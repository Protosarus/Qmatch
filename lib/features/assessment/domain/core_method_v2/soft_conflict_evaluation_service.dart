import 'dart:convert';
import 'dart:math' as math;

import 'core_method_v2_validation.dart';
import 'relationship_value_comparison_config.dart';
import 'relationship_value_comparison_models.dart';
import 'soft_conflict_evaluation_models.dart';

/// Soft-conflict signals from value field comparisons (P2B-3).
/// Non-blocking. Does not recompute base compatibility.
class SoftConflictEvaluationService {
  const SoftConflictEvaluationService();

  SoftConflictEvaluationResult evaluate({
    required MutualRelationshipValueResult mutualValues,
    required RelationshipValueComparisonConfig config,
  }) {
    final aSignals = _directional(mutualValues.subjectAToBResult, config);
    final bSignals = _directional(mutualValues.subjectBToAResult, config);
    final aByField = {for (final s in aSignals) s.fieldId: s};
    final bByField = {for (final s in bSignals) s.fieldId: s};
    final fields = {...aByField.keys, ...bByField.keys}.toList()..sort();
    final mutual = <MutualSoftConflictSignal>[];
    final diagnostics = <String>['soft_conflict_available'];

    for (final id in fields) {
      final a = aByField[id];
      final b = bByField[id];
      final aSev = a?.severity;
      final bSev = b?.severity;
      double? mSev;
      if (aSev != null && bSev != null) {
        mSev = math.max(aSev, bSev);
      } else {
        mSev = aSev ?? bSev;
      }
      final band = mSev == null
          ? 'none'
          : config.softConflictSeverityBands.bandFor(mSev);
      diagnostics.add('soft_conflict_$band');
      mutual.add(MutualSoftConflictSignal(
        fieldId: id,
        subjectAToBSeverity: aSev,
        subjectBToASeverity: bSev,
        mutualSeverity: mSev,
        severityBand: band,
        directionalAsymmetry:
            (aSev != null && bSev != null) ? (aSev - bSev).abs() : null,
        diagnosticCodes: [
          'soft_conflict_$band',
          if (aSev != null && bSev != null && (aSev - bSev).abs() > 1e-12)
            'value_difference_directional',
        ]..sort(),
      ));
    }

    if (mutual.isEmpty) {
      diagnostics
        ..clear()
        ..add('soft_conflict_unavailable');
    }

    final provisional = SoftConflictEvaluationResult(
      subjectAToBSignals: aSignals,
      subjectBToASignals: bSignals,
      mutualSignals: mutual,
      deterministicFingerprint: '',
      diagnostics: diagnostics..sort(),
      configVersion: config.configVersion,
      registryVersion: mutualValues.registryVersion,
    );
    return SoftConflictEvaluationResult(
      subjectAToBSignals: provisional.subjectAToBSignals,
      subjectBToASignals: provisional.subjectBToASignals,
      mutualSignals: provisional.mutualSignals,
      deterministicFingerprint: _fingerprint(provisional.toJson()),
      diagnostics: provisional.diagnostics,
      configVersion: provisional.configVersion,
      registryVersion: provisional.registryVersion,
    );
  }

  List<DirectionalSoftConflictSignal> _directional(
    DirectionalRelationshipValueResult result,
    RelationshipValueComparisonConfig config,
  ) {
    final out = <DirectionalSoftConflictSignal>[];
    for (final f in result.fieldComparisons) {
      final severity = f.ownerImportance * (1 - f.adjustedDirectionalFit);
      final band = config.softConflictSeverityBands.bandFor(severity);
      final codes = <String>[
        'soft_conflict_$band',
        if (severity == 0) 'value_alignment_close',
        if (f.ownerImportance <= 0.25 && severity > 0)
          'value_difference_low_importance',
        if (f.ownerFlexibility >= 0.7 && f.baseCompatibility < 1)
          'value_difference_high_flexibility',
      ]..sort();
      out.add(DirectionalSoftConflictSignal(
        fieldId: f.fieldId,
        ownerId: f.preferenceOwnerId,
        evaluatedSubjectId: f.evaluatedSubjectId,
        baseCompatibility: f.baseCompatibility,
        adjustedDirectionalFit: f.adjustedDirectionalFit,
        importance: f.ownerImportance,
        flexibility: f.ownerFlexibility,
        severity: severity,
        severityBand: band,
        evidenceConfidence: f.evidenceConfidence,
        diagnosticCodes: codes,
      ));
    }
    out.sort((a, b) => a.fieldId.compareTo(b.fieldId));
    return out;
  }

  String _fingerprint(Map<String, dynamic> json) {
    final encoded = jsonEncode(cmSortedMap({
      ...json,
      'deterministic_fingerprint': null,
    }));
    var hash = 0xcbf29ce484222325;
    for (final unit in encoded.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
