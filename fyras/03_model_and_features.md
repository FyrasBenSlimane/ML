# 03 — The patient-friendly model

## Why a reduced feature set
Patients can't report ICD-9 codes, the number of lab tests or the admitting doctor's specialty. The model must use only what a patient (or caregiver) can answer at discharge.

## Patient questions → dataset features
| Question to the patient | Answer format | Dataset feature | Transformation |
|---|---|---|---|
| How old are you? | Number | `age` | Bucket to 10-year group, ordinal |
| Gender | Choice | `gender` | One-hot (fairness audit) |
| Hospital stays in the past year (other than this one)? | 0, 1, 2, 3+ | `number_inpatient` | Cap at 3+ |
| Emergency room visits in the past year? | 0, 1, 2, 3+ | `number_emergency` | Cap at 3+ |
| Clinic visits in the past year? | 0, 1–2, 3–5, 6+ | `number_outpatient` | Bucket |
| How many days were you in hospital this time? | 1–14 | `time_in_hospital` | As is |
| Main reason for this stay? | Heart, breathing, diabetes problem, digestive, infection/kidney, injury/fall, other | `diag_1` | ICD-9 family grouping |
| How many different medicines do you take now? | Number | `num_medications` | As is (approximation) |
| Was your insulin dose changed? | Increased / decreased / same / no insulin | `insulin` | Up / Down / Steady / No |
| Were other diabetes medicines changed? | Yes / No | `change` | Ch / No |
| Did you have an HbA1c test this stay? | Yes / No / Don't know | `A1Cresult` | Tested vs. None |
| Where are you going after discharge? | Home, home with help, care facility | `discharge_disposition_id` | Grouped into 3 classes |

Note: what the patient reports may differ from the hospital record (e.g. number of medications). This is a known limitation, discussed in 08.

## Target
`y = 1` if `readmitted == "<30"`, else `0` (~11% positives).

## Data preparation (same rules as the main project)
1. Remove encounters ending in death or hospice (`discharge_disposition_id` 11, 13, 14, 19, 20, 21).
2. Split by patient (`GroupShuffleSplit` / `GroupKFold` on `patient_nbr`) to avoid leakage.
3. Group `diag_1` into the same families as the patient's "main reason" list.
4. Map `discharge_disposition_id` to home / home with help / facility (check `IDS_mapping.csv`).
5. Everything in one sklearn `Pipeline`.

## Models
| Step | Model | Purpose |
|---|---|---|
| 1 | Logistic regression | Baseline, easy to explain |
| 2 | LightGBM / XGBoost (class weights) | Best performance |
| 3 | Full-feature LightGBM | Reference: how much do we lose? |

Tuning with GroupKFold; calibration with isotonic or Platt scaling.

## Evaluation
| Metric | Why |
|---|---|
| PR-AUC | Imbalanced classes; focus on readmitted patients |
| ROC-AUC | Standard ranking quality |
| Brier score + calibration curve | Patients read "medium risk" literally |
| Recall in the high-risk group | Avoid falsely reassuring patients at risk |
| Patient model / full model PR-AUC ratio | Cost of usability |

## Risk levels
Thresholds chosen on validation data, for example:
| Level | Rule (illustrative) | Meaning |
|---|---|---|
| 🟢 Low | probability < hospital average (~11%) | Standard plan |
| 🟠 Medium | between average and ~2× average | Plan + closer follow-up |
| 🔴 High | ≥ ~2× average | Plan + care team alerts + daily check-ins mandatory |

The exact cutoffs are set so the high group captures a target share of readmissions (e.g. 50%) while staying small enough for the care team to follow.
