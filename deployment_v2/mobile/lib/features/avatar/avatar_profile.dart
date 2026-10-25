import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Everything the talking-avatar stage needs to present a model's persona.
/// Teammates create their own profile (see features/modules/_template).
class AvatarProfile {
  const AvatarProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.faceAsset,
    required this.portraitAsset,
    required this.gradient,
    required this.accent,
    this.videoAsset,
  });

  final String id;
  final String name;
  final String role;

  /// Square head-and-shoulders crop, used in circles and bubbles.
  final String faceAsset;

  /// Still frame shown before speaking — should be the video's FIRST frame so
  /// the switch from still to moving is seamless.
  final String portraitAsset;

  /// Looping, muted clip of the avatar talking/gesturing. Optional: without it
  /// the stage animates the portrait instead.
  final String? videoAsset;

  final LinearGradient gradient;
  final Color accent;

  String get heroTag => 'avatar-$id';

  static const teemo = AvatarProfile(
    id: 'teemo',
    name: 'Teemo',
    role: 'Readmission risk advisor',
    faceAsset: 'assets/teemo/teemo_face.png',
    portraitAsset: 'assets/teemo/teemo_portrait.png',
    videoAsset: 'assets/teemo/teemo_talk.mp4',
    gradient: AppColors.brandGradient,
    accent: AppColors.teal,
  );
}

/// One subtitle line of an avatar's script. `kind` lets the UI pick an icon.
class SpeechSegment {
  const SpeechSegment(this.kind, this.text);

  factory SpeechSegment.fromJson(Map<String, dynamic> j) =>
      SpeechSegment(j['kind'] as String? ?? 'info', j['text'] as String);

  final String kind;
  final String text;

  Map<String, dynamic> toJson() => {'kind': kind, 'text': text};

  IconData get icon => switch (kind) {
        'greeting' => Icons.waving_hand_rounded,
        'score' => Icons.speed_rounded,
        'comparison' => Icons.leaderboard_rounded,
        'calibration' => Icons.groups_rounded,
        'driver_up' => Icons.trending_up_rounded,
        'driver_down' => Icons.trending_down_rounded,
        'actions_intro' || 'action' => Icons.checklist_rounded,
        'closing' => Icons.favorite_rounded,
        _ => Icons.chat_bubble_rounded,
      };
}
