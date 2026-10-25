import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/pressable.dart';
import '../avatar_profile.dart';
import 'avatar_face.dart';

/// Floating avatar that bobs, pulses and says "tap me". Tapping it opens the
/// avatar stage (the face flies there through a Hero transition).
class AvatarBubble extends StatefulWidget {
  const AvatarBubble({
    super.key,
    required this.avatar,
    required this.onTap,
    this.message = "Tap me — I'll explain it!",
  });

  final AvatarProfile avatar;
  final VoidCallback onTap;
  final String message;

  @override
  State<AvatarBubble> createState() => _AvatarBubbleState();
}

class _AvatarBubbleState extends State<AvatarBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, 5 * math.sin(_bob.value * 2 * math.pi)),
          child: child,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: AppColors.softShadow(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 18, color: widget.avatar.accent),
                  const SizedBox(width: 6),
                  Text(widget.message,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(delay: 1800.ms, duration: 1400.ms, color: widget.avatar.accent.withValues(alpha: 0.25)),
            const SizedBox(width: 2),
            AvatarFace(avatar: widget.avatar, size: 66, halo: true, hero: true),
          ],
        ),
      ),
    );
  }
}
