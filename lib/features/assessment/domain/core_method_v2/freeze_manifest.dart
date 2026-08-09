import 'dart:convert';
import 'dart:io';

import 'core_method_v2_validation.dart';

String cmSha256File(String path) {
  final result = Process.runSync('shasum', ['-a', '256', path]);
  if (result.exitCode != 0) {
    throw CoreMethodValidationException('sha256 failed', [
      CoreMethodValidationError(
        fieldPath: path,
        reasonCode: 'sha256_failed',
        explanation: result.stderr.toString(),
      ),
    ]);
  }
  return result.stdout.toString().split(' ').first.trim();
}

class FreezeArtifactRecord {
  final String path;
  final String module;
  final String role;
  final String? formId;
  final String? contentVersion;
  final String? parentContentVersion;
  final Object? schemaVersion;
  final String? reviewState;
  final String? calibrationStatus;
  final String? status;
  final String sha256;
  final bool runtimeLoaded;
  final bool productionWired;
  final String questionTextFreezeStatus;
  final String optionTextFreezeStatus;
  final String evidenceDeltaFreezeStatus;
  final String metadataFreezeStatus;
  final List<String> knownPendingReviews;
  final String engineeringFreezeMeaning;

  const FreezeArtifactRecord({
    required this.path,
    required this.module,
    required this.role,
    required this.formId,
    required this.contentVersion,
    required this.parentContentVersion,
    required this.schemaVersion,
    required this.reviewState,
    required this.calibrationStatus,
    required this.status,
    required this.sha256,
    required this.runtimeLoaded,
    required this.productionWired,
    required this.questionTextFreezeStatus,
    required this.optionTextFreezeStatus,
    required this.evidenceDeltaFreezeStatus,
    required this.metadataFreezeStatus,
    required this.knownPendingReviews,
    required this.engineeringFreezeMeaning,
  });

  factory FreezeArtifactRecord.fromJson(Map<String, dynamic> j) =>
      FreezeArtifactRecord(
        path: j['path']?.toString() ?? '',
        module: j['module']?.toString() ?? '',
        role: j['role']?.toString() ?? '',
        formId: j['form_id']?.toString(),
        contentVersion: j['content_version']?.toString(),
        parentContentVersion: j['parent_content_version']?.toString(),
        schemaVersion: j['schema_version'],
        reviewState: j['review_state']?.toString(),
        calibrationStatus: j['calibration_status']?.toString(),
        status: j['status']?.toString(),
        sha256: j['sha256']?.toString() ?? '',
        runtimeLoaded: j['runtime_loaded'] == true,
        productionWired: j['production_wired'] == true,
        questionTextFreezeStatus:
            j['question_text_freeze_status']?.toString() ?? '',
        optionTextFreezeStatus:
            j['option_text_freeze_status']?.toString() ?? '',
        evidenceDeltaFreezeStatus:
            j['evidence_delta_freeze_status']?.toString() ?? '',
        metadataFreezeStatus: j['metadata_freeze_status']?.toString() ?? '',
        knownPendingReviews: [
          for (final e in (j['known_pending_reviews'] as List?) ?? const [])
            e.toString(),
        ],
        engineeringFreezeMeaning:
            j['engineering_freeze_meaning']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'path': path,
        'module': module,
        'role': role,
        'form_id': formId,
        'content_version': contentVersion,
        'parent_content_version': parentContentVersion,
        'schema_version': schemaVersion,
        'review_state': reviewState,
        'calibration_status': calibrationStatus,
        'status': status,
        'sha256': sha256,
        'runtime_loaded': runtimeLoaded,
        'production_wired': productionWired,
        'question_text_freeze_status': questionTextFreezeStatus,
        'option_text_freeze_status': optionTextFreezeStatus,
        'evidence_delta_freeze_status': evidenceDeltaFreezeStatus,
        'metadata_freeze_status': metadataFreezeStatus,
        'known_pending_reviews': knownPendingReviews,
        'engineering_freeze_meaning': engineeringFreezeMeaning,
      });
}

class P2aAssessmentEngineeringFreezeManifest {
  final String manifestId;
  final String manifestVersion;
  final String schemaVersion;
  final String status;
  final bool scientificallyValidated;
  final bool psychometricallyCalibrated;
  final bool expertApproved;
  final bool productionReady;
  final String createdForPhase;
  final Map<String, dynamic> notes;
  final List<FreezeArtifactRecord> artifacts;

  P2aAssessmentEngineeringFreezeManifest({
    required this.manifestId,
    required this.manifestVersion,
    required this.schemaVersion,
    required this.status,
    required this.scientificallyValidated,
    required this.psychometricallyCalibrated,
    required this.expertApproved,
    required this.productionReady,
    required this.createdForPhase,
    required this.notes,
    required this.artifacts,
  }) {
    cmRequire(!scientificallyValidated, 'scientifically_validated',
        'must_be_false', 'engineering freeze is not scientific validation');
    cmRequire(!psychometricallyCalibrated, 'psychometrically_calibrated',
        'must_be_false', 'not calibrated');
    cmRequire(!expertApproved, 'expert_approved', 'must_be_false',
        'not expert approved');
    cmRequire(!productionReady, 'production_ready', 'must_be_false',
        'not production ready');
  }

  factory P2aAssessmentEngineeringFreezeManifest.fromJson(
    Map<String, dynamic> j,
  ) =>
      P2aAssessmentEngineeringFreezeManifest(
        manifestId: j['manifest_id']?.toString() ?? '',
        manifestVersion: j['manifest_version']?.toString() ?? '',
        schemaVersion: j['schema_version']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        scientificallyValidated: j['scientifically_validated'] == true,
        psychometricallyCalibrated: j['psychometrically_calibrated'] == true,
        expertApproved: j['expert_approved'] == true,
        productionReady: j['production_ready'] == true,
        createdForPhase: j['created_for_phase']?.toString() ?? '',
        notes: Map<String, dynamic>.from(j['notes'] as Map? ?? {}),
        artifacts: [
          for (final e in (j['artifacts'] as List?) ?? const [])
            FreezeArtifactRecord.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );

  Map<String, dynamic> toJson() => cmSortedMap({
        'manifest_id': manifestId,
        'manifest_version': manifestVersion,
        'schema_version': schemaVersion,
        'status': status,
        'scientifically_validated': scientificallyValidated,
        'psychometrically_calibrated': psychometricallyCalibrated,
        'expert_approved': expertApproved,
        'production_ready': productionReady,
        'created_for_phase': createdForPhase,
        'notes': notes,
        'artifacts': [for (final a in artifacts) a.toJson()],
      });

  static P2aAssessmentEngineeringFreezeManifest parseJsonString(String text) =>
      P2aAssessmentEngineeringFreezeManifest.fromJson(
        Map<String, dynamic>.from(jsonDecode(text) as Map),
      );

  static P2aAssessmentEngineeringFreezeManifest loadFile(String path) =>
      parseJsonString(File(path).readAsStringSync());

  /// Verify listed artifact paths exist and SHA256 digests match.
  List<CoreMethodValidationError> verifyArtifactHashes(String repoRoot) {
    final errors = <CoreMethodValidationError>[];
    for (final a in artifacts) {
      final file = File('$repoRoot/${a.path}');
      if (!file.existsSync()) {
        errors.add(CoreMethodValidationError(
          fieldPath: a.path,
          reasonCode: 'missing_path',
          explanation: 'artifact path does not exist',
        ));
        continue;
      }
      final digest = cmSha256File(file.path);
      if (digest != a.sha256) {
        errors.add(CoreMethodValidationError(
          fieldPath: a.path,
          reasonCode: 'sha256_mismatch',
          explanation: 'expected ${a.sha256} got $digest',
        ));
      }
    }
    return errors;
  }
}
