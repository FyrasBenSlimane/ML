# 3. Modèle 1 : le traitement va-t-il changer ?

## Target
`change` recodée en binaire : `Ch` → 1 (le traitement a changé), `No` → 0.

## Features

| Feature | Type | Encodage |
|---|---|---|
| `age` | Tranches (ex : `[70-80)`) | One-hot, ou ordinal (tranche → milieu) |
| `A1Cresult` | `None` / `Norm` / `>7` / `>8` | One-hot |
| `max_glu_serum` | `None` / `Norm` / `>200` / `>300` | One-hot |
| `num_medications` | Numérique | Aucun |
| `time_in_hospital` | Numérique (jours) | Aucun |
| `number_diagnoses` | Numérique | Aucun |
| `num_lab_procedures` | Numérique | Aucun |
| `metformin_prescrite` | Binaire : `No` → 0, `Steady`/`Up`/`Down` → 1 | Recodage |

## Version initiale à corriger
La première version contenait `insulin_prescrite` (binaire) comme feature. Elle est **retirée** :

- `change` signale qu'au moins un médicament a été modifié, et l'insuline est le principal médicament concerné : forte corrélation, donc fuite de données ;
- l'insuline n'est connue qu'une fois le traitement décidé, pas au moment où l'on veut anticiper.

Alternative : l'utiliser sous forme **prédite** (voir [05](05-combinaison-des-modeles.md), option 3).

## Paramétrage conseillé
`DecisionTreeClassifier(max_depth=6, min_samples_leaf=50, class_weight="balanced", random_state=42)`, à ajuster par validation croisée.
