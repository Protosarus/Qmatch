import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// World map plate + breathing city hubs — shared by phone signup & email login.
class AuthWorldMapAccent extends StatefulWidget {
  const AuthWorldMapAccent({super.key});

  @override
  State<AuthWorldMapAccent> createState() => _AuthWorldMapAccentState();
}

class _AuthWorldMapAccentState extends State<AuthWorldMapAccent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    // Continuous cycle — city hubs inhale/exhale, map stays still.
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    // Height from full screen width; map bleeds past column padding L/R equally.
    final mapH = (screenW * 0.58).clamp(230.0, 290.0);

    return SizedBox(
      height: mapH,
      width: double.infinity,
      child: OverflowBox(
        minWidth: screenW,
        maxWidth: screenW,
        alignment: Alignment.center,
        child: SizedBox(
          width: screenW,
          height: mapH,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              // Soft edge only at the very screen sides — map yaslanır L/R.
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0x00FFFFFF),
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 0.7),
                  const Color(0x00FFFFFF),
                ],
                stops: const [0.0, 0.03, 0.08, 0.92, 0.97, 1.0],
              ).createShader(bounds);
            },
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x00FFFFFF),
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white,
                    Colors.white,
                    Colors.white.withValues(alpha: 0.45),
                    const Color(0x00FFFFFF),
                  ],
                  stops: const [0.0, 0.10, 0.22, 0.78, 0.90, 1.0],
                ).createShader(bounds);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/phone_signup_world_map.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                  AnimatedBuilder(
                    animation: _breath,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _BreathingCityLightsPainter(_breath.value),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingCityLightsPainter extends CustomPainter {
  const _BreathingCityLightsPainter(this.t);

  final double t;

  /// Normalized hubs on the equirectangular art (nx, ny, phase, gold?).
  static const _hubs = <(double, double, double, bool)>[
    (0.22, 0.36, 0.00, false), // NYC
    (0.14, 0.40, 0.18, true), // LA
    (0.28, 0.70, 0.35, false), // Sao Paulo
    (0.48, 0.30, 0.52, false), // London
    (0.56, 0.36, 0.12, true), // Istanbul
    (0.50, 0.54, 0.68, false), // Lagos
    (0.68, 0.40, 0.28, false), // Delhi
    (0.84, 0.36, 0.45, true), // Tokyo
    (0.84, 0.68, 0.72, false), // Sydney
    (0.36, 0.42, 0.88, false), // Mexico City-ish
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (nx, ny, phase, gold) in _hubs) {
      final breath =
          0.5 + 0.5 * math.sin((t + phase) * math.pi * 2); // 0..1
      final c = Offset(nx * size.width, ny * size.height);
      final core = gold ? AppColors.softGold : const Color(0xFFE8E4FF);
      final halo = gold
          ? AppColors.softGold.withValues(alpha: 0.22 + breath * 0.38)
          : AppColors.resonanceViolet.withValues(alpha: 0.18 + breath * 0.32);
      final r = 2.0 + breath * 2.4;

      canvas.drawCircle(
        c,
        r + 5.5,
        Paint()
          ..color = halo
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()..color = core.withValues(alpha: 0.55 + breath * 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BreathingCityLightsPainter oldDelegate) =>
      oldDelegate.t != t;
}
