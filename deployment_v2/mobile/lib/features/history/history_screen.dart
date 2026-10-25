import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../avatar/avatar_profile.dart';
import '../avatar/widgets/avatar_face.dart';
import '../home/home_screen.dart' show RiskRing;
import '../teemo/bloc/history_cubit.dart';
import '../teemo/data/teemo_models.dart';
import '../teemo/screens/assessment_screen.dart';
import '../teemo/screens/result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<HistoryCubit>().state;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final counts = {
      for (final l in ['LOW', 'MODERATE', 'HIGH']) l: items.where((e) => e.level == l).length,
    };
    return BlobBackground(
      opacity: 0.16,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text('History',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ),
                  if (items.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _confirmClear(context),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.coral),
                    ),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    _Count('Low', counts['LOW']!, AppColors.green),
                    const SizedBox(width: 10),
                    _Count('Moderate', counts['MODERATE']!, AppColors.amber),
                    const SizedBox(width: 10),
                    _Count('High', counts['HIGH']!, AppColors.red),
                  ],
                ).animate().fadeIn().slideY(begin: 0.1),
              ),
            ),
          if (items.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _Empty())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottom),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) => _HistoryTile(result: items[i])
                    .animate()
                    .fadeIn(delay: (40 * i).ms)
                    .slideX(begin: 0.06),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('All saved assessments on this device will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<HistoryCubit>().clear();
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.n, this.color);

  final String label;
  final int n;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            AnimatedCount(
                value: n.toDouble(),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.result});

  final TeemoResult result;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forLevel(result.level);
    final top = result.drivers.where((d) => d.up).map((d) => d.title).take(2).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(result.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => context.read<HistoryCubit>().remove(result.id),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.coral.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Icon(Icons.delete_rounded, color: AppColors.coral),
        ),
        child: SoftCard(
          radius: 26,
          padding: const EdgeInsets.all(14),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ResultScreen(result: result))),
          child: Row(
            children: [
              RiskRing(probability: result.probability, color: color, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.label ?? 'Patient',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(DateFormat('EEE d MMM · HH:mm').format(result.createdAt),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    if (top.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(top,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Pill(result.level, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AvatarFace(avatar: AvatarProfile.teemo, size: 110, halo: true),
          const SizedBox(height: 18),
          const Text('Nothing here yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Your assessments are saved on this device so you can reopen them any time.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Start an assessment',
            expanded: false,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AssessmentScreen())),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }
}
