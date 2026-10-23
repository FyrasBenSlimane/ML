<!-- Fond ambiant -->
<div class="pointer-events-none absolute inset-0 z-0 bg-[radial-gradient(ellipse_75%_50%_at_50%_0%,rgba(107,216,203,0.3),transparent_75%)]"></div>

<!-- En-tête -->
<header class="sticky top-0 w-full z-50 pt-safe bg-surface/80 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
    <div class="h-16 px-margin flex items-center gap-space-sm">
        <a aria-label="Retour" href="<?= BASE_URL ?>" class="w-11 h-11 flex items-center justify-center rounded-full bg-surface-container-lowest text-on-surface hover:bg-surface-container transition-colors">
            <span class="material-symbols-outlined text-[20px]">arrow_back</span>
        </a>
        <h1 class="font-headline-sm text-headline-sm text-on-surface">Connexion</h1>
    </div>
</header>

<main class="relative z-10 flex-1 flex flex-col w-full bg-surface pb-safe">
    <div class="flex flex-col w-full px-margin pb-space-xl max-w-md mx-auto">

        <!-- Hero -->
        <div class="relative w-full rounded-lg bg-surface-container-lowest/70 backdrop-blur-xl p-space-lg my-space-md shadow-[0_14px_34px_-8px_rgba(0,104,95,0.1)] flex flex-col items-center text-center overflow-hidden">
            <div class="relative my-space-xs">
                <div class="absolute -inset-2 rounded-full bg-primary-fixed-dim/35 blur-md animate-pulse"></div>
                <div class="relative w-20 h-20 rounded-full p-1 bg-surface-container-lowest shadow-[0_12px_28px_rgba(0,104,95,0.22)] flex items-center justify-center overflow-hidden">
                    <img alt="MedCare" class="w-full h-full object-cover rounded-full" src="<?= ASSETS_URL ?>/img/orb.png">
                </div>
            </div>
            <h2 class="font-headline-sm text-headline-sm text-on-surface mt-space-sm">Content de vous revoir</h2>
            <p class="font-body-sm text-body-sm text-on-surface-variant">Connectez-vous à votre espace MedCare.</p>
        </div>

        <!-- Erreur globale -->
        <?php if (!empty($errors['global'])): ?>
            <div class="flex items-center gap-2 p-space-sm rounded-DEFAULT bg-error-container text-on-error-container mb-space-sm">
                <span class="material-symbols-outlined text-[18px]">error</span>
                <span class="font-body-sm text-body-sm"><?= htmlspecialchars($errors['global']) ?></span>
            </div>
        <?php endif; ?>

        <form class="flex flex-col gap-space-sm" method="post" action="<?= BASE_URL ?>auth/login">
            <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">

            <!-- Email -->
            <div class="flex flex-col gap-1">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="email">Adresse e-mail</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:ring-1 focus-within:ring-primary transition-all">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">alternate_email</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none"
                           id="email" name="email" type="email" value="<?= htmlspecialchars($old['email']) ?>" placeholder="vous@exemple.fr" autocomplete="email">
                </div>
            </div>

            <!-- Mot de passe -->
            <div class="flex flex-col gap-1">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="password">Mot de passe</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:ring-1 focus-within:ring-primary transition-all">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">key</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none tracking-wider"
                           id="password" name="password" type="password" placeholder="••••••••" autocomplete="current-password">
                    <button class="text-outline hover:text-primary transition-colors ml-1" type="button" onclick="togglePwd('password', this)">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                    </button>
                </div>
            </div>

            <button class="mt-space-sm w-full py-3.5 rounded-full bg-primary text-on-primary font-label-lg text-label-lg font-bold shadow-[0_8px_24px_rgba(0,104,95,0.28)] active:scale-[0.99] transition flex items-center justify-center gap-2" type="submit">
                <span>Se connecter</span>
                <span class="material-symbols-outlined text-[20px]">arrow_forward</span>
            </button>
        </form>

        <p class="mt-space-lg text-center font-body-sm text-body-sm text-on-surface-variant">
            Pas encore de compte ?
            <a class="text-primary font-semibold underline underline-offset-2" href="<?= BASE_URL ?>auth/register">Créer un compte</a>
        </p>
    </div>
</main>

<script>
  function togglePwd(id, btn) {
    const inp = document.getElementById(id);
    inp.type = inp.type === 'password' ? 'text' : 'password';
    btn.querySelector('span').textContent = inp.type === 'password' ? 'visibility' : 'visibility_off';
  }
</script>
