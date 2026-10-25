import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    // google_fonts only supplies the family name (it downloads and caches the
    // font); all text styling stays on Flutter's own ThemeData types.
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.violet,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );
    final text = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    return base.copyWith(
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
        titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 8,
        activeTrackColor: AppColors.teal,
        inactiveTrackColor: AppColors.teal.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: AppColors.teal.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12, elevation: 4),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
