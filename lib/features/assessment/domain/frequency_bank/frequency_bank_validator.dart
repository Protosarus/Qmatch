import 'frequency_bank_contract.dart';
import 'frequency_bank_models.dart';
import 'frequency_canonical_dimensions.dart';

class FrequencyBankValidationResult {
  const FrequencyBankValidationResult({
    required this.ok,
    required this.issues,
    required this.coverage,
  });

  final bool ok;
  final List<String> issues;
  final List<FrequencyDimensionCoverage> coverage;
}

/// Hard validator for Frequency banks.
///
/// Use [requireRuntimeCandidateBlueprint] = true only for promoted 50-item
/// runtime candidates. Math fixtures may set it false.
class FrequencyCanonicalBankValidator {
  const FrequencyCanonicalBankValidator({
    this.requireRuntimeCandidateBlueprint = true,
  });

  final bool requireRuntimeCandidateBlueprint;

  FrequencyBankValidationResult validate(FrequencyCanonicalBankDocument bank) {
    final issues = <String>[];

    void fail(String code, [String? detail]) {
      issues.add(detail == null ? code : '$code: $detail');
    }

    if (bank.schemaVersion != FrequencyBankContract.schemaVersion) {
      fail('incompatible_schema', bank.schemaVersion);
    }
    if (bank.scoringPolicyVersion !=
        FrequencyBankContract.scoringPolicyVersion) {
      fail('incompatible_scoring_policy', bank.scoringPolicyVersion);
    }
    if (bank.calibrationStatus !=
        FrequencyBankContract.calibrationUncalibrated) {
      fail('unexpected_calibration', bank.calibrationStatus);
    }
    if (bank.reliabilityStatus !=
        FrequencyBankContract.reliabilityNotCalibrated) {
      fail('unexpected_reliability', bank.reliabilityStatus);
    }

    if (requireRuntimeCandidateBlueprint) {
      if (bank.status != FrequencyBankContract.statusRuntimeCandidate) {
        fail('unexpected_status', bank.status);
      }
      if (bank.items.length != FrequencyBankContract.sessionItemCount) {
        fail(
          'BLOCKED_FREQUENCY_ITEM_COUNT',
          '${bank.items.length}',
        );
      }
    }

    final seenItems = <String>{};
    var coreCount = 0;
    var relatedCount = 0;
    var separatorCount = 0;
    var qualityCount = 0;
    final separatorIds = <String>{};
    final qualityIds = <String>{};

    for (final item in bank.items) {
      if (item.itemId.trim().isEmpty) fail('empty_item_id');
      if (!seenItems.add(item.itemId)) {
        fail('duplicate_item_id', item.itemId);
      }
      if (item.prompt.trim().isEmpty) {
        fail('empty_prompt', item.itemId);
      }

      switch (item.itemRole) {
        case FrequencyBankContract.itemRoleCore:
          coreCount++;
          break;
        case FrequencyBankContract.itemRoleBehavioralEquivalence:
          relatedCount++;
          break;
        case FrequencyBankContract.itemRoleSeparator:
          separatorCount++;
          separatorIds.add(item.itemId);
          break;
        case FrequencyBankContract.itemRoleQuality:
          qualityCount++;
          qualityIds.add(item.itemId);
          break;
        default:
          fail('unknown_item_role', '${item.itemId}:${item.itemRole}');
      }

      final primary = item.primaryDimension;
      if (item.itemRole == FrequencyBankContract.itemRoleQuality) {
        if (item.traitScoring) {
          fail('quality_must_not_trait_score', item.itemId);
        }
        if (item.rviRuntimeGate) {
          fail('quality_rvi_gate_must_be_false', item.itemId);
        }
        if (item.qualityType == null || item.qualityType!.trim().isEmpty) {
          fail('quality_type_missing', item.itemId);
        }
        if (item.expectedProtocolOptionId == null ||
            item.expectedProtocolOptionId!.trim().isEmpty) {
          fail('expected_protocol_option_missing', item.itemId);
        } else if (item.optionById(item.expectedProtocolOptionId!) == null) {
          fail('expected_protocol_option_unknown', item.itemId);
        }
        if (primary != null) {
          fail('quality_must_omit_primary', item.itemId);
        }
      } else if (item.itemRole == FrequencyBankContract.itemRoleSeparator) {
        if (item.separatorType !=
            FrequencyBankContract.separatorTypeDimensionBoundary) {
          fail('separator_type', '${item.itemId}:${item.separatorType}');
        }
        if (item.separatorDimensions.length <
            FrequencyBankContract.minSeparatorDimensions) {
          fail('separator_dimensions_lt_2', item.itemId);
        }
        for (final d in item.separatorDimensions) {
          if (!FrequencyCanonicalDimensions.isCanonical(d)) {
            fail('unknown_separator_dimension', '$d@${item.itemId}');
          }
          if (FrequencyCanonicalDimensions.isForbiddenLegacy(d)) {
            fail('legacy_separator_dimension', '$d@${item.itemId}');
          }
        }
        // Persona targets optional / empty in R1A — do not invent.
        for (final p in item.separatorPersonaTargets) {
          if (p.trim().isEmpty) {
            fail('empty_separator_persona_target', item.itemId);
          }
        }
        if (!item.traitScoring) {
          fail('separator_must_trait_score', item.itemId);
        }
      } else {
        if (primary == null || primary.isEmpty) {
          fail('missing_primary_dimension', item.itemId);
        } else {
          if (!FrequencyCanonicalDimensions.isCanonical(primary)) {
            fail('unknown_primary_dimension', primary);
          }
          if (FrequencyCanonicalDimensions.isForbiddenLegacy(primary)) {
            fail('legacy_primary_dimension', primary);
          }
        }
        if (!item.traitScoring) {
          fail('trait_role_must_score', item.itemId);
        }
      }

      for (final s in item.secondaryDimensions) {
        if (!FrequencyCanonicalDimensions.isCanonical(s)) {
          fail('unknown_secondary_dimension', '$s@${item.itemId}');
        }
        if (FrequencyCanonicalDimensions.isForbiddenLegacy(s)) {
          fail('legacy_secondary_dimension', '$s@${item.itemId}');
        }
      }

      if (item.options.isEmpty) {
        fail('empty_options', item.itemId);
      }
      if (requireRuntimeCandidateBlueprint &&
          item.options.length != FrequencyBankContract.optionsPerItem) {
        fail('option_count', item.itemId);
      }

      final seenOpts = <String>{};
      for (final o in item.options) {
        if (o.optionId.trim().isEmpty) {
          fail('empty_option_id', item.itemId);
        }
        if (!seenOpts.add(o.optionId)) {
          fail('duplicate_option_id', '${item.itemId}:${o.optionId}');
        }
        if (o.text.trim().isEmpty) {
          fail('empty_option_text', '${item.itemId}:${o.optionId}');
        }

        if (item.itemRole == FrequencyBankContract.itemRoleQuality ||
            !item.traitScoring) {
          if (o.dimensionDeltas.isNotEmpty) {
            fail(
                'quality_deltas_must_be_empty', '${item.itemId}:${o.optionId}');
          }
        } else if (o.dimensionDeltas.isEmpty) {
          fail('empty_deltas', '${item.itemId}:${o.optionId}');
        }

        for (final e in o.dimensionDeltas.entries) {
          if (!FrequencyCanonicalDimensions.isCanonical(e.key)) {
            fail('unknown_delta_dimension', '${item.itemId}:${e.key}');
          }
          if (FrequencyCanonicalDimensions.isForbiddenLegacy(e.key)) {
            fail('legacy_delta_dimension', '${item.itemId}:${e.key}');
          }
          if (e.value.isNaN || e.value.isInfinite) {
            fail('non_finite_delta', '${item.itemId}:${e.key}');
          }
          if (e.value < -1.0 || e.value > 1.0) {
            fail('delta_out_of_range', '${item.itemId}:${e.key}=${e.value}');
          }
        }

        if (item.itemRole == FrequencyBankContract.itemRoleCore ||
            item.itemRole ==
                FrequencyBankContract.itemRoleBehavioralEquivalence) {
          if (primary != null && !o.dimensionDeltas.containsKey(primary)) {
            fail('primary_delta_missing_on_option', item.itemId);
          }
        }
      }

      if (item.itemRole ==
              FrequencyBankContract.itemRoleBehavioralEquivalence &&
          item.behavioralIsomorphGroupId == null &&
          item.relationshipType == null &&
          item.semanticPairId == null &&
          item.reversePairId == null) {
        fail('missing_relationship_metadata', item.itemId);
      }
    }

    final coverage = frequencyBankDimensionCoverage(bank);

    if (requireRuntimeCandidateBlueprint) {
      if (coreCount != FrequencyBankContract.coreItemCount) {
        fail('BLOCKED_FREQUENCY_CORE_EVIDENCE_COVERAGE', 'core=$coreCount');
      }
      if (relatedCount !=
          FrequencyBankContract.behavioralEquivalenceItemCount) {
        fail(
          'BLOCKED_FREQUENCY_RELATIONSHIP_ITEM_COVERAGE',
          'related=$relatedCount',
        );
      }
      if (separatorCount != FrequencyBankContract.separatorItemCount) {
        fail(
          'BLOCKED_FREQUENCY_SEPARATOR_ITEM_COVERAGE',
          'separator=$separatorCount',
        );
      }
      if (qualityCount != FrequencyBankContract.qualityItemCount) {
        fail(
          'BLOCKED_FREQUENCY_QUALITY_ITEM_COVERAGE',
          'quality=$qualityCount',
        );
      }

      final expectedSep =
          FrequencyBankContract.authoredSeparatorIds.toSet();
      if (separatorIds.length != expectedSep.length ||
          !separatorIds.containsAll(expectedSep)) {
        fail(
          'separator_ids_mismatch',
          'got=${(separatorIds.toList()..sort())} expected=${(expectedSep.toList()..sort())}',
        );
      }
      final expectedQual = FrequencyBankContract.authoredQualityIds.toSet();
      if (qualityIds.length != expectedQual.length ||
          !qualityIds.containsAll(expectedQual)) {
        fail(
          'quality_ids_mismatch',
          'got=${(qualityIds.toList()..sort())} expected=${(expectedQual.toList()..sort())}',
        );
      }

      for (final c in coverage) {
        if (c.corePrimaryItemCount !=
            FrequencyBankContract.primaryCoreItemsPerDimension) {
          fail(
            'BLOCKED_FREQUENCY_CORE_EVIDENCE_COVERAGE',
            '${c.dimensionId}=${c.corePrimaryItemCount}',
          );
        }
        if (c.relatedItemCount !=
            FrequencyBankContract.relatedItemsPerDimension) {
          fail(
            'BLOCKED_FREQUENCY_RELATIONSHIP_ITEM_COVERAGE',
            '${c.dimensionId}=${c.relatedItemCount}',
          );
        }
      }
    }

    if (bank.rviRuntimeGate != null &&
        bank.rviRuntimeGate != FrequencyBankContract.rviGateNotActive) {
      fail('unexpected_rvi_gate', bank.rviRuntimeGate);
    }

    return FrequencyBankValidationResult(
      ok: issues.isEmpty,
      issues: issues,
      coverage: coverage,
    );
  }
}

/// Structural TR/EN parity (language fields excluded).
class FrequencyBankParityResult {
  const FrequencyBankParityResult({required this.ok, required this.issues});

  final bool ok;
  final List<String> issues;
}

class FrequencyCanonicalBankParity {
  const FrequencyCanonicalBankParity();

  FrequencyBankParityResult compare(
    FrequencyCanonicalBankDocument tr,
    FrequencyCanonicalBankDocument en,
  ) {
    final issues = <String>[];
    void fail(String m) => issues.add(m);

    if (tr.items.length != en.items.length) {
      fail('item_count_mismatch');
    }
    final enBy = {for (final i in en.items) i.itemId: i};
    for (final t in tr.items) {
      final e = enBy[t.itemId];
      if (e == null) {
        fail('missing_en_item:${t.itemId}');
        continue;
      }
      if (e.itemRole != t.itemRole) {
        fail('role_mismatch:${t.itemId}');
      }
      if (e.primaryDimension != t.primaryDimension) {
        fail('primary_mismatch:${t.itemId}');
      }
      if (!_listEq(e.secondaryDimensions, t.secondaryDimensions)) {
        fail('secondary_mismatch:${t.itemId}');
      }
      if (e.semanticPairId != t.semanticPairId) {
        fail('semantic_pair_mismatch:${t.itemId}');
      }
      if (e.reversePairId != t.reversePairId) {
        fail('reverse_pair_mismatch:${t.itemId}');
      }
      if (e.behavioralIsomorphGroupId != t.behavioralIsomorphGroupId) {
        fail('isomorph_mismatch:${t.itemId}');
      }
      if (e.relationshipType != t.relationshipType) {
        fail('relationship_type_mismatch:${t.itemId}');
      }
      if (e.reverseScored != t.reverseScored) {
        fail('reverse_scored_mismatch:${t.itemId}');
      }
      if (e.separatorType != t.separatorType) {
        fail('separator_type_mismatch:${t.itemId}');
      }
      if (!_listEq(e.separatorDimensions, t.separatorDimensions)) {
        fail('separator_dimensions_mismatch:${t.itemId}');
      }
      if (!_listEq(e.separatorPersonaTargets, t.separatorPersonaTargets)) {
        fail('separator_persona_mismatch:${t.itemId}');
      }
      if (e.traitScoring != t.traitScoring) {
        fail('trait_scoring_mismatch:${t.itemId}');
      }
      if (e.qualityType != t.qualityType) {
        fail('quality_type_mismatch:${t.itemId}');
      }
      if (e.expectedProtocolOptionId != t.expectedProtocolOptionId) {
        fail('expected_protocol_mismatch:${t.itemId}');
      }
      if (e.rviRuntimeGate != t.rviRuntimeGate) {
        fail('item_rvi_gate_mismatch:${t.itemId}');
      }
      if (e.options.length != t.options.length) {
        fail('option_count_mismatch:${t.itemId}');
      }
      for (var i = 0; i < t.options.length; i++) {
        final to = t.options[i];
        final eo = e.options[i];
        if (eo.optionId != to.optionId) {
          fail('option_id_mismatch:${t.itemId}');
        }
        if (!_mapEq(eo.dimensionDeltas, to.dimensionDeltas)) {
          fail('delta_mismatch:${t.itemId}:${to.optionId}');
        }
      }
    }
    if (tr.scoringPolicyVersion != en.scoringPolicyVersion) {
      fail('scoring_policy_mismatch');
    }
    if (tr.schemaVersion != en.schemaVersion) {
      fail('schema_mismatch');
    }
    return FrequencyBankParityResult(ok: issues.isEmpty, issues: issues);
  }

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEq(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      final other = b[e.key];
      if (other == null) return false;
      if ((other - e.value).abs() > 1e-12) return false;
    }
    return true;
  }
}
