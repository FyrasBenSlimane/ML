<!-- ============ PORTAIL PERSONNEL ============ -->
<div class="relative w-full max-w-md min-h-screen flex flex-col pb-10 screen-ambient">

    <!-- Barre supérieure -->
    <header class="sticky top-0 z-40 px-6 pt-4 pb-3 flex justify-between items-center bg-white/40 backdrop-blur-md">
        <div>
            <p class="text-[11px] font-semibold text-teal-700/80 uppercase tracking-wide">Espace personnel</p>
            <h1 class="text-lg font-bold text-slate-800">Bonjour, <?= htmlspecialchars($user['first_name']) ?></h1>
        </div>
        <a href="<?= BASE_URL ?>auth/logout" class="flex items-center gap-1.5 px-3 py-2 rounded-2xl bg-white/80 border border-slate-200 text-slate-600 text-xs font-semibold hover:bg-white active:scale-95 transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            Déconnexion
        </a>
    </header>

    <main class="px-5 mt-4 space-y-4">
        <p class="text-[13.5px] text-slate-600 leading-relaxed px-1">
            Accédez aux outils d'aide à la décision pour les soignants.
        </p>

        <!-- Carte ReadmitGuard -->
        <a href="<?= htmlspecialchars($readmitUrl) ?>" target="_blank" rel="noopener"
           class="block rounded-3xl p-5 bg-white shadow-soft-card ring-1 ring-teal-300/40 hover:shadow-md active:scale-[0.99] transition">
            <div class="flex items-center gap-4">
                <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-700 flex items-center justify-center text-white shadow-inner">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
                <div class="flex-1 min-w-0">
                    <h2 class="text-base font-bold text-teal-darkText">ReadmitGuard</h2>
                    <p class="text-xs text-slate-500 mt-0.5">Prédiction du risque de réadmission à 30 jours</p>
                </div>
                <svg class="w-5 h-5 text-teal-600" fill="none" stroke="currentColor" stroke-width="2.4" viewBox="0 0 24 24"><path d="M9 5l7 7-7 7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </div>
            <p class="mt-3 text-[11.5px] text-slate-400">Ouvre l'application (nouvel onglet) ; vous êtes connecté automatiquement.</p>
        </a>

        <div class="flex items-start gap-2.5 px-3.5 py-2.5 rounded-2xl bg-amber-50/70 border border-amber-200/70">
            <svg class="w-4 h-4 text-amber-600 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L1 21h22L12 2zm0 5l7.5 13h-15L12 7zm-1 4v4h2v-4h-2zm0 5v2h2v-2h-2z"></path></svg>
            <p class="text-[12.5px] text-slate-600 leading-snug">Outils d'aide à la décision — ne remplacent pas le jugement clinique.</p>
        </div>
    </main>
</div>
