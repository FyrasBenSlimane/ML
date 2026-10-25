"""
TEMPLATE router. Keep the same three habits as Teemo:
  1. load artifacts once (lru_cache), from artifacts/<your_id>/
  2. accept a pydantic model where every field has a sensible default
  3. return a `narrative` list of {kind, text} segments — the app's avatar
     stage can then read your results aloud with subtitles for free.
"""
from functools import lru_cache

import joblib
from fastapi import APIRouter
from pydantic import BaseModel

from app.core.config import ARTIFACTS_DIR

router = APIRouter()


@lru_cache(maxsize=1)
def get_model():
    return joblib.load(ARTIFACTS_DIR / "mymodel" / "model.joblib")


class MyInput(BaseModel):
    age_ordinal: int = 6
    num_medications: int = 15


@router.get("/meta")
def meta():
    return {"fields": {}, "model": {"name": "MyModel"}}


@router.post("/predict")
def predict(body: MyInput):
    # import pandas as pd
    # p = float(get_model().predict_proba(pd.DataFrame([body.model_dump()]))[0, 1])
    p = 0.12
    return {
        "probability": p,
        "narrative": [
            {"kind": "greeting", "text": "Hi, I'm MyAvatar."},
            {"kind": "score", "text": f"The result is {round(p * 100)} percent."},
        ],
    }
