# -*- coding: utf-8 -*-
"""
CareStep — business logic, ported 1:1 from the Streamlit page
(`deployment/app/pages/2_CareStep.py`) and its helpers in `deployment/app/utils.py`
(`render_risk_result`, `generate_reasons`, `generate_actions`).

  * 12 patient-reported answers -> 23 one-hot features (same row builder as the page,
    including the encoding fix: change_No = 1 means NO medication change).
  * CalibratedClassifierCV (LightGBM + isotonic), loaded ONCE from artifacts/carestep/.
  * Risk levels: LOW < 14 % <= MEDIUM < 25 % <= HIGH (same thresholds as the page).
  * Rule-based (SHAP-free) reasons, actions, 30-day plan and care-team summary.
"""
import re
from functools import lru_cache

import joblib
import pandas as pd

from app.core.config import ARTIFACTS_DIR

ARTIFACT_DIR = ARTIFACTS_DIR / "carestep"
MODEL_PATH = ARTIFACT_DIR / "carestep_model.joblib"
FEATURES_PATH = ARTIFACT_DIR / "carestep_features.joblib"

LOW_MAX, MEDIUM_MAX = 0.14, 0.25          # p < 0.14 LOW, p < 0.25 MEDIUM, else HIGH
HOSPITAL_AVERAGE_PCT = 11                 # "Hospital average: ~11%" on the page

# --------------------------------------------------------------------------- #
# Allowed values (same options and labels as the page)
# --------------------------------------------------------------------------- #
AGE_RANGES = {
    0: "0-10", 1: "10-20", 2: "20-30", 3: "30-40", 4: "40-50",
    5: "50-60", 6: "60-70", 7: "70-80", 8: "80-90", 9: "90-100",
}
GENDERS = {"Female": "Female", "Male": "Male"}
DIAG_GROUPS = {
    "circulatory": "Heart or blood vessel problem",
    "respiratory": "Breathing or lung problem",
    "digestive": "Stomach or digestive problem",
    "diabetes": "Diabetes complication",
    "injury": "Injury or accident",
    "infection_renal": "Kidney, urinary or infection",
    "other": "Other medical condition",
}
INSULIN_OPTIONS = {
    "No": "Not on insulin",
    "Steady": "Insulin — no change",
    "Up": "Insulin — dose increased",
    "Down": "Insulin — dose decreased",
}
DISCHARGE_OPTIONS = {
    "home": "Going home alone",
    "home_with_help": "Going home with help",
    "facility": "Going to a facility (rehab, nursing)",
}
MED_CHANGE_OPTIONS = {"Yes": "Yes — medications were changed", "No": "No changes"}
A1C_OPTIONS = {"No": "No — not tested", "Yes": "Yes — HbA1c was tested"}

# (min, max, default) — the page's sliders
RANGES = {
    "time_hosp": (1, 14, 5),
    "num_meds": (1, 50, 12),
    "inpatient": (0, 10, 0),
    "emergency": (0, 10, 0),
    "outpatient_raw": (0, 20, 2),
}

NO_FACTOR = "No major individual risk factors — overall pattern contributes to the score"


# --------------------------------------------------------------------------- #
# Model
# --------------------------------------------------------------------------- #
def model_available() -> bool:
    return MODEL_PATH.exists() and FEATURES_PATH.exists()


@lru_cache(maxsize=1)
def get_model():
    return joblib.load(MODEL_PATH), list(joblib.load(FEATURES_PATH))


def build_row(inp: dict, features: list) -> dict:
    """The page's row builder, unchanged (12 answers -> one-hot feature row)."""
    inpatient_cap = min(inp["inpatient"], 3)
    emergency_cap = min(inp["emergency"], 3)
    outpatient_raw = inp["outpatient_raw"]
    if outpatient_raw == 0:
        outpatient_bkt = 0
    elif outpatient_raw <= 2:
        outpatient_bkt = 1
    elif outpatient_raw <= 5:
        outpatient_bkt = 2
    else:
        outpatient_bkt = 3

    row = {f: 0 for f in features}
    row["age_ord"] = inp["age"]
    row["gender_bin"] = 1 if inp["gender"] == "Male" else 0
    row["inpatient_cap"] = inpatient_cap
    row["emergency_cap"] = emergency_cap
    row["outpatient_bkt"] = outpatient_bkt
    row["time_in_hospital"] = inp["time_hosp"]
    row["num_medications"] = inp["num_meds"]
    row["a1c_tested"] = 1 if inp["a1c_tested"] == "Yes" else 0

    for col in (f"diag_group_{inp['diag_group']}", f"insulin_{inp['insulin']}",
                f"discharge_group_{inp['discharge']}"):
        if col in row:
            row[col] = 1
    # encoder keeps only change_No (1 = nothing changed)
    change_val = "Ch" if inp["med_change"] == "Yes" else "No"
    if change_val == "No":
        row["change_No"] = 1
    return row


def predict_proba(inp: dict) -> float:
    model, features = get_model()
    row_df = pd.DataFrame([build_row(inp, features)])[features]
    return float(model.predict_proba(row_df)[0][1])


def risk_level(prob: float):
    """render_risk_result(): level + advice sentence."""
    pct = prob * 100
    if pct < LOW_MAX * 100:
        return "LOW", "Your risk is below the hospital average. Keep following your care plan."
    if pct < MEDIUM_MAX * 100:
        return "MEDIUM", "Your risk is moderate. A follow-up within 7 days is recommended."
    return "HIGH", "Your risk is elevated. Please schedule an urgent follow-up and medication review."


# --------------------------------------------------------------------------- #
# Reasons / actions (utils.generate_reasons / generate_actions on the page's human_row)
# --------------------------------------------------------------------------- #
def human_row(inp: dict) -> dict:
    return {
        "total_prior_visits": inp["inpatient"] + inp["emergency"] + inp["outpatient_raw"],
        "num_medications": inp["num_meds"],
        "insulin_prescrite": 0 if inp["insulin"] == "No" else 1,
        "time_in_hospital": inp["time_hosp"],
        "A1Cresult": "Not_Tested" if inp["a1c_tested"] == "No" else "Tested",
        "number_diagnoses": 3,
        "age_ordinal": inp["age"],
        "num_med_changes": 1 if inp["med_change"] == "Yes" else 0,
    }


def generate_reasons(row: dict) -> list:
    reasons = []
    if row["total_prior_visits"] >= 3:
        reasons.append(f"Multiple prior visits ({int(row['total_prior_visits'])} total) "
                       "suggest a complex health situation")
    if row["num_medications"] >= 10:
        reasons.append(f"Taking {int(row['num_medications'])} medications increases "
                       "interaction and adherence risk")
    if row["insulin_prescrite"] == 1:
        reasons.append("Insulin therapy requires careful monitoring after discharge")
    if row["time_in_hospital"] >= 7:
        reasons.append(f"Extended hospital stay ({int(row['time_in_hospital'])} days) "
                       "indicates higher severity")
    if row["A1Cresult"] == "Not_Tested":
        reasons.append("HbA1c was not tested this stay — an important diabetes marker was missed")
    if row["number_diagnoses"] >= 7:
        reasons.append(f"{int(row['number_diagnoses'])} diagnoses indicate multiple health conditions")
    if row["age_ordinal"] >= 7:
        ages = {7: "70-80", 8: "80-90", 9: "90+"}
        reasons.append(f"Age range ({ages.get(int(row['age_ordinal']), '70+')}) "
                       "is a non-modifiable risk factor")
    if row["num_med_changes"] >= 2:
        reasons.append(f"{int(row['num_med_changes'])} medication changes during this stay "
                       "need careful follow-up")
    return reasons[:5] if reasons else [NO_FACTOR]


def generate_actions(reasons: list, level: str) -> list:
    actions = []
    if level in ("HIGH", "MEDIUM"):
        actions.append("Book a follow-up appointment within 7 days of discharge")
    if any("medication" in r.lower() for r in reasons):
        actions.append("Ask your pharmacist to review all medications for interactions")
    if any("insulin" in r.lower() for r in reasons):
        actions.append("Monitor blood sugar daily and follow your insulin schedule")
    if any("HbA1c" in r for r in reasons):
        actions.append("Ask your doctor about scheduling an HbA1c test")
    if any("prior visit" in r.lower() or "hospital stay" in r.lower() for r in reasons):
        actions.append("Discuss a home health visit or phone check-in with your care team")
    if level == "HIGH":
        actions.append("Go to the ER if blood sugar stays very high/low, "
                       "or you feel confused or short of breath")
    if not actions:
        actions.append("Continue following your care team's discharge instructions")
        actions.append("Keep all scheduled follow-up appointments")
    return actions


# --------------------------------------------------------------------------- #
# 30-day plan and care-team summary (tabs 2 and 4 of the page)
# --------------------------------------------------------------------------- #
def action_plan(inp: dict, level: str) -> list:
    on_insulin = inp["insulin"] != "No"
    a1c_not_tested = inp["a1c_tested"] == "No"
    many_meds = inp["num_meds"] >= 8
    high_risk = level in ("HIGH", "MEDIUM")

    week1 = [{"icon": "pill", "text": "Take all medications exactly as prescribed — set a daily alarm"}]
    week1.append({"icon": "calendar", "text": "Book a follow-up appointment within 7 days"} if high_risk
                 else {"icon": "calendar", "text": "Keep your next scheduled follow-up appointment"})
    week1.append({"icon": "blood", "text": "Measure blood sugar every morning and evening"} if on_insulin
                 else {"icon": "blood", "text": "Check blood sugar at least 3 times this week"})
    week1.append({"icon": "organizer", "text": f"Use a pill organizer for your {inp['num_meds']} medications"}
                 if many_meds else {"icon": "alarm", "text": "Set daily medication reminders on your phone"})
    if a1c_not_tested:
        week1.append({"icon": "lab", "text": "Ask your doctor about scheduling an HbA1c test"})

    week2 = [
        {"icon": "pill", "text": "Continue daily medication routine"},
        {"icon": "hospital", "text": "Attend your follow-up visit — bring your blood sugar log"},
        {"icon": "phone", "text": "Report any new symptoms to your care team immediately"},
        {"icon": "walk", "text": "Start light physical activity as approved by your doctor"},
        {"icon": "diet", "text": "Review your diet plan — aim for consistent meal timing"},
    ]
    week4 = [
        {"icon": "target", "text": "Maintain your medication and monitoring routine"},
        {"icon": "note", "text": "Write down questions for your next doctor visit"},
        {"icon": "progress", "text": "Review your 30-day progress — celebrate your wins!"},
        {"icon": "calendar", "text": "Schedule your next monthly follow-up"},
    ]
    if level == "HIGH":
        week4.append({"icon": "alert",
                      "text": "Keep emergency numbers accessible — call if blood sugar spikes"})

    return [
        {"title": "Week 1 — Intensive Phase", "subtitle": "Days 1–7: Building your foundation",
         "color": "#059669", "items": week1},
        {"title": "Weeks 2–3 — Stabilization", "subtitle": "Days 8–21: Strengthening your routine",
         "color": "#0D9488", "items": week2},
        {"title": "Week 4 — Independence", "subtitle": "Days 22–30: Taking the lead",
         "color": "#2563EB", "items": week4},
    ]


def care_team(inp: dict, prob: float, level: str, reasons: list) -> dict:
    key_factors = [] if (not reasons or reasons[0] == NO_FACTOR) else reasons[:4]

    if level == "HIGH":
        recs = ["Urgent follow-up within 48 hours of discharge"]
    elif level == "MEDIUM":
        recs = ["Schedule follow-up within 7 days of discharge"]
    else:
        recs = ["Keep standard follow-up schedule"]
    if inp["a1c_tested"] == "No":
        recs.append("Order HbA1c test — not done this stay")
    if inp["num_meds"] >= 10:
        recs.append("Pharmacist medication reconciliation recommended")
    if inp["insulin"] != "No":
        recs.append("Provide blood glucose monitoring supplies and education")

    questions = [
        "Should my medication doses be adjusted based on recent blood sugar readings?",
        "Can my medication schedule be simplified to help me stay on track?",
        "When should I get an HbA1c test done?" if inp["a1c_tested"] == "No"
        else "What does my HbA1c result mean for my daily routine?",
        "What warning signs should I watch for at home?",
    ]
    if level == "HIGH":
        questions.append("Should I consider home health visits or phone check-ins?")

    summary = (
        f"Patient at {level} risk with {prob * 100:.0f}% readmission probability. "
        f"Key factors: {', '.join(reasons[:2]) if reasons else 'no major individual factors'}. "
        f"{'Urgent follow-up recommended.' if level == 'HIGH' else 'Standard follow-up plan in place.'}"
    )
    return {
        "profile": {
            "age_range": AGE_RANGES[inp["age"]],
            "gender": inp["gender"],
            "hospital_stay": f"{inp['time_hosp']} days",
            "discharge_to": DISCHARGE_OPTIONS[inp["discharge"]],
            "medications": inp["num_meds"],
            "insulin": INSULIN_OPTIONS[inp["insulin"]],
            "primary_diagnosis": DIAG_GROUPS[inp["diag_group"]],
            "hba1c_tested": inp["a1c_tested"],
        },
        "key_factors": key_factors,
        "recommended_actions": recs,
        "questions_for_doctor": questions,
        "summary": summary,
    }


# --------------------------------------------------------------------------- #
# Spoken narrative (numbers as words, no symbols)
# --------------------------------------------------------------------------- #
_ONES = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
         "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
         "seventeen", "eighteen", "nineteen"]
_TENS = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]


def words(n: int) -> str:
    n = int(round(n))
    if n < 0:
        return "minus " + words(-n)
    if n < 20:
        return _ONES[n]
    if n < 100:
        t, u = divmod(n, 10)
        return _TENS[t] + ("" if u == 0 else f"-{_ONES[u]}")
    if n < 1000:
        h, r = divmod(n, 100)
        return f"{_ONES[h]} hundred" + ("" if r == 0 else f" and {words(r)}")
    return str(n)


def percent(p: float) -> str:
    return f"{words(round(p * 100))} percent"


def speak(text: str) -> str:
    """Written sentence -> spoken sentence (digits to words, symbols out)."""
    text = re.sub(r"\bER\b", "emergency room", text.replace("HbA1c", "A one C"))
    text = text.replace("high/low", "high or low").replace(" — ", ", ")
    text = re.sub(r"(\d+)\+", lambda m: f"{words(int(m.group(1)))} plus", text)
    text = re.sub(r"(\d+)-(\d+)", lambda m: f"{words(int(m.group(1)))} to {words(int(m.group(2)))}", text)
    text = re.sub(r"\d+", lambda m: words(int(m.group())), text)
    return re.sub(r"\s*\(([^)]*)\)", r", \1,", text)   # "visits (19 total) suggest" -> "visits, nineteen total, suggest"


def narrative(prob: float, level: str, advice: str, reasons: list, actions: list) -> list:
    level_word = {"LOW": "low", "MEDIUM": "medium", "HIGH": "high"}[level]
    above = round(prob * 100) > HOSPITAL_AVERAGE_PCT
    segs = [
        {"kind": "greeting", "text": "Hi, I'm CareStep, your thirty-day recovery companion."},
        {"kind": "score", "text": f"Your thirty-day readmission risk is {percent(prob)}, "
                                  f"rated {level_word}. {speak(advice)}"},
        {"kind": "comparison",
         "text": f"For comparison, the hospital average is about {words(HOSPITAL_AVERAGE_PCT)} percent, "
                 f"so you are {'above' if above else 'at or below'} average."},
    ]
    real = [r for r in reasons if r != NO_FACTOR]
    if real:
        for r in real[:3]:
            segs.append({"kind": "driver_up", "text": speak(r) + "."})
    else:
        segs.append({"kind": "driver_down", "text": speak(NO_FACTOR) + "."})
    for a in actions[:3]:
        segs.append({"kind": "action", "text": speak(a) + "."})
    segs.append({"kind": "closing",
                 "text": "Your week-by-week recovery plan is ready. This is a support tool, "
                         "not a diagnosis: always follow your care team's advice."})
    return segs


# --------------------------------------------------------------------------- #
# Full assessment
# --------------------------------------------------------------------------- #
def assess(inp: dict) -> dict:
    prob = predict_proba(inp)
    level, advice = risk_level(prob)
    reasons = generate_reasons(human_row(inp))
    actions = generate_actions(reasons, level)
    return {
        "probability": round(prob, 4),
        "percent": round(prob * 100),
        "level": level,
        "advice": advice,
        "hospital_average_percent": HOSPITAL_AVERAGE_PCT,
        "thresholds": {"medium": LOW_MAX, "high": MEDIUM_MAX},
        "reasons": reasons,
        "actions": actions,
        "plan": action_plan(inp, level),
        "care_team": care_team(inp, prob, level, reasons),
        "narrative": narrative(prob, level, advice, reasons, actions),
    }
