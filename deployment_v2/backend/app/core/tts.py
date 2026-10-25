"""
Shared text-to-speech: Microsoft neural voices through `edge-tts`.

POST /api/v1/tts returns an audio URL plus word timings, which the app uses to
highlight subtitles word by word. Any module can use it (it is not Teemo-only).
Needs internet access; when it fails the endpoint answers 503 and the app
falls back to the phone's built-in female voice.
"""
import hashlib
from collections import OrderedDict
from typing import Optional

import edge_tts
from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import Response
from pydantic import BaseModel, Field

from .config import TTS_CACHE_SIZE, TTS_VOICE

router = APIRouter(tags=["Voice"])

FEMALE_VOICES = ["en-US-AvaNeural", "en-US-JennyNeural", "en-US-AriaNeural",
                 "en-US-EmmaNeural", "en-GB-SoniaNeural", "en-US-MichelleNeural"]

_cache: "OrderedDict[str, dict]" = OrderedDict()


class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=2000)
    voice: Optional[str] = None
    rate: str = Field("+0%", pattern=r"^[+-]\d{1,2}%$", description="e.g. -10% slower, +10% faster")
    pitch: str = Field("+0Hz", pattern=r"^[+-]\d{1,2}Hz$")


async def synthesize(text: str, voice: str, rate: str, pitch: str) -> dict:
    key = hashlib.sha1(f"{voice}|{rate}|{pitch}|{text}".encode()).hexdigest()[:16]
    if key in _cache:
        _cache.move_to_end(key)
        return _cache[key]
    comm = edge_tts.Communicate(text, voice, rate=rate, pitch=pitch, boundary="WordBoundary")
    audio, words = bytearray(), []
    async for chunk in comm.stream():
        if chunk["type"] == "audio":
            audio.extend(chunk["data"])
        elif chunk["type"] == "WordBoundary":
            start = chunk["offset"] // 10_000          # 100-ns ticks -> ms
            words.append({"text": chunk["text"], "start_ms": start,
                          "end_ms": start + chunk["duration"] // 10_000})
    if not audio:
        raise RuntimeError("no audio returned")
    entry = {"id": key, "audio": bytes(audio), "words": words, "voice": voice,
             "duration_ms": words[-1]["end_ms"] if words else 0}
    _cache[key] = entry
    while len(_cache) > TTS_CACHE_SIZE:
        _cache.popitem(last=False)
    return entry


@router.post("/tts", summary="Synthesize speech (female neural voice) with word timings")
async def tts(req: TTSRequest, request: Request):
    voice = req.voice or TTS_VOICE
    try:
        entry = await synthesize(req.text, voice, req.rate, req.pitch)
    except Exception as exc:
        raise HTTPException(503, detail=f"tts_unavailable: {type(exc).__name__}: {exc}")
    return {
        "id": entry["id"],
        "audio_url": str(request.url_for("tts_audio", clip_id=entry["id"])),
        "words": entry["words"],
        "duration_ms": entry["duration_ms"],
        "voice": entry["voice"],
    }


@router.get("/tts/voices", summary="Recommended female voices")
def voices():
    return {"default": TTS_VOICE, "voices": FEMALE_VOICES}


@router.get("/tts/audio/{clip_id}.mp3", name="tts_audio", include_in_schema=False)
def tts_audio(clip_id: str):
    entry = _cache.get(clip_id)
    if entry is None:
        raise HTTPException(404, detail="clip expired — request /tts again")
    return Response(entry["audio"], media_type="audio/mpeg",
                    headers={"Cache-Control": "public, max-age=86400"})
