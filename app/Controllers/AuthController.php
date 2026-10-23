<?php
/**
 * Authentification : connexion, création de compte, déconnexion.
 *   /auth           -> redirige (connecté : portail ; sinon : /auth/login)
 *   /auth/login     -> GET : formulaire ; POST : vérifie les identifiants
 *   /auth/register  -> GET : formulaire ; POST : crée le compte (puis connecte)
 *   /auth/logout    -> détruit la session
 *
 * Deux rôles : « patient » (portail Doza + Sora) et « personnel » (ReadmitGuard).
 * L'inscription « personnel » exige un code établissement (config.local.php).
 */
class AuthController extends Controller
{
    public function index()
    {
        if ($this->isLoggedIn()) {
            $this->redirect($this->homeFor($this->currentUser()['role']));
        }
        $this->redirect('auth/login');
    }

    public function login()
    {
        if ($this->isLoggedIn()) {
            $this->redirect($this->homeFor($this->currentUser()['role']));
        }

        $errors = [];
        $old = ['email' => ''];

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            if (!$this->verifyCsrf($_POST['csrf'] ?? '')) {
                $errors['global'] = 'Session expirée, veuillez réessayer.';
            } else {
                $old['email'] = trim($_POST['email'] ?? '');
                $password = $_POST['password'] ?? '';

                // Messages d'erreur par champ (affichés sous le champ concerné).
                if ($old['email'] === '') { $errors['email'] = 'Veuillez renseigner votre e-mail.'; }
                if ($password === '')     { $errors['password'] = 'Veuillez renseigner votre mot de passe.'; }

                if (empty($errors)) {
                    try {
                        $user = $this->model('User')->findByEmail($old['email']);
                        if ($user && password_verify($password, $user->password_hash)) {
                            // « Se souvenir de moi » : cookie de session prolongé (30 j) si coché.
                            $this->loginUser($user, !empty($_POST['remember']));
                            $this->redirect($this->homeFor($user->role));
                        }
                        $errors['global'] = 'Identifiants incorrects.';
                    } catch (Throwable $e) {
                        $errors['global'] = "Base de données indisponible. Démarrez MySQL (XAMPP) puis réessayez.";
                    }
                }
            }
        }

        $this->view('auth/login', [
            'title'  => 'Connexion',
            'errors' => $errors,
            'old'    => $old,
            'csrf'   => $this->csrfToken(),
        ], 'auth');
    }

    public function register()
    {
        if ($this->isLoggedIn()) {
            $this->redirect($this->homeFor($this->currentUser()['role']));
        }

        $errors = [];
        $old = ['first_name' => '', 'last_name' => '', 'email' => '', 'phone' => '', 'role' => 'patient'];

        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            foreach (['first_name', 'last_name', 'email', 'phone', 'role'] as $k) {
                $old[$k] = trim($_POST[$k] ?? '');
            }
            $password = $_POST['password'] ?? '';
            $confirm  = $_POST['password_confirm'] ?? '';
            $accessCode = trim($_POST['access_code'] ?? '');
            if (!in_array($old['role'], ['patient', 'personnel'], true)) {
                $old['role'] = 'patient';
            }

            if (!$this->verifyCsrf($_POST['csrf'] ?? '')) {
                $errors['global'] = 'Session expirée, veuillez réessayer.';
            } else {
                if ($old['first_name'] === '') $errors['first_name'] = 'Le prénom est obligatoire.';
                if ($old['last_name'] === '')  $errors['last_name']  = 'Le nom est obligatoire.';
                if (!filter_var($old['email'], FILTER_VALIDATE_EMAIL)) {
                    $errors['email'] = "L'adresse e-mail n'est pas valide.";
                }
                if (strlen($password) < 8) {
                    $errors['password'] = 'Le mot de passe doit contenir au moins 8 caractères.';
                }
                if ($confirm !== $password) {
                    $errors['password_confirm'] = 'La confirmation ne correspond pas au mot de passe.';
                }
                if ($old['role'] === 'personnel' && !hash_equals(PERSONNEL_ACCESS_CODE, $accessCode)) {
                    $errors['access_code'] = "Code établissement incorrect : impossible de créer un compte personnel.";
                }

                if (empty($errors)) {
                    try {
                        $userModel = $this->model('User');
                        if ($userModel->emailExists($old['email'])) {
                            $errors['email'] = 'Cette adresse e-mail est déjà utilisée.';
                        } else {
                            $id = $userModel->create([
                                'first_name' => $old['first_name'],
                                'last_name'  => $old['last_name'],
                                'email'      => $old['email'],
                                'phone'      => $old['phone'],
                                'password'   => $password,
                                'role'       => $old['role'],
                            ]);
                            if ($id) {
                                $this->loginUser($userModel->findById($id));
                                $this->redirect($this->homeFor($old['role']));
                            }
                            $errors['global'] = "La création du compte a échoué, réessayez.";
                        }
                    } catch (Throwable $e) {
                        $errors['global'] = "Base de données indisponible. Démarrez MySQL (XAMPP) puis réessayez.";
                    }
                }
            }
        }

        $this->view('auth/register', [
            'title'  => 'Créer un compte',
            'errors' => $errors,
            'old'    => $old,
            'csrf'   => $this->csrfToken(),
        ], 'auth');
    }

    /** Page « Mot de passe oublié ? » — simple consigne, pas de réinitialisation automatique. */
    public function forgot()
    {
        $this->view('auth/forgot', ['title' => 'Mot de passe oublié'], 'auth');
    }

    public function logout()
    {
        $_SESSION = [];
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_unset();
            session_destroy();
        }
        // Une nouvelle session (et un nouveau jeton CSRF) seront créés au prochain chargement.
        $this->redirect('auth/login');
    }

    /**
     * Ouvre la session pour un utilisateur (régénère l'id de session).
     * $remember = true → prolonge le cookie de session à 30 jours (« Se souvenir de moi »).
     */
    private function loginUser($user, $remember = false)
    {
        session_regenerate_id(true);
        $_SESSION['user'] = [
            'id'         => (int) $user->id,
            'first_name' => $user->first_name,
            'last_name'  => $user->last_name,
            'email'      => $user->email,
            'role'       => $user->role,
        ];

        if ($remember) {
            $p = session_get_cookie_params();
            setcookie(session_name(), session_id(), [
                'expires'  => time() + 30 * 24 * 3600,
                'path'     => $p['path'] ?: '/',
                'domain'   => $p['domain'],
                'secure'   => $p['secure'],
                'httponly' => true,
                'samesite' => $p['samesite'] ?: 'Lax',
            ]);
        }
    }
}
