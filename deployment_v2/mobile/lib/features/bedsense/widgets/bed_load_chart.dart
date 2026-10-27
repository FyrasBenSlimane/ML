import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/bedsense_models.dart';
import 'bs_common.dart';

/// Daily beds needed (bars coloured by status) with the "safe plan" cap on top
/// of each bar and the beds available as a dashed line. Tap a bar to select it.
class BedLoadChart extends StatelessWidget {
  const BedLoadChart({super.key, required this.days, this.selected, this.onSelect, this.height = 220});

  final List<BsDay> days;
  final int? selected;
  final ValueChanged<int>? onSelect;
  final double height;

  static const _leftPad = 34.0;
  static const _bottomPad = 26.0;
  static const _topPad = 18.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, c) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onSelect == null || days.isEmpty
                ? null
                : (d) {
                    final plotW = c.maxWidth - _leftPad;
                    final i = ((d.localPosition.dx - _leftPad) / (plotW / days.length)).floor();
                    if (i >= 0 && i < days.length) onSelect!(i);
                  },
            child: SizedBox(
              width: c.maxWidth,
              height: height,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, t, _) => CustomPaint(
                  painter: _BedLoadPainter(days: days, progress: t, selected: selected),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _Legend(color: AppColors.green, label: 'Enough beds'),
            _Legend(color: AppColors.amber, label: 'Tight'),
            _Legend(color: AppColors.red, label: 'Beds missing'),
            _Legend(color: AppColors.muted, label: 'Safe plan', faded: true),
            _Legend(color: AppColors.ink, label: 'Beds available', line: true),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.line = false, this.faded = false});

  final Color color;
  final String label;
  final bool line;
  final bool faded;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: line ? 16 : 10,
            height: line ? 3 : 10,
            decoration: BoxDecoration(
              color: faded ? color.withValues(alpha: 0.35) : color,
              borderRadius: BorderRadius.circular(line ? 2 : 3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5)),
        ],
      );
}

class _BedLoadPainter extends CustomPainter {
  _BedLoadPainter({required this.days, required this.progress, this.selected});

  final List<BsDay> days;
  final double progress;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    const left = BedLoadChart._leftPad;
    const bottom = BedLoadChart._bottomPad;
    const top = BedLoadChart._topPad;
    final plotW = size.width - left;
    final plotH = size.height - bottom - top;
    final capacity = days.map((d) => d.capacity).reduce(math.max);
    final peak = days.map((d) => math.max(d.safe, d.needed)).reduce(math.max);
    final yMax = _niceMax(math.max(capacity, peak) * 1.08);
    double y(double v) => top + plotH - (v / yMax) * plotH;

    // Grid + y labels.
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var k = 0; k <= 4; k++) {
      final v = yMax * k / 4;
      final gy = y(v);
      canvas.drawLine(Offset(left, gy), Offset(size.width, gy), grid);
      _text(canvas, v.round().toString(), Offset(left - 6, gy), align: _Align.right);
    }

    // Bars.
    final slot = plotW / days.length;
    final barW = math.max(2.0, slot * 0.62);
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final cx = left + slot * (i + 0.5);
      final color = statusColor(d.status);
      final isSel = selected == i;
      if (isSel) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(cx - slot / 2, top - 4, cx + slot / 2, top + plotH), const Radius.circular(6)),
          Paint()..color = bsGreen.withValues(alpha: 0.10),
        );
      }
      final needTop = y(d.needed * progress);
      final safeTop = y(math.max(d.safe, d.needed) * progress);
      // Safe-plan cap (lighter) above the bar.
      if (safeTop < needTop) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(Rect.fromLTRB(cx - barW / 2, safeTop, cx + barW / 2, needTop),
              topLeft: const Radius.circular(3), topRight: const Radius.circular(3)),
          Paint()..color = AppColors.muted.withValues(alpha: 0.35),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTRB(cx - barW / 2, needTop, cx + barW / 2, top + plotH),
            topLeft: Radius.circular(safeTop < needTop ? 0 : 3),
            topRight: Radius.circular(safeTop < needTop ? 0 : 3)),
        Paint()..color = color.withValues(alpha: isSel || selected == null ? 0.9 : 0.55),
      );
    }

    // Capacity: dashed line, following the capacity day by day.
    final cap = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2;
    for (var i = 0; i < days.length; i++) {
      final cy = y(days[i].capacity);
      final x0 = left + slot * i;
      final x1 = x0 + slot;
      for (var x = x0; x < x1; x += 8) {
        canvas.drawLine(Offset(x, cy), Offset(math.min(x + 4, x1), cy), cap);
      }
    }
    _text(canvas, '${capacity.round()} beds', Offset(size.width, y(capacity) - 3),
        align: _Align.right, above: true, bold: true);

    // X labels: first day, then roughly every week.
    final step = days.length <= 8 ? 1 : 7;
    for (var i = 0; i < days.length; i += step) {
      final d = days[i].date;
      final label = days.length <= 8 ? '${_wd(d)}\n${d.day}' : dayMonth(d);
      _text(canvas, label, Offset(left + slot * (i + 0.5), top + plotH + 5), align: _Align.center);
    }
  }

  static String _wd(DateTime d) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];

  static double _niceMax(double v) {
    if (v <= 0) return 10;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * mag >= v) return m * mag;
    }
    return 10 * mag;
  }

  void _text(Canvas canvas, String s, Offset at,
      {_Align align = _Align.left, bool above = false, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: bold ? AppColors.ink : AppColors.muted,
          fontSize: 10,
          height: 1.15,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _Align.left => at.dx,
      _Align.center => at.dx - tp.width / 2,
      _Align.right => at.dx - tp.width,
    };
    final dy = above ? at.dy - tp.height : (align == _Align.right && !bold ? at.dy - tp.height / 2 : at.dy);
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_BedLoadPainter old) =>
      old.days != days || old.progress != progress || old.selected != selected;
}

enum _Align { left, center, right }
