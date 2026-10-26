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

/// Sora's clinical form — phrased FOR THE DOCTOR (French labels). The VALUES
/// sent to the two models stay in English (Circulatory, Up, Not_Tested…), never
/// translated. Builds a discharge profile: follow-up intensity × diabetes control.
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
    FieldOption('[20-30]', '20 – 29 ans'),
    FieldOption('[30-40]', '30 – 39 ans'),
    FieldOption('[40-50]', '40 – 49 ans'),
    FieldOption('[50-60]', '50 – 59 ans'),
    FieldOption('[60-70]', '60 – 69 ans'),
    FieldOption('[70-80]', '70 – 79 ans'),
    FieldOption('[80-90]', '80 – 89 ans'),
    FieldOption('[90-100]', '90 ans et +'),
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
                  'Renseignez le séjour du patient. Je combine deux modèles — intensité du '
                  'suivi et contrôle du diabète — pour un profil de sortie, destiné au médecin.'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    const SectionHeader('Séjour', icon: Icons.local_hospital_rounded),
                    FieldCard(
                      icon: Icons.cake_rounded,
                      color: AppColors.pink,
                      title: 'Tranche d\'âge',
                      child: PickerField(
                        title: 'Tranche d\'âge',
                        spec: _ageSpec,
                        value: _a['age'],
                        color: AppColors.pink,
                        onChanged: (v) => _set('age', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.bed_rounded,
                      color: AppColors.teal,
                      title: 'Durée d\'hospitalisation',
                      child: SliderField(
                        value: (_a['hosp_days'] as num).toInt(),
                        min: 1,
                        max: 14,
                        unit: 'jours',
                        onChanged: (v) => _set('hosp_days', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.medication_rounded,
                      color: AppColors.coral,
                      title: 'Nombre de médicaments',
                      child: SliderField(
                        value: (_a['medications'] as num).toInt(),
                        min: 1,
                        max: 81,
                        unit: 'médicaments',
                        color: AppColors.coral,
                        onChanged: (v) => _set('medications', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.format_list_numbered_rounded,
                      color: AppColors.violet,
                      title: 'Nombre de diagnostics',
                      child: CounterField(
                        value: (_a['diagnostics'] as num).toInt(),
                        min: 1,
                        max: 16,
                        unit: 'diagnostics',
                        color: AppColors.violet,
                        onChanged: (v) => _set('diagnostics', v),
                      ),
                    ),
                    const SectionHeader('Clinique', icon: Icons.monitor_heart_rounded),
                    FieldCard(
                      icon: Icons.monitor_heart_rounded,
                      color: AppColors.red,
                      title: 'Motif principal d\'hospitalisation',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Circulatory', 'Cœur / vaisseaux'),
                          FieldOption('Diabetes', 'Diabète'),
                          FieldOption('Respiratory', 'Poumons'),
                          FieldOption('Digestive', 'Digestif'),
                          FieldOption('Injury', 'Blessure'),
                          FieldOption('Musculoskeletal', 'Articulations'),
                          FieldOption('Genitourinary', 'Reins'),
                          FieldOption('Neoplasms', 'Cancer'),
                          FieldOption('External', 'Cause externe'),
                          FieldOption('Other', 'Autre'),
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
                      title: 'Glycémie max (sérum)',
                      subtitle: 'Plus haute valeur pendant le séjour',
                      child: SegmentedChoice(
                        options: const [
                          FieldOption('Not_Tested', 'Non testée'),
                          FieldOption('Norm', 'Normale'),
                          FieldOption('>200', '> 200'),
                          FieldOption('>300', '> 300'),
                        ],
                        value: _a['glucose'],
                        color: AppColors.sky,
                        onChanged: (v) => _set('glucose', v),
                      ),
                    ),
                    const SectionHeader('Traitements', icon: Icons.vaccines_rounded),
                    FieldCard(
                      icon: Icons.medical_information_rounded,
                      color: AppColors.indigo,
                      title: 'Traitement antidiabétique',
                      child: SegmentedChoice(
                        options: const [FieldOption('Oui', 'Oui'), FieldOption('Non', 'Non')],
                        value: _a['antidiabetic'],
                        color: AppColors.indigo,
                        onChanged: (v) => _set('antidiabetic', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.vaccines_rounded,
                      color: AppColors.violet,
                      title: 'Insuline',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Oui', 'Prescrite'),
                          FieldOption('Non', 'Non prescrite'),
                          FieldOption('Up', 'Augmentée'),
                          FieldOption('Down', 'Diminuée'),
                        ],
                        value: _a['insulin'],
                        color: AppColors.violet,
                        onChanged: (v) => _set('insulin', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.medication_liquid_rounded,
                      color: AppColors.teal,
                      title: 'Metformine',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Oui', 'Prescrite'),
                          FieldOption('Non', 'Non prescrite'),
                          FieldOption('Steady', 'Inchangée'),
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
              child: Text('Sora · profil de sortie',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'Réinitialiser',
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
          label: 'Obtenir le profil',
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
