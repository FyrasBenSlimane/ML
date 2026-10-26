import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ambient.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../avatar/widgets/avatar_face.dart';
import '../../teemo/data/teemo_models.dart';
import '../../teemo/widgets/form_fields.dart';
import 'doza_analyzing_screen.dart';

/// Doza's questionnaire — 12 questions phrased FOR THE DOCTOR, about "the
/// patient". The labels are French; the CODES sent to the API are the ones the
/// model expects (predict.py converts them). Population: patients already on
/// insulin.
class DozaQuestionnaireScreen extends StatefulWidget {
  const DozaQuestionnaireScreen({super.key});

  @override
  State<DozaQuestionnaireScreen> createState() => _DozaQuestionnaireScreenState();
}

class _DozaQuestionnaireScreenState extends State<DozaQuestionnaireScreen> {
  // Starting answers = the model's own defaults, expressed as questionnaire codes.
  static const _initial = <String, Object>{
    'gender': 1,
    'age_ordinal': 6,
    'admission_type_id': 0,
    'admission_source_id': 'jnsp',
    'medical_specialty': 'Unknown',
    'diag_1_group': 'Diabetes',
    'A1Cresult': 0,
    'num_medications': 13,
    'sulfonylurea': 0,
    'number_inpatient': 0,
    'number_emergency': 0,
    'number_outpatient': 0,
  };

  late Map<String, Object> _a = Map.of(_initial);

  void _set(String k, Object v) => setState(() => _a[k] = v);

  static const _specialty = FieldSpec(type: 'choice', defaultValue: 'Unknown', options: [
    FieldOption('InternalMedicine', 'Médecine interne'),
    FieldOption('Emergency/Trauma', 'Urgences'),
    FieldOption('Family/GeneralPractice', 'Médecine générale'),
    FieldOption('Cardiology', 'Cardiologie'),
    FieldOption('Other', 'Autre service'),
    FieldOption('Unknown', 'Inconnu'),
  ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        colors: const [AppColors.coral, AppColors.pink, AppColors.amber],
        opacity: 0.16,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(context),
              const _Tip(
                  'Décrivez le patient (déjà sous insuline). J\'estime si sa dose va changer '
                  'pendant le séjour. Les questions sont formulées pour vous, médecin.'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    const SectionHeader('Patient & admission', icon: Icons.badge_rounded),
                    FieldCard(
                      icon: Icons.wc_rounded,
                      color: AppColors.violet,
                      title: 'Sexe du patient',
                      child: SegmentedChoice(
                        options: const [FieldOption(1, 'Homme'), FieldOption(0, 'Femme')],
                        value: _a['gender'],
                        color: AppColors.violet,
                        icons: const [Icons.male_rounded, Icons.female_rounded],
                        onChanged: (v) => _set('gender', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.cake_rounded,
                      color: AppColors.pink,
                      title: 'Tranche d\'âge',
                      child: ChoiceChips(
                        options: const [
                          FieldOption(3, '18–39'), FieldOption(4, '40–49'),
                          FieldOption(5, '50–59'), FieldOption(6, '60–69'),
                          FieldOption(7, '70–79'), FieldOption(8, '80+'),
                        ],
                        value: _a['age_ordinal'],
                        color: AppColors.pink,
                        onChanged: (v) => _set('age_ordinal', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.local_hospital_rounded,
                      color: AppColors.coral,
                      title: 'Type d\'admission',
                      child: ChoiceChips(
                        options: const [
                          FieldOption(1, 'Urgence'), FieldOption(2, 'Urgente'),
                          FieldOption(3, 'Programmée'), FieldOption(0, 'Je ne sais pas'),
                        ],
                        value: _a['admission_type_id'],
                        color: AppColors.coral,
                        onChanged: (v) => _set('admission_type_id', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.login_rounded,
                      color: AppColors.blue,
                      title: 'Provenance',
                      subtitle: 'D\'où arrive le patient',
                      child: ChoiceChips(
                        options: const [
                          FieldOption(7, 'Urgences'), FieldOption(1, 'Médecin'),
                          FieldOption(6, 'Transfert'), FieldOption(0, 'Autre'),
                          FieldOption('jnsp', 'Je ne sais pas'),
                        ],
                        value: _a['admission_source_id'],
                        color: AppColors.blue,
                        onChanged: (v) => _set('admission_source_id', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.medical_services_rounded,
                      color: AppColors.indigo,
                      title: 'Service',
                      child: PickerField(
                        title: 'Service',
                        spec: _specialty,
                        value: _a['medical_specialty'],
                        color: AppColors.indigo,
                        onChanged: (v) => _set('medical_specialty', v),
                      ),
                    ),
                    const SectionHeader('Clinique', icon: Icons.monitor_heart_rounded),
                    FieldCard(
                      icon: Icons.monitor_heart_rounded,
                      color: AppColors.red,
                      title: 'Motif principal d\'hospitalisation',
                      child: ChoiceChips(
                        options: const [
                          FieldOption('Diabetes', 'Diabète'),
                          FieldOption('Circulatory', 'Cœur / vaisseaux'),
                          FieldOption('Respiratory', 'Poumons'),
                          FieldOption('Digestive', 'Digestif'),
                          FieldOption('Genitourinary', 'Reins'),
                          FieldOption('Musculoskeletal', 'Articulations'),
                          FieldOption('Injury', 'Blessure'),
                          FieldOption('Neoplasms', 'Cancer'),
                          FieldOption('Other', 'Autre'),
                        ],
                        value: _a['diag_1_group'],
                        color: AppColors.red,
                        icons: diagnosisIcon,
                        onChanged: (v) => _set('diag_1_group', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.bloodtype_rounded,
                      color: AppColors.violet,
                      title: 'HbA1c',
                      subtitle: 'Contrôle glycémique des 3 derniers mois',
                      child: SegmentedChoice(
                        options: const [
                          FieldOption(1, '< 7 %'), FieldOption(2, '7–8 %'),
                          FieldOption(3, '> 8 %'), FieldOption(0, 'Inconnue'),
                        ],
                        value: _a['A1Cresult'],
                        color: AppColors.violet,
                        onChanged: (v) => _set('A1Cresult', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.medication_rounded,
                      color: AppColors.teal,
                      title: 'Nombre de médicaments',
                      child: ChoiceChips(
                        options: const [
                          FieldOption(3, '1–5'), FieldOption(8, '6–10'),
                          FieldOption(13, '11–15'), FieldOption(18, '16–20'),
                          FieldOption(25, '> 20'),
                        ],
                        value: _a['num_medications'],
                        color: AppColors.teal,
                        onChanged: (v) => _set('num_medications', v),
                      ),
                    ),
                    FieldCard(
                      icon: Icons.science_rounded,
                      color: AppColors.amber,
                      title: 'Sulfamide hypoglycémiant prescrit ?',
                      child: SegmentedChoice(
                        options: const [FieldOption(0, 'Non'), FieldOption(1, 'Oui')],
                        value: _a['sulfonylurea'],
                        color: AppColors.amber,
                        onChanged: (v) => _set('sulfonylurea', v),
                      ),
                    ),
                    const SectionHeader('Antécédents (année précédente)',
                        icon: Icons.history_rounded),
                    _counter('number_inpatient', 'Hospitalisations', 'admissions',
                        Icons.king_bed_rounded, AppColors.red),
                    _counter('number_emergency', 'Passages aux urgences', 'passages',
                        Icons.emergency_rounded, AppColors.amber),
                    _counter('number_outpatient', 'Consultations externes', 'consultations',
                        Icons.event_available_rounded, AppColors.blue),
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

  Widget _counter(String f, String title, String unit, IconData icon, Color color) => FieldCard(
        icon: icon,
        color: color,
        title: title,
        child: CounterField(
          value: (_a[f] as num).toInt(),
          max: 9,
          unit: unit,
          color: color,
          onChanged: (v) => _set(f, v),
        ),
      );

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            ),
            const Expanded(
              child: Text('Doza · nouvelle évaluation',
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
          label: 'Analyser avec Doza',
          icon: Icons.auto_awesome_rounded,
          gradient: AppColors.coralGradient,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DozaAnalyzingScreen(answers: Map.of(_a)),
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
          const AvatarFace(avatar: AvatarProfile.doza, size: 44),
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
