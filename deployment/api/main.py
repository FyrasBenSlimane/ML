"""
FastAPI backend for ReadmitGuard.
Serves predictions from all trained models via REST endpoints.
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import joblib
import pandas as pd
import numpy as np
from pathlib import Path

app = FastAPI(
    title="ReadmitGuard API",
    description="AI-Powered Diabetes Readmission Prevention Platform",
    version="1.0.0",
)

MODEL_DIR = Path(__file__).resolve().parent.parent / "models"


def load(name):
    model = joblib.load(MODEL_DIR / f"{name}_model.joblib")
    features = joblib.load(MODEL_DIR / f"{name}_features.joblib")
    return model, features


models = {}
for name in ["teemo", "carestep", "medoracle", "rxpredict_change", "rxpredict_insulin",
             "dailyguard_suivi", "dailyguard_compagnon", "dailyguard_rappel"]:
    try:
        models[name] = load(name)
    except Exception as e:
        print(f"Warning: Could not load {name}: {e}")

try:
    models["bedsense_a"] = (
        joblib.load(MODEL_DIR / "bedsense_model_a.joblib"),
        joblib.load(MODEL_DIR / "bedsense_features_a.joblib"),
    )
    models["bedsense_b"] = (
        joblib.load(MODEL_DIR / "bedsense_model_b.joblib"),
        joblib.load(MODEL_DIR / "bedsense_features_b.joblib"),
    )
except Exception as e:
    print(f"Warning: Could not load bedsense: {e}")


class PatientData(BaseModel):
    age_ordinal: int = 6
    gender: str = "Female"
    race: str = "Caucasian"
    time_in_hospital: int = 5
    num_medications: int = 12
    number_diagnoses: int = 6
    total_prior_visits: int = 3
    num_lab_procedures: int = 40
    num_procedures: int = 1
    diag_1_group: str = "Circulatory"
    diag_2_group: str = "Other"
    diag_3_group: str = "Other"
    A1Cresult: str = "Not_Tested"
    max_glu_serum: str = "Not_Tested"
    insulin_prescrite: int = 0
    metformin_prescrite: int = 0
    diabetesMed: str = "Yes"
    num_med_changes: int = 1
    admission_type_id: Optional[int] = 1
    discharge_disposition_id: Optional[int] = 1
    admission_source_id: Optional[int] = 7
    payer_code: Optional[str] = "Missing"
    medical_specialty: Optional[str] = "Unknown"
    number_outpatient: Optional[int] = 1
    number_emergency: Optional[int] = 0
    number_inpatient: Optional[int] = 1
    insulin_changed: Optional[int] = 0


def predict_safe(model_name: str, data: dict):
    if model_name not in models:
        raise HTTPException(status_code=404, detail=f"Model {model_name} not loaded")
    model, features = models[model_name]
    row = pd.DataFrame([data])
    for f in features:
        if f not in row.columns:
            row[f] = 0
    prob = model.predict_proba(row[features])[0][1]
    return float(prob)


@app.get("/")
def root():
    return {
        "name": "ReadmitGuard API",
        "version": "1.0.0",
        "models": list(models.keys()),
        "status": "running",
    }


@app.get("/health")
def health():
    return {"status": "ok", "models_loaded": len(models)}


@app.post("/predict/teemo")
def predict_teemo(patient: PatientData):
    prob = predict_safe("teemo", patient.model_dump())
    level = "HIGH" if prob >= 0.25 else ("MEDIUM" if prob >= 0.14 else "LOW")
    return {
        "model": "teemo",
        "probability": round(prob, 4),
        "percentage": round(prob * 100, 1),
        "level": level,
        "hospital_average": 11.4,
    }


@app.post("/predict/carestep")
def predict_carestep(patient: PatientData):
    prob = predict_safe("carestep", patient.model_dump())
    level = "HIGH" if prob >= 0.25 else ("MEDIUM" if prob >= 0.14 else "LOW")
    return {
        "model": "carestep",
        "probability": round(prob, 4),
        "level": level,
    }


@app.post("/predict/medoracle")
def predict_medoracle(patient: PatientData):
    prob = predict_safe("medoracle", patient.model_dump())
    level = "HIGH" if prob >= 0.25 else ("MEDIUM" if prob >= 0.14 else "LOW")
    return {
        "model": "medoracle",
        "probability": round(prob, 4),
        "level": level,
    }


@app.post("/predict/rxpredict")
def predict_rxpredict(patient: PatientData):
    prob_change = predict_safe("rxpredict_change", patient.model_dump())
    prob_insulin = predict_safe("rxpredict_insulin", patient.model_dump())
    return {
        "model": "rxpredict",
        "treatment_change_probability": round(prob_change, 4),
        "treatment_change_likely": prob_change > 0.5,
        "insulin_need_probability": round(prob_insulin, 4),
        "insulin_need_likely": prob_insulin > 0.5,
    }


@app.post("/predict/dailyguard")
def predict_dailyguard(patient: PatientData):
    data = patient.model_dump()
    results = {}
    for sub in ["suivi", "compagnon", "rappel"]:
        name = f"dailyguard_{sub}"
        if name in models:
            results[sub] = round(predict_safe(name, data), 4)
    return {"model": "dailyguard", "predictions": results}


@app.post("/predict/bedsense")
def predict_bedsense(patient: PatientData):
    data = patient.model_dump()
    result = {}
    if "bedsense_a" in models:
        model_a, feats_a = models["bedsense_a"]
        row = pd.DataFrame([data])
        for f in feats_a:
            if f not in row.columns:
                row[f] = 0
        prob = float(model_a.predict_proba(row[feats_a])[0][1])
        level = "HIGH" if prob >= 0.25 else ("MEDIUM" if prob >= 0.14 else "LOW")
        result["readmission_probability"] = round(prob, 4)
        result["level"] = level

    if "bedsense_b" in models:
        model_b, feats_b = models["bedsense_b"]
        row = pd.DataFrame([data])
        for f in feats_b:
            if f not in row.columns:
                row[f] = 0
        los = float(model_b.predict(row[feats_b])[0])
        result["expected_length_of_stay"] = round(max(los, 1), 1)

    return {"model": "bedsense", **result}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
