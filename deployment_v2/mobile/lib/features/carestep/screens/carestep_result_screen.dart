import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/doctor_banner.dart';
import '../../../shared/widgets/patient_alert_card.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../data/carestep_models.dart';

/// CareStep result for the doctor: risk gauge and level, comparison with the
/// hospital average, reasons, actions, the week-by-week plan and a care-team
/// summary — then the patient alert and the talking avatar.
class CareStepResultScreen extends StatelessWidget {
  const CareStepResultScreen({super.key, required this.result});

  final CareStepResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final levelColor = AppColors.forLevel(r.paletteLevel);
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.blue, AppColors.sky, AppColors.indigo],
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
              title: const Text('CareStep result'),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 36 + MediaQuery.paddingOf(context).bottom),
              sliver: SliverList.list(
                children: [
                  const DoctorBanner(),
                  const SizedBox(height: 14),
                  _hero(levelColor),
                  const SizedBox(height: 14),
                  _comparison(levelColor),
                  const SizedBox(height: 14),
                  _ListCard(
                    icon: Icons.manage_search_rounded,
                    color: AppColors.coral,
                    title: 'Why this result',
                    items: r.reasons,
                    bullet: Icons.arrow_right_rounded,
                  ),
                  const SizedBox(height: 14),
                  _ListCard(
                    icon: Icons.task_alt_rounded,
                    color: AppColors.green,
                    title: 'What to do now',
                    items: r.actions,
                    bullet: Icons.check_circle_rounded,
                  ),
                  if (r.plan.isNotEmpty) ...[
                    const SectionHeader('30-day recovery plan', icon: Icons.event_note_rounded),
                    for (final w in r.plan) ...[
                      _WeekCard(week: w),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 2),
                  _CareTeamCard(team: r.careTeam),
                  const SizedBox(height: 14),
                  PatientAlertCard(
                    module: 'carestep',
                    gradient: AppColors.blueGradient,
                    niveau: switch (r.level) {
                      'HIGH' => 'important',
                      'MEDIUM' => 'attention',
                      _ => 'info',
                    },
                    titre: switch (r.level) {
                      'HIGH' => 'Let\'s plan your next visit soon',
                      'MEDIUM' => 'A check-in in the coming days',
                      _ => 'Your recovery plan is ready',
                    },
                    message: switch (r.level) {
                      'HIGH' => 'Hello, your doctor would like to see you again soon after you '
                          'go home, to check your treatment and how you feel. Your week-by-week '
                          'recovery plan is ready. Take care of yourself.',
                      'MEDIUM' => 'Hello, your doctor suggests a follow-up visit within a week '
                          'of going home. Your week-by-week recovery plan will help you day to '
                          'day. Take care of yourself.',
                      _ => 'Hello, your doctor has prepared your recovery plan. Keep following '
                          'your treatment and your usual appointments. Take care of yourself.',
                    },
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    label: 'Hear CareStep\'s explanation',
                    icon: Icons.volume_up_rounded,
                    gradient: AppColors.blueGradient,
                    onTap: r.narrative.isEmpty
                        ? null
                        : () => AvatarStageScreen.open(context,
                            avatar: AvatarProfile.carestep,
                            segments: r.narrative,
                            title: 'CareStep explains'),
                  ),
                ].animate(interval: 60.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(Color levelColor) {
    return SoftCard(
      gradient: AppColors.blueGradient,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          _Gauge(value: result.probability, percentage: result.percent),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: levelColor),
                const SizedBox(width: 6),
                Text(result.levelLabel.toUpperCase(),
                    style: TextStyle(
                        color: levelColor, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('Chance of coming back to hospital within 30 days',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          Text(result.advice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.35)),
        ],
      ),
    );
  }

  Widget _comparison(Color levelColor) {
    final avg = result.hospitalAveragePercent;
    // Scale both bars against the larger value (with headroom).
    final top = [result.percent, avg, 1].reduce((a, b) => a > b ? a : b) * 1.15;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard_rounded, color: AppColors.blue),
              SizedBox(width: 8),
              Text('Compared with other patients',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            ],
          ),
          const SizedBox(height: 14),
          _Bar(label: 'This patient', percent: result.percent, fraction: result.percent / top, color: levelColor),
          const SizedBox(height: 10),
          _Bar(label: 'Hospital average', percent: avg, fraction: avg / top, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            result.aboveAverage
                ? 'Higher than the usual patient leaving this hospital.'
                : 'At or below the usual patient leaving this hospital.',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
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
                const Text('30-day risk',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.percent, required this.fraction, required this.color});

  final String label;
  final int percent;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 12,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 40,
          child: Text('$percent%',
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
    required this.bullet,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> items;
  final IconData bullet;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, color: color, size: 38),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            ],
          ),
          const SizedBox(height: 12),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(bullet, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t, style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.week});

  final PlanWeek week;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              color: week.color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 34, decoration: BoxDecoration(color: week.color, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(week.title,
                          style: TextStyle(color: week.color, fontWeight: FontWeight.w800, fontSize: 15)),
                      if (week.subtitle.isNotEmpty)
                        Text(week.subtitle,
                            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Column(
              children: [
                for (final it in week.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        IconBadge(it.iconData, color: week.color, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(it.text,
                              style: const TextStyle(fontSize: 13.5, height: 1.35, fontWeight: FontWeight.w600)),
                        ),
                      ],
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

class _CareTeamCard extends StatelessWidget {
  const _CareTeamCard({required this.team});

  final CareTeamSummary team;

  static const _profileLabels = {
    'age_range': 'Age range',
    'gender': 'Gender',
    'hospital_stay': 'Hospital stay',
    'discharge_to': 'Going to',
    'medications': 'Medications',
    'insulin': 'Insulin',
    'primary_diagnosis': 'Main reason',
    'hba1c_tested': 'HbA1c tested',
  };

  @override
  Widget build(BuildContext context) {
    final profile = team.profile;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              IconBadge(Icons.groups_rounded, color: AppColors.indigo, size: 38),
              SizedBox(width: 10),
              Expanded(
                child: Text('Care-team summary',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
            ],
          ),
          if (team.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.blue.withValues(alpha: 0.12),
                  AppColors.indigo.withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(team.summary,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.4)),
            ),
          ],
          if (profile.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in profile.entries)
                  _InfoChip(label: _profileLabels[e.key] ?? e.key, value: '${e.value}'),
              ],
            ),
          ],
          _sub('Recommended for the care team', Icons.medical_services_rounded, AppColors.blue,
              team.recommendedActions),
          _sub('Questions to go over with the patient', Icons.help_outline_rounded, AppColors.violet,
              team.questionsForDoctor),
        ],
      ),
    );
  }

  Widget _sub(String title, IconData icon, Color color, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          for (final t in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 17),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 10.5, fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}
