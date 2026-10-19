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

// Base de données
define('DB_HOST', 'localhost');
define('DB_NAME', 'medcare');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_CHARSET', 'utf8mb4');

// Affichage des erreurs (à passer à 0 en production)
error_reporting(E_ALL);
ini_set('display_errors', 1);
