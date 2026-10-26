import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../avatar/avatar_patient_profile_screen.dart';
import '../../avatar/avatar_profile.dart';

/// Ce que Sora raconte quand le patient veut faire sa connaissance.
/// Aucun chiffre, aucun résultat de modèle — seulement des mots rassurants.
const soraIntro = [
  SpeechSegment('greeting',
      "Hello, I'm Sora, your care team's follow-up assistant."),
  SpeechSegment('action',
      'Before you go home, your doctor fills in a form about your stay.'),
  SpeechSegment('comparison',
      "I help your doctor plan the right follow-up pace and, if needed, support with diet and physical activity."),
  SpeechSegment('action', "Your doctor always makes the decision."),
  SpeechSegment('action',
      "They'll send you a message in the app to explain what comes next."),
  SpeechSegment('closing',
      'Take care of yourself. Your care team stays by your side.'),
];

/// Écran patient de Sora — l'écran générique [AvatarPatientProfileScreen] en
/// ambre, sans aucun résultat de modèle, avec le seul bouton « Hear me » et un
/// « Comment je fonctionne » simple.
class SoraPatientProfileScreen extends StatelessWidget {
  const SoraPatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AvatarPatientProfileScreen(
      avatar: AvatarProfile.sora,
      module: 'sora',
      headerGradient: LinearGradient(
        colors: [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFFB923C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      blobColors: [AppColors.amber, Color(0xFFFB923C), Color(0xFFFCD34D)],
      brandLabel: 'SORA AI',
      brandDot: Color(0xFFFDE68A),
      subtitle: 'Discharge follow-up · by Fatma',
      title: 'Sora',
      intro: soraIntro,
      steps: [
        (Icons.edit_note_rounded, 'The doctor fills in your discharge form',
            'During your stay, about your hospitalization and treatments.', AppColors.blue),
        (Icons.insights_rounded, 'I help your doctor organize your follow-up',
            'The right follow-up pace and, if needed, extra support.', AppColors.amber),
        (Icons.mark_email_read_rounded, 'The doctor writes to you if needed',
            'You get a kind message in “Your messages”.', AppColors.teal),
      ],
    );
  }
}
