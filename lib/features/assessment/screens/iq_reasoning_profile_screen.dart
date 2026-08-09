import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/iq_bank/iq_canonical_dimensions.dart';
import '../domain/iq_scoring/iq_scoring.dart';

/// Post-IQ uncalibrated reasoning profile (not a standardized IQ result).
class IqReasoningProfileScreen extends StatelessWidget {
  const IqReasoningProfileScreen({
    super.key,
    required this.result,
    required this.onContinue,
  });

  final IqCanonicalScoringResult result;
  final VoidCallback onContinue;

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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0618),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.iqReasoningProfileTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.iqReasoningProfileSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.iqUncalibratedDisclaimer,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.softGold.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final d in result.dimensionScores) ...[
                          _DimensionRow(
                            label: _labelFor(l10n, d.dimension),
                            // Presentation only: 100 × provisionalScore.
                            percent: (d.provisionalScore * 100).round(),
                            fraction: d.provisionalScore.clamp(0.0, 1.0),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vizIq,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        l10n.continueToEqAssessment,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                color: AppColors.softGold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vizIq),
          ),
        ),
      ],
    );
  }
}
