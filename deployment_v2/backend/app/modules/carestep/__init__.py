"""CareStep — Fyras · 30-day recovery companion (patient-reported readmission risk)."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="carestep",
    name="CareStep",
    owner="Fyras",
    tagline="30-day recovery companion",
    description="Calibrated LightGBM on 12 patient-reportable answers (no lab codes): "
                "30-day readmission risk, why, what to do, a week-by-week recovery plan "
                "and a care-team summary.",
    color="#3B82F6",  # blue
    status="live",
)

__all__ = ["MODULE", "router"]
