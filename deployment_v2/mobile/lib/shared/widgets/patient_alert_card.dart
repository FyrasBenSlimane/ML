import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/patient/active_patient_cubit.dart';
import '../../core/theme/app_colors.dart';
import 'cards.dart';

/// Shown under every model result (doctor side). It carries a kind, pre-written
/// message — no figures, no alarming words — that the doctor can edit and then
/// send to the confirmed patient. Nothing is sent until the button is tapped.
class PatientAlertCard extends StatefulWidget {
  const PatientAlertCard({
    super.key,
    required this.module,
    required this.niveau,
    required this.titre,
    required this.message,
    this.gradient = AppColors.brandGradient,
  });

  final String module;
  final String niveau; // info | attention | important
  final String titre;
  final String message;
  final Gradient gradient;

  @override
  State<PatientAlertCard> createState() => _PatientAlertCardState();
}

class _PatientAlertCardState extends State<PatientAlertCard> {
  late final TextEditingController _titre = TextEditingController(text: widget.titre);
  late final TextEditingController _message = TextEditingController(text: widget.message);
  bool _busy = false;
  bool _sent = false;
  String? _error;

  (String, Color) get _niveauInfo => switch (widget.niveau) {
        'important' => ('Review soon', AppColors.coral),
        'attention' => ('A bit more follow-up', AppColors.amber),
        _ => ('All is well', AppColors.green),
      };

  @override
  void dispose() {
    _titre.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send(ActivePatient patient) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().postJson('/api/v1/notifications', {
        'patient_code': patient.code,
        'module': widget.module,
        'niveau': widget.niveau,
        'titre': _titre.text.trim(),
        'message': _message.text.trim(),
      });
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() => _sent = true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<ActivePatientCubit>().state;
    final (niveauLabel, niveauColor) = _niveauInfo;

    if (_sent) {
      return SoftCard(
        gradient: AppColors.gradientForLevel('LOW'),
        child: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                patient == null
                    ? 'Alert sent to the patient.'
                    : 'Alert sent to ${patient.fullName}.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        ),
      );
    }

    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.send_rounded, color: AppColors.teal, size: 40),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Send an alert to the patient',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              ),
              Pill(niveauLabel, color: niveauColor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            patient == null
                ? 'No patient selected.'
                : 'Kind message for ${patient.fullName} · ${patient.code}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titre,
            decoration: const InputDecoration(labelText: 'Title', isDense: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          GradientButton(
            label: 'Send the alert',
            icon: Icons.notifications_active_rounded,
            gradient: widget.gradient,
            loading: _busy,
            onTap: (patient == null || _busy) ? null : () => _send(patient),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.lock_person_rounded, color: AppColors.muted, size: 15),
              SizedBox(width: 6),
              Expanded(
                child: Text('The patient only receives this message — never the model result.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
