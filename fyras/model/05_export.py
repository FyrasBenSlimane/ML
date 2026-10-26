"""
CareStep — Lab 5 : Export vers l'application
=============================================
Membre : Fyras

Copie le modèle final (LightGBM tuné + calibré, Lab 4) et la liste de ses 23 colonnes
dans deployment/models/fyras/, là où la page CareStep et l'API les chargent.
"""

import sys
import joblib
from pathlib import Path

OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(OUT.parents[1] / "deployment"))
from registry import model_file

tuned = joblib.load(OUT / "tuned_models.pkl")
model, features = tuned["cal_model"], list(tuned["patient_names"])

dest_model, dest_features = model_file("carestep_model.joblib"), model_file("carestep_features.joblib")
dest_model.parent.mkdir(parents=True, exist_ok=True)
joblib.dump(model, dest_model)
joblib.dump(features, dest_features)

print(f"Modèle exporté   : {dest_model}")
print(f"Colonnes ({len(features)}) : {dest_features}")
