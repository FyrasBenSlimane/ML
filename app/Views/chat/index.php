<!-- ============ ÉCRAN "DOZA" — CONVERSATION GUIDÉE (collecte des entrées du modèle) ============ -->
<div class="relative w-full max-w-[400px] h-[844px] my-0 sm:my-6 flex flex-col voice-ambient overflow-hidden sm:rounded-[40px] shadow-2xl">

    <!-- Lueurs ambiantes menthe -->
    <div class="pointer-events-none absolute -top-16 -right-20 w-72 h-72 rounded-full bg-[#71F8E4]/40 blur-3xl -z-10"></div>
    <div class="pointer-events-none absolute top-1/3 -left-24 w-72 h-72 rounded-full bg-[#D0BCFF]/30 blur-3xl -z-10"></div>

    <!-- Barre d'état iOS -->
    <header class="shrink-0 px-6 pt-3 pb-1 flex justify-between items-center text-slate-900">
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

    <!-- En-tête : retour · Doza · profil -->
    <section class="shrink-0 px-5 py-2 flex items-center justify-between bg-white/40 backdrop-blur-md">
        <a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-11 h-11 rounded-full bg-white/70 backdrop-blur-md flex items-center justify-center text-slate-700 hover:text-teal-brand shadow-sm transition active:scale-95">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24">
                <path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path>
            </svg>
        </a>
        <h1 class="text-[19px] font-bold tracking-tight" style="color:#0F2E2B">Doza</h1>
        <div class="w-9 h-9 rounded-full bg-gradient-to-br from-[#1EACA0] to-[#12897F] flex items-center justify-center shadow-icon-soft">
            <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"></path>
            </svg>
        </div>
    </section>

    <!-- Indicateur de progression (masqué tant que la 1re question n'est pas posée) -->
    <div class="shrink-0 px-5 pt-1 pb-1 flex justify-center">
        <span id="progress" class="hidden text-[11px] font-semibold text-teal-700 bg-white/70 px-3 py-0.5 rounded-full shadow-sm"></span>
    </div>

    <!-- ===== Flux de conversation (rempli par le JS) ===== -->
    <main id="chat-stream" class="flex-1 overflow-y-auto no-scrollbar px-4 py-3 space-y-4">

        <!-- Badge de session (statique) -->
        <div class="flex items-center justify-center">
            <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/70 backdrop-blur-md border border-teal-200/50 shadow-sm">
                <span class="w-2 h-2 rounded-full bg-teal-brand animate-pulse"></span>
                <span class="text-[12px] font-medium text-teal-800">Session Doza</span>
            </div>
        </div>
        <!-- Les bulles de conversation sont ajoutées ici par le JS -->
    </main>

    <!-- Barre de saisie (texte libre désactivé : on répond via les chips) -->
    <div class="shrink-0 px-4 pb-5 pt-2">
        <div class="bg-white/90 backdrop-blur-xl rounded-full p-1.5 pl-2 shadow-[0_10px_24px_-4px_rgba(13,148,136,0.18)] flex items-center gap-2">
            <button aria-label="Ajouter" disabled class="w-10 h-10 rounded-full bg-teal-50 text-teal-800/40 flex items-center justify-center shrink-0 cursor-not-allowed">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.4" viewBox="0 0 24 24"><path d="M12 5v14M5 12h14" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            </button>
            <input disabled class="flex-1 bg-transparent text-[14px] text-slate-700 placeholder:text-slate-400 focus:outline-none px-1 cursor-not-allowed" placeholder="Choisissez une réponse ci-dessus" type="text">
            <button aria-label="Micro (bientôt disponible)" disabled class="w-10 h-10 rounded-full bg-slate-200 text-slate-400 flex items-center justify-center shrink-0 cursor-not-allowed">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3zm5-3c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"></path>
                </svg>
            </button>
        </div>
    </div>
</div>

<!-- Modèle de prédiction (mock, remplaçable par une API Python plus tard) -->
<script src="<?= ASSETS_URL ?>/js/model.js"></script>
<script>
  (function () {
    const BASE   = '<?= BASE_URL ?>';
    const stream = document.getElementById('chat-stream');
    const progressEl = document.getElementById('progress');

    // Mode vocal : activé uniquement si l'URL contient ?voice=1 (choix explicite du patient).
    // Dans ce mode, chaque question de Doza est lue automatiquement à voix haute.
    const VOICE = new URLSearchParams(location.search).get('voice') === '1';

    // ===== Script de la conversation =====
    // Étape 0 = porte d'entrée (insuline). Étapes 1 à 9 = questions du modèle.
    const FLOW = [
      { gate: true, texte: "Bonjour 👋 Je suis Doza. Prenez-vous de l'insuline ?",
        reponses: [ {label:'Oui', value:'oui'}, {label:'Non', value:'non'} ] },

      { key:'age_ordinal', texte:"Quel âge avez-vous ?",
        reponses:[ {label:'18–39',value:3},{label:'40–49',value:4},{label:'50–59',value:5},
                   {label:'60–69',value:6},{label:'70–79',value:7},{label:'80+',value:8} ] },

      { key:'gender', texte:"Vous êtes…",
        reponses:[ {label:'Homme',value:1},{label:'Femme',value:0} ] },

      { key:'admission_type_id', texte:"Votre hospitalisation était…",
        reponses:[ {label:'En urgence',value:1},{label:'Urgente non vitale',value:2},
                   {label:'Programmée',value:3},{label:'Je ne sais pas',value:0} ] },

      { key:'admission_source_id', texte:"Comment êtes-vous arrivé à l'hôpital ?",
        reponses:[ {label:'Par les urgences',value:7},{label:'Envoyé par mon médecin',value:1},
                   {label:"Transféré d'un autre établissement",value:6},{label:'Autre',value:0} ] },

      { key:'diag_1_group', texte:"Pour quelle raison principale êtes-vous hospitalisé ?",
        reponses:[ {label:'Diabète',value:'Diabetes'},{label:'Cœur / vaisseaux',value:'Circulatory'},
                   {label:'Poumons',value:'Respiratory'},{label:'Digestif',value:'Digestive'},
                   {label:'Reins / urinaire',value:'Genitourinary'},{label:'Os / articulations',value:'Musculoskeletal'},
                   {label:'Chute / blessure',value:'Injury'},{label:'Cancer',value:'Neoplasms'},
                   {label:'Autre',value:'Other'} ] },

      { key:'number_emergency', texte:"Combien de fois êtes-vous allé aux urgences cette année ?",
        reponses:[ {label:'0',value:0},{label:'1',value:1},{label:'2',value:2},{label:'3 ou plus',value:3} ] },

      { key:'number_inpatient', texte:"Combien de fois avez-vous été hospitalisé cette année ?",
        reponses:[ {label:'0',value:0},{label:'1',value:1},{label:'2',value:2},{label:'3 ou plus',value:3} ] },

      { key:'number_outpatient', texte:"Combien de consultations à l'hôpital avez-vous eues cette année ?",
        reponses:[ {label:'0',value:0},{label:'1–2',value:2},{label:'3–5',value:4},{label:'6 ou plus',value:6} ] },

      { key:'A1Cresult', texte:"Connaissez-vous votre dernière HbA1c (hémoglobine glyquée) ?",
        reponses:[ {label:'Moins de 7 %',value:1},{label:'Entre 7 et 8 %',value:2},
                   {label:'Plus de 8 %',value:3},{label:'Je ne sais pas',value:0} ] },
    ];

    // Réponses collectées (c'est ce qui sera envoyé au modèle)
    const answers = {};

    // ===== Petits utilitaires =====
    function scrollBas() { stream.scrollTop = stream.scrollHeight; }

    function majProgression(i) {
      // i = numéro d'étape (0 = porte). On affiche "Question n / 9" pour les étapes 1 à 9.
      if (i >= 1 && i <= 9) {
        progressEl.textContent = 'Question ' + i + ' / 9';
        progressEl.classList.remove('hidden');
      } else {
        progressEl.classList.add('hidden');
      }
    }

    // Lecture à voix haute d'un texte (fr-FR), déclenchée au clic uniquement
    function lire(texte) {
      if (!('speechSynthesis' in window)) return;
      speechSynthesis.cancel();
      const u = new SpeechSynthesisUtterance(texte);
      u.lang = 'fr-FR';
      u.rate = 0.9;
      speechSynthesis.speak(u);
    }

    // ===== Création des bulles =====
    // Bulle de Doza (question) + petit bouton 🔊
    function bulleDoza(texte, step) {
      const ligne = document.createElement('div');
      ligne.className = 'flex items-start gap-2.5 max-w-[90%]';
      ligne.dataset.step = step;
      ligne.innerHTML =
        '<div class="w-9 h-9 rounded-full overflow-hidden shadow-sm shrink-0 mt-1 border border-white">' +
          '<img src="<?= ASSETS_URL ?>/img/doctor5.jpg" alt="Doza" class="w-full h-full object-cover object-top">' +
        '</div>' +
        '<div class="bg-white/90 backdrop-blur-md rounded-2xl rounded-tl-sm p-4 shadow-sm flex items-start gap-2">' +
          '<p class="text-[14px] leading-relaxed" style="color:#134E4A"></p>' +
          '<button aria-label="Écouter la question" class="shrink-0 text-teal-brand/70 hover:text-teal-brand mt-0.5" type="button">' +
            '<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M3 10v4a1 1 0 001 1h3l4 4V5L7 9H4a1 1 0 00-1 1zm13.5 2A4.5 4.5 0 0014 7.97v8.05A4.5 4.5 0 0016.5 12z"></path></svg>' +
          '</button>' +
        '</div>';
      // texte (via textContent pour éviter tout souci de caractères)
      ligne.querySelector('p').textContent = texte;
      // bouton écouter
      ligne.querySelector('button').addEventListener('click', function () { lire(texte); });
      stream.appendChild(ligne);
      scrollBas();
      // Mode vocal : lecture automatique de la question
      if (VOICE) { lire(texte); }
    }

    // Rangée de chips de réponse (sous la question)
    function chipsReponse(step) {
      const zone = document.createElement('div');
      zone.className = 'flex flex-wrap justify-end gap-2 pl-11';
      zone.id = 'chips-' + step;
      zone.dataset.step = step;
      FLOW[step].reponses.forEach(function (rep) {
        const chip = document.createElement('button');
        chip.type = 'button';
        chip.className = 'px-3.5 py-1.5 rounded-full bg-white/90 backdrop-blur-sm text-teal-800 text-[12.5px] font-medium shadow-sm border border-teal-200/50 hover:bg-teal-50 active:scale-95 transition';
        chip.textContent = rep.label;
        chip.addEventListener('click', function () { repondre(step, rep); });
        zone.appendChild(chip);
      });
      stream.appendChild(zone);
      scrollBas();
    }

    // Bulle du patient (réponse) — cliquable pour corriger
    function bullePatient(label, step) {
      const ligne = document.createElement('div');
      ligne.className = 'flex flex-col items-end self-end max-w-[85%] ml-auto';
      ligne.dataset.step = step;
      ligne.innerHTML =
        '<div class="group bg-teal-primary text-white rounded-2xl rounded-tr-sm px-4 py-2.5 shadow-sm cursor-pointer active:scale-95 transition" title="Cliquer pour modifier cette réponse">' +
          '<span class="text-[14px]"></span>' +
          '<span class="ml-2 text-[10px] opacity-70">✎</span>' +
        '</div>';
      ligne.querySelector('span').textContent = label;
      ligne.querySelector('div').addEventListener('click', function () { modifier(step); });
      stream.appendChild(ligne);
      scrollBas();
    }

    // Message simple de Doza (sans chips) — ex. arrêt ou chargement
    function messageDoza(html, id) {
      const ligne = document.createElement('div');
      ligne.className = 'flex items-start gap-2.5 max-w-[90%]';
      if (id) ligne.id = id;
      ligne.dataset.step = 0;
      ligne.innerHTML =
        '<div class="w-9 h-9 rounded-full overflow-hidden shadow-sm shrink-0 mt-1 border border-white">' +
          '<img src="<?= ASSETS_URL ?>/img/doctor5.jpg" alt="Doza" class="w-full h-full object-cover object-top">' +
        '</div>' +
        '<div class="bg-white/90 backdrop-blur-md rounded-2xl rounded-tl-sm p-4 shadow-sm">' + html + '</div>';
      stream.appendChild(ligne);
      scrollBas();
    }

    // ===== Enchaînement =====
    function poserQuestion(i) {
      if (i >= FLOW.length) { finir(); return; }
      majProgression(i);
      bulleDoza(FLOW[i].texte, i);
      chipsReponse(i);
    }

    function repondre(i, rep) {
      // On retire les chips de cette question
      const z = document.getElementById('chips-' + i);
      if (z) z.remove();

      // Bulle patient (réponse affichée)
      bullePatient(rep.label, i);

      // Cas particulier : porte d'entrée (insuline)
      if (FLOW[i].gate) {
        if (rep.value === 'non') {
          majProgression(-1); // on cache la progression
          messageDoza('<p class="text-[14px] leading-relaxed" style="color:#134E4A">Cet outil concerne les patients traités par insuline. Parlez-en à votre médecin.</p>');
          return; // on s'arrête, pas de prédiction
        }
        poserQuestion(i + 1);
        return;
      }

      // Questions normales : on stocke la valeur
      answers[FLOW[i].key] = rep.value;
      poserQuestion(i + 1);
    }

    // Correction : on repart de la question i (on supprime tout ce qui suit)
    function modifier(i) {
      // Supprime toutes les bulles/chips des étapes >= i
      stream.querySelectorAll('[data-step]').forEach(function (el) {
        if (parseInt(el.dataset.step, 10) >= i) el.remove();
      });
      // Efface les réponses des étapes >= i
      for (let j = i; j < FLOW.length; j++) {
        if (FLOW[j].key) delete answers[FLOW[j].key];
      }
      // Repose la question
      poserQuestion(i);
    }

    // Fin : analyse puis redirection vers l'écran de résultat
    function finir() {
      majProgression(-1);
      messageDoza(
        '<div class="flex items-center gap-2">' +
          '<p class="text-[14px]" style="color:#134E4A">Merci ! J\'analyse vos réponses…</p>' +
          '<span class="flex gap-1">' +
            '<span class="w-1.5 h-1.5 rounded-full bg-teal-brand animate-bounce"></span>' +
            '<span class="w-1.5 h-1.5 rounded-full bg-teal-brand animate-bounce" style="animation-delay:.15s"></span>' +
            '<span class="w-1.5 h-1.5 rounded-full bg-teal-brand animate-bounce" style="animation-delay:.3s"></span>' +
          '</span>' +
        '</div>'
      );

      // Appel du modèle (mock), enregistrement en base, puis redirection résultat
      setTimeout(function () {
        const p = predictDose(answers);
        const aller = function () { window.location = BASE + 'doza/resultat?p=' + p; };

        // Sauvegarde de la session (question du patient + réponse du modèle).
        // On redirige dans tous les cas, même si la base n'est pas disponible.
        fetch(BASE + 'doza/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ answers: answers, p: p })
        }).then(aller, aller);
      }, 1300);
    }

    // ===== Démarrage de la conversation =====
    poserQuestion(0);
  })();
</script>
