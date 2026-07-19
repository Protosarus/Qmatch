import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Compact assessment identity + question counter.
///
/// Does not invent exit/confirmation flows — optional [leading] only when
/// the host screen already provides that behavior.
class QAssessmentHeader extends StatelessWidget {
  const QAssessmentHeader({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.total,
    this.leading,
    this.eyebrow = 'Qmatch',
  });

  final String title;
  final int currentIndex;
  final int total;
  final Widget? leading;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: GoogleFonts.inter(
                  color: AppColors.softGold.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0x44101828),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x66B07CFF)),
          ),
          child: Text(
            '$currentIndex / $total',
            style: GoogleFonts.inter(
              color: AppColors.vizEq,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
