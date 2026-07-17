import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String reporterUid;
  final String reportedUid;
  final String? matchId;
  final String? threadId;
  final String? messageId;
  final String reason;
  final String? details;
  final Timestamp? createdAt;
  final String status;

  const ReportModel({
    required this.reportId,
    required this.reporterUid,
    required this.reportedUid,
    this.matchId,
    this.threadId,
    this.messageId,
    required this.reason,
    this.details,
    this.createdAt,
    this.status = 'new',
  });

  factory ReportModel.fromFirestore(String reportId, Map<String, dynamic> data) {
    return ReportModel(
      reportId: reportId,
      reporterUid: (data['reporter_uid'] as String?) ?? '',
      reportedUid: (data['reported_uid'] as String?) ?? '',
      matchId: data['match_id'] as String?,
      threadId: data['thread_id'] as String?,
      messageId: data['message_id'] as String?,
      reason: (data['reason'] as String?) ?? 'other',
      details: data['details'] as String?,
      createdAt: data['created_at'] as Timestamp?,
      status: (data['status'] as String?) ?? 'new',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporter_uid': reporterUid,
      'reported_uid': reportedUid,
      'match_id': matchId,
      'thread_id': threadId,
      'message_id': messageId,
      'reason': reason,
      'details': details,
      'created_at': createdAt,
      'status': status,
    };
  }
}
