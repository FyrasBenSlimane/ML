# fyras/ — CareStep: a 30-day recovery companion for diabetic patients

Diabetes 130-US Hospitals (1999–2008) — Advanced ML project.

This folder develops **one patient-centered idea**: instead of only predicting who will be readmitted, we turn each patient's risk factors into a **personal daily plan**, check **every day** what the patient actually did, and send a **clear summary and questions** to their care team.

> We turn each patient's risk factors into a personal daily plan, check every day what they did, and share the result with their care team before it becomes a readmission.

## Files
| File | Content |
|---|---|
| [01_vision_and_problem.md](01_vision_and_problem.md) | The problem, the gap we fill, the product in one page |
| [02_objective_OM_ODS.md](02_objective_OM_ODS.md) | The single OM and its ODS, KPIs, success criteria |
| [03_model_and_features.md](03_model_and_features.md) | The patient-friendly model: features, target, training, evaluation |
| [04_action_plan_engine.md](04_action_plan_engine.md) | From the model's explanations (SHAP) to a personal checklist |
| [05_daily_checkin.md](05_daily_checkin.md) | Daily questions, the 30-day schedule, adherence score, alert levels |
| [06_care_team_summary.md](06_care_team_summary.md) | Weekly summary, questions for the doctor, care team dashboard |
| [07_architecture_and_deployment.md](07_architecture_and_deployment.md) | System design, data model, API, tech stack, deployment |
| [08_evaluation_ethics_limits.md](08_evaluation_ethics_limits.md) | How we evaluate, safety, privacy, fairness, limits, future work |
| [09_demo_scenario.md](09_demo_scenario.md) | A full 30-day journey of one patient, step by step |

## What is ML and what is not
| Part | Type | Trained on the dataset? |
|---|---|---|
| Discharge risk score | ML model | ✅ Yes |
| Personal risk factors | SHAP on the model | ✅ Derived from the model |
| Action plan | Rule table on SHAP output | Rules |
| Daily check-in, adherence score, alerts | Rule engine | Rules |
| Summary and questions | Templates | Rules |

The dataset stops at discharge, so only the risk part is learned. Being explicit about this is part of the project's rigor.

**Dataset:** https://archive.ics.uci.edu/dataset/296/diabetes+130-us+hospitals+for+years+1999-2008
**Reference paper:** Strack et al. (2014), *Impact of HbA1c Measurement on Hospital Readmission Rates*, BioMed Research International.
