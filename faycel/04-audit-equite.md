# 4. Audit d'équité des soins

## Objectif métier
Vérifier si des patients reçoivent un traitement significativement différent (durée d'hospitalisation, nombre de procédures, nombre de médicaments) selon leur race, leur genre ou leur tranche d'âge — à état clinique comparable — afin d'identifier d'éventuelles inégalités de traitement.

## Objectif data
Tests statistiques (ANOVA / Kruskal-Wallis) + régression multivariée de `time_in_hospital` / `num_procedures` sur `race`, `gender`, `age`, en contrôlant par la gravité clinique (`number_diagnoses`, `admission_type_id`, `number_inpatient`, `number_emergency`). Un coefficient significatif après contrôle est un signal de disparité.
