import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/settings/settings_cubit.dart';
import '../../shared/widgets/ambient.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pressable.dart';
import 'avatar_profile.dart';
import 'voice/avatar_voice_cubit.dart';
import 'widgets/avatar_video.dart';
import 'widgets/voice_widgets.dart';

/// Full-screen "the avatar explains it" experience: the avatar grows from its
/// bubble, moves and gestures while a female voice reads [segments] aloud with
/// word-by-word subtitles. Reusable by every team module.
class AvatarStageScreen extends StatelessWidget {
  const AvatarStageScreen({
    super.key,
    required this.avatar,
    required this.segments,
    this.title,
  });

  final AvatarProfile avatar;
  final List<SpeechSegment> segments;
  final String? title;

  static Future<void> open(
    BuildContext context, {
    required AvatarProfile avatar,
    required List<SpeechSegment> segments,
    String? title,
  }) {
    return Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 750),
      reverseTransitionDuration: const Duration(milliseconds: 550),
      pageBuilder: (_, _, _) =>
          AvatarStageScreen(avatar: avatar, segments: segments, title: title),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AvatarVoiceCubit(
        segments: segments,
        api: ctx.read<ApiClient>(),
        preferred: ctx.read<SettingsCubit>().state.voiceEngine,
      ),
      child: _StageView(avatar: avatar, title: title),
    );
  }
}

class _StageView extends StatefulWidget {
  const _StageView({required this.avatar, this.title});

  final AvatarProfile avatar;
  final String? title;

  @override
  State<_StageView> createState() => _StageViewState();
}

class _StageViewState extends State<_StageView> {
  @override
  void initState() {
    super.initState();
    // Let the hero flight land before she starts talking.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.read<AvatarVoiceCubit>().start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.avatar;
    final subtitles = context.select((SettingsCubit c) => c.state.subtitles);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1B33),
        body: BlocListener<AvatarVoiceCubit, AvatarVoiceState>(
          listenWhen: (a, b) => b.notice != null && a.notice != b.notice,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.notice!)));
            context.read<AvatarVoiceCubit>().clearNotice();
          },
          child: BlobBackground(
            baseColor: const Color(0xFF0B1B33),
            colors: [...avatar.gradient.colors, const Color(0xFF8B5CF6)],
            opacity: 0.38,
            child: SafeArea(
              child: BlocBuilder<AvatarVoiceCubit, AvatarVoiceState>(
                builder: (context, s) {
                  return Column(
                    children: [
                      _TopBar(avatar: avatar, state: s, title: widget.title),
                      Expanded(child: _VideoCard(avatar: avatar, active: s.isAnimating)),
                      const SizedBox(height: 8),
                      VoiceWave(active: s.status == VoiceStatus.speaking),
                      const SizedBox(height: 8),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: subtitles ? _Subtitles(state: s) : const SizedBox(width: double.infinity),
                      ),
                      const SizedBox(height: 10),
                      _Progress(state: s, color: avatar.accent),
                      const SizedBox(height: 14),
                      _Controls(state: s, avatar: avatar),
                      const SizedBox(height: 18),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.avatar, required this.state, this.title});

  final AvatarProfile avatar;
  final AvatarVoiceState state;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>();
    final (label, color) = switch (state.status) {
      VoiceStatus.speaking => ('Speaking', const Color(0xFF34D399)),
      VoiceStatus.loading => ('Getting ready…', const Color(0xFFFBBF24)),
      VoiceStatus.paused => ('Paused', Colors.white70),
      VoiceStatus.finished => ('Finished', const Color(0xFF7DD3FC)),
      VoiceStatus.error => ('Voice error', const Color(0xFFFB7185)),
      VoiceStatus.idle => ('Ready', Colors.white70),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
          Expanded(
            child: Column(
              children: [
                Text(title ?? avatar.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PulseDot(color: color, size: 7),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          _RoundIcon(
            icon: settings.state.subtitles ? Icons.closed_caption_rounded : Icons.closed_caption_off_rounded,
            onTap: () => settings.setSubtitles(!settings.state.subtitles),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.avatar, required this.active});

  final AvatarProfile avatar;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.92,
          child: AnimatedScale(
            scale: active ? 1.0 : 0.97,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: avatar.accent.withValues(alpha: active ? 0.65 : 0.3),
                    blurRadius: active ? 48 : 24,
                    spreadRadius: active ? 2 : 0,
                  ),
                ],
              ),
              child: Hero(
                tag: avatar.heroTag,
                flightShuttleBuilder: (ctx, anim, dir, from, to) =>
                    avatarHeroShuttle(ctx, anim, dir, from, to, avatar),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AvatarVideo(avatar: avatar, active: active),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: GlassPanel(
                          radius: 16,
                          opacity: 0.22,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text('${avatar.name} · ${avatar.role}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Subtitles extends StatelessWidget {
  const _Subtitles({required this.state});

  final AvatarVoiceState state;

  @override
  Widget build(BuildContext context) {
    if (state.segments.isEmpty) return const SizedBox.shrink();
    final seg = state.current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GlassPanel(
        opacity: 0.12,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(state.index),
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(seg.icon, color: Colors.white70, size: 15),
                    const SizedBox(width: 6),
                    Text('${state.index + 1} / ${state.segments.length}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                KaraokeText(text: seg.text, charEnd: state.charEnd),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state, required this.color});

  final AvatarVoiceState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(state.segments.length, (i) {
        final on = i == state.index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i <= state.index ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.avatar});

  final AvatarVoiceState state;
  final AvatarProfile avatar;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AvatarVoiceCubit>();
    if (state.status == VoiceStatus.finished) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          children: [
            Expanded(
              child: _PillButton(
                icon: Icons.replay_rounded,
                label: 'Replay',
                onTap: cubit.restart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PillButton(
                icon: Icons.check_rounded,
                label: 'Done',
                filled: true,
                color: avatar.accent,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.3),
      );
    }
    final playing = state.status == VoiceStatus.speaking || state.status == VoiceStatus.loading;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundIcon(icon: Icons.skip_previous_rounded, size: 54, onTap: cubit.previous),
        const SizedBox(width: 22),
        Pressable(
          onTap: cubit.togglePlay,
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: avatar.gradient,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: avatar.accent.withValues(alpha: 0.6), blurRadius: 26)],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                key: ValueKey(playing),
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(width: 22),
        _RoundIcon(icon: Icons.skip_next_rounded, size: 54, onTap: cubit.next),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.size = 46});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: GlassPanel(
        radius: size / 2,
        opacity: 0.16,
        padding: EdgeInsets.zero,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: filled ? color : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
