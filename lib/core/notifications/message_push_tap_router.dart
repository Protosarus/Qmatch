import 'package:flutter/foundation.dart';

import '../../features/matching/models/match_model.dart';
import '../../features/messages/models/chat_thread_model.dart';

enum MessagePushTapOutcome {
  openChat,
  openAlignmentSignals,
  fallbackMessages,
  ignore,
}

class MessagePushTapResult {
  const MessagePushTapResult._(
    this.outcome, {
    this.threadId,
    this.otherUserId,
    this.messageId,
    this.signalId,
    this.guard,
  });

  final MessagePushTapOutcome outcome;
  final String? threadId;
  final String? otherUserId;
  final String? messageId;
  final String? signalId;

  /// Guard name for debug / tests.
  final String? guard;

  static const MessagePushTapResult ignore = MessagePushTapResult._(
    MessagePushTapOutcome.ignore,
    guard: 'ignore',
  );

  static const MessagePushTapResult fallbackMessages = MessagePushTapResult._(
    MessagePushTapOutcome.fallbackMessages,
    guard: 'fallback',
  );

  static const MessagePushTapResult openAlignmentSignalsFallback =
      MessagePushTapResult._(
    MessagePushTapOutcome.openAlignmentSignals,
    guard: 'alignment_fallback',
  );

  factory MessagePushTapResult.fallback(String guard) {
    return MessagePushTapResult._(
      MessagePushTapOutcome.fallbackMessages,
      guard: guard,
    );
  }

  factory MessagePushTapResult.ignored(String guard) {
    return MessagePushTapResult._(
      MessagePushTapOutcome.ignore,
      guard: guard,
    );
  }

  factory MessagePushTapResult.openChat({
    required String threadId,
    required String otherUserId,
    required String messageId,
  }) {
    return MessagePushTapResult._(
      MessagePushTapOutcome.openChat,
      threadId: threadId,
      otherUserId: otherUserId,
      messageId: messageId,
      guard: 'open_chat',
    );
  }

  factory MessagePushTapResult.openAlignmentSignals({
    required String signalId,
    required String otherUserId,
    String guard = 'open_alignment_signals',
  }) {
    return MessagePushTapResult._(
      MessagePushTapOutcome.openAlignmentSignals,
      signalId: signalId,
      otherUserId: otherUserId,
      messageId: 'sr:$signalId',
      guard: guard,
    );
  }
}

/// Validates message/match push taps. Never trusts the payload alone.
class MessagePushTapRouter {
  MessagePushTapRouter({this.log});

  final void Function(String message)? log;
  final Set<String> _handledTapIds = {};

  @visibleForTesting
  bool hasHandled(String tapId) => _handledTapIds.contains(tapId);

  Future<MessagePushTapResult> handle({
    required Map<String, String> data,
    required String? currentUid,
    required Future<ChatThreadModel?> Function(String threadId) loadThread,
    required Future<bool> Function(String fromUid, String toUid) blockExists,
    Future<MatchModel?> Function(String matchId)? loadMatch,
  }) async {
    final type = (data['type'] ?? '').trim();
    if (type == 'message') {
      return _handleMessage(
        data: data,
        currentUid: currentUid,
        loadThread: loadThread,
        blockExists: blockExists,
      );
    }
    if (type == 'match') {
      return _handleMatch(
        data: data,
        currentUid: currentUid,
        loadThread: loadThread,
        blockExists: blockExists,
        loadMatch: loadMatch,
      );
    }
    if (type == 'super_resonance') {
      return _handleSuperResonance(
        data: data,
        currentUid: currentUid,
        blockExists: blockExists,
      );
    }
    return MessagePushTapResult.ignored('type_unsupported');
  }

  Future<MessagePushTapResult> _handleMessage({
    required Map<String, String> data,
    required String? currentUid,
    required Future<ChatThreadModel?> Function(String threadId) loadThread,
    required Future<bool> Function(String fromUid, String toUid) blockExists,
  }) async {
    final threadId = (data['thread_id'] ?? '').trim();
    final otherUid = (data['other_uid'] ?? '').trim();
    // Prefer chat_message_id: iOS/FCM can drop or collide on bare "message_id".
    final messageId =
        (data['chat_message_id'] ?? data['message_id'] ?? '').trim();

    if (threadId.isEmpty || otherUid.isEmpty || messageId.isEmpty) {
      if (messageId.isNotEmpty) _handledTapIds.add(messageId);
      return MessagePushTapResult.fallback('malformed_payload');
    }

    final uid = (currentUid ?? '').trim();
    if (uid.isEmpty) {
      return MessagePushTapResult.ignored('signed_out');
    }
    if (_handledTapIds.contains(messageId)) {
      return MessagePushTapResult.ignored('duplicate');
    }

    return _validateThreadAndOpen(
      tapId: messageId,
      threadId: threadId,
      otherUid: otherUid,
      uid: uid,
      loadThread: loadThread,
      blockExists: blockExists,
    );
  }

  Future<MessagePushTapResult> _handleMatch({
    required Map<String, String> data,
    required String? currentUid,
    required Future<ChatThreadModel?> Function(String threadId) loadThread,
    required Future<bool> Function(String fromUid, String toUid) blockExists,
    Future<MatchModel?> Function(String matchId)? loadMatch,
  }) async {
    final matchId = (data['match_id'] ?? '').trim();
    final threadId = (data['thread_id'] ?? '').trim();
    final otherUid = (data['other_uid'] ?? '').trim();

    if (matchId.isEmpty || threadId.isEmpty || otherUid.isEmpty) {
      if (matchId.isNotEmpty) _handledTapIds.add('match:$matchId');
      return MessagePushTapResult.fallback('malformed_payload');
    }

    final uid = (currentUid ?? '').trim();
    if (uid.isEmpty) {
      return MessagePushTapResult.ignored('signed_out');
    }
    final tapId = 'match:$matchId';
    if (_handledTapIds.contains(tapId)) {
      return MessagePushTapResult.ignored('duplicate');
    }

    if (loadMatch != null) {
      MatchModel? match;
      try {
        match = await loadMatch(matchId);
      } catch (error) {
        _emit(
          'qmatch.push tap_guard=match_load_error'
          ' error=${error.runtimeType}',
        );
        return MessagePushTapResult.fallback('match_load_error');
      }
      if (match == null) {
        _handledTapIds.add(tapId);
        return MessagePushTapResult.fallback('match_missing');
      }
      if (match.state != MatchState.active) {
        _handledTapIds.add(tapId);
        return MessagePushTapResult.fallback('match_not_active');
      }
      if (match.threadId.isNotEmpty && match.threadId != threadId) {
        _handledTapIds.add(tapId);
        return MessagePushTapResult.fallback('thread_id_mismatch');
      }
      if (!match.users.contains(uid) || !match.users.contains(otherUid)) {
        _handledTapIds.add(tapId);
        return MessagePushTapResult.fallback('not_match_participant');
      }
    }

    return _validateThreadAndOpen(
      tapId: tapId,
      threadId: threadId,
      otherUid: otherUid,
      uid: uid,
      loadThread: loadThread,
      blockExists: blockExists,
    );
  }

  Future<MessagePushTapResult> _handleSuperResonance({
    required Map<String, String> data,
    required String? currentUid,
    required Future<bool> Function(String fromUid, String toUid) blockExists,
  }) async {
    final signalId = (data['signal_id'] ?? '').trim();
    final otherUid = (data['other_uid'] ?? '').trim();

    if (signalId.isEmpty || otherUid.isEmpty) {
      if (signalId.isNotEmpty) _handledTapIds.add('sr:$signalId');
      // Still open Alignment Signals — never fabricate a card.
      return MessagePushTapResult.openAlignmentSignals(
        signalId: signalId.isEmpty ? 'unknown' : signalId,
        otherUserId: otherUid.isEmpty ? 'unknown' : otherUid,
        guard: 'malformed_payload',
      );
    }

    final uid = (currentUid ?? '').trim();
    if (uid.isEmpty) {
      return MessagePushTapResult.ignored('signed_out');
    }
    final tapId = 'sr:$signalId';
    if (_handledTapIds.contains(tapId)) {
      return MessagePushTapResult.ignored('duplicate');
    }

    // Clients cannot read super_resonance_signals (Admin-only). Ownership is
    // proven by deterministic id from_uid_to_uid where to_uid == me.
    final expectedId = '${otherUid}_$uid';
    if (signalId != expectedId || otherUid == uid) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.openAlignmentSignals(
        signalId: signalId,
        otherUserId: otherUid,
        guard: 'signal_not_for_recipient',
      );
    }

    bool blockedByMe;
    try {
      blockedByMe = await blockExists(uid, otherUid);
    } catch (error) {
      _emit(
        'qmatch.push tap_guard=block_check_error'
        ' error=${error.runtimeType}',
      );
      return MessagePushTapResult.openAlignmentSignals(
        signalId: signalId,
        otherUserId: otherUid,
        guard: 'block_check_error',
      );
    }
    if (blockedByMe) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.openAlignmentSignals(
        signalId: signalId,
        otherUserId: otherUid,
        guard: 'blocked_by_me',
      );
    }

    _handledTapIds.add(tapId);
    return MessagePushTapResult.openAlignmentSignals(
      signalId: signalId,
      otherUserId: otherUid,
    );
  }

  Future<MessagePushTapResult> _validateThreadAndOpen({
    required String tapId,
    required String threadId,
    required String otherUid,
    required String uid,
    required Future<ChatThreadModel?> Function(String threadId) loadThread,
    required Future<bool> Function(String fromUid, String toUid) blockExists,
  }) async {
    ChatThreadModel? thread;
    try {
      thread = await _loadThreadWithRetry(threadId, loadThread);
    } catch (error) {
      // Do not claim tap id — cold-start Firestore can fail once.
      _emit(
        'qmatch.push tap_guard=thread_load_error'
        ' error=${error.runtimeType}',
      );
      return MessagePushTapResult.fallback('thread_load_error');
    }
    if (thread == null) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.fallback('thread_missing');
    }
    if (thread.status != ThreadStatus.active) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.fallback('thread_not_active');
    }
    if (!thread.participants.contains(uid) ||
        !thread.participants.contains(otherUid) ||
        otherUid == uid ||
        thread.participants.length != 2) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.fallback('not_participant');
    }
    final derivedOther = thread.participants.firstWhere((id) => id != uid);
    if (derivedOther != otherUid) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.fallback('other_uid_mismatch');
    }

    // Client can only read users/{me}/blocks/{other}. Reverse docs are
    // owner-only in rules; a GET throws permission-denied even when absent.
    // Relationship blocks close the thread, so status==active covers them.
    bool blockedByMe;
    try {
      blockedByMe = await blockExists(uid, otherUid);
    } catch (error) {
      _emit(
        'qmatch.push tap_guard=block_check_error'
        ' error=${error.runtimeType}',
      );
      return MessagePushTapResult.fallback('block_check_error');
    }
    if (blockedByMe) {
      _handledTapIds.add(tapId);
      return MessagePushTapResult.fallback('blocked_by_me');
    }

    _handledTapIds.add(tapId);
    return MessagePushTapResult.openChat(
      threadId: threadId,
      otherUserId: otherUid,
      messageId: tapId,
    );
  }

  Future<ChatThreadModel?> _loadThreadWithRetry(
    String threadId,
    Future<ChatThreadModel?> Function(String threadId) loadThread,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await loadThread(threadId);
      } catch (error) {
        lastError = error;
        if (attempt == 2) break;
        await Future<void>.delayed(Duration(milliseconds: 80 * (attempt + 1)));
      }
    }
    throw lastError ?? StateError('thread_load_failed');
  }

  void _emit(String message) {
    if (log != null) {
      log!(message);
      return;
    }
    if (kReleaseMode) return;
    debugPrint(message);
  }
}
