import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import 'frequency_question_chrome.dart';

/// IQ question-screen chrome — presentation only; host owns selection / next.
class IqQuestionTopBar extends StatelessWidget {
  const IqQuestionTopBar({super.key, this.onBack});

  /// When null, no back control is shown (forward-only active questions).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
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
    final minH = compact ? 44.0 : 54.0;
    final vPad = compact ? 10.0 : 14.0;
    final badge = compact ? 26.0 : 28.0;

    // Match IqContinueButton active gradient brightness.
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
        splashColor: AppColors.resonanceViolet.withValues(alpha: 0.16),
        highlightColor: AppColors.resonanceViolet.withValues(alpha: 0.06),
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
                        : const Color(0x558A90B8),
                    width: 1,
                  ),
                ),
                child: Text(
                  letter,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : const Color(0xFFB8C0D8),
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
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
    return FrequencyContinueButton(
      label: label,
      onPressed: onPressed,
      active: active,
    );
  }
}

/// Question-screen neural hero with brain-clipped breathing lights.
class IqQuestionBreathingHero extends StatefulWidget {
  const IqQuestionBreathingHero({super.key});

  @override
  State<IqQuestionBreathingHero> createState() =>
      _IqQuestionBreathingHeroState();
}

class _IqQuestionBreathingHeroState extends State<IqQuestionBreathingHero>
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
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Square canvas so BoxFit.contain aligns 1:1 with the painter.
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
                  'assets/images/iq_question_neural_hero.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                ),
                CustomPaint(
                  painter: _IqQuestionBrainBreathPainter(_seconds),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sparse breathing sparks clipped to the purple brain (left-facing).
class _IqQuestionBrainBreathPainter extends CustomPainter {
  const _IqQuestionBrainBreathPainter(this.seconds);

  final double seconds;

  /// Few well-spaced hubs — (nx, ny, phase, gold).
  static const _nodes = <(double, double, double, bool)>[
    (0.43, 0.33, 0.00, false),
    (0.58, 0.32, 0.28, true),
    (0.48, 0.42, 0.55, false),
    (0.56, 0.45, 0.78, true),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final brainRect = Rect.fromLTRB(
      size.width * 0.40,
      size.height * 0.27,
      size.width * 0.63,
      size.height * 0.49,
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(brainRect));

    for (var i = 0; i < _nodes.length; i++) {
      final (_, _, phase, gold) = _nodes[i];
      final breath = 0.5 +
          0.5 *
              math.sin(
                seconds * (math.pi * 2 / 3.4) + phase * math.pi * 2,
              );
      final c = _clampToBrain(_drifted(i, size), brainRect);
      final core = gold ? AppColors.softGold : const Color(0xFFE8E4FF);
      final halo = gold
          ? AppColors.softGold.withValues(alpha: 0.10 + breath * 0.28)
          : AppColors.vizIq.withValues(alpha: 0.09 + breath * 0.26);
      final r = 0.9 + breath * 1.05;

      canvas.drawCircle(
        c,
        r + 3.2,
        Paint()
          ..color = halo
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
      );
      canvas.drawCircle(
        c,
        r * 0.75,
        Paint()..color = core.withValues(alpha: 0.35 + breath * 0.40),
      );
    }

    canvas.restore();
  }

  Offset _drifted(int i, Size size) {
    final (nx, ny, phase, _) = _nodes[i];
    final ax = 0.005 + (i % 2) * 0.0015;
    final ay = 0.004 + (i % 3) * 0.0012;
    final periodX = 6.5 + i * 0.7;
    final periodY = 7.2 + i * 0.55;
    final ph = phase * math.pi * 2;
    final dx = ax * math.sin(seconds * (math.pi * 2 / periodX) + ph);
    final dy = ay * math.cos(seconds * (math.pi * 2 / periodY) + ph * 1.1);
    return Offset((nx + dx) * size.width, (ny + dy) * size.height);
  }

  Offset _clampToBrain(Offset o, Rect r) {
    final c = r.center;
    final nx = (o.dx - c.dx) / (r.width * 0.5);
    final ny = (o.dy - c.dy) / (r.height * 0.5);
    final d = math.sqrt(nx * nx + ny * ny);
    if (d <= 0.78 || d == 0) return o;
    final s = 0.78 / d;
    return Offset(
      c.dx + nx * s * r.width * 0.5,
      c.dy + ny * s * r.height * 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _IqQuestionBrainBreathPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}
