# ReadmitGuard v2 — Flutter mobile app + FastAPI

New deployment (the old Streamlit one in `../deployment/` is untouched and unused).

```
deployment_v2/
├── backend/                     FastAPI — one plug-in module per team member
│   ├── app/main.py              entry point (auto-discovers modules)
│   ├── app/core/                registry, shared female TTS (/api/v1/tts), config
│   ├── app/modules/bedsense/    Najd's bed planning + length of stay (imports ../../capalit_ml)
│   ├── app/modules/carestep/    Fyras's 30-day recovery companion
│   ├── app/modules/medoracle/   physician-only equity-of-care comparison
│   ├── app/modules/teemo/       Ryma's model: features, model, SHAP, care plan, narrative
│   ├── app/modules/_template/   copy this to add a model
│   ├── artifacts/carestep/      CareStep model + feature list
│   ├── artifacts/medoracle/     MedOracle model, metadata and source coefficients
│   ├── artifacts/teemo/         model files + reference.json (built from the data splits)
│   ├── scripts/build_teemo_reference.py
│   └── tests/                   pytest (45 tests)
├── mobile/                      Flutter app (Android / iOS / web)
│   ├── lib/core/                theme, settings, API client, server status
│   ├── lib/features/avatar/     reusable talking-avatar stage (video + voice + subtitles)
│   ├── lib/features/bedsense/   bed planning, follow-up list, check a patient
│   ├── lib/features/carestep/   questionnaire, analysing, result + 30-day plan
│   ├── lib/features/medoracle/  physician-only comparative analysis form and results
│   ├── lib/features/teemo/      assessment wizard, analysing, results, profile
│   ├── lib/features/home/       day/night sky home screen
│   ├── lib/features/modules/    team hub, registry (all six live), _template
│   └── assets/teemo/            Teemo's portrait, face and talking clip
├── README.md
└── INTEGRATION.md               how teammates plug their model in
```

## 1. Run the backend

```powershell
cd backend
.\run_server.ps1          # uses the conda env "myenv" (sklearn 1.9.1 / lightgbm 4.7)
```
or manually: `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000`

* API docs: http://localhost:8000/docs
* Tests: `python -m pytest -q`
* The saved joblib model files need **scikit-learn 1.9.1, lightgbm 4.7.0 and xgboost 3.4.1** (see `requirements.txt`).
* The neural female voice (edge-tts, `en-US-AvaNeural`) needs internet on the server.
  Without it the app falls back to the phone's own female voice automatically.

  MedOracle uses the model files in `backend/artifacts/medoracle/`; keep them with the
  deployment and use the pinned `xgboost==3.4.1`, scikit-learn and LightGBM dependencies.
  It is listed as live at `/api/v1/modules`, and both its metadata and comparison
  endpoints require an authenticated physician.

## 2. Run the app

Flutter SDK must be installed and available on `PATH` (`flutter doctor -v` checks the setup).
On Windows, enable Developer Mode if Flutter reports that plugin symlinks are unavailable.

```powershell
cd mobile
flutter pub get
flutter run -d chrome              # quickest: runs in the browser
flutter run                        # Android phone / emulator (needs Android Studio + SDK)
```

**Server address** (gear icon on the home screen → Settings):

| Where the app runs  | Address                        |
|---------------------|--------------------------------|
| Chrome on this PC   | `http://localhost:8000`        |
| Android emulator    | `http://10.0.2.2:8000`         |
| Real phone (Wi-Fi)  | `http://<PC IP>:8000` — printed by `run_server.ps1`; allow port 8000 in Windows Firewall |

To build an APK: install Android Studio (it brings the Android SDK), run `flutter doctor`, then
`flutter build apk --release` → `mobile/build/app/outputs/flutter-apk/app-release.apk`.

## 3. What Teemo does

1. **Assessment** — 5 animated steps (Patient, Admission, Clinical, History, Medication), or
   one-tap real sample patients (low / moderate / high) from the held-out test set.
2. **Prediction** — calibrated LightGBM on 38 features (ROC-AUC 0.668, PR-AUC 0.223 ≈ 2× baseline,
   Brier 0.096). Derived features are rebuilt exactly like the team notebook (asserted on the
   whole test split).
3. **Explanation** — TreeSHAP per patient, grouped into clinical concepts (e.g. *visit history*).
4. **Calibrated message** — risk bands: LOW < 8 % (cost-optimal intervention threshold),
   MODERATE 8–20 %, HIGH ≥ 20 %. In testing, the observed readmission rates were 6.3 % / 11.4 % / 25.4 %,
   so the app can honestly say "25 out of 100 patients like this came back".
5. **Care plan** generated from the drivers.
6. **Teemo explains** — tap the floating avatar: she grows to full screen, the talking clip plays
   while a female neural voice reads the analysis, with word-by-word subtitles, pause / skip / replay.

The home header follows the real clock (blue day, sunset, purple starry night with a lit hospital).
Tap the *Live* chip to preview Dawn / Day / Dusk / Night.

## 4. MedOracle (physician only)

Open MedOracle from the Team tab. The app requires the physician to confirm a patient,
then compares two demographic profiles at the same supplied clinical severity. Each
comparison shows adjusted group differences, approximate 95% confidence intervals,
and the model's context estimate. The patient code is sent with the evaluation so the
portal can enforce and log the physician/patient association.

This is a retrospective group comparison on US hospital data from 1999–2008. It is
not an individual prediction or treatment recommendation; associations do not establish
causation or prove unequal care. The reconstructed severity regressors report test RMSE
of about 2.83 days for length of stay and 1.43 procedures on the held-out source split.
These estimates are population context only. The reconstruction is close to, but not
bit-for-bit identical with, the source report (about 2.81 and 1.42 respectively); the
metadata records the exact train/test split hashes and runtime library versions.

To rebuild the artifacts, provide the original equity split directory explicitly:

```powershell
cd backend
python scripts\build_medoracle_artifacts.py --data-dir "C:\path\to\source\data\splits\equity"
```

The directory must contain `train_with_sensitive.parquet` and
`test_with_sensitive.parquet` from the model's source pipeline. Do not substitute
another project split; it changes the reference population and model metrics.
