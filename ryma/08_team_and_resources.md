# 08 — Team, resources and feasibility

## Hardware
i7 12th gen, 32 GB RAM: more than enough.
- CSV ~18 MB, ~100k rows → loads in about a second, well under 1 GB RAM.
- Logistic regression, Random Forest, XGBoost, LightGBM train on CPU in seconds to minutes.
- Hyperparameter search with GroupKFold: minutes to about an hour.
- SHAP: compute on a 2,000–5,000 sample.
- **No GPU needed.** Free hosting (Streamlit Cloud, Hugging Face Spaces, Render) handles a model this size.

## Feasibility
- Alone: about 4–6 weeks of steady work (the time goes into understanding and cleaning the data).
- Group of 6: comfortable, with room to go deeper than other groups.

## Roles (6 people)
| # | Role | Deliverables |
|---|---|---|
| 1 | Business & documentation | OM/ODS, cost analysis, model card, final presentation |
| 2 | EDA | Distributions, missing-value analysis, HbA1c insight |
| 3 | Data preparation | Leakage fixes, ICD-9 grouping, medication features, sklearn pipeline |
| 4 | Modeling | Baseline, boosting models, tuning, calibration |
| 5 | Evaluation & trust | Cost-based threshold, SHAP, fairness audit |
| 6 | Deployment | FastAPI, Streamlit UI, Docker, hosting, monitoring |

Everyone must understand the full pipeline: professors often question one person about another person's part.
