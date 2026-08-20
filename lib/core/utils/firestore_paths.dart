import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore path helpers for Qmatch.
///
/// Keep all collection/document naming in one place to avoid drift.
class FirestorePaths {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Root collections
  static CollectionReference<Map<String, dynamic>> users() =>
      _db.collection('users');
  static CollectionReference<Map<String, dynamic>> matches() =>
      _db.collection('matches');
  static CollectionReference<Map<String, dynamic>> threads() =>
      _db.collection('threads');
  static CollectionReference<Map<String, dynamic>> reports() =>
      _db.collection('reports');

  /// Per-user account deletion requests (ops processes these; app does not wipe data).
  static CollectionReference<Map<String, dynamic>> accountDeletionRequests() =>
      _db.collection('account_deletion_requests');

  static DocumentReference<Map<String, dynamic>> accountDeletionRequestDoc(
    String uid,
  ) =>
      accountDeletionRequests().doc(uid);

  /// Global assessment set definitions (IQ / EQ / frequency variants).
  static CollectionReference<Map<String, dynamic>> assessmentSets() =>
      _db.collection('assessment_sets');

  static DocumentReference<Map<String, dynamic>> assessmentSetDoc(
          String setId) =>
      assessmentSets().doc(setId);

  // users/{uid}
  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      users().doc(uid);

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

  /// Trusted Passport preference: `users/{uid}/preferences/discover_passport_v1`.
  /// Client reads only; writes are Admin callables.
  static DocumentReference<Map<String, dynamic>> userDiscoverPassportDoc(
    String uid,
  ) =>
      userDoc(uid).collection('preferences').doc('discover_passport_v1');

  /// Per-user assignment to a specific assessment set (`iq`, `eq`, `frequency`).
  static CollectionReference<Map<String, dynamic>> userAssessmentAssignments(
          String uid) =>
      userDoc(uid).collection('assessment_assignments');

  static DocumentReference<Map<String, dynamic>> userAssessmentAssignmentDoc(
    String uid,
    String type,
  ) =>
      userAssessmentAssignments(uid).doc(type);

  /// Canonical assessment results: `users/{uid}/assessments/{iq|eq|frequency|persona}`.
  static CollectionReference<Map<String, dynamic>> userAssessments(
          String uid) =>
      userDoc(uid).collection('assessments');

  static DocumentReference<Map<String, dynamic>> userAssessmentDoc(
    String uid,
    String assessmentType,
  ) =>
      userAssessments(uid).doc(assessmentType);

  /// Canonical multidimensional profile: `users/{uid}/profiles/canonical_v1`.
  static CollectionReference<Map<String, dynamic>> userProfiles(String uid) =>
      userDoc(uid).collection('profiles');

  static DocumentReference<Map<String, dynamic>> userCanonicalProfileDoc(
    String uid,
  ) =>
      userProfiles(uid).doc('canonical_v1');

  /// Trusted Resonance entitlement snapshot: `entitlements/{uid}` (owner read only).
  static CollectionReference<Map<String, dynamic>> entitlements() =>
      _db.collection('entitlements');

  static DocumentReference<Map<String, dynamic>> entitlementDoc(String uid) =>
      entitlements().doc(uid);

  // matches/{matchId}
  static DocumentReference<Map<String, dynamic>> matchDoc(String matchId) =>
      matches().doc(matchId);

  // threads/{threadId}
  static DocumentReference<Map<String, dynamic>> threadDoc(String threadId) =>
      threads().doc(threadId);

  // threads/{threadId}/messages
  static CollectionReference<Map<String, dynamic>> threadMessages(
          String threadId) =>
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
