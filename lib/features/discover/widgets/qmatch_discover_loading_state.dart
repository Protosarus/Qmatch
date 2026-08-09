import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';

/// Discover loading skeleton shaped like the final candidate card.
///
/// Uses a lightweight opacity pulse (no shimmer package). A small spinner
/// sits beside the localized loading text — not centered in an empty photo.
class QMatchDiscoverLoadingState extends StatefulWidget {
  const QMatchDiscoverLoadingState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  State<QMatchDiscoverLoadingState> createState() =>
      _QMatchDiscoverLoadingStateState();
}

class _QMatchDiscoverLoadingStateState extends State<QMatchDiscoverLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.42, end: 0.78).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('qmatch-discover-loading'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Expanded(
            child: QGlassCard(
              emphasized: true,
              padding: EdgeInsets.zero,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final short = constraints.maxHeight < 420;
                  final photoFlex = short ? 5 : 6;
                  final detailsFlex = short ? 4 : 3;

                  return AnimatedBuilder(
                    animation: _opacity,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _opacity.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: photoFlex,
                              child: const _PhotoSkeleton(),
                            ),
                            Expanded(
                              flex: detailsFlex,
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.md,
                                  AppSpacing.sm,
                                  AppSpacing.md,
                                  AppSpacing.md,
                                ),
                                child: _DetailsSkeleton(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedBuilder(
            animation: _opacity,
            builder: (context, _) {
              return Opacity(
                opacity: (_opacity.value * 0.85).clamp(0.35, 0.7),
                child: const _ActionPlaceholders(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _LoadingCaption(message: widget.message),
        ],
      ),
    );
  }
}

class _PhotoSkeleton extends StatelessWidget {
  const _PhotoSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.deepIndigo.withValues(alpha: 0.55),
            AppColors.surfaceElevated,
            AppColors.cosmicBlack.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBar(
                key: const Key('qmatch-discover-loading-identity'),
                width: 168,
                height: 18,
                radius: 6,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: const [
                  _SkeletonBar(width: 88, height: 22, radius: AppRadii.pill),
                  SizedBox(width: AppSpacing.xs),
                  _SkeletonBar(width: 64, height: 22, radius: AppRadii.pill),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsSkeleton extends StatelessWidget {
  const _DetailsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBar(
          key: Key('qmatch-discover-loading-bio-1'),
          width: double.infinity,
          height: 11,
        ),
        const SizedBox(height: AppSpacing.xs),
        const _SkeletonBar(
          key: Key('qmatch-discover-loading-bio-2'),
          width: 210,
          height: 11,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: const [
            _SkeletonBar(
              key: Key('qmatch-discover-loading-chip-1'),
              width: 72,
              height: 24,
              radius: AppRadii.pill,
            ),
            SizedBox(width: AppSpacing.xs),
            _SkeletonBar(
              key: Key('qmatch-discover-loading-chip-2'),
              width: 64,
              height: 24,
              radius: AppRadii.pill,
            ),
            SizedBox(width: AppSpacing.xs),
            _SkeletonBar(
              key: Key('qmatch-discover-loading-chip-3'),
              width: 56,
              height: 24,
              radius: AppRadii.pill,
            ),
          ],
        ),
        const Spacer(),
        const _SkeletonBar(width: 140, height: 10),
      ],
    );
  }
}

class _ActionPlaceholders extends StatelessWidget {
  const _ActionPlaceholders();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Row(
        children: const [
          Expanded(
            child: _SkeletonBar(
              key: Key('qmatch-discover-loading-pass'),
              height: 40,
              radius: AppRadii.button,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SkeletonBar(
              key: Key('qmatch-discover-loading-like'),
              height: 40,
              radius: AppRadii.button,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCaption extends StatelessWidget {
  const _LoadingCaption({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.softGold),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
