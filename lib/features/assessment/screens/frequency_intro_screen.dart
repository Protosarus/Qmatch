import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';
import '../widgets/frequency_question_chrome.dart';
import '../widgets/q_assessment_scaffold.dart';
import 'frequency_test_screen.dart';

class FrequencyIntroScreen extends StatelessWidget {
  const FrequencyIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return QAssessmentScaffold(
      richBackdrop: true,
      backgroundImageAsset: 'assets/images/welcome_cosmic_background.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 700;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FrequencyQuestionTopBar(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(height: compact ? 2 : 8),
              Text(
                l10n.frequencyIntroTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFFFE4A0),
                  fontSize: compact ? 25 : 31,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  shadows: const [
                    Shadow(color: Color(0xAA9A48FF), blurRadius: 18),
                  ],
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
              Text(
                l10n.frequencyIntroDescription,
                maxLines: compact ? 3 : 4,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: compact ? 11.5 : 13.5,
                  height: 1.38,
                ),
              ),
              SizedBox(
                height: compact ? 76 : 128,
                child: const FrequencyWaveHero(),
              ),
              Expanded(
                child: _FrequencyIntroCard(
                  compact: compact,
                  eyebrow: l10n.assessmentStageFrequency,
                  bullets: [
                    l10n.frequencyBulletConnect,
                    l10n.frequencyBulletTrust,
                    l10n.frequencyBulletOpenness,
                    l10n.frequencyBulletRhythm,
                  ],
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              FrequencyContinueButton(
                label: l10n.startFrequencyTest,
                active: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FrequencyTestScreen(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FrequencyIntroCard extends StatelessWidget {
  const _FrequencyIntroCard({
    required this.compact,
    required this.eyebrow,
    required this.bullets,
  });

  final bool compact;
  final String eyebrow;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 18,
            compact ? 9 : 14,
            compact ? 14 : 18,
            compact ? 7 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xD51D1733),
                Color(0xC50D1229),
                Color(0xC7151024),
              ],
            ),
            border: Border.all(
              color: const Color(0x668F79B4),
              width: 0.9,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                eyebrow.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFFDAB873),
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              for (final bullet in bullets)
                _FrequencyIntroBullet(
                  text: bullet,
                  compact: compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyIntroBullet extends StatelessWidget {
  const _FrequencyIntroBullet({
    required this.text,
    required this.compact,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 25 : 29,
          height: compact ? 25 : 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x55201638),
            border: Border.all(color: const Color(0x668D70B0)),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: Color(0xFFFFD68B),
          ),
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: compact ? 10.5 : 12.5,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
