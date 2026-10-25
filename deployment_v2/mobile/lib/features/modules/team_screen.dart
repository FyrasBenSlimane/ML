import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/server_status_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import 'module_registry.dart';

/// The team hub: one card per companion. Live modules open; reserved slots
/// open their integration guide.
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key, required this.onOpenModule});

  final ValueChanged<ModelModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final status = context.watch<ServerStatusCubit>().state;
    final live = kModules.where((m) => m.status == ModuleStatus.live).length;
    return BlobBackground(
      colors: const [AppColors.violet, AppColors.pink, AppColors.sky, AppColors.teal],
      opacity: 0.16,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.fromLTRB(16, top + 12, 16, 8),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: AppColors.violetGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppColors.glow(AppColors.violet, strength: 0.3),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Team ReadmitGuard',
                            style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text('Six AI companions, one platform.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Pill('$live live · ${kModules.length - live} slots open',
                            color: Colors.white.withValues(alpha: 0.25), filled: true, icon: Icons.hub_rounded),
                      ],
                    ),
                  ),
                  const Icon(Icons.diversity_3_rounded, color: Colors.white, size: 64)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .rotate(begin: -0.03, end: 0.03, duration: 2.seconds),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottom),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: kModules.length,
              itemBuilder: (context, i) => _ModuleCard(
                module: kModules[i],
                apiLive: status.hasModule(kModules[i].id),
                onTap: () => onOpenModule(kModules[i]),
              ).animate().fadeIn(delay: (80 * i).ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.apiLive, required this.onTap});

  final ModelModule module;
  final bool apiLive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = module;
    final live = m.status == ModuleStatus.live;
    return SoftCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: m.gradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: m.avatar != null
                        ? Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipOval(child: Image.asset(m.avatar!.faceAsset, fit: BoxFit.cover)),
                          )
                        : Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.22),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7), width: 2, strokeAlign: 1),
                            ),
                            child: Icon(m.icon, color: Colors.white, size: 36),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Pill(
                      live ? 'LIVE' : (apiLive ? 'API READY' : 'SLOT'),
                      color: live ? AppColors.green : Colors.white.withValues(alpha: 0.3),
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('by ${m.owner}',
                    style: TextStyle(color: m.color, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(m.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
