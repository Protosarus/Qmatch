import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/messages/models/chat_thread_model.dart';
import '../../features/messages/screens/chat_detail_screen.dart';
import '../../features/messages/services/chat_service.dart';
import '../navigation/main_navigation_screen.dart';
import '../utils/firestore_paths.dart';
import 'firebase_push_messaging_adapter.dart';
import 'message_push_tap_router.dart';
import 'push_messaging_port.dart';

/// Opens Chat Detail from a validated message-push tap after main is ready.
class MessagePushTapHost extends StatefulWidget {
  const MessagePushTapHost({
    super.key,
    this.messaging,
    this.router,
    this.currentUid,
    this.loadThread,
    this.blockExists,
    this.actions,
    this.log,
    this.child,
  });

  final PushMessagingPort? messaging;
  final MessagePushTapRouter? router;
  final String? Function()? currentUid;
  final Future<ChatThreadModel?> Function(String threadId)? loadThread;
  final Future<bool> Function(String fromUid, String toUid)? blockExists;
  final MessagePushTapActions? actions;
  final void Function(String message)? log;
  final Widget? child;

  @override
  State<MessagePushTapHost> createState() => _MessagePushTapHostState();
}

abstract class MessagePushTapActions {
  void openChat({required String threadId, required String otherUserId});
  void showMessagesTab();
}

class _MessagePushTapHostState extends State<MessagePushTapHost> {
  final GlobalKey<MainNavigationScreenState> _navKey =
      GlobalKey<MainNavigationScreenState>();
  late final MessagePushTapRouter _router;
  late final PushMessagingPort _messaging;
  StreamSubscription<Map<String, String>>? _openedSub;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? MessagePushTapRouter();
    _messaging = widget.messaging ?? FirebasePushMessagingAdapter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _start();
    });
  }

  @override
  void dispose() {
    _openedSub?.cancel();
    super.dispose();
  }

  String? _uid() =>
      widget.currentUid?.call() ?? FirebaseAuth.instance.currentUser?.uid;

  Future<ChatThreadModel?> _loadThread(String threadId) {
    final custom = widget.loadThread;
    if (custom != null) return custom(threadId);
    return ChatService().getThreadById(threadId);
  }

  Future<bool> _blockExists(String fromUid, String toUid) async {
    final custom = widget.blockExists;
    if (custom != null) return custom(fromUid, toUid);
    final snap = await FirestorePaths.userBlockDoc(fromUid, toUid).get();
    return snap.exists;
  }

  void _log(String message) {
    if (widget.log != null) {
      widget.log!(message);
      return;
    }
    if (kReleaseMode) return;
    debugPrint(message);
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    _openedSub = _messaging.onNotificationOpened.listen(_onTap);
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null && mounted) await _onTap(initial);
    } catch (_) {}
  }

  Future<void> _onTap(Map<String, String> data) async {
    if (!mounted) return;
    final result = await _router.handle(
      data: data,
      currentUid: _uid(),
      loadThread: _loadThread,
      blockExists: _blockExists,
    );
    if (!mounted) return;
    try {
      switch (result.outcome) {
        case MessagePushTapOutcome.openChat:
          _log('qmatch.push tap_open');
          _actions.openChat(
            threadId: result.threadId!,
            otherUserId: result.otherUserId!,
          );
        case MessagePushTapOutcome.fallbackMessages:
          _log('qmatch.push tap_fallback');
          _actions.showMessagesTab();
        case MessagePushTapOutcome.ignore:
          break;
      }
    } catch (_) {}
  }

  MessagePushTapActions get _actions =>
      widget.actions ?? _ContextTapActions(context, _navKey);

  @override
  Widget build(BuildContext context) {
    return widget.child ?? MainNavigationScreen(key: _navKey);
  }
}

class _ContextTapActions implements MessagePushTapActions {
  _ContextTapActions(this._context, this._navKey);

  final BuildContext _context;
  final GlobalKey<MainNavigationScreenState> _navKey;

  @override
  void openChat({required String threadId, required String otherUserId}) {
    final nav = Navigator.maybeOf(_context);
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatDetailScreen(
          threadId: threadId,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  @override
  void showMessagesTab() {
    Navigator.maybeOf(_context)?.popUntil((route) => route.isFirst);
    _navKey.currentState?.selectTab(1);
  }
}
