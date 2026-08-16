import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/auth_wrapper.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_scaffold.dart';

/// Post-Frequency completion screen (P1B-2A).
///
/// Cosmic celebration composition — not a Persona reveal.
/// No archetype, HH…LL, Frequency type, confidence, or %.
class AssessmentFlowCompleteScreen extends StatelessWidget {
  const AssessmentFlowCompleteScreen({
    super.key,
    required this.profileCompleted,
  });

  final bool profileCompleted;

  static const Color _lavender = Color(0xFFDAC8ED);
  static const Color _title = Color(0xFFF2EEF7);

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.maybeLocaleOf(context)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final tr = languageCode.startsWith('tr');

    final titleLead = tr ? 'Değerlendirmelerin' : 'Your assessments';
    final titleEmphasis = tr ? 'tamamlandı' : 'are complete';
    // Kept for identity tests that match the full English sentence.
    final titleFull =
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
              SizedBox(height: compact ? 8 : 18),
              Center(
                child: Image.asset(
                  'assets/images/welcome_q_glow.png',
                  height: compact ? 48 : 60,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Text(
                    'Q',
                    style: GoogleFonts.playfairDisplay(
                      color: _lavender,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 22 : 32),
              Semantics(
                header: true,
                label: titleFull,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$titleLead\n',
                        style: GoogleFonts.playfairDisplay(
                          color: _title,
                          fontSize: compact ? 26 : 30,
                          fontWeight: FontWeight.w500,
                          height: 1.08,
                          letterSpacing: 0.15,
                        ),
                      ),
                      TextSpan(
                        text: titleEmphasis,
                        style: GoogleFonts.playfairDisplay(
                          color: _lavender,
                          fontSize: compact ? 28 : 34,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          height: 1.05,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  key: const Key('assessment-flow-complete-title'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: compact ? 14 : 15,
                  height: 1.45,
                ),
              ),
              SizedBox(height: compact ? 28 : 40),
              _CompletionSteps(
                compact: compact,
                labels: [iqLabel, eqLabel, freqLabel],
              ),
              const Spacer(),
              FrequencyContinueButton(
                label: cta,
                active: true,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (route) => false,
                  );
                },
              ),
              SizedBox(height: compact ? 8 : 16),
            ],
          );
        },
      ),
    );
  }
}

/// Cardless completion list — cool glass checks, no bordered dashboard tiles.
class _CompletionSteps extends StatelessWidget {
  const _CompletionSteps({
    required this.compact,
    required this.labels,
  });

  final bool compact;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) SizedBox(height: compact ? 14 : 18),
          _CompletionStep(label: labels[i], compact: compact),
        ],
      ],
    );
  }
}

class _CompletionStep extends StatelessWidget {
  const _CompletionStep({
    required this.label,
    required this.compact,
  });

  final String label;
  final bool compact;

  static const Color _lavender = Color(0xFFDAC8ED);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 28 : 32,
          height: compact ? 28 : 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _lavender.withValues(alpha: 0.14),
            border: Border.all(
              color: _lavender.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A4DDF).withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.check_rounded,
            color: _lavender,
            size: compact ? 16 : 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFE8ECFA),
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
        ),
      ],
    );
  }
}
