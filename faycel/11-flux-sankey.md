# 11. Radiographie du parcours hospitalier (flux Sankey)

## Objectif métier
Visualiser le "voyage" complet des patients entre source d'admission, hôpital et mode de sortie, pour repérer les goulots d'étranglement du système de santé.

## Objectif data
Diagramme de flux (Sankey) construit sur `admission_source_id` → `admission_type_id` → `discharge_disposition_id`, pondéré par le taux de réadmission de chaque chemin.
