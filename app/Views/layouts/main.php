<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= isset($title) ? htmlspecialchars($title) . ' · MedCare' : 'MedCare' ?></title>

    <!-- Tailwind CSS v3 (CDN) + plugins -->
    <script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>

    <!-- Google Fonts : Plus Jakarta Sans -->
    <link href="https://fonts.googleapis.com" rel="preconnect">
    <link crossorigin href="https://fonts.gstatic.com" rel="preconnect">
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <!-- Configuration Tailwind (thème MedCare — commun à tous les écrans) -->
    <script>
      tailwind.config = {
        theme: {
          extend: {
            fontFamily: {
              sans: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
            },
            colors: {
              teal: {
                brand: '#1AA89B',
                brandDark: '#12867B',
                brandLight: '#E8F7F5',
                darkText: '#0B2926',
                450: '#14b8a6',
                550: '#0d9488',
                soft: '#2dd4bf',
                primary: '#0fa396'
              },
              doctor: {
                bg: '#fcf8f5',
                card: 'rgba(255, 255, 255, 0.78)',
                subtext: '#8a99a8',
                heading: '#1e293b'
              }
            },
            boxShadow: {
              'teal-glow': '0 10px 25px -4px rgba(26, 168, 155, 0.45)',
              'glass': '0 20px 40px -15px rgba(18, 77, 72, 0.08), inset 0 1px 1px 0 rgba(255, 255, 255, 0.8)',
              'icon-soft': '0 8px 16px -2px rgba(26, 168, 155, 0.08), 0 2px 4px -1px rgba(0, 0, 0, 0.04)',
              'podium-shadow': '0 25px 40px -10px rgba(19, 74, 69, 0.15)',
              'soft-card': '0 10px 25px -4px rgba(220, 185, 170, 0.22), 0 4px 10px -2px rgba(0, 0, 0, 0.03)',
              'floating-btn': '0 8px 20px -2px rgba(15, 163, 150, 0.45)',
              'pill-soft': '0 4px 12px rgba(0, 0, 0, 0.04)',
              'nav-bar': '0 -6px 24px rgba(180, 150, 140, 0.12)'
            },
            borderRadius: {
              '3xl': '1.8rem',
              '4xl': '2.2rem'
            }
          }
        }
      }
    </script>

    <!-- Styles personnalisés (verre dépoli, podium 3D, cartes) -->
    <link rel="stylesheet" href="<?= ASSETS_URL ?>/css/style.css">
</head>
<body class="<?= $bodyClass ?? 'bg-slate-900 min-h-screen flex items-center justify-center p-0 sm:p-6 antialiased font-sans select-none' ?>">

    <?= $content ?>

    <script src="<?= ASSETS_URL ?>/js/app.js"></script>
</body>
</html>
