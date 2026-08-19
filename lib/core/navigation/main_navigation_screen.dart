import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/discover/screens/discover_screen.dart';
import '../../features/messages/models/chat_thread_model.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/messages/services/chat_service.dart';
import '../../features/messages/utils/unread_conversation_badge.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../l10n/app_localizations.dart';
import 'qmatch_main_shell.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.screens,
    this.threadsStream,
    this.currentUid,
  });

  final int initialIndex;
  final List<Widget>? screens;

  /// Tests inject the existing participant-thread query. Production is null.
  @visibleForTesting
  final Stream<List<ChatThreadModel>>? threadsStream;

  /// Tests inject uid so Firebase Auth is not required. Production is null.
  @visibleForTesting
  final String? currentUid;

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

  Stream<List<ChatThreadModel>> _threadsStream() {
    return widget.threadsStream ?? ChatService().getMyThreadsStream();
  }

  String? _uid() =>
      widget.currentUid ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ChatThreadModel>>(
      stream: _threadsStream(),
      initialData: const <ChatThreadModel>[],
      builder: (context, snapshot) {
        final threads = snapshot.hasError
            ? const <ChatThreadModel>[]
            : (snapshot.data ?? const <ChatThreadModel>[]);
        final badge = unreadConversationBadgeLabel(
          unreadConversationCount(threads: threads, currentUid: _uid()),
        );

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
              badgeLabel: badge,
            ),
            QMatchBottomNavigationItem(
              icon: Icons.person_rounded,
              label: l10n.navProfile,
            ),
          ],
        );
      },
    );
  }
}
