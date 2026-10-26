"""BedSense API, mounted at /api/v1/bedsense.

POST /predict      patient check (doctor token + X-Patient-Code, enforced by PredictGuardMiddleware)
GET  /meta         form fields, services, settings          (doctor only)
GET  /plan         ward bed plan, alerts, weekly view        (doctor only)
GET  /followup     patients to follow up, highest risk first (doctor only)
"""
from typing import Literal, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field

from app.core.portal import require_medecin

from . import logic

router = APIRouter()

AgeBand = Literal["[0-10)", "[10-20)", "[20-30)", "[30-40)", "[40-50)", "[50-60)",
                  "[60-70)", "[70-80)", "[80-90)", "[90-100)"]
Family = Literal["Heart or blood vessels", "Lungs or breathing", "Digestion", "Diabetes", "Injury",
                 "Bones or joints", "Kidneys or bladder", "Cancer", "Other"]
Dose = Literal["No", "Steady", "Up", "Down"]


class BedSenseInput(BaseModel):
    """Same inputs as the 'Check a Patient' form; field names follow diabetic_data.csv."""
    age: AgeBand = "[60-70)"
    gender: Literal["Female", "Male"] = "Female"
    race: Optional[Literal["Caucasian", "AfricanAmerican", "Hispanic", "Asian", "Other"]] = None
    service: Literal["Internal medicine", "Emergency", "General practice", "Cardiology", "Surgery",
                     "Kidney care", "Other services"] = "Internal medicine"
    admission_type_id: Literal[1, 2, 3, 7] = 1
    admission_source_id: Literal[7, 1, 2, 4, 6] = 7
    discharge_disposition_id: Literal[1, 6, 3, 22, 2, 7] = 1
    time_in_hospital: int = Field(4, ge=1, le=14)
    num_medications: int = Field(15, ge=1, le=80)
    num_lab_procedures: int = Field(44, ge=1, le=130)
    num_procedures: int = Field(1, ge=0, le=6)
    number_diagnoses: int = Field(7, ge=1, le=16)
    diag_1: Family = "Heart or blood vessels"
    diag_2: Family = "Diabetes"
    diag_3: Family = "Other"
    number_inpatient: int = Field(0, ge=0, le=21)
    number_emergency: int = Field(0, ge=0, le=76)
    number_outpatient: int = Field(0, ge=0, le=42)
    A1Cresult: Literal["Not measured", "Normal", "Above 7", "Above 8"] = "Not measured"
    max_glu_serum: Literal["Not measured", "Normal", "Above 200", "Above 300"] = "Not measured"
    insulin: Dose = "No"
    metformin: Dose = "No"
    change: Literal["No", "Yes"] = "No"
    diabetesMed: Literal["Yes", "No"] = "Yes"


@router.get("/meta", summary="BedSense form fields, services and settings")
def meta(_: object = Depends(require_medecin)):
    return logic.meta()


@router.post("/predict", summary="Return risk within 30 days and return length of stay for one patient")
def predict(body: BedSenseInput, _: object = Depends(require_medecin)):
    try:
        return logic.predict(body.model_dump())
    except logic.P.PatientDataError as exc:
        raise HTTPException(status_code=422, detail=str(exc))


@router.get("/plan", summary="Ward bed plan: daily load vs capacity, safe band, alerts, weekly plan")
def plan(
    service: Optional[str] = None,
    horizon: Optional[int] = Query(None, ge=1, le=90, description="Days ahead (capped by the config horizon)"),
    _: object = Depends(require_medecin),
):
    return logic.plan(service, horizon)


@router.get("/followup", summary="Patients to follow up, highest risk first")
def followup(
    service: Optional[str] = None,
    top: int = Query(20, ge=1, le=200),
    _: object = Depends(require_medecin),
):
    return logic.followup(service, top)
