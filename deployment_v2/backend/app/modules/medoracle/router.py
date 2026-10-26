"""MedOracle equity comparison API, mounted at /api/v1/medoracle."""
import csv
import json
from functools import lru_cache

import joblib
import numpy as np
import pandas as pd
from fastapi import APIRouter, Depends

from app.core.config import ARTIFACTS_DIR
from app.core.portal import require_medecin

from .schemas import MedOracleRequest

router = APIRouter()
ARTIFACT_DIR = ARTIFACTS_DIR / "medoracle"

MODEL_INFO = {
    "name": "MedOracle · care equity comparison",
    "version": "1.0.0",
    "dataset": "Diabetes 130-US Hospitals, US facilities, 1999–2008",
    "target": "Average observed gaps in length of stay and number of procedures",
    "method": "Regression adjusted for clinical severity; LightGBM and XGBoost estimate the average context.",
    "limitations": (
        "Retrospective group analysis, not an individual prediction or a recommendation. "
        "The historical US data does not necessarily describe current practices. "
        "An association does not prove a cause or a care fault."
    ),
}

TARGETS = {
    "time_in_hospital": {
        "label": "Length of stay",
        "singular": "day",
        "plural": "days",
        "floor": 1,
    },
    "num_procedures": {
        "label": "Number of procedures",
        "singular": "procedure",
        "plural": "procedures",
        "floor": 0,
    },
}
REFERENCES = {"race": "Caucasian", "gender": "Female", "age_band": "60-79"}


@lru_cache(maxsize=1)
def _artifacts() -> tuple[dict, dict, dict, dict]:
    required = (
        ARTIFACT_DIR / "severity_models.joblib",
        ARTIFACT_DIR / "model_metadata.json",
        ARTIFACT_DIR / "ols_coefficients.csv",
        ARTIFACT_DIR / "residual_quantiles.json",
    )
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"MedOracle model artifacts are missing: {', '.join(missing)}")

    models = joblib.load(required[0])
    metadata = json.loads(required[1].read_text(encoding="utf-8"))
    with required[2].open(encoding="utf-8-sig", newline="") as file:
        coefficients = {
            (row["cible"], row["variable"], row["niveau"]): row
            for row in csv.DictReader(file)
        }
    residuals = json.loads(required[3].read_text(encoding="utf-8"))
    return models, metadata, coefficients, residuals


@router.get("/meta", summary="Options, modèle et performances MedOracle")
def meta(_: object = Depends(require_medecin)):
    _, metadata, _, _ = _artifacts()
    return {
        "model": {**MODEL_INFO, "metrics": metadata["metrics"]},
        "rows": {"training": metadata["training_rows"], "test": metadata["test_rows"]},
        "features": metadata["features"],
        "fields": {
            **{
                field: {
                    "type": "number",
                    "default": value,
                }
                for field, value in metadata["defaults"].items()
                if field in metadata["numeric_features"]
            },
            **{
                field: {
                    "type": "choice",
                    "default": metadata["defaults"][field],
                    "options": metadata["options"][field],
                }
                for field in metadata["categorical_features"]
            },
        },
    }


def _coefficient(coefficients: dict, target: str, variable: str, level: str) -> tuple[float, float]:
    if level == REFERENCES[variable]:
        return 0.0, 0.0
    row = coefficients.get((target, variable, level))
    if row is None:
        raise ValueError(f"No adjusted coefficient for {target}/{variable}/{level}")
    estimate = float(row["coef A"])
    standard_error = (float(row["IC95 haut A"]) - float(row["IC95 bas A"])) / (2 * 1.96)
    return estimate, standard_error


def _comparison(target: str, profiles: dict, expected: float, coefficients: dict, residuals: dict) -> dict:
    total = 0.0
    variance = 0.0
    parts = []
    for variable in REFERENCES:
        level_a = profiles["patient_a"][variable]
        level_b = profiles["patient_b"][variable]
        estimate_a, error_a = _coefficient(coefficients, target, variable, level_a)
        estimate_b, error_b = _coefficient(coefficients, target, variable, level_b)
        difference = estimate_b - estimate_a
        standard_error = float(np.hypot(error_a, error_b))
        total += difference
        variance += standard_error**2
        if level_a != level_b:
            parts.append(
                {
                    "variable": variable,
                    "difference": round(difference, 2),
                    "ci_low": round(difference - 1.96 * standard_error, 2),
                    "ci_high": round(difference + 1.96 * standard_error, 2),
                    "detectable": abs(difference) > 1.96 * standard_error,
                }
            )

    standard_error_total = float(np.sqrt(variance))
    ci_low = total - 1.96 * standard_error_total
    ci_high = total + 1.96 * standard_error_total
    floor = TARGETS[target]["floor"]
    range_low, range_high = residuals[target]
    return {
        "label": TARGETS[target]["label"],
        "unit": TARGETS[target]["singular"] if abs(total) < 1.5 else TARGETS[target]["plural"],
        "difference": round(total, 2),
        "ci_low": round(ci_low, 2),
        "ci_high": round(ci_high, 2),
        "detectable": ci_low > 0 or ci_high < 0,
        "expected": round(max(floor, expected), 2),
        "expected_range_low": max(floor, round(expected + range_low)),
        "expected_range_high": max(floor, round(expected + range_high)),
        "percent_of_expected": round(100 * total / max(floor, expected), 1),
        "parts": parts,
    }


@router.post("/predict", summary="Comparer les écarts de soins moyens entre profils")
def predict(body: MedOracleRequest, _: object = Depends(require_medecin)):
    models, metadata, coefficients, residuals = _artifacts()
    severity = body.severity.model_dump()
    frame = pd.DataFrame(
        [{field: severity[field] for field in metadata["features"]}],
        columns=metadata["features"],
    )
    frame[metadata["categorical_features"]] = frame[
        metadata["categorical_features"]
    ].astype(str)
    profiles = {
        "patient_a": body.patient_a.model_dump(),
        "patient_b": body.patient_b.model_dump(),
    }

    comparisons = {}
    for target, model in models.items():
        prediction = float(model.predict(frame)[0])
        comparisons[target] = _comparison(
            target, profiles, prediction, coefficients, residuals
        )

    return {
        "comparisons": comparisons,
        "profiles": profiles,
        "model": {**MODEL_INFO, "metrics": metadata["metrics"]},
        "disclaimer": MODEL_INFO["limitations"],
    }
