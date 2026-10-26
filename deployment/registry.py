"""Single source of truth: who owns each avatar, its page, its model files and its training code.

The Streamlit app (app/utils.py), the API (api/main.py) and the training script
(train_all_models.py) all locate model files through this module.
"""
from pathlib import Path

DEPLOYMENT = Path(__file__).resolve().parent
ROOT = DEPLOYMENT.parent
MODELS = DEPLOYMENT / "models"

AVATARS = {
    "teemo": {
        "owner": "ryma", "page": "app/pages/1_Teemo.py",
        "training": "deployment/train_all_models.py",
    },
    "carestep": {
        "owner": "fyras", "page": "app/pages/2_CareStep.py",
        "training": "fyras/model/ (01_preparation.py → 04_tuning.py, then 05_export.py)",
    },
    "medoracle": {
        "owner": "faycel", "page": "app/pages/3_MedOracle.py",
        "training": "deployment/train_all_models.py",
    },
    "rxpredict": {
        "owner": "emna", "page": "app/pages/4_RxPredict.py",
        "training": "deployment/train_all_models.py",
    },
    "dailyguard": {
        "owner": "fatma", "page": "app/pages/5_DailyGuard.py",
        "training": "deployment/train_all_models.py",
    },
    "bedsense": {
        "owner": "najd", "page": "app/pages/6_BedSense.py",
        "training": "capalit_ml/ (models trained in Najd's notebooks; page uses capalit_ml/*.joblib)",
    },
}


def model_dir(avatar: str) -> Path:
    return MODELS / AVATARS[avatar]["owner"]


def model_file(filename: str) -> Path:
    """'carestep_model.joblib' -> models/fyras/carestep_model.joblib (owner found from the name prefix)."""
    return model_dir(filename.split("_", 1)[0]) / filename
