<?php
/**
 * Profil du patient connecté : son historique Doza + Sora, et la déconnexion.
 *   /profile      → mon profil + mes historiques
 *   /profile/qa   → communauté Q&A (écran secondaire conservé)
 */
class ProfileController extends Controller
{
    public function index()
    {
        $this->requireRole('patient');
        $user = $this->currentUser();

        $doza = [];
        $sora = [];
        try {
            $doza = $this->model('Consultation')->recentByUser($user['id'], 30);
            $sora = $this->model('SoraFiche')->recentByUser($user['id'], 30);
        } catch (Throwable $e) {
            // Base indisponible : historiques vides, pas de blocage.
        }

        $this->view('profile/index', [
            'title'     => 'Mon profil',
            'user'      => $user,
            'doza'      => $doza,
            'sora'      => $sora,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ]);
    }

    /** Fiche « Doza » (Doctor Profile & Overview) : bio, stats et historique questions / réponses du patient. */
    public function doza()
    {
        $this->requireRole('patient');
        $user = $this->currentUser();

        $doctor = [
            'name'     => 'Doza',
            'spec'     => 'Détection du changement d\'insuline · IA',
            'center'   => 'Assistant de dosage d\'insuline',
            'exp'      => 'Modèle prédictif',
            'img'      => 'doctor5.jpg',
            'badgeImg' => 'doctor6.jpg',
            'bio'      => "Specialized in pediatric diagnostics and personalized treatment "
                        . "protocols. Collaborating with clinical AI models to deliver rapid, "
                        . "evidence-based care for every young patient.",
            'stats'    => [
                ['icon' => 'star',     'value' => '4.9',  'label' => '320 Reviews'],
                ['icon' => 'chat',     'value' => '1.4k', 'label' => 'Questions Answered'],
                ['icon' => 'patients', 'value' => '5.2k', 'label' => 'Patients'],
            ],
        ];

        // Historique réel du patient connecté (sessions Doza enregistrées en base).
        $questions = [];
        $answers   = [];
        try {
            foreach ($this->model('Consultation')->recentByUser($user['id'], 50) as $row) {
                $date = $this->formatDate($row->created_at);
                $questions[] = ['text' => $row->question, 'tag' => $row->tag, 'date' => $date];
                $answers[]   = ['text' => $row->answer, 'result' => $row->result,
                                'confidence' => $row->probability . '%', 'date' => $date];
            }
        } catch (Throwable $e) {
            // Base indisponible : historique vide.
        }

        $this->view('profile/doza', [
            'title'     => 'Doza',
            'doctor'    => $doctor,
            'questions' => $questions,
            'answers'   => $answers,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ]);
    }

    /** Fiche d'un autre médecin de la liste — même interface que la fiche Doza. */
    public function doctor($slug = '')
    {
        $this->requireRole('patient');

        $cat  = require APP_PATH . '/Config/doctors.php';
        $slug = preg_replace('/[^a-z0-9_-]/', '', strtolower((string) $slug));
        if (!isset($cat[$slug])) {
            $this->redirect('doctors');
        }
        $d = $cat[$slug];

        $doctor = [
            'name'   => $d['name'],
            'spec'   => $d['spec'],
            'center' => $d['center'],
            'exp'    => $d['exp'] . ' ans d\'expérience',
            'img'    => $d['img'],
            'bio'    => $d['bio'],
            'stats'  => [
                ['icon' => 'star',     'value' => $d['rating'], 'label' => $d['reviews'] . ' Reviews'],
                ['icon' => 'chat',     'value' => $d['exp'],    'label' => 'Years Exp.'],
                ['icon' => 'patients', 'value' => '1.2k',       'label' => 'Patients'],
            ],
        ];

        $this->view('profile/doctor', [
            'title'     => $d['name'],
            'doctor'    => $doctor,
            'badge'     => $d['spec'],
            'questions' => [],
            'answers'   => [],
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ]);
    }

    /** Fiche « Sora » (Doctor Profile & Overview) : même interface que Doza, côté patient. */
    public function sora()
    {
        $this->requireRole('patient');
        $user = $this->currentUser();

        $doctor = [
            'name'   => 'Sora',
            'spec'   => 'Profil de sortie · IA',
            'center' => 'Assistant de sortie',
            'exp'    => 'Modèle prédictif',
            'img'    => 'doctor6.jpg',
            'bio'    => "Compagnon de sortie : suivi et contrôle du diabète pour préparer l'après-hospitalisation.",
            'stats'  => [
                ['icon' => 'star',     'value' => '4.7',  'label' => '190 Reviews'],
                ['icon' => 'chat',     'value' => '1.1k', 'label' => 'Fiches'],
                ['icon' => 'patients', 'value' => '3.4k', 'label' => 'Patients'],
            ],
        ];

        // Historique réel des fiches Sora du patient connecté.
        $questions = [];
        $answers   = [];
        try {
            foreach ($this->model('SoraFiche')->recentByUser($user['id'], 50) as $row) {
                $date = $this->formatDate($row->created_at);
                $questions[] = ['text' => 'Fiche de sortie — ' . $row->profil, 'tag' => 'Sora', 'date' => $date];
                $answers[]   = ['text' => $row->profil, 'result' => $row->resultat_suivi,
                                'confidence' => $row->resultat_controle, 'date' => $date];
            }
        } catch (Throwable $e) {
            // Base indisponible : historique vide.
        }

        $this->view('profile/doctor', [
            'title'     => 'Sora',
            'doctor'    => $doctor,
            'badge'     => 'Sora · Santé IA',
            'questions' => $questions,
            'answers'   => $answers,
            'plusLink'  => 'sora',
            'plusAria'  => 'Nouvelle fiche Sora',
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ]);
    }

    /** Date MySQL (Y-m-d H:i:s) → « 12 oct. » en français. */
    public function formatDate($datetime)
    {
        $ts = strtotime((string) $datetime);
        if ($ts === false) { return ''; }
        $mois = ['', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
                 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
        return (int) date('j', $ts) . ' ' . $mois[(int) date('n', $ts)];
    }

    /** Communauté Q&A (conservée). */
    public function qa()
    {
        $this->requireRole('patient');
        $questions = [
            ['text' => "Protocole d'ajustement de l'insuline en pédiatrie ?", 'tag' => 'Pédiatrie', 'answers' => 160, 'helpful' => '98% utile'],
            ['text' => "Céphalées chroniques : diagnostic différentiel ?",     'tag' => 'Neurologie', 'answers' => 84,  'helpful' => '95% utile'],
            ['text' => "Calendrier vaccinal chez l'immunodéprimé ?",            'tag' => 'Immunologie', 'answers' => 52,  'helpful' => '91% utile'],
        ];
        $data = [
            'title'     => 'Communauté Q&A',
            'doctor'    => ['name' => 'Doza', 'spec' => "Détection du changement d'insuline · IA", 'img' => 'doctor5.jpg', 'badgeImg' => 'doctor6.jpg'],
            'questions' => $questions,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ];
        $this->view('profile/qa', $data);
    }
}
