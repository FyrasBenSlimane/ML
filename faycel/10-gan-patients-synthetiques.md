# 10. Générateur de patients synthétiques (GAN médical)

## Objectif métier
Créer de faux patients statistiquement réalistes pour renforcer les classes rares (ex. réadmissions précoces peu fréquentes) sans violer la confidentialité des vrais patients.

## Objectif data
GAN tabulaire (CTGAN) entraîné sur `diabetic_data.csv` pour générer des données augmentées, puis mesure du gain de performance du modèle de classification entraîné avec ces données enrichies.
