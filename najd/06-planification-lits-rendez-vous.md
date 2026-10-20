# 6. Planification des lits et des rendez-vous

## Objectif métier
Transformer les prédictions individuelles en décisions : combien de lits garder, quels patients suivre en priorité.

## Objectif data
Un calcul (pas un modèle) qui combine le modèle A et le modèle B, puis une simulation pour choisir la marge de sécurité.

## Charge attendue par patient

```
Charge attendue = probabilité de retour × durée prévue du séjour de retour
```

On additionne la charge de tous les patients sortis pour obtenir les jours-lits à prévoir.

## Exemple pour un mois (illustratif)
- 200 patients sortent.
- Risque moyen de retour d'environ 11 % : environ 22 retours attendus.
- 5 jours par séjour : environ 110 jours-lits, répartis sur 30 jours.
- **Environ 3,7 lits occupés en moyenne chaque jour.**
- Marge de sécurité (par exemple 2 lits de plus) : 6 lits à garder.

La taille de la marge se calcule par simulation, pour couvrir par exemple 90 % des cas.

## Hypothèse importante
Le jour exact du retour est inconnu. La charge est donc répartie sur les 30 jours suivant la sortie. C'est une hypothèse du système, pas un résultat du modèle.

## Rendez-vous de suivi
Priorité aux patients à risque élevé, par exemple les 10 à 20 % les plus à risque, selon la capacité de la clinique. Voir les niveaux de risque dans [04](04-modele-a-probabilite-retour.md).

## Bonne façon de l'utiliser
Réserver une **capacité globale** (« cette semaine, prévoir X lits pour les retours probables ») plutôt qu'une chambre pour un patient précis à une date précise : les prévisions sont fiables sur un groupe, fragiles sur un individu.
