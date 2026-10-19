<!-- ============ ÉCRAN "ACTIVE VOICE SESSION" (résultat du modèle ML) ============ -->
<div class="relative w-full max-w-[400px] h-[844px] my-0 sm:my-6 flex flex-col pb-6 voice-ambient overflow-y-auto overflow-x-hidden sm:rounded-[40px] shadow-2xl">

    <!-- Lueurs ambiantes menthe -->
    <div class="pointer-events-none absolute -top-10 left-1/2 -translate-x-1/2 w-80 h-80 bg-gradient-to-tr from-[#B8F3EC]/50 via-[#8EE6DB]/40 to-[#C9BBF5]/30 rounded-full blur-3xl -z-10"></div>
    <div class="pointer-events-none absolute top-48 -left-16 w-56 h-56 bg-[#6BD8CB]/25 rounded-full blur-2xl -z-10"></div>
    <div class="pointer-events-none absolute bottom-20 -right-4 w-64 h-64 bg-[#71F8E4]/30 rounded-full blur-3xl -z-10"></div>

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
    <section class="px-5 pt-2 pb-1 flex items-center justify-between">
        <a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-11 h-11 rounded-2xl flex items-center justify-center text-slate-700 hover:bg-white/60 hover:text-teal-brand transition active:scale-95">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24">
                <path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </a>
        <h1 class="text-lg font-bold text-teal-darkText tracking-tight">Doza</h1>
        <div class="w-9 h-9 rounded-full bg-gradient-to-br from-[#1EACA0] to-[#12897F] flex items-center justify-center shadow-icon-soft">
            <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path>
            </svg>
        </div>
    </section>

    <!-- Pastille d'état (texte mis à jour par le JS pendant la lecture audio) -->
    <div class="flex justify-center items-center mt-2 mb-1">
        <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/80 backdrop-blur-md shadow-pill-soft">
            <span class="relative flex h-2 w-2">
                <span class="relative inline-flex rounded-full h-2 w-2 bg-teal-brand"></span>
            </span>
            <span class="text-[13px] font-semibold text-teal-brandDark tracking-wide" id="listening-state">Résultat prêt</span>
        </div>
    </div>

    <!-- Orbe holographique 3D : animé UNIQUEMENT pendant la lecture audio (voir CSS #orb-stage) -->
    <div class="relative w-full flex flex-col items-center justify-center my-0">
        <div class="relative flex items-center justify-center w-52 h-52" id="orb-stage">
            <!-- Anneaux d'onde acoustique -->
            <div class="absolute w-44 h-44 rounded-full border border-teal-brand/30 pointer-events-none animate-ripple-1"></div>
            <div class="absolute w-44 h-44 rounded-full border border-[#71F8E4] pointer-events-none animate-ripple-2"></div>
            <!-- Halo harmonique rotatif -->
            <div class="absolute inset-0 rounded-full bg-gradient-to-br from-[#89F5E7] via-[#C6FEF8] to-[#D0BCFF] blur-2xl animate-aura-glow pointer-events-none"></div>
            <!-- Lueur de base -->
            <div class="absolute -bottom-3 w-40 h-8 bg-teal-brand/20 rounded-full blur-xl pointer-events-none animate-pulse"></div>
            <!-- Orbe liquide holographique 3D (image irisée) -->
            <div class="relative w-48 h-48 rounded-full overflow-hidden shadow-[0_20px_50px_-10px_rgba(0,104,95,0.22),inset_0_2px_4px_rgba(255,255,255,0.9)] bg-gradient-to-br from-white via-[#C6FEF8] to-[#6DF5E1]/40 p-1 flex items-center justify-center animate-orb-breathe">
                <img src="<?= ASSETS_URL ?>/img/orb.png" alt="Orbe holographique d'analyse vocale" class="w-full h-full object-cover rounded-full pointer-events-none select-none">
                <div class="pointer-events-none absolute inset-0 rounded-full bg-gradient-to-tr from-transparent via-white/25 to-white/55"></div>
                <div class="pointer-events-none absolute inset-0 rounded-full bg-gradient-to-br from-[#6DF5E1]/20 via-[#D0BCFF]/20 to-[#89F5E7]/20 mix-blend-overlay animate-shimmer-liquid blur-sm"></div>
            </div>
        </div>
    </div>

    <!-- ===== CARTE : RÉSULTAT DU MODÈLE ML (charte "Serene Pulse") ===== -->
    <div class="mt-2 px-4">
        <div class="relative rounded-[28px] p-4 glass-panel shadow-glass ring-1 ring-teal-brand/15 text-center flex flex-col items-center">

            <!-- 1. Badge "Résultat du modèle" (teal doux + icône étincelle) -->
            <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-teal-50 text-teal-700 border border-teal-200/60 text-[12px] font-medium tracking-wide mb-2">
                <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2l1.6 4.8L18 8.4l-4.4 1.6L12 15l-1.6-5L6 8.4l4.4-1.6L12 2zm6 10l.9 2.6 2.6.9-2.6.9L18 19l-.9-2.6-2.6-.9 2.6-.9L18 12zM6 13l.75 2.25L9 16l-2.25.75L6 19l-.75-2.25L3 16l2.25-.75L6 13z"></path>
                </svg>
                <span>Résultat du modèle</span>
            </div>

            <!-- 2. Pastille niveau (point lumineux + libellé) + phrase — rempli par afficherResultat(p) -->
            <div id="result-level" class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-[13px] font-semibold mb-2 bg-slate-100 text-slate-600">—</div>
            <p id="result-message" class="text-[19px] font-semibold leading-snug max-w-xs" style="color:#134E4A">—</p>

            <!-- 3. Avertissement — TOUJOURS affiché (encart ambre doux) -->
            <div class="mt-3 flex items-start gap-2.5 text-left px-3.5 py-2.5 rounded-2xl bg-amber-50/60 border border-amber-200/60 w-full">
                <svg class="w-4 h-4 text-amber-600 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 2L1 21h22L12 2zm0 5l7.5 13h-15L12 7zm-1 4v4h2v-4h-2zm0 5v2h2v-2h-2z"></path>
                </svg>
                <p class="text-[13px] text-slate-700 leading-snug">
                    <span class="font-medium text-slate-800">Ne modifiez jamais votre dose vous-même.</span> Parlez-en à votre médecin ou à votre infirmier.
                </p>
            </div>

            <!-- 4. Mention bas de carte (disclaimer discret) -->
            <p class="mt-2 text-[11px] text-slate-400 font-normal">Prédiction indicative — ne remplace pas l'avis médical</p>
        </div>
    </div>

    <!-- Boutons de navigation sous la carte -->
    <div class="mt-auto px-4 pt-3 flex flex-col gap-2">
        <a href="<?= BASE_URL ?>doctors" class="h-11 rounded-2xl bg-gradient-to-r from-[#1EACA0] to-[#12897F] text-white font-bold text-[14px] shadow-teal-glow flex items-center justify-center gap-2 active:scale-95 transition">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
            Prendre rendez-vous avec un médecin
        </a>
        <a href="<?= BASE_URL ?>doza" class="h-10 rounded-2xl bg-white/80 border border-teal-200/60 text-teal-700 font-semibold text-[13px] flex items-center justify-center gap-2 hover:bg-white active:scale-95 transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path d="M4 4v6h6M20 20v-6h-6" stroke-linecap="round" stroke-linejoin="round"></path>
                <path d="M20 10a8 8 0 00-14.3-3.7L4 8M4 14a8 8 0 0014.3 3.7L20 16" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
            Refaire le test
        </a>
    </div>

    <!-- Contrôles audio flottants (plus compacts) -->
    <div class="pt-2.5 mb-1 flex items-center justify-center gap-5 px-4">
        <!-- Bouton pause : arrête la lecture audio -->
        <button aria-label="Arrêter la lecture" class="group w-12 h-12 rounded-full bg-white/90 backdrop-blur-md text-slate-700 shadow-pill-soft flex items-center justify-center active:scale-95 transition-transform" id="btn-pause" type="button">
            <svg class="w-5 h-5 text-slate-500 group-hover:text-teal-brand transition-colors" fill="currentColor" viewBox="0 0 24 24">
                <path d="M6 5h4v14H6zM14 5h4v14h-4z"></path>
            </svg>
        </button>

        <!-- Bouton principal : « 🔊 Écouter » (lecture audio à la demande) -->
        <div class="relative flex items-center justify-center">
            <div class="absolute -inset-1.5 rounded-full bg-teal-brand/25 blur-md animate-pulse"></div>
            <button aria-label="Écouter le résultat" class="relative h-12 px-6 rounded-full bg-gradient-to-br from-[#1EACA0] to-[#0F776E] text-white font-bold text-[14px] tracking-wide shadow-floating-btn flex items-center justify-center gap-2 active:scale-95 transition cursor-pointer" id="btn-ecouter" type="button">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M3 10v4a1 1 0 001 1h3l4 4V5L7 9H4a1 1 0 00-1 1zm13.5 2a4.5 4.5 0 00-2.5-4.03v8.05A4.5 4.5 0 0016.5 12zM14 3.23v2.06a7 7 0 010 13.42v2.06a9 9 0 000-17.54z"></path>
                </svg>
                <span>Écouter</span>
            </button>
        </div>

        <!-- Bouton fermeture : quitte l'écran (et stoppe l'audio) -->
        <button aria-label="Fermer" class="group w-12 h-12 rounded-full bg-white/90 backdrop-blur-md text-slate-700 shadow-pill-soft flex items-center justify-center active:scale-95 transition-transform" id="btn-cancel" type="button">
            <svg class="w-5 h-5 text-slate-500 group-hover:text-rose-500 transition-colors" fill="none" stroke="currentColor" stroke-width="2.4" viewBox="0 0 24 24">
                <path d="M6 6l12 12M18 6L6 18" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </button>
    </div>

    <!-- Barre d'accueil iOS -->
    <div aria-hidden="true" class="w-32 h-1 bg-slate-400/50 rounded-full mx-auto mt-2"></div>
</div>

<script>
  (function () {
    // ===== 1. Textes fixes =====
    // Avertissement : affiché en permanence ET lu à voix haute après le message principal.
    const AVERTISSEMENT = "Ne modifiez jamais votre dose vous-même. Parlez-en à votre médecin ou à votre infirmier.";

    // Phrase complète qui sera lue à voix haute. Remplie par afficherResultat().
    // On n'y met JAMAIS le pourcentage brut.
    let texteALire = "";

    // ===== 2. Récupération des éléments de la page =====
    const etat       = document.getElementById('listening-state'); // pastille d'état
    const niveauEl   = document.getElementById('result-level');    // pastille colorée (niveau)
    const messageEl  = document.getElementById('result-message');  // phrase principale
    const orbStage   = document.getElementById('orb-stage');       // orbe animé
    const btnEcouter = document.getElementById('btn-ecouter');
    const btnPause   = document.getElementById('btn-pause');
    const btnCancel  = document.getElementById('btn-cancel');

    // ===== 3. Fonction UNIQUE : afficher le résultat selon la probabilité p (0 à 1) =====
    // C'est ici qu'on branchera le vrai modèle plus tard (il suffit d'appeler afficherResultat(p)).
    function afficherResultat(p) {
      let titre, message, classes, dot;

      if (p < 0.35) {
        titre = 'Peu probable';
        message = "Votre dose d'insuline devrait probablement rester la même.";
        classes = 'bg-emerald-50 text-emerald-700 border border-emerald-200/70';
        dot = 'bg-emerald-500';
      } else if (p < 0.65) {
        titre = 'Possible';
        message = "Un ajustement de votre dose d'insuline est possible pendant votre séjour.";
        classes = 'bg-amber-50 text-amber-800 border border-amber-200/80';
        dot = 'bg-amber-500';
      } else {
        titre = 'Probable';
        message = "Un ajustement de votre dose d'insuline est probable pendant votre séjour.";
        classes = 'bg-orange-50 text-orange-700 border border-orange-200/80';
        dot = 'bg-orange-500';
      }

      // Pastille niveau : point lumineux coloré + libellé (tons doux de la charte)
      niveauEl.className = 'inline-flex items-center gap-2 px-3 py-1 rounded-full text-[13px] font-semibold mb-2 ' + classes;
      niveauEl.innerHTML = '<span class="w-2 h-2 rounded-full ' + dot + ' animate-pulse"></span>' + titre;
      messageEl.textContent = message;

      // Texte lu à voix haute = niveau + message + avertissement (jamais le pourcentage)
      texteALire = titre + '. ' + message + ' ' + AVERTISSEMENT;
    }

    // ===== 4. Lecture audio (Web Speech API), uniquement au clic (pas d'auto-play) =====
    function ecouter() {
      if (!('speechSynthesis' in window)) {
        etat.textContent = "Audio non supporté par ce navigateur";
        return;
      }
      speechSynthesis.cancel(); // on stoppe une éventuelle lecture en cours

      const message = new SpeechSynthesisUtterance(texteALire);
      message.lang = 'fr-FR';
      message.rate = 0.9;

      // L'orbe s'anime pendant la lecture, puis s'arrête à la fin
      message.onstart = function () { orbStage.classList.add('is-speaking'); etat.textContent = 'Lecture en cours…'; };
      message.onend   = function () { orbStage.classList.remove('is-speaking'); etat.textContent = 'Lecture terminée'; };

      speechSynthesis.speak(message);
    }

    // ===== 5. Arrêt de la lecture (bouton pause) =====
    function arreterLecture() {
      speechSynthesis.cancel();
      orbStage.classList.remove('is-speaking');
      etat.textContent = 'Lecture arrêtée';
    }

    // ===== 6. Branchement des boutons =====
    if (btnEcouter) btnEcouter.addEventListener('click', ecouter);
    if (btnPause)   btnPause.addEventListener('click', arreterLecture);
    if (btnCancel)  btnCancel.addEventListener('click', function () {
      speechSynthesis.cancel(); // on coupe l'audio avant de quitter
      history.back();
    });

    // ===== 7. Affichage initial =====
    // p est fourni par le serveur (PHP) depuis l'URL ?p=... (défaut 0.70).
    afficherResultat(<?= json_encode($p) ?>);
  })();
</script>
