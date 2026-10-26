import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import 'sky_scene.dart';

/// Live clock over a sky that follows the real time of day.
/// Tap the sun/moon chip to preview dawn, day, dusk and night.
class SkyHeader extends StatefulWidget {
  const SkyHeader({
    super.key,
    required this.height,
    required this.userName,
    required this.onSettings,
    required this.statusChip,
  });

  final double height;
  final String userName;
  final VoidCallback onSettings;
  final Widget statusChip;

  @override
  State<SkyHeader> createState() => _SkyHeaderState();
}

class _SkyHeaderState extends State<SkyHeader> with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  late final AnimationController _shift =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  Animation<double>? _hourAnim;
  Timer? _clock;
  DateTime _now = DateTime.now();

  /// null = live time; otherwise a preview hour.
  int _preview = 0;
  static const _previews = <(String, double?, IconData)>[
    ('Live', null, Icons.schedule_rounded),
    ('Dawn', 6.6, Icons.wb_twilight_rounded),
    ('Day', 12.0, Icons.wb_sunny_rounded),
    ('Dusk', 18.6, Icons.wb_twilight_rounded),
    ('Night', 23.0, Icons.nightlight_round),
  ];

  double get _liveHour => _now.hour + _now.minute / 60 + _now.second / 3600;

  double get _hour => _hourAnim?.value ?? _previews[_preview].$2 ?? _liveHour;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _clock?.cancel();
    _loop.dispose();
    _shift.dispose();
    super.dispose();
  }

  void _cyclePreview() {
    final from = _hour;
    _preview = (_preview + 1) % _previews.length;
    final to = _previews[_preview].$2 ?? _liveHour;
    _hourAnim = Tween(begin: from, end: to < from - 12 ? to + 24 : to)
        .animate(CurvedAnimation(parent: _shift, curve: Curves.easeInOutCubic))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) setState(() => _hourAnim = null);
      });
    _shift.forward(from: 0);
  }

  String get _greeting {
    final h = _hour % 24;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
  }

  String get _shiftLine {
    final n = nightness(_hour);
    return n > 0.5 ? 'Night shift · Teemo never sleeps' : 'Day shift · Teemo is ready to help';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final shown = _previews[_preview].$2 == null
        ? _now
        : DateTime(_now.year, _now.month, _now.day, (_hour % 24).floor(), ((_hour % 1) * 60).floor());
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_loop, _shift]),
                builder: (_, _) => CustomPaint(painter: SkyPainter(hour: _hour, t: _loop.value)),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: top + 10,
            child: Row(
              children: [
                const _Logo(),
                const Spacer(),
                Pressable(
                  onTap: _cyclePreview,
                  child: GlassPanel(
                    radius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(_previews[_preview].$3, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(_previews[_preview].$1,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: widget.onSettings,
                  child: const GlassPanel(
                    radius: 20,
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: top + 66,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName.isEmpty ? '$_greeting 👋' : '$_greeting, ${widget.userName} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                Text(
                  DateFormat('HH:mm').format(shown),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -2,
                    shadows: [Shadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                ).animate().fadeIn(duration: 700.ms, delay: 100.ms).slideY(begin: 0.2),
                Text(DateFormat('EEEE, d MMMM').format(_now),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    widget.statusChip,
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(_shiftLine,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.health_and_safety_rounded, size: 16, color: Color(0xFF14B8A6)),
          ),
          const SizedBox(width: 6),
          const Text('MAAK معاك',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}
