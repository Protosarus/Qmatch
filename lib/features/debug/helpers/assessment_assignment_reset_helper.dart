import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/firestore_paths.dart';

/// Debug-only report for current-user full assessment state reset.
class AssessmentFullStateResetReport {
  const AssessmentFullStateResetReport({
    required this.refused,
    this.refusalReason,
    required this.currentUserIdMasked,
    required this.assignmentDocsDeleted,
    required this.resultDocsDeleted,
    required this.userFieldsDeleted,
    required this.userFieldsPreservedNote,
    required this.errors,
    required this.warnings,
    required this.writesPerformed,
    required this.globalContentTouched,
    required this.scope,
  });

  final bool refused;
  final String? refusalReason;
  final String currentUserIdMasked;
  final int assignmentDocsDeleted;
  final int resultDocsDeleted;
  final List<String> userFieldsDeleted;
  final String userFieldsPreservedNote;
  final List<String> errors;
  final List<String> warnings;
  final bool writesPerformed;
  final bool globalContentTouched;
  final String scope;
}

/// Debug-only report for current-user assessment assignment reset.
class AssessmentAssignmentResetReport {
  const AssessmentAssignmentResetReport({
    required this.refused,
    this.refusalReason,
    required this.currentUserIdMasked,
    required this.assignmentTypesReset,
    required this.docsDeleted,
    required this.errors,
    required this.warnings,
    required this.writesPerformed,
    required this.scope,
  });

  final bool refused;
  final String? refusalReason;
  final String currentUserIdMasked;
  final List<String> assignmentTypesReset;
  final int docsDeleted;
  final List<String> errors;
  final List<String> warnings;
  final bool writesPerformed;
  final String scope;

  Map<String, Object?> toJson() => {
        'refused': refused,
        'refusalReason': refusalReason,
        'currentUserIdMasked': currentUserIdMasked,
        'assignmentTypesReset': assignmentTypesReset,
        'docsDeleted': docsDeleted,
        'errors': errors,
        'warnings': warnings,
        'writesPerformed': writesPerformed,
        'scope': scope,
      };
}

/// Debug-only tools to reset the signed-in user's assessment assignments.
///
/// Deletes only `users/{uid}/assessment_assignments/{type}` documents.
/// Never touches global `assessment_sets`, legacy `questions`, or other users.
class AssessmentAssignmentResetHelper {
  AssessmentAssignmentResetHelper._();

  static const _allTypes = ['iq', 'eq', 'frequency'];

  static const _userAssessmentFieldsToDelete = [
    'test_completed',
    'frequency_completed',
    'iq_score',
    'eq_score',
    'iq_normalized',
    'eq_normalized',
    'archetype',
    'category',
    'frequency_type',
    'frequency_score',
    'frequency_tags',
    'frequency_language_used',
    'test_completed_at',
    'iq_completed_at',
    'eq_completed_at',
    'frequency_completed_at',
    'assessment_completed_at',
  ];

  static const _userFieldsPreservedNote =
      'Preserved: name, age, gender, bio/about, interests, photos, preferences, '
      'visibility, location, phone, created_at, profile_completed, auth fields, '
      'and other non-assessment profile data.';

  static const _relatedCachesNotCleared = [
    'users/{uid}.test_completed',
    'users/{uid}.frequency_completed',
    'users/{uid}.iq_score / eq_score / archetype / category',
    'users/{uid}.frequency_type / frequency_score / frequency_tags',
    'users/{uid}/assessments/frequency',
  ];

  static Future<AssessmentAssignmentResetReport> resetIqAssignment() =>
      _reset(types: const ['iq']);

  static Future<AssessmentAssignmentResetReport> resetEqAssignment() =>
      _reset(types: const ['eq']);

  static Future<AssessmentAssignmentResetReport> resetFrequencyAssignment() =>
      _reset(types: const ['frequency']);

  static Future<AssessmentAssignmentResetReport> resetAllAssignments() =>
      _reset(types: _allTypes);

  /// Clears assignments, frequency result doc, and assessment fields on the user doc.
  static Future<AssessmentFullStateResetReport>
      resetCurrentUserFullAssessmentState() async {
    if (!kDebugMode) {
      return const AssessmentFullStateResetReport(
        refused: true,
        refusalReason:
            'Full assessment state reset is available only in debug builds.',
        currentUserIdMasked: '',
        assignmentDocsDeleted: 0,
        resultDocsDeleted: 0,
        userFieldsDeleted: [],
        userFieldsPreservedNote: _userFieldsPreservedNote,
        errors: [],
        warnings: [],
        writesPerformed: false,
        globalContentTouched: false,
        scope: 'current_user_only',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AssessmentFullStateResetReport(
        refused: true,
        refusalReason: 'No signed-in user.',
        currentUserIdMasked: '',
        assignmentDocsDeleted: 0,
        resultDocsDeleted: 0,
        userFieldsDeleted: [],
        userFieldsPreservedNote: _userFieldsPreservedNote,
        errors: [],
        warnings: [],
        writesPerformed: false,
        globalContentTouched: false,
        scope: 'current_user_only',
      );
    }

    final masked = _maskUserId(user.uid);
    final errors = <String>[];
    final warnings = <String>[
      'discover_eligible was not cleared; it may remain true until profile '
      'eligibility is refreshed after retesting.',
    ];
    var assignmentDocsDeleted = 0;
    var resultDocsDeleted = 0;
    var writesPerformed = false;

    for (final type in _allTypes) {
      try {
        final ref = FirestorePaths.userAssessmentAssignmentDoc(user.uid, type);
        final snap = await ref.get();
        if (!snap.exists) continue;
        await ref.delete();
        assignmentDocsDeleted++;
        writesPerformed = true;
      } catch (e) {
        errors.add('Failed to delete assignment for type=$type: $e');
      }
    }

    try {
      final freqResultRef = FirestorePaths.userDoc(user.uid)
          .collection('assessments')
          .doc('frequency');
      final freqSnap = await freqResultRef.get();
      if (freqSnap.exists) {
        await freqResultRef.delete();
        resultDocsDeleted++;
        writesPerformed = true;
      }
    } catch (e) {
      errors.add('Failed to delete users/{uid}/assessments/frequency: $e');
    }

    final deletedFields = <String>[];
    try {
      final userRef = FirestorePaths.userDoc(user.uid);
      final userSnap = await userRef.get();
      if (!userSnap.exists) {
        warnings.add('User document does not exist; skipped user-field cleanup.');
      } else {
        final data = userSnap.data() ?? {};
        final updates = <String, dynamic>{};
        for (final field in _userAssessmentFieldsToDelete) {
          if (data.containsKey(field)) {
            updates[field] = FieldValue.delete();
            deletedFields.add(field);
          }
        }
        if (updates.isNotEmpty) {
          await userRef.update(updates);
          writesPerformed = true;
        } else {
          warnings.add('No assessment fields found on user doc to delete.');
        }
      }
    } catch (e) {
      errors.add('Failed to clear assessment fields on user doc: $e');
    }

    return AssessmentFullStateResetReport(
      refused: false,
      currentUserIdMasked: masked,
      assignmentDocsDeleted: assignmentDocsDeleted,
      resultDocsDeleted: resultDocsDeleted,
      userFieldsDeleted: deletedFields,
      userFieldsPreservedNote: _userFieldsPreservedNote,
      errors: errors,
      warnings: warnings,
      writesPerformed: writesPerformed,
      globalContentTouched: false,
      scope: 'current_user_only',
    );
  }

  static Future<AssessmentAssignmentResetReport> _reset({
    required List<String> types,
  }) async {
    if (!kDebugMode) {
      return const AssessmentAssignmentResetReport(
        refused: true,
        refusalReason: 'Assignment reset is available only in debug builds.',
        currentUserIdMasked: '',
        assignmentTypesReset: [],
        docsDeleted: 0,
        errors: [],
        warnings: [],
        writesPerformed: false,
        scope: 'current_user_only',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AssessmentAssignmentResetReport(
        refused: true,
        refusalReason: 'No signed-in user.',
        currentUserIdMasked: '',
        assignmentTypesReset: [],
        docsDeleted: 0,
        errors: [],
        warnings: [],
        writesPerformed: false,
        scope: 'current_user_only',
      );
    }

    final masked = _maskUserId(user.uid);
    final errors = <String>[];
    final warnings = <String>[
      'Related result caches were not cleared. Assignment reset alone may not '
      're-open IQ/EQ/Frequency intro flows if completion flags remain on the user doc.',
      'Not cleared: ${_relatedCachesNotCleared.join('; ')}',
    ];
    final resetTypes = <String>[];
    var docsDeleted = 0;

    for (final type in types) {
      try {
        final ref = FirestorePaths.userAssessmentAssignmentDoc(user.uid, type);
        final snap = await ref.get();
        if (!snap.exists) {
          warnings.add('No assignment doc to delete for type=$type');
          continue;
        }
        await ref.delete();
        resetTypes.add(type);
        docsDeleted++;
      } catch (e) {
        errors.add('Failed to delete assignment for type=$type: $e');
      }
    }

    return AssessmentAssignmentResetReport(
      refused: false,
      currentUserIdMasked: masked,
      assignmentTypesReset: resetTypes,
      docsDeleted: docsDeleted,
      errors: errors,
      warnings: warnings,
      writesPerformed: docsDeleted > 0,
      scope: 'current_user_only',
    );
  }

  static String _maskUserId(String uid) {
    final trimmed = uid.trim();
    if (trimmed.length <= 10) return '***';
    return '${trimmed.substring(0, 4)}…${trimmed.substring(trimmed.length - 4)}';
  }
}
