<?php
/**
 * Point d'entrée unique (Front Controller).
 * Toutes les requêtes passent par ce fichier.
 */

// --- Serveur intégré PHP (php -S) : servir directement les fichiers existants (assets) ---
if (php_sapi_name() === 'cli-server') {
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $file = __DIR__ . $path;
    if ($path !== '/' && is_file($file)) {
        return false; // laisse le serveur servir l'asset tel quel
    }
}

// Chargement de la configuration
require_once __DIR__ . '/../app/Config/config.php';

// Autoloader simple des classes de app/
spl_autoload_register(function ($class) {
    $paths = [
        APP_PATH . '/Core/' . $class . '.php',
        APP_PATH . '/Controllers/' . $class . '.php',
        APP_PATH . '/Models/' . $class . '.php',
    ];
    foreach ($paths as $file) {
        if (file_exists($file)) {
            require_once $file;
            return;
        }
    }
});

// Démarrage de l'application (routeur)
$app = new App();
