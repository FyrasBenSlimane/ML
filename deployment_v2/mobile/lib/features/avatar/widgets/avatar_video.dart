import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../avatar_profile.dart';

/// Builds the in-flight widget for the avatar Hero: the round face morphs into
/// the rounded portrait card (and back on close).
Widget avatarHeroShuttle(
  BuildContext context,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
  AvatarProfile avatar,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (_, _) {
      final t = Curves.easeInOutCubic.transform(animation.value);
      return ClipRRect(
        borderRadius: BorderRadius.circular(math.max(32, 400 * (1 - t))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(avatar.portraitAsset, fit: BoxFit.cover, alignment: Alignment.topCenter),
            Opacity(
              opacity: (1 - t * 1.6).clamp(0, 1),
              child: Image.asset(avatar.faceAsset, fit: BoxFit.cover),
            ),
          ],
        ),
      );
    },
  );
}

/// The avatar's moving body. Plays the muted talking clip while [active] and
/// freezes on the current frame otherwise. Platforms without video support
/// (e.g. Windows desktop) get an animated portrait instead.
class AvatarVideo extends StatefulWidget {
  const AvatarVideo({super.key, required this.avatar, required this.active});

  final AvatarProfile avatar;
  final bool active;

  @override
  State<AvatarVideo> createState() => _AvatarVideoState();
}

class _AvatarVideoState extends State<AvatarVideo> with SingleTickerProviderStateMixin {
  VideoPlayerController? _video;
  bool _ready = false;
  late final AnimationController _sway =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final asset = widget.avatar.videoAsset;
    if (asset == null) return;
    final c = VideoPlayerController.asset(asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0); // the voice comes from TTS, never from the clip
      if (!mounted) {
        c.dispose();
        return;
      }
      setState(() {
        _video = c;
        _ready = true;
      });
      _sync();
    } catch (_) {
      c.dispose(); // unsupported platform -> animated portrait fallback
    }
  }

  @override
  void didUpdateWidget(AvatarVideo old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active) {
      _video?.play();
      if (!_ready) _sway.repeat(reverse: true);
    } else {
      _video?.pause();
      _sway.animateTo(0.5, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portrait = Image.asset(widget.avatar.portraitAsset,
        fit: BoxFit.cover, alignment: Alignment.topCenter);
    if (_ready && _video != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          portrait,
          FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _video!.value.size.width,
              height: _video!.value.size.height,
              child: VideoPlayer(_video!),
            ),
          ),
        ],
      );
    }
    // Fallback: a gentle talking sway so she still feels alive.
    return AnimatedBuilder(
      animation: _sway,
      builder: (_, child) {
        final v = (_sway.value - 0.5) * 2;
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..rotateZ(v * 0.018)
            ..scaleByDouble(1 + v.abs() * 0.015, 1 + v.abs() * 0.015, 1, 1),
          child: child,
        );
      },
      child: portrait,
    );
  }
}
