"""Validated request shapes for MedOracle's physician-only comparisons."""
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class PatientProfile(BaseModel):
    model_config = ConfigDict(extra="forbid")

    race: Literal[
        "Caucasian",
        "AfricanAmerican",
        "Asian",
        "Hispanic",
        "Other",
        "Unknown",
    ]
    gender: Literal["Female", "Male"]
    age_band: Literal["<40", "40-59", "60-79", "80+"]


class SeverityFeatures(BaseModel):
    model_config = ConfigDict(extra="forbid")

    number_diagnoses: int = Field(ge=1, le=16)
    number_inpatient: int = Field(ge=0, le=20)
    number_emergency: int = Field(ge=0, le=40)
    number_outpatient: int = Field(ge=0, le=40)
    admission_type_id: Literal[1, 2, 3, 4, 5, 6, 7, 8]
    admission_source_id: Literal[1, 2, 3, 4, 5, 6, 7, 8, 9, 17, 20]
    diag_1_group: Literal[
        "Circulatory",
        "Respiratory",
        "Digestive",
        "Diabetes",
        "Injury",
        "Musculoskeletal",
        "Genitourinary",
        "Neoplasms",
        "External",
        "Other",
    ]
    diag_2_group: Literal[
        "Circulatory",
        "Respiratory",
        "Digestive",
        "Diabetes",
        "Injury",
        "Musculoskeletal",
        "Genitourinary",
        "Neoplasms",
        "External",
        "Other",
    ]
    diag_3_group: Literal[
        "Circulatory",
        "Respiratory",
        "Digestive",
        "Diabetes",
        "Injury",
        "Musculoskeletal",
        "Genitourinary",
        "Neoplasms",
        "External",
        "Other",
    ]
    A1Cresult: Literal["Not_Tested", "Norm", ">7", ">8"]
    max_glu_serum: Literal["Not_Tested", "Norm", ">200", ">300"]


class MedOracleRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    severity: SeverityFeatures
    patient_a: PatientProfile
    patient_b: PatientProfile
