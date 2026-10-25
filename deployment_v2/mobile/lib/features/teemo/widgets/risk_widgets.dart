import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import '../data/teemo_models.dart';

/// Semicircular gauge that sweeps up to the calibrated risk.
/// Scale is 0–50 %: almost every patient falls inside it, and the 8 % / 20 %
/// band thresholds stay readable instead of being squeezed at the left.
class RiskGauge extends StatelessWidget {
  const RiskGauge({
    super.key,
    required this.probability,
    required this.level,
    required this.thresholds,
    required this.baseline,
    this.size = 250,
  });

  final double probability;
  final String level;
  final Map<String, dynamic> thresholds;
  final double baseline;
  final double size;

  static const maxScale = 0.5;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: probability),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutCubic,
      builder: (_, p, _) => SizedBox(
        width: size,
        height: size * 0.62,
        child: CustomPaint(
          painter: _GaugePainter(
            value: (p / maxScale).clamp(0, 1),
            marks: [
              ((thresholds['moderate'] as num) / maxScale).toDouble(),
              ((thresholds['high'] as num) / maxScale).toDouble(),
            ],
            baseline: baseline / maxScale,
          ),
          child: Align(
            alignment: const Alignment(0, 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(p * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        letterSpacing: -1)),
                const SizedBox(height: 4),
                const Text('30-day readmission risk',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.marks, required this.baseline});

  final double value;
  final List<double> marks;
  final double baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.075;
    final center = Offset(size.width / 2, size.height * 0.95);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi;
    const sweep = math.pi;

    canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.22));

    canvas.drawArc(
        rect,
        start,
        sweep * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..shader = const SweepGradient(
            startAngle: math.pi,
            endAngle: 2 * math.pi,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF7D6), Color(0xFFFFFFFF)],
          ).createShader(rect));

    // threshold ticks
    for (final m in marks) {
      final a = start + sweep * m;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (radius - stroke * 0.9);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (radius + stroke * 0.9);
      canvas.drawLine(
          p1,
          p2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }

    // hospital-average dot
    final ab = start + sweep * baseline;
    canvas.drawCircle(center + Offset(math.cos(ab), math.sin(ab)) * (radius + stroke * 1.25), 4,
        Paint()..color = Colors.white);

    // knob at the current value
    final av = start + sweep * value;
    final knob = center + Offset(math.cos(av), math.sin(av)) * radius;
    canvas.drawCircle(knob, stroke * 0.75, Paint()..color = Colors.white);
    canvas.drawCircle(
        knob,
        stroke * 0.75,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

/// 100 people, N highlighted — the clearest way to communicate a probability.
class IconArray extends StatelessWidget {
  const IconArray({super.key, required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cell = c.maxWidth / 10;
      return Wrap(
        children: List.generate(100, (i) {
          final on = i < count;
          return SizedBox(
            width: cell,
            height: cell * 1.05,
            child: Icon(Icons.person_rounded,
                    size: cell * 0.95, color: on ? color : AppColors.line)
                .animate()
                .fadeIn(delay: (i * 12).ms, duration: 220.ms)
                .scale(begin: const Offset(0.4, 0.4), delay: (i * 12).ms),
          );
        }),
      );
    });
  }
}

/// Where the patient sits among everyone the model was tested on.
class PercentileBar extends StatelessWidget {
  const PercentileBar({super.key, required this.percentile, required this.color});

  final int percentile;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percentile / 100),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => SizedBox(
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 18,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                        colors: [AppColors.green, AppColors.amber, AppColors.red]),
                  ),
                ),
              ),
              Positioned(
                left: (c.maxWidth - 26) * v,
                top: 10,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 5),
                    boxShadow: AppColors.glow(color, strength: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Diverging bars: what pushes the risk up (coral) or down (teal).
class DriverList extends StatefulWidget {
  const DriverList({super.key, required this.drivers});

  final List<Driver> drivers;

  @override
  State<DriverList> createState() => _DriverListState();
}

class _DriverListState extends State<DriverList> {
  int? _open;

  @override
  Widget build(BuildContext context) {
    final maxShare = widget.drivers.map((d) => d.share).fold<double>(0.0001, math.max);
    return Column(
      children: [
        for (var i = 0; i < widget.drivers.length; i++)
          _DriverRow(
            driver: widget.drivers[i],
            fraction: widget.drivers[i].share / maxShare,
            open: _open == i,
            delay: i * 90,
            onTap: () => setState(() => _open = _open == i ? null : i),
          ),
      ],
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.driver,
    required this.fraction,
    required this.open,
    required this.delay,
    required this.onTap,
  });

  final Driver driver;
  final double fraction;
  final bool open;
  final int delay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = driver.up ? AppColors.coral : AppColors.teal;
    return Pressable(
      scale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: open ? color.withValues(alpha: 0.07) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: open ? color.withValues(alpha: 0.35) : Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(driver.up ? Icons.north_east_rounded : Icons.south_east_rounded,
                    color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(driver.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                if (!driver.modifiable)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Pill('fixed', color: AppColors.muted),
                  ),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.expand_more_rounded, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(driver.value, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, c) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: c.maxWidth * fraction,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color.withValues(alpha: 0.6), color]),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                      .animate()
                      .scaleX(
                          begin: 0,
                          alignment: Alignment.centerLeft,
                          delay: delay.ms,
                          duration: 900.ms,
                          curve: Curves.easeOutCubic),
                ],
              );
            }),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${driver.explanation}\n'
                  '${driver.up ? 'Raises' : 'Lowers'} the risk · ${(driver.share * 100).round()}% of the total explanation',
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.inkSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Care plan with tick-off items.
class ActionChecklist extends StatefulWidget {
  const ActionChecklist({super.key, required this.actions});

  final List<CareAction> actions;

  @override
  State<ActionChecklist> createState() => _ActionChecklistState();
}

class _ActionChecklistState extends State<ActionChecklist> {
  final Set<int> _done = {};

  static IconData _icon(String key) => switch (key) {
        'call' => Icons.phone_in_talk_rounded,
        'calendar' => Icons.event_rounded,
        'team' => Icons.groups_rounded,
        'pill' => Icons.medication_rounded,
        'syringe' => Icons.vaccines_rounded,
        'lab' => Icons.science_rounded,
        'home' => Icons.home_rounded,
        'alert' => Icons.warning_amber_rounded,
        _ => Icons.check_circle_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.actions.length; i++)
          _row(i, widget.actions[i]).animate().fadeIn(delay: (i * 90).ms).slideX(begin: 0.08),
      ],
    );
  }

  Widget _row(int i, CareAction a) {
    final color = switch (a.priority) {
      'high' => AppColors.red,
      'medium' => AppColors.amber,
      _ => AppColors.teal,
    };
    final done = _done.contains(i);
    return Pressable(
      scale: 0.98,
      onTap: () => setState(() => done ? _done.remove(i) : _done.add(i)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? AppColors.green.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(_icon(a.icon), color: color, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? AppColors.muted : AppColors.ink,
                      )),
                  const SizedBox(height: 3),
                  Text(a.detail,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, an) => ScaleTransition(scale: an, child: c),
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(done),
                color: done ? AppColors.green : AppColors.line,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
