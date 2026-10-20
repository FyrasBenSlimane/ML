"""
CareStep — Main Pipeline (live)
================================
Membre : Fyras

Lance les 4 labs pas à pas avec affichage live des métriques.
La fenêtre matplotlib se met à jour après chaque étape.
"""

import numpy as np
import pandas as pd
import joblib
import warnings
import time
import os
import matplotlib
try:
    matplotlib.use(os.environ.get("MPLBACKEND") or "TkAgg")
except ImportError:
    matplotlib.use("Agg")   # no display (server, CI): the dashboard is still saved to figs/
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from pathlib import Path

from sklearn.model_selection import GroupShuffleSplit, GroupKFold, RandomizedSearchCV
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.calibration import CalibratedClassifierCV, calibration_curve
from sklearn.metrics import (
    average_precision_score, roc_auc_score, brier_score_loss,
    precision_recall_curve, roc_curve,
)
from scipy.stats import randint, uniform
import lightgbm as lgb

warnings.filterwarnings("ignore")

_HERE = Path(__file__).resolve().parent
DATA_PATH = next(p for p in [
    _HERE.parent / "extracted_data" / "diabetic_data.csv",           # local copy next to model/
    _HERE.parents[1] / "capalit_ml" / "diabetic_data.csv",            # team repo (fyras/model/)
    _HERE.parents[1] / "extracted_data" / "diabetic_data.csv",
] if p.exists())
OUT = Path(__file__).resolve().parent
FIGS = OUT / "figs"
FIGS.mkdir(exist_ok=True)

# ── Dashboard setup ──────────────────────────────────────────────────────────

plt.ion()
fig = plt.figure(figsize=(16, 10))
fig.canvas.manager.set_window_title("CareStep — Pipeline Live")
fig.patch.set_facecolor("#1a1a2e")

gs = GridSpec(3, 3, figure=fig, hspace=0.45, wspace=0.35,
              left=0.07, right=0.97, top=0.93, bottom=0.06)

COLORS = {
    "bg": "#1a1a2e",
    "card": "#16213e",
    "text": "#e0e0e0",
    "accent": "#0f3460",
    "green": "#4ecca3",
    "orange": "#f0a500",
    "red": "#e94560",
    "blue": "#4da8da",
    "purple": "#a855f7",
    "grid": "#2a2a4a",
}

def style_ax(ax, title=""):
    ax.set_facecolor(COLORS["card"])
    ax.tick_params(colors=COLORS["text"], labelsize=8)
    for spine in ax.spines.values():
        spine.set_color(COLORS["grid"])
    if title:
        ax.set_title(title, color=COLORS["text"], fontsize=10, fontweight="bold", pad=8)

def status_text(msg):
    fig.suptitle(f"CareStep Pipeline  —  {msg}", fontsize=13,
                 fontweight="bold", color=COLORS["green"], y=0.98)
    fig.canvas.draw_idle()
    fig.canvas.flush_events()

def pause(sec=1.0):
    plt.pause(sec)

metrics_log = {}

# ══════════════════════════════════════════════════════════════════════════════
# LAB 1 — PRÉPARATION
# ══════════════════════════════════════════════════════════════════════════════

status_text("Lab 1 — Chargement des données…")
pause(0.5)

print("\n" + "="*60)
print("LAB 1 — PRÉPARATION DES DONNÉES")
print("="*60)

df = pd.read_csv(DATA_PATH)
n_total = len(df)
n_patients = df["patient_nbr"].nunique()
print(f"  {n_total:,} encounters, {n_patients:,} patients")

EXCLUDE_DISPOSITIONS = {11, 13, 14, 19, 20, 21}
mask = df["discharge_disposition_id"].isin(EXCLUDE_DISPOSITIONS)
n_excluded = mask.sum()
df = df[~mask].copy()
print(f"  Exclusion décès/palliatifs : {n_excluded:,} → {len(df):,} restants")

gender_mask = df["gender"].isin(["Unknown/Invalid"])
n_excluded += gender_mask.sum()
df = df[~gender_mask].copy()
print(f"  Exclusion gender Unknown/Invalid : {gender_mask.sum()} → {len(df):,} restants")

df["y"] = (df["readmitted"] == "<30").astype(int)
prevalence = df["y"].mean()
print(f"  Cible y=1 (réadmis <30j) : {df['y'].sum():,} ({prevalence:.1%})")

# Features patient
AGE_ORDER = ["[0-10)", "[10-20)", "[20-30)", "[30-40)", "[40-50)",
             "[50-60)", "[60-70)", "[70-80)", "[80-90)", "[90-100)"]
df["age_ord"] = df["age"].map({a: i for i, a in enumerate(AGE_ORDER)})
df["gender_bin"] = (df["gender"] == "Male").astype(int)
df["inpatient_cap"] = df["number_inpatient"].clip(upper=3)
df["emergency_cap"] = df["number_emergency"].clip(upper=3)
df["outpatient_bkt"] = df["number_outpatient"].apply(
    lambda x: 0 if x == 0 else (1 if x <= 2 else (2 if x <= 5 else 3)))

def group_diag(code):
    if pd.isna(code) or code == "?":
        return "other"
    try:
        num = float(code)
    except ValueError:
        return "injury" if str(code).startswith("E") else "other"
    if 390 <= num <= 459 or num == 785: return "circulatory"
    if 460 <= num <= 519 or num == 786: return "respiratory"
    if 250 <= num < 251: return "diabetes"
    if 520 <= num <= 579 or num == 787: return "digestive"
    if 580 <= num <= 629 or 1 <= num <= 139 or 680 <= num <= 709 or num == 788:
        return "infection_renal"
    if 800 <= num <= 999: return "injury"
    return "other"

df["diag_group"] = df["diag_1"].apply(group_diag)
# pandas lit le texte "None" du CSV comme NaN : NaN = test non fait
df["a1c_tested"] = df["A1Cresult"].notna().astype(int)
df["discharge_group"] = df["discharge_disposition_id"].apply(
    lambda d: "home" if d in (1, 8) else ("home_with_help" if d == 6 else "facility"))

NUM_FEATURES = ["age_ord", "gender_bin", "inpatient_cap", "emergency_cap",
                "outpatient_bkt", "time_in_hospital", "num_medications", "a1c_tested"]
CAT_FEATURES = ["diag_group", "insulin", "change", "discharge_group"]

# Split
gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
groups_all = df["patient_nbr"].values
train_idx, test_idx = next(gss.split(df, df["y"], groups_all))
df_train, df_test = df.iloc[train_idx].copy(), df.iloc[test_idx].copy()

preprocessor = ColumnTransformer([
    ("num", "passthrough", NUM_FEATURES),
    ("cat", OneHotEncoder(handle_unknown="infrequent_if_exist",
                          sparse_output=False, drop="if_binary"), CAT_FEATURES),
], remainder="drop", verbose_feature_names_out=False)

X_train = preprocessor.fit_transform(df_train)
X_test = preprocessor.transform(df_test)
feature_names = list(preprocessor.get_feature_names_out())

# Toutes les features (modèle de référence pour le ratio patient/full) — race reste audit-only
FULL_NUM = NUM_FEATURES + ["num_lab_procedures", "num_procedures", "number_diagnoses",
                           "admission_type_id", "admission_source_id"]
FULL_CAT = CAT_FEATURES + ["medical_specialty"]
for d in (df_train, df_test):
    d["medical_specialty"] = d["medical_specialty"].replace("?", "Unknown")
full_preprocessor = ColumnTransformer([
    ("num", "passthrough", FULL_NUM),
    ("cat", OneHotEncoder(handle_unknown="infrequent_if_exist",
                          sparse_output=False, drop="if_binary"), FULL_CAT),
], remainder="drop", verbose_feature_names_out=False)
X_train_full = full_preprocessor.fit_transform(df_train)
X_test_full = full_preprocessor.transform(df_test)
y_train = df_train["y"].values
y_test = df_test["y"].values
groups = df_train["patient_nbr"].values

pos_rate = y_train.mean()
scale_pos = (1 - pos_rate) / pos_rate

print(f"  Train : {len(y_train):,}  |  Test : {len(y_test):,}")
print(f"  Features : {len(feature_names)}  |  Anti-fuite : ✓")

# ── Dashboard: Lab 1 stats ───────────────────────────────────────────────────

ax_stats = fig.add_subplot(gs[0, 0])
style_ax(ax_stats, "Lab 1 — Dataset")
ax_stats.axis("off")

stats_text = (
    f"Encounters : {n_total:,}\n"
    f"Patients   : {n_patients:,}\n"
    f"Exclus     : {n_excluded:,}\n"
    f"Restants   : {len(df):,}\n"
    f"─────────────────\n"
    f"Train      : {len(y_train):,}\n"
    f"Test       : {len(y_test):,}\n"
    f"Prévalence : {prevalence:.1%}\n"
    f"Features   : {len(feature_names)}"
)
ax_stats.text(0.08, 0.92, stats_text, transform=ax_stats.transAxes,
              fontsize=9, fontfamily="monospace", color=COLORS["text"],
              verticalalignment="top")

# Diag distribution
ax_diag = fig.add_subplot(gs[0, 1])
style_ax(ax_diag, "Lab 1 — Diagnostics")
diag_counts = df["diag_group"].value_counts()
bars = ax_diag.barh(diag_counts.index, diag_counts.values,
                     color=COLORS["blue"], alpha=0.8, height=0.6)
ax_diag.set_xlabel("Count", color=COLORS["text"], fontsize=8)
ax_diag.invert_yaxis()

status_text("Lab 1 — Préparation ✓")
pause(1.5)

# ══════════════════════════════════════════════════════════════════════════════
# LAB 2 — MODÉLISATION
# ══════════════════════════════════════════════════════════════════════════════

status_text("Lab 2 — Régression logistique…")
pause(0.3)

print("\n" + "="*60)
print("LAB 2 — MODÉLISATION")
print("="*60)

# Step 1: LogReg
lr = LogisticRegression(class_weight="balanced", max_iter=1000, solver="lbfgs", random_state=42)
lr.fit(X_train, y_train)
lr_proba = lr.predict_proba(X_test)[:, 1]
lr_pr = average_precision_score(y_test, lr_proba)
lr_roc = roc_auc_score(y_test, lr_proba)
lr_brier = brier_score_loss(y_test, lr_proba)
metrics_log["LogReg"] = {"PR-AUC": lr_pr, "ROC-AUC": lr_roc, "Brier": lr_brier}
print(f"  LogReg      : PR-AUC={lr_pr:.4f}  ROC-AUC={lr_roc:.4f}")

# Dashboard: metrics table (will update)
ax_table = fig.add_subplot(gs[0, 2])
style_ax(ax_table, "Métriques (live)")
ax_table.axis("off")

def draw_metrics_table():
    ax_table.clear()
    style_ax(ax_table, "Métriques (live)")
    ax_table.axis("off")
    header = f"{'Modèle':<24s} {'PR-AUC':>7s} {'ROC-AUC':>8s} {'Brier':>7s}"
    lines = [header, "─" * 50]
    for name, m in metrics_log.items():
        b = f"{m['Brier']:.4f}" if m["Brier"] else "  —"
        lines.append(f"{name:<24s} {m['PR-AUC']:>7.4f} {m['ROC-AUC']:>8.4f} {b:>7s}")
    ax_table.text(0.05, 0.92, "\n".join(lines), transform=ax_table.transAxes,
                  fontsize=8, fontfamily="monospace", color=COLORS["text"],
                  verticalalignment="top")

draw_metrics_table()
status_text("Lab 2 — LogReg ✓  |  LightGBM en cours…")
pause(1.0)

# Step 2: LightGBM patient
lgbm = lgb.LGBMClassifier(
    n_estimators=500, learning_rate=0.05, max_depth=5, num_leaves=31,
    min_child_samples=50, scale_pos_weight=scale_pos,
    subsample=0.8, colsample_bytree=0.8,
    reg_alpha=0.1, reg_lambda=1.0, random_state=42, verbose=-1, n_jobs=-1,
)
lgbm.fit(X_train, y_train)
lgbm_proba = lgbm.predict_proba(X_test)[:, 1]
lgbm_pr = average_precision_score(y_test, lgbm_proba)
lgbm_roc = roc_auc_score(y_test, lgbm_proba)
lgbm_brier = brier_score_loss(y_test, lgbm_proba)
metrics_log["LightGBM"] = {"PR-AUC": lgbm_pr, "ROC-AUC": lgbm_roc, "Brier": lgbm_brier}
print(f"  LightGBM    : PR-AUC={lgbm_pr:.4f}  ROC-AUC={lgbm_roc:.4f}")

# Step 3: LightGBM full (référence — combien perd-on avec 12 features ?)
lgbm_full = lgb.LGBMClassifier(
    n_estimators=500, learning_rate=0.05, max_depth=6, num_leaves=63,
    min_child_samples=50, scale_pos_weight=scale_pos,
    subsample=0.8, colsample_bytree=0.8,
    reg_alpha=0.1, reg_lambda=1.0, random_state=42, verbose=-1, n_jobs=-1,
)
lgbm_full.fit(X_train_full, y_train)
full_proba = lgbm_full.predict_proba(X_test_full)[:, 1]
full_pr = average_precision_score(y_test, full_proba)
full_roc = roc_auc_score(y_test, full_proba)
metrics_log["LightGBM full (réf.)"] = {"PR-AUC": full_pr, "ROC-AUC": full_roc,
                                       "Brier": brier_score_loss(y_test, full_proba)}
print(f"  Full (réf.) : PR-AUC={full_pr:.4f}  ROC-AUC={full_roc:.4f}")

draw_metrics_table()

# PR curve (live)
ax_pr = fig.add_subplot(gs[1, 0])
style_ax(ax_pr, "Courbe PR (live)")

def draw_pr_curves(probas_dict):
    ax_pr.clear()
    style_ax(ax_pr, "Courbe PR (live)")
    colors_list = [COLORS["orange"], COLORS["blue"], COLORS["green"], COLORS["purple"]]
    for i, (name, proba) in enumerate(probas_dict.items()):
        prec, rec, _ = precision_recall_curve(y_test, proba)
        ap = average_precision_score(y_test, proba)
        ax_pr.plot(rec, prec, color=colors_list[i % len(colors_list)],
                   label=f"{name} ({ap:.3f})", linewidth=1.5)
    ax_pr.axhline(y_test.mean(), color="gray", ls=":", alpha=0.5, label=f"Baseline ({y_test.mean():.3f})")
    ax_pr.set_xlabel("Recall", color=COLORS["text"], fontsize=8)
    ax_pr.set_ylabel("Precision", color=COLORS["text"], fontsize=8)
    ax_pr.legend(fontsize=7, facecolor=COLORS["card"], edgecolor=COLORS["grid"],
                 labelcolor=COLORS["text"], loc="upper right")
    ax_pr.set_xlim(0, 1)
    ax_pr.set_ylim(0, 0.6)

pr_curves = {"LogReg": lr_proba, "LightGBM": lgbm_proba}
draw_pr_curves(pr_curves)
status_text("Lab 2 — LightGBM ✓  |  Calibration…")
pause(1.0)

# Calibration
cal_split = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=99)
cal_train_idx, cal_val_idx = next(cal_split.split(X_train, y_train, groups))
lgbm_cal = lgb.LGBMClassifier(**lgbm.get_params())
lgbm_cal.fit(X_train[cal_train_idx], y_train[cal_train_idx])
cal_model = CalibratedClassifierCV(lgbm_cal, method="isotonic", cv="prefit")
cal_model.fit(X_train[cal_val_idx], y_train[cal_val_idx])
cal_proba = cal_model.predict_proba(X_test)[:, 1]
cal_pr = average_precision_score(y_test, cal_proba)
cal_roc = roc_auc_score(y_test, cal_proba)
cal_brier = brier_score_loss(y_test, cal_proba)
metrics_log["Calibré"] = {"PR-AUC": cal_pr, "ROC-AUC": cal_roc, "Brier": cal_brier}
print(f"  Calibré     : PR-AUC={cal_pr:.4f}  ROC-AUC={cal_roc:.4f}  Brier={cal_brier:.4f}")

draw_metrics_table()
pr_curves["Calibré"] = cal_proba
draw_pr_curves(pr_curves)

# Calibration curve
ax_cal = fig.add_subplot(gs[1, 1])
style_ax(ax_cal, "Calibration")
prob_true_raw, prob_pred_raw = calibration_curve(y_test, lgbm_proba, n_bins=10, strategy="uniform")
prob_true_cal, prob_pred_cal = calibration_curve(y_test, cal_proba, n_bins=10, strategy="uniform")
ax_cal.plot(prob_pred_raw, prob_true_raw, "o--", color=COLORS["orange"],
            label="Brut", markersize=4, linewidth=1.2)
ax_cal.plot(prob_pred_cal, prob_true_cal, "o-", color=COLORS["green"],
            label="Calibré", markersize=4, linewidth=1.2)
ax_cal.plot([0, 0.5], [0, 0.5], ":", color="gray", alpha=0.5)
ax_cal.set_xlabel("Prédit", color=COLORS["text"], fontsize=8)
ax_cal.set_ylabel("Observé", color=COLORS["text"], fontsize=8)
ax_cal.legend(fontsize=7, facecolor=COLORS["card"], edgecolor=COLORS["grid"],
              labelcolor=COLORS["text"])

# Risk levels
threshold_med = pos_rate
threshold_high = 2 * pos_rate
risk = np.where(cal_proba >= threshold_high, "high",
                np.where(cal_proba >= threshold_med, "medium", "low"))

ax_risk = fig.add_subplot(gs[1, 2])
style_ax(ax_risk, "Niveaux de risque")
risk_data = {}
total_re = y_test.sum()
for level in ["low", "medium", "high"]:
    m = risk == level
    risk_data[level] = {"n": m.sum(), "rate": y_test[m].mean(), "capture": y_test[m].sum() / total_re}

labels = list(risk_data.keys())
counts = [risk_data[l]["n"] for l in labels]
rates = [risk_data[l]["rate"] for l in labels]
bar_colors = [COLORS["green"], COLORS["orange"], COLORS["red"]]

bars = ax_risk.bar(labels, counts, color=bar_colors, alpha=0.8, width=0.5)
ax_risk.set_ylabel("Patients", color=COLORS["text"], fontsize=8)
ax_risk2 = ax_risk.twinx()
ax_risk2.plot(labels, [r * 100 for r in rates], "D-", color="white", markersize=5, linewidth=1.5)
ax_risk2.set_ylabel("Taux réadm. %", color=COLORS["text"], fontsize=8)
ax_risk2.tick_params(colors=COLORS["text"], labelsize=8)
for spine in ax_risk2.spines.values():
    spine.set_color(COLORS["grid"])

for level in ["low", "medium", "high"]:
    d = risk_data[level]
    print(f"  {level:6s} : {d['n']:5,} ({d['rate']:.1%} réadm, capture {d['capture']:.1%})")

status_text("Lab 2 — Modélisation ✓")
pause(1.5)

# ══════════════════════════════════════════════════════════════════════════════
# LAB 3 — ÉVALUATION + SHAP
# ══════════════════════════════════════════════════════════════════════════════

status_text("Lab 3 — SHAP en cours…")
pause(0.3)

print("\n" + "="*60)
print("LAB 3 — ÉVALUATION + SHAP")
print("="*60)

import shap
explainer = shap.TreeExplainer(lgbm)
shap_idx = np.random.RandomState(42).choice(len(X_test), size=min(2000, len(X_test)), replace=False)
X_shap = X_test[shap_idx]
shap_values = explainer.shap_values(X_shap)
if isinstance(shap_values, list):
    shap_vals = shap_values[1]
else:
    shap_vals = shap_values

mean_abs_shap = np.abs(shap_vals).mean(axis=0)
sorted_idx = np.argsort(mean_abs_shap)[::-1]
top_n = min(12, len(feature_names))

ax_shap = fig.add_subplot(gs[2, 0])
style_ax(ax_shap, "Lab 3 — SHAP importance")
top_names = [feature_names[i] for i in sorted_idx[:top_n]][::-1]
top_vals = [mean_abs_shap[i] for i in sorted_idx[:top_n]][::-1]

MODIFIABLE_BASES = {"insulin", "change", "num_medications", "a1c_tested",
                    "discharge_group", "outpatient_bkt", "emergency_cap"}

def is_modifiable(fname):
    for base in MODIFIABLE_BASES:
        if fname == base or fname.startswith(base + "_"):
            return True
    return False

bar_colors_shap = [COLORS["green"] if is_modifiable(n) else COLORS["blue"] for n in top_names]
ax_shap.barh(range(len(top_names)), top_vals, color=bar_colors_shap, alpha=0.8, height=0.6)
ax_shap.set_yticks(range(len(top_names)))
ax_shap.set_yticklabels(top_names, fontsize=7)
ax_shap.set_xlabel("Mean |SHAP|", color=COLORS["text"], fontsize=8)

# Legend for modifiable
from matplotlib.patches import Patch
legend_elements = [Patch(facecolor=COLORS["green"], label="Modifiable"),
                   Patch(facecolor=COLORS["blue"], label="Non-modifiable")]
ax_shap.legend(handles=legend_elements, fontsize=7, facecolor=COLORS["card"],
               edgecolor=COLORS["grid"], labelcolor=COLORS["text"], loc="lower right")

ratio = lgbm_pr / full_pr
ratio_cal = cal_pr / full_pr
print(f"  Ratio PR-AUC patient/full (modèles bruts)   : {ratio:.1%}")
print(f"  Ratio PR-AUC patient calibré/full (Lab 3)   : {ratio_cal:.1%} (cible ≥ 85-90%)")
print(f"  SHAP top 3 : {', '.join(top_names[-3:][::-1])}")

status_text("Lab 3 — Évaluation ✓")
pause(1.5)

# ══════════════════════════════════════════════════════════════════════════════
# LAB 4 — TUNING
# ══════════════════════════════════════════════════════════════════════════════

status_text("Lab 4 — Tuning (40 combos × 5 folds)…")
pause(0.3)

print("\n" + "="*60)
print("LAB 4 — TUNING")
print("="*60)

param_distributions = {
    "n_estimators":      randint(200, 800),
    "learning_rate":     uniform(0.01, 0.14),
    "max_depth":         randint(3, 8),
    "num_leaves":        randint(15, 63),
    "min_child_samples": randint(20, 100),
    "subsample":         uniform(0.6, 0.35),
    "colsample_bytree":  uniform(0.5, 0.45),
    "reg_alpha":         uniform(0, 1.0),
    "reg_lambda":        uniform(0.5, 2.5),
}

base = lgb.LGBMClassifier(scale_pos_weight=scale_pos, random_state=42, verbose=-1, n_jobs=-1)
gkf = GroupKFold(n_splits=5)

search = RandomizedSearchCV(
    base, param_distributions, n_iter=40, scoring="average_precision",
    cv=gkf, random_state=42, verbose=0, n_jobs=-1,
)
search.fit(X_train, y_train, groups=groups)

best = search.best_estimator_
tuned_proba = best.predict_proba(X_test)[:, 1]
tuned_pr = average_precision_score(y_test, tuned_proba)
tuned_roc = roc_auc_score(y_test, tuned_proba)
tuned_brier = brier_score_loss(y_test, tuned_proba)
metrics_log["Tuné"] = {"PR-AUC": tuned_pr, "ROC-AUC": tuned_roc, "Brier": tuned_brier}
print(f"  Tuné        : PR-AUC={tuned_pr:.4f}  ROC-AUC={tuned_roc:.4f}")
print(f"  Best CV     : {search.best_score_:.4f}")

# Calibrate tuned
tuned_for_cal = lgb.LGBMClassifier(**best.get_params())
tuned_for_cal.fit(X_train[cal_train_idx], y_train[cal_train_idx])
cal_tuned = CalibratedClassifierCV(tuned_for_cal, method="isotonic", cv="prefit")
cal_tuned.fit(X_train[cal_val_idx], y_train[cal_val_idx])
cal_tuned_proba = cal_tuned.predict_proba(X_test)[:, 1]
cal_tuned_pr = average_precision_score(y_test, cal_tuned_proba)
cal_tuned_roc = roc_auc_score(y_test, cal_tuned_proba)
cal_tuned_brier = brier_score_loss(y_test, cal_tuned_proba)
metrics_log["Tuné+Cal"] = {"PR-AUC": cal_tuned_pr, "ROC-AUC": cal_tuned_roc, "Brier": cal_tuned_brier}
print(f"  Tuné+Cal    : PR-AUC={cal_tuned_pr:.4f}  Brier={cal_tuned_brier:.4f}")

draw_metrics_table()
pr_curves["Tuné"] = tuned_proba
pr_curves["Tuné+Cal"] = cal_tuned_proba
draw_pr_curves(pr_curves)

# Before/after bar chart
ax_compare = fig.add_subplot(gs[2, 1])
style_ax(ax_compare, "Lab 4 — Avant / Après tuning")
compare_labels = ["PR-AUC", "ROC-AUC"]
before_vals = [lgbm_pr, lgbm_roc]
after_vals = [tuned_pr, tuned_roc]
x = np.arange(len(compare_labels))
w = 0.3
ax_compare.bar(x - w/2, before_vals, w, label="Avant", color=COLORS["orange"], alpha=0.8)
ax_compare.bar(x + w/2, after_vals, w, label="Après", color=COLORS["green"], alpha=0.8)
ax_compare.set_xticks(x)
ax_compare.set_xticklabels(compare_labels)
ax_compare.set_ylim(0, 0.8)
for i in range(len(compare_labels)):
    delta = (after_vals[i] - before_vals[i]) / before_vals[i] * 100
    ax_compare.text(x[i] + w/2, after_vals[i] + 0.01, f"+{delta:.1f}%",
                    ha="center", color=COLORS["green"], fontsize=8, fontweight="bold")
ax_compare.legend(fontsize=7, facecolor=COLORS["card"], edgecolor=COLORS["grid"],
                  labelcolor=COLORS["text"])

# Final summary
ax_summary = fig.add_subplot(gs[2, 2])
style_ax(ax_summary, "Résumé final")
ax_summary.axis("off")

risk_tuned = np.where(cal_tuned_proba >= threshold_high, "high",
                      np.where(cal_tuned_proba >= threshold_med, "medium", "low"))
high_cap = y_test[risk_tuned == "high"].sum() / total_re
mh_cap = y_test[risk_tuned != "low"].sum() / total_re

summary = (
    f"Meilleur modèle : Tuné + Calibré\n"
    f"─────────────────────────────\n"
    f"PR-AUC   : {cal_tuned_pr:.4f}\n"
    f"ROC-AUC  : {cal_tuned_roc:.4f}\n"
    f"Brier    : {cal_tuned_brier:.4f}\n"
    f"─────────────────────────────\n"
    f"HIGH capture     : {high_cap:.1%}\n"
    f"MED+HIGH capture : {mh_cap:.1%}\n"
    f"─────────────────────────────\n"
    f"Tuning gain PR   : {(tuned_pr-lgbm_pr)/lgbm_pr*100:+.1f}%\n"
    f"Tuning gain ROC  : {(tuned_roc-lgbm_roc)/lgbm_roc*100:+.1f}%\n"
    f"─────────────────────────────\n"
    f"Features         : {len(feature_names)}\n"
    f"Anti-fuite       : ✓"
)
ax_summary.text(0.08, 0.95, summary, transform=ax_summary.transAxes,
                fontsize=9, fontfamily="monospace", color=COLORS["text"],
                verticalalignment="top")

status_text("Pipeline terminé ✓")

print("\n" + "="*60)
print("PIPELINE TERMINÉ")
print("="*60)
print(f"  Dashboard ouvert dans la fenêtre matplotlib.")
print(f"  Fermez la fenêtre pour quitter.")

fig.savefig(FIGS / "00_dashboard.png", dpi=150, facecolor=COLORS["bg"])
print(f"  Dashboard sauvegardé : {FIGS / '00_dashboard.png'}")

plt.ioff()
plt.show()
