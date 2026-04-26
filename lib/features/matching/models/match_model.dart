import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchState {
  active,
  unmatched,
  blocked,
}

class MatchRevealModel {
  final int blurLevel;
  final bool consentA;
  final bool consentB;
  final String? requestedBy;
  final Timestamp? requestedAt;
  final Timestamp? revealedAt;

  const MatchRevealModel({
    this.blurLevel = 3,
    this.consentA = false,
    this.consentB = false,
    this.requestedBy,
    this.requestedAt,
    this.revealedAt,
  });

  factory MatchRevealModel.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const MatchRevealModel();
    return MatchRevealModel(
      blurLevel: (data['blur_level'] as num?)?.toInt() ?? 3,
      consentA: (data['consent_a'] as bool?) ?? false,
      consentB: (data['consent_b'] as bool?) ?? false,
      requestedBy: data['requested_by'] as String?,
      requestedAt: data['requested_at'] as Timestamp?,
      revealedAt: data['revealed_at'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'blur_level': blurLevel,
      'consent_a': consentA,
      'consent_b': consentB,
      'requested_by': requestedBy,
      'requested_at': requestedAt,
      'revealed_at': revealedAt,
    };
  }
}

class MatchModel {
  final String matchId;
  final String userA;
  final String userB;
  final List<String> users;
  final Timestamp? createdAt;
  final String? createdBy;
  final String threadId;
  final MatchState state;
  final Timestamp? lastActivityAt;
  final Map<String, dynamic>? compat;
  final MatchRevealModel reveal;

  const MatchModel({
    required this.matchId,
    required this.userA,
    required this.userB,
    required this.users,
    required this.threadId,
    this.createdAt,
    this.createdBy,
    this.state = MatchState.active,
    this.lastActivityAt,
    this.compat,
    this.reveal = const MatchRevealModel(),
  });

  static MatchState _stateFromString(String? value) {
    switch (value) {
      case 'active':
        return MatchState.active;
      case 'unmatched':
        return MatchState.unmatched;
      case 'blocked':
        return MatchState.blocked;
      default:
        return MatchState.active;
    }
  }

  factory MatchModel.fromFirestore(String matchId, Map<String, dynamic> data) {
    final users = List<String>.from((data['users'] as List?) ?? const []);
    return MatchModel(
      matchId: matchId,
      userA: (data['user_a'] as String?) ?? (users.isNotEmpty ? users.first : ''),
      userB: (data['user_b'] as String?) ?? (users.length > 1 ? users[1] : ''),
      users: users,
      createdAt: data['created_at'] as Timestamp?,
      createdBy: data['created_by'] as String?,
      threadId: (data['thread_id'] as String?) ?? '',
      state: _stateFromString(data['state'] as String?),
      lastActivityAt: data['last_activity_at'] as Timestamp?,
      compat: (data['compat'] as Map?)?.cast<String, dynamic>(),
      reveal: MatchRevealModel.fromFirestore(
        (data['reveal'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_a': userA,
      'user_b': userB,
      'users': users,
      'created_at': createdAt,
      'created_by': createdBy,
      'thread_id': threadId,
      'state': state.name,
      'last_activity_at': lastActivityAt,
      'compat': compat,
      'reveal': reveal.toFirestore(),
    };
  }
}

