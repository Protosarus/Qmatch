import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_wrapper.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/q_assessment_scaffold.dart';

/// Temporary post-Frequency completion screen (P1B-2A).
///
/// Not a persona screen — no archetype, HH…LL, Frequency type, or confidence.
class AssessmentFlowCompleteScreen extends StatelessWidget {
  const AssessmentFlowCompleteScreen({
    super.key,
    required this.profileCompleted,
  });

  final bool profileCompleted;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final tr = languageCode.startsWith('tr');

    final title =
        tr ? 'Değerlendirmelerin tamamlandı' : 'Your assessments are complete';
    final body = tr
        ? 'Zihinsel, duygusal ve bağ kurma profilinin temel verileri kaydedildi.'
        : 'Your cognitive, emotional, and connection profile data has been saved.';
    final iqLabel = tr ? 'IQ tamamlandı' : 'IQ completed';
    final eqLabel = tr ? 'EQ tamamlandı' : 'EQ completed';
    final freqLabel = tr ? 'Frekans tamamlandı' : 'Frequency completed';
    final cta = profileCompleted
        ? (tr ? 'Devam' : 'Continue')
        : (tr ? 'Profilimi Oluştur' : 'Create My Profile');

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: compact ? 12 : 24),
              Center(
                child: Image.asset(
                  'assets/images/welcome_q_glow.png',
                  height: compact ? 44 : 56,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    'Q',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.primary,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 28 : 40),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: compact ? 26 : 30,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              SizedBox(height: compact ? 28 : 36),
              _Indicator(label: iqLabel),
              const SizedBox(height: 10),
              _Indicator(label: eqLabel),
              const SizedBox(height: 10),
              _Indicator(label: freqLabel),
              const Spacer(),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    cta,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 8 : 16),
            ],
          );
        },
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
