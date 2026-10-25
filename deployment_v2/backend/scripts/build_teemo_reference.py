"""
Build `artifacts/teemo/reference.json` — everything the Teemo API needs at
runtime that comes from the data, so the server never touches the raw splits.

What it computes (all from the GroupShuffle readmission split, no leakage):
  * defaults   — training mode (categorical) / median (numeric) for every raw
                 input field, so a client can send a partial patient.
  * options    — the categories the model actually saw during training
                 (an unseen category would silently fall into LightGBM's
                 "missing" branch, so we only ever offer seen ones).
  * metrics    — honest test-set ROC-AUC / PR-AUC / Brier of the calibrated model.
  * bands      — share of test patients and OBSERVED readmission rate in each
                 risk band. This is what lets Teemo say "patients rated HIGH
                 were actually readmitted 24% of the time" — a calibrated claim.
  * percentiles— 101 quantiles of test predictions, to place a new patient
                 ("higher than 85% of patients").
  * samples    — three real (anonymous) test patients: low / moderate / high.

Run from the backend folder:
    python scripts/build_teemo_reference.py
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.metrics import average_precision_score, brier_score_loss, roc_auc_score

BACKEND = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND))

from app.modules.teemo.features import (  # noqa: E402
    CATEGORICAL_INPUTS, MED_COLUMNS, NUMERIC_INPUTS, build_feature_frame,
)
from app.modules.teemo.model import TeemoModel, LEVEL_THRESHOLDS  # noqa: E402

SPLIT_DIR = BACKEND.parents[1] / "data" / "splits" / "readmission"
OUT = BACKEND / "artifacts" / "teemo" / "reference.json"

RAW_FIELDS = NUMERIC_INPUTS + CATEGORICAL_INPUTS + MED_COLUMNS


def to_py(v):
    """numpy scalar -> plain python, for JSON."""
    if isinstance(v, (np.integer,)):
        return int(v)
    if isinstance(v, (np.floating,)):
        return float(v)
    return v


def main():
    X_train = pd.read_parquet(SPLIT_DIR / "X_train.parquet")
    X_test = pd.read_parquet(SPLIT_DIR / "X_test.parquet")
    y_test = pd.read_parquet(SPLIT_DIR / "y_test.parquet").squeeze().to_numpy()

    # ---- defaults & options (training data only) -------------------------
    defaults, options = {}, {}
    for col in NUMERIC_INPUTS:
        defaults[col] = int(round(float(X_train[col].median())))
        options[col] = {"min": int(X_train[col].min()), "max": int(X_train[col].max())}
    for col in CATEGORICAL_INPUTS + MED_COLUMNS:
        counts = X_train[col].astype(str).value_counts()
        defaults[col] = counts.index[0]
        options[col] = [str(c) for c in counts.index]
    # These ids are numeric in the model but categorical in meaning.
    for col in ["admission_type_id", "discharge_disposition_id", "admission_source_id"]:
        counts = X_train[col].value_counts()
        defaults[col] = int(counts.index[0])
        options[col] = [int(c) for c in counts.index]

    # ---- predictions on the held-out test set ----------------------------
    model = TeemoModel.load(BACKEND / "artifacts" / "teemo", reference=None)
    # Rebuild features from the raw columns through the SAME code path the API
    # uses — this doubles as a regression test of the feature builder.
    raw_rows = X_test[RAW_FIELDS].to_dict(orient="records")
    rebuilt = build_feature_frame(raw_rows, model.feature_names, model.cat_cols)
    original = X_test[model.feature_names]
    for col in ["age_ordinal", "total_prior_visits", "num_med_changes",
                "insulin_prescrite", "metformin_prescrite", "insulin_changed"]:
        mismatch = int((rebuilt[col].to_numpy() != original[col].to_numpy()).sum())
        assert mismatch == 0, f"derived feature {col} differs on {mismatch} rows"
    p = model.predict_proba_frame(rebuilt)

    metrics = {
        "roc_auc": round(float(roc_auc_score(y_test, p)), 4),
        "pr_auc": round(float(average_precision_score(y_test, p)), 4),
        "brier": round(float(brier_score_loss(y_test, p)), 4),
        "baseline_rate": round(float(y_test.mean()), 4),
        "n_test": int(len(y_test)),
        "n_train": int(len(X_train)),
        "n_features": len(model.feature_names),
    }
    metrics["pr_lift"] = round(metrics["pr_auc"] / metrics["baseline_rate"], 2)

    bands = {}
    lo, hi = LEVEL_THRESHOLDS["moderate"], LEVEL_THRESHOLDS["high"]
    for name, mask in [("LOW", p < lo), ("MODERATE", (p >= lo) & (p < hi)), ("HIGH", p >= hi)]:
        bands[name] = {
            "share": round(float(mask.mean()), 4),
            "observed_rate": round(float(y_test[mask].mean()), 4) if mask.any() else None,
            "n": int(mask.sum()),
        }

    percentiles = [round(float(q), 5) for q in np.quantile(p, np.linspace(0, 1, 101))]

    # ---- three demo patients near typical low / moderate / high scores ----
    rng = np.random.default_rng(42)
    samples = []
    for label, target in [("Low risk example", 0.04), ("Moderate risk example", 0.13),
                          ("High risk example", 0.38)]:
        near = np.argsort(np.abs(p - target))[:40]
        idx = int(rng.choice(near))
        row = {k: to_py(v) for k, v in X_test.iloc[idx][RAW_FIELDS].items()}
        samples.append({"label": label, "expected_probability": round(float(p[idx]), 4),
                        "patient": row})

    ref = {
        "defaults": defaults,
        "options": options,
        "metrics": metrics,
        "thresholds": LEVEL_THRESHOLDS,
        "bands": bands,
        "percentiles": percentiles,
        "samples": samples,
    }
    OUT.write_text(json.dumps(ref, indent=2, default=to_py), encoding="utf-8")
    print(json.dumps({"metrics": metrics, "bands": bands}, indent=2))
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
