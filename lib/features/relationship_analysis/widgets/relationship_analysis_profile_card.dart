import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/relationship_analysis_state.dart';
import '../domain/relationship_dimensions.dart';

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
    final isComplete = depthPct >= 100 ||
        state.answeredCount >= RelationshipAnalysisContract.questionCount;
    final isNone = depthPct <= 0 && !isComplete;

    final String statusLine;
    final String? ctaLabel;
    if (isComplete) {
      statusLine = l10n.relationshipAnalysisStatusComplete;
      ctaLabel = null;
    } else if (isNone) {
      statusLine = l10n.relationshipAnalysisStatusNone;
      ctaLabel = l10n.relationshipAnalysisStartCta;
    } else {
      statusLine = l10n.relationshipAnalysisDepthLabel;
      ctaLabel = l10n.relationshipAnalysisDeepenCta;
    }

    return QGlassCard(
      key: const Key('qmatch-relationship-analysis-card'),
      starVisibleGlass: true,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 2,
        AppSpacing.md,
        AppSpacing.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.relationshipAnalysisTitle,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (isNone) ...[
            Text(
              statusLine,
              key: const Key('qmatch-relationship-analysis-status'),
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusLine,
                    key: const Key('qmatch-relationship-analysis-status'),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
                Text(
                  l10n.relationshipAnalysisDepthPercent(depthPct),
                  key: const Key('qmatch-relationship-analysis-depth'),
                  style: GoogleFonts.inter(
                    color: AppColors.resonanceViolet,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                key: const Key('qmatch-relationship-analysis-depth-bar'),
                value: depthPct / 100.0,
                minHeight: 5,
                backgroundColor: AppColors.borderSubtle,
                color: AppColors.resonanceViolet,
              ),
            ),
          ],
          if (ctaLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 42,
              child: QCosmicButton(
                key: const Key('qmatch-relationship-analysis-deepen'),
                label: ctaLabel,
                onPressed: onDeepen,
                variant: QCosmicButtonVariant.glass,
                height: 42,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
