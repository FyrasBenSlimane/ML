import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/patient_gate.dart';
import '../avatar/avatar_profile.dart';
import '../bedsense/bedsense_screen.dart';
import '../carestep/carestep_screen.dart';
import '../doza/screens/doza_chat_screen.dart';
import '../medoracle/medoracle_screen.dart';
import '../sora/screens/sora_questionnaire_screen.dart';

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

/// The six companions of MAAK معاك. Teemo is live; the other five slots are
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
    status: ModuleStatus.live,
    avatar: AvatarProfile.carestep,
    entry: _careStepEntry,
  ),
  ModelModule(
    id: 'medoracle',
    name: 'MedOracle',
    owner: 'Faycel',
    tagline: 'Care equity comparison analysis',
    icon: Icons.analytics_rounded,
    gradient: AppColors.violetGradient,
    status: ModuleStatus.live,
    entry: _medOracleEntry,
  ),
  ModelModule(
    id: 'doza',
    name: 'Doza',
    owner: 'Emna',
    tagline: 'Insulin dose change advisor',
    icon: Icons.medication_rounded,
    gradient: AppColors.coralGradient,
    status: ModuleStatus.live,
    avatar: AvatarProfile.doza,
    entry: _dozaEntry,
  ),
  ModelModule(
    id: 'sora',
    name: 'Sora',
    owner: 'Fatma',
    tagline: 'Discharge profile: follow-up & control',
    icon: Icons.assignment_turned_in_rounded,
    gradient: AppColors.amberGradient,
    status: ModuleStatus.live,
    avatar: AvatarProfile.sora,
    entry: _soraEntry,
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
    status: ModuleStatus.live,
    avatar: AvatarProfile.bedsense,
    entry: _bedSenseEntry,
  ),
];

// Entry builders (top-level tear-offs are const, so kModules stays const).
// Each model is gated by the Patient ID step before any evaluation starts.
Widget _dozaEntry(BuildContext _) =>
    const PatientGate(module: 'doza', child: DozaChatScreen());
Widget _soraEntry(BuildContext _) =>
    const PatientGate(module: 'sora', child: SoraQuestionnaireScreen());
Widget _medOracleEntry(BuildContext _) =>
    const PatientGate(module: 'medoracle', child: MedOracleScreen());
Widget _careStepEntry(BuildContext _) =>
    const PatientGate(module: 'carestep', child: CareStepScreen());
Widget _bedSenseEntry(BuildContext _) =>
    const PatientGate(module: 'bedsense', child: BedSenseScreen());
