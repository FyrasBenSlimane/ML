# -*- coding: utf-8 -*-
"""
Tests de l'application : 3 patients d'exemple doivent donner la meme prediction
que celle calculee a partir du pipeline sauvegarde (regression + coherence).

Lancer :  python -m pytest tests/ -q      (ou :  python tests/test_predict.py)
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "api"))
from predict import predire, SEUIL  # noqa: E402

# 3 patients (reponses au format questionnaire) + resultat attendu (modele deterministe).
PATIENTS = [
    ("A", dict(age_ordinal=3, gender=0, admission_type_id=3, admission_source_id=1,
               medical_specialty="Family/GeneralPractice", diag_1_group="Other",
               number_emergency=0, number_inpatient=0, number_outpatient=0,
               A1Cresult=1, num_medications=3, sulfonylurea=0),
     {"pourcentage": 54, "classe": 1, "zone": "Risque intermédiaire"}),
    ("B", dict(age_ordinal=8, gender=1, admission_type_id=1, admission_source_id=7,
               medical_specialty="InternalMedicine", diag_1_group="Diabetes",
               number_emergency=3, number_inpatient=3, number_outpatient=6,
               A1Cresult=3, num_medications=25, sulfonylurea=1),
     {"pourcentage": 68, "classe": 1, "zone": "Risque élevé"}),
    ("C", dict(age_ordinal=6, gender=0, admission_type_id=2, admission_source_id=6,
               medical_specialty="Cardiology", diag_1_group="Circulatory",
               number_emergency=1, number_inpatient=0, number_outpatient=2,
               A1Cresult=2, num_medications=13, sulfonylurea=0),
     {"pourcentage": 15, "classe": 0, "zone": "Risque plus faible"}),
]


def test_predictions_attendues():
    for nom, patient, attendu in PATIENTS:
        r = predire(patient)
        assert r["pourcentage"] == attendu["pourcentage"], f"{nom}: {r['pourcentage']} != {attendu['pourcentage']}"
        assert r["classe"] == attendu["classe"], f"{nom}: classe {r['classe']}"
        assert r["zone"] == attendu["zone"], f"{nom}: zone {r['zone']}"


def test_coherence_classe_seuil():
    # la classe doit toujours correspondre a (proba >= seuil)
    for nom, patient, _ in PATIENTS:
        r = predire(patient)
        assert r["classe"] == int(r["proba"] >= SEUIL), nom
        assert 0.0 <= r["proba"] <= 1.0


def test_reproductible():
    # deux appels identiques -> resultat identique
    _, patient, _ = PATIENTS[1]
    assert predire(patient)["proba"] == predire(patient)["proba"]


if __name__ == "__main__":
    test_predictions_attendues()
    test_coherence_classe_seuil()
    test_reproductible()
    print("OK — 3 tests passes")
