"""
Turns a Prediction into what a person can act on:

  drivers   — the grouped SHAP contributions, labelled in plain language
  actions   — a short, prioritised care plan derived from the drivers
  narrative — the script Teemo reads aloud (one subtitle per segment)

Wording rules: TTS-friendly (no symbols like ">"), never claims certainty,
always ends by handing the decision back to the care team.
"""
from . import labels as L
from .features import MED_COLUMNS

# Demographics are used by the model but are neither actionable nor something
# we want Teemo to announce as "your risk factor". They stay in the full list
# (transparency) but are excluded from the spoken top drivers.
NOT_SPOKEN = {"race", "gender", "payer_code"}  # payer: mostly a missing-data artefact
# Contributions below this share of the total are noise — never announce them.
MIN_SPOKEN_SHARE = 0.05
NON_MODIFIABLE = {"race", "gender", "age"}


def _plural(n: int, word: str) -> str:
    if n == 0:
        return f"no {word}s"
    return f"{n} {word}{'' if n == 1 else 's'}"


def _med_phrase(status: str) -> str:
    return {"No": "not prescribed", "Steady": "prescribed at a steady dose",
            "Up": "prescribed, dose increased", "Down": "prescribed, dose decreased"}[status]


def describe(group: str, r: dict):
    """(title, value text, plain-language explanation) for one driver group."""
    if group == "visits":
        value = (f"{_plural(int(r['number_inpatient']), 'inpatient stay')} · "
                 f"{_plural(int(r['number_emergency']), 'ER visit')} · "
                 f"{_plural(int(r['number_outpatient']), 'outpatient visit')}")
        return ("Hospital visit history", value,
                "Visits in the year before this admission — prior inpatient stays are the "
                "single strongest readmission signal in this dataset.")
    if group == "age":
        return ("Age", f"{L.AGE[r['age']]} years", "Older patients tend to recover more slowly.")
    if group == "time_in_hospital":
        return ("Length of stay", _plural(int(r["time_in_hospital"]), "day"),
                "Longer stays usually mean a more severe or complicated episode.")
    if group == "num_medications":
        return ("Medications", _plural(int(r["num_medications"]), "medication"),
                "Many medications raise the chance of interactions and missed doses.")
    if group == "number_diagnoses":
        return ("Recorded diagnoses", _plural(int(r["number_diagnoses"]), "condition"),
                "More conditions means more things that can go wrong after discharge.")
    if group == "num_lab_procedures":
        return ("Lab tests", _plural(int(r["num_lab_procedures"]), "test"),
                "How intensively the patient was investigated during the stay.")
    if group == "num_procedures":
        return ("Procedures", _plural(int(r["num_procedures"]), "procedure"),
                "Non-lab procedures performed during the stay.")
    if group == "discharge_disposition_id":
        return ("Discharge destination",
                L.DISCHARGE_DISPOSITION.get(int(r["discharge_disposition_id"]), "Other"),
                "Where the patient goes next shapes how much support they will have.")
    if group == "admission_type_id":
        return ("Admission type", L.ADMISSION_TYPE.get(int(r["admission_type_id"]), "Other"),
                "Emergency and urgent admissions differ from planned ones.")
    if group == "admission_source_id":
        return ("Admitted from", L.ADMISSION_SOURCE.get(int(r["admission_source_id"]), "Other"),
                "The route into hospital reflects how the episode started.")
    if group == "medical_specialty":
        return ("Admitting specialty", L.specialty(r["medical_specialty"]),
                "The specialty that admitted the patient.")
    if group == "payer_code":
        return ("Insurance", L.payer(r["payer_code"]),
                "Coverage can affect access to follow-up care.")
    if group == "A1Cresult":
        return ("HbA1c result", L.A1C[r["A1Cresult"]],
                "HbA1c summarises blood-sugar control over the last three months.")
    if group == "max_glu_serum":
        return ("Glucose serum test", L.GLUCOSE[r["max_glu_serum"]],
                "The highest blood glucose measured during the stay.")
    if group == "insulin":
        return ("Insulin", _med_phrase(r["insulin"]).capitalize(),
                "Insulin therapy needs careful dosing and monitoring at home.")
    if group == "metformin":
        return ("Metformin", _med_phrase(r["metformin"]).capitalize(),
                "First-line oral diabetes medication.")
    if group == "other_meds":
        on = [m for m in MED_COLUMNS if m not in ("insulin", "metformin") and r[m] != "No"]
        value = ", ".join(f"{m} ({L.MED_STATUS[r[m]].lower()})" for m in on) or "None"
        return ("Other diabetes medications", value, "Oral agents other than metformin.")
    if group == "med_changes":
        n = sum(1 for m in MED_COLUMNS if r[m] in ("Up", "Down"))
        return ("Dose changes this stay", _plural(n, "change"),
                "Each change is something the patient must get right at home.")
    if group == "diabetesMed":
        return ("Diabetes medication", "Prescribed" if r["diabetesMed"] == "Yes" else "None",
                "Whether any diabetes medication was prescribed.")
    if group in ("diag_1", "diag_2", "diag_3"):
        title = {"diag_1": "Primary diagnosis", "diag_2": "Secondary diagnosis",
                 "diag_3": "Additional diagnosis"}[group]
        return (title, L.DIAGNOSIS.get(r[f"{group}_group"], r[f"{group}_group"]),
                "The clinical family of the diagnosis (ICD-9 grouping).")
    if group == "race":
        return ("Race (recorded)", L.RACE.get(r["race"], r["race"]),
                "Demographic pattern learned from historical data — not a cause, "
                "and audited for fairness.")
    if group == "gender":
        return ("Gender (recorded)", r["gender"],
                "Demographic pattern learned from historical data — not a cause.")
    return (group, "", "")


def build_drivers(contributions: dict, r: dict, limit: int = 12):
    total = sum(abs(v) for v in contributions.values()) or 1.0
    ordered = sorted(contributions.items(), key=lambda kv: abs(kv[1]), reverse=True)
    out = []
    for group, value in ordered[:limit]:
        title, val_text, why = describe(group, r)
        out.append({
            "key": group,
            "title": title,
            "value": val_text,
            "explanation": why,
            "direction": "up" if value > 0 else "down",
            "impact": round(value, 4),
            "share": round(abs(value) / total, 4),
            "modifiable": group not in NON_MODIFIABLE,
        })
    return out


# --------------------------------------------------------------------- actions
def build_actions(level: str, drivers: list, r: dict, limit: int = 5):
    up = {d["key"] for d in drivers[:8] if d["direction"] == "up"}
    acts = []

    def add(icon, title, detail, priority):
        acts.append({"icon": icon, "title": title, "detail": detail, "priority": priority})

    if level == "HIGH":
        add("call", "Nurse call within 72 hours",
            "Enroll the patient in a transitional-care phone follow-up after discharge.", "high")
        add("calendar", "Follow-up visit within 7 days",
            "Book the appointment before the patient leaves the ward.", "high")
    elif level == "MODERATE":
        add("calendar", "Follow-up visit within 14 days",
            "Above the cost-effective threshold for intervention — schedule it now.", "medium")
    if "visits" in up:
        add("team", "Assign a care coordinator",
            "Repeated recent visits — review why and build one shared care plan.", "high")
    if {"num_medications", "med_changes"} & up:
        add("pill", "Medication reconciliation",
            "Pharmacist review of every medication and dose change before discharge.", "medium")
    if "insulin" in up and r["insulin"] != "No":
        add("syringe", "Insulin teaching & glucose plan",
            "Confirm the patient can dose insulin and log glucose at home.", "medium")
    if r["A1Cresult"] == "Not_Tested":
        add("lab", "Order an HbA1c test",
            "It wasn't measured this stay — tested patients are managed better.", "medium")
    elif r["A1Cresult"] in (">7", ">8"):
        add("lab", "Intensify diabetes management",
            "HbA1c is above target — review the treatment plan at follow-up.", "medium")
    if "discharge_disposition_id" in up:
        add("home", "Hand over the care plan",
            "Make sure the discharge destination receives the full care plan.", "medium")
    if "time_in_hospital" in up or "number_diagnoses" in up:
        add("home", "Home-health check in week one",
            "A complex stay — a visit or video check during the first week.", "medium")
    if level == "LOW":
        add("check", "Standard discharge plan",
            "Routine follow-up with the primary care physician.", "low")
    add("alert", "Teach the warning signs",
        "Very high or low glucose, confusion, chest pain or breathlessness — seek care fast.",
        "low")

    seen, unique = set(), []
    for a in acts:
        if a["title"] not in seen:
            seen.add(a["title"])
            unique.append(a)
    return unique[:limit]


# ------------------------------------------------------------------- narrative
LEVEL_WORD = {"LOW": "low", "MODERATE": "moderate", "HIGH": "high"}


def _spoken_value(d: dict) -> str:
    """Driver value rewritten for the voice (no symbols, no '·')."""
    v = d["value"]
    if v[:1].isupper() and not v[:2].isupper():  # "Prescribed" -> "prescribed", keep "ER"
        v = v[0].lower() + v[1:]
    return (v.replace(" · ", ", ").replace("–", " to ").replace("%", " percent")
            .replace("+", " plus").replace("/", " or ").replace(" — ", ", "))


def build_narrative(p: float, level: str, baseline: float, percentile, drivers: list,
                    actions: list, band_rate=None):
    pct = round(p * 100)
    base = round(baseline * 100)
    ratio = p / baseline if baseline else 1.0
    seg = []

    def say(kind, text):
        seg.append({"kind": kind, "text": text})

    say("greeting", "Hi, I'm Teemo. I've finished analysing this patient's record.")
    say("score", f"The estimated chance of being readmitted within 30 days is {pct} percent. "
                 f"That is a {LEVEL_WORD[level]} risk.")
    if ratio >= 1.15:
        comp = f"about {ratio:.1f} times the hospital average of {base} percent"
    elif ratio <= 0.85:
        comp = f"below the hospital average of {base} percent"
    else:
        comp = f"close to the hospital average of {base} percent"
    line = f"It's {comp}."
    if percentile is not None:
        line += f" It's higher than {percentile} percent of the patients I was tested on."
    say("comparison", line)
    if band_rate is not None:
        say("calibration", f"In testing, about {round(band_rate * 100)} out of 100 patients in "
                           f"this {LEVEL_WORD[level]} risk group really did come back within a month.")

    spoken = [d for d in drivers if d["key"] not in NOT_SPOKEN and d["share"] >= MIN_SPOKEN_SHARE]
    ups = [d for d in spoken if d["direction"] == "up"][:3]
    downs = [d for d in spoken if d["direction"] == "down"][:2]

    def listing(ds):
        return " and ".join(f"{d['title'].lower()}, {_spoken_value(d)}" for d in ds)

    if level == "LOW":
        if downs:
            say("driver_down", f"The main things keeping the risk low are {listing(downs)}.")
        if ups:
            say("driver_up", f"A few things still nudge it up slightly: {listing(ups[:2])}.")
    else:
        ordinal = ["The biggest factor raising the risk is", "Next comes", "And also"]
        for i, d in enumerate(ups):
            say("driver_up", f"{ordinal[i]} {d['title'].lower()}: {_spoken_value(d)}.")
        if downs:
            verb = "helps" if len(downs) == 1 else "help"
            say("driver_down", f"On the positive side, {listing(downs)} {verb} lower the risk.")

    if actions:
        say("actions_intro", "Here is what I recommend.")
        for a in actions[:4]:
            say("action", f"{a['title']}. {a['detail']}")
    say("closing", "Remember, I'm a decision-support tool. The care team always makes the final call. "
                   "Take care!")
    return seg
