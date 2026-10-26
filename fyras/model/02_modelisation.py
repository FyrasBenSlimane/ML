"""
CareStep — Lab 2 : Modélisation
================================
Membre : Fyras

3 modèles (spec 03_model_and_features) :
  Step 1 — Régression logistique (baseline, 12 features patient)
  Step 2 — LightGBM avec class_weight (12 features patient)
  Step 3 — LightGBM toutes features (référence : combien on perd ?)

Calibration : isotonic scaling sur validation set.
Tuning : GroupKFold (5 folds) sur patient_nbr.
"""

import numpy as np
import joblib
from pathlib import Path
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GroupKFold, cross_val_predict
from sklearn.calibration import CalibratedClassifierCV
import lightgbm as lgb

OUT = Path(__file__).resolve().parent

# ── Chargement ───────────────────────────────────────────────────────────────

print("Chargement des données préparées…")
data = joblib.load(OUT / "prepared_data.pkl")

X_train_p = data["X_train_patient"]
X_test_p = data["X_test_patient"]
X_train_f = data["X_train_full"]
X_test_f = data["X_test_full"]
y_train = data["y_train"]
y_test = data["y_test"]
groups = data["groups_train"]
patient_names = data["patient_feature_names"]
full_names = data["full_feature_names"]

pos_rate = y_train.mean()
scale_pos = (1 - pos_rate) / pos_rate
print(f"  Train : {len(y_train):,}  |  Test : {len(y_test):,}")
print(f"  Prévalence : {pos_rate:.3f}  |  scale_pos_weight : {scale_pos:.1f}")

gkf = GroupKFold(n_splits=5)

# ══════════════════════════════════════════════════════════════════════════════
# Step 1 — Régression logistique (baseline)
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*60)
print("STEP 1 — Régression logistique (12 features patient)")
print("="*60)

lr = LogisticRegression(
    class_weight="balanced",
    max_iter=1000,
    solver="lbfgs",
    random_state=42,
)
lr.fit(X_train_p, y_train)

lr_proba_train = cross_val_predict(
    lr, X_train_p, y_train, groups=groups,
    cv=gkf, method="predict_proba",
)[:, 1]

lr_proba_test = lr.predict_proba(X_test_p)[:, 1]

print(f"  Coefficients : {dict(zip(patient_names, lr.coef_[0].round(3)))}")
print(f"  Intercept    : {lr.intercept_[0]:.3f}")

# ══════════════════════════════════════════════════════════════════════════════
# Step 2 — LightGBM patient (12 features)
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*60)
print("STEP 2 — LightGBM (12 features patient)")
print("="*60)

lgbm_patient = lgb.LGBMClassifier(
    n_estimators=500,
    learning_rate=0.05,
    max_depth=5,
    num_leaves=31,
    min_child_samples=50,
    scale_pos_weight=scale_pos,
    subsample=0.8,
    colsample_bytree=0.8,
    reg_alpha=0.1,
    reg_lambda=1.0,
    random_state=42,
    verbose=-1,
    n_jobs=-1,
)

lgbm_patient.fit(
    X_train_p, y_train,
    eval_set=[(X_test_p, y_test)],
    callbacks=[lgb.log_evaluation(0)],
)

lgbm_p_proba_train = cross_val_predict(
    lgbm_patient, X_train_p, y_train, groups=groups,
    cv=gkf, method="predict_proba",
)[:, 1]

lgbm_p_proba_test = lgbm_patient.predict_proba(X_test_p)[:, 1]

print(f"  Best iteration : {lgbm_patient.best_iteration_}")
fi = sorted(zip(patient_names, lgbm_patient.feature_importances_),
            key=lambda x: -x[1])
print("  Feature importance (gain) :")
for name, imp in fi:
    print(f"    {name:25s} : {imp}")

# ══════════════════════════════════════════════════════════════════════════════
# Step 3 — LightGBM full (toutes features — référence)
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*60)
print("STEP 3 — LightGBM FULL (toutes features — référence)")
print("="*60)

lgbm_full = lgb.LGBMClassifier(
    n_estimators=500,
    learning_rate=0.05,
    max_depth=6,
    num_leaves=63,
    min_child_samples=50,
    scale_pos_weight=scale_pos,
    subsample=0.8,
    colsample_bytree=0.8,
    reg_alpha=0.1,
    reg_lambda=1.0,
    random_state=42,
    verbose=-1,
    n_jobs=-1,
)

lgbm_full.fit(
    X_train_f, y_train,
    eval_set=[(X_test_f, y_test)],
    callbacks=[lgb.log_evaluation(0)],
)

lgbm_f_proba_test = lgbm_full.predict_proba(X_test_f)[:, 1]

print(f"  Best iteration : {lgbm_full.best_iteration_}")
fi_full = sorted(zip(full_names, lgbm_full.feature_importances_),
                 key=lambda x: -x[1])
print("  Top 15 feature importance (gain) :")
for name, imp in fi_full[:15]:
    print(f"    {name:30s} : {imp}")

# ══════════════════════════════════════════════════════════════════════════════
# Calibration — isotonic sur le modèle patient LightGBM
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*60)
print("CALIBRATION — Isotonic (LightGBM patient)")
print("="*60)

# CalibratedClassifierCV doesn't route groups, so we use prefit + held-out
# Train a fresh LightGBM on 80% of train, calibrate on the other 20%
from sklearn.model_selection import GroupShuffleSplit as GSS

cal_split = GSS(n_splits=1, test_size=0.2, random_state=99)
cal_train_idx, cal_val_idx = next(cal_split.split(X_train_p, y_train, groups))

lgbm_for_cal = lgb.LGBMClassifier(**lgbm_patient.get_params())
lgbm_for_cal.fit(X_train_p[cal_train_idx], y_train[cal_train_idx],
                 eval_set=[(X_train_p[cal_val_idx], y_train[cal_val_idx])],
                 callbacks=[lgb.log_evaluation(0)])

cal_lgbm = CalibratedClassifierCV(lgbm_for_cal, method="isotonic", cv="prefit")
cal_lgbm.fit(X_train_p[cal_val_idx], y_train[cal_val_idx])

cal_proba_test = cal_lgbm.predict_proba(X_test_p)[:, 1]
print(f"  Calibrated probabilities — mean : {cal_proba_test.mean():.4f} "
      f"(prevalence : {y_test.mean():.4f})")

# ══════════════════════════════════════════════════════════════════════════════
# Seuils de risque (low / medium / high)
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*60)
print("SEUILS DE RISQUE")
print("="*60)

threshold_medium = pos_rate           # ~11%
threshold_high = 2 * pos_rate         # ~22%

risk_levels = np.where(
    cal_proba_test >= threshold_high, "high",
    np.where(cal_proba_test >= threshold_medium, "medium", "low")
)

for level in ["low", "medium", "high"]:
    mask = risk_levels == level
    n = mask.sum()
    readmit = y_test[mask].sum()
    rate = y_test[mask].mean() if mask.any() else 0
    print(f"  {level:6s} : {n:5,} patients ({n/len(y_test):.1%}), "
          f"réadmissions = {readmit:,} ({rate:.1%})")

high_capture = y_test[risk_levels == "high"].sum() / y_test.sum()
print(f"\n  Le groupe HIGH capture {high_capture:.1%} des réadmissions")

# ── Sauvegarde ───────────────────────────────────────────────────────────────

print("\n  Sauvegarde des modèles…")

models = {
    "lr": lr,
    "lgbm_patient": lgbm_patient,
    "lgbm_full": lgbm_full,
    "cal_lgbm": cal_lgbm,
    "lr_proba_test": lr_proba_test,
    "lgbm_p_proba_test": lgbm_p_proba_test,
    "lgbm_f_proba_test": lgbm_f_proba_test,
    "cal_proba_test": cal_proba_test,
    "risk_levels": risk_levels,
    "threshold_medium": threshold_medium,
    "threshold_high": threshold_high,
    "patient_names": patient_names,
    "full_names": full_names,
}

joblib.dump(models, OUT / "models.pkl")
print(f"  Sauvegardé : {OUT / 'models.pkl'}")
print("="*60)
