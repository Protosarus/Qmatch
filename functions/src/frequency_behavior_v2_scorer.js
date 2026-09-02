'use strict';

const contract = require('./frequency_behavior_v2_contract');

function meanOf(values) {
  let sum = 0;
  let n = 0;
  for (const v of values) {
    if (v == null) return null;
    sum += v;
    n++;
  }
  if (n === 0) return null;
  return sum / n;
}

function accumulateEvidence(sums, ns, meta) {
  function add(key, value) {
    if (value == null) return;
    sums[key] = (sums[key] || 0) + value;
    ns[key] = (ns[key] || 0) + 1;
  }
  add('diagnostic_value', meta.diagnostic_value);
  add('behavioral_plausibility', meta.behavioral_plausibility);
  add('ambiguity', meta.ambiguity);
  add('social_desirability', meta.social_desirability);
  add('obviousness', meta.obviousness);
  add('self_presentation_risk', meta.self_presentation_risk);
}

function meanOrNull(sums, ns, key) {
  const n = ns[key] || 0;
  if (n === 0) return null;
  return sums[key] / n;
}

function nearDupIndex(clusters, presentedIds) {
  const presented = new Set(presentedIds);
  const out = {};
  for (let i = 0; i < clusters.length; i++) {
    const members = clusters[i].filter((id) => presented.has(id));
    if (members.length < 2) continue;
    for (const id of members) {
      if (out[id] === undefined) out[id] = i;
    }
  }
  return out;
}

function crossContext(rows, nearDupIdx) {
  let possible = 0;
  let eligible = 0;
  let simSum = 0;
  for (let i = 0; i < rows.length; i++) {
    for (let j = i + 1; j < rows.length; j++) {
      if (rows[i].cluster === rows[j].cluster) continue;
      possible++;
      const ndi = nearDupIdx[rows[i].item_id];
      const ndj = nearDupIdx[rows[j].item_id];
      if (ndi != null && ndi === ndj) continue;
      eligible++;
      simSum += 1.0 - Math.abs(rows[i].signal - rows[j].signal) / 4.0;
    }
  }
  return {
    possible,
    eligible,
    consistency: eligible === 0 ? null : simSum / eligible,
    coverage: possible === 0 ? null : eligible / possible,
  };
}

function questionCapacity(item, dim) {
  let maxAbs = 0;
  for (const oid of item.authored_option_ids) {
    const opt = item.options[oid];
    if (!opt || !opt.behavioral_weights) continue;
    const w = opt.behavioral_weights[dim];
    if (w == null) continue;
    const a = Math.abs(w);
    if (a > maxAbs) maxAbs = a;
  }
  return maxAbs;
}

function deriveProvisionalConfidence({
  meanDiagnosticValue,
  meanBehavioralPlausibility,
  meanAmbiguity,
  meanSocialDesirability,
  meanObviousness,
  meanSelfPresentationRisk,
  primarySignalCoverage,
  crossContextConsistency,
  crossContextCoverage,
}) {
  const semanticClarity =
    meanAmbiguity == null ? null : Math.max(0, Math.min(1, 1.0 - meanAmbiguity));
  const evidenceQuality = meanOf([
    meanDiagnosticValue,
    meanBehavioralPlausibility,
    semanticClarity,
  ]);
  const primaryObservability = primarySignalCoverage;
  let contextComponent = null;
  if (crossContextConsistency != null && crossContextCoverage != null) {
    contextComponent = Math.max(
      0,
      Math.min(
        1,
        0.75 * Math.max(0, Math.min(1, crossContextConsistency)) +
          0.25 * Math.max(0, Math.min(1, crossContextCoverage)),
      ),
    );
  }
  const presentationPressure = meanOf([
    meanSocialDesirability,
    meanObviousness,
    meanSelfPresentationRisk,
  ]);
  const presentationAdjustment =
    presentationPressure == null
      ? 1.0
      : Math.max(
          1.0 - contract.PRESENTATION_PRESSURE_MAX_DISCOUNT,
          Math.min(
            1.0,
            1.0 -
              contract.PRESENTATION_PRESSURE_MAX_DISCOUNT *
                Math.max(0, Math.min(1, presentationPressure)),
          ),
        );
  let baseConfidence = null;
  if (evidenceQuality != null && primaryObservability != null) {
    if (contextComponent != null) {
      baseConfidence = Math.max(
        0,
        Math.min(
          1,
          contract.CONFIDENCE_EVIDENCE_WEIGHT * evidenceQuality +
            contract.CONFIDENCE_OBSERVABILITY_WEIGHT * primaryObservability +
            contract.CONFIDENCE_CONTEXT_WEIGHT * contextComponent,
        ),
      );
    } else {
      baseConfidence = Math.max(
        0,
        Math.min(
          1,
          (contract.CONFIDENCE_EVIDENCE_WEIGHT * evidenceQuality +
            contract.CONFIDENCE_OBSERVABILITY_WEIGHT * primaryObservability) /
            (contract.CONFIDENCE_EVIDENCE_WEIGHT +
              contract.CONFIDENCE_OBSERVABILITY_WEIGHT),
        ),
      );
    }
  }
  const provisionalConfidence =
    baseConfidence == null
      ? null
      : Math.max(0, Math.min(1, baseConfidence * presentationAdjustment));
  const confidenceCompleteness = contextComponent == null ? 0.8 : 1.0;
  const flags = [];
  if (
    evidenceQuality != null &&
    evidenceQuality < contract.FLAG_LOW_EVIDENCE_QUALITY_MAX
  ) {
    flags.push(contract.FLAG_LOW_EVIDENCE_QUALITY);
  }
  if (
    presentationPressure != null &&
    presentationPressure >= contract.FLAG_HIGH_PRESENTATION_PRESSURE_MIN
  ) {
    flags.push(contract.FLAG_HIGH_PRESENTATION_PRESSURE);
  }
  if (
    primaryObservability != null &&
    primaryObservability < contract.FLAG_LOW_PRIMARY_OBSERVABILITY_MAX
  ) {
    flags.push(contract.FLAG_LOW_PRIMARY_OBSERVABILITY);
  }
  const limitedContext =
    contextComponent == null ||
    (crossContextCoverage != null &&
      crossContextCoverage < contract.FLAG_LIMITED_CROSS_CONTEXT_COVERAGE_MAX);
  if (limitedContext) {
    flags.push(contract.FLAG_LIMITED_CROSS_CONTEXT);
  }
  if (
    crossContextConsistency != null &&
    crossContextCoverage != null &&
    crossContextConsistency < contract.FLAG_CONTEXT_SENSITIVE_CONSISTENCY_MAX &&
    crossContextCoverage >= contract.FLAG_CONTEXT_SENSITIVE_COVERAGE_MIN
  ) {
    flags.push(contract.FLAG_CONTEXT_SENSITIVE);
  }
  return {
    semantic_clarity: semanticClarity,
    evidence_quality: evidenceQuality,
    primary_observability: primaryObservability,
    presentation_pressure: presentationPressure,
    presentation_adjustment: presentationAdjustment,
    context_component: contextComponent,
    base_confidence: baseConfidence,
    provisional_confidence: provisionalConfidence,
    confidence_completeness: confidenceCompleteness,
    confidence_flags: flags,
  };
}

function buildScoreSummary(dimensionScores) {
  let dimensionsWithBehavior = 0;
  let supportSum = 0;
  let supportN = 0;
  for (const d of dimensionScores) {
    if (d.normalized_behavior != null) {
      dimensionsWithBehavior++;
      if (d.provisional_confidence != null && d.confidence_completeness != null) {
        supportSum += d.provisional_confidence * d.confidence_completeness;
        supportN++;
      }
    }
  }
  return {
    measured_dimension_count: contract.DIMENSION_COUNT,
    dimensions_with_behavior: dimensionsWithBehavior,
    global_support: supportN === 0 ? null : supportSum / supportN,
  };
}

function scoreSession({
  bank,
  responses,
  manifest,
  nearDuplicateClusters,
}) {
  if (bank.scoring_policy_version !== contract.SCORING_POLICY_VERSION) {
    return {
      ok: false,
      message: 'Incompatible scoring policy',
      dimension_scores: [],
    };
  }
  if (manifest && manifest.bank_version !== bank.bank_version) {
    return {
      ok: false,
      message: `Manifest bank_version ${manifest.bank_version} != pool ${bank.bank_version}`,
      dimension_scores: [],
      bank_version: bank.bank_version,
      selector_version: manifest.selector_version,
      session_id: manifest.session_id,
    };
  }

  const itemsById = bank.items_by_id;
  const clusters = nearDuplicateClusters || bank.near_duplicate_clusters || [];
  const presentedIds =
    manifest != null
      ? manifest.question_ids.slice()
      : responses.map((r) => r.item_id);

  const seenPresented = new Set();
  for (const id of presentedIds) {
    if (seenPresented.has(id)) {
      return fail(bank, manifest, `Duplicate presented question ${id}`);
    }
    seenPresented.add(id);
    if (!itemsById[id]) {
      return fail(bank, manifest, `Unknown item ${id}`);
    }
  }

  const seenAnswers = new Set();
  const answerByItem = {};
  for (const r of responses) {
    if (seenAnswers.has(r.item_id)) {
      return fail(bank, manifest, `Duplicate answer for ${r.item_id}`);
    }
    seenAnswers.add(r.item_id);
    const item = itemsById[r.item_id];
    if (!item) {
      return fail(bank, manifest, `Unknown item ${r.item_id}`);
    }
    const opt = item.options[r.selected_option_id];
    if (!opt) {
      return fail(
        bank,
        manifest,
        `Option ${r.selected_option_id} not in ${r.item_id}`,
      );
    }
    for (const key of Object.keys(opt.behavioral_weights || {})) {
      if (!contract.isCanonicalDimension(key)) {
        return fail(bank, manifest, `Unknown dimension ${key}`);
      }
    }
    answerByItem[r.item_id] = opt;
  }

  const nearDupIdx = nearDupIndex(clusters, seenPresented);
  const dims = contract.CANONICAL_DIMENSIONS;
  const rawSum = Object.fromEntries(dims.map((d) => [d, 0]));
  const capacity = Object.fromEntries(dims.map((d) => [d, 0]));
  const absSelected = Object.fromEntries(dims.map((d) => [d, 0]));
  const primaryCount = Object.fromEntries(dims.map((d) => [d, 0]));
  const nonzeroPrimary = Object.fromEntries(dims.map((d) => [d, 0]));
  const zeroPrimary = Object.fromEntries(dims.map((d) => [d, 0]));
  const primaryRows = Object.fromEntries(dims.map((d) => [d, []]));
  const evidenceSums = Object.fromEntries(dims.map((d) => [d, {}]));
  const evidenceNs = Object.fromEntries(dims.map((d) => [d, {}]));

  for (const id of presentedIds) {
    const item = itemsById[id];
    for (const d of dims) {
      capacity[d] += questionCapacity(item, d);
    }
    const selected = answerByItem[id];
    if (selected) {
      for (const d of dims) {
        const w = selected.behavioral_weights[d] || 0;
        rawSum[d] += w;
        absSelected[d] += Math.abs(w);
      }
    }
    if (!item.primary_dimension) continue;
    const primary = item.primary_dimension;
    if (!contract.isCanonicalDimension(primary)) continue;
    primaryCount[primary]++;
    const signal = selected
      ? selected.behavioral_weights[primary] || 0
      : 0;
    if (signal === 0) {
      zeroPrimary[primary]++;
    } else {
      nonzeroPrimary[primary]++;
    }
    primaryRows[primary].push({
      item_id: id,
      cluster: item.semantic_cluster,
      signal,
    });
    if (selected && selected.evidence_meta) {
      accumulateEvidence(
        evidenceSums[primary],
        evidenceNs[primary],
        selected.evidence_meta,
      );
    }
  }

  const dimensionScores = [];
  for (const d of dims) {
    const cap = capacity[d];
    const raw = rawSum[d];
    const absSig = absSelected[d];
    const pCount = primaryCount[d];
    let normalized = null;
    if (cap > 0) {
      normalized = Math.max(-1, Math.min(1, raw / cap));
    }
    let utilization = null;
    if (cap > 0) {
      utilization = Math.max(0, Math.min(1, absSig / cap));
    }
    let primaryCoverage = null;
    if (pCount > 0) {
      primaryCoverage = nonzeroPrimary[d] / pCount;
    }
    const pairStats = crossContext(primaryRows[d], nearDupIdx);
    const meanDv = meanOrNull(evidenceSums[d], evidenceNs[d], 'diagnostic_value');
    const meanPlaus = meanOrNull(
      evidenceSums[d],
      evidenceNs[d],
      'behavioral_plausibility',
    );
    const meanAmb = meanOrNull(evidenceSums[d], evidenceNs[d], 'ambiguity');
    const meanSd = meanOrNull(
      evidenceSums[d],
      evidenceNs[d],
      'social_desirability',
    );
    const meanObv = meanOrNull(evidenceSums[d], evidenceNs[d], 'obviousness');
    const meanSpr = meanOrNull(
      evidenceSums[d],
      evidenceNs[d],
      'self_presentation_risk',
    );
    const conf = deriveProvisionalConfidence({
      meanDiagnosticValue: meanDv,
      meanBehavioralPlausibility: meanPlaus,
      meanAmbiguity: meanAmb,
      meanSocialDesirability: meanSd,
      meanObviousness: meanObv,
      meanSelfPresentationRisk: meanSpr,
      primarySignalCoverage: primaryCoverage,
      crossContextConsistency: pairStats.consistency,
      crossContextCoverage: pairStats.coverage,
    });
    dimensionScores.push({
      dimension_id: d,
      raw_sum: raw,
      capacity: cap,
      normalized_behavior: normalized,
      primary_question_count: pCount,
      nonzero_primary_signal_count: nonzeroPrimary[d],
      zero_primary_signal_count: zeroPrimary[d],
      primary_signal_coverage: primaryCoverage,
      absolute_selected_signal: absSig,
      signal_utilization: utilization,
      cross_context_consistency: pairStats.consistency,
      eligible_cross_context_pair_count: pairStats.eligible,
      possible_cross_context_pair_count: pairStats.possible,
      cross_context_coverage: pairStats.coverage,
      mean_diagnostic_value: meanDv,
      mean_behavioral_plausibility: meanPlaus,
      mean_ambiguity: meanAmb,
      mean_social_desirability: meanSd,
      mean_obviousness: meanObv,
      mean_self_presentation_risk: meanSpr,
      semantic_clarity: conf.semantic_clarity,
      evidence_quality: conf.evidence_quality,
      primary_observability: conf.primary_observability,
      presentation_pressure: conf.presentation_pressure,
      presentation_adjustment: conf.presentation_adjustment,
      context_component: conf.context_component,
      base_confidence: conf.base_confidence,
      provisional_confidence: conf.provisional_confidence,
      confidence_completeness: conf.confidence_completeness,
      confidence_flags: conf.confidence_flags,
    });
  }

  const summary = buildScoreSummary(dimensionScores);
  return {
    ok: true,
    schema_version: contract.SESSION_SCORE_SCHEMA_VERSION,
    scorer_version: contract.SCORER_VERSION,
    confidence_model_version: contract.CONFIDENCE_MODEL_VERSION,
    bank_version: bank.bank_version,
    selector_version:
      manifest?.selector_version || contract.SELECTOR_VERSION,
    session_id: manifest?.session_id || null,
    dimension_scores: dimensionScores,
    dimensions: dimensionScores,
    summary,
  };
}

function fail(bank, manifest, message) {
  return {
    ok: false,
    dimension_scores: [],
    bank_version: bank.bank_version,
    selector_version: manifest?.selector_version,
    session_id: manifest?.session_id,
    message,
  };
}

module.exports = {
  scoreSession,
  deriveProvisionalConfidence,
  buildScoreSummary,
};
