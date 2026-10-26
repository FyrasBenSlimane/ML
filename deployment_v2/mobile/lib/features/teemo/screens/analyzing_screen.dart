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
import '../bloc/history_cubit.dart';
import '../data/teemo_models.dart';
import '../data/teemo_repository.dart';
import 'result_screen.dart';

/// Teemo "thinking": the request runs while a short checklist animates, so
/// the wait feels purposeful (and explains what the model actually does).
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key, required this.patient, this.label});

  final Map<String, dynamic> patient;
  final String? label;

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  static const _steps = [
    ('Reading 38 clinical features', Icons.fact_check_rounded),
    ('Running calibrated LightGBM', Icons.account_tree_rounded),
    ('Explaining with SHAP', Icons.insights_rounded),
    ('Writing the care plan', Icons.edit_note_rounded),
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
    _ticker = Timer.periodic(const Duration(milliseconds: 620), (t) {
      if (_done < _steps.length - 1) setState(() => _done++);
    });
    try {
      final code = context.read<ActivePatientCubit>().state?.code;
      final results = await Future.wait([
        context.read<TeemoRepository>().predict(widget.patient, label: widget.label, patientCode: code),
        Future<void>.delayed(const Duration(milliseconds: 2600)),
      ]);
      final result = results.first as TeemoResult;
      if (!mounted) return;
      _ticker?.cancel();
      setState(() => _done = _steps.length);
      HapticFeedback.mediumImpact();
      await context.read<HistoryCubit>().add(result);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, _, _) => ResultScreen(result: result, fresh: true),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: a,
          child: ScaleTransition(
              scale: Tween(begin: 1.06, end: 1.0)
                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
              child: child),
        ),
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
        baseColor: const Color(0xFFF0FDFA),
        opacity: 0.3,
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
        const AvatarFace(avatar: AvatarProfile.teemo, size: 150, ring: true)
            .animate()
            .scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 900.ms),
        const SizedBox(height: 26),
        const Text('Teemo is analysing…',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1800.ms, color: AppColors.teal),
        const SizedBox(height: 6),
        Text(widget.label ?? 'New patient',
            style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 18),
        const EcgLine(color: AppColors.teal, height: 46),
        const SizedBox(height: 18),
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            label: _steps[i].$1,
            icon: _steps[i].$2,
            state: i < _done ? 2 : (i == _done ? 1 : 0),
          ).animate().fadeIn(delay: (150 * i).ms).slideX(begin: 0.15),
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
        GradientButton(label: 'Try again', icon: Icons.refresh_rounded, onTap: _run),
        const SizedBox(height: 12),
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: const Text('Back to the form')),
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
    final color = state == 2 ? AppColors.green : (state == 1 ? AppColors.teal : AppColors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: state == 0 ? 0.5 : 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: state == 1 ? AppColors.glow(AppColors.teal, strength: 0.18) : null,
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
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.teal),
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
