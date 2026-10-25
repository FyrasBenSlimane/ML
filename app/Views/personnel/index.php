<?php
/**
 * Accueil médecin (rôle personnel) — maquette « Doza Santé ».
 * CTA « Lancer une évaluation » + grille Doza / Sora / ReadmitGuard / médecins.
 */
?>
<!-- ============ ACCUEIL MÉDECIN ============ -->
<div class="relative w-full max-w-[400px] h-[844px] max-h-screen sm:max-h-[92vh] overflow-hidden flex flex-col bg-[#E7F6F3] shadow-2xl border-[8px] border-slate-800/80 sm:border-slate-700/60 sm:rounded-[44px] screen-ambient">

    <!-- Barre supérieure : marque + déconnexion -->
    <header class="shrink-0 px-5 pt-4 pb-2 flex items-center justify-between bg-white/40 backdrop-blur-md">
        <div class="flex items-center gap-2">
            <div class="w-8 h-8 rounded-xl bg-teal-500/15 border border-teal-500/20 flex items-center justify-center text-teal-600 shadow-sm">
                <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"></path></svg>
            </div>
            <div>
                <span class="block text-[9px] uppercase tracking-wider font-extrabold text-teal-800">Doza Santé</span>
                <span class="block text-sm font-extrabold text-slate-800 leading-none">Espace médecin</span>
            </div>
        </div>
        <a href="<?= BASE_URL ?>auth/logout" aria-label="Déconnexion" class="w-9 h-9 rounded-full bg-white/80 border border-white flex items-center justify-center text-slate-600 shadow-sm hover:bg-white active:scale-95 transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
    </header>

    <!-- Contenu défilant -->
    <main class="flex-1 overflow-y-auto px-5 pt-2 pb-6 space-y-4 no-scrollbar">

        <!-- Salutation -->
        <div class="px-1">
            <h1 class="text-lg font-extrabold text-slate-900 leading-tight">Bonjour, Dr <?= htmlspecialchars($user['first_name']) ?> !</h1>
            <p class="text-[11px] text-slate-500 font-medium">Vos outils d'aide à la décision clinique</p>
        </div>

        <!-- Recherche -->
        <div class="flex items-center bg-white/90 backdrop-blur rounded-2xl px-3 py-2.5 shadow-sm border border-white">
            <svg class="w-4 h-4 text-slate-400 mr-2" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
            <input type="text" placeholder="Rechercher un outil, un médecin..." class="bg-transparent text-xs text-slate-700 placeholder-slate-400 w-full focus:outline-none font-medium">
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
            <a href="<?= BASE_URL ?>doctors" class="text-[10px] font-bold text-teal-700">Voir tout</a>
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
        <a href="<?= BASE_URL ?>doctors" class="flex flex-col items-center text-slate-400 hover:text-teal-700 transition">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M19 21v-2a4 4 0 00-4-4H9a4 4 0 00-4 4v2M16 7a4 4 0 11-8 0 4 4 0 018 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[9px] font-medium">Médecins</span>
        </a>
        <a href="<?= BASE_URL ?>profile" class="flex flex-col items-center text-slate-400 hover:text-teal-700 transition">
            <svg class="w-5 h-5 mb-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path></svg>
            <span class="text-[9px] font-medium">Profil</span>
        </a>
    </nav>
</div>
