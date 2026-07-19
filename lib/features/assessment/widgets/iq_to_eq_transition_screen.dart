import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen IQ → EQ handoff — presentation only; host owns navigation.
class IqToEqTransitionScreen extends StatelessWidget {
  const IqToEqTransitionScreen({
    super.key,
    required this.onStartEq,
    required this.onClose,
  });

  final VoidCallback onStartEq;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final h = MediaQuery.sizeOf(context).height;
    final brainH = (h * 0.34).clamp(200.0, 280.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onClose,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      height: brainH,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(brainH * 1.15, brainH * 1.15),
                            painter: const _RadarRingsPainter(),
                          ),
                          Image.asset(
                            'assets/images/iq_complete_neural_core.png',
                            height: brainH * 0.88,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.iqTestCompleted,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white.withValues(alpha: 0.96),
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.iqToEqMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFC8C2D8),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(flex: 3),
                    _EqStartCta(
                      label: l10n.startEqTest.toUpperCase(),
                      onPressed: onStartEq,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                        child: Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.95),
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
          // Soft vertical beam behind brain
          Align(
            alignment: const Alignment(0, -0.15),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 40),
              child: Container(
                width: 90,
                height: 320,
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

    // Dotted outer ring
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
