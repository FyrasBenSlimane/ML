<!-- Fond ambiant -->
<div class="pointer-events-none fixed inset-0 z-0 bg-[radial-gradient(ellipse_75%_50%_at_50%_0%,rgba(107,216,203,0.3),transparent_75%)]"></div>

<!-- En-tête fixe -->
<header class="fixed top-0 w-full z-50 pt-safe bg-surface/80 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)]">
    <div class="h-16 px-margin flex items-center justify-between">
        <div class="flex items-center gap-space-sm">
            <a aria-label="Retour" href="<?= BASE_URL ?>" class="w-11 h-11 flex items-center justify-center rounded-full bg-surface-container-lowest text-on-surface hover:bg-surface-container transition-colors shadow-[0_4px_12px_-2px_rgba(19,78,74,0.06)]">
                <span class="material-symbols-outlined text-[20px]">arrow_back</span>
            </a>
            <h1 class="font-headline-sm text-headline-sm text-on-surface">Créer un compte</h1>
        </div>
    </div>
</header>

<main class="relative z-10 flex-1 flex flex-col w-full bg-surface pt-16 pb-safe">
    <div class="flex flex-col w-full px-margin pb-space-xl">

        <!-- Section Hero : orbe IA holographique -->
        <div class="relative w-full rounded-lg bg-surface-container-lowest/70 backdrop-blur-xl p-space-lg mb-space-md shadow-[0_14px_34px_-8px_rgba(0,104,95,0.1),0_4px_12px_rgba(0,0,0,0.03)] flex flex-col items-center text-center overflow-hidden">
            <div class="absolute -top-12 -left-12 w-44 h-44 rounded-full bg-secondary-container/40 blur-3xl pointer-events-none"></div>
            <div class="absolute -bottom-10 -right-10 w-44 h-44 rounded-full bg-tertiary-fixed/30 blur-3xl pointer-events-none"></div>

            <div class="relative my-space-xs group cursor-pointer">
                <div class="absolute -inset-3 rounded-full bg-primary-fixed-dim/35 blur-md animate-ping opacity-75"></div>
                <div class="absolute -inset-1.5 rounded-full bg-secondary-fixed/50 blur-sm animate-pulse"></div>
                <div class="relative w-28 h-28 rounded-full p-1 bg-surface-container-lowest shadow-[0_12px_28px_rgba(0,104,95,0.22)] flex items-center justify-center overflow-hidden transition-transform active:scale-95 duration-300">
                    <img alt="Doza AI" class="w-full h-full object-cover rounded-full transform group-hover:rotate-12 transition-transform duration-700" src="<?= ASSETS_URL ?>/img/orb.png">
                    <div class="absolute inset-0 bg-primary/10 mix-blend-overlay pointer-events-none"></div>
                    <div class="absolute top-2 right-4 w-2 h-2 rounded-full bg-surface-container-lowest shadow-[0_0_8px_#ffffff]"></div>
                </div>
            </div>

            <div class="mt-space-sm max-w-xs">
                <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-surface-container-high/60 backdrop-blur-sm mb-1.5">
                    <span class="material-symbols-outlined text-primary text-[16px]" style="font-variation-settings: 'FILL' 1;">neurology</span>
                    <span class="font-label-sm text-label-sm text-on-surface font-semibold">Bienvenue sur&nbsp;<strong>Ma3ak</strong> (معاك)</span>
                </div>
                <h2 class="font-headline-sm text-headline-sm text-on-surface tracking-tight mb-1">Bonjour. Préparez votre espace vital.</h2>
                <p class="font-body-sm text-body-sm text-on-surface-variant">Sécurisation quantique &amp; accompagnement médical sur-mesure instantané.</p>
            </div>

            <div class="flex items-center gap-1 mt-space-sm h-4">
                <span class="w-1 bg-primary/40 rounded-full h-2 animate-pulse"></span>
                <span class="w-1 bg-primary rounded-full h-4 animate-bounce"></span>
                <span class="w-1 bg-secondary rounded-full h-3 animate-pulse"></span>
                <span class="w-1 bg-primary-container rounded-full h-5 animate-pulse"></span>
                <span class="w-1 bg-primary rounded-full h-3 animate-bounce"></span>
                <span class="w-1 bg-primary/50 rounded-full h-2 animate-pulse"></span>
            </div>
        </div>

        <!-- Sélecteur d'onglets (Connexion / Créer un compte) -->
        <div class="p-1 rounded-full bg-surface-container-high/60 backdrop-blur-lg shadow-inner flex items-center mb-space-md">
            <button class="flex-1 py-2.5 rounded-full font-label-lg text-label-lg text-on-surface-variant text-center transition-all duration-300" id="tab-login" onclick="switchAuthTab('login')" type="button">Connexion</button>
            <button class="flex-1 py-2.5 rounded-full bg-surface-container-lowest text-primary font-label-lg text-label-lg font-bold text-center shadow-[0_4px_16px_rgba(0,104,95,0.12)] transition-all duration-300" id="tab-signup" onclick="switchAuthTab('signup')" type="button">Créer un compte</button>
        </div>

        <!-- Sélecteur de rôle -->
        <div class="mb-space-md">
            <div class="flex items-center justify-between mb-space-xs px-1">
                <span class="font-label-md text-label-md text-on-surface font-semibold">Choisissez votre profil</span>
                <span class="font-label-sm text-label-sm text-primary font-medium flex items-center gap-1">
                    <span class="material-symbols-outlined text-[14px]">verified_user</span> Rôle certifié
                </span>
            </div>
            <div class="grid grid-cols-2 gap-space-sm">
                <!-- Patient (sélectionné par défaut) -->
                <button class="relative text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest shadow-[0_6px_20px_rgba(0,104,95,0.12)] ring-2 ring-primary transition-all duration-200" id="role-patient" onclick="selectRole('patient')" type="button">
                    <div class="w-10 h-10 rounded-full bg-primary-fixed/40 flex items-center justify-center text-primary mb-2 shadow-sm">
                        <span class="material-symbols-outlined text-[22px]" style="font-variation-settings: 'FILL' 1;">favorite</span>
                    </div>
                    <div class="flex items-center justify-between mb-1">
                        <span class="font-label-lg text-label-lg text-on-surface font-bold">Patient</span>
                        <span class="material-symbols-outlined text-primary text-[18px]" id="check-patient">check_circle</span>
                    </div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant line-clamp-2">Suivi &amp; Diagnostics préventifs Doza</p>
                    <div class="mt-2 inline-block px-2 py-0.5 rounded-full bg-surface-container-low font-label-sm text-label-sm text-primary font-semibold">Espace Personnel</div>
                </button>
                <!-- Praticien -->
                <button class="relative text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest/70 shadow-[0_4px_14px_rgba(0,0,0,0.03)] ring-0 hover:bg-surface-container-lowest transition-all duration-200" id="role-pro" onclick="selectRole('pro')" type="button">
                    <div class="w-10 h-10 rounded-full bg-tertiary-fixed/50 flex items-center justify-center text-tertiary mb-2 shadow-sm">
                        <span class="material-symbols-outlined text-[22px]">stethoscope</span>
                    </div>
                    <div class="flex items-center justify-between mb-1">
                        <span class="font-label-lg text-label-lg text-on-surface font-bold">Praticien</span>
                        <span class="material-symbols-outlined text-outline-variant text-[18px]" id="check-pro">radio_button_unchecked</span>
                    </div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant line-clamp-2">Clinique IA &amp; Télé-expertise</p>
                    <div class="mt-2 inline-block px-2 py-0.5 rounded-full bg-tertiary-fixed/40 font-label-sm text-label-sm text-on-tertiary-fixed-variant font-semibold">Pro Santé Connect</div>
                </button>
            </div>
        </div>

        <!-- Formulaire -->
        <form class="flex flex-col gap-space-sm" id="auth-form" onsubmit="handleAuthSubmit(event)">
            <!-- Prénom / Nom -->
            <div class="grid grid-cols-2 gap-space-sm" id="name-fields">
                <div class="flex flex-col gap-1">
                    <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="first-name">Prénom</label>
                    <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:shadow-[0_4px_16px_rgba(0,104,95,0.14)] focus-within:ring-1 focus-within:ring-primary transition-all">
                        <span class="material-symbols-outlined text-outline text-[18px] mr-1.5">badge</span>
                        <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none" id="first-name" placeholder="Éléonore" type="text">
                    </div>
                </div>
                <div class="flex flex-col gap-1">
                    <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="last-name">Nom</label>
                    <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:shadow-[0_4px_16px_rgba(0,104,95,0.14)] focus-within:ring-1 focus-within:ring-primary transition-all">
                        <span class="material-symbols-outlined text-outline text-[18px] mr-1.5">person</span>
                        <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none" id="last-name" placeholder="Vasseur" type="text">
                    </div>
                </div>
            </div>

            <!-- Email -->
            <div class="flex flex-col gap-1">
                <div class="flex items-center justify-between ml-1">
                    <label class="font-label-sm text-label-sm text-on-surface-variant font-medium" for="email">Adresse email professionnelle ou privée</label>
                    <span class="font-label-sm text-label-sm text-primary font-medium flex items-center gap-1">
                        <span class="material-symbols-outlined text-[14px]">encrypted</span> Chiffré HDS
                    </span>
                </div>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:shadow-[0_4px_16px_rgba(0,104,95,0.14)] focus-within:ring-1 focus-within:ring-primary transition-all">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">alternate_email</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none" id="email" placeholder="eleonore.vasseur@sante.fr" type="email">
                </div>
            </div>

            <!-- Téléphone -->
            <div class="flex flex-col gap-1" id="phone-field">
                <label class="font-label-sm text-label-sm text-on-surface-variant font-medium ml-1" for="phone">Numéro de mobile (authentification 2FA)</label>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:shadow-[0_4px_16px_rgba(0,104,95,0.14)] focus-within:ring-1 focus-within:ring-primary transition-all">
                    <div class="flex items-center gap-1 pr-2 mr-2 border-r border-outline-variant/30">
                        <span class="text-base">🇫🇷</span>
                        <span class="font-label-md text-label-md text-on-surface font-semibold">+33</span>
                        <span class="material-symbols-outlined text-[14px] text-outline">expand_more</span>
                    </div>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none" id="phone" placeholder="06 12 34 56 78" type="tel">
                    <span class="material-symbols-outlined text-outline text-[18px]">phone_iphone</span>
                </div>
            </div>

            <!-- Mot de passe -->
            <div class="flex flex-col gap-1">
                <div class="flex items-center justify-between ml-1">
                    <label class="font-label-sm text-label-sm text-on-surface-variant font-medium" for="password">Mot de passe fort</label>
                    <span class="font-label-sm text-label-sm text-primary font-semibold">Recommandation Doza AI</span>
                </div>
                <div class="flex items-center px-space-sm py-2.5 rounded-DEFAULT bg-surface-container-lowest shadow-[0_3px_10px_rgba(0,104,95,0.04)] focus-within:shadow-[0_4px_16px_rgba(0,104,95,0.14)] focus-within:ring-1 focus-within:ring-primary transition-all">
                    <span class="material-symbols-outlined text-outline text-[18px] mr-2">key</span>
                    <input class="w-full bg-transparent font-body-md text-body-md text-on-surface placeholder:text-outline/60 focus:outline-none tracking-wider" id="password" placeholder="••••••••••••" type="password">
                    <button class="text-outline hover:text-primary transition-colors focus:outline-none ml-1" onclick="togglePasswordVisibility()" type="button">
                        <span class="material-symbols-outlined text-[20px]" id="eye-icon">visibility</span>
                    </button>
                </div>
                <div class="flex items-center gap-1.5 mt-1 px-1">
                    <div class="flex-1 h-1 rounded-full bg-surface-container-high overflow-hidden">
                        <div class="h-full w-4/5 bg-primary rounded-full"></div>
                    </div>
                </div>
            </div>

            <!-- Avis rôle praticien (affiché si Praticien sélectionné) -->
            <div class="hidden items-start gap-2 p-space-sm rounded-DEFAULT bg-tertiary-fixed/30 text-on-tertiary-fixed-variant" id="pro-notice">
                <span class="material-symbols-outlined text-[18px] mt-0.5">info</span>
                <p class="font-body-sm text-body-sm">L'espace Praticien (Pro Santé Connect) arrive bientôt. Vous pouvez déjà créer votre espace Patient.</p>
            </div>

            <!-- Bouton principal -->
            <button class="mt-space-sm w-full py-3.5 rounded-full bg-primary text-on-primary font-label-lg text-label-lg font-bold shadow-[0_8px_24px_rgba(0,104,95,0.28)] active:scale-[0.99] transition flex items-center justify-center gap-2" id="cta-btn" type="submit">
                <span id="cta-label">Rejoindre Doza AI</span>
                <span class="material-symbols-outlined text-[20px]">arrow_forward</span>
            </button>
        </form>

        <!-- Pied : mentions légales -->
        <p class="mt-space-lg text-center font-body-sm text-body-sm text-on-surface-variant/80 px-space-sm leading-relaxed">
            En créant un compte, vous acceptez nos
            <a class="text-primary font-semibold underline decoration-primary/40 underline-offset-2" href="#">Conditions d'Utilisation</a>
            et notre
            <a class="text-primary font-semibold underline decoration-primary/40 underline-offset-2" href="#">Politique de Confidentialité HDS</a> certifiée conforme RGPD.
        </p>
    </div>
</main>

<script>
  const BASE = '<?= BASE_URL ?>';
  let currentTab = 'signup';
  let currentRole = 'patient';

  function switchAuthTab(tab) {
    currentTab = tab;
    const loginBtn   = document.getElementById('tab-login');
    const signupBtn  = document.getElementById('tab-signup');
    const nameFields = document.getElementById('name-fields');
    const phoneField = document.getElementById('phone-field');
    const ctaLabel   = document.getElementById('cta-label');

    if (tab === 'login') {
      loginBtn.className  = 'flex-1 py-2.5 rounded-full bg-surface-container-lowest text-primary font-label-lg text-label-lg font-bold text-center shadow-[0_4px_16px_rgba(0,104,95,0.12)] transition-all duration-300';
      signupBtn.className = 'flex-1 py-2.5 rounded-full font-label-lg text-label-lg text-on-surface-variant text-center transition-all duration-300';
      nameFields.style.display = 'none';
      phoneField.style.display = 'none';
      ctaLabel.textContent = 'Accéder à mon espace Doza';
    } else {
      signupBtn.className = 'flex-1 py-2.5 rounded-full bg-surface-container-lowest text-primary font-label-lg text-label-lg font-bold text-center shadow-[0_4px_16px_rgba(0,104,95,0.12)] transition-all duration-300';
      loginBtn.className  = 'flex-1 py-2.5 rounded-full font-label-lg text-label-lg text-on-surface-variant text-center transition-all duration-300';
      nameFields.style.display = 'grid';
      phoneField.style.display = 'flex';
      ctaLabel.textContent = 'Rejoindre Doza AI';
    }
  }

  function selectRole(role) {
    currentRole = role;
    const rolePatient  = document.getElementById('role-patient');
    const rolePro      = document.getElementById('role-pro');
    const checkPatient = document.getElementById('check-patient');
    const checkPro     = document.getElementById('check-pro');
    const proNotice    = document.getElementById('pro-notice');

    if (role === 'patient') {
      rolePatient.className = 'relative text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest shadow-[0_6px_20px_rgba(0,104,95,0.12)] ring-2 ring-primary transition-all duration-200';
      rolePro.className     = 'relative text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest/70 shadow-[0_4px_14px_rgba(0,0,0,0.03)] ring-0 hover:bg-surface-container-lowest transition-all duration-200';
      checkPatient.textContent = 'check_circle';
      checkPatient.className   = 'material-symbols-outlined text-primary text-[18px]';
      checkPro.textContent     = 'radio_button_unchecked';
      checkPro.className       = 'material-symbols-outlined text-outline-variant text-[18px]';
      proNotice.classList.add('hidden'); proNotice.classList.remove('flex');
    } else {
      rolePro.className     = 'relative text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest shadow-[0_6px_20px_rgba(107,56,212,0.12)] ring-2 ring-tertiary transition-all duration-200';
      rolePatient.className = 'relative text-left p-space-sm rounded-DEFAULT bg-surface-container-lowest/70 shadow-[0_4px_14px_rgba(0,0,0,0.03)] ring-0 hover:bg-surface-container-lowest transition-all duration-200';
      checkPro.textContent     = 'check_circle';
      checkPro.className       = 'material-symbols-outlined text-tertiary text-[18px]';
      checkPatient.textContent = 'radio_button_unchecked';
      checkPatient.className   = 'material-symbols-outlined text-outline-variant text-[18px]';
      proNotice.classList.remove('hidden'); proNotice.classList.add('flex');
    }
  }

  function togglePasswordVisibility() {
    const passwordInput = document.getElementById('password');
    const eyeIcon = document.getElementById('eye-icon');
    if (passwordInput.type === 'password') {
      passwordInput.type = 'text';
      eyeIcon.textContent = 'visibility_off';
    } else {
      passwordInput.type = 'password';
      eyeIcon.textContent = 'visibility';
    }
  }

  // Front-end uniquement pour l'instant : le patient entre dans son espace Doza.
  // L'espace praticien sera branché plus tard.
  function handleAuthSubmit(event) {
    event.preventDefault();
    if (currentRole === 'pro') {
      document.getElementById('pro-notice').scrollIntoView({ behavior: 'smooth', block: 'center' });
      return;
    }
    window.location = BASE + 'profile';
  }
</script>
