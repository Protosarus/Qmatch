import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

/// Cosmic assessment shell — calm midnight canvas for MCQ reading.
///
/// Presentation only. Does not own scoring, navigation, or persistence.
class QAssessmentScaffold extends StatelessWidget {
  const QAssessmentScaffold({
    super.key,
    required this.child,
    this.maxContentWidth = 480,
    this.richBackdrop = false,
    this.backgroundImageAsset,
  });

  final Widget child;
  final double maxContentWidth;
  /// Richer nebula / planet wash for IQ question reference look.
  final bool richBackdrop;
  /// Optional full-bleed cosmic photo (e.g. IQ question nebula + planet).
  final String? backgroundImageAsset;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.midnightNavy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _AssessmentBackdrop(
              rich: richBackdrop,
              backgroundImageAsset: backgroundImageAsset,
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final padH = (constraints.maxWidth * 0.05).clamp(16.0, 22.0);
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidth,
                        maxHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padH, 4, padH, 8),
                        child: child,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentBackdrop extends StatelessWidget {
  const _AssessmentBackdrop({
    this.rich = false,
    this.backgroundImageAsset,
  });

  final bool rich;
  final String? backgroundImageAsset;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = backgroundImageAsset != null;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.cosmicBackgroundGradient,
            ),
          ),
          if (hasPhoto)
            Positioned.fill(
              child: Image.asset(
                backgroundImageAsset!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
              ),
            ),
          if (!hasPhoto) ...[
            // Soft planet / glow — top left
            Positioned(
              top: rich ? -40 : -80,
              left: rich ? -50 : -30,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: rich ? 40 : 55,
                  sigmaY: rich ? 40 : 55,
                ),
                child: Container(
                  width: rich ? 200 : 180,
                  height: rich ? 200 : 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.electricBlue.withValues(
                      alpha: rich ? 0.20 : 0.12,
                    ),
                  ),
                ),
              ),
            ),
            // Nebula wash — top right
            Positioned(
              top: rich ? -90 : -80,
              right: rich ? -70 : -60,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  width: rich ? 280 : 220,
                  height: rich ? 260 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.resonanceViolet.withValues(
                      alpha: rich ? 0.38 : 0.22,
                    ),
                  ),
                ),
              ),
            ),
            if (rich)
              Positioned(
                top: 80,
                right: -20,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 40,
              left: -40,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.secondary.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            if (rich) const CustomPaint(painter: _StarDustPainter()),
          ],
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hasPhoto
                    ? const [
                        Color(0x440A0F1C),
                        Color(0x330A0F1C),
                        Color(0xBB08060F),
                      ]
                    : const [
                        Color(0x660A0F1C),
                        Color(0x220A0F1C),
                        Color(0x990C0C0C),
                      ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarDustPainter extends CustomPainter {
  const _StarDustPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const seeds = <(double, double, double, double)>[
      (0.12, 0.18, 1.0, 0.35),
      (0.28, 0.12, 0.7, 0.28),
      (0.72, 0.22, 0.9, 0.32),
      (0.88, 0.16, 0.6, 0.25),
      (0.18, 0.42, 0.5, 0.22),
      (0.65, 0.38, 0.8, 0.30),
      (0.92, 0.48, 0.55, 0.20),
      (0.08, 0.62, 0.7, 0.24),
      (0.45, 0.08, 0.6, 0.26),
      (0.78, 0.55, 0.5, 0.18),
    ];
    for (final (nx, ny, r, a) in seeds) {
      paint.color = Color.fromRGBO(230, 225, 255, a);
      canvas.drawCircle(Offset(nx * size.width, ny * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
