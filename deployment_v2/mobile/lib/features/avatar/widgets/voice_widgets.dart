import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Equalizer bars that dance while the avatar speaks and settle when silent.
class VoiceWave extends StatefulWidget {
  const VoiceWave({super.key, required this.active, this.color = Colors.white, this.bars = 28});

  final bool active;
  final Color color;
  final int bars;

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave> with TickerProviderStateMixin {
  late final AnimationController _t =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _level = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(VoiceWave old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) {
      widget.active ? _level.forward() : _level.reverse();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: AnimatedBuilder(
        animation: Listenable.merge([_t, _level]),
        builder: (_, _) {
          final time = _t.value * 2 * math.pi * 6;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.bars, (i) {
              final centre = 1 - ((i - widget.bars / 2).abs() / (widget.bars / 2));
              final wobble = (math.sin(time * 1.7 + i * 0.9) +
                      math.sin(time * 2.9 + i * 0.37) +
                      math.sin(time * 0.7 + i * 1.3)) /
                  3;
              final h = 4 + _level.value * (8 + 30 * centre) * (0.55 + 0.45 * wobble.abs());
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.55 + 0.45 * centre),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Karaoke subtitles: words already spoken are bright, the rest dimmed.
class KaraokeText extends StatelessWidget {
  const KaraokeText({super.key, required this.text, required this.charEnd, this.style});

  final String text;
  final int charEnd;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(fontSize: 19, height: 1.45, fontWeight: FontWeight.w700, color: Colors.white);
    final spans = <TextSpan>[];
    final words = RegExp(r'\S+\s*').allMatches(text);
    for (final m in words) {
      final spoken = m.start < charEnd;
      spans.add(TextSpan(
        text: m.group(0),
        style: base.copyWith(
          color: (base.color ?? Colors.white).withValues(alpha: spoken ? 1 : 0.45),
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.center);
  }
}
