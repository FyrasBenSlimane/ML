<?php
/**
 * Alertes patient.
 *   POST /notifications/send   → (médecin) envoie une alerte au patient en session
 *   GET  /notifications        → (patient) liste de SES alertes
 *   POST /notifications/read   → (patient) marque une de ses alertes comme lue
 *
 * Sécurité : patient_id vient TOUJOURS de la session (jamais du client),
 * source_id est déduit côté serveur (dernière évaluation de ce médecin pour ce
 * patient) donc appartient forcément au patient, et chaque action vérifie le CSRF.
 */
class NotificationsController extends Controller
{
    /** (Médecin) Envoie une alerte au patient sélectionné. AJAX JSON. */
    public function send()
    {
        header('Content-Type: application/json; charset=utf-8');

        if (($this->currentUser()['role'] ?? null) !== 'personnel') {
            http_response_code(403);
            echo json_encode(['ok' => false, 'error' => 'forbidden']);
            return;
        }

        $in = json_decode(file_get_contents('php://input'), true) ?: [];
        if (!$this->verifyCsrf($in['csrf'] ?? '')) {
            http_response_code(419);
            echo json_encode(['ok' => false, 'error' => 'csrf']);
            return;
        }

        $patient = $this->evalPatient();
        if (empty($patient)) {
            http_response_code(409);
            echo json_encode(['ok' => false, 'error' => 'no_patient']);
            return;
        }

        $source  = in_array(($in['source'] ?? ''), ['doza', 'sora'], true) ? $in['source'] : '';
        $niveau  = in_array(($in['niveau'] ?? ''), ['info', 'attention', 'important'], true) ? $in['niveau'] : 'info';
        $titre   = trim((string) ($in['titre'] ?? ''));
        $message = trim((string) ($in['message'] ?? ''));

        if ($source === '')  { http_response_code(422); echo json_encode(['ok' => false, 'error' => 'source']); return; }
        if ($titre === '')   { $titre = 'Message de votre médecin'; }
        if ($message === '') { http_response_code(422); echo json_encode(['ok' => false, 'error' => 'empty']); return; }

        $personnelId = (int) $this->currentUser()['id'];

        try {
            // source_id déduit côté serveur : dernière évaluation de CE médecin pour CE patient.
            $model = $source === 'doza' ? $this->model('Consultation') : $this->model('SoraFiche');
            $sourceId = $model->latestIdForPatientBy($patient['id'], $personnelId);
            if ($sourceId <= 0) {
                http_response_code(409);
                echo json_encode(['ok' => false, 'error' => 'no_record']);
                return;
            }

            $ok = $this->model('Notification')->create([
                'patient_id' => $patient['id'],
                'sender_id'  => $personnelId,
                'source'     => $source,
                'source_id'  => $sourceId,
                'niveau'     => $niveau,
                'titre'      => $titre,
                'message'    => $message,
            ]);
            echo json_encode(['ok' => (bool) $ok]);
        } catch (Throwable $e) {
            http_response_code(200);
            echo json_encode(['ok' => false, 'error' => 'db_unavailable']);
        }
    }

    /** (Patient) Liste de ses propres alertes. */
    public function index()
    {
        $this->requireRole('patient');
        $user  = $this->currentUser();
        $items = [];
        try {
            $items = $this->model('Notification')->listByPatient($user['id'], 50);
        } catch (Throwable $e) {
            // Base indisponible : liste vide.
        }

        $this->view('notifications/index', [
            'title'     => 'Mes alertes',
            'items'     => $items,
            'csrf'      => $this->csrfToken(),
            'bodyClass' => 'bg-slate-900 min-h-screen flex items-center justify-center p-0 sm:p-6 antialiased font-sans text-slate-800 selection:bg-teal-100 select-none',
        ]);
    }

    /** (Patient) Marque une de ses alertes comme lue. */
    public function read()
    {
        $this->requireRole('patient');
        if ($_SERVER['REQUEST_METHOD'] === 'POST' && $this->verifyCsrf($_POST['csrf'] ?? '')) {
            try {
                $this->model('Notification')->markRead($_POST['id'] ?? 0, $this->currentUser()['id']);
            } catch (Throwable $e) {
                // Base indisponible : on ignore, l'alerte reste non lue.
            }
        }
        $this->redirect('notifications');
    }
}
