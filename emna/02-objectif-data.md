# 2. Objectif data

## Objectif data fixé
Deux **classifications binaires supervisées**, réalisées avec un arbre de décision (`DecisionTreeClassifier`) :

| | Modèle 1 : changement | Modèle 2 : insuline |
|---|---|---|
| Question | Le traitement va-t-il être modifié ? | Le patient aura-t-il besoin d'insuline ? |
| Target | `change` : `Ch` → 1, `No` → 0 | `insulin` : `No` → 0, `Steady`/`Up`/`Down` → 1 |
| Équilibre des classes | À vérifier (probablement déséquilibré) | Équilibré : 53 % oui, 47 % non |
| Rééchantillonnage | À évaluer (`class_weight="balanced"`) | Pas nécessaire |

## Features communes
`age`, `A1Cresult`, `max_glu_serum`, `num_medications`, `time_in_hospital`, `number_diagnoses`, `num_lab_procedures`, `metformin_prescrite`.

## Point d'attention
`insulin_prescrite` ne doit **pas** être une feature du modèle 1 : c'est la target du modèle 2 et elle fuit l'information de `change` (voir [03](03-modele-change.md) et [06](06-evaluation-precautions.md)).

## Métriques
Rappel, F1, précision, matrice de confusion, ROC-AUC. L'accuracy seule ne suffit pas, surtout pour `change`.
