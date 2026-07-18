import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';

/// Channel styling for [QMetricCircle] (Neo Lab viz — IQ / EQ / Frequency).
enum QMetricCircleVariant {
  iq,
  eq,
  frequency,
  neutral,
}

/// Static circular metric for future assessment / compatibility surfaces.
///
/// No animation in DS-1.
class QMetricCircle extends StatelessWidget {
  const QMetricCircle({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.variant = QMetricCircleVariant.neutral,
    this.size = 120,
  });

  final String label;
  final String value;
  final String? subtitle;
  final QMetricCircleVariant variant;
  final double size;

  Gradient get _ringGradient {
    switch (variant) {
      case QMetricCircleVariant.iq:
        return AppGradients.iqGradient;
      case QMetricCircleVariant.eq:
        return AppGradients.eqGradient;
      case QMetricCircleVariant.frequency:
        return AppGradients.frequencyGradient;
      case QMetricCircleVariant.neutral:
        return AppGradients.compatibilityRingGradient;
    }
  }

  Color get _accent {
    switch (variant) {
      case QMetricCircleVariant.iq:
        return AppColors.vizIq;
      case QMetricCircleVariant.eq:
        return AppColors.vizEq;
      case QMetricCircleVariant.frequency:
        return AppColors.vizFrequency;
      case QMetricCircleVariant.neutral:
        return AppColors.softGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringWidth = (size * 0.06).clamp(3.0, 6.0);
    final inner = size - (ringWidth * 2) - 8;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer static ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _ringGradient,
            ),
          ),
          // Inner void fill
          Container(
            width: size - ringWidth * 2,
            height: size - ringWidth * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.deepIndigo,
                  AppColors.cosmicBlack,
                ],
              ),
            ),
          ),
          SizedBox(
            width: inner,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _accent.withValues(alpha: 0.9),
                    fontSize: (size * 0.09).clamp(10.0, 12.0),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: (size * 0.22).clamp(18.0, 32.0),
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: (size * 0.085).clamp(9.0, 11.0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
