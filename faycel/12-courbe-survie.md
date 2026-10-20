# 12. Courbe de survie du risque

## Objectif métier
Remplacer la question "va-t-il être réadmis ?" par "dans combien de temps risque-t-il d'être réadmis ?" — beaucoup plus utile cliniquement pour prioriser le suivi.

## Objectif data
Analyse de survie (modèle de Cox à risques proportionnels) avec `readmitted` recodée en temps-jusqu'à-événement, produisant une courbe de probabilité dans le temps par patient.
