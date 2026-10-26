"""
Plug-in registry: discovers every package in app/modules and mounts its router.

A teammate integrates by dropping a folder into app/modules — no edit to
main.py. A module that fails to import is reported as status="error" in
/api/v1/modules instead of taking the whole server down.
"""
import importlib
import logging
import pkgutil
import traceback
from dataclasses import asdict, dataclass, field
from typing import List, Optional

from fastapi import APIRouter, FastAPI

log = logging.getLogger("maak.registry")


@dataclass
class ModuleInfo:
    id: str                      # url-safe, unique: /api/v1/<id>/...
    name: str                    # display name of the avatar / tool
    owner: str                   # team member
    tagline: str = ""
    description: str = ""
    color: str = "#6366F1"       # accent colour used by the app
    status: str = "live"         # live | beta | coming_soon | error
    error: Optional[str] = None
    endpoints: List[str] = field(default_factory=list)


def discover(app: FastAPI, prefix: str) -> List[ModuleInfo]:
    from app import modules as pkg

    found: List[ModuleInfo] = []
    for m in sorted(pkgutil.iter_modules(pkg.__path__), key=lambda m: m.name):
        if m.name.startswith("_"):
            continue  # _template and private helpers
        dotted = f"{pkg.__name__}.{m.name}"
        try:
            mod = importlib.import_module(dotted)
            info: ModuleInfo = mod.MODULE
            router: APIRouter = mod.router
            app.include_router(router, prefix=f"{prefix}/{info.id}", tags=[info.name])
            info.endpoints = sorted({f"{prefix}/{info.id}{r.path}" for r in router.routes})
            found.append(info)
            log.info("module %-12s mounted (%d routes)", info.id, len(router.routes))
        except Exception as exc:  # isolate broken modules
            log.error("module %s failed to load:\n%s", m.name, traceback.format_exc())
            found.append(ModuleInfo(id=m.name, name=m.name, owner="?", status="error",
                                    error=f"{type(exc).__name__}: {exc}"))
    return found


def as_dicts(modules: List[ModuleInfo]):
    return [asdict(m) for m in modules]
