<?php
/**
 * Contrôleur de la liste des médecins.
 */
class DoctorsController extends Controller
{
    public function index()
    {
        // Données d'exemple — à remplacer par un appel au modèle/BDD.
        $doctors = [
            ['name' => 'Dr. Amina K.',     'spec' => 'Cardiologist',          'rating' => '4.9', 'reviews' => 320, 'exp' => '10+', 'img' => 'doctor2.jpg', 'bg' => 'bg-teal-50/80'],
            ['name' => 'Dr. Ryan Scott',   'spec' => 'Neurologist',           'rating' => '4.8', 'reviews' => 280, 'exp' => '8+',  'img' => 'doctor3.jpg', 'bg' => 'bg-sky-50/80'],
            ['name' => 'Dr. Sarah Jenkins','spec' => 'Pediatrician',          'rating' => '4.9', 'reviews' => 340, 'exp' => '7+',  'img' => 'doctor4.jpg', 'bg' => 'bg-amber-50/80'],
            ['name' => 'Dr. Alex Martin',  'spec' => 'Dentist',               'rating' => '4.9', 'reviews' => 210, 'exp' => '6+',  'img' => 'doctor5.jpg', 'bg' => 'bg-teal-50/60'],
            ['name' => 'Dr. Emily Davis',  'spec' => 'Orthopedic',            'rating' => '4.7', 'reviews' => 190, 'exp' => '9+',  'img' => 'doctor6.jpg', 'bg' => 'bg-rose-50/60'],
            ['name' => 'Dr. Lucas Bennett','spec' => 'General Practitioner',  'rating' => '4.8', 'reviews' => 175, 'exp' => '5+',  'img' => 'doctor.png',  'bg' => 'bg-indigo-50/70'],
        ];

        $data = [
            'title'       => 'Find Doctors',
            'doctors'     => $doctors,
            'specialties' => ['All', 'Cardiologist', 'Neurologist', 'Pediatrician', 'Dentist', 'Orthopedic'],
            // Écran plein format (pas de cadre sombre centré)
            'bodyClass'   => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];

        $this->view('doctors/index', $data);
    }
}
