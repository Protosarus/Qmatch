import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';

class QMatchProfilePersonaCard extends StatelessWidget {
  const QMatchProfilePersonaCard({
    super.key,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.personaAsset,
    required this.sectionLabel,
    required this.supportingLabel,
    required this.openLabel,
    required this.onTap,
  });

  final String primaryTitle;
  final String secondaryTitle;
  final String personaAsset;
  final String sectionLabel;
  final String supportingLabel;
  final String openLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      key: const Key('qmatch-profile-persona-card'),
      starVisibleGlass: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.resonanceViolet.withValues(alpha: 0.82),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x339D5B18),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Image.asset(
              personaAsset,
              key: const Key('qmatch-profile-persona-art'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sectionLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFDAC8ED),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  primaryTitle,
                  key: const Key('qmatch-profile-persona-primary'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$supportingLabel · $secondaryTitle',
                  key: const Key('qmatch-profile-persona-secondary'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  openLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB9A7FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFFB9A7FF),
            size: 22,
          ),
        ],
      ),
    );
  }
}
