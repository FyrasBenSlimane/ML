# MedCare — portail santé diabète (projet d'équipe ML)

Application d'équipe autour du jeu de données *Diabetes 130-US hospitals*. **MedCare** (site PHP) est la
**porte d'entrée unique** : le patient se connecte et accède à deux assistants d'IA — **Doza** (changement
de dose d'insuline) et **Sora** (profil de sortie : suivi + contrôle) ; le personnel soignant accède à
**ReadmitGuard** (risque de réadmission, application Streamlit).

> ⚠️ Outils d'**aide à l'orientation**, ils ne remplacent pas l'avis d'un médecin.

## Architecture

```
            Navigateur (patient / soignant)
                        |
                 Site MedCare — PHP MVC  (:8000, XAMPP/Apache)
             /          |            \
   Base MySQL      API MedCare        ReadmitGuard (soignant)
   (medcare)       FastAPI (:8001)    Streamlit (:8501) + API (:8002)
                   /predict  Doza     jeton signé HMAC
                   /sora     Sora
```

- **Patient** → portail `/doctors` : Doza (`/doza`), Sora (`/sora`), profil + historique (`/profile`).
- **Personnel** → portail `/personnel` : bouton ReadmitGuard (ouvre Streamlit avec un jeton signé).

## Ports

| Service | Port | Lancement |
| --- | --- | --- |
| Site PHP MedCare | 8000 | XAMPP (Apache) ou `php -S 127.0.0.1:8000 -t public` |
| API MedCare (Doza + Sora) | 8001 | `uvicorn main:app --app-dir api --port 8001` (`.venv-api`) |
| API ReadmitGuard | 8002 | `uvicorn main:app --app-dir deployment/api --port 8002` (`deployment/.venv`) |
| Streamlit ReadmitGuard | 8501 | `streamlit run deployment/app/Home.py` (`deployment/.venv`) |
| MySQL | 3306 | XAMPP |

## Qui a fait quoi

| Membre | Contribution |
| --- | --- |
| **Emna** | Doza — changement de dose d'insuline (`/predict`, `models/insulin_pipeline.joblib`) |
| **Fatma** | Sora — suivi + contrôle du diabète (`/sora`, `api/models/*.joblib`) |
| **Ryma** | ReadmitGuard — réadmission (dossier `deployment/`, Streamlit) |
| **Faycel, Fyras, Najd** | dossiers d'analyse et préparation des données (`faycel/`, `fyras/`, `najd/`, `data/`, `00_team_data_preparation.ipynb`) |

## Installation (Windows / XAMPP)

1. **XAMPP** : démarrer **Apache** et **MySQL**. Importer `database/medcare.sql` dans phpMyAdmin
   (ou laisser les tables se créer automatiquement au premier usage).
2. **Secrets** : copier `app/Config/config.local.example.php` → `app/Config/config.local.php` et définir
   `READMITGUARD_SECRET` (identique côté ReadmitGuard) et `PERSONNEL_ACCESS_CODE`.
3. **API MedCare** : `python -m venv .venv-api` ; `.venv-api\Scripts\activate` ; `pip install -r api/requirements.txt`.
4. **ReadmitGuard** : `cd deployment` ; `python -m venv .venv` ; `pip install -r requirements.txt`.
5. **Tout lancer** : `start_all.bat` (à la racine) — MySQL reste géré par XAMPP.

## Lancement rapide

```
start_all.bat
```
Puis ouvrir **http://127.0.0.1:8000** → « Get Started » → créer un compte.

## Jeton ReadmitGuard (SSO soignant)

Le portail personnel ouvre ReadmitGuard avec un jeton signé, vérifié côté Streamlit avec la **même clé**
(`READMITGUARD_SECRET`) :

```
token   = base64url(payload) . "." . base64url(HMAC_SHA256(payload, READMITGUARD_SECRET))
payload = {"uid": <int>, "name": <str>, "role": "personnel", "exp": <timestamp + 600s>}
```
Jeton valide et non expiré → connexion automatique ; absent → formulaire normal ; invalide/expiré → erreur.

## Comptes de test

Créer via `/auth/register`. Pour un compte **Personnel**, saisir le **code établissement**
(`PERSONNEL_ACCESS_CODE` de `config.local.php` ; valeur de dev : `MEDCARE-2024`).

## Limites connues

- Dans `deployment/`, **RxPredict** et **DailyGuard** font doublon avec Doza / Sora (décision d'équipe à venir).
- Modèles aux performances modestes (ex. ROC-AUC ~0,70) : aide à l'orientation, pas un diagnostic.

## Reste à faire

- Test de bout en bout **en base** à refaire avec **XAMPP MySQL démarré** (non disponible lors de l'intégration).
- Adaptation « langage patient » du formulaire Sora (libellés simplifiés, tranches, « Je ne sais pas ») — reportée.
- Fusion éventuelle des deux API (MedCare :8001 et ReadmitGuard :8002) — reportée après validation.
