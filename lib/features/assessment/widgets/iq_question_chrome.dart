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
      height: 44,
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
                    color: const Color(0x66101828),
                    border: Border.all(
                      color: const Color(0x779B8CFF),
                      width: 1,
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
            width: 38,
            height: 38,
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
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
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
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padH = compact ? 14.0 : 16.0;
    final padV = compact ? 12.0 : 14.0;
    // Readable sans size — scales lightly with width, floors for small phones.
    final screenW = MediaQuery.sizeOf(context).width;
    final qSize = (screenW * 0.040).clamp(14.5, compact ? 15.5 : 16.5);

    return ClipRRect(
      borderRadius: AppRadii.cardBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(padH, padV, padH, padV),
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
              color: const Color(0x66C4B0FF),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.start,
            softWrap: true,
            style: GoogleFonts.inter(
              color: const Color(0xFFE8E6F0),
              fontSize: qSize,
              fontWeight: FontWeight.w500,
              height: 1.34,
              letterSpacing: 0.05,
            ),
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
        child: Container(
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
    this.active = true,
  });

  final String label;
  final VoidCallback onPressed;
  /// Visual emphasis when an answer is selected (logic still owned by host).
  final bool active;

  @override
  Widget build(BuildContext context) {
    final glowV = active ? 0.38 : 0.14;
    final glowG = active ? 0.22 : 0.08;
    final tint = active ? 1.0 : 0.52;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: active ? 1.0 : 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.pillBorder,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4B1FE0).withValues(alpha: glowV),
              blurRadius: active ? 20 : 10,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFFF0C65A).withValues(alpha: glowG),
              blurRadius: active ? 16 : 8,
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
                        Color.fromRGBO(75, 31, 224, 0.52 * tint),
                        Color.fromRGBO(122, 60, 240, 0.42 * tint),
                        Color.fromRGBO(212, 160, 58, 0.48 * tint),
                        Color.fromRGBO(240, 198, 90, 0.55 * tint),
                      ],
                      stops: const [0.0, 0.40, 0.72, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: active ? 0.28 : 0.16,
                      ),
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
    );
  }
}
