# 03 — The dataset, feature by feature

- **101,766 rows**, 130 US hospitals, 1999–2008, inpatient diabetic encounters, stays of 1–14 days.
- Files: `diabetic_data.csv` (~18 MB), `IDS_mapping.csv` (meaning of the ID codes).
- Missing values are written as `?`.
- **Each row is one hospital stay (encounter), not one person.** The same patient can appear several times.

## Identifiers (never model inputs)
| Feature | Meaning |
|---|---|
| `encounter_id` | Unique number of a hospital stay |
| `patient_nbr` | Unique number of a patient. **Used to split the data by patient** (leakage trap) |

## Who the patient is
| Feature | Meaning |
|---|---|
| `race` | Caucasian, African American, Hispanic, Asian, Other; some `?` |
| `gender` | Male, Female, Unknown/Invalid |
| `age` | 10-year groups like `[70-80)` → converted to ordered numbers |
| `weight` | ~97% missing → **dropped** |
| `payer_code` | Who pays (Medicare, private, self-pay…); ~40% missing → "Missing" category |

## How they arrived and left
| Feature | Meaning |
|---|---|
| `admission_type_id` | Emergency, urgent, elective… (see `IDS_mapping.csv`) |
| `admission_source_id` | Emergency room, doctor referral, transfer… |
| `discharge_disposition_id` | Home, home with care, facility, **died**, hospice… Died/hospice are removed |
| `medical_specialty` | Specialty of the admitting doctor; ~half missing → "Missing" category |

## What happened during the stay
| Feature | Meaning |
|---|---|
| `time_in_hospital` | Days in hospital (1–14) |
| `num_lab_procedures` | Number of lab tests |
| `num_procedures` | Non-lab procedures (scans, small operations) |
| `num_medications` | Distinct medications given |
| `number_diagnoses` | Health problems recorded |

## History (past year)
| Feature | Meaning |
|---|---|
| `number_outpatient` | Clinic visits without an overnight stay |
| `number_emergency` | Emergency room visits |
| `number_inpatient` | Previous hospital stays, **usually the strongest predictor** |

## Diagnoses
| Feature | Meaning |
|---|---|
| `diag_1` | Main reason for this stay (ICD-9 code, e.g. `428` = heart failure) |
| `diag_2`, `diag_3` | Second and third diagnoses |

Hundreds of codes → grouped into clinical families (see 04).

## Diabetes tests
| Feature | Meaning |
|---|---|
| `max_glu_serum` | Blood sugar test: `Norm`, `>200`, `>300`, `None` (not tested) |
| `A1Cresult` | **HbA1c**: `Norm`, `>7`, `>8`, `None` (not tested). The variable studied by the original paper |

⚠️ pandas may read the text `None` as missing. Check it so "not tested" doesn't disappear.

## The 23 diabetes medications
Values: `No` (not prescribed), `Steady` (dose unchanged), `Up` (increased), `Down` (decreased).
- **Insulin**, the most important
- **Metformin**, the most common pill
- **Sulfonylureas:** glipizide, glyburide, glimepiride, chlorpropamide, tolbutamide, tolazamide, acetohexamide
- **Glitazones:** pioglitazone, rosiglitazone, troglitazone
- **Others:** repaglinide, nateglinide, acarbose, miglitol, examide, citoglipton
- **Combinations:** glyburide-metformin, glipizide-metformin, glimepiride-pioglitazone, metformin-rosiglitazone, metformin-pioglitazone

Near-constant columns (e.g. examide, citoglipton are always `No`) carry no information → dropped or merged.

## Summary columns and target
| Feature | Meaning |
|---|---|
| `change` | Any diabetes medication changed? (`Ch` / `No`) |
| `diabetesMed` | Any diabetes medication prescribed? (`Yes` / `No`) |
| `readmitted` | **Target:** `<30`, `>30`, `NO` |

## Features we focus on
**Strongest signals (expected):** `number_inpatient`, `discharge_disposition_id`, `number_emergency`, `number_diagnoses`, `diag_1` family, `time_in_hospital`, `num_medications`, `age`.

**Story features (actionable by doctors):** `insulin`, `change`, `A1Cresult`.

**Engineered features:**
- `total_prior_visits = number_outpatient + number_emergency + number_inpatient`
- `num_med_changes` = number of drugs with `Up` or `Down`
- `insulin_changed`
- diagnosis families from ICD-9

**Sensitive features (`race`, `gender`, `age`):** always used for the fairness audit. Recommended: keep `race` out of model inputs.
