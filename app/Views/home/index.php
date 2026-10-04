<!-- ============ ÉCRAN D'ACCUEIL ============ -->
<!-- Cadre mobile -->
<main class="relative w-full max-w-[400px] h-[844px] bg-gradient-to-b from-[#E7F6F3] via-[#E2F3F0] to-[#CDECE6] sm:rounded-[50px] shadow-2xl overflow-hidden flex flex-col justify-between border-[8px] border-slate-800/80 sm:border-slate-700/60">

    <!-- Barre d'état iOS -->
    <header class="relative z-30 pt-3 px-8 flex items-center justify-between text-slate-800 font-semibold text-sm">
        <span>9:41</span>
        <div class="w-28 h-4 bg-transparent rounded-full mx-auto"></div>
        <div class="flex items-center space-x-2 text-slate-800">
            <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M2 18h2v2H2v-2zm4-4h2v6H6v-6zm4-4h2v10h-2V10zm4-4h2v14h-2V6zm4-4h2v18h-2V2z"></path></svg>
            <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M12 4a14.9 14.9 0 0 1 8.87 2.9l-2.07 2.07A11.96 11.96 0 0 0 12 7c-2.6 0-5 1-6.8 2.63L3.13 6.9A14.9 14.9 0 0 1 12 4zm0 6c2.4 0 4.6.9 6.2 2.4l-2.1 2.1c-1.1-.9-2.5-1.5-4.1-1.5s-3 .6-4.1 1.5L5.8 12.4C7.4 10.9 9.6 10 12 10zm0 6a3 3 0 0 1 2.12.88l-2.12 2.12-2.12-2.12A3 3 0 0 1 12 16z"></path></svg>
            <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <rect fill="none" height="10" rx="3" stroke="currentColor" stroke-width="2" width="18" x="2" y="7"></rect>
                <rect fill="currentColor" height="6" rx="1.5" width="13" x="4" y="9"></rect>
                <path d="M21 10.5v3" stroke="currentColor" stroke-linecap="round" stroke-width="2"></path>
            </svg>
        </div>
    </header>

    <!-- Navigation supérieure -->
    <nav class="relative z-30 px-6 pt-2 flex items-center justify-between">
        <button aria-label="Accueil / Marque" class="w-12 h-12 rounded-2xl glass-tile flex items-center justify-center shadow-icon-soft text-teal-brand transition hover:scale-105 active:scale-95" type="button">
            <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" fill="#1AA89B"></path>
                <path d="M6.5 11h2.5l1.5-3 2 6 1.5-3h3.5" stroke="#FFFFFF" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8"></path>
            </svg>
        </button>
        <button aria-label="Options" class="w-12 h-12 rounded-full glass-tile flex items-center justify-center shadow-icon-soft text-slate-700 transition hover:scale-105 active:scale-95" type="button">
            <div class="flex space-x-1 items-center">
                <span class="w-1.5 h-1.5 rounded-full bg-slate-700"></span>
                <span class="w-1.5 h-1.5 rounded-full bg-slate-700"></span>
                <span class="w-1.5 h-1.5 rounded-full bg-slate-700"></span>
            </div>
        </button>
    </nav>

    <!-- Zone Hero -->
    <div class="relative flex-1 px-6 pt-5">
        <!-- Titre & CTA -->
        <section class="relative z-20 max-w-[210px] pt-1">
            <h1 class="text-teal-darkText text-[34px] font-extrabold leading-[1.12] tracking-tight">
                Your Health<br>Our Priority
            </h1>
            <p class="mt-3 text-slate-600 text-[13px] leading-relaxed font-medium">
                Advanced healthcare for a better and healthier you.
            </p>
            <div class="mt-5">
                <a href="<?= BASE_URL ?>doctors" class="group relative inline-flex items-center bg-gradient-to-r from-[#1EACA0] to-[#12897F] hover:from-[#179B90] hover:to-[#0F776E] text-white font-semibold text-[14px] pl-5 pr-1.5 py-1.5 rounded-full shadow-teal-glow transition-all duration-300 transform active:scale-95">
                    <span>Get Started</span>
                    <div class="ml-3 w-8 h-8 rounded-full bg-white flex items-center justify-center text-teal-brand shadow-sm group-hover:translate-x-0.5 transition-transform duration-200">
                        <svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3" stroke-linecap="round" stroke-linejoin="round"></path>
                        </svg>
                    </div>
                </a>
            </div>
        </section>

        <!-- Podium 3D & personnage médecin -->
        <div class="absolute inset-0 pointer-events-none overflow-hidden">
            <div class="absolute bottom-[90px] right-[-10px] w-[310px] h-[220px] flex flex-col items-center justify-end z-0">
                <div class="relative w-[180px] h-[130px]">
                    <div class="w-full h-[48px] rounded-[50%] podium-cylinder-top border-t border-white/80"></div>
                    <div class="w-full h-[95px] -mt-[24px] podium-cylinder-body"></div>
                </div>
                <div class="relative w-[280px] h-[70px] -mt-[35px]">
                    <div class="w-full h-[60px] rounded-[50%] podium-cylinder-top border-t border-white"></div>
                    <div class="w-full h-[32px] -mt-[30px] rounded-b-[40px] podium-base-rim"></div>
                </div>
            </div>
            <!-- Image du médecin : à télécharger dans assets/img/ pour un projet réel (voir README) -->
            <div class="absolute top-[70px] right-[-4px] w-[250px] h-[430px] z-10 flex items-center justify-center">
                <img alt="Personnage médecin 3D, bras croisés" class="w-full h-full object-contain filter drop-shadow-[-10px_15px_22px_rgba(15,50,47,0.18)]" style="mix-blend-mode: multiply;" src="<?= ASSETS_URL ?>/img/doctor.png">
            </div>
        </div>
    </div>

    <!-- Carte inférieure en verre dépoli -->
    <div class="relative z-30 px-4 pb-7">
        <div aria-hidden="true" class="absolute -left-7 bottom-4 w-24 h-24 rounded-full bg-gradient-to-tr from-[#FFA585] to-[#FF758C] opacity-80 blur-[2px] shadow-lg pointer-events-none -z-10 transform -rotate-12"></div>

        <section class="glass-panel rounded-[32px] p-5 shadow-glass">
            <!-- Preuve sociale -->
            <div class="flex items-center justify-between mb-4 px-1">
                <div>
                    <p class="text-[11px] font-semibold tracking-wider text-slate-400 uppercase">Trusted by</p>
                    <p class="text-[19px] font-extrabold text-teal-darkText tracking-tight">2M+ Users</p>
                </div>
                <div class="flex items-center -space-x-2">
                    <div class="relative w-7 h-7 rounded-full border-2 border-white overflow-hidden shadow-sm ring-1 ring-slate-100 bg-white">
                        <img alt="Médecin" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/doctor2.jpg">
                    </div>
                    <div class="relative w-7 h-7 rounded-full border-2 border-white overflow-hidden shadow-sm ring-1 ring-slate-100 bg-white">
                        <img alt="Médecin" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/doctor3.jpg">
                    </div>
                    <div class="relative w-7 h-7 rounded-full border-2 border-white overflow-hidden shadow-sm ring-1 ring-slate-100 bg-white">
                        <img alt="Médecin" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/doctor4.jpg">
                    </div>
                    <div class="relative w-7 h-7 rounded-full border-2 border-white overflow-hidden shadow-sm ring-1 ring-slate-100 bg-white">
                        <img alt="Médecin" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/doctor5.jpg">
                    </div>
                    <div class="relative w-7 h-7 rounded-full border-2 border-white overflow-hidden shadow-sm ring-1 ring-slate-100 bg-white">
                        <img alt="Médecin" class="w-full h-full object-cover object-top" src="<?= ASSETS_URL ?>/img/doctor6.jpg">
                    </div>
                </div>
            </div>

            <!-- Grille d'actions rapides -->
            <div class="grid grid-cols-3 gap-2.5">
                <a href="<?= BASE_URL ?>doctors" class="group flex flex-col items-center justify-center p-2.5 rounded-2xl glass-tile shadow-sm hover:shadow-md transition-all duration-200 active:scale-95 text-center">
                    <div class="w-12 h-12 rounded-xl bg-teal-50 border border-teal-100 flex items-center justify-center text-teal-brand shadow-inner group-hover:scale-105 transition-transform duration-200">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path>
                            <circle cx="18" cy="6" fill="#178D84" r="3" stroke="#FFF" stroke-width="1.5"></circle>
                        </svg>
                    </div>
                    <span class="mt-2 text-[11px] font-bold text-teal-darkText leading-tight">Find Doctors</span>
                </a>

                <button class="group flex flex-col items-center justify-center p-2.5 rounded-2xl glass-tile shadow-sm hover:shadow-md transition-all duration-200 active:scale-95 text-center" type="button">
                    <div class="w-12 h-12 rounded-xl bg-teal-50 border border-teal-100 flex items-center justify-center text-teal-brand shadow-inner group-hover:scale-105 transition-transform duration-200">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M19 4h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20a2 2 0 0 0 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V10h14v10zm-7-8h5v5h-5z"></path>
                        </svg>
                    </div>
                    <span class="mt-2 text-[11px] font-bold text-teal-darkText leading-tight">Book<br>Appointment</span>
                </button>

                <button class="group flex flex-col items-center justify-center p-2.5 rounded-2xl glass-tile shadow-sm hover:shadow-md transition-all duration-200 active:scale-95 text-center" type="button">
                    <div class="w-12 h-12 rounded-xl bg-purple-50 border border-purple-100 flex items-center justify-center text-purple-600 shadow-inner group-hover:scale-105 transition-transform duration-200">
                        <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                            <path d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-7 12h-2v-2h2v2zm0-4h-2V6h2v4z"></path>
                        </svg>
                    </div>
                    <span class="mt-2 text-[11px] font-bold text-teal-darkText leading-tight">24/7<br>Support</span>
                </button>
            </div>
        </section>

        <!-- Barre d'accueil iOS -->
        <div aria-hidden="true" class="w-32 h-1 bg-slate-400/50 rounded-full mx-auto mt-4"></div>
    </div>
</main>
