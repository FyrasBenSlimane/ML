# 08 — Evaluation, ethics and limits

## What we can evaluate now (with the dataset)
| Component | Evaluation |
|---|---|
| Risk model | PR-AUC, ROC-AUC, Brier score, calibration curve, recall in the high-risk group, patient-model vs full-model ratio |
| Explanations | Top SHAP drivers make clinical sense; stable across similar patients |
| Action plan | Every medium/high-risk patient gets ≥ 1 action tied to their own top driver |
| Fairness | Recall and calibration gaps across age, gender and race groups |

## What we evaluate with tests and simulation
| Component | Evaluation |
|---|---|
| Adherence score | Unit tests on known answer sequences |
| Alert rules | Test cases for each threshold (e.g. glucose 53 → red, 69 → orange, 120 → none) |
| Summaries | Generated for all simulated patients; questions match the data |
| End-to-end | Simulated 30-day runs for different patient profiles |

## What needs a real pilot
- Effect on the readmission rate (users vs. non-users)
- Check-in completion and patient satisfaction
- Care team workload and alert usefulness

## Safety
- The tool **never diagnoses** and **never changes treatment**; it says "as prescribed" and "ask your doctor".
- Every danger answer points to a doctor or emergency services.
- Alert thresholds must be **validated by clinicians** before real use.
- The low-risk label must not make patients ignore symptoms: warning-sign questions are asked to everyone.

## Privacy
- Health data is sensitive: store only what is needed, encrypt it, and give access only to the patient and the people they choose.
- A real deployment must follow health data rules (e.g. HIPAA in the US, GDPR in Europe).
- The demo uses only the public dataset and simulated patients.

## Fairness
- `race` is not a model input; it is used only for the audit.
- If one group has much lower recall in the high-risk band, adjust thresholds or retrain, and document it in the model card.

## Limits
1. **The dataset stops at discharge.** Only the risk is learned from data; daily tracking uses rules.
2. **Self-reported answers** may differ from hospital records (e.g. number of medicines).
3. **Old data (1999–2008)** from US hospitals: treatments and practices have changed.
4. **Modest predictive power:** ROC-AUC on this dataset is typically mid-0.6s to ~0.70, so the tool supports, never replaces, clinical judgment.
5. **Engagement risk:** patients may stop answering; missed check-ins are themselves tracked as a signal.

## Future work: the data flywheel
Once CareStep runs, every patient produces 30 days of answers **and** a known outcome (readmitted or not). This creates a new dataset to:
- train a **day-by-day risk model** that updates the risk from daily answers,
- learn which actions really reduce readmissions,
- replace illustrative thresholds with data-driven ones.

> Version 1 is guided by the hospital data and clinical rules. Version 2 learns from the patients who use it.
