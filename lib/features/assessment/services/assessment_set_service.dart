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
        final set = await _loadSetById(assignment.setId, type);
        if (set != null && set.questions.isNotEmpty) {
          return set;
        }
        throw StateError(
          'Assigned assessment set "${assignment.setId}" could not be loaded.',
        );
      }
    }

    final picked = await _pickRandomActiveSet(type);
    await assignmentRef.set(
      AssessmentAssignmentModel(
        type: type,
        setId: picked.id,
      ).toFirestoreNewAssignment(),
      SetOptions(merge: true),
    );
    return picked;
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
