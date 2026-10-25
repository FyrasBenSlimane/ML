<?php
/**
 * Accueil médecin (rôle personnel) — maquette « MAAK ».
 * CTA « Lancer une évaluation » + grille Doza / Sora / ReadmitGuard / médecins.
 */
$ini = strtoupper(mb_substr($user['first_name'] ?? '', 0, 1) . mb_substr($user['last_name'] ?? '', 0, 1));
?>
<!-- ============ ACCUEIL MÉDECIN ============ -->
<div class="relative w-full max-w-[400px] h-[844px] max-h-screen sm:max-h-[92vh] overflow-hidden flex flex-col bg-[#E7F6F3] shadow-2xl border-[8px] border-slate-800/80 sm:border-slate-700/60 sm:rounded-[44px] screen-ambient">

    <!-- ===== Bandeau d'en-tête dégradé (marque + salutation + avatar) ===== -->
    <div class="shrink-0 relative overflow-hidden px-5 pt-5 pb-11 bg-gradient-to-br from-[#16b5a6] via-[#0d9488] to-[#0f766e]">
        <!-- Lueurs & onde cardiaque décoratives -->
        <div class="pointer-events-none absolute -top-12 -right-10 w-44 h-44 rounded-full bg-white/15 blur-2xl"></div>
        <div class="pointer-events-none absolute -bottom-16 -left-10 w-48 h-48 rounded-full bg-emerald-200/25 blur-3xl"></div>
        <svg class="pointer-events-none absolute right-4 bottom-6 w-40 h-16 text-white/10" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 120 40"><path d="M0 20h22l6-13 10 26 8-20 6 10 6-3h56" stroke-linecap="round" stroke-linejoin="round"></path></svg>

        <!-- Marque + déconnexion -->
        <div class="relative z-10 flex items-center justify-between">
            <div class="flex items-center gap-2">
                <div class="w-9 h-9 rounded-xl overflow-hidden border border-white/40 shadow-sm">
                    <img src="<?= ASSETS_URL ?>/img/doctor5.jpg" alt="MAAK" class="w-full h-full object-cover object-top">
                </div>
                <div>
                    <span class="block text-[9px] uppercase tracking-[0.18em] font-extrabold text-white/80">MAAK</span>
                    <span class="block text-sm font-extrabold text-white leading-none">Espace médecin</span>
                </div>
            </div>
            <a href="<?= BASE_URL ?>auth/logout" aria-label="Déconnexion" class="w-9 h-9 rounded-full bg-white/20 backdrop-blur border border-white/30 flex items-center justify-center text-white hover:bg-white/30 active:scale-95 transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </a>
        </div>

        <!-- Salutation + avatar -->
        <div class="relative z-10 mt-5 flex items-end justify-between">
            <div class="min-w-0">
                <h1 class="text-[22px] font-extrabold text-white leading-tight tracking-tight">Bonjour, Dr <?= htmlspecialchars($user['first_name']) ?> !</h1>
                <p class="text-[11px] text-teal-50/90 font-medium mt-0.5">Vos outils d'aide à la décision clinique</p>
            </div>
            <div class="shrink-0 w-12 h-12 rounded-2xl bg-white/90 text-teal-700 flex items-center justify-center text-base font-extrabold shadow-lg ring-2 ring-white/60">
                <?= htmlspecialchars($ini) ?>
            </div>
        </div>
    </div>

    <!-- Contenu défilant -->
    <main class="flex-1 overflow-y-auto px-5 pb-6 space-y-4 no-scrollbar">

        <!-- Recherche (flottante, remontée sur le bandeau) -->
        <div class="-mt-6 relative z-20 flex items-center gap-2">
            <div class="flex-1 flex items-center bg-white rounded-2xl px-3.5 py-3 shadow-[0_12px_28px_-10px_rgba(13,148,136,0.35)] border border-white">
                <svg class="w-4 h-4 text-teal-500 mr-2" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                <input type="text" placeholder="Rechercher un outil, un médecin..." class="bg-transparent text-xs text-slate-700 placeholder-slate-400 w-full focus:outline-none font-medium">
            </div>
            <button type="button" aria-label="Filtres" class="w-11 h-11 rounded-2xl bg-gradient-to-br from-teal-600 to-teal-700 text-white flex items-center justify-center shadow-[0_10px_20px_-6px_rgba(13,148,136,0.6)] active:scale-95 transition">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 5h18M6 12h12M10 19h4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </button>
        </div>

        <!-- CTA : lancer une évaluation -->
        <a href="<?= BASE_URL ?>doza" class="block rounded-3xl p-4 bg-white/90 backdrop-blur-md border border-white shadow-soft-card active:scale-[0.99] transition">
            <div class="flex items-center justify-between">
                <div class="max-w-[64%]">
                    <span class="inline-block bg-teal-50 text-teal-700 text-[9px] font-bold px-2 py-0.5 rounded-full mb-1">✦ Évaluation IA</span>
                    <h2 class="text-sm font-extrabold text-slate-900 leading-tight">Lancer une évaluation</h2>
                    <p class="text-[10px] text-slate-500 mt-1 mb-2.5">Détection du changement d'insuline (Doza).</p>
                    <span class="inline-flex items-center gap-1 bg-teal-800 text-white text-[11px] font-semibold px-3 py-1.5 rounded-xl shadow-sm">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M13 10V3L4 14h7v7l9-11h-7z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        Commencer
                    </span>
                </div>
                <div class="w-16 h-16 rounded-full bg-teal-100/70 border border-teal-200/50 flex items-center justify-center text-teal-700 shadow-inner">
                    <svg class="w-8 h-8" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 12h3l2 5 4-14 2 7 2-3h5" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
            </div>
        </a>

        <!-- Titre section -->
        <div class="flex justify-between items-center pt-1">
            <h3 class="text-xs font-extrabold text-slate-900">Outils & médecins</h3>
            <a href="<?= BASE_URL ?>patient/select?next=doza" class="text-[10px] font-bold text-teal-700">Évaluer un patient</a>
        </div>

        <!-- Grille : Doza · Sora · ReadmitGuard · médecins -->
        <div class="grid grid-cols-2 gap-3">

            <!-- Doza -->
            <a href="<?= BASE_URL ?>profile/doza" class="bg-white rounded-2xl p-2.5 shadow-soft-card ring-1 ring-teal-100/70 active:scale-[0.98] transition flex flex-col">
                <div class="relative w-full aspect-square rounded-xl overflow-hidden bg-teal-50 mb-2">
                    <img src="<?= ASSETS_URL ?>/img/doctor5.jpg" alt="Doza" class="w-full h-full object-cover object-top">
                    <span class="absolute bottom-1 left-1 bg-teal-700/90 text-white px-1.5 py-0.5 rounded-md text-[8px] font-bold">IA</span>
                </div>
                <h4 class="text-xs font-bold text-slate-800 truncate">Doza</h4>
                <p class="text-[9px] text-slate-400 truncate">Changement d'insuline</p>
            </a>

            <!-- Sora -->
            <a href="<?= BASE_URL ?>profile/sora" class="bg-white rounded-2xl p-2.5 shadow-soft-card ring-1 ring-teal-100/70 active:scale-[0.98] transition flex flex-col">
                <div class="relative w-full aspect-square rounded-xl overflow-hidden bg-rose-50 mb-2">
                    <img src="<?= ASSETS_URL ?>/img/doctor6.jpg" alt="Sora" class="w-full h-full object-cover object-top">
                    <span class="absolute bottom-1 left-1 bg-teal-700/90 text-white px-1.5 py-0.5 rounded-md text-[8px] font-bold">IA</span>
                </div>
                <h4 class="text-xs font-bold text-slate-800 truncate">Sora</h4>
                <p class="text-[9px] text-slate-400 truncate">Profil de sortie</p>
            </a>

            <!-- ReadmitGuard (nouvel onglet) -->
            <a href="<?= htmlspecialchars($readmitUrl) ?>" target="_blank" rel="noopener" class="bg-white rounded-2xl p-2.5 shadow-soft-card ring-1 ring-teal-100/70 active:scale-[0.98] transition flex flex-col">
                <div class="relative w-full aspect-square rounded-xl overflow-hidden bg-gradient-to-br from-teal-500 to-teal-700 text-white flex items-center justify-center mb-2">
                    <svg class="w-9 h-9" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6l7-3z" stroke-linecap="round" stroke-linejoin="round"></path><path d="M9 12l2 2 4-4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    <span class="absolute top-1 right-1 bg-white/85 text-teal-700 px-1.5 py-0.5 rounded-md text-[8px] font-bold">↗</span>
                </div>
                <h4 class="text-xs font-bold text-slate-800 truncate">ReadmitGuard</h4>
                <p class="text-[9px] text-slate-400 truncate">Réadmission 30j · onglet</p>
            </a>

            <!-- Médecins existants (fiche de profil au clic) -->
            <?php foreach ($doctors as $doc): ?>
            <a href="<?= BASE_URL . $doc['link'] ?>" class="bg-white rounded-2xl p-2.5 shadow-soft-card ring-1 ring-teal-100/70 active:scale-[0.98] transition flex flex-col">
                <div class="relative w-full aspect-square rounded-xl overflow-hidden <?= $doc['bg'] ?? 'bg-teal-50' ?> mb-2">
                    <img src="<?= ASSETS_URL ?>/img/<?= $doc['img'] ?>" alt="<?= htmlspecialchars($doc['name']) ?>" class="w-full h-full object-cover object-top">
                    <span class="absolute bottom-1 left-1 bg-white/90 backdrop-blur px-1.5 py-0.5 rounded-md text-[9px] font-bold text-amber-500 shadow-sm">★ <?= htmlspecialchars($doc['rating']) ?></span>
                </div>
                <h4 class="text-xs font-bold text-slate-800 truncate"><?= htmlspecialchars($doc['name']) ?></h4>
                <p class="text-[9px] text-slate-400 truncate"><?= htmlspecialchars($doc['spec']) ?></p>
            </a>
            <?php endforeach; ?>
        </div>

        <!-- Avertissement clinique -->
        <div class="flex items-start gap-2.5 px-3.5 py-2.5 rounded-2xl bg-amber-50/70 border border-amber-200/70">
            <svg class="w-4 h-4 text-amber-600 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L1 21h22L12 2zm0 5l7.5 13h-15L12 7zm-1 4v4h2v-4h-2zm0 5v2h2v-2h-2z"></path></svg>
            <p class="text-[12px] text-slate-600 leading-snug">Outils d'aide à la décision — ne remplacent pas le jugement clinique.</p>
        </div>
    </main>

    <!-- Barre de navigation inférieure (onglet Accueil actif) -->
    <nav class="shrink-0 bg-white/90 backdrop-blur-md border-t border-slate-100 px-8 py-2.5 flex items-center justify-between">
        <a href="<?= BASE_URL ?>personnel" class="flex flex-col items-center text-teal-700">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[9px] font-bold">Accueil</span>
        </a>
        <a href="<?= BASE_URL ?>patient/select?next=doza" class="flex flex-col items-center text-slate-400 hover:text-teal-700 transition">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[9px] font-medium">Évaluer</span>
        </a>
        <a href="<?= BASE_URL ?>profile" class="flex flex-col items-center text-slate-400 hover:text-teal-700 transition">
            <svg class="w-5 h-5 mb-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path></svg>
            <span class="text-[9px] font-medium">Profil</span>
        </a>
    </nav>
</div>
