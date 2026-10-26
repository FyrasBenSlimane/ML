# -*- coding: utf-8 -*-
"""Portail patient : comptes, garde des modèles, alertes bienveillantes.

Règle (décision du professeur) : le patient ne voit JAMAIS un résultat de
modèle. Doza, Sora et Teemo sont réservés au MÉDECIN authentifié, qui envoie
ensuite une alerte rédigée (sans chiffre) au patient.

Ce module « core » ajoute, sans toucher aux modules de modèles :
  * /api/v1/auth    inscription / connexion / profil
  * /api/v1/patients/{code}   (médecin) confirmation d'un patient
  * /api/v1/notifications     alertes médecin -> patient
  * une garde (middleware) qui protège tous les /predict et enregistre
    chaque évaluation (patient, médecin, module, résultat, date).
"""
import json
import logging
import re
import sqlite3
from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field, field_validator
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from app.core import db
from app.core.security import (
    format_patient_code,
    hash_password,
    make_token,
    medecin_code,
    parse_patient_code,
    read_token,
    verify_password,
)

log = logging.getLogger("maak.portal")

# Modules dont le /predict est réservé au médecin et journalisé.
GUARDED_MODULES = ("doza", "sora", "teemo", "medoracle")
_PREDICT_RE = re.compile(r"^/api/v1/(" + "|".join(GUARDED_MODULES) + r")/predict/?$")


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


# --------------------------------------------------------------------------- #
# Accès base
# --------------------------------------------------------------------------- #
def _user_by_id(uid: int) -> sqlite3.Row | None:
    conn = db.connect()
    try:
        return conn.execute("SELECT * FROM users WHERE id = ?", (uid,)).fetchone()
    finally:
        conn.close()


def _user_by_email(email: str) -> sqlite3.Row | None:
    conn = db.connect()
    try:
        return conn.execute("SELECT * FROM users WHERE email = ?", (email.lower(),)).fetchone()
    finally:
        conn.close()


def _public_user(row: sqlite3.Row) -> dict:
    """Vue publique d'un compte (jamais l'empreinte du mot de passe)."""
    return {
        "id": row["id"],
        "prenom": row["prenom"],
        "nom": row["nom"],
        "email": row["email"],
        "role": row["role"],
        "code": format_patient_code(row["id"]),
        "created_at": row["created_at"],
    }


# --------------------------------------------------------------------------- #
# Dépendances d'authentification
# --------------------------------------------------------------------------- #
def _bearer(authorization: str | None) -> str | None:
    if authorization and authorization.lower().startswith("bearer "):
        return authorization[7:].strip()
    return None


def current_user(authorization: str | None = Header(default=None)) -> sqlite3.Row:
    payload = read_token(_bearer(authorization) or "")
    if not payload:
        raise HTTPException(401, "Authentication required.")
    user = _user_by_id(int(payload["uid"]))
    if not user:
        raise HTTPException(401, "Account not found.")
    return user


def require_medecin(user: sqlite3.Row = Depends(current_user)) -> sqlite3.Row:
    if user["role"] != "medecin":
        raise HTTPException(403, "Action restricted to the doctor.")
    return user


def require_patient(user: sqlite3.Row = Depends(current_user)) -> sqlite3.Row:
    if user["role"] != "patient":
        raise HTTPException(403, "Action restricted to the patient.")
    return user


# --------------------------------------------------------------------------- #
# Schémas
# --------------------------------------------------------------------------- #
_EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class RegisterIn(BaseModel):
    prenom: str = Field(min_length=1)
    nom: str = Field(min_length=1)
    email: str
    password: str = Field(min_length=6)
    role: Literal["patient", "medecin"] = "patient"
    code: str | None = None  # code établissement, obligatoire pour un médecin

    @field_validator("email")
    @classmethod
    def _email(cls, v: str) -> str:
        if not _EMAIL_RE.match(v.strip()):
            raise ValueError("Invalid email address.")
        return v.strip()


class LoginIn(BaseModel):
    email: str
    password: str


class NotificationIn(BaseModel):
    patient_code: str
    module: str
    niveau: Literal["info", "attention", "important"] = "info"
    titre: str = Field(min_length=1)
    message: str = Field(min_length=1)


# --------------------------------------------------------------------------- #
# Routeur AUTH
# --------------------------------------------------------------------------- #
auth_router = APIRouter(prefix="/auth", tags=["Portail · Auth"])


@auth_router.post("/register", summary="Créer un compte patient ou médecin")
def register(body: RegisterIn):
    if body.role == "medecin" and (body.code or "") != medecin_code():
        raise HTTPException(403, "Invalid establishment code for a doctor account.")
    if _user_by_email(body.email):
        raise HTTPException(400, "An account already exists with this email.")
    conn = db.connect()
    try:
        cur = conn.execute(
            "INSERT INTO users (prenom, nom, email, password_hash, role, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (body.prenom.strip(), body.nom.strip(), body.email.lower(),
             hash_password(body.password), body.role, _now()),
        )
        conn.commit()
        row = conn.execute("SELECT * FROM users WHERE id = ?", (cur.lastrowid,)).fetchone()
    finally:
        conn.close()
    return {"token": make_token(row["id"], row["role"]), "user": _public_user(row)}


@auth_router.post("/login", summary="Se connecter et obtenir un jeton (7 jours)")
def login(body: LoginIn):
    row = _user_by_email(body.email)
    if not row or not verify_password(body.password, row["password_hash"]):
        raise HTTPException(401, "Incorrect email or password.")
    return {"token": make_token(row["id"], row["role"]), "user": _public_user(row)}


@auth_router.get("/me", summary="Profil du compte connecté")
def me(user: sqlite3.Row = Depends(current_user)):
    return _public_user(user)


# --------------------------------------------------------------------------- #
# Routeur PATIENTS (médecin)
# --------------------------------------------------------------------------- #
patients_router = APIRouter(prefix="/patients", tags=["Portail · Patients"])


def _patient_by_code(code: str) -> sqlite3.Row:
    uid = parse_patient_code(code)
    row = _user_by_id(uid) if uid is not None else None
    if not row or row["role"] != "patient":
        raise HTTPException(404, "No patient matches this ID.")
    return row


@patients_router.get("/{code}", summary="Confirmer un patient par son ID (médecin)")
def get_patient(code: str, _: sqlite3.Row = Depends(require_medecin)):
    row = _patient_by_code(code)
    return {"code": format_patient_code(row["id"]), "prenom": row["prenom"], "nom": row["nom"]}


# --------------------------------------------------------------------------- #
# Routeur NOTIFICATIONS
# --------------------------------------------------------------------------- #
notifications_router = APIRouter(prefix="/notifications", tags=["Portail · Alertes"])


@notifications_router.post("", summary="Envoyer une alerte au patient (médecin)")
def send_notification(body: NotificationIn, medecin: sqlite3.Row = Depends(require_medecin)):
    patient = _patient_by_code(body.patient_code)
    # L'évaluation doit appartenir à ce patient (et avoir été faite par ce médecin).
    conn = db.connect()
    try:
        evalu = conn.execute(
            "SELECT 1 FROM evaluations WHERE patient_id = ? AND medecin_id = ? AND module = ? "
            "LIMIT 1",
            (patient["id"], medecin["id"], body.module),
        ).fetchone()
        if not evalu:
            raise HTTPException(
                403, "You must assess this patient with this module before alerting them.")
        cur = conn.execute(
            "INSERT INTO notifications "
            "(patient_id, medecin_id, module, niveau, titre, message, lu, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?, 0, ?)",
            (patient["id"], medecin["id"], body.module, body.niveau,
             body.titre.strip(), body.message.strip(), _now()),
        )
        conn.commit()
        nid = cur.lastrowid
    finally:
        conn.close()
    return {"id": nid, "status": "sent", "patient": format_patient_code(patient["id"])}


@notifications_router.get("", summary="Mes alertes (patient)")
def list_notifications(patient: sqlite3.Row = Depends(require_patient)):
    conn = db.connect()
    try:
        rows = conn.execute(
            "SELECT n.id, n.module, n.niveau, n.titre, n.message, n.lu, n.created_at, "
            "       u.prenom AS medecin_prenom, u.nom AS medecin_nom "
            "FROM notifications n JOIN users u ON u.id = n.medecin_id "
            "WHERE n.patient_id = ? ORDER BY n.created_at DESC, n.id DESC",
            (patient["id"],),
        ).fetchall()
    finally:
        conn.close()
    return [
        {
            "id": r["id"],
            "module": r["module"],
            "niveau": r["niveau"],
            "titre": r["titre"],
            "message": r["message"],
            "lu": bool(r["lu"]),
            "created_at": r["created_at"],
            "medecin": f"Dr {r['medecin_prenom']} {r['medecin_nom']}",
        }
        for r in rows
    ]


@notifications_router.post("/{notif_id}/read", summary="Marquer une alerte comme lue (patient)")
def mark_read(notif_id: int, patient: sqlite3.Row = Depends(require_patient)):
    conn = db.connect()
    try:
        cur = conn.execute(
            "UPDATE notifications SET lu = 1 WHERE id = ? AND patient_id = ?",
            (notif_id, patient["id"]),
        )
        conn.commit()
        if cur.rowcount == 0:
            raise HTTPException(404, "Alert not found.")
    finally:
        conn.close()
    return {"id": notif_id, "lu": True}


# --------------------------------------------------------------------------- #
# Garde des /predict (middleware) : médecin authentifié + code patient, et
# journalisation de chaque évaluation. Les modules de modèles restent intacts.
# --------------------------------------------------------------------------- #
def _json_error(status: int, detail: str) -> Response:
    return Response(json.dumps({"detail": detail}), status_code=status,
                    media_type="application/json")


class PredictGuardMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        match = _PREDICT_RE.match(request.url.path)
        if not (match and request.method == "POST"):
            return await call_next(request)

        module = match.group(1)
        payload = read_token(_bearer(request.headers.get("authorization")) or "")
        if not payload:
            return _json_error(401, "Doctor sign-in required for an assessment.")
        if payload.get("role") != "medecin":
            return _json_error(403, "Only a doctor can run an assessment.")
        medecin = _user_by_id(int(payload["uid"]))
        if not medecin:
            return _json_error(401, "Doctor account not found.")

        code = request.headers.get("x-patient-code")
        uid = parse_patient_code(code or "")
        patient = _user_by_id(uid) if uid is not None else None
        if not code:
            return _json_error(400, "The patient ID is required.")
        if not patient or patient["role"] != "patient":
            return _json_error(404, "No patient matches this ID.")

        response = await call_next(request)
        body = b"".join([chunk async for chunk in response.body_iterator])

        if response.status_code == 200:
            try:
                conn = db.connect()
                try:
                    conn.execute(
                        "INSERT INTO evaluations "
                        "(patient_id, medecin_id, module, resultat, created_at) "
                        "VALUES (?, ?, ?, ?, ?)",
                        (patient["id"], medecin["id"], module,
                         body.decode("utf-8", "replace"), _now()),
                    )
                    conn.commit()
                finally:
                    conn.close()
            except Exception:  # la journalisation ne doit jamais casser la réponse
                log.exception("échec de l'enregistrement de l'évaluation %s", module)

        headers = {k: v for k, v in response.headers.items() if k.lower() != "content-length"}
        return Response(content=body, status_code=response.status_code, headers=headers,
                        media_type=response.media_type)


def install(app, prefix: str) -> None:
    """Branche la base, les routeurs du portail et la garde des /predict."""
    db.init_db()
    app.add_middleware(PredictGuardMiddleware)
    app.include_router(auth_router, prefix=prefix)
    app.include_router(patients_router, prefix=prefix)
    app.include_router(notifications_router, prefix=prefix)
