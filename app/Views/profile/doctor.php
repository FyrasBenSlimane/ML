<?php
// Bouton « + » de la barre du bas : par défaut retour à la liste ; pour un outil IA (Sora), le lance.
$plusLink = $plusLink ?? 'doctors';
$plusAria = $plusAria ?? 'Trouver un médecin';
?>
<!-- ============ ÉCRAN « DOCTOR PROFILE & OVERVIEW » (autre médecin de la liste) ============ -->
<!-- Même interface que la fiche Doza. -->
<main class="relative w-full max-w-[390px] h-[844px] bg-gradient-to-b from-teal-600 via-teal-500 to-teal-400 overflow-hidden flex flex-col shadow-2xl sm:rounded-[48px] border-0 sm:border-8 border-slate-900">

    <!-- Lueurs organiques d'ambiance -->
    <div class="pointer-events-none absolute -top-10 -right-16 w-64 h-64 rounded-full bg-teal-300/40 blur-3xl"></div>
    <div class="pointer-events-none absolute top-24 -left-20 w-56 h-56 rounded-full bg-emerald-200/25 blur-3xl"></div>

    <!-- Barre d'état iOS -->
    <header class="pt-3 px-7 flex justify-between items-center text-white text-xs font-semibold z-20 shrink-0">
        <span>9:41</span>
        <div class="w-24 h-5 bg-black/20 backdrop-blur-md rounded-full absolute left-1/2 -translate-x-1/2 top-2.5"></div>
        <div class="flex items-center space-x-1.5">
            <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24"><path d="M2 17h3v4H2v-4zm6-5h3v9H8v-9zm6-4h3v13h-3V8zm6-5h3v18h-3V3z"></path></svg>
            <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24"><path d="M12 4C7.31 4 3.07 5.9 0 8.98L12 21 24 8.98C20.93 5.9 16.69 4 12 4z"></path></svg>
            <div class="w-5 h-2.5 border border-white rounded-sm p-0.5 flex items-center">
                <div class="h-full w-full bg-white rounded-sm"></div>
            </div>
        </div>
    </header>

    <!-- Navigation supérieure : retour · badge spécialité · menu -->
    <nav class="px-5 pt-3 pb-2 flex justify-between items-center z-20 shrink-0">
        <a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white border border-white/25 active:scale-95 transition-transform shadow-sm">
            <svg class="w-5 h-5 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <div class="flex items-center gap-1.5 px-3 py-1 bg-white/15 backdrop-blur-md rounded-full border border-white/20">
            <span class="w-2 h-2 rounded-full bg-emerald-300 animate-pulse"></span>
            <span class="text-[11px] font-semibold text-white tracking-wide uppercase"><?= htmlspecialchars($badge) ?></span>
        </div>
        <button aria-label="Plus d'options" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white border border-white/25 active:scale-95 transition-transform shadow-sm">
            <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24"><circle cx="5" cy="12" r="2.2"></circle><circle cx="12" cy="12" r="2.2"></circle><circle cx="19" cy="12" r="2.2"></circle></svg>
        </button>
    </nav>

    <!-- Identité du médecin -->
    <section class="flex flex-col items-center px-6 pt-1 pb-3 text-center z-10 shrink-0">
        <!-- Portrait -->
        <div class="relative mb-2.5">
            <div class="absolute -inset-1.5 bg-gradient-to-tr from-teal-200 to-white rounded-3xl opacity-60 blur-md"></div>
            <div class="relative w-24 h-24 rounded-3xl overflow-hidden border-2 border-white/80 shadow-lg bg-teal-800">
                <img alt="<?= htmlspecialchars($doctor['name']) ?>" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/<?= $doctor['img'] ?>">
            </div>
        </div>
        <!-- Nom + badge vérifié -->
        <div class="flex items-center justify-center space-x-1.5 mt-1">
            <h1 class="text-xl font-bold text-white tracking-tight"><?= htmlspecialchars($doctor['name']) ?></h1>
            <svg class="w-4 h-4 text-teal-100 fill-current" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"></path></svg>
        </div>
        <p class="text-xs text-teal-50 font-medium mt-0.5"><?= htmlspecialchars($doctor['spec']) ?></p>
        <p class="text-[11px] text-teal-100/90 mt-1">
            <?= htmlspecialchars($doctor['center']) ?> • <?= htmlspecialchars($doctor['exp']) ?>
        </p>

        <!-- Statistiques (pilules verre dépoli) -->
        <div class="grid grid-cols-3 gap-2.5 mt-4 w-full">
            <?php foreach ($doctor['stats'] as $stat): ?>
            <div class="bg-white/15 backdrop-blur-md rounded-2xl py-2.5 px-1 border border-white/20 flex flex-col items-center">
                <div class="flex items-center gap-1 text-white">
                    <?php if ($stat['icon'] === 'star'): ?>
                        <svg class="w-3.5 h-3.5 text-amber-300 fill-current" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"></path></svg>
                    <?php elseif ($stat['icon'] === 'chat'): ?>
                        <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"></path></svg>
                    <?php else: ?>
                        <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24"><path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"></path></svg>
                    <?php endif; ?>
                    <span class="text-sm font-bold"><?= htmlspecialchars($stat['value']) ?></span>
                </div>
                <span class="text-[9px] text-teal-50/90 font-medium mt-0.5 leading-tight text-center"><?= htmlspecialchars($stat['label']) ?></span>
            </div>
            <?php endforeach; ?>
        </div>
    </section>

    <!-- Feuille blanche coulissante -->
    <div class="flex-1 bg-[#F5FCFA] rounded-t-[36px] shadow-2xl flex flex-col overflow-hidden relative z-20 border-t border-white/60">

        <!-- Onglets (historique) -->
        <div class="pt-5 px-6 pb-2">
            <div class="flex items-center justify-around relative">
                <button type="button" data-tab="questions" class="tab-btn relative pb-2.5 px-4 text-center">
                    <span class="tab-label text-sm font-bold text-slate-800">My Questions</span>
                    <span class="tab-underline absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-1 bg-teal-500 rounded-full"></span>
                </button>
                <span class="h-4 w-px bg-slate-200"></span>
                <button type="button" data-tab="answers" class="tab-btn relative pb-2.5 px-4 text-center">
                    <span class="tab-label text-sm font-semibold text-slate-400 hover:text-slate-600 transition-colors">My Answers</span>
                    <span class="tab-underline absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-1 bg-teal-500 rounded-full hidden"></span>
                </button>
            </div>
        </div>

        <!-- Recherche -->
        <div class="px-5 pt-2 pb-3">
            <div class="relative flex items-center">
                <input id="history-search" class="w-full bg-white text-slate-700 text-xs rounded-2xl pl-4 pr-10 py-3 border border-teal-900/10 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 placeholder:text-slate-300 outline-none shadow-sm transition-all" placeholder="Rechercher dans l'historique..." type="text">
                <div class="absolute right-3.5 text-slate-400 pointer-events-none">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
            </div>
        </div>

        <!-- Historiques -->
        <div class="flex-1 overflow-y-auto px-5 pb-28 no-scrollbar">

            <!-- Questions -->
            <div id="tab-panel-questions" class="space-y-3">
                <?php if (empty($questions)): ?>
                <div class="text-center py-10 px-4">
                    <div class="w-12 h-12 mx-auto rounded-2xl bg-teal-50 text-teal-500 flex items-center justify-center mb-3">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M8 12h8m-8 4h5M21 12c0 4.418-4.03 8-9 8a9.9 9.9 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </div>
                    <p class="text-xs font-semibold text-slate-500">Aucune question pour le moment</p>
                    <p class="text-[11px] text-slate-400 mt-1 leading-relaxed">Vos échanges avec ce médecin apparaîtront ici.</p>
                </div>
                <?php endif; ?>
                <?php foreach ($questions as $q): ?>
                <article class="history-item bg-white rounded-2xl p-4 shadow-[0_8px_24px_-6px_rgba(13,148,136,0.08)] border border-teal-800/5 hover:border-teal-500/20 transition-all">
                    <div class="flex items-start gap-2.5">
                        <div class="w-7 h-7 rounded-full bg-teal-50 text-teal-600 flex items-center justify-center shrink-0 mt-0.5">
                            <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01" stroke-linecap="round" stroke-linejoin="round"></path><circle cx="12" cy="12" r="9"></circle></svg>
                        </div>
                        <h2 class="history-text text-xs font-bold text-slate-800 leading-snug"><?= htmlspecialchars($q['text']) ?></h2>
                    </div>
                    <div class="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px]">
                        <span class="px-2 py-0.5 rounded-full bg-teal-primary/10 text-teal-700 text-[9px] font-bold uppercase tracking-wide border border-teal-300/40"><?= htmlspecialchars($q['tag']) ?></span>
                        <span class="flex items-center gap-1.5 text-slate-400 font-medium">
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"></circle><path d="M12 7v5l3 2" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                            <?= htmlspecialchars($q['date']) ?>
                        </span>
                    </div>
                </article>
                <?php endforeach; ?>
            </div>

            <!-- Réponses -->
            <div id="tab-panel-answers" class="space-y-3 hidden">
                <?php if (empty($answers)): ?>
                <div class="text-center py-10 px-4">
                    <div class="w-12 h-12 mx-auto rounded-2xl bg-teal-50 text-teal-500 flex items-center justify-center mb-3">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l1.6 4.8L18 8.4l-4.4 1.6L12 15l-1.6-5L6 8.4l4.4-1.6L12 2z"></path></svg>
                    </div>
                    <p class="text-xs font-semibold text-slate-500">Aucune réponse pour le moment</p>
                    <p class="text-[11px] text-slate-400 mt-1 leading-relaxed">Les réponses de ce médecin apparaîtront ici.</p>
                </div>
                <?php endif; ?>
                <?php foreach ($answers as $a): ?>
                <article class="history-item bg-white rounded-2xl p-4 shadow-[0_8px_24px_-6px_rgba(13,148,136,0.08)] border border-teal-800/5 hover:border-teal-500/20 transition-all">
                    <div class="flex items-start gap-2.5">
                        <div class="w-7 h-7 rounded-full bg-gradient-to-br from-teal-500 to-teal-400 text-white flex items-center justify-center shrink-0 mt-0.5">
                            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2l1.6 4.8L18 8.4l-4.4 1.6L12 15l-1.6-5L6 8.4l4.4-1.6L12 2z"></path></svg>
                        </div>
                        <p class="history-text text-xs text-slate-700 leading-relaxed"><?= htmlspecialchars($a['text']) ?></p>
                    </div>
                    <div class="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px]">
                        <span class="px-2 py-0.5 rounded-full bg-teal-primary/10 text-teal-700 text-[9px] font-bold uppercase tracking-wide border border-teal-300/40"><?= htmlspecialchars($a['result']) ?> · <?= htmlspecialchars($a['confidence']) ?></span>
                        <span class="flex items-center gap-1.5 text-slate-400 font-medium">
                            <svg class="w-3 h-3" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"></circle><path d="M12 7v5l3 2" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                            <?= htmlspecialchars($a['date']) ?>
                        </span>
                    </div>
                </article>
                <?php endforeach; ?>
            </div>

            <!-- Message « aucun résultat » (recherche) -->
            <p id="history-empty" class="hidden text-center text-xs text-slate-400 py-8">Aucun résultat dans l'historique.</p>
        </div>
    </div>

    <!-- Barre de navigation flottante -->
    <nav class="absolute bottom-5 left-5 right-5 h-16 bg-white/95 backdrop-blur-md rounded-3xl shadow-[0_12px_32px_-4px_rgba(15,118,110,0.16)] flex items-center justify-around px-4 border border-teal-100/60 z-30">
        <a href="<?= BASE_URL ?>" aria-label="Accueil" class="w-10 h-10 flex items-center justify-center text-slate-400 hover:text-teal-600 active:scale-90 transition-transform">
            <svg class="w-6 h-6 stroke-[1.8]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <a href="<?= BASE_URL . $plusLink ?>" aria-label="<?= htmlspecialchars($plusAria) ?>" class="w-12 h-12 -mt-4 bg-gradient-to-tr from-teal-600 to-teal-400 text-white rounded-2xl flex items-center justify-center shadow-[0_0_25px_rgba(45,212,191,0.45)] active:scale-95 transition-all">
            <svg class="w-6 h-6 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M12 4v16m8-8H4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <a href="<?= BASE_URL ?>profile" aria-label="Profil" class="w-10 h-10 flex flex-col items-center justify-center text-slate-400 hover:text-teal-600 active:scale-90 transition-transform">
            <svg class="w-6 h-6 fill-current" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path></svg>
        </a>
    </nav>

    <!-- Barre d'accueil iOS -->
    <div class="absolute bottom-1 left-1/2 -translate-x-1/2 w-32 h-1 bg-slate-300 rounded-full z-40"></div>
</main>

<!-- Bascule des onglets (Questions / Réponses) + recherche dans l'historique -->
<script>
  (function () {
    const tabs    = document.querySelectorAll('.tab-btn');
    const panels  = {
      questions: document.getElementById('tab-panel-questions'),
      answers:   document.getElementById('tab-panel-answers'),
    };
    const search  = document.getElementById('history-search');
    const empty   = document.getElementById('history-empty');
    let current   = 'questions';

    function activerOnglet(nom) {
      current = nom;
      tabs.forEach(function (btn) {
        const actif = btn.dataset.tab === nom;
        btn.querySelector('.tab-label').classList.toggle('text-slate-800', actif);
        btn.querySelector('.tab-label').classList.toggle('font-bold', actif);
        btn.querySelector('.tab-label').classList.toggle('text-slate-400', !actif);
        btn.querySelector('.tab-label').classList.toggle('font-semibold', !actif);
        btn.querySelector('.tab-underline').classList.toggle('hidden', !actif);
      });
      panels.questions.classList.toggle('hidden', nom !== 'questions');
      panels.answers.classList.toggle('hidden', nom !== 'answers');
      filtrer();
    }

    function filtrer() {
      const q = (search.value || '').trim().toLowerCase();
      const items = panels[current].querySelectorAll('.history-item');
      let visibles = 0;
      items.forEach(function (el) {
        const txt = el.querySelector('.history-text').textContent.toLowerCase();
        const ok  = q === '' || txt.indexOf(q) !== -1;
        el.classList.toggle('hidden', !ok);
        if (ok) visibles++;
      });
      empty.classList.toggle('hidden', visibles !== 0);
    }

    tabs.forEach(function (btn) {
      btn.addEventListener('click', function () { activerOnglet(btn.dataset.tab); });
    });
    search.addEventListener('input', filtrer);
  })();
</script>
