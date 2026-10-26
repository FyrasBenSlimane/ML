import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/patient/patient_alerts_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pressable.dart';
import 'avatar_profile.dart';
import 'avatar_stage_screen.dart';
import 'widgets/avatar_video.dart';

/// Une étape de la rubrique « Comment je fonctionne ».
typedef HowStep = (IconData icon, String title, String subtitle, Color color);

/// Une ligne de la rubrique « Bon à savoir ».
typedef GoodToKnow = (IconData icon, String text);

/// Écran patient générique d'un avatar (Doza, Sora, …) : même mise en page,
/// seulement paramétrée par le profil, les couleurs et les textes. Aucun
/// résultat de modèle, un seul bouton « Hear me ». Les alertes du patient pour
/// ce [module] s'affichent ici, avec un halo lumineux et des gestes animés
/// lorsqu'un message n'est pas encore lu.
///
/// Réutilisé par [DozaPatientProfileScreen] et [SoraPatientProfileScreen] :
/// paramétrer plutôt que dupliquer.
class AvatarPatientProfileScreen extends StatefulWidget {
  const AvatarPatientProfileScreen({
    super.key,
    required this.avatar,
    required this.module,
    required this.headerGradient,
    required this.blobColors,
    required this.brandLabel,
    required this.brandDot,
    required this.subtitle,
    required this.title,
    required this.intro,
    required this.steps,
    this.notes = const [],
  });

  /// Le profil de l'avatar (visage, portrait, dégradé, accent, voix).
  final AvatarProfile avatar;

  /// Clé module des alertes affichées ici ('doza', 'sora', …).
  final String module;

  /// Dégradé de l'en-tête (charte de Ryma, aucun nouveau style).
  final LinearGradient headerGradient;

  /// Couleurs du fond « blob » derrière le contenu.
  final List<Color> blobColors;

  /// Étiquette de marque en haut de l'en-tête, ex. « DOZA AI ».
  final String brandLabel;

  /// Petite pastille clignotante à côté de l'étiquette de marque.
  final Color brandDot;

  /// Sous-titre sous le nom, ex. « Assistant insuline · by Emna ».
  final String subtitle;

  /// Nom affiché et titre de l'écran-vidéo (« Doza », « Sora »).
  final String title;

  /// Ce que l'avatar raconte quand le patient appuie sur « Hear me ».
  final List<SpeechSegment> intro;

  /// Étapes de la rubrique « Comment je fonctionne ».
  final List<HowStep> steps;

  /// Rubrique « Bon à savoir » (optionnelle : vide = rubrique masquée).
  final List<GoodToKnow> notes;

  @override
  State<AvatarPatientProfileScreen> createState() => _AvatarPatientProfileScreenState();
}

class _AvatarPatientProfileScreenState extends State<AvatarPatientProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Rafraîchir les messages à l'ouverture de l'écran.
    context.read<PatientAlertsCubit>().load();
  }

  void _openIntro() => AvatarStageScreen.open(
        context,
        avatar: widget.avatar,
        segments: widget.intro,
        title: widget.title,
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final state = context.watch<PatientAlertsCubit>().state;
    final alerts =
        state.alerts.where((a) => a.module == widget.module).toList(growable: false);
    final unread = alerts.where((a) => !a.lu).length;

    return Scaffold(
      body: BlobBackground(
        colors: widget.blobColors,
        opacity: 0.18,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _Header(
                avatar: widget.avatar,
                gradient: widget.headerGradient,
                brandLabel: widget.brandLabel,
                brandDot: widget.brandDot,
                subtitle: widget.subtitle,
                title: widget.title,
                onIntro: _openIntro,
                unread: unread,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 32 + bottom),
              sliver: SliverList.list(
                children: [
                  if (alerts.isNotEmpty) ...[
                    SectionHeader(
                      unread > 0 ? 'A message from your doctor' : 'Your messages',
                      icon: unread > 0
                          ? Icons.mark_email_unread_rounded
                          : Icons.mark_email_read_rounded,
                    ),
                    for (final a in alerts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AlertCard(alert: a, accent: widget.avatar.accent),
                      ),
                    const SizedBox(height: 10),
                  ],
                  const SectionHeader('How I work', icon: Icons.route_rounded),
                  _HowItWorks(steps: widget.steps),
                  if (widget.notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const SectionHeader('Good to know', icon: Icons.favorite_rounded),
                    SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final n in widget.notes)
                            _Note(n.$1, n.$2, color: widget.avatar.accent),
                        ],
                      ),
                    ),
                  ],
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
  const _Header({
    required this.avatar,
    required this.gradient,
    required this.brandLabel,
    required this.brandDot,
    required this.subtitle,
    required this.title,
    required this.onIntro,
    this.unread = 0,
  });

  final AvatarProfile avatar;
  final LinearGradient gradient;
  final String brandLabel;
  final Color brandDot;
  final String subtitle;
  final String title;
  final VoidCallback onIntro;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 26),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseDot(color: brandDot, size: 7),
                  Text(brandLabel,
                      style: const TextStyle(
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
                  child: _AlertBadge(count: unread, accent: avatar.accent),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Colors.white),
            ],
          ),
          Text(subtitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
  const _AlertBadge({required this.count, required this.accent});

  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glow(accent, strength: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_active_rounded, color: accent, size: 15)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(begin: -0.06, end: 0.06, duration: 420.ms, curve: Curves.easeInOut),
          const SizedBox(width: 4),
          Text('$count',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.12, duration: 700.ms, curve: Curves.easeInOut);
  }
}

/// Carte d'alerte affichée dans l'écran de l'avatar. Non lue : halo pulsé,
/// balayage lumineux et cloche animée pour attirer l'œil (règle C : aucun
/// résultat). L'accent sert d'ultime recours quand le niveau est neutre.
class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.accent});

  final PatientAlert alert;
  final Color accent;

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
  const _HowItWorks({required this.steps});

  final List<HowStep> steps;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      IconBadge(steps[i].$1, color: steps[i].$4, size: 44),
                      if (i < steps.length - 1)
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
                          Text(steps[i].$2,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(steps[i].$3,
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
  const _Note(this.icon, this.text, {required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
