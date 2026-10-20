<!DOCTYPE html><html class="h-full" lang="fr"><head>
<meta charset="utf-8">
<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" name="viewport">
<title>Sora Santé - Profil du patient</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com" rel="preconnect">
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet">
<script>
    tailwind.config = { theme: { extend: {
      fontFamily: { sans: ['"Plus Jakarta Sans"', 'system-ui', 'sans-serif'] },
      colors: { serene: { 50:'#f0fdfa',100:'#ccfbf1',200:'#99f6e4',300:'#5eead4',400:'#2dd4bf',500:'#14b8a6',600:'#0d9488',700:'#0f766e',800:'#115e59',900:'#134e4a' } },
      boxShadow: {
        'neu-card': '0 20px 35px -8px rgba(15, 118, 110, 0.08), 0 0 0 1px rgba(255, 255, 255, 0.9) inset, 0 1px 3px rgba(0, 0, 0, 0.03)',
        'neu-inset': 'inset 2px 2px 5px rgba(15, 118, 110, 0.07), inset -2px -2px 5px rgba(255, 255, 255, 0.95)',
        'neu-dock': '0 18px 30px -4px rgba(15, 118, 110, 0.16), 0 6px 12px -2px rgba(0, 0, 0, 0.04), 0 0 0 1px rgba(255, 255, 255, 0.85) inset'
      }
    } } }
  </script>
<style>
    .bg-medical-pattern {
      background-image:
        radial-gradient(circle at 18% 12%, rgba(20,184,166,0.16) 0%, transparent 45%),
        radial-gradient(circle at 85% 20%, rgba(254,215,170,0.26) 0%, transparent 40%),
        radial-gradient(circle at 80% 88%, rgba(253,186,116,0.2) 0%, transparent 45%),
        radial-gradient(#14b8a6 0.75px, transparent 0.75px);
      background-size: 100% 100%, 100% 100%, 100% 100%, 26px 26px;
    }
    .gauge-arc { transition: stroke-dasharray .9s cubic-bezier(.22,1,.36,1); }
  </style>
</head>
<body class="bg-gradient-to-b from-[#e6fbf7] via-[#f2faf7] to-[#fbeee6] text-slate-800 antialiased font-sans min-h-screen flex justify-center selection:bg-serene-200">
<div class="relative w-full max-w-md min-h-screen bg-medical-pattern overflow-x-hidden flex flex-col pb-40 pt-3 px-4 sm:px-5">

<!-- Header -->
<header class="relative z-10 w-full pt-1 pb-2">
<div class="flex items-center justify-between mt-1 px-1">
<a href="<?= BASE_URL ?>sora" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/80 border border-white/90 shadow-sm flex items-center justify-center text-teal-800 hover:bg-white active:scale-95 transition">
<svg class="w-5 h-5 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M15.75 19.5L8.25 12l7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg>
</a>
<h1 class="text-xl font-extrabold text-slate-800 tracking-tight flex items-center gap-1.5">
<span class="text-serene-600">💚</span> Profil du patient
</h1>
<span class="w-10 h-10"></span>
</div>
</header>

<main class="relative z-10 flex-1 space-y-4">

<!-- Recommandation clinique -->
<div class="rounded-[26px] p-4 bg-white/95 shadow-neu-card border border-white/80">
<div class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-serene-500/10 border border-serene-500/20 text-serene-700 text-[10px] font-bold tracking-wider uppercase mb-2">
<span class="w-1.5 h-1.5 rounded-full bg-serene-500"></span> Recommandation clinique
</div>
<p id="reco-titre" class="text-[17px] font-bold text-slate-800 leading-snug">—</p>
<p id="reco-sous" class="text-[12.5px] text-slate-500 mt-1">—</p>
</div>

<!-- Double analyse : jauge + tuiles -->
<div class="rounded-[26px] p-4 bg-white/95 shadow-neu-card border border-white/80">
<div class="flex items-center justify-between mb-1">
<span class="text-[11px] font-bold tracking-wider uppercase text-slate-500">Double analyse algorithmique</span>
<span class="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-slate-100 text-slate-500">Modèle UCI-130</span>
</div>

<!-- Jauge circulaire -->
<div class="flex justify-center my-3">
<div class="relative w-44 h-44">
<svg class="w-44 h-44 -rotate-90" viewBox="0 0 120 120">
<circle cx="60" cy="60" r="52" fill="none" stroke="#e8f3f1" stroke-width="12"></circle>
<circle id="gauge" class="gauge-arc" cx="60" cy="60" r="52" fill="none" stroke="#0d9488" stroke-width="12" stroke-linecap="round" stroke-dasharray="0 400"></circle>
</svg>
<div class="absolute inset-0 flex flex-col items-center justify-center">
<span id="gauge-val" class="text-3xl font-extrabold text-slate-800">—</span>
<span id="gauge-label" class="text-[12px] font-bold text-serene-700">Renforcé</span>
<span class="text-[10px] text-slate-400">Statut actif</span>
</div>
</div>
</div>

<!-- Tuiles -->
<div class="grid grid-cols-2 gap-3">
<div class="rounded-2xl p-3 bg-slate-50/70 shadow-neu-inset text-center">
<p id="tile-suivi" class="text-xl font-extrabold text-slate-800">—</p>
<p id="tile-suivi-label" class="text-[12px] font-semibold text-slate-700">Suivi</p>
<p class="text-[10px] text-slate-400">seuil 23 %</p>
</div>
<div class="rounded-2xl p-3 bg-slate-50/70 shadow-neu-inset text-center">
<p id="tile-ctrl" class="text-xl font-extrabold text-slate-800">—</p>
<p id="tile-ctrl-label" class="text-[12px] font-semibold text-slate-700">Contrôle</p>
<p class="text-[10px] text-slate-400">seuil 43 %</p>
</div>
</div>
</div>

<!-- Niveau d'intervention -->
<div class="rounded-[26px] p-4 bg-white/95 shadow-neu-card border border-white/80">
<div class="flex items-center justify-between mb-2">
<span class="text-[12.5px] font-bold text-slate-700">Niveau d'intervention recommandé</span>
<span id="score" class="text-[11px] font-bold px-2 py-0.5 rounded-full bg-serene-500/10 text-serene-700">Score —/100</span>
</div>
<div class="relative h-3 rounded-full bg-gradient-to-r from-serene-300 via-amber-300 to-rose-400 shadow-neu-inset">
<div class="absolute top-[-3px] bottom-[-3px] w-0.5 bg-slate-500/70 rounded" style="left:23%"></div>
<div id="cursor" class="absolute -top-1 w-5 h-5 rounded-full bg-white border-2 border-serene-600 shadow-md -translate-x-1/2 transition-all" style="left:0%"></div>
</div>
<div class="flex justify-between mt-1.5 text-[10px] text-slate-400 font-medium">
<span>Suivi léger</span><span>Seuil 23 %</span><span>Suivi renforcé</span>
</div>
</div>

<p class="text-center text-[11px] text-slate-400 px-4">Outil d'aide à l'orientation, ne remplace pas l'avis d'un médecin.</p>
</main>

<!-- Bottom navigation -->
<nav aria-label="Navigation principale" class="fixed bottom-4 left-0 right-0 max-w-sm mx-auto px-4 z-40">
<div class="bg-white/95 backdrop-blur-xl border border-white/90 rounded-3xl py-2 px-3 shadow-neu-dock flex items-center justify-around">
<a class="flex flex-col items-center py-1 px-3 text-slate-500 hover:text-serene-700 transition" href="<?= BASE_URL ?>"><span class="text-xl">🏡</span><span class="text-[11px] font-semibold mt-0.5">Accueil</span></a>
<a class="flex flex-col items-center py-1 px-3 text-slate-500 hover:text-serene-700 transition" href="<?= BASE_URL ?>sora"><span class="text-xl">📋</span><span class="text-[11px] font-semibold mt-0.5">Patient</span></a>
<a aria-current="page" class="flex flex-col items-center py-1.5 px-5 rounded-2xl bg-gradient-to-r from-serene-600 to-serene-700 text-white shadow-md shadow-serene-700/30" href="<?= BASE_URL ?>sora/profil"><span class="text-lg">💚</span><span class="text-[11px] font-bold">Profil</span></a>
</div>
</nav>
</div>

<script>
  (function () {
    // Appel des VRAIS modèles Sora (M1 Suivi + M2 Contrôle) via l'API Python.
    const SORA_API = 'http://127.0.0.1:8001';
    const el = (id) => document.getElementById(id);
    const erreur = (msg) => { el('reco-titre').textContent = 'Résultat indisponible'; el('reco-sous').textContent = msg; };

    // Fiche saisie à l'écran précédent (défauts sinon).
    let fiche = { age:'[70-80]', hosp_days:4, medications:14, diagnostics:7, diagnosis:'Circulatory',
                  glucose:'Not_Tested', antidiabetic:'Oui', insulin:'Oui', metformin:'Oui' };
    try { const s = JSON.parse(sessionStorage.getItem('sora_fiche')); if (s) fiche = Object.assign(fiche, s); } catch (e) {}

    function afficher(r) {
      const suivi = r.suivi, ctrl = r.controle;
      const couleurSuivi = suivi.classe === 1 ? '#d97706' : '#0d9488'; // seuil 0,23 : renforcé=ambre, léger=teal
      const couleurCtrl  = ctrl.classe === 1 ? '#d97706' : '#0d9488';

      // Jauge (sur le suivi)
      const C = 2 * Math.PI * 52, arc = C * suivi.pourcentage / 100;
      const g = el('gauge'); g.setAttribute('stroke', couleurSuivi);
      setTimeout(() => g.setAttribute('stroke-dasharray', arc + ' ' + C), 60);
      el('gauge-val').textContent = suivi.pourcentage + '%';
      const gl = el('gauge-label'); gl.textContent = suivi.resultat; gl.style.color = couleurSuivi;

      // Tuiles
      el('tile-suivi').textContent = suivi.pourcentage + '%'; el('tile-suivi').style.color = couleurSuivi;
      el('tile-suivi-label').textContent = suivi.resultat;
      el('tile-ctrl').textContent = ctrl.pourcentage + '%'; el('tile-ctrl').style.color = couleurCtrl;
      el('tile-ctrl-label').textContent = ctrl.resultat;

      // Recommandation = profil combiné (M1 x M2)
      el('reco-titre').textContent = r.profil;
      el('reco-sous').textContent = 'Suivi : ' + suivi.resultat.toLowerCase()
                                  + ' · Contrôle : ' + ctrl.resultat.toLowerCase() + '.';

      // Niveau d'intervention (piloté par le suivi)
      el('score').textContent = 'Score ' + suivi.pourcentage + '/100';
      el('cursor').style.left = suivi.pourcentage + '%';
      el('cursor').style.borderColor = couleurSuivi;
    }

    (async function () {
      let res;
      try {
        res = await fetch(SORA_API + '/sora', {
          method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(fiche)
        });
      } catch (e) {
        erreur("Service de prédiction injoignable. Vérifiez que l'API est lancée (port 8001), puis réessayez.");
        return;
      }
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        let msg = 'Une erreur est survenue.';
        if (Array.isArray(data.detail)) msg = data.detail.map(d => d.msg).join(' ');
        else if (typeof data.detail === 'string') msg = data.detail;
        erreur(msg);
        return;
      }
      afficher(data);
    })();
  })();
</script>
</body></html>
