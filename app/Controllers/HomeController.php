<?php
/**
 * Contrôleur de la page d'accueil.
 */
class HomeController extends Controller
{
    public function index()
    {
        $data = [
            'title' => 'Your Health, Our Priority',
        ];

        $this->view('home/index', $data);
    }
}
