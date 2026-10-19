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
}
