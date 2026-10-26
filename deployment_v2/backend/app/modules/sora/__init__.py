"""Sora — Fatma · profil de sortie (suivi + contrôle du diabète)."""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="sora",
    name="Sora",
    owner="Fatma",
    tagline="Profil de sortie : suivi & contrôle",
    description="Combine deux modèles — intensité du suivi (M1) et contrôle du diabète (M2) — "
                "en un profil de sortie avec recommandation. Résultat destiné au médecin.",
    color="#F59E0B",  # amber
    status="live",
)

__all__ = ["MODULE", "router"]
