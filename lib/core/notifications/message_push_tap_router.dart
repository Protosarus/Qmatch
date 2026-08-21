import 'package:flutter/foundation.dart';

import '../../features/messages/models/chat_thread_model.dart';

enum MessagePushTapOutcome {
  openChat,
  fallbackMessages,
  ignore,
}

class MessagePushTapResult {
  const MessagePushTapResult._(
    this.outcome, {
    this.threadId,
    this.otherUserId,
    this.messageId,
    this.guard,
  });

  final MessagePushTapOutcome outcome;
  final String? threadId;
  final String? otherUserId;
  final String? messageId;

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
}

/// Validates a message-push tap. Never trusts the payload alone.
class MessagePushTapRouter {
  MessagePushTapRouter({this.log});

  final void Function(String message)? log;
  final Set<String> _handledMessageIds = {};

  @visibleForTesting
  bool hasHandled(String messageId) => _handledMessageIds.contains(messageId);

  Future<MessagePushTapResult> handle({
    required Map<String, String> data,
    required String? currentUid,
    required Future<ChatThreadModel?> Function(String threadId) loadThread,
    required Future<bool> Function(String fromUid, String toUid) blockExists,
  }) async {
    final type = (data['type'] ?? '').trim();
    final threadId = (data['thread_id'] ?? '').trim();
    final otherUid = (data['other_uid'] ?? '').trim();
    // Prefer chat_message_id: iOS/FCM can drop or collide on bare "message_id".
    final messageId =
        (data['chat_message_id'] ?? data['message_id'] ?? '').trim();

    if (type != 'message') {
      return MessagePushTapResult.ignored('type_not_message');
    }

    if (threadId.isEmpty || otherUid.isEmpty || messageId.isEmpty) {
      if (messageId.isNotEmpty) _handledMessageIds.add(messageId);
      return MessagePushTapResult.fallback('malformed_payload');
    }

    final uid = (currentUid ?? '').trim();
    if (uid.isEmpty) {
      return MessagePushTapResult.ignored('signed_out');
    }
    if (_handledMessageIds.contains(messageId)) {
      return MessagePushTapResult.ignored('duplicate');
    }

    ChatThreadModel? thread;
    try {
      thread = await _loadThreadWithRetry(threadId, loadThread);
    } catch (error) {
      // Do not claim message_id — cold-start Firestore can fail once.
      _emit(
        'qmatch.push tap_guard=thread_load_error'
        ' error=${error.runtimeType}',
      );
      return MessagePushTapResult.fallback('thread_load_error');
    }
    if (thread == null) {
      _handledMessageIds.add(messageId);
      return MessagePushTapResult.fallback('thread_missing');
    }
    if (thread.status != ThreadStatus.active) {
      _handledMessageIds.add(messageId);
      return MessagePushTapResult.fallback('thread_not_active');
    }
    if (!thread.participants.contains(uid) ||
        !thread.participants.contains(otherUid) ||
        otherUid == uid ||
        thread.participants.length != 2) {
      _handledMessageIds.add(messageId);
      return MessagePushTapResult.fallback('not_participant');
    }
    final derivedOther = thread.participants.firstWhere((id) => id != uid);
    if (derivedOther != otherUid) {
      _handledMessageIds.add(messageId);
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
      _handledMessageIds.add(messageId);
      return MessagePushTapResult.fallback('blocked_by_me');
    }

    _handledMessageIds.add(messageId);
    return MessagePushTapResult.openChat(
      threadId: threadId,
      otherUserId: otherUid,
      messageId: messageId,
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
