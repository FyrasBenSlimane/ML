# 2. Détecteur de polypharmacie excessive

## Objectif métier
Repérer les profils de patients auxquels on prescrit un très grand nombre de médicaments sans amélioration clinique réelle — un vrai sujet de santé publique (risque d'interactions médicamenteuses).

## Objectif data
Créer un score de "charge médicamenteuse" à partir des 23 colonnes de médicaments et de `num_medications`, puis clustering (K-Means) pour isoler le segment "sur-traité mais toujours réadmis" vs "sous-traité".
