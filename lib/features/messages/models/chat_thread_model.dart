import 'package:cloud_firestore/cloud_firestore.dart';

enum ThreadStatus {
  active,
  closed,
}

class ChatThreadModel {
  final String threadId;
  final String? matchId;
  final List<String> participants;
  final Timestamp? createdAt;
  final Timestamp? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSender;
  final Map<String, int> unreadCounts;
  final ThreadStatus status;

  const ChatThreadModel({
    required this.threadId,
    required this.participants,
    this.matchId,
    this.createdAt,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSender,
    this.unreadCounts = const {},
    this.status = ThreadStatus.active,
  });

  static ThreadStatus _statusFromString(String? value) {
    switch (value) {
      case 'active':
        return ThreadStatus.active;
      case 'closed':
        return ThreadStatus.closed;
      default:
        return ThreadStatus.active;
    }
  }

  factory ChatThreadModel.fromFirestore(String threadId, Map<String, dynamic> data) {
    final unreadRaw = (data['unread_counts'] as Map?)?.cast<String, dynamic>() ?? const {};
    final unreadCounts = <String, int>{};
    for (final entry in unreadRaw.entries) {
      unreadCounts[entry.key] = (entry.value as num?)?.toInt() ?? 0;
    }

    return ChatThreadModel(
      threadId: threadId,
      matchId: data['match_id'] as String?,
      participants: List<String>.from((data['participants'] as List?) ?? const []),
      createdAt: data['created_at'] as Timestamp?,
      lastMessageAt: data['last_message_at'] as Timestamp?,
      lastMessagePreview: data['last_message_preview'] as String?,
      lastMessageSender: data['last_message_sender'] as String?,
      unreadCounts: unreadCounts,
      status: _statusFromString(data['status'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'match_id': matchId,
      'participants': participants,
      'created_at': createdAt,
      'last_message_at': lastMessageAt,
      'last_message_preview': lastMessagePreview,
      'last_message_sender': lastMessageSender,
      'unread_counts': unreadCounts,
      'status': status.name,
    };
  }
}

