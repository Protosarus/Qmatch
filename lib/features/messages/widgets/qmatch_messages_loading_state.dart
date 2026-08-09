import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/cosmic/q_glass_card.dart';

/// Lightweight conversation-list skeleton (no shimmer package).
class QMatchMessagesLoadingState extends StatefulWidget {
  const QMatchMessagesLoadingState({
    super.key,
    required this.message,
    this.rowCount = 4,
  });

  final String message;
  final int rowCount;

  @override
  State<QMatchMessagesLoadingState> createState() =>
      _QMatchMessagesLoadingStateState();
}

class _QMatchMessagesLoadingStateState extends State<QMatchMessagesLoadingState>
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
      key: const Key('qmatch-messages-loading'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _opacity,
              builder: (context, _) {
                return Opacity(
                  opacity: _opacity.value,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.rowCount,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      return const _SkeletonRow();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
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
                  widget.message,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return QGlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glassSurfaceStrong,
              border: Border.all(
                color: AppColors.borderSubtle.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(child: _Bar(height: 12)),
                    SizedBox(width: AppSpacing.sm),
                    _Bar(width: 36, height: 10),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const _Bar(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
