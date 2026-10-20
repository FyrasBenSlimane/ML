# 4. Modèle A : probabilité de retour en moins de 30 jours

## Objectif métier
Savoir, à la sortie, quels patients ont le plus de chances de revenir, pour leur donner un rendez-vous de suivi plus tôt et estimer le nombre de retours attendus.

## Objectif data
Classification binaire sur `readmitted` (`<30` = 1 vs `NO`/`>30` = 0), avec des probabilités **calibrées** : quand le modèle dit 20 %, environ 20 % des patients doivent vraiment revenir. Modèle candidat : gradient boosting (HistGradientBoosting / XGBoost).

## Variables (colonnes du fichier)

| Groupe | Colonnes | Utilité |
|---|---|---|
| Patient | `age` (converti en nombre), `gender`, `race` | Profil général |
| Historique | `number_inpatient`, `number_emergency`, `number_outpatient` | Hospitalisations, urgences, consultations de l'année précédente |
| Admission et sortie | `admission_type_id`, `admission_source_id`, `discharge_disposition_id` | Type d'admission, provenance, destination après la sortie |
| Séjour | `time_in_hospital`, `num_lab_procedures`, `num_procedures`, `num_medications`, `number_diagnoses` | Lourdeur du séjour qui se termine |
| Diagnostics | `diag_1`, `diag_2`, `diag_3` | Regroupés en familles (circulatoire, respiratoire, digestif, diabète, cancer, autre) |
| Diabète et traitement | `A1Cresult`, `max_glu_serum`, `insulin`, `metformin` et autres médicaments, `change`, `diabetesMed` | Équilibre du diabète et traitement. Variables créées : nombre de médicaments prescrits, nombre modifiés |
| Organisation | `medical_specialty`, `payer_code` | Service, assurance |

## Variables non utilisées
- `readmitted` : c'est la cible.
- `encounter_id`, `patient_nbr` : identifiants (`patient_nbr` sert uniquement à séparer entraînement et test).
- `weight` : manquante à 97 %.

## Attention
`race` et `gender` sont des variables sensibles : décider avec l'équipe médicale si on les garde (voir aussi `../faycel/04-audit-equite.md`).

## Niveaux de risque (indicatifs)

| Niveau | Risque | Action |
|---|---|---|
| Faible | moins de 14 % | Rendez-vous standard |
| Moyen | 14 à 21 % | Rendez-vous à 2 semaines |
| Élevé | plus de 21 % | Rendez-vous dans la semaine et appel de contrôle |

Seuils issus d'un premier essai rapide (70e et 90e percentiles) ; à ajuster selon la capacité de suivi de la clinique.
