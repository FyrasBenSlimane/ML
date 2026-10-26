"""MedOracle — Faycel's equity-of-care analysis tool for clinicians."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="medoracle",
    name="MedOracle",
    owner="Faycel",
    tagline="Care equity comparison analysis",
    description="Compares the average observed gaps between profiles of comparable clinical severity.",
    color="#8B5CF6",
    status="live",
)

__all__ = ["MODULE", "router"]
