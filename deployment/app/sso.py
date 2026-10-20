"""
SSO ReadmitGuard <- MedCare (ajout non invasif).

MedCare (portail personnel) ouvre ReadmitGuard avec ?token=... . Ce module vérifie
le jeton signé et connecte automatiquement le soignant. Jeton absent -> rien (on
garde le formulaire de Ryma). Jeton invalide/expiré -> message d'erreur en français.

Format du jeton (identique côté MedCare, cf README) :
    token   = base64url(payload) . "." . base64url(HMAC_SHA256(payload, SECRET))
    payload = {"uid", "name", "role", "exp"}   (exp = timestamp + 600 s)
La clé SECRET est lue dans la variable d'environnement READMITGUARD_SECRET,
sinon dans deployment/.env (non versionné).
"""
import os
import json
import time
import hmac
import hashlib
import base64
from pathlib import Path


def _load_env_file():
    env = {}
    p = Path(__file__).resolve().parent.parent / ".env"
    if p.exists():
        for line in p.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip('"').strip("'")
    return env


_ENV_FILE = _load_env_file()


def _conf(key, default):
    return os.environ.get(key) or _ENV_FILE.get(key) or default


READMITGUARD_SECRET = _conf("READMITGUARD_SECRET", "dev-secret-a-changer")
MEDCARE_URL = _conf("MEDCARE_URL", "http://127.0.0.1:8000/personnel")


def _b64url_decode(s):
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


def verifier_token(token):
    """Renvoie le payload (dict) si le jeton est valide et non expiré, sinon lève ValueError."""
    try:
        payload_b64, sig_b64 = token.split(".")
        payload_bytes = _b64url_decode(payload_b64)
        received = _b64url_decode(sig_b64)
    except Exception:
        raise ValueError("Jeton d'accès mal formé.")

    expected = hmac.new(READMITGUARD_SECRET.encode("utf-8"), payload_bytes, hashlib.sha256).digest()
    if not hmac.compare_digest(expected, received):
        raise ValueError("Jeton d'accès invalide (signature).")

    data = json.loads(payload_bytes.decode("utf-8"))
    if int(data.get("exp", 0)) < int(time.time()):
        raise ValueError("Jeton expiré. Revenez à MedCare pour vous reconnecter.")
    return data


def try_token_login():
    """
    Si l'URL contient ?token=..., connecte automatiquement le soignant.
    Renvoie un message d'erreur (str) si le jeton est présent mais invalide, sinon None.
    """
    import streamlit as st

    if st.session_state.get("logged_in"):
        return None
    token = st.query_params.get("token")
    if not token:
        return None
    try:
        data = verifier_token(token)
    except ValueError as e:
        return str(e)

    st.session_state["logged_in"] = True
    st.session_state["user_name"] = data.get("name", "Soignant")
    st.session_state["portal_type"] = "medical"
    try:
        st.query_params.clear()
    except Exception:
        pass
    return None
