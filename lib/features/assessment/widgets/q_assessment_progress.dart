import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Horizontal progress for MCQ assessments.
///
/// [value] must already be computed by the host (`(index + 1) / total`).
class QAssessmentProgress extends StatelessWidget {
  const QAssessmentProgress({
    super.key,
    required this.value,
    this.height = 6,
  });

  /// 0.0–1.0 progress fraction from existing index logic.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0x33101828),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: const Color(0x33B07CFF)),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height),
            gradient: const LinearGradient(
              colors: [
                AppColors.resonanceViolet,
                AppColors.secondary,
                AppColors.softGold,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
