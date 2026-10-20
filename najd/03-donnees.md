# 3. Les données

## Chiffres clés (`diabetic_data.csv`)

| Élément | Valeur |
|---|---|
| Séjours (lignes) | 101 766 |
| Patients différents | 71 518 (16 773 ont plusieurs séjours) |
| Colonnes | 50 |
| Retour en moins de 30 jours (`<30`) | 11 357 séjours (environ 11 %) |
| Retour après plus de 30 jours (`>30`) | 35 545 séjours (environ 35 %) |
| Pas de retour (`NO`) | 54 864 séjours (environ 54 %) |
| Durée d'un séjour | de 1 à 14 jours, 4,4 jours en moyenne |
| Séjours de retour retrouvables pour les `<30` | 8 133 sur 11 357 (72 %) |

`IDS_mapping.csv` sert à traduire `admission_type_id`, `discharge_disposition_id` et `admission_source_id`.

## Comment obtenir la durée du séjour de retour
Le fichier n'a pas de colonne « durée du retour », mais il contient plusieurs séjours par patient. Pour un séjour marqué `<30`, on retrouve le séjour suivant du même patient (tri par `patient_nbr` puis `encounter_id`) et on lit sa durée dans `time_in_hospital`.

| Séjour | Patient | Durée | readmitted | Cible du modèle B |
|---|---|---|---|---|
| 1er séjour | 1042 | 3 jours | `<30` | **6 jours** (durée du 2e séjour) |
| 2e séjour | 1042 | 6 jours | `NO` | non utilisé |

*(exemple illustratif)*

Vérifications faites : `encounter_id` est croissant pour tous les patients (l'ordre est cohérent). La durée du séjour de retour vaut 5 jours en moyenne, avec une forte variation (écart-type de 3,2 jours). La durée du premier séjour explique peu celle du retour (corrélation de 0,21).

## Valeurs manquantes
`weight` (97 %), `max_glu_serum` (95 %), `A1Cresult` (83 %), `medical_specialty` (49 %), `payer_code` (40 %), `race` (2 %). Pour les analyses de sang, « non mesuré » est une information : on le garde comme catégorie.

## Lignes à retirer
- Patients décédés ou en soins palliatifs (`discharge_disposition_id` 11, 13, 14, 19, 20, 21) : ils ne peuvent pas être réadmis.
- 490 séjours marqués `NO` qui ont pourtant un séjour suivant (incohérents).
