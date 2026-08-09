import 'package:flutter/material.dart';

import '../../features/discover/screens/discover_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../l10n/app_localizations.dart';
import 'qmatch_main_shell.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.screens,
  });

  final int initialIndex;
  final List<Widget>? screens;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = widget.screens ??
        const [
          DiscoverScreen(),
          MessagesScreen(),
          ProfileScreen(),
        ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return QMatchMainShell(
      currentIndex: _currentIndex,
      onTabSelected: (index) {
        if (index == _currentIndex) return;
        setState(() => _currentIndex = index);
      },
      pages: _screens,
      items: [
        QMatchBottomNavigationItem(
          icon: Icons.explore_rounded,
          label: l10n.navDiscover,
        ),
        QMatchBottomNavigationItem(
          icon: Icons.chat_bubble_rounded,
          label: l10n.navMessages,
        ),
        QMatchBottomNavigationItem(
          icon: Icons.person_rounded,
          label: l10n.navProfile,
        ),
      ],
    );
  }
}
