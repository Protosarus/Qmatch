import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/iq_bank/iq_canonical_dimensions.dart';
import '../domain/iq_scoring/iq_scoring.dart';
import '../widgets/iq_question_chrome.dart';
import '../widgets/q_assessment_scaffold.dart';

/// Post-IQ uncalibrated reasoning profile (not a standardized IQ result).
class IqReasoningProfileScreen extends StatelessWidget {
  const IqReasoningProfileScreen({
    super.key,
    required this.result,
    required this.onContinue,
  });

  final IqCanonicalScoringResult result;
  final VoidCallback onContinue;

  static const String _cosmicBackgroundAsset =
      'assets/images/welcome_cosmic_background.png';

  /// Frequency / cosmic label lavender (not flat soft-gold).
  static const Color _accentLabel = Color(0xFFDAC8ED);

  String _labelFor(AppLocalizations l10n, String dimension) {
    switch (dimension) {
      case IqCanonicalDimensions.logicalReasoning:
        return l10n.iqDimLogicalReasoning;
      case IqCanonicalDimensions.patternReasoning:
        return l10n.iqDimPatternReasoning;
      case IqCanonicalDimensions.verbalReasoning:
        return l10n.iqDimVerbalReasoning;
      case IqCanonicalDimensions.spatialReasoning:
        return l10n.iqDimSpatialReasoning;
      default:
        return dimension;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: QAssessmentScaffold(
        richBackdrop: true,
        backgroundImageAsset: _cosmicBackgroundAsset,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: compact ? 8 : 16),
                Text(
                  l10n.iqReasoningProfileTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: compact ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.iqReasoningProfileSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.iqUncalibratedDisclaimer,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _accentLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 20 : 28),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final d in result.dimensionScores) ...[
                        _DimensionRow(
                          label: _labelFor(l10n, d.dimension),
                          // Presentation only: 100 × provisionalScore.
                          percent: (d.provisionalScore * 100).round(),
                          fraction: d.provisionalScore.clamp(0.0, 1.0),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                IqContinueButton(
                  label: l10n.continueToEqAssessment,
                  onPressed: onContinue,
                  active: true,
                ),
                SizedBox(height: compact ? 4 : 8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.label,
    required this.percent,
    required this.fraction,
  });

  final String label;
  final int percent;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: AppRadii.buttonBorder,
        border: Border.all(color: const Color(0x554F4D79)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.94),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.inter(
                  color: IqReasoningProfileScreen._accentLabel,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vizIq),
            ),
          ),
        ],
      ),
    );
  }
}
