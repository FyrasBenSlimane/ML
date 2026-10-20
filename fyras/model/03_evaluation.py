"""
CareStep — Lab 3 : Évaluation
==============================
Membre : Fyras

Métriques (spec 03_model_and_features) :
  - PR-AUC (métrique phare — classes déséquilibrées)
  - ROC-AUC
  - Brier score + courbe de calibration
  - Recall dans le groupe haut risque
  - Ratio PR-AUC patient / full (coût de l'utilisabilité)

+ SHAP (ODS-B) : extraction des facteurs modifiables → plan d'action
+ Figures sauvegardées dans model/figs/
"""

import numpy as np
import joblib
import shap
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path
from sklearn.metrics import (
    average_precision_score, roc_auc_score, brier_score_loss,
    precision_recall_curve, roc_curve, classification_report,
)
from sklearn.calibration import calibration_curve

OUT = Path(__file__).resolve().parent
FIGS = OUT / "figs"
FIGS.mkdir(exist_ok=True)

# ── Chargement ───────────────────────────────────────────────────────────────

print("Chargement…")
data = joblib.load(OUT / "prepared_data.pkl")
models = joblib.load(OUT / "models.pkl")

y_test = data["y_test"]
X_test_p = data["X_test_patient"]
X_train_p = data["X_train_patient"]
y_train = data["y_train"]

lr_proba = models["lr_proba_test"]
lgbm_p_proba = models["lgbm_p_proba_test"]
lgbm_f_proba = models["lgbm_f_proba_test"]
cal_proba = models["cal_proba_test"]
risk_levels = models["risk_levels"]
patient_names = models["patient_names"]

# ══════════════════════════════════════════════════════════════════════════════
# TABLEAU DES MÉTRIQUES
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*70)
print("TABLEAU COMPARATIF DES MÉTRIQUES")
print("="*70)

results = {}
for name, proba in [
    ("LogReg (patient 12f)", lr_proba),
    ("LightGBM (patient 12f)", lgbm_p_proba),
    ("LightGBM calibré (patient)", cal_proba),
    ("LightGBM FULL (référence)", lgbm_f_proba),
]:
    pr_auc = average_precision_score(y_test, proba)
    roc = roc_auc_score(y_test, proba)
    brier = brier_score_loss(y_test, proba)
    results[name] = {"PR-AUC": pr_auc, "ROC-AUC": roc, "Brier": brier}
    print(f"  {name:35s}  PR-AUC={pr_auc:.4f}  ROC-AUC={roc:.4f}  Brier={brier:.4f}")

# Ratio patient / full
ratio = results["LightGBM calibré (patient)"]["PR-AUC"] / results["LightGBM FULL (référence)"]["PR-AUC"]
print(f"\n  ➜ Ratio PR-AUC patient/full = {ratio:.1%} (cible ≥ 85–90%)")

if ratio >= 0.85:
    print("    ✓ Objectif atteint : le modèle patient conserve assez de performance")
else:
    print("    ✗ En dessous de la cible — le modèle perd trop en réduisant les features")

# ══════════════════════════════════════════════════════════════════════════════
# RECALL DANS LE GROUPE HAUT RISQUE
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*70)
print("RECALL PAR NIVEAU DE RISQUE")
print("="*70)

total_readmits = y_test.sum()
for level in ["low", "medium", "high"]:
    mask = risk_levels == level
    n = mask.sum()
    tp = y_test[mask].sum()
    rate = y_test[mask].mean() if mask.any() else 0
    capture = tp / total_readmits if total_readmits > 0 else 0
    print(f"  {level:6s} : {n:5,} patients | {tp:4,} réadmis ({rate:.1%}) | "
          f"capture {capture:.1%} des réadmissions")

high_mask = risk_levels == "high"
high_capture = y_test[high_mask].sum() / total_readmits if total_readmits > 0 else 0

ratio = results["LightGBM calibré (patient)"]["PR-AUC"] / results["LightGBM FULL (référence)"]["PR-AUC"]

# ══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ══════════════════════════════════════════════════════════════════════════════

print("\nGénération des figures…")

# ── Fig 1 : Courbe PR ────────────────────────────────────────────────────────

fig, ax = plt.subplots(figsize=(8, 6))
for name, proba, ls in [
    ("LogReg patient", lr_proba, "--"),
    ("LightGBM patient", lgbm_p_proba, "-"),
    ("LightGBM calibré", cal_proba, "-"),
    ("LightGBM FULL", lgbm_f_proba, ":"),
]:
    prec, rec, _ = precision_recall_curve(y_test, proba)
    ap = average_precision_score(y_test, proba)
    ax.plot(rec, prec, ls, label=f"{name} (AP={ap:.3f})")

ax.axhline(y_test.mean(), color="gray", ls=":", label=f"Baseline ({y_test.mean():.3f})")
ax.set_xlabel("Recall")
ax.set_ylabel("Precision")
ax.set_title("Courbe Precision-Recall — CareStep")
ax.legend(loc="upper right")
ax.set_xlim(0, 1)
ax.set_ylim(0, 1)
fig.tight_layout()
fig.savefig(FIGS / "01_pr_curve.png", dpi=150)
plt.close()
print("  ✓ 01_pr_curve.png")

# ── Fig 2 : Courbe ROC ──────────────────────────────────────────────────────

fig, ax = plt.subplots(figsize=(8, 6))
for name, proba, ls in [
    ("LogReg patient", lr_proba, "--"),
    ("LightGBM patient", lgbm_p_proba, "-"),
    ("LightGBM calibré", cal_proba, "-"),
    ("LightGBM FULL", lgbm_f_proba, ":"),
]:
    fpr, tpr, _ = roc_curve(y_test, proba)
    auc = roc_auc_score(y_test, proba)
    ax.plot(fpr, tpr, ls, label=f"{name} (AUC={auc:.3f})")

ax.plot([0, 1], [0, 1], "k:", alpha=0.3)
ax.set_xlabel("False Positive Rate")
ax.set_ylabel("True Positive Rate")
ax.set_title("Courbe ROC — CareStep")
ax.legend(loc="lower right")
fig.tight_layout()
fig.savefig(FIGS / "02_roc_curve.png", dpi=150)
plt.close()
print("  ✓ 02_roc_curve.png")

# ── Fig 3 : Courbe de calibration ───────────────────────────────────────────

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

for name, proba, ls in [
    ("LightGBM brut", lgbm_p_proba, "--"),
    ("LightGBM calibré", cal_proba, "-"),
]:
    prob_true, prob_pred = calibration_curve(y_test, proba, n_bins=10, strategy="uniform")
    axes[0].plot(prob_pred, prob_true, ls, marker="o", label=name)

axes[0].plot([0, 1], [0, 1], "k:", alpha=0.3, label="Parfaitement calibré")
axes[0].set_xlabel("Probabilité prédite (moyenne du bin)")
axes[0].set_ylabel("Fraction de positifs observée")
axes[0].set_title("Courbe de calibration")
axes[0].legend()

# Histogramme des probabilités calibrées
axes[1].hist(cal_proba[y_test == 0], bins=50, alpha=0.6, label="Non réadmis", density=True)
axes[1].hist(cal_proba[y_test == 1], bins=50, alpha=0.6, label="Réadmis <30j", density=True)
axes[1].axvline(models["threshold_medium"], color="orange", ls="--", label=f"Seuil medium ({models['threshold_medium']:.2f})")
axes[1].axvline(models["threshold_high"], color="red", ls="--", label=f"Seuil high ({models['threshold_high']:.2f})")
axes[1].set_xlabel("Probabilité calibrée")
axes[1].set_ylabel("Densité")
axes[1].set_title("Distribution des probabilités + seuils de risque")
axes[1].legend()

fig.tight_layout()
fig.savefig(FIGS / "03_calibration.png", dpi=150)
plt.close()
print("  ✓ 03_calibration.png")

# ── Fig 4 : SHAP — feature importance globale ───────────────────────────────

print("\n  Calcul SHAP (peut prendre ~30s)…")

lgbm_model = models["lgbm_patient"]
explainer = shap.TreeExplainer(lgbm_model)

shap_sample_idx = np.random.RandomState(42).choice(len(X_test_p), size=min(2000, len(X_test_p)), replace=False)
X_shap = X_test_p[shap_sample_idx]
shap_values = explainer.shap_values(X_shap)

if isinstance(shap_values, list):
    shap_vals = shap_values[1]
else:
    shap_vals = shap_values

fig, ax = plt.subplots(figsize=(10, 7))
shap.summary_plot(shap_vals, X_shap, feature_names=patient_names,
                  show=False, max_display=len(patient_names))
plt.title("SHAP — Importance des 12 features patient")
plt.tight_layout()
plt.savefig(FIGS / "04_shap_summary.png", dpi=150, bbox_inches="tight")
plt.close()
print("  ✓ 04_shap_summary.png")

# ── Fig 5 : SHAP bar plot ───────────────────────────────────────────────────

fig, ax = plt.subplots(figsize=(8, 6))
shap.summary_plot(shap_vals, X_shap, feature_names=patient_names,
                  plot_type="bar", show=False, max_display=len(patient_names))
plt.title("SHAP — Mean |SHAP value| par feature")
plt.tight_layout()
plt.savefig(FIGS / "05_shap_bar.png", dpi=150, bbox_inches="tight")
plt.close()
print("  ✓ 05_shap_bar.png")

# ══════════════════════════════════════════════════════════════════════════════
# ODS-B : FACTEURS MODIFIABLES → PLAN D'ACTION
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*70)
print("ODS-B : MAPPING FACTEURS MODIFIABLES → ACTIONS")
print("="*70)

MODIFIABLE_FEATURES = {
    "insulin":           "Prenez votre nouvelle dose d'insuline comme prescrit",
    "change":            "Suivez les changements de médicaments prescrits à la sortie",
    "num_medications":   "Utilisez un pilulier pour organiser vos médicaments",
    "a1c_tested":        "Planifiez un test HbA1c avec votre médecin",
    "discharge_group":   "Respectez le plan de suivi de votre lieu de sortie",
    "outpatient_bkt":    "Prenez un rendez-vous de suivi dans les 7 jours",
    "emergency_cap":     "En cas de symptômes, appelez votre médecin avant d'aller aux urgences",
}

NON_MODIFIABLE = {"age_ord", "gender_bin", "time_in_hospital",
                  "inpatient_cap", "diag_group"}

def get_base_feature(fname):
    for base in MODIFIABLE_FEATURES:
        if fname == base or fname.startswith(base + "_"):
            return base
    return None

mean_abs_shap = np.abs(shap_vals).mean(axis=0)
feature_shap = sorted(zip(patient_names, mean_abs_shap), key=lambda x: -x[1])

print("\n  Classement SHAP → action :")
for fname, importance in feature_shap:
    base = get_base_feature(fname)
    is_mod = "✓ MODIFIABLE" if base else "✗ non-modifiable"
    print(f"    {fname:25s}  SHAP={importance:.4f}  {is_mod}")
    if base:
        print(f"      → Action : {MODIFIABLE_FEATURES[base]}")

# ── Exemple patient haut risque ──────────────────────────────────────────────

print("\n" + "="*70)
print("EXEMPLE — PLAN PERSONNALISÉ (1 patient haut risque)")
print("="*70)

high_idx = np.where(risk_levels == "high")[0]
if len(high_idx) > 0:
    ex_idx = high_idx[0]
    ex_proba = cal_proba[ex_idx]
    ex_shap = explainer.shap_values(X_test_p[ex_idx:ex_idx+1])
    if isinstance(ex_shap, list):
        ex_shap = ex_shap[1]

    print(f"  Patient test #{ex_idx}")
    print(f"  Probabilité calibrée : {ex_proba:.1%}")
    print(f"  Niveau de risque : HIGH 🔴")
    print(f"\n  Ses facteurs de risque (SHAP > 0 = pousse vers réadmission) :")

    driver_pairs = sorted(zip(patient_names, ex_shap[0]), key=lambda x: -x[1])
    action_count = 0
    for fname, sv in driver_pairs:
        if sv > 0:
            direction = "↑ risque"
        else:
            direction = "↓ protecteur"
        print(f"    {fname:25s}  SHAP={sv:+.4f}  {direction}")
        base = get_base_feature(fname)
        if sv > 0 and base:
            print(f"      ★ ACTION : {MODIFIABLE_FEATURES[base]}")
            action_count += 1

    print(f"\n  → {action_count} action(s) personnalisée(s) générée(s)")

# ══════════════════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ══════════════════════════════════════════════════════════════════════════════

print("\n" + "="*70)
print("RÉSUMÉ FINAL — CareStep (Fyras)")
print("="*70)

r = results
print(f"""
  ┌─────────────────────────────┬──────────┬──────────┬──────────┐
  │ Modèle                      │  PR-AUC  │ ROC-AUC  │  Brier   │
  ├─────────────────────────────┼──────────┼──────────┼──────────┤
  │ LogReg (12 features)        │  {r['LogReg (patient 12f)']['PR-AUC']:.4f}  │  {r['LogReg (patient 12f)']['ROC-AUC']:.4f}  │  {r['LogReg (patient 12f)']['Brier']:.4f}  │
  │ LightGBM (12 features)      │  {r['LightGBM (patient 12f)']['PR-AUC']:.4f}  │  {r['LightGBM (patient 12f)']['ROC-AUC']:.4f}  │  {r['LightGBM (patient 12f)']['Brier']:.4f}  │
  │ LightGBM calibré (12f)      │  {r['LightGBM calibré (patient)']['PR-AUC']:.4f}  │  {r['LightGBM calibré (patient)']['ROC-AUC']:.4f}  │  {r['LightGBM calibré (patient)']['Brier']:.4f}  │
  │ LightGBM FULL (référence)   │  {r['LightGBM FULL (référence)']['PR-AUC']:.4f}  │  {r['LightGBM FULL (référence)']['ROC-AUC']:.4f}  │  {r['LightGBM FULL (référence)']['Brier']:.4f}  │
  └─────────────────────────────┴──────────┴──────────┴──────────┘

  Ratio patient/full PR-AUC : {ratio:.1%}
  Groupe HIGH capture : {high_capture:.1%} des réadmissions

  Figures sauvegardées dans : {FIGS}/
    01_pr_curve.png
    02_roc_curve.png
    03_calibration.png
    04_shap_summary.png
    05_shap_bar.png
""")
