import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Localization classification for one Firestore (or asset) assessment set.
enum AssessmentSetLocalizationKind {
  localized,
  englishOnly,
  partiallyLocalized,
  empty,
}

/// Read-only preflight comparison of bundled assets vs Firestore `assessment_sets`.
class AssessmentSetsPreflightReport {
  const AssessmentSetsPreflightReport({
    required this.refused,
    required this.refusalReason,
    required this.localDocCount,
    required this.firestoreDocCount,
    required this.expectedDocCount,
    required this.localIqCount,
    required this.localEqCount,
    required this.localFrequencyCount,
    required this.firestoreIqCount,
    required this.firestoreEqCount,
    required this.firestoreFrequencyCount,
    required this.missingInFirestore,
    required this.extraInFirestore,
    required this.matchingIds,
    required this.firestoreEnglishOnlyCount,
    required this.firestoreLocalizedCount,
    required this.firestorePartiallyLocalizedCount,
    required this.firestoreQuestionCountTotal,
    required this.localQuestionCountTotal,
    required this.localFullyLocalized,
    required this.docsWithQuestionCountMismatch,
    required this.docsWithTypeMismatch,
    required this.docsWithSetNumberMismatch,
    required this.docsWithInvalidCorrectAnswer,
    required this.errors,
    required this.recommendation,
    required this.firestoreReadsPerformed,
    required this.firestoreWritesPerformed,
  });

  final bool refused;
  final String? refusalReason;
  final int localDocCount;
  final int firestoreDocCount;
  final int expectedDocCount;
  final int localIqCount;
  final int localEqCount;
  final int localFrequencyCount;
  final int firestoreIqCount;
  final int firestoreEqCount;
  final int firestoreFrequencyCount;
  final List<String> missingInFirestore;
  final List<String> extraInFirestore;
  final List<String> matchingIds;
  final int firestoreEnglishOnlyCount;
  final int firestoreLocalizedCount;
  final int firestorePartiallyLocalizedCount;
  final int firestoreQuestionCountTotal;
  final int localQuestionCountTotal;
  final bool localFullyLocalized;
  final List<String> docsWithQuestionCountMismatch;
  final List<String> docsWithTypeMismatch;
  final List<String> docsWithSetNumberMismatch;
  final List<String> docsWithInvalidCorrectAnswer;
  final List<String> errors;
  final String recommendation;
  final bool firestoreReadsPerformed;
  final bool firestoreWritesPerformed;

  Map<String, Object?> toJson() => {
        'refused': refused,
        'refusalReason': refusalReason,
        'localDocCount': localDocCount,
        'firestoreDocCount': firestoreDocCount,
        'expectedDocCount': expectedDocCount,
        'localIqCount': localIqCount,
        'localEqCount': localEqCount,
        'localFrequencyCount': localFrequencyCount,
        'firestoreIqCount': firestoreIqCount,
        'firestoreEqCount': firestoreEqCount,
        'firestoreFrequencyCount': firestoreFrequencyCount,
        'missingInFirestore': missingInFirestore,
        'extraInFirestore': extraInFirestore,
        'matchingIds': matchingIds,
        'firestoreEnglishOnlyCount': firestoreEnglishOnlyCount,
        'firestoreLocalizedCount': firestoreLocalizedCount,
        'firestorePartiallyLocalizedCount': firestorePartiallyLocalizedCount,
        'firestoreQuestionCountTotal': firestoreQuestionCountTotal,
        'localQuestionCountTotal': localQuestionCountTotal,
        'localFullyLocalized': localFullyLocalized,
        'docsWithQuestionCountMismatch': docsWithQuestionCountMismatch,
        'docsWithTypeMismatch': docsWithTypeMismatch,
        'docsWithSetNumberMismatch': docsWithSetNumberMismatch,
        'docsWithInvalidCorrectAnswer': docsWithInvalidCorrectAnswer,
        'errors': errors,
        'recommendation': recommendation,
        'firestoreReadsPerformed': firestoreReadsPerformed,
        'firestoreWritesPerformed': firestoreWritesPerformed,
      };

  @override
  String toString() =>
      'AssessmentSetsPreflightReport(${json.encode(toJson())})';
}

/// Debug-only, **read-only** comparison of local assessment assets vs Firestore.
///
/// Never calls Firestore set/update/delete/add/writeBatch or write transactions.
/// Actual sync/upload must remain a separate explicitly approved phase.
class AssessmentSetsPreflightHelper {
  AssessmentSetsPreflightHelper._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int expectedDocCount = 150;

  static const List<_AssetBundleSpec> _bundles = [
    _AssetBundleSpec(
      assetPath: 'assets/data/assessment_sets/iq_sets.json',
      type: 'iq',
    ),
    _AssetBundleSpec(
      assetPath: 'assets/data/assessment_sets/eq_sets.json',
      type: 'eq',
    ),
    _AssetBundleSpec(
      assetPath: 'assets/data/assessment_sets/frequency_sets.json',
      type: 'frequency',
    ),
  ];

  /// Compares bundled assessment JSON assets with Firestore `assessment_sets`.
  ///
  /// Reads only. Refuses outside [kDebugMode].
  static Future<AssessmentSetsPreflightReport> compareBundledAssetsWithFirestore() async {
    if (!kDebugMode) {
      final refused = AssessmentSetsPreflightReport(
        refused: true,
        refusalReason:
            'Assessment Firestore preflight refused: debug gate not satisfied',
        localDocCount: 0,
        firestoreDocCount: 0,
        expectedDocCount: expectedDocCount,
        localIqCount: 0,
        localEqCount: 0,
        localFrequencyCount: 0,
        firestoreIqCount: 0,
        firestoreEqCount: 0,
        firestoreFrequencyCount: 0,
        missingInFirestore: const [],
        extraInFirestore: const [],
        matchingIds: const [],
        firestoreEnglishOnlyCount: 0,
        firestoreLocalizedCount: 0,
        firestorePartiallyLocalizedCount: 0,
        firestoreQuestionCountTotal: 0,
        localQuestionCountTotal: 0,
        localFullyLocalized: false,
        docsWithQuestionCountMismatch: const [],
        docsWithTypeMismatch: const [],
        docsWithSetNumberMismatch: const [],
        docsWithInvalidCorrectAnswer: const [],
        errors: const [],
        recommendation:
            'Preflight is debug-only. Re-run in a debug build. '
            'This preflight performed READS ONLY — no Firestore writes.',
        firestoreReadsPerformed: false,
        firestoreWritesPerformed: false,
      );
      debugPrint(
        '⛔ Assessment Firestore preflight refused: debug gate not satisfied',
      );
      _logReport(refused);
      return refused;
    }

    final errors = <String>[];
    final localById = <String, _SetSnapshot>{};

    for (final bundle in _bundles) {
      try {
        final raw = await rootBundle.loadString(bundle.assetPath);
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final sets = (decoded['sets'] as List<dynamic>?) ?? const [];
        for (final item in sets) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = (map['id'] as String?)?.trim() ?? '';
          if (id.isEmpty) {
            errors.add('${bundle.type}: skipped local set with missing id');
            continue;
          }
          localById[id] = _SetSnapshot.fromMap(id: id, data: map, fallbackType: bundle.type);
        }
      } catch (e) {
        errors.add('${bundle.assetPath}: $e');
      }
    }

    final firestoreById = <String, _SetSnapshot>{};
    var firestoreReadsPerformed = false;
    try {
      // Read-only: QuerySnapshot get — no set/update/delete/batch/write.
      final snap = await _firestore.collection('assessment_sets').get();
      firestoreReadsPerformed = true;
      for (final doc in snap.docs) {
        final data = doc.data();
        final idFromField = (data['id'] as String?)?.trim();
        final id = (idFromField != null && idFromField.isNotEmpty)
            ? idFromField
            : doc.id;
        firestoreById[id] = _SetSnapshot.fromMap(
          id: id,
          data: data,
          fallbackType: (data['type'] as String?) ?? '',
        );
      }
    } catch (e) {
      errors.add('Firestore read assessment_sets failed: $e');
    }

    final localIds = localById.keys.toSet();
    final firestoreIds = firestoreById.keys.toSet();
    final missing = (localIds.difference(firestoreIds).toList()..sort());
    final extra = (firestoreIds.difference(localIds).toList()..sort());
    final matching = (localIds.intersection(firestoreIds).toList()..sort());

    var localIq = 0;
    var localEq = 0;
    var localFq = 0;
    var localQuestions = 0;
    var localLocalizedSets = 0;
    for (final s in localById.values) {
      localQuestions += s.questionCount;
      switch (s.type) {
        case 'iq':
          localIq++;
        case 'eq':
          localEq++;
        case 'frequency':
          localFq++;
      }
      if (s.localization == AssessmentSetLocalizationKind.localized) {
        localLocalizedSets++;
      }
    }
    final localFullyLocalized =
        localById.isNotEmpty && localLocalizedSets == localById.length;

    var fsIq = 0;
    var fsEq = 0;
    var fsFq = 0;
    var fsQuestions = 0;
    var fsLocalized = 0;
    var fsEnglishOnly = 0;
    var fsPartial = 0;
    for (final s in firestoreById.values) {
      fsQuestions += s.questionCount;
      switch (s.type) {
        case 'iq':
          fsIq++;
        case 'eq':
          fsEq++;
        case 'frequency':
          fsFq++;
      }
      switch (s.localization) {
        case AssessmentSetLocalizationKind.localized:
          fsLocalized++;
        case AssessmentSetLocalizationKind.englishOnly:
          fsEnglishOnly++;
        case AssessmentSetLocalizationKind.partiallyLocalized:
        case AssessmentSetLocalizationKind.empty:
          fsPartial++;
      }
    }

    final qCountMismatch = <String>[];
    final typeMismatch = <String>[];
    final setNumberMismatch = <String>[];
    final invalidCorrectAnswer = <String>[];

    for (final id in matching) {
      final local = localById[id]!;
      final remote = firestoreById[id]!;
      if (local.questionCount != remote.questionCount ||
          remote.declaredQuestionCount != remote.questionCount) {
        qCountMismatch.add(id);
      }
      if (local.type.isNotEmpty &&
          remote.type.isNotEmpty &&
          local.type != remote.type) {
        typeMismatch.add(id);
      }
      if (local.setNumber != 0 &&
          remote.setNumber != 0 &&
          local.setNumber != remote.setNumber) {
        setNumberMismatch.add(id);
      }
      if (remote.hasInvalidCorrectAnswer || local.hasInvalidCorrectAnswer) {
        invalidCorrectAnswer.add(id);
      }
    }

    // Also flag Firestore-only docs with invalid correctAnswer.
    for (final id in extra) {
      if (firestoreById[id]!.hasInvalidCorrectAnswer) {
        invalidCorrectAnswer.add(id);
      }
    }

    final recommendation = _buildRecommendation(
      localFullyLocalized: localFullyLocalized,
      firestoreDocCount: firestoreById.length,
      missingCount: missing.length,
      extraCount: extra.length,
      fsLocalized: fsLocalized,
      fsEnglishOnly: fsEnglishOnly,
      fsPartial: fsPartial,
      mismatchCount: qCountMismatch.length +
          typeMismatch.length +
          setNumberMismatch.length +
          invalidCorrectAnswer.length,
      hadReadErrors: errors.isNotEmpty && !firestoreReadsPerformed,
    );

    final report = AssessmentSetsPreflightReport(
      refused: false,
      refusalReason: null,
      localDocCount: localById.length,
      firestoreDocCount: firestoreById.length,
      expectedDocCount: expectedDocCount,
      localIqCount: localIq,
      localEqCount: localEq,
      localFrequencyCount: localFq,
      firestoreIqCount: fsIq,
      firestoreEqCount: fsEq,
      firestoreFrequencyCount: fsFq,
      missingInFirestore: List.unmodifiable(missing),
      extraInFirestore: List.unmodifiable(extra),
      matchingIds: List.unmodifiable(matching),
      firestoreEnglishOnlyCount: fsEnglishOnly,
      firestoreLocalizedCount: fsLocalized,
      firestorePartiallyLocalizedCount: fsPartial,
      firestoreQuestionCountTotal: fsQuestions,
      localQuestionCountTotal: localQuestions,
      localFullyLocalized: localFullyLocalized,
      docsWithQuestionCountMismatch: List.unmodifiable(qCountMismatch..sort()),
      docsWithTypeMismatch: List.unmodifiable(typeMismatch..sort()),
      docsWithSetNumberMismatch: List.unmodifiable(setNumberMismatch..sort()),
      docsWithInvalidCorrectAnswer:
          List.unmodifiable(invalidCorrectAnswer..sort()),
      errors: List.unmodifiable(errors),
      recommendation: recommendation,
      firestoreReadsPerformed: firestoreReadsPerformed,
      firestoreWritesPerformed: false,
    );

    _logReport(report);
    return report;
  }

  static String _buildRecommendation({
    required bool localFullyLocalized,
    required int firestoreDocCount,
    required int missingCount,
    required int extraCount,
    required int fsLocalized,
    required int fsEnglishOnly,
    required int fsPartial,
    required int mismatchCount,
    required bool hadReadErrors,
  }) {
    if (hadReadErrors) {
      return 'Could not complete Firestore read. Fix credentials/rules for '
          'debug reads, then re-run preflight. '
          'This preflight performed READS ONLY — no Firestore writes.';
    }

    final inSync = firestoreDocCount == expectedDocCount &&
        missingCount == 0 &&
        extraCount == 0 &&
        mismatchCount == 0 &&
        fsLocalized == firestoreDocCount &&
        localFullyLocalized;

    if (inSync) {
      return 'Firestore already matches localized assets; no sync needed. '
          'This preflight performed READS ONLY — no Firestore writes.';
    }

    if (fsEnglishOnly > 0 || fsPartial > 0 || missingCount > 0) {
      return 'Firestore is English-only, partial, or missing sets versus '
          'localized assets. Run an approved sync phase later (after backup). '
          'This preflight performed READS ONLY — no Firestore writes.';
    }

    return 'Differences remain between assets and Firestore; review the '
        'report before any approved sync phase. '
        'This preflight performed READS ONLY — no Firestore writes.';
  }

  static void _logReport(AssessmentSetsPreflightReport report) {
    debugPrint('================================================================');
    debugPrint('Assessment Firestore Preflight Compare');
    debugPrint('================================================================');
    if (report.refused) {
      debugPrint('REFUSED: ${report.refusalReason}');
    }
    debugPrint('Local assets:');
    debugPrint('- Docs: ${report.localDocCount}');
    debugPrint(
      '- IQ/EQ/Frequency: ${report.localIqCount}/${report.localEqCount}/${report.localFrequencyCount}',
    );
    debugPrint('- Questions: ${report.localQuestionCountTotal}');
    debugPrint(
      '- Fully localized: ${report.localFullyLocalized ? 'yes' : 'no'}',
    );
    debugPrint('Firestore:');
    debugPrint('- Docs: ${report.firestoreDocCount}');
    debugPrint(
      '- IQ/EQ/Frequency: ${report.firestoreIqCount}/${report.firestoreEqCount}/${report.firestoreFrequencyCount}',
    );
    debugPrint('- Questions: ${report.firestoreQuestionCountTotal}');
    debugPrint('- Fully localized docs: ${report.firestoreLocalizedCount}');
    debugPrint('- English-only docs: ${report.firestoreEnglishOnlyCount}');
    debugPrint(
      '- Partially localized docs: ${report.firestorePartiallyLocalizedCount}',
    );
    debugPrint('Differences:');
    debugPrint(
      '- Missing in Firestore: ${_summarizeIds(report.missingInFirestore)}',
    );
    debugPrint(
      '- Extra in Firestore: ${_summarizeIds(report.extraInFirestore)}',
    );
    debugPrint(
      '- Question count mismatches: ${_summarizeIds(report.docsWithQuestionCountMismatch)}',
    );
    debugPrint(
      '- Type mismatches: ${_summarizeIds(report.docsWithTypeMismatch)}',
    );
    debugPrint(
      '- Set number mismatches: ${_summarizeIds(report.docsWithSetNumberMismatch)}',
    );
    debugPrint(
      '- Invalid correctAnswer: ${_summarizeIds(report.docsWithInvalidCorrectAnswer)}',
    );
    for (final e in report.errors) {
      debugPrint('❌ $e');
    }
    debugPrint('Recommendation:');
    debugPrint('- ${report.recommendation}');
    debugPrint('firestoreReadsPerformed: ${report.firestoreReadsPerformed}');
    debugPrint('firestoreWritesPerformed: ${report.firestoreWritesPerformed}');
    debugPrint('This preflight performed READS ONLY — no Firestore writes.');
    debugPrint('================================================================');
  }

  static String _summarizeIds(List<String> ids) {
    if (ids.isEmpty) return 'none';
    if (ids.length <= 8) return '${ids.join(', ')} (${ids.length})';
    return '${ids.take(4).join(', ')} … ${ids.sublist(ids.length - 2).join(', ')} '
        '(${ids.length})';
  }
}

class _AssetBundleSpec {
  const _AssetBundleSpec({
    required this.assetPath,
    required this.type,
  });

  final String assetPath;
  final String type;
}

class _SetSnapshot {
  const _SetSnapshot({
    required this.id,
    required this.type,
    required this.setNumber,
    required this.questionCount,
    required this.declaredQuestionCount,
    required this.localization,
    required this.hasInvalidCorrectAnswer,
  });

  final String id;
  final String type;
  final int setNumber;
  final int questionCount;
  final int declaredQuestionCount;
  final AssessmentSetLocalizationKind localization;
  final bool hasInvalidCorrectAnswer;

  factory _SetSnapshot.fromMap({
    required String id,
    required Map<String, dynamic> data,
    required String fallbackType,
  }) {
    final type = ((data['type'] as String?)?.trim().isNotEmpty == true)
        ? (data['type'] as String).trim()
        : fallbackType;
    final questions = (data['questions'] as List<dynamic>?) ?? const [];
    final declared = (data['question_count'] as num?)?.toInt() ?? questions.length;
    return _SetSnapshot(
      id: id,
      type: type,
      setNumber: (data['set_number'] as num?)?.toInt() ?? 0,
      questionCount: questions.length,
      declaredQuestionCount: declared,
      localization: _classifyLocalization(questions, type),
      hasInvalidCorrectAnswer: _hasInvalidCorrectAnswer(questions, type),
    );
  }

  static AssessmentSetLocalizationKind _classifyLocalization(
    List<dynamic> questions,
    String type,
  ) {
    if (questions.isEmpty) return AssessmentSetLocalizationKind.empty;

    var localized = 0;
    var englishOnly = 0;

    for (final raw in questions) {
      if (raw is! Map) {
        return AssessmentSetLocalizationKind.partiallyLocalized;
      }
      switch (_classifyQuestion(raw, type)) {
        case AssessmentSetLocalizationKind.localized:
          localized++;
        case AssessmentSetLocalizationKind.englishOnly:
          englishOnly++;
        case AssessmentSetLocalizationKind.partiallyLocalized:
        case AssessmentSetLocalizationKind.empty:
          return AssessmentSetLocalizationKind.partiallyLocalized;
      }
    }

    if (localized == questions.length) {
      return AssessmentSetLocalizationKind.localized;
    }
    if (englishOnly == questions.length) {
      return AssessmentSetLocalizationKind.englishOnly;
    }
    return AssessmentSetLocalizationKind.partiallyLocalized;
  }

  static AssessmentSetLocalizationKind _classifyQuestion(
    Map<dynamic, dynamic> question,
    String type,
  ) {
    final qStatus = _classifyText(question['question']);
    if (type == 'frequency') {
      return qStatus;
    }

    final options = question['options'];
    if (options is! List || options.isEmpty) {
      return AssessmentSetLocalizationKind.partiallyLocalized;
    }

    var optLocalized = 0;
    var optEnglish = 0;
    for (final opt in options) {
      if (opt is! Map) {
        return AssessmentSetLocalizationKind.partiallyLocalized;
      }
      // Support both `{label:{en,tr}}` and legacy string / map-as-label shapes.
      final label = opt.containsKey('label') ? opt['label'] : opt;
      switch (_classifyText(label)) {
        case AssessmentSetLocalizationKind.localized:
          optLocalized++;
        case AssessmentSetLocalizationKind.englishOnly:
          optEnglish++;
        case AssessmentSetLocalizationKind.partiallyLocalized:
        case AssessmentSetLocalizationKind.empty:
          return AssessmentSetLocalizationKind.partiallyLocalized;
      }
    }

    if (qStatus == AssessmentSetLocalizationKind.localized &&
        optLocalized == options.length) {
      return AssessmentSetLocalizationKind.localized;
    }
    if (qStatus == AssessmentSetLocalizationKind.englishOnly &&
        optEnglish == options.length) {
      return AssessmentSetLocalizationKind.englishOnly;
    }
    return AssessmentSetLocalizationKind.partiallyLocalized;
  }

  static AssessmentSetLocalizationKind _classifyText(Object? value) {
    if (value == null) return AssessmentSetLocalizationKind.empty;
    if (value is String) {
      return value.trim().isEmpty
          ? AssessmentSetLocalizationKind.empty
          : AssessmentSetLocalizationKind.englishOnly;
    }
    if (value is Map) {
      final en = value['en'];
      final tr = value['tr'];
      final enOk = en is String && en.trim().isNotEmpty;
      final trOk = tr is String && tr.trim().isNotEmpty;
      if (enOk && trOk) return AssessmentSetLocalizationKind.localized;
      if (enOk && !trOk) return AssessmentSetLocalizationKind.englishOnly;
      if (!enOk && trOk) {
        return AssessmentSetLocalizationKind.partiallyLocalized;
      }
      return AssessmentSetLocalizationKind.empty;
    }
    return AssessmentSetLocalizationKind.partiallyLocalized;
  }

  static bool _hasInvalidCorrectAnswer(List<dynamic> questions, String type) {
    if (type == 'frequency') return false;
    for (final raw in questions) {
      if (raw is! Map) continue;
      final options = raw['options'];
      if (options is! List || options.isEmpty) continue;
      final ca = raw['correctAnswer'];
      if (ca == null) continue;
      final index = ca is int
          ? ca
          : ca is num
              ? ca.toInt()
              : int.tryParse(ca.toString());
      if (index == null || index < 0 || index >= options.length) {
        return true;
      }
    }
    return false;
  }
}
