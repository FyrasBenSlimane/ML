import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/doctor_banner.dart';
import '../../../shared/widgets/patient_alert_card.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../data/doza_models.dart';

/// Doza result for the doctor: risk zone, the zone's real observed rate, the
/// decision, and the factors that weighed most (an explanation, not advice).
class DozaResultScreen extends StatelessWidget {
  const DozaResultScreen({super.key, required this.result});

  final DozaResult result;

  Color get _zoneColor => switch (result.zone) {
        'Risque élevé' => AppColors.red,
        'Risque intermédiaire' => AppColors.amber,
        _ => AppColors.green,
      };

  LinearGradient get _zoneGradient => switch (result.zone) {
        'Risque élevé' => const LinearGradient(
            colors: [Color(0xFFFB7185), Color(0xFFEF4444), Color(0xFFDB2777)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        'Risque intermédiaire' => const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFF97316)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        _ => const LinearGradient(
            colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: [_zoneColor, AppColors.coral, AppColors.amber],
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
              title: const Text('Résultat Doza'),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 36 + MediaQuery.paddingOf(context).bottom),
              sliver: SliverList.list(
                children: [
                  const DoctorBanner(),
                  const SizedBox(height: 14),
                  _hero(),
                  const SizedBox(height: 14),
                  _zoneRateCard(),
                  const SizedBox(height: 14),
                  _factorsCard(),
                  const SizedBox(height: 14),
                  PatientAlertCard(
                    module: 'doza',
                    gradient: AppColors.coralGradient,
                    niveau: result.changeProbable ? 'attention' : 'info',
                    titre: result.changeProbable
                        ? 'Un petit ajustement de votre traitement'
                        : 'Votre suivi se passe bien',
                    message: result.changeProbable
                        ? 'Bonjour, votre médecin a bien étudié votre dossier. Il souhaite adapter '
                            'votre traitement pour votre confort et vous proposera un rendez-vous '
                            'prochainement. Prenez soin de vous.'
                        : 'Bonjour, votre médecin a étudié votre dossier. Tout se poursuit '
                            'normalement : vous pouvez continuer votre traitement comme convenu. '
                            'Prenez soin de vous.',
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Écouter l\'explication de Doza',
                    icon: Icons.volume_up_rounded,
                    gradient: AppColors.coralGradient,
                    onTap: () => AvatarStageScreen.open(context,
                        avatar: AvatarProfile.doza,
                        segments: result.narrative,
                        title: 'Doza explique'),
                  ),
                ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return SoftCard(
      gradient: _zoneGradient,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          _Gauge(value: result.proba, percentage: result.pourcentage),
          const SizedBox(height: 14),
          Text(result.zone,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Probabilité que la dose d\'insuline change',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5)),
          const SizedBox(height: 12),
          Pill(
            result.changeProbable ? 'CHANGEMENT PROBABLE' : 'DOSE PLUTÔT STABLE',
            color: Colors.white.withValues(alpha: 0.28),
            filled: true,
            icon: result.changeProbable ? Icons.swap_vert_rounded : Icons.horizontal_rule_rounded,
          ),
        ],
      ),
    );
  }

  Widget _zoneRateCard() {
    return SoftCard(
      child: Row(
        children: [
          IconBadge(Icons.insights_rounded, color: _zoneColor, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.zoneTaux != null
                      ? 'Taux réel observé : ${result.zoneTaux} %'
                      : 'Taux réel observé : indisponible',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Parmi les patients proches de cette zone, c\'est la part dont la dose a '
                  'réellement changé. Seuil de décision : ${(result.seuil * 100).round()} %.',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _factorsCard() {
    final facteurs = result.facteurs;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_tree_rounded, color: AppColors.coral),
              SizedBox(width: 8),
              Expanded(
                child: Text('Facteurs qui ont le plus pesé',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Explication de ce patient précis — pas un conseil : ces éléments '
              '(âge, provenance…) ne sont pas modifiables.',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          if (facteurs.isEmpty)
            const Text('Aucun facteur n\'a dépassé le seuil d\'influence.',
                style: TextStyle(color: AppColors.inkSoft))
          else
            for (final f in facteurs) ...[
              _FactorRow(factor: f, maxImpact: facteurs.first.impact),
              if (f != facteurs.last) const SizedBox(height: 12),
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
                const Text('estimée',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor, required this.maxImpact});

  final DozaFactor factor;
  final int maxImpact;

  @override
  Widget build(BuildContext context) {
    final frac = maxImpact <= 0 ? 0.0 : (factor.impact / maxImpact).clamp(0.08, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${factor.champ[0].toUpperCase()}${factor.champ.substring(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            ),
            Text(factor.reponse,
                style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: frac),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.coral),
            ),
          ),
        ),
      ],
    );
  }
}
