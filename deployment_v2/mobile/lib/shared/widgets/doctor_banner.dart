import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Red-tinted banner shown at the top of every model result: these outputs are
/// for the doctor only and must never be shown to the patient. The patient only
/// ever receives the gentle alert the doctor sends from the card below.
class DoctorBanner extends StatelessWidget {
  const DoctorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_person_rounded, color: AppColors.coral, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Résultat destiné au médecin — ne pas montrer au patient.',
                style: TextStyle(
                    color: AppColors.coral.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    height: 1.3)),
          ),
        ],
      ),
    );
  }
}
