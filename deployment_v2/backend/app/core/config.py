"""Paths and settings shared by every module."""
import os
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parents[2]
ARTIFACTS_DIR = BACKEND_DIR / "artifacts"

API_PREFIX = "/api/v1"

# Female neural voice used by the shared /tts endpoint (any en-US *Neural works).
TTS_VOICE = os.getenv("READMITGUARD_TTS_VOICE", "en-US-AvaNeural")
TTS_CACHE_SIZE = int(os.getenv("READMITGUARD_TTS_CACHE", "256"))
