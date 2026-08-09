import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'qmatch_glass_icon_button.dart';

/// Shared pushed-route header for Settings destinations and photo management.
class QMatchPushedScreenHeader extends StatelessWidget {
  const QMatchPushedScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.titleKey,
    this.backButtonKey,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Key? titleKey;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          QMatchGlassIconButton(
            key: backButtonKey,
            icon: Icons.arrow_back_ios_new,
            iconSize: 18,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              key: titleKey,
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
