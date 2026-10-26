import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../avatar/avatar_patient_profile_screen.dart';
import '../../avatar/avatar_profile.dart';

/// Ce que Sora raconte quand le patient veut faire sa connaissance.
/// Aucun chiffre, aucun résultat de modèle — seulement des mots rassurants.
const soraIntro = [
  SpeechSegment('greeting',
      "Bonjour, je suis Sora, l'assistante de suivi de votre équipe soignante."),
  SpeechSegment('action',
      'Avant votre sortie, votre médecin remplit une fiche sur votre séjour.'),
  SpeechSegment('comparison',
      "J'aide votre médecin à prévoir le bon rythme de suivi et, si besoin, un accompagnement sur l'alimentation et l'activité physique."),
  SpeechSegment('action', "C'est toujours votre médecin qui décide."),
  SpeechSegment('action',
      'Il vous enverra un message dans l\'application pour vous expliquer la suite.'),
  SpeechSegment('closing',
      'Prenez soin de vous. Votre équipe soignante reste à vos côtés.'),
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
      subtitle: 'Suivi de sortie · by Fatma',
      title: 'Sora',
      intro: soraIntro,
      steps: [
        (Icons.edit_note_rounded, 'Le médecin remplit votre fiche de sortie',
            'Pendant votre séjour, sur votre hospitalisation et vos traitements.', AppColors.blue),
        (Icons.insights_rounded, "J'aide votre médecin à organiser votre suivi",
            'Le bon rythme de suivi et, si besoin, un accompagnement.', AppColors.amber),
        (Icons.mark_email_read_rounded, 'Le médecin vous écrit si besoin',
            'Vous recevez un message bienveillant dans « Mes messages ».', AppColors.teal),
      ],
    );
  }
}
