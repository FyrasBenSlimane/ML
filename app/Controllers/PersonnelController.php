<?php
/**
 * Portail du personnel soignant.
 *   /personnel  -> tableau de bord : bouton vers ReadmitGuard (Ryma) avec jeton signé.
 *
 * Le jeton permet à l'application Streamlit de reconnaître l'utilisateur sans
 * second login. Format (documenté dans le README) :
 *   token = base64url(payload) . "." . base64url(HMAC_SHA256(payload, READMITGUARD_SECRET))
 *   payload = {"uid", "name", "role", "exp"}   (exp = maintenant + 10 min)
 */
class PersonnelController extends Controller
{
    public function index()
    {
        $this->requireRole('personnel');
        $user = $this->currentUser();

        $token = $this->buildReadmitToken($user);
        $url = rtrim(READMITGUARD_URL, '/') . '/?token=' . urlencode($token);

        $this->view('personnel/index', [
            'title'          => 'Espace personnel',
            'user'           => $user,
            'readmitUrl'     => $url,
            'bodyClass'      => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ]);
    }

    /** Construit le jeton signé HMAC-SHA256 pour ReadmitGuard. */
    private function buildReadmitToken(array $user)
    {
        $payload = json_encode([
            'uid'  => $user['id'],
            'name' => trim($user['first_name'] . ' ' . $user['last_name']),
            'role' => $user['role'],
            'exp'  => time() + 600, // 10 minutes
        ], JSON_UNESCAPED_UNICODE);

        $sig = hash_hmac('sha256', $payload, READMITGUARD_SECRET, true);
        return $this->b64url($payload) . '.' . $this->b64url($sig);
    }

    /** base64 URL-safe sans padding. */
    private function b64url($bin)
    {
        return rtrim(strtr(base64_encode($bin), '+/', '-_'), '=');
    }
}
