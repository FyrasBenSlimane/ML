# 02 — Objectives: OM (business) and ODS (data science)

- **OM (objectif métier):** what the hospital wants, in its own language (patients, money, quality).
- **ODS (objectif data science):** the technical translation (task, target, metric, success threshold).
- **Rule:** every ODS serves an OM. We show the link explicitly.

We deliberately kept a **tight set: 2 OM and 3 ODS**, all served by **one single model**.

---

## Main OM — Reduce readmissions by helping the right patients
Reduce 30-day readmissions of diabetic patients by targeting limited follow-up resources (calls, pharmacist review, nurse visits) at the highest-risk patients.

**Why:** it is the reason the dataset exists, it is measurable (patients, money), and it gives meaning to everything else.
**Business KPIs:** 30-day readmission rate; share of future readmissions captured in the top X% of flagged patients; savings per unit of money spent.

### ODS1 — Prediction
- **Task:** binary classification. Target: `readmitted == "<30"` → 1, `NO` or `>30` → 0.
- **Inputs:** only information available **at discharge**.
- **Metrics:** PR-AUC (target ≥ 2× the ~0.11 baseline) and ROC-AUC (target ≥ 0.68; published results on this dataset are typically mid-0.6s to ~0.70). Must beat a logistic-regression baseline.
- **Not accuracy:** always predicting "no" already scores ~89% accuracy and is useless.

### ODS2 — Decision
- **Task:** rank patients by risk, choose the alert threshold using costs, not 0.5.
- **Metrics:** recall@top-20% (share of readmissions captured), lift vs. random (target ≥ 2), expected savings per 1,000 discharges.
- **Requires calibrated probabilities** (Platt scaling or isotonic; Brier score, calibration curve).

**Cost formula:**
```
Savings = (readmissions prevented × cost of a readmission)
        − (patients flagged × cost of the intervention)
```
Assumptions (label clearly, run a sensitivity analysis):
- cost of a readmission ≈ $15,000 (AHRQ 2018 figure)
- cost of the intervention ≈ $300 per patient (assumption)
- the intervention prevents ≈ 25% of the readmissions it reaches (assumption)

---

## Secondary OM — A trustworthy and fair tool
Clinicians must understand why a patient is flagged, and no group of patients should be systematically missed.

**Why:** in healthcare nobody uses a black box they don't trust, and an unfair tool can harm patients. Most groups skip this.

### ODS3 — Explainability and fairness
- **SHAP** global and per-patient explanations; top drivers must make clinical sense.
- **Fairness audit:** recall and calibration gaps across race, gender, age and payer groups, kept under an agreed tolerance.
- Sensitive attributes (e.g. `race`) are used for the **audit**; leaving `race` out of the model inputs is the safer, better-defended choice.

---

## One model for all objectives
| Objective | Role with respect to the model |
|---|---|
| ODS1 | **Builds** the model (we compare several algorithms and keep the best) |
| ODS2 | **Uses** its scores: ranking + cost-based threshold, no new model |
| ODS3 | **Explains and audits** the same model |

Analogy: ODS1 builds the thermometer, ODS2 decides at what temperature to call the doctor, ODS3 checks it reads correctly for everyone.

## Traceability matrix
| | ODS1 Prediction | ODS2 Decision | ODS3 Trust |
|---|:-:|:-:|:-:|
| Main OM (reduce readmissions) | ✅ | ✅ | |
| Secondary OM (trust and fairness) | | | ✅ |

## Ideas kept outside the objectives
- **Calibration** → part of ODS2.
- **Deployment and monitoring** → final project phase (see 05).
- **HbA1c care-quality gap** → EDA insight ("patients without an HbA1c test are readmitted more often?").

> If the professor imposes "exactly 1 OM and 1 ODS": use the main OM + ODS1, and move ODS2's cost threshold into ODS1's success criteria.
