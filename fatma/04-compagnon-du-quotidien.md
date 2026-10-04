# 4. Le Compagnon du Quotidien

## Objectif métier
Orienter le patient vers un accompagnement pédagogique (alimentation, activité physique) uniquement s'il en a réellement besoin, plutôt que d'appliquer les mêmes conseils génériques à tout le monde.

## Objectif data
Classification binaire supervisée, réalisée avec un arbre de décision (`DecisionTreeClassifier`).

## Features
| Feature | Description |
|---|---|
| `age` | Tranches, ex : `[70-80)` |
| `num_medications` | Nombre de médicaments |
| `insulin_prescrite` | Recodée en binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 |
| `metformin_prescrite` | Recodée en binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 |
| `number_diagnoses` | Nombre de diagnostics |
| `time_in_hospital` | Jours d'hospitalisation |
| `diag_1` | Regroupé en catégories cliniques |

## Target
`A1Cresult` recodée en binaire, **uniquement sur les patients ayant réalisé le test** (17 018 lignes sur 101 766) :

| Valeur | Signification | Part |
|---|---|---|
| 0 | Bien contrôlé (`Norm` ou `>7`) | 51,7 % |
| 1 | Mal contrôlé (`>8`) | 48,3 % |

Classes équilibrées : pas de rééchantillonnage nécessaire.
