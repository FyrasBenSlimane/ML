# 3. Suivi

## Objectif métier
Donner au patient, dès sa sortie, une idée réaliste du rythme de suivi médical à prévoir dans l'année, afin qu'il puisse s'organiser : ne pas être surpris par la fréquence des rendez-vous, ni relâcher sa vigilance s'il en a réellement besoin.

## Objectif data
Classification binaire supervisée, réalisée avec un arbre de décision (`DecisionTreeClassifier`).

## Features
| Feature | Description |
|---|---|
| `age` | Tranches, ex : `[70-80)` |
| `time_in_hospital` | Jours d'hospitalisation |
| `num_medications` | Nombre de médicaments |
| `number_diagnoses` | Nombre de diagnostics |
| `diag_1` | Regroupé en catégories cliniques |
| `diabetesMed` | `Yes` / `No` |
| `insulin_prescrite` | Recodée en binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 |
| `A1Cresult` | `None` / `Norm` / `>7` / `>8` |
| `max_glu_serum` | `None` / `Norm` / `>200` / `>300` |

## Target
`suivi_score` (= `number_outpatient` + `number_emergency`) recodée en binaire :

| Valeur | Signification | Part |
|---|---|---|
| 0 | Suivi léger : aucune visite ambulatoire ni urgence dans l'année | 76,2 % |
| 1 | Suivi renforcé nécessaire : au moins une visite | 23,8 % |

Classes déséquilibrées (76/24) : prévoir `class_weight="balanced"` et suivre le rappel de la classe 1.
