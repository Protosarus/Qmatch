import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/chat_thread_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseAuth _auth;

  ChatService({
    FirebaseAuth? auth,
  })  : _auth = auth ?? FirebaseAuth.instance,
        super();

  Stream<List<ChatThreadModel>> getMyThreadsStream() {
    final me = _auth.currentUser;
    if (me == null) return const Stream<List<ChatThreadModel>>.empty();

    // TODO: Consider indexing + ordering (last_message_at desc).
    return FirestorePaths.threads()
        .where('participants', arrayContains: me.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => ChatThreadModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Stream<List<MessageModel>> getMessagesStream(String threadId) {
    final me = _auth.currentUser;
    if (me == null) return const Stream<List<MessageModel>>.empty();

    // TODO: Enforce participant checks via security rules.
    return FirestorePaths.threadMessages(threadId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((d) => MessageModel.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> sendTextMessage(String threadId, String text) async {
    final me = _auth.currentUser;
    if (me == null) return;
    if (text.trim().isEmpty) return;

    // TODO: Update thread preview/unreads transactionally.
    final msgRef = FirestorePaths.threadMessages(threadId).doc();
    await msgRef.set(
      MessageModel(
        messageId: msgRef.id,
        threadId: threadId,
        senderId: me.uid,
        type: MessageType.text,
        text: text.trim(),
        createdAt: Timestamp.now(),
        clientCreatedAt: DateTime.now().millisecondsSinceEpoch,
      ).toFirestore(),
    );
  }

  Future<void> markThreadAsRead(String threadId) async {
    final me = _auth.currentUser;
    if (me == null) return;

    // TODO: Set unread_counts[me.uid] = 0 (merge) and/or update message read_by.
    await FirestorePaths.threadDoc(threadId).set(
      {
        'unread_counts': {me.uid: 0},
        'last_read_at_${me.uid}': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

