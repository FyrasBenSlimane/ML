"""
TEMPLATE — copy this folder to app/modules/<your_id>/ (no leading underscore)
and fill in MODULE + router. Nothing else in the backend needs to change.
"""
from app.core.registry import ModuleInfo
from .router import router

MODULE = ModuleInfo(
    id="mymodel",                 # -> /api/v1/mymodel/...
    name="MyAvatar",              # shown in the app
    owner="Your name",
    tagline="One-line promise",
    description="What the model predicts and for whom.",
    color="#8B5CF6",
    status="beta",
)

__all__ = ["MODULE", "router"]
