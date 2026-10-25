"""API tests for Teemo — run from the backend folder:  python -m pytest -q"""
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402

client = TestClient(app)


@pytest.fixture(scope="module")
def meta():
    r = client.get("/api/v1/teemo/meta")
    assert r.status_code == 200
    return r.json()


def test_health_lists_teemo():
    r = client.get("/health")
    assert r.status_code == 200
    assert "teemo" in r.json()["modules"]


def test_template_is_not_mounted():
    ids = [m["id"] for m in client.get("/api/v1/modules").json()]
    assert "teemo" in ids and "mymodel" not in ids


def test_meta_has_fields_and_samples(meta):
    assert meta["fields"]["age"]["type"] == "choice"
    assert meta["fields"]["time_in_hospital"]["type"] == "number"
    assert len(meta["samples"]) == 3
    assert meta["model"]["metrics"]["roc_auc"] > 0.6


def test_empty_patient_uses_defaults():
    r = client.post("/api/v1/teemo/predict", json={})
    assert r.status_code == 200
    body = r.json()
    assert 0 <= body["probability"] <= 1
    assert "age" in body["defaulted_fields"]
    assert body["narrative"][0]["kind"] == "greeting"
    assert body["narrative"][-1]["kind"] == "closing"


def test_samples_reproduce_reference_probability(meta):
    """The API must give the same score as the offline evaluation."""
    for s in meta["samples"]:
        r = client.post("/api/v1/teemo/predict", json=s["patient"])
        assert r.status_code == 200, r.text
        assert r.json()["probability"] == pytest.approx(s["expected_probability"], abs=1e-4)
        assert r.json()["defaulted_fields"] == []


def test_levels_follow_thresholds(meta):
    by_label = {s["label"]: s for s in meta["samples"]}
    low = client.post("/api/v1/teemo/predict", json=by_label["Low risk example"]["patient"]).json()
    high = client.post("/api/v1/teemo/predict", json=by_label["High risk example"]["patient"]).json()
    assert low["level"] == "LOW" and not low["intervention_recommended"]
    assert high["level"] == "HIGH" and high["intervention_recommended"]
    assert high["percentile"] > low["percentile"]


def test_more_prior_admissions_raise_risk():
    base = {"number_inpatient": 0, "number_emergency": 0, "number_outpatient": 0}
    p0 = client.post("/api/v1/teemo/predict", json=base).json()["probability"]
    p1 = client.post("/api/v1/teemo/predict", json={**base, "number_inpatient": 5}).json()["probability"]
    assert p1 > p0


def test_drivers_and_actions_are_well_formed():
    body = client.post("/api/v1/teemo/predict", json={"number_inpatient": 4, "insulin": "Up"}).json()
    assert body["drivers"][0]["key"] == "visits"
    assert body["drivers"][0]["direction"] == "up"
    assert abs(sum(d["share"] for d in body["drivers"]) - 1) < 0.2
    assert 1 <= len(body["actions"]) <= 5
    spoken = " ".join(s["text"] for s in body["narrative"])
    assert ">" not in spoken and "·" not in spoken


def test_unknown_category_is_rejected():
    r = client.post("/api/v1/teemo/predict", json={"medical_specialty": "Astrology"})
    assert r.status_code == 422


def test_hyphenated_medication_alias():
    r = client.post("/api/v1/teemo/predict", json={"glipizide-metformin": "No"})
    assert r.status_code == 200
    assert "glipizide-metformin" not in r.json()["defaulted_fields"]


def test_out_of_range_is_rejected():
    assert client.post("/api/v1/teemo/predict", json={"time_in_hospital": 40}).status_code == 422
