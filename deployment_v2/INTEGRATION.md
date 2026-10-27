# Plugging your model into ReadmitGuard

All six modules are live: Teemo, CareStep, MedOracle, Doza, Sora and BedSense.
These steps describe how each one was plugged in, and how to add a new one.
BedSense imports Najd's `capalit_ml/` package from the repository root, so keep that
folder next to `deployment_v2/`. Nothing in Teemo's code needs to change.

## 1. Backend (5 minutes)

```bash
cd backend
cp -r app/modules/_template app/modules/<your_id>      # e.g. carestep
mkdir artifacts/<your_id>                              # put model.joblib etc. here
```

In `app/modules/<your_id>/__init__.py` set `MODULE.id = "<your_id>"` (must match the id in the
app's registry), your name, colour, status.

In `router.py` implement `POST /predict` (and optionally `GET /meta`). Restart the server: the
registry mounts it at `/api/v1/<your_id>/...` and lists it at `/api/v1/modules`. A module that
crashes on import is reported with `status: "error"`. It never takes the server down.

Return a **`narrative`** list in your response if you want your avatar to talk:

```json
{"probability": 0.12,
 "narrative": [{"kind": "greeting", "text": "Hi, I'm CareStep."},
               {"kind": "score",    "text": "Your recovery score is 82 out of 100."}]}
```

`kind` picks the subtitle icon: greeting, score, comparison, calibration, driver_up,
driver_down, action, closing. Write numbers and words the way they should be *spoken*
("12 percent", not "12%").

Shared for free: `POST /api/v1/tts` (female neural voice + word timings).

## 2. App

```
mobile/lib/features/modules/_template/template_screen.dart   ← copy to lib/features/<your_id>/
```

* Call your API: `context.read<ApiClient>().postJson('/api/v1/<your_id>/predict', body)`.
  The server address, timeouts and error messages (`ApiException`) are shared.
* Reuse the look: `SoftCard`, `GradientButton`, `Pill`, `IconBadge`, `SectionHeader`
  (`lib/shared/widgets/cards.dart`), `BlobBackground`, `EcgLine`, `AnimatedCount`,
  `PulseDot` (`ambient.dart`), and form widgets in `features/teemo/widgets/form_fields.dart`.
* Talking avatar with voice + subtitles:

```dart
AvatarStageScreen.open(context, avatar: myAvatar, segments: narrative, title: 'CareStep explains');
```

Create your persona once (`features/avatar/avatar_profile.dart` shows Teemo's):

```dart
const myAvatar = AvatarProfile(
  id: 'carestep', name: 'CareStep', role: 'Recovery companion',
  faceAsset: 'assets/carestep/face.png',          // square crop
  portraitAsset: 'assets/carestep/portrait.png',  // = first frame of the video
  videoAsset: 'assets/carestep/talk.mp4',         // optional, muted, loops while speaking
  gradient: AppColors.blueGradient, accent: AppColors.blue,
);
```
Add your asset folder to `pubspec.yaml` under `flutter: assets:`.

## 3. Register

In `mobile/lib/features/modules/module_registry.dart`, on your entry:

```dart
status: ModuleStatus.live,
avatar: myAvatar,                       // optional, shows your face in the hub
entry: (_) => const CareStepScreen(),
```

The Team hub, the home strip and the navigation now open your screen.

## Checklist before merging
- [ ] `python -m pytest -q` in `backend/` passes (add tests in `backend/tests/`)
- [ ] `flutter analyze` shows no issues
- [ ] your model's sklearn/lightgbm/xgboost versions are compatible with `requirements.txt`

## MedOracle deployment

MedOracle is registered in the app and mounted at `/api/v1/medoracle`. Its model
artifacts are required at `backend/artifacts/medoracle/`; `/meta` and `/predict`
require physician authentication, and `/predict` also requires a confirmed patient
code so the portal can log the evaluation. The Flutter screen and API use the existing
design system and doctor/patient gate.

The model compares group-level differences at matched clinical severity using
historical US hospital data (1999–2008). It must be presented as descriptive context,
not an individual prediction, causal conclusion, or clinical recommendation.
