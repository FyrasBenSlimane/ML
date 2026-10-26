"""Doza — Emna · changement de dose d'insuline."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="doza",
    name="Doza",
    owner="Emna",
    tagline="Insulin dose change advisor",
    description="Calibrated Gradient Boosting pipeline: probability and risk zone that the "
                "insulin dose changes, with the factors that weighed most (explanation). "
                "Result for the doctor.",
    color="#FB7185",  # coral
    status="live",
)

__all__ = ["MODULE", "router"]
