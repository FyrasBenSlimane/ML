<?php
/**
 * Contrôleur de l'écran "Doza" — assistant médical IA (chat).
 */
class ChatController extends Controller
{
    public function index()
    {
        // Alias de /doza : réservé au médecin, sur un patient confirmé.
        $this->requireRole('personnel');
        $patient = $this->requireEvalPatient('doza');
        $data = [
            'title'     => 'Doza',
            'patient'   => $patient,
            // Écran plein format (pas de cadre sombre centré)
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];

        $this->view('chat/index', $data);
    }
}
