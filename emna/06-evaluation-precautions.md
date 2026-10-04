# 6. Évaluation, précautions et limites

## Évaluation
- Séparation train/test stratifiée (`stratify` sur la target), `random_state` fixé.
- Validation croisée pour choisir `max_depth` et `min_samples_leaf`.
- Métriques : **rappel**, F1, précision, matrice de confusion, ROC-AUC.
- Pour `change` : comparer à un modèle de référence (toujours la classe majoritaire) avant de conclure.

## Fuite de données (data leakage)
- `insulin_prescrite` comme feature de `change` : corrélation forte, information connue seulement après la décision thérapeutique.
- Option 3 : toujours utiliser la prédiction en test, jamais la vraie valeur.

## Autres précautions
- Plusieurs séjours par patient (`patient_nbr`) : séparer train/test **par patient** pour éviter qu'un même patient soit dans les deux jeux.
- Valeurs manquantes : `A1Cresult` et `max_glu_serum` ont une modalité `None` (test non réalisé), à garder comme catégorie à part, pas comme une valeur manquante à imputer.
- Un arbre trop profond sur-apprend et devient illisible : profondeur limitée.

## Limites
- Les arbres de décision sont instables : de petits changements dans les données peuvent changer la structure.
- Le dataset ne contient pas la glycémie en continu ni l'historique complet du patient.
- L'outil est une aide à l'anticipation, pas une aide à la prescription : la décision reste clinique.
