# Preparation des Donnees — Equipe ReadmitGuard

**Dataset** : UCI #296 — Diabetes 130-US Hospitals (1999-2008)  
**Notebook** : `00_team_data_preparation.ipynb`  
**Donnees** : `data/splits/` (11 datasets) + `data/processed/cleaned_common.parquet`

---

## IMPORTANT — A lire en premier

> Avant de commencer, **chaque membre doit verifier** que les objectifs, modeles et features decrits ci-dessous correspondent exactement a ce qu'il/elle a prevu.
> Si quelque chose a change dans votre specification (algorithme, features, cible, etc.), **signalez-le immediatement** pour qu'on adapte la preparation.

---

## Ce qui a ete fait (etapes de nettoyage)

1. Chargement du dataset brut : **101,766 lignes x 50 colonnes**
2. Exclusion des patients decedes ou en hospice (discharge_disposition_id 11,13,14,19,20,21) → **-2,423 lignes**
3. Suppression des 3 lignes avec gender = "Unknown/Invalid"
4. Suppression de la colonne `weight` (97% manquant)
5. Remplacement des valeurs manquantes :
   - `payer_code` → "Missing"
   - `medical_specialty` → "Unknown"
   - `race` → "Unknown"
   - `A1Cresult` / `max_glu_serum` → "Not_Tested"
6. Suppression de 13 medicaments quasi-constants (>97% une seule valeur)
7. Groupement ICD-9 en 9 familles cliniques (Strack et al., 2014)
8. Features creees : `age_ordinal`, `total_prior_visits`, `num_med_changes`, `insulin_prescrite`, `metformin_prescrite`, `insulin_changed`
9. Construction de 7 cibles : `target_readmit`, `target_change`, `target_insulin`, `target_suivi`, `target_compagnon`, `target_risque_oubli`, `next_time_in_hospital`
10. **GroupShuffleSplit** (test_size=0.2, random_state=42) — un patient ne peut PAS etre dans train ET test

**Resultat final** : **99,340 lignes** nettoyees, **0 fuite patient** verifiee sur tous les splits.

---

## Comment utiliser son dataset

### Prerequis

```bash
pip install pandas pyarrow scikit-learn
```

### Chargement (identique pour tous)

```python
import pandas as pd

# Remplacer <votre_dataset> par le nom de votre dossier (voir ci-dessous)
X_train = pd.read_parquet("data/splits/<votre_dataset>/X_train.parquet")
X_test = pd.read_parquet("data/splits/<votre_dataset>/X_test.parquet")
y_train = pd.read_parquet("data/splits/<votre_dataset>/y_train.parquet").squeeze()
y_test = pd.read_parquet("data/splits/<votre_dataset>/y_test.parquet").squeeze()

# Pour verifier les groupes patients (anti-leakage)
groups_train = pd.read_parquet("data/splits/<votre_dataset>/groups_train.parquet")
```

### Regles communes

- **NE PAS re-splitter** les donnees (le split par patient est deja fait)
- **NE PAS supprimer d'outliers** (les valeurs extremes sont cliniquement valides)
- **NE PAS fusionner** des datasets de dossiers differents (features differentes pour une raison)
- Utiliser `class_weight='balanced'` pour les classes desequilibrees (pas SMOTE)
- Verifier `features.csv` dans votre dossier pour voir vos colonnes exactes

---

## Instructions par membre

---

### RYMA — ReadmitGuard (readmission + fairness)

> **Verifie que tes modeles sont toujours : Logistic Regression (baseline), Random Forest, XGBoost, LightGBM avec class_weight='balanced'. Verifie aussi que tu utilises toujours SHAP pour les explications et que l'audit fairness couvre race, gender, age, payer. Si quoi que ce soit a change, dis-le avant de commencer.**

**Tes datasets** :
| Dossier | Cible | Lignes train | Features | Usage |
|---------|-------|-------------|----------|-------|
| `data/splits/readmission/` | target_readmit | 79,567 | 38 | Modele principal de readmission |
| `data/splits/patient_friendly/` | target_readmit | 79,567 | 18 | Outil patient (features comprehensibles) |
| `data/splits/equity/` | target_readmit | train+test | full | Audit fairness (contient race, gender, age) |

**Etapes** :
1. Charger `readmission/` → entrainer tes 4 modeles (LR, RF, XGBoost, LightGBM)
2. Evaluer avec ROC-AUC, PR-AUC, Brier score, matrice de confusion
3. Appliquer SHAP sur le meilleur modele
4. Charger `equity/` → audit fairness (recall et calibration par sous-groupe)
5. Charger `patient_friendly/` → modele simplifie pour l'outil patient Streamlit
6. Deployer via FastAPI + Streamlit

**Target** : `target_readmit` = 1 si readmis en <30 jours (11.4% positifs → classe desequilibree)

---

### FYRAS — CareStep (outil patient)

> **Verifie que tes modeles sont toujours : Logistic Regression (baseline) + LightGBM/XGBoost en version features reduites. Verifie que tu classes en 3 niveaux de risque (Low/Medium/High). Si quoi que ce soit a change, dis-le avant de commencer.**

**Ton dataset** :
| Dossier | Cible | Lignes train | Features | Usage |
|---------|-------|-------------|----------|-------|
| `data/splits/patient_friendly/` | target_readmit | 79,567 | 18 | CareStep — features patient-reportables uniquement |

**Etapes** :
1. Charger `patient_friendly/`
2. Entrainer Logistic Regression (baseline) + LightGBM/XGBoost
3. Evaluer avec PR-AUC, ROC-AUC, Brier score
4. Definir 3 seuils pour classification Low/Medium/High risk
5. Integrer dans l'outil patient avec plan d'action personnalise
6. Generer le daily check-in et le resume equipe soignante

**18 features** : age_ordinal, gender, race, time_in_hospital, num_medications, number_diagnoses, total_prior_visits, num_lab_procedures, num_procedures, diag_1/2/3_group, A1Cresult, max_glu_serum, insulin_prescrite, metformin_prescrite, diabetesMed, num_med_changes

---

### NAJD — Planification des lits (2 modeles)

> **Verifie que tes modeles sont toujours : Modele A = HistGradientBoosting ou XGBoost (classification), Modele B = regression quantile (10e-90e percentile). Verifie que les seuils de probabilite sont 14% et 21% pour le Modele A. Si quoi que ce soit a change, dis-le avant de commencer.**

**Tes datasets** :
| Dossier | Cible | Lignes train | Features | Usage |
|---------|-------|-------------|----------|-------|
| `data/splits/readmission/` | target_readmit | 79,567 | 38 | Modele A : probabilite de retour |
| `data/splits/najd_b/` | next_time_in_hospital | 37,585 | 38 | Modele B : duree de sejour (regression) |

**Etapes** :
1. **Modele A** : Charger `readmission/` → HistGradientBoosting/XGBoost classification
   - Calibrer les probabilites
   - Appliquer seuils 14% et 21% pour planning rendez-vous
2. **Modele B** : Charger `najd_b/` → regression quantile sur duree de sejour
   - Ce subset contient uniquement les patients readmis (<30 ou >30)
   - Baseline a battre : "toujours 4 jours" (mediane)
   - Attention : correlation faible (r~0.21), signal limite
3. Combiner les deux pour la planification des lits

**Note** : `najd_b/` est un sous-ensemble (patients readmis uniquement) avec son propre GroupShuffleSplit.

---

### EMNA — Changement de traitement + Insuline (2 modeles)

> **Verifie que tes modeles sont toujours : DecisionTreeClassifier (max_depth=6, min_samples_leaf=50, class_weight='balanced') pour les deux modeles. Verifie que tu ne comptes pas utiliser insulin_prescrite comme feature pour le modele insuline (leakage). Si quoi que ce soit a change, dis-le avant de commencer.**

**Tes datasets** :
| Dossier | Cible | Lignes train | Features | Usage |
|---------|-------|-------------|----------|-------|
| `data/splits/treatment_change/` | target_change | 79,567 | 23 | Modele 1 : changement de traitement |
| `data/splits/treatment_insulin/` | target_insulin | 79,567 | 22 | Modele 2 : besoin insuline |

**Etapes** :
1. **Modele 1** : Charger `treatment_change/` → DecisionTreeClassifier
   - target_change = 46.4% positifs (quasi equilibre)
   - Ce dataset INCLUT insulin_prescrite et metformin_prescrite (pas de leakage ici)
2. **Modele 2** : Charger `treatment_insulin/` → DecisionTreeClassifier
   - target_insulin = 23.0% positifs → utiliser class_weight='balanced'
   - Ce dataset EXCLUT insulin_prescrite (anti-leakage : on ne peut pas predire un changement d'insuline en sachant deja si l'insuline est prescrite)
   - Inclut metformin_prescrite (pas de leakage)
3. Evaluer les deux modeles separement
4. Combiner les predictions pour la vision globale traitement

**Anti-leakage** : La difference entre les deux datasets est que `treatment_change/` a 23 features (avec insulin_prescrite) et `treatment_insulin/` a 22 features (sans insulin_prescrite).

---

### FATMA — 5 sous-projets patient

> **Verifie que tes modeles sont toujours : DecisionTreeClassifier pour les 5 sous-projets, avec class_weight='balanced' quand necessaire. Verifie aussi que le Modele 4 (compagnon) utilise bien A1Cresult comme cible et le Modele 5 (rappel) utilise bien age>=70 ET medications>=15. Si quelque chose a change dans tes specifications, dis-le avant de commencer.**

**Tes datasets** :
| # | Dossier | Cible | Lignes train | Features | Usage |
|---|---------|-------|-------------|----------|-------|
| 1 | `data/splits/treatment_change/` | target_change | 79,567 | 23 | Changement de traitement |
| 2 | `data/splits/treatment_insulin/` | target_insulin | 79,567 | 22 | Besoin insuline |
| 3 | `data/splits/suivi/` | target_suivi | 79,567 | 20 | Qualite de suivi medical |
| 4 | `data/splits/compagnon/` | target_compagnon | 36,632 | 15 | Compagnon du quotidien |
| 5 | `data/splits/rappel/` | target_risque_oubli | 79,567 | 16 | Rappel utile (risque oubli) |

**Etapes** :
1. **Sous-projet 1** : Charger `treatment_change/` → DecisionTreeClassifier
   - target_change = 46.4% (quasi equilibre, pas besoin de class_weight)
2. **Sous-projet 2** : Charger `treatment_insulin/` → DecisionTreeClassifier
   - target_insulin = 23.0% → class_weight='balanced'
   - Sans insulin_prescrite (anti-leakage)
3. **Sous-projet 3** : Charger `suivi/` → DecisionTreeClassifier
   - target_suivi = 5.5% → **tres desequilibre** → class_weight='balanced' obligatoire
   - Cible composite : A1C teste + glucose teste + visites >= 2
4. **Sous-projet 4** : Charger `compagnon/` → DecisionTreeClassifier
   - target_compagnon = 4.6% → **tres desequilibre** → class_weight='balanced'
   - **Attention** : ce dataset est un sous-ensemble (patients avec 2+ encounters = ~17k train)
   - Cible : pas readmis + traitement stable + bon suivi
5. **Sous-projet 5** : Charger `rappel/` → DecisionTreeClassifier
   - target_risque_oubli = 59.0% (equilibre)
   - Cible : polypharmacie (>=7 meds) + age >= 60 + comorbidites >= 5

**Notes** :
- Sous-projets 1 et 2 partagent les memes datasets qu'Emna (memes splits, memes features)
- Le sous-projet 4 a moins de donnees car filtre sur les patients multi-encounters
- Verifier `features.csv` dans chaque dossier pour la liste exacte des features

---

### FAYCEL — Analytics exploratoire + Fairness (6 objectifs)

> **Verifie que tes modeles sont toujours : Obj 1 = Random Forest/XGBoost, Obj 2 = K-Means clustering, Obj 3 = Apriori/FP-Growth, Obj 4 = ANOVA/Kruskal-Wallis + regression, Obj 5 = K-Means/hierarchique, Obj 6 = XGBoost + SHAP. Si tu as modifie les objectifs 7-12 (jumeau numerique, inference causale, RL, GAN, Sankey, survie), precise comment ils impactent la preparation. Si quoi que ce soit a change, dis-le avant de commencer.**

**Tes datasets** :
| # | Dossier | Cible | Lignes | Features | Usage |
|---|---------|-------|--------|----------|-------|
| 1 | `data/splits/readmission/` | target_readmit | 79,567 train | 38 | Classification readmission |
| 2 | `data/splits/clustering/` | (unsupervised) | 99,340 full | 20 | Polypharmacie (K-Means) |
| 3 | `data/splits/association/` | (unsupervised) | 99,340 full | 13 | Maladies compagnes (Apriori) |
| 4 | `data/splits/equity/` | target_readmit | train+test | full | Audit equite |
| 5 | `data/splits/clustering/` | (unsupervised) | 99,340 full | 20 | Personas patients |
| 6 | `data/splits/readmission/` | target_readmit | 79,567 train | 38 | Simulateur "et si" (SHAP) |

**Etapes** :
1. **Obj 1 — Readmission** : Charger `readmission/` → Random Forest / XGBoost
   - target_readmit = 11.4% → class_weight='balanced'
   - Focus sur le recall
2. **Obj 2 — Polypharmacie** : Charger `clustering/X_full.parquet`
   - Pas de train/test split (unsupervised)
   - Encoder les categoriques avant K-Means (OrdinalEncoder ou OneHot)
   - Calculer un drug-load score si besoin
3. **Obj 3 — Maladies compagnes** : Charger `association/data_association.parquet`
   - Utiliser les colonnes diag_1/2/3_group pour Apriori/FP-Growth
   - Installer `mlxtend` si necessaire : `pip install mlxtend`
   - Binariser les colonnes avant les regles d'association
4. **Obj 4 — Audit equite** : Charger `equity/train_with_sensitive.parquet`
   - Contient les colonnes sensibles (race, gender, age_ordinal) + target
   - ANOVA/Kruskal-Wallis par sous-groupe
   - Regression multivariee pour isoler les effets
5. **Obj 5 — Personas** : Charger `clustering/X_full.parquet`
   - Meme dataset que Obj 2, mais clustering sur des dimensions differentes
   - K-Means ou hierarchique sur (age, emergency_visits, outpatient, medications, insulin)
6. **Obj 6 — Simulateur "et si"** : Charger `readmission/`
   - Entrainer XGBoost puis appliquer SHAP local
   - Permettre de modifier des features et voir l'impact sur la prediction

**Notes** :
- `clustering/` et `association/` n'ont PAS de split train/test (donnees completes pour l'exploration)
- Pour les objectifs 7-12 (jumeau numerique, inference causale, RL, GAN, Sankey, survie) : utiliser `data/processed/cleaned_common.parquet` comme base
- `equity/` contient les features completes + les colonnes sensibles pour l'analyse de biais

---

## Resume des datasets

| Dataset | Train | Test | Features | Membres |
|---------|------:|-----:|---------:|---------|
| `readmission/` | 79,567 | 19,773 | 38 | Ryma, Najd A, Faycel 1/6 |
| `patient_friendly/` | 79,567 | 19,773 | 18 | Fyras, Ryma |
| `treatment_change/` | 79,567 | 19,773 | 23 | Emna, Fatma 1 |
| `treatment_insulin/` | 79,567 | 19,773 | 22 | Emna, Fatma 2 |
| `suivi/` | 79,567 | 19,773 | 20 | Fatma 3 |
| `compagnon/` | 36,632 | 9,062 | 15 | Fatma 4 |
| `rappel/` | 79,567 | 19,773 | 16 | Fatma 5 |
| `najd_b/` | 37,585 | 9,231 | 38 | Najd B |
| `clustering/` | 99,340 | — | 20 | Faycel 2/5 |
| `equity/` | full | full | full | Faycel 4, Ryma |
| `association/` | 99,340 | — | 13 | Faycel 3 |

---

## Structure des fichiers

```
data/
  splits/
    readmission/          # Ryma, Najd A, Faycel 1/6
      X_train.parquet
      X_test.parquet
      y_train.parquet
      y_test.parquet
      groups_train.parquet
      groups_test.parquet
      features.csv
      README.txt
    patient_friendly/     # Fyras, Ryma
      (meme structure)
    treatment_change/     # Emna, Fatma 1
    treatment_insulin/    # Emna, Fatma 2
    suivi/                # Fatma 3
    compagnon/            # Fatma 4
    rappel/               # Fatma 5
    najd_b/               # Najd B
    clustering/           # Faycel 2/5
      X_full.parquet
      features.csv
    equity/               # Faycel 4, Ryma
      train_with_sensitive.parquet
      test_with_sensitive.parquet
    association/          # Faycel 3
      data_association.parquet
  processed/
    cleaned_common.parquet  # Dataset complet nettoye (pour objectifs avances)
```

---

## Questions frequentes

**Q : Puis-je ajouter des features ?**  
R : Oui, a partir de `data/processed/cleaned_common.parquet`. Mais ne modifiez pas les splits existants.

**Q : Le dataset est desequilibre, que faire ?**  
R : Utilisez `class_weight='balanced'` dans votre modele. Ne pas utiliser SMOTE (risque de leakage avec GroupShuffleSplit).

**Q : Comment regenerer les datasets ?**  
R : Executez `00_team_data_preparation.ipynb` du debut a la fin. Tout est reproductible (random_state=42).

**Q : Pourquoi 22 features pour insulin et 23 pour change ?**  
R : `insulin_prescrite` est exclue du dataset insulin pour eviter le data leakage (on ne peut pas predire un changement d'insuline en sachant deja si l'insuline est prescrite).

**Q : Pourquoi `compagnon/` a moins de lignes ?**  
R : C'est un sous-ensemble filtre sur les patients ayant 2+ encounters (necessaire pour evaluer le suivi dans le temps).
