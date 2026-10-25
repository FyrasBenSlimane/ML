<!DOCTYPE html>
<html class="h-full" lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title><?= isset($title) ? htmlspecialchars($title) . ' · MAAK' : 'MAAK' ?></title>
    <link rel="icon" type="image/jpeg" href="<?= ASSETS_URL ?>/img/doctor5.jpg">
    <link rel="apple-touch-icon" href="<?= ASSETS_URL ?>/img/doctor5.jpg">

    <!-- Polices : Plus Jakarta Sans + Material Symbols -->
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet">

    <!-- Tailwind CDN + configuration Material 3 (propre à l'écran d'authentification) -->
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      tailwind.config = { darkMode: "class", theme: { extend: {
        colors: { "primary-fixed-dim": "#6bd8cb", "error-container": "#ffdad6", "inverse-surface": "#003734", "on-tertiary-fixed-variant": "#5516be", "surface-variant": "#b5ede7", "error": "#ba1a1a", "on-error": "#ffffff", "surface-tint": "#006a61", "inverse-primary": "#6bd8cb", "on-secondary-fixed": "#00201c", "on-secondary": "#ffffff", "secondary-container": "#6df5e1", "secondary": "#006b5f", "on-error-container": "#93000a", "inverse-on-surface": "#c3fcf5", "primary-container": "#008378", "on-primary-container": "#f4fffc", "on-tertiary-container": "#fffbff", "tertiary-fixed": "#e9ddff", "on-surface": "#00201e", "on-secondary-container": "#006f64", "outline": "#6d7a77", "outline-variant": "#bcc9c6", "on-tertiary": "#ffffff", "on-primary-fixed": "#00201d", "on-surface-variant": "#3d4947", "tertiary": "#6b38d4", "secondary-fixed-dim": "#4fdbc8", "surface-container-low": "#c6fef8", "surface-dim": "#ade5df", "surface-container-lowest": "#ffffff", "on-primary": "#ffffff", "tertiary-fixed-dim": "#d0bcff", "on-secondary-fixed-variant": "#005048", "on-tertiary-fixed": "#23005c", "surface-container-high": "#bbf3ed", "primary": "#00685f", "surface-container": "#c1f9f3", "surface-container-highest": "#b5ede7", "surface-bright": "#e4fffb", "on-background": "#00201e", "background": "#e4fffb", "on-primary-fixed-variant": "#005049", "surface": "#e4fffb", "primary-fixed": "#89f5e7", "secondary-fixed": "#71f8e4", "tertiary-container": "#8455ef" },
        borderRadius: { "DEFAULT": "1rem", "lg": "2rem", "xl": "3rem", "full": "9999px" },
        spacing: { "gutter": "1rem", "space-lg": "1.5rem", "space-md": "1rem", "margin-mobile": "1rem", "space-xs": "0.25rem", "gutter-sm": "0.75rem", "margin": "1.25rem", "space-xl": "2rem", "space-sm": "0.5rem" },
        fontFamily: { "display-lg": ["Plus Jakarta Sans"], "headline-sm": ["Plus Jakarta Sans"], "headline-md": ["Plus Jakarta Sans"], "label-sm": ["Plus Jakarta Sans"], "body-md": ["Plus Jakarta Sans"], "headline-lg": ["Plus Jakarta Sans"], "label-md": ["Plus Jakarta Sans"], "headline-lg-mobile": ["Plus Jakarta Sans"], "label-lg": ["Plus Jakarta Sans"], "body-lg": ["Plus Jakarta Sans"], "body-sm": ["Plus Jakarta Sans"] },
        fontSize: { "display-lg": ["36px", { lineHeight: "44px", letterSpacing: "-0.03em", fontWeight: "800" }], "headline-sm": ["18px", { lineHeight: "24px", fontWeight: "600" }], "headline-md": ["22px", { lineHeight: "28px", letterSpacing: "-0.01em", fontWeight: "700" }], "label-sm": ["11px", { lineHeight: "14px", letterSpacing: "0.02em", fontWeight: "500" }], "body-md": ["14px", { lineHeight: "20px", fontWeight: "400" }], "headline-lg": ["30px", { lineHeight: "38px", letterSpacing: "-0.02em", fontWeight: "700" }], "label-md": ["13px", { lineHeight: "18px", fontWeight: "600" }], "headline-lg-mobile": ["26px", { lineHeight: "34px", letterSpacing: "-0.02em", fontWeight: "700" }], "label-lg": ["15px", { lineHeight: "20px", letterSpacing: "0.01em", fontWeight: "600" }], "body-lg": ["16px", { lineHeight: "24px", fontWeight: "500" }], "body-sm": ["12px", { lineHeight: "16px", fontWeight: "400" }] }
      } } };
    </script>
    <style>
      @layer base {
        html, body { width: 100%; margin: 0; padding: 0; }
        body { overscroll-behavior: none; }
        .pb-safe { padding-bottom: env(safe-area-inset-bottom, 0px); }
        .pt-safe { padding-top: env(safe-area-inset-top, 0px); }
        main > :first-child { margin-top: 0 !important; }
        main > :last-child { margin-bottom: 0 !important; }
      }
      ::-webkit-scrollbar { display: none; }
    </style>
</head>
<body class="min-h-screen bg-slate-900 text-on-surface flex items-center justify-center p-0 sm:p-6 font-body-md text-body-md antialiased select-none">
    <!-- Cadre mobile (même format que l'écran d'accueil) -->
    <main class="relative w-full max-w-[400px] h-[844px] max-h-screen sm:max-h-[92vh] bg-surface overflow-y-auto shadow-2xl border-[8px] border-slate-800/80 sm:border-slate-700/60 sm:rounded-[44px] flex flex-col">
        <?= $content ?>
    </main>
</body>
</html>
