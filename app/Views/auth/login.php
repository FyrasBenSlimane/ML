<!-- Applique le thème mémorisé le plus tôt possible (évite le flash clair → sombre). -->
<script>(function(){try{var t=localStorage.getItem('doza-theme');if(!t&&window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches){t='dark';}if(t==='dark'){document.documentElement.classList.add('dark');}}catch(e){}})();</script>

<style>
  /* MAAK — soft neumorphism (clair + sombre). */
  .login-root{ font-family:'Plus Jakarta Sans','Inter',system-ui,sans-serif;
    background:linear-gradient(to bottom,#EBF9F6,#F1FAF8,#F7FCFB); }
  .dark .login-root{ background:linear-gradient(to bottom,#0b141b,#0f1b23,#0b141b); }

  .neu-flat{ background:#F0F8F6;
    box-shadow:6px 6px 14px rgba(170,195,190,.40), -6px -6px 14px rgba(255,255,255,.95); }
  .dark .neu-flat{ background:#14222c;
    box-shadow:6px 6px 14px rgba(0,0,0,.45), -6px -6px 14px rgba(255,255,255,.04); }

  .neu-inset{ background:#E8F4F1;
    box-shadow:inset 3px 3px 6px rgba(160,188,182,.45), inset -3px -3px 6px rgba(255,255,255,.90); }
  .dark .neu-inset{ background:#101b23;
    box-shadow:inset 3px 3px 6px rgba(0,0,0,.55), inset -3px -3px 6px rgba(255,255,255,.04); }

  .neu-btn{ box-shadow:0 10px 20px -3px rgba(13,148,136,.35), 0 4px 6px -2px rgba(13,148,136,.20); }

  .login-root :focus-visible{ outline:2px solid #0d9488; outline-offset:2px; border-radius:12px; }
</style>

<div id="loginRoot" class="login-root relative flex-1 flex flex-col justify-between px-6 pt-6 pb-5 overflow-hidden">

    <!-- Halos de fond -->
    <div class="pointer-events-none absolute -top-16 -left-16 w-56 h-56 bg-teal-200/25 dark:bg-teal-500/10 rounded-full blur-3xl"></div>
    <div class="pointer-events-none absolute top-1/3 -right-20 w-64 h-64 bg-cyan-200/20 dark:bg-cyan-500/10 rounded-full blur-3xl"></div>

    <!-- 1. En-tête -->
    <div class="flex items-center justify-between z-10">
        <div class="flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded-full bg-teal-600 shadow-sm shadow-teal-500/50 animate-pulse"></span>
            <span class="text-xs font-extrabold tracking-widest text-slate-800 dark:text-slate-100 uppercase">MAAK</span>
        </div>
        <button id="themeToggle" type="button" aria-label="Basculer le thème clair/sombre" aria-pressed="false"
                class="w-10 h-10 rounded-full neu-flat flex items-center justify-center text-slate-700 dark:text-slate-200 transition active:scale-95">
            <svg id="iconMoon" class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
            <svg id="iconSun" class="w-4 h-4 hidden" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="4"></circle><path stroke-linecap="round" d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"></path></svg>
        </button>
    </div>

    <!-- 2. Médaillon + titres -->
    <div class="flex flex-col items-center z-10">
        <div class="w-24 h-24 rounded-3xl neu-flat flex items-center justify-center mb-5 p-2">
            <img src="<?= ASSETS_URL ?>/img/doctor5.jpg" alt="MAAK" class="w-full h-full object-cover object-top rounded-2xl">
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 dark:text-slate-50 tracking-tight">Bon retour</h1>
        <p class="text-xs text-slate-500 dark:text-slate-400 font-medium mt-1">Connectez-vous à votre espace santé Doza</p>
    </div>

    <!-- 3. Formulaire -->
    <form class="space-y-3.5 z-10" method="post" action="<?= BASE_URL ?>auth/login" novalidate>
        <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">

        <!-- Erreur globale (identifiants incorrects, base indisponible…) -->
        <?php if (!empty($errors['global'])): ?>
        <div role="alert" class="flex items-center gap-2 px-3 py-2.5 rounded-2xl bg-rose-50 text-rose-700 border border-rose-200 dark:bg-rose-500/15 dark:text-rose-200 dark:border-rose-500/30 text-xs font-semibold">
            <svg class="w-4 h-4 shrink-0" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L1 21h22L12 2zm0 6l6.5 11h-13L12 8zm-1 3v4h2v-4h-2zm0 5v2h2v-2h-2z"></path></svg>
            <span><?= htmlspecialchars($errors['global']) ?></span>
        </div>
        <?php endif; ?>

        <!-- E-mail -->
        <div>
            <label for="email" class="sr-only">Adresse e-mail</label>
            <div class="neu-inset rounded-2xl px-4 py-3.5 flex items-center gap-3 focus-within:ring-2 focus-within:ring-teal-500/60 <?= !empty($errors['email']) ? 'ring-2 ring-rose-400/80' : '' ?>">
                <svg class="w-5 h-5 text-slate-400 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg>
                <input id="email" name="email" type="email" autocomplete="email" value="<?= htmlspecialchars($old['email']) ?>"
                       placeholder="E-mail"
                       aria-invalid="<?= !empty($errors['email']) ? 'true' : 'false' ?>" <?= !empty($errors['email']) ? 'aria-describedby="email-err"' : '' ?>
                       class="bg-transparent w-full text-sm font-medium text-slate-800 dark:text-slate-100 placeholder-slate-400 focus:outline-none">
            </div>
            <?php if (!empty($errors['email'])): ?>
            <p id="email-err" class="mt-1 ml-1 text-[11px] font-semibold text-rose-600 dark:text-rose-300"><?= htmlspecialchars($errors['email']) ?></p>
            <?php endif; ?>
        </div>

        <!-- Mot de passe -->
        <div>
            <label for="password" class="sr-only">Mot de passe</label>
            <div class="neu-inset rounded-2xl px-4 py-3.5 flex items-center gap-3 focus-within:ring-2 focus-within:ring-teal-500/60 <?= !empty($errors['password']) ? 'ring-2 ring-rose-400/80' : '' ?>">
                <svg class="w-5 h-5 text-slate-400 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
                <input id="password" name="password" type="password" autocomplete="current-password" placeholder="Mot de passe"
                       aria-invalid="<?= !empty($errors['password']) ? 'true' : 'false' ?>" <?= !empty($errors['password']) ? 'aria-describedby="password-err"' : '' ?>
                       class="bg-transparent w-full text-sm font-medium text-slate-800 dark:text-slate-100 placeholder-slate-400 focus:outline-none tracking-wider">
                <button id="pwdToggle" type="button" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition shrink-0" aria-label="Afficher le mot de passe" aria-pressed="false">
                    <svg id="eyeOpen" class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M2.5 12S5.5 5.5 12 5.5 21.5 12 21.5 12 18.5 18.5 12 18.5 2.5 12 2.5 12z"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    <svg id="eyeOff" class="w-5 h-5 hidden" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18"></path></svg>
                </button>
            </div>
            <?php if (!empty($errors['password'])): ?>
            <p id="password-err" class="mt-1 ml-1 text-[11px] font-semibold text-rose-600 dark:text-rose-300"><?= htmlspecialchars($errors['password']) ?></p>
            <?php endif; ?>
        </div>

        <!-- Options -->
        <div class="flex items-center justify-between px-1">
            <label class="flex items-center gap-2 cursor-pointer select-none">
                <input type="checkbox" name="remember" value="1" class="w-4 h-4 rounded text-teal-600 focus:ring-teal-500 border-slate-300">
                <span class="text-xs font-semibold text-slate-600 dark:text-slate-300">Se souvenir de moi</span>
            </label>
            <a href="<?= BASE_URL ?>auth/forgot" class="text-xs font-bold text-teal-700 dark:text-teal-300 hover:underline">Mot de passe oublié ?</a>
        </div>

        <!-- Bouton principal -->
        <button type="submit" class="w-full bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white py-3.5 px-6 rounded-2xl flex items-center justify-between neu-btn active:scale-[0.99] transition">
            <span class="flex-1 text-center font-extrabold text-sm pl-8">Se connecter</span>
            <span class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center">
                <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
            </span>
        </button>
    </form>

    <!-- 4. Connexion alternative (décorative) -->
    <div class="space-y-3 z-10">
        <div class="flex items-center gap-3">
            <div class="flex-1 border-t border-slate-200/80 dark:border-slate-600/50"></div>
            <span class="text-[10px] font-bold tracking-widest text-slate-400 uppercase">Ou continuer avec</span>
            <div class="flex-1 border-t border-slate-200/80 dark:border-slate-600/50"></div>
        </div>
        <div class="flex justify-center gap-4">
            <!-- Google (bientôt disponible) -->
            <button type="button" disabled title="Bientôt disponible" aria-label="Google — bientôt disponible"
                    class="w-14 h-14 rounded-2xl neu-flat flex items-center justify-center opacity-50 cursor-not-allowed">
                <svg class="w-5 h-5" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"></path><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"></path><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"></path><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"></path></svg>
            </button>
            <!-- Identifiant Doza (bientôt disponible) -->
            <button type="button" disabled title="Bientôt disponible" aria-label="Identifiant Doza — bientôt disponible"
                    class="w-14 h-14 rounded-2xl neu-flat flex items-center justify-center text-teal-700 dark:text-teal-300 opacity-50 cursor-not-allowed">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path><circle cx="18" cy="6" r="1.5" fill="currentColor"></circle></svg>
            </button>
            <!-- Biométrie (bientôt disponible) -->
            <button type="button" disabled title="Bientôt disponible" aria-label="Reconnaissance biométrique — bientôt disponible"
                    class="w-14 h-14 rounded-2xl neu-flat flex items-center justify-center text-slate-700 dark:text-slate-200 opacity-50 cursor-not-allowed">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M4 8V6a2 2 0 012-2h2M4 16v2a2 2 0 002 2h2m8-16h2a2 2 0 012 2v2m-4 12h2a2 2 0 002-2v-2M9 10h.01M15 10h.01M9.5 15a3.5 3.5 0 005 0"></path></svg>
            </button>
        </div>
        <p class="text-center text-xs text-slate-500 dark:text-slate-400">
            Pas encore de compte ?
            <a href="<?= BASE_URL ?>auth/register" class="text-teal-700 dark:text-teal-300 font-bold hover:underline">Créer un compte</a>
        </p>
    </div>

    <!-- 5. Pied de page -->
    <div class="text-center z-10">
        <p class="text-[9px] font-extrabold tracking-widest text-slate-400 uppercase">MAAK</p>
        <p class="text-[9px] font-semibold tracking-wider text-slate-400 mt-0.5">Votre santé • sécurisée • notre priorité</p>
        <div class="w-32 h-1 bg-slate-300/80 dark:bg-slate-600 rounded-full mx-auto mt-3"></div>
    </div>
</div>

<script>
  (function () {
    // --- Bascule de thème (mémorisée) ---
    var root = document.documentElement;
    var btn  = document.getElementById('themeToggle');
    var moon = document.getElementById('iconMoon');
    var sun  = document.getElementById('iconSun');
    function syncIcons() {
      var dark = root.classList.contains('dark');
      if (moon) moon.classList.toggle('hidden', dark);
      if (sun)  sun.classList.toggle('hidden', !dark);
      if (btn)  btn.setAttribute('aria-pressed', String(dark));
    }
    syncIcons();
    if (btn) btn.addEventListener('click', function () {
      var dark = root.classList.toggle('dark');
      try { localStorage.setItem('doza-theme', dark ? 'dark' : 'light'); } catch (e) {}
      syncIcons();
    });

    // --- Afficher / masquer le mot de passe ---
    var pwd = document.getElementById('password');
    var tgl = document.getElementById('pwdToggle');
    var eO  = document.getElementById('eyeOpen');
    var eF  = document.getElementById('eyeOff');
    if (tgl && pwd) tgl.addEventListener('click', function () {
      var show = pwd.type === 'password';
      pwd.type = show ? 'text' : 'password';
      if (eO) eO.classList.toggle('hidden', show);
      if (eF) eF.classList.toggle('hidden', !show);
      tgl.setAttribute('aria-pressed', String(show));
      tgl.setAttribute('aria-label', show ? 'Masquer le mot de passe' : 'Afficher le mot de passe');
    });
  })();
</script>
