<?php
/**
 * Configuration globale de l'application.
 */

// Chemins
define('ROOT_PATH', dirname(__DIR__, 2));
define('APP_PATH', ROOT_PATH . '/app');

// URL de base (adapter selon l'installation)
define('BASE_URL', '/');
define('ASSETS_URL', BASE_URL . 'assets');

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
