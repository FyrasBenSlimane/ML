"""MedOracle API tests — run from backend/ with python -m pytest -q."""
import sys
import uuid
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402
from app.core.security import MEDECIN_CODE_DEFAULT  # noqa: E402
from _auth import authenticate  # noqa: E402

client = TestClient(app)
PATIENT_CODE = authenticate(client)


def _doctor_token() -> str:
    email = f"medoracle-{uuid.uuid4().hex[:8]}@maak.fr"
    response = client.post(
        "/api/v1/auth/register",
        json={
            "prenom": "Med",
            "nom": "Oracle",
            "email": email,
            "password": "secret123",
            "role": "medecin",
            "code": MEDECIN_CODE_DEFAULT,
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["token"]


def _request_body(meta, patient_a=None, patient_b=None):
    severity = {
        key: field["default"]
        for key, field in meta["fields"].items()
    }
    reference = {"race": "Caucasian", "gender": "Female", "age_band": "60-79"}
    return {
        "severity": severity,
        "patient_a": patient_a or reference,
        "patient_b": patient_b or reference,
    }


def test_medoracle_is_listed_and_requires_physician_auth():
    response = client.get("/api/v1/modules")
    assert response.status_code == 200
    assert "medoracle" in [module["id"] for module in response.json()]

    anonymous = TestClient(app)
    assert anonymous.get("/api/v1/medoracle/meta").status_code == 401
    assert anonymous.post("/api/v1/medoracle/predict", json={}).status_code == 401


def test_medoracle_rejects_patient_and_requires_patient_code():
    patient = client.post(
        "/api/v1/auth/register",
        json={
            "prenom": "Pat",
            "nom": "Oracle",
            "email": f"patient-{uuid.uuid4().hex[:8]}@maak.fr",
            "password": "secret123",
        },
    ).json()
    denied = client.post(
        "/api/v1/medoracle/predict",
        json={},
        headers={
            "Authorization": f"Bearer {patient['token']}",
            "X-Patient-Code": PATIENT_CODE,
        },
    )
    assert denied.status_code == 403

    physician = TestClient(app)
    token = _doctor_token()
    missing_patient = physician.post(
        "/api/v1/medoracle/predict",
        json={},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert missing_patient.status_code == 400


def test_meta_has_available_fields_and_historical_limitations():
    meta = client.get("/api/v1/medoracle/meta")
    assert meta.status_code == 200
    body = meta.json()
    assert body["fields"]["number_diagnoses"]["type"] == "number"
    assert "Circulatory" in body["fields"]["diag_1_group"]["options"]
    assert "does not prove" in body["model"]["limitations"]
    assert body["rows"]["training"] > body["rows"]["test"] > 0


def test_prediction_handles_categorical_features_and_same_profile():
    meta = client.get("/api/v1/medoracle/meta").json()
    body = _request_body(meta)
    response = client.post(
        "/api/v1/medoracle/predict",
        json=body,
        headers={"X-Patient-Code": PATIENT_CODE},
    )
    assert response.status_code == 200, response.text
    comparisons = response.json()["comparisons"]
    assert set(comparisons) == {"time_in_hospital", "num_procedures"}
    for result in comparisons.values():
        assert result["difference"] == 0
        assert result["parts"] == []
        assert result["expected"] >= 0
    alert = client.post(
        "/api/v1/notifications",
        json={
            "patient_code": PATIENT_CODE,
            "module": "medoracle",
            "niveau": "info",
            "titre": "Comparaison terminée",
            "message": "Votre médecin a terminé une analyse comparative.",
        },
    )
    assert alert.status_code == 200, alert.text


def test_prediction_reports_only_changed_demographic_factors():
    meta = client.get("/api/v1/medoracle/meta").json()
    profile_b = {"race": "AfricanAmerican", "gender": "Female", "age_band": "60-79"}
    response = client.post(
        "/api/v1/medoracle/predict",
        json=_request_body(meta, patient_b=profile_b),
        headers={"X-Patient-Code": PATIENT_CODE},
    )
    assert response.status_code == 200, response.text
    for comparison in response.json()["comparisons"].values():
        assert [part["variable"] for part in comparison["parts"]] == ["race"]


def test_prediction_rejects_unknown_demographic_values():
    meta = client.get("/api/v1/medoracle/meta").json()
    body = _request_body(meta)
    body["patient_a"]["race"] = "Unvalidated"
    response = client.post(
        "/api/v1/medoracle/predict",
        json=body,
        headers={"X-Patient-Code": PATIENT_CODE},
    )
    assert response.status_code == 422
