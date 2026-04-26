import 'package:cloud_firestore/cloud_firestore.dart';

enum SwipeDirection {
  like,
  pass,
}

class SwipeModel {
  final String fromUid;
  final String targetUid;
  final SwipeDirection direction;
  final Timestamp? createdAt;
  final String? source;

  const SwipeModel({
    required this.fromUid,
    required this.targetUid,
    required this.direction,
    this.createdAt,
    this.source,
  });

  static SwipeDirection _directionFromString(String? value) {
    switch (value) {
      case 'like':
        return SwipeDirection.like;
      case 'pass':
        return SwipeDirection.pass;
      default:
        return SwipeDirection.pass;
    }
  }

  factory SwipeModel.fromFirestore(Map<String, dynamic> data) {
    return SwipeModel(
      fromUid: (data['from_uid'] as String?) ?? '',
      targetUid: (data['target_uid'] as String?) ?? '',
      direction: _directionFromString(data['direction'] as String?),
      createdAt: data['created_at'] as Timestamp?,
      source: data['source'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'from_uid': fromUid,
      'target_uid': targetUid,
      'direction': direction.name,
      'created_at': createdAt,
      'source': source,
    };
  }
}

