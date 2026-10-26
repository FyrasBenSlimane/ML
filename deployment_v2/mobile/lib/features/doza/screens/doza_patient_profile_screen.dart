import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../avatar/avatar_patient_profile_screen.dart';
import '../../avatar/avatar_profile.dart';

/// Ce que Doza raconte quand le patient veut faire sa connaissance.
/// Aucun chiffre, aucun résultat de modèle — seulement des mots rassurants.
const dozaIntro = [
  SpeechSegment('greeting',
      "Bonjour, je suis Doza, l'assistante insuline de votre équipe soignante."),
  SpeechSegment('action',
      'Pendant votre séjour, votre médecin répond à quelques questions sur votre santé et votre traitement.'),
  SpeechSegment('comparison',
      "Grâce à ces réponses, j'aide votre médecin à anticiper si votre dose d'insuline doit être adaptée."),
  SpeechSegment('action',
      "C'est toujours votre médecin qui décide. Moi, je l'aide simplement à préparer votre suivi."),
  SpeechSegment('action',
      'Si quelque chose doit changer, votre médecin vous enverra un message dans l\'application.'),
  SpeechSegment('closing',
      'Prenez soin de vous. Votre équipe soignante veille sur vous.'),
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
      subtitle: 'Assistant insuline · by Emna',
      title: 'Doza',
      intro: dozaIntro,
      steps: [
        (Icons.edit_note_rounded, 'Le médecin répond à quelques questions',
            'Sur votre santé et votre traitement, pendant votre séjour.', AppColors.blue),
        (Icons.insights_rounded, "J'aide le médecin à anticiper",
            "Un éventuel ajustement de votre dose d'insuline.", AppColors.coral),
        (Icons.mark_email_read_rounded, 'Le médecin vous écrit si besoin',
            'Vous recevez un message bienveillant dans « Mes messages ».', AppColors.teal),
      ],
      notes: [
        (Icons.verified_user_rounded,
            "C'est toujours votre médecin qui décide. Doza l'aide seulement à préparer votre suivi."),
        (Icons.lock_person_rounded,
            'Vos analyses restent avec votre médecin ; vous ne voyez que ses messages.'),
        (Icons.spa_rounded, 'Doza est là pour vous rassurer, jamais pour vous inquiéter.'),
      ],
    );
  }
}
