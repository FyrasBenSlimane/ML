# 06 — Patient-facing tool

Most groups will build a tool for hospital staff only. We add a view that **patients and their families** can use.

## Key challenge
Patients don't know most dataset features (ICD-9 codes, number of lab tests…). A patient tool must use **only questions a patient can answer**:

| Question to the patient | Dataset feature |
|---|---|
| Age, gender | `age`, `gender` |
| Hospital stays / ER visits / clinic visits in the past year | `number_inpatient`, `number_emergency`, `number_outpatient` |
| Days in hospital this time | `time_in_hospital` |
| Main reason for the stay (plain list: heart, breathing, diabetes complication, infection, injury…) | `diag_1` family |
| Number of medications taken | `num_medications` |
| Insulin / diabetes medication changed? | `insulin`, `change` |
| HbA1c test done? | `A1Cresult` |
| Going home, home with help, or a care facility? | `discharge_disposition_id` (grouped) |

## Patient-centered OMs
- **OM-P1 — Understand my risk:** a patient answers simple questions and learns whether their 30-day risk is low, medium or high.
- **OM-P2 — Know what to do at home:** a personal checklist (follow-up visit, medication review, HbA1c test).
- **OM-P3 — Talk better with my care team:** a short summary and questions to bring to the next appointment.

## ODS
- **ODS-P1 — Patient-friendly model:** train on patient-answerable features only; compare with the full model. Success: keep ≥ 85–90% of the full model's PR-AUC. Key result: *how much performance do we lose by making the tool usable by patients?*
- **ODS-P2 — Calibrated plain risk levels:** calibrate, then map to low / medium / high with justified thresholds.
- **ODS-P3 — Plain-language advice from SHAP:** advice **only on changeable factors** (medications, follow-up, HbA1c). Non-changeable factors (age) are explained, never turned into advice.
- **ODS-P4 — Safety first:** favor recall on high-risk patients (avoid false reassurance); fairness check across age, gender, race.

## What the patient sees (illustrative)
> **Your risk of returning to hospital in the next 30 days: 🟠 MEDIUM**
>
> **What raises your risk:** hospitalized twice in the past year · insulin dose changed during this stay
>
> **What you can do this week:**
> - ✅ Book a follow-up appointment within 7 days
> - ✅ Ask your doctor or pharmacist to review your new insulin dose
> - ✅ Ask whether you need an HbA1c test (not done this stay)
>
> **Go to the emergency room if:** blood sugar stays very high or very low, or you feel confused, faint or short of breath.
>
> *This tool does not replace your doctor. Always follow your care team's advice.*

## Ethics
- Risks: anxiety, false reassurance.
- A real deployment would need medical validation and possibly regulatory approval.
- The tool never diagnoses, always points to a doctor, and every score comes with actions.

## Best option: one pipeline, two views
- **Staff view:** full model, ranking of patients for follow-up.
- **Patient view:** reduced-feature model, plain risk level, checklist, questions for the doctor.
