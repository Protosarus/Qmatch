import 'package:cloud_firestore/cloud_firestore.dart';

class RevealStateModel {
  final int blurLevel; // 3..0
  final bool consentA;
  final bool consentB;
  final String? requestedBy;
  final Timestamp? requestedAt;
  final Timestamp? revealedAt;

  const RevealStateModel({
    this.blurLevel = 3,
    this.consentA = false,
    this.consentB = false,
    this.requestedBy,
    this.requestedAt,
    this.revealedAt,
  });

  bool get isFullyRevealed => revealedAt != null || (consentA && consentB) || blurLevel <= 0;

  bool hasConsentFrom(String uid, {required String userA, required String userB}) {
    if (uid == userA) return consentA;
    if (uid == userB) return consentB;
    return false;
  }

  bool isRequestedBy(String uid) => requestedBy != null && requestedBy == uid;

  bool isPendingFor(String uid) => requestedBy != null && requestedBy != uid && !isFullyRevealed;

  double get blurSigma {
    final level = blurLevel.clamp(0, 3);
    switch (level) {
      case 3:
        return 14.0;
      case 2:
        return 9.0;
      case 1:
        return 4.0;
      case 0:
      default:
        return 0.0;
    }
  }

  factory RevealStateModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RevealStateModel();

    // Support both snake_case (current Firestore) and camelCase (future)
    int? readInt(String snake, String camel) =>
        (map[snake] as num?)?.toInt() ?? (map[camel] as num?)?.toInt();
    bool? readBool(String snake, String camel) =>
        (map[snake] as bool?) ?? (map[camel] as bool?);
    String? readStr(String snake, String camel) =>
        (map[snake] as String?) ?? (map[camel] as String?);
    Timestamp? readTs(String snake, String camel) =>
        (map[snake] is Timestamp ? map[snake] as Timestamp : null) ??
        (map[camel] is Timestamp ? map[camel] as Timestamp : null);

    return RevealStateModel(
      blurLevel: readInt('blur_level', 'blurLevel') ?? 3,
      consentA: readBool('consent_a', 'consentA') ?? false,
      consentB: readBool('consent_b', 'consentB') ?? false,
      requestedBy: readStr('requested_by', 'requestedBy'),
      requestedAt: readTs('requested_at', 'requestedAt'),
      revealedAt: readTs('revealed_at', 'revealedAt'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blur_level': blurLevel,
      'consent_a': consentA,
      'consent_b': consentB,
      'requested_by': requestedBy,
      'requested_at': requestedAt,
      'revealed_at': revealedAt,
    };
  }

  RevealStateModel copyWith({
    int? blurLevel,
    bool? consentA,
    bool? consentB,
    String? requestedBy,
    Timestamp? requestedAt,
    Timestamp? revealedAt,
  }) {
    return RevealStateModel(
      blurLevel: blurLevel ?? this.blurLevel,
      consentA: consentA ?? this.consentA,
      consentB: consentB ?? this.consentB,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedAt: requestedAt ?? this.requestedAt,
      revealedAt: revealedAt ?? this.revealedAt,
    );
  }
}

