# -*- coding: utf-8 -*-
"""
Modèle "Accompagnement" (compagnon du quotidien) — logique métier.

Prédit si le diabète d'un patient est bien ou mal contrôlé, pour recommander
(ou non) un programme pédagogique (alimentation, activité physique).

Le modèle est un dictionnaire joblib fourni par la collègue (Fatma) :
    "modele"   : pipeline scikit-learn calibré (CalibratedClassifierCV + AdaBoost)
    "seuil"    : float (proba >= seuil -> classe 1)
    "features" : liste ordonnée des 8 colonnes attendues
    "messages" : {1: "...", 0: "..."}

Chargé UNE SEULE FOIS (au premier appel), puis réutilisé.
"""
from pathlib import Path

import joblib
import pandas as pd

ROOT = Path(__file__).resolve().parent
MODEL_PATH = ROOT / "models" / "accompagnement_modele.joblib"

# Valeurs autorisées pour le motif principal d'hospitalisation (groupes ICD-9).
DIAG_GROUPS = ["Circulatory", "Diabetes", "Respiratory", "Digestive", "Injury",
               "Musculoskeletal", "Genitourinary", "Neoplasms", "External", "Other"]

_bundle = None

# Messages affichés à l'écran, AVEC accents. Le fichier modèle contient des
# libellés sans accents ("pedagogique", "recommande") ; on les ré-affiche
# proprement ici (couche présentation), sans modifier le fichier modèle.
MESSAGES_FR = {
    1: "Programme pédagogique recommandé (alimentation, activité physique)",
    0: "Conseils standards, pas de programme spécifique",
}


def modele_disponible() -> bool:
    """True si le fichier modèle est présent sur le disque."""
    return MODEL_PATH.exists()


def _charger():
    """Charge le dictionnaire joblib une seule fois."""
    global _bundle
    if _bundle is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Modèle introuvable : {MODEL_PATH}. "
                "Placez 'accompagnement_modele.joblib' dans api/models/."
            )
        b = joblib.load(MODEL_PATH)
        _bundle = {
            "modele": b["modele"],
            "seuil": float(b["seuil"]),
            "features": list(b["features"]),
            "messages": b["messages"],
        }
    return _bundle


def _message(messages, classe: int) -> str:
    """Récupère le message quel que soit le type de clé (int ou str)."""
    if classe in messages:
        return messages[classe]
    return messages.get(str(classe), "")


def predire(data: dict) -> dict:
    """
    data : dict contenant les 8 features (déjà validées).
    Renvoie proba, pourcentage, classe, seuil, résultat et message.
    """
    b = _charger()
    # Construit la ligne dans l'ordre EXACT attendu par le modèle.
    row = {f: data[f] for f in b["features"]}
    X = pd.DataFrame([row], columns=b["features"])

    proba = float(b["modele"].predict_proba(X)[0, 1])
    classe = int(proba >= b["seuil"])

    return {
        "proba": round(proba, 4),
        "pourcentage": round(proba * 100),
        "classe": classe,
        "seuil": round(b["seuil"], 4),
        # classe 1 = programme recommandé = diabète plutôt mal contrôlé
        "resultat": "Mal contrôlé" if classe == 1 else "Bien contrôlé",
        # message affiché avec accents (repli sur le libellé du modèle si besoin)
        "message": MESSAGES_FR.get(classe, _message(b["messages"], classe)),
    }
