import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/qmatch_glass_icon_button.dart';

/// Pass / Like action bar for Discover. Handlers are provided by the screen.
///
/// Icon-only: X (pass) on the left, heart (like) on the right.
/// Optional Super Resonance sits between them as a smaller distinct control.
/// This is not a Tinder-style 5-button row.
///
/// [passLabel] / [likeLabel] remain as semantic labels.
///
/// [swipeFeedback] is signed card drag progress (`+` like/right, `-` pass/left).
/// Direct X/heart taps use the same signed activation for a short pulse.
/// Only the matching Like/Pass button animates; Super Resonance stays idle.
class QMatchDiscoverActionBar extends StatefulWidget {
  const QMatchDiscoverActionBar({
    super.key,
    required this.passLabel,
    required this.likeLabel,
    required this.onPass,
    required this.onLike,
    required this.isActionLoading,
    this.rewindLabel,
    this.onRewind,
    this.isRewindLoading = false,
    this.showRewind = false,
    this.subdued = false,
    this.swipeFeedback = 0,
    this.superResonanceLabel,
    this.onSuperResonance,
    this.isSuperResonanceLoading = false,
    this.showSuperResonance = false,
    this.superResonanceBalance = 0,
  });

  /// Short tactile pulse for direct X/heart taps. Independent of fly-off.
  static const Duration tapFeedbackDuration = Duration(milliseconds: 160);

  final String passLabel;
  final String likeLabel;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final bool isActionLoading;

  final String? rewindLabel;
  final VoidCallback? onRewind;
  final bool isRewindLoading;
  final bool showRewind;

  final bool subdued;

  /// `-1..1` from [QMatchDiscoverSwipeableCard] drag progress.
  final double swipeFeedback;

  final String? superResonanceLabel;
  final VoidCallback? onSuperResonance;
  final bool isSuperResonanceLoading;
  final bool showSuperResonance;
  final int superResonanceBalance;

  @override
  State<QMatchDiscoverActionBar> createState() =>
      _QMatchDiscoverActionBarState();
}

class _QMatchDiscoverActionBarState extends State<QMatchDiscoverActionBar> {
  double _tapFeedback = 0;
  Timer? _tapClearTimer;

  @override
  void didUpdateWidget(QMatchDiscoverActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.swipeFeedback != oldWidget.swipeFeedback &&
        widget.swipeFeedback.abs() > 0.05 &&
        _tapFeedback != 0) {
      _tapClearTimer?.cancel();
      _tapFeedback = 0;
    }
  }

  @override
  void dispose() {
    _tapClearTimer?.cancel();
    super.dispose();
  }

  double get _feedback {
    if (_tapFeedback.abs() > 0.05) return _tapFeedback;
    return widget.swipeFeedback;
  }

  void _startTapPulse(double signed) {
    _tapClearTimer?.cancel();
    setState(() => _tapFeedback = signed);
    _tapClearTimer = Timer(QMatchDiscoverActionBar.tapFeedbackDuration, () {
      if (!mounted) return;
      setState(() => _tapFeedback = 0);
    });
  }

  void _onPassPressed() {
    final cb = widget.onPass;
    if (cb == null) return;
    if (_tapFeedback < -0.05) return;
    _startTapPulse(-1);
    cb();
  }

  void _onLikePressed() {
    final cb = widget.onLike;
    if (cb == null) return;
    if (_tapFeedback > 0.05) return;
    _startTapPulse(1);
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    final likeAmount = feedback > 0 ? feedback.clamp(0.0, 1.0) : 0.0;
    final passAmount = feedback < 0 ? (-feedback).clamp(0.0, 1.0) : 0.0;

    return Opacity(
      opacity: widget.subdued ? 0.42 : 1,
      child: Padding(
        key: const Key('qmatch-discover-action-bar'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.showRewind ||
                widget.onRewind != null ||
                widget.isRewindLoading) ...[
              QMatchDiscoverRewindButton(
                semanticLabel: widget.rewindLabel ?? 'Rewind',
                onPressed: widget.onRewind,
                loading: widget.isRewindLoading,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            _DiscoverIconButton(
              buttonKey: const Key('qmatch-discover-pass'),
              icon: Icons.close_rounded,
              semanticLabel: widget.passLabel,
              onPressed: widget.onPass == null ? null : _onPassPressed,
              like: false,
              loading: false,
              activation: passAmount,
            ),
            if (widget.showSuperResonance ||
                widget.onSuperResonance != null ||
                widget.isSuperResonanceLoading) ...[
              const SizedBox(width: AppSpacing.md),
              _SuperResonanceButton(
                semanticLabel: widget.superResonanceLabel ?? '',
                onPressed: widget.onSuperResonance,
                loading: widget.isSuperResonanceLoading,
                balance: widget.superResonanceBalance,
              ),
              const SizedBox(width: AppSpacing.md),
            ] else
              const SizedBox(width: AppSpacing.xxl),
            _DiscoverIconButton(
              buttonKey: const Key('qmatch-discover-like'),
              icon: Icons.favorite_rounded,
              semanticLabel: widget.likeLabel,
              onPressed: widget.onLike == null ? null : _onLikePressed,
              like: true,
              loading: widget.isActionLoading,
              activation: likeAmount,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverIconButton extends StatelessWidget {
  const _DiscoverIconButton({
    required this.buttonKey,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    required this.like,
    required this.loading,
    required this.activation,
  });

  final Key buttonKey;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool like;
  final bool loading;
  final double activation;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final enabled = onPressed != null && !loading;
    final t = loading ? 0.0 : activation.clamp(0.0, 1.0);
    final active = t > 0.05;

    final idleFill = QMatchGlassIconButton.glassFill;
    final activeFill = like
        ? AppColors.resonanceViolet.withValues(alpha: 0.88)
        : AppColors.danger.withValues(alpha: 0.72);
    final idleBorder = QMatchGlassIconButton.coolBorder;
    final activeBorder = like
        ? AppColors.softGold.withValues(alpha: 0.42)
        : AppColors.danger.withValues(alpha: 0.78);
    final idleIcon = QMatchGlassIconButton.iconDefault;
    final activeIcon = AppColors.textPrimary;

    final face = loading
        ? const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary,
                ),
              ),
            ),
          )
        : Icon(
            icon,
            size: 26,
            color: Color.lerp(idleIcon, activeIcon, t),
          );

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: Color.lerp(idleFill, activeFill, t),
      border: Border.all(
        color: Color.lerp(idleBorder, activeBorder, t)!,
      ),
      boxShadow: active
          ? [
              BoxShadow(
                color: (like ? AppColors.resonanceViolet : AppColors.danger)
                    .withValues(alpha: 0.18 + 0.32 * t),
                blurRadius: 10 + 12 * t,
                offset: Offset(0, 4 + 4 * t),
              ),
              if (like)
                BoxShadow(
                  color: AppColors.softGold.withValues(alpha: 0.22 * t),
                  blurRadius: 16 * t,
                ),
            ]
          : null,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      selected: active,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Transform.scale(
          scale: 1.0 + 0.10 * t,
          child: SizedBox(
            key: buttonKey,
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: decoration,
              child: Center(child: face),
            ),
          ),
        ),
      ),
    );
  }
}

const _lilac = Color(0xFFDAC8ED);

class QMatchDiscoverRewindButton extends StatelessWidget {
  const QMatchDiscoverRewindButton({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    this.loading = false,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final enabled = onPressed != null && !loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: enabled || loading ? 1 : 0.42,
              child: SizedBox(
                key: const Key('qmatch-discover-rewind'),
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cosmicPurple.withValues(alpha: 0.40),
                    border: Border.all(
                      color: _lilac.withValues(
                        alpha: enabled || loading ? 0.72 : 0.34,
                      ),
                    ),
                    boxShadow: enabled
                        ? [
                            BoxShadow(
                              color: AppColors.resonanceViolet.withValues(
                                alpha: 0.22,
                              ),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_lilac),
                            ),
                          )
                        : const Icon(
                            Icons.undo_rounded,
                            size: 20,
                            color: _lilac,
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

class _SuperResonanceButton extends StatelessWidget {
  const _SuperResonanceButton({
    required this.semanticLabel,
    required this.onPressed,
    required this.loading,
    required this.balance,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool loading;
  final int balance;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      value: '$balance',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              SizedBox(
                key: const Key('qmatch-discover-super-resonance'),
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cosmicPurple.withValues(alpha: 0.42),
                    border: Border.all(color: _lilac.withValues(alpha: 0.72)),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.resonanceViolet.withValues(alpha: 0.28),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_lilac),
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: _lilac,
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: DecoratedBox(
                  key: const Key('qmatch-discover-super-resonance-balance'),
                  decoration: BoxDecoration(
                    color: balance > 0
                        ? AppColors.cosmicPurple
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          balance > 0 ? _lilac : _lilac.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    child: Text(
                      '$balance',
                      style: TextStyle(
                        color: balance > 0
                            ? _lilac
                            : _lilac.withValues(alpha: 0.72),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
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
