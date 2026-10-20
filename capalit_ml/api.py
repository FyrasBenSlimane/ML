"""REST endpoints for Najd's bed planning, built like deployment/api/main.py.

Run on its own:  uvicorn capalit_ml.api:app --port 8001
Or mount in the main API (needs a 2-line change there):  app.include_router(router)
"""
from __future__ import annotations

import json
from datetime import date
from functools import lru_cache
from typing import Any, Optional

import numpy as np
import pandas as pd
from fastapi import APIRouter, FastAPI, HTTPException, Query
from pydantic import BaseModel

from . import planning as P

router = APIRouter(prefix="/capalit", tags=["Bed planning (Najd)"])


class Stays(BaseModel):
    stays: list[dict[str, Any]]


def _records(df: pd.DataFrame) -> list[dict]:
    return json.loads(df.to_json(orient="records", date_format="iso"))


def _frame(body: Stays) -> pd.DataFrame:
    if not body.stays:
        raise HTTPException(status_code=422, detail="Please send at least one hospital stay.")
    return pd.DataFrame(body.stays).replace("?", np.nan)


def _score(body: Stays) -> pd.DataFrame:
    try:
        return P.score_stays(_frame(body))
    except P.PatientDataError as e:
        raise HTTPException(status_code=422, detail=str(e))


@lru_cache(maxsize=2)
def _sim(day: str) -> P.Simulation:
    return P.simulate(today=date.fromisoformat(day))


def _plan(service: Optional[str], days: int) -> tuple[P.Simulation, pd.DataFrame]:
    sim = _sim(date.today().isoformat())
    if service and service not in P.services(sim):
        raise HTTPException(status_code=404,
                            detail=f"Unknown service. Choose one of: {', '.join(P.services(sim))}.")
    return sim, P.daily_plan(sim, service, days)


@router.get("/services")
def list_services():
    return {"services": P.services(_sim(date.today().isoformat()))}


@router.post("/risk")
def risk(body: Stays):
    s = _score(body)
    return {"patients": [
        {"return_risk": round(r, 3), "level": lvl, "advice": P.ADVICE[lvl]}
        for r, lvl in zip(s["risk"], s["level"])]}


@router.post("/stay")
def stay(body: Stays):
    s = _score(body)
    return {"patients": [
        {"likely_days": round(m, 1), "low_days": round(lo, 1), "high_days": round(hi, 1),
         "mean_days": round(a, 1), "range_text": P.stay_range(lo, hi)}
        for m, lo, hi, a in zip(s["stay_likely"], s["stay_low"], s["stay_high"], s["stay_mean"])]}


@router.post("/load")
def load(body: Stays):
    s = _score(body)
    return {"total_bed_days": round(float(s["bed_days"].sum()), 2),
            "patients": [{"return_risk": round(r, 3), "mean_days": round(a, 1), "bed_days": round(b, 2)}
                         for r, a, b in zip(s["risk"], s["stay_mean"], s["bed_days"])]}


@router.get("/beds")
def beds(service: Optional[str] = None, days: int = Query(28, ge=1, le=28)):
    _, plan = _plan(service, days)
    cols = ["date", "current_patients", "new_patients", "expected_returns", "beds_needed", "beds_safe",
            "capacity", "free_beds", "occupancy", "status"]
    return {"days": _records(plan[cols].round(2)),
            "weeks": _records(P.weekly_plan(plan)[["label", "start", "end", "peak_beds", "capacity",
                                                   "margin", "critical_days", "tight_days"]].round(2))}


@router.get("/overload")
def overload(service: Optional[str] = None, days: int = Query(28, ge=1, le=28)):
    _, plan = _plan(service, days)
    found = P.alerts(plan)
    for a in found:
        a["date"] = a["date"].isoformat()
    return {"critical_days": int((plan["status"] == "over").sum()),
            "tight_days": int((plan["status"] == "tight").sum()),
            "peak_occupancy": round(float(plan["occupancy"].max()), 3),
            "alerts": found}


@router.get("/staff")
def staff(service: Optional[str] = None, days: int = Query(28, ge=1, le=28)):
    _, plan = _plan(service, days)
    return {"note": "Estimate based on expected beds and the patients-per-nurse setting, not a direct prediction.",
            "patients_per_nurse": P.load_config()["hospital"]["patients_per_nurse"],
            "days": _records(plan[["date", "nurses_needed", "nurses_needed_safe", "nurses_on_duty",
                                   "staff_gap"]])}


app = FastAPI(title="CapaLit API", description="Bed planning from Najd's two models", version="1.0.0")
app.include_router(router)


@app.get("/health")
def health():
    return {"status": "ok"}
