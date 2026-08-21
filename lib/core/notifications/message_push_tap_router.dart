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
  });

  final MessagePushTapOutcome outcome;
  final String? threadId;
  final String? otherUserId;
  final String? messageId;

  static const MessagePushTapResult ignore = MessagePushTapResult._(
    MessagePushTapOutcome.ignore,
  );

  static const MessagePushTapResult fallbackMessages = MessagePushTapResult._(
    MessagePushTapOutcome.fallbackMessages,
  );

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
    );
  }
}

/// Validates a message-push tap. Never trusts the payload alone.
class MessagePushTapRouter {
  MessagePushTapRouter();

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
    if (type != 'message') return MessagePushTapResult.ignore;

    final threadId = (data['thread_id'] ?? '').trim();
    final otherUid = (data['other_uid'] ?? '').trim();
    final messageId = (data['message_id'] ?? '').trim();
    if (threadId.isEmpty || otherUid.isEmpty || messageId.isEmpty) {
      if (messageId.isNotEmpty) _handledMessageIds.add(messageId);
      return MessagePushTapResult.fallbackMessages;
    }

    final uid = (currentUid ?? '').trim();
    if (uid.isEmpty) {
      return MessagePushTapResult.ignore;
    }
    if (!_handledMessageIds.add(messageId)) {
      return MessagePushTapResult.ignore;
    }

    ChatThreadModel? thread;
    try {
      thread = await loadThread(threadId);
    } catch (_) {
      return MessagePushTapResult.fallbackMessages;
    }
    if (thread == null) {
      return MessagePushTapResult.fallbackMessages;
    }
    if (thread.status != ThreadStatus.active) {
      return MessagePushTapResult.fallbackMessages;
    }
    if (!thread.participants.contains(uid) ||
        !thread.participants.contains(otherUid) ||
        otherUid == uid ||
        thread.participants.length != 2) {
      return MessagePushTapResult.fallbackMessages;
    }
    final derivedOther = thread.participants.firstWhere((id) => id != uid);
    if (derivedOther != otherUid) {
      return MessagePushTapResult.fallbackMessages;
    }

    bool blocked;
    try {
      blocked =
          await blockExists(uid, otherUid) || await blockExists(otherUid, uid);
    } catch (_) {
      return MessagePushTapResult.fallbackMessages;
    }
    if (blocked) {
      return MessagePushTapResult.fallbackMessages;
    }

    return MessagePushTapResult.openChat(
      threadId: threadId,
      otherUserId: otherUid,
      messageId: messageId,
    );
  }
}
