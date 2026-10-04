# 2. Besoin d'insuline

## Objectif métier
Anticiper, à partir du profil clinique du patient, s'il aura besoin d'un traitement à l'insuline pendant son séjour, afin d'aider l'équipe soignante à anticiper les ressources et le suivi liés à l'insulinothérapie.

## Objectif data
Classification supervisée avec un arbre de décision (`DecisionTreeClassifier`).

## Features retenues
`age`, `A1Cresult`, `max_glu_serum`, `num_medications`, `time_in_hospital`, `number_diagnoses`, `num_lab_procedures`, `metformin_prescrite`.

## Target
`insulin` recodée en binaire :
- `No` → 0 : pas d'insuline ;
- `Steady` / `Up` / `Down` → 1 : insuline prescrite, peu importe l'ajustement de dose.

Classes bien équilibrées : **53 %** ont besoin d'insuline, **47 %** non. Pas de rééchantillonnage nécessaire.
