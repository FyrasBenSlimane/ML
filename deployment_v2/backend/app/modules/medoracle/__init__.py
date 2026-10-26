"""MedOracle — Faycel's equity-of-care analysis tool for clinicians."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="medoracle",
    name="MedOracle",
    owner="Faycel",
    tagline="Analyse comparative de l'équité des soins",
    description="Compare les écarts moyens observés entre profils à gravité clinique comparable.",
    color="#8B5CF6",
    status="live",
)

__all__ = ["MODULE", "router"]
