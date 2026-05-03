import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore: `assessment_sets/{setId}`
class AssessmentSetModel {
  final String id;
  final String type;
  final int setNumber;
  final String version;
  final bool active;
  final int questionCount;
  final List<Map<String, dynamic>> questions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssessmentSetModel({
    required this.id,
    required this.type,
    this.setNumber = 0,
    this.version = '',
    this.active = true,
    this.questionCount = 0,
    this.questions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AssessmentSetModel.fromFirestore(String docId, Map<String, dynamic> data) {
    final rawQuestions = data['questions'] as List<dynamic>? ?? const [];
    final questions = rawQuestions
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();

    return AssessmentSetModel(
      id: (data['id'] as String?)?.trim().isNotEmpty == true ? data['id'] as String : docId,
      type: (data['type'] as String?) ?? '',
      setNumber: (data['set_number'] as num?)?.toInt() ?? 0,
      version: (data['version'] as String?) ?? '',
      active: data['active'] as bool? ?? false,
      questionCount: (data['question_count'] as num?)?.toInt() ??
          questions.length,
      questions: questions,
      createdAt: _tsToDate(data['created_at']),
      updatedAt: _tsToDate(data['updated_at']),
    );
  }

  /// Local seed JSON object (one element of `sets` array).
  factory AssessmentSetModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    final questions = rawQuestions
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();

    return AssessmentSetModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      setNumber: (json['set_number'] as num?)?.toInt() ?? 0,
      version: json['version'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      questionCount:
          (json['question_count'] as num?)?.toInt() ?? questions.length,
      questions: questions,
      createdAt: null,
      updatedAt: null,
    );
  }

  /// Converts legacy `questions/{docId}` documents into the unified shape.
  factory AssessmentSetModel.fromLegacyQuestionsDoc(
    String docId,
    Map<String, dynamic> data,
  ) {
    final rawQuestions = data['questions'] as List<dynamic>? ?? const [];
    final questions = rawQuestions
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();

    return AssessmentSetModel(
      id: docId,
      type: (data['type'] as String?) ?? '',
      setNumber: (data['set_number'] as num?)?.toInt() ?? 0,
      version: (data['version'] as String?) ?? 'legacy',
      active: data['active'] as bool? ?? true,
      questionCount: (data['question_count'] as num?)?.toInt() ??
          questions.length,
      questions: questions,
      createdAt: _tsToDate(data['created_at']),
      updatedAt: _tsToDate(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': type,
      'set_number': setNumber,
      'version': version,
      'active': active,
      'question_count': questionCount,
      'questions': questions,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }

  static DateTime? _tsToDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

/// Firestore: `users/{uid}/assessment_assignments/{type}`
class AssessmentAssignmentModel {
  final String type;
  final String setId;
  final Timestamp? assignedAt;
  final bool completed;
  final Timestamp? completedAt;
  final num? score;
  /// Persisted as `question_order` — stable question ids for this user (shuffled once).
  final List<String> questionOrder;
  /// Persisted as `option_orders` — per-question permutation of original option indexes (IQ only).
  final Map<String, List<int>> optionOrders;

  const AssessmentAssignmentModel({
    required this.type,
    required this.setId,
    this.assignedAt,
    this.completed = false,
    this.completedAt,
    this.score,
    this.questionOrder = const [],
    this.optionOrders = const {},
  });

  factory AssessmentAssignmentModel.fromFirestore(Map<String, dynamic> data) {
    return AssessmentAssignmentModel(
      type: (data['type'] as String?) ?? '',
      setId: (data['set_id'] as String?) ?? '',
      assignedAt: data['assigned_at'] is Timestamp
          ? data['assigned_at'] as Timestamp
          : null,
      completed: data['completed'] as bool? ?? false,
      completedAt: data['completed_at'] is Timestamp
          ? data['completed_at'] as Timestamp
          : null,
      score: data['score'] as num?,
      questionOrder: _parseQuestionOrder(data['question_order']),
      optionOrders: _parseOptionOrders(data['option_orders']),
    );
  }

  static List<String> _parseQuestionOrder(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final e in raw) {
      if (e != null) out.add(e.toString());
    }
    return out;
  }

  static Map<String, List<int>> _parseOptionOrders(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, List<int>>{};
    for (final e in raw.entries) {
      final k = e.key.toString();
      final v = e.value;
      if (v is List) {
        final ints = <int>[];
        for (final x in v) {
          if (x is num) {
            ints.add(x.toInt());
          }
        }
        out[k] = ints;
      }
    }
    return out;
  }

  Map<String, dynamic> toFirestoreNewAssignment() {
    return {
      'type': type,
      'set_id': setId,
      'assigned_at': FieldValue.serverTimestamp(),
      'completed': false,
      'completed_at': null,
      'score': null,
      'question_order': questionOrder,
      'option_orders': {
        for (final e in optionOrders.entries) e.key: e.value,
      },
    };
  }
}
