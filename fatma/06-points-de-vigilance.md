# 6. Points de vigilance

Remarques à prendre en compte avant l'entraînement des modèles.

## Changement de traitement
- `insulin_prescrite` en feature : `change` indique qu'au moins un médicament a été modifié, et l'insuline est le principal médicament concerné. Risque de **fuite de données**, et information connue seulement une fois le traitement décidé. À retirer, ou à tester avec et sans pour mesurer l'écart.

## Suivi
- `number_outpatient` et `number_emergency` comptent les visites de l'**année précédant** le séjour, pas celles qui suivent la sortie. La target mesure donc l'historique de recours aux soins ; la formulation « rythme de suivi à prévoir dans l'année » est à nuancer.
- Classes déséquilibrées (76/24) : regarder rappel, F1 et matrice de confusion, pas seulement l'accuracy.

## Compagnon du Quotidien
- Seuls 17 018 séjours sur 101 766 ont un `A1Cresult` : les patients testés ne sont pas un échantillon représentatif (le test est surtout fait quand le médecin soupçonne un déséquilibre). Le modèle ne vaut que pour cette population.
- Le regroupement `Norm` + `>7` contre `>8` doit être justifié cliniquement (seuils de contrôle glycémique).

## Rappel Utile
- La target est un **proxy** (âge ≥ 70 et ≥ 15 médicaments), pas une mesure réelle de l'oubli de traitement. Le modèle apprend cette règle, pas le comportement des patients.
- `age` et `num_medications` ne sont pas dans les features, ce qui évite la fuite directe. Mais des variables corrélées (`number_diagnoses`, `time_in_hospital`) permettent de la retrouver indirectement.
- Aucune validation possible sans donnée réelle d'observance : à présenter comme une aide à la priorisation, pas comme une mesure du risque.

## Général
- Plusieurs séjours par patient (`patient_nbr`) : séparer train et test **par patient**.
- Arbres à profondeur limitée (`max_depth`, `min_samples_leaf`) pour garder des règles explicables.
- Ces outils sont une aide à l'anticipation et à l'accompagnement, pas une aide à la prescription.
