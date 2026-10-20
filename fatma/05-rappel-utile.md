# 5. Le Rappel Utile

## Objectif métier
Identifier les patients les plus exposés au risque d'oublier leur traitement une fois sortis de l'hôpital, afin de leur proposer en priorité des rappels (notifications, alertes) plutôt que de les envoyer à tout le monde de façon générique.

## Objectif data
Classification binaire supervisée, réalisée avec un arbre de décision (`DecisionTreeClassifier`).

## Features
| Feature | Description |
|---|---|
| `time_in_hospital` | Jours d'hospitalisation |
| `number_diagnoses` | Nombre de diagnostics |
| `number_inpatient` | Hospitalisations dans les 12 derniers mois |
| `A1Cresult` | `None` / `Norm` / `>7` / `>8` |
| `max_glu_serum` | `None` / `Norm` / `>200` / `>300` |
| `insulin_prescrite` | Recodée en binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 |
| `diag_1` | Regroupé en catégories cliniques |

## Target
`risque_oubli` : variable **construite** (proxy, absente du dataset d'origine) :
- 1 → patient à risque : `age` ≥ 70 ans **et** `num_medications` ≥ 15 ;
- 0 → patient à faible risque.

> Voir [06](06-points-de-vigilance.md) : la target est une règle, pas une mesure réelle de l'oubli.
