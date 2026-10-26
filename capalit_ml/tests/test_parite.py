"""Parité entre capalit_ml et les notebooks de Najd.

Les notebooks n'ont pas de sorties enregistrées : la référence est donc le code des notebooks
lui-même, exécuté ici (chargement, variables, séparation par patient, fonctions de prédiction),
avec les modèles entraînés lus dans les fichiers .joblib.
"""
import ast
import inspect
import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import pytest

from capalit_ml import modele1, modele2

ROOT = Path(__file__).resolve().parent.parent
DATA_PATH = str(ROOT / "diabetic_data.csv")
NB1 = ROOT / "modele1_readmission_30j.ipynb"
NB2 = ROOT / "modele2_duree_sejour_retour.ipynb"


def _cells(nb_path):
    nb = json.loads(nb_path.read_text(encoding="utf-8"))
    return {c["id"]: "".join(c["source"]) for c in nb["cells"] if c["cell_type"] == "code"}


def _function_defs(source, names):
    tree = ast.parse(source)
    return {n.name: n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names}


def _exec_functions(ns, source, names):
    defs = _function_defs(source, names)
    assert set(defs) == set(names), f"fonctions introuvables dans le notebook : {set(names) - set(defs)}"
    exec(compile(ast.Module(body=list(defs.values()), type_ignores=[]), "<notebook>", "exec"), ns)


def _same_source(module_fn, notebook_source):
    nb_def = _function_defs(notebook_source, [module_fn.__name__])[module_fn.__name__]
    mod_def = ast.parse(inspect.getsource(module_fn)).body[0]
    return ast.dump(nb_def) == ast.dump(mod_def)


@pytest.fixture(scope="module")
def nb1():
    cells = _cells(NB1)
    ns = {"pd": pd, "np": np, "DATA_PATH": DATA_PATH, "SAMPLE": None, "SEED": 42}
    for cid in ["c7ce23b8", "dabb6c46", "25d3b540"]:   # étapes 2, 3, 4
        exec(cells[cid], ns)
    _exec_functions(ns, cells["f470e09d"], ["prep"])
    a = joblib.load(modele1.ARTIFACT_PATH)
    ns.update(final_model=a["model"], iso=a["calibrator"], BEST_NAME=a["best_name"],
              thr_med=a["thr_med"], thr_high=a["thr_high"])
    _exec_functions(ns, cells["1d52e45d"], ["predict_patients"])
    ns["_cells"] = cells
    return ns


@pytest.fixture(scope="module")
def nb2():
    cells = _cells(NB2)
    ns = {"pd": pd, "np": np, "DATA_PATH": DATA_PATH, "SAMPLE": None, "SEED": 42}
    for cid in ["22f1c129", "1668348c", "181e4643"]:   # étapes 2, 3, 4
        exec(cells[cid], ns)
    a = joblib.load(modele2.ARTIFACT_PATH)
    ns.update(m_med=a["m_med"], m_q10=a["m_q10"], m_q90=a["m_q90"], m_avg=a["m_avg"], DELTA=a["delta"])
    _exec_functions(ns, cells["90230db2"], ["predict_all"])
    _exec_functions(ns, cells["a8d899a3"], ["predict_los", "charge_attendue"])
    ns["_cells"] = cells
    return ns


# ---------- Le code recopié est identique à celui des notebooks ----------

@pytest.mark.parametrize("fn,cell", [
    ("icd9_group", "dabb6c46"), ("build_features", "dabb6c46"), ("apply_categories", "dabb6c46"),
    ("prep", "f470e09d"), ("predict_patients", "1d52e45d"),
])
def test_modele1_code_identique(nb1, fn, cell):
    assert _same_source(getattr(modele1, fn), nb1["_cells"][cell])


@pytest.mark.parametrize("fn,cell", [
    ("icd9_group", "1668348c"), ("build_features", "1668348c"), ("apply_categories", "1668348c"),
    ("predict_all", "90230db2"), ("predict_los", "a8d899a3"), ("charge_attendue", "a8d899a3"),
])
def test_modele2_code_identique(nb2, fn, cell):
    assert _same_source(getattr(modele2, fn), nb2["_cells"][cell])


def test_modele1_constantes(nb1):
    assert modele1.MED_COLS == nb1["MED_COLS"]
    assert modele1.CAT == nb1["CAT"] and modele1.NUM == nb1["NUM"]
    assert modele1.TOP_SPEC == nb1["TOP_SPEC"]
    assert modele1.CATEGORIES == nb1["CATEGORIES"]


def test_modele2_constantes(nb2):
    assert modele2.MED_COLS == nb2["MED_COLS"]
    assert modele2.CAT == nb2["CAT"] and modele2.NUM == nb2["NUM"]
    assert modele2.TOP_SPEC == nb2["TOP_SPEC"]
    assert modele2.CATEGORIES == nb2["CATEGORIES"]


# ---------- Mêmes sorties que les notebooks ----------

def test_modele1_parite_5_patients(nb1):
    ex = nb1["df"].iloc[nb1["test_idx"][:5]]            # exemple de l'étape 11 du notebook
    pd.testing.assert_frame_equal(modele1.predict_patients(ex), nb1["predict_patients"](ex), check_exact=True)


def test_modele1_parite_tout_le_test(nb1):
    ex = nb1["df"].iloc[nb1["test_idx"]]
    pd.testing.assert_frame_equal(modele1.predict_patients(ex), nb1["predict_patients"](ex), check_exact=True)


def test_modele2_parite_5_patients(nb2):
    ex = nb2["pairs"].iloc[nb2["test_idx"]].loc[lambda d: d["is_lt30"] == 1].head(5)   # exemple de l'étape 11
    pd.testing.assert_frame_equal(modele2.predict_los(ex), nb2["predict_los"](ex), check_exact=True)


def test_modele2_parite_tout_le_test(nb2):
    ex = nb2["pairs"].iloc[nb2["test_idx"]]
    pd.testing.assert_frame_equal(modele2.predict_los(ex), nb2["predict_los"](ex), check_exact=True)


def test_charge_attendue_parite(nb2):
    p, los = [0.32, 0.14, 0.05, 0.20, 0.10], [5.1, 4.0, 3.2, 6.8, 2.5]
    np.testing.assert_array_equal(modele2.charge_attendue(p, los), nb2["charge_attendue"](p, los))


# ---------- Cohérence des sorties sur tout le fichier ----------

@pytest.fixture(scope="module")
def all_rows():
    return pd.read_csv(DATA_PATH, na_values="?", low_memory=False)


def test_modele1_sorties_valides(all_rows):
    out = modele1.predict_patients(all_rows)
    assert out["risque_retour_30j"].between(0, 1).all()
    assert set(out["niveau"]) <= {"faible", "moyen", "élevé"}
    assert modele1.thr_med < modele1.thr_high


def test_modele2_sorties_valides(all_rows):
    out = modele2.predict_los(all_rows)
    for c in out.columns:
        assert out[c].between(1, 14).all()
    assert (out["duree_basse_j"] <= out["duree_mediane_j"]).all()
    assert (out["duree_mediane_j"] <= out["duree_haute_j"]).all()
