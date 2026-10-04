<!-- ============ ÉCRAN "FIND DOCTORS" ============ -->
<div class="relative w-full max-w-md min-h-screen flex flex-col pb-28 screen-ambient">

    <!-- Barre d'état iOS -->
    <header class="sticky top-0 z-40 px-6 pt-3 pb-2 flex justify-between items-center text-slate-900 bg-white/40 backdrop-blur-md">
        <span class="text-xs font-semibold tracking-tight text-slate-800">9:41</span>
        <div class="flex items-center space-x-1.5 text-slate-800">
            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                <rect height="6" rx="1" width="3" x="2" y="16"></rect>
                <rect height="10" rx="1" width="3" x="7.5" y="12"></rect>
                <rect height="15" rx="1" width="3" x="13" y="7"></rect>
                <rect height="19" rx="1" width="3" x="18.5" y="3"></rect>
            </svg>
            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 4c-5 0-9.27 2.16-12 5.5l12 12.5 12-12.5c-2.73-3.34-7-5.5-12-5.5z"></path>
            </svg>
            <div class="w-5 h-2.5 border border-slate-700 rounded-sm p-0.5 flex items-center">
                <div class="h-full w-3/4 bg-slate-800 rounded-sm"></div>
            </div>
        </div>
    </header>

    <!-- Navigation supérieure -->
    <section class="px-5 pt-3 pb-3 flex items-center justify-between">
        <a href="<?= BASE_URL ?>" aria-label="Retour" class="w-10 h-10 rounded-2xl flex items-center justify-center text-slate-700 hover:bg-white/60 transition active:scale-95">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24">
                <path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </a>
        <h1 class="text-lg font-bold text-slate-800 tracking-tight">Find Doctors</h1>
        <button aria-label="Filtrer" class="w-10 h-10 rounded-2xl flex items-center justify-center text-slate-700 hover:bg-white/60 transition active:scale-95">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M3 4h18M6 10h12m-8 6h4" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </button>
    </section>

    <!-- Barre de recherche -->
    <section class="px-5 mt-1">
        <div class="relative flex items-center">
            <div class="absolute left-4 text-slate-400 pointer-events-none">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path d="M21 21l-4.35-4.35M17 11a6 6 0 11-12 0 6 6 0 0112 0z" stroke-linecap="round" stroke-linejoin="round"></path>
                </svg>
            </div>
            <input class="w-full py-3.5 pl-12 pr-4 bg-white/80 border border-white/70 rounded-2xl text-sm placeholder-slate-400 text-slate-700 shadow-sm focus:outline-none focus:ring-2 focus:ring-teal-400 focus:bg-white transition" placeholder="Search doctors, specialists..." type="text">
        </div>
    </section>

    <!-- Carrousel des spécialités -->
    <nav class="mt-4 px-5 overflow-x-auto no-scrollbar flex space-x-2.5 items-center pb-1">
        <?php foreach ($specialties as $i => $spec): ?>
            <?php if ($i === 0): ?>
                <button class="px-5 py-2.5 rounded-full bg-teal-primary text-white text-xs font-semibold shadow-md shadow-teal-500/25 active:scale-95 transition whitespace-nowrap"><?= htmlspecialchars($spec) ?></button>
            <?php else: ?>
                <button class="px-5 py-2.5 rounded-full bg-white/70 text-slate-500 text-xs font-semibold shadow-pill-soft border border-white/70 hover:bg-white active:scale-95 transition whitespace-nowrap"><?= htmlspecialchars($spec) ?></button>
            <?php endif; ?>
        <?php endforeach; ?>
    </nav>

    <!-- Liste des médecins -->
    <main class="px-5 mt-4 space-y-3.5">
        <?php foreach ($doctors as $doc): ?>
        <article class="glass-card rounded-3xl p-3.5 flex items-center shadow-soft-card hover:shadow-md transition">
            <!-- Avatar -->
            <div class="w-16 h-16 rounded-2xl <?= $doc['bg'] ?> overflow-hidden flex-shrink-0 shadow-inner border border-white/80">
                <img alt="<?= htmlspecialchars($doc['name']) ?>" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/<?= $doc['img'] ?>">
            </div>
            <!-- Informations -->
            <div class="ml-3.5 flex-1 min-w-0">
                <h2 class="text-sm font-bold text-slate-800 truncate leading-snug"><?= htmlspecialchars($doc['name']) ?></h2>
                <p class="text-xs text-slate-400 font-medium truncate mt-0.5"><?= htmlspecialchars($doc['spec']) ?></p>
                <div class="flex items-center space-x-1.5 mt-1.5 text-xs">
                    <span class="text-amber-400 text-xs">★</span>
                    <span class="font-bold text-slate-700 text-[11px]"><?= $doc['rating'] ?></span>
                    <span class="text-slate-400 text-[11px]">(<?= $doc['reviews'] ?> reviews)</span>
                </div>
                <div class="flex items-center space-x-1 mt-1 text-[11px] text-slate-400">
                    <svg class="w-3 h-3 text-amber-500/70" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10"></circle>
                        <polyline points="12 6 12 12 16 14"></polyline>
                    </svg>
                    <span><?= htmlspecialchars($doc['exp']) ?> Years Exp.</span>
                </div>
            </div>
            <!-- Actions (message & appel) -->
            <div class="flex flex-col space-y-2 ml-2 flex-shrink-0">
                <button aria-label="Message <?= htmlspecialchars($doc['name']) ?>" class="w-9 h-9 rounded-full bg-white/90 border border-slate-100 flex items-center justify-center text-teal-600 shadow-sm hover:bg-teal-50 active:scale-95 transition">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                </button>
                <button aria-label="Appeler <?= htmlspecialchars($doc['name']) ?>" class="w-9 h-9 rounded-full bg-teal-primary text-white flex items-center justify-center shadow-sm shadow-teal-600/30 hover:bg-teal-600 active:scale-95 transition">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                        <path d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" stroke-linecap="round" stroke-linejoin="round"></path>
                    </svg>
                </button>
            </div>
        </article>
        <?php endforeach; ?>
    </main>

    <!-- Barre de navigation inférieure flottante -->
    <nav class="fixed bottom-0 left-0 right-0 max-w-md mx-auto z-50 px-6 pt-2 pb-6 glass-nav rounded-t-[2.2rem] shadow-nav-bar flex items-center justify-between">
        <a href="<?= BASE_URL ?>" class="flex flex-col items-center justify-center text-slate-400 hover:text-teal-600 transition group flex-1">
            <svg class="w-5 h-5 mb-0.5 group-hover:scale-110 transition" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
            <span class="text-[10px] font-medium tracking-tight">Home</span>
        </a>
        <button class="flex flex-col items-center justify-center text-slate-400 hover:text-teal-600 transition group flex-1">
            <svg class="w-5 h-5 mb-0.5 group-hover:scale-110 transition" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
            <span class="text-[10px] font-medium tracking-tight">Appointments</span>
        </button>
        <div class="relative -top-4 flex justify-center items-center flex-1">
            <button aria-label="Nouvelle réservation" class="w-14 h-14 rounded-full bg-teal-primary text-white shadow-floating-btn hover:bg-teal-600 active:scale-90 transition-all flex items-center justify-center ring-4 ring-white">
                <svg class="w-6 h-6 stroke-[2.6]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path d="M12 4v16m8-8H4" stroke-linecap="round" stroke-linejoin="round"></path>
                </svg>
            </button>
        </div>
        <button class="flex flex-col items-center justify-center text-slate-400 hover:text-teal-600 transition group flex-1">
            <svg class="w-5 h-5 mb-0.5 group-hover:scale-110 transition" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
            <span class="text-[10px] font-medium tracking-tight">Records</span>
        </button>
        <button class="flex flex-col items-center justify-center text-slate-400 hover:text-teal-600 transition group flex-1">
            <svg class="w-5 h-5 mb-0.5 group-hover:scale-110 transition" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
            <span class="text-[10px] font-medium tracking-tight">Profile</span>
        </button>
    </nav>
</div>
