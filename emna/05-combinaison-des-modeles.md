# 5. Combiner les deux modèles

`insulin_prescrite` est une **feature** dans le modèle 1 et la **target** dans le modèle 2 : on ne peut pas simplement fusionner les deux. Trois options.

## Préparation commune
```python
import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

features = ["age", "A1Cresult", "max_glu_serum", "num_medications",
            "time_in_hospital", "number_diagnoses", "num_lab_procedures",
            "metformin_prescrite"]
X = pd.get_dummies(df[features], columns=["age", "A1Cresult", "max_glu_serum"])
```

## Option 1 : un seul arbre multi-sorties
Un arbre prédit `[change, insulin]` ensemble, avec les mêmes features et sans `insulin_prescrite` en entrée.

```python
y = df[["change", "insulin_prescrite"]]
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2,
                                          random_state=42, stratify=y["change"])
clf = DecisionTreeClassifier(max_depth=6, min_samples_leaf=50, random_state=42)
clf.fit(X_tr, y_tr)
pred = clf.predict(X_te)
for i, col in enumerate(y.columns):
    print(col); print(classification_report(y_te[col], pred[:, i]))
```
- **Avantage :** un seul modèle, un seul pipeline.
- **Limite :** l'arbre est un compromis entre les deux cibles et les règles métier sont moins lisibles.

## Option 2 : deux arbres séparés, mêmes features (recommandée)
Même préparation, un arbre par target. Chaque modèle reste lisible, avec sa propre profondeur et ses propres poids de classe (`insulin` est équilibré, `change` probablement pas).

## Option 3 : enchaînement
1. Prédire l'insuline.
2. Utiliser `insulin_predite` comme feature pour `change`.

Cohérent cliniquement, mais en test il faut utiliser la **prédiction** et non la vraie valeur, sinon les performances sont gonflées.

## Recommandation
Option 2, ou option 1 si un modèle unique est exigé. Dans tous les cas :
1. retirer `insulin_prescrite` des features de `change` (ou passer par l'option 3) ;
2. harmoniser les features (`num_lab_procedures` partout) ;
3. vérifier le déséquilibre de `change` avant de conclure ;
4. limiter la profondeur pour garder des règles explicables.
