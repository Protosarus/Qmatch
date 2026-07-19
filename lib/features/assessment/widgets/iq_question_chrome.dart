import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// IQ question-screen chrome — presentation only; host owns selection / next.
class IqQuestionTopBar extends StatelessWidget {
  const IqQuestionTopBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x33101828),
                    border: Border.all(
                      color: AppColors.softGold.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: AppColors.softGold.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Image.asset(
                  'assets/images/welcome_q_glow.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Text(
                'Qmatch',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.05,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class IqQuestionProgressHeader extends StatelessWidget {
  const IqQuestionProgressHeader({
    super.key,
    required this.label,
    required this.progress,
  });

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology_alt_rounded,
              size: 16,
              color: AppColors.softGold.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        IqSparkProgressBar(value: progress),
      ],
    );
  }
}

class IqSparkProgressBar extends StatelessWidget {
  const IqSparkProgressBar({
    super.key,
    required this.value,
    this.height = 7,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackW = constraints.maxWidth;
        final fillW = trackW * clamped;
        final tipX = (fillW - 7).clamp(0.0, trackW - 14);

        return SizedBox(
          height: height + 10,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0x33101828),
                  borderRadius: BorderRadius.circular(height),
                  border: Border.all(color: const Color(0x33B07CFF)),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: fillW,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.resonanceViolet,
                      AppColors.electricBlue,
                      AppColors.softGold,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.resonanceViolet.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: tipX,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFFF2C8),
                        AppColors.softGold,
                        Color(0x00E3C565),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.softGold.withValues(alpha: 0.7),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 9,
                    color: Color(0xFF2A1A08),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class IqInsightQuestionCard extends StatelessWidget {
  const IqInsightQuestionCard({
    super.key,
    required this.eyebrow,
    required this.text,
    this.compact = false,
  });

  final String eyebrow;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 12.0 : 16.0;
    final qSize = compact ? 15.0 : 18.0;

    return ClipRRect(
      borderRadius: AppRadii.cardBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(pad, pad, pad, compact ? 12 : 18),
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xCC1A1538),
                AppColors.glassSurface,
                const Color(0x99101828),
              ],
            ),
            border: Border.all(
              color: const Color(0x88E8C878),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.softGold.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 24 : 28,
                    height: compact ? 24 : 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0x44281858),
                      border: Border.all(
                        color: AppColors.softGold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      size: compact ? 14 : 16,
                      color: AppColors.softGold.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    eyebrow,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.softGold.withValues(alpha: 0.95),
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 12),
              Text(
                text,
                maxLines: compact ? 4 : 6,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: qSize,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IqAnswerOptionRow extends StatelessWidget {
  const IqAnswerOptionRow({
    super.key,
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  /// Display order index (0–3) → visual labels A–D only.
  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    final fill = selected
        ? const Color(0x55401A78)
        : const Color(0x59101828);
    final minH = compact ? 44.0 : 54.0;
    final vPad = compact ? 10.0 : 14.0;
    final badge = compact ? 26.0 : 28.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.resonanceViolet.withValues(alpha: 0.16),
        highlightColor: AppColors.resonanceViolet.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          // 1px frame always — selected uses gradient, idle uses muted edge.
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.resonanceViolet,
                      AppColors.electricBlue,
                      Color(0xFFE3C565),
                    ],
                  )
                : null,
            color: selected ? null : const Color(0x448A90B8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.resonanceViolet.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: AppColors.softGold.withValues(alpha: 0.14),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Container(
            constraints: BoxConstraints(minHeight: minH - 2),
            padding: EdgeInsets.fromLTRB(11, vPad - 0.5, 9, vPad - 0.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: fill,
            ),
            child: Row(
              children: [
                Container(
                  width: badge,
                  height: badge,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.resonanceViolet.withValues(alpha: 0.72)
                        : const Color(0x33101828),
                    border: Border.all(
                      color: selected
                          ? AppColors.softGold.withValues(alpha: 0.55)
                          : const Color(0x558A90B8),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFB8C0D8),
                      fontSize: compact ? 12.5 : 13,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(
                        alpha: selected ? 1.0 : 0.82,
                      ),
                      fontSize: compact ? 13.5 : 14.5,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ),
                SizedBox(
                  width: compact ? 20 : 22,
                  height: compact ? 20 : 22,
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          size: compact ? 20 : 22,
                          color: AppColors.softGold.withValues(alpha: 0.95),
                        )
                      : Icon(
                          Icons.circle_outlined,
                          size: compact ? 16 : 18,
                          color: const Color(0x448A90B8),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class IqContinueButton extends StatelessWidget {
  const IqContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.pillBorder,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4B1FE0).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFF0C65A).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadii.pillBorder,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: AppRadii.pillBorder,
                  splashColor: Colors.white.withValues(alpha: 0.12),
                  highlightColor: Colors.white.withValues(alpha: 0.06),
                  child: Ink(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.pillBorder,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF4B1FE0).withValues(alpha: 0.52),
                          const Color(0xFF7A3CF0).withValues(alpha: 0.42),
                          const Color(0xFFD4A03A).withValues(alpha: 0.48),
                          const Color(0xFFF0C65A).withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.40, 0.72, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white.withValues(alpha: 0.96),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 38),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        IgnorePointer(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 36),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFF0C65A).withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF0C65A).withValues(alpha: 0.35),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
