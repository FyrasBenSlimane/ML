# 9. Étapes du projet et évolutions

## Étapes
1. Préparer les données : nettoyer, retirer les cas exclus, regrouper les diagnostics, construire les couples « séjour → séjour de retour ».
2. Entraîner et calibrer le modèle A.
3. Entraîner le modèle B avec fourchette.
4. Construire le calcul de charge et la simulation de marge de sécurité.
5. Évaluer au niveau patient, puis sur des groupes de 100 patients.
6. Faire valider les niveaux de risque par l'équipe médicale.

## Évolution : prédire le nombre de jours avant le retour
Avec les dates d'admission, de sortie et de retour d'un hôpital, on pourrait prédire « retour au jour 25 » et placer la charge sur le bon jour du calendrier. Il faudrait calculer `jours avant retour = date du retour − date de sortie`, puis utiliser une analyse de survie (qui gère aussi les patients qui ne reviennent jamais). Seul le modèle A serait remplacé, le reste du système resterait identique.

Lien avec l'idée [12 — Courbe de survie](../faycel/12-courbe-survie.md) : elle suppose un temps jusqu'à l'événement, que `diabetic_data.csv` ne fournit pas (seulement `<30`, `>30`, `NO`). Elle n'est réalisable qu'avec des dates réelles.
