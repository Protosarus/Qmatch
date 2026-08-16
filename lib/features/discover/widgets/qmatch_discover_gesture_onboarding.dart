import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_cosmic_button.dart';

/// First-visit holographic swipe tutorial. Presentation only.
class QMatchDiscoverGestureOnboarding extends StatefulWidget {
  const QMatchDiscoverGestureOnboarding({
    super.key,
    required this.swipeRightText,
    required this.swipeLeftText,
    required this.gotItLabel,
    required this.onCompleted,
    this.animate = true,
  });

  final String swipeRightText;
  final String swipeLeftText;
  final String gotItLabel;
  final VoidCallback onCompleted;
  final bool animate;

  static const Duration autoAdvanceAfter = Duration(milliseconds: 2600);
  static const Duration motionDuration = Duration(milliseconds: 1100);

  @override
  State<QMatchDiscoverGestureOnboarding> createState() =>
      _QMatchDiscoverGestureOnboardingState();
}

class _QMatchDiscoverGestureOnboardingState
    extends State<QMatchDiscoverGestureOnboarding>
    with SingleTickerProviderStateMixin {
  static const int _stepLike = 0;
  static const int _stepPass = 1;

  late final AnimationController _motion;
  int _step = _stepLike;
  Timer? _autoAdvance;

  bool get _isLikeStep => _step == _stepLike;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: QMatchDiscoverGestureOnboarding.motionDuration,
    );
    if (widget.animate) {
      _motion.repeat(reverse: true);
      _armAutoAdvance();
    } else {
      _motion.value = 0.55;
    }
  }

  @override
  void didUpdateWidget(QMatchDiscoverGestureOnboarding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate && !widget.animate) {
      _autoAdvance?.cancel();
      _motion.stop();
      _motion.value = 0.55;
    }
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _motion.dispose();
    super.dispose();
  }

  void _armAutoAdvance() {
    _autoAdvance?.cancel();
    if (!widget.animate || !_isLikeStep) return;
    _autoAdvance = Timer(
      QMatchDiscoverGestureOnboarding.autoAdvanceAfter,
      _goToPassStep,
    );
  }

  void _goToPassStep() {
    if (!mounted || !_isLikeStep) return;
    _autoAdvance?.cancel();
    setState(() => _step = _stepPass);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      key: const Key('qmatch-discover-gesture-onboarding'),
      behavior: HitTestBehavior.opaque,
      onTap: _isLikeStep ? _goToPassStep : null,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, _) {
          final t = (!widget.animate || reduceMotion) ? 0.55 : _motion.value;
          final dx = (_isLikeStep ? 1.0 : -1.0) * (18 + (t * 22));
          final rotation = (_isLikeStep ? 1.0 : -1.0) * 0.045 * t;
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.midnightNavy.withValues(alpha: 0.18),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(dx, -6 * t),
                  child: Transform.rotate(
                    angle: rotation,
                    child: _HolographicGhostCard(likeStep: _isLikeStep),
                  ),
                ),
              ),
              Positioned(
                key: _isLikeStep
                    ? const Key(
                        'qmatch-discover-gesture-onboarding-step-like',
                      )
                    : const Key(
                        'qmatch-discover-gesture-onboarding-step-pass',
                      ),
                top: AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Align(
                  alignment: _isLikeStep
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  child: _GlowCue(
                    key: _isLikeStep
                        ? const Key(
                            'qmatch-discover-gesture-onboarding-heart',
                          )
                        : const Key(
                            'qmatch-discover-gesture-onboarding-pass-icon',
                          ),
                    icon: _isLikeStep
                        ? Icons.favorite_rounded
                        : Icons.close_rounded,
                    color: AppColors.softGold,
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CaptionGlass(
                      text: _isLikeStep
                          ? widget.swipeRightText
                          : widget.swipeLeftText,
                    ),
                    if (!_isLikeStep) ...[
                      const SizedBox(height: AppSpacing.md),
                      QCosmicButton(
                        key: const Key(
                          'qmatch-discover-gesture-onboarding-got-it',
                        ),
                        label: widget.gotItLabel,
                        onPressed: widget.onCompleted,
                        variant: QCosmicButtonVariant.cosmic,
                        expanded: false,
                        height: 48,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HolographicGhostCard extends StatelessWidget {
  const _HolographicGhostCard({required this.likeStep});

  final bool likeStep;

  @override
  Widget build(BuildContext context) {
    final glow = likeStep
        ? AppColors.resonanceViolet.withValues(alpha: 0.42)
        : AppColors.softGold.withValues(alpha: 0.32);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280, maxHeight: 360),
      child: AspectRatio(
        aspectRatio: 0.72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadii.cardBorder,
            color: const Color(0xFF141A2E).withValues(alpha: 0.12),
            border: Border.all(
              color: AppColors.softGold.withValues(alpha: 0.38),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: glow,
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCue extends StatelessWidget {
  const _GlowCue({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.resonanceViolet.withValues(alpha: 0.22),
        border: Border.all(color: AppColors.borderGlow),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 22,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _CaptionGlass extends StatelessWidget {
  const _CaptionGlass({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.buttonBorder,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.buttonBorder,
            color: const Color(0xFF141A2E).withValues(alpha: 0.28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
