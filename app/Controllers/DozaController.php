<?php
/**
 * Contrôleur de l'assistant IA "Doza".
 *  - /doza            → conversation guidée (collecte des réponses)
 *  - /doza/resultat   → écran de résultat (sortie du modèle), lit ?p=…
 *
 * Remarque : ces écrans réutilisent les vues existantes (chat/ et voice/),
 * accessibles aussi via les anciennes routes /chat et /voice (alias).
 */
class DozaController extends Controller
{
    /** Conversation guidée. */
    public function index()
    {
        // Évaluation réservée au médecin (rôle personnel), sur un patient confirmé.
        $this->requireRole('personnel');
        $patient = $this->requireEvalPatient('doza');
        $data = [
            'title'     => 'Doza',
            'patient'   => $patient,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];
        $this->view('chat/index', $data);
    }

    /**
     * Enregistre une session terminée (AJAX, POST JSON : { answers, p }).
     * Appelé par l'écran de conversation juste avant la redirection résultat.
     */
    public function save()
    {
        header('Content-Type: application/json; charset=utf-8');

        // Évaluation réservée au médecin, sur un patient confirmé en session.
        if (($this->currentUser()['role'] ?? null) !== 'personnel' || empty($this->evalPatient())) {
            http_response_code(403);
            echo json_encode(['ok' => false, 'error' => 'no_patient']);
            return;
        }

        // Lecture du corps JSON
        $payload = json_decode(file_get_contents('php://input'), true);
        $answers = isset($payload['answers']) && is_array($payload['answers']) ? $payload['answers'] : [];
        $p       = isset($payload['p']) ? (float) $payload['p'] : 0.0;
        if ($p < 0) { $p = 0; }
        if ($p > 1) { $p = 1; }

        // Résultat = la ZONE renvoyée par l'API (seuils 0.315 / 0.55 de insulin_meta.json),
        // pas un recalcul local avec 0.40 / 0.66.
        $zone = isset($payload['zone']) ? (string) $payload['zone'] : '';
        $messages = [
            'Risque élevé'         => "D'après vos réponses, un réajustement de votre dose d'insuline est probable. Parlez-en à votre médecin.",
            'Risque intermédiaire' => "Un ajustement de votre dose d'insuline est possible. Surveillez votre glycémie.",
            'Risque plus faible'   => "Votre profil ne montre pas de besoin de changement immédiat. Poursuivez votre suivi habituel.",
        ];
        if ($zone !== '' && isset($messages[$zone])) {
            $result = $zone;
        } else {
            // Repli si la zone n'est pas transmise : mêmes seuils que l'API.
            $result = $p >= 0.55 ? 'Risque élevé' : ($p >= 0.315 ? 'Risque intermédiaire' : 'Risque plus faible');
        }
        $answer = $messages[$result];

        // Domaine principal (motif d'hospitalisation) → tag lisible
        $tag = $this->tagFromDiag($answers['diag_1_group'] ?? null);
        // user_id = patient évalué (session) ; personnel_id = médecin connecté.
        $patientId   = $this->evalPatient()['id'] ?? null;
        $personnelId = $this->currentUser()['id'] ?? null;

        try {
            $model = $this->model('Consultation');
            $ok = $model->create([
                'user_id'      => $patientId,
                'personnel_id' => $personnelId,
                'tag'          => $tag,
                'question'     => "Dois-je ajuster ma dose d'insuline ?",
                'answer'       => $answer,
                'result'       => $result,
                'probability'  => (int) round($p * 100),
                'answers_json' => json_encode($answers, JSON_UNESCAPED_UNICODE),
            ]);
            echo json_encode(['ok' => (bool) $ok]);
        } catch (Throwable $e) {
            // Base indisponible : on ne bloque pas le patient, on signale juste l'échec.
            http_response_code(200);
            echo json_encode(['ok' => false, 'error' => 'db_unavailable']);
        }
    }

    /** Traduit le groupe de diagnostic (flux Doza) en tag court en français. */
    private function tagFromDiag($diag)
    {
        $map = [
            'Diabetes'        => 'Diabète',
            'Circulatory'     => 'Cœur',
            'Respiratory'     => 'Poumons',
            'Digestive'       => 'Digestif',
            'Genitourinary'   => 'Reins',
            'Musculoskeletal' => 'Articulations',
            'Injury'          => 'Blessure',
            'Neoplasms'       => 'Cancer',
        ];
        return $map[$diag] ?? 'Général';
    }

    /** Écran de résultat : /doza/resultat?p=0.70 */
    public function resultat()
    {
        // Résultat réservé au médecin ; le patient ne voit jamais la sortie du modèle.
        $this->requireRole('personnel');
        $patient = $this->requireEvalPatient('doza');
        // Probabilité renvoyée par le modèle (0 à 1), bornée par sécurité.
        $p = isset($_GET['p']) ? (float) $_GET['p'] : 0.70;
        if ($p < 0) { $p = 0; }
        if ($p > 1) { $p = 1; }

        $data = [
            'title'          => 'Doza',
            'p'              => $p,
            'patient'        => $patient,
            'csrf'           => $this->csrfToken(),
            'alertSource'    => 'doza',
            'alertTemplates' => require APP_PATH . '/Config/notifications.php',
            'bodyClass'      => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];
        $this->view('voice/index', $data);
    }
}
