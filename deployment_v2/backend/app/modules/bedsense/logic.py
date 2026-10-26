"""BedSense adapter: imports Najd's capalit_ml package from the repo root and shapes its output.

Nothing here re-implements a model. Scoring, thresholds, the ward simulation, the plans, the
alerts and the plain-language wording all come from capalit_ml (planning.py / api.py). This file
only maps the app's form to his raw columns (same mapping as the Streamlit "Check a Patient" tab)
and turns his DataFrames into small JSON-safe payloads.
"""
from __future__ import annotations

import json
import math
import os
import sys
from datetime import date
from functools import lru_cache
from pathlib import Path
from typing import Any, Optional

import numpy as np
import pandas as pd


# --------------------------------------------------------------------------- #
# Locate capalit_ml (lives at the repo root, never copied into the backend)
# --------------------------------------------------------------------------- #
def _find_repo_root() -> Path:
    candidates = []
    override = os.getenv("BEDSENSE_REPO_ROOT")
    if override:
        candidates.append(Path(override).expanduser().resolve())
    candidates.extend(Path(__file__).resolve().parents)
    for folder in candidates:
        if (folder / "capalit_ml" / "__init__.py").is_file():
            return folder
    raise ImportError(
        "BedSense needs Najd's 'capalit_ml' package at the repository root "
        "(expected <repo>/capalit_ml next to deployment_v2/). It was not found above "
        f"{Path(__file__).resolve().parent}. Set BEDSENSE_REPO_ROOT to the folder that contains capalit_ml/."
    )


REPO_ROOT = _find_repo_root()
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from capalit_ml import planning as P  # noqa: E402
from capalit_ml import api as capalit_api  # noqa: E402  (reuse his cached simulation and plan helpers)


# --------------------------------------------------------------------------- #
# Form -> raw columns (same choices and mapping as deployment/app/pages/6_BedSense.py)
# --------------------------------------------------------------------------- #
AGE_BANDS = ["[0-10)", "[10-20)", "[20-30)", "[30-40)", "[40-50)", "[50-60)",
             "[60-70)", "[70-80)", "[80-90)", "[90-100)"]
RACES = ["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other"]
DIAG_CODES = {
    "Heart or blood vessels": "428", "Lungs or breathing": "486", "Digestion": "577",
    "Diabetes": "250.02", "Injury": "820", "Bones or joints": "715", "Kidneys or bladder": "599",
    "Cancer": "162", "Other": "780",
}
SPECIALTY = {
    "Internal medicine": "InternalMedicine", "Emergency": "Emergency/Trauma",
    "General practice": "Family/GeneralPractice", "Cardiology": "Cardiology",
    "Surgery": "Surgery-General", "Kidney care": "Nephrology", "Other services": np.nan,
}
DOSE = {"No": "Not taking it", "Steady": "Same dose", "Up": "Dose increased", "Down": "Dose lowered"}
A1C = {"Not measured": np.nan, "Normal": "Norm", "Above 7": ">7", "Above 8": ">8"}
GLUCOSE = {"Not measured": np.nan, "Normal": "Norm", "Above 200": ">200", "Above 300": ">300"}
ADMISSION_TYPES = [1, 2, 3, 7]
ADMISSION_SOURCES = [7, 1, 2, 4, 6]
DISCHARGES = [1, 6, 3, 22, 2, 7]

DISCLAIMER = (
    "Decision support built on historical US hospital stays of diabetic patients (1999-2008). "
    "It does not replace the clinical judgement of the care team. Ward capacity and staffing "
    "figures are placeholder settings until the service enters its own numbers."
)


def admission_label(code: int) -> str:
    return {3: "Planned"}.get(code, P.label("admission_type_id", code))


def build_row(form: dict) -> dict:
    """One raw stay with the columns of diabetic_data.csv, built like the Streamlit form."""
    row: dict[str, Any] = {c: "No" for c in P.MED_COLS}
    insulin, metformin = form["insulin"], form["metformin"]
    row.update({
        "race": form["race"] if form["race"] else np.nan,
        "gender": form["gender"], "age": form["age"],
        "admission_type_id": form["admission_type_id"],
        "discharge_disposition_id": form["discharge_disposition_id"],
        "admission_source_id": form["admission_source_id"],
        "time_in_hospital": form["time_in_hospital"], "payer_code": np.nan,
        "medical_specialty": SPECIALTY[form["service"]],
        "num_lab_procedures": form["num_lab_procedures"], "num_procedures": form["num_procedures"],
        "num_medications": form["num_medications"], "number_outpatient": form["number_outpatient"],
        "number_emergency": form["number_emergency"], "number_inpatient": form["number_inpatient"],
        "diag_1": DIAG_CODES[form["diag_1"]], "diag_2": DIAG_CODES[form["diag_2"]],
        "diag_3": DIAG_CODES[form["diag_3"]], "number_diagnoses": form["number_diagnoses"],
        "max_glu_serum": GLUCOSE[form["max_glu_serum"]], "A1Cresult": A1C[form["A1Cresult"]],
        "insulin": insulin, "metformin": metformin,
        "change": "Ch" if form["change"] == "Yes" else "No",
        "diabetesMed": "Yes" if (form["diabetesMed"] == "Yes" or insulin != "No" or metformin != "No") else "No",
    })
    return row


# --------------------------------------------------------------------------- #
# Spoken wording helpers
# --------------------------------------------------------------------------- #
def _days(n: int) -> str:
    return f"{n} day" if n == 1 else f"{n} days"


def _spoken_range(text: str) -> str:
    return text.replace(" to ", " and ")


def _num(x: float) -> str:
    """Small decimal read aloud cleanly: 0.74 -> '0.7', 3.0 -> '3'."""
    v = round(float(x), 1)
    return str(int(v)) if v == int(v) else f"{v}"


# --------------------------------------------------------------------------- #
# Patient-level prediction
# --------------------------------------------------------------------------- #
@lru_cache(maxsize=1)
def _risk_reference() -> np.ndarray:
    """Sorted risks of every scored stay in the hospital file (P.load_stays is itself cached)."""
    return np.sort(P.load_stays()["risk"].to_numpy())


def predict(form: dict) -> dict:
    row = build_row(form)
    s = P.score_stays(pd.DataFrame([row])).iloc[0]
    ref = _risk_reference()
    risk = float(s["risk"])
    risk_rank = float(np.searchsorted(ref, risk, side="right") / len(ref))  # == mean(ref <= risk)
    likely = max(1, round(float(s["stay_likely"])))
    range_text = P.stay_range(s["stay_low"], s["stay_high"])
    card = pd.Series({
        **s.to_dict(), "risk_rank": risk_rank, "stay_text": range_text, "stay_likely": likely,
        "number_inpatient": form["number_inpatient"], "number_emergency": form["number_emergency"],
        "number_outpatient": form["number_outpatient"], "num_medications": form["num_medications"],
        "time_in_hospital": form["time_in_hospital"], "admission_type_id": form["admission_type_id"],
        "discharge_disposition_id": form["discharge_disposition_id"],
    })
    e = P.explain(card)
    e["arrival"] = admission_label(form["admission_type_id"])
    level_label = str(s["level"])
    level = level_label.lower()
    percent = round(risk * 100)
    bed_days = float(s["bed_days"])
    above = min(99, int(risk_rank * 100))

    narrative = [
        {"kind": "greeting", "text": "Hi, I'm BedSense. I looked at this stay to help plan the discharge."},
        {"kind": "score", "text": f"The chance that this patient comes back to hospital within 30 days "
                                  f"is about {percent} percent. That is a {level} risk."},
        {"kind": "comparison", "text": f"Their chance is higher than for {above} out of 100 patients in our records."},
        {"kind": "score", "text": f"If they come back, they would most likely stay about {_days(likely)}, "
                                  f"between {_spoken_range(range_text)}."},
        {"kind": "calibration", "text": f"Counting the chance that they come back, plan about "
                                        f"{_num(bed_days)} bed days for this patient."},
        {"kind": "action", "text": f"My advice: {e['advice'][0].lower()}{e['advice'][1:]}."},
        {"kind": "closing", "text": "This is decision support, not a diagnosis. The final call stays with the care team."},
    ]
    return {
        "probability": round(risk, 4),
        "percent": percent,
        "level": level,
        "level_label": f"{level_label} risk",
        "thresholds": {"medium": round(P.RISK_THRESHOLDS["Medium"], 4),
                       "high": round(P.RISK_THRESHOLDS["High"], 4)},
        "risk_rank": round(risk_rank, 4),
        "stay": {
            "median": round(float(s["stay_likely"]), 1),
            "q10": round(float(s["stay_low"]), 1),
            "q90": round(float(s["stay_high"]), 1),
            "mean": round(float(s["stay_mean"]), 1),
            "likely_days": likely,
            "range_text": range_text,
        },
        "bed_days": round(bed_days, 2),
        "headline": e["headline"],
        "sentence": e["sentence"],
        "stay_sentence": e["stay"],
        "facts": e["facts"],
        "advice": e["advice"],
        "arrival": e["arrival"],
        "leaving_to": e["leaving_to"],
        "narrative": narrative,
        "disclaimer": DISCLAIMER,
    }


# --------------------------------------------------------------------------- #
# Ward-level (simulation from capalit_ml, cached)
# --------------------------------------------------------------------------- #
def _clean(obj):
    """Recursively make numpy / pandas / dates / NaN JSON-safe."""
    if isinstance(obj, dict):
        return {k: _clean(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [_clean(v) for v in obj]
    if isinstance(obj, (pd.Timestamp, date)):
        return obj.isoformat()[:10]
    if isinstance(obj, np.generic):
        obj = obj.item()
    if isinstance(obj, float):
        return None if math.isnan(obj) or math.isinf(obj) else round(obj, 3)
    return obj


def _records(df: pd.DataFrame) -> list[dict]:
    return _clean(json.loads(df.to_json(orient="records", date_format="iso")))


def _today() -> str:
    return date.today().isoformat()


def simulation() -> "P.Simulation":
    return capalit_api._sim(_today())  # lru_cached by day in capalit_ml/api.py


def services() -> list[str]:
    return P.services(simulation())


@lru_cache(maxsize=32)
def _plan_payload(day: str, service: Optional[str], horizon: int) -> dict:
    sim, plan = capalit_api._plan(service, horizon)
    days_cols = ["date", "current_patients", "new_patients", "expected_returns", "beds_needed", "beds_safe",
                 "capacity", "free_beds", "occupancy", "status", "admissions_planned", "returns_arriving",
                 "nurses_needed", "nurses_on_duty", "staff_gap"]
    week_cols = ["label", "start", "end", "peak_beds", "avg_needed", "capacity", "margin", "critical_days",
                 "tight_days", "returns", "admissions", "nurses_peak", "nurses_on_duty"]
    days = plan[days_cols].round(2).copy()
    days["date"] = [d.isoformat() for d in plan["date"]]
    weeks = P.weekly_plan(plan)[week_cols].round(2).copy()
    weeks["start"] = [d.isoformat() for d in weeks["start"]]
    weeks["end"] = [d.isoformat() for d in weeks["end"]]
    alerts = P.alerts(plan)
    for a in alerts:
        a["date"] = a["date"].isoformat()
    summ = P.summary(sim, service, horizon)
    safety = float(sim.cfg["returns"]["safety_level"])
    beds, nurses = P.capacity(sim, service)

    where = f"the {service} service" if service else "the hospital"
    over, tight = summ["critical_days"], summ["tight_days"]
    if over:
        outlook = (f"I expect beds to run out on {_days(over)} in the next {_days(horizon)}, "
                   f"starting {pd.Timestamp(summ['first_critical']).strftime('%A %d %B')}.")
    elif tight:
        outlook = f"There are enough beds, but {_days(tight)} in the next {_days(horizon)} look tight."
    else:
        outlook = f"There are enough beds every day for the next {_days(horizon)}."
    narrative = [
        {"kind": "greeting", "text": f"Hi, I'm BedSense. Here is the bed plan for {where}."},
        {"kind": "score", "text": f"Today about {summ['beds_needed_today']} of {summ['capacity']} beds are needed, "
                                  f"leaving {summ['free_beds_today']} free."},
        {"kind": "comparison", "text": outlook},
        {"kind": "action", "text": f"{summ['high_risk_patients']} patients are at high risk of coming back "
                                   f"and should be followed up closely."},
        {"kind": "closing", "text": "Capacity numbers are settings to adjust to your ward."},
    ]
    return _clean({
        "today": day,
        "service": service,
        "horizon": int(len(plan)),
        "capacity": {"beds": beds, "nurses_per_shift": nurses},
        "safe_band": {
            "level": safety,
            "text": f"The safe plan covers {round(safety * 10)} cases out of 10.",
            "tight_occupancy": float(sim.cfg["hospital"]["tight_occupancy"]),
        },
        "summary": summ,
        "days": _records(days),
        "weeks": _records(weeks),
        "alerts": alerts,
        "narrative": narrative,
        "disclaimer": DISCLAIMER,
    })


def plan(service: Optional[str], horizon: Optional[int]) -> dict:
    sim = simulation()
    h = min(horizon or sim.horizon, sim.horizon)
    return _plan_payload(_today(), service or None, h)


@lru_cache(maxsize=16)
def _followup_frame(day: str, service: Optional[str]) -> pd.DataFrame:
    return P.followup_list(simulation(), service)


def followup(service: Optional[str], top: int) -> dict:
    sim = simulation()
    if service and service not in P.services(sim):
        capalit_api._plan(service, 1)  # raises his 404 with the list of services
    full = _followup_frame(_today(), service or None)
    shown = full.head(top)
    patients = []
    for _, row in shown.iterrows():
        e = P.explain(row)
        patients.append({
            "pid": row["pid"], "where": row["where"], "when": row["when"],
            "discharge_date": row["discharge_date"].isoformat(),
            "age_band": row["age_band"], "gender": row["gender"], "service": row["service"],
            "main_reason": row["main_reason"],
            "probability": round(float(row["risk"]), 3), "percent": round(float(row["risk"]) * 100),
            "level": str(row["level"]).lower(), "stay_likely": int(row["stay_likely"]),
            "stay_text": row["stay_text"], "bed_days": round(float(row["bed_days"]), 2),
            "advice": row["advice"], "headline": e["headline"], "sentence": e["sentence"],
            "stay_sentence": e["stay"], "facts": e["facts"],
            "arrival": admission_label(int(row["admission_type_id"])), "leaving_to": e["leaving_to"],
        })
    counts = full["level"].value_counts()
    return _clean({
        "today": _today(),
        "service": service or None,
        "total": int(len(full)),
        "by_level": {lvl.lower(): int(counts.get(lvl, 0)) for lvl in P.LEVELS},
        "shown": len(patients),
        "patients": patients,
        "disclaimer": DISCLAIMER,
    })


def meta() -> dict:
    cfg = P.load_config()
    disch = {c: P.label("discharge_disposition_id", c) for c in DISCHARGES}
    src = {c: P.label("admission_source_id", c) for c in ADMISSION_SOURCES}
    adm = {c: admission_label(c) for c in ADMISSION_TYPES}
    families = list(DIAG_CODES)

    def choice(default, options, labels=None, help_=""):
        out = {"type": "choice", "default": default, "options": options}
        if labels:
            out["labels"] = {str(k): v for k, v in labels.items()}
        if help_:
            out["help"] = help_
        return out

    def number(default, lo, hi, help_=""):
        return {"type": "number", "default": default, "min": lo, "max": hi, "help": help_}

    fields = {
        "age": choice("[60-70)", AGE_BANDS, {a: f"{a[1:-1]} years" for a in AGE_BANDS}, "Age"),
        "gender": choice("Female", ["Female", "Male"], help_="Sex"),
        "race": choice(None, [None, *RACES], {"None": "Prefer not to say", "AfricanAmerican": "African American"},
                       "Background (optional)"),
        "service": choice("Internal medicine", list(SPECIALTY), help_="Service"),
        "admission_type_id": choice(1, ADMISSION_TYPES, adm, "How they came in"),
        "admission_source_id": choice(7, ADMISSION_SOURCES, src, "Sent by"),
        "discharge_disposition_id": choice(1, DISCHARGES, disch, "Going to"),
        "time_in_hospital": number(4, 1, 14, "Days in hospital this time"),
        "num_medications": number(15, 1, 80, "Medicines given"),
        "num_lab_procedures": number(44, 1, 130, "Lab tests"),
        "num_procedures": number(1, 0, 6, "Procedures (operations, scans...)"),
        "number_diagnoses": number(7, 1, 16, "Health problems written in the file"),
        "diag_1": choice("Heart or blood vessels", families, help_="Main reason for the stay"),
        "diag_2": choice("Diabetes", families, help_="Second health problem"),
        "diag_3": choice("Other", families, help_="Third health problem"),
        "number_inpatient": number(0, 0, 21, "Hospital stays in the past year"),
        "number_emergency": number(0, 0, 76, "Emergency visits in the past year"),
        "number_outpatient": number(0, 0, 42, "Clinic visits in the past year"),
        "A1Cresult": choice("Not measured", list(A1C), help_="Long-term sugar test (HbA1c)"),
        "max_glu_serum": choice("Not measured", list(GLUCOSE), help_="Sugar level test"),
        "insulin": choice("No", list(DOSE), DOSE, "Insulin"),
        "metformin": choice("No", list(DOSE), DOSE, "Metformin"),
        "change": choice("No", ["No", "Yes"], help_="Diabetes medicines changed during the stay?"),
        "diabetesMed": choice("Yes", ["Yes", "No"], help_="Takes diabetes medicines?"),
    }
    return _clean({
        "fields": fields,
        "services": services(),
        "levels": {lvl.lower(): P.ADVICE[lvl] for lvl in P.LEVELS},
        "thresholds": {"medium": P.RISK_THRESHOLDS["Medium"], "high": P.RISK_THRESHOLDS["High"]},
        "config": {
            "total_beds": cfg["hospital"]["total_beds"],
            "patients_per_nurse": cfg["hospital"]["patients_per_nurse"],
            "nurses_on_duty_per_shift": cfg["hospital"]["nurses_on_duty_per_shift"],
            "tight_occupancy": cfg["hospital"]["tight_occupancy"],
            "planned_admissions_per_day": cfg["activity"]["planned_admissions_per_day"],
            "horizon_days": cfg["activity"]["horizon_days"],
            "return_window_days": cfg["returns"]["return_window_days"],
            "safety_level": cfg["returns"]["safety_level"],
            "placeholder_note": "Bed, staffing and admission figures are placeholders until the service sets its own.",
        },
        "model": {
            "name": "BedSense · 30-day return risk and return length of stay",
            "owner": "Najd",
            "dataset": "Diabetes 130-US Hospitals, 1999-2008",
            "return_model": "Model 1: chance of coming back to hospital within 30 days",
            "stay_model": "Model 2: length of the return stay (median with a q10-q90 range)",
            "bed_days": "Expected bed-days = return chance x mean return stay",
        },
        "disclaimer": DISCLAIMER,
    })
