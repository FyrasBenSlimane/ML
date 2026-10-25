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
        // Profil accessible au patient ET au médecin (rôle personnel).
        $this->requireLogin();
        $user = $this->currentUser();
        $role = $user['role'] ?? 'patient';
        $isMedecin = ($role === 'personnel');

        // Compteurs : patient = ses sessions Doza + ses fiches Sora (nombre, sans résultat) ;
        //             médecin = patients évalués (distincts) + total des évaluations.
        // IMPORTANT : le patient ne voit JAMAIS les résultats des modèles — aucun historique ici.
        $stats = $isMedecin
            ? [['value' => 0, 'label' => 'Patients évalués'], ['value' => 0, 'label' => 'Évaluations']]
            : [['value' => 0, 'label' => 'Sessions Doza'],    ['value' => 0, 'label' => 'Fiches Sora']];
        $unread = 0;

        try {
            $consultations = $this->model('Consultation');
            $fiches        = $this->model('SoraFiche');
            if ($isMedecin) {
                $patients = array_unique(array_merge(
                    $consultations->distinctUserIds(),
                    $fiches->distinctUserIds()
                ));
                $stats = [
                    ['value' => count($patients),                            'label' => 'Patients évalués'],
                    ['value' => $consultations->countAll() + $fiches->countAll(), 'label' => 'Évaluations'],
                ];
            } else {
                $stats = [
                    ['value' => $consultations->countByUser($user['id']), 'label' => 'Sessions Doza'],
                    ['value' => $fiches->countByUser($user['id']),        'label' => 'Fiches Sora'],
                ];
                $unread = $this->model('Notification')->unreadCountByPatient($user['id']);
            }
        } catch (Throwable $e) {
            // Base indisponible : compteurs à 0, pas de blocage.
        }

        $this->view('profile/index', [
            'title'       => 'Mon profil',
            'user'        => $user,
            'isMedecin'   => $isMedecin,
            // ID Patient #PT-xxxxx (format centralisé) ; côté médecin : identifiant interne.
            'idLabel'     => $isMedecin ? 'Identifiant' : 'ID Patient',
            'idValue'     => $isMedecin
                                ? 'MED-' . str_pad((string) ($user['id'] ?? 0), 5, '0', STR_PAD_LEFT)
                                : User::patientCode($user['id'] ?? 0),
            'initials'    => $this->initials($user),
            'roleBadge'   => $isMedecin ? 'Médecin' : 'Patient Doza',
            'stats'       => $stats,
            'unread'      => $unread,
            // Dossier : médecin → fiche Doza ; patient → ses alertes (jamais de résultats bruts).
            'dossierLink' => $isMedecin ? 'profile/doza' : 'notifications',
            'backLink'    => $isMedecin ? 'personnel' : 'doctors',
            'bodyClass'   => 'bg-slate-900 min-h-screen flex items-center justify-center p-0 sm:p-6 antialiased font-sans text-slate-800 selection:bg-teal-100 select-none',
        ]);
    }

    /** Initiales (majuscules) à partir du prénom et du nom, pour l'avatar sans photo. */
    private function initials(array $user)
    {
        $fn = trim((string) ($user['first_name'] ?? ''));
        $ln = trim((string) ($user['last_name'] ?? ''));
        $i  = ($fn !== '' ? mb_substr($fn, 0, 1) : '') . ($ln !== '' ? mb_substr($ln, 0, 1) : '');
        return mb_strtoupper($i !== '' ? $i : 'U');
    }

    /** Fiche « Doza » (Doctor Profile & Overview) : bio, stats et historique questions / réponses du patient. */
    public function doza()
    {
        $this->requireLogin();
        $user = $this->currentUser();

        // Patient : fiche « but du modèle + mes alertes » (jamais de résultat brut).
        if (($user['role'] ?? '') === 'patient') {
            $this->modelFichePatient('doza', [
                'name'    => 'Doza',
                'spec'    => "Détection du changement d'insuline · IA",
                'img'     => 'doctor5.jpg',
                'badge'   => 'Doza · IA clinique',
                'purpose' => "Doza est un assistant d'intelligence artificielle qui aide votre médecin à repérer "
                           . "si votre traitement par insuline pourrait nécessiter un ajustement pendant votre "
                           . "séjour. C'est votre médecin qui l'utilise, puis vous informe des décisions à prendre.",
            ]);
            return;
        }

        // Médecin : fiche clinique + historique des évaluations qu'il a réalisées.
        $questions = [];
        $answers   = [];
        $patients  = [];
        try {
            foreach ($this->model('Consultation')->recentByPersonnel($user['id'], 50) as $row) {
                $date = $this->formatDate($row->created_at);
                $questions[] = ['text' => $row->question, 'tag' => $row->tag, 'date' => $date];
                $answers[]   = ['text' => $row->answer, 'result' => $row->result,
                                'confidence' => $row->probability . '%', 'date' => $date];
                if (!empty($row->user_id)) { $patients[$row->user_id] = true; }
            }
        } catch (Throwable $e) {
            // Base indisponible : historique vide.
        }

        $doctor = [
            'name'     => 'Doza',
            'spec'     => "Détection du changement d'insuline · IA",
            'center'   => "Assistant de dosage d'insuline",
            'exp'      => 'Modèle prédictif',
            'img'      => 'doctor5.jpg',
            'badgeImg' => 'doctor6.jpg',
            'bio'      => "Modèle d'aide à la décision : estime la probabilité qu'un ajustement de la dose "
                        . "d'insuline soit nécessaire pendant le séjour, à partir des données cliniques du patient.",
            'stats'    => [
                ['icon' => 'star',     'value' => '4.9',                    'label' => 'Fiabilité'],
                ['icon' => 'chat',     'value' => (string) count($answers),  'label' => 'Évaluations'],
                ['icon' => 'patients', 'value' => (string) count($patients), 'label' => 'Patients suivis'],
            ],
        ];

        $this->view('profile/doza', [
            'title'     => 'Doza',
            'doctor'    => $doctor,
            'questions' => $questions,
            'answers'   => $answers,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start sm:items-center bg-slate-100 min-h-screen p-0 sm:p-4',
        ]);
    }

    /** Fiche patient d'un modèle (Doza/Sora) : but du modèle + alertes reçues pour ce modèle. */
    private function modelFichePatient($source, array $meta)
    {
        $user   = $this->currentUser();
        $alerts = [];
        try {
            $alerts = $this->model('Notification')->listByPatientAndSource($user['id'], $source, 50);
        } catch (Throwable $e) {
            // Base indisponible : pas d'alertes.
        }
        $this->view('profile/patient_model', [
            'title'     => $meta['name'],
            'model'     => $meta,
            'source'    => $source,
            'alerts'    => $alerts,
            'csrf'      => $this->csrfToken(),
            'bodyClass' => 'bg-slate-900 min-h-screen flex items-center justify-center p-0 sm:p-6 antialiased font-sans text-slate-800 selection:bg-teal-100 select-none',
        ]);
    }

    /** Fiche d'un autre médecin de la liste — même interface que la fiche Doza. */
    public function doctor($slug = '')
    {
        // Lecture ouverte au patient et au médecin (rôle personnel).
        $this->requireLogin();

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
                ['icon' => 'star',     'value' => $d['rating'], 'label' => $d['reviews'] . ' avis'],
                ['icon' => 'chat',     'value' => $d['exp'],    'label' => "ans d'exp."],
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
        $this->requireLogin();
        $user = $this->currentUser();

        // Patient : fiche « but du modèle + mes alertes ».
        if (($user['role'] ?? '') === 'patient') {
            $this->modelFichePatient('sora', [
                'name'    => 'Sora',
                'spec'    => 'Profil de sortie · IA',
                'img'     => 'doctor6.jpg',
                'badge'   => 'Sora · IA clinique',
                'purpose' => "Sora est un assistant d'intelligence artificielle qui aide votre médecin à préparer "
                           . "votre sortie de l'hôpital et à organiser votre suivi (contrôle du diabète). C'est votre "
                           . "médecin qui l'utilise, puis vous transmet les recommandations adaptées.",
            ]);
            return;
        }

        // Médecin : fiche Sora + historique des fiches qu'il a réalisées.
        $questions = [];
        $answers   = [];
        $patients  = [];
        try {
            foreach ($this->model('SoraFiche')->recentByPersonnel($user['id'], 50) as $row) {
                $date = $this->formatDate($row->created_at);
                $questions[] = ['text' => 'Fiche de sortie — ' . $row->profil, 'tag' => 'Sora', 'date' => $date];
                $answers[]   = ['text' => $row->profil, 'result' => $row->resultat_suivi,
                                'confidence' => $row->resultat_controle, 'date' => $date];
                if (!empty($row->user_id)) { $patients[$row->user_id] = true; }
            }
        } catch (Throwable $e) {
            // Base indisponible : historique vide.
        }

        $doctor = [
            'name'   => 'Sora',
            'spec'   => 'Profil de sortie · IA',
            'center' => 'Assistant de sortie',
            'exp'    => 'Modèle prédictif',
            'img'    => 'doctor6.jpg',
            'bio'    => "Compagnon de sortie : prépare le suivi et le contrôle du diabète pour l'après-hospitalisation.",
            'stats'  => [
                ['icon' => 'star',     'value' => '4.7',                    'label' => 'Fiabilité'],
                ['icon' => 'chat',     'value' => (string) count($answers),  'label' => 'Fiches'],
                ['icon' => 'patients', 'value' => (string) count($patients), 'label' => 'Patients suivis'],
            ],
        ];

        $this->view('profile/doctor', [
            'title'     => 'Sora',
            'doctor'    => $doctor,
            'badge'     => 'Sora · IA',
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
