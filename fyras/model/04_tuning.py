"""
CareStep — Lab 4 : Amélioration du modèle
==========================================
Membre : Fyras

Objectif pédagogique :
  On part du LightGBM de base (Lab 2) et on l'améliore pas à pas :
    Étape 1 — Comprendre les hyperparamètres clés
    Étape 2 — Recherche par RandomizedSearchCV + GroupKFold
    Étape 3 — Comparer avant / après
    Étape 4 — Re-calibrer le meilleur modèle
    Étape 5 — Vérifier les niveaux de risque
"""

import numpy as np
import joblib
import warnings
from pathlib import Path
from sklearn.model_selection import RandomizedSearchCV, GroupKFold
from sklearn.calibration import CalibratedClassifierCV
from sklearn.model_selection import GroupShuffleSplit as GSS
from sklearn.metrics import average_precision_score, roc_auc_score, brier_score_loss
from scipy.stats import randint, uniform
import lightgbm as lgb

warnings.filterwarnings("ignore", category=UserWarning)

OUT = Path(__file__).resolve().parent

# ── Chargement ───────────────────────────────────────────────────────────────

print("Chargement des données et modèles…")
data = joblib.load(OUT / "prepared_data.pkl")
models_old = joblib.load(OUT / "models.pkl")

X_train = data["X_train_patient"]
X_test = data["X_test_patient"]
y_train = data["y_train"]
y_test = data["y_test"]
groups = data["groups_train"]
patient_names = data["patient_feature_names"]

pos_rate = y_train.mean()
scale_pos = (1 - pos_rate) / pos_rate
print(f"  Train : {len(y_train):,}  |  Test : {len(y_test):,}")
print(f"  Prévalence : {pos_rate:.3f}")

# ══════════════════════════════════════════════════════════════════════════════
# Étape 1 — Rappel : les hyperparamètres qu'on va chercher
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*65)
print("ÉTAPE 1 — Hyperparamètres clés de LightGBM")
print("="*65)
print("""
  n_estimators    : nombre d'arbres (plus = plus puissant, risque overfit)
  learning_rate   : pas d'apprentissage (petit = lent mais précis)
  max_depth       : profondeur max d'un arbre (limite la complexité)
  num_leaves      : nombre de feuilles (contrôle la taille des arbres)
  min_child_samples : observations min dans une feuille (régularise)
  subsample       : fraction des données par arbre (réduit l'overfit)
  colsample_bytree: fraction des features par arbre (diversifie)
  reg_alpha       : régularisation L1 (pousse des poids vers 0)
  reg_lambda      : régularisation L2 (empêche les grands poids)
""")

# Modèle de base (Lab 2) — rappel des performances
old_proba = models_old["lgbm_p_proba_test"]
old_pr = average_precision_score(y_test, old_proba)
old_roc = roc_auc_score(y_test, old_proba)
print(f"  Modèle Lab 2 (avant tuning) :")
print(f"    PR-AUC  = {old_pr:.4f}")
print(f"    ROC-AUC = {old_roc:.4f}")

# ══════════════════════════════════════════════════════════════════════════════
# Étape 2 — RandomizedSearchCV avec GroupKFold
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*65)
print("ÉTAPE 2 — Recherche d'hyperparamètres (RandomizedSearchCV)")
print("="*65)
print("  Stratégie : tester 40 combinaisons aléatoires, 5 folds par patient")
print("  Métrique  : average_precision (= PR-AUC)")

param_distributions = {
    "n_estimators":      randint(200, 800),
    "learning_rate":     uniform(0.01, 0.14),       # entre 0.01 et 0.15
    "max_depth":         randint(3, 8),              # entre 3 et 7
    "num_leaves":        randint(15, 63),
    "min_child_samples": randint(20, 100),
    "subsample":         uniform(0.6, 0.35),         # entre 0.6 et 0.95
    "colsample_bytree":  uniform(0.5, 0.45),         # entre 0.5 et 0.95
    "reg_alpha":         uniform(0, 1.0),
    "reg_lambda":        uniform(0.5, 2.5),
}

base_model = lgb.LGBMClassifier(
    scale_pos_weight=scale_pos,
    random_state=42,
    verbose=-1,
    n_jobs=-1,
)

gkf = GroupKFold(n_splits=5)

search = RandomizedSearchCV(
    estimator=base_model,
    param_distributions=param_distributions,
    n_iter=40,
    scoring="average_precision",
    cv=gkf,
    random_state=42,
    verbose=1,
    n_jobs=-1,
)

print("\n  Lancement de la recherche…\n")
search.fit(X_train, y_train, groups=groups)

print(f"\n  Meilleur score CV (PR-AUC) : {search.best_score_:.4f}")
print(f"\n  Meilleurs hyperparamètres :")
for param, val in sorted(search.best_params_.items()):
    if isinstance(val, float):
        print(f"    {param:22s} = {val:.4f}")
    else:
        print(f"    {param:22s} = {val}")

# ══════════════════════════════════════════════════════════════════════════════
# Étape 3 — Comparer avant / après sur le test set
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*65)
print("ÉTAPE 3 — Comparaison avant / après tuning (test set)")
print("="*65)

best_model = search.best_estimator_
new_proba = best_model.predict_proba(X_test)[:, 1]
new_pr = average_precision_score(y_test, new_proba)
new_roc = roc_auc_score(y_test, new_proba)
new_brier = brier_score_loss(y_test, new_proba)

print(f"""
  ┌──────────────────┬──────────┬──────────┐
  │                  │  Avant   │  Après   │
  ├──────────────────┼──────────┼──────────┤
  │ PR-AUC           │  {old_pr:.4f}  │  {new_pr:.4f}  │
  │ ROC-AUC          │  {old_roc:.4f}  │  {new_roc:.4f}  │
  └──────────────────┴──────────┴──────────┘
""")

delta_pr = (new_pr - old_pr) / old_pr * 100
print(f"  Variation PR-AUC : {delta_pr:+.1f}%")

# ══════════════════════════════════════════════════════════════════════════════
# Étape 4 — Calibration isotonique du meilleur modèle
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*65)
print("ÉTAPE 4 — Calibration isotonique du modèle tuné")
print("="*65)

cal_split = GSS(n_splits=1, test_size=0.2, random_state=99)
cal_train_idx, cal_val_idx = next(cal_split.split(X_train, y_train, groups))

tuned_for_cal = lgb.LGBMClassifier(**best_model.get_params())
tuned_for_cal.fit(X_train[cal_train_idx], y_train[cal_train_idx])

cal_model = CalibratedClassifierCV(tuned_for_cal, method="isotonic", cv="prefit")
cal_model.fit(X_train[cal_val_idx], y_train[cal_val_idx])

cal_proba = cal_model.predict_proba(X_test)[:, 1]
cal_pr = average_precision_score(y_test, cal_proba)
cal_roc = roc_auc_score(y_test, cal_proba)
cal_brier = brier_score_loss(y_test, cal_proba)

print(f"  Calibré — PR-AUC={cal_pr:.4f}  ROC-AUC={cal_roc:.4f}  Brier={cal_brier:.4f}")
print(f"  Moyenne des probas calibrées : {cal_proba.mean():.4f} (prévalence : {y_test.mean():.4f})")

# ══════════════════════════════════════════════════════════════════════════════
# Étape 5 — Niveaux de risque avec le modèle amélioré
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*65)
print("ÉTAPE 5 — Niveaux de risque (modèle tuné + calibré)")
print("="*65)

threshold_medium = pos_rate
threshold_high = 2 * pos_rate

risk_levels = np.where(
    cal_proba >= threshold_high, "high",
    np.where(cal_proba >= threshold_medium, "medium", "low")
)

total_readmits = y_test.sum()
for level in ["low", "medium", "high"]:
    mask = risk_levels == level
    n = mask.sum()
    tp = y_test[mask].sum()
    rate = y_test[mask].mean() if mask.any() else 0
    capture = tp / total_readmits if total_readmits > 0 else 0
    print(f"  {level:6s} : {n:5,} patients ({n/len(y_test):.1%}), "
          f"réadmissions = {tp:,} ({rate:.1%}), "
          f"capture {capture:.1%}")

high_capture = y_test[risk_levels == "high"].sum() / total_readmits
med_high_capture = y_test[risk_levels != "low"].sum() / total_readmits
print(f"\n  HIGH capture         : {high_capture:.1%} des réadmissions")
print(f"  MEDIUM + HIGH capture : {med_high_capture:.1%} des réadmissions")

# ── Sauvegarde ───────────────────────────────────────────────────────────────

print("\n" + "="*65)
print("SAUVEGARDE")
print("="*65)

tuned_models = {
    "best_model": best_model,
    "cal_model": cal_model,
    "best_params": search.best_params_,
    "best_cv_score": search.best_score_,
    "new_proba_test": new_proba,
    "cal_proba_test": cal_proba,
    "risk_levels": risk_levels,
    "threshold_medium": threshold_medium,
    "threshold_high": threshold_high,
    "patient_names": patient_names,
}

joblib.dump(tuned_models, OUT / "tuned_models.pkl")
print(f"  Sauvegardé : {OUT / 'tuned_models.pkl'}")

# ── Résumé comparatif final ─────────────────────────────────────────────────

old_cal_pr = average_precision_score(y_test, models_old["cal_proba_test"])
old_cal_brier = brier_score_loss(y_test, models_old["cal_proba_test"])

print(f"""
  ┌───────────────────────────┬──────────┬──────────┬──────────┐
  │ Modèle                    │  PR-AUC  │ ROC-AUC  │  Brier   │
  ├───────────────────────────┼──────────┼──────────┼──────────┤
  │ Lab 2 — LightGBM brut     │  {old_pr:.4f}  │  {old_roc:.4f}  │    —     │
  │ Lab 2 — LightGBM calibré  │  {old_cal_pr:.4f}  │    —     │  {old_cal_brier:.4f}  │
  │ Lab 4 — Tuné brut         │  {new_pr:.4f}  │  {new_roc:.4f}  │    —     │
  │ Lab 4 — Tuné + calibré    │  {cal_pr:.4f}  │  {cal_roc:.4f}  │  {cal_brier:.4f}  │
  └───────────────────────────┴──────────┴──────────┴──────────┘
""")

print("="*65)
print("Lab 4 terminé.")
print("="*65)
