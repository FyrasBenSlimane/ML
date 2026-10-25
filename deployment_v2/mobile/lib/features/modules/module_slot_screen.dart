import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/server_status_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import 'module_registry.dart';

/// Placeholder shown for a teammate's reserved slot: what goes here and the
/// exact steps to plug the model in.
class ModuleSlotScreen extends StatelessWidget {
  const ModuleSlotScreen({super.key, required this.module});

  final ModelModule module;

  @override
  Widget build(BuildContext context) {
    final m = module;
    final apiLive = context.select((ServerStatusCubit c) => c.state.hasModule(m.id));
    return Scaffold(
      body: BlobBackground(
        colors: [...m.gradient.colors, AppColors.sky],
        opacity: 0.2,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(m.name),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.list(
                children: [
                  _hero(m, apiLive),
                  const SizedBox(height: 18),
                  const SectionHeader('Plug your model in', icon: Icons.extension_rounded),
                  _Step(
                    n: 1,
                    color: m.color,
                    title: 'Backend — add your module',
                    body: 'Copy backend/app/modules/_template to backend/app/modules/${m.id}, '
                        'put your joblib files in backend/artifacts/${m.id}/ and set MODULE.id = "${m.id}". '
                        'The server mounts it automatically at /api/v1/${m.id}.',
                    code: 'cp -r app/modules/_template app/modules/${m.id}',
                  ),
                  _Step(
                    n: 2,
                    color: m.color,
                    title: 'App — build your screens',
                    body: 'Copy lib/features/modules/_template to lib/features/${m.id}. '
                        'Call your endpoint with context.read<ApiClient>() — the server address '
                        'and error handling are already shared.',
                    code: "api.postJson('/api/v1/${m.id}/predict', patient)",
                  ),
                  _Step(
                    n: 3,
                    color: m.color,
                    title: 'Register it',
                    body: "In lib/features/modules/module_registry.dart set this module's "
                        '`entry` to your screen and `status: ModuleStatus.live`. '
                        'Return a `narrative` list from your API to get a talking avatar with '
                        'voice and subtitles via AvatarStageScreen.open(...).',
                    code: 'entry: (_) => const ${m.name}Screen(),',
                  ),
                ].animate(interval: 90.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(ModelModule m, bool apiLive) {
    return SoftCard(
      gradient: m.gradient,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            ),
            child: Icon(m.icon, color: Colors.white, size: 46),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1600.ms),
          const SizedBox(height: 14),
          Text(m.name,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          Text('by ${m.owner} · ${m.tagline}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              Pill('SLOT RESERVED', color: Colors.white.withValues(alpha: 0.28), filled: true,
                  icon: Icons.lock_clock_rounded),
              if (apiLive)
                Pill('API LIVE', color: Colors.white.withValues(alpha: 0.28), filled: true,
                    icon: Icons.cloud_done_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.color,
    required this.title,
    required this.body,
    required this.code,
  });

  final int n;
  final Color color;
  final String title;
  final String body;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(color: AppColors.inkSoft, height: 1.4, fontSize: 13)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(code,
                                style: const TextStyle(
                                    color: Color(0xFF7DD3FC), fontFamily: 'monospace', fontSize: 12)),
                          ),
                          const Icon(Icons.copy_rounded, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
