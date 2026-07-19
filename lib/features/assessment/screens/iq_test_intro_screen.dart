import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radii.dart';
import '../../../l10n/app_localizations.dart';
import 'iq_test_screen.dart';

/// Cosmic IQ intro — copy hierarchy only; navigation / start flow unchanged.
class IQTestIntroScreen extends StatelessWidget {
  const IQTestIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    // Keep current hero scale — do not enlarge.
    final heroH = (h * 0.36).clamp(210.0, 295.0);
    // Narrow centered band so the headline wraps to ≤2 lines without
    // hard-coded TR/EN line breaks or shrinking the type.
    final headlineMaxW = (size.width * 0.58).clamp(228.0, 268.0);

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
            const _IqIntroBackdrop(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.asset(
                        'assets/images/welcome_q_glow.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    // Tighter Q → brain breath; still not collapsed.
                    const SizedBox(height: 10),
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            height: heroH,
                            width: double.infinity,
                            child: _BreathingNeuralHero(height: heroH),
                          ),
                          // Center copy in the gap between brain and CTA.
                          const Spacer(flex: 2),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: headlineMaxW),
                            child: Text(
                              l10n.iqIntroHeadline,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                height: 1.12,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.resonanceViolet,
                                  Color(0xFFC4B0FF),
                                  AppColors.softGold,
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              l10n.iqIntroLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.iqIntroMeta,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF9A90B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              height: 1.35,
                            ),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                    _CosmicStartButton(
                      label: l10n.iqIntroStart,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const IQTestScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
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

/// Neural head art + soft breathing constellation lights (image unchanged).
class _BreathingNeuralHero extends StatefulWidget {
  const _BreathingNeuralHero({required this.height});

  final double height;

  @override
  State<_BreathingNeuralHero> createState() => _BreathingNeuralHeroState();
}

class _BreathingNeuralHeroState extends State<_BreathingNeuralHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        return Center(
          child: SizedBox(
            height: widget.height,
            width: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/iq_neural_head.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                CustomPaint(
                  painter: _NeuralBreathPainter(_breath.value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NeuralBreathPainter extends CustomPainter {
  const _NeuralBreathPainter(this.t);

  final double t;

  /// Brain-cavity only (right-facing profile). Spread nodes — still inside skull.
  static const _nodes = <(double, double, double, bool)>[
    (0.42, 0.27, 0.00, false),
    (0.52, 0.25, 0.10, true),
    (0.61, 0.28, 0.20, false),
    (0.45, 0.34, 0.30, false),
    (0.55, 0.33, 0.40, true),
    (0.63, 0.36, 0.50, false),
    (0.41, 0.41, 0.60, false),
    (0.50, 0.42, 0.70, false),
    (0.58, 0.44, 0.80, true),
    (0.48, 0.48, 0.90, false),
  ];

  /// Synapse edges between brain nodes (index pairs).
  static const _edges = <(int, int)>[
    (0, 1),
    (1, 2),
    (0, 3),
    (1, 4),
    (2, 5),
    (3, 4),
    (4, 5),
    (3, 6),
    (4, 7),
    (5, 8),
    (6, 7),
    (7, 8),
    (7, 9),
    (8, 9),
    (1, 7),
    (2, 4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Cranial oval — a touch wider so spread nodes stay clipped to brain.
    final brainRect = Rect.fromLTRB(
      size.width * 0.38,
      size.height * 0.22,
      size.width * 0.66,
      size.height * 0.52,
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(brainRect),
    );

    Offset p(double nx, double ny) =>
        Offset(nx * size.width, ny * size.height);

    // Soft synaptic filaments + traveling signal dots.
    for (var e = 0; e < _edges.length; e++) {
      final (ia, ib) = _edges[e];
      final a = p(_nodes[ia].$1, _nodes[ia].$2);
      final b = p(_nodes[ib].$1, _nodes[ib].$2);

      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = AppColors.vizIq.withValues(alpha: 0.18)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // Pulse travels a→b, then a second phase the other way.
      final u = (t * 1.15 + e * 0.07) % 1.0;
      final v = (t * 1.15 + e * 0.07 + 0.5) % 1.0;
      _signal(canvas, a, b, u, gold: e.isEven);
      _signal(canvas, b, a, v, gold: !e.isEven);
    }

    // Breathing hubs — only on brain nodes.
    for (final (nx, ny, phase, gold) in _nodes) {
      final breath = 0.5 + 0.5 * math.sin((t + phase) * math.pi * 2);
      final c = p(nx, ny);
      final core = gold ? AppColors.softGold : const Color(0xFFE8E4FF);
      final halo = gold
          ? AppColors.softGold.withValues(alpha: 0.20 + breath * 0.45)
          : AppColors.vizIq.withValues(alpha: 0.18 + breath * 0.40);
      final r = 1.4 + breath * 1.8;

      canvas.drawCircle(
        c,
        r + 4.5,
        Paint()
          ..color = halo
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
      );
      canvas.drawCircle(
        c,
        r * 0.85,
        Paint()..color = core.withValues(alpha: 0.50 + breath * 0.50),
      );
    }

    canvas.restore();
  }

  void _signal(
    Canvas canvas,
    Offset a,
    Offset b,
    double u, {
    required bool gold,
  }) {
    final pos = Offset.lerp(a, b, u)!;
    final col = gold ? AppColors.softGold : AppColors.vizIq;
    canvas.drawCircle(
      pos,
      3.2,
      Paint()
        ..color = col.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawCircle(
      pos,
      1.35,
      Paint()..color = col.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _NeuralBreathPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _CosmicStartButton extends StatefulWidget {
  const _CosmicStartButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_CosmicStartButton> createState() => _CosmicStartButtonState();
}

class _CosmicStartButtonState extends State<_CosmicStartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_breath.value);
        // Noticeable but contained — stronger pulse, tighter blur.
        final glow = 0.28 + (t * 0.18);
        final blur = 10.0 + (t * 5.0);
        final opacity = 0.90 + (t * 0.10);
        final spread = t * 0.4;

        return Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.pillBorder,
              gradient: AppGradients.cosmicCtaGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.softGold.withValues(alpha: glow * 0.9),
                  blurRadius: blur,
                  spreadRadius: spread,
                  offset: const Offset(2, 3),
                ),
                BoxShadow(
                  color: AppColors.resonanceViolet.withValues(alpha: glow),
                  blurRadius: blur + 1,
                  spreadRadius: spread * 0.6,
                  offset: const Offset(-1, 2),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: AppRadii.pillBorder,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Center(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IqIntroBackdrop extends StatelessWidget {
  const _IqIntroBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.cosmicBackgroundGradient,
            ),
          ),
          Positioned(
            top: -50,
            left: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.electricBlue.withValues(alpha: 0.16),
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.resonanceViolet.withValues(alpha: 0.30),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.softGold.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x440A0F1C),
                  Color(0x180A0F1C),
                  Color(0x990C0C0C),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
