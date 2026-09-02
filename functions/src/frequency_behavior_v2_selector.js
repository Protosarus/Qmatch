'use strict';

const contract = require('./frequency_behavior_v2_contract');
const { FrequencyBehaviorV2Rng } = require('./frequency_behavior_v2_rng');

function isSelectable(item, review) {
  if (!item.primary_dimension) return false;
  if (!contract.isCanonicalDimension(item.primary_dimension)) return false;
  if (review) {
    if (review.selector_eligible !== true) return false;
    if (review.rewrite_pending === true) return false;
    if (review.drop_from_selectable === true) return false;
    if (review.processing_style_present === true) return false;
    if (review.primary_review_pending === true) return false;
    const unresolved = review.unresolved_dimension_labels;
    if (Array.isArray(unresolved) && unresolved.length > 0) return false;
    const status = review.review_status != null ? String(review.review_status) : null;
    if (
      status === 'manual_review' ||
      status === 'rewrite_pending' ||
      status === 'dropped_from_selectable'
    ) {
      return false;
    }
  }
  const optionIds = item.authored_option_ids || [];
  for (const oid of optionIds) {
    const opt = item.options[oid];
    if (!opt || !opt.behavioral_weights || Object.keys(opt.behavioral_weights).length === 0) {
      return false;
    }
  }
  return optionIds.length > 0;
}

function candidateRank({
  selectorVersion,
  bankVersion,
  sessionSeed,
  dimension,
  questionId,
}) {
  return FrequencyBehaviorV2Rng.fromParts([
    selectorVersion,
    bankVersion,
    sessionSeed,
    dimension,
    questionId,
  ]).nextUint32();
}

function nearDupIndex(clusters, eligibleIds) {
  const eligible = new Set(eligibleIds);
  const out = {};
  for (let i = 0; i < clusters.length; i++) {
    const members = clusters[i].filter((id) => eligible.has(id));
    if (members.length < 2) continue;
    for (const id of members) {
      if (out[id] === undefined) out[id] = i;
    }
  }
  return out;
}

function contextFamily(item) {
  if (!item.context || item.context.length === 0) return 'unclassified';
  return item.context[0];
}

function thematicTag(item) {
  const text = `${item.prompt || ''} ${item.semantic_cluster || ''}`.toLowerCase();
  if (/aile|anne|baba|kayın|çocuk|cocuk/.test(text)) return 'family';
  if (/para|fatura|hesap|ödeme|odeme|borç|borc/.test(text)) return 'payment';
  if (
    (item.context || []).includes('conflict') ||
    String(item.semantic_cluster || '').includes('conflict')
  ) {
    return 'conflict';
  }
  return null;
}

function keyGreater(a, b) {
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return a[i] > b[i];
  }
  return false;
}

function neighborDimOk(neighbor, extra) {
  if (!neighbor) return true;
  return neighbor.primary_dimension !== extra.primary_dimension;
}

function neighborContextOk(neighbor, extra) {
  if (!neighbor) return true;
  return contextFamily(neighbor) !== contextFamily(extra);
}

function neighborClusterOk(neighbor, extra) {
  if (!neighbor) return true;
  return neighbor.semantic_cluster !== extra.semantic_cluster;
}

function runLengthIfInsert(sequence, pos, extra) {
  const dim = extra.primary_dimension;
  let run = 1;
  for (let i = pos - 1; i >= 0; i--) {
    if (sequence[i].primary_dimension !== dim) break;
    run++;
  }
  for (let i = pos; i < sequence.length; i++) {
    if (sequence[i].primary_dimension !== dim) break;
    run++;
  }
  return run;
}

function insertExtra(sequence, extra) {
  let bestKey = null;
  let bestPos = -1;
  for (let pos = 0; pos <= sequence.length; pos++) {
    if (
      runLengthIfInsert(sequence, pos, extra) >
      contract.MAX_CONSECUTIVE_SAME_PRIMARY
    ) {
      continue;
    }
    const prev = pos === 0 ? null : sequence[pos - 1];
    const next = pos === sequence.length ? null : sequence[pos];
    const key = [
      neighborDimOk(prev, extra) ? 1 : 0,
      neighborDimOk(next, extra) ? 1 : 0,
      neighborContextOk(prev, extra) ? 1 : 0,
      neighborContextOk(next, extra) ? 1 : 0,
      neighborClusterOk(prev, extra) ? 1 : 0,
      neighborClusterOk(next, extra) ? 1 : 0,
    ];
    if (bestKey === null || keyGreater(key, bestKey)) {
      bestKey = key;
      bestPos = pos;
    }
  }
  if (bestPos < 0) {
    throw new Error(`no_valid_extra_insert_pos:${extra.item_id}`);
  }
  sequence.splice(bestPos, 0, extra);
}

function similarFamily(a, b) {
  if (a.semantic_cluster === b.semantic_cluster) return true;
  const ta = thematicTag(a);
  const tb = thematicTag(b);
  return ta != null && ta === tb;
}

function swap(sequence, i, j) {
  const tmp = sequence[i];
  sequence[i] = sequence[j];
  sequence[j] = tmp;
}

function consecutivePrimaryOk(sequence) {
  let run = 1;
  for (let i = 1; i < sequence.length; i++) {
    if (sequence[i].primary_dimension === sequence[i - 1].primary_dimension) {
      run++;
      if (run > contract.MAX_CONSECUTIVE_SAME_PRIMARY) return false;
    } else {
      run = 1;
    }
  }
  return true;
}

function softenAdjacentFamilies(sequence) {
  for (let i = 1; i < sequence.length; i++) {
    if (!similarFamily(sequence[i - 1], sequence[i])) continue;
    for (let j = i + 1; j < sequence.length; j++) {
      swap(sequence, i, j);
      const improved =
        consecutivePrimaryOk(sequence) &&
        !similarFamily(sequence[i - 1], sequence[i]);
      if (improved) break;
      swap(sequence, i, j);
    }
  }
}

function composeManifest({
  bank,
  sessionSeed,
  sessionId,
  createdAt,
  excludeUnresolvedReview = true,
}) {
  const selectorVersion = contract.SELECTOR_VERSION;
  const bankVersion = bank.bank_version;
  const itemsById = bank.items_by_id;
  const reviewByItemId = bank.review_by_item_id || {};
  const nearDuplicateClusters = bank.near_duplicate_clusters || [];

  const eligible = [];
  for (const item of bank.items) {
    const review = reviewByItemId[item.item_id];
    if (excludeUnresolvedReview && !isSelectable(item, review)) continue;
    eligible.push(item);
  }

  const eligibleIds = eligible.map((i) => i.item_id);
  const ndIndex = nearDupIndex(nearDuplicateClusters, eligibleIds);
  const usedNearDup = new Set();

  const extraRng = FrequencyBehaviorV2Rng.forStream({
    selectorVersion,
    bankVersion,
    sessionSeed,
    stream: 'extra_slots',
  });
  const extraOrder = extraRng.shuffledCopy([...contract.CANONICAL_DIMENSIONS]);
  const extraDims = new Set([extraOrder[0], extraOrder[1]]);

  const pickedByDim = {};
  for (const dim of contract.CANONICAL_DIMENSIONS) {
    const quota = extraDims.has(dim)
      ? contract.SESSION_BASE_PER_DIMENSION + 1
      : contract.SESSION_BASE_PER_DIMENSION;
    const ranked = eligible.filter((item) => item.primary_dimension === dim);
    ranked.sort((a, b) => {
      const ra = candidateRank({
        selectorVersion,
        bankVersion,
        sessionSeed,
        dimension: dim,
        questionId: a.item_id,
      });
      const rb = candidateRank({
        selectorVersion,
        bankVersion,
        sessionSeed,
        dimension: dim,
        questionId: b.item_id,
      });
      if (ra !== rb) return ra - rb;
      return a.item_id < b.item_id ? -1 : a.item_id > b.item_id ? 1 : 0;
    });
    if (ranked.length < quota) {
      throw new Error(`insufficient_candidates:${dim} have=${ranked.length} need=${quota}`);
    }

    const picked = [];
    const clusterCounts = {};
    const pickedSet = new Set();

    function nearDupBlocked(c) {
      const nd = ndIndex[c.item_id];
      return nd != null && usedNearDup.has(nd);
    }

    function absorb(c) {
      pickedSet.add(c.item_id);
      picked.push(c);
      clusterCounts[c.semantic_cluster] = (clusterCounts[c.semantic_cluster] || 0) + 1;
      const nd = ndIndex[c.item_id];
      if (nd != null) usedNearDup.add(nd);
    }

    while (picked.length < quota) {
      const remaining = ranked.filter(
        (c) => !pickedSet.has(c.item_id) && !nearDupBlocked(c),
      );
      if (remaining.length === 0) {
        throw new Error(`underfilled:${dim} have=${picked.length} need=${quota}`);
      }
      let chosen = remaining[0];
      if ((clusterCounts[chosen.semantic_cluster] || 0) > 0) {
        const altLimit =
          contract.SOFT_CLUSTER_LOOKAHEAD < remaining.length - 1
            ? contract.SOFT_CLUSTER_LOOKAHEAD
            : remaining.length - 1;
        for (let i = 1; i <= altLimit; i++) {
          const alt = remaining[i];
          if ((clusterCounts[alt.semantic_cluster] || 0) === 0) {
            chosen = alt;
            break;
          }
        }
      }
      absorb(chosen);
    }
    pickedByDim[dim] = picked;
  }

  const queues = {};
  for (const dim of contract.CANONICAL_DIMENSIONS) {
    const qRng = FrequencyBehaviorV2Rng.forStream({
      selectorVersion,
      bankVersion,
      sessionSeed,
      stream: `queue|${dim}`,
    });
    queues[dim] = qRng.shuffledCopy(pickedByDim[dim]);
  }

  const interleaveRng = FrequencyBehaviorV2Rng.forStream({
    selectorVersion,
    bankVersion,
    sessionSeed,
    stream: 'interleave_order',
  });
  const dimOrder = interleaveRng.shuffledCopy([...contract.CANONICAL_DIMENSIONS]);

  const sequence = [];
  for (let round = 0; round < contract.SESSION_BASE_PER_DIMENSION; round++) {
    for (const dim of dimOrder) {
      sequence.push(queues[dim].shift());
    }
  }
  const extras = [];
  for (const dim of dimOrder) {
    extras.push(...queues[dim]);
  }
  for (const extra of extras) {
    insertExtra(sequence, extra);
  }
  softenAdjacentFamilies(sequence);

  if (sequence.length !== contract.SESSION_ITEM_COUNT) {
    throw new Error(`session_length_${sequence.length}`);
  }
  if (!consecutivePrimaryOk(sequence)) {
    throw new Error('consecutive_primary_violation');
  }

  const derivedId =
    sessionId ||
    `frequency_v2_${FrequencyBehaviorV2Rng.fnv1a32(
      `${selectorVersion}|${bankVersion}|${sessionSeed}`,
    )
      .toString(16)
      .padStart(8, '0')}`;

  const questions = [];
  for (let i = 0; i < sequence.length; i++) {
    const item = sequence[i];
    const optRng = FrequencyBehaviorV2Rng.forStream({
      selectorVersion,
      bankVersion,
      sessionSeed,
      stream: `options|${item.item_id}`,
    });
    const authored = item.authored_option_ids.slice();
    const presented = optRng.shuffledCopy(authored);
    questions.push({
      question_id: item.item_id,
      primary_dimension: item.primary_dimension,
      presentation_index: i,
      presented_option_order: presented,
    });
  }

  return {
    schema_version: contract.SESSION_MANIFEST_SCHEMA_VERSION,
    selector_version: selectorVersion,
    bank_version: bankVersion,
    session_id: derivedId,
    session_seed: sessionSeed,
    locale: bank.locale,
    created_at: createdAt || null,
    question_ids: questions.map((q) => q.question_id),
    questions,
    items_by_id: itemsById,
  };
}

module.exports = {
  composeManifest,
  isSelectable,
  thematicTag,
  contextFamily,
};
