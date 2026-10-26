"""Rebuild MedOracle's severity models using the deployment dependency versions."""
import argparse
import hashlib
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from lightgbm import LGBMRegressor
from sklearn.compose import ColumnTransformer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from xgboost import XGBRegressor

ARTIFACTS = Path(__file__).resolve().parents[1] / "artifacts" / "medoracle"

NUMERIC = [
    "number_diagnoses",
    "number_inpatient",
    "number_emergency",
    "number_outpatient",
]
CATEGORICAL = [
    "admission_type_id",
    "admission_source_id",
    "diag_1_group",
    "diag_2_group",
    "diag_3_group",
    "A1Cresult",
    "max_glu_serum",
]
FEATURES = NUMERIC + CATEGORICAL
TARGETS = ("time_in_hospital", "num_procedures")


def _json_scalar(value):
    return value.item() if isinstance(value, np.generic) else value


def _pipeline(target: str) -> Pipeline:
    prep = ColumnTransformer(
        [
            ("num", StandardScaler(), NUMERIC),
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), CATEGORICAL),
        ]
    )
    if target == "time_in_hospital":
        model = LGBMRegressor(
            n_estimators=300,
            num_leaves=7,
            learning_rate=0.1,
            subsample=0.7,
            subsample_freq=1,
            reg_lambda=1,
            random_state=42,
            n_jobs=-1,
            verbose=-1,
        )
    else:
        model = XGBRegressor(
            objective="reg:squarederror",
            n_estimators=400,
            learning_rate=0.02,
            max_depth=6,
            colsample_bytree=0.8,
            min_child_weight=20,
            reg_lambda=10,
            subsample=0.8,
            tree_method="hist",
            random_state=42,
            n_jobs=-1,
        )
    return Pipeline([("prep", prep), ("model", model)])


def _model_frame(frame: pd.DataFrame) -> pd.DataFrame:
    result = frame[FEATURES].copy()
    result[CATEGORICAL] = result[CATEGORICAL].astype(str)
    return result


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--data-dir",
        type=Path,
        required=True,
        help="Directory containing train_with_sensitive.parquet and test_with_sensitive.parquet",
    )
    data_dir = parser.parse_args().data_dir
    train_path = data_dir / "train_with_sensitive.parquet"
    test_path = data_dir / "test_with_sensitive.parquet"
    for path in (train_path, test_path):
        if not path.is_file():
            raise FileNotFoundError(f"Required MedOracle split is missing: {path}")

    train = pd.read_parquet(train_path)
    test = pd.read_parquet(test_path)
    required = set(FEATURES) | set(TARGETS)
    for label, frame in (("training", train), ("test", test)):
        missing = sorted(required - set(frame.columns))
        if missing:
            raise ValueError(f"{label} split is missing columns: {missing}")

    models = {}
    for target in TARGETS:
        estimator = _pipeline(target)
        estimator.fit(_model_frame(train), train[target])
        prediction = estimator.predict(_model_frame(test))
        models[target] = estimator
        print(
            f"{target}: RMSE={mean_squared_error(test[target], prediction) ** 0.5:.4f}, "
            f"MAE={mean_absolute_error(test[target], prediction):.4f}, "
            f"R2={r2_score(test[target], prediction):.4f}"
        )

    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    joblib.dump(models, ARTIFACTS / "severity_models.joblib")

    defaults = {
        column: int(round(train[column].median()))
        for column in NUMERIC
    }
    defaults.update({
        column: _json_scalar(train[column].mode(dropna=True).iloc[0])
        for column in CATEGORICAL
    })
    options = {
        column: [_json_scalar(value) for value in sorted(train[column].dropna().unique(), key=str)]
        for column in CATEGORICAL
    }
    metrics = {}
    for target, estimator in models.items():
        prediction = estimator.predict(_model_frame(test))
        metrics[target] = {
            "rmse": float(mean_squared_error(test[target], prediction) ** 0.5),
            "mae": float(mean_absolute_error(test[target], prediction)),
            "r2": float(r2_score(test[target], prediction)),
        }
    (ARTIFACTS / "model_metadata.json").write_text(
        json.dumps(
            {
                "features": FEATURES,
                "numeric_features": NUMERIC,
                "categorical_features": CATEGORICAL,
                "defaults": defaults,
                "options": options,
                "metrics": metrics,
                "training_rows": int(len(train)),
                "test_rows": int(len(test)),
                "split_sha256": {
                    "train": _sha256(train_path),
                    "test": _sha256(test_path),
                },
                "sklearn_version": __import__("sklearn").__version__,
                "lightgbm_version": __import__("lightgbm").__version__,
                "xgboost_version": __import__("xgboost").__version__,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
