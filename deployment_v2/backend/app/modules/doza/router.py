# -*- coding: utf-8 -*-
"""Endpoints Doza — montés sur /api/v1/doza par le registre de modules."""
from typing import Any, Dict

from fastapi import APIRouter

from . import logic
from .french import en_lettres, pourcent

router = APIRouter()


def _narrative(res: dict) -> list:
    """SPOKEN text for the avatar (English, numbers spelled out).

    For the doctor: we state the probability, the zone and its real observed
    rate, then the factors that weighed most (an explanation, not advice).
    """
    segs = [{
        "kind": "greeting",
        "text": "Hello, I'm Doza. Here is my analysis of the insulin dose change, "
                "for the doctor.",
    }, {
        "kind": "score",
        "text": f"The estimated probability that the dose changes is {pourcent(res['pourcentage'])}.",
    }]

    zone = res["zone"].lower()
    if res["zone_taux"] is not None:
        segs.append({
            "kind": "calibration",
            "text": f"This patient is in the {zone} zone. Among similar patients, "
                    f"about {pourcent(res['zone_taux'])} saw their dose change.",
        })
    else:
        segs.append({"kind": "calibration", "text": f"This patient is in the {zone} zone."})

    if res["facteurs"]:
        segs.append({
            "kind": "action",
            "text": "The factors that weighed most for this patient are as follows.",
        })
        for f in res["facteurs"]:
            segs.append({
                "kind": "driver_up",
                "text": f"{f['champ'].capitalize()}, recorded as {f['reponse']}.",
            })

    segs.append({
        "kind": "closing",
        "text": "Important reminder: this result is a decision aid for the doctor. "
                "It must not be shown to the patient.",
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
