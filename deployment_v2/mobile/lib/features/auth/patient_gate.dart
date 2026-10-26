import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/patient/active_patient_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/cards.dart';

/// Asks the doctor for a Patient ID, confirms the name with the server and
/// returns the chosen patient (or null if the doctor backs out).
Future<ActivePatient?> askPatientCode(BuildContext context) {
  return showModalBottomSheet<ActivePatient>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: context.read<ActivePatientCubit>(),
      child: RepositoryProvider.value(
        value: context.read<ApiClient>(),
        child: const _PatientCodeSheet(),
      ),
    ),
  );
}

/// Wraps a model's first screen so an evaluation can only start once a patient
/// has been confirmed. Cancelling simply leaves the module.
class PatientGate extends StatefulWidget {
  const PatientGate({super.key, required this.module, required this.child});

  final String module;
  final Widget child;

  @override
  State<PatientGate> createState() => _PatientGateState();
}

class _PatientGateState extends State<PatientGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prompt());
  }

  Future<void> _prompt() async {
    final patient = await askPatientCode(context);
    if (!mounted) return;
    if (patient == null) {
      Navigator.of(context).pop(); // doctor backed out of the module
      return;
    }
    context.read<ActivePatientCubit>().select(patient);
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    // Quiet placeholder while the patient sheet is up.
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
    );
  }
}

class _PatientCodeSheet extends StatefulWidget {
  const _PatientCodeSheet();

  @override
  State<_PatientCodeSheet> createState() => _PatientCodeSheetState();
}

class _PatientCodeSheetState extends State<_PatientCodeSheet> {
  late final TextEditingController _code =
      TextEditingController(text: context.read<ActivePatientCubit>().state?.code ?? '');
  bool _busy = false;
  String? _error;
  ActivePatient? _found;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final json = await context.read<ApiClient>().getJson('/api/v1/patients/$code');
      if (mounted) setState(() => _found = ActivePatient.fromJson(json));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconBadge(Icons.badge_rounded, color: AppColors.teal, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Which patient are you assessing?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(
                      _found == null
                          ? 'Enter their Patient ID (e.g. PT-00042).'
                          : 'Check this is the right person.',
                      style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_found == null) ...[
            TextField(
              controller: _code,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
              decoration: const InputDecoration(
                hintText: 'PT-00042',
                prefixIcon: Icon(Icons.tag_rounded, color: AppColors.muted),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _errorBox(_error!),
            ],
            const SizedBox(height: 18),
            GradientButton(
              label: 'Confirm patient',
              icon: Icons.search_rounded,
              loading: _busy,
              onTap: _busy ? null : _confirm,
            ),
          ] else ...[
            _confirmedCard(_found!),
            const SizedBox(height: 18),
            GradientButton(
              label: 'Start assessment',
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.of(context).pop(_found),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => setState(() {
                _found = null;
                _error = null;
              }),
              child: const Text('Change patient',
                  style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confirmedCard(ActivePatient p) {
    final initials = ((p.prenom.isNotEmpty ? p.prenom[0] : '') + (p.nom.isNotEmpty ? p.nom[0] : ''))
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.glow(AppColors.teal, strength: 0.3),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Text(initials.isEmpty ? '?' : initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                Text(p.code,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
        ],
      ),
    );
  }

  Widget _errorBox(String message) {
    HapticFeedback.lightImpact();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 12.5, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
