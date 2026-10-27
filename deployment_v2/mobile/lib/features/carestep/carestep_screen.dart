import 'package:flutter/material.dart';

import 'screens/carestep_questionnaire_screen.dart';

/// Entry point of Fyras's CareStep module (wrapped in PatientGate by the
/// module registry): the 12-question form, then analysis, then the result.
class CareStepScreen extends StatelessWidget {
  const CareStepScreen({super.key});

  @override
  Widget build(BuildContext context) => const CareStepQuestionnaireScreen();
}
