<?php
/**
 * Inscription — design « Rejoignez-nous » (néomorphique Doza Santé).
 * Les champs et la logique restent ceux du backend : rôle Patient/Personnel,
 * nom complet (scindé en prénom/nom), e-mail, téléphone, code établissement
 * (personnel), mot de passe + confirmation, CSRF.
 */
?>
<style data-purpose="neu-register">
  .reg-bg { background:#edf6f4; }
  .neu-raised-card { background:#f3faf8; box-shadow:10px 10px 24px #d4e4e1,-10px -10px 24px #ffffff; }
  .neu-circle-btn  { background:#eef6f4; box-shadow:5px 5px 12px #d2e2df,-5px -5px 12px #ffffff; }
  .neu-circle-btn:active { box-shadow:inset 2px 2px 5px #d2e2df,inset -2px -2px 5px #ffffff; }
  .neu-input { background:#eef5f3; box-shadow:inset 3px 3px 6px #d5e3e0,inset -3px -3px 6px #ffffff; border:1px solid rgba(255,255,255,.6); }
  .neu-input:focus-within { box-shadow:inset 4px 4px 8px #c9dad6,inset -3px -3px 6px #ffffff; border:1px solid rgba(10,138,124,.35); }
  .neu-role { background:#eef5f3; box-shadow:inset 3px 3px 6px #d5e3e0,inset -3px -3px 6px #ffffff; border:1px solid rgba(255,255,255,.6); }
  .neu-role.is-active { background:#f3faf8; box-shadow:6px 6px 14px #d5e4e1,-6px -6px 14px #ffffff; border:1px solid rgba(10,138,124,.45); }
  .neu-btn-teal { background:linear-gradient(135deg,#0e9686 0%,#087d70 100%); box-shadow:0 10px 20px -3px rgba(10,138,124,.42),0 4px 6px -2px rgba(10,138,124,.2); }
  .neu-btn-teal:active { transform:scale(.985); box-shadow:0 5px 12px -2px rgba(10,138,124,.4); }
  .neu-social-btn { background:#edf5f3; box-shadow:6px 6px 14px #d5e4e1,-6px -6px 14px #ffffff; transition:all .2s ease; }
  .neu-social-btn:active { box-shadow:inset 2px 2px 6px #d3e0dd,inset -2px -2px 6px #ffffff; transform:scale(.96); }
</style>

<div class="reg-bg relative flex flex-col min-h-full w-full px-6 pt-5 pb-5 overflow-hidden text-slate-800">

    <!-- Décor organique -->
    <div class="absolute -top-16 -left-16 w-56 h-56 rounded-full border-[22px] border-white/40 pointer-events-none opacity-60"></div>
    <div class="absolute -top-8 -left-8 w-40 h-40 rounded-full border-[10px] border-white/50 pointer-events-none opacity-40"></div>
    <div class="absolute top-[26%] -right-20 w-64 h-64 rounded-full bg-gradient-to-br from-white/60 to-transparent pointer-events-none blur-xl"></div>
    <div class="absolute bottom-16 -left-12 w-48 h-48 rounded-full bg-teal-100/30 pointer-events-none blur-2xl"></div>

    <div class="relative z-10 flex flex-col">

        <!-- Barre supérieure : retour + marque + lune (déco) -->
        <header class="flex items-center justify-between pt-3 pb-1">
            <div class="flex items-center space-x-2.5">
                <a href="<?= BASE_URL ?>" aria-label="Retour" class="neu-circle-btn w-9 h-9 rounded-full flex items-center justify-center text-[#123e4c] hover:text-[#0a8a7c] transition-colors">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.4" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                </a>
                <div class="flex items-center space-x-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-[#0a8a7c] shadow-[0_0_8px_rgba(10,138,124,0.6)]"></span>
                    <span class="text-xs font-black tracking-widest text-[#0e3342] uppercase">Doza Santé</span>
                </div>
            </div>
            <button type="button" aria-label="Mode sombre" class="neu-circle-btn w-9 h-9 rounded-full flex items-center justify-center text-[#123e4c]">
                <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24"><path d="M21.64 13a1 1 0 0 0-1.05-.14 8.05 8.05 0 0 1-3.37.73A8.15 8.15 0 0 1 9.08 5.49a8.59 8.59 0 0 1 .25-2A1 1 0 0 0 8 2.36a10.14 10.14 0 1 0 14 11.69 1 1 0 0 0-.36-1.05z"></path></svg>
            </button>
        </header>

        <!-- Hero : goutte + titre -->
        <section class="flex flex-col items-center mt-1 mb-3">
            <div class="neu-raised-card w-[72px] h-[72px] rounded-[22px] flex items-center justify-center mb-2.5 relative">
                <div class="absolute inset-0 rounded-[22px] bg-gradient-to-tr from-teal-500/10 to-transparent pointer-events-none"></div>
                <svg class="w-9 h-9 drop-shadow-sm" fill="none" viewBox="0 0 36 36">
                    <path d="M12.5 24.5C9.5 22 8 18.5 10 14.5C11.5 11.5 16.5 8 18 6C19 9.5 24 14.5 23.5 19C23 23.5 19.5 27 15 26.5C13.8 26.3 12.8 25.5 12.5 24.5Z" fill="#1d61d6"></path>
                    <path d="M18 10C19.5 13 25.5 17 25 21C24.5 24.5 21.5 27 18 27C17 27 16.2 26.7 15.5 26.2C18.5 24.8 20.5 21.5 20 18C19.5 14.5 18 12.5 18 10Z" fill="#38a9f5"></path>
                </svg>
            </div>
            <h1 class="text-2xl font-extrabold text-[#0d2a36] tracking-tight">Rejoignez-nous</h1>
            <p class="text-xs text-[#708d96] font-medium mt-0.5 tracking-wide">Créez votre espace santé Doza &amp; Sora</p>
        </section>

        <!-- Erreur globale -->
        <?php if (!empty($errors['global'])): ?>
            <div class="flex items-center gap-2 px-3 py-2.5 rounded-2xl bg-[#ffe3e0] text-[#b4231b] mb-2.5 text-xs font-semibold">
                <svg class="w-4 h-4 shrink-0" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9"></circle><path d="M12 8v4m0 4h.01" stroke-linecap="round"></path></svg>
                <span><?= htmlspecialchars($errors['global']) ?></span>
            </div>
        <?php endif; ?>

        <!-- Formulaire -->
        <form method="post" action="<?= BASE_URL ?>auth/register" class="space-y-2.5">
            <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
            <input type="hidden" name="role" id="role-input" value="<?= htmlspecialchars($old['role']) ?>">

            <!-- Sélecteur de rôle -->
            <div class="grid grid-cols-2 gap-2.5">
                <button type="button" id="btn-patient" onclick="selRole('patient')" class="neu-role is-active rounded-2xl text-left px-3.5 py-2.5 transition">
                    <svg class="w-5 h-5 text-[#0a8a7c] fill-current mb-0.5" viewBox="0 0 24 24"><path d="M12 21s-6.7-4.3-9.3-8.5C.9 9.4 2.4 5.8 5.8 5.2 7.8 4.9 9.8 5.9 11 7.5 12.2 5.9 14.2 4.9 16.2 5.2c3.4.6 4.9 4.2 3.1 7.3C18.7 16.7 12 21 12 21z"></path></svg>
                    <div class="text-sm font-bold text-[#143b46]">Patient</div>
                    <p class="text-[10px] text-[#708d96] font-medium">Doza &amp; Sora</p>
                </button>
                <button type="button" id="btn-personnel" onclick="selRole('personnel')" class="neu-role rounded-2xl text-left px-3.5 py-2.5 transition">
                    <svg class="w-5 h-5 text-[#6b38d4] mb-0.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M6 3v5a4 4 0 008 0V3M6 3H5m1 0h1m6 0h1m-1 0h-1m-2 13a5 5 0 005 5 4 4 0 004-4v-2" stroke-linecap="round" stroke-linejoin="round"></path><circle cx="19" cy="13" r="2"></circle></svg>
                    <div class="text-sm font-bold text-[#143b46]">Personnel</div>
                    <p class="text-[10px] text-[#708d96] font-medium">ReadmitGuard</p>
                </button>
            </div>

            <!-- Nom complet -->
            <div>
                <div class="neu-input rounded-2xl flex items-center px-4 py-2.5 transition">
                    <span class="text-[#84a3aa] mr-3">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                    <input class="w-full bg-transparent border-0 p-0 text-xs font-semibold text-[#183946] placeholder-[#90abb2] focus:ring-0 outline-none" id="fullname" name="fullname" type="text" placeholder="Nom complet" value="<?= htmlspecialchars($old['fullname']) ?>" required>
                </div>
                <?php if (!empty($errors['fullname'])): ?><p class="text-[10px] text-[#b4231b] font-semibold mt-1 ml-1"><?= htmlspecialchars($errors['fullname']) ?></p><?php endif; ?>
            </div>

            <!-- E-mail -->
            <div>
                <div class="neu-input rounded-2xl flex items-center px-4 py-2.5 transition">
                    <span class="text-[#84a3aa] mr-3">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                    <input class="w-full bg-transparent border-0 p-0 text-xs font-semibold text-[#183946] placeholder-[#90abb2] focus:ring-0 outline-none" id="email" name="email" type="email" placeholder="Adresse e-mail" value="<?= htmlspecialchars($old['email']) ?>" required>
                </div>
                <?php if (!empty($errors['email'])): ?><p class="text-[10px] text-[#b4231b] font-semibold mt-1 ml-1"><?= htmlspecialchars($errors['email']) ?></p><?php endif; ?>
            </div>

            <!-- Téléphone (optionnel) -->
            <div class="neu-input rounded-2xl flex items-center px-4 py-2.5 transition">
                <span class="text-[#84a3aa] mr-3">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="7" y="2" width="10" height="20" rx="2"></rect><path d="M11 18h2" stroke-linecap="round"></path></svg>
                </span>
                <input class="w-full bg-transparent border-0 p-0 text-xs font-semibold text-[#183946] placeholder-[#90abb2] focus:ring-0 outline-none" id="phone" name="phone" type="tel" placeholder="N° Mobile (optionnel)" value="<?= htmlspecialchars($old['phone']) ?>">
            </div>

            <!-- Code établissement (personnel uniquement) -->
            <div id="access-code-field" class="<?= $old['role'] === 'personnel' ? '' : 'hidden' ?>">
                <div class="neu-input rounded-2xl flex items-center px-4 py-2.5 transition">
                    <span class="text-[#84a3aa] mr-3">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 21h18M6 21V8l6-4 6 4v13M10 12h.01M14 12h.01M10 16h.01M14 16h.01" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                    <input class="w-full bg-transparent border-0 p-0 text-xs font-semibold text-[#183946] placeholder-[#90abb2] focus:ring-0 outline-none" id="access_code" name="access_code" type="text" placeholder="Code établissement">
                </div>
                <?php if (!empty($errors['access_code'])): ?><p class="text-[10px] text-[#b4231b] font-semibold mt-1 ml-1"><?= htmlspecialchars($errors['access_code']) ?></p><?php endif; ?>
            </div>

            <!-- Mot de passe -->
            <div>
                <div class="neu-input rounded-2xl flex items-center px-4 py-2.5 transition">
                    <span class="text-[#84a3aa] mr-3">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="10" rx="2"></rect><path d="M8 11V7a4 4 0 118 0v4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                    <input class="w-full bg-transparent border-0 p-0 text-xs font-semibold text-[#183946] placeholder-[#90abb2] focus:ring-0 outline-none tracking-wider" id="password" name="password" type="password" placeholder="Mot de passe (8 caractères min.)" required>
                    <button type="button" aria-label="Afficher le mot de passe" class="text-[#8faab1] hover:text-[#0a8a7c] ml-2" onclick="togglePwd('password', this)">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M1.5 12S5 5 12 5s10.5 7 10.5 7-3.5 7-10.5 7S1.5 12 1.5 12z" stroke-linecap="round" stroke-linejoin="round"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </button>
                </div>
                <?php if (!empty($errors['password'])): ?><p class="text-[10px] text-[#b4231b] font-semibold mt-1 ml-1"><?= htmlspecialchars($errors['password']) ?></p><?php endif; ?>
            </div>

            <!-- Confirmation -->
            <div>
                <div class="neu-input rounded-2xl flex items-center px-4 py-2.5 transition">
                    <span class="text-[#84a3aa] mr-3">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><rect x="5" y="11" width="14" height="10" rx="2"></rect><path d="M8 11V7a4 4 0 118 0v4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                    <input class="w-full bg-transparent border-0 p-0 text-xs font-semibold text-[#183946] placeholder-[#90abb2] focus:ring-0 outline-none tracking-wider" id="password_confirm" name="password_confirm" type="password" placeholder="Confirmer le mot de passe" required>
                    <button type="button" aria-label="Afficher le mot de passe" class="text-[#8faab1] hover:text-[#0a8a7c] ml-2" onclick="togglePwd('password_confirm', this)">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M1.5 12S5 5 12 5s10.5 7 10.5 7-3.5 7-10.5 7S1.5 12 1.5 12z" stroke-linecap="round" stroke-linejoin="round"></path><circle cx="12" cy="12" r="3"></circle></svg>
                    </button>
                </div>
                <?php if (!empty($errors['password_confirm'])): ?><p class="text-[10px] text-[#b4231b] font-semibold mt-1 ml-1"><?= htmlspecialchars($errors['password_confirm']) ?></p><?php endif; ?>
            </div>

            <!-- Conditions -->
            <div class="flex items-start pt-0.5 px-1">
                <input class="w-3.5 h-3.5 mt-0.5 rounded text-[#0a8a7c] bg-[#e3efec] border-[#b0cac6] focus:ring-[#0a8a7c] cursor-pointer" id="terms" name="terms" type="checkbox" required>
                <label class="ml-2 text-[10px] leading-tight text-[#6b8992] select-none" for="terms">
                    J'accepte les <a class="text-[#0a8a7c] font-semibold hover:underline" href="#">conditions d'utilisation</a> et la <a class="text-[#0a8a7c] font-semibold hover:underline" href="#">politique de confidentialité</a>
                </label>
            </div>

            <!-- Bouton S'inscrire -->
            <div class="pt-1.5">
                <button type="submit" class="neu-btn-teal w-full rounded-2xl py-3 px-5 text-white font-bold text-sm tracking-wide flex items-center justify-between transition-all duration-150">
                    <span class="w-7"></span>
                    <span class="tracking-wide">S'inscrire</span>
                    <span class="w-7 h-7 rounded-full bg-white/20 flex items-center justify-center backdrop-blur-sm shadow-inner">
                        <svg class="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M14 5l7 7m0 0l-7 7m7-7H3" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                    </span>
                </button>
            </div>
        </form>

        <!-- Alternatives (décoratives) -->
        <section class="mt-3.5">
            <div class="relative flex items-center justify-center mb-3">
                <div class="border-t border-[#cde0dc] w-full"></div>
                <span class="absolute bg-[#edf6f4] px-2 text-[9px] font-bold text-[#8ba6ad] tracking-widest uppercase">ou continuer avec</span>
            </div>
            <div class="flex justify-center items-center space-x-4">
                <button type="button" aria-label="Google" class="neu-social-btn w-12 h-12 rounded-2xl flex items-center justify-center">
                    <svg class="w-5 h-5" viewBox="0 0 24 24"><path d="M12 5c1.6 0 3 .6 4.1 1.7l3.1-3.1C17.3 1.8 14.8 1 12 1 7.5 1 3.7 3.6 1.9 7.3l3.7 2.9C6.5 7.4 9 5 12 5z" fill="#EA4335"></path><path d="M23.5 12.3c0-.8-.1-1.6-.2-2.3H12v4.5h6.5c-.3 1.5-1.1 2.8-2.4 3.7l3.7 2.9c2.2-2 3.7-5 3.7-8.8z" fill="#4285F4"></path><path d="M5.6 14.8c-.2-.7-.4-1.5-.4-2.3s.2-1.6.4-2.3L1.9 7.3C.7 9.7 0 12.3 0 15.2s.7 5.5 1.9 7.9l3.7-2.9z" fill="#FBBC05"></path><path d="M12 23.5c3.2 0 6-1.1 8-3l-3.7-2.9c-1.1.7-2.5 1.2-4.3 1.2-3 0-5.5-2.4-6.4-5.2L1.9 16.5C3.7 20.3 7.5 23.5 12 23.5z" fill="#34A853"></path></svg>
                </button>
                <button type="button" aria-label="Identifiant santé" class="neu-social-btn w-12 h-12 rounded-2xl flex items-center justify-center text-[#0a8a7c]">
                    <div class="relative flex items-center justify-center">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M12 4v16m8-8H4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
                        <span class="absolute -top-1 -right-1 w-1.5 h-1.5 rounded-full bg-[#0a8a7c]"></span>
                    </div>
                </button>
                <button type="button" aria-label="Biométrie" class="neu-social-btn w-12 h-12 rounded-2xl flex items-center justify-center text-[#214a57]">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24"><path d="M3 7V5a2 2 0 012-2h2m10 0h2a2 2 0 012 2v2m0 10v2a2 2 0 01-2 2h-2m-10 0H5a2 2 0 01-2-2v-2" stroke-linecap="round" stroke-linejoin="round"></path><circle cx="9" cy="9" fill="currentColor" r="1.2"></circle><circle cx="15" cy="9" fill="currentColor" r="1.2"></circle><path d="M12 11.5v2m-3 3c.8.7 1.8 1 3 1s2.2-.3 3-1" stroke-linecap="round"></path></svg>
                </button>
            </div>
        </section>

        <!-- Pied de page -->
        <footer class="mt-3 text-center">
            <p class="text-xs text-[#63828c] font-medium mb-2.5">
                Vous avez déjà un compte ?
                <a class="font-bold text-[#0a8a7c] hover:underline" href="<?= BASE_URL ?>auth/login">Se connecter</a>
            </p>
            <div class="text-[8px] tracking-[0.2em] font-bold text-[#98b3ba] uppercase mb-1">Serene Pulse</div>
            <div class="text-[8px] font-bold text-[#86a3aa] tracking-wider uppercase mb-1.5">Votre santé • Sécurisée • Notre priorité</div>
            <div class="w-32 h-1 bg-[#a3bebe]/60 rounded-full mx-auto"></div>
        </footer>
    </div>
</div>

<script>
  function togglePwd(id, btn) {
    const inp = document.getElementById(id);
    inp.type = inp.type === 'password' ? 'text' : 'password';
  }
  function selRole(role) {
    document.getElementById('role-input').value = role;
    document.getElementById('btn-patient').classList.toggle('is-active', role === 'patient');
    document.getElementById('btn-personnel').classList.toggle('is-active', role === 'personnel');
    document.getElementById('access-code-field').classList.toggle('hidden', role !== 'personnel');
  }
  selRole(document.getElementById('role-input').value || 'patient');
</script>
