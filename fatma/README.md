# Fatma : accompagnement du patient diabétique

Dataset : *Diabetes 130-US hospitals* (`diabetic_data.csv`, 101 766 séjours).

Cinq projets, tous en **classification binaire supervisée** avec un arbre de décision (`DecisionTreeClassifier`).

| Fichier | Projet | Question posée | Target |
|---|---|---|---|
| [01-changement-traitement.md](01-changement-traitement.md) | Changement de traitement | Le traitement va-t-il être modifié ? | `change` |
| [02-besoin-insuline.md](02-besoin-insuline.md) | Besoin d'insuline | Le patient aura-t-il besoin d'insuline ? | `insulin` |
| [03-suivi.md](03-suivi.md) | Suivi | Quel rythme de suivi prévoir dans l'année ? | `suivi_score` |
| [04-compagnon-du-quotidien.md](04-compagnon-du-quotidien.md) | Le Compagnon du Quotidien | Le patient a-t-il besoin d'un accompagnement pédagogique ? | `A1Cresult` |
| [05-rappel-utile.md](05-rappel-utile.md) | Le Rappel Utile | Le patient risque-t-il d'oublier son traitement ? | `risque_oubli` |
| [06-points-de-vigilance.md](06-points-de-vigilance.md) | Points de vigilance | Fuite de données, proxys, limites | |
