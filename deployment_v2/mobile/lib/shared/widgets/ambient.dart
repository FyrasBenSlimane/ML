import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Slowly drifting, blurred colour blobs — the "alive" backdrop used behind
/// forms and the avatar stage.
class BlobBackground extends StatefulWidget {
  const BlobBackground({
    super.key,
    this.colors = const [AppColors.teal, AppColors.sky, AppColors.violet, AppColors.pink],
    this.baseColor = AppColors.bg,
    this.opacity = 0.22,
    this.child,
  });

  final List<Color> colors;
  final Color baseColor;
  final double opacity;
  final Widget? child;

  @override
  State<BlobBackground> createState() => _BlobBackgroundState();
}

class _BlobBackgroundState extends State<BlobBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: widget.baseColor)),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(
                painter: _BlobPainter(_c.value, widget.colors, widget.opacity),
              ),
            ),
          ),
        ),
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.t, this.colors, this.opacity);

  final double t;
  final List<Color> colors;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < colors.length; i++) {
      final phase = t * 2 * math.pi + i * 1.7;
      final cx = size.width * (0.2 + 0.6 * ((i * 0.37) % 1)) + math.cos(phase) * size.width * 0.12;
      final cy = size.height * (0.15 + 0.7 * ((i * 0.61) % 1)) + math.sin(phase * 0.8) * size.height * 0.08;
      final r = size.shortestSide * (0.35 + 0.08 * math.sin(phase * 1.3));
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          colors[i].withValues(alpha: opacity),
          colors[i].withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}

/// Glowing dot that breathes — "online", "speaking" indicators.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s + s * 1.4 * _c.value,
              height: s + s * 1.4 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Endless heartbeat (ECG) trace.
class EcgLine extends StatefulWidget {
  const EcgLine({super.key, this.color = Colors.white, this.height = 40, this.strokeWidth = 2.5});

  final Color color;
  final double height;
  final double strokeWidth;

  @override
  State<EcgLine> createState() => _EcgLineState();
}

class _EcgLineState extends State<EcgLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _EcgPainter(_c.value, widget.color, widget.strokeWidth),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter(this.t, this.color, this.stroke);

  final double t;
  final Color color;
  final double stroke;

  // One beat as (x, y) in unit space; y=0.5 is the baseline.
  static const _beat = [
    Offset(0, .5), Offset(.30, .5), Offset(.36, .42), Offset(.40, .5), Offset(.46, .5),
    Offset(.49, .62), Offset(.53, .05), Offset(.57, .92), Offset(.60, .5), Offset(.70, .5),
    Offset(.76, .36), Offset(.82, .5), Offset(1, .5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final beatW = size.height * 3.2;
    final path = Path();
    final shift = t * beatW;
    var started = false;
    for (var x0 = -beatW; x0 < size.width + beatW; x0 += beatW) {
      for (final p in _beat) {
        final pt = Offset(x0 + p.dx * beatW - shift + beatW, p.dy * size.height);
        if (!started) {
          path.moveTo(pt.dx, pt.dy);
          started = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: [
        color.withValues(alpha: 0),
        color,
        color,
        color.withValues(alpha: 0),
      ], stops: const [0, .25, .75, 1])
          .createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.t != t;
}

/// Number that counts up when it first appears or changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.decimals = 0,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1400),
  });

  final double value;
  final int decimals;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}
