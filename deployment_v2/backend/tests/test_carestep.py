"""API tests for CareStep — run from backend/:  python -m pytest -q"""
import re
import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.main import app  # noqa: E402
from _auth import authenticate  # noqa: E402

client = TestClient(app)
authenticate(client)  # /predict is doctor-only: authenticate the client

URL = "/api/v1/carestep/predict"
KINDS = {"greeting", "score", "comparison", "calibration", "driver_up", "driver_down",
         "action", "closing"}

LIGHT = dict(age=3, gender="Female", time_hosp=2, discharge="home", num_meds=5, insulin="No",
             med_change="No", a1c_tested="Yes", diag_group="injury",
             inpatient=0, emergency=0, outpatient_raw=0)
HEAVY = dict(age=8, gender="Male", time_hosp=12, discharge="facility", num_meds=30, insulin="Up",
             med_change="Yes", a1c_tested="No", diag_group="infection_renal",
             inpatient=6, emergency=4, outpatient_raw=9)


def test_carestep_meta():
    assert "carestep" in client.get("/health").json()["modules"]
    body = client.get("/api/v1/carestep/meta").json()
    assert body["model"]["available"] is True
    assert len(body["fields"]) == 12
    assert body["fields"]["num_meds"]["min"] == 1 and body["fields"]["num_meds"]["max"] == 50
    assert {o["value"] for o in body["fields"]["insulin"]["options"]} == {"No", "Steady", "Up", "Down"}


def test_carestep_predict_defaults_and_narrative():
    body = client.post(URL, json={}).json()   # every field has a default
    p = body["probability"]
    assert 0.0 <= p <= 1.0
    assert body["level"] == ("HIGH" if p >= 0.25 else "MEDIUM" if p >= 0.14 else "LOW")
    assert body["reasons"] and body["actions"]
    assert [ph["title"][:6] for ph in body["plan"]] == ["Week 1", "Weeks ", "Week 4"]
    assert body["care_team"]["recommended_actions"]

    nar = body["narrative"]
    assert nar[0]["kind"] == "greeting" and nar[-1]["kind"] == "closing"
    assert all(s["kind"] in KINDS for s in nar)
    spoken = " ".join(s["text"] for s in nar)
    assert "percent" in spoken
    assert "%" not in spoken and not re.search(r"\d", spoken)


def test_carestep_heavier_profile_scores_higher():
    light = client.post(URL, json=LIGHT).json()
    heavy = client.post(URL, json=HEAVY).json()
    assert heavy["probability"] > light["probability"]
    assert len(heavy["reasons"]) > len(light["reasons"])


def test_carestep_validation():
    assert client.post(URL, json={**LIGHT, "num_meds": 99}).status_code == 422
    assert client.post(URL, json={**LIGHT, "insulin": "Maybe"}).status_code == 422
    assert client.post(URL, json={**LIGHT, "diag_group": "astrology"}).status_code == 422


def test_carestep_predict_requires_doctor():
    anon = TestClient(app)
    assert anon.post(URL, json=LIGHT).status_code == 401
