# Najd — Prévoir les retours et la durée de séjour pour planifier les lits (Diabetes 130-US Hospitals Dataset)

Ce dossier décrit un projet de data mining basé sur le dataset [Diabetes 130-US hospitals for years 1999-2008](https://archive.ics.uci.edu/dataset/296) (`diabetic_data.csv` + `IDS_mapping.csv`).

**Idée en une phrase :** pour chaque patient qui sort, prédire (1) la probabilité qu'il revienne en moins de 30 jours et (2) la durée de son séjour s'il revient, afin de réserver les lits et placer les rendez-vous de suivi sans surcharger la clinique.

## Contenu
1. [Objectif métier](01-objectif-metier.md)
2. [Objectif data](02-objectif-data.md)
3. [Les données](03-donnees.md)
4. [Modèle A : probabilité de retour](04-modele-a-probabilite-retour.md)
5. [Modèle B : durée du séjour de retour](05-modele-b-duree-sejour-retour.md)
6. [Planification des lits et des rendez-vous](06-planification-lits-rendez-vous.md)
7. [Exemples de patients](07-exemples-patients.md)
8. [Évaluation, précautions et limites](08-evaluation-precautions-limites.md)
9. [Étapes du projet et évolutions](09-etapes-et-evolutions.md)

## Limite principale à retenir
Le fichier ne contient **aucune date** : `readmitted` indique seulement `<30`, `>30` ou `NO`. On ne peut donc pas prédire « retour au jour 25 ». Le système prédit un retour probable *dans les 30 jours* et la durée du séjour de retour.
