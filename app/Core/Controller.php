<?php
/**
 * Contrôleur de base : charge les modèles et rend les vues.
 */
class Controller
{
    /**
     * Instancie un modèle.
     */
    protected function model($model)
    {
        require_once APP_PATH . '/Models/' . $model . '.php';
        return new $model();
    }

    /**
     * Rend une vue dans le layout principal.
     *
     * @param string $view   ex: 'home/index'
     * @param array  $data   données passées à la vue
     * @param string $layout layout à utiliser (fichier dans Views/layouts/), défaut 'main'
     */
    protected function view($view, $data = [], $layout = 'main')
    {
        extract($data);

        $viewFile = APP_PATH . '/Views/' . $view . '.php';
        if (!file_exists($viewFile)) {
            http_response_code(404);
            exit("Vue introuvable : {$view}");
        }

        // Capture le contenu de la vue
        ob_start();
        require $viewFile;
        $content = ob_get_clean();

        // Injecte dans le layout choisi (repli sur main.php si absent)
        $layoutFile = APP_PATH . '/Views/layouts/' . $layout . '.php';
        if (!file_exists($layoutFile)) {
            $layoutFile = APP_PATH . '/Views/layouts/main.php';
        }
        require $layoutFile;
    }

    // ===================== Authentification / sessions =====================

    /** Utilisateur connecté (tableau) ou null. */
    protected function currentUser()
    {
        return $_SESSION['user'] ?? null;
    }

    /** Vrai si un utilisateur est connecté. */
    protected function isLoggedIn()
    {
        return isset($_SESSION['user']);
    }

    /** Redirige vers une route interne puis stoppe le script. */
    protected function redirect($path = '')
    {
        header('Location: ' . BASE_URL . ltrim($path, '/'));
        exit;
    }

    /** Portail d'accueil selon le rôle. */
    protected function homeFor($role)
    {
        return $role === 'personnel' ? 'personnel' : 'doctors';
    }

    /** Exige une connexion ; sinon -> page de connexion. */
    protected function requireLogin()
    {
        if (!$this->isLoggedIn()) {
            $this->redirect('auth/login');
        }
    }

    /**
     * Exige un rôle précis. Visiteur -> connexion ;
     * mauvais rôle -> son propre portail.
     */
    protected function requireRole($role)
    {
        $this->requireLogin();
        if (($this->currentUser()['role'] ?? null) !== $role) {
            $this->redirect($this->homeFor($this->currentUser()['role'] ?? null));
        }
    }

    // ===================== Jeton CSRF =====================

    /** Jeton CSRF de la session (créé si absent). */
    protected function csrfToken()
    {
        if (empty($_SESSION['csrf'])) {
            $_SESSION['csrf'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf'];
    }

    /** Champ caché à insérer dans les formulaires. */
    protected function csrfField()
    {
        return '<input type="hidden" name="csrf" value="' . htmlspecialchars($this->csrfToken()) . '">';
    }

    /** Vérifie le jeton CSRF reçu. */
    protected function verifyCsrf($token)
    {
        return !empty($_SESSION['csrf']) && is_string($token) && hash_equals($_SESSION['csrf'], $token);
    }
}
