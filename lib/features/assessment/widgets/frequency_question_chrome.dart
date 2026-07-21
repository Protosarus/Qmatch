import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Presentation-only header for Frequency questions.
///
/// The glowing Q intentionally stands alone; the Qmatch wordmark is omitted.
class FrequencyQuestionTopBar extends StatelessWidget {
  const FrequencyQuestionTopBar({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x66101828),
                    border: Border.all(
                      color: AppColors.softGold.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: Image.asset(
              'assets/images/welcome_q_glow.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ],
      ),
    );
  }
}

class FrequencyProgressHeader extends StatelessWidget {
  const FrequencyProgressHeader({
    super.key,
    required this.label,
    required this.progress,
  });

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFFDAC8ED),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.2,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * clamped;
            final tipX = (fillWidth - 7).clamp(0.0, constraints.maxWidth - 14);
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      color: const Color(0x55171A34),
                      border: Border.all(
                        color: const Color(0x446F6D9B),
                        width: 0.7,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: fillWidth,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF7756F4),
                          Color(0xFFC663F3),
                          Color(0xFFFFD47B),
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x88BC68FF),
                          blurRadius: 9,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: tipX,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            Color(0xFFFFD685),
                            Color(0x00FFD685),
                          ],
                          stops: [0, 0.28, 1],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Reference-locked static resonance artwork.
///
/// It is deliberately an image rather than an animated painter so the wave
/// remains visually identical and motion-free on every device.
class FrequencyWaveHero extends StatelessWidget {
  const FrequencyWaveHero({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image.asset(
        'assets/images/frequency_static_resonance_hero.png',
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}

class FrequencyQuestionPanel extends StatelessWidget {
  const FrequencyQuestionPanel({
    super.key,
    required this.eyebrow,
    required this.question,
    required this.labels,
    required this.selectedValue,
    required this.onSelected,
    this.compact = false,
  });

  final String eyebrow;
  final String question;
  final List<String> labels;
  final int? selectedValue;
  final ValueChanged<int> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 10 : 14,
            compact ? 12 : 16,
            compact ? 8 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                eyebrow.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFFDAB873),
                  fontSize: compact ? 8.5 : 9.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.1,
                ),
              ),
              SizedBox(height: compact ? 3 : 6),
              Text(
                question,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFF2EEF7),
                  fontSize: compact ? 15.5 : 18.5,
                  fontWeight: FontWeight.w500,
                  height: 1.18,
                ),
              ),
              SizedBox(height: compact ? 5 : 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      FrequencyAnswerOptionRow(
                        value: i + 1,
                        label: labels[i],
                        selected: selectedValue == i + 1,
                        compact: compact,
                        onTap: () => onSelected(i + 1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FrequencyAnswerOptionRow extends StatelessWidget {
  const FrequencyAnswerOptionRow({
    super.key,
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final int value;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final minHeight = compact ? 34.0 : 42.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 4 : 7,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      Color(0xB34C25C9),
                      Color(0xA06D34DA),
                      Color(0x99D89C47),
                    ],
                  )
                : const LinearGradient(
                    colors: [
                      Color(0x8A17142D),
                      Color(0x72101227),
                    ],
                  ),
            border: Border.all(
              color:
                  selected ? const Color(0x99F2D08A) : const Color(0x554F4D79),
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x554D25D2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 25 : 29,
                height: compact ? 25 : 29,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x55201638),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFFFD68B)
                        : const Color(0x668D70B0),
                  ),
                ),
                child: CustomPaint(
                  painter: _FrequencyGlyphPainter(
                    value: value,
                    selected: selected,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(
                      alpha: selected ? 1 : 0.82,
                    ),
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: compact ? 17 : 19,
                color: selected
                    ? const Color(0xFFFFD68B)
                    : const Color(0x777D7597),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyGlyphPainter extends CustomPainter {
  const _FrequencyGlyphPainter({
    required this.value,
    required this.selected,
  });

  final int value;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final centerY = size.height / 2;
    final amplitude = size.height * (0.08 + value * 0.025);
    for (double x = 4; x <= size.width - 4; x += 1) {
      final y = centerY +
          math.sin((x / size.width) * math.pi * (2 + value * 0.45)) * amplitude;
      if (x == 4) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round
        ..color = selected ? const Color(0xFFFFD68B) : const Color(0xFFB997D2),
    );
  }

  @override
  bool shouldRepaint(covariant _FrequencyGlyphPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.selected != selected;
}

class FrequencyContinueButton extends StatelessWidget {
  const FrequencyContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.active,
    this.saving = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final tint = active ? 1.0 : 0.5;
    return Opacity(
      opacity: active ? 1 : 0.7,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: AppRadii.pillBorder,
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x884D25DF),
                    blurRadius: 20,
                    offset: Offset(-6, 5),
                  ),
                  BoxShadow(
                    color: Color(0x77F0B95B),
                    blurRadius: 18,
                    offset: Offset(7, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.pillBorder,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: saving ? null : onPressed,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.pillBorder,
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(84, 34, 221, 0.9 * tint),
                      Color.fromRGBO(126, 55, 229, 0.82 * tint),
                      Color.fromRGBO(221, 154, 65, 0.86 * tint),
                      Color.fromRGBO(255, 210, 116, 0.92 * tint),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: active ? 0.45 : 0.18,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      Expanded(
                        child: saving
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFFFEDC4),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FrequencySelectAnswerWarning extends StatelessWidget {
  const FrequencySelectAnswerWarning({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.pillBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            gradient: const LinearGradient(
              colors: [
                Color(0xCC4F25D0),
                Color(0xE0191834),
                Color(0x99C98D40),
              ],
            ),
            border: Border.all(
              color: const Color(0x99F1D08A),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 17,
                color: Color(0xFFFFD68B),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
