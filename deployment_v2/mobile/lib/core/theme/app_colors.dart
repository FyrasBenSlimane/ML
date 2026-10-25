import 'package:flutter/material.dart';

/// One palette for the whole app: mint/teal medical base, with blue, violet,
/// coral and amber accents so screens feel colourful but still clinical.
abstract final class AppColors {
  static const teal = Color(0xFF14B8A6);
  static const tealDeep = Color(0xFF0F766E);
  static const mint = Color(0xFFE6FBF6);
  static const blue = Color(0xFF3B82F6);
  static const sky = Color(0xFF38BDF8);
  static const indigo = Color(0xFF6366F1);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFF472B6);
  static const coral = Color(0xFFFB7185);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF10B981);
  static const red = Color(0xFFEF4444);

  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF475569);
  static const muted = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const bg = Color(0xFFF3F7FB);
  static const card = Colors.white;

  static const brandGradient = LinearGradient(
    colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const violetGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF8B5CF6), Color(0xFFC084FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const coralGradient = LinearGradient(
    colors: [Color(0xFFFDA4AF), Color(0xFFFB7185), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const amberGradient = LinearGradient(
    colors: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const blueGradient = LinearGradient(
    colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color forLevel(String level) => switch (level) {
        'HIGH' => red,
        'MODERATE' => amber,
        _ => green,
      };

  static LinearGradient gradientForLevel(String level) => switch (level) {
        'HIGH' => const LinearGradient(
            colors: [Color(0xFFFB7185), Color(0xFFEF4444), Color(0xFFDB2777)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        'MODERATE' => const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        _ => const LinearGradient(
            colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      };

  static List<BoxShadow> softShadow([Color color = const Color(0xFF0F172A)]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> glow(Color color, {double strength = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];
}
