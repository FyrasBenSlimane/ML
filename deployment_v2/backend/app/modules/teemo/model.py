"""
Teemo's model wrapper: calibrated LightGBM + per-patient explanations.

Pipeline at inference:
    raw fields -> features.build_feature_frame -> LGBM raw score
               -> isotonic calibrator -> calibrated probability

Explanations use LightGBM's native TreeSHAP (`pred_contrib=True`). These are
exact SHAP values in log-odds space of the *uncalibrated* booster. Isotonic
calibration is monotonic, so the direction and ranking of drivers is preserved;
we therefore show drivers as relative strength, never as "percentage points".
"""
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import joblib
import numpy as np

from .features import build_feature_frame

# Risk bands on the CALIBRATED probability.
#   moderate: 8%  = cost-optimal intervention threshold
#             (intervention $300) / (25% prevention x $15,000 readmission)
#   high:    20%  = ~1.8x the 11.3% hospital baseline
LEVEL_THRESHOLDS = {"moderate": 0.08, "high": 0.20}

# Several model columns describe the same clinical idea (e.g. `age` and
# `age_ordinal`). Summing their SHAP values per group gives one readable driver.
FEATURE_GROUPS = {
    "age": "age", "age_ordinal": "age",
    "number_inpatient": "visits", "number_emergency": "visits",
    "number_outpatient": "visits", "total_prior_visits": "visits",
    "insulin": "insulin", "insulin_prescrite": "insulin", "insulin_changed": "insulin",
    "metformin": "metformin", "metformin_prescrite": "metformin",
    "num_med_changes": "med_changes",
    "repaglinide": "other_meds", "nateglinide": "other_meds", "glimepiride": "other_meds",
    "glipizide": "other_meds", "glyburide": "other_meds", "pioglitazone": "other_meds",
    "rosiglitazone": "other_meds", "glipizide-metformin": "other_meds",
    "diag_1_group": "diag_1", "diag_2_group": "diag_2", "diag_3_group": "diag_3",
}


@dataclass
class Prediction:
    probability: float
    level: str
    contributions: dict  # group -> summed SHAP value (log-odds)


class TeemoModel:
    def __init__(self, base, calibrator, feature_names, cat_cols, reference: Optional[dict]):
        self.base = base
        self.calibrator = calibrator
        self.feature_names = list(feature_names)
        self.cat_cols = list(cat_cols)
        self.reference = reference

    @classmethod
    def load(cls, artifact_dir: Path, reference: Optional[dict] = "auto") -> "TeemoModel":
        artifact_dir = Path(artifact_dir)
        if reference == "auto":
            ref_path = artifact_dir / "reference.json"
            reference = json.loads(ref_path.read_text(encoding="utf-8")) if ref_path.exists() else None
        return cls(
            base=joblib.load(artifact_dir / "teemo_full_base.joblib"),
            calibrator=joblib.load(artifact_dir / "teemo_full_calibrator.joblib"),
            feature_names=joblib.load(artifact_dir / "teemo_full_features.joblib"),
            cat_cols=joblib.load(artifact_dir / "teemo_full_catcols.joblib"),
            reference=reference,
        )

    # ------------------------------------------------------------------ core
    def predict_proba_frame(self, X) -> np.ndarray:
        raw = self.base.predict_proba(X)[:, 1]
        return np.clip(self.calibrator.predict(raw), 0.0, 1.0)

    @staticmethod
    def level_for(p: float) -> str:
        if p >= LEVEL_THRESHOLDS["high"]:
            return "HIGH"
        if p >= LEVEL_THRESHOLDS["moderate"]:
            return "MODERATE"
        return "LOW"

    def predict(self, raw_patient: dict) -> Prediction:
        X = build_feature_frame([raw_patient], self.feature_names, self.cat_cols)
        p = float(self.predict_proba_frame(X)[0])
        # Last column of pred_contrib is the expected value (bias) — drop it.
        contrib = self.base.predict(X, pred_contrib=True)[0][:-1]
        groups: dict = {}
        for name, value in zip(self.feature_names, contrib):
            g = FEATURE_GROUPS.get(name, name)
            groups[g] = groups.get(g, 0.0) + float(value)
        return Prediction(probability=p, level=self.level_for(p), contributions=groups)

    # ------------------------------------------------------------- reference
    def percentile(self, p: float) -> Optional[int]:
        """Share (0-100) of test patients with a LOWER predicted risk."""
        if not self.reference:
            return None
        qs = np.asarray(self.reference["percentiles"])
        return int(np.clip(np.searchsorted(qs, p, side="left") - 1, 0, 100))
