"""
MAAK معاك v2 API — entry point.

    uvicorn app.main:app --host 0.0.0.0 --port 8000

Use --host 0.0.0.0 so a phone on the same Wi-Fi can reach the server.
"""
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core import portal, registry, tts
from app.core.config import API_PREFIX

logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(name)s  %(message)s")

app = FastAPI(
    title="MAAK معاك API",
    version="2.0.0",
    description="Model modules for the MAAK معاك mobile app. "
                "Each team member's model lives in app/modules/<id>.",
)

# The Flutter web build and dev tools call from other origins.
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"],
                   allow_headers=["*"])

app.include_router(tts.router, prefix=API_PREFIX)
MODULES = registry.discover(app, API_PREFIX)

# Portail patient : auth, confirmation patient, alertes + garde des /predict.
portal.install(app, API_PREFIX)


@app.get("/health", tags=["System"])
def health():
    live = [m.id for m in MODULES if m.status != "error"]
    return {"status": "ok", "version": app.version, "modules": live}


@app.get(f"{API_PREFIX}/modules", tags=["System"], summary="Modules mounted on this server")
def modules():
    return registry.as_dicts(MODULES)
