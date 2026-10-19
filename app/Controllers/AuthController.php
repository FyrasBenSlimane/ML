<?php
/**
 * Authentification : connexion / création de compte.
 *  - /auth            → écran combiné (onglets Connexion / Créer un compte)
 *
 * Deux rôles sont proposés : « Patient » (espace Doza) et « Praticien »
 * (espace professionnel, à venir). Pour l'instant, seule l'interface est
 * réalisée ; la logique serveur (enregistrement, session) viendra ensuite.
 */
class AuthController extends Controller
{
    public function index()
    {
        $data = [
            'title' => 'Créer un compte',
        ];
        // Layout dédié (thème Material 3 propre à cet écran)
        $this->view('auth/index', $data, 'auth');
    }
}
