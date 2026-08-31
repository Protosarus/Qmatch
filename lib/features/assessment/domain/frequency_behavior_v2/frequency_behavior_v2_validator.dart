import 'frequency_behavior_v2_contract.dart';
import 'frequency_behavior_v2_models.dart';

class FrequencyBehaviorV2ValidationResult {
  const FrequencyBehaviorV2ValidationResult({
    required this.ok,
    required this.issues,
  });

  final bool ok;
  final List<String> issues;
}

/// Draft validator accepts unresolved second-layer metadata.
/// Production-ready validator rejects pending/manual-review items.
class FrequencyBehaviorV2PoolValidator {
  const FrequencyBehaviorV2PoolValidator({
    this.productionReady = false,
  });

  final bool productionReady;

  FrequencyBehaviorV2ValidationResult validate(
    FrequencyBehaviorV2PoolDocument pool, {
    Map<String, Map<String, dynamic>> reviewByItemId = const {},
  }) {
    final issues = <String>[];
    void fail(String code, [String? detail]) {
      issues.add(detail == null ? code : '$code: $detail');
    }

    if (pool.schemaVersion != FrequencyBehaviorV2Contract.schemaVersion) {
      fail('incompatible_schema', pool.schemaVersion);
    }
    if (pool.scoringPolicyVersion !=
        FrequencyBehaviorV2Contract.scoringPolicyVersion) {
      fail('incompatible_scoring_policy', pool.scoringPolicyVersion);
    }
    if (pool.runtimeSelectable) {
      fail('draft_must_not_be_runtime_selectable');
    }
    if (pool.status != FrequencyBehaviorV2Contract.statusDraftNotRuntime &&
        !productionReady) {
      fail('unexpected_status', pool.status);
    }
    if (pool.items.length != FrequencyBehaviorV2Contract.poolItemCount) {
      fail('item_count', '${pool.items.length}');
    }

    final seenItems = <String>{};
    var optionCount = 0;
    for (final item in pool.items) {
      if (item.itemId.trim().isEmpty) fail('empty_item_id');
      if (!seenItems.add(item.itemId)) fail('duplicate_item_id', item.itemId);
      if (item.prompt.trim().isEmpty) fail('empty_prompt', item.itemId);
      if (item.options.length != FrequencyBehaviorV2Contract.optionsPerItem) {
        fail('option_count', item.itemId);
      }
      for (final d in [...item.primaryDimensions, ...item.secondaryDimensions]) {
        if (!FrequencyBehaviorV2Contract.isCanonicalDimension(d)) {
          fail('unknown_dimension', '$d@${item.itemId}');
        }
        if (FrequencyBehaviorV2Contract.neverAutoMap.contains(d)) {
          fail('processing_style_leaked_into_pool', '${item.itemId}:$d');
        }
      }
      if (item.primaryDimensions.length > 1) {
        final review = reviewByItemId[item.itemId];
        final eligible = review?['selector_eligible'] == true;
        if (productionReady || eligible) {
          fail('multiple_primary_dimensions', item.itemId);
        }
      }
      if (item.semanticCluster.trim().isEmpty) {
        fail('empty_semantic_cluster', item.itemId);
      }

      final seenOpts = <String>{};
      for (final o in item.options) {
        optionCount++;
        if (o.optionId.trim().isEmpty) fail('empty_option_id', item.itemId);
        if (!seenOpts.add(o.optionId)) {
          fail('duplicate_option_id', '${item.itemId}:${o.optionId}');
        }
        if (o.text.trim().isEmpty) {
          fail('empty_option_text', '${item.itemId}:${o.optionId}');
        }
        for (final e in o.behavioralWeights.entries) {
          if (!FrequencyBehaviorV2Contract.isCanonicalDimension(e.key)) {
            fail('unknown_weight_dimension', '${item.itemId}:${e.key}');
          }
          if (e.value.isNaN || e.value.isInfinite) {
            fail('non_finite_weight', '${item.itemId}:${e.key}');
          }
          if (e.value < FrequencyBehaviorV2Contract.weightMin ||
              e.value > FrequencyBehaviorV2Contract.weightMax) {
            fail('weight_out_of_range', '${item.itemId}:${e.key}=${e.value}');
          }
        }
        _validateEvidenceMeta(o.evidenceMeta, item.itemId, o.optionId, fail);
        if (productionReady) {
          if (!o.evidenceMeta.isResolved) {
            fail('unresolved_evidence_meta', '${item.itemId}:${o.optionId}');
          }
          if (o.behavioralWeights.isEmpty) {
            fail('empty_weights_production', '${item.itemId}:${o.optionId}');
          }
        }
      }

      final review = reviewByItemId[item.itemId];
      if (productionReady) {
        if (item.primaryDimensions.isEmpty) {
          fail('no_canonical_primary_production', item.itemId);
        }
        if (review != null) {
          final status = review['review_status']?.toString();
          if (status == 'manual_review' || status == 'pending') {
            fail('unresolved_item_review', item.itemId);
          }
          final unresolved = review['unresolved_dimension_labels'];
          if (unresolved is List && unresolved.isNotEmpty) {
            fail('unresolved_dimension_labels', item.itemId);
          }
          if (review['processing_style_present'] == true) {
            fail('processing_style_not_rescored', item.itemId);
          }
          if (review['primary_review_pending'] == true) {
            fail('primary_review_pending', item.itemId);
          }
          if (review['rewrite_pending'] == true) {
            fail('rewrite_pending', item.itemId);
          }
          if (review['drop_from_selectable'] == true) {
            fail('drop_from_selectable_pool', item.itemId);
          }
          if (review['selector_eligible'] == true &&
              item.primaryDimensions.length != 1) {
            fail('selectable_must_have_exactly_one_primary', item.itemId);
          }
        }
      }
    }

    if (optionCount != FrequencyBehaviorV2Contract.poolOptionCount &&
        pool.items.length == FrequencyBehaviorV2Contract.poolItemCount) {
      fail('option_total', '$optionCount');
    }

    return FrequencyBehaviorV2ValidationResult(
      ok: issues.isEmpty,
      issues: issues,
    );
  }

  FrequencyBehaviorV2ValidationResult validateEvidenceMetaOnly(
    FrequencyBehaviorV2EvidenceMeta meta, {
    String itemId = 'item',
    String optionId = 'opt',
  }) {
    final issues = <String>[];
    _validateEvidenceMeta(meta, itemId, optionId, (code, [detail]) {
      issues.add(detail == null ? code : '$code: $detail');
    });
    return FrequencyBehaviorV2ValidationResult(
      ok: issues.isEmpty,
      issues: issues,
    );
  }

  void _validateEvidenceMeta(
    FrequencyBehaviorV2EvidenceMeta meta,
    String itemId,
    String optionId,
    void Function(String code, [String? detail]) fail,
  ) {
    final loc = '$itemId:$optionId';
    if (meta.version != FrequencyBehaviorV2Contract.evidenceMetaVersion) {
      fail('evidence_meta_unknown_version', '$loc:${meta.version}');
    }
    if (meta.calibrationStatus !=
        FrequencyBehaviorV2Contract.evidenceCalibrationUncalibrated) {
      fail('evidence_meta_not_uncalibrated', '$loc:${meta.calibrationStatus}');
    }

    final named = <String, double?>{
      'social_desirability': meta.socialDesirability,
      'obviousness': meta.obviousness,
      'behavioral_plausibility': meta.behavioralPlausibility,
      'self_presentation_risk': meta.selfPresentationRisk,
      'diagnostic_value': meta.diagnosticValue,
      'ambiguity': meta.ambiguity,
    };
    final present = named.entries.where((e) => e.value != null).toList();
    final missing = named.entries.where((e) => e.value == null).toList();

    for (final e in present) {
      final v = e.value!;
      if (v.isNaN || v.isInfinite) {
        fail('non_finite_evidence_meta', '$loc:${e.key}');
        continue;
      }
      if (!FrequencyBehaviorV2Contract.isAllowedEvidenceValue(v)) {
        fail('evidence_meta_not_allowed_value', '$loc:${e.key}=$v');
      }
    }

    if (present.isNotEmpty && missing.isNotEmpty) {
      fail('incomplete_evidence_meta_set', loc);
    }

    if (meta.reviewStatus ==
        FrequencyBehaviorV2Contract.evidenceReviewReviewed) {
      if (missing.isNotEmpty) {
        fail('incomplete_reviewed_evidence_meta', loc);
      }
    } else if (meta.reviewStatus ==
        FrequencyBehaviorV2Contract.evidenceReviewPending) {
      if (present.isNotEmpty) {
        fail('numeric_evidence_with_pending_status', loc);
      }
    } else {
      fail('evidence_meta_unknown_review_status', '$loc:${meta.reviewStatus}');
    }
  }
}
