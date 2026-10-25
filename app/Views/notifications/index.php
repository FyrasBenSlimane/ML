<?php
/**
 * Liste des alertes du patient connecté. Il ne voit que les siennes.
 */
$styles = [
    'info'      => ['dot' => 'bg-teal-500',   'chip' => 'bg-teal-50 text-teal-700',     'label' => 'Information'],
    'attention' => ['dot' => 'bg-amber-500',  'chip' => 'bg-amber-50 text-amber-700',   'label' => 'À regarder'],
    'important' => ['dot' => 'bg-rose-500',   'chip' => 'bg-rose-50 text-rose-700',     'label' => 'Important'],
];
$mois = ['', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
$fmt  = function ($dt) use ($mois) {
    $ts = strtotime((string) $dt);
    return $ts ? ((int) date('j', $ts) . ' ' . $mois[(int) date('n', $ts)] . ' ' . date('H:i', $ts)) : '';
};
?>
<div class="relative w-full max-w-[400px] h-[844px] max-h-screen sm:max-h-[92vh] overflow-hidden flex flex-col bg-[#E7F6F3] shadow-2xl border-[8px] border-slate-800/80 sm:border-slate-700/60 sm:rounded-[44px] screen-ambient">

    <header class="shrink-0 px-5 pt-4 pb-3 flex items-center gap-3 bg-white/40 backdrop-blur-md">
        <a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/80 border border-white flex items-center justify-center text-slate-700 shadow-sm hover:bg-white active:scale-95 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <div class="flex items-center gap-2">
            <svg class="w-5 h-5 text-teal-700" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 00-4-5.7V5a2 2 0 10-4 0v.3C7.7 6.2 6 8.4 6 11v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <h1 class="text-base font-extrabold text-slate-900 leading-tight">Mes alertes</h1>
        </div>
    </header>

    <main class="flex-1 overflow-y-auto px-5 pt-4 pb-6 space-y-3 no-scrollbar">
        <?php if (empty($items)): ?>
            <div class="text-center py-16 px-6">
                <div class="w-14 h-14 mx-auto rounded-2xl bg-teal-50 text-teal-500 flex items-center justify-center mb-3">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 00-4-5.7V5a2 2 0 10-4 0v.3C7.7 6.2 6 8.4 6 11v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
                <p class="text-sm font-semibold text-slate-500">Aucune alerte pour l'instant</p>
                <p class="text-[11px] text-slate-400 mt-1">Les messages de votre médecin apparaîtront ici.</p>
            </div>
        <?php else: ?>
            <?php foreach ($items as $n): ?>
                <?php
                $s       = $styles[$n->niveau] ?? $styles['info'];
                $unread  = empty($n->read_at);
                $sender  = trim(($n->sender_first ?? '') . ' ' . ($n->sender_last ?? ''));
                ?>
                <article class="rounded-2xl p-4 bg-white/95 shadow-soft-card border <?= $unread ? 'border-teal-200' : 'border-white' ?>">
                    <div class="flex items-start justify-between gap-2">
                        <div class="flex items-center gap-2">
                            <span class="inline-flex items-center gap-1.5 text-[9px] font-bold uppercase tracking-wide px-2 py-0.5 rounded-full <?= $s['chip'] ?>">
                                <span class="w-1.5 h-1.5 rounded-full <?= $s['dot'] ?>"></span><?= $s['label'] ?>
                            </span>
                            <?php if ($unread): ?><span class="text-[9px] font-bold text-teal-700">● Nouveau</span><?php endif; ?>
                        </div>
                        <span class="text-[10px] text-slate-400 shrink-0"><?= htmlspecialchars($fmt($n->created_at)) ?></span>
                    </div>

                    <h2 class="text-sm font-bold text-slate-800 mt-2"><?= htmlspecialchars($n->titre) ?></h2>
                    <p class="text-[12.5px] text-slate-600 leading-relaxed mt-1"><?= nl2br(htmlspecialchars($n->message)) ?></p>

                    <div class="flex items-center justify-between mt-3 pt-2.5 border-t border-slate-100">
                        <span class="text-[11px] text-slate-400">
                            <?= $sender !== '' ? 'Dr ' . htmlspecialchars($sender) : 'Votre médecin' ?>
                        </span>
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
    </main>
</div>
