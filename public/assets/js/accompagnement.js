/* ===================================================================
   accompagnement.js — écran "Compagnon du quotidien"
   -------------------------------------------------------------------
   Envoie les 8 champs du formulaire à l'API Python (POST /accompagnement)
   et affiche le résultat (bien / mal contrôlé + message), ou une erreur
   claire si l'API n'est pas lancée.

   L'API tourne sur un autre port que le site PHP :
       uvicorn main:app --app-dir api --port 8001
   =================================================================== */
const ACCOMP_API = 'http://127.0.0.1:8001';

document.addEventListener('DOMContentLoaded', function () {
  const form   = document.getElementById('accomp-form');
  const result = document.getElementById('accomp-result');
  const btn    = document.getElementById('accomp-submit');
  const label  = document.getElementById('accomp-submit-label');

  const val = (id) => document.getElementById(id).value;
  const num = (id) => parseInt(val(id), 10);

  function carte(couleurBg, couleurTxt, html) {
    result.className = 'mt-4 rounded-3xl p-4 border shadow-soft-card ' + couleurBg;
    result.innerHTML = '<div class="' + couleurTxt + '">' + html + '</div>';
    result.classList.remove('hidden');
    result.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }

  function erreur(message) {
    carte('bg-rose-50/80 border-rose-200/70', 'text-rose-700',
      '<p class="text-[13.5px] font-semibold">⚠️ ' + message + '</p>');
  }

  form.addEventListener('submit', async function (e) {
    e.preventDefault();

    const payload = {
      age: num('age'),
      time_in_hospital: num('time_in_hospital'),
      num_medications: num('num_medications'),
      number_diagnoses: num('number_diagnoses'),
      diabetesMed_num: num('diabetesMed_num'),
      insulin_prescrite: num('insulin_prescrite'),
      metformin_prescrite: num('metformin_prescrite'),
      diag_1_group: val('diag_1_group'),
    };

    btn.disabled = true;
    label.textContent = 'Analyse en cours…';

    let r;
    try {
      r = await fetch(ACCOMP_API + '/accompagnement', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
    } catch (netErr) {
      erreur("Impossible de joindre le service de prédiction. Vérifiez que l'API est lancée "
           + "(uvicorn main:app --app-dir api --port 8001), puis réessayez.");
      btn.disabled = false; label.textContent = 'Obtenir la recommandation';
      return;
    }

    const data = await r.json().catch(() => ({}));
    btn.disabled = false;
    label.textContent = 'Obtenir la recommandation';

    if (!r.ok) {
      // 422 = validation (detail = liste) ; 503 = modèle absent ; 500 = erreur interne.
      let msg = "Une erreur est survenue.";
      if (Array.isArray(data.detail))      msg = data.detail.map(d => d.msg).join(' ');
      else if (typeof data.detail === 'string') msg = data.detail;
      erreur(msg);
      return;
    }

    // Succès : carte colorée selon le résultat.
    const malControle = data.classe === 1;
    const bg  = malControle ? 'bg-amber-50/80 border-amber-200/70' : 'bg-emerald-50/80 border-emerald-200/70';
    const txt = malControle ? 'text-amber-800' : 'text-emerald-800';
    const dot = malControle ? 'bg-amber-500' : 'bg-emerald-500';

    carte(bg, txt,
        '<div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/70 text-[12px] font-bold mb-2">'
      +   '<span class="w-2 h-2 rounded-full ' + dot + ' animate-pulse"></span>' + data.resultat
      + '</div>'
      + '<p class="text-[16px] font-bold leading-snug">' + data.message + '</p>'
      + '<p class="text-[12.5px] text-slate-500 mt-2">Probabilité estimée de diabète mal contrôlé : '
      +   '<span class="font-bold text-slate-700">' + data.pourcentage + ' %</span> '
      +   '(seuil de décision : ' + Math.round(data.seuil * 100) + ' %).</p>'
      + '<p class="text-[11px] text-slate-400 mt-1.5">Aide à l\'orientation — ne remplace pas l\'avis d\'un médecin.</p>');
  });
});
