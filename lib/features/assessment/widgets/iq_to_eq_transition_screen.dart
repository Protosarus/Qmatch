import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen IQ → EQ handoff — presentation only; host owns navigation.
///
/// Non-dismissible: no close control; system back / barrier tap must not exit.
class IqToEqTransitionScreen extends StatelessWidget {
  const IqToEqTransitionScreen({
    super.key,
    required this.onStartEq,
  });

  final VoidCallback onStartEq;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = MediaQuery.sizeOf(context).height;
    final brainH = (h * 0.32).clamp(200.0, 268.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // Swallow system back / predictive-back — EQ CTA is the only exit.
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0618),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _TransitionBackdrop(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      // Smaller top spacer (~40–50px lift vs previous flex:2).
                      const Spacer(flex: 1),
                      SizedBox(
                        height: brainH,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: Size(brainH * 1.12, brainH * 1.12),
                              painter: const _RadarRingsPainter(),
                            ),
                            SizedBox(
                              height: brainH * 0.88,
                              width: brainH * 0.88,
                              child: const _BreathingNeuralCore(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _IqCompletedSweepTitle(text: l10n.iqTestCompleted),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          l10n.iqToEqMessage,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFB8B0CC),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            height: 1.42,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _AssessmentStageRail(
                        iqLabel: l10n.assessmentStageIq,
                        eqLabel: l10n.assessmentStageEq,
                        frequencyLabel: l10n.assessmentStageFrequency,
                      ),
                      // Keep CTA near content — avoid a lonely bottom island.
                      const Spacer(flex: 2),
                      _EqStartCta(
                        label: l10n.continueToEqAssessment,
                        onPressed: onStartEq,
                      ),
                    ],
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

/// Visual-only IQ → EQ → Frequency stage strip (no navigation).
class _AssessmentStageRail extends StatelessWidget {
  const _AssessmentStageRail({
    required this.iqLabel,
    required this.eqLabel,
    required this.frequencyLabel,
  });

  final String iqLabel;
  final String eqLabel;
  final String frequencyLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StageChip(
          label: iqLabel,
          state: _StageVisualState.done,
        ),
        const _StageConnector(tone: _ConnectorTone.completed),
        _StageChip(
          label: eqLabel,
          state: _StageVisualState.current,
        ),
        const _StageConnector(tone: _ConnectorTone.upcoming),
        _StageChip(
          label: frequencyLabel,
          state: _StageVisualState.upcoming,
        ),
      ],
    );
  }
}

enum _StageVisualState { done, current, upcoming }

enum _ConnectorTone { completed, upcoming }

class _StageConnector extends StatelessWidget {
  const _StageConnector({required this.tone});

  final _ConnectorTone tone;

  @override
  Widget build(BuildContext context) {
    final color = tone == _ConnectorTone.completed
        ? AppColors.resonanceViolet.withValues(alpha: 0.55)
        : const Color(0x8A8A90B8); // ~54% — quiet bridge to Frequency

    return Container(
      width: 22,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: color,
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.state,
  });

  final String label;
  final _StageVisualState state;

  @override
  Widget build(BuildContext context) {
    final isDone = state == _StageVisualState.done;
    final isCurrent = state == _StageVisualState.current;

    final Color labelColor;
    final FontWeight weight;
    if (isDone) {
      labelColor = const Color(0xFFE8D9A8);
      weight = FontWeight.w600;
    } else if (isCurrent) {
      labelColor = Colors.white.withValues(alpha: 0.96);
      weight = FontWeight.w700;
    } else {
      // Passiveive but readable — slightly clearer than EQ-active, still muted.
      labelColor = const Color(0xA38A90B8); // ~64%
      weight = FontWeight.w500;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDone) ...[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  AppColors.resonanceViolet,
                  AppColors.softGold,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.35),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 11,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
        ] else if (isCurrent) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.resonanceViolet,
              boxShadow: [
                BoxShadow(
                  color: AppColors.resonanceViolet.withValues(alpha: 0.55),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ] else ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xA38A90B8),
              border: Border.all(
                color: const Color(0xB38A90B8),
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: GoogleFonts.inter(
            color: labelColor,
            fontSize: isCurrent ? 12.5 : 12,
            fontWeight: weight,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _EqStartCta extends StatelessWidget {
  const _EqStartCta({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const iconColor = Color(0xF2FFFFFF);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.resonanceViolet.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.softGold.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.pillBorder,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppRadii.pillBorder,
              child: Ink(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.pillBorder,
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF4B1FE0).withValues(alpha: 0.72),
                      const Color(0xFF7A3CF0).withValues(alpha: 0.65),
                      const Color(0xFFB8944A).withValues(alpha: 0.55),
                      const Color(0xFFE3C565).withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.42, 0.78, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0x99B8A0FF),
                    width: 1.1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.2),
                          border: Border.all(
                            color: AppColors.softGold.withValues(alpha: 0.55),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: iconColor,
                      ),
                      const SizedBox(width: 8),
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

class _TransitionBackdrop extends StatelessWidget {
  const _TransitionBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF120A28),
                  Color(0xFF0A0618),
                  Color(0xFF06040F),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.resonanceViolet.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          const CustomPaint(painter: _StarFieldPainter()),
          Align(
            alignment: const Alignment(0, -0.12),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 40),
              child: Container(
                width: 90,
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.resonanceViolet.withValues(alpha: 0.0),
                      AppColors.resonanceViolet.withValues(alpha: 0.18),
                      AppColors.resonanceViolet.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const seeds = <(double, double, double, double)>[
      (0.12, 0.16, 1.1, 0.35),
      (0.28, 0.10, 0.7, 0.25),
      (0.72, 0.14, 0.9, 0.30),
      (0.88, 0.22, 0.6, 0.22),
      (0.18, 0.38, 0.5, 0.20),
      (0.65, 0.42, 0.8, 0.28),
      (0.92, 0.48, 0.55, 0.18),
      (0.08, 0.58, 0.7, 0.22),
      (0.45, 0.08, 0.6, 0.24),
      (0.78, 0.62, 0.5, 0.16),
      (0.35, 0.72, 0.65, 0.18),
      (0.55, 0.85, 0.7, 0.20),
    ];
    for (final (nx, ny, r, a) in seeds) {
      paint.color = Color.fromRGBO(230, 220, 255, a);
      canvas.drawCircle(Offset(nx * size.width, ny * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RadarRingsPainter extends CustomPainter {
  const _RadarRingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 1; i <= 4; i++) {
      final t = i / 4.0;
      paint.color = Color.fromRGBO(180, 160, 255, 0.10 + (1 - t) * 0.08);
      canvas.drawCircle(center, maxR * (0.42 + t * 0.52), paint);
    }

    paint.strokeWidth = 1.2;
    paint.color = const Color.fromRGBO(200, 180, 255, 0.22);
    final outer = maxR * 0.96;
    const count = 64;
    for (var i = 0; i < count; i++) {
      if (i.isOdd) continue;
      final a0 = (i / count) * math.pi * 2;
      final a1 = ((i + 0.45) / count) * math.pi * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft gleam on existing brain-mesh nodes — no extra field of lights.
class _BreathingNeuralCore extends StatefulWidget {
  const _BreathingNeuralCore();

  @override
  State<_BreathingNeuralCore> createState() => _BreathingNeuralCoreState();
}

class _BreathingNeuralCoreState extends State<_BreathingNeuralCore>
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/iq_complete_neural_core.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
        ),
        // Explicit fill — CustomPaint alone can collapse to Size.zero
        // under some Stack constraint paths, killing the overlay.
        Positioned.fill(
          child: CustomPaint(
            painter: _NeuralCoreNodeGleamPainter(_seconds),
          ),
        ),
      ],
    );
  }
}

/// Headline: dim stage → follow-spot sweeps left→right → stays lit.
class _IqCompletedSweepTitle extends StatefulWidget {
  const _IqCompletedSweepTitle({required this.text});

  final String text;

  @override
  State<_IqCompletedSweepTitle> createState() => _IqCompletedSweepTitleState();
}

class _IqCompletedSweepTitleState extends State<_IqCompletedSweepTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Stage dark vs follow-spot (theatrical wash).
  static const _dark = Color(0xFF2A243C);
  static const _lit = Color(0xFFF8F4FF);
  static const _spotRim = Color(0xFFB8A0FF);
  static const _spotCore = Color(0xFFFFF6E0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      // A touch slower than before — still present, not draggy.
      duration: const Duration(milliseconds: 3400),
    );
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.playfairDisplay(
      color: Colors.white,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.22,
    );

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Ease that eases in/out like a slow follow-spot pan.
        final u = Curves.easeInOut.transform(_ctrl.value);

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            if (u >= 0.999) {
              return const LinearGradient(
                colors: [_lit, _lit],
              ).createShader(bounds);
            }
            if (u <= 0.001) {
              return const LinearGradient(
                colors: [_dark, _dark],
              ).createShader(bounds);
            }

            // Spot center travels left → right (reading direction).
            // 0 = sentence start, 1 = sentence end.
            final spot = u;
            // Soft theatrical beam width (~28% of title).
            const half = 0.14;

            final sLitL = (spot - half - 0.05).clamp(0.0, 1.0);
            final sRimL = (spot - half).clamp(0.0, 1.0);
            final sCoreL = (spot - half * 0.35).clamp(0.0, 1.0);
            final sCore = spot.clamp(0.0, 1.0);
            final sCoreR = (spot + half * 0.35).clamp(0.0, 1.0);
            final sRimR = (spot + half).clamp(0.0, 1.0);
            final sDarkR = (spot + half + 0.06).clamp(0.0, 1.0);

            final stops = <double>[0.0];
            final colors = <Color>[_lit];
            void push(double s, Color c) {
              if (s <= stops.last + 0.0005) {
                colors[colors.length - 1] = c;
                return;
              }
              stops.add(s);
              colors.add(c);
            }

            // Left of spot: already revealed — stays lit.
            push(sLitL, _lit);
            // Entering the beam.
            push(sRimL, _spotRim);
            push(sCoreL, _spotCore);
            // Hot center of the follow-spot.
            push(sCore, Colors.white);
            push(sCoreR, _spotCore);
            push(sRimR, _spotRim);
            // Right of spot: still in shadow (not yet read).
            push(sDarkR, _dark);
            push(1.0, _dark);

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: colors,
              stops: stops,
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: baseStyle,
      ),
    );
  }
}

/// Opacity + halo pulse locked to sampled bright nodes in the brain mesh.
class _NeuralCoreNodeGleamPainter extends CustomPainter {
  const _NeuralCoreNodeGleamPainter(this.seconds);

  final double seconds;

  /// Calibrated to existing interior starburst nodes (nx, ny, phase).
  static const _nodes = <(double, double, double)>[
    (0.504, 0.259, 0.00),
    (0.317, 0.454, 0.17),
    (0.685, 0.454, 0.34),
    (0.507, 0.348, 0.50),
    (0.417, 0.527, 0.67),
    (0.582, 0.524, 0.84),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final side = size.shortestSide;
    final brainRect = Rect.fromLTRB(
      size.width * 0.26,
      size.height * 0.18,
      size.width * 0.74,
      size.height * 0.72,
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(brainRect));

    for (var i = 0; i < _nodes.length; i++) {
      final (nx, ny, phase) = _nodes[i];
      // Clear inhale/exhale — previously ~1–2px dots were invisible on flares.
      final breath = 0.5 +
          0.5 *
              math.sin(
                seconds * (math.pi * 2 / 2.8) + phase * math.pi * 2,
              );
      final c = Offset(nx * size.width, ny * size.height);

      final outerR = side * (0.028 + breath * 0.022);
      final midR = side * (0.014 + breath * 0.010);
      final coreR = side * (0.006 + breath * 0.004);

      // Soft violet bloom — readable against already-bright baked nodes.
      canvas.drawCircle(
        c,
        outerR,
        Paint()
          ..color = AppColors.vizIq.withValues(alpha: 0.18 + breath * 0.42)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.028)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        c,
        midR,
        Paint()
          ..color = const Color(0xFFC8B8FF).withValues(
            alpha: 0.22 + breath * 0.48,
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.012)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        c,
        coreR,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35 + breath * 0.55)
          ..blendMode = BlendMode.plus,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeuralCoreNodeGleamPainter oldDelegate) =>
      oldDelegate.seconds != seconds;
}
