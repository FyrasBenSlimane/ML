import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/patient/active_patient_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/widgets/avatar_face.dart';
import '../data/carestep_api.dart';
import '../data/carestep_models.dart';
import 'carestep_result_screen.dart';

/// CareStep "thinking": the /predict call runs while a short checklist animates.
class CareStepAnalyzingScreen extends StatefulWidget {
  const CareStepAnalyzingScreen({super.key, required this.answers});

  final Map<String, Object> answers;

  @override
  State<CareStepAnalyzingScreen> createState() => _CareStepAnalyzingScreenState();
}

class _CareStepAnalyzingScreenState extends State<CareStepAnalyzingScreen> {
  static const _steps = [
    ('Reading the answers', Icons.fact_check_rounded),
    ('Estimating the 30-day risk', Icons.speed_rounded),
    ('Finding the main reasons', Icons.search_rounded),
    ('Building the recovery plan', Icons.event_note_rounded),
  ];

  int _done = 0;
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _done = 0;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 600), (t) {
      if (_done < _steps.length - 1) setState(() => _done++);
    });
    final code = context.read<ActivePatientCubit>().state?.code;
    final api = CareStepApi(context.read<ApiClient>());
    try {
      final results = await Future.wait([
        api.predict(widget.answers, patientCode: code),
        Future<void>.delayed(const Duration(milliseconds: 2400)),
      ]);
      if (!mounted) return;
      _ticker?.cancel();
      setState(() => _done = _steps.length);
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, _, _) => CareStepResultScreen(result: results.first as CareStepResult),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));
    } on ApiException catch (e) {
      _ticker?.cancel();
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        baseColor: const Color(0xFFF0F7FF),
        colors: const [AppColors.blue, AppColors.sky, AppColors.indigo],
        opacity: 0.25,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _error == null ? _thinking() : _failure(),
          ),
        ),
      ),
    );
  }

  Widget _thinking() {
    return Column(
      children: [
        const Spacer(flex: 2),
        const AvatarFace(avatar: AvatarProfile.carestep, size: 140, ring: true)
            .animate()
            .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 900.ms),
        const SizedBox(height: 24),
        const Text('CareStep is looking ahead…',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1800.ms, color: AppColors.blue),
        const SizedBox(height: 16),
        const EcgLine(color: AppColors.blue, height: 44),
        const SizedBox(height: 18),
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            label: _steps[i].$1,
            icon: _steps[i].$2,
            state: i < _done ? 2 : (i == _done ? 1 : 0),
          ).animate().fadeIn(delay: (120 * i).ms).slideX(begin: 0.15),
        const Spacer(flex: 3),
      ],
    );
  }

  Widget _failure() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const IconBadge(Icons.wifi_off_rounded, color: AppColors.coral, size: 90),
        const SizedBox(height: 20),
        const Text('Analysis failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
        const SizedBox(height: 26),
        GradientButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            gradient: AppColors.blueGradient,
            onTap: _run),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to the form')),
      ],
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.icon, required this.state});

  final String label;
  final IconData icon;

  /// 0 = waiting, 1 = running, 2 = done
  final int state;

  @override
  Widget build(BuildContext context) {
    final color = state == 2 ? AppColors.green : (state == 1 ? AppColors.blue : AppColors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: state == 0 ? 0.5 : 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: state == 1 ? AppColors.glow(AppColors.blue, strength: 0.18) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: state == 0 ? AppColors.muted : AppColors.ink)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (state) {
                2 => const Icon(Icons.check_circle_rounded, color: AppColors.green, key: ValueKey(2)),
                1 => const SizedBox(
                    key: ValueKey(1),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.blue),
                  ),
                _ => const Icon(Icons.circle_outlined, color: AppColors.line, key: ValueKey(0)),
              },
            ),
          ],
        ),
      ),
    );
  }
}
