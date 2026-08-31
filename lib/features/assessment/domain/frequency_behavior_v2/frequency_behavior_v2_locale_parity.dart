import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_models.dart';

class FrequencyBehaviorV2LocaleParityResult {
  const FrequencyBehaviorV2LocaleParityResult({
    required this.ok,
    required this.issues,
  });

  final bool ok;
  final List<String> issues;
}

/// Structural parity validator between TR master and EN semantic presentation.
///
/// Compares immutable assessment fields only. User-facing `prompt` / option
/// `text` may differ. Does not validate translation quality.
class FrequencyBehaviorV2LocaleParityValidator {
  const FrequencyBehaviorV2LocaleParityValidator();

  static const List<String> evidenceMetaCompareKeys = [
    'version',
    'calibration_status',
    'review_status',
    'diagnostic_value',
    'behavioral_plausibility',
    'ambiguity',
    'social_desirability',
    'obviousness',
    'self_presentation_risk',
  ];

  static const List<String> reviewStructuralKeys = [
    'item_id',
    'selector_eligible',
    'selector_exclusion_reason',
    'drop_from_selectable',
    'rewrite_pending',
    'primary_review_pending',
    'processing_style_present',
    'semantic_cluster',
    'primary_dimensions',
    'secondary_dimensions',
    'review_status',
  ];

  FrequencyBehaviorV2LocaleParityResult validate({
    required FrequencyBehaviorV2PoolDocument trPool,
    required FrequencyBehaviorV2PoolDocument enPool,
    required Map<String, Map<String, dynamic>> trReviewByItemId,
    required Map<String, Map<String, dynamic>> enReviewByItemId,
    required List<List<String>> trNearDuplicateClusters,
    required List<List<String>> enNearDuplicateClusters,
  }) {
    final issues = <String>[];
    void fail(String code, [String? detail]) {
      issues.add(detail == null ? code : '$code: $detail');
    }

    if (trPool.items.length != FrequencyBehaviorV2Contract.poolItemCount) {
      fail('tr_item_count', '${trPool.items.length}');
    }
    if (enPool.items.length != FrequencyBehaviorV2Contract.poolItemCount) {
      fail('en_item_count', '${enPool.items.length}');
    }
    if (trPool.runtimeSelectable || enPool.runtimeSelectable) {
      fail('runtime_selectable_must_be_false');
    }
    if (enPool.scoringPolicyVersion != trPool.scoringPolicyVersion) {
      fail(
        'scoring_policy_mismatch',
        '${enPool.scoringPolicyVersion} vs ${trPool.scoringPolicyVersion}',
      );
    }
    if (enPool.locale != FrequencyBehaviorV2Contract.localeEn) {
      fail('en_locale', enPool.locale);
    }
    if (trPool.locale != FrequencyBehaviorV2Contract.localeTr) {
      fail('tr_locale', trPool.locale);
    }

    final trById = trPool.itemsById;
    final enById = enPool.itemsById;

    final trIds = trById.keys.toSet();
    final enIds = enById.keys.toSet();
    for (final id in trIds.difference(enIds)) {
      fail('tr_only_item', id);
    }
    for (final id in enIds.difference(trIds)) {
      fail('en_only_item', id);
    }

    var trOptionCount = 0;
    var enOptionCount = 0;
    var trDropCount = 0;
    var enDropCount = 0;
    var trSelectableCount = 0;
    var enSelectableCount = 0;

    for (final id in trIds) {
      final trItem = trById[id]!;
      final enItem = enById[id]!;

      if (trItem.primaryDimensions.join('|') !=
          enItem.primaryDimensions.join('|')) {
        fail('primary_dimension_mismatch', id);
      }
      if (trItem.secondaryDimensions.join('|') !=
          enItem.secondaryDimensions.join('|')) {
        fail('secondary_dimension_mismatch', id);
      }
      if (trItem.semanticCluster != enItem.semanticCluster) {
        fail('semantic_cluster_mismatch', id);
      }
      if (trItem.context.join('|') != enItem.context.join('|')) {
        fail('context_mismatch', id);
      }
      if (trItem.crosscheckGroupIds.join('|') !=
          enItem.crosscheckGroupIds.join('|')) {
        fail('crosscheck_group_mismatch', id);
      }

      final trOpts = {for (final o in trItem.options) o.optionId: o};
      final enOpts = {for (final o in enItem.options) o.optionId: o};
      if (trOpts.keys.join('|') != enOpts.keys.join('|')) {
        fail('option_id_set_mismatch', id);
      }

      for (final optId in trOpts.keys) {
        trOptionCount++;
        enOptionCount++;
        final trO = trOpts[optId]!;
        final enO = enOpts[optId]!;

        if (!_weightsEqual(trO.behavioralWeights, enO.behavioralWeights)) {
          fail('behavioral_weights_mismatch', '$id:$optId');
        }
        if (!_evidenceMetaEqual(trO.evidenceMeta, enO.evidenceMeta)) {
          fail('evidence_meta_mismatch', '$id:$optId');
        }
      }

      final trReview = trReviewByItemId[id];
      final enReview = enReviewByItemId[id];
      if (trReview == null) {
        fail('tr_review_missing', id);
      }
      if (enReview == null) {
        fail('en_review_missing', id);
      }
      if (trReview != null && enReview != null) {
        for (final key in reviewStructuralKeys) {
          if (!_jsonScalarEqual(trReview[key], enReview[key])) {
            fail('review_field_mismatch', '$id:$key');
          }
        }
        final trDrop = trReview['drop_from_selectable'] == true;
        final enDrop = enReview['drop_from_selectable'] == true;
        if (trDrop) trDropCount++;
        if (enDrop) enDropCount++;
        if (!trDrop && trReview['selector_eligible'] == true) {
          trSelectableCount++;
        }
        if (!enDrop && enReview['selector_eligible'] == true) {
          enSelectableCount++;
        }
      }
    }

    if (trOptionCount != FrequencyBehaviorV2Contract.poolOptionCount) {
      fail('tr_option_count', '$trOptionCount');
    }
    if (enOptionCount != FrequencyBehaviorV2Contract.poolOptionCount) {
      fail('en_option_count', '$enOptionCount');
    }
    if (trDropCount != FrequencyBehaviorV2Contract.phase2fDropFromSelectableTotal) {
      fail('tr_drop_count', '$trDropCount');
    }
    if (enDropCount != FrequencyBehaviorV2Contract.phase2fDropFromSelectableTotal) {
      fail('en_drop_count', '$enDropCount');
    }
    if (trSelectableCount !=
        FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops) {
      fail('tr_selectable_count', '$trSelectableCount');
    }
    if (enSelectableCount !=
        FrequencyBehaviorV2Contract.phase2fSelectableAfterDrops) {
      fail('en_selectable_count', '$enSelectableCount');
    }

    if (!_clusterSetsEqual(trNearDuplicateClusters, enNearDuplicateClusters)) {
      fail('near_duplicate_cluster_mismatch');
    }

    return FrequencyBehaviorV2LocaleParityResult(
      ok: issues.isEmpty,
      issues: issues,
    );
  }

  static bool _weightsEqual(
    Map<String, double> a,
    Map<String, double> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final bv = b[e.key];
      if (bv == null || (e.value - bv).abs() > 1e-9) return false;
    }
    return true;
  }

  static bool _evidenceMetaEqual(
    FrequencyBehaviorV2EvidenceMeta a,
    FrequencyBehaviorV2EvidenceMeta b,
  ) {
    if (a.version != b.version) return false;
    if (a.calibrationStatus != b.calibrationStatus) return false;
    if (a.reviewStatus != b.reviewStatus) return false;
    if (!_nullableDoubleEqual(a.diagnosticValue, b.diagnosticValue)) {
      return false;
    }
    if (!_nullableDoubleEqual(
      a.behavioralPlausibility,
      b.behavioralPlausibility,
    )) {
      return false;
    }
    if (!_nullableDoubleEqual(a.ambiguity, b.ambiguity)) return false;
    if (!_nullableDoubleEqual(a.socialDesirability, b.socialDesirability)) {
      return false;
    }
    if (!_nullableDoubleEqual(a.obviousness, b.obviousness)) return false;
    if (!_nullableDoubleEqual(
      a.selfPresentationRisk,
      b.selfPresentationRisk,
    )) {
      return false;
    }
    return true;
  }

  static bool _nullableDoubleEqual(double? a, double? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() < 1e-9;
  }

  static bool _jsonScalarEqual(Object? a, Object? b) {
    if (a == null && b == null) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_jsonScalarEqual(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final k in a.keys) {
        if (!_jsonScalarEqual(a[k], b[k])) return false;
      }
      return true;
    }
    return a == b;
  }

  static bool _clusterSetsEqual(
    List<List<String>> a,
    List<List<String>> b,
  ) {
    final as = {
      for (final c in a)
        () {
          final sorted = [...c]..sort();
          return sorted.join('|');
        }(),
    };
    final bs = {
      for (final c in b)
        () {
          final sorted = [...c]..sort();
          return sorted.join('|');
        }(),
    };
    return as.length == bs.length && as.containsAll(bs);
  }
}
