"""Request / response models for Teemo. Every input field is optional: missing
fields are filled with the training-set mode/median (see reference.json), so a
quick triage with five fields and a full chart review use the same endpoint."""
from typing import List, Literal, Optional

from pydantic import BaseModel, ConfigDict, Field

MedStatus = Literal["No", "Steady", "Up", "Down"]


class TeemoPatient(BaseModel):
    model_config = ConfigDict(populate_by_name=True, extra="forbid")

    # demographics
    age: Optional[str] = Field(None, examples=["[70-80)"])
    gender: Optional[Literal["Female", "Male"]] = None
    race: Optional[str] = None
    # admission
    admission_type_id: Optional[int] = Field(None, ge=1)
    admission_source_id: Optional[int] = Field(None, ge=1)
    discharge_disposition_id: Optional[int] = Field(None, ge=1)
    medical_specialty: Optional[str] = None
    payer_code: Optional[str] = None
    # stay
    time_in_hospital: Optional[int] = Field(None, ge=1, le=14)
    num_lab_procedures: Optional[int] = Field(None, ge=0, le=150)
    num_procedures: Optional[int] = Field(None, ge=0, le=10)
    num_medications: Optional[int] = Field(None, ge=0, le=100)
    number_diagnoses: Optional[int] = Field(None, ge=1, le=16)
    # history (year before admission)
    number_outpatient: Optional[int] = Field(None, ge=0, le=60)
    number_emergency: Optional[int] = Field(None, ge=0, le=60)
    number_inpatient: Optional[int] = Field(None, ge=0, le=30)
    # diagnoses & labs
    diag_1_group: Optional[str] = None
    diag_2_group: Optional[str] = None
    diag_3_group: Optional[str] = None
    A1Cresult: Optional[Literal["Not_Tested", "Norm", ">7", ">8"]] = None
    max_glu_serum: Optional[Literal["Not_Tested", "Norm", ">200", ">300"]] = None
    # medications
    diabetesMed: Optional[Literal["Yes", "No"]] = Field(
        None, description="Derived from the medication fields when omitted.")
    metformin: Optional[MedStatus] = None
    repaglinide: Optional[MedStatus] = None
    nateglinide: Optional[MedStatus] = None
    glimepiride: Optional[MedStatus] = None
    glipizide: Optional[MedStatus] = None
    glyburide: Optional[MedStatus] = None
    pioglitazone: Optional[MedStatus] = None
    rosiglitazone: Optional[MedStatus] = None
    insulin: Optional[MedStatus] = None
    glipizide_metformin: Optional[MedStatus] = Field(None, alias="glipizide-metformin")


class Driver(BaseModel):
    key: str
    title: str
    value: str
    explanation: str
    direction: Literal["up", "down"]
    impact: float
    share: float
    modifiable: bool


class Action(BaseModel):
    icon: str
    title: str
    detail: str
    priority: Literal["high", "medium", "low"]


class Segment(BaseModel):
    kind: str
    text: str


class TeemoResult(BaseModel):
    id: str
    created_at: str
    probability: float
    percentage: float
    level: Literal["LOW", "MODERATE", "HIGH"]
    thresholds: dict
    baseline_rate: float
    relative_risk: float
    percentile: Optional[int]
    band_observed_rate: Optional[float]
    intervention_recommended: bool
    drivers: List[Driver]
    actions: List[Action]
    narrative: List[Segment]
    patient: dict
    defaulted_fields: List[str]
    model: dict
