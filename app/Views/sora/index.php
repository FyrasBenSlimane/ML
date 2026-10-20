<!DOCTYPE html><html class="h-full" lang="fr"><head>
<meta charset="utf-8">
<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" name="viewport">
<title>Sora Santé - Fiche Patient (Serene Pulse)</title>
<!-- Tailwind CSS CDN with plugins -->
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<!-- Google Fonts: Plus Jakarta Sans -->
<link href="https://fonts.googleapis.com" rel="preconnect">
<link crossorigin="" href="https://fonts.gstatic.com" rel="preconnect">
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet">
<!-- Tailwind Configuration -->
<script>
    tailwind.config = {
      theme: {
        extend: {
          fontFamily: {
            sans: ['"Plus Jakarta Sans"', 'system-ui', '-apple-system', 'sans-serif'],
          },
          colors: {
            serene: {
              50: '#f0fdfa', 100: '#ccfbf1', 200: '#99f6e4', 300: '#5eead4', 400: '#2dd4bf',
              500: '#14b8a6', 600: '#0d9488', 700: '#0f766e', 800: '#115e59', 900: '#134e4a',
            },
            peach: { 50: '#fffbf7', 100: '#fff4eb', 200: '#ffe6d3' }
          },
          boxShadow: {
            'neu-outer': '10px 10px 24px rgba(13, 148, 136, 0.08), -10px -10px 24px rgba(255, 255, 255, 0.95), 0 4px 14px rgba(15, 118, 110, 0.06)',
            'neu-card': '0 20px 35px -8px rgba(15, 118, 110, 0.08), 0 0 0 1px rgba(255, 255, 255, 0.9) inset, 0 1px 3px rgba(0, 0, 0, 0.03)',
            'neu-inset': 'inset 2px 2px 5px rgba(15, 118, 110, 0.07), inset -2px -2px 5px rgba(255, 255, 255, 0.95)',
            'neu-inset-focus': 'inset 2px 2px 6px rgba(13, 148, 136, 0.14), inset -2px -2px 6px rgba(255, 255, 255, 1), 0 0 0 2px rgba(20, 184, 166, 0.35)',
            'neu-btn': '0 10px 20px -3px rgba(13, 148, 136, 0.45), 0 4px 6px -2px rgba(13, 148, 136, 0.3), inset 0 1px 0 rgba(255, 255, 255, 0.35)',
            'neu-dock': '0 18px 30px -4px rgba(15, 118, 110, 0.16), 0 6px 12px -2px rgba(0, 0, 0, 0.04), 0 0 0 1px rgba(255, 255, 255, 0.85) inset'
          }
        }
      }
    }
  </script>
<style data-purpose="neumorphic-custom-surfaces">
    .bg-medical-pattern {
      background-image:
        radial-gradient(circle at 18% 12%, rgba(20, 184, 166, 0.18) 0%, transparent 45%),
        radial-gradient(circle at 88% 30%, rgba(254, 215, 170, 0.28) 0%, transparent 40%),
        radial-gradient(circle at 80% 85%, rgba(253, 186, 116, 0.22) 0%, transparent 45%),
        radial-gradient(circle at 15% 82%, rgba(45, 212, 191, 0.22) 0%, transparent 50%),
        radial-gradient(#14b8a6 0.75px, transparent 0.75px);
      background-size: 100% 100%, 100% 100%, 100% 100%, 100% 100%, 26px 26px;
    }
    @keyframes soft-glow { 0%,100% { transform: scale(1); opacity: 0.35; } 50% { transform: scale(1.05); opacity: 0.55; } }
    .animate-serene-glow { animation: soft-glow 8s ease-in-out infinite; }
    select { -webkit-appearance: none; -moz-appearance: none; appearance: none; }
    .no-scrollbar::-webkit-scrollbar { display: none; }
    .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
  </style>
</head>
<body class="bg-gradient-to-b from-[#e6fbf7] via-[#f2faf7] to-[#fbeee6] text-slate-800 antialiased font-sans min-h-screen flex justify-center selection:bg-serene-200 selection:text-serene-900">
<div class="relative w-full max-w-md min-h-screen bg-medical-pattern overflow-x-hidden flex flex-col justify-between pb-28 pt-3 px-4 sm:px-5" data-purpose="mobile-viewport">
<!-- Background ambient motifs -->
<div aria-hidden="true" class="pointer-events-none absolute -top-16 -left-16 w-64 h-64 rounded-full bg-teal-200/40 blur-3xl animate-serene-glow"></div>
<div aria-hidden="true" class="pointer-events-none absolute top-1/3 -right-20 w-72 h-72 rounded-full bg-orange-200/45 blur-3xl animate-serene-glow" style="animation-delay: -3s;"></div>
<div aria-hidden="true" class="pointer-events-none absolute bottom-24 -left-10 w-60 h-60 rounded-full bg-teal-300/30 blur-2xl"></div>

<!-- Header -->
<header class="relative z-10 w-full pt-1 pb-3">
<div class="flex items-center justify-between mt-1 px-1">
<a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-10 h-10 rounded-2xl bg-white/80 border border-white/90 shadow-sm flex items-center justify-center text-teal-800 hover:bg-white active:scale-95 transition-all">
<svg class="w-5 h-5 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M15.75 19.5L8.25 12l7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg>
</a>
<div class="text-center">
<div class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-teal-500/10 border border-teal-500/20 text-serene-700 text-[10px] font-bold tracking-wider uppercase mb-0.5">
<span class="w-1.5 h-1.5 rounded-full bg-serene-500 animate-ping"></span>Sora | Santé • IA
</div>
<h1 class="text-xl font-extrabold text-slate-800 tracking-tight">Fiche patient</h1>
</div>
<button aria-label="Aide et informations" type="button" class="w-10 h-10 rounded-2xl bg-white/80 border border-white/90 shadow-sm flex items-center justify-center text-teal-800 hover:bg-white active:scale-95 transition-all"><svg class="w-5 h-5 stroke-[2]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M12 18h.01" stroke-linecap="round" stroke-linejoin="round"></path></svg></button>
</div>

<!-- Quick presets -->
<section class="mt-4 px-1" data-purpose="quick-presets">
<div class="flex items-center justify-between mb-2 px-1">
<span class="text-xs font-semibold text-slate-600 tracking-wide">Exemples rapides :</span>
<span class="text-[11px] text-serene-600 font-medium">Préremplissage ⚡</span>
</div>
<div class="flex items-center gap-2 overflow-x-auto pb-1 no-scrollbar text-xs">
<button type="button" class="shrink-0 px-3.5 py-1.5 rounded-full font-semibold shadow-sm border hover:bg-teal-50 transition active:scale-95 bg-white text-serene-800 border-teal-300/80">Peu complexe</button>
<button type="button" class="shrink-0 px-3.5 py-1.5 rounded-full bg-white/85 text-slate-700 font-medium shadow-sm border border-white/90 hover:bg-white transition active:scale-95">Très complexe</button>
<button type="button" class="shrink-0 px-3.5 py-1.5 rounded-full bg-white/85 text-slate-700 font-medium shadow-sm border border-white/90 hover:bg-white transition active:scale-95">Jeune sous insuline</button>
</div>
</section>
</header>

<!-- Form -->
<main class="relative z-10 mt-1 flex-1">
<form class="bg-white/95 backdrop-blur-xl rounded-[28px] p-5 shadow-neu-card border border-white/80" id="patient-clinical-form">
<div class="grid grid-cols-2 gap-3.5 sm:gap-4">
<div class="flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="age-select">Âge</label>
<div class="relative">
<select class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 pr-8 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition cursor-pointer" id="age-select" name="age">
<option value="[60-70]">[60-70]</option>
<option selected value="[70-80]">[70-80]</option>
<option value="[80-90]">[80-90]</option>
<option value="[90-100]">[90-100]</option>
</select>
<div class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-serene-700"><svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19.5 8.25l-7.5 7.5-7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg></div>
</div>
</div>
<div class="flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5 truncate" for="hosp-days">Jours d'hospitalisation</label>
<input class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition" id="hosp-days" min="0" name="hosp_days" type="number" value="4">
</div>
<div class="flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5 truncate" for="medications-count">Médicaments</label>
<input class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition" id="medications-count" min="0" name="medications_count" type="number" value="14">
</div>
<div class="flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5 truncate" for="diagnostics-count">Diagnostics</label>
<input class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition" id="diagnostics-count" min="0" name="diagnostics_count" type="number" value="7">
</div>
<div class="col-span-2 flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="primary-diagnosis">Diagnostic principal</label>
<div class="relative">
<select class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 pr-8 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition cursor-pointer" id="primary-diagnosis" name="primary_diagnosis">
<option selected value="Circulatory">Circulatory</option>
<option value="Diabetes">Diabetes</option>
<option value="Respiratory">Respiratory</option>
<option value="Digestive">Digestive</option>
<option value="Injury">Injury</option>
</select>
<div class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-serene-700"><svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19.5 8.25l-7.5 7.5-7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg></div>
</div>
</div>
<div class="col-span-2 flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="serum-glucose-max">Glycémie sérique max</label>
<div class="relative">
<select class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 pr-8 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition cursor-pointer" id="serum-glucose-max" name="serum_glucose_max">
<option selected value="Not_Tested">Not_Tested</option>
<option value="Norm">Norm</option>
<option value="&gt;200">&gt;200</option>
<option value="&gt;300">&gt;300</option>
</select>
<div class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-serene-700"><svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19.5 8.25l-7.5 7.5-7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg></div>
</div>
</div>
<div class="flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="antidiabetic-select">Antidiabétique</label>
<div class="relative">
<select class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 pr-8 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition cursor-pointer" id="antidiabetic-select" name="antidiabetic">
<option selected value="Oui">Oui</option>
<option value="Non">Non</option>
</select>
<div class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-serene-700"><svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19.5 8.25l-7.5 7.5-7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg></div>
</div>
</div>
<div class="flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="insulin-select">Insuline</label>
<div class="relative">
<select class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 pr-8 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition cursor-pointer" id="insulin-select" name="insulin">
<option selected value="Oui">Oui</option>
<option value="Non">Non</option>
<option value="Up">Up</option>
<option value="Down">Down</option>
</select>
<div class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-serene-700"><svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19.5 8.25l-7.5 7.5-7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg></div>
</div>
</div>
<div class="col-span-2 flex flex-col">
<label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="metformin-select">Metformine</label>
<div class="relative">
<select class="w-full h-11 bg-slate-50/70 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 pr-8 border border-slate-200/80 shadow-neu-inset focus:border-serene-500 focus:bg-white focus:ring-0 transition cursor-pointer" id="metformin-select" name="metformin">
<option selected value="Oui">Oui</option>
<option value="Non">Non</option>
<option value="Steady">Steady</option>
</select>
<div class="pointer-events-none absolute inset-y-0 right-3.5 flex items-center text-serene-700"><svg class="w-4 h-4 stroke-[2.5]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19.5 8.25l-7.5 7.5-7.5-7.5" stroke-linecap="round" stroke-linejoin="round"></path></svg></div>
</div>
</div>
</div>
</form>

<div class="mt-4 px-1">
<button class="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-serene-600 via-serene-600 to-serene-700 text-white font-bold text-base shadow-neu-btn hover:brightness-105 active:scale-[0.98] transition-all flex items-center justify-center gap-2.5" id="btn-submit-profile" type="button">
<span>Obtenir le profil</span>
<svg class="w-5 h-5 text-teal-200" fill="currentColor" viewBox="0 0 20 20"><path clip-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" fill-rule="evenodd"></path></svg>
</button>
</div>
</main>

<!-- Bottom navigation -->
<nav aria-label="Navigation principale" class="fixed bottom-4 left-0 right-0 max-w-sm mx-auto px-4 z-40">
<div class="bg-white/95 backdrop-blur-xl border border-white/90 rounded-3xl py-2 px-3 shadow-neu-dock flex items-center justify-around">
<a class="flex flex-col items-center justify-center py-1 px-3 text-slate-500 hover:text-serene-700 transition group" href="<?= BASE_URL ?>">
<span class="text-xl group-hover:scale-110 transition-transform">🏡</span>
<span class="text-[11px] font-semibold mt-0.5 text-slate-500 group-hover:text-serene-700">Accueil</span>
</a>
<a aria-current="page" class="flex flex-col items-center justify-center py-1.5 px-5 rounded-2xl bg-gradient-to-r from-serene-600 to-serene-700 text-white shadow-md shadow-serene-700/30" href="<?= BASE_URL ?>sora">
<span class="text-lg">📋</span>
<span class="text-[11px] font-bold tracking-tight">Patient</span>
</a>
<a class="flex flex-col items-center justify-center py-1 px-3 text-slate-500 hover:text-serene-700 transition group" href="<?= BASE_URL ?>profile">
<span class="text-xl group-hover:scale-110 transition-transform">💚</span>
<span class="text-[11px] font-semibold mt-0.5 text-slate-500 group-hover:text-serene-700">Profil</span>
</a>
</div>
</nav>
</div>

<!-- Interactive logic for presets -->
<script>
    document.addEventListener('DOMContentLoaded', () => {
      const presetButtons = document.querySelectorAll('[data-purpose="quick-presets"] button');
      const f = {
        age: document.getElementById('age-select'),
        hospDays: document.getElementById('hosp-days'),
        medications: document.getElementById('medications-count'),
        diagnostics: document.getElementById('diagnostics-count'),
        diagnosis: document.getElementById('primary-diagnosis'),
        glucose: document.getElementById('serum-glucose-max'),
        antidiabetic: document.getElementById('antidiabetic-select'),
        insulin: document.getElementById('insulin-select'),
        metformin: document.getElementById('metformin-select'),
      };
      const presetData = {
        'Peu complexe':        { age: '[70-80]', hospDays: '4',  medications: '14', diagnostics: '7',  diagnosis: 'Circulatory', glucose: 'Not_Tested', antidiabetic: 'Oui', insulin: 'Oui',  metformin: 'Oui' },
        'Très complexe':       { age: '[80-90]', hospDays: '12', medications: '22', diagnostics: '11', diagnosis: 'Respiratory', glucose: '>200',       antidiabetic: 'Oui', insulin: 'Up',   metformin: 'Non' },
        'Jeune sous insuline': { age: '[60-70]', hospDays: '2',  medications: '6',  diagnostics: '3',  diagnosis: 'Diabetes',    glucose: '>300',       antidiabetic: 'Non', insulin: 'Oui',  metformin: 'Non' }
      };
      presetButtons.forEach((btn) => {
        btn.addEventListener('click', () => {
          presetButtons.forEach(b => {
            b.classList.remove('bg-white', 'text-serene-800', 'border-teal-300/80');
            b.classList.add('bg-white/85', 'text-slate-700', 'border-white/90');
          });
          btn.classList.add('bg-white', 'text-serene-800', 'border-teal-300/80');
          btn.classList.remove('bg-white/85', 'text-slate-700', 'border-white/90');
          const data = presetData[btn.textContent.trim()];
          if (data) {
            f.age.value = data.age; f.hospDays.value = data.hospDays; f.medications.value = data.medications;
            f.diagnostics.value = data.diagnostics; f.diagnosis.value = data.diagnosis; f.glucose.value = data.glucose;
            f.antidiabetic.value = data.antidiabetic; f.insulin.value = data.insulin; f.metformin.value = data.metformin;
          }
        });
      });

      // "Obtenir le profil" -> collecte les champs saisis et ouvre l'ecran "Profil du patient".
      const btnProfil = document.getElementById('btn-submit-profile');
      if (btnProfil) {
        btnProfil.addEventListener('click', () => {
          const fiche = {
            age: f.age.value, hosp_days: +f.hospDays.value || 0, medications: +f.medications.value || 0,
            diagnostics: +f.diagnostics.value || 0, diagnosis: f.diagnosis.value, glucose: f.glucose.value,
            antidiabetic: f.antidiabetic.value, insulin: f.insulin.value, metformin: f.metformin.value
          };
          try { sessionStorage.setItem('sora_fiche', JSON.stringify(fiche)); } catch (e) {}
          window.location = '<?= BASE_URL ?>sora/profil';
        });
      }
    });
  </script>
</body></html>
