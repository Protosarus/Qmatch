import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityEventType {
  photoAdded,
  bioUpdated,
  workEducationUpdated,
  matchCreated,
  superResonanceReceived,
  anthemUpdated,
  unknown,
}

class ActivityEventModel {
  const ActivityEventModel({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.createdAt,
    this.actorName,
    this.actorPhotoUrl,
    this.photoUrl,
    this.photoAddedCount = 0,
    this.changedFields = const <String>[],
    this.matchId,
    this.threadId,
    this.signalId,
    this.sourceCollection,
    this.sourceId,
  });

  final String id;
  final ActivityEventType type;
  final String actorUid;
  final Timestamp? createdAt;

  final String? actorName;
  final String? actorPhotoUrl;

  final String? photoUrl;
  final int photoAddedCount;
  final List<String> changedFields;

  final String? matchId;
  final String? threadId;
  final String? signalId;

  final String? sourceCollection;
  final String? sourceId;

  static ActivityEventType _typeFromString(String? value) {
    switch (value) {
      case 'photo_added':
        return ActivityEventType.photoAdded;
      case 'bio_updated':
        return ActivityEventType.bioUpdated;
      case 'work_education_updated':
        return ActivityEventType.workEducationUpdated;
      case 'match_created':
        return ActivityEventType.matchCreated;
      case 'super_resonance_received':
        return ActivityEventType.superResonanceReceived;
      case 'anthem_updated':
        return ActivityEventType.anthemUpdated;
      default:
        return ActivityEventType.unknown;
    }
  }

  static String? _optionalString(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  factory ActivityEventModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final changedFieldsRaw = data['changed_fields'];

    return ActivityEventModel(
      id: id,
      type: _typeFromString(data['type'] as String?),
      actorUid: _optionalString(data['actor_uid']) ?? '',
      actorName: _optionalString(data['actor_name']),
      actorPhotoUrl: _optionalString(data['actor_photo_url']),
      createdAt: data['created_at'] is Timestamp
          ? data['created_at'] as Timestamp
          : null,
      photoUrl: _optionalString(data['photo_url']),
      photoAddedCount: (data['photo_added_count'] as num?)?.toInt() ?? 0,
      changedFields: changedFieldsRaw is List
          ? changedFieldsRaw.whereType<String>().toList(growable: false)
          : const <String>[],
      matchId: _optionalString(data['match_id']),
      threadId: _optionalString(data['thread_id']),
      signalId: _optionalString(data['signal_id']),
      sourceCollection: _optionalString(data['source_collection']),
      sourceId: _optionalString(data['source_id']),
    );
  }
}
