import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colours of the sky at one moment of the day.
class SkyPalette {
  const SkyPalette({
    required this.top,
    required this.bottom,
    required this.far,
    required this.mid,
    required this.nearTop,
    required this.nearBottom,
  });

  final Color top, bottom, far, mid, nearTop, nearBottom;

  static SkyPalette lerp(SkyPalette a, SkyPalette b, double t) => SkyPalette(
        top: Color.lerp(a.top, b.top, t)!,
        bottom: Color.lerp(a.bottom, b.bottom, t)!,
        far: Color.lerp(a.far, b.far, t)!,
        mid: Color.lerp(a.mid, b.mid, t)!,
        nearTop: Color.lerp(a.nearTop, b.nearTop, t)!,
        nearBottom: Color.lerp(a.nearBottom, b.nearBottom, t)!,
      );
}

const _night = SkyPalette(
  top: Color(0xFF1E1B4B), bottom: Color(0xFF6D3FB8),
  far: Color(0xFF5B43A8), mid: Color(0xFF45338F),
  nearTop: Color(0xFFB794F4), nearBottom: Color(0xFF7C5BD6),
);
const _dawn = SkyPalette(
  top: Color(0xFF6366F1), bottom: Color(0xFFF9A8D4),
  far: Color(0xFF8F86E0), mid: Color(0xFF7468CC),
  nearTop: Color(0xFF99F6E4), nearBottom: Color(0xFF5EB8D9),
);
const _day = SkyPalette(
  top: Color(0xFF3B6FF0), bottom: Color(0xFF9CCBFF),
  far: Color(0xFF5B8DEF), mid: Color(0xFF3E6FD9),
  nearTop: Color(0xFF7DF2DD), nearBottom: Color(0xFF2CC5C0),
);
const _sunset = SkyPalette(
  top: Color(0xFF5B5BD6), bottom: Color(0xFFFDBA74),
  far: Color(0xFF8C7BD8), mid: Color(0xFF6A5BC2),
  nearTop: Color(0xFFA7F3D0), nearBottom: Color(0xFF4FB3C9),
);
const _dusk = SkyPalette(
  top: Color(0xFF3B1F7A), bottom: Color(0xFFF472B6),
  far: Color(0xFF7A4FB8), mid: Color(0xFF5A3A9E),
  nearTop: Color(0xFFC4B5FD), nearBottom: Color(0xFF8B5CF6),
);

/// (hour, palette) keyframes; colours are blended between neighbours.
const _keys = <(double, SkyPalette)>[
  (0, _night), (5.0, _night), (6.3, _dawn), (8.0, _day), (16.0, _day),
  (17.6, _sunset), (19.0, _dusk), (20.5, _night), (24, _night),
];

SkyPalette paletteAt(double hour) {
  final h = hour % 24;
  for (var i = 0; i < _keys.length - 1; i++) {
    final (h0, p0) = _keys[i];
    final (h1, p1) = _keys[i + 1];
    if (h >= h0 && h <= h1) {
      final t = h1 == h0 ? 0.0 : (h - h0) / (h1 - h0);
      return SkyPalette.lerp(p0, p1, Curves.easeInOut.transform(t));
    }
  }
  return _night;
}

/// 0 in full daylight, 1 in deep night.
double nightness(double hour) {
  final h = hour % 24;
  if (h >= 8 && h <= 17) return 0;
  if (h >= 20.5 || h <= 5) return 1;
  if (h < 8) return 1 - ((h - 5) / 3).clamp(0, 1);
  return ((h - 17) / 3.5).clamp(0, 1);
}

/// The whole animated landscape. [hour] may be fractional (14.5 = 14:30);
/// [t] is a looping 0..1 animation value for clouds and twinkling.
class SkyPainter extends CustomPainter {
  SkyPainter({required this.hour, required this.t});

  final double hour;
  final double t;

  static final _stars = List.generate(46, (i) {
    final r = math.Random(i * 7919);
    return (r.nextDouble(), r.nextDouble() * 0.6, 0.6 + r.nextDouble() * 1.4, r.nextDouble());
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = paletteAt(hour);
    final night = nightness(hour);
    final w = size.width, hgt = size.height;

    // sky
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.top, p.bottom],
        ).createShader(Offset.zero & size),
    );

    // stars
    if (night > 0.02) {
      for (final (sx, sy, sr, phase) in _stars) {
        final tw = 0.5 + 0.5 * math.sin((t * 6 + phase) * 2 * math.pi);
        canvas.drawCircle(Offset(sx * w, sy * hgt), sr,
            Paint()..color = Colors.white.withValues(alpha: night * (0.35 + 0.65 * tw)));
      }
      // a shooting star now and then
      final sp = (t * 3) % 1;
      if (sp < 0.12 && night > 0.6) {
        final k = sp / 0.12;
        final a = Offset(w * (0.2 + 0.5 * k), hgt * (0.08 + 0.18 * k));
        canvas.drawLine(
          a,
          a - const Offset(46, 16),
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(colors: [
              Colors.white.withValues(alpha: 0.9 * (1 - k)),
              Colors.white.withValues(alpha: 0),
            ]).createShader(Rect.fromPoints(a, a - const Offset(46, 16))),
        );
      }
    }

    _paintCelestial(canvas, size, night);
    _paintClouds(canvas, size, night);

    // far mountains
    _hills(canvas, size, p.far, base: 0.66, amp: 0.13, freq: 2.6, phase: 0.4, peaks: true);
    _hills(canvas, size, p.mid, base: 0.74, amp: 0.08, freq: 1.7, phase: 1.9, peaks: true);
    _paintHospital(canvas, size, night, p.mid);

    // glossy near hill
    final near = Path()..moveTo(0, hgt);
    for (var x = 0.0; x <= w; x += 4) {
      final y = hgt * (0.84 - 0.05 * math.sin(x / w * math.pi * 1.2 + 0.3));
      near.lineTo(x, y);
    }
    near
      ..lineTo(w, hgt)
      ..close();
    canvas.drawPath(
      near,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.nearTop, p.nearBottom],
        ).createShader(Rect.fromLTWH(0, hgt * 0.75, w, hgt * 0.25)),
    );
    // shine streak on the hill
    final shine = Path()
      ..moveTo(w * 0.08, hgt * 0.835)
      ..quadraticBezierTo(w * 0.3, hgt * 0.795, w * 0.52, hgt * 0.81);
    canvas.drawPath(
      shine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _paintCelestial(Canvas canvas, Size size, double night) {
    final w = size.width, hgt = size.height;
    final h = hour % 24;
    final isDay = h >= 6 && h < 19;
    final prog = isDay ? (h - 6) / 13 : (((h - 19) % 24) / 11);
    // Arc stays in the right half so it never sits behind the clock text.
    final c = Offset(w * (0.52 + 0.38 * prog), hgt * (0.52 - 0.32 * math.sin(prog * math.pi)));
    final r = w * 0.085;

    // halo
    canvas.drawCircle(
      c,
      r * 2.6,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: isDay ? 0.45 : 0.25),
          Colors.white.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: c, radius: r * 2.6)),
    );
    if (isDay) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [Color(0xFFFFF7CC), Color(0xFFFFD66B)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    } else {
      // crescent moon: a disc with an offset bite taken out
      final moon = Path()..addOval(Rect.fromCircle(center: c, radius: r));
      final bite = Path()..addOval(Rect.fromCircle(center: c + Offset(r * 0.55, -r * 0.25), radius: r * 0.9));
      canvas.drawPath(
        Path.combine(PathOperation.difference, moon, bite),
        Paint()..color = const Color(0xFFFFF1B8),
      );
    }
  }

  void _paintClouds(Canvas canvas, Size size, double night) {
    final w = size.width, hgt = size.height;
    final color = Color.lerp(Colors.white, const Color(0xFFE9D5FF), night)!
        .withValues(alpha: 0.95 - night * 0.45);
    const specs = [(0.18, 0.9, 1.0, 0.0), (0.33, 0.6, 0.7, 0.45), (0.12, 0.75, 0.55, 0.75)];
    for (final (y, scale, speed, offset) in specs) {
      final span = w + 220;
      final x = ((t * speed + offset) % 1) * span - 110;
      _cloud(canvas, Offset(x, hgt * y), w * 0.16 * scale, color);
    }
  }

  void _cloud(Canvas canvas, Offset o, double s, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx - s * 1.3, o.dy, s * 2.6, s * 0.7), Radius.circular(s * 0.35)))
      ..addOval(Rect.fromCircle(center: o + Offset(-s * 0.45, s * 0.05), radius: s * 0.48))
      ..addOval(Rect.fromCircle(center: o + Offset(s * 0.25, -s * 0.12), radius: s * 0.62));
    canvas.drawPath(path, paint);
  }

  void _hills(Canvas canvas, Size size, Color color,
      {required double base, required double amp, required double freq, required double phase, bool peaks = false}) {
    final w = size.width, hgt = size.height;
    final path = Path()..moveTo(0, hgt);
    for (var x = 0.0; x <= w; x += 3) {
      final u = x / w * math.pi * freq + phase;
      var s = math.sin(u);
      if (peaks) s = math.pow(s.abs(), 1.6) * s.sign * 0.7 + 0.3 * math.sin(u * 2.3);
      path.lineTo(x, hgt * (base - amp * s));
    }
    path
      ..lineTo(w, hgt)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintHospital(Canvas canvas, Size size, double night, Color hill) {
    final w = size.width, hgt = size.height;
    final bw = w * 0.2, bh = hgt * 0.17;
    final left = w * 0.70, bottom = hgt * 0.80;
    final body = Rect.fromLTWH(left, bottom - bh, bw, bh);
    final wall = Color.lerp(const Color(0xFFF8FAFC), const Color(0xFF8B7FD8), night * 0.7)!;
    canvas.drawRRect(RRect.fromRectAndCorners(body, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
        Paint()..color = wall);
    // side wing
    final wing = Rect.fromLTWH(left - bw * 0.42, bottom - bh * 0.58, bw * 0.46, bh * 0.58);
    canvas.drawRRect(RRect.fromRectAndCorners(wing, topLeft: const Radius.circular(5)),
        Paint()..color = Color.lerp(wall, hill, 0.18)!);

    // windows — glow at night
    final lit = Color.lerp(const Color(0xFF93C5FD), const Color(0xFFFDE68A), night)!;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final on = night < 0.5 || (row * 3 + col + (t * 4).floor()) % 4 != 0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left + bw * (0.12 + col * 0.28), bottom - bh * (0.86 - row * 0.26), bw * 0.18, bh * 0.14),
            const Radius.circular(2),
          ),
          Paint()..color = on ? lit : lit.withValues(alpha: 0.35),
        );
      }
    }
    for (var col = 0; col < 2; col++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wing.left + wing.width * (0.14 + col * 0.44), wing.top + wing.height * 0.22,
              wing.width * 0.3, wing.height * 0.22),
          const Radius.circular(2),
        ),
        Paint()..color = lit.withValues(alpha: 0.85),
      );
    }

    // red cross sign on the roof, softly pulsing
    final pulse = 0.75 + 0.25 * math.sin(t * 2 * math.pi * 8);
    final cc = Offset(left + bw / 2, bottom - bh - bh * 0.22);
    final cs = bh * 0.2;
    canvas.drawCircle(cc, cs * 1.1, Paint()..color = Colors.white);
    final cross = Paint()..color = Color.lerp(const Color(0xFFEF4444), const Color(0xFFFF6B6B), pulse)!;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: cc, width: cs * 0.5, height: cs * 1.5), const Radius.circular(2)), cross);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: cc, width: cs * 1.5, height: cs * 0.5), const Radius.circular(2)), cross);
    if (night > 0.3) {
      canvas.drawCircle(
        cc,
        cs * 2.4,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFEF4444).withValues(alpha: 0.35 * night * pulse),
            const Color(0x00EF4444),
          ]).createShader(Rect.fromCircle(center: cc, radius: cs * 2.4)),
      );
    }

    // trees
    for (final (dx, s) in [(-0.62, 1.0), (1.12, 0.8), (1.32, 1.1)]) {
      final base = Offset(left + bw * dx, bottom);
      canvas.drawRect(Rect.fromLTWH(base.dx - 1.5, base.dy - bh * 0.25 * s, 3, bh * 0.25 * s),
          Paint()..color = Color.lerp(const Color(0xFF0F766E), hill, 0.5)!);
      canvas.drawCircle(base - Offset(0, bh * 0.32 * s), bh * 0.16 * s,
          Paint()..color = Color.lerp(const Color(0xFF14B8A6), hill, 0.35 + night * 0.3)!);
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) => old.hour != hour || old.t != t;
}
