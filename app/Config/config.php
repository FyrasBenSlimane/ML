<?php
/**
 * Configuration globale de l'application.
 */

// Chemins
define('ROOT_PATH', dirname(__DIR__, 2));
define('APP_PATH', ROOT_PATH . '/app');

// URL de base — détectée automatiquement.
// Fonctionne à la racine, dans un sous-dossier XAMPP (htdocs/Projet ML/…)
// et avec le serveur intégré PHP (php -S ... -t public).
$scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '/index.php');
// Ex. Apache sous-dossier : /Projet ML/public/index.php → /Projet ML
//     Apache (docroot=public) ou php -S : /index.php → ''
$base = preg_replace('#/public/index\.php$#', '', $scriptName);
if ($base === $scriptName) {
    $base = rtrim(str_replace('\\', '/', dirname($scriptName)), '/');
    $base = preg_replace('#/public$#', '', $base);
}
$base = rtrim($base, '/');
define('BASE_URL', $base . '/');
define('ASSETS_URL', $base . '/assets');

// Contrôleur et action par défaut
define('DEFAULT_CONTROLLER', 'HomeController');
define('DEFAULT_ACTION', 'index');

// Base de données (127.0.0.1 plutôt que localhost : évite l'ambiguïté socket/IPv6 sous Windows)
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'medcare');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');

// --- Configuration locale (secrets, NON versionnée) ---
// app/Config/config.local.php (ignoré par Git) peut définir READMITGUARD_SECRET,
// PERSONNEL_ACCESS_CODE, READMITGUARD_URL… Modèle : config.local.example.php.
$localConfig = __DIR__ . '/config.local.php';
if (file_exists($localConfig)) {
    require_once $localConfig;
}

// URL de l'application ReadmitGuard (Streamlit) ouverte depuis le portail personnel.
if (!defined('READMITGUARD_URL'))    define('READMITGUARD_URL', 'http://localhost:8501');
// Secret HMAC du jeton ReadmitGuard — valeur de DEV, À CHANGER (via config.local.php).
if (!defined('READMITGUARD_SECRET')) define('READMITGUARD_SECRET', 'dev-secret-a-changer');
// Code établissement exigé pour créer un compte Personnel — valeur de DEV, À CHANGER.
if (!defined('PERSONNEL_ACCESS_CODE')) define('PERSONNEL_ACCESS_CODE', 'MEDCARE-DEV');

// Affichage des erreurs (à passer à 0 en production)
error_reporting(E_ALL);
ini_set('display_errors', 1);
