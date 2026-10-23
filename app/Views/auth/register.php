<!-- Fond ambiant -->
<div class="pointer-events-none absolute inset-0 z-0 bg-[radial-gradient(ellipse_75%_50%_at_50%_0%,rgba(107,216,203,0.3),transparent_75%)]"></div>

<!-- En-tête -->
<header class="sticky top-0 w-full z-50 pt-safe bg-surface/80 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
    <div class="h-16 px-margin flex items-center gap-space-sm">
        <a aria-label="Retour" href="<?= BASE_URL ?>" class="w-11 h-11 flex items-center justify-center rounded-full bg-surface-container-lowest text-on-surface hover:bg-surface-container transition-colors">
            <span class="material-symbols-outlined text-[20px]">arrow_back</span>
        </a>
        <h1 class="font-headline-sm text-headline-sm text-on-surface">Créer un compte</h1>
    </div>
</header>

<main class="relative z-10 flex-1 flex flex-col w-full bg-surface pb-safe">
    <div class="flex flex-col w-full px-margin pb-space-xl max-w-md mx-auto">

        <p class="font-body-sm text-body-sm text-on-surface-variant my-space-md text-center">Rejoignez MedCare : votre espace santé, Doza et Sora.</p>

        <!-- Erreur globale -->
        <?php if (!empty($errors['global'])): ?>
            <div class="flex items-center gap-2 p-space-sm rounded-DEFAULT bg-error-container text-on-error-container mb-space-sm">
                <span class="material-symbols-outlined text-[18px]">error</span>
                <span class="font-body-sm text-body-sm"><?= htmlspecialchars($errors['global']) ?></span>
            </div>
        <?php endif; ?>

        <form class="flex flex-col gap-space-sm" method="post" action="<?= BASE_URL ?>auth/register">
            <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
            <input type="hidden" name="role" id="role-input" value="<?= htmlspecialchars($old['role']) ?>">

            <!-- Rôle -->
            <div class="grid grid-cols-2 gap-space-sm mb-space-xs">
                <button type="button" id="btn-patient" onclick="selRole('patient')" class="text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest ring-2 ring-primary transition">
                    <span class="material-symbols-outlined text-primary text-[22px]" style="font-variation-settings:'FILL' 1;">favorite</span>
                    <div class="font-label-lg text-label-lg text-on-surface font-bold">Patient</div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant">Doza &amp; Sora</p>
                </button>
                <button type="button" id="btn-personnel" onclick="selRole('personnel')" class="text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest/70 ring-0 hover:bg-surface-container-lowest transition">
                    <span class="material-symbols-outlined text-tertiary text-[22px]">stethoscope</span>
                    <div class="font-label-lg text-label-lg text-on-surface font-bold">Personnel</div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant">ReadmitGuard</p>
                </button>
            </div>

            <!-- Prénom / Nom -->
            <div class="grid grid-cols-2 gap-space-sm">
                <div class="flex flex-col gap-1">
                    <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="first_name">Prénom</label>
                    <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                        <span class="material-symbols-outlined text-outline text-[18px] mr-1.5">badge</span>
                        <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none" id="first_name" name="first_name" type="text" value="<?= htmlspecialchars($old['first_name']) ?>">
                    </div>
                    <?php if (!empty($errors['first_name'])): ?><p class="font-label-sm text-label-sm text-error ml-1"><?= htmlspecialchars($errors['first_name']) ?></p><?php endif; ?>
                </div>
                <div class="flex flex-col gap-1">
                    <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="last_name">Nom</label>
                    <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                        <span class="material-symbols-outlined text-outline text-[18px] mr-1.5">person</span>
                        <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none" id="last_name" name="last_name" type="text" value="<?= htmlspecialchars($old['last_name']) ?>">
                    </div>
                    <?php if (!empty($errors['last_name'])): ?><p class="font-label-sm text-label-sm text-error ml-1"><?= htmlspecialchars($errors['last_name']) ?></p><?php endif; ?>
                </div>
            </div>

            <!-- Email -->
            <div class="flex flex-col gap-1">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="email">Adresse e-mail</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">alternate_email</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none" id="email" name="email" type="email" value="<?= htmlspecialchars($old['email']) ?>" placeholder="vous@exemple.fr">
                </div>
                <?php if (!empty($errors['email'])): ?><p class="font-label-sm text-label-sm text-error ml-1"><?= htmlspecialchars($errors['email']) ?></p><?php endif; ?>
            </div>

            <!-- Téléphone -->
            <div class="flex flex-col gap-1">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="phone">Téléphone (optionnel)</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">phone_iphone</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none" id="phone" name="phone" type="tel" value="<?= htmlspecialchars($old['phone']) ?>" placeholder="06 12 34 56 78">
                </div>
            </div>

            <!-- Code établissement (personnel) -->
            <div class="flex flex-col gap-1 <?= $old['role'] === 'personnel' ? '' : 'hidden' ?>" id="access-code-field">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="access_code">Code établissement</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">domain</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none" id="access_code" name="access_code" type="text" placeholder="Fourni par l'établissement">
                </div>
                <?php if (!empty($errors['access_code'])): ?><p class="font-label-sm text-label-sm text-error ml-1"><?= htmlspecialchars($errors['access_code']) ?></p><?php endif; ?>
            </div>

            <!-- Mot de passe -->
            <div class="flex flex-col gap-1">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="password">Mot de passe (8 caractères min.)</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">key</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none tracking-wider" id="password" name="password" type="password" placeholder="••••••••">
                    <button class="text-outline hover:text-primary ml-1" type="button" onclick="togglePwd('password', this)"><span class="material-symbols-outlined text-[20px]">visibility</span></button>
                </div>
                <?php if (!empty($errors['password'])): ?><p class="font-label-sm text-label-sm text-error ml-1"><?= htmlspecialchars($errors['password']) ?></p><?php endif; ?>
            </div>

            <!-- Confirmation -->
            <div class="flex flex-col gap-1">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="password_confirm">Confirmer le mot de passe</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest focus-within:ring-1 focus-within:ring-primary transition">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">key</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface focus:outline-none tracking-wider" id="password_confirm" name="password_confirm" type="password" placeholder="••••••••">
                </div>
                <?php if (!empty($errors['password_confirm'])): ?><p class="font-label-sm text-label-sm text-error ml-1"><?= htmlspecialchars($errors['password_confirm']) ?></p><?php endif; ?>
            </div>

            <button class="mt-space-sm w-full py-3.5 rounded-full bg-primary text-on-primary font-label-lg text-label-lg font-bold shadow-[0_8px_24px_rgba(0,104,95,0.28)] active:scale-[0.99] transition flex items-center justify-center gap-2" type="submit">
                <span>Créer mon compte</span>
                <span class="material-symbols-outlined text-[20px]">arrow_forward</span>
            </button>
        </form>

        <p class="mt-space-lg text-center font-body-sm text-body-sm text-on-surface-variant">
            Déjà un compte ?
            <a class="text-primary font-semibold underline underline-offset-2" href="<?= BASE_URL ?>auth/login">Se connecter</a>
        </p>
    </div>
</main>

<script>
  function togglePwd(id, btn) {
    const inp = document.getElementById(id);
    inp.type = inp.type === 'password' ? 'text' : 'password';
    btn.querySelector('span').textContent = inp.type === 'password' ? 'visibility' : 'visibility_off';
  }
  function selRole(role) {
    document.getElementById('role-input').value = role;
    const p = document.getElementById('btn-patient'), s = document.getElementById('btn-personnel');
    const on = 'text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest ring-2 ring-primary transition';
    const off = 'text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest/70 ring-0 hover:bg-surface-container-lowest transition';
    p.className = role === 'patient' ? on : off;
    s.className = role === 'personnel' ? on.replace('ring-primary', 'ring-tertiary') : off;
    document.getElementById('access-code-field').classList.toggle('hidden', role !== 'personnel');
  }
  selRole(document.getElementById('role-input').value || 'patient');
</script>
