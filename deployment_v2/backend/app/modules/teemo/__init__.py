"""Teemo — Ryma's 30-day readmission risk advisor."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="teemo",
    name="Teemo",
    owner="Ryma",
    tagline="30-day readmission risk advisor",
    description="Calibrated LightGBM on 38 features with per-patient SHAP explanations, "
                "an action plan, and a spoken summary.",
    color="#14B8A6",
    status="live",
)

__all__ = ["MODULE", "router"]
