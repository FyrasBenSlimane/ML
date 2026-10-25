import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps any widget with a springy press-down scale and a light haptic.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.95});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 160),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}
