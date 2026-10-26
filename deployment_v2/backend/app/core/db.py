# -*- coding: utf-8 -*-
"""Base SQLite locale du portail patient (comptes, évaluations, notifications).

Aucune dépendance nouvelle : on utilise le module `sqlite3` de la librairie
standard. Le fichier vit dans backend/data/maak.db ; le chemin est réglable par
la variable d'environnement MAAK_DB (utilisée par les tests pour une base
jetable).
"""
import os
import sqlite3
from pathlib import Path

from app.core.config import BACKEND_DIR


def db_path() -> Path:
    """Emplacement du fichier SQLite (lu à chaque appel -> testable)."""
    env = os.getenv("MAAK_DB")
    if env:
        return Path(env)
    return BACKEND_DIR / "data" / "maak.db"


def connect() -> sqlite3.Connection:
    """Ouvre une connexion ; les lignes se lisent comme des dictionnaires."""
    path = db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


_SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    prenom        TEXT NOT NULL,
    nom           TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('patient', 'medecin')),
    created_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS evaluations (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL REFERENCES users(id),
    medecin_id INTEGER NOT NULL REFERENCES users(id),
    module     TEXT NOT NULL,
    resultat   TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS notifications (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    patient_id INTEGER NOT NULL REFERENCES users(id),
    medecin_id INTEGER NOT NULL REFERENCES users(id),
    module     TEXT NOT NULL,
    niveau     TEXT NOT NULL CHECK (niveau IN ('info', 'attention', 'important')),
    titre      TEXT NOT NULL,
    message    TEXT NOT NULL,
    lu         INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL
);
"""


def init_db() -> None:
    """Crée les tables si besoin. Idempotent : appelée au démarrage du serveur."""
    conn = connect()
    try:
        conn.executescript(_SCHEMA)
        conn.commit()
    finally:
        conn.close()
