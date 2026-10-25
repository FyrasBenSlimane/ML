import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../../avatar/widgets/avatar_video.dart';
import '../data/teemo_models.dart';
import '../data/teemo_repository.dart';
import 'assessment_screen.dart';

/// What Teemo says when you just want to meet her.
const teemoIntro = [
  SpeechSegment('greeting', "Hi! I'm Teemo, your readmission risk advisor."),
  SpeechSegment('info',
      'I estimate the chance that a patient with diabetes comes back to hospital within 30 days of discharge.'),
  SpeechSegment('calibration',
      'I learned from about eighty thousand real hospital stays, and I was tested on almost twenty thousand patients I had never seen.'),
  SpeechSegment('driver_up',
      'For every patient, I explain which factors raise or lower the risk, and I suggest a care plan.'),
  SpeechSegment('action',
      "When an analysis is ready, just tap on me and I'll walk you through it, out loud."),
  SpeechSegment('closing', 'Remember, I support your judgement. I never replace it.'),
];

void openTeemoIntro(BuildContext context) => AvatarStageScreen.open(
      context,
      avatar: AvatarProfile.teemo,
      segments: teemoIntro,
      title: 'Meet Teemo',
    );

class TeemoProfileScreen extends StatefulWidget {
  const TeemoProfileScreen({super.key});

  @override
  State<TeemoProfileScreen> createState() => _TeemoProfileScreenState();
}

class _TeemoProfileScreenState extends State<TeemoProfileScreen> {
  late Future<TeemoMeta> _meta = context.read<TeemoRepository>().meta();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return BlobBackground(
      opacity: 0.18,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(onIntro: () => openTeemoIntro(context))),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 120 + bottom),
            sliver: SliverList.list(
              children: [
                const SectionHeader('How I work', icon: Icons.route_rounded),
                const _HowItWorks(),
                const SizedBox(height: 10),
                const SectionHeader('My report card', icon: Icons.verified_rounded),
                FutureBuilder<TeemoMeta>(
                  future: _meta,
                  builder: (context, snap) {
                    if (snap.hasData) return _ReportCard(meta: snap.data!);
                    if (snap.hasError) {
                      return SoftCard(
                        onTap: () => setState(() => _meta = context.read<TeemoRepository>().meta(refresh: true)),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: AppColors.coral),
                            SizedBox(width: 12),
                            Expanded(child: Text('Server offline — tap to retry')),
                          ],
                        ),
                      );
                    }
                    return const SoftCard(
                      child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const SectionHeader('Honest limits', icon: Icons.info_rounded),
                const SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Limit(Icons.history_rounded, 'Trained on 130 US hospitals, 1999–2008 — practice has changed since.'),
                      _Limit(Icons.balance_rounded, 'Race and gender are in the data; they are shown, never spoken as "causes".'),
                      _Limit(Icons.psychology_rounded, 'A risk score, not a diagnosis. The care team decides.'),
                    ],
                  ),
                ),
              ].animate(interval: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
            ),
          ),
        ],
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
    const avatar = AvatarProfile.teemo;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulseDot(color: Color(0xFF86EFAC), size: 7),
              Text('TEEMO AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
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
                  child: Image.asset(avatar.portraitAsset, fit: BoxFit.cover, alignment: Alignment.topCenter),
                ),
              ),
            ),
          ).animate().scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack, duration: 600.ms),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Teemo', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
              SizedBox(width: 6),
              Icon(Icons.verified_rounded, color: Colors.white),
            ],
          ),
          const Text('Readmission risk advisor · by Ryma',
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
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderButton(
                  icon: Icons.add_chart_rounded,
                  label: 'Assess',
                  filled: true,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const AssessmentScreen())),
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
  const _HeaderButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: filled ? AppColors.tealDeep : Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: filled ? AppColors.tealDeep : Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    (Icons.edit_note_rounded, 'You describe the stay', 'Up to 38 fields — or load a real sample patient.', AppColors.blue),
    (Icons.account_tree_rounded, 'I score the risk', 'LightGBM, calibrated so 20% really means 20 in 100.', AppColors.violet),
    (Icons.insights_rounded, 'I explain why', 'SHAP shows what raises or lowers this patient\'s risk.', AppColors.coral),
    (Icons.record_voice_over_rounded, 'I talk you through it', 'Care plan, read aloud with subtitles.', AppColors.teal),
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
                          Text(_steps[i].$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(_steps[i].$3, style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.meta});

  final TeemoMeta meta;

  @override
  Widget build(BuildContext context) {
    final m = meta.metrics;
    final bands = [
      ('Low', meta.bands['LOW'] ?? 0, AppColors.green),
      ('Moderate', meta.bands['MODERATE'] ?? 0, AppColors.amber),
      ('High', meta.bands['HIGH'] ?? 0, AppColors.red),
    ];
    final maxRate = bands.map((b) => b.$2).reduce((a, b) => a > b ? a : b);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Metric('ROC-AUC', m.rocAuc, 3, AppColors.indigo),
              _Metric('PR-AUC', m.prAuc, 3, AppColors.violet),
              _Metric('Brier', m.brier, 3, AppColors.teal),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Actually readmitted, by risk group',
              style: TextStyle(fontWeight: FontWeight.w800)),
          Text('Test set · ${NumberFormat.decimalPattern().format(m.nTest)} unseen patients',
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bands.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${(bands[i].$2 * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontWeight: FontWeight.w800, color: bands[i].$3)),
                          const SizedBox(height: 6),
                          Container(
                            height: 100 * bands[i].$2 / maxRate,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [bands[i].$3.withValues(alpha: 0.6), bands[i].$3],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          )
                              .animate()
                              .scaleY(begin: 0, alignment: Alignment.bottomCenter, delay: (200 + i * 150).ms, duration: 800.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 6),
                          Text(bands[i].$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hospital average: ${(m.baselineRate * 100).toStringAsFixed(1)}%. '
            'PR-AUC is ${m.prLift.toStringAsFixed(1)}× the no-skill baseline.',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.decimals, this.color);

  final String label;
  final double value;
  final int decimals;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            AnimatedCount(
              value: value,
              decimals: decimals,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _Limit extends StatelessWidget {
  const _Limit(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
