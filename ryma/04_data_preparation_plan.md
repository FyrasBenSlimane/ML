# 04 — Data preparation plan (the traps other groups will miss)

## 1. Patient leakage
`patient_nbr` repeats: ~101k encounters come from ~70k patients. A random split puts the same patient in train and test and inflates scores.
**Fix:** split by patient (`GroupShuffleSplit`, `GroupKFold` with `groups=patient_nbr`), or keep each patient's first encounter (as Strack et al. did).

## 2. Patients who cannot be readmitted
Remove encounters where the patient **died** (`discharge_disposition_id` 11, 19, 20, 21) or went to **hospice** (13, 14). Verify the IDs in `IDS_mapping.csv`.

## 3. Missing values (`?`)
| Column | Approx. missing | Action |
|---|---|---|
| `weight` | ~97% | Drop |
| `payer_code` | ~40% | Keep, "Missing" category |
| `medical_specialty` | ~50% | Keep, "Missing" category; group rare specialties |
| `race` | small | "Missing" category |
| `gender` | `Unknown/Invalid` (few rows) | Drop those rows |

## 4. Diagnosis codes → clinical families (diag_1/2/3)
| Family | ICD-9 codes |
|---|---|
| Circulatory | 390–459, 785 |
| Respiratory | 460–519, 786 |
| Digestive | 520–579, 787 |
| Diabetes | 250.xx |
| Injury | 800–999 |
| Musculoskeletal | 710–739 |
| Genitourinary | 580–629, 788 |
| Neoplasms | 140–239 |
| Other | everything else, including V and E codes |

## 5. Medication and other features
- Engineer `num_med_changes`, `insulin_changed`, `total_prior_visits`.
- Map `age` brackets to ordinal values.
- Drop constant / near-constant drug columns.
- Check that `A1Cresult` / `max_glu_serum` value `None` is kept as "Not tested".

## 6. Target
`y = (readmitted == "<30").astype(int)` — imbalanced (~11% positives) → class weights, stratification within group splits, PR-AUC.

## 7. One pipeline
Everything (cleaning, grouping, encoding, model) lives in **one sklearn `Pipeline` / `ColumnTransformer`**, fit only on training data, so training and serving use identical code and nothing from test leaks into preprocessing.

## Leakage checklist
- [ ] Split by patient
- [ ] Preprocessing fit on train only
- [ ] No feature that exists only after discharge
- [ ] Dead / hospice encounters removed
- [ ] Suspiciously high scores (ROC-AUC ≫ 0.75) investigated
