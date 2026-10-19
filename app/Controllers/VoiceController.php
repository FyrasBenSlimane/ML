<?php
/**
 * Contrôleur de l'écran "Active Voice Session".
 * Cet écran affiche la SORTIE du modèle ML (probabilité que la dose d'insuline soit modifiée).
 */
class VoiceController extends Controller
{
    public function index()
    {
        // Probabilité renvoyée par le modèle ML, entre 0 et 1.
        // Lue depuis l'URL : /voice?p=0.70 . Valeur par défaut (démo) : 0.70
        $p = isset($_GET['p']) ? (float) $_GET['p'] : 0.70;

        // Sécurité : on garde p dans l'intervalle [0, 1]
        if ($p < 0) { $p = 0; }
        if ($p > 1) { $p = 1; }

        $data = [
            'title'     => 'Doza',
            'p'         => $p,
            // Écran plein format (pas de cadre sombre centré)
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];

        $this->view('voice/index', $data);
    }
}
