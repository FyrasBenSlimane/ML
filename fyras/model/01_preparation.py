"""
CareStep — Lab 1 : Préparation des données
===========================================
Dataset : Diabetes 130-US Hospitals (UCI #296)
Membre  : Fyras

Pipeline :
  1. Chargement du CSV
  2. Exclusion décès / palliatifs (disposition 11,13,14,19,20,21)
  3. Construction de la cible binaire  y = 1 si readmitted == "<30"
  4. Création des 12 features patient-friendly
  5. Split anti-fuite par patient (GroupShuffleSplit sur patient_nbr)
  6. Sauvegarde des jeux train / test + pipeline sklearn
"""

import pandas as pd
import numpy as np
from pathlib import Path
from sklearn.model_selection import GroupShuffleSplit
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OrdinalEncoder, OneHotEncoder, FunctionTransformer
import joblib

_HERE = Path(__file__).resolve().parent
DATA_PATH = next(p for p in [
    _HERE.parent / "extracted_data" / "diabetic_data.csv",           # local copy next to model/
    _HERE.parents[1] / "capalit_ml" / "diabetic_data.csv",            # team repo (fyras/model/)
    _HERE.parents[1] / "extracted_data" / "diabetic_data.csv",
] if p.exists())
OUT = Path(__file__).resolve().parent
OUT.mkdir(exist_ok=True)

# ── 1. Chargement ────────────────────────────────────────────────────────────

print("1. Chargement du dataset…")
df = pd.read_csv(DATA_PATH)
print(f"   {df.shape[0]:,} encounters, {df.shape[1]} colonnes")
print(f"   Patients uniques : {df['patient_nbr'].nunique():,}")

# ── 2. Exclusion décès / palliatifs ──────────────────────────────────────────

EXCLUDE_DISPOSITIONS = {11, 13, 14, 19, 20, 21}
mask = df["discharge_disposition_id"].isin(EXCLUDE_DISPOSITIONS)
print(f"\n2. Exclusion décès/palliatifs : {mask.sum():,} lignes retirées "
      f"(dispositions {sorted(EXCLUDE_DISPOSITIONS)})")
df = df[~mask].copy()

# Exclure gender Unknown/Invalid (Protocol Rule 2)
gender_mask = df["gender"].isin(["Unknown/Invalid"])
print(f"   Exclusion gender Unknown/Invalid : {gender_mask.sum()} lignes retirées")
df = df[~gender_mask].copy()
print(f"   Restant : {df.shape[0]:,} encounters")

# ── 3. Cible binaire ────────────────────────────────────────────────────────

df["y"] = (df["readmitted"] == "<30").astype(int)
prev = df["y"].mean()
print(f"\n3. Cible y = readmitted < 30 jours")
print(f"   Positifs : {df['y'].sum():,} / {len(df):,} ({prev:.1%})")

# ── 4. Construction des 12 features patient ─────────────────────────────────

print("\n4. Construction des 12 features patient…")

# 4a. age — déjà en buckets dans le dataset, encoder en ordinal
AGE_ORDER = ["[0-10)", "[10-20)", "[20-30)", "[30-40)", "[40-50)",
             "[50-60)", "[60-70)", "[70-80)", "[80-90)", "[90-100)"]
df["age_ord"] = df["age"].map({a: i for i, a in enumerate(AGE_ORDER)})

# 4b. gender — binary
df["gender_bin"] = (df["gender"] == "Male").astype(int)

# 4c-e. visites passées — cap à 3
df["inpatient_cap"] = df["number_inpatient"].clip(upper=3)
df["emergency_cap"] = df["number_emergency"].clip(upper=3)

# outpatient — bucket
def bucket_outpatient(x):
    if x == 0: return 0
    if x <= 2: return 1
    if x <= 5: return 2
    return 3
df["outpatient_bkt"] = df["number_outpatient"].apply(bucket_outpatient)

# 4f. time_in_hospital — tel quel
# (déjà numérique, 1-14)

# 4g. diag_1 — regroupement ICD-9 en 7 familles patient
def group_diag(code):
    """Regroupe un code ICD-9 en famille patient-friendly."""
    if pd.isna(code) or code == "?":
        return "other"
    try:
        num = float(code)
    except ValueError:
        if code.startswith("V"):
            return "other"
        if code.startswith("E"):
            return "injury"
        return "other"

    if 390 <= num <= 459 or num == 785:
        return "circulatory"
    if 460 <= num <= 519 or num == 786:
        return "respiratory"
    if 250 <= num < 251:
        return "diabetes"
    if 520 <= num <= 579 or num == 787:
        return "digestive"
    if (580 <= num <= 629 or 1 <= num <= 139
            or 680 <= num <= 709 or num == 788):
        return "infection_renal"
    if 800 <= num <= 999:
        return "injury"
    return "other"

df["diag_group"] = df["diag_1"].apply(group_diag)
print(f"   diag_group distribution :")
for g, c in df["diag_group"].value_counts().items():
    print(f"     {g:20s} : {c:6,} ({c/len(df):.1%})")

# 4h. num_medications — tel quel

# 4i. insulin — déjà catégoriel (No, Steady, Up, Down)

# 4j. change — déjà Ch / No

# 4k. A1Cresult — binariser en tested (>7, >8, Norm) vs None
df["a1c_tested"] = df["A1Cresult"].notna().astype(int)

# 4l. discharge_disposition — regrouper en 3 classes
def group_disposition(d):
    """home / home_with_help / facility"""
    if d in (1, 8):
        return "home"
    if d in (6,):
        return "home_with_help"
    # SNF, rehab, autre institution, etc.
    return "facility"

df["discharge_group"] = df["discharge_disposition_id"].apply(group_disposition)

# ── Liste finale des 12 features ────────────────────────────────────────────

PATIENT_FEATURES = [
    "age_ord",           # 1. âge (ordinal 0-9)
    "gender_bin",        # 2. genre (0/1)
    "inpatient_cap",     # 3. séjours passés (0-3)
    "emergency_cap",     # 4. urgences passées (0-3)
    "outpatient_bkt",    # 5. consultations passées (0-3)
    "time_in_hospital",  # 6. durée séjour (1-14)
    "diag_group",        # 7. raison principale (7 cat)
    "num_medications",   # 8. nb médicaments
    "insulin",           # 9. changement insuline (4 cat)
    "change",            # 10. autre médicament changé (2 cat)
    "a1c_tested",        # 11. test HbA1c fait (0/1)
    "discharge_group",   # 12. destination sortie (3 cat)
]

# Features numériques vs catégorielles
NUM_FEATURES = ["age_ord", "gender_bin", "inpatient_cap", "emergency_cap",
                "outpatient_bkt", "time_in_hospital", "num_medications",
                "a1c_tested"]
CAT_FEATURES = ["diag_group", "insulin", "change", "discharge_group"]

print(f"\n   12 features patient : {PATIENT_FEATURES}")
print(f"   Numériques ({len(NUM_FEATURES)}) : {NUM_FEATURES}")
print(f"   Catégorielles ({len(CAT_FEATURES)}) : {CAT_FEATURES}")

# ── Features complètes (pour le modèle de référence) ────────────────────────

ALL_FEATURES_EXTRA = [
    "num_lab_procedures", "num_procedures", "number_diagnoses",
    "admission_type_id", "admission_source_id",
]
FULL_NUM = NUM_FEATURES + ALL_FEATURES_EXTRA
FULL_CAT = CAT_FEATURES + ["medical_specialty"]

# Nettoyer medical_specialty (remplacer ? par "Unknown")
df["medical_specialty"] = df["medical_specialty"].replace("?", "Unknown")
df["race"] = df["race"].replace("?", "Unknown")

# ── 5. Split anti-fuite par patient ──────────────────────────────────────────

print("\n5. Split train/test par patient (80/20)…")
gss = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
groups = df["patient_nbr"].values

train_idx, test_idx = next(gss.split(df, df["y"], groups))

df_train = df.iloc[train_idx].copy()
df_test = df.iloc[test_idx].copy()

# Vérifier aucun patient en commun
train_patients = set(df_train["patient_nbr"])
test_patients = set(df_test["patient_nbr"])
assert train_patients.isdisjoint(test_patients), "FUITE : patients en commun !"

print(f"   Train : {len(df_train):,} encounters, {len(train_patients):,} patients")
print(f"   Test  : {len(df_test):,} encounters, {len(test_patients):,} patients")
print(f"   Prévalence train : {df_train['y'].mean():.3f}")
print(f"   Prévalence test  : {df_test['y'].mean():.3f}")
print(f"   Patients en commun : {len(train_patients & test_patients)} (doit être 0)")

# ── 6. Construction du preprocessor sklearn ──────────────────────────────────

print("\n6. Construction du preprocessor sklearn…")

# Preprocessor pour les 12 features patient
patient_preprocessor = ColumnTransformer(
    transformers=[
        ("num", "passthrough", NUM_FEATURES),
        ("cat", OneHotEncoder(handle_unknown="infrequent_if_exist",
                              sparse_output=False, drop="if_binary"),
         CAT_FEATURES),
    ],
    remainder="drop",
    verbose_feature_names_out=False,
)

# Preprocessor pour toutes les features (référence)
full_preprocessor = ColumnTransformer(
    transformers=[
        ("num", "passthrough", FULL_NUM),
        ("cat", OneHotEncoder(handle_unknown="infrequent_if_exist",
                              sparse_output=False, drop="if_binary"),
         FULL_CAT),
    ],
    remainder="drop",
    verbose_feature_names_out=False,
)

# Fit sur le train
X_train_patient = patient_preprocessor.fit_transform(df_train)
X_test_patient = patient_preprocessor.transform(df_test)
patient_feature_names = patient_preprocessor.get_feature_names_out()

X_train_full = full_preprocessor.fit_transform(df_train)
X_test_full = full_preprocessor.transform(df_test)
full_feature_names = full_preprocessor.get_feature_names_out()

y_train = df_train["y"].values
y_test = df_test["y"].values

print(f"   Patient features shape : {X_train_patient.shape}")
print(f"   Full features shape    : {X_train_full.shape}")
print(f"   Patient feature names  : {list(patient_feature_names)}")

# ── 7. Sauvegarde ────────────────────────────────────────────────────────────

print("\n7. Sauvegarde…")

artifacts = {
    "X_train_patient": X_train_patient,
    "X_test_patient": X_test_patient,
    "X_train_full": X_train_full,
    "X_test_full": X_test_full,
    "y_train": y_train,
    "y_test": y_test,
    "patient_feature_names": list(patient_feature_names),
    "full_feature_names": list(full_feature_names),
    "patient_preprocessor": patient_preprocessor,
    "full_preprocessor": full_preprocessor,
    "groups_train": df_train["patient_nbr"].values,
    "df_test": df_test,  # pour SHAP / démo
}

joblib.dump(artifacts, OUT / "prepared_data.pkl")
print(f"   Sauvegardé : {OUT / 'prepared_data.pkl'}")

# ── Résumé ───────────────────────────────────────────────────────────────────

print("\n" + "="*60)
print("RÉSUMÉ PRÉPARATION")
print("="*60)
print(f"  Encounters totaux  : {df.shape[0]:,}")
print(f"  Train              : {len(df_train):,} ({len(df_train)/len(df):.0%})")
print(f"  Test               : {len(df_test):,} ({len(df_test)/len(df):.0%})")
print(f"  Prévalence (y=1)   : {df['y'].mean():.3f}")
print(f"  Features patient   : {len(patient_feature_names)}")
print(f"  Features complètes : {len(full_feature_names)}")
print(f"  Anti-fuite         : GroupShuffleSplit sur patient_nbr ✓")
print(f"  Décès exclus       : ✓")
print("="*60)
