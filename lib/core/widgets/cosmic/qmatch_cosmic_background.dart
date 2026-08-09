import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Deterministic star layout for [QMatchCosmicBackground].
@immutable
class CosmicStarSpec {
  const CosmicStarSpec({
    required this.nx,
    required this.ny,
    required this.radius,
    required this.baseOpacity,
    required this.accent,
    required this.phase,
    required this.periodSeconds,
    required this.driftAmplitude,
    required this.driftPeriodSeconds,
    required this.driftPhase,
  });

  /// Normalized X/Y in 0..1.
  final double nx;
  final double ny;
  final double radius;
  final double baseOpacity;
  final bool accent;
  final double phase;
  final double periodSeconds;

  /// Logical-pixel drift radius for subtle motion.
  final double driftAmplitude;
  final double driftPeriodSeconds;
  final double driftPhase;
}

/// Shared cosmic backdrop for main tabs (Discover / Profile) and Settings.
///
/// Not for Chat Detail (dedicated wallpaper). Soft starfield image + breathing
/// / drifting points. Layout seeds stay stable across rebuilds.
class QMatchCosmicBackground extends StatefulWidget {
  const QMatchCosmicBackground({
    super.key,
    required this.child,
    this.seed = 42,
    this.animate,
    this.starCount = 18,
    this.debugTimeSeconds,
    this.showStarfieldImage = true,
    this.starfieldOpacity = 0.42,
    this.showAccentHalos = true,
  });

  static const String starfieldAsset =
      'assets/images/qmatch_main_cosmic_starfield.png';

  final Widget child;

  /// Deterministic layout seed (tests / goldens).
  final int seed;

  /// When null, follows [TickerMode] + [MediaQuery.disableAnimations].
  final bool? animate;

  /// Total breathing points (target ~14–20 on phone).
  final int starCount;

  /// Test/golden-only static frame snapshot.
  final double? debugTimeSeconds;

  /// Soft painted starfield under the animated points.
  final bool showStarfieldImage;

  /// Opacity for [starfieldAsset] when shown.
  final double starfieldOpacity;

  /// Large soft accent blooms (can read as bright white blobs).
  final bool showAccentHalos;

  /// Builds the frozen star list for [seed] (testable).
  static List<CosmicStarSpec> starsFor({
    required int seed,
    int count = 18,
  }) {
    final rng = math.Random(seed);
    final stars = <CosmicStarSpec>[];
    for (var i = 0; i < count; i++) {
      final accent = i < 5;
      stars.add(
        CosmicStarSpec(
          nx: rng.nextDouble(),
          ny: rng.nextDouble(),
          radius: accent
              ? 2.0 + rng.nextDouble() * 2.2
              : 1.3 + rng.nextDouble() * 1.6,
          baseOpacity: accent
              ? 0.34 + rng.nextDouble() * 0.18
              : 0.16 + rng.nextDouble() * 0.14,
          accent: accent,
          phase: rng.nextDouble() * math.pi * 2,
          periodSeconds: 3.8 + rng.nextDouble() * 3.4,
          driftAmplitude: accent
              ? 3.0 + rng.nextDouble() * 3.5
              : 1.6 + rng.nextDouble() * 2.6,
          driftPeriodSeconds: 8.0 + rng.nextDouble() * 8.0,
          driftPhase: rng.nextDouble() * math.pi * 2,
        ),
      );
    }
    return List<CosmicStarSpec>.unmodifiable(stars);
  }

  static double opacityFor(
    CosmicStarSpec star, {
    required double timeSeconds,
    required bool breathing,
  }) {
    if (!breathing) return star.baseOpacity;
    final wave =
        math.sin((timeSeconds / star.periodSeconds) * math.pi * 2 + star.phase);
    final t = (wave + 1) / 2;
    final minOpacity = star.accent
        ? math.max(0.18, star.baseOpacity * 0.48)
        : math.max(0.10, star.baseOpacity * 0.52);
    final maxOpacity = star.accent
        ? math.min(0.72, star.baseOpacity * 1.45)
        : math.min(0.42, star.baseOpacity * 1.55);
    return (minOpacity + (maxOpacity - minOpacity) * t).clamp(0.10, 0.72);
  }

  /// Soft positional drift in logical pixels (stable seed, time-driven).
  static Offset offsetFor(
    CosmicStarSpec star, {
    required double timeSeconds,
    required bool drifting,
  }) {
    if (!drifting) return Offset.zero;
    final angle =
        (timeSeconds / star.driftPeriodSeconds) * math.pi * 2 + star.driftPhase;
    return Offset(
      math.cos(angle) * star.driftAmplitude,
      math.sin(angle * 1.17) * star.driftAmplitude * 0.72,
    );
  }

  @override
  State<QMatchCosmicBackground> createState() => _QMatchCosmicBackgroundState();
}

class _QMatchCosmicBackgroundState extends State<QMatchCosmicBackground>
    with SingleTickerProviderStateMixin {
  static const int _loopSeconds = 60;

  late List<CosmicStarSpec> _stars;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _stars = QMatchCosmicBackground.starsFor(
      seed: widget.seed,
      count: widget.starCount.clamp(14, 22),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant QMatchCosmicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.starCount != widget.starCount) {
      _stars = QMatchCosmicBackground.starsFor(
        seed: widget.seed,
        count: widget.starCount.clamp(14, 22),
      );
    }
    _syncController();
  }

  bool get _shouldAnimate {
    if (widget.animate != null) return widget.animate!;
    final mq = MediaQuery.maybeOf(context);
    if (mq?.disableAnimations == true) return false;
    // ignore: deprecated_member_use
    if (!TickerMode.of(context)) return false;
    return true;
  }

  void _syncController() {
    final want = _shouldAnimate;
    if (want) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: _loopSeconds),
      )..repeat();
      if (!_controller!.isAnimating) {
        _controller!.repeat();
      }
    } else {
      _controller?.stop();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = _shouldAnimate;
    final listenable = animate && _controller != null
        ? _controller!
        : const AlwaysStoppedAnimation<double>(0);
    final timeSeconds = widget.debugTimeSeconds ??
        (animate ? (_controller?.value ?? 0) * _loopSeconds : 0.0);
    final motion = widget.debugTimeSeconds == null && animate;

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.cosmicBlack),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.midnightNavy,
                AppColors.cosmicBlack,
                Color(0xFF08060F),
              ],
            ),
          ),
        ),
        if (widget.showStarfieldImage)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: widget.starfieldOpacity.clamp(0.0, 1.0),
                child: Image.asset(
                  QMatchCosmicBackground.starfieldAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: listenable,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CosmicStarsPainter(
                      stars: _stars,
                      timeSeconds: timeSeconds,
                      motion: motion,
                      showAccentHalos: widget.showAccentHalos,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.55, -0.65),
                  radius: 1.15,
                  colors: [
                    AppColors.resonanceViolet.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, 0.55),
                  radius: 1.0,
                  colors: [
                    AppColors.deepIndigo.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _CosmicStarsPainter extends CustomPainter {
  _CosmicStarsPainter({
    required this.stars,
    required this.timeSeconds,
    required this.motion,
    required this.showAccentHalos,
  });

  final List<CosmicStarSpec> stars;
  final double timeSeconds;
  final bool motion;
  final bool showAccentHalos;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in stars) {
      final drift = QMatchCosmicBackground.offsetFor(
        star,
        timeSeconds: timeSeconds,
        drifting: motion,
      );
      final x = star.nx * size.width + drift.dx;
      final y = star.ny * size.height + drift.dy;
      final opacity = QMatchCosmicBackground.opacityFor(
        star,
        timeSeconds: timeSeconds,
        breathing: motion,
      );

      if (showAccentHalos && star.accent) {
        paint.color = Color.fromRGBO(200, 210, 255, opacity * 0.08);
        canvas.drawCircle(Offset(x, y), star.radius * 1.35, paint);
      }

      paint.color = Color.fromRGBO(214, 220, 242, opacity * 0.55);
      canvas.drawCircle(Offset(x, y), star.radius * 0.7, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicStarsPainter oldDelegate) {
    return oldDelegate.timeSeconds != timeSeconds ||
        oldDelegate.motion != motion ||
        oldDelegate.showAccentHalos != showAccentHalos ||
        !identical(oldDelegate.stars, stars);
  }
}
