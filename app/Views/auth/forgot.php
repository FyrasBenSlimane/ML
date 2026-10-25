<!-- Applique le thème mémorisé le plus tôt possible (cohérent avec /auth/login). -->
<script>(function(){try{var t=localStorage.getItem('doza-theme');if(!t&&window.matchMedia&&matchMedia('(prefers-color-scheme: dark)').matches){t='dark';}if(t==='dark'){document.documentElement.classList.add('dark');}}catch(e){}})();</script>

<style>
  .login-root{ font-family:'Plus Jakarta Sans','Inter',system-ui,sans-serif;
    background:linear-gradient(to bottom,#EBF9F6,#F1FAF8,#F7FCFB); }
  .dark .login-root{ background:linear-gradient(to bottom,#0b141b,#0f1b23,#0b141b); }
  .neu-flat{ background:#F0F8F6;
    box-shadow:6px 6px 14px rgba(170,195,190,.40), -6px -6px 14px rgba(255,255,255,.95); }
  .dark .neu-flat{ background:#14222c;
    box-shadow:6px 6px 14px rgba(0,0,0,.45), -6px -6px 14px rgba(255,255,255,.04); }
  .login-root :focus-visible{ outline:2px solid #0d9488; outline-offset:2px; border-radius:12px; }
</style>

<div class="login-root relative flex-1 flex flex-col justify-between px-6 pt-6 pb-5 overflow-hidden">

    <div class="pointer-events-none absolute -top-16 -left-16 w-56 h-56 bg-teal-200/25 dark:bg-teal-500/10 rounded-full blur-3xl"></div>
    <div class="pointer-events-none absolute top-1/3 -right-20 w-64 h-64 bg-cyan-200/20 dark:bg-cyan-500/10 rounded-full blur-3xl"></div>

    <!-- En-tête -->
    <div class="flex items-center gap-2 z-10">
        <span class="w-2.5 h-2.5 rounded-full bg-teal-600 shadow-sm shadow-teal-500/50 animate-pulse"></span>
        <span class="text-xs font-extrabold tracking-widest text-slate-800 dark:text-slate-100 uppercase">MAAK</span>
    </div>

    <!-- Contenu -->
    <div class="flex flex-col items-center text-center z-10">
        <div class="w-24 h-24 rounded-3xl neu-flat flex items-center justify-center mb-5">
            <svg class="w-10 h-10 text-teal-600 dark:text-teal-300" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"></path></svg>
        </div>
        <h1 class="text-2xl font-extrabold text-slate-900 dark:text-slate-50 tracking-tight">Mot de passe oublié</h1>
        <p class="text-sm text-slate-600 dark:text-slate-300 font-medium mt-3 leading-relaxed max-w-xs">
            La réinitialisation n'est pas automatique. <span class="font-bold text-slate-800 dark:text-slate-100">Contactez l'administrateur de votre établissement</span> pour retrouver l'accès à votre compte.
        </p>
    </div>

    <!-- Retour -->
    <div class="z-10">
        <a href="<?= BASE_URL ?>auth/login" class="w-full bg-gradient-to-r from-teal-600 to-teal-700 hover:from-teal-700 hover:to-teal-800 text-white py-3.5 px-6 rounded-2xl flex items-center justify-center gap-2 font-extrabold text-sm active:scale-[0.99] transition shadow-[0_10px_20px_-3px_rgba(13,148,136,.35)]">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
            Retour à la connexion
        </a>
        <div class="text-center mt-5">
            <p class="text-[9px] font-extrabold tracking-widest text-slate-400 uppercase">MAAK</p>
            <p class="text-[9px] font-semibold tracking-wider text-slate-400 mt-0.5">Votre santé • sécurisée • notre priorité</p>
            <div class="w-32 h-1 bg-slate-300/80 dark:bg-slate-600 rounded-full mx-auto mt-3"></div>
        </div>
    </div>
</div>
