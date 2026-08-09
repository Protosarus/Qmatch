import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Day boundary chip between message groups (presentation only).
class QMatchDateSeparator extends StatelessWidget {
  const QMatchDateSeparator({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('qmatch-chat-date-separator'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassSurfaceStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small timestamp under a bubble — only when [text] is non-null/non-empty.
class QMatchMessageTimestamp extends StatelessWidget {
  const QMatchMessageTimestamp({
    super.key,
    required this.text,
    required this.alignEnd,
  });

  final String text;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          key: const Key('qmatch-chat-message-timestamp'),
          text,
          style: GoogleFonts.inter(
            color: AppColors.textMuted.withValues(alpha: 0.9),
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
