import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';

/// Small lilac Resonance mark for the owner's profile photo.
///
/// Sized to sit on the lower-right rim so it does not cover the face.
class QMatchResonancePhotoBadge extends StatelessWidget {
  const QMatchResonancePhotoBadge({
    super.key,
    required this.semanticLabel,
  });

  final String semanticLabel;

  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        key: const Key('qmatch-profile-resonance-badge'),
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.resonanceViolet.withValues(alpha: 0.92),
            border: Border.all(
              color: const Color(0xFFDAC8ED),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 11,
            color: Color(0xFFF4EEFF),
          ),
        ),
      ),
    );
  }
}

/// Compact owner membership status. Always shown; tap opens Membership.
class QMatchProfileMembershipCard extends StatelessWidget {
  const QMatchProfileMembershipCard({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      key: const Key('qmatch-profile-membership'),
      starVisibleGlass: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 18,
            color: Color(0xFFDAC8ED),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              key: const Key('qmatch-profile-membership-label'),
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFFE8ECFA),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: QMatchGlassIconButton.iconDefault.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}
