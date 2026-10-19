<!-- ============ ÉCRAN « DOCTOR PROFILE & Q&A » (liste des questions) ============ -->
<main class="relative w-full max-w-[390px] h-[844px] bg-gradient-to-b from-teal-600 via-teal-500 to-teal-400 overflow-hidden flex flex-col shadow-2xl sm:rounded-[48px] border-0 sm:border-8 border-slate-900">

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

    <!-- Navigation supérieure : retour vers la fiche · badge · menu -->
    <nav class="px-5 pt-3 pb-2 flex justify-between items-center z-20 shrink-0">
        <a href="<?= BASE_URL ?>profile" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white border border-white/25 active:scale-95 transition-transform shadow-sm">
            <svg class="w-5 h-5 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <div class="flex items-center gap-1.5 px-3 py-1 bg-white/15 backdrop-blur-md rounded-full border border-white/20">
            <span class="w-2 h-2 rounded-full bg-emerald-300 animate-pulse"></span>
            <span class="text-[11px] font-semibold text-white tracking-wide uppercase">Doza AI</span>
        </div>
        <button aria-label="Plus d'options" class="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center text-white border border-white/25 active:scale-95 transition-transform shadow-sm">
            <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24"><circle cx="5" cy="12" r="2.2"></circle><circle cx="12" cy="12" r="2.2"></circle><circle cx="19" cy="12" r="2.2"></circle></svg>
        </button>
    </nav>

    <!-- Hero compact du médecin -->
    <section class="flex flex-col items-center px-6 pt-1 pb-4 text-center z-10 shrink-0">
        <div class="relative mb-2.5">
            <div class="absolute -inset-1.5 bg-gradient-to-tr from-teal-200 to-white rounded-3xl opacity-60 blur-md"></div>
            <div class="relative w-20 h-20 rounded-2xl overflow-hidden border-2 border-white/80 shadow-lg bg-teal-800">
                <img alt="<?= htmlspecialchars($doctor['name']) ?>" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/<?= $doctor['img'] ?>">
            </div>
            <div class="absolute -bottom-1 -right-2 w-8 h-8 rounded-xl overflow-hidden border-2 border-white shadow-md bg-white">
                <img alt="Collaborateur" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/<?= $doctor['badgeImg'] ?>">
            </div>
        </div>
        <div class="flex items-center justify-center space-x-1.5">
            <h1 class="text-xl font-bold text-white tracking-tight"><?= htmlspecialchars($doctor['name']) ?></h1>
            <svg class="w-4 h-4 text-teal-200 fill-current" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"></path></svg>
        </div>
        <p class="text-xs text-teal-100 font-medium mt-0.5"><?= htmlspecialchars($doctor['spec']) ?></p>
    </section>

    <!-- Feuille blanche : onglets + recherche + liste -->
    <div class="flex-1 bg-[#F5FCFA] rounded-t-[36px] shadow-2xl flex flex-col overflow-hidden relative z-20 border-t border-white/60">

        <!-- Onglets -->
        <div class="pt-5 px-6 pb-2">
            <div class="flex items-center justify-around relative">
                <button class="relative pb-2.5 px-4 text-center">
                    <span class="text-sm font-bold text-slate-800">My Questions</span>
                    <span class="absolute bottom-0 left-1/2 -translate-x-1/2 w-8 h-1 bg-teal-500 rounded-full"></span>
                </button>
                <span class="h-4 w-px bg-slate-200"></span>
                <button class="relative pb-2.5 px-4 text-center">
                    <span class="text-sm font-semibold text-slate-400 hover:text-slate-600 transition-colors">My Answers</span>
                </button>
            </div>
        </div>

        <!-- Recherche -->
        <div class="px-5 pt-2 pb-3">
            <div class="relative flex items-center">
                <input class="w-full bg-white text-slate-700 text-xs rounded-2xl pl-4 pr-10 py-3 border border-teal-900/10 focus:border-teal-500 focus:ring-2 focus:ring-teal-200 placeholder:text-slate-300 outline-none shadow-sm transition-all" placeholder="Search questions, cases or symptoms..." type="text">
                <div class="absolute right-3.5 text-slate-400 pointer-events-none">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </div>
            </div>
        </div>

        <!-- Liste des questions -->
        <div class="flex-1 overflow-y-auto px-5 space-y-3 pb-24 no-scrollbar">
            <?php foreach ($questions as $q): ?>
            <article class="bg-white rounded-2xl p-4 shadow-[0_8px_24px_-6px_rgba(13,148,136,0.08)] border border-teal-800/5 hover:border-teal-500/20 transition-all">
                <h2 class="text-xs font-bold text-slate-800 leading-snug"><?= htmlspecialchars($q['text']) ?></h2>
                <div class="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px]">
                    <div class="flex items-center gap-2">
                        <span class="px-2 py-0.5 rounded-full bg-teal-primary/10 text-teal-700 text-[9px] font-bold uppercase tracking-wide border border-teal-300/40"><?= htmlspecialchars($q['tag']) ?></span>
                        <span class="text-slate-400 font-medium"><?= (int) $q['answers'] ?> answers • <?= htmlspecialchars($q['helpful']) ?></span>
                    </div>
                    <button aria-label="Actions" class="text-slate-300 hover:text-slate-600 p-1">
                        <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><circle cx="5" cy="12" r="1.8"></circle><circle cx="12" cy="12" r="1.8"></circle><circle cx="19" cy="12" r="1.8"></circle></svg>
                    </button>
                </div>
            </article>
            <?php endforeach; ?>
        </div>
    </div>

    <!-- Barre de navigation flottante -->
    <nav class="absolute bottom-5 left-5 right-5 h-16 bg-white/95 backdrop-blur-md rounded-3xl shadow-[0_12px_32px_-4px_rgba(15,118,110,0.16)] flex items-center justify-around px-4 border border-teal-100/60 z-30">
        <a href="<?= BASE_URL ?>" aria-label="Accueil" class="w-10 h-10 flex items-center justify-center text-slate-400 hover:text-teal-600 active:scale-90 transition-transform">
            <svg class="w-6 h-6 stroke-[1.8]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <a href="<?= BASE_URL ?>doza" aria-label="Poser une question" class="w-12 h-12 -mt-4 bg-gradient-to-tr from-teal-600 to-teal-400 text-white rounded-2xl flex items-center justify-center shadow-[0_0_25px_rgba(45,212,191,0.45)] active:scale-95 transition-all">
            <svg class="w-6 h-6 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M12 4v16m8-8H4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <a href="<?= BASE_URL ?>profile" aria-label="Profil" class="w-10 h-10 flex flex-col items-center justify-center text-teal-600 active:scale-90 transition-transform">
            <svg class="w-6 h-6 fill-current" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path></svg>
            <span class="w-1 h-1 bg-teal-600 rounded-full mt-0.5"></span>
        </a>
    </nav>

    <div class="absolute bottom-1 left-1/2 -translate-x-1/2 w-32 h-1 bg-slate-300 rounded-full z-40"></div>
</main>
