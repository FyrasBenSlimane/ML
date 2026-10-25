import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../avatar/avatar_profile.dart';

enum ModuleStatus { live, reserved }

/// One team member's model inside the app.
///
/// TO INTEGRATE YOUR MODEL (see INTEGRATION.md):
///   1. build your screens in `lib/features/<your_id>/` (start from modules/_template)
///   2. set `entry` below to your first screen and `status` to live
///   3. (optional) give it an `avatar` to get the talking stage for free
class ModelModule {
  const ModelModule({
    required this.id,
    required this.name,
    required this.owner,
    required this.tagline,
    required this.icon,
    required this.gradient,
    this.status = ModuleStatus.reserved,
    this.avatar,
    this.entry,
  });

  /// Must match the backend module id (`/api/v1/<id>`).
  final String id;
  final String name;
  final String owner;
  final String tagline;
  final IconData icon;
  final LinearGradient gradient;
  final ModuleStatus status;
  final AvatarProfile? avatar;

  /// First screen of the module; null while the slot is reserved.
  final WidgetBuilder? entry;

  Color get color => gradient.colors[1];
}

/// The six companions of ReadmitGuard. Teemo is live; the other five slots are
/// reserved for teammates and show an integration guide until they plug in.
/// Teemo's entry is wired by the shell (it opens the Teemo tab).
const kModules = <ModelModule>[
  ModelModule(
    id: 'teemo',
    name: 'Teemo',
    owner: 'Ryma',
    tagline: '30-day readmission risk advisor',
    icon: Icons.favorite_rounded,
    gradient: AppColors.brandGradient,
    status: ModuleStatus.live,
    avatar: AvatarProfile.teemo,
  ),
  ModelModule(
    id: 'carestep',
    name: 'CareStep',
    owner: 'Fyras',
    tagline: '30-day recovery companion',
    icon: Icons.directions_walk_rounded,
    gradient: AppColors.blueGradient,
  ),
  ModelModule(
    id: 'medoracle',
    name: 'MedOracle',
    owner: 'Faycel',
    tagline: 'Clinical analytics & what-if',
    icon: Icons.analytics_rounded,
    gradient: AppColors.violetGradient,
  ),
  ModelModule(
    id: 'rxpredict',
    name: 'RxPredict',
    owner: 'Emna',
    tagline: 'Treatment & insulin changes',
    icon: Icons.medication_rounded,
    gradient: AppColors.coralGradient,
  ),
  ModelModule(
    id: 'dailyguard',
    name: 'DailyGuard',
    owner: 'Fatma',
    tagline: 'Follow-up & medication reminders',
    icon: Icons.notifications_active_rounded,
    gradient: AppColors.amberGradient,
  ),
  ModelModule(
    id: 'bedsense',
    name: 'BedSense',
    owner: 'Najd',
    tagline: 'Bed planning & length of stay',
    icon: Icons.bed_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF86EFAC), Color(0xFF22C55E), Color(0xFF0D9488)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];
