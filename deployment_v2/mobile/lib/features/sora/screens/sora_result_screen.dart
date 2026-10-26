import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/doctor_banner.dart';
import '../../../shared/widgets/patient_alert_card.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../data/sora_models.dart';

/// Sora result for the doctor: a gauge driven by the follow-up model, two tiles
/// (follow-up / control), and the combined discharge profile.
class SoraResultScreen extends StatelessWidget {
  const SoraResultScreen({super.key, required this.result});

  final SoraResult result;

  @override
  Widget build(BuildContext context) {
    final suivi = result.suivi;
    final ctrl = result.controle;
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.amber, AppColors.coral, AppColors.teal],
        opacity: 0.16,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Résultat Sora'),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 36 + MediaQuery.paddingOf(context).bottom),
              sliver: SliverList.list(
                children: [
                  const DoctorBanner(),
                  const SizedBox(height: 14),
                  _gaugeHero(suivi),
                  const SizedBox(height: 14),
                  // IntrinsicHeight gives the stretched Row a bounded height so
                  // both tiles match (a plain stretch Row would take infinite
                  // height inside the scroll view).
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _Tile(
                            icon: Icons.event_repeat_rounded,
                            color: suivi.classe == 1 ? AppColors.coral : AppColors.green,
                            title: 'Suivi',
                            verdict: suivi.resultat,
                            pourcentage: suivi.pourcentage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Tile(
                            icon: Icons.monitor_heart_rounded,
                            color: ctrl.classe == 1 ? AppColors.red : AppColors.green,
                            title: 'Contrôle',
                            verdict: ctrl.resultat,
                            pourcentage: ctrl.pourcentage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _profilCard(ctrl),
                  const SizedBox(height: 14),
                  PatientAlertCard(
                    module: 'sora',
                    gradient: AppColors.amberGradient,
                    niveau: suivi.classe == 1 ? 'attention' : 'info',
                    titre: suivi.classe == 1
                        ? 'Un accompagnement renforcé après votre sortie'
                        : 'Votre sortie est bien préparée',
                    message: suivi.classe == 1
                        ? 'Bonjour, votre médecin souhaite vous accompagner de plus près après '
                            'votre sortie. Un suivi vous sera proposé pour vous aider au quotidien. '
                            'Prenez soin de vous.'
                        : 'Bonjour, votre médecin a préparé votre sortie. Votre suivi habituel '
                            'suffit : continuez vos bonnes habitudes. Prenez soin de vous.',
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Écouter l\'explication de Sora',
                    icon: Icons.volume_up_rounded,
                    gradient: AppColors.amberGradient,
                    onTap: () => AvatarStageScreen.open(context,
                        avatar: AvatarProfile.sora,
                        segments: result.narrative,
                        title: 'Sora explique'),
                  ),
                ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gaugeHero(SoraBloc suivi) {
    return SoftCard(
      gradient: AppColors.amberGradient,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          _Gauge(value: suivi.proba, percentage: suivi.pourcentage),
          const SizedBox(height: 14),
          Text(suivi.resultat,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Jauge pilotée par le besoin de suivi à la sortie',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _profilCard(SoraBloc ctrl) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_rounded, color: AppColors.amber),
              SizedBox(width: 8),
              Text('Profil de sortie recommandé',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.amber.withValues(alpha: 0.14),
                AppColors.coral.withValues(alpha: 0.10),
              ]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(result.profil,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.35)),
          ),
          if (ctrl.message != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.inkSoft, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ctrl.message!,
                      style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, height: 1.4)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular gauge filling to the probability, percentage in the centre.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.value, required this.percentage});

  final double value;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 11,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$percentage%',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1)),
                const Text('suivi',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.verdict,
    required this.pourcentage,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String verdict;
  final int pourcentage;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, color: color, size: 38),
              const Spacer(),
              Text('$pourcentage%',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(verdict, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
        ],
      ),
    );
  }
}
