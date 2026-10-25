import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../avatar_profile.dart';
import 'avatar_video.dart';

/// Circular avatar that gently breathes, with an optional rotating gradient
/// ring (used while "thinking") and soft pulse halos (used to invite a tap).
class AvatarFace extends StatefulWidget {
  const AvatarFace({
    super.key,
    required this.avatar,
    this.size = 64,
    this.ring = false,
    this.halo = false,
    this.hero = false,
  });

  final AvatarProfile avatar;
  final double size;
  final bool ring;
  final bool halo;

  /// Fly into the avatar stage with a shared-element transition.
  final bool hero;

  @override
  State<AvatarFace> createState() => _AvatarFaceState();
}

class _AvatarFaceState extends State<AvatarFace> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final face = ClipOval(
      child: Image.asset(widget.avatar.faceAsset, width: s, height: s, fit: BoxFit.cover),
    );
    return SizedBox(
      width: s * (widget.halo ? 1.6 : 1.12),
      height: s * (widget.halo ? 1.6 : 1.12),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          final breathe = 1 + 0.025 * math.sin(t * 2 * math.pi * 2);
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.halo)
                for (var k = 0; k < 2; k++)
                  _halo(s, (t * 2 + k * 0.5) % 1, widget.avatar.accent),
              if (widget.ring)
                Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: Container(
                    width: s * 1.12,
                    height: s * 1.12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        ...widget.avatar.gradient.colors,
                        widget.avatar.gradient.colors.first,
                      ]),
                    ),
                  ),
                )
              else
                Container(
                  width: s * 1.08,
                  height: s * 1.08,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: widget.avatar.accent.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              Transform.scale(scale: breathe, child: child),
            ],
          );
        },
        child: widget.hero
            ? Hero(
                tag: widget.avatar.heroTag,
                flightShuttleBuilder: (ctx, anim, dir, from, to) =>
                    avatarHeroShuttle(ctx, anim, dir, from, to, widget.avatar),
                child: face,
              )
            : face,
      ),
    );
  }

  Widget _halo(double s, double p, Color color) => Container(
        width: s * (1 + 0.6 * p),
        height: s * (1 + 0.6 * p),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5 * (1 - p)), width: 2.5),
        ),
      );
}
