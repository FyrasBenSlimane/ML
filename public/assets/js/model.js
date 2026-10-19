/* ===================================================================
   model.js — Modèle de prédiction "Doza"
   -------------------------------------------------------------------
   predictDose(answers) : renvoie une probabilité p (0 à 1) que la dose
   d'insuline soit modifiée pendant le séjour.

   ⚠️ VERSION MOCK : ces règles imitent l'arbre de décision pour la démo.
   Plus tard, cette fonction sera remplacée par un appel à l'API Python :

       async function predictDose(answers) {
         const r = await fetch('/predict', {
           method: 'POST',
           headers: { 'Content-Type': 'application/json' },
           body: JSON.stringify(answers)
         });
         const data = await r.json();
         return data.p;
       }
   =================================================================== */
function predictDose(answers) {
    // Règle 1 : transfert d'un autre établissement → peu probable
    if (answers.admission_source_id === 6) {
        return 0.25;
    }
    // Règle 2 : motif principal = diabète et patient plus âgé → probable
    if (answers.diag_1_group === "Diabetes" && answers.age_ordinal >= 2) {
        return 0.70;
    }
    // Règle 3 : au moins un passage aux urgences cette année → possible
    if (answers.number_emergency >= 1) {
        return 0.55;
    }
    // Sinon : plutôt stable
    return 0.30;
}
