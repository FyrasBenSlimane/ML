<?php
/**
 * Contrôleur de l'écran "Fiche patient" (Sora — Santé · IA).
 *  - /sora  → formulaire clinique "Fiche patient" (saisie par un soignant)
 *
 * La vue est une page autonome (elle a son propre <head> / Tailwind),
 * on la rend donc avec le layout vierge "blank".
 */
class SoraController extends Controller
{
    public function index()
    {
        $this->requireRole('patient');
        $this->view('sora/index', ['title' => 'Sora · Fiche patient'], 'blank');
    }

    /** Écran "Profil du patient" (résultat de la fiche). */
    public function profil()
    {
        $this->requireRole('patient');
        $this->view('sora/profil', ['title' => 'Sora · Profil du patient'], 'blank');
    }

    /**
     * Enregistre une fiche Sora + ses résultats (AJAX, POST JSON : { fiche, resultat }).
     * Appelé par l'écran de résultat après l'appel à l'API /sora.
     */
    public function save()
    {
        header('Content-Type: application/json; charset=utf-8');
        $payload = json_decode(file_get_contents('php://input'), true) ?: [];
        $f = isset($payload['fiche']) && is_array($payload['fiche']) ? $payload['fiche'] : [];
        $r = isset($payload['resultat']) && is_array($payload['resultat']) ? $payload['resultat'] : [];
        $uid = $this->currentUser()['id'] ?? null;

        if (!$uid) {
            echo json_encode(['ok' => false, 'error' => 'not_logged_in']);
            return;
        }
        try {
            $ok = $this->model('SoraFiche')->create([
                'user_id'           => $uid,
                'age'               => $f['age'] ?? '',
                'hosp_days'         => $f['hosp_days'] ?? 0,
                'medications'       => $f['medications'] ?? 0,
                'diagnostics'       => $f['diagnostics'] ?? 0,
                'diagnosis'         => $f['diagnosis'] ?? '',
                'glucose'           => $f['glucose'] ?? '',
                'antidiabetic'      => $f['antidiabetic'] ?? '',
                'insulin'           => $f['insulin'] ?? '',
                'metformin'         => $f['metformin'] ?? '',
                'proba_suivi'       => $r['suivi']['proba'] ?? 0,
                'resultat_suivi'    => $r['suivi']['resultat'] ?? '',
                'proba_controle'    => $r['controle']['proba'] ?? 0,
                'resultat_controle' => $r['controle']['resultat'] ?? '',
                'profil'            => $r['profil'] ?? '',
            ]);
            echo json_encode(['ok' => (bool) $ok]);
        } catch (Throwable $e) {
            http_response_code(200);
            echo json_encode(['ok' => false, 'error' => 'db_unavailable']);
        }
    }
}
