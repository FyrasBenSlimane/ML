"""Sora — Fatma · profil de sortie (suivi + contrôle du diabète)."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="sora",
    name="Sora",
    owner="Fatma",
    tagline="Discharge profile: follow-up & control",
    description="Combines two models — follow-up intensity (M1) and diabetes control (M2) — "
                "into a discharge profile with a recommendation. Result for the doctor.",
    color="#F59E0B",  # amber
    status="live",
)

__all__ = ["MODULE", "router"]
