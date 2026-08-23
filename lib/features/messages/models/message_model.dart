import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  gif,
  system,
  revealRequest,
}

class MessageModel {
  final String messageId;
  final String threadId;
  final String senderId;
  final MessageType type;
  final String text;
  final String? gifUrl;
  final String? gifProvider;
  final Timestamp? createdAt;
  final int? clientCreatedAt;
  final Map<String, Timestamp> readBy;
  final Map<String, String> reactions;
  final Map<String, dynamic>? moderation;

  const MessageModel({
    required this.messageId,
    required this.threadId,
    required this.senderId,
    required this.type,
    required this.text,
    this.gifUrl,
    this.gifProvider,
    this.createdAt,
    this.clientCreatedAt,
    this.readBy = const {},
    this.reactions = const {},
    this.moderation,
  });

  static MessageType _typeFromString(String? value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'gif':
        return MessageType.gif;
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
      case MessageType.gif:
        return 'gif';
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
    final readByRaw =
        (data['read_by'] as Map?)?.cast<String, dynamic>() ?? const {};
    final readBy = <String, Timestamp>{};
    for (final entry in readByRaw.entries) {
      final ts = entry.value;
      if (ts is Timestamp) {
        readBy[entry.key] = ts;
      }
    }

    final reactionsRaw =
        (data['reactions'] as Map?)?.cast<String, dynamic>() ?? const {};
    final reactions = <String, String>{};
    for (final entry in reactionsRaw.entries) {
      final value = entry.value;
      if (value is String && value.trim().isNotEmpty) {
        reactions[entry.key] = value;
      }
    }

    return MessageModel(
      messageId: messageId,
      threadId: (data['thread_id'] as String?) ?? '',
      senderId: (data['sender_id'] as String?) ?? '',
      type: _typeFromString(data['type'] as String?),
      text: (data['text'] as String?) ?? '',
      gifUrl: (data['gif_url'] as String?)?.trim(),
      gifProvider: (data['gif_provider'] as String?)?.trim(),
      createdAt: data['created_at'] is Timestamp
          ? data['created_at'] as Timestamp
          : null,
      clientCreatedAt: (data['client_created_at'] as num?)?.toInt(),
      readBy: readBy,
      reactions: reactions,
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
      if (gifUrl != null) 'gif_url': gifUrl,
      if (gifProvider != null) 'gif_provider': gifProvider,
      'created_at': createdAt,
      'client_created_at': clientCreatedAt,
      'read_by': readBy,
      if (reactions.isNotEmpty) 'reactions': reactions,
      'moderation': moderation,
    };
  }
}
