# MAAK — Guide de migration & de passation (handoff)

> **Écrit pour :** un·e coéquipier·ère qui reprend ce projet sur **un autre poste de travail**
> (Windows + éditeur, session de dev séparée). Objectif : pouvoir **reproduire l'environnement,
> comprendre l'architecture, respecter la charte et la logique**, et **continuer le travail**
> sans rien casser ni rien oublier.
>
> Ce document couvre : le produit, la stack, la migration pas-à-pas, l'arborescence complète
> (filemap), le schéma de base de données, la charte graphique, les flux fonctionnels, les
> **phases de travail** réalisées, la **façon de penser** (mindset), les optimisations, les
> tests, et les **pièges connus**. Chaque partie contient des **exemples concrets**.

---

## Sommaire

0. [Objectif & périmètre](#0-objectif--périmètre)
1. [Vue d'ensemble du produit MAAK](#1-vue-densemble-du-produit-maak)
2. [Stack technique & prérequis](#2-stack-technique--prérequis)
3. [Migration pas-à-pas vers un nouveau poste](#3-migration-pas-à-pas-vers-un-nouveau-poste)
4. [Démarrer les 3 services](#4-démarrer-les-3-services)
5. [Arborescence du projet (filemap)](#5-arborescence-du-projet-filemap)
6. [Le routeur & les conventions de routes](#6-le-routeur--les-conventions-de-routes)
7. [Rôles, sessions, CSRF & protection du patient](#7-rôles-sessions-csrf--protection-du-patient)
8. [Schéma de base de données](#8-schéma-de-base-de-données)
9. [Charte graphique (couleurs, police, composants)](#9-charte-graphique-couleurs-police-composants)
10. [Flux fonctionnels détaillés](#10-flux-fonctionnels-détaillés)
11. [Les phases de travail réalisées (roadmap)](#11-les-phases-de-travail-réalisées-roadmap)
12. [Façon de penser / mindset de travail](#12-façon-de-penser--mindset-de-travail)
13. [Optimisations](#13-optimisations)
14. [Tests & vérification](#14-tests--vérification)
15. [Pièges connus (gotchas)](#15-pièges-connus-gotchas)
16. [Exemple de bout en bout (walkthrough)](#16-exemple-de-bout-en-bout-walkthrough)
17. [Checklist finale de migration](#17-checklist-finale-de-migration)
18. [Backlog & améliorations possibles](#18-backlog--améliorations-possibles)
19. [Annexes](#19-annexes)

---

## 0. Objectif & périmètre

MAAK est une application web de **santé / aide à la décision clinique** autour du diabète.
Elle réunit :

- un **site PHP** (MVC maison) pour les patients et le personnel soignant ;
- une **API Python (FastAPI)** qui héberge les modèles de Machine Learning ;
- une **application externe ReadmitGuard** (Streamlit) pour le risque de réadmission.

La **règle d'or** du produit (à ne jamais casser) :

> **Le patient ne voit JAMAIS le résultat brut d'un modèle.**
> Les modèles Doza/Sora sont exécutés **uniquement par le médecin** (rôle `personnel`).
> Le médecin envoie ensuite au patient une **alerte** (message rassurant, sans chiffre).

Si une modification met en danger cette règle, **c'est un bug**, même si le code « marche ».

---

## 1. Vue d'ensemble du produit MAAK

### 1.1 Les acteurs (rôles)

| Rôle (`users.role`) | Appelé | Portail d'accueil | Peut faire |
|---|---|---|---|
| `patient` | Patient | `/doctors` (Find Doctors) | Voir les fiches Doza/Sora (but + ses alertes), lire ses alertes |
| `personnel` | Médecin | `/personnel` (Accueil médecin) | Sélectionner un patient, lancer Doza/Sora, envoyer des alertes, ReadmitGuard |

> ⚠️ Dans tout le code, **« médecin » = rôle `personnel`**. Il n'y a pas d'autre rôle.

### 1.2 Les trois « modèles » / outils

1. **Doza** — détection du changement de dose d'insuline (classification, proba + zone de risque).
   Avatar = `doctor5.jpg` (« Dr. Amina »), aussi utilisé comme **logo de l'app**.
2. **Sora** — profil de sortie : deux modèles (M1 *Suivi*, M2 *Contrôle*) → recommandation.
   Avatar = `doctor6.jpg`.
3. **ReadmitGuard** — risque de réadmission à 30 jours (app Streamlit externe, SSO par jeton HMAC).

### 1.3 Le cœur du flux (à mémoriser)

```
Médecin se connecte
   └─> Accueil médecin (/personnel)
        └─> « Lancer une évaluation » / « Évaluer »
             └─> Sélection du patient par ID Patient #PT-xxxxx  (/patient/select)
                  └─> patient mémorisé en session (eval_patient)
                       ├─> Doza (/doza -> /doza/resultat)   ──┐
                       └─> Sora (/sora -> /sora/profil)      ──┤
                                                               └─> « Envoyer une alerte » (/notifications/send)
                                                                    └─> le PATIENT reçoit l'alerte (cloche + /notifications)
```

---

## 2. Stack technique & prérequis

| Composant | Version utilisée | Rôle |
|---|---|---|
| PHP | **8.0.30** (min 7.4 ok) | Site MVC |
| MySQL / MariaDB | via **XAMPP** | Base `medcare` (utf8mb4) |
| Python | **3.14.3** (3.10+ ok) | API FastAPI (modèles ML) |
| FastAPI + Uvicorn + scikit-learn + joblib | voir `api/requirements.txt` | API `/predict`, `/sora`, `/accompagnement` |
| Streamlit (ReadmitGuard) | séparé | app externe (optionnelle en dev) |
| Tailwind CSS | **CDN v3** (`cdn.tailwindcss.com`) | styles (pas de build) |
| Police | **Plus Jakarta Sans** (Google Fonts) | typographie |

> En dev on peut **tout lancer sans Apache** : serveur intégré PHP (`php -S`) + `uvicorn`.
> En « prod locale » XAMPP : Apache sert `public/`, MySQL tourne, l'API Python tourne à part.

---

## 3. Migration pas-à-pas vers un nouveau poste

### Étape 1 — Récupérer le code

```bash
# Option A : via Git (recommandé)
git clone <URL_DU_DEPOT> "Projet ML"
cd "Projet ML"
git checkout feature/portail-medecin      # branche de travail courante

# Option B : copier le dossier (clé USB / zip) — NE PAS copier :
#   - app/Config/config.local.php  (secrets, à recréer)
#   - api/__pycache__/             (régénéré)
#   - .venv-api/ ou venv Python    (recréer localement)
```

### Étape 2 — Installer les outils

- **XAMPP** (Apache + MySQL) OU au minimum **PHP 8.x** dans le PATH.
- **Python 3.10+** dans le PATH (`python --version`).

### Étape 3 — Base de données

```bash
# Démarrer MySQL (panneau XAMPP) puis importer le schéma :
#   - via phpMyAdmin : importer database/medcare.sql
#   - ou en ligne de commande :
mysql -u root < database/medcare.sql
```

> `database/medcare.sql` est **idempotent** : il crée la base `medcare`, les 4 tables et
> applique les migrations (`personnel_id`, table `notifications`) **sans erreur** s'il est
> relancé. Les modèles PHP recréent aussi les tables manquantes au premier usage (voir §13).

### Étape 4 — Secrets (fichier NON versionné)

Créer `app/Config/config.local.php` à partir de l'exemple :

```bash
cp app/Config/config.local.example.php app/Config/config.local.php
```

Puis éditer les valeurs (voir [Annexe B](#annexe-b--configlocalphp)) :

```php
<?php
// app/Config/config.local.php  (ignoré par Git)
define('READMITGUARD_SECRET', 'un-secret-aleatoire-long');   // HMAC du jeton SSO
define('PERSONNEL_ACCESS_CODE', 'VOTRE-CODE-ETABLISSEMENT');  // exigé à l'inscription personnel
define('READMITGUARD_URL', 'http://localhost:8501');          // app Streamlit
```

> Sans `config.local.php`, le code **fonctionne quand même** avec des valeurs de DEV
> (voir fin de `app/Config/config.php`). Mais **ne jamais** committer de secrets réels.

### Étape 5 — Dépendances Python (API)

```bash
# (optionnel mais propre) créer un venv
python -m venv .venv-api
# Windows :
.venv-api\Scripts\activate
pip install -r api/requirements.txt
```

### Étape 6 — Vérifier la config PHP de la base

`app/Config/config.php` définit la connexion. Par défaut :

```php
define('DB_HOST', '127.0.0.1');   // 127.0.0.1 (pas "localhost") -> évite l'ambiguïté socket/IPv6 sous Windows
define('DB_NAME', 'medcare');
define('DB_USER', 'root');
define('DB_PASS', '');            // XAMPP par défaut : pas de mot de passe root
```

> Si MySQL a un mot de passe root sur le nouveau poste, l'ajuster **dans `config.local.php`**
> (redéfinir `DB_PASS`) plutôt que dans `config.php` versionné.

---

## 4. Démarrer les 3 services

```bash
# 1) Site PHP (depuis la racine du projet)
php -S 127.0.0.1:8000 -t public
#    -> http://127.0.0.1:8000/

# 2) API Python Doza/Sora (depuis la racine)
python -m uvicorn main:app --app-dir api --port 8001
#    -> http://127.0.0.1:8001/health  (doit renvoyer {"ok":true,...})

# 3) (optionnel) ReadmitGuard (Streamlit) sur le port 8501
```

Raccourci : **`start_all.bat`** à la racine lance tout d'un coup.

> **Sans l'API (port 8001), Doza et Sora affichent « service de prédiction indisponible ».**
> Ce n'est pas un bug du site : il faut lancer `uvicorn`. Vérifier d'abord `/health`.

---

## 5. Arborescence du projet (filemap)

```
Projet ML/
├─ public/                         ← racine web (docroot)
│  ├─ index.php                    ← Front Controller (point d'entrée unique)
│  ├─ .htaccess                    ← réécriture Apache -> index.php?url=...
│  └─ assets/
│     ├─ css/style.css             ← styles custom (screen-ambient, voice-ambient, glass, podium…)
│     ├─ js/app.js                 ← JS global (léger)
│     ├─ js/model.js               ← appel API Doza (/predict) côté navigateur
│     └─ img/                      ← doctorX.jpg (avatars), orb.png, doctor5.jpg = LOGO
│
├─ app/
│  ├─ Core/
│  │  ├─ App.php                   ← routeur /controleur/action/param
│  │  ├─ Controller.php            ← base : model(), view(), auth, rôles, CSRF, eval_patient
│  │  └─ Database.php              ← PDO + helpers query/bind/single/all/execute
│  ├─ Config/
│  │  ├─ config.php                ← constantes globales (BASE_URL, DB_*, ...), charge config.local
│  │  ├─ config.local.php          ← SECRETS (NON versionné)
│  │  ├─ config.local.example.php  ← modèle à copier
│  │  ├─ doctors.php               ← catalogue médecins (ryan/sarah/lucas) partagé
│  │  └─ notifications.php         ← modèles de messages d'alerte (par source + sortie)
│  ├─ Controllers/
│  │  ├─ HomeController.php         ← / (landing publique)
│  │  ├─ AuthController.php         ← /auth/login|register|logout|forgot
│  │  ├─ DoctorsController.php      ← /doctors (PATIENT uniquement) + badge cloche
│  │  ├─ PersonnelController.php    ← /personnel (accueil MÉDECIN) + jeton ReadmitGuard
│  │  ├─ PatientController.php      ← /patient/select|clear (sélection du patient)
│  │  ├─ DozaController.php         ← /doza, /doza/resultat, /doza/save (MÉDECIN)
│  │  ├─ ChatController.php         ← /chat (alias Doza, MÉDECIN)
│  │  ├─ VoiceController.php        ← /voice (alias résultat Doza, MÉDECIN)
│  │  ├─ SoraController.php         ← /sora, /sora/profil, /sora/save (MÉDECIN)
│  │  ├─ ProfileController.php      ← /profile, /profile/doza, /profile/sora, /profile/doctor/<slug>
│  │  └─ NotificationsController.php← /notifications, /notifications/send, /notifications/read
│  ├─ Models/
│  │  ├─ Model.php                 ← base : ensureSchema() (migration idempotente, SANS information_schema)
│  │  ├─ User.php                  ← comptes + patientCode()/parsePatientCode()/findPatientById()
│  │  ├─ Consultation.php          ← sessions Doza (user_id=patient, personnel_id=médecin)
│  │  ├─ SoraFiche.php             ← fiches Sora
│  │  └─ Notification.php          ← alertes patient
│  └─ Views/
│     ├─ layouts/
│     │  ├─ main.php               ← layout principal (Tailwind config + favicon + style.css)
│     │  ├─ auth.php               ← layout des écrans d'authentification (thème Material)
│     │  └─ blank.php              ← layout vierge (pages auto-portées : Sora)
│     ├─ home/index.php            ← landing
│     ├─ auth/{login,register,forgot,index}.php
│     ├─ doctors/index.php         ← Find Doctors (patient) + cloche alertes
│     ├─ personnel/index.php       ← Accueil médecin (hero dégradé, CTA, grille)
│     ├─ patient/select.php        ← saisie ID Patient #PT-xxxxx
│     ├─ profile/
│     │  ├─ index.php              ← Mon profil (patient ET médecin, hero dégradé + tuiles)
│     │  ├─ doza.php               ← fiche Doza (MÉDECIN : historique)
│     │  ├─ doctor.php             ← fiche générique (médecins de la liste + Sora médecin)
│     │  ├─ patient_model.php      ← fiche Doza/Sora (PATIENT : but + mes alertes)
│     │  └─ qa.php                 ← communauté Q&A (écran secondaire)
│     ├─ chat/index.php            ← questionnaire Doza (collecte -> /doza/save -> /doza/resultat)
│     ├─ voice/index.php           ← résultat Doza + bloc « Envoyer une alerte »
│     ├─ sora/index.php            ← formulaire Sora (saisie clinique)
│     ├─ sora/profil.php           ← résultat Sora + bloc « Envoyer une alerte »
│     ├─ notifications/index.php   ← liste des alertes (PATIENT)
│     └─ partials/patient_banner.php ← bandeau « Patient : … (changer) » (écrans d'éval)
│
├─ api/                            ← API Python (FastAPI)
│  ├─ main.py                      ← app FastAPI : /health, /predict (Doza), /sora, /accompagnement
│  ├─ predict.py                   ← logique Doza (seuils, zones, features)
│  ├─ sora_suivi.py                ← modèle M1 Suivi
│  ├─ accompagnement.py            ← modèle M2 Contrôle
│  ├─ models/*.joblib              ← modèles sérialisés
│  └─ requirements.txt
│
├─ database/medcare.sql            ← schéma + migrations (idempotent)
├─ start_all.bat                   ← lance PHP + API (+ Streamlit)
├─ README.md
└─ GUIDE_MIGRATION.md              ← CE document
```

---

## 6. Le routeur & les conventions de routes

### 6.1 Comment une URL devient un contrôleur

`app/Core/App.php` découpe l'URL `/<controleur>/<action>/<params…>` et appelle la méthode.

> **PIÈGE IMPORTANT :** le routeur fait `ucfirst($url[0]) . 'Controller'`.
> Donc la route **`/notifications` → `NotificationsController`** (avec un **S**, au pluriel).
> Si la classe s'appelle `NotificationController` (singulier), la route tombe sur la page
> d'accueil par défaut (`HomeController`) — **bug silencieux**. (Vécu pendant la session.)
>
> Règle : **le nom du fichier/classe du contrôleur doit correspondre au segment d'URL
> (avec la même casse/pluriel), + suffixe `Controller`.**

### 6.2 Table des routes principales

| URL | Contrôleur::méthode | Accès |
|---|---|---|
| `/` | `HomeController::index` | public |
| `/auth/login`, `/auth/register`, `/auth/logout`, `/auth/forgot` | `AuthController::*` | public |
| `/doctors` | `DoctorsController::index` | **patient** |
| `/personnel` | `PersonnelController::index` | **personnel** |
| `/patient/select`, `/patient/clear` | `PatientController::*` | **personnel** |
| `/doza`, `/doza/resultat`, `/doza/save` | `DozaController::*` | **personnel** (+ patient confirmé) |
| `/chat`, `/voice` | alias Doza | **personnel** |
| `/sora`, `/sora/profil`, `/sora/save` | `SoraController::*` | **personnel** (+ patient confirmé) |
| `/profile` | `ProfileController::index` | patient **ou** personnel |
| `/profile/doza`, `/profile/sora` | `ProfileController::*` | patient **ou** personnel (contenu selon rôle) |
| `/profile/doctor/<slug>` | `ProfileController::doctor` | patient **ou** personnel |
| `/notifications` | `NotificationsController::index` | **patient** |
| `/notifications/send` | `NotificationsController::send` | **personnel** (AJAX JSON) |
| `/notifications/read` | `NotificationsController::read` | **patient** (POST) |

---

## 7. Rôles, sessions, CSRF & protection du patient

### 7.1 Les gardes (dans `app/Core/Controller.php`)

```php
$this->requireLogin();          // visiteur -> /auth/login
$this->requireRole('patient');  // mauvais rôle -> son propre portail (homeFor)
$this->requireRole('personnel');
// homeFor : personnel -> 'personnel' ; sinon -> 'doctors'
```

**Convention adoptée dans la session :**
- Écrans d'exécution des modèles (`/doza`, `/sora`, `/chat`, `/voice`, `/profile/doza`,
  `/profile/sora` côté action) → **personnel**.
- `/doctors` (Find Doctors) → **patient**.
- `/profile`, `/profile/doza`, `/profile/sora` (consultation) → **les deux**, avec
  **branchement par rôle** (contenu différent).

### 7.2 Le patient en cours d'évaluation (`eval_patient`)

Avant toute évaluation, le médecin **sélectionne** un patient par son **ID Patient**.
Le patient est mémorisé **en session** (jamais pris depuis le client au moment d'écrire en base).

```php
// Controller.php
protected function evalPatient()        { return $_SESSION['eval_patient'] ?? null; }
protected function setEvalPatient($u)   { $_SESSION['eval_patient'] = ['id'=>$u->id,'name'=>…,'code'=>User::patientCode($u->id)]; }
protected function requireEvalPatient($next) { if (empty eval_patient) redirect('patient/select?next='.$next); return eval_patient; }
```

**Exemple** (`DozaController::index`) :

```php
public function index() {
    $this->requireRole('personnel');
    $patient = $this->requireEvalPatient('doza');  // sinon -> /patient/select?next=doza
    $this->view('chat/index', ['patient'=>$patient, ...]);
}
```

### 7.3 ID Patient `#PT-xxxxx` (format centralisé)

```php
User::patientCode(7);          // -> "PT-00007"  (affiché "#PT-00007")
User::parsePatientCode('#PT-00007'); // -> 7   (tolérant : "PT-7", "7" fonctionnent aussi)
User::findPatientById(7);      // -> ligne users SI elle existe ET role='patient', sinon null
```

> Côté médecin, le profil affiche un identifiant interne `#MED-xxxxx` (pas un ID patient).

### 7.4 CSRF

```php
$this->csrfToken();   // crée/retourne le jeton de session
$this->csrfField();   // <input type="hidden" name="csrf" ...>
$this->verifyCsrf($_POST['csrf'] ?? '');   // compare en hash_equals
```

Toutes les écritures (inscription, sélection patient, envoi d'alerte, marquer lu) **vérifient le CSRF**.

### 7.5 La règle d'or, concrètement

- Le **résultat** d'un modèle n'est rendu que sur des écrans **personnel** (`/doza/resultat`, `/sora/profil`).
- Le profil **patient** ne montre **aucun** résultat brut (on a retiré l'ancien historique Doza/Sora
  qui exposait `result` + `%`).
- L'envoi d'alerte (`/notifications/send`) :
  - `patient_id` vient **de la session** (`eval_patient`), jamais du POST ;
  - `source_id` est **déduit côté serveur** (dernière éval de ce médecin pour ce patient) ;
  - le message est **rassurant, sans chiffre** (modèles dans `app/Config/notifications.php`).

---

## 8. Schéma de base de données

Base `medcare`, moteur **InnoDB**, charset **utf8mb4**.

### 8.1 `users`
| Colonne | Type | Notes |
|---|---|---|
| id | INT PK AI | |
| first_name | VARCHAR(80) | |
| last_name | VARCHAR(80) | |
| email | VARCHAR(190) UNIQUE | |
| phone | VARCHAR(30) NULL | |
| password_hash | VARCHAR(255) | `password_hash()` (bcrypt) |
| role | ENUM('patient','personnel') | |
| created_at | DATETIME | |

### 8.2 `consultations` (sessions Doza)
| Colonne | Type | Notes |
|---|---|---|
| id | INT PK AI | |
| **user_id** | INT NULL | **= patient évalué** |
| **personnel_id** | INT NULL | **= médecin qui a évalué** (ajouté en migration) |
| tag | VARCHAR(50) | domaine (Diabète, Cœur…) |
| question | VARCHAR(255) | |
| answer | TEXT | message |
| result | VARCHAR(50) | zone : Risque plus faible / intermédiaire / élevé |
| probability | TINYINT UNSIGNED | 0–100 |
| answers_json | TEXT NULL | réponses brutes |
| created_at | DATETIME | |

### 8.3 `sora_fiches` (fiches Sora)
`user_id` (= patient, NOT NULL, FK users), **`personnel_id`** (= médecin, ajouté), puis les
champs cliniques (`age, hosp_days, medications, diagnostics, diagnosis, glucose, antidiabetic,
insulin, metformin`) et les résultats (`proba_suivi, resultat_suivi, proba_controle,
resultat_controle, profil`), `created_at`.

### 8.4 `notifications` (alertes)
| Colonne | Type | Notes |
|---|---|---|
| id | INT PK AI | |
| patient_id | INT (FK users, CASCADE) | **destinataire** |
| sender_id | INT (FK users, SET NULL) | médecin émetteur |
| source | ENUM('doza','sora') | modèle à l'origine |
| source_id | INT NULL | id consultation/fiche liée (déduit serveur) |
| niveau | ENUM('info','attention','important') | |
| titre | VARCHAR(140) | |
| message | TEXT | sans chiffre |
| created_at | DATETIME | |
| read_at | DATETIME NULL | NULL = non lue |

### 8.5 Relations

```
users (1) ──< consultations.user_id        (patient)
users (1) ──< consultations.personnel_id   (médecin)
users (1) ──< sora_fiches.user_id / personnel_id
users (1) ──< notifications.patient_id (CASCADE) / sender_id (SET NULL)
```

---

## 9. Charte graphique (couleurs, police, composants)

### 9.1 Couleurs (teal « MAAK »)

| Usage | Hex |
|---|---|
| Teal principal / boutons | `#0D9488` → dégradé `#0F766E` |
| Teal clair (marque) | `#1AA89B` (`teal-brand`) |
| Teal primary | `#0FA396` (`teal-primary`) |
| Teal foncé (texte titres) | `#0B2926` (`teal-darkText`) / `#134E4A` |
| Dégradé boutons Doza | `from-[#1EACA0] to-[#12897F]` |
| Fond portails/profils | `#E7F6F3` + `screen-ambient` |
| Fond Doza (chat/voice) | `voice-ambient` (dégradé menthe) |
| Fond Sora | menthe `from-[#e6fbf7] via-[#eef9f6] to-[#ddf3ee]` (⚠️ **plus de pêche/orange**) |
| Fond inscription | néomorphique `#edf6f4` |
| Niveaux d'alerte | info = teal · attention = `amber` · important = `rose` |

> Le `serene` (Sora) **est** du teal (`#0d9488`, `#0f766e`…) : c'est pratiquement la même
> palette que Doza. La divergence historique était le **pêche** (retiré lors de la session).

### 9.2 Police & config Tailwind

- **Plus Jakarta Sans** (Google Fonts) partout.
- `main.php` embarque une **config Tailwind inline** (couleurs teal, `borderRadius` 3xl/4xl,
  ombres custom : `soft-card`, `glass`, `teal-glow`, `nav-bar`, `icon-soft`, `floating-btn`…).
- `style.css` fournit `screen-ambient`, `voice-ambient`, `glass-panel`, `podium-*`, animations.

### 9.3 Cadre mobile (constant)

```
max-w-[400px] h-[844px] sm:rounded-[44px]/[40px]/[48px] shadow-2xl
border-[8px] border-slate-800/80  (sur certains écrans)
```

### 9.4 Logo & favicon

- **Logo = `doctor5.jpg` (Dr. Amina)** : marques des portails, auth, accueil.
- **Favicon** : `<link rel="icon" href="<?= ASSETS_URL ?>/img/doctor5.jpg">` dans
  `layouts/main.php`, `layouts/auth.php`, et les `<head>` auto-portés de Sora.

### 9.5 Exemple de composant (tuile de statistique d'un profil)

```html
<div class="rounded-2xl bg-gradient-to-br from-[#E8FAF6] to-[#D2F0EA] p-3.5 border border-white flex flex-col items-center">
  <div class="w-9 h-9 rounded-xl bg-white text-teal-700 flex items-center justify-center mb-1.5 shadow-sm"><!-- icône --></div>
  <div class="text-2xl font-extrabold text-slate-900 leading-none">2</div>
  <p class="text-[10px] text-slate-600 font-semibold mt-1">Patients évalués</p>
</div>
```

---

## 10. Flux fonctionnels détaillés

### 10.1 Authentification
- Inscription (`/auth/register`) : design néomorphique, **1 champ « Nom complet »** scindé en
  prénom/nom dans `AuthController::register`, sélecteur **Patient/Personnel**, **code
  établissement** exigé pour `personnel` (`PERSONNEL_ACCESS_CODE`), mot de passe + confirmation, CSRF.
- Connexion (`/auth/login`) : vérifie `password_verify`, régénère la session, redirige vers
  `homeFor(role)`.

### 10.2 Accueil médecin (`/personnel`)
- Bandeau dégradé (marque + salutation + avatar initiales).
- CTA « Lancer une évaluation » → `/doza` (qui redirige vers la sélection patient).
- Grille : Doza (`/profile/doza`), Sora (`/profile/sora`), ReadmitGuard (nouvel onglet, jeton
  HMAC), médecins (`/profile/doctor/<slug>`).

### 10.3 Sélection du patient (`/patient/select?next=doza|sora`)
- Le médecin saisit `#PT-xxxxx`. Vérification en base (compte + rôle patient). Confirmation du
  nom → `eval_patient` en session → redirection vers l'étape (`doza`/`sora`).
- Un **bandeau « Patient : Prénom Nom · #PT-… (changer) »** apparaît sur tous les écrans d'éval
  (`partials/patient_banner.php`).

### 10.4 Doza (évaluation)
- `/doza` → `chat/index.php` : **questionnaire** (12 variables) **formulé pour un médecin**
  (« Le patient est-il traité par insuline ? », « Diagnostic principal ? »…).
- Le JS appelle l'API `POST /predict` (via `model.js`), stocke le résultat, POST `/doza/save`
  (crée une `consultations` : `user_id=patient`, `personnel_id=médecin`), puis redirige
  `/doza/resultat`.
- `/doza/resultat` → `voice/index.php` : affiche zone + message + facteurs + **bloc « Envoyer
  une alerte »**. (Les mentions patient « ne modifiez jamais votre dose » et « démo éducative »,
  ainsi que le bouton « Prendre rendez-vous », ont été **retirés**.)

### 10.5 Sora (évaluation)
- `/sora` → `sora/index.php` : **formulaire clinique** (âge, jours d'hospit., médicaments,
  diagnostic, glycémie, antidiabétique, insuline, metformine) — libellés **en français**,
  valeurs modèle inchangées.
- `/sora/profil` → `sora/profil.php` : jauge + tuiles + recommandation + **bloc « Envoyer une
  alerte »**. Enregistre via `/sora/save`.

### 10.6 Envoi d'alerte (`/notifications/send`, AJAX JSON)
- `patient_id` = session, `source_id` = dernière éval (serveur), `niveau`/`titre`/`message`
  pré-remplis depuis `notifications.php` (modifiable), CSRF.

### 10.7 Côté patient
- `/doctors` : cloche + **badge non lues**.
- `/notifications` : liste de **ses** alertes, « Marquer comme lu ».
- `/profile/doza`, `/profile/sora` (**fiche patient** `patient_model.php`) : **but du modèle** +
  **ses alertes pour ce modèle** (jamais de résultat brut).

---

## 11. Les phases de travail réalisées (roadmap)

> Pour chaque phase : **But**, **Étapes**, **Fichiers**, **Exemple**. C'est l'ordre réel suivi
> (branche `feature/portail-medecin`).

### Phase 0 — Reprise d'un prompt interrompu
- **But :** retrouver et poursuivre une tâche coupée (limite de tokens) d'une session précédente.
- **Étapes :** lister les sessions locales (`~/.claude/projects/<projet>/*.jsonl`), repérer la
  bonne par date, récupérer le prompt, repartir de l'état réel du dépôt (jamais supposer).
- **Mindset :** une nouvelle session **n'a pas** la mémoire des précédentes → toujours **relire
  le code** avant d'agir.

### Phase 1 — Portail : profil (patient + médecin) & accueil médecin
- **But :** un écran « Mon profil » commun aux deux rôles + un accueil médecin.
- **Étapes :** `ProfileController::index` branché par rôle (compteurs réels), nouvelles vues
  `profile/index.php` et `personnel/index.php`, barre de navigation basse selon le rôle.
- **Exemple :** compteurs médecin = patients évalués (distincts) + total des évaluations ;
  compteurs patient = sessions Doza + fiches Sora.

### Phase 2 — Inscription néomorphique
- **But :** re-styliser `/auth/register` (maquette fournie) **sans casser le backend**.
- **Étapes :** garder tous les champs fonctionnels (rôle, code établissement, confirmation,
  CSRF), 1 champ « Nom complet » scindé côté contrôleur.

### Phase 3 — Protection du patient (gros morceau)
- **But :** le patient ne voit jamais les résultats ; le médecin évalue puis alerte.
- **Étapes :**
  1. Verrouiller les accès par rôle.
  2. **ID Patient #PT-** centralisé (`User::patientCode`/`parsePatientCode`).
  3. Sélection du patient en session (`PatientController`, `eval_patient`, bandeau).
  4. Enregistrement avec `personnel_id` (migration des 2 tables).
  5. Table `notifications` + `NotificationsController` + modèles de messages.
  6. Côté patient : cloche + badge + liste + « marquer comme lu ».
- **Exemple de test :** médecin saisit un ID valide puis invalide ; Doza→alerte ; Sora→alerte ;
  patient voit ses 2 alertes ; un autre patient ne les voit pas ; patient redirigé depuis `/doza`.

### Phase 4 — Redesign (hero & cartes d'identité)
- **But :** rendre l'accueil médecin et les cartes de profil plus « stylés » (toujours la charte).
- **Étapes :** bandeau dégradé teal, avatar flottant (halo + pastille), tuiles de stats à icône.

### Phase 5 — Marque MAAK + logo + chatbot médecin + erreur API
- **But :** nom d'app = **MAAK** ; logo = Dr. Amina ; questionnaire reformulé pour un médecin ;
  régler « service de prédiction indisponible ».
- **Étapes :** remplacer « Doza Santé / MedCare / Serene Pulse » → **MAAK** (garder Doza/Sora
  = noms d'assistants), poser `doctor5.jpg` comme logo + favicon, reformuler le `FLOW` du chat,
  **lancer l'API** (`uvicorn`).

### Phase 6 — Fiches, historique, suppression, Sora « comme Doza », français
- **But :** retirer les mentions patient de l'écran résultat ; corriger l'historique ;
  fiches patient Doza/Sora ; aligner Sora sur Doza ; tout en français.
- **Étapes :**
  - `voice/index.php` : retirer bouton RDV + avertissement patient + « démo éducative ».
  - **Correctif historique** : `recentByPersonnel()` (la fiche médecin interrogeait `user_id`
    = médecin → vide ; il faut `personnel_id`).
  - Branchement rôle de `/profile/doza` et `/profile/sora` ; nouvelle vue `patient_model.php`
    (but + `listByPatientAndSource`).
  - `sora/index.php` + `sora/profil.php` : palette alignée Doza (pêche→teal), cadre 400px,
    libellés FR (valeurs modèle inchangées).

---

## 12. Façon de penser / mindset de travail

1. **Relire avant d'écrire.** Ouvrir les fichiers cités, comprendre les conventions existantes
   (nommage, style de commentaires, classes Tailwind) et **écrire du code qui leur ressemble**.
2. **Ne pas casser l'existant.** Garder la charte et la logique (sessions, rôles, CSRF, PDO).
   Préférer des **édits ciblés** à des réécritures.
3. **Penser « rôle ».** Chaque écran/route a un rôle attendu ; chaque lien de navigation doit
   pointer vers une destination **valide pour ce rôle**.
4. **Respecter la règle d'or** (patient ≠ résultats bruts). En cas de doute, c'est non.
5. **Demander seulement sur un vrai embranchement** (choix produit ambigu). Sinon, choisir un
   défaut raisonnable et **l'annoncer**.
6. **Vérifier systématiquement** : `php -l` → rendu CLI (zéro alerte PHP + marqueurs de contenu)
   → parcours HTTP (curl) → **nettoyer les données de test**.
7. **Committer par petits lots** avec un message **descriptif en français** + la ligne
   d'attribution. **Pas de push** sauf demande. Travailler sur la branche courante.
8. **Écrire pour la bonne audience.** Un livrable destiné à un·e coéquipier·ère (comme ce guide)
   est rédigé pour lui/elle, pas pour soi.

---

## 13. Optimisations

### 13.1 Migrations sans casser MySQL (le point le plus important)
`Model::ensureSchema()` :
- **saute** toute vérification si déjà faite dans la session (`$_SESSION['schema_ok_<table>']`) →
  **zéro requête** ensuite ;
- sinon **sonde** la table via un `SELECT … LIMIT 1` **léger** (pas `information_schema`) ;
- ne lance `CREATE`/`ALTER` **que si** la table/colonne manque vraiment.

> **Pourquoi pas `information_schema` ?** Sur le poste d'origine (XAMPP/MariaDB), interroger
> `information_schema` **faisait planter `mysqld`** (segfault). Le `SELECT` sur la vraie table
> emprunte un chemin stable. **Ne pas réintroduire `information_schema` ici.**

### 13.2 Accès base
- PDO en **requêtes préparées** (`ATTR_EMULATE_PREPARES=false`), `FETCH_OBJ`.
- `LIMIT` injecté par **cast entier** (pas de bind possible en mode non émulé).

### 13.3 Sécurité = optimisation de confiance
- `source_id` **déduit serveur** (pas de confiance au client).
- `patient_id` **en session**.

### 13.4 Frontend
- Tailwind **CDN** (pas de build en dev). *Pour la prod : compiler Tailwind et auto-héberger
  la police — voir backlog.*
- Avatars en `object-cover object-top` pour cadrer le visage.

---

## 14. Tests & vérification

### 14.1 Lint PHP
```bash
php -l app/Controllers/ProfileController.php   # "No syntax errors detected"
```

### 14.2 Rendu CLI (sans serveur) — très utile
Un petit harnais qui **exécute le vrai code** (contrôleur → vue) avec une session simulée,
capture la sortie, et vérifie **l'absence d'alertes PHP** + des **marqueurs de contenu** :

```php
<?php
$_SERVER['SCRIPT_NAME']='/index.php'; $_SERVER['REQUEST_METHOD']='GET';
require 'app/Config/config.php';
spl_autoload_register(function($c){foreach(['Core','Controllers','Models'] as $d){$f=APP_PATH."/$d/$c.php";if(is_file($f)){require_once $f;return;}}});
session_start();
$_SESSION=['user'=>['id'=>4,'first_name'=>'Fatma','last_name'=>'Souei','email'=>'f@x.fr','phone'=>'','role'=>'personnel']];
ob_start(); (new ProfileController())->index(); $o=ob_get_clean();
echo (stripos($o,'Warning:')===false ? "OK\n" : "ALERTE\n");
echo (strpos($o,'Patients évalués')!==false ? "contenu OK\n" : "MANQUE\n");
```

### 14.3 Parcours HTTP (curl) — bout en bout
Lancer `php -S 127.0.0.1:8000 -t public` + l'API, puis enchaîner : login → sélection patient →
`/doza/save` → `/doza/resultat` (extraire le CSRF) → `/notifications/send` → vérifier côté patient.

> **PIÈGE UTF-8 (vécu) :** `curl --data '{"message":"médecin"}'` en Git Bash peut **mal encoder
> les accents** → `json_decode` échoue côté PHP → l'alerte semble « refusée (csrf) ».
> **Solution :** écrire le corps JSON avec `php -r 'file_put_contents("b.json", json_encode(...))'`
> puis `curl --data-binary @b.json`. (Le vrai navigateur envoie de l'UTF-8 correct, donc ce
> n'est **pas** un bug de l'app.)

> **PIÈGE CRLF :** un script `.sh` sauvegardé avec des fins de ligne **CRLF** fait que les URLs
> curl se terminent par `\r` → toutes les requêtes échouent. Garder les `.sh` en **LF**, ou
> exécuter les commandes en ligne.

### 14.4 Toujours nettoyer les données de test
Après un parcours qui crée des comptes/alertes de test, **les supprimer** pour laisser la base
dans l'état d'origine (ne garder que les migrations de schéma voulues).

---

## 15. Pièges connus (gotchas)

| Piège | Symptôme | Correctif |
|---|---|---|
| Contrôleur au pluriel | `/notifications` affiche l'accueil | classe = `NotificationsController` (segment d'URL + `Controller`) |
| Historique fiche médecin vide | « Aucune question » après une éval | interroger `personnel_id` (`recentByPersonnel`), pas `user_id` |
| API non lancée | « service de prédiction indisponible » | `uvicorn main:app --app-dir api --port 8001` ; tester `/health` |
| `information_schema` | `mysqld` plante (segfault XAMPP) | ne jamais l'utiliser ; sonder par `SELECT … LIMIT 1` |
| UTF-8 dans curl `--data` | alerte « csrf »/refusée en test | `--data-binary @fichier.json` écrit en UTF-8 |
| CRLF dans `.sh` | toutes les requêtes curl échouent | fins de ligne **LF** |
| `localhost` MySQL | connexion capricieuse Windows | `DB_HOST=127.0.0.1` |
| Liens inter-rôles | redirection « morte » vers le portail | pointer chaque lien vers une route valide pour le rôle |
| Secrets en dur | fuite de secret | tout dans `config.local.php` (non versionné) |

---

## 16. Exemple de bout en bout (walkthrough)

**Scénario : le Dr Fatma évalue la patiente Emna (#PT-00005) avec Doza, puis l'alerte.**

1. **Connexion médecin** → redirigé vers `/personnel` (Accueil médecin).
2. Clic **« Lancer une évaluation »** → `/doza` → comme aucun patient n'est confirmé,
   redirection **`/patient/select?next=doza`**.
3. Saisie **`#PT-00005`** → vérif base (compte + rôle patient) → `eval_patient` en session →
   retour **`/doza`** avec le bandeau *« Patient : Emna Omri · #PT-00005 (changer) »*.
4. Le médecin répond au **questionnaire** (formulé « sur le patient »).
5. Fin → appel **`POST /predict`** (API) → **`POST /doza/save`** (crée une `consultations` :
   `user_id=5`, `personnel_id=<id Fatma>`) → **`/doza/resultat`**.
6. L'écran résultat montre la **zone de risque**, les **facteurs**, et le **bloc alerte**
   pré-rempli (message rassurant selon la zone). Clic **« Envoyer l'alerte »** →
   **`POST /notifications/send`** : `patient_id=5` (session), `source_id` = dernière conso
   (serveur), CSRF vérifié → insert `notifications`.
7. **Côté patiente Emna** : à sa connexion, **cloche avec badge** sur `/doctors` ; dans
   `/notifications` (ou la **fiche patient** `/profile/doza`), elle lit le **message du médecin**
   (jamais le score), puis « Marquer comme lu ».
8. Une **autre** patiente ne voit **pas** cette alerte (isolation par `patient_id`).

---

## 17. Checklist finale de migration

- [ ] Code récupéré, branche `feature/portail-medecin`.
- [ ] PHP 8.x et Python 3.10+ dans le PATH.
- [ ] MySQL démarré, `database/medcare.sql` importé (base `medcare`).
- [ ] `app/Config/config.local.php` créé (secrets) ; `DB_PASS` ajusté si besoin.
- [ ] `pip install -r api/requirements.txt` (dans un venv de préférence).
- [ ] `php -S 127.0.0.1:8000 -t public` → page d'accueil OK.
- [ ] `uvicorn main:app --app-dir api --port 8001` → `/health` renvoie `{"ok":true,...}`.
- [ ] Inscription d'un compte **personnel** (avec le code établissement) et d'un **patient**.
- [ ] Parcours complet : sélection patient → Doza → alerte → la patiente voit l'alerte.
- [ ] `php -l` propre sur les fichiers modifiés ; données de test nettoyées.
- [ ] Commits en français + attribution ; **pas de push** sans accord.

---

## 18. Backlog & améliorations possibles

- Statistiques **100 % calculées** sur les fiches médecin (actuellement « Fiabilité 4.9 » générique).
- **Compiler Tailwind** et auto-héberger Plus Jakarta Sans (prod, hors-ligne, perfs).
- Pagination/chargement progressif des historiques et alertes.
- Journalisation (qui a évalué quel patient, quand) et export.
- Tests automatisés (PHPUnit + un script d'intégration HTTP versionné, en **LF**).
- Internationalisation complète (tout le reste du produit en français).
- Durcissement prod : `display_errors=0`, en-têtes de sécurité, HTTPS, rotation des secrets.

---

## 19. Annexes

### Annexe A — Commandes utiles

```bash
# Lancer le site + l'API
php -S 127.0.0.1:8000 -t public
python -m uvicorn main:app --app-dir api --port 8001
#   (ou start_all.bat)

# Vérifier la syntaxe PHP
php -l app/Controllers/XxxController.php

# Santé de l'API
curl http://127.0.0.1:8001/health

# Inspecter la base
php -r 'require "app/Config/config.php"; $p=new PDO("mysql:host=".DB_HOST.";dbname=".DB_NAME,DB_USER,DB_PASS); foreach($p->query("DESCRIBE users") as $r) echo $r["Field"].PHP_EOL;'

# Git (branche de travail)
git status
git add app
git commit -m "..."
```

### Annexe B — `config.local.php`

```php
<?php
// app/Config/config.local.php — NON versionné (secrets)
define('READMITGUARD_SECRET',  '<secret-hmac-long-et-aleatoire>');
define('PERSONNEL_ACCESS_CODE','<code-exige-a-inscription-personnel>');
define('READMITGUARD_URL',     'http://localhost:8501');
// Optionnel si MySQL a un mot de passe root sur ce poste :
// define('DB_PASS', '<mot-de-passe-root>');
```

### Annexe C — Conventions de commit (adoptées)

- Messages **en français**, à l'impératif/descriptif, qui expliquent **le pourquoi**.
- Terminer par la ligne d'attribution convenue.
- **Pas de `git push`** sauf demande explicite ; travailler sur `feature/portail-medecin`.

---

*Fin du guide. En cas de doute : relire le code concerné, respecter la charte et la règle d'or
(le patient ne voit jamais les résultats), vérifier avec `php -l` + rendu + curl, puis committer
par petits lots. Bon courage et bienvenue sur MAAK. 🩺*
