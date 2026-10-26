"""BedSense API tests (Najd) — run from backend/ with python -m pytest -q."""
import json
import math
import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402
from _auth import authenticate  # noqa: E402

client = TestClient(app)
PATIENT_CODE = authenticate(client)

HIGHEST_RISK = {
    "age": "[20-30)",
    "race": "Caucasian",
    "service": "Kidney care",
    "admission_type_id": 2,            # Urgent
    "discharge_disposition_id": 22,    # Rehabilitation centre
    "number_inpatient": 15,            # prior hospital stays in the past year
}


def _no_nan(obj):
    if isinstance(obj, dict):
        return all(_no_nan(v) for v in obj.values())
    if isinstance(obj, list):
        return all(_no_nan(v) for v in obj)
    return not (isinstance(obj, float) and (math.isnan(obj) or math.isinf(obj)))


def test_bedsense_is_listed_live():
    modules = {m["id"]: m for m in client.get("/api/v1/modules").json()}
    assert modules["bedsense"]["status"] == "live"
    assert modules["bedsense"]["owner"] == "Najd"


def test_predict_defaults_returns_probability_stay_and_narrative():
    r = client.post("/api/v1/bedsense/predict", json={})
    assert r.status_code == 200, r.text
    body = r.json()
    assert 0.0 <= body["probability"] <= 1.0
    assert body["level"] in {"low", "medium", "high"}
    stay = body["stay"]
    assert 1 <= stay["q10"] <= stay["median"] <= stay["q90"] <= 14
    assert body["bed_days"] >= 0
    assert body["advice"]
    kinds = [seg["kind"] for seg in body["narrative"]]
    assert kinds[0] == "greeting" and "score" in kinds and "action" in kinds
    spoken = " ".join(seg["text"] for seg in body["narrative"])
    assert "percent" in spoken and "%" not in spoken
    assert "about" in spoken and "days" in spoken


def test_highest_risk_profile_scores_higher_than_defaults():
    base = client.post("/api/v1/bedsense/predict", json={}).json()
    high = client.post("/api/v1/bedsense/predict", json=HIGHEST_RISK)
    assert high.status_code == 200, high.text
    high = high.json()
    assert high["probability"] > base["probability"]
    assert high["level"] == "high"


def test_predict_rejects_unknown_values():
    r = client.post("/api/v1/bedsense/predict", json={"service": "Unknown ward"})
    assert r.status_code == 422


def test_predict_requires_patient_code_and_token():
    anonymous = TestClient(app)
    assert anonymous.post("/api/v1/bedsense/predict", json={}).status_code == 401
    token = client.headers["Authorization"]
    r = anonymous.post("/api/v1/bedsense/predict", json={}, headers={"Authorization": token})
    assert r.status_code == 400


def test_plan_for_doctor_is_json_safe():
    r = client.get("/api/v1/bedsense/plan")
    assert r.status_code == 200, r.text
    body = r.json()
    assert _no_nan(body)
    assert len(body["days"]) == body["horizon"] > 0
    day = body["days"][0]
    assert day["status"] in {"ok", "tight", "over"}
    assert day["beds_safe"] >= day["beds_needed"]
    assert isinstance(day["date"], str) and len(day["date"]) == 10
    assert body["weeks"] and body["summary"]["capacity"] > 0
    assert 0 < body["safe_band"]["level"] < 1
    assert isinstance(body["alerts"], list)
    assert len(json.dumps(body)) < 100_000


def test_plan_filters_by_service_and_horizon():
    meta = client.get("/api/v1/bedsense/meta")
    assert meta.status_code == 200
    services = meta.json()["services"]
    assert "Kidney care" in services
    r = client.get("/api/v1/bedsense/plan", params={"service": services[0], "horizon": 7})
    assert r.status_code == 200, r.text
    assert len(r.json()["days"]) == 7
    assert client.get("/api/v1/bedsense/plan", params={"service": "Nowhere"}).status_code == 404


def test_followup_for_doctor_lists_top_patients():
    r = client.get("/api/v1/bedsense/followup", params={"top": 5})
    assert r.status_code == 200, r.text
    body = r.json()
    assert _no_nan(body)
    assert body["shown"] == len(body["patients"]) <= 5
    assert body["total"] >= body["shown"]
    first = body["patients"][0]
    assert first["level"] == "high" and 0 <= first["probability"] <= 1
    assert first["advice"] and first["facts"]


def test_ward_endpoints_require_doctor_token():
    anonymous = TestClient(app)
    for path in ("/api/v1/bedsense/plan", "/api/v1/bedsense/followup", "/api/v1/bedsense/meta"):
        assert anonymous.get(path).status_code == 401
