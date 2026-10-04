# 8. Évaluation, précautions et limites

## Comment mesurer la réussite
- **Modèle A** : AUC, lift sur les 10 % les plus à risque, calibration des probabilités.
- **Modèle B** : erreur moyenne en jours (MAE), comparée à la règle simple « toujours 4 jours ».
- **Planification** : le test le plus important. Sur des groupes de 100 patients mis de côté, comparer les jours-lits prévus aux jours-lits réels. Les erreurs individuelles se compensent en partie dans un groupe : c'est ce chiffre qui dit si la clinique peut s'y fier.

## Ordres de grandeur d'un premier essai rapide (à confirmer)
- Modèle A : AUC d'environ 0,67. Parmi les 10 % de patients classés les plus à risque, environ 26 % sont revenus, contre 11 % en moyenne.
- Modèle B : pas encore mesuré.

## Précautions
- **Séparer par patient** (GroupShuffleSplit sur `patient_nbr`) : un patient ne doit jamais être à la fois dans l'entraînement et dans le test.
- **Retirer** les décès, les soins palliatifs et les 490 lignes incohérentes.
- **Aucune information du futur** dans les variables (surtout pour le modèle B).
- **Comparer à une référence simple** avant de conclure qu'un modèle apporte quelque chose.

## Limites
- Pas de date exacte de retour dans le fichier.
- Données américaines et anciennes (1999 à 2008) : à réentraîner sur les données d'un hôpital réel avant tout usage.
- Aide à la décision, pas réservation exacte d'une chambre : la décision reste celle de l'équipe médicale.
