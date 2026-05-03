import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/firestore_paths.dart';
import '../models/assessment_set_model.dart';

/// Assigns persistent IQ/EQ/Frequency question sets per user via Firestore.
///
/// Primary store: `assessment_sets/{setId}`
/// Assignments: `users/{uid}/assessment_assignments/{type}`
///
/// Question order is shuffled once per assignment and stored in `question_order`.
/// IQ option permutations are stored in `option_orders` (EQ/Frequency options stay ordered).
class AssessmentSetService {
  AssessmentSetService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<AssessmentSetModel> getOrAssignSet({required String type}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    final assignmentRef =
        FirestorePaths.userAssessmentAssignmentDoc(user.uid, type);
    final assignmentSnap = await assignmentRef.get();

    if (assignmentSnap.exists && assignmentSnap.data() != null) {
      final assignment = AssessmentAssignmentModel.fromFirestore(
        assignmentSnap.data()!,
      );
      if (assignment.setId.isNotEmpty) {
        final rawSet = await _loadSetById(assignment.setId, type);
        if (rawSet == null || rawSet.questions.isEmpty) {
          throw StateError(
            'Assigned assessment set "${assignment.setId}" could not be loaded.',
          );
        }

        final normalized = _ensureQuestionIds(rawSet);
        final synced = await _syncAssignmentOrders(
          assignmentRef,
          assignment,
          normalized,
          type,
        );

        debugPrint(
          'AssessmentSet[$type]: set=${normalized.id} '
          'questions=${normalized.questions.length} '
          'order=${synced.didRepair ? "repaired/saved" : "reused"}',
        );

        return _applyOrdersToSet(normalized, synced.model, type);
      }
    }

    final picked = await _pickRandomActiveSet(type);
    final normalized = _ensureQuestionIds(picked);
    final questionOrder = _buildShuffledQuestionIds(normalized);
    final optionOrders = type == 'iq'
        ? _buildOptionPermutationsForMcq(normalized.questions)
        : <String, List<int>>{};

    final newAssignment = AssessmentAssignmentModel(
      type: type,
      setId: normalized.id,
      questionOrder: questionOrder,
      optionOrders: optionOrders,
    );

    await assignmentRef.set(
      newAssignment.toFirestoreNewAssignment(),
      SetOptions(merge: true),
    );

    debugPrint(
      'AssessmentSet[$type]: set=${normalized.id} '
      'questions=${normalized.questions.length} order=created',
    );

    return _applyOrdersToSet(normalized, newAssignment, type);
  }

  Future<void> markAssignmentCompleted({
    required String type,
    required num score,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    await FirestorePaths.userAssessmentAssignmentDoc(user.uid, type).set(
      {
        'completed': true,
        'completed_at': FieldValue.serverTimestamp(),
        'score': score,
      },
      SetOptions(merge: true),
    );
  }

  // --- Question ids ---

  AssessmentSetModel _ensureQuestionIds(AssessmentSetModel set) {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < set.questions.length; i++) {
      final m = Map<String, dynamic>.from(set.questions[i]);
      final idRaw = m['id'];
      final idStr = idRaw?.toString().trim() ?? '';
      if (idStr.isEmpty) {
        m['id'] = '${set.id}_q_${i + 1}';
      }
      out.add(m);
    }
    return AssessmentSetModel(
      id: set.id,
      type: set.type,
      setNumber: set.setNumber,
      version: set.version,
      active: set.active,
      questionCount: set.questionCount,
      questions: out,
      createdAt: set.createdAt,
      updatedAt: set.updatedAt,
    );
  }

  List<String> _buildShuffledQuestionIds(AssessmentSetModel set) {
    final ids = set.questions.map((q) => q['id'] as String).toList();
    ids.shuffle(Random());
    return ids;
  }

  Map<String, List<int>> _buildOptionPermutationsForMcq(
    List<Map<String, dynamic>> questions,
  ) {
    final rnd = Random();
    final out = <String, List<int>>{};
    for (final q in questions) {
      final id = q['id'] as String;
      final opts = q['options'];
      final n = opts is List ? opts.length : 0;
      if (n <= 1) continue;
      out[id] = List<int>.generate(n, (i) => i)..shuffle(rnd);
    }
    return out;
  }

  // --- Order repair / sync ---

  Future<({AssessmentAssignmentModel model, bool didRepair})> _syncAssignmentOrders(
    DocumentReference<Map<String, dynamic>> assignmentRef,
    AssessmentAssignmentModel assignment,
    AssessmentSetModel normalizedSet,
    String type,
  ) async {
    final canonicalIds =
        normalizedSet.questions.map((q) => q['id'] as String).toList();

    if (assignment.completed) {
      var qOrder = List<String>.from(assignment.questionOrder);
      if (qOrder.isEmpty) {
        qOrder = List<String>.from(canonicalIds);
      }
      final opts =
          type == 'iq' ? Map<String, List<int>>.from(assignment.optionOrders) : <String, List<int>>{};
      return (
        model: AssessmentAssignmentModel(
          type: assignment.type,
          setId: assignment.setId,
          assignedAt: assignment.assignedAt,
          completed: assignment.completed,
          completedAt: assignment.completedAt,
          score: assignment.score,
          questionOrder: qOrder,
          optionOrders: opts,
        ),
        didRepair: false,
      );
    }

    var qOrder = List<String>.from(assignment.questionOrder);
    var optOrders = type == 'iq'
        ? Map<String, List<int>>.from(assignment.optionOrders)
        : <String, List<int>>{};

    final repairedQ = _repairQuestionOrder(canonicalIds, qOrder);
    var repaired = !listEquals(repairedQ, qOrder);
    qOrder = repairedQ;

    if (type == 'iq') {
      final fixedOpt =
          _repairOptionOrdersForIq(normalizedSet.questions, optOrders);
      if (!_optionOrdersMapsEqual(fixedOpt, optOrders)) {
        repaired = true;
      }
      optOrders = fixedOpt;
    } else if (optOrders.isNotEmpty) {
      optOrders = {};
      repaired = true;
    }

    if (repaired) {
      await assignmentRef.set(
        {
          'question_order': qOrder,
          'option_orders': optOrders,
        },
        SetOptions(merge: true),
      );
    }

    return (
      model: AssessmentAssignmentModel(
        type: assignment.type,
        setId: assignment.setId,
        assignedAt: assignment.assignedAt,
        completed: assignment.completed,
        completedAt: assignment.completedAt,
        score: assignment.score,
        questionOrder: qOrder,
        optionOrders: optOrders,
      ),
      didRepair: repaired,
    );
  }

  List<String> _repairQuestionOrder(
    List<String> canonicalIds,
    List<String> savedOrder,
  ) {
    if (canonicalIds.isEmpty) return const [];
    final idSet = canonicalIds.toSet();

    if (savedOrder.isEmpty) {
      return List<String>.from(canonicalIds)..shuffle(Random());
    }

    final seen = <String>{};
    final base = <String>[];
    for (final id in savedOrder) {
      if (idSet.contains(id) && seen.add(id)) {
        base.add(id);
      }
    }
    final missing = <String>[];
    for (final id in canonicalIds) {
      if (!seen.contains(id)) missing.add(id);
    }
    missing.shuffle(Random());
    var result = [...base, ...missing];

    if (result.length != canonicalIds.length ||
        result.toSet().length != canonicalIds.length) {
      result = List<String>.from(canonicalIds)..shuffle(Random());
    }
    return result;
  }

  Map<String, List<int>> _repairOptionOrdersForIq(
    List<Map<String, dynamic>> questions,
    Map<String, List<int>> existing,
  ) {
    final rnd = Random();
    final out = <String, List<int>>{};
    for (final q in questions) {
      final id = q['id'] as String;
      final opts = q['options'];
      final n = opts is List ? opts.length : 0;
      if (n <= 1) continue;

      final prev = existing[id];
      if (prev != null &&
          prev.length == n &&
          _isPermutationIndices(prev, n)) {
        out[id] = List<int>.from(prev);
      } else {
        out[id] = List<int>.generate(n, (i) => i)..shuffle(rnd);
      }
    }
    return out;
  }

  bool _isPermutationIndices(List<int> perm, int n) {
    if (perm.length != n) return false;
    final s = perm.toSet();
    return s.length == n && s.every((e) => e >= 0 && e < n);
  }

  bool _optionOrdersMapsEqual(
    Map<String, List<int>> a,
    Map<String, List<int>> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!listEquals(e.value, b[e.key])) return false;
    }
    return true;
  }

  // --- Apply persisted orders to returned set ---

  AssessmentSetModel _applyOrdersToSet(
    AssessmentSetModel normalized,
    AssessmentAssignmentModel assignment,
    String type,
  ) {
    final byId = <String, Map<String, dynamic>>{
      for (final q in normalized.questions)
        q['id'] as String: Map<String, dynamic>.from(q),
    };

    final order = assignment.questionOrder.isNotEmpty
        ? assignment.questionOrder
        : normalized.questions.map((q) => q['id'] as String).toList();

    final ordered = <Map<String, dynamic>>[];
    final used = <String>{};
    for (final id in order) {
      final m = byId[id];
      if (m != null && used.add(id)) {
        ordered.add(Map<String, dynamic>.from(m));
      }
    }
    for (final q in normalized.questions) {
      final id = q['id'] as String;
      if (!used.contains(id)) {
        ordered.add(Map<String, dynamic>.from(q));
      }
    }

    if (type == 'iq') {
      for (var i = 0; i < ordered.length; i++) {
        final id = ordered[i]['id'] as String;
        final perm = assignment.optionOrders[id];
        if (perm != null && perm.isNotEmpty) {
          ordered[i] = _applyOptionPermutationToQuestionMap(ordered[i], perm);
        }
      }
    }

    return AssessmentSetModel(
      id: normalized.id,
      type: normalized.type,
      setNumber: normalized.setNumber,
      version: normalized.version,
      active: normalized.active,
      questionCount: ordered.length,
      questions: ordered,
      createdAt: normalized.createdAt,
      updatedAt: normalized.updatedAt,
    );
  }

  Map<String, dynamic> _applyOptionPermutationToQuestionMap(
    Map<String, dynamic> q,
    List<int> order,
  ) {
    final optionsRaw = q['options'];
    if (optionsRaw is! List) return q;
    final options =
        List<String>.from(optionsRaw.map((e) => e.toString()));
    if (order.length != options.length ||
        !_isPermutationIndices(order, options.length)) {
      return q;
    }

    final oldCorrectRaw = q['correctAnswer'];
    final oldCorrect = oldCorrectRaw is int
        ? oldCorrectRaw
        : (oldCorrectRaw as num?)?.toInt();
    if (oldCorrect == null ||
        oldCorrect < 0 ||
        oldCorrect >= options.length) {
      return q;
    }

    final newCorrect = order.indexOf(oldCorrect);
    if (newCorrect < 0) return q;

    final newOptions = List<String>.generate(
      order.length,
      (i) => options[order[i]],
    );

    return Map<String, dynamic>.from(q)
      ..['options'] = newOptions
      ..['correctAnswer'] = newCorrect;
  }

  Future<AssessmentSetModel?> _loadSetById(String setId, String type) async {
    final primary =
        await FirestorePaths.assessmentSetDoc(setId).get();
    if (primary.exists && primary.data() != null) {
      return AssessmentSetModel.fromFirestore(setId, primary.data()!);
    }

    // TODO: Legacy questions collection fallback. New scalable system uses assessment_sets.
    final legacy = await _firestore.collection('questions').doc(setId).get();
    if (legacy.exists && legacy.data() != null) {
      return AssessmentSetModel.fromLegacyQuestionsDoc(setId, legacy.data()!);
    }

    final bundled = await _loadSetFromAssetById(setId, type);
    if (bundled != null) return bundled;

    if (setId.startsWith('local_flat_') &&
        (type == 'iq' || type == 'eq')) {
      try {
        return await _loadLegacyFlatQuestionAsset(type);
      } catch (_) {}
    }

    return null;
  }

  Future<AssessmentSetModel> _pickRandomActiveSet(String type) async {
    final fromSets = await _queryActiveAssessmentSets(type);
    if (fromSets.isNotEmpty) {
      return fromSets[Random().nextInt(fromSets.length)];
    }

    // TODO: Legacy questions collection fallback. New scalable system uses assessment_sets.
    final fromLegacy = await _queryLegacyQuestionDocs(type);
    if (fromLegacy.isNotEmpty) {
      return fromLegacy[Random().nextInt(fromLegacy.length)];
    }

    try {
      return await _loadRandomSetFromAssetBundle(type);
    } catch (e, st) {
      debugPrint('AssessmentSetService asset fallback failed: $e\n$st');
    }

    if (type == 'iq' || type == 'eq') {
      try {
        return await _loadLegacyFlatQuestionAsset(type);
      } catch (e, st) {
        debugPrint('AssessmentSetService flat JSON fallback failed: $e\n$st');
      }
    }

    throw StateError('No active assessment set found for type: $type');
  }

  Future<List<AssessmentSetModel>> _queryActiveAssessmentSets(String type) async {
    final snap = await FirestorePaths.assessmentSets()
        .where('type', isEqualTo: type)
        .limit(100)
        .get();

    final out = <AssessmentSetModel>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if ((data['active'] as bool?) != true) continue;
      final m = AssessmentSetModel.fromFirestore(doc.id, data);
      if (m.questions.isEmpty) continue;
      out.add(m);
    }
    return out;
  }

  Future<List<AssessmentSetModel>> _queryLegacyQuestionDocs(String type) async {
    final snap = await _firestore
        .collection('questions')
        .where('type', isEqualTo: type)
        .limit(100)
        .get();

    final out = <AssessmentSetModel>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      if ((data['active'] as bool?) != true) continue;
      final m = AssessmentSetModel.fromLegacyQuestionsDoc(doc.id, data);
      if (m.questions.isEmpty) continue;
      out.add(m);
    }
    return out;
  }

  Future<AssessmentSetModel> _loadRandomSetFromAssetBundle(String type) async {
    final path = 'assets/data/assessment_sets/${type}_sets.json';
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final sets = (decoded['sets'] as List<dynamic>?) ?? const [];
    final active = <AssessmentSetModel>[];
    for (final s in sets) {
      final map = Map<String, dynamic>.from(s as Map<dynamic, dynamic>);
      final model = AssessmentSetModel.fromJson(map);
      if (!model.active || model.questions.isEmpty) continue;
      active.add(model);
    }
    if (active.isEmpty) {
      throw StateError('No active assessment set found for type: $type');
    }
    return active[Random().nextInt(active.length)];
  }

  Future<AssessmentSetModel?> _loadSetFromAssetById(
    String setId,
    String type,
  ) async {
    try {
      final path = 'assets/data/assessment_sets/${type}_sets.json';
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final sets = (decoded['sets'] as List<dynamic>?) ?? const [];
      for (final s in sets) {
        final map = Map<String, dynamic>.from(s as Map<dynamic, dynamic>);
        if ((map['id'] as String?) == setId) {
          return AssessmentSetModel.fromJson(map);
        }
      }
    } catch (e) {
      debugPrint('_loadSetFromAssetById failed: $e');
    }
    return null;
  }

  Future<AssessmentSetModel> _loadLegacyFlatQuestionAsset(String type) async {
    final path =
        type == 'iq' ? 'assets/data/iq_questions.json' : 'assets/data/eq_questions.json';
    final raw = await rootBundle.loadString(path);
    final list = json.decode(raw) as List<dynamic>;
    final questions = list
        .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
        .toList();

    return AssessmentSetModel(
      id: 'local_flat_${type}_v1',
      type: type,
      setNumber: 0,
      version: 'local_flat',
      active: true,
      questionCount: questions.length,
      questions: questions,
    );
  }
}
