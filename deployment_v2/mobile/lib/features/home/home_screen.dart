import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/network/server_status_cubit.dart';
import '../../core/settings/settings_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pressable.dart';
import '../avatar/avatar_profile.dart';
import '../avatar/widgets/avatar_face.dart';
import '../modules/module_registry.dart';
import '../settings/settings_sheet.dart';
import '../teemo/bloc/history_cubit.dart';
import '../teemo/data/teemo_models.dart';
import '../teemo/data/teemo_repository.dart';
import '../teemo/screens/assessment_screen.dart';
import '../teemo/screens/result_screen.dart';
import '../teemo/screens/teemo_profile_screen.dart';
import 'widgets/sky_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab, required this.onOpenModule});

  /// Switch the shell to another tab (1 = Teemo, 2 = History, 3 = Team).
  final ValueChanged<int> onOpenTab;
  final ValueChanged<ModelModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final skyHeight = (size.height * 0.44).clamp(340.0, 440.0);
    final name = context.select((SettingsCubit c) => c.state.userName);
    // One box for sky + sheet: a viewport paints earlier slivers on top, which
    // would hide the sheet's rounded overlap behind the sky.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SkyHeader(
            height: skyHeight,
            userName: name,
            onSettings: () => showSettingsSheet(context),
            statusChip: const _StatusChip(),
          ),
          Transform.translate(
            offset: const Offset(0, -34),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              padding: EdgeInsets.fromLTRB(16, 22, 16, 110 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeemoCard(onProfile: () => onOpenTab(1)),
                  const SizedBox(height: 16),
                  const _StatsRow(),
                  const SizedBox(height: 6),
                  const SectionHeader('Quick actions', icon: Icons.grid_view_rounded),
                  _QuickActions(onOpenTab: onOpenTab),
                  const SizedBox(height: 6),
                  SectionHeader('Recent assessments',
                      icon: Icons.history_rounded, action: 'See all', onAction: () => onOpenTab(2)),
                  const _RecentStrip(),
                  const SizedBox(height: 6),
                  const SectionHeader('Care tips', icon: Icons.tips_and_updates_rounded),
                  const _TipsCarousel(),
                  const SizedBox(height: 6),
                  SectionHeader('Team companions',
                      icon: Icons.diversity_1_rounded, action: 'Open hub', onAction: () => onOpenTab(3)),
                  _TeamStrip(onOpenModule: onOpenModule),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('Decision support only · not a substitute for clinical judgement',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ),
                ]
                    .animate(interval: 70.ms)
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: 0.06, curve: Curves.easeOutCubic),
              ),
            ),
          ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ServerStatusCubit>().state;
    final (label, color) = switch (s.health) {
      ServerHealth.online => ('Online', const Color(0xFF4ADE80)),
      ServerHealth.offline => ('Offline', const Color(0xFFFB7185)),
      ServerHealth.checking => ('Connecting', const Color(0xFFFBBF24)),
    };
    return Pressable(
      onTap: () => context.read<ServerStatusCubit>().refresh(),
      child: GlassPanel(
        radius: 14,
        padding: const EdgeInsets.only(left: 2, right: 10, top: 2, bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PulseDot(color: color, size: 7),
            Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TeemoCard extends StatelessWidget {
  const _TeemoCard({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onProfile,
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -10,
            left: 120,
            bottom: 8,
            child: Opacity(opacity: 0.35, child: EcgLine(height: 36)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const AvatarFace(avatar: AvatarProfile.teemo, size: 78, halo: true, hero: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pill('AI NURSE', color: Colors.white.withValues(alpha: 0.25), filled: true,
                          icon: Icons.auto_awesome_rounded),
                      const SizedBox(height: 8),
                      const Text('Meet Teemo',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const Text('Predicts 30-day readmission, explains why and reads it aloud.',
                          style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _CardButton(
                            label: 'Assess',
                            icon: Icons.add_rounded,
                            filled: true,
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => const AssessmentScreen())),
                          ),
                          const SizedBox(width: 8),
                          _CardButton(
                            label: 'Hear her',
                            icon: Icons.volume_up_rounded,
                            onTap: () => openTeemoIntro(context),
                          ),
                        ],
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

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.icon, required this.onTap, this.filled = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: filled ? AppColors.tealDeep : Colors.white),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: filled ? AppColors.tealDeep : Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  const _StatsRow();

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  TeemoMeta? _meta;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await context.read<TeemoRepository>().meta();
      if (mounted) setState(() => _meta = m);
    } catch (_) {
      // Offline: the tiles show dashes until the server is back.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ServerStatusCubit, ServerStatus>(
      listenWhen: (a, b) => a.health != ServerHealth.online && b.health == ServerHealth.online,
      listener: (_, _) => _load(),
      child: Row(
        children: [
          _StatTile(
              icon: Icons.track_changes_rounded,
              color: AppColors.indigo,
              value: _meta?.metrics.rocAuc,
              decimals: 3,
              label: 'ROC-AUC'),
          const SizedBox(width: 10),
          _StatTile(
              icon: Icons.groups_rounded,
              color: AppColors.coral,
              value: _meta?.metrics.nTest.toDouble(),
              label: 'test patients',
              compact: true),
          const SizedBox(width: 10),
          _StatTile(
              icon: Icons.tune_rounded,
              color: AppColors.amber,
              value: _meta?.metrics.nFeatures.toDouble(),
              label: 'features'),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.decimals = 0,
    this.compact = false,
  });

  final IconData icon;
  final Color color;
  final double? value;
  final String label;
  final int decimals;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: color);
    return Expanded(
      child: SoftCard(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, color: color, size: 34),
            const SizedBox(height: 10),
            if (value == null)
              Text('—', style: style)
            else if (compact)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value!),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(NumberFormat.compact().format(v), style: style),
              )
            else
              AnimatedCount(value: value!, decimals: decimals, style: style),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  Future<void> _pickSample(BuildContext context) async {
    final repo = context.read<TeemoRepository>();
    TeemoMeta meta;
    try {
      meta = await repo.meta();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      return;
    }
    if (!context.mounted) return;
    final colors = [AppColors.green, AppColors.amber, AppColors.red];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Try a real patient', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Text('Anonymised encounters Teemo never saw during training',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            for (var i = 0; i < meta.samples.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  onTap: () => Navigator.pop(ctx, meta.samples[i].label),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      IconBadge(Icons.person_rounded, color: colors[i % 3]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(meta.samples[i].label,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => AssessmentScreen(sample: picked)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyCount = context.select((HistoryCubit c) => c.state.length);
    final tiles = [
      (Icons.assignment_add, 'New assessment', 'Full 5-step form', AppColors.teal,
          () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AssessmentScreen()))),
      (Icons.person_search_rounded, 'Sample patient', 'One tap demo', AppColors.violet,
          () => _pickSample(context)),
      (Icons.history_rounded, 'History', '$historyCount saved', AppColors.blue, () => onOpenTab(2)),
      (Icons.hub_rounded, 'Team hub', '${kModules.length} companions', AppColors.coral, () => onOpenTab(3)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero, // don't inherit the nav-bar safe-area padding
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        for (final (icon, title, sub, color, onTap) in tiles)
          SoftCard(
            onTap: onTap,
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(icon, color: color, size: 42),
                const Spacer(),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                Text(sub, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentStrip extends StatelessWidget {
  const _RecentStrip();

  @override
  Widget build(BuildContext context) {
    final items = context.watch<HistoryCubit>().state.take(8).toList();
    if (items.isEmpty) {
      return SoftCard(
        child: Row(
          children: [
            const AvatarFace(avatar: AvatarProfile.teemo, size: 52),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No assessments yet. Start one and I will keep it here for you.',
                  style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => RecentCard(result: items[i]),
      ),
    );
  }
}

class RecentCard extends StatelessWidget {
  const RecentCard({super.key, required this.result});

  final TeemoResult result;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forLevel(result.level);
    return SizedBox(
      width: 150,
      child: SoftCard(
        radius: 24,
        padding: const EdgeInsets.all(14),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ResultScreen(result: result))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RiskRing(probability: result.probability, color: color, size: 46),
                const Spacer(),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const Spacer(),
            Text(result.label ?? 'Patient',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(DateFormat('d MMM · HH:mm').format(result.createdAt),
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
            const SizedBox(height: 4),
            Text(result.levelLabel,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Small circular progress ring with the percentage inside.
class RiskRing extends StatelessWidget {
  const RiskRing({super.key, required this.probability, required this.color, this.size = 52});

  final double probability;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: probability),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: (v / 0.5).clamp(0, 1),
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
              ),
            ),
            Text('${(v * 100).round()}%',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * 0.26, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TipsCarousel extends StatefulWidget {
  const _TipsCarousel();

  @override
  State<_TipsCarousel> createState() => _TipsCarouselState();
}

class _TipsCarouselState extends State<_TipsCarousel> {
  final _ctrl = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _auto;

  static const _tips = [
    (Icons.king_bed_rounded, 'Prior stays matter most',
        'Patients with 2+ inpatient stays last year are readmitted far more often.', AppColors.coralGradient),
    (Icons.bloodtype_rounded, 'Test the HbA1c',
        'It was not measured in most stays — yet it guides the whole diabetes plan.', AppColors.violetGradient),
    (Icons.event_available_rounded, 'Follow-up within 7 days',
        'An early visit after discharge is one of the best-proven ways to prevent returns.', AppColors.brandGradient),
    (Icons.medication_rounded, 'Reconcile medications',
        'Each dose change is a chance for error at home. Review them before discharge.', AppColors.amberGradient),
  ];

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_ctrl.hasClients) return;
      _ctrl.animateToPage((_page + 1) % _tips.length,
          duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _ctrl,
            padEnds: false,
            itemCount: _tips.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (_, i) {
              final (icon, title, body, gradient) = _tips[i];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SoftCard(
                  gradient: gradient,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16.5)),
                            const SizedBox(height: 6),
                            Text(body,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 32),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: -3, end: 3, duration: 1800.ms, curve: Curves.easeInOut),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_tips.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _page ? AppColors.teal : AppColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TeamStrip extends StatelessWidget {
  const _TeamStrip({required this.onOpenModule});

  final ValueChanged<ModelModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: kModules.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final m = kModules[i];
          final live = m.status == ModuleStatus.live;
          return Pressable(
            onTap: () => onOpenModule(m),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(gradient: m.gradient, shape: BoxShape.circle),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: m.avatar != null
                          ? ClipOval(child: Image.asset(m.avatar!.faceAsset, fit: BoxFit.cover))
                          : Container(
                              decoration: BoxDecoration(
                                  color: m.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: Icon(m.icon, color: m.color),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(m.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  Text(live ? 'live' : 'soon',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: live ? AppColors.green : AppColors.muted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
