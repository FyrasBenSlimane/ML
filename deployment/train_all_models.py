"""
Train all 11 models for the ReadmitGuard deployment.
Each model is trained, validated, and saved as a joblib pipeline.
"""
import sys, os, warnings
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd
import joblib
from pathlib import Path

from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder, OrdinalEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import (
    RandomForestClassifier, GradientBoostingClassifier,
    HistGradientBoostingClassifier, HistGradientBoostingRegressor
)
from sklearn.tree import DecisionTreeClassifier
from sklearn.calibration import CalibratedClassifierCV
from sklearn.metrics import (
    roc_auc_score, average_precision_score, brier_score_loss,
    classification_report, mean_absolute_error, r2_score
)

import lightgbm as lgb
import xgboost as xgb

SEED = 42
np.random.seed(SEED)

DATA_DIR = Path(__file__).resolve().parent.parent / "data" / "splits"
MODEL_DIR = Path(__file__).resolve().parent / "models"
MODEL_DIR.mkdir(exist_ok=True)

def load_split(name):
    d = DATA_DIR / name
    X_train = pd.read_parquet(d / "X_train.parquet")
    X_test = pd.read_parquet(d / "X_test.parquet")
    y_train = pd.read_parquet(d / "y_train.parquet").squeeze()
    y_test = pd.read_parquet(d / "y_test.parquet").squeeze()
    features = pd.read_csv(d / "features.csv")["feature"].tolist()
    return X_train, X_test, y_train, y_test, features

def get_col_types(df, features):
    num = [c for c in features if c in df.columns and df[c].dtype in ('int64','float64','int32','float32')]
    cat = [c for c in features if c in df.columns and df[c].dtype == 'object']
    return num, cat

def make_preprocessor(X_train, features, mode="scale"):
    num, cat = get_col_types(X_train, features)
    if mode == "scale":
        return ColumnTransformer([
            ("num", StandardScaler(), num),
            ("cat", OneHotEncoder(handle_unknown="ignore", sparse_output=False), cat)
        ], remainder="drop"), num, cat
    else:
        return ColumnTransformer([
            ("num", "passthrough", num),
            ("cat", OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1), cat)
        ], remainder="drop"), num, cat

def evaluate_clf(name, model, X_test, y_test):
    y_prob = model.predict_proba(X_test)[:, 1]
    y_pred = model.predict(X_test)
    roc = roc_auc_score(y_test, y_prob)
    pr = average_precision_score(y_test, y_prob)
    brier = brier_score_loss(y_test, y_prob)
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")
    print(f"  ROC-AUC:  {roc:.4f}")
    print(f"  PR-AUC:   {pr:.4f}")
    print(f"  Brier:    {brier:.4f}")
    print(f"  Baseline: {y_test.mean():.4f}")
    print(f"  PR lift:  {pr/y_test.mean():.2f}x")
    print(classification_report(y_test, y_pred, zero_division=0))
    return {"roc_auc": roc, "pr_auc": pr, "brier": brier}


# ============================================================
# 1. TEEMO — Ryma's patient-friendly readmission model
# ============================================================
print("\n" + "#"*60)
print("# TRAINING TEEMO (Ryma) — Patient-friendly readmission")
print("#"*60)

X_tr, X_te, y_tr, y_te, feats = load_split("patient_friendly")
prep, num, cat = make_preprocessor(X_tr, feats)

teemo_pipe = Pipeline([
    ("prep", prep),
    ("clf", lgb.LGBMClassifier(
        n_estimators=500, max_depth=6, learning_rate=0.05,
        class_weight="balanced", random_state=SEED, verbose=-1,
        num_leaves=31, min_child_samples=50, subsample=0.8, colsample_bytree=0.8
    ))
])
teemo_pipe.fit(X_tr, y_tr)
teemo_metrics = evaluate_clf("TEEMO (Patient-Friendly LightGBM)", teemo_pipe, X_te, y_te)

calibrated_teemo = CalibratedClassifierCV(teemo_pipe, cv=3, method="isotonic")
calibrated_teemo.fit(X_tr, y_tr)
evaluate_clf("TEEMO Calibrated", calibrated_teemo, X_te, y_te)

joblib.dump(calibrated_teemo, MODEL_DIR / "teemo_model.joblib")
joblib.dump(feats, MODEL_DIR / "teemo_features.joblib")
print("Saved: teemo_model.joblib")


# ============================================================
# 2. CARESTEP — Fyras's CareStep (same data, different model)
# ============================================================
print("\n" + "#"*60)
print("# TRAINING CARESTEP (Fyras) — Recovery companion")
print("#"*60)

prep2, _, _ = make_preprocessor(X_tr, feats)
carestep_pipe = Pipeline([
    ("prep", prep2),
    ("clf", xgb.XGBClassifier(
        n_estimators=500, max_depth=5, learning_rate=0.05,
        scale_pos_weight=(y_tr==0).sum()/(y_tr==1).sum(),
        random_state=SEED, eval_metric="aucpr", verbosity=0,
        subsample=0.8, colsample_bytree=0.8
    ))
])
carestep_pipe.fit(X_tr, y_tr)
evaluate_clf("CARESTEP (XGBoost)", carestep_pipe, X_te, y_te)

calibrated_cs = CalibratedClassifierCV(carestep_pipe, cv=3, method="isotonic")
calibrated_cs.fit(X_tr, y_tr)
evaluate_clf("CARESTEP Calibrated", calibrated_cs, X_te, y_te)

joblib.dump(calibrated_cs, MODEL_DIR / "carestep_model.joblib")
joblib.dump(feats, MODEL_DIR / "carestep_features.joblib")
print("Saved: carestep_model.joblib")


# ============================================================
# 3. MEDORACLE — Faycel's full readmission model
# ============================================================
print("\n" + "#"*60)
print("# TRAINING MEDORACLE (Faycel) — Full readmission model")
print("#"*60)

X_tr_f, X_te_f, y_tr_f, y_te_f, feats_f = load_split("readmission")
prep3, _, _ = make_preprocessor(X_tr_f, feats_f)

medoracle_pipe = Pipeline([
    ("prep", prep3),
    ("clf", xgb.XGBClassifier(
        n_estimators=600, max_depth=6, learning_rate=0.03,
        scale_pos_weight=(y_tr_f==0).sum()/(y_tr_f==1).sum(),
        random_state=SEED, eval_metric="aucpr", verbosity=0,
        subsample=0.8, colsample_bytree=0.7, reg_alpha=0.1, reg_lambda=1.0
    ))
])
medoracle_pipe.fit(X_tr_f, y_tr_f)
evaluate_clf("MEDORACLE (Full XGBoost)", medoracle_pipe, X_te_f, y_te_f)

calibrated_mo = CalibratedClassifierCV(medoracle_pipe, cv=3, method="isotonic")
calibrated_mo.fit(X_tr_f, y_tr_f)
evaluate_clf("MEDORACLE Calibrated", calibrated_mo, X_te_f, y_te_f)

joblib.dump(calibrated_mo, MODEL_DIR / "medoracle_model.joblib")
joblib.dump(feats_f, MODEL_DIR / "medoracle_features.joblib")
print("Saved: medoracle_model.joblib")


# ============================================================
# 4. RXPREDICT — Emna's treatment change + insulin models
# ============================================================
print("\n" + "#"*60)
print("# TRAINING RXPREDICT (Emna) — Treatment predictions")
print("#"*60)

# Model 4a: Treatment change
X_tc_tr, X_tc_te, y_tc_tr, y_tc_te, feats_tc = load_split("treatment_change")
prep4a, _, _ = make_preprocessor(X_tc_tr, feats_tc, mode="tree")

rxp_change_pipe = Pipeline([
    ("prep", prep4a),
    ("clf", DecisionTreeClassifier(
        max_depth=8, min_samples_leaf=50,
        class_weight="balanced", random_state=SEED
    ))
])
rxp_change_pipe.fit(X_tc_tr, y_tc_tr)
evaluate_clf("RXPREDICT Change (DecisionTree)", rxp_change_pipe, X_tc_te, y_tc_te)

joblib.dump(rxp_change_pipe, MODEL_DIR / "rxpredict_change_model.joblib")
joblib.dump(feats_tc, MODEL_DIR / "rxpredict_change_features.joblib")
print("Saved: rxpredict_change_model.joblib")

# Model 4b: Insulin need
X_ti_tr, X_ti_te, y_ti_tr, y_ti_te, feats_ti = load_split("treatment_insulin")
prep4b, _, _ = make_preprocessor(X_ti_tr, feats_ti, mode="tree")

rxp_insulin_pipe = Pipeline([
    ("prep", prep4b),
    ("clf", DecisionTreeClassifier(
        max_depth=8, min_samples_leaf=50,
        class_weight="balanced", random_state=SEED
    ))
])
rxp_insulin_pipe.fit(X_ti_tr, y_ti_tr)
evaluate_clf("RXPREDICT Insulin (DecisionTree)", rxp_insulin_pipe, X_ti_te, y_ti_te)

joblib.dump(rxp_insulin_pipe, MODEL_DIR / "rxpredict_insulin_model.joblib")
joblib.dump(feats_ti, MODEL_DIR / "rxpredict_insulin_features.joblib")
print("Saved: rxpredict_insulin_model.joblib")


# ============================================================
# 5. DAILYGUARD — Fatma's 5 sub-projects
# ============================================================
print("\n" + "#"*60)
print("# TRAINING DAILYGUARD (Fatma) — Patient companion")
print("#"*60)

# 5a: Suivi quality
X_s_tr, X_s_te, y_s_tr, y_s_te, feats_s = load_split("suivi")
prep5a, _, _ = make_preprocessor(X_s_tr, feats_s, mode="tree")
dg_suivi = Pipeline([
    ("prep", prep5a),
    ("clf", DecisionTreeClassifier(max_depth=6, min_samples_leaf=50, class_weight="balanced", random_state=SEED))
])
dg_suivi.fit(X_s_tr, y_s_tr)
evaluate_clf("DAILYGUARD Suivi", dg_suivi, X_s_te, y_s_te)
joblib.dump(dg_suivi, MODEL_DIR / "dailyguard_suivi_model.joblib")
joblib.dump(feats_s, MODEL_DIR / "dailyguard_suivi_features.joblib")

# 5b: Compagnon
X_c_tr, X_c_te, y_c_tr, y_c_te, feats_c = load_split("compagnon")
prep5b, _, _ = make_preprocessor(X_c_tr, feats_c, mode="tree")
dg_comp = Pipeline([
    ("prep", prep5b),
    ("clf", DecisionTreeClassifier(max_depth=6, min_samples_leaf=50, class_weight="balanced", random_state=SEED))
])
dg_comp.fit(X_c_tr, y_c_tr)
evaluate_clf("DAILYGUARD Compagnon", dg_comp, X_c_te, y_c_te)
joblib.dump(dg_comp, MODEL_DIR / "dailyguard_compagnon_model.joblib")
joblib.dump(feats_c, MODEL_DIR / "dailyguard_compagnon_features.joblib")

# 5c: Rappel (medication forgetfulness risk)
X_r_tr, X_r_te, y_r_tr, y_r_te, feats_r = load_split("rappel")
prep5c, _, _ = make_preprocessor(X_r_tr, feats_r, mode="tree")
dg_rappel = Pipeline([
    ("prep", prep5c),
    ("clf", DecisionTreeClassifier(max_depth=6, min_samples_leaf=50, class_weight="balanced", random_state=SEED))
])
dg_rappel.fit(X_r_tr, y_r_tr)
evaluate_clf("DAILYGUARD Rappel", dg_rappel, X_r_te, y_r_te)
joblib.dump(dg_rappel, MODEL_DIR / "dailyguard_rappel_model.joblib")
joblib.dump(feats_r, MODEL_DIR / "dailyguard_rappel_features.joblib")

print("Saved: all DailyGuard models")


# ============================================================
# 6. BEDSENSE — Najd's readmission + length of stay
# ============================================================
print("\n" + "#"*60)
print("# TRAINING BEDSENSE (Najd) — Bed planning")
print("#"*60)

# 6a: Model A — Readmission classification (same data as MedOracle)
prep6a, _, _ = make_preprocessor(X_tr_f, feats_f)
bedsense_a = Pipeline([
    ("prep", prep6a),
    ("clf", HistGradientBoostingClassifier(
        max_iter=500, max_depth=6, learning_rate=0.05,
        class_weight="balanced", random_state=SEED
    ))
])
bedsense_a.fit(X_tr_f, y_tr_f)
evaluate_clf("BEDSENSE Model-A (HistGB Classification)", bedsense_a, X_te_f, y_te_f)

calibrated_bs_a = CalibratedClassifierCV(bedsense_a, cv=3, method="isotonic")
calibrated_bs_a.fit(X_tr_f, y_tr_f)
evaluate_clf("BEDSENSE Model-A Calibrated", calibrated_bs_a, X_te_f, y_te_f)

joblib.dump(calibrated_bs_a, MODEL_DIR / "bedsense_model_a.joblib")
joblib.dump(feats_f, MODEL_DIR / "bedsense_features_a.joblib")

# 6b: Model B — Length of stay regression
X_nb_tr, X_nb_te, y_nb_tr, y_nb_te, feats_nb = load_split("najd_b")
prep6b, num_nb, cat_nb = make_preprocessor(X_nb_tr, feats_nb)

bedsense_b = Pipeline([
    ("prep", prep6b),
    ("reg", HistGradientBoostingRegressor(
        max_iter=500, max_depth=6, learning_rate=0.05,
        random_state=SEED
    ))
])
bedsense_b.fit(X_nb_tr, y_nb_tr)
y_pred_nb = bedsense_b.predict(X_nb_te)

print(f"\n{'='*60}")
print(f"  BEDSENSE Model-B (HistGB Regression — Length of Stay)")
print(f"{'='*60}")
print(f"  MAE:      {mean_absolute_error(y_nb_te, y_pred_nb):.2f} days")
print(f"  R²:       {r2_score(y_nb_te, y_pred_nb):.4f}")
print(f"  Baseline: always {y_nb_te.median():.0f} days → MAE={mean_absolute_error(y_nb_te, [y_nb_te.median()]*len(y_nb_te)):.2f}")

joblib.dump(bedsense_b, MODEL_DIR / "bedsense_model_b.joblib")
joblib.dump(feats_nb, MODEL_DIR / "bedsense_features_b.joblib")
print("Saved: bedsense_model_a.joblib + bedsense_model_b.joblib")


# ============================================================
# SUMMARY
# ============================================================
print("\n" + "="*60)
print("ALL MODELS TRAINED AND SAVED")
print("="*60)
models_saved = list(MODEL_DIR.glob("*.joblib"))
for m in sorted(models_saved):
    size_mb = m.stat().st_size / 1024 / 1024
    print(f"  {m.name:45s} {size_mb:6.2f} MB")
print(f"\nTotal: {len(models_saved)} files")
