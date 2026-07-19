import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';

/// Primary Next / Finish control for MCQ assessments.
///
/// Host owns [onPressed] (existing `_nextQuestion` / equivalent).
class QAssessmentNavigation extends StatelessWidget {
  const QAssessmentNavigation({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.buttonBorder,
        gradient: AppGradients.eqGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.resonanceViolet.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: AppRadii.buttonBorder,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: Center(
              child: Opacity(
                opacity: enabled ? 1.0 : AppColors.disabledOpacity,
                child: Text(
                  label.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
