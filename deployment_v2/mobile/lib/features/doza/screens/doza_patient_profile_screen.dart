import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/patient/patient_alerts_cubit.dart';
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
/// Les alertes « doza » du patient s'affichent ici, avec un halo lumineux et
/// des gestes animés lorsqu'un message n'est pas encore lu.
class DozaPatientProfileScreen extends StatefulWidget {
  const DozaPatientProfileScreen({super.key});

  @override
  State<DozaPatientProfileScreen> createState() => _DozaPatientProfileScreenState();
}

class _DozaPatientProfileScreenState extends State<DozaPatientProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Rafraîchir les messages à l'ouverture de l'écran.
    context.read<PatientAlertsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final state = context.watch<PatientAlertsCubit>().state;
    final dozaAlerts =
        state.alerts.where((a) => a.module == 'doza').toList(growable: false);
    final unread = dozaAlerts.where((a) => !a.lu).length;

    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.coral, AppColors.pink, AppColors.amber],
        opacity: 0.18,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(onIntro: () => openDozaIntro(context), unread: unread),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 32 + bottom),
              sliver: SliverList.list(
                children: [
                  if (dozaAlerts.isNotEmpty) ...[
                    SectionHeader(
                      unread > 0 ? 'Un message de votre médecin' : 'Vos messages',
                      icon: unread > 0
                          ? Icons.mark_email_unread_rounded
                          : Icons.mark_email_read_rounded,
                    ),
                    for (final a in dozaAlerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AlertCard(alert: a),
                      ),
                    const SizedBox(height: 10),
                  ],
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

/// Halo lumineux qui pulse autour de [child] tant que [active] est vrai.
class _Glow extends StatefulWidget {
  const _Glow({
    required this.child,
    required this.color,
    this.radius = 28,
    this.active = true,
  });

  final Widget child;
  final Color color;
  final double radius;
  final bool active;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + 0.45 * t),
                blurRadius: 18 + 30 * t,
                spreadRadius: 1 + 3 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onIntro, this.unread = 0});

  final VoidCallback onIntro;
  final int unread;

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
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _Glow(
                active: unread > 0,
                color: Colors.white,
                radius: 40,
                child: Pressable(
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
                ),
              ).animate().scale(
                  begin: const Offset(0.85, 0.85),
                  curve: Curves.easeOutBack,
                  duration: 600.ms),
              if (unread > 0)
                Positioned(
                  top: -6,
                  right: 6,
                  child: _AlertBadge(count: unread),
                ),
            ],
          ),
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

/// Pastille « nouveau message » qui rebondit sur l'avatar.
class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glow(AppColors.coral, strength: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active_rounded, color: AppColors.coral, size: 15)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.06, end: 0.06, duration: 420.ms, curve: Curves.easeInOut),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(
                  color: AppColors.coral, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.12, duration: 700.ms, curve: Curves.easeInOut);
  }
}

/// Carte d'alerte affichée dans l'écran Doza. Non lue : halo pulsé, balayage
/// lumineux et cloche animée pour attirer l'œil (règle C : aucun résultat).
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final PatientAlert alert;

  (Color, IconData) get _style => switch (alert.niveau) {
        'important' => (AppColors.coral, Icons.favorite_rounded),
        'attention' => (AppColors.amber, Icons.spa_rounded),
        _ => (AppColors.green, Icons.check_circle_rounded),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    final unread = !alert.lu;
    final card = SoftCard(
      padding: const EdgeInsets.all(16),
      border: unread ? Border.all(color: color.withValues(alpha: 0.6), width: 1.6) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (unread)
                IconBadge(Icons.notifications_active_rounded, color: color, size: 42)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .rotate(begin: -0.05, end: 0.05, duration: 420.ms, curve: Curves.easeInOut)
              else
                IconBadge(icon, color: color, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.titre,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    Text(
                        '${alert.medecin} · ${DateFormat('d MMM · HH:mm').format(alert.createdAt)}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(alert.message,
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 13.5, height: 1.45)),
          if (unread) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Pressable(
                onTap: () => context.read<PatientAlertsCubit>().markRead(alert.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_rounded, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text('Marquer comme lu',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (!unread) return card;
    // Non lue : halo lumineux pulsé + balayage « shimmer » répété.
    return _Glow(color: color, radius: 28, child: card)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
            duration: 1900.ms,
            delay: 600.ms,
            color: color.withValues(alpha: 0.25),
            angle: 0.4);
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
