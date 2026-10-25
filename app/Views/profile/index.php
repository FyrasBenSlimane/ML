<?php
/**
 * Écran « Mon Profil » — commun au patient et au médecin (rôle personnel).
 * Les compteurs, le dossier médical et les libellés s'adaptent au rôle.
 */
$stat1 = $stats[0] ?? ['value' => 0, 'label' => ''];
$stat2 = $stats[1] ?? ['value' => 0, 'label' => ''];
$fullName = trim(($user['first_name'] ?? '') . ' ' . ($user['last_name'] ?? ''));
?>
<!-- ============ MON PROFIL (patient / médecin) ============ -->
<div class="relative w-full max-w-[400px] h-[844px] max-h-screen sm:max-h-[92vh] overflow-hidden flex flex-col bg-[#E7F6F3] shadow-2xl border-[8px] border-slate-800/80 sm:border-slate-700/60 sm:rounded-[44px] screen-ambient">

    <!-- Barre supérieure : retour · titre + Doza ID · édition -->
    <header class="shrink-0 px-5 pt-4 pb-3 flex items-center justify-between bg-white/40 backdrop-blur-md">
        <a href="<?= BASE_URL . $backLink ?>" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/80 border border-white flex items-center justify-center text-slate-700 shadow-sm hover:bg-white active:scale-95 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <div class="text-center">
            <h1 class="text-base font-extrabold text-slate-900 leading-tight">Mon profil</h1>
            <p class="text-[10px] font-bold text-teal-700 tracking-tight"><?= htmlspecialchars($idLabel) ?> : #<?= htmlspecialchars($idValue) ?></p>
        </div>
        <a href="<?= BASE_URL ?>auth/logout" aria-label="Déconnexion" class="w-10 h-10 rounded-2xl bg-white/80 border border-white flex items-center justify-center text-slate-700 shadow-sm hover:bg-white active:scale-95 transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
    </header>

    <!-- Contenu défilant -->
    <main class="flex-1 overflow-y-auto px-5 pt-8 pb-6 space-y-4 no-scrollbar">

        <!-- Carte principale : identité + statistiques -->
        <section class="bg-white/90 backdrop-blur-md rounded-3xl p-5 pt-11 shadow-soft-card border border-white relative flex flex-col items-center text-center">
            <!-- Avatar (initiales, faute de photo en base) -->
            <div class="absolute -top-9 left-1/2 -translate-x-1/2 w-[72px] h-[72px] rounded-full p-1 bg-white shadow-md">
                <div class="w-full h-full rounded-full bg-gradient-to-br from-teal-500 to-teal-700 text-white flex items-center justify-center text-xl font-extrabold ring-2 ring-teal-200">
                    <?= htmlspecialchars($initials) ?>
                </div>
            </div>

            <!-- Double compteur -->
            <div class="w-full bg-[#E0F7F4] rounded-2xl p-3 flex justify-around items-center mb-4">
                <div class="text-center">
                    <div class="text-lg font-extrabold text-slate-900"><?= (int) $stat1['value'] ?></div>
                    <p class="text-[10px] text-slate-600 font-medium"><?= htmlspecialchars($stat1['label']) ?></p>
                </div>
                <div class="w-px h-8 bg-teal-200"></div>
                <div class="text-center">
                    <div class="text-lg font-extrabold text-slate-900"><?= (int) $stat2['value'] ?></div>
                    <p class="text-[10px] text-slate-600 font-medium"><?= htmlspecialchars($stat2['label']) ?></p>
                </div>
            </div>

            <h2 class="text-lg font-extrabold text-slate-900"><?= htmlspecialchars($fullName) ?></h2>

            <!-- Coordonnées réelles (e-mail / téléphone) au lieu de ville inexistante en base -->
            <div class="mt-1 flex items-center gap-1.5 text-[11px] font-bold text-teal-800 bg-teal-50/80 px-3 py-1 rounded-full border border-teal-100">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 8l9 6 9-6M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                <span class="truncate max-w-[180px]"><?= htmlspecialchars($user['email'] ?? '') ?></span>
                <span class="text-teal-400">•</span>
                <span><?= htmlspecialchars($roleBadge) ?></span>
            </div>
            <?php if (!empty($user['phone'])): ?>
            <p class="mt-1.5 text-[11px] text-slate-500 font-medium">☎ <?= htmlspecialchars($user['phone']) ?></p>
            <?php endif; ?>

            <div class="mt-2 inline-flex items-center gap-1 text-[10px] font-bold text-teal-700 bg-teal-100/60 px-2.5 py-0.5 rounded-full">
                <span class="w-1.5 h-1.5 rounded-full bg-teal-500"></span> Compte vérifié
            </div>
        </section>

        <!-- Carte Dossier médical -->
        <a href="<?= BASE_URL . ltrim($dossierLink, '/') ?>" class="block bg-white/90 backdrop-blur-md rounded-2xl p-3.5 shadow-soft-card border border-white active:scale-[0.99] transition">
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-teal-100 text-teal-700 flex items-center justify-center">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-xs font-bold text-slate-800"><?= $isMedecin ? 'Dossier médical' : 'Messages de mon médecin' ?></h3>
                        <p class="text-[10px] text-slate-500 font-medium">
                            <?= $isMedecin ? "Fiche Doza & suivi clinique" : "Mes alertes" ?>
                            <?php if (!$isMedecin && !empty($unread)): ?>
                                <span class="ml-1 inline-flex items-center justify-center min-w-[16px] h-4 px-1 rounded-full bg-rose-500 text-white text-[9px] font-bold align-middle"><?= (int) $unread > 9 ? '9+' : (int) $unread ?></span>
                            <?php endif; ?>
                        </p>
                    </div>
                </div>
                <span class="bg-teal-700 text-white text-[11px] font-bold px-3.5 py-1.5 rounded-xl shadow-sm">Voir</span>
            </div>
        </a>

        <!-- Espace & déconnexion -->
        <div class="space-y-1.5">
            <span class="text-[9px] uppercase tracking-wider font-extrabold text-slate-500 px-1"><?= $isMedecin ? 'Espace médecin' : 'Espace patient' ?></span>
            <a href="<?= BASE_URL ?>auth/logout" class="block bg-white/90 backdrop-blur-md rounded-2xl p-3.5 shadow-soft-card border border-white hover:bg-rose-50/50 transition group">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <div class="w-9 h-9 rounded-xl bg-rose-100/80 text-rose-600 flex items-center justify-center">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        </div>
                        <div class="text-left">
                            <h4 class="text-xs font-bold text-rose-700">Déconnexion</h4>
                            <p class="text-[10px] text-slate-400">Fermer la session sécurisée</p>
                        </div>
                    </div>
                    <svg class="w-4 h-4 text-slate-300 group-hover:text-rose-500 transition" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 5l7 7-7 7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
            </a>
        </div>

        <!-- Assistance 24/7 -->
        <div class="bg-teal-800 text-white rounded-2xl p-3.5 shadow-md flex items-center justify-between">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-teal-700/80 flex items-center justify-center text-teal-100">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M18.364 5.636a9 9 0 010 12.728M15.536 8.464a5 5 0 010 7.072M21 12a9 9 0 11-18 0 9 9 0 0118 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
                <div>
                    <h4 class="text-xs font-bold leading-tight">Assistance 24/7</h4>
                    <p class="text-[10px] text-teal-200/80"><?= $isMedecin ? "Support clinique de garde" : "Infirmière de garde disponible" ?></p>
                </div>
            </div>
            <a href="tel:+213000000000" aria-label="Appeler l'assistance" class="w-8 h-8 rounded-full bg-white text-teal-800 flex items-center justify-center shadow-sm active:scale-95 transition">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2a1 1 0 011.02-.24c1.12.37 2.33.57 3.57.57a1 1 0 011 1V20a1 1 0 01-1 1A17 17 0 013 4a1 1 0 011-1h3.5a1 1 0 011 1c0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"></path></svg>
            </a>
        </div>

        <?php if (!$isMedecin): ?>
        <!-- Rappel : le patient ne consulte que les messages de son médecin (jamais les résultats bruts). -->
        <a href="<?= BASE_URL ?>notifications" class="block text-center text-[11px] font-semibold text-teal-700 py-2">Voir toutes mes alertes →</a>
        <?php endif; ?>
    </main>

    <!-- Barre de navigation inférieure (onglet Profil actif) -->
    <nav class="shrink-0 bg-white/90 backdrop-blur-md border-t border-slate-100 px-8 py-2.5 flex items-center justify-between">
        <a href="<?= BASE_URL . ($isMedecin ? 'personnel' : '') ?>" class="flex flex-col items-center text-slate-400 hover:text-teal-700 transition">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[9px] font-medium">Accueil</span>
        </a>
        <a href="<?= BASE_URL ?><?= $isMedecin ? 'patient/select?next=doza' : 'doctors' ?>" class="flex flex-col items-center text-slate-400 hover:text-teal-700 transition">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M19 21v-2a4 4 0 00-4-4H9a4 4 0 00-4 4v2M16 7a4 4 0 11-8 0 4 4 0 018 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[9px] font-medium"><?= $isMedecin ? 'Évaluer' : 'Médecins' ?></span>
        </a>
        <a href="<?= BASE_URL ?>profile" class="flex flex-col items-center text-teal-700">
            <svg class="w-5 h-5 mb-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path></svg>
            <span class="text-[9px] font-bold">Profil</span>
        </a>
    </nav>
</div>
