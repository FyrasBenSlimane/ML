# MedCare — Structure MVC (PHP pur)

Squelette MVC sans framework.

## Arborescence

```
Projet ML/
├── app/
│   ├── Config/
│   │   └── config.php          # Config globale (chemins, BDD, routes par défaut)
│   ├── Controllers/
│   │   └── HomeController.php   # Contrôleur d'exemple
│   ├── Core/
│   │   ├── App.php             # Routeur (URL -> contrôleur/action)
│   │   ├── Controller.php      # Contrôleur de base (model(), view())
│   │   └── Database.php        # Connexion PDO + requêtes préparées
│   ├── Models/
│   │   └── Model.php           # Modèle de base
│   └── Views/
│       ├── layouts/
│       │   └── main.php        # Gabarit HTML (head, assets, contenu)
│       └── home/
│           └── index.php       # Vue de la page d'accueil
├── public/                     # Racine web (document root)
│   ├── assets/
│   │   ├── css/style.css
│   │   ├── js/app.js
│   │   └── img/
│   ├── .htaccess               # Réécriture vers index.php
│   └── index.php               # Front controller (point d'entrée)
├── .htaccess                   # Redirige la racine vers public/
└── README.md
```

## Fonctionnement

- Toute requête arrive sur `public/index.php`.
- `App.php` lit l'URL `/{controleur}/{action}/{params...}` et appelle la méthode.
- Un contrôleur étend `Controller` et rend une vue : `$this->view('home/index', $data)`.
- Les vues sont injectées dans `app/Views/layouts/main.php`.

## Lancer en local

```bash
# Depuis la racine du projet — passer public/index.php comme routeur
php -S localhost:8000 -t public public/index.php
```

Puis ouvrir http://localhost:8000

> Le serveur intégré PHP ignore le `.htaccess` : il faut donc indiquer
> `public/index.php` comme routeur. Sous Apache (XAMPP/WAMP), le `.htaccess`
> fourni gère la réécriture automatiquement, pas besoin de cet argument.

## Assets / images

Images attendues dans `public/assets/img/` :

- `doctor.png`   : personnage 3D de l'accueil (+ 6ᵉ carte de la liste)
- `doctor2.jpg` … `doctor6.jpg` : avatars « Trusted by » (accueil) et cartes médecins (liste)

Sans ces fichiers, les illustrations ne s'affichent pas.

## Routes

| URL         | Contrôleur              | Écran         |
|-------------|-------------------------|---------------|
| `/`         | `HomeController@index`    | Accueil       |
| `/doctors`  | `DoctorsController@index` | Find Doctors  |

## Ajouter une page

1. Créer `app/Controllers/XxxController.php` (classe qui étend `Controller`).
2. Créer la vue `app/Views/xxx/index.php`.
3. Accéder via `/xxx` ou `/xxx/action`.
