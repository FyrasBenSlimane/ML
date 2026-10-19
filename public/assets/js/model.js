/* ===================================================================
   model.js — Appel du modèle de prédiction "Doza"
   -------------------------------------------------------------------
   predictDose(answers) : interroge l'API Python (FastAPI) et renvoie
   l'objet résultat complet :
     { proba, pourcentage, classe, seuil, zone, pourquoi[], changerait[] }

   L'API tourne sur un autre port que le site PHP. La lancer depuis la
   racine du projet :
       uvicorn main:app --app-dir api --port 8001
   =================================================================== */
const DOZA_API = 'http://127.0.0.1:8001';

async function predictDose(answers) {
    const r = await fetch(DOZA_API + '/predict', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ answers: answers })
    });
    if (!r.ok) {
        throw new Error('API /predict a répondu ' + r.status);
    }
    return await r.json();
}
