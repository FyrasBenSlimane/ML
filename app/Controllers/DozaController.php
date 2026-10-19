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
        $data = [
            'title'     => 'Doza',
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

        // Lecture du corps JSON
        $payload = json_decode(file_get_contents('php://input'), true);
        $answers = isset($payload['answers']) && is_array($payload['answers']) ? $payload['answers'] : [];
        $p       = isset($payload['p']) ? (float) $payload['p'] : 0.0;
        if ($p < 0) { $p = 0; }
        if ($p > 1) { $p = 1; }

        // Interprétation de la probabilité → libellé de résultat + réponse du modèle
        if ($p >= 0.66) {
            $result = 'Réajustement probable';
            $answer = "D'après vos réponses, un réajustement de votre dose d'insuline est probable. Parlez-en à votre médecin.";
        } elseif ($p >= 0.40) {
            $result = 'À surveiller';
            $answer = "Risque modéré détecté. Surveillez votre glycémie sur les prochaines 48 h et notez toute variation.";
        } else {
            $result = 'Dose stable';
            $answer = "Votre profil ne montre pas de besoin de changement immédiat. Poursuivez votre suivi habituel.";
        }

        // Domaine principal (motif d'hospitalisation) → tag lisible
        $tag = $this->tagFromDiag($answers['diag_1_group'] ?? null);

        try {
            $model = $this->model('Consultation');
            $ok = $model->create([
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
        // Probabilité renvoyée par le modèle (0 à 1), bornée par sécurité.
        $p = isset($_GET['p']) ? (float) $_GET['p'] : 0.70;
        if ($p < 0) { $p = 0; }
        if ($p > 1) { $p = 1; }

        $data = [
            'title'     => 'Doza',
            'p'         => $p,
            'bodyClass' => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];
        $this->view('voice/index', $data);
    }
}
