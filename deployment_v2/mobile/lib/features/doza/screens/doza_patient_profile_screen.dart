import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../../avatar/widgets/avatar_video.dart';

/// Ce que Doza raconte quand le patient veut faire sa connaissance.
/// Aucun chiffre, aucun résultat de modèle — seulement des mots rassurants.
const dozaIntro = [
  SpeechSegment('greeting',
      "Bonjour, je suis Doza, l'assistante insuline de votre équipe soignante."),
  SpeechSegment('action',
      'Pendant votre séjour, votre médecin répond à quelques questions sur votre santé et votre traitement.'),
  SpeechSegment('comparison',
      "Grâce à ces réponses, j'aide votre médecin à anticiper si votre dose d'insuline doit être adaptée."),
  SpeechSegment('action',
      "C'est toujours votre médecin qui décide. Moi, je l'aide simplement à préparer votre suivi."),
  SpeechSegment('action',
      'Si quelque chose doit changer, votre médecin vous enverra un message dans l\'application.'),
  SpeechSegment('closing',
      'Prenez soin de vous. Votre équipe soignante veille sur vous.'),
];

void openDozaIntro(BuildContext context) => AvatarStageScreen.open(
      context,
      avatar: AvatarProfile.doza,
      segments: dozaIntro,
      title: 'Doza',
    );

/// Écran patient de Doza — même mise en page que [TeemoProfileScreen], en
/// corail, sans aucun résultat de modèle et avec le seul bouton « Hear me ».
class DozaPatientProfileScreen extends StatelessWidget {
  const DozaPatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.coral, AppColors.pink, AppColors.amber],
        opacity: 0.18,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(onIntro: () => openDozaIntro(context))),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 32 + bottom),
              sliver: SliverList.list(
                children: [
                  const SectionHeader('Comment je fonctionne', icon: Icons.route_rounded),
                  const _HowItWorks(),
                  const SizedBox(height: 10),
                  const SectionHeader('Bon à savoir', icon: Icons.favorite_rounded),
                  const SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Note(Icons.verified_user_rounded,
                            "C'est toujours votre médecin qui décide. Doza l'aide seulement à préparer votre suivi."),
                        _Note(Icons.lock_person_rounded,
                            'Vos analyses restent avec votre médecin ; vous ne voyez que ses messages.'),
                        _Note(Icons.spa_rounded,
                            'Doza est là pour vous rassurer, jamais pour vous inquiéter.'),
                      ],
                    ),
                  ),
                ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onIntro});

  final VoidCallback onIntro;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const avatar = AvatarProfile.doza;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDA4AF), Color(0xFFFB7185), Color(0xFFF472B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Pressable(
                onTap: () => Navigator.of(context).maybePop(),
                child: const GlassPanel(
                  radius: 16,
                  opacity: 0.22,
                  padding: EdgeInsets.all(9),
                  child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseDot(color: Color(0xFFFECDD3), size: 7),
                  Text('DOZA AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontSize: 12)),
                ],
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 14),
          Pressable(
            onTap: onIntro,
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: AppColors.glow(Colors.black, strength: 0.18),
              ),
              child: Hero(
                tag: avatar.heroTag,
                flightShuttleBuilder: (ctx, anim, dir, from, to) =>
                    avatarHeroShuttle(ctx, anim, dir, from, to, avatar),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Image.asset(avatar.portraitAsset,
                      fit: BoxFit.cover, alignment: Alignment.topCenter),
                ),
              ),
            ),
          ).animate().scale(
              begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 600.ms),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Doza',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              SizedBox(width: 6),
              Icon(Icons.verified_rounded, color: Colors.white),
            ],
          ),
          const Text('Assistant insuline · by Emna',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeaderButton(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Hear me',
                  onTap: onIntro,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (Icons.edit_note_rounded, 'Le médecin répond à quelques questions',
        'Sur votre santé et votre traitement, pendant votre séjour.', AppColors.blue),
    (Icons.insights_rounded, "J'aide le médecin à anticiper",
        "Un éventuel ajustement de votre dose d'insuline.", AppColors.coral),
    (Icons.mark_email_read_rounded, 'Le médecin vous écrit si besoin',
        'Vous recevez un message bienveillant dans « Mes messages ».', AppColors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      IconBadge(_steps[i].$1, color: _steps[i].$4, size: 44),
                      if (i < _steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: AppColors.line,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18, top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_steps[i].$2,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(_steps[i].$3,
                              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.coral),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
