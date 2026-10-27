import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/cards.dart';
import '../../avatar/avatar_profile.dart';
import '../../teemo/data/teemo_models.dart';
import '../../teemo/widgets/form_fields.dart';

/// BedSense accent: the green of its avatar.
const bsGreen = Color(0xFF22C55E);
const bsGreenDeep = Color(0xFF15803D);
final LinearGradient bsGradient = AvatarProfile.bedsense.gradient;

Color levelColor(String level) => switch (level.toLowerCase()) {
      'high' => AppColors.red,
      'medium' => AppColors.amber,
      _ => AppColors.green,
    };

LinearGradient levelGradient(String level) => AppColors.gradientForLevel(switch (level.toLowerCase()) {
      'high' => 'HIGH',
      'medium' => 'MODERATE',
      _ => 'LOW',
    });

Color statusColor(String status) => switch (status) {
      'over' => AppColors.red,
      'tight' => AppColors.amber,
      _ => AppColors.green,
    };

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Mon 26 Oct"
String shortDay(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "26 Oct"
String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Spinner + short line while a section loads.
class BsLoading extends StatelessWidget {
  const BsLoading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const CircularProgressIndicator(color: bsGreen),
            const SizedBox(height: 14),
            Text(text, style: const TextStyle(color: AppColors.inkSoft)),
          ],
        ),
      );
}

/// Error card with a retry button (same look as MedOracle's).
class BsErrorCard extends StatelessWidget {
  const BsErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => SoftCard(
        color: const Color(0xFFFFF1F2),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.coral),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: AppColors.ink, height: 1.4))),
              ],
            ),
            if (onRetry != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ),
          ],
        ),
      );
}

/// Small figure tile: icon, big number, label and a hint line.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.hint,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13.5)),
            const SizedBox(height: 2),
            Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.3)),
          ],
        ),
      );
}

/// Two KPI tiles per row, equal heights.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 12),
            Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
          ],
        ),
      ));
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

/// "Whole hospital" + one chip per service. `null` means the whole hospital.
class ServicePicker extends StatelessWidget {
  const ServicePicker({super.key, required this.services, required this.value, required this.onChanged});

  final List<String> services;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => ChoiceChips(
        color: bsGreen,
        options: [
          const FieldOption('', 'Whole hospital'),
          for (final s in services) FieldOption(s, s),
        ],
        value: value ?? '',
        onChanged: (v) => onChanged(v == '' ? null : v as String),
      );
}

/// Grey footnote (disclaimers, how-to-read lines).
class BsNote extends StatelessWidget {
  const BsNote(this.text, {super.key, this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: const TextStyle(color: AppColors.inkSoft, fontSize: 11.5, height: 1.5),
      );
}

/// Bulleted line used for facts and alert options.
class BsBullet extends StatelessWidget {
  const BsBullet(this.text, {super.key, this.color = bsGreen, this.icon = Icons.circle});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: icon == Icons.circle ? 6 : 1, right: 10),
              child: Icon(icon, size: icon == Icons.circle ? 7 : 16, color: color),
            ),
            Expanded(child: Text(text, style: const TextStyle(color: AppColors.ink, height: 1.4))),
          ],
        ),
      );
}
