<?php
/**
 * Modèle de configuration locale (secrets).
 *
 * Copiez ce fichier en « config.local.php » (dans le même dossier) et mettez
 * vos vraies valeurs. config.local.php est IGNORÉ par Git (voir .gitignore),
 * il ne doit jamais être poussé sur GitHub.
 *
 * config.php le charge automatiquement s'il existe ; sinon des valeurs de
 * développement sont utilisées (à ne pas garder en production).
 */

// Secret partagé pour signer le jeton ReadmitGuard (HMAC-SHA256).
// À générer long et aléatoire. Même valeur côté application Streamlit (Ryma).
define('READMITGUARD_SECRET', 'changez-moi-par-une-cle-longue-et-aleatoire');

// Code établissement exigé pour créer un compte « Personnel ».
define('PERSONNEL_ACCESS_CODE', 'CHANGEZ-MOI');

// (Optionnel) URL de l'application ReadmitGuard si différente de la valeur par défaut.
// define('READMITGUARD_URL', 'http://localhost:8501');
