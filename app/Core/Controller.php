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
     * @param string $view  ex: 'home/index'
     * @param array  $data  données passées à la vue
     */
    protected function view($view, $data = [])
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

        // Injecte dans le layout
        require APP_PATH . '/Views/layouts/main.php';
    }
}
