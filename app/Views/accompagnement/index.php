<!-- ============ ÉCRAN "ACCOMPAGNEMENT" (compagnon du quotidien) ============ -->
<div class="relative w-full max-w-md min-h-screen flex flex-col pb-40 screen-ambient">

    <!-- Barre d'état iOS -->
    <header class="sticky top-0 z-40 px-6 pt-3 pb-2 flex justify-between items-center text-slate-900 bg-white/40 backdrop-blur-md">
        <span class="text-xs font-semibold tracking-tight text-slate-800">9:41</span>
        <div class="flex items-center space-x-1.5 text-slate-800">
            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><rect height="6" rx="1" width="3" x="2" y="16"></rect><rect height="10" rx="1" width="3" x="7.5" y="12"></rect><rect height="15" rx="1" width="3" x="13" y="7"></rect><rect height="19" rx="1" width="3" x="18.5" y="3"></rect></svg>
            <svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 4c-5 0-9.27 2.16-12 5.5l12 12.5 12-12.5c-2.73-3.34-7-5.5-12-5.5z"></path></svg>
            <div class="w-5 h-2.5 border border-slate-700 rounded-sm p-0.5 flex items-center"><div class="h-full w-3/4 bg-slate-800 rounded-sm"></div></div>
        </div>
    </header>

    <!-- Navigation supérieure -->
    <section class="px-5 pt-3 pb-2 flex items-center justify-between">
        <a href="<?= BASE_URL ?>doctors" aria-label="Retour" class="w-10 h-10 rounded-2xl flex items-center justify-center text-slate-700 hover:bg-white/60 transition active:scale-95">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.2" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        </a>
        <h1 class="text-lg font-bold text-slate-800 tracking-tight">Accompagnement</h1>
        <span class="w-10 h-10"></span>
    </section>

    <!-- Intro -->
    <section class="px-5 mt-1">
        <div class="rounded-3xl p-4 bg-white/90 border border-teal-100/70 shadow-soft-card">
            <div class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-teal-brandLight text-teal-brandDark text-[10px] font-bold tracking-wider uppercase mb-2">
                <span class="w-1.5 h-1.5 rounded-full bg-teal-brand animate-pulse"></span> Compagnon du quotidien
            </div>
            <p class="text-[13.5px] text-slate-600 leading-relaxed">
                Répondez à quelques questions : l'outil estime si votre diabète est plutôt
                <span class="font-semibold text-slate-700">bien</span> ou
                <span class="font-semibold text-slate-700">mal contrôlé</span>, pour savoir si un
                <span class="font-semibold">programme pédagogique</span> (alimentation, activité physique)
                pourrait vous aider.
            </p>
        </div>
    </section>

    <!-- Formulaire -->
    <main class="px-5 mt-3">
        <form id="accomp-form" class="bg-white/95 rounded-3xl p-5 shadow-glass border border-white/80 space-y-3.5">
            <div class="grid grid-cols-2 gap-3.5">
                <!-- Tranche d'âge -->
                <div class="flex flex-col col-span-2">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="age">Tranche d'âge</label>
                    <select id="age" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                        <option value="0">0 – 10 ans</option>
                        <option value="1">10 – 20 ans</option>
                        <option value="2">20 – 30 ans</option>
                        <option value="3">30 – 40 ans</option>
                        <option value="4">40 – 50 ans</option>
                        <option value="5">50 – 60 ans</option>
                        <option value="6" selected>60 – 70 ans</option>
                        <option value="7">70 – 80 ans</option>
                        <option value="8">80 – 90 ans</option>
                        <option value="9">90 – 100 ans</option>
                    </select>
                </div>

                <!-- Jours d'hospitalisation -->
                <div class="flex flex-col">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="time_in_hospital">Jours d'hospitalisation</label>
                    <input id="time_in_hospital" type="number" min="1" max="14" value="4" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                </div>
                <!-- Nombre de médicaments -->
                <div class="flex flex-col">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="num_medications">Nombre de médicaments</label>
                    <input id="num_medications" type="number" min="1" max="81" value="14" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                </div>
                <!-- Nombre de diagnostics -->
                <div class="flex flex-col">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="number_diagnoses">Nombre de diagnostics</label>
                    <input id="number_diagnoses" type="number" min="1" max="16" value="7" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                </div>

                <!-- Motif principal -->
                <div class="flex flex-col">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="diag_1_group">Motif principal</label>
                    <select id="diag_1_group" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                        <?php foreach ($diagGroups as $val => $label): ?>
                        <option value="<?= $val ?>"<?= $val === 'Diabetes' ? ' selected' : '' ?>><?= htmlspecialchars($label) ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <!-- Traitements (oui / non) -->
                <div class="flex flex-col">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="diabetesMed_num">Traitement antidiabétique ?</label>
                    <select id="diabetesMed_num" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                        <option value="1" selected>Oui</option><option value="0">Non</option>
                    </select>
                </div>
                <div class="flex flex-col">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="insulin_prescrite">Insuline prescrite ?</label>
                    <select id="insulin_prescrite" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                        <option value="1" selected>Oui</option><option value="0">Non</option>
                    </select>
                </div>
                <div class="flex flex-col col-span-2">
                    <label class="text-[12px] font-semibold text-slate-600 mb-1.5" for="metformin_prescrite">Metformine prescrite ?</label>
                    <select id="metformin_prescrite" class="h-11 bg-slate-50 text-slate-800 text-sm font-semibold rounded-2xl px-3.5 border border-slate-200 focus:border-teal-brand focus:ring-2 focus:ring-teal-200 outline-none transition">
                        <option value="1" selected>Oui</option><option value="0">Non</option>
                    </select>
                </div>
            </div>

            <button type="submit" id="accomp-submit" class="w-full py-3.5 rounded-2xl bg-teal-primary text-white font-bold text-base shadow-teal-glow hover:bg-teal-brandDark active:scale-[0.98] transition flex items-center justify-center gap-2">
                <span id="accomp-submit-label">Obtenir la recommandation</span>
            </button>
        </form>

        <!-- Carte résultat (remplie par le JS) -->
        <div id="accomp-result" class="mt-4 hidden"></div>

        <!-- Avertissement + performance honnête -->
        <div class="mt-4 flex items-start gap-2.5 px-3.5 py-2.5 rounded-2xl bg-amber-50/70 border border-amber-200/70">
            <svg class="w-4 h-4 text-amber-600 shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L1 21h22L12 2zm0 5l7.5 13h-15L12 7zm-1 4v4h2v-4h-2zm0 5v2h2v-2h-2z"></path></svg>
            <p class="text-[12.5px] text-slate-600 leading-snug">
                <span class="font-semibold text-slate-800">Outil d'aide à l'orientation, ne remplace pas l'avis d'un médecin.</span>
                Performance modeste (ROC-AUC ≈ 0,69), apprise uniquement sur des patients ayant fait le test HbA1c.
            </p>
        </div>
    </main>

    <!-- Barre de navigation inférieure -->
    <nav class="fixed bottom-0 left-0 right-0 max-w-md mx-auto z-50 px-6 pt-2 pb-6 glass-nav rounded-t-[2.2rem] shadow-nav-bar flex items-center justify-around">
        <a href="<?= BASE_URL ?>" class="flex flex-col items-center text-slate-400 hover:text-teal-600 transition flex-1">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[10px] font-medium">Home</span>
        </a>
        <a href="<?= BASE_URL ?>doctors" class="flex flex-col items-center text-slate-400 hover:text-teal-600 transition flex-1">
            <svg class="w-5 h-5 mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-1.13a4 4 0 10-4-4 4 4 0 004 4z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
            <span class="text-[10px] font-medium">Médecins</span>
        </a>
        <a href="<?= BASE_URL ?>accompagnement" class="flex flex-col items-center text-teal-600 transition flex-1">
            <svg class="w-5 h-5 mb-0.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"></path></svg>
            <span class="text-[10px] font-semibold">Accompagnement</span>
        </a>
    </nav>
</div>

<script src="<?= ASSETS_URL ?>/js/accompagnement.js"></script>
