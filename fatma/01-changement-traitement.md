# 1. Changement de traitement

## Objectif métier
Anticiper, à partir du profil clinique du patient, si son traitement antidiabétique va être modifié pendant son séjour hospitalier, afin de préparer le patient (et l'équipe soignante) à ce changement plutôt que de le lui annoncer sans explication.

## Objectif data
Classification binaire supervisée, réalisée avec un arbre de décision (`DecisionTreeClassifier`).

## Features
| Feature | Description |
|---|---|
| `age` | Tranches, ex : `[70-80)` |
| `A1Cresult` | `None` / `Norm` / `>7` / `>8` |
| `max_glu_serum` | `None` / `Norm` / `>200` / `>300` |
| `num_medications` | Nombre de médicaments |
| `time_in_hospital` | Jours d'hospitalisation |
| `number_diagnoses` | Nombre de diagnostics |
| `insulin_prescrite` | Recodée en binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 |
| `metformin_prescrite` | Recodée en binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 |

## Target
`change` recodée en binaire :
- `Ch` → 1 : le traitement a changé ;
- `No` → 0 : pas de changement.

> Voir [06](06-points-de-vigilance.md) : `insulin_prescrite` en feature présente un risque de fuite de données.
