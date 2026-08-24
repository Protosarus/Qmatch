import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';
import '../../../l10n/app_localizations.dart';
import '../services/relationship_analysis_discovery.dart';

/// Derived Activity system card for Relationship Analysis (not a feed event).
class RelationshipAnalysisActivityCard extends StatelessWidget {
  const RelationshipAnalysisActivityCard({
    super.key,
    required this.prompt,
    required this.onStart,
  });

  final RelationshipActivityPrompt prompt;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resume = prompt.isResume;

    final title = resume
        ? l10n.relationshipAnalysisActivityContinueTitle
        : l10n.relationshipAnalysisActivityTitle;
    final body = resume
        ? l10n.relationshipAnalysisActivityContinueBody
        : l10n.relationshipAnalysisActivityBody;
    final cta = resume
        ? l10n.relationshipAnalysisActivityContinueCta
        : l10n.relationshipAnalysisActivityCta;

    return Container(
      key: const Key('qmatch-relationship-analysis-activity-card'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.resonanceViolet.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.resonanceViolet.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppColors.resonanceViolet.withValues(alpha: 0.4),
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.resonanceViolet,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      key: const Key(
                        'qmatch-relationship-analysis-activity-title',
                      ),
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      key: const Key(
                        'qmatch-relationship-analysis-activity-body',
                      ),
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 44,
            child: QCosmicButton(
              key: const Key('qmatch-relationship-analysis-activity-cta'),
              label: cta,
              onPressed: onStart,
              variant: QCosmicButtonVariant.primary,
              height: 44,
            ),
          ),
        ],
      ),
    );
  }
}
