"""BedSense — Najd's bed planning and length-of-stay module (thin adapter over capalit_ml)."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="bedsense",
    name="BedSense",
    owner="Najd",
    tagline="Bed planning & length of stay",
    description=(
        "Estimates the chance that a patient comes back to hospital within 30 days, how long "
        "they would stay if they do, and the beds the ward needs over the coming weeks."
    ),
    color="#22C55E",
    status="live",
)

__all__ = ["MODULE", "router"]
