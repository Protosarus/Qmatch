import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/relationship_analysis_state.dart';

class RelationshipAnalysisProfileCard extends StatelessWidget {
  const RelationshipAnalysisProfileCard({
    super.key,
    required this.state,
    required this.onDeepen,
  });

  final RelationshipAnalysisState state;
  final VoidCallback onDeepen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final depthPct = (state.analysisDepth * 100).round().clamp(0, 100);
    final status = depthPct <= 0
        ? l10n.relationshipAnalysisStatusNone
        : depthPct >= 100
            ? l10n.relationshipAnalysisStatusComplete
            : l10n.relationshipAnalysisStatusPartial;

    return QGlassCard(
      key: const Key('qmatch-relationship-analysis-card'),
      starVisibleGlass: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.relationshipAnalysisTitle,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE8ECFA),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.relationshipAnalysisSubtitle,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l10n.relationshipAnalysisDepthLabel} $depthPct%',
            key: const Key('qmatch-relationship-analysis-depth'),
            style: GoogleFonts.inter(
              color: const Color(0xFFDAC8ED),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              key: const Key('qmatch-relationship-analysis-deepen'),
              onPressed: depthPct >= 100 ? null : onDeepen,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDAC8ED),
                side: BorderSide(
                  color: const Color(0xFFDAC8ED).withValues(alpha: 0.7),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadii.buttonBorder,
                ),
              ),
              child: Text(
                l10n.relationshipAnalysisDeepenCta,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
