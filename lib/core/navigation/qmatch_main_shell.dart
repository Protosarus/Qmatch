import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../widgets/cosmic/qmatch_cosmic_background.dart';

class QMatchBottomNavigationItem {
  const QMatchBottomNavigationItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class QMatchMainShell extends StatelessWidget {
  const QMatchMainShell({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onTabSelected,
    required this.items,
  }) : assert(
          pages.length == items.length,
          'pages and items must have the same length.',
        );

  /// Visual bar height excluding system safe-area (≈30% shorter than 56).
  static const double navContentHeight = 40;

  final List<Widget> pages;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final List<QMatchBottomNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomInset = navContentHeight + safeBottom + AppSpacing.lg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Positioned.fill(child: QMatchMainBackground()),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: IndexedStack(index: currentIndex, children: pages),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: QMatchBottomNavigation(
                currentIndex: currentIndex,
                onTap: onTabSelected,
                items: items,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QMatchMainBackground extends StatelessWidget {
  const QMatchMainBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // Shell stays static so tab tests / settle loops are stable.
    // Discover + Profile own animated cosmic layers for breathing stars.
    return const IgnorePointer(
      child: QMatchCosmicBackground(
        key: Key('qmatch-main-cosmic'),
        seed: 21,
        starCount: 18,
        animate: false,
        showAccentHalos: false,
        starfieldOpacity: 0.22,
        child: SizedBox.expand(),
      ),
    );
  }
}

class QMatchBottomNavigation extends StatelessWidget {
  const QMatchBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<QMatchBottomNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('qmatch-bottom-nav-safe-area'),
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: AppRadii.sheetBorder,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                key: const Key('qmatch-bottom-navigation'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.sheetBorder,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.08),
                      const Color(0xFF141A2E).withValues(alpha: 0.35),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: QMatchBottomNavigationItemWidget(
                          item: items[i],
                          index: i,
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QMatchBottomNavigationItemWidget extends StatelessWidget {
  const QMatchBottomNavigationItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final QMatchBottomNavigationItem item;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Selected: soft purple capsule + white content + one gold accent bar.
    // Inactive: transparent, no card border, muted icon/label only.
    final fgColor = selected ? AppColors.textPrimary : AppColors.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('qmatch-nav-item-$index'),
          onTap: onTap,
          borderRadius: AppRadii.pillBorder,
          splashColor: AppColors.resonanceViolet.withValues(alpha: 0.12),
          highlightColor: AppColors.resonanceViolet.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            // Visual height is compact; hit target stays ≥44 for a11y.
            constraints: const BoxConstraints(minHeight: 44),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.pillBorder,
              color: selected
                  ? AppColors.resonanceViolet.withValues(alpha: 0.22)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 18, color: fgColor),
                const SizedBox(height: 2),
                Text(
                  key: Key('qmatch-nav-label-$index'),
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  key: Key('qmatch-nav-indicator-$index'),
                  duration: const Duration(milliseconds: 160),
                  width: selected ? 14 : 0,
                  height: selected ? 2 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.softGold.withValues(alpha: 0.9),
                    borderRadius: AppRadii.pillBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
