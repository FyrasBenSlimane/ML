import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/ambient.dart';
import '../auth/root_gate.dart';
import '../avatar/avatar_profile.dart';
import '../avatar/widgets/avatar_face.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) => const RootGate(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        baseColor: const Color(0xFFF0FDFA),
        colors: const [AppColors.teal, AppColors.sky, AppColors.violet, AppColors.pink],
        opacity: 0.35,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.glow(AppColors.teal, strength: 0.45),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 54),
              )
                  .animate()
                  .scale(begin: const Offset(0.3, 0.3), duration: 900.ms, curve: Curves.elasticOut)
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.white54),
              const SizedBox(height: 22),
              const Text('ReadmitGuard',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1))
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.4),
              const Text('Care that follows patients home',
                      style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600))
                  .animate()
                  .fadeIn(delay: 600.ms),
              const SizedBox(height: 26),
              const SizedBox(width: 220, child: EcgLine(color: AppColors.teal, height: 44))
                  .animate()
                  .fadeIn(delay: 800.ms),
              const SizedBox(height: 22),
              const AvatarFace(avatar: AvatarProfile.teemo, size: 64)
                  .animate()
                  .fadeIn(delay: 1100.ms)
                  .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
