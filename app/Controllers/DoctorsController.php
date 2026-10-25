<?php
/**
 * Contrôleur de la liste des médecins.
 * Chaque médecin ouvre une fiche de profil (même interface que la fiche Doza).
 */
class DoctorsController extends Controller
{
    public function index()
    {
        // Accueil patient : liste réservée au rôle patient.
        $this->requireRole('patient');

        // Alertes non lues du patient (badge de la cloche).
        $unread = 0;
        try {
            $unread = $this->model('Notification')->unreadCountByPatient($this->currentUser()['id']);
        } catch (Throwable $e) {
            // Base indisponible : pas de badge, pas de blocage.
        }

        // Catalogue partagé avec l'écran de profil (/profile/doctor/<slug>).
        $cat = require APP_PATH . '/Config/doctors.php';

        // 'link' = route ouverte au clic sur la carte.
        $ryan  = $cat['ryan']  + ['link' => 'profile/doctor/ryan'];
        $sarah = $cat['sarah'] + ['link' => 'profile/doctor/sarah'];
        $lucas = $cat['lucas'] + ['link' => 'profile/doctor/lucas'];

        $doctors = [
            $ryan,
            $sarah,
            ['name' => 'Sora', 'spec' => 'Assistant santé · IA', 'rating' => '4.7', 'reviews' => 190, 'exp' => '9+', 'img' => 'doctor6.jpg', 'bg' => 'bg-rose-50/60', 'link' => 'profile/sora'],
            $lucas,
        ];

        $data = [
            'title'       => 'Find Doctors',
            'doctors'     => $doctors,
            'specialties' => ['All', 'Cardiologist', 'Neurologist', 'Pediatrician', 'Dentist', 'Orthopedic'],
            'unread'      => $unread,
            // Écran plein format (pas de cadre sombre centré)
            'bodyClass'   => 'font-sans text-slate-800 antialiased selection:bg-teal-100 flex justify-center items-start',
        ];

        $this->view('doctors/index', $data);
    }
}
