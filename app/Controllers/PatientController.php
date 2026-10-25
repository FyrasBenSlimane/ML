<?php
/**
 * Sélection du patient par le médecin AVANT toute évaluation (Doza, Sora, …).
 *   /patient/select?next=doza  → saisie de l'ID Patient (#PT-xxxxx)
 *   /patient/clear?next=doza   → oublie le patient courant
 *
 * Le patient confirmé est mémorisé en session (jamais pris depuis le client au
 * moment de l'enregistrement). Sans patient confirmé : pas d'évaluation.
 */
class PatientController extends Controller
{
    public function select()
    {
        $this->requireRole('personnel');
        $next   = $this->safeNext($_GET['next'] ?? ($_POST['next'] ?? 'doza'));
        $errors = [];
        $old    = ['code' => ''];

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $old['code'] = trim($_POST['code'] ?? '');
            if (!$this->verifyCsrf($_POST['csrf'] ?? '')) {
                $errors['global'] = 'Session expirée, veuillez réessayer.';
            } else {
                $id = User::parsePatientCode($old['code']);
                if (!$id) {
                    $errors['code'] = "Format attendu : #PT-00000.";
                } else {
                    try {
                        $patient = $this->model('User')->findPatientById($id);
                        if (!$patient) {
                            $errors['code'] = "Aucun patient ne correspond à cet ID Patient.";
                        } else {
                            $this->setEvalPatient($patient);
                            $this->redirect($next);
                        }
                    } catch (Throwable $e) {
                        $errors['global'] = "Base de données indisponible. Démarrez MySQL (XAMPP) puis réessayez.";
                    }
                }
            }
        }

        $this->view('patient/select', [
            'title'     => 'Sélection du patient',
            'next'      => $next,
            'errors'    => $errors,
            'old'       => $old,
            'csrf'      => $this->csrfToken(),
            'current'   => $this->evalPatient(),
            'bodyClass' => 'bg-slate-900 min-h-screen flex items-center justify-center p-0 sm:p-6 antialiased font-sans text-slate-800 selection:bg-teal-100 select-none',
        ]);
    }

    public function clear()
    {
        $this->requireRole('personnel');
        $this->clearEvalPatient();
        $this->redirect('patient/select?next=' . $this->safeNext($_GET['next'] ?? 'doza'));
    }

    /** N'autorise que les étapes connues après la sélection. */
    private function safeNext($next)
    {
        $next = ltrim((string) $next, '/');
        return in_array($next, ['doza', 'sora'], true) ? $next : 'doza';
    }
}
