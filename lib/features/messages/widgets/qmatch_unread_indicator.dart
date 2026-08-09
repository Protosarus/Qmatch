import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';

/// Unread marker: count text + filled chip (not color-only).
class QMatchUnreadIndicator extends StatelessWidget {
  const QMatchUnreadIndicator({
    super.key,
    required this.count,
    required this.semanticLabel,
  });

  final int count;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final label = count > 99 ? '99+' : '$count';

    return Semantics(
      key: const Key('qmatch-conversation-unread'),
      label: semanticLabel,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppColors.resonanceViolet.withValues(alpha: 0.92),
          borderRadius: AppRadii.pillBorder,
          border:
              Border.all(color: AppColors.borderGlow.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.softGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
