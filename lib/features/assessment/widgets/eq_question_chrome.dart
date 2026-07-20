import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// EQ question-screen chrome — presentation only; host owns selection / next.
class EqQuestionTopBar extends StatelessWidget {
  const EqQuestionTopBar({super.key, required this.onBack});

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
                      color: AppColors.vizEq.withValues(alpha: 0.45),
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

class EqQuestionProgressHeader extends StatelessWidget {
  const EqQuestionProgressHeader({
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
        EqSparkProgressBar(value: progress),
      ],
    );
  }
}

class EqSparkProgressBar extends StatelessWidget {
  const EqSparkProgressBar({
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
                  border: Border.all(color: AppColors.vizEq.withValues(alpha: 0.22)),
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
                      AppColors.vizEq,
                      AppColors.softGold,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.vizEq.withValues(alpha: 0.4),
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
                  child: Icon(
                    Icons.psychology_rounded,
                    size: 9,
                    color: AppColors.resonanceViolet.withValues(alpha: 0.9),
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

class EqInsightQuestionCard extends StatelessWidget {
  const EqInsightQuestionCard({
    super.key,
    required this.insightLabel,
    required this.text,
    this.compact = false,
  });

  final String insightLabel;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padH = compact ? 14.0 : 16.0;
    final padV = compact ? 12.0 : 14.0;
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
                const Color(0xCC221838),
                AppColors.glassSurface,
                const Color(0x99101828),
              ],
            ),
            border: Border.all(
              color: AppColors.vizEq.withValues(alpha: 0.42),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.vizEq.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: compact ? 11 : 12,
                    color: AppColors.vizEq.withValues(alpha: 0.88),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    insightLabel,
                    style: GoogleFonts.inter(
                      color: AppColors.vizEq.withValues(alpha: 0.88),
                      fontSize: compact ? 10.5 : 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
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
            ],
          ),
        ),
      ),
    );
  }
}

class EqAnswerOptionRow extends StatelessWidget {
  const EqAnswerOptionRow({
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

  /// Presentation-only shorten — scoring still uses the original option index.
  static String displayLabel(String raw, {int maxChars = 64}) {
    final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= maxChars) return t;
    final cut = t.substring(0, maxChars);
    final sp = cut.lastIndexOf(' ');
    final base = (sp > maxChars ~/ 2 ? cut.substring(0, sp) : cut).trimRight();
    return '$base…';
  }

  @override
  Widget build(BuildContext context) {
    final letter = String.fromCharCode(65 + index);
    final minH = compact ? 44.0 : 54.0;
    final vPad = compact ? 10.0 : 14.0;
    final badge = compact ? 26.0 : 28.0;

    const selectedFill = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color.fromRGBO(75, 31, 224, 0.52),
        Color.fromRGBO(122, 60, 240, 0.42),
        Color.fromRGBO(212, 160, 58, 0.48),
        Color.fromRGBO(240, 198, 90, 0.55),
      ],
      stops: [0.0, 0.40, 0.72, 1.0],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.vizEq.withValues(alpha: 0.16),
        highlightColor: AppColors.vizEq.withValues(alpha: 0.06),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minH),
          padding: EdgeInsets.fromLTRB(12, vPad, 10, vPad),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected ? selectedFill : null,
            color: selected ? null : const Color(0x59101828),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.28)
                  : const Color(0x448A90B8),
              width: 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4B1FE0).withValues(alpha: 0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFF0C65A).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
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
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0x33101828),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.35)
                        : AppColors.vizEq.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  letter,
                  style: GoogleFonts.inter(
                    color: selected
                        ? Colors.white
                        : AppColors.vizEq.withValues(alpha: 0.9),
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
                    fontSize: compact ? 13 : 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    height: 1.22,
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
    );
  }
}

class EqContinueButton extends StatelessWidget {
  const EqContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.active = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final glowV = active ? 0.38 : 0.14;
    final glowG = active ? 0.22 : 0.08;
    final tint = active ? 1.0 : 0.52;

    return Opacity(
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
                            Icons.psychology_rounded,
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

/// Universal EQ figure with a soft pulse traveling brain ↔ heart.
class EqMindHeartFigure extends StatefulWidget {
  const EqMindHeartFigure({super.key});

  @override
  State<EqMindHeartFigure> createState() => _EqMindHeartFigureState();
}

class _EqMindHeartFigureState extends State<EqMindHeartFigure>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _seconds = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _seconds = elapsed.inMicroseconds / 1e6;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/eq_intro_figure.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BrainHeartLinkPainter(_seconds),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Soft traveler along the baked brain–heart axis (normalized to asset).
class _BrainHeartLinkPainter extends CustomPainter {
  const _BrainHeartLinkPainter(this.seconds);

  final double seconds;

  // Calibrated to eq_intro_figure.png (1024²).
  static const _x = 0.502;
  static const _yBrain = 0.30;
  static const _yHeart = 0.64;
  static const _period = 2.8; // seconds for one full up+down cycle

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final side = size.shortestSide;
    // Triangle wave 0→1→0 for seamless brain→heart→brain.
    final cycle = (seconds / _period) % 1.0;
    final t = cycle < 0.5 ? cycle * 2.0 : 2.0 - cycle * 2.0;
    final eased = Curves.easeInOut.transform(t);

    final x = size.width * _x;
    final y = size.height * (_yBrain + (_yHeart - _yBrain) * eased);
    final c = Offset(x, y);

    final breath = 0.55 + 0.45 * math.sin(seconds * math.pi * 2 / 1.6);
    final outerR = side * (0.022 + breath * 0.010);
    final coreR = side * (0.007 + breath * 0.003);

    canvas.drawCircle(
      c,
      outerR,
      Paint()
        ..color = AppColors.softGold.withValues(alpha: 0.22 + breath * 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.018)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      c,
      outerR * 0.55,
      Paint()
        ..color = const Color(0xFFFFF2C8).withValues(alpha: 0.35 + breath * 0.40)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.008)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      c,
      coreR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75 + breath * 0.25)
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  bool shouldRepaint(covariant _BrainHeartLinkPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}
