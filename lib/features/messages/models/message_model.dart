import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  system,
  revealRequest,
}

class MessageModel {
  final String messageId;
  final String threadId;
  final String senderId;
  final MessageType type;
  final String text;
  final Timestamp? createdAt;
  final int? clientCreatedAt;
  final Map<String, Timestamp> readBy;
  final Map<String, dynamic>? moderation;

  const MessageModel({
    required this.messageId,
    required this.threadId,
    required this.senderId,
    required this.type,
    required this.text,
    this.createdAt,
    this.clientCreatedAt,
    this.readBy = const {},
    this.moderation,
  });

  static MessageType _typeFromString(String? value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'system':
        return MessageType.system;
      case 'reveal_request':
        return MessageType.revealRequest;
      default:
        return MessageType.text;
    }
  }

  static String _typeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.system:
        return 'system';
      case MessageType.revealRequest:
        return 'reveal_request';
    }
  }

  factory MessageModel.fromFirestore(
    String messageId,
    Map<String, dynamic> data,
  ) {
    final readByRaw = (data['read_by'] as Map?)?.cast<String, dynamic>() ?? const {};
    final readBy = <String, Timestamp>{};
    for (final entry in readByRaw.entries) {
      final ts = entry.value;
      if (ts is Timestamp) {
        readBy[entry.key] = ts;
      }
    }

    return MessageModel(
      messageId: messageId,
      threadId: (data['thread_id'] as String?) ?? '',
      senderId: (data['sender_id'] as String?) ?? '',
      type: _typeFromString(data['type'] as String?),
      text: (data['text'] as String?) ?? '',
      createdAt: data['created_at'] is Timestamp ? data['created_at'] as Timestamp : null,
      clientCreatedAt: (data['client_created_at'] as num?)?.toInt(),
      readBy: readBy,
      moderation: data['moderation'] is Map
          ? (data['moderation'] as Map).cast<String, dynamic>()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'thread_id': threadId,
      'sender_id': senderId,
      'type': _typeToString(type),
      'text': text,
      'created_at': createdAt,
      'client_created_at': clientCreatedAt,
      'read_by': readBy,
      'moderation': moderation,
    };
  }
}

