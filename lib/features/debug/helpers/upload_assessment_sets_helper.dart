import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of a dry-run or (gated) write sync of assessment sets.
class AssessmentFirestoreSyncReport {
  const AssessmentFirestoreSyncReport({
    required this.mode,
    required this.source,
    required this.writeEnabledFlag,
    required this.debugMode,
    required this.confirmationAccepted,
    required this.docsConsidered,
    required this.docsWritten,
    required this.docsSkipped,
    required this.iqDocs,
    required this.eqDocs,
    required this.frequencyDocs,
    required this.totalQuestions,
    required this.versionedIdCount,
    required this.legacyIdCount,
    required this.contentVersion,
    required this.status,
    required this.active,
    required this.languageMode,
    required this.targetCollection,
    required this.fullyLocalizedSets,
    required this.fullyLocalizedQuestions,
    required this.firestoreWritesPerformed,
    required this.refused,
    required this.refusalReasons,
    required this.errors,
    required this.warnings,
    required this.documentIds,
  });

  /// `dryRun` or `write`.
  final String mode;

  /// e.g. `bundled_assets_converted_to_v2` or `bundled_assets_legacy`.
  final String source;
  final bool writeEnabledFlag;
  final bool debugMode;
  final bool confirmationAccepted;
  final int docsConsidered;
  final int docsWritten;
  final int docsSkipped;
  final int iqDocs;
  final int eqDocs;
  final int frequencyDocs;
  final int totalQuestions;
  final int versionedIdCount;
  final int legacyIdCount;
  final int contentVersion;
  final String status;
  final bool active;
  final String languageMode;
  final String targetCollection;
  final int fullyLocalizedSets;
  final int fullyLocalizedQuestions;
  final bool firestoreWritesPerformed;
  final bool refused;
  final List<String> refusalReasons;
  final List<String> errors;
  final List<String> warnings;
  final List<String> documentIds;

  Map<String, Object?> toJson() => {
        'mode': mode,
        'source': source,
        'writeEnabledFlag': writeEnabledFlag,
        'kDebugMode': debugMode,
        'confirmationAccepted': confirmationAccepted,
        'docsConsidered': docsConsidered,
        'docsWritten': docsWritten,
        'docsSkipped': docsSkipped,
        'iqCount': iqDocs,
        'eqCount': eqDocs,
        'frequencyCount': frequencyDocs,
        'questionCount': totalQuestions,
        'versionedIdCount': versionedIdCount,
        'legacyIdCount': legacyIdCount,
        'version': contentVersion,
        'status': status,
        'active': active,
        'language_mode': languageMode,
        'targetCollection': targetCollection,
        'fullyLocalizedSets': fullyLocalizedSets,
        'fullyLocalizedQuestions': fullyLocalizedQuestions,
        'firestoreWritesPerformed': firestoreWritesPerformed,
        'writesPerformed': firestoreWritesPerformed,
        'refused': refused,
        'refusalReasons': refusalReasons,
        'errors': errors,
        'warnings': warnings,
        'documentIds': documentIds,
      };

  @override
  String toString() =>
      'AssessmentFirestoreSyncReport(${json.encode(toJson())})';
}

/// Debug/admin helper: syncs assessment sets into Firestore.
///
/// **Preferred path:** [syncAssessmentSetsVersionedV2] — converts bundled
/// legacy assets to immutable `*_v2` docs in memory (same rules as
/// `scripts/export_assessment_sets_v2.py`). Does **not** read `build/`.
///
/// Default mode is **dry-run** (no Firestore writes). Real writes require:
/// 1. [kDebugMode] == true (release/profile never write)
/// 2. `--dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true`
/// 3. `dryRun: false`
/// 4. `confirmationPhrase` exactly [requiredConfirmationPhrase]
///
/// Legacy in-place sync of `iq_set_001` IDs is **not** recommended and cannot
/// write. Actual production sync must be a separate explicitly approved phase.
class UploadAssessmentSetsHelper {
  UploadAssessmentSetsHelper._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Exact phrase required for write mode.
  static const String requiredConfirmationPhrase =
      'SYNC_LOCALIZED_ASSESSMENT_SETS';

  /// Compile-time gate. Default false — must be enabled via dart-define.
  static const bool syncEnabledFromEnvironment = bool.fromEnvironment(
    'QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC',
    defaultValue: false,
  );

  static const int v2Version = 2;
  static const String v2Status = 'published';
  static const String v2LanguageMode = 'localized';
  static const String targetCollection = 'assessment_sets';

  static const List<_AssetBundleSpec> _bundles = [
    _AssetBundleSpec(
      assetPath: 'assets/data/assessment_sets/iq_sets.json',
      type: 'iq',
      expectedSets: 50,
      expectedQuestions: 500,
    ),
    _AssetBundleSpec(
      assetPath: 'assets/data/assessment_sets/eq_sets.json',
      type: 'eq',
      expectedSets: 50,
      expectedQuestions: 500,
    ),
    _AssetBundleSpec(
      assetPath: 'assets/data/assessment_sets/frequency_sets.json',
      type: 'frequency',
      expectedSets: 50,
      expectedQuestions: 600,
    ),
  ];

  /// Preferred API: convert bundled legacy assets → versioned v2, then dry-run
  /// (default) or gated write to `assessment_sets/{id}_v2`.
  ///
  /// Does not archive/delete v1 docs. Does not write user assignments.
  static Future<AssessmentFirestoreSyncReport> syncAssessmentSetsVersionedV2({
    bool dryRun = true,
    String confirmationPhrase = '',
  }) {
    return _sync(
      dryRun: dryRun,
      confirmationPhrase: confirmationPhrase,
      convertToV2: true,
    );
  }

  /// Convenience alias — always dry-run for versioned v2.
  static Future<AssessmentFirestoreSyncReport> dryRunVersionedV2AssessmentSync() {
    return syncAssessmentSetsVersionedV2(dryRun: true);
  }

  /// Legacy-ID path. Always dry-run; **cannot write** legacy IDs.
  ///
  /// Prefer [syncAssessmentSetsVersionedV2].
  @Deprecated(
    'Prefer syncAssessmentSetsVersionedV2. Legacy in-place sync cannot write.',
  )
  static Future<AssessmentFirestoreSyncReport> syncBundledAssessmentSets({
    bool dryRun = true,
    String confirmationPhrase = '',
  }) async {
    final warnings = <String>[
      'Legacy sync path is not recommended. Prefer '
          'syncAssessmentSetsVersionedV2 (immutable *_v2 docs).',
    ];
    if (!dryRun) {
      warnings.add(
        'Legacy write refused: will not overwrite v1 IDs like iq_set_001. '
        'Use syncAssessmentSetsVersionedV2 for publishing.',
      );
      debugPrint(
        '⛔ Legacy Firestore sync refused: in-place v1 overwrite is disabled. '
        'Use syncAssessmentSetsVersionedV2.',
      );
    }
    final report = await _sync(
      dryRun: true,
      confirmationPhrase: confirmationPhrase,
      convertToV2: false,
      forceRefuseWrite: !dryRun,
      extraWarnings: warnings,
    );
    return report;
  }

  /// Legacy entry point. Always dry-runs; does not write to Firestore.
  @Deprecated('Use dryRunVersionedV2AssessmentSync() or syncAssessmentSetsVersionedV2')
  static Future<int> uploadAllBundledSets() async {
    debugPrint(
      '⚠️ uploadAllBundledSets is deprecated and dry-run only. '
      'Use syncAssessmentSetsVersionedV2.',
    );
    final report = await dryRunVersionedV2AssessmentSync();
    return report.docsConsidered;
  }

  /// Legacy per-file entry. Always dry-runs; does not write to Firestore.
  @Deprecated('Use syncAssessmentSetsVersionedV2')
  static Future<int> uploadAssetFile(String assetPath) async {
    debugPrint(
      '⚠️ uploadAssetFile is deprecated and dry-run only for $assetPath. '
      'Use syncAssessmentSetsVersionedV2.',
    );
    final report = await dryRunVersionedV2AssessmentSync();
    final typeHint = assetPath.contains('iq')
        ? 'iq'
        : assetPath.contains('eq')
            ? 'eq'
            : assetPath.contains('frequency')
                ? 'frequency'
                : null;
    if (typeHint == 'iq') return report.iqDocs;
    if (typeHint == 'eq') return report.eqDocs;
    if (typeHint == 'frequency') return report.frequencyDocs;
    return report.docsConsidered;
  }

  /// Converts one legacy set map to immutable v2 (questions deep-copied).
  ///
  /// Same rules as `scripts/export_assessment_sets_v2.py`.
  static Map<String, dynamic> convertLegacySetToV2(
    Map<String, dynamic> source, {
    required String expectedType,
  }) {
    final rawId = (source['id'] as String?)?.trim() ?? '';
    if (rawId.isEmpty) {
      throw ArgumentError('set missing id');
    }
    if (!_isLegacySetId(rawId, expectedType)) {
      throw ArgumentError(
        'source set id must be legacy $expectedType id (got $rawId)',
      );
    }

    final questionsRaw = source['questions'];
    if (questionsRaw is! List) {
      throw ArgumentError('$rawId: questions must be a list');
    }
    // Deep copy via JSON round-trip — preserves order and nested maps.
    final questions = json.decode(json.encode(questionsRaw)) as List<dynamic>;

    final setNumber = _parseSetNumber(rawId) ??
        (source['set_number'] is num
            ? (source['set_number'] as num).toInt()
            : null);
    if (setNumber == null) {
      throw ArgumentError('$rawId: cannot determine set_number');
    }

    return {
      'id': '${rawId}_v$v2Version',
      'base_id': rawId,
      'type': expectedType,
      'set_number': setNumber,
      'version': v2Version,
      'active': true,
      'status': v2Status,
      'language_mode': v2LanguageMode,
      'question_count': questions.length,
      'questions': questions,
    };
  }

  static Future<AssessmentFirestoreSyncReport> _sync({
    required bool dryRun,
    required String confirmationPhrase,
    required bool convertToV2,
    bool forceRefuseWrite = false,
    List<String> extraWarnings = const [],
  }) async {
    final writeFlag = syncEnabledFromEnvironment;
    final debugMode = kDebugMode;
    final confirmationAccepted =
        confirmationPhrase == requiredConfirmationPhrase;
    final errors = <String>[];
    final warnings = <String>[...extraWarnings];
    final refusalReasons = <String>[];

    final wantWrite = !dryRun && !forceRefuseWrite;
    if (wantWrite) {
      if (!debugMode) {
        refusalReasons.add(
          'Firestore assessment sync refused: debug gate not satisfied',
        );
      }
      if (!writeFlag) {
        refusalReasons.add(
          'Firestore assessment sync refused: dart-define flag missing',
        );
      }
      if (!confirmationAccepted) {
        refusalReasons.add(
          'Firestore assessment sync refused: confirmation phrase mismatch',
        );
      }
    }

    final writesAllowed =
        wantWrite && refusalReasons.isEmpty && debugMode && writeFlag;
    final mode = writesAllowed ? 'write' : 'dryRun';

    for (final reason in refusalReasons) {
      debugPrint('⛔ $reason');
    }
    if ((wantWrite || forceRefuseWrite) && !writesAllowed) {
      if (!forceRefuseWrite) {
        warnings.add(
          'Write requested but gates not satisfied; continuing as dry-run.',
        );
        debugPrint(
          '⚠️ Write requested but gates not satisfied; continuing as dry-run.',
        );
      }
    }

    var docsConsidered = 0;
    var docsWritten = 0;
    var docsSkipped = 0;
    var iqDocs = 0;
    var eqDocs = 0;
    var frequencyDocs = 0;
    var totalQuestions = 0;
    var versionedIdCount = 0;
    var legacyIdCount = 0;
    var fullyLocalizedSets = 0;
    var fullyLocalizedQuestions = 0;
    final documentIds = <String>[];

    for (final bundle in _bundles) {
      try {
        final raw = await rootBundle.loadString(bundle.assetPath);
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final sets = (decoded['sets'] as List<dynamic>?) ?? const [];

        if (sets.length != bundle.expectedSets) {
          warnings.add(
            '${bundle.type}: expected ${bundle.expectedSets} sets, '
            'found ${sets.length}',
          );
        }

        var bundleQuestions = 0;
        for (final item in sets) {
          final legacyMap = Map<String, dynamic>.from(item as Map);
          Map<String, dynamic> map;
          try {
            map = convertToV2
                ? convertLegacySetToV2(
                    legacyMap,
                    expectedType: bundle.type,
                  )
                : legacyMap;
          } catch (e) {
            docsSkipped++;
            errors.add('${bundle.type}: convert failed: $e');
            continue;
          }

          final id = map['id'] as String?;
          if (id == null || id.isEmpty) {
            docsSkipped++;
            warnings.add('${bundle.type}: skipped set with missing id');
            continue;
          }

          final questions =
              (map['questions'] as List<dynamic>?) ?? const <dynamic>[];
          bundleQuestions += questions.length;
          totalQuestions += questions.length;

          final setLocalized = _isSetFullyLocalized(map, bundle.type);
          if (setLocalized) {
            fullyLocalizedSets++;
          } else {
            warnings.add('$id: not fully localized (en/tr)');
          }
          for (final q in questions) {
            if (q is Map && _isQuestionFullyLocalized(q, bundle.type)) {
              fullyLocalizedQuestions++;
            }
          }

          if (_looksVersionedId(id)) {
            versionedIdCount++;
          } else {
            legacyIdCount++;
          }

          docsConsidered++;
          documentIds.add(id);
          switch (bundle.type) {
            case 'iq':
              iqDocs++;
            case 'eq':
              eqDocs++;
            case 'frequency':
              frequencyDocs++;
          }

          if (writesAllowed) {
            // Write versioned v2 docs only. Never delete/archive v1.
            await _firestore.collection(targetCollection).doc(id).set(
                  {
                    ...map,
                    'created_at': FieldValue.serverTimestamp(),
                    'updated_at': FieldValue.serverTimestamp(),
                    'published_at': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );
            docsWritten++;
          }
        }

        if (bundleQuestions != bundle.expectedQuestions) {
          warnings.add(
            '${bundle.type}: expected ${bundle.expectedQuestions} questions, '
            'found $bundleQuestions',
          );
        }

        debugPrint(
          '📋 ${bundle.type}: ${sets.length} docs'
          '${writesAllowed ? ' (wrote)' : ' (dry-run)'} '
          '${convertToV2 ? 'as *_v$v2Version' : 'legacy IDs'} '
          'from ${bundle.assetPath}',
        );
      } catch (e) {
        errors.add('${bundle.assetPath}: $e');
        debugPrint('❌ Failed loading ${bundle.assetPath}: $e');
      }
    }

    final report = AssessmentFirestoreSyncReport(
      mode: mode,
      source: convertToV2
          ? 'bundled_assets_converted_to_v2'
          : 'bundled_assets_legacy',
      writeEnabledFlag: writeFlag,
      debugMode: debugMode,
      confirmationAccepted: confirmationAccepted,
      docsConsidered: docsConsidered,
      docsWritten: docsWritten,
      docsSkipped: docsSkipped,
      iqDocs: iqDocs,
      eqDocs: eqDocs,
      frequencyDocs: frequencyDocs,
      totalQuestions: totalQuestions,
      versionedIdCount: versionedIdCount,
      legacyIdCount: legacyIdCount,
      contentVersion: convertToV2 ? v2Version : 0,
      status: convertToV2 ? v2Status : '',
      active: convertToV2 ? true : false,
      languageMode: convertToV2 ? v2LanguageMode : '',
      targetCollection: targetCollection,
      fullyLocalizedSets: fullyLocalizedSets,
      fullyLocalizedQuestions: fullyLocalizedQuestions,
      firestoreWritesPerformed: writesAllowed && docsWritten > 0,
      refused: (wantWrite || forceRefuseWrite) && !writesAllowed,
      refusalReasons: List.unmodifiable(refusalReasons),
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
      documentIds: List.unmodifiable(documentIds),
    );

    _logReport(report, convertToV2: convertToV2);
    return report;
  }

  static void _logReport(
    AssessmentFirestoreSyncReport report, {
    required bool convertToV2,
  }) {
    debugPrint('================================================================');
    debugPrint(
      convertToV2
          ? 'Assessment Firestore Sync Report (versioned v2)'
          : 'Assessment Firestore Sync Report (legacy dry-run)',
    );
    debugPrint('================================================================');
    debugPrint('mode: ${report.mode}');
    debugPrint('source: ${report.source}');
    debugPrint(
      'QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC: ${report.writeEnabledFlag}',
    );
    debugPrint('kDebugMode: ${report.debugMode}');
    debugPrint('confirmationAccepted: ${report.confirmationAccepted}');
    debugPrint('docsConsidered: ${report.docsConsidered}');
    debugPrint(
      'docs that would be written / docsWritten: ${report.docsWritten}',
    );
    debugPrint('docsSkipped: ${report.docsSkipped}');
    debugPrint(
      'IQ/EQ/Frequency: ${report.iqDocs}/${report.eqDocs}/${report.frequencyDocs}',
    );
    debugPrint('questions: ${report.totalQuestions}');
    debugPrint('versionedIdCount: ${report.versionedIdCount}');
    debugPrint('legacyIdCount: ${report.legacyIdCount}');
    if (convertToV2) {
      debugPrint('version: ${report.contentVersion}');
      debugPrint('status: ${report.status}');
      debugPrint('active: ${report.active}');
      debugPrint('language_mode: ${report.languageMode}');
    }
    debugPrint('target collection: ${report.targetCollection}');
    debugPrint(
      'fullyLocalized: sets=${report.fullyLocalizedSets} '
      'questions=${report.fullyLocalizedQuestions}',
    );
    debugPrint(
      'firestoreWritesPerformed: ${report.firestoreWritesPerformed}',
    );
    if (report.documentIds.isNotEmpty) {
      debugPrint(
        'doc IDs (first/last): ${report.documentIds.first} … '
        '${report.documentIds.last} (${report.documentIds.length} total)',
      );
    }
    for (final w in report.warnings) {
      debugPrint('⚠️ $w');
    }
    for (final e in report.errors) {
      debugPrint('❌ $e');
    }
    if (!report.firestoreWritesPerformed) {
      debugPrint('DRY RUN ONLY — no Firestore writes performed');
    } else {
      debugPrint(
        '✅ Firestore writes completed for ${report.docsWritten} docs '
        '(v1 docs not deleted/archived)',
      );
    }
    debugPrint('================================================================');
  }

  static bool _isLegacySetId(String id, String type) {
    final re = RegExp('^${RegExp.escape(type)}_set_(\\d{3})\$');
    return re.hasMatch(id);
  }

  static bool _looksVersionedId(String id) {
    return RegExp(r'^(iq|eq|frequency)_set_\d{3}_v\d+$').hasMatch(id);
  }

  static int? _parseSetNumber(String legacyId) {
    final m = RegExp(r'_set_(\d{3})$').firstMatch(legacyId);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  static bool _isSetFullyLocalized(Map<String, dynamic> set, String type) {
    final questions = (set['questions'] as List<dynamic>?) ?? const [];
    if (questions.isEmpty) return false;
    for (final q in questions) {
      if (q is! Map) return false;
      if (!_isQuestionFullyLocalized(q, type)) return false;
    }
    return true;
  }

  static bool _isQuestionFullyLocalized(
    Map<dynamic, dynamic> question,
    String type,
  ) {
    if (!_hasEnTr(question['question'])) return false;
    if (type == 'frequency') return true;

    final options = question['options'];
    if (options is! List || options.isEmpty) return false;
    for (final opt in options) {
      if (opt is! Map) return false;
      if (!_hasEnTr(opt['label'])) return false;
    }
    return true;
  }

  static bool _hasEnTr(Object? value) {
    if (value is! Map) return false;
    final en = value['en'];
    final tr = value['tr'];
    return en is String &&
        en.trim().isNotEmpty &&
        tr is String &&
        tr.trim().isNotEmpty;
  }
}

class _AssetBundleSpec {
  const _AssetBundleSpec({
    required this.assetPath,
    required this.type,
    required this.expectedSets,
    required this.expectedQuestions,
  });

  final String assetPath;
  final String type;
  final int expectedSets;
  final int expectedQuestions;
}
