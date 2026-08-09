# Core Method v2 Explanation Input Audit v1

Phase: **P2B-5**. Offline audit only. A mathematical contribution is **not** a
causal explanation of relationship success.

## Structural (P2B-1)

| Field | Object | Safe? | Score vs diagnostic | Directional? | Confidence | Missing | Prohibited interpretation | Usage |
|-------|--------|-------|---------------------|--------------|------------|---------|---------------------------|-------|
| similarityScore | StructuralModuleSimilarityResult | yes | score-producing (source) | no | evidenceConfidence | null when insufficient | intelligence superiority | module-level status / coverage signals |
| distanceSquared | same | yes | diagnostic | no | — | null | maturity/fitness | optional magnitude context only |
| absoluteDifference | StructuralDimensionComparison | yes | diagnostic magnitude | no | pairConfidence | excluded dims | emotional health | closeness / difference signals |
| pairConfidence | same | yes | diagnostic | no | itself | — | — | confidence band / low-confidence variants |
| effectiveWeight | same | yes | diagnostic | no | already includes pairQ | — | — | normalized weight for salience |
| baseWeight | same | yes | diagnostic | no | — | — | — | audit only |
| coverage | module unweighted/weighted | yes | diagnostic | no | — | low coverage | — | partial / high coverage signals |
| excludedDimensions | module | yes | diagnostic | no | — | reason codes | — | evidence-limitation |

**Salience note:** `effectiveWeight = baseWeight × pairConfidence`, so explanation
salience uses `normalizedEffectiveWeight × magnitude` without re-multiplying
pair confidence.

## Partner preference (P2B-2)

| Field | Object | Safe? | Usage |
|-------|--------|-------|-------|
| rawFitScore / mutualRawFitScore | directional / mutual | yes | overall preference status only; not re-scored |
| rawDimensionFit | PreferenceDimensionFit | yes | strong/weak fit magnitude |
| importance, flexibility | same | yes | already in effectiveWeight; do not recompute |
| evidenceConfidence | same | yes | confidence band |
| open / unavailable exclusions | directional exclusions | yes | distinct open vs unavailable signals |
| directionalAsymmetry | mutual | yes | diagnostic asymmetry only |

## Relationship values (P2B-3)

| Field | Object | Safe? | Usage |
|-------|--------|-------|-------|
| adjustedDirectionalFit | RelationshipValueFieldComparison | yes | aligned / difference magnitude |
| baseCompatibility | same | yes | audit reference |
| ownerImportance | same | yes | in effectiveWeight |
| mutualRawValueFitScore | mutual | yes | status only |
| directionalAsymmetry | mutual | yes | diagnostic |
| exclusions (pending/private/missing) | directional | yes | distinct evidence codes; no raw private values |

## Hard constraints (P2B-3)

| Field | Safe? | Usage |
|-------|-------|-------|
| aggregateOutcome | yes | blocking / cautionary status |
| failed/unknown/passed/notApplicable IDs | yes | categorical signals; no numeric score |
| counterpart values | **restricted** | never copy into localization params when private/denied |

## Soft conflicts (P2B-3)

| Field | Safe? | Usage |
|-------|-------|-------|
| mutualSeverity / severityBand | yes | magnitude only; **no penalty** |
| directional severities | yes | directional soft signals |
| fieldId | yes | localization parameter |

## Aggregation (P2B-4)

| Field | Safe? | Usage |
|-------|-------|-------|
| rawScore / confidenceAdjustedScore | yes | confidence-adjustment explanation only |
| overallEvidenceConfidence / M_available / Q_mean | yes | shrink parameters |
| componentContributions | yes | missing / low-confidence / contribution audit refs |
| evaluationStatus | yes | overall_status |
| softConflictSummary / asymmetrySummary | yes | diagnostics |
| publishable / rankingEligible / productionApproved | yes | production_limitation |

## Explicit non-claims

- Do not treat contribution weight as causal importance for relationship success.
- Do not invent preferences, constraints, or private values.
- Do not use persona IDs or Frequency types.
