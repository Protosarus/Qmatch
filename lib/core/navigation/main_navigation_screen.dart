import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DiscoverScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  // Target: compact ~80–95px total height + safe area.
  static const double _navContentHeight = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final navTotalHeight = _navContentHeight + safeBottom;
    final bodyBottomPadding = navTotalHeight + 24;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: bodyBottomPadding),
            child: _screens[_currentIndex],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: safeBottom + 10,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.explore,
                        label: l10n.navDiscover,
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.chat_bubble,
                        label: l10n.navMessages,
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.person,
                        label: l10n.navProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black.withValues(alpha: 0.72) : null,
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 22,
        ),
      ),
      ),
    );
  }
}
