import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/patient/active_patient_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/doctor_banner.dart';
import '../../../shared/widgets/patient_alert_card.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/avatar_stage_screen.dart';
import '../../teemo/widgets/form_fields.dart';
import '../data/bedsense_api.dart';
import '../data/bedsense_models.dart';
import '../widgets/bs_common.dart';

/// Form groups, in the order of the Streamlit "Check a Patient" tab.
const _groups = <(String, String, IconData, List<String>)>[
  ('About the patient', 'Age, sex and background', Icons.person_rounded, ['age', 'gender', 'race']),
  (
    'This hospital stay',
    'How they came in, where they go next',
    Icons.local_hospital_rounded,
    ['service', 'admission_type_id', 'admission_source_id', 'discharge_disposition_id', 'time_in_hospital'],
  ),
  (
    'Care during the stay',
    'Medicines, tests and procedures',
    Icons.medication_rounded,
    ['num_medications', 'num_lab_procedures', 'num_procedures', 'number_diagnoses'],
  ),
  ('Health problems', 'The main reasons in the file', Icons.monitor_heart_rounded, ['diag_1', 'diag_2', 'diag_3']),
  (
    'The past year',
    'Visits before this stay',
    Icons.history_rounded,
    ['number_inpatient', 'number_emergency', 'number_outpatient'],
  ),
  (
    'Diabetes',
    'Sugar tests and diabetes medicines',
    Icons.water_drop_rounded,
    ['A1Cresult', 'max_glu_serum', 'insulin', 'metformin', 'change', 'diabetesMed'],
  ),
];

const _units = <String, String>{
  'time_in_hospital': 'days',
  'num_medications': 'medicines',
  'num_lab_procedures': 'tests',
  'num_procedures': 'procedures',
  'number_diagnoses': 'problems',
  'number_inpatient': 'stays',
  'number_emergency': 'visits',
  'number_outpatient': 'visits',
};

/// "Check a patient": the form from /meta, then the risk + length-of-stay card.
class CheckPatientView extends StatefulWidget {
  const CheckPatientView({super.key, required this.meta, required this.api});

  final BsMeta meta;
  final BedSenseApi api;

  @override
  State<CheckPatientView> createState() => _CheckPatientViewState();
}

class _CheckPatientViewState extends State<CheckPatientView> with AutomaticKeepAliveClientMixin {
  late Map<String, Object> _values = _defaults();
  final _resultKey = GlobalKey();
  BsPrediction? _result;
  String? _error;
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  Map<String, Object> _defaults() => {for (final f in widget.meta.fields.values) f.key: f.defaultValue};

  void _set(String key, Object v) => setState(() => _values[key] = v);

  Future<void> _check() async {
    final code = context.read<ActivePatientCubit>().state?.code;
    final body = {for (final e in _values.entries) e.key: e.value == bsNone ? null : e.value};
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final res = await widget.api.predict(body, patientCode: code);
      if (!mounted) return;
      setState(() => _result = res);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final patient = context.watch<ActivePatientCubit>().state;
    final fields = widget.meta.fields;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 36 + MediaQuery.paddingOf(context).bottom),
      children: [
        SoftCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: bsGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  patient == null
                      ? 'No patient confirmed'
                      : 'Check linked to file ${patient.code}'
                          '${patient.fullName.isEmpty ? '' : ' · ${patient.fullName}'}',
                  style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Reset the form',
                onPressed: () => setState(() {
                  _values = _defaults();
                  _result = null;
                  _error = null;
                }),
                icon: const Icon(Icons.refresh_rounded, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Fill in what you know about this stay. BedSense estimates the chance the patient '
            'comes back within 30 days and how long they would stay.',
            style: TextStyle(color: AppColors.inkSoft, height: 1.45),
          ),
        ),
        for (final g in _groups) ...[
          SectionHeader(g.$1, icon: g.$3),
          for (final key in g.$4)
            if (fields[key] != null) _field(fields[key]!),
        ],
        if (_error != null) ...[
          const SizedBox(height: 4),
          BsErrorCard(message: _error!),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        GradientButton(
          label: _busy ? 'Checking…' : 'Check this patient',
          icon: Icons.bed_rounded,
          gradient: bsGradient,
          loading: _busy,
          onTap: _busy ? null : _check,
        ),
        const SizedBox(height: 12),
        BsNote(widget.meta.disclaimer, center: true),
        if (_result != null) ...[
          const SizedBox(height: 24),
          KeyedSubtree(key: _resultKey, child: _ResultCard(result: _result!)),
        ],
      ],
    );
  }

  Widget _field(BsField f) {
    final value = _values[f.key] ?? f.defaultValue;
    final Widget input;
    if (f.isNumber) {
      final v = value is num ? value.toInt() : f.min;
      input = f.max - f.min > 25
          ? SliderField(
              value: v,
              min: f.min,
              max: f.max,
              unit: _units[f.key] ?? '',
              color: bsGreen,
              onChanged: (n) => _set(f.key, n),
            )
          : CounterField(
              value: v,
              min: f.min,
              max: f.max,
              unit: _units[f.key] ?? '',
              color: bsGreen,
              onChanged: (n) => _set(f.key, n),
            );
    } else if (f.options.length <= 3) {
      input = SegmentedChoice(
        options: f.options,
        value: value,
        color: bsGreen,
        onChanged: (v) => _set(f.key, v),
      );
    } else if (f.options.length <= 5) {
      input = ChoiceChips(
        options: f.options,
        value: value,
        color: bsGreen,
        onChanged: (v) => _set(f.key, v),
      );
    } else {
      input = PickerField(
        spec: f.spec,
        value: value,
        title: f.help,
        color: bsGreen,
        onChanged: (v) => _set(f.key, v),
      );
    }
    return FieldCard(
      icon: _iconFor(f.key),
      color: bsGreen,
      title: f.help,
      child: input,
    );
  }

  IconData _iconFor(String key) => switch (key) {
        'age' => Icons.cake_rounded,
        'gender' => Icons.wc_rounded,
        'race' => Icons.public_rounded,
        'service' => Icons.apartment_rounded,
        'admission_type_id' => Icons.login_rounded,
        'admission_source_id' => Icons.send_rounded,
        'discharge_disposition_id' => Icons.logout_rounded,
        'time_in_hospital' => Icons.calendar_month_rounded,
        'num_medications' => Icons.medication_rounded,
        'num_lab_procedures' => Icons.science_rounded,
        'num_procedures' => Icons.healing_rounded,
        'number_diagnoses' => Icons.assignment_rounded,
        'diag_1' || 'diag_2' || 'diag_3' => Icons.monitor_heart_rounded,
        'number_inpatient' => Icons.hotel_rounded,
        'number_emergency' => Icons.emergency_rounded,
        'number_outpatient' => Icons.event_available_rounded,
        'A1Cresult' || 'max_glu_serum' => Icons.water_drop_rounded,
        'insulin' || 'metformin' => Icons.vaccines_rounded,
        _ => Icons.tune_rounded,
      };
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final BsPrediction result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final color = levelColor(r.level);
    final high = r.level == 'high';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DoctorBanner(),
        const SizedBox(height: 14),
        SoftCard(
          gradient: levelGradient(r.level),
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Text(r.levelLabel.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12.5)),
              const SizedBox(height: 6),
              AnimatedCount(
                value: r.percent.toDouble(),
                suffix: '%',
                style: const TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(height: 4),
              const Text('chance of coming back to hospital within 30 days',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(r.headline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: KpiTile(
                  icon: Icons.hotel_rounded,
                  value: plural(r.likelyDays, 'day'),
                  label: 'Likely stay if they come back',
                  hint: r.rangeText.isEmpty ? '' : 'Usually ${r.rangeText}',
                  color: bsGreenDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiTile(
                  icon: Icons.bed_rounded,
                  value: r.bedDays.toStringAsFixed(1),
                  label: 'Bed days to plan',
                  hint: 'Chance of coming back × likely stay',
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('In plain words',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(r.sentence, style: const TextStyle(color: AppColors.ink, height: 1.45)),
              const SizedBox(height: 6),
              Text(r.staySentence, style: const TextStyle(color: AppColors.ink, height: 1.45)),
              if (r.facts.isNotEmpty) ...[
                const Divider(height: 24),
                const Text('From the file',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.inkSoft, fontSize: 13)),
                const SizedBox(height: 8),
                for (final f in r.facts) BsBullet(_capitalize(f), color: color),
                if (r.arrival.isNotEmpty) BsBullet('Came in: ${r.arrival}', color: color),
                if (r.leavingTo.isNotEmpty) BsBullet('Going to: ${r.leavingTo}', color: color),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          color: bsGreen.withValues(alpha: 0.08),
          border: Border.all(color: bsGreen.withValues(alpha: 0.3)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(Icons.tips_and_updates_rounded, color: bsGreenDeep, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What to do',
                        style: TextStyle(fontWeight: FontWeight.w800, color: bsGreenDeep)),
                    const SizedBox(height: 4),
                    Text('${r.advice}.', style: const TextStyle(color: AppColors.ink, height: 1.45)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PatientAlertCard(
          module: 'bedsense',
          gradient: bsGradient,
          niveau: high ? 'attention' : 'info',
          titre: switch (r.level) {
            'high' => 'A follow-up visit soon after you go home',
            'medium' => 'An earlier check-up after you go home',
            _ => 'Your usual check-up after you go home',
          },
          message: switch (r.level) {
            'high' => 'Hello, your doctor would like to see you again soon after you go home. '
                'The team will contact you to book a visit. Take care of yourself.',
            'medium' => 'Hello, your doctor would like to see you a little earlier than usual '
                'after you go home. The team will help you book a visit. Take care of yourself.',
            _ => 'Hello, your doctor has prepared your discharge. Your usual check-up is enough. '
                'Take care of yourself.',
          },
        ),
        const SizedBox(height: 16),
        if (r.narrative.isNotEmpty)
          GradientButton(
            label: 'Hear BedSense explain',
            icon: Icons.volume_up_rounded,
            gradient: bsGradient,
            onTap: () => AvatarStageScreen.open(context,
                avatar: AvatarProfile.bedsense, segments: r.narrative, title: 'BedSense explains'),
          ),
      ].animate(interval: 70.ms).fadeIn(duration: 380.ms).slideY(begin: 0.06),
    );
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
