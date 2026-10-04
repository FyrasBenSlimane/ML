# 1. Prédiction de réadmission

## Objectif métier
Anticiper, avant la sortie du patient, lesquels risquent de revenir à l'hôpital dans les 30 jours, afin d'agir en amont (suivi renforcé, appel à domicile, ajustement du traitement).

## Objectif data
Classification binaire sur la variable `readmitted` (recodée en `<30` = 1 vs `NO`/`>30` = 0), à partir de `time_in_hospital`, `num_medications`, `number_inpatient`, `diag_1/2/3`, `A1Cresult`. Modèles candidats : Random Forest / XGBoost. Métrique prioritaire : recall (ne pas rater un patient à risque).
