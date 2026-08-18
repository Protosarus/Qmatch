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
class QMatchDiscoverActionBar extends StatelessWidget {
  const QMatchDiscoverActionBar({
    super.key,
    required this.passLabel,
    required this.likeLabel,
    required this.onPass,
    required this.onLike,
    required this.isActionLoading,
    this.subdued = false,
    this.superResonanceLabel,
    this.onSuperResonance,
    this.isSuperResonanceLoading = false,
    this.showSuperResonance = false,
    this.superResonanceBalance = 0,
  });

  final String passLabel;
  final String likeLabel;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final bool isActionLoading;
  final bool subdued;

  final String? superResonanceLabel;
  final VoidCallback? onSuperResonance;
  final bool isSuperResonanceLoading;
  final bool showSuperResonance;
  final int superResonanceBalance;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: subdued ? 0.42 : 1,
      child: Padding(
        key: const Key('qmatch-discover-action-bar'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          mainAlignment: MainAxisAlignment.center,
          children: [
            _DiscoverIconButton(
              buttonKey: const Key('qmatch-discover-pass'),
              icon: Icons.close_rounded,
              semanticLabel: passLabel,
              onPressed: onPass,
              like: false,
              loading: false,
            ),
            if (showSuperResonance ||
                onSuperResonance != null ||
                isSuperResonanceLoading) ...[
              const SizedBox(width: AppSpacing.md),
              _SuperResonanceButton(
                semanticLabel: superResonanceLabel ?? '',
                onPressed: onSuperResonance,
                loading: isSuperResonanceLoading,
                balance: superResonanceBalance,
              ),
              const SizedBox(width: AppSpacing.md),
            ] else
              const SizedBox(width: AppSpacing.xxl),
            _DiscoverIconButton(
              buttonKey: const Key('qmatch-discover-like'),
              icon: Icons.favorite_rounded,
              semanticLabel: likeLabel,
              onPressed: onLike,
              like: true,
              loading: isActionLoading,
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
  });

  final Key buttonKey;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool like;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final enabled = onPressed != null && !loading;

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
            color: like ? AppColors.textPrimary : QMatchGlassIconButton.iconDefault,
          );

    final decoration = BoxDecoration(
      shape: BoxShape.circle,
      color: like
          ? AppColors.resonanceViolet.withValues(alpha: enabled ? 0.88 : 0.35)
          : QMatchGlassIconButton.glassFill,
      border: Border.all(
        color: like
            ? AppColors.softGold.withValues(alpha: 0.42)
            : QMatchGlassIconButton.coolBorder,
      ),
      boxShadow: like && enabled
          ? [
              BoxShadow(
                color: AppColors.resonanceViolet.withValues(alpha: 0.45),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.softGold.withValues(alpha: 0.22),
                blurRadius: 16,
              ),
            ]
          : null,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
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
    );
  }
}

const _lilac = Color(0xFFDAC8ED);

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
      value: balance > 0 ? '$balance' : '0',
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
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
                  color: AppColors.resonanceViolet.withValues(alpha: 0.28),
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
      ),
    );
  }
}
