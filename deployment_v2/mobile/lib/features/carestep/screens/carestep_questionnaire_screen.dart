import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/widgets/avatar_face.dart';
import '../../teemo/widgets/form_fields.dart';
import '../data/carestep_api.dart';
import '../data/carestep_models.dart';
import 'carestep_analyzing_screen.dart';

const _blobs = [AppColors.blue, AppColors.sky, AppColors.indigo];

enum _Kind { picker, segmented, chips, slider, counter }

/// How each of the 12 answers is shown. Labels, options and ranges come from
/// /meta; only the look (icon, colour, widget, unit) lives here.
typedef _Look = ({IconData icon, Color color, _Kind kind, String unit});

const Map<String, _Look> _looks = {
  'age': (icon: Icons.cake_rounded, color: AppColors.pink, kind: _Kind.picker, unit: ''),
  'gender': (icon: Icons.person_rounded, color: AppColors.violet, kind: _Kind.segmented, unit: ''),
  'diag_group': (
    icon: Icons.monitor_heart_rounded,
    color: AppColors.red,
    kind: _Kind.chips,
    unit: ''
  ),
  'time_hosp': (icon: Icons.bed_rounded, color: AppColors.teal, kind: _Kind.slider, unit: 'days'),
  'discharge': (icon: Icons.home_rounded, color: AppColors.green, kind: _Kind.chips, unit: ''),
  'num_meds': (
    icon: Icons.medication_rounded,
    color: AppColors.coral,
    kind: _Kind.slider,
    unit: 'medications'
  ),
  'insulin': (icon: Icons.vaccines_rounded, color: AppColors.indigo, kind: _Kind.chips, unit: ''),
  'med_change': (
    icon: Icons.published_with_changes_rounded,
    color: AppColors.amber,
    kind: _Kind.chips,
    unit: ''
  ),
  'a1c_tested': (icon: Icons.science_rounded, color: AppColors.sky, kind: _Kind.chips, unit: ''),
  'inpatient': (
    icon: Icons.local_hospital_rounded,
    color: AppColors.blue,
    kind: _Kind.counter,
    unit: 'stays'
  ),
  'emergency': (icon: Icons.emergency_rounded, color: AppColors.red, kind: _Kind.counter, unit: 'visits'),
  'outpatient_raw': (
    icon: Icons.medical_services_rounded,
    color: AppColors.teal,
    kind: _Kind.counter,
    unit: 'visits'
  ),
};

const _sections = <(String, IconData, List<String>)>[
  ('About the patient', Icons.person_rounded, ['age', 'gender']),
  ('This hospital stay', Icons.local_hospital_rounded, ['diag_group', 'time_hosp', 'discharge']),
  ('Medicines', Icons.medication_rounded, ['num_meds', 'insulin', 'med_change', 'a1c_tested']),
  ('The past year', Icons.history_rounded, ['inpatient', 'emergency', 'outpatient_raw']),
];

IconData _diagIcon(Object v) => switch (v) {
      'circulatory' => Icons.favorite_rounded,
      'respiratory' => Icons.air_rounded,
      'digestive' => Icons.restaurant_rounded,
      'diabetes' => Icons.water_drop_rounded,
      'injury' => Icons.personal_injury_rounded,
      'infection_renal' => Icons.coronavirus_rounded,
      _ => Icons.more_horiz_rounded,
    };

/// CareStep's 12-question form. The questions and their options are loaded
/// from the server (/meta) so they always match what the model expects.
class CareStepQuestionnaireScreen extends StatefulWidget {
  const CareStepQuestionnaireScreen({super.key});

  @override
  State<CareStepQuestionnaireScreen> createState() => _CareStepQuestionnaireScreenState();
}

class _CareStepQuestionnaireScreenState extends State<CareStepQuestionnaireScreen> {
  CareStepMeta? _meta;
  Map<String, Object> _a = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final meta = await CareStepApi(context.read<ApiClient>()).meta();
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _a = meta.defaults;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _set(String k, Object v) => setState(() => _a[k] = v);

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return Scaffold(
      body: BlobBackground(
        colors: _blobs,
        opacity: 0.16,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              if (meta == null)
                Expanded(child: _error == null ? _loading() : _failure())
              else ...[
                const _Tip("Go through these 12 simple questions with the patient. "
                    "I'll estimate the chance of coming back to hospital within 30 days "
                    'and prepare a week-by-week recovery plan.'),
                Expanded(child: _form(meta)),
                _bottomBar(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.blue),
            SizedBox(height: 14),
            Text('Loading the questions…',
                style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _failure() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const IconBadge(Icons.wifi_off_rounded, color: AppColors.coral, size: 90),
            const SizedBox(height: 20),
            const Text("Couldn't load the form",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 26),
            GradientButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                gradient: AppColors.blueGradient,
                onTap: _load),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      );

  Widget _form(CareStepMeta meta) {
    final placed = <String>{};
    final children = <Widget>[];
    for (final (title, icon, keys) in _sections) {
      final present = keys.where(meta.fields.containsKey).toList();
      if (present.isEmpty) continue;
      children.add(SectionHeader(title, icon: icon));
      for (final k in present) {
        children.add(_field(meta.fields[k]!));
        placed.add(k);
      }
    }
    // Any field the server adds later still shows up.
    final extra = meta.fields.keys.where((k) => !placed.contains(k)).toList();
    if (extra.isNotEmpty) {
      children.add(const SectionHeader('More', icon: Icons.more_horiz_rounded));
      for (final k in extra) {
        children.add(_field(meta.fields[k]!));
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: children.animate(interval: 40.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08),
    );
  }

  Widget _field(CareStepField f) {
    final look = _looks[f.key] ??
        (
          icon: f.isChoice ? Icons.checklist_rounded : Icons.pin_rounded,
          color: AppColors.blue,
          kind: f.isChoice
              ? (f.spec.options.length > 7 ? _Kind.picker : _Kind.chips)
              : _Kind.counter,
          unit: '',
        );
    final value = _a[f.key] ?? f.spec.defaultValue;
    final Widget input = switch (look.kind) {
      _Kind.picker => PickerField(
          title: f.label,
          spec: f.spec,
          value: value,
          color: look.color,
          onChanged: (v) => _set(f.key, v),
        ),
      _Kind.segmented => SegmentedChoice(
          options: f.spec.options,
          value: value,
          color: look.color,
          onChanged: (v) => _set(f.key, v),
        ),
      _Kind.chips => ChoiceChips(
          options: f.spec.options,
          value: value,
          color: look.color,
          icons: f.key == 'diag_group' ? _diagIcon : null,
          onChanged: (v) => _set(f.key, v),
        ),
      _Kind.slider => SliderField(
          value: (value as num).toInt(),
          min: f.min,
          max: f.max,
          unit: look.unit,
          color: look.color,
          onChanged: (v) => _set(f.key, v),
        ),
      _Kind.counter => CounterField(
          value: (value as num).toInt(),
          min: f.min,
          max: f.max,
          unit: look.unit,
          color: look.color,
          onChanged: (v) => _set(f.key, v),
        ),
    };
    return FieldCard(
      icon: look.icon,
      color: look.color,
      title: f.label,
      subtitle: f.help,
      child: input,
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            const Expanded(
              child: Text('CareStep · 30-day recovery',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'Reset',
              onPressed: _meta == null ? null : () => setState(() => _a = _meta!.defaults),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );

  Widget _bottomBar(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: AppColors.softShadow(),
        ),
        child: GradientButton(
          label: 'Check the recovery risk',
          icon: Icons.auto_awesome_rounded,
          gradient: AppColors.blueGradient,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CareStepAnalyzingScreen(answers: Map.of(_a)),
          )),
        ),
      );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AvatarFace(avatar: AvatarProfile.carestep, size: 44),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: AppColors.softShadow(),
              ),
              child: Text(text,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35)),
            ),
          ),
        ],
      ),
    );
  }
}
