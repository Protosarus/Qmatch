import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Glass question surface for long EQ / IQ stems.
class QQuestionCard extends StatelessWidget {
  const QQuestionCard({
    super.key,
    required this.text,
    this.eyebrow,
  });

  final String text;
  /// Optional gold label (e.g. IQ Insight) — EQ leaves null.
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.cardBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            color: AppColors.glassSurface,
            border: Border.all(color: const Color(0x66E8C878), width: 0.9),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.softGold.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null && eyebrow!.trim().isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.psychology_alt_rounded,
                      size: 16,
                      color: AppColors.softGold.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      eyebrow!,
                      style: GoogleFonts.inter(
                        color: AppColors.softGold.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text(
                text,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
