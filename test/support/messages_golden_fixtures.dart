import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qmatch/features/messages/models/chat_thread_model.dart';

/// Test-only Messages fixtures. No Firebase I/O.
class MessagesGoldenFixtures {
  MessagesGoldenFixtures._();

  static const Size compactIphone = Size(375, 667);
  static const Size largeIphone = Size(430, 932);

  static Timestamp tsToday({int hour = 14, int minute = 30}) {
    final now = DateTime(2026, 7, 27, hour, minute);
    return Timestamp.fromDate(now);
  }

  static Timestamp tsEarlierDay() {
    return Timestamp.fromDate(DateTime(2026, 7, 20, 9, 5));
  }

  static ChatThreadModel thread({
    required String id,
    String preview = 'Hello there',
    Timestamp? lastMessageAt,
    Map<String, int> unread = const {},
  }) {
    return ChatThreadModel(
      threadId: id,
      participants: const ['me', 'other'],
      lastMessagePreview: preview,
      lastMessageAt: lastMessageAt ?? tsToday(),
      unreadCounts: unread,
    );
  }
}

class MessagesConversationFixture {
  const MessagesConversationFixture({
    required this.displayName,
    required this.previewText,
    this.age,
    this.photoUrl,
    this.timestampText,
    this.unreadCount = 0,
    this.photoImageProvider,
  });

  final String displayName;
  final int? age;
  final String? photoUrl;
  final ImageProvider? photoImageProvider;
  final String previewText;
  final String? timestampText;
  final int unreadCount;
}
