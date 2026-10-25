"""
Raw patient fields -> the exact 38-column frame Teemo's LightGBM was trained on.

The derived columns are rebuilt with the SAME rules as
`00_team_data_preparation.ipynb` (section 3b/3c). If these rules drift from the
notebook, predictions silently change — `scripts/build_teemo_reference.py`
asserts they reproduce the stored test split row-for-row.
"""
from typing import Iterable, Mapping

import pandas as pd

AGE_BRACKETS = [
    "[0-10)", "[10-20)", "[20-30)", "[30-40)", "[40-50)",
    "[50-60)", "[60-70)", "[70-80)", "[80-90)", "[90-100)",
]
AGE_ORDINAL = {b: i for i, b in enumerate(AGE_BRACKETS)}

# The 10 medication columns that survived cleaning (13 near-constant ones were
# dropped). num_med_changes in the notebook counts Up/Down over exactly these.
MED_COLUMNS = [
    "metformin", "repaglinide", "nateglinide", "glimepiride", "glipizide",
    "glyburide", "pioglitazone", "rosiglitazone", "insulin", "glipizide-metformin",
]

NUMERIC_INPUTS = [
    "admission_type_id", "discharge_disposition_id", "admission_source_id",
    "time_in_hospital", "num_lab_procedures", "num_procedures", "num_medications",
    "number_outpatient", "number_emergency", "number_inpatient", "number_diagnoses",
]

CATEGORICAL_INPUTS = [
    "race", "gender", "age", "payer_code", "medical_specialty",
    "max_glu_serum", "A1Cresult", "diabetesMed",
    "diag_1_group", "diag_2_group", "diag_3_group",
]


def add_derived(row: Mapping) -> dict:
    """Return a copy of `row` with the six engineered features added."""
    r = dict(row)
    r["age_ordinal"] = AGE_ORDINAL[r["age"]]
    r["total_prior_visits"] = (
        int(r["number_outpatient"]) + int(r["number_emergency"]) + int(r["number_inpatient"])
    )
    r["num_med_changes"] = sum(1 for m in MED_COLUMNS if r[m] in ("Up", "Down"))
    r["insulin_prescrite"] = int(r["insulin"] != "No")
    r["metformin_prescrite"] = int(r["metformin"] != "No")
    r["insulin_changed"] = int(r["insulin"] in ("Up", "Down"))
    return r


def build_feature_frame(rows: Iterable[Mapping], feature_names, cat_cols) -> pd.DataFrame:
    """Rows of raw fields -> model-ready DataFrame (column order + dtypes)."""
    df = pd.DataFrame([add_derived(r) for r in rows])
    df = df[list(feature_names)].copy()
    for c in cat_cols:
        # LightGBM re-maps pandas categories onto the training categories it
        # stored (booster.pandas_categorical), so a single row is safe here.
        df[c] = df[c].astype(str).astype("category")
    return df
