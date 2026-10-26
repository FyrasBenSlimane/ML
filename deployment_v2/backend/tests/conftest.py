# -*- coding: utf-8 -*-
"""Config pytest : base SQLite jetable, recréée à chaque session de tests.

On fixe MAAK_DB *avant* tout import de l'application pour que le portail et la
garde des /predict écrivent dans une base temporaire, jamais dans maak.db.
"""
import os
import tempfile
from pathlib import Path

_TEST_DB = Path(tempfile.gettempdir()) / "maak_test.db"
if _TEST_DB.exists():
    _TEST_DB.unlink()
os.environ["MAAK_DB"] = str(_TEST_DB)
