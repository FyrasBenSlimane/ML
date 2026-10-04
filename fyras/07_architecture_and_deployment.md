# 07 — Architecture and deployment

## Overview
```
                ┌───────────────────────────┐
 diabetic_data  │ Training (offline)        │
 ─────────────► │ sklearn Pipeline + LightGBM│ ──► model.joblib + SHAP explainer
                │ GroupKFold, calibration   │      + model card
                └───────────────────────────┘
                              │
                              ▼
┌──────────────────────── FastAPI backend ─────────────────────────┐
│ /assess   → risk level + SHAP reasons                             │
│ /plan     → action plan engine (rules on SHAP)                    │
│ /checkin  → store answers, compute score, run alert rules         │
│ /summary  → weekly summary + questions for the doctor             │
│ /dashboard→ care team list                                        │
└──────────────────────────────────────────────────────────────────┘
          │                        │
          ▼                        ▼
   Database (SQLite →        Frontend (Streamlit or React)
   PostgreSQL)               - Patient app: assessment, plan, daily check-in
                             - Care team dashboard
```

## API
| Method | Endpoint | Input | Output |
|---|---|---|---|
| POST | `/assess` | Discharge answers (see 03) | `{probability, level, reasons[]}` |
| POST | `/plan` | `patient_id` | `{actions[], daily_questions[]}` |
| GET | `/checkin/{patient_id}/{day}` | — | Today's questions |
| POST | `/checkin` | `{patient_id, day, answers}` | `{daily_score, alerts[]}` |
| GET | `/summary/{patient_id}/{week}` | — | Summary + questions |
| GET | `/dashboard` | — | Patients sorted by priority |

## Data model
| Table | Main fields |
|---|---|
| `patients` | id, discharge_date, answers (JSON), probability, level, consent |
| `plans` | patient_id, actions (JSON), questions (JSON) |
| `checkins` | patient_id, day, answers (JSON), daily_score, created_at |
| `alerts` | patient_id, day, level, message, resolved |
| `summaries` | patient_id, week, content, questions |

## Tech stack
| Layer | Choice | Why |
|---|---|---|
| Model | scikit-learn, LightGBM, SHAP | Standard, fast on CPU |
| API | FastAPI | Simple, typed, auto docs |
| Database | SQLite (demo), PostgreSQL (prod) | Easy start, easy upgrade |
| UI | Streamlit (demo) | Fast to build for a student project |
| Notifications | Simulated (demo); SMS/e-mail in a real version | Daily reminders |
| Packaging | Docker | Same environment everywhere |
| Hosting | Hugging Face Spaces / Render | Free tier is enough |
| Monitoring | Prediction logs, Evidently drift report | Detect changes in patients |

## Repository structure (suggested)
```
carestep/
├── data/                 # raw and processed data (not committed if large)
├── notebooks/            # EDA, modeling
├── src/
│   ├── features.py       # patient question → feature mapping
│   ├── train.py          # pipeline training, calibration
│   ├── explain.py        # SHAP
│   ├── plan_rules.py     # action plan engine
│   ├── checkin_rules.py  # adherence score + alerts
│   └── summary.py        # summaries and questions
├── api/main.py           # FastAPI app
├── app/streamlit_app.py  # UI
├── models/               # model.joblib, model card
├── tests/                # unit tests for rules and API
└── Dockerfile
```

## Demo mode
For the final presentation, a **simulated 30-day run**: a script feeds daily answers for 3 example patients (on track, needs support, falling behind) so the jury sees alerts, scores and summaries in a few minutes.
