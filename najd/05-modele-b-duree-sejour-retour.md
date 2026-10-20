# 5. Modèle B : durée du séjour de retour

## Objectif métier
Savoir combien de jours un patient occupera un lit **s'il revient**, pour réserver la bonne capacité.

## Objectif data
Régression sur la durée du **séjour suivant** du même patient (`time_in_hospital` du séjour N+1), avec une **fourchette** (par exemple 10e à 90e percentile) plutôt qu'un seul chiffre, car l'incertitude est grande (écart-type de 3,2 jours).

## Données d'entraînement
- Départ : les 8 133 couples « séjour précédent → séjour de retour » des patients `<30`.
- Si ce n'est pas assez : ajouter les réadmissions `>30` (29 758 couples au total) avec un indicateur pour les distinguer.

## Variables
Les mêmes que le modèle A, mais **uniquement celles du séjour précédent**. Aucune information du séjour de retour n'est utilisée (sinon le modèle « triche »).

## Référence à battre
Une règle simple : « toujours 4 jours » (valeur médiane des séjours de retour). Le modèle doit faire mieux, sinon on le dit.

## Attendu
La durée du premier séjour explique peu la durée du retour (corrélation de 0,21) : on s'attend à un gain modeste. Ce modèle n'a pas encore été mesuré.
