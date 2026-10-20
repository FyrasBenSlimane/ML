"""Bed planning built only on Najd's two models.

Expected bed-days for a patient = return risk (modèle 1) x mean return stay (modèle 2), as in
modele2_duree_sejour_retour.ipynb (charge_attendue). Returns are spread evenly over the 30 days
after discharge (najd/06). The data has no calendar dates, so today's ward is simulated from real
stays of diabetic_data.csv; every setting lives in config/planning.toml.
"""
from __future__ import annotations

import tomllib
from dataclasses import dataclass
from datetime import date, timedelta
from functools import lru_cache
from pathlib import Path
from statistics import NormalDist

import numpy as np
import pandas as pd

from .modele1 import MED_COLS, icd9_group, predict_patients, thr_high, thr_med
from .modele2 import charge_attendue, predict_los

ROOT = Path(__file__).resolve().parent
CONFIG_PATH = ROOT / "config" / "planning.toml"
DATA_PATH = ROOT / "diabetic_data.csv"
IDS_PATH = ROOT / "IDS_mapping.csv"

EXCLUDE_DISCH = [11, 13, 14, 19, 20, 21]

RAW_COLUMNS = [
    "race", "gender", "age", "admission_type_id", "discharge_disposition_id", "admission_source_id",
    "time_in_hospital", "payer_code", "medical_specialty", "num_lab_procedures", "num_procedures",
    "num_medications", "number_outpatient", "number_emergency", "number_inpatient",
    "diag_1", "diag_2", "diag_3", "number_diagnoses", "max_glu_serum", "A1Cresult",
    *MED_COLS, "change", "diabetesMed",
]

RISK_THRESHOLDS = {"Medium": float(thr_med), "High": float(thr_high)}
LEVEL_EN = {"faible": "Low", "moyen": "Medium", "élevé": "High"}
LEVELS = ["Low", "Medium", "High"]
ADVICE = {
    "High": "Book a follow-up visit within 7 days and phone the patient 48 hours after discharge",
    "Medium": "Book a follow-up visit within 2 weeks",
    "Low": "Usual check-up in 3 to 4 weeks",
}

SERVICES = {
    "InternalMedicine": "Internal medicine",
    "Emergency/Trauma": "Emergency",
    "Family/GeneralPractice": "General practice",
    "Cardiology": "Cardiology",
    "Surgery-Cardiovascular/Thoracic": "Surgery",
    "Surgery-General": "Surgery",
    "Surgery-Vascular": "Surgery",
    "Surgery-Neuro": "Surgery",
    "Orthopedics": "Surgery",
    "Orthopedics-Reconstructive": "Surgery",
    "Urology": "Surgery",
    "Nephrology": "Kidney care",
}
OTHER_SERVICE = "Other services"

DIAG_FAMILY = {
    "circulatoire": "Heart or blood vessels", "respiratoire": "Lungs or breathing",
    "digestif": "Digestion", "diabete": "Diabetes", "blessure": "Injury",
    "musculo-squelettique": "Bones or joints", "genito-urinaire": "Kidneys or bladder",
    "cancer": "Cancer", "autre": "Other", "inconnu": "Not recorded",
}


PLAIN_LABELS = {
    "discharge_disposition_id": {
        1: "Home", 2: "Another hospital", 3: "Nursing home", 4: "Care facility",
        5: "Another care centre (inpatient)", 6: "Home, with a home-care nurse",
        7: "Left against medical advice", 8: "Home, with IV treatment at home",
        9: "Admitted to this hospital", 10: "Another hospital (newborn care)",
        12: "Home, still followed by this hospital", 15: "Another bed in this hospital",
        16: "Followed by another clinic", 17: "Followed by this hospital's clinic",
        22: "Rehabilitation centre", 23: "Long-term care hospital", 24: "Nursing home",
        27: "Federal health centre", 28: "Psychiatric hospital", 29: "Small rural hospital",
        30: "Another care institution",
    },
    "admission_source_id": {
        1: "Sent by a doctor", 2: "Sent by a clinic", 3: "Sent by the health insurer",
        4: "Transferred from a hospital", 5: "Transferred from a nursing home",
        6: "Transferred from another care centre", 7: "Emergency room", 8: "Police or court",
        10: "Transferred from a rural hospital", 22: "Transferred within this hospital",
        25: "Transferred from a day-surgery centre",
    },
}


class PatientDataError(ValueError):
    """Patient details that the models cannot read; the message is meant for the end user."""


def load_config(path: Path | None = None) -> dict:
    with open(path or CONFIG_PATH, "rb") as f:
        return tomllib.load(f)


@lru_cache(maxsize=1)
def id_labels() -> dict[str, dict[int, str]]:
    blocks, current = {}, None
    for line in IDS_PATH.read_text(encoding="utf-8").splitlines():
        if not line.strip(",").strip():
            current = None
            continue
        key, _, text = line.partition(",")
        if current is None:
            current = blocks.setdefault(key, {})
            continue
        text = text.strip().strip('"').strip()
        if text in ("", "NULL", "Not Mapped", "Not Available", "Unknown/Invalid"):
            text = "Not recorded"
        current[int(key)] = text
    return blocks


def label(kind: str, code) -> str:
    try:
        code = int(code)
    except (TypeError, ValueError):
        return "Not recorded"
    return PLAIN_LABELS.get(kind, {}).get(code) or id_labels().get(kind, {}).get(code, "Not recorded")


def check_columns(raw_df: pd.DataFrame) -> None:
    missing = [c for c in RAW_COLUMNS if c not in raw_df.columns]
    if missing:
        shown = ", ".join(missing[:6]) + ("…" if len(missing) > 6 else "")
        raise PatientDataError(
            f"Some patient details are missing ({shown}). Please send the full hospital stay record.")


def score_stays(raw_df: pd.DataFrame) -> pd.DataFrame:
    """Runs both models on raw stays (same columns as diabetic_data.csv)."""
    check_columns(raw_df)
    risk = predict_patients(raw_df)
    stay = predict_los(raw_df)
    out = pd.DataFrame({
        "risk": risk["risque_retour_30j"].astype(float),
        "level": risk["niveau"].map(LEVEL_EN),
        "stay_likely": stay["duree_mediane_j"].astype(float),
        "stay_low": stay["duree_basse_j"].astype(float),
        "stay_high": stay["duree_haute_j"].astype(float),
        "stay_mean": stay["duree_moyenne_j"].astype(float),
    }, index=raw_df.index)
    out["bed_days"] = charge_attendue(out["risk"], out["stay_mean"])
    return out


@lru_cache(maxsize=1)
def load_stays() -> pd.DataFrame:
    """Every usable stay of the hospital file, scored once (patients who died are left out, as in the notebooks)."""
    df = pd.read_csv(DATA_PATH, na_values="?", low_memory=False)
    df = df[~df["discharge_disposition_id"].isin(EXCLUDE_DISCH)].reset_index(drop=True)
    out = pd.concat([df, score_stays(df)], axis=1)
    out["service"] = out["medical_specialty"].map(SERVICES).fillna(OTHER_SERVICE)
    out["age_band"] = out["age"].str.strip("[)").str.replace("-", "–")
    out["main_reason"] = out["diag_1"].map(icd9_group).map(DIAG_FAMILY)
    out["risk_rank"] = out["risk"].rank(pct=True, method="max")
    return out


def stay_range(low: float, high: float) -> str:
    lo, hi = max(1, round(low)), max(1, round(high))
    return f"{lo} day" if lo == hi == 1 else (f"{lo} days" if lo == hi else f"{lo} to {hi} days")


@dataclass
class Simulation:
    today: date
    horizon: int
    window: int
    patients: pd.DataFrame
    return_beds: np.ndarray
    return_arrivals: np.ndarray
    cfg: dict


def simulate(cfg: dict | None = None, today: date | None = None) -> Simulation:
    """Builds today's ward and the coming weeks from real stays (seeded, so every screen agrees)."""
    cfg = cfg or load_config()
    today = today or date.today()
    act, ret = cfg["activity"], cfg["returns"]
    H, W, hist = int(act["horizon_days"]), int(ret["return_window_days"]), int(act["history_days"])
    stays = load_stays()
    rng = np.random.default_rng(int(act["seed"]))
    profile = np.asarray(act["weekday_profile"], float)

    rows = []
    for d in range(-hist, H):
        weekday = (today + timedelta(days=d)).weekday()
        n = rng.poisson(float(act["planned_admissions_per_day"]) * profile[weekday])
        for idx in rng.choice(len(stays), size=n, replace=True):
            rows.append((d, idx))
    adm = np.array(rows, dtype=int).reshape(-1, 2)
    p = stays.iloc[adm[:, 1]].reset_index(drop=True).copy()
    p.insert(0, "pid", [f"P-{i + 1:05d}" for i in range(len(p))])
    p["admit_day"] = adm[:, 0]
    p["discharge_day"] = p["admit_day"] + p["time_in_hospital"].astype(int)
    p["group"] = np.where(p["admit_day"] >= 0, "planned",
                          np.where(p["discharge_day"] > 0, "in_hospital", "discharged"))

    t = np.arange(H)[None, :]
    D = p["discharge_day"].to_numpy()[:, None]
    L = p["stay_mean"].to_numpy()[:, None]
    acc = np.zeros((len(p), H))
    for k in range(1, W + 1):
        u = t - (D + k)
        acc += np.where(u >= 0, np.clip(L - u, 0, 1), 0.0)
    risk = p["risk"].to_numpy()[:, None]
    return_beds = risk / W * acc
    since = t - D
    return_arrivals = np.where((since >= 1) & (since <= W), risk / W, 0.0)
    return Simulation(today, H, W, p, return_beds, return_arrivals, cfg)


def services(sim: Simulation) -> list[str]:
    counts = sim.patients["service"].value_counts()
    return [s for s in counts.index if s != OTHER_SERVICE] + ([OTHER_SERVICE] if OTHER_SERVICE in counts else [])


def _mask(sim: Simulation, service: str | None) -> np.ndarray:
    if not service:
        return np.ones(len(sim.patients), bool)
    return (sim.patients["service"] == service).to_numpy()


def capacity(sim: Simulation, service: str | None = None) -> tuple[int, int]:
    """Beds and nurses per shift for the hospital, or the service's share of them."""
    h = sim.cfg["hospital"]
    share = _mask(sim, service).mean()
    beds = int(h["total_beds"]) if not service else max(1, round(int(h["total_beds"]) * share))
    nurses = int(h["nurses_on_duty_per_shift"]) if not service else max(1, round(int(h["nurses_on_duty_per_shift"]) * share))
    return beds, nurses


def daily_plan(sim: Simulation, service: str | None = None, days: int | None = None) -> pd.DataFrame:
    days = min(days or sim.horizon, sim.horizon)
    m = _mask(sim, service)
    p = sim.patients[m]
    t = np.arange(days)
    in_bed = (p["admit_day"].to_numpy()[:, None] <= t) & (t < p["discharge_day"].to_numpy()[:, None])
    current = (in_bed & (p["admit_day"].to_numpy()[:, None] < 0)).sum(axis=0)
    new = (in_bed & (p["admit_day"].to_numpy()[:, None] >= 0)).sum(axis=0)
    o = sim.return_beds[m][:, :days]
    returns = o.sum(axis=0)
    needed = current + new + returns
    z = NormalDist().inv_cdf(float(sim.cfg["returns"]["safety_level"]))
    safe = needed + z * np.sqrt((o * (1 - o)).sum(axis=0))
    beds, nurses = capacity(sim, service)
    per_nurse = float(sim.cfg["hospital"]["patients_per_nurse"])
    tight = float(sim.cfg["hospital"]["tight_occupancy"])

    plan = pd.DataFrame({
        "day": t,
        "date": [sim.today + timedelta(days=int(d)) for d in t],
        "current_patients": current,
        "new_patients": new,
        "expected_returns": returns,
        "beds_needed": needed,
        "beds_safe": safe,
        "capacity": beds,
        "admissions_planned": [(p["admit_day"] == d).sum() for d in t],
        "returns_arriving": sim.return_arrivals[m][:, :days].sum(axis=0),
        "nurses_needed": np.ceil(needed / per_nurse).astype(int),
        "nurses_needed_safe": np.ceil(safe / per_nurse).astype(int),
        "nurses_on_duty": nurses,
    })
    plan["free_beds"] = plan["capacity"] - plan["beds_needed"].round().astype(int)
    plan["occupancy"] = plan["beds_needed"] / plan["capacity"]
    plan["shortfall"] = np.ceil(np.maximum(plan["beds_needed"] - plan["capacity"], 0)).astype(int)
    plan["shortfall_safe"] = np.ceil(np.maximum(plan["beds_safe"] - plan["capacity"], 0)).astype(int)
    plan["status"] = np.where(plan["beds_needed"] > plan["capacity"], "over",
                              np.where((plan["occupancy"] > tight) | (plan["beds_safe"] > plan["capacity"]),
                                       "tight", "ok"))
    plan["staff_gap"] = plan["nurses_needed"] - plan["nurses_on_duty"]
    return plan


def weekly_plan(plan: pd.DataFrame) -> pd.DataFrame:
    g = plan.assign(week=plan["day"] // 7).groupby("week")
    out = g.agg(start=("date", "first"), end=("date", "last"), peak_needed=("beds_needed", "max"),
                avg_needed=("beds_needed", "mean"), capacity=("capacity", "first"),
                critical_days=("status", lambda s: int((s == "over").sum())),
                tight_days=("status", lambda s: int((s == "tight").sum())),
                returns=("returns_arriving", "sum"), admissions=("admissions_planned", "sum"),
                nurses_peak=("nurses_needed", "max"), nurses_on_duty=("nurses_on_duty", "first"))
    out["peak_beds"] = np.ceil(out["peak_needed"]).astype(int)
    out["margin"] = out["capacity"] - out["peak_beds"]
    names = {0: "This week", 1: "Next week"}
    out["label"] = [names.get(int(w), f"In {int(w)} weeks") for w in out.index]
    return out.reset_index()


def alerts(plan: pd.DataFrame) -> list[dict]:
    """One alert per day at risk, each with options to consider (decision support, not orders)."""
    found = []
    for r in plan.itertuples():
        day = r.date.strftime("%a %d %b")
        if r.status == "over":
            postpone = min(int(r.shortfall), int(r.admissions_planned))
            options = [f"open {r.shortfall} extra bed{'s' if r.shortfall > 1 else ''}"]
            if postpone:
                options.insert(0, f"postpone {postpone} planned admission{'s' if postpone > 1 else ''}")
            found.append(dict(date=r.date, day=r.day, severity="over", shortfall=int(r.shortfall),
                              title=f"{day}: about {r.shortfall} bed{'s' if r.shortfall > 1 else ''} missing",
                              action="Consider: " + " or ".join(options) + "."))
        elif r.status == "tight" and r.shortfall_safe > 0:
            found.append(dict(date=r.date, day=r.day, severity="tight", shortfall=int(r.shortfall_safe),
                              title=f"{day}: beds may run short",
                              action=f"Keep {r.shortfall_safe} bed{'s' if r.shortfall_safe > 1 else ''} free "
                                     f"or ready to open, just in case."))
    return found


def followup_list(sim: Simulation, service: str | None = None) -> pd.DataFrame:
    """Patients in hospital now or sent home in the last 30 days, still able to come back."""
    p = sim.patients[_mask(sim, service)]
    p = p[(p["group"] == "in_hospital") | ((p["group"] == "discharged") & (p["discharge_day"] > -sim.window))]
    out = pd.DataFrame({
        "pid": p["pid"],
        "where": np.where(p["group"] == "in_hospital", "In hospital", "At home"),
        "discharge_date": [sim.today + timedelta(days=int(d)) for d in p["discharge_day"]],
        "when": [f"Leaves in {d} day{'s' if d > 1 else ''}" if d > 0 else
                 ("Went home today" if d == 0 else f"Went home {-d} day{'s' if d < -1 else ''} ago")
                 for d in p["discharge_day"].astype(int)],
        "age_band": p["age_band"], "gender": p["gender"], "service": p["service"],
        "risk": p["risk"], "level": p["level"],
        "stay_text": [stay_range(lo, hi) for lo, hi in zip(p["stay_low"], p["stay_high"])],
        "stay_likely": p["stay_likely"].round().clip(lower=1).astype(int),
        "bed_days": p["bed_days"],
        "advice": p["level"].map(ADVICE),
    })
    keep = ["main_reason", "number_inpatient", "number_emergency", "number_outpatient", "num_medications",
            "time_in_hospital", "admission_type_id", "discharge_disposition_id", "risk_rank", "encounter_id"]
    out = pd.concat([out, p[keep]], axis=1)
    order = {"High": 0, "Medium": 1, "Low": 2}
    return out.sort_values(["level", "risk"], key=lambda s: s.map(order) if s.name == "level" else -s).reset_index(drop=True)


def explain(row) -> dict:
    """Plain-language patient summary. Facts come from the file; nothing here claims a cause."""
    level, risk = row["level"], float(row["risk"])
    in100 = max(1, round(risk * 100))
    headline = {
        "High": "High risk: plan close follow-up",
        "Medium": "Medium risk: plan an earlier check-up",
        "Low": "Low risk: usual follow-up",
    }[level]
    sentence = (f"About {in100} in 100 patients like this one come back to hospital within 30 days. "
                f"Their chance is higher than for {min(99, int(float(row['risk_rank']) * 100))} out of 100 patients.")
    stay = (f"If they come back, they will most likely stay about {int(row['stay_likely'])} "
            f"day{'s' if int(row['stay_likely']) > 1 else ''} (between {row['stay_text'].replace(' to ', ' and ')}).")
    facts = []
    for col, one, many in [("number_inpatient", "hospital stay", "hospital stays"),
                           ("number_emergency", "emergency visit", "emergency visits"),
                           ("number_outpatient", "clinic visit", "clinic visits")]:
        n = int(row[col])
        if n:
            facts.append(f"{n} {one if n == 1 else many} in the past year")
    facts.append(f"{int(row['num_medications'])} medicines during this stay")
    facts.append(f"stayed {int(row['time_in_hospital'])} day{'s' if int(row['time_in_hospital']) > 1 else ''} this time")
    return dict(headline=headline, sentence=sentence, stay=stay, facts=facts, advice=ADVICE[level],
                arrival=label("admission_type_id", row["admission_type_id"]),
                leaving_to=label("discharge_disposition_id", row["discharge_disposition_id"]))


def week_compare(plan: pd.DataFrame) -> pd.DataFrame:
    weeks = weekly_plan(plan)
    return weeks[weeks["week"] < 2].set_index("label")


def summary(sim: Simulation, service: str | None = None, days: int | None = None) -> dict:
    plan = daily_plan(sim, service, days)
    follow = followup_list(sim, service)
    today = plan.iloc[0]
    return dict(
        beds_needed_today=int(round(today["beds_needed"])),
        free_beds_today=int(today["free_beds"]),
        capacity=int(today["capacity"]),
        high_risk_patients=int((follow["level"] == "High").sum()),
        critical_days=int((plan["status"] == "over").sum()),
        tight_days=int((plan["status"] == "tight").sum()),
        expected_bed_days_returns=float(follow["bed_days"].sum()),
        first_critical=(plan.loc[plan["status"] == "over", "date"].min() if (plan["status"] == "over").any() else None),
    )
