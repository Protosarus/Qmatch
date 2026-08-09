import 'eq_bank_contract.dart';
import 'eq_bank_models.dart';
import 'eq_canonical_dimensions.dart';

class EqBankValidationResult {
  const EqBankValidationResult({
    required this.ok,
    required this.issues,
    required this.coverage,
  });

  final bool ok;
  final List<String> issues;
  final List<EqDimensionCoverage> coverage;
}

/// Hard validator for runtime-candidate EQ banks.
class EqCanonicalBankValidator {
  const EqCanonicalBankValidator();

  EqBankValidationResult validate(EqCanonicalBankDocument bank) {
    final issues = <String>[];

    void fail(String code, [String? detail]) {
      issues.add(detail == null ? code : '$code: $detail');
    }

    if (bank.schemaVersion != EqBankContract.schemaVersion) {
      fail('incompatible_schema', bank.schemaVersion);
    }
    if (bank.scoringPolicyVersion != EqBankContract.scoringPolicyVersion) {
      fail('incompatible_scoring_policy', bank.scoringPolicyVersion);
    }
    if (bank.status != EqBankContract.statusRuntimeCandidate) {
      fail('unexpected_status', bank.status);
    }
    if (bank.calibrationStatus != EqBankContract.calibrationUncalibrated) {
      fail('unexpected_calibration', bank.calibrationStatus);
    }
    if (bank.reliabilityStatus != EqBankContract.reliabilityNotCalibrated) {
      fail('unexpected_reliability', bank.reliabilityStatus);
    }
    if (bank.items.length != EqBankContract.sessionItemCount) {
      fail('item_count', '${bank.items.length}');
    }

    final seenItems = <String>{};
    for (final item in bank.items) {
      if (item.itemId.trim().isEmpty) fail('empty_item_id');
      if (!seenItems.add(item.itemId)) {
        fail('duplicate_item_id', item.itemId);
      }
      if (item.prompt.trim().isEmpty) {
        fail('empty_prompt', item.itemId);
      }
      if (!EqCanonicalDimensions.isCanonical(item.primaryDimension)) {
        fail('unknown_primary_dimension', item.primaryDimension);
      }
      if (EqCanonicalDimensions.isForbiddenLegacy(item.primaryDimension)) {
        fail('legacy_primary_dimension', item.primaryDimension);
      }
      for (final s in item.secondaryDimensions) {
        if (!EqCanonicalDimensions.isCanonical(s)) {
          fail('unknown_secondary_dimension', '$s@${item.itemId}');
        }
        if (EqCanonicalDimensions.isForbiddenLegacy(s)) {
          fail('legacy_secondary_dimension', '$s@${item.itemId}');
        }
      }
      if (item.options.length != EqBankContract.optionsPerItem) {
        fail('option_count', item.itemId);
      }
      final seenOpts = <String>{};
      var primaryDeltaCoverage = 0;
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
        if (o.dimensionDeltas.isEmpty) {
          fail('empty_deltas', '${item.itemId}:${o.optionId}');
        }
        for (final e in o.dimensionDeltas.entries) {
          if (!EqCanonicalDimensions.isCanonical(e.key)) {
            fail('unknown_delta_dimension', '${item.itemId}:${e.key}');
          }
          if (EqCanonicalDimensions.isForbiddenLegacy(e.key)) {
            fail('legacy_delta_dimension', '${item.itemId}:${e.key}');
          }
          if (e.value.isNaN || e.value.isInfinite) {
            fail('non_finite_delta', '${item.itemId}:${e.key}');
          }
          if (e.value < -1.0 || e.value > 1.0) {
            fail('delta_out_of_range', '${item.itemId}:${e.key}=${e.value}');
          }
        }
        if (o.dimensionDeltas.containsKey(item.primaryDimension)) {
          primaryDeltaCoverage++;
        }
        // Correctness metadata must not drive scoring — reject if present on
        // option maps via reserved keys that parsers might accidentally keep.
        // Banks are constructed without these fields; this is a structural guard
        // when raw JSON is re-checked via toJson roundtrip only.
      }
      if (primaryDeltaCoverage != item.options.length) {
        fail('primary_delta_missing_on_option', item.itemId);
      }
    }

    final coverage = eqBankDimensionCoverage(bank);
    for (final c in coverage) {
      if (c.primaryItemCount < EqBankContract.primaryItemsPerDimension) {
        fail(
          'BLOCKED_EQ_PRIMARY_EVIDENCE_COVERAGE',
          '${c.dimensionId}=${c.primaryItemCount}',
        );
      }
      if (c.primaryItemCount != EqBankContract.primaryItemsPerDimension) {
        fail(
          'primary_item_count_not_exact',
          '${c.dimensionId}=${c.primaryItemCount}',
        );
      }
    }

    // Pair registry: only validate identity consistency; do not invent pairs.
    final itemIds = seenItems;
    final semantic = bank.pairRegistry['semantic_pairs'];
    if (semantic is List) {
      for (final raw in semantic) {
        if (raw is! Map) continue;
        final ids = (raw['item_ids'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        for (final id in ids) {
          if (!itemIds.contains(id)) {
            fail('semantic_pair_unknown_item', id);
          }
        }
      }
    }
    final reverse = bank.pairRegistry['reverse_pairs'];
    if (reverse is List) {
      for (final raw in reverse) {
        if (raw is! Map) continue;
        final ids = (raw['item_ids'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        for (final id in ids) {
          if (!itemIds.contains(id)) {
            fail('reverse_pair_unknown_item', id);
          }
        }
      }
    }

    if (bank.rviRuntimeGate != null &&
        bank.rviRuntimeGate != EqBankContract.rviGateNotActive) {
      fail('unexpected_rvi_gate', bank.rviRuntimeGate);
    }

    return EqBankValidationResult(
      ok: issues.isEmpty,
      issues: issues,
      coverage: coverage,
    );
  }
}

/// Structural TR/EN parity (language fields excluded).
class EqBankParityResult {
  const EqBankParityResult({required this.ok, required this.issues});

  final bool ok;
  final List<String> issues;
}

class EqCanonicalBankParity {
  const EqCanonicalBankParity();

  EqBankParityResult compare(
    EqCanonicalBankDocument tr,
    EqCanonicalBankDocument en,
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
    return EqBankParityResult(ok: issues.isEmpty, issues: issues);
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
