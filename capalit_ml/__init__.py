"""capalit_ml : modèles de Najd (risque de retour sous 30 jours, durée du séjour de retour)."""
from .modele1 import predict_patients
from .modele2 import charge_attendue, predict_los

__all__ = ["predict_patients", "predict_los", "charge_attendue"]
