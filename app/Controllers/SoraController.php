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
        $this->view('sora/index', ['title' => 'Sora · Fiche patient'], 'blank');
    }

    /** Écran "Profil du patient" (résultat de la fiche). */
    public function profil()
    {
        $this->view('sora/profil', ['title' => 'Sora · Profil du patient'], 'blank');
    }
}
