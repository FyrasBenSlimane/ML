# -*- coding: utf-8 -*-
"""Endpoints Doza — montés sur /api/v1/doza par le registre de modules."""
from typing import Any, Dict

from fastapi import APIRouter

from . import logic
from .french import en_lettres, pourcent

router = APIRouter()


def _narrative(res: dict) -> list:
    """Texte PARLÉ pour l'avatar (français, nombres en toutes lettres).

    Destiné au médecin : on énonce la probabilité, la zone et son taux réel
    observé, puis les facteurs qui ont le plus pesé (explication, pas un conseil).
    """
    segs = [{
        "kind": "greeting",
        "text": "Bonjour, je suis Doza. Voici mon analyse du changement de dose "
                "d'insuline, destinée au médecin.",
    }, {
        "kind": "score",
        "text": f"La probabilité estimée que la dose change est de {pourcent(res['pourcentage'])}.",
    }]

    zone = res["zone"].lower()
    if res["zone_taux"] is not None:
        segs.append({
            "kind": "calibration",
            "text": f"Ce patient se situe en zone de {zone}. Parmi les patients proches, "
                    f"environ {pourcent(res['zone_taux'])} ont vu leur dose changer.",
        })
    else:
        segs.append({"kind": "calibration", "text": f"Ce patient se situe en zone de {zone}."})

    if res["facteurs"]:
        segs.append({
            "kind": "action",
            "text": "Les facteurs qui ont le plus pesé pour ce patient sont les suivants.",
        })
        for f in res["facteurs"]:
            segs.append({
                "kind": "driver_up",
                "text": f"{f['champ'].capitalize()}, renseignée comme {f['reponse']}.",
            })

    segs.append({
        "kind": "closing",
        "text": "Rappel important : ce résultat est une aide à la décision pour le médecin. "
                "Il ne doit pas être montré au patient.",
    })
    return segs


@router.get("/meta", summary="Seuil, zones et libellés du questionnaire Doza")
def meta():
    return {
        "model": {"name": "Doza · Gradient Boosting calibré",
                  "owner": "Emna",
                  "target": "Changement de dose d'insuline (Up/Down = 1, Steady = 0)",
                  "population": "patients déjà sous insuline"},
        "features": logic.features(),
        "seuil": logic.seuil(),
        "zones": logic.zones(),
    }


@router.post("/predict", summary="Prédire le changement de dose d'insuline + explication")
def predict(payload: Dict[str, Any]):
    # Le questionnaire envoie { answers: {...} } ; on accepte aussi un dict brut.
    answers = payload.get("answers", payload) if isinstance(payload, dict) else payload
    res = logic.predire(answers)
    return {
        **res,
        # Clé générique pour l'app (anneau de risque), en plus des clés métier.
        "probability": res["proba"],
        "narrative": _narrative(res),
    }
