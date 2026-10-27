# ReadmitGuard — ML Avancé (Diabetes 130-US Hospitals, UCI #296)

Two apps with six AI avatars, one per team member:

- **MAAK معاك** (`deployment_v2/`): the main app. A Flutter mobile/web app and a FastAPI
  backend with one plug-in module per member. See [`deployment_v2/README.md`](deployment_v2/README.md).
- **ReadmitGuard** (`deployment/`): the Streamlit app. Every avatar's page, model files and
  training code are listed in [`deployment/registry.py`](deployment/registry.py).

| Avatar (MAAK) | Owner | Backend module | App screens |
|---|---|---|---|
| Teemo | Ryma | `deployment_v2/backend/app/modules/teemo/` | `deployment_v2/mobile/lib/features/teemo/` |
| CareStep | Fyras | `deployment_v2/backend/app/modules/carestep/` | `deployment_v2/mobile/lib/features/carestep/` |
| MedOracle | Faycel | `deployment_v2/backend/app/modules/medoracle/` | `deployment_v2/mobile/lib/features/medoracle/` |
| Doza | Emna | `deployment_v2/backend/app/modules/doza/` | `deployment_v2/mobile/lib/features/doza/` |
| Sora | Fatma | `deployment_v2/backend/app/modules/sora/` | `deployment_v2/mobile/lib/features/sora/` |
| BedSense | Najd | `deployment_v2/backend/app/modules/bedsense/` (uses `capalit_ml/`) | `deployment_v2/mobile/lib/features/bedsense/` |

Streamlit app:

| Avatar | Owner | Page | Model files | Trained by |
|---|---|---|---|---|
| Teemo — readmission risk | Ryma | `deployment/app/pages/1_Teemo.py` | `deployment/models/ryma/` | `deployment/train_all_models.py` |
| CareStep — 30-day recovery companion | Fyras | `deployment/app/pages/2_CareStep.py` | `deployment/models/fyras/` | `fyras/model/` (labs 01 → 05) |
| MedOracle — clinical analytics | Faycel | `deployment/app/pages/3_MedOracle.py` | `deployment/models/faycel/` | `deployment/train_all_models.py` |
| RxPredict — treatment change / insulin | Emna | `deployment/app/pages/4_RxPredict.py` | `deployment/models/emna/` | `deployment/train_all_models.py` |
| DailyGuard — patient companion | Fatma | `deployment/app/pages/5_DailyGuard.py` | `deployment/models/fatma/` | `deployment/train_all_models.py` |
| BedSense — bed planning | Najd | `deployment/app/pages/6_BedSense.py` | `capalit_ml/*.joblib` | Najd's notebooks in `capalit_ml/` |

## Repository layout

```
00_team_data_preparation.ipynb   shared cleaning → data/splits/ (see DATA_README.md)
data/splits/                     one prepared dataset per use case
deployment/
  app/Home.py                    entry point: login + links to the six avatars
  app/pages/                     one page per avatar
  app/utils.py                   shared theme and components
  api/main.py                    REST API for every avatar (+ /capalit/* bed planning)
  models/<member>/               each member's trained model files
  registry.py                    who owns which page, model and training code
  train_all_models.py            retrains Ryma, Faycel, Emna and Fatma's models
deployment_v2/                   MAAK app: backend/ (FastAPI modules) + mobile/ (Flutter)
capalit_ml/                      Najd: models, planning, settings, tests
fyras/model/                     Fyras: CareStep labs, main.py, notebook
<member>/                        each member's design notes (and report)
```

## Run the app

```bash
cd deployment
pip install -r requirements.txt
streamlit run app/Home.py              # app on http://localhost:8501
uvicorn api.main:app --port 8000       # API on http://localhost:8000/docs
```

With Docker (build from the repository root):

```bash
docker build -f deployment/Dockerfile -t readmitguard .
docker run -p 8501:8501 -p 8000:8000 readmitguard
```

## Retrain or update a model

- **Ryma, Faycel, Emna, Fatma** — `python deployment/train_all_models.py` (reads `data/splits/`).
- **Fyras (CareStep)** — in `fyras/model/`: `python 01_preparation.py`, then `02_modelisation.py`,
  `03_evaluation.py`, `04_tuning.py`, and `05_export.py` to copy the final model into
  `deployment/models/fyras/`. `main.py` runs labs 1–4 in one go with a live dashboard.
- **Najd (BedSense)** — replace the files in `capalit_ml/` (same names), then check them with
  `python -m pytest capalit_ml/tests`. Bed and staff numbers are in `capalit_ml/config/planning.toml`.
