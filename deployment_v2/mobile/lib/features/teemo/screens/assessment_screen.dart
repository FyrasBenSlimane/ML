import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../../shared/widgets/pressable.dart';
import '../../auth/patient_gate.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/widgets/avatar_face.dart';
import '../bloc/assessment_cubit.dart';
import '../data/teemo_models.dart';
import '../data/teemo_repository.dart';
import '../widgets/form_fields.dart';
import 'analyzing_screen.dart';

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({super.key, this.sample});

  /// Pre-load one of the demo patients (from the home screen shortcut).
  final String? sample;

  @override
  Widget build(BuildContext context) {
    // Confirm the Patient ID before any Teemo assessment can begin.
    return PatientGate(
      module: 'teemo',
      child: BlocProvider(
        create: (ctx) => AssessmentCubit(ctx.read<TeemoRepository>()),
        child: _AssessmentView(sample: sample),
      ),
    );
  }
}

class _AssessmentView extends StatefulWidget {
  const _AssessmentView({this.sample});

  final String? sample;

  @override
  State<_AssessmentView> createState() => _AssessmentViewState();
}

class _AssessmentViewState extends State<_AssessmentView> {
  final _pages = PageController();
  bool _sampleApplied = false;

  static const _tips = [
    "Hi! Tell me about the patient. Short on time? Load a real anonymised sample patient below.",
    'Where the patient goes after discharge tells me how much support they will have.',
    'More diagnoses and medications usually mean a more complex recovery.',
    'Prior inpatient stays are my strongest signal — count them carefully!',
    'Mark every dose change: each one is something to get right at home.',
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _analyze(AssessmentState s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AnalyzingScreen(
        patient: Map<String, dynamic>.from(s.values),
        label: s.label.trim().isEmpty ? null : s.label.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssessmentCubit, AssessmentState>(
      listenWhen: (a, b) => a.step != b.step || a.status != b.status,
      listener: (context, s) {
        if (s.status == FormStatus.ready && !_sampleApplied && widget.sample != null) {
          _sampleApplied = true;
          final match = s.meta!.samples.where((x) => x.label == widget.sample);
          if (match.isNotEmpty) context.read<AssessmentCubit>().loadSample(match.first);
        }
        if (_pages.hasClients && _pages.page?.round() != s.step) {
          _pages.animateToPage(s.step,
              duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
        }
      },
      builder: (context, s) {
        return Scaffold(
          body: BlobBackground(
            opacity: 0.16,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _Header(step: s.step),
                  if (s.status == FormStatus.ready) ...[
                    _TeemoTip(
                      text: s.step == 0 && s.sampleLabel != null
                          ? 'Loaded the ${s.sampleLabel!.toLowerCase()}. Review the steps, '
                              'or tap Medication and analyze straight away!'
                          : _tips[s.step],
                      tipKey: '${s.step}-${s.sampleLabel}',
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (i) => context.read<AssessmentCubit>().goTo(i),
                        children: [
                          _PatientStep(s),
                          _StayStep(s),
                          _ClinicalStep(s),
                          _HistoryStep(s),
                          _MedicationStep(s),
                        ],
                      ),
                    ),
                    _BottomBar(state: s, onAnalyze: () => _analyze(s)),
                  ] else if (s.status == FormStatus.loading)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(child: _ErrorView(message: s.error ?? 'Something went wrong')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ chrome
class _Header extends StatelessWidget {
  const _Header({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const steps = AssessmentState.steps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              const Expanded(
                child: Text('New assessment',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: 'Reset form',
                onPressed: () => context.read<AssessmentCubit>().reset(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.read<AssessmentCubit>().goTo(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: i <= step ? AppColors.brandGradient : null,
                              color: i <= step ? null : AppColors.line,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == step ? FontWeight.w800 : FontWeight.w600,
                              color: i == step ? AppColors.tealDeep : AppColors.muted,
                              fontFamily: DefaultTextStyle.of(context).style.fontFamily,
                            ),
                            child: Text(steps[i]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeemoTip extends StatelessWidget {
  const _TeemoTip({required this.text, required this.tipKey});

  final String text;
  final String tipKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const AvatarFace(avatar: AvatarProfile.teemo, size: 44),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(
                    scale: Tween(begin: 0.92, end: 1.0).animate(a),
                    alignment: Alignment.bottomLeft,
                    child: c),
              ),
              child: Container(
                key: ValueKey(tipKey),
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.onAnalyze});

  final AssessmentState state;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final last = state.step == AssessmentState.steps.length - 1;
    final cubit = context.read<AssessmentCubit>();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppColors.softShadow(),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: state.step == 0
                ? const SizedBox(width: 0)
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Pressable(
                      onTap: cubit.back,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: last
                ? GradientButton(
                    label: 'Analyze with Teemo',
                    icon: Icons.auto_awesome_rounded,
                    gradient: AppColors.violetGradient,
                    onTap: onAnalyze,
                  )
                : GradientButton(label: 'Continue', onTap: cubit.next),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IconBadge(Icons.cloud_off_rounded, color: AppColors.coral, size: 84),
          const SizedBox(height: 18),
          const Text("Teemo can't reach the server",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 22),
          GradientButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onTap: () => context.read<AssessmentCubit>().load(),
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }
}

// ------------------------------------------------------------------- steps
/// Shared scaffold for a step: scrolling list with staggered entrance.
class _StepList extends StatelessWidget {
  const _StepList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: children
          .animate(interval: 60.ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.12, curve: Curves.easeOutCubic),
    );
  }
}

extension on AssessmentState {
  FieldSpec spec(String f) => meta!.fields[f]!;
  int intOf(String f) => (values[f] as num).toInt();
}

class _PatientStep extends StatelessWidget {
  const _PatientStep(this.s);

  final AssessmentState s;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AssessmentCubit>();
    return _StepList(children: [
      _SampleStrip(s),
      FieldCard(
        icon: Icons.badge_rounded,
        color: AppColors.indigo,
        title: 'Patient nickname',
        subtitle: 'Optional — helps you find it in history',
        child: _LabelField(initial: s.label, onChanged: c.setLabel),
      ),
      FieldCard(
        icon: Icons.cake_rounded,
        color: AppColors.pink,
        title: 'Age group',
        child: ChoiceChips(
          options: [...s.spec('age').options]
            ..sort((a, b) => '${a.value}'.compareTo('${b.value}')),
          value: s['age'],
          color: AppColors.pink,
          onChanged: (v) => c.set('age', v),
        ),
      ),
      FieldCard(
        icon: Icons.wc_rounded,
        color: AppColors.violet,
        title: 'Gender',
        child: SegmentedChoice(
          options: s.spec('gender').options,
          value: s['gender'],
          color: AppColors.violet,
          icons: s.spec('gender').options
              .map((o) => o.value == 'Female' ? Icons.female_rounded : Icons.male_rounded)
              .toList(),
          onChanged: (v) => c.set('gender', v),
        ),
      ),
      FieldCard(
        icon: Icons.diversity_3_rounded,
        color: AppColors.sky,
        title: 'Race (as recorded)',
        subtitle: 'Used only as recorded in the hospital data',
        child: ChoiceChips(
          options: s.spec('race').options,
          value: s['race'],
          color: AppColors.sky,
          onChanged: (v) => c.set('race', v),
        ),
      ),
    ]);
  }
}

class _LabelField extends StatefulWidget {
  const _LabelField({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_LabelField> createState() => _LabelFieldState();
}

class _LabelFieldState extends State<_LabelField> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(_LabelField old) {
    super.didUpdateWidget(old);
    if (widget.initial != _ctrl.text && widget.initial != old.initial) _ctrl.text = widget.initial;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'e.g. Room 214 · Mrs. K',
        prefixIcon: Icon(Icons.edit_rounded, size: 20),
      ),
    );
  }
}

class _SampleStrip extends StatelessWidget {
  const _SampleStrip(this.s);

  final AssessmentState s;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.green, AppColors.amber, AppColors.red];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFF0FDFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.indigo),
                SizedBox(width: 6),
                Text('Quick start with a real patient',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Anonymised encounters from the held-out test set',
                style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < s.meta!.samples.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _SampleChip(
                      sample: s.meta!.samples[i],
                      color: colors[i % colors.length],
                      selected: s.sampleLabel == s.meta!.samples[i].label,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({required this.sample, required this.color, required this.selected});

  final SamplePatient sample;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final short = sample.label.split(' ').first;
    return Pressable(
      onTap: () => context.read<AssessmentCubit>().loadSample(sample),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: selected ? AppColors.glow(color, strength: 0.3) : null,
        ),
        child: Column(
          children: [
            Icon(Icons.person_rounded, color: selected ? Colors.white : color),
            const SizedBox(height: 4),
            Text(short,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.ink)),
            Text('risk',
                style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _StayStep extends StatelessWidget {
  const _StayStep(this.s);

  final AssessmentState s;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AssessmentCubit>();
    final los = s.spec('time_in_hospital');
    return _StepList(children: [
      FieldCard(
        icon: Icons.local_hospital_rounded,
        color: AppColors.coral,
        title: 'Admission type',
        child: ChoiceChips(
          options: s.spec('admission_type_id').options,
          value: s['admission_type_id'],
          color: AppColors.coral,
          onChanged: (v) => c.set('admission_type_id', v),
        ),
      ),
      FieldCard(
        icon: Icons.login_rounded,
        color: AppColors.blue,
        title: 'Admitted from',
        child: PickerField(
          title: 'Admitted from',
          spec: s.spec('admission_source_id'),
          value: s['admission_source_id'],
          color: AppColors.blue,
          onChanged: (v) => c.set('admission_source_id', v),
        ),
      ),
      FieldCard(
        icon: Icons.medical_services_rounded,
        color: AppColors.violet,
        title: 'Admitting specialty',
        child: PickerField(
          title: 'Admitting specialty',
          spec: s.spec('medical_specialty'),
          value: s['medical_specialty'],
          color: AppColors.violet,
          onChanged: (v) => c.set('medical_specialty', v),
        ),
      ),
      FieldCard(
        icon: Icons.bed_rounded,
        color: AppColors.teal,
        title: 'Length of stay',
        child: SliderField(
          value: s.intOf('time_in_hospital'),
          min: los.min ?? 1,
          max: los.max ?? 14,
          unit: 'days',
          onChanged: (v) => c.set('time_in_hospital', v),
        ),
      ),
      FieldCard(
        icon: Icons.home_rounded,
        color: AppColors.green,
        title: 'Discharge destination',
        subtitle: 'Where the patient goes next',
        child: PickerField(
          title: 'Discharge destination',
          spec: s.spec('discharge_disposition_id'),
          value: s['discharge_disposition_id'],
          color: AppColors.green,
          onChanged: (v) => c.set('discharge_disposition_id', v),
        ),
      ),
      FieldCard(
        icon: Icons.shield_rounded,
        color: AppColors.amber,
        title: 'Insurance',
        child: PickerField(
          title: 'Insurance',
          spec: s.spec('payer_code'),
          value: s['payer_code'],
          color: AppColors.amber,
          onChanged: (v) => c.set('payer_code', v),
        ),
      ),
    ]);
  }
}

class _ClinicalStep extends StatelessWidget {
  const _ClinicalStep(this.s);

  final AssessmentState s;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AssessmentCubit>();
    final labs = s.spec('num_lab_procedures');
    final meds = s.spec('num_medications');
    return _StepList(children: [
      FieldCard(
        icon: Icons.monitor_heart_rounded,
        color: AppColors.red,
        title: 'Primary diagnosis',
        subtitle: 'ICD-9 family of the main diagnosis',
        child: ChoiceChips(
          options: s.spec('diag_1_group').options,
          value: s['diag_1_group'],
          color: AppColors.red,
          icons: diagnosisIcon,
          onChanged: (v) => c.set('diag_1_group', v),
        ),
      ),
      FieldCard(
        icon: Icons.playlist_add_check_rounded,
        color: AppColors.indigo,
        title: 'Secondary & additional diagnoses',
        child: Column(
          children: [
            PickerField(
              title: 'Secondary diagnosis',
              spec: s.spec('diag_2_group'),
              value: s['diag_2_group'],
              color: AppColors.indigo,
              onChanged: (v) => c.set('diag_2_group', v),
            ),
            const SizedBox(height: 10),
            PickerField(
              title: 'Additional diagnosis',
              spec: s.spec('diag_3_group'),
              value: s['diag_3_group'],
              color: AppColors.indigo,
              onChanged: (v) => c.set('diag_3_group', v),
            ),
          ],
        ),
      ),
      FieldCard(
        icon: Icons.format_list_numbered_rounded,
        color: AppColors.violet,
        title: 'Number of diagnoses',
        child: CounterField(
          value: s.intOf('number_diagnoses'),
          min: 1,
          max: 16,
          unit: 'conditions recorded',
          color: AppColors.violet,
          onChanged: (v) => c.set('number_diagnoses', v),
        ),
      ),
      FieldCard(
        icon: Icons.science_rounded,
        color: AppColors.sky,
        title: 'Lab tests during the stay',
        child: SliderField(
          value: s.intOf('num_lab_procedures'),
          min: labs.min ?? 1,
          max: labs.max ?? 130,
          unit: 'tests',
          color: AppColors.sky,
          onChanged: (v) => c.set('num_lab_procedures', v),
        ),
      ),
      FieldCard(
        icon: Icons.healing_rounded,
        color: AppColors.pink,
        title: 'Procedures (non-lab)',
        child: CounterField(
          value: s.intOf('num_procedures'),
          min: 0,
          max: 6,
          unit: 'procedures',
          color: AppColors.pink,
          onChanged: (v) => c.set('num_procedures', v),
        ),
      ),
      FieldCard(
        icon: Icons.medication_rounded,
        color: AppColors.teal,
        title: 'Medications administered',
        child: SliderField(
          value: s.intOf('num_medications'),
          min: meds.min ?? 1,
          max: meds.max ?? 80,
          unit: 'medications',
          onChanged: (v) => c.set('num_medications', v),
        ),
      ),
    ]);
  }
}

class _HistoryStep extends StatelessWidget {
  const _HistoryStep(this.s);

  final AssessmentState s;

  @override
  Widget build(BuildContext context) {
    final c = context.read<AssessmentCubit>();
    Widget counter(String f, String title, String unit, IconData icon, Color color, int max) =>
        FieldCard(
          icon: icon,
          color: color,
          title: title,
          subtitle: 'In the year before this admission',
          child: CounterField(
            value: s.intOf(f),
            max: max,
            unit: unit,
            color: color,
            onChanged: (v) => c.set(f, v),
          ),
        );
    return _StepList(children: [
      counter('number_inpatient', 'Inpatient stays', 'previous admissions',
          Icons.king_bed_rounded, AppColors.red, 21),
      counter('number_emergency', 'Emergency visits', 'ER visits',
          Icons.emergency_rounded, AppColors.amber, 76),
      counter('number_outpatient', 'Outpatient visits', 'clinic visits',
          Icons.event_available_rounded, AppColors.blue, 42),
      FieldCard(
        icon: Icons.bloodtype_rounded,
        color: AppColors.violet,
        title: 'HbA1c result',
        subtitle: '3-month blood-sugar control',
        child: SegmentedChoice(
          options: _short(s.spec('A1Cresult').options, const {
            'Not_Tested': 'Not tested', 'Norm': 'Normal', '>7': '> 7%', '>8': '> 8%'
          }),
          value: s['A1Cresult'],
          color: AppColors.violet,
          onChanged: (v) => c.set('A1Cresult', v),
        ),
      ),
      FieldCard(
        icon: Icons.water_drop_rounded,
        color: AppColors.coral,
        title: 'Max glucose serum',
        subtitle: 'Highest value during the stay (mg/dL)',
        child: SegmentedChoice(
          options: _short(s.spec('max_glu_serum').options, const {
            'Not_Tested': 'Not tested', 'Norm': 'Normal', '>200': '> 200', '>300': '> 300'
          }),
          value: s['max_glu_serum'],
          color: AppColors.coral,
          onChanged: (v) => c.set('max_glu_serum', v),
        ),
      ),
    ]);
  }
}

/// Shorter labels for segmented controls, in a fixed clinical order.
List<FieldOption> _short(List<FieldOption> opts, Map<String, String> labels) => [
      for (final e in labels.entries)
        if (opts.any((o) => o.value == e.key)) FieldOption(e.key, e.value),
    ];

const _medOrder = {'No': 'None', 'Steady': 'Steady', 'Up': 'Up', 'Down': 'Down'};
const _medIcons = [
  Icons.block_rounded,
  Icons.horizontal_rule_rounded,
  Icons.north_rounded,
  Icons.south_rounded,
];

class _MedicationStep extends StatelessWidget {
  const _MedicationStep(this.s);

  final AssessmentState s;

  static const _others = [
    'glipizide', 'glyburide', 'glimepiride', 'pioglitazone', 'rosiglitazone',
    'repaglinide', 'nateglinide', 'glipizide-metformin',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.read<AssessmentCubit>();
    final onAny = [..._others, 'insulin', 'metformin'].any((m) => s[m] != 'No');
    Widget med(String f, String title, IconData icon, Color color, {String? sub}) => FieldCard(
          icon: icon,
          color: color,
          title: title,
          subtitle: sub,
          child: SegmentedChoice(
            options: _short(s.spec(f).options, _medOrder),
            value: s[f],
            color: color,
            icons: s.spec(f).options.length == _medOrder.length ? _medIcons : null,
            onChanged: (v) => c.set(f, v),
          ),
        );
    return _StepList(children: [
      med('insulin', 'Insulin', Icons.vaccines_rounded, AppColors.violet,
          sub: 'Status at discharge'),
      med('metformin', 'Metformin', Icons.medication_liquid_rounded, AppColors.teal,
          sub: 'First-line oral agent'),
      FieldCard(
        icon: Icons.medication_rounded,
        color: AppColors.blue,
        title: 'Other oral agents',
        subtitle: 'Tap a status for each medication',
        child: Column(
          children: [
            for (final m in _others)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(m[0].toUpperCase() + m.substring(1),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                    Expanded(
                      child: SegmentedChoice(
                        height: 38,
                        options: _short(s.spec(m).options, _medOrder),
                        value: s[m],
                        color: AppColors.blue,
                        onChanged: (v) => c.set(m, v),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      SoftCard(
        padding: const EdgeInsets.all(14),
        color: (onAny ? AppColors.teal : AppColors.muted).withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(onAny ? Icons.check_circle_rounded : Icons.info_rounded,
                color: onAny ? AppColors.teal : AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                onAny
                    ? 'Diabetes medication: yes — derived automatically from your choices.'
                    : 'No diabetes medication selected.',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
