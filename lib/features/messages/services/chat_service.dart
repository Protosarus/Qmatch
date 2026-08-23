import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/chat_thread_model.dart';
import '../models/message_model.dart';
import '../utils/closed_account_chat_history.dart';

class ChatService {
  static const Set<String> supportedMessageReactions = {
    '❤️',
    '😂',
    '😮',
    '😢',
    '👍',
    '🔥',
  };

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ChatService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<ChatThreadModel>> getMyThreadsStream() {
    final me = _auth.currentUser;
    if (me == null) {
      return Stream<List<ChatThreadModel>>.error(
        StateError('User is not authenticated.'),
      );
    }

    return FirestorePaths.threads()
        .where('participants', arrayContains: me.uid)
        .snapshots()
        .map((snapshot) {
      final threads = snapshot.docs
          .map((d) => ChatThreadModel.fromFirestore(d.id, d.data()))
          .where(ClosedAccountChatHistory.includeInMessagesList)
          .toList();

      threads.sort((a, b) {
        final aTs = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final bTs = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        return bTs.compareTo(aTs);
      });

      return threads;
    });
  }

  Future<ChatThreadModel?> getThreadById(String threadId) async {
    final doc = await FirestorePaths.threadDoc(threadId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return ChatThreadModel.fromFirestore(threadId, data);
  }

  Future<Map<String, dynamic>?> getUserPublicProfile(String uid) async {
    final doc = await FirestorePaths.userDoc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    return {
      'uid': uid,
      'name': data['name'],
      'age': data['age'],
      'archetype': data['archetype'],
      'category': data['category'],
      'profile_photo_url': data['profile_photo_url'],
      'photos': data['photos'],
    };
  }

  String getOtherParticipantId(ChatThreadModel thread, String currentUid) {
    if (thread.participants.length < 2) {
      throw StateError('Invalid thread participants.');
    }
    for (final p in thread.participants) {
      if (p != currentUid) return p;
    }
    throw StateError('Invalid thread participants.');
  }

  /// Realtime messages for [threadId], ordered by [client_created_at] ascending (MVP stable ordering).
  Stream<List<MessageModel>> getMessagesStream(String threadId) async* {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final thread = await getThreadById(threadId);
    if (thread == null) {
      throw StateError('Thread not found.');
    }
    if (!thread.participants.contains(me.uid)) {
      throw StateError('Current user is not a participant of this thread.');
    }
    if (!ClosedAccountChatHistory.allowMessageHistoryRead(thread)) {
      throw StateError('This conversation is closed.');
    }

    yield* FirestorePaths.threadMessages(threadId)
        .orderBy('client_created_at', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((d) => MessageModel.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> sendTextMessage(String threadId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw StateError('Message cannot be empty.');
    }

    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final threadSnap = await FirestorePaths.threadDoc(threadId).get();
    final threadData = threadSnap.data();
    if (!threadSnap.exists || threadData == null) {
      throw StateError('Thread not found.');
    }

    final thread = ChatThreadModel.fromFirestore(threadId, threadData);
    if (!thread.participants.contains(me.uid)) {
      throw StateError('Current user is not a participant of this thread.');
    }
    if (!ClosedAccountChatHistory.allowSend(thread)) {
      throw StateError('This conversation is closed.');
    }

    final otherUid = thread.participants.firstWhere(
      (id) => id != me.uid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) {
      throw StateError('Invalid thread participants.');
    }

    final preview = trimmed.length > 80 ? trimmed.substring(0, 80) : trimmed;
    final msgRef = FirestorePaths.threadMessages(threadId).doc();
    final threadRef = FirestorePaths.threadDoc(threadId);

    final batch = _firestore.batch();
    batch.set(msgRef, {
      'thread_id': threadId,
      'sender_id': me.uid,
      'type': 'text',
      'text': trimmed,
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': DateTime.now().millisecondsSinceEpoch,
      'read_by': {
        me.uid: FieldValue.serverTimestamp(),
      },
      'moderation': null,
    });

    batch.update(threadRef, {
      'last_message_at': FieldValue.serverTimestamp(),
      'last_message_preview': preview,
      'last_message_sender': me.uid,
      'unread_counts.${me.uid}': 0,
      'unread_counts.$otherUid': FieldValue.increment(1),
      // MVP counters for reveal progression (safe on old threads: increments create fields).
      'text_count_total': FieldValue.increment(1),
      'text_count_by_uid.${me.uid}': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> sendGifMessage(String threadId, String gifUrl) async {
    final uri = Uri.tryParse(gifUrl.trim());
    final host = uri?.host.toLowerCase() ?? '';
    final isGiphyMedia = RegExp(r'^media\d*\.giphy\.com$').hasMatch(host);

    if (uri == null || uri.scheme != 'https' || !isGiphyMedia) {
      throw StateError('Invalid GIF URL.');
    }

    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final threadSnap = await FirestorePaths.threadDoc(threadId).get();
    final threadData = threadSnap.data();
    if (!threadSnap.exists || threadData == null) {
      throw StateError('Thread not found.');
    }

    final thread = ChatThreadModel.fromFirestore(threadId, threadData);
    if (!thread.participants.contains(me.uid)) {
      throw StateError('Current user is not a participant of this thread.');
    }
    if (!ClosedAccountChatHistory.allowSend(thread)) {
      throw StateError('This conversation is closed.');
    }

    final otherUid = thread.participants.firstWhere(
      (id) => id != me.uid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) {
      throw StateError('Invalid thread participants.');
    }

    final msgRef = FirestorePaths.threadMessages(threadId).doc();
    final threadRef = FirestorePaths.threadDoc(threadId);

    final batch = _firestore.batch();
    batch.set(msgRef, {
      'thread_id': threadId,
      'sender_id': me.uid,
      'type': 'gif',
      'text': '',
      'gif_provider': 'giphy',
      'gif_url': uri.toString(),
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': DateTime.now().millisecondsSinceEpoch,
      'read_by': {
        me.uid: FieldValue.serverTimestamp(),
      },
      'moderation': null,
    });

    batch.update(threadRef, {
      'last_message_at': FieldValue.serverTimestamp(),
      'last_message_preview': 'GIF',
      'last_message_sender': me.uid,
      'unread_counts.${me.uid}': 0,
      'unread_counts.$otherUid': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> toggleMessageReaction({
    required String threadId,
    required String messageId,
    required String reaction,
  }) async {
    if (!supportedMessageReactions.contains(reaction)) {
      throw StateError('Unsupported message reaction.');
    }

    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final threadSnap = await FirestorePaths.threadDoc(threadId).get();
    final threadData = threadSnap.data();
    if (!threadSnap.exists || threadData == null) {
      throw StateError('Thread not found.');
    }

    final thread = ChatThreadModel.fromFirestore(threadId, threadData);
    if (!thread.participants.contains(me.uid)) {
      throw StateError('Current user is not a participant of this thread.');
    }
    if (!ClosedAccountChatHistory.allowSend(thread)) {
      throw StateError('This conversation is closed.');
    }

    final messageRef = FirestorePaths.threadMessages(threadId).doc(messageId);
    final messageSnap = await messageRef.get();
    final messageData = messageSnap.data();

    if (!messageSnap.exists || messageData == null) {
      throw StateError('Message not found.');
    }

    final message = MessageModel.fromFirestore(
      messageId,
      messageData,
    );

    if (message.type != MessageType.text && message.type != MessageType.gif) {
      throw StateError('This message cannot be reacted to.');
    }
    if (message.senderId == 'system') {
      throw StateError('System messages cannot be reacted to.');
    }

    final currentReaction = message.reactions[me.uid];

    await messageRef.update({
      'reactions.${me.uid}':
          currentReaction == reaction ? FieldValue.delete() : reaction,
    });
  }

  Future<void> sendImageMessage({
    required String threadId,
    required String imageUrl,
    required String storagePath,
  }) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final uri = Uri.tryParse(imageUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.toLowerCase() != 'firebasestorage.googleapis.com') {
      throw StateError('Invalid chat image URL.');
    }

    final expectedPrefix = 'chat_media/$threadId/${me.uid}/';
    if (!storagePath.startsWith(expectedPrefix) ||
        storagePath.substring(expectedPrefix.length).contains('/')) {
      throw StateError('Invalid chat image storage path.');
    }

    final threadSnap = await FirestorePaths.threadDoc(threadId).get();
    final threadData = threadSnap.data();
    if (!threadSnap.exists || threadData == null) {
      throw StateError('Thread not found.');
    }

    final thread = ChatThreadModel.fromFirestore(threadId, threadData);
    if (!thread.participants.contains(me.uid)) {
      throw StateError(
        'Current user is not a participant of this thread.',
      );
    }
    if (!ClosedAccountChatHistory.allowSend(thread)) {
      throw StateError('This conversation is closed.');
    }

    final otherUid = thread.participants.firstWhere(
      (id) => id != me.uid,
      orElse: () => '',
    );
    if (otherUid.isEmpty) {
      throw StateError('Invalid thread participants.');
    }

    final msgRef = FirestorePaths.threadMessages(threadId).doc();
    final threadRef = FirestorePaths.threadDoc(threadId);

    final batch = _firestore.batch();

    batch.set(msgRef, {
      'thread_id': threadId,
      'sender_id': me.uid,
      'type': 'image',
      'text': '',
      'image_url': uri.toString(),
      'image_storage_path': storagePath,
      'created_at': FieldValue.serverTimestamp(),
      'client_created_at': DateTime.now().millisecondsSinceEpoch,
      'read_by': {
        me.uid: FieldValue.serverTimestamp(),
      },
      'moderation': null,
    });

    batch.update(threadRef, {
      'last_message_at': FieldValue.serverTimestamp(),
      'last_message_preview': '📷',
      'last_message_sender': me.uid,
      'unread_counts.${me.uid}': 0,
      'unread_counts.$otherUid': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<ChatThreadModel> markThreadAsRead(String threadId) async {
    final me = _auth.currentUser;
    if (me == null) {
      throw StateError('User is not authenticated.');
    }

    final thread = await getThreadById(threadId);
    if (thread == null) {
      throw StateError('Thread not found.');
    }
    if (!thread.participants.contains(me.uid)) {
      throw StateError('Current user is not a participant of this thread.');
    }

    await FirestorePaths.threadDoc(threadId).update({
      'unread_counts.${me.uid}': 0,
    });
    return thread;
  }
}
