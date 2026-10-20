<!-- ============ MON PROFIL (patient) ============ -->
<div class="relative w-full max-w-md min-h-screen flex flex-col pb-10 screen-ambient">

    <header class="sticky top-0 z-40 px-6 pt-4 pb-3 flex justify-between items-center bg-white/40 backdrop-blur-md">
        <div class="flex items-center gap-3">
            <a href="<?= BASE_URL ?>doctors" class="w-10 h-10 rounded-2xl flex items-center justify-center text-slate-700 hover:bg-white/60 transition active:scale-95">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </a>
            <div>
                <p class="text-[11px] font-semibold text-teal-700/80 uppercase tracking-wide">Mon profil</p>
                <h1 class="text-lg font-bold text-slate-800"><?= htmlspecialchars(trim($user['first_name'] . ' ' . $user['last_name'])) ?></h1>
            </div>
        </div>
        <a href="<?= BASE_URL ?>auth/logout" class="flex items-center gap-1.5 px-3 py-2 rounded-2xl bg-white/80 border border-slate-200 text-slate-600 text-xs font-semibold hover:bg-white active:scale-95 transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            Déconnexion
        </a>
    </header>

    <main class="px-5 mt-4 space-y-5">
        <!-- Raccourcis -->
        <div class="grid grid-cols-2 gap-3">
            <a href="<?= BASE_URL ?>doza" class="rounded-2xl p-4 bg-white shadow-soft-card ring-1 ring-teal-200/50 active:scale-[0.98] transition">
                <p class="text-sm font-bold text-teal-darkText">Doza</p>
                <p class="text-[11px] text-slate-500 mt-0.5">Changement d'insuline</p>
            </a>
            <a href="<?= BASE_URL ?>sora" class="rounded-2xl p-4 bg-white shadow-soft-card ring-1 ring-teal-200/50 active:scale-[0.98] transition">
                <p class="text-sm font-bold text-teal-darkText">Sora</p>
                <p class="text-[11px] text-slate-500 mt-0.5">Profil de sortie</p>
            </a>
        </div>

        <!-- Historique Doza -->
        <section>
            <h2 class="text-sm font-bold text-slate-700 mb-2 px-1">Mes sessions Doza</h2>
            <?php if (empty($doza)): ?>
                <p class="text-[12.5px] text-slate-400 px-1">Aucune session pour l'instant.</p>
            <?php else: ?>
                <div class="space-y-2">
                    <?php foreach ($doza as $c): ?>
                    <div class="rounded-2xl p-3.5 bg-white/90 shadow-soft-card flex items-center justify-between">
                        <div class="min-w-0">
                            <p class="text-[13px] font-semibold text-slate-800 truncate"><?= htmlspecialchars($c->result) ?></p>
                            <p class="text-[11px] text-slate-400"><?= htmlspecialchars($this->formatDate($c->created_at)) ?> · <?= htmlspecialchars($c->tag) ?></p>
                        </div>
                        <span class="text-[12px] font-bold text-teal-700 shrink-0 ml-2"><?= (int) $c->probability ?> %</span>
                    </div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>
        </section>

        <!-- Historique Sora -->
        <section>
            <h2 class="text-sm font-bold text-slate-700 mb-2 px-1">Mes fiches Sora</h2>
            <?php if (empty($sora)): ?>
                <p class="text-[12.5px] text-slate-400 px-1">Aucune fiche pour l'instant.</p>
            <?php else: ?>
                <div class="space-y-2">
                    <?php foreach ($sora as $s): ?>
                    <div class="rounded-2xl p-3.5 bg-white/90 shadow-soft-card">
                        <p class="text-[13px] font-semibold text-slate-800"><?= htmlspecialchars($s->profil) ?></p>
                        <p class="text-[11px] text-slate-400 mt-0.5">
                            <?= htmlspecialchars($this->formatDate($s->created_at)) ?> ·
                            <?= htmlspecialchars($s->resultat_suivi) ?> ·
                            <?= htmlspecialchars($s->resultat_controle) ?>
                        </p>
                    </div>
                    <?php endforeach; ?>
                </div>
            <?php endif; ?>
        </section>
    </main>
</div>
