# -*- coding: utf-8 -*-
"""CareStep endpoints — mounted at /api/v1/carestep by the module registry."""
from typing import Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from . import logic

router = APIRouter()

R = logic.RANGES

MODEL_INFO = {
    "name": "CareStep · calibrated LightGBM",
    "owner": "Fyras",
    "algorithm": "LightGBM wrapped in CalibratedClassifierCV (isotonic)",
    "target": "Readmission within 30 days (UCI Diabetes 130-US hospitals, 1999–2008)",
    "inputs": "12 patient-reported answers -> 23 one-hot features (no lab codes)",
    "explanations": "Rule-based reasons and actions (no SHAP)",
}


class CareStepAnswers(BaseModel):
    """The 12 patient-friendly answers of the CareStep form (defaults = the page's defaults)."""
    age: int = Field(6, ge=0, le=9, description="Age range index: 6 = 60-70")
    gender: Literal["Female", "Male"] = "Female"
    time_hosp: int = Field(R["time_hosp"][2], ge=R["time_hosp"][0], le=R["time_hosp"][1])
    discharge: Literal["home", "home_with_help", "facility"] = "home"
    num_meds: int = Field(R["num_meds"][2], ge=R["num_meds"][0], le=R["num_meds"][1])
    insulin: Literal["No", "Steady", "Up", "Down"] = "No"
    med_change: Literal["Yes", "No"] = "Yes"
    a1c_tested: Literal["No", "Yes"] = "No"
    diag_group: Literal["circulatory", "respiratory", "digestive", "diabetes",
                        "injury", "infection_renal", "other"] = "circulatory"
    inpatient: int = Field(R["inpatient"][2], ge=R["inpatient"][0], le=R["inpatient"][1])
    emergency: int = Field(R["emergency"][2], ge=R["emergency"][0], le=R["emergency"][1])
    outpatient_raw: int = Field(R["outpatient_raw"][2], ge=R["outpatient_raw"][0],
                                le=R["outpatient_raw"][1])


def _choice(label, options, default):
    return {"label": label, "type": "choice", "default": default,
            "options": [{"value": k, "label": v} for k, v in options.items()]}


def _slider(label, key, help_=None):
    lo, hi, d = R[key]
    f = {"label": label, "type": "int", "min": lo, "max": hi, "default": d}
    if help_:
        f["help"] = help_
    return f


@router.get("/meta", summary="CareStep form fields and model info")
def meta():
    return {
        "model": {**MODEL_INFO, "available": logic.model_available()},
        "thresholds": {"medium": logic.LOW_MAX, "high": logic.MEDIUM_MAX,
                       "levels": ["LOW", "MEDIUM", "HIGH"]},
        "hospital_average_percent": logic.HOSPITAL_AVERAGE_PCT,
        "fields": {
            "age": {"label": "Your age range", "type": "choice", "default": 6,
                    "options": [{"value": k, "label": v} for k, v in logic.AGE_RANGES.items()]},
            "gender": _choice("Gender", logic.GENDERS, "Female"),
            "time_hosp": _slider("Days spent in hospital this stay", "time_hosp"),
            "discharge": _choice("Where are you going after discharge?",
                                 logic.DISCHARGE_OPTIONS, "home"),
            "num_meds": _slider("Total medications you take", "num_meds"),
            "insulin": _choice("Insulin status", logic.INSULIN_OPTIONS, "No"),
            "med_change": _choice("Were medications changed this stay?",
                                  logic.MED_CHANGE_OPTIONS, "Yes"),
            "a1c_tested": _choice("Was HbA1c tested this stay?", logic.A1C_OPTIONS, "No"),
            "diag_group": _choice("Main reason for this hospital visit",
                                  logic.DIAG_GROUPS, "circulatory"),
            "inpatient": _slider("Hospital stays in the past year", "inpatient",
                                 "How many times you were admitted as an inpatient"),
            "emergency": _slider("ER visits in the past year", "emergency",
                                 "How many times you went to the emergency room"),
            "outpatient_raw": _slider("Outpatient visits in the past year", "outpatient_raw",
                                      "Clinic or doctor visits (not ER or hospital stays)"),
        },
    }


@router.post("/predict", summary="30-day readmission risk, reasons, actions and recovery plan")
def predict(answers: CareStepAnswers):
    if not logic.model_available():
        raise HTTPException(
            status_code=503,
            detail="CareStep model unavailable: check artifacts/carestep/ "
                   "(carestep_model.joblib and carestep_features.joblib).",
        )
    try:
        return logic.assess(answers.model_dump())
    except Exception as e:  # pragma: no cover - unexpected prediction error
        raise HTTPException(status_code=500, detail=f"Prediction error: {e}")
