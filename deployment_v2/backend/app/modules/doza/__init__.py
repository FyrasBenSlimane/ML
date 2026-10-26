"""Doza — Emna · changement de dose d'insuline."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="doza",
    name="Doza",
    owner="Emna",
    tagline="Changement de dose d'insuline",
    description="Pipeline Gradient Boosting calibré : probabilité et zone de risque que la "
                "dose d'insuline change, avec les facteurs qui ont le plus pesé (explication). "
                "Résultat destiné au médecin.",
    color="#FB7185",  # coral
    status="live",
)

__all__ = ["MODULE", "router"]
