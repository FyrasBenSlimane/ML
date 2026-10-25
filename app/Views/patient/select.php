<?php
/**
 * Sélection du patient par le médecin avant une évaluation (Doza / Sora).
 * Le médecin saisit l'ID Patient (#PT-xxxxx) ; vérification en base côté serveur.
 */
$label = $next === 'sora' ? 'Sora' : 'Doza';
?>
<div class="relative w-full max-w-[400px] h-[844px] max-h-screen sm:max-h-[92vh] overflow-hidden flex flex-col bg-[#E7F6F3] shadow-2xl border-[8px] border-slate-800/80 sm:border-slate-700/60 sm:rounded-[44px] screen-ambient">

    <header class="shrink-0 px-5 pt-4 pb-3 flex items-center gap-3 bg-white/40 backdrop-blur-md">
        <a href="<?= BASE_URL ?>personnel" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/80 border border-white flex items-center justify-center text-slate-700 shadow-sm hover:bg-white active:scale-95 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <div>
            <p class="text-[10px] font-bold text-teal-700 uppercase tracking-wide">Évaluation <?= htmlspecialchars($label) ?></p>
            <h1 class="text-base font-extrabold text-slate-900 leading-tight">Sélectionner le patient</h1>
        </div>
    </header>

    <main class="flex-1 overflow-y-auto px-5 pt-6 pb-6 space-y-4 no-scrollbar">

        <div class="flex flex-col items-center text-center">
            <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-700 text-white flex items-center justify-center shadow-md mb-3">
                <svg class="w-8 h-8" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 9a2 2 0 100-4 2 2 0 000 4zm0 0c1.3 0 2.4.8 2.8 2M9 15a3 3 0 00-2.8 2" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </div>
            <p class="text-[12.5px] text-slate-600 leading-relaxed max-w-[280px]">
                Saisissez l'<span class="font-semibold text-slate-800">ID Patient</span> (affiché sur le profil du patient,
                au format <span class="font-mono font-semibold">#PT-00000</span>) pour lancer une évaluation en son nom.
            </p>
        </div>

        <?php if (!empty($errors['global'])): ?>
            <div class="flex items-center gap-2 px-3 py-2.5 rounded-2xl bg-rose-100 text-rose-700 text-xs font-semibold">
                <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"></circle><path d="M12 8v4m0 4h.01" stroke-linecap="round"></path></svg>
                <span><?= htmlspecialchars($errors['global']) ?></span>
            </div>
        <?php endif; ?>

        <?php if (!empty($current)): ?>
            <div class="flex items-center justify-between gap-2 px-3.5 py-2.5 rounded-2xl bg-teal-50 border border-teal-200/70">
                <div class="min-w-0">
                    <p class="text-[10px] font-bold text-teal-700 uppercase tracking-wide">Patient actuel</p>
                    <p class="text-[13px] font-bold text-slate-800 truncate"><?= htmlspecialchars($current['name']) ?> · #<?= htmlspecialchars($current['code']) ?></p>
                </div>
                <a href="<?= BASE_URL ?><?= htmlspecialchars($next) ?>" class="shrink-0 bg-teal-700 text-white text-[11px] font-bold px-3 py-1.5 rounded-xl shadow-sm">Continuer</a>
            </div>
        <?php endif; ?>

        <form method="post" action="<?= BASE_URL ?>patient/select" class="space-y-2.5">
            <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
            <input type="hidden" name="next" value="<?= htmlspecialchars($next) ?>">
            <label for="code" class="block text-[11px] font-semibold text-slate-600 ml-1">ID Patient</label>
            <div class="flex items-center bg-white rounded-2xl px-4 py-3 shadow-sm border border-white ring-1 ring-teal-100 focus-within:ring-teal-400 transition">
                <span class="text-teal-700 font-bold mr-1.5">#</span>
                <input id="code" name="code" type="text" autocomplete="off" autofocus
                       value="<?= htmlspecialchars($old['code']) ?>" placeholder="PT-00000"
                       class="w-full bg-transparent text-sm font-semibold text-slate-800 placeholder-slate-300 focus:outline-none uppercase">
            </div>
            <?php if (!empty($errors['code'])): ?><p class="text-[11px] text-rose-600 font-semibold ml-1"><?= htmlspecialchars($errors['code']) ?></p><?php endif; ?>

            <button type="submit" class="w-full mt-1 py-3 rounded-2xl bg-gradient-to-r from-[#0e9686] to-[#087d70] text-white font-bold text-sm shadow-[0_10px_20px_-3px_rgba(10,138,124,0.42)] active:scale-[0.99] transition flex items-center justify-center gap-2">
                Vérifier &amp; continuer
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.4" viewBox="0 0 24 24"><path d="M14 5l7 7m0 0l-7 7m7-7H3" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </button>
        </form>

        <div class="flex items-start gap-2.5 px-3.5 py-2.5 rounded-2xl bg-amber-50/70 border border-amber-200/70">
            <svg class="w-4 h-4 text-amber-600 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L1 21h22L12 2zm0 5l7.5 13h-15L12 7zm-1 4v4h2v-4h-2zm0 5v2h2v-2h-2z"></path></svg>
            <p class="text-[12px] text-slate-600 leading-snug">Le patient ne voit jamais le résultat du modèle. Vous lui enverrez une alerte adaptée après l'évaluation.</p>
        </div>
    </main>
</div>
