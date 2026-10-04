# 6. Simulateur "Et si ?"

## Objectif métier
Fournir aux médecins un outil interactif qui, à partir du profil d'un patient, estime en temps réel sa probabilité de réadmission et explique quels facteurs pèsent le plus, pour agir avant la sortie.

## Objectif data
Classification (XGBoost) sur `readmitted` recodée en binaire, avec interprétabilité locale via SHAP (quelle variable fait monter/baisser le risque pour CE patient), intégrée dans une interface web interactive mise à jour en temps réel.
