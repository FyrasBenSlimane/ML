<?php
/**
 * Fiche patient d'un modèle IA (Doza / Sora) — vue PATIENT.
 * Montre le BUT du modèle + les ALERTES envoyées par le médecin pour ce modèle.
 * Jamais de résultat brut ni de score : le patient ne voit que les messages de son médecin.
 */
$styles = [
    'info'      => ['dot' => 'bg-teal-500',  'chip' => 'bg-teal-50 text-teal-700',   'label' => 'Information'],
    'attention' => ['dot' => 'bg-amber-500', 'chip' => 'bg-amber-50 text-amber-700', 'label' => 'À regarder'],
    'important' => ['dot' => 'bg-rose-500',  'chip' => 'bg-rose-50 text-rose-700',   'label' => 'Important'],
];
$mois = ['', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
$fmt  = function ($dt) use ($mois) {
    $ts = strtotime((string) $dt);
    return $ts ? ((int) date('j', $ts) . ' ' . $mois[(int) date('n', $ts)] . ' ' . date('H:i', $ts)) : '';
};
?>
<!-- ============ FICHE MODÈLE (vue patient) ============ -->
<main class="relative w-full max-w-[400px] h-[844px] bg-gradient-to-b from-teal-600 via-teal-500 to-teal-400 overflow-hidden flex flex-col shadow-2xl sm:rounded-[48px] border-0 sm:border-8 border-slate-900">

    <div class="pointer-events-none absolute -top-10 -right-16 w-64 h-64 rounded-full bg-teal-300/40 blur-3xl"></div>
    <div class="pointer-events-none absolute top-24 -left-20 w-56 h-56 rounded-full bg-emerald-200/25 blur-3xl"></div>

    <!-- Navigation supérieure -->
    <nav class="px-5 pt-5 pb-2 flex justify-between items-center z-20 shrink-0">
        <a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white border border-white/25 active:scale-95 transition">
            <svg class="w-5 h-5 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <div class="flex items-center gap-1.5 px-3 py-1 bg-white/15 backdrop-blur-md rounded-full border border-white/20">
            <span class="w-2 h-2 rounded-full bg-emerald-300 animate-pulse"></span>
            <span class="text-[11px] font-semibold text-white tracking-wide uppercase"><?= htmlspecialchars($model['badge']) ?></span>
        </div>
        <span class="w-10 h-10"></span>
    </nav>

    <!-- Identité du modèle -->
    <section class="flex flex-col items-center px-6 pt-1 pb-4 text-center z-10 shrink-0">
        <div class="relative mb-2.5">
            <div class="absolute -inset-1.5 bg-gradient-to-tr from-teal-200 to-white rounded-3xl opacity-60 blur-md"></div>
            <div class="relative w-24 h-24 rounded-3xl overflow-hidden border-2 border-white/80 shadow-lg bg-teal-800">
                <img alt="<?= htmlspecialchars($model['name']) ?>" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/<?= $model['img'] ?>">
            </div>
        </div>
        <div class="flex items-center justify-center space-x-1.5 mt-1">
            <h1 class="text-xl font-bold text-white tracking-tight"><?= htmlspecialchars($model['name']) ?></h1>
            <svg class="w-4 h-4 text-teal-100 fill-current" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"></path></svg>
        </div>
        <p class="text-xs text-teal-50 font-medium mt-0.5"><?= htmlspecialchars($model['spec']) ?></p>
    </section>

    <!-- Feuille blanche -->
    <div class="flex-1 bg-[#F5FCFA] rounded-t-[36px] shadow-2xl flex flex-col overflow-hidden relative z-20 border-t border-white/60">
        <div class="flex-1 overflow-y-auto px-5 pt-5 pb-28 no-scrollbar space-y-4">

            <!-- But du modèle -->
            <section class="bg-white rounded-2xl p-4 shadow-[0_8px_24px_-6px_rgba(13,148,136,0.08)] border border-teal-800/5">
                <div class="flex items-center gap-2 mb-1.5">
                    <div class="w-8 h-8 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </div>
                    <h2 class="text-sm font-bold text-slate-800">À quoi sert <?= htmlspecialchars($model['name']) ?> ?</h2>
                </div>
                <p class="text-[12.5px] text-slate-600 leading-relaxed"><?= htmlspecialchars($model['purpose']) ?></p>
            </section>

            <!-- Alertes du médecin pour ce modèle -->
            <div class="flex items-center justify-between px-1">
                <h2 class="text-sm font-bold text-slate-700">Mes alertes de <?= htmlspecialchars($model['name']) ?></h2>
                <?php if (!empty($alerts)): ?><span class="text-[10px] font-bold text-teal-700 bg-teal-50 px-2 py-0.5 rounded-full"><?= count($alerts) ?></span><?php endif; ?>
            </div>

            <?php if (empty($alerts)): ?>
                <div class="text-center py-10 px-4">
                    <div class="w-12 h-12 mx-auto rounded-2xl bg-teal-50 text-teal-500 flex items-center justify-center mb-3">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 00-4-5.7V5a2 2 0 10-4 0v.3C7.7 6.2 6 8.4 6 11v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </div>
                    <p class="text-xs font-semibold text-slate-500">Aucune alerte pour le moment</p>
                    <p class="text-[11px] text-slate-400 mt-1 leading-relaxed">Les messages de votre médecin liés à <?= htmlspecialchars($model['name']) ?> apparaîtront ici.</p>
                </div>
            <?php else: ?>
                <?php foreach ($alerts as $n): ?>
                    <?php $s = $styles[$n->niveau] ?? $styles['info']; $unread = empty($n->read_at); $sender = trim(($n->sender_first ?? '') . ' ' . ($n->sender_last ?? '')); ?>
                    <article class="rounded-2xl p-4 bg-white shadow-[0_8px_24px_-6px_rgba(13,148,136,0.08)] border <?= $unread ? 'border-teal-200' : 'border-teal-800/5' ?>">
                        <div class="flex items-start justify-between gap-2">
                            <div class="flex items-center gap-2">
                                <span class="inline-flex items-center gap-1.5 text-[9px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full <?= $s['chip'] ?>">
                                    <span class="w-1.5 h-1.5 rounded-full <?= $s['dot'] ?>"></span><?= $s['label'] ?>
                                </span>
                                <?php if ($unread): ?><span class="text-[9px] font-bold text-teal-700">● Nouveau</span><?php endif; ?>
                            </div>
                            <span class="text-[10px] text-slate-400 shrink-0"><?= htmlspecialchars($fmt($n->created_at)) ?></span>
                        </div>
                        <h3 class="text-sm font-bold text-slate-800 mt-2"><?= htmlspecialchars($n->titre) ?></h3>
                        <p class="text-[12.5px] text-slate-600 leading-relaxed mt-1"><?= nl2br(htmlspecialchars($n->message)) ?></p>
                        <div class="flex items-center justify-between mt-3 pt-2.5 border-t border-slate-100">
                            <span class="text-[11px] text-slate-400"><?= $sender !== '' ? 'Dr ' . htmlspecialchars($sender) : 'Votre médecin' ?></span>
                            <?php if ($unread): ?>
                            <form method="post" action="<?= BASE_URL ?>notifications/read">
                                <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
                                <input type="hidden" name="id" value="<?= (int) $n->id ?>">
                                <button type="submit" class="text-[11px] font-bold text-teal-700 hover:text-teal-900 active:scale-95 transition">Marquer comme lu</button>
                            </form>
                            <?php else: ?>
                            <span class="text-[11px] font-medium text-slate-300">Lu</span>
                            <?php endif; ?>
                        </div>
                    </article>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>

    <!-- Barre de navigation flottante -->
    <nav class="absolute bottom-5 left-5 right-5 h-16 bg-white/95 backdrop-blur-md rounded-3xl shadow-[0_12px_32px_-4px_rgba(15,118,110,0.16)] flex items-center justify-around px-4 border border-teal-100/60 z-30">
        <a href="<?= BASE_URL ?>doctors" aria-label="Accueil" class="w-10 h-10 flex items-center justify-center text-slate-400 hover:text-teal-600 active:scale-90 transition">
            <svg class="w-6 h-6 stroke-[1.8]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <a href="<?= BASE_URL ?>notifications" aria-label="Mes alertes" class="w-12 h-12 -mt-4 bg-gradient-to-tr from-teal-600 to-teal-400 text-white rounded-2xl flex items-center justify-center shadow-[0_0_25px_rgba(45,212,191,0.45)] active:scale-95 transition">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 00-4-5.7V5a2 2 0 10-4 0v.3C7.7 6.2 6 8.4 6 11v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <a href="<?= BASE_URL ?>profile" aria-label="Profil" class="w-10 h-10 flex items-center justify-center text-slate-400 hover:text-teal-600 active:scale-90 transition">
            <svg class="w-6 h-6 fill-current" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path></svg>
        </a>
    </nav>

    <div class="absolute bottom-1 left-1/2 -translate-x-1/2 w-32 h-1 bg-slate-300 rounded-full z-40"></div>
</main>
