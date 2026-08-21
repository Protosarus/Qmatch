import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/matching/models/match_model.dart';
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
    this.loadMatch,
    this.blockExists,
    this.actions,
    this.log,
    this.child,
    this.chatBuilder,
    this.mainScreens,
    this.threadsStream,
  });

  final PushMessagingPort? messaging;
  final MessagePushTapRouter? router;
  final String? Function()? currentUid;
  final Future<ChatThreadModel?> Function(String threadId)? loadThread;
  final Future<MatchModel?> Function(String matchId)? loadMatch;
  final Future<bool> Function(String fromUid, String toUid)? blockExists;
  final MessagePushTapActions? actions;
  final void Function(String message)? log;
  final Widget? child;

  /// Tests swap ChatDetail for a lightweight marker widget.
  @visibleForTesting
  final Widget Function(String threadId, String otherUserId)? chatBuilder;

  /// Tests inject main-shell pages without Discover/Messages Firebase.
  @visibleForTesting
  final List<Widget>? mainScreens;

  /// Tests inject thread stream for the unread badge.
  @visibleForTesting
  final Stream<List<ChatThreadModel>>? threadsStream;

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
  bool _navigating = false;
  final Set<String> _seenTapFingerprints = {};

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? MessagePushTapRouter(log: _log);
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

  Future<MatchModel?> _loadMatch(String matchId) async {
    final custom = widget.loadMatch;
    if (custom != null) return custom(matchId);
    final snap = await FirestorePaths.matchDoc(matchId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return MatchModel.fromFirestore(matchId, data);
  }

  Future<bool> _blockExists(String fromUid, String toUid) async {
    final custom = widget.blockExists;
    if (custom != null) return custom(fromUid, toUid);
    // Owner-only: users/{me}/blocks/{other}. Reverse reads are denied by rules.
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

  /// Stable tap identity without logging secret values.
  String _tapFingerprint(Map<String, String> data) {
    final mid = (data['chat_message_id'] ?? data['message_id'] ?? '').trim();
    if (mid.isNotEmpty) return 'mid:$mid';
    final matchId = (data['match_id'] ?? '').trim();
    if (matchId.isNotEmpty) return 'match:$matchId';
    final keys = data.keys.toList()..sort();
    return 'keys:${keys.join(',')}|type:${(data['type'] ?? '').trim()}|'
        't:${(data['thread_id'] ?? '').isNotEmpty}|'
        'o:${(data['other_uid'] ?? '').isNotEmpty}';
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    // Consume terminated-launch message first, then listen. Avoids treating the
    // same iOS tap as both getInitialMessage and onMessageOpenedApp.
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null && mounted) await _onTap(initial);
    } catch (error) {
      _log('qmatch.push tap_initial_error type=${error.runtimeType}');
    }
    if (!mounted) return;
    _openedSub = _messaging.onNotificationOpened.listen(_onTap);
  }

  Future<void> _waitForMainShell({int maxFrames = 12}) async {
    for (var i = 0; i < maxFrames; i++) {
      if (!mounted) return;
      if (widget.child != null || _navKey.currentState != null) return;
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  Future<void> _afterNextFrame() async {
    if (!mounted) return;
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  Future<void> _onTap(Map<String, String> data) async {
    if (!mounted || _navigating) return;
    final fingerprint = _tapFingerprint(data);
    if (!_seenTapFingerprints.add(fingerprint)) {
      _log('qmatch.push tap_duplicate fingerprint_ignored');
      return;
    }

    await _waitForMainShell();
    if (!mounted) return;

    final result = await _router.handle(
      data: data,
      currentUid: _uid(),
      loadThread: _loadThread,
      loadMatch: _loadMatch,
      blockExists: _blockExists,
    );
    if (!mounted) return;

    _log(
      'qmatch.push tap_decision'
      ' outcome=${result.outcome.name}'
      ' guard=${result.guard ?? '-'}'
      ' threadId=${result.threadId ?? '-'}'
      ' otherUserId=${result.otherUserId ?? '-'}',
    );

    try {
      switch (result.outcome) {
        case MessagePushTapOutcome.openChat:
          await _openValidatedChat(
            threadId: result.threadId!,
            otherUserId: result.otherUserId!,
          );
        case MessagePushTapOutcome.fallbackMessages:
          await _showMessagesFallback();
        case MessagePushTapOutcome.ignore:
          break;
      }
    } catch (error) {
      _log('qmatch.push tap_nav_error type=${error.runtimeType}');
    }
  }

  Future<void> _openValidatedChat({
    required String threadId,
    required String otherUserId,
  }) async {
    final custom = widget.actions;
    if (custom != null) {
      custom.openChat(threadId: threadId, otherUserId: otherUserId);
      return;
    }

    _navigating = true;
    try {
      await _waitForMainShell();
      if (!mounted) return;

      final main = _navKey.currentState;
      final tabBefore = main?.currentIndex;
      _log(
        'qmatch.push tap_nav'
        ' phase=before'
        ' mainMounted=${main != null}'
        ' tab=$tabBefore'
        ' threadId=$threadId'
        ' otherUserId=$otherUserId',
      );

      // Keep the underlying shell on Messages if push is lost to a rebuild.
      main?.selectTab(1);
      await _afterNextFrame();
      if (!mounted) return;

      final nav = Navigator.maybeOf(context, rootNavigator: true);
      _log(
        'qmatch.push tap_nav'
        ' phase=ready'
        ' navigator=${nav != null}'
        ' tab=${_navKey.currentState?.currentIndex}',
      );
      if (nav == null) {
        _log('qmatch.push tap_nav phase=no_navigator');
        _navKey.currentState?.selectTab(1);
        return;
      }

      nav.popUntil((route) => route.isFirst);
      await _afterNextFrame();
      if (!mounted) return;

      final page = widget.chatBuilder?.call(threadId, otherUserId) ??
          ChatDetailScreen(
            threadId: threadId,
            otherUserId: otherUserId,
          );

      _log('qmatch.push tap_nav phase=push_call');
      // Do not await the route future — it completes only when chat is popped.
      nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => page,
          settings: RouteSettings(
            name: 'message_push_chat',
            arguments: <String, String>{
              'threadId': threadId,
              'otherUserId': otherUserId,
            },
          ),
        ),
      );
      _log(
        'qmatch.push tap_nav'
        ' phase=push_done'
        ' tab=${_navKey.currentState?.currentIndex}',
      );
    } finally {
      _navigating = false;
    }
  }

  Future<void> _showMessagesFallback() async {
    final custom = widget.actions;
    if (custom != null) {
      custom.showMessagesTab();
      return;
    }

    await _waitForMainShell();
    if (!mounted) return;
    final nav = Navigator.maybeOf(context, rootNavigator: true);
    nav?.popUntil((route) => route.isFirst);
    await _afterNextFrame();
    if (!mounted) return;
    _navKey.currentState?.selectTab(1);
    _log(
      'qmatch.push tap_nav'
      ' phase=fallback_messages'
      ' mainMounted=${_navKey.currentState != null}'
      ' tab=${_navKey.currentState?.currentIndex}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ??
        MainNavigationScreen(
          key: _navKey,
          screens: widget.mainScreens,
          threadsStream: widget.threadsStream,
          currentUid: widget.currentUid?.call(),
        );
  }
}
