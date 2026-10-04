<?php
/**
 * Routeur minimal : URL -> Contrôleur / Action / Paramètres.
 * Format d'URL : /controleur/action/param1/param2
 */
class App
{
    private $controller = DEFAULT_CONTROLLER;
    private $action     = DEFAULT_ACTION;
    private $params     = [];

    public function __construct()
    {
        $url = $this->parseUrl();

        // 1. Contrôleur
        if (!empty($url[0])) {
            $controllerName = ucfirst($url[0]) . 'Controller';
            if (file_exists(APP_PATH . '/Controllers/' . $controllerName . '.php')) {
                $this->controller = $controllerName;
                unset($url[0]);
            }
        }

        $this->controller = new $this->controller;

        // 2. Action (méthode)
        if (isset($url[1])) {
            if (method_exists($this->controller, $url[1])) {
                $this->action = $url[1];
                unset($url[1]);
            }
        }

        // 3. Paramètres restants
        $this->params = $url ? array_values($url) : [];

        // 4. Appel
        call_user_func_array([$this->controller, $this->action], $this->params);
    }

    private function parseUrl()
    {
        // 1. Via réécriture Apache (.htaccess) : index.php?url=...
        if (!empty($_GET['url'])) {
            return explode('/', trim(filter_var($_GET['url'], FILTER_SANITIZE_URL), '/'));
        }

        // 2. Sinon, lecture directe de l'URI (serveur intégré PHP, etc.)
        $uri  = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
        $base = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? ''));
        if ($base !== '' && $base !== '/' && strpos($uri, $base) === 0) {
            $uri = substr($uri, strlen($base));
        }

        $uri = trim($uri, '/');
        if ($uri === '') {
            return [];
        }
        return explode('/', filter_var($uri, FILTER_SANITIZE_URL));
    }
}
