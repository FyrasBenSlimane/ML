import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/patient_alert_card.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../../avatar/widgets/avatar_bubble.dart';
import '../data/teemo_models.dart';
import '../widgets/risk_widgets.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result, this.fresh = false});

  final TeemoResult result;

  /// Just computed (vs. reopened from history) — plays the bigger entrance.
  final bool fresh;

  void _openTeemo(BuildContext context) => AvatarStageScreen.open(
        context,
        avatar: AvatarProfile.teemo,
        segments: result.narrative,
        title: 'Teemo explains',
      );

  @override
  Widget build(BuildContext context) {
    final r = result;
    final color = AppColors.forLevel(r.level);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(result: r)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 130 + bottomPad),
                  sliver: SliverList.list(
                    children: [
                      _MeaningCard(result: r, color: color),
                      _DriversCard(result: r),
                      _PlanCard(result: r),
                      PatientAlertCard(
                        module: 'teemo',
                        gradient: AppColors.gradientForLevel(r.level),
                        niveau: switch (r.level) {
                          'HIGH' => 'important',
                          'MODERATE' => 'attention',
                          _ => 'info',
                        },
                        titre: switch (r.level) {
                          'HIGH' => 'Votre médecin aimerait vous revoir bientôt',
                          'MODERATE' => 'Un suivi un peu plus attentif',
                          _ => 'Votre rétablissement est sur la bonne voie',
                        },
                        message: switch (r.level) {
                          'HIGH' =>
                            'Bonjour, votre médecin souhaite vous revoir rapidement après votre '
                                'sortie pour s\'assurer que tout va bien. Un rendez-vous rapproché '
                                'vous sera proposé. Prenez soin de vous.',
                          'MODERATE' =>
                            'Bonjour, votre médecin souhaite garder un œil attentif sur votre '
                                'rétablissement. Pensez à bien respecter vos rendez-vous de suivi. '
                                'Prenez soin de vous.',
                          _ =>
                            'Bonjour, votre médecin a étudié votre dossier. Votre rétablissement '
                                'se présente bien : continuez vos bonnes habitudes. Prenez soin de vous.',
                        },
                      ),
                      _SnapshotCard(result: r),
                      _ModelCard(result: r),
                    ]
                        .animate(interval: 120.ms)
                        .fadeIn(duration: 450.ms, delay: fresh ? 900.ms : 100.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutCubic),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 20 + bottomPad,
              child: AvatarBubble(avatar: AvatarProfile.teemo, onTap: () => _openTeemo(context))
                  .animate()
                  .scale(
                      delay: fresh ? 1600.ms : 300.ms,
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      alignment: Alignment.bottomRight)
                  .fadeIn(delay: fresh ? 1600.ms : 300.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.result});

  final TeemoResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 4, 16, 26),
      decoration: BoxDecoration(
        gradient: AppColors.gradientForLevel(r.level),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: AppColors.glow(AppColors.forLevel(r.level), strength: 0.3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(r.label ?? 'Assessment',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                    Text(DateFormat('EEE d MMM · HH:mm').format(r.createdAt),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 14),
          RiskGauge(
            probability: r.probability,
            level: r.level,
            thresholds: r.thresholds,
            baseline: r.baselineRate,
          ),
          const SizedBox(height: 10),
          Pill(r.levelLabel.toUpperCase(),
                  color: Colors.white.withValues(alpha: 0.25), filled: true, icon: Icons.shield_rounded)
              .animate()
              .scale(delay: 1200.ms, curve: Curves.elasticOut, duration: 800.ms),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(
                value: '${r.relativeRisk.toStringAsFixed(1)}×',
                label: 'hospital average\n(${(r.baselineRate * 100).toStringAsFixed(1)}%)',
              ),
              _divider(),
              _HeaderStat(
                value: r.percentile == null ? '—' : '${r.percentile}%',
                label: 'of tested patients\nhave lower risk',
              ),
              _divider(),
              _HeaderStat(
                value: r.interventionRecommended ? 'Yes' : 'No',
                label: 'follow-up\nintervention',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3));
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.25)),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.icon, required this.color, required this.title, required this.child, this.subtitle});

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(icon, color: color, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                      if (subtitle != null)
                        Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _MeaningCard extends StatelessWidget {
  const _MeaningCard({required this.result, required this.color});

  final TeemoResult result;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final band = r.bandObservedRate;
    final n = band == null ? (r.probability * 100).round() : (band * 100).round();
    final group = r.level.toLowerCase();
    return _CardShell(
      icon: Icons.groups_rounded,
      color: color,
      title: 'What this means',
      subtitle: 'Calibrated on ${NumberFormat.decimalPattern().format(r.metrics.nTest)} held-out patients',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(
            style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.inkSoft),
            children: [
              const TextSpan(text: 'In testing, '),
              TextSpan(
                  text: '$n out of 100',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
              TextSpan(text: ' patients in the $group-risk group were readmitted within 30 days.'),
            ],
          )),
          const SizedBox(height: 4),
          Text("This patient's own estimate: ${r.percentage.round()} in 100.",
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          const SizedBox(height: 14),
          IconArray(count: n, color: color),
          if (r.percentile != null) ...[
            const SizedBox(height: 16),
            Text('Higher than ${r.percentile}% of tested patients',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            PercentileBar(percentile: r.percentile!, color: color),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lowest', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                Text('Highest', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DriversCard extends StatelessWidget {
  const _DriversCard({required this.result});

  final TeemoResult result;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      icon: Icons.insights_rounded,
      color: AppColors.violet,
      title: 'Why — key drivers',
      subtitle: 'SHAP explanation for this patient · tap a row',
      child: Column(
        children: [
          const Row(
            children: [
              _Legend(color: AppColors.coral, text: 'raises risk'),
              SizedBox(width: 16),
              _Legend(color: AppColors.teal, text: 'lowers risk'),
            ],
          ),
          const SizedBox(height: 12),
          DriverList(drivers: result.drivers.take(8).toList()),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.result});

  final TeemoResult result;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      icon: Icons.checklist_rounded,
      color: AppColors.teal,
      title: 'Care plan',
      subtitle: 'Tick items off as you go',
      child: ActionChecklist(actions: result.actions),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.result});

  final TeemoResult result;

  static const _age = {
    '[0-10)': '0–9', '[10-20)': '10–19', '[20-30)': '20–29', '[30-40)': '30–39',
    '[40-50)': '40–49', '[50-60)': '50–59', '[60-70)': '60–69', '[70-80)': '70–79',
    '[80-90)': '80–89', '[90-100)': '90+',
  };

  @override
  Widget build(BuildContext context) {
    final p = result.patient;
    final chips = <(IconData, String)>[
      (Icons.cake_rounded, '${_age[p['age']] ?? p['age']} yrs'),
      (p['gender'] == 'Female' ? Icons.female_rounded : Icons.male_rounded, '${p['gender']}'),
      (Icons.bed_rounded, '${p['time_in_hospital']} days'),
      (Icons.medication_rounded, '${p['num_medications']} meds'),
      (Icons.format_list_numbered_rounded, '${p['number_diagnoses']} diagnoses'),
      (Icons.king_bed_rounded, '${p['number_inpatient']} prior stays'),
      (Icons.emergency_rounded, '${p['number_emergency']} ER visits'),
      (Icons.vaccines_rounded, 'Insulin: ${p['insulin']}'),
      (Icons.bloodtype_rounded, 'HbA1c: ${p['A1Cresult']}'.replaceAll('Not_Tested', 'not tested')),
    ];
    final defaulted = result.defaultedFields.where((f) => f != 'diabetesMed').length;
    return _CardShell(
      icon: Icons.assignment_ind_rounded,
      color: AppColors.blue,
      title: 'Patient snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, text) in chips)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: AppColors.blue),
                      const SizedBox(width: 6),
                      Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          if (defaulted > 0) ...[
            const SizedBox(height: 12),
            Text('$defaulted field(s) were not provided and used typical hospital values.',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.result});

  final TeemoResult result;

  @override
  Widget build(BuildContext context) {
    final m = result.metrics;
    Widget metric(String label, String value, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: c)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              ],
            ),
          ),
        );
    return _CardShell(
      icon: Icons.verified_user_rounded,
      color: AppColors.indigo,
      title: 'About this prediction',
      subtitle: '${result.model['name']}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              metric('ROC-AUC', m.rocAuc.toStringAsFixed(3), AppColors.indigo),
              const SizedBox(width: 8),
              metric('PR-AUC', m.prAuc.toStringAsFixed(3), AppColors.violet),
              const SizedBox(width: 8),
              metric('PR lift', '${m.prLift.toStringAsFixed(1)}×', AppColors.teal),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${result.model['split']}. Explanations: ${result.model['explanations']}.\n\n'
            'Teemo supports — never replaces — clinical judgement.',
            style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
