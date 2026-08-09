import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qmatch/features/messages/models/message_model.dart';

/// Synthetic chat-detail fixtures (no Firebase).
class ChatDetailGoldenFixtures {
  ChatDetailGoldenFixtures._();

  static const Size compactIphone = Size(390, 844);
  static const Size largeIphone = Size(430, 932);

  static MessageModel textMessage({
    required String id,
    required String senderId,
    required String text,
    DateTime? createdAt,
    int? clientCreatedAt,
  }) {
    return MessageModel(
      messageId: id,
      threadId: 'thread_fixture',
      senderId: senderId,
      type: MessageType.text,
      text: text,
      createdAt: createdAt == null ? null : Timestamp.fromDate(createdAt),
      clientCreatedAt: clientCreatedAt,
    );
  }

  static MessageModel systemMessage({
    required String id,
    required String text,
    DateTime? createdAt,
  }) {
    return MessageModel(
      messageId: id,
      threadId: 'thread_fixture',
      senderId: 'system',
      type: MessageType.system,
      text: text,
      createdAt: createdAt == null ? null : Timestamp.fromDate(createdAt),
    );
  }

  static List<MessageModel> mixedConversation({
    required String me,
    required String them,
  }) {
    return [
      textMessage(
        id: '1',
        senderId: them,
        text: 'Hi — nice to match.',
        createdAt: DateTime(2026, 7, 26, 10, 0),
      ),
      textMessage(
        id: '2',
        senderId: me,
        text: 'Hello! Looking forward to chatting.',
        createdAt: DateTime(2026, 7, 26, 10, 5),
      ),
      textMessage(
        id: '3',
        senderId: them,
        text: 'How is your week going so far?',
        createdAt: DateTime(2026, 7, 27, 9, 12),
      ),
      textMessage(
        id: '4',
        senderId: me,
        text:
            'Pretty good — working on a few projects and trying to leave evenings free.',
        createdAt: DateTime(2026, 7, 27, 9, 18),
      ),
    ];
  }

  static MessageModel longMessage({required String me}) => textMessage(
        id: 'long',
        senderId: me,
        text: 'This is a deliberately long message used to verify wrapping, '
            'maximum bubble width, and that unbroken_runs_like_this_one_still_stay_inside '
            'the bubble without overflowing the viewport horizontally.',
        createdAt: DateTime(2026, 7, 27, 11, 0),
      );

  static MessageModel emojiMultiline({required String them}) => textMessage(
        id: 'emoji',
        senderId: them,
        text: 'Hey 👋\nHope your day is going well ✨\nTalk soon!',
        createdAt: DateTime(2026, 7, 27, 12, 0),
      );
}
