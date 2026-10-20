import json
import re
from datetime import date

import numpy as np
import pandas as pd
import pytest
from fastapi.testclient import TestClient

from capalit_ml import charge_attendue, planning as P
from capalit_ml.api import app

TODAY = date(2026, 10, 20)
JARGON = re.compile(r"probabilit|model|predict|median|quantile|\bAUC\b|feature|calibrat|percentile", re.I)


@pytest.fixture(scope="module")
def sim():
    return P.simulate(today=TODAY)


@pytest.fixture(scope="module")
def plan(sim):
    return P.daily_plan(sim)


@pytest.fixture(scope="module")
def raw_rows():
    return pd.read_csv(P.DATA_PATH, na_values="?", low_memory=False).iloc[[0, 1, 2]]


def test_same_ward_every_time(sim):
    again = P.simulate(today=TODAY)
    pd.testing.assert_frame_equal(sim.patients, again.patients)


def test_bed_days_add_up_to_charge_attendue():
    cfg = P.load_config()
    cfg["activity"] = {**cfg["activity"], "horizon_days": 80}
    s = P.simulate(cfg, today=TODAY)
    p = s.patients
    full = ((p["admit_day"] >= 0) & (p["discharge_day"] + s.window + 15 < s.horizon)).to_numpy()
    expected = charge_attendue(p.loc[full, "risk"], p.loc[full, "stay_mean"])
    np.testing.assert_allclose(s.return_beds[full].sum(axis=1), expected, rtol=1e-9)
    np.testing.assert_allclose(s.return_arrivals[full].sum(axis=1), p.loc[full, "risk"], rtol=1e-9)


def test_daily_plan_is_consistent(plan):
    np.testing.assert_allclose(plan["beds_needed"],
                               plan["current_patients"] + plan["new_patients"] + plan["expected_returns"])
    assert (plan["beds_safe"] >= plan["beds_needed"]).all()
    over = plan["beds_needed"] > plan["capacity"]
    assert ((plan["status"] == "over") == over).all()
    assert (plan.loc[over, "shortfall"] >= 1).all() and (plan.loc[~over, "shortfall"] == 0).all()
    per = P.load_config()["hospital"]["patients_per_nurse"]
    assert (plan["nurses_needed"] == np.ceil(plan["beds_needed"] / per)).all()


def test_weeks_and_comparison(plan):
    w = P.weekly_plan(plan)
    assert list(w["label"][:2]) == ["This week", "Next week"]
    assert (w["margin"] == w["capacity"] - w["peak_beds"]).all()
    assert list(P.week_compare(plan).index) == ["This week", "Next week"]


def test_every_overload_has_an_action(plan):
    found = P.alerts(plan)
    over_days = set(plan.loc[plan["status"] == "over", "day"])
    assert {a["day"] for a in found if a["severity"] == "over"} == over_days
    for a in found:
        assert a["action"].startswith(("Consider:", "Keep"))
        assert not JARGON.search(a["title"] + a["action"])


def test_service_capacity_shares(sim):
    total = P.load_config()["hospital"]["total_beds"]
    beds = sum(P.capacity(sim, s)[0] for s in P.services(sim))
    assert abs(beds - total) <= len(P.services(sim))


def test_followup_list(sim):
    f = P.followup_list(sim)
    assert set(f["where"]) <= {"In hospital", "At home"}
    assert f["level"].map({"High": 0, "Medium": 1, "Low": 2}).is_monotonic_increasing
    assert (f["discharge_date"] > pd.Timestamp(TODAY - pd.Timedelta(days=30)).date()).all()


def test_patient_summary_has_no_jargon(sim):
    f = P.followup_list(sim)
    for _, row in pd.concat([f.head(5), f.tail(5)]).iterrows():
        e = P.explain(row)
        text = " ".join([e["headline"], e["sentence"], e["stay"], e["advice"], *e["facts"]])
        assert not JARGON.search(text), text
        assert "100 out of 100" not in e["sentence"]


def test_labels_are_words_not_codes():
    df = pd.read_csv(P.DATA_PATH, na_values="?", low_memory=False)
    for kind in ["admission_type_id", "discharge_disposition_id", "admission_source_id"]:
        for code in df[kind].dropna().unique():
            text = P.label(kind, code)
            assert text and not text.strip().isdigit()


def test_missing_details_message(raw_rows):
    with pytest.raises(P.PatientDataError, match="missing"):
        P.score_stays(raw_rows.drop(columns=["age", "insulin"]))


# ---------- API ----------

@pytest.fixture(scope="module")
def client():
    return TestClient(app)


def _body(rows):
    return {"stays": json.loads(rows.to_json(orient="records"))}


def test_api_risk_stay_load_match_models(client, raw_rows):
    s = P.score_stays(raw_rows)
    r = client.post("/capalit/risk", json=_body(raw_rows)).json()["patients"]
    assert [x["return_risk"] for x in r] == list(s["risk"].round(3))
    assert [x["level"] for x in r] == list(s["level"])
    d = client.post("/capalit/stay", json=_body(raw_rows)).json()["patients"]
    assert [x["likely_days"] for x in d] == list(s["stay_likely"].round(1))
    ld = client.post("/capalit/load", json=_body(raw_rows)).json()
    assert ld["total_bed_days"] == pytest.approx(round(s["bed_days"].sum(), 2))


def test_api_errors_are_plain(client, raw_rows):
    r = client.post("/capalit/risk", json=_body(raw_rows.drop(columns=["age"])))
    assert r.status_code == 422 and "missing" in r.json()["detail"]
    r = client.post("/capalit/risk", json={"stays": []})
    assert r.status_code == 422
    r = client.get("/capalit/beds", params={"service": "Nowhere"})
    assert r.status_code == 404 and "Choose one of" in r.json()["detail"]


def test_api_planning_endpoints(client):
    b = client.get("/capalit/beds", params={"days": 7}).json()
    assert len(b["days"]) == 7 and b["weeks"][0]["label"] == "This week"
    svc = client.get("/capalit/services").json()["services"][0]
    assert client.get("/capalit/beds", params={"service": svc}).status_code == 200
    o = client.get("/capalit/overload").json()
    assert set(o) == {"critical_days", "tight_days", "peak_occupancy", "alerts"}
    s = client.get("/capalit/staff").json()
    assert "Estimate" in s["note"] and len(s["days"]) == 28
    assert client.get("/health").json() == {"status": "ok"}
