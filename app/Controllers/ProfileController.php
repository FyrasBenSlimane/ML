<?php
/**
 * Contrôleur du profil médecin.
 *  - /profile        → « Doctor Profile & Overview » (écran qui précède le Q&A)
 *  - /profile/qa     → « Doctor Profile & Q&A » (liste des questions / réponses)
 *
 * Point d'entrée naturel depuis la liste des médecins (/doctors).
 * Le bloc « Community Q&A » de l'écran profil ouvre /profile/qa.
 */
class ProfileController extends Controller
{
    /** Fiche du médecin + aperçu de la communauté Q&A. */
    public function index()
    {
        $doctor = [
            'name'     => 'Doza',
            'spec'     => 'Détection du changement d\'insuline · IA',
            'center'   => 'Assistant de dosage d\'insuline',
            'exp'      => 'Modèle prédictif',
            'img'      => 'doctor5.jpg', // avatar principal
            'badgeImg' => 'doctor6.jpg', // collaborateur (petit badge)
            'bio'      => "Specialized in pediatric diagnostics and personalized treatment "
                        . "protocols. Collaborating with clinical AI models to deliver rapid, "
                        . "evidence-based care for every young patient.",
            'stats'    => [
                ['icon' => 'star',     'value' => '4.9',  'label' => '320 Reviews'],
                ['icon' => 'chat',     'value' => '1.4k', 'label' => 'Questions Answered'],
                ['icon' => 'patients', 'value' => '5.2k', 'label' => 'Patients'],
            ],
        ];

        // Historiques réels, construits à partir des sessions enregistrées en base.
        // (Si MySQL n'est pas démarré, on affiche simplement un historique vide.)
        $questions = [];
        $answers   = [];
        try {
            $rows = $this->model('Consultation')->recent(50);
            foreach ($rows as $row) {
                $date = $this->formatDate($row->created_at);
                $questions[] = [
                    'text' => $row->question,
                    'tag'  => $row->tag,
                    'date' => $date,
                ];
                $answers[] = [
                    'text'       => $row->answer,
                    'result'     => $row->result,
                    'confidence' => $row->probability . '%',
                    'date'       => $date,
                ];
            }
        } catch (Throwable $e) {
            $questions = [];
            $answers   = [];
        }

        $data = [
            'title'     => 'Doza',
            'doctor'    => $doctor,
            'questions' => $questions,
            'answers'   => $answers,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ];

        $this->view('profile/index', $data);
    }

    /** Date MySQL (Y-m-d H:i:s) → « 12 oct. » en français. */
    private function formatDate($datetime)
    {
        $ts = strtotime((string) $datetime);
        if ($ts === false) { return ''; }
        $mois = ['', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
                 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
        return (int) date('j', $ts) . ' ' . $mois[(int) date('n', $ts)];
    }

    /** Liste des questions / réponses de la communauté. */
    public function qa()
    {
        $questions = [
            [
                'text'    => 'Protocol for adjusting insulin dosage in newly diagnosed type 1 pediatric patients?',
                'tag'     => 'Pediatrics',
                'answers' => 160,
                'helpful' => '98% helpful',
            ],
            [
                'text'    => 'Key differential diagnosis guidelines for chronic tension headaches vs ocular strain in children?',
                'tag'     => 'Neurology',
                'answers' => 84,
                'helpful' => '95% helpful',
            ],
            [
                'text'    => 'Recommended vaccination schedule adjustments for immunocompromised toddlers?',
                'tag'     => 'Immunology',
                'answers' => 52,
                'helpful' => '91% helpful',
            ],
        ];

        $data = [
            'title'     => 'Doza · Q&A',
            'doctor'    => [
                'name'     => 'Doza',
                'spec'     => 'Détection du changement d\'insuline · IA',
                'img'      => 'doctor5.jpg',
                'badgeImg' => 'doctor6.jpg',
            ],
            'questions' => $questions,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ];

        $this->view('profile/qa', $data);
    }
}
