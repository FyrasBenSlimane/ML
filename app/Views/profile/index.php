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

    <!-- ===== Bandeau d'en-tête dégradé (retour · titre+ID · déconnexion) ===== -->
    <div class="shrink-0 relative overflow-hidden h-[128px] bg-gradient-to-br from-[#16b5a6] via-[#0d9488] to-[#0f766e]">
        <div class="pointer-events-none absolute -top-10 -right-8 w-40 h-40 rounded-full bg-white/15 blur-2xl"></div>
        <div class="pointer-events-none absolute -bottom-16 -left-8 w-48 h-48 rounded-full bg-emerald-200/25 blur-3xl"></div>
        <svg class="pointer-events-none absolute left-1/2 -translate-x-1/2 top-10 w-52 h-14 text-white/10" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 140 36"><path d="M0 18h26l6-12 10 24 8-18 6 9 7-3h71" stroke-linecap="round" stroke-linejoin="round"></path></svg>

        <div class="relative z-10 px-5 pt-4 flex items-center justify-between">
            <a href="<?= BASE_URL . $backLink ?>" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur border border-white/30 flex items-center justify-center text-white hover:bg-white/30 active:scale-95 transition">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </a>
            <div class="text-center">
                <h1 class="text-base font-extrabold text-white leading-tight">Mon profil</h1>
                <span class="inline-block mt-1 text-[10px] font-bold text-white bg-white/20 border border-white/25 px-2.5 py-0.5 rounded-full tracking-tight"><?= htmlspecialchars($idLabel) ?> : #<?= htmlspecialchars($idValue) ?></span>
            </div>
            <a href="<?= BASE_URL ?>auth/logout" aria-label="Déconnexion" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur border border-white/30 flex items-center justify-center text-white hover:bg-white/30 active:scale-95 transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </a>
        </div>
    </div>

    <!-- Contenu défilant -->
    <main class="flex-1 overflow-y-auto px-5 pb-6 space-y-4 no-scrollbar">

        <!-- Carte principale : identité + statistiques (remontée sur le bandeau) -->
        <section class="-mt-14 bg-white rounded-3xl pt-14 pb-5 px-5 shadow-soft-card border border-white relative flex flex-col items-center text-center">
            <!-- Avatar flottant : halo + anneau + pastille en ligne -->
            <div class="absolute -top-10 left-1/2 -translate-x-1/2">
                <div class="relative">
                    <div class="absolute -inset-2 rounded-full bg-gradient-to-tr from-teal-300/70 to-teal-500/70 blur-md"></div>
                    <div class="relative w-[88px] h-[88px] rounded-full p-[3px] bg-white shadow-xl">
                        <div class="w-full h-full rounded-full bg-gradient-to-br from-teal-500 to-teal-700 text-white flex items-center justify-center text-2xl font-extrabold tracking-tight"><?= htmlspecialchars($initials) ?></div>
                    </div>
                    <span class="absolute bottom-1.5 right-1.5 w-4 h-4 rounded-full bg-emerald-400 ring-[3px] ring-white"></span>
                </div>
            </div>

            <!-- Nom + badge rôle (vérifié) -->
            <h2 class="text-xl font-extrabold text-slate-900 tracking-tight"><?= htmlspecialchars($fullName) ?></h2>
            <div class="mt-1.5 inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-1 rounded-full bg-gradient-to-r from-teal-50 to-teal-100 text-teal-800 border border-teal-200/60">
                <span class="w-1.5 h-1.5 rounded-full bg-teal-500"></span>
                <?= htmlspecialchars($roleBadge) ?>
                <svg class="w-3.5 h-3.5 text-teal-600" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l2.4 1.8 3 .2.9 2.8 2.4 1.8-1 2.8 1 2.8-2.4 1.8-.9 2.8-3 .2L12 22l-2.4-1.8-3-.2-.9-2.8L3.3 15.4l1-2.8-1-2.8 2.4-1.8.9-2.8 3-.2L12 2zm-1.2 13.2l5-5-1.4-1.4-3.6 3.6-1.6-1.6-1.4 1.4 3 3z"></path></svg>
            </div>

            <!-- Compteurs : deux tuiles à icône -->
            <div class="w-full grid grid-cols-2 gap-3 mt-4">
                <div class="rounded-2xl bg-gradient-to-br from-[#E8FAF6] to-[#D2F0EA] p-3.5 border border-white flex flex-col items-center">
                    <div class="w-9 h-9 rounded-xl bg-white text-teal-700 flex items-center justify-center mb-1.5 shadow-sm">
                        <?php if ($isMedecin): ?>
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        <?php else: ?>
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 12c0 4.418-4.03 8-9 8a9.9 9.9 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        <?php endif; ?>
                    </div>
                    <div class="text-2xl font-extrabold text-slate-900 leading-none"><?= (int) $stat1['value'] ?></div>
                    <p class="text-[10px] text-slate-600 font-semibold mt-1"><?= htmlspecialchars($stat1['label']) ?></p>
                </div>
                <div class="rounded-2xl bg-gradient-to-br from-[#E8FAF6] to-[#D2F0EA] p-3.5 border border-white flex flex-col items-center">
                    <div class="w-9 h-9 rounded-xl bg-white text-teal-700 flex items-center justify-center mb-1.5 shadow-sm">
                        <?php if ($isMedecin): ?>
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M13 10V3L4 14h7v7l9-11h-7z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        <?php else: ?>
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        <?php endif; ?>
                    </div>
                    <div class="text-2xl font-extrabold text-slate-900 leading-none"><?= (int) $stat2['value'] ?></div>
                    <p class="text-[10px] text-slate-600 font-semibold mt-1"><?= htmlspecialchars($stat2['label']) ?></p>
                </div>
            </div>

            <!-- Contact (coordonnées réelles) -->
            <div class="w-full mt-4 rounded-2xl bg-slate-50/80 border border-white px-3.5 py-2.5 space-y-2 text-left">
                <div class="flex items-center gap-2 text-[11px] text-slate-600 font-medium">
                    <span class="w-6 h-6 rounded-lg bg-teal-50 text-teal-600 flex items-center justify-center shrink-0">
                        <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 8l9 6 9-6M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                    <span class="truncate"><?= htmlspecialchars($user['email'] ?? '') ?></span>
                </div>
                <?php if (!empty($user['phone'])): ?>
                <div class="flex items-center gap-2 text-[11px] text-slate-600 font-medium">
                    <span class="w-6 h-6 rounded-lg bg-teal-50 text-teal-600 flex items-center justify-center shrink-0">
                        <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><path d="M6.62 10.79a15.053 15.053 0 006.59 6.59l2.2-2.2a1 1 0 011.02-.24c1.12.37 2.33.57 3.57.57a1 1 0 011 1V20a1 1 0 01-1 1A17 17 0 013 4a1 1 0 011-1h3.5a1 1 0 011 1c0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"></path></svg>
                    </span>
                    <span><?= htmlspecialchars($user['phone']) ?></span>
                </div>
                <?php endif; ?>
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
