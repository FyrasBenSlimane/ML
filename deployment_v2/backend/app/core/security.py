# -*- coding: utf-8 -*-
"""Sécurité du portail : hachage des mots de passe, jetons signés, ID patient.

Tout repose sur la librairie standard (hashlib / hmac / secrets) — aucune
dépendance supplémentaire.
"""
import base64
import hashlib
import hmac
import json
import os
import secrets
import time

# Clé de signature des jetons. En production on la fixe via MAAK_SECRET ;
# la valeur par défaut ne sert qu'au développement.
_SECRET = os.getenv("MAAK_SECRET", "maak-dev-secret-change-me").encode("utf-8")

# Code établissement exigé pour créer un compte médecin (défaut de dev).
MEDECIN_CODE_DEFAULT = "MAAK-MED-2024"

TOKEN_TTL_SECONDS = 7 * 24 * 3600  # jeton valable 7 jours

_PBKDF2_ROUNDS = 120_000


def medecin_code() -> str:
    """Code attendu à l'inscription d'un médecin (variable d'environnement)."""
    return os.getenv("MAAK_MEDECIN_CODE", MEDECIN_CODE_DEFAULT)


# --------------------------------------------------------------------------- #
# Format de l'identifiant patient — centralisé dans UNE seule fonction.
# --------------------------------------------------------------------------- #
PATIENT_PREFIX = "PT-"


def format_patient_code(user_id: int) -> str:
    """Identifiant patient lisible : « PT-00001 » (id sur 5 chiffres)."""
    return f"{PATIENT_PREFIX}{user_id:05d}"


def parse_patient_code(code: str) -> int | None:
    """Inverse de format_patient_code ; None si le code est mal formé."""
    if not code:
        return None
    code = code.strip().upper()
    if not code.startswith(PATIENT_PREFIX):
        return None
    reste = code[len(PATIENT_PREFIX):]
    return int(reste) if reste.isdigit() else None


# --------------------------------------------------------------------------- #
# Mots de passe : PBKDF2-HMAC-SHA256 avec sel aléatoire.
# --------------------------------------------------------------------------- #
def hash_password(password: str) -> str:
    """Retourne « sel$empreinte » (hex) ; sel unique par utilisateur."""
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, _PBKDF2_ROUNDS)
    return f"{salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    """Compare en temps constant le mot de passe au couple « sel$empreinte »."""
    try:
        salt_hex, digest_hex = stored.split("$", 1)
        salt = bytes.fromhex(salt_hex)
        expected = bytes.fromhex(digest_hex)
    except (ValueError, AttributeError):
        return False
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, _PBKDF2_ROUNDS)
    return hmac.compare_digest(digest, expected)


# --------------------------------------------------------------------------- #
# Jetons signés HMAC (format compact « payload.signature », base64url).
# --------------------------------------------------------------------------- #
def _b64e(raw: bytes) -> str:
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def _b64d(txt: str) -> bytes:
    pad = "=" * (-len(txt) % 4)
    return base64.urlsafe_b64decode(txt + pad)


def _sign(payload_b64: str) -> str:
    sig = hmac.new(_SECRET, payload_b64.encode("ascii"), hashlib.sha256).digest()
    return _b64e(sig)


def make_token(user_id: int, role: str) -> str:
    """Crée un jeton signé portant l'id, le rôle et une expiration (7 jours)."""
    payload = {"uid": user_id, "role": role, "exp": int(time.time()) + TOKEN_TTL_SECONDS}
    payload_b64 = _b64e(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    return f"{payload_b64}.{_sign(payload_b64)}"


def read_token(token: str) -> dict | None:
    """Vérifie signature et expiration ; retourne le payload ou None."""
    if not token or token.count(".") != 1:
        return None
    payload_b64, sig = token.split(".", 1)
    if not hmac.compare_digest(sig, _sign(payload_b64)):
        return None
    try:
        payload = json.loads(_b64d(payload_b64))
    except (ValueError, json.JSONDecodeError):
        return None
    if int(payload.get("exp", 0)) < int(time.time()):
        return None
    return payload
