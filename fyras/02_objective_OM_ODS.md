# 02 — The objective: OM and ODS

## OM — Help patients stay on track at home after discharge

**Give each diabetic patient a personal daily action plan after leaving hospital, check every day what they actually did, and turn their answers into a clear summary and questions for their care team, so they avoid coming back to the hospital.**

### Why this objective
- **Readmissions are often avoidable** with simple home actions (taking medication correctly, follow-up visit, blood sugar monitoring).
- **Patients forget or misunderstand** discharge instructions; a daily check turns instructions into habits.
- **Care teams lack visibility** after discharge; a summary gives them information before the next visit.

### Business KPIs
| KPI | Definition | Target (illustrative) |
|---|---|---|
| Check-in completion | % of the 30 days with a completed check-in | ≥ 70% |
| Early follow-up | % of patients with a follow-up visit within 7 days | ≥ 80% of high-risk patients |
| Alert response | % of orange/red alerts acted on within 24 h | ≥ 90% |
| Readmission rate | 30-day readmission of users vs. non-users | Lower for users (pilot study) |
| Patient understanding | % of patients who can name their top 2 risk factors | ≥ 75% |

Targets are hypotheses to be tested in a pilot, not results from the dataset.

---

## ODS — Personalized plan and daily adherence tracking

**Use the model to find each patient's main *changeable* risk factors, turn them into a personal checklist and daily questions, and score the daily answers to detect patients who are falling behind.**

It breaks down into three technical parts.

### ODS-A — Patient-friendly risk model (ML)
- **Task:** binary classification, `readmitted == "<30"` → 1, else 0.
- **Inputs:** only features a patient can answer (see 03).
- **Metrics:** PR-AUC (target ≥ 2× the ~0.11 baseline), ROC-AUC, Brier score, calibration curve.
- **Comparison:** against a full-feature model; target ≥ 85–90% of its PR-AUC.
- **Output:** calibrated probability → low / medium / high.

### ODS-B — Personal action plan (SHAP + rules)
- **Task:** extract each patient's top changeable risk factors with SHAP and map them to actions and daily questions.
- **Success:** 100% of medium/high-risk patients get at least one action linked to their own top driver; non-changeable factors (age) are explained but never turned into actions.

### ODS-C — Daily tracking, alerts and summary (rule engine)
- **Task:** score daily answers into an adherence score, raise alerts on warning answers, generate weekly summaries.
- **Success:** alert rules match standard diabetes warning signs (validated by clinicians in a real deployment); summaries are generated for 100% of active patients each week; all answers are logged for future modeling.

---

## Traceability
| OM part | Served by |
|---|---|
| Personal action plan | ODS-A (risk factors) + ODS-B (actions) |
| Daily verification | ODS-C (check-in, score, alerts) |
| Communication with the care team | ODS-C (summary, questions) |

## One model
There is only **one ML model** (ODS-A). ODS-B explains and uses it; ODS-C is logic built around it.
