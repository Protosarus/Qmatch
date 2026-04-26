import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String blockedUid;
  final Timestamp? createdAt;
  final String? reason;

  const BlockModel({
    required this.blockedUid,
    this.createdAt,
    this.reason,
  });

  factory BlockModel.fromFirestore(Map<String, dynamic> data) {
    return BlockModel(
      blockedUid: (data['blocked_uid'] as String?) ?? '',
      createdAt: data['created_at'] as Timestamp?,
      reason: data['reason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'blocked_uid': blockedUid,
      'created_at': createdAt,
      'reason': reason,
    };
  }
}

