"""HTTP endpoints for Teemo — mounted at /api/v1/teemo by the module registry."""
import uuid
from datetime import datetime, timezone
from functools import lru_cache

from fastapi import APIRouter, HTTPException

from app.core.config import ARTIFACTS_DIR
from . import labels as L
from .explain import build_actions, build_drivers, build_narrative
from .features import CATEGORICAL_INPUTS, MED_COLUMNS, NUMERIC_INPUTS
from .model import LEVEL_THRESHOLDS, TeemoModel
from .schemas import TeemoPatient, TeemoResult

router = APIRouter()

MODEL_INFO = {
    "name": "Teemo · calibrated LightGBM",
    "version": "2.0.0",
    "algorithm": "LightGBM (500 trees, depth 6) + isotonic calibration",
    "target": "Readmission within 30 days (UCI Diabetes 130-US hospitals, 1999–2008)",
    "split": "GroupShuffleSplit by patient — no patient appears in both train and test",
    "explanations": "TreeSHAP (LightGBM pred_contrib), grouped into clinical concepts",
}


@lru_cache(maxsize=1)
def get_model() -> TeemoModel:
    model = TeemoModel.load(ARTIFACTS_DIR / "teemo")
    if model.reference is None:
        raise RuntimeError("artifacts/teemo/reference.json missing — run "
                           "`python scripts/build_teemo_reference.py`")
    return model


def fill_defaults(patient: TeemoPatient, ref: dict):
    """Complete a partial patient with training defaults; validate categories."""
    given = patient.model_dump(by_alias=True, exclude_none=True)
    row, defaulted = {}, []
    for field in NUMERIC_INPUTS + CATEGORICAL_INPUTS + MED_COLUMNS:
        if field in given:
            row[field] = given[field]
        elif field == "diabetesMed":
            continue  # derived below, once the medications are known
        else:
            row[field] = ref["defaults"][field]
            defaulted.append(field)
    if "diabetesMed" not in row:
        row["diabetesMed"] = "Yes" if any(row[m] != "No" for m in MED_COLUMNS) else "No"
        defaulted.append("diabetesMed")

    # Only categories seen in training are meaningful to the model.
    for field in CATEGORICAL_INPUTS + ["admission_type_id", "discharge_disposition_id",
                                       "admission_source_id"]:
        allowed = ref["options"].get(field)
        if isinstance(allowed, list) and row[field] not in allowed:
            raise HTTPException(422, detail=f"'{row[field]}' is not a known value for {field}. "
                                            f"Allowed: {allowed}")
    return row, defaulted


@router.get("/meta", summary="Form options, defaults, model card and sample patients")
def meta():
    m = get_model()
    ref = m.reference
    fields = {}
    for field, opts in ref["options"].items():
        if isinstance(opts, dict):
            fields[field] = {"type": "number", **opts, "default": ref["defaults"][field]}
        else:
            fields[field] = {"type": "choice", "options": L.options_with_labels(field, opts),
                             "default": ref["defaults"][field]}
    return {
        "fields": fields,
        "model": {**MODEL_INFO, "metrics": ref["metrics"]},
        "thresholds": ref["thresholds"],
        "bands": ref["bands"],
        "samples": ref["samples"],
    }


@router.post("/predict", response_model=TeemoResult,
             summary="Predict 30-day readmission risk and explain it")
def predict(patient: TeemoPatient):
    m = get_model()
    ref = m.reference
    row, defaulted = fill_defaults(patient, ref)
    pred = m.predict(row)

    baseline = ref["metrics"]["baseline_rate"]
    percentile = m.percentile(pred.probability)
    band_rate = ref["bands"][pred.level]["observed_rate"]
    drivers = build_drivers(pred.contributions, row)
    actions = build_actions(pred.level, drivers, row)
    narrative = build_narrative(pred.probability, pred.level, baseline, percentile,
                                drivers, actions, band_rate)
    return {
        "id": uuid.uuid4().hex[:12],
        "created_at": datetime.now(timezone.utc).isoformat(),
        "probability": round(pred.probability, 4),
        "percentage": round(pred.probability * 100, 1),
        "level": pred.level,
        "thresholds": LEVEL_THRESHOLDS,
        "baseline_rate": baseline,
        "relative_risk": round(pred.probability / baseline, 2),
        "percentile": percentile,
        "band_observed_rate": band_rate,
        "intervention_recommended": pred.probability >= LEVEL_THRESHOLDS["moderate"],
        "drivers": drivers,
        "actions": actions,
        "narrative": narrative,
        "patient": row,
        "defaulted_fields": defaulted,
        "model": {**MODEL_INFO, "metrics": ref["metrics"]},
    }
