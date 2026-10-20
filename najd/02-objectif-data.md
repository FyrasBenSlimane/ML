# 2. Objectif data

## Objectif data fixé
À partir des informations d'un séjour terminé, prédire :
1. la **probabilité** que le patient revienne en moins de 30 jours ;
2. la **durée en jours** de son séjour de retour, avec une fourchette.

## Deux modèles et un calcul

| | Modèle A : retour | Modèle B : durée du retour |
|---|---|---|
| Question | Ce patient va-t-il revenir en moins de 30 jours ? | S'il revient, combien de jours restera-t-il ? |
| Réponse | Une probabilité (ex : 28 %) | Un nombre de jours et une fourchette (ex : 5 jours, entre 3 et 8) |
| Type | Classification (probabilité calibrée) | Régression (avec fourchette) |
| Cible | `readmitted` : `<30` = 1, sinon 0 | `time_in_hospital` du séjour suivant du même patient |

Le **calcul de planification** (voir [06](06-planification-lits-rendez-vous.md)) combine les deux réponses. Ce n'est pas un modèle, juste une multiplication et une addition.

## Ce que le dataset ne permet pas
Prédire le nombre de jours avant le retour (« retour au jour 25 ») : le fichier n'a ni date d'admission, ni date de sortie, ni date de retour.
