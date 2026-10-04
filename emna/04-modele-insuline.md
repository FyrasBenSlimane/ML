# 4. Modèle 2 : besoin d'insuline

## Objectif métier
Anticiper, à partir du profil clinique, si le patient aura besoin d'un traitement à l'insuline pendant son séjour, pour aider l'équipe à anticiper les ressources et le suivi liés à l'insulinothérapie.

## Target
`insulin` recodée en binaire :
- `No` → 0 : pas d'insuline ;
- `Steady` / `Up` / `Down` → 1 : insuline prescrite, quel que soit l'ajustement de dose.

Classes bien équilibrées (53 % ont besoin d'insuline, 47 % non) : **pas de rééchantillonnage nécessaire**.

## Features retenues
`age`, `A1Cresult`, `max_glu_serum`, `num_medications`, `time_in_hospital`, `number_diagnoses`, `num_lab_procedures`, `metformin_prescrite`.

## Modèle
Classification supervisée avec `DecisionTreeClassifier`.

```python
clf_ins = DecisionTreeClassifier(max_depth=6, min_samples_leaf=50, random_state=42)
clf_ins.fit(X_tr, y_tr["insulin_prescrite"])
```
