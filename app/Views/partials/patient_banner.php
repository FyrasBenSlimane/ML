<?php
/**
 * Bandeau « Patient en cours d'évaluation » affiché sur les écrans Doza/Sora.
 * Attend : $patient (['name','code']) et éventuellement $bannerNext ('doza'|'sora').
 */
$bannerNext = $bannerNext ?? 'doza';
if (!empty($patient)):
?>
<div class="flex items-center justify-between gap-2 mx-4 mt-2 px-3.5 py-2 rounded-2xl bg-teal-600/95 text-white shadow-md">
    <div class="flex items-center gap-2 min-w-0">
        <svg class="w-4 h-4 shrink-0 text-teal-100" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        <span class="text-[12px] font-semibold truncate">Patient : <?= htmlspecialchars($patient['name']) ?> · #<?= htmlspecialchars($patient['code']) ?></span>
    </div>
    <a href="<?= BASE_URL ?>patient/select?next=<?= htmlspecialchars($bannerNext) ?>" class="shrink-0 text-[11px] font-bold underline underline-offset-2 text-teal-50 hover:text-white">changer</a>
</div>
<?php endif; ?>
