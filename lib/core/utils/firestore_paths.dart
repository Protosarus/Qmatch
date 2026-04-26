import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore path helpers for Qmatch.
///
/// Keep all collection/document naming in one place to avoid drift.
class FirestorePaths {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Root collections
  static CollectionReference<Map<String, dynamic>> users() => _db.collection('users');
  static CollectionReference<Map<String, dynamic>> matches() => _db.collection('matches');
  static CollectionReference<Map<String, dynamic>> threads() => _db.collection('threads');
  static CollectionReference<Map<String, dynamic>> reports() => _db.collection('reports');

  // users/{uid}
  static DocumentReference<Map<String, dynamic>> userDoc(String uid) => users().doc(uid);

  // users/{uid}/swipes
  static CollectionReference<Map<String, dynamic>> userSwipes(String uid) =>
      userDoc(uid).collection('swipes');

  static DocumentReference<Map<String, dynamic>> userSwipeDoc(
    String uid,
    String targetUid,
  ) =>
      userSwipes(uid).doc(targetUid);

  // users/{uid}/blocks
  static CollectionReference<Map<String, dynamic>> userBlocks(String uid) =>
      userDoc(uid).collection('blocks');

  static DocumentReference<Map<String, dynamic>> userBlockDoc(
    String uid,
    String blockedUid,
  ) =>
      userBlocks(uid).doc(blockedUid);

  // matches/{matchId}
  static DocumentReference<Map<String, dynamic>> matchDoc(String matchId) =>
      matches().doc(matchId);

  // threads/{threadId}
  static DocumentReference<Map<String, dynamic>> threadDoc(String threadId) =>
      threads().doc(threadId);

  // threads/{threadId}/messages
  static CollectionReference<Map<String, dynamic>> threadMessages(String threadId) =>
      threadDoc(threadId).collection('messages');

  /// Deterministic match id using sorted UID order.
  static String deterministicMatchId(String uidA, String uidB) {
    final sorted = _sortedPair(uidA, uidB);
    return '${sorted.$1}_${sorted.$2}';
  }

  /// Deterministic thread id using sorted UID order.
  ///
  /// For MVP it mirrors the match id to keep linking simple.
  static String deterministicThreadId(String uidA, String uidB) {
    final sorted = _sortedPair(uidA, uidB);
    return '${sorted.$1}_${sorted.$2}';
  }

  static (String, String) _sortedPair(String a, String b) {
    if (a.compareTo(b) <= 0) return (a, b);
    return (b, a);
  }
}

