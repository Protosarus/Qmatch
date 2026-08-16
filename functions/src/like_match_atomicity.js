/**
 * Like → match atomicity (`like_match_atomicity_v1` +
 * `match_create_lifecycle_v1` + `stale_user_match_eligibility_v1`).
 *
 * Pure helpers — no I/O. Mirrors the Dart gates.
 */

'use strict';

const { hasValidPhoto } = require('./discover_eligibility');

const DECISION = Object.freeze({
  createNew: 'createNew',
  idempotentActiveSuccess: 'idempotentActiveSuccess',
  refuseUnmatchedExists: 'refuseUnmatchedExists',
  refuseBlockedExists: 'refuseBlockedExists',
  refuseExistingNonActive: 'refuseExistingNonActive',
  refuseBlockEitherDirection: 'refuseBlockEitherDirection',
  refuseNonMutualLike: 'refuseNonMutualLike',
  refuseInvalidLiveUser: 'refuseInvalidLiveUser',
});

const OUTCOME = Object.freeze({
  createdNewMatch: 'created_new_match',
  existingActiveMatch: 'existing_active_match',
  noMatch: 'no_match',
});

function isLikeDirection(direction) {
  return direction === 'like';
}

function isValidLiveUser(exists, data) {
  if (!exists || !data || typeof data !== 'object') return false;
  if (data.discover_eligible !== true) return false;

  const active = typeof data.active === 'boolean' ? data.active : true;
  const profileCompleted = data.profile_completed === true;
  const testCompleted = data.test_completed === true;
  const assessmentFlowCompleted = data.assessment_flow_completed === true;
  if (!active) return false;
  if (!profileCompleted) return false;
  if (!hasValidPhoto(data)) return false;
  return testCompleted || assessmentFlowCompleted;
}

function decideMatchCreate({
  matchExists,
  matchState,
  viewerBlockedCandidate,
  candidateBlockedViewer,
  viewerLikesCandidate,
  candidateLikesViewer,
}) {
  if (matchExists) {
    if (matchState === 'active') return DECISION.idempotentActiveSuccess;
    if (matchState === 'unmatched') return DECISION.refuseUnmatchedExists;
    if (matchState === 'blocked') return DECISION.refuseBlockedExists;
    return DECISION.refuseExistingNonActive;
  }
  if (viewerBlockedCandidate || candidateBlockedViewer) {
    return DECISION.refuseBlockEitherDirection;
  }
  if (!viewerLikesCandidate || !candidateLikesViewer) {
    return DECISION.refuseNonMutualLike;
  }
  return DECISION.createNew;
}

function planLike({
  matchExists,
  matchState,
  viewerBlockedCandidate,
  candidateBlockedViewer,
  viewerLikesCandidatePending,
  candidateLikesViewer,
  viewerLiveEligible,
  targetLiveEligible,
}) {
  if (!viewerLiveEligible || !targetLiveEligible) {
    const alreadyActive = matchExists && matchState === 'active';
    return {
      persistOwnLike: false,
      matchDecision: alreadyActive
        ? DECISION.idempotentActiveSuccess
        : DECISION.refuseInvalidLiveUser,
    };
  }

  const matchDecision = decideMatchCreate({
    matchExists,
    matchState,
    viewerBlockedCandidate,
    candidateBlockedViewer,
    viewerLikesCandidate: viewerLikesCandidatePending,
    candidateLikesViewer,
  });
  return {
    persistOwnLike: matchDecision !== DECISION.refuseBlockEitherDirection,
    matchDecision,
  };
}

function writeMatchArtifacts(decision) {
  return decision === DECISION.createNew;
}

function outcomeFromDecision(decision) {
  if (decision === DECISION.createNew) return OUTCOME.createdNewMatch;
  if (decision === DECISION.idempotentActiveSuccess) {
    return OUTCOME.existingActiveMatch;
  }
  return OUTCOME.noMatch;
}

function sortedPair(a, b) {
  return a <= b ? [a, b] : [b, a];
}

function deterministicMatchId(a, b) {
  const [userA, userB] = sortedPair(a, b);
  return `${userA}_${userB}`;
}

module.exports = {
  DECISION,
  OUTCOME,
  isLikeDirection,
  isValidLiveUser,
  decideMatchCreate,
  planLike,
  writeMatchArtifacts,
  outcomeFromDecision,
  sortedPair,
  deterministicMatchId,
};
