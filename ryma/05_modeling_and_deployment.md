# 05 — Modeling plan and deployment vision ("ReadmitGuard")

## Modeling
1. **Baseline:** logistic regression (class weights).
2. **Candidates:** Random Forest, XGBoost, LightGBM (class weights).
3. **Tuning:** GroupKFold on `patient_nbr`.
4. **Calibration:** Platt or isotonic; Brier score, calibration curve.
5. **Threshold:** chosen with the cost formula (see 02), plus sensitivity analysis.
6. **Explanations:** SHAP on a sample of 2,000–5,000 patients.
7. **Fairness audit:** recall and calibration by race, gender, age, payer.
8. **Model card:** metrics, limits, fairness results, intended use.

Realistic expectations: ROC-AUC mid-0.6s to ~0.70. The ceiling is low because the data has no vital signs, social factors or post-discharge information. A claimed 0.95 almost certainly means leakage.

## ReadmitGuard — a day at the hospital
4 pm. Mr. K., 72, discharged after 6 days for heart failure, type 2 diabetes. The nurse opens ReadmitGuard:

> **30-day readmission risk: 34%** (hospital average 11%) 🔴 HIGH — top 8% of today's discharges
>
> **Why (SHAP):** 3 inpatient stays last year (+9 pts) · discharged to nursing facility (+5) · insulin changed (+4) · no HbA1c this stay (+2) · 18 medications (+2)
>
> **Suggested actions:** pharmacist medication review · order HbA1c · follow-up call within 48 h, clinic visit within 7 days

*(Illustrative example, not real output.)*

## Three views
| View | Who | Shows |
|---|---|---|
| Nurse | Discharge nurse | One patient: risk, reasons, actions |
| Coordinator | Care coordinator | Today's discharges ranked: "You can call 8 patients; these capture ~X% of readmissions" |
| Manager | Hospital manager | Monthly KPIs, estimated savings, fairness panel, drift alerts |

## Architecture
```
diabetic_data.csv
      │
      ▼
[sklearn Pipeline: cleaning → ICD grouping → encoding → model]
      │  GroupKFold, calibration, cost-based threshold
      ▼
model.joblib + model card
      │
      ▼
FastAPI — POST /predict → {risk, level, top_reasons, actions}
      │
      ▼
Streamlit UI (Nurse · Coordinator · Manager · Patient)
      │
      ▼
Docker → Render / Hugging Face Spaces / Streamlit Cloud
      + monitoring: prediction logs, weekly drift check (Evidently)
```

## Closing sentence
> This is a **decision-support tool, not a decision-maker**. It helps a hospital with limited staff spend its follow-up budget where it prevents the most readmissions, and it explains every alert.
