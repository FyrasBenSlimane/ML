<?php
/**
 * Contrôleur de l'écran "Accompagnement" (compagnon du quotidien).
 *  - /accompagnement  → formulaire + résultat (diabète bien / mal contrôlé)
 *
 * Le calcul est fait par l'API Python (POST /accompagnement), appelée depuis
 * public/assets/js/accompagnement.js.
 */
class AccompagnementController extends Controller
{
    public function index()
    {
        // Motifs d'hospitalisation : valeur modèle => libellé français.
        $diagGroups = [
            'Circulatory'     => 'Cœur / vaisseaux',
            'Diabetes'        => 'Diabète',
            'Respiratory'     => 'Poumons',
            'Digestive'       => 'Digestif',
            'Genitourinary'   => 'Reins / voies urinaires',
            'Musculoskeletal' => 'Os / articulations',
            'Injury'          => 'Blessure',
            'Neoplasms'       => 'Cancer',
            'External'        => 'Cause externe',
            'Other'           => 'Autre',
        ];

        $data = [
            'title'      => 'Accompagnement',
            'diagGroups' => $diagGroups,
            'bodyClass'  => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];

        $this->view('accompagnement/index', $data);
    }
}
