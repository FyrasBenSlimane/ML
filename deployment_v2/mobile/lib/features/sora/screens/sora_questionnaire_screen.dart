import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/widgets/avatar_face.dart';
import '../../teemo/data/teemo_models.dart';
import '../../teemo/widgets/form_fields.dart';
import 'sora_analyzing_screen.dart';

/// Sora's clinical form — phrased FOR THE DOCTOR. The VALUES sent to the two
/// models stay as the model expects them (Circulatory, Up, Not_Tested, Oui…),
/// never translated. Builds a discharge profile: follow-up × diabetes control.
class SoraQuestionnaireScreen extends StatefulWidget {
  const SoraQuestionnaireScreen({super.key});

  @override
  State<SoraQuestionnaireScreen> createState() => _SoraQuestionnaireScreenState();
}

class _SoraQuestionnaireScreenState extends State<SoraQuestionnaireScreen> {
  static const _initial = <String, Object>{
    'age': '[60-70]',
    'hosp_days': 4,
    'medications': 13,
    'diagnostics': 7,
    'diagnosis': 'Circulatory',
    'glucose': 'Not_Tested',
    'antidiabetic': 'Oui',
    'insulin': 'Non',
    'metformin': 'Non',
  };

  late Map<String, Object> _a = Map.of(_initial);

  void _set(String k, Object v) => setState(() => _a[k] = v);

  static const _ageSpec = FieldSpec(type: 'choice', defaultValue: '[60-70]', options: [
    FieldOption('[20-30]', '20 – 29 yrs'),
    FieldOption('[30-40]', '30 – 39 yrs'),
    FieldOption('[40-50]', '40 – 49 yrs'),
    FieldOption('[50-60]', '50 – 59 yrs'),
    FieldOption('[60-70]', '60 – 69 yrs'),
    FieldOption('[70-80]', '70 – 79 yrs'),
    FieldOption('[80-90]', '80 – 89 yrs'),
    FieldOption('[90-100]', '90+ yrs'),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.amber, AppColors.coral, AppColors.teal],
        opacity: 0.16,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              const _Tip(
                  "Fill in the patient's stay. I combine two models — follow-up "
                  'intensity and diabetes control — into a discharge profile, for the doctor.'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    const SectionHeader('Stay', icon: Icons.local_hospital_rounded),
                    FieldCard(
                      icon: Icons.cake_rounded,
                      color: AppColors.pink,
                      title: 'Age range',
                      child: PickerField(
                        title: 'Age range',
                        spec: _ageSpec,
                        value: _a['age'],
                        color: AppColors.pink,
                        onChanged: (v) => _set('age', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.bed_rounded,
                      color: AppColors.teal,
                      title: 'Length of stay',
                      child: SliderField(
                        value: (_a['hosp_days'] as num).toInt(),
                        min: 1,
                        max: 14,
                        unit: 'days',
                        onChanged: (v) => _set('hosp_days', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.medication_rounded,
                      color: AppColors.coral,
                      title: 'Number of medications',
                      child: SliderField(
                        value: (_a['medications'] as num).toInt(),
                        min: 1,
                        max: 81,
                        unit: 'medications',
                        color: AppColors.coral,
                        onChanged: (v) => _set('medications', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.format_list_numbered_rounded,
                      color: AppColors.violet,
                      title: 'Number of diagnoses',
                      child: CounterField(
                        value: (_a['diagnostics'] as num).toInt(),
                        min: 1,
                        max: 16,
                        unit: 'diagnoses',
                        color: AppColors.violet,
                        onChanged: (v) => _set('diagnostics', v),
                      ),
                    ),
                    const SectionHeader('Clinical', icon: Icons.monitor_heart_rounded),
                    FieldCard(
                      icon: Icons.monitor_heart_rounded,
                      color: AppColors.red,
                      title: 'Main reason for admission',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Circulatory', 'Heart / vessels'),
                          FieldOption('Diabetes', 'Diabetes'),
                          FieldOption('Respiratory', 'Lungs'),
                          FieldOption('Digestive', 'Digestive'),
                          FieldOption('Injury', 'Injury'),
                          FieldOption('Musculoskeletal', 'Joints'),
                          FieldOption('Genitourinary', 'Kidneys'),
                          FieldOption('Neoplasms', 'Cancer'),
                          FieldOption('External', 'External cause'),
                          FieldOption('Other', 'Other'),
                        ],
                        value: _a['diagnosis'],
                        color: AppColors.red,
                        icons: diagnosisIcon,
                        onChanged: (v) => _set('diagnosis', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.water_drop_rounded,
                      color: AppColors.sky,
                      title: 'Max glucose (serum)',
                      subtitle: 'Highest value during the stay',
                      child: SegmentedChoice(
                        options: const [
                          FieldOption('Not_Tested', 'Not tested'),
                          FieldOption('Norm', 'Normal'),
                          FieldOption('>200', '> 200'),
                          FieldOption('>300', '> 300'),
                        ],
                        value: _a['glucose'],
                        color: AppColors.sky,
                        onChanged: (v) => _set('glucose', v),
                      ),
                    ),
                    const SectionHeader('Treatments', icon: Icons.vaccines_rounded),
                    FieldCard(
                      icon: Icons.medical_information_rounded,
                      color: AppColors.indigo,
                      title: 'Antidiabetic treatment',
                      child: SegmentedChoice(
                        options: const [FieldOption('Oui', 'Yes'), FieldOption('Non', 'No')],
                        value: _a['antidiabetic'],
                        color: AppColors.indigo,
                        onChanged: (v) => _set('antidiabetic', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.vaccines_rounded,
                      color: AppColors.violet,
                      title: 'Insulin',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Oui', 'Prescribed'),
                          FieldOption('Non', 'Not prescribed'),
                          FieldOption('Up', 'Increased'),
                          FieldOption('Down', 'Decreased'),
                        ],
                        value: _a['insulin'],
                        color: AppColors.violet,
                        onChanged: (v) => _set('insulin', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.medication_liquid_rounded,
                      color: AppColors.teal,
                      title: 'Metformin',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Oui', 'Prescribed'),
                          FieldOption('Non', 'Not prescribed'),
                          FieldOption('Steady', 'Unchanged'),
                        ],
                        value: _a['metformin'],
                        color: AppColors.teal,
                        onChanged: (v) => _set('metformin', v),
                      ),
                    ),
                  ].animate(interval: 40.ms).fadeIn(duration: 300.ms).slideY(begin: 0.08),
                ),
              ),
              _bottomBar(context),
            ],
          ),
        ),
      ),
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
              child: Text('Sora · discharge profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'Reset',
              onPressed: () => setState(() => _a = Map.of(_initial)),
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
          label: 'Get the profile',
          icon: Icons.auto_awesome_rounded,
          gradient: AppColors.amberGradient,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SoraAnalyzingScreen(fiche: Map.of(_a)),
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
          const AvatarFace(avatar: AvatarProfile.sora, size: 44),
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
