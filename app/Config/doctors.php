<?php
/**
 * Catalogue des médecins (données d'exemple) partagé par la liste « Find Doctors »
 * et l'écran de profil (même interface que la fiche Doza).
 * La clé est le « slug » utilisé dans l'URL : /profile/doctor/<slug>.
 */
return [
    'ryan' => [
        'name'    => 'Dr. Ryan Scott',
        'spec'    => 'Neurologist',
        'rating'  => '4.8',
        'reviews' => 280,
        'exp'     => '8+',
        'img'     => 'doctor3.jpg',
        'bg'      => 'bg-sky-50/80',
        'center'  => 'NeuroCare Clinic',
        'bio'     => "Spécialiste en neurologie, centré sur le diagnostic et le suivi personnalisé des patients.",
    ],
    'sarah' => [
        'name'    => 'Dr. Sarah Jenkins',
        'spec'    => 'Pediatrician',
        'rating'  => '4.9',
        'reviews' => 340,
        'exp'     => '7+',
        'img'     => 'doctor4.jpg',
        'bg'      => 'bg-amber-50/80',
        'center'  => 'Kids Health Center',
        'bio'     => "Pédiatre dédiée à la santé de l'enfant, du suivi de routine aux soins spécialisés.",
    ],
    'lucas' => [
        'name'    => 'Dr. Lucas Bennett',
        'spec'    => 'General Practitioner',
        'rating'  => '4.8',
        'reviews' => 175,
        'exp'     => '5+',
        'img'     => 'doctor.png',
        'bg'      => 'bg-indigo-50/70',
        'center'  => 'City Medical Center',
        'bio'     => "Médecin généraliste, accompagnement global et coordination des soins au quotidien.",
    ],
];
