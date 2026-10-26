import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../avatar/avatar_patient_profile_screen.dart';
import '../../avatar/avatar_profile.dart';

/// Ce que Doza raconte quand le patient veut faire sa connaissance.
/// Aucun chiffre, aucun résultat de modèle — seulement des mots rassurants.
const dozaIntro = [
  SpeechSegment('greeting',
      "Hello, I'm Doza, your care team's insulin assistant."),
  SpeechSegment('action',
      'During your stay, your doctor answers a few questions about your health and your treatment.'),
  SpeechSegment('comparison',
      "From those answers, I help your doctor anticipate whether your insulin dose should be adjusted."),
  SpeechSegment('action',
      "Your doctor always makes the decision. I simply help them prepare your follow-up."),
  SpeechSegment('action',
      'If anything needs to change, your doctor will send you a message in the app.'),
  SpeechSegment('closing',
      'Take care of yourself. Your care team is looking out for you.'),
];

/// Écran patient de Doza — l'écran générique [AvatarPatientProfileScreen] en
/// corail, sans aucun résultat de modèle et avec le seul bouton « Hear me ».
class DozaPatientProfileScreen extends StatelessWidget {
  const DozaPatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AvatarPatientProfileScreen(
      avatar: AvatarProfile.doza,
      module: 'doza',
      headerGradient: LinearGradient(
        colors: [Color(0xFFFDA4AF), Color(0xFFFB7185), Color(0xFFF472B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      blobColors: [AppColors.coral, AppColors.pink, AppColors.amber],
      brandLabel: 'DOZA AI',
      brandDot: Color(0xFFFECDD3),
      subtitle: 'Insulin assistant · by Emna',
      title: 'Doza',
      intro: dozaIntro,
      steps: [
        (Icons.edit_note_rounded, 'The doctor answers a few questions',
            'About your health and treatment, during your stay.', AppColors.blue),
        (Icons.insights_rounded, 'I help the doctor anticipate',
            'A possible adjustment to your insulin dose.', AppColors.coral),
        (Icons.mark_email_read_rounded, 'The doctor writes to you if needed',
            'You get a kind message in “Your messages”.', AppColors.teal),
      ],
      notes: [
        (Icons.verified_user_rounded,
            'Your doctor always makes the decision. Doza only helps them prepare your follow-up.'),
        (Icons.lock_person_rounded,
            'Your analyses stay with your doctor; you only see their messages.'),
        (Icons.spa_rounded, 'Doza is here to reassure you, never to worry you.'),
      ],
    );
  }
}
