# Current Assessment Bank Audit v1

**Status:** offline deterministic rule audit (P2A-1)
**Generated_at_logic:** content-hash stable; no wall-clock in body
**Important:** Automated checks do **not** replace expert manual review.
**Banks were not modified.**

Audit content version: `assessment_bank_audit_v1`

## IQ

| Metric | Value |
|---|---:|
| Total sets | 50 |
| Total items | 500 |
| Unique question ids | 500 |
| Near-duplicate groups | 8 |
| Near-duplicate items | 258 |
| Missing-metadata signals | 500 |
| KEEP | 0 |
| KEEP_WITH_METADATA | 242 |
| REWRITE | 0 |
| RETIRE | 0 |
| MANUAL_REVIEW | 258 |
| Dimension-mappable | 0 |
| Unmappable | 500 |
| Social-answer risk | 0 |
| IQ answer/logic risk signals | 500 |
| Localization issues | 0 |
| Security/exposure issues | 0 |

**Recommended next action:** Selective rewrite with manual construct review

### Canonical dimension distribution (where mapped)

_None mappable with current metadata._

## EQ

| Metric | Value |
|---|---:|
| Total sets | 50 |
| Total items | 500 |
| Unique question ids | 500 |
| Near-duplicate groups | 0 |
| Near-duplicate items | 0 |
| Missing-metadata signals | 500 |
| KEEP | 0 |
| KEEP_WITH_METADATA | 0 |
| REWRITE | 500 |
| RETIRE | 0 |
| MANUAL_REVIEW | 0 |
| Dimension-mappable | 0 |
| Unmappable | 500 |
| Social-answer risk | 500 |
| IQ answer/logic risk signals | 0 |
| Localization issues | 0 |
| Security/exposure issues | 0 |

**Recommended next action:** Author schema-v3 replacements; do not promote current items to active

### Canonical dimension distribution (where mapped)

_None mappable with current metadata._

## FREQUENCY

| Metric | Value |
|---|---:|
| Total sets | 50 |
| Total items | 600 |
| Unique question ids | 600 |
| Near-duplicate groups | 0 |
| Near-duplicate items | 0 |
| Missing-metadata signals | 600 |
| KEEP | 0 |
| KEEP_WITH_METADATA | 600 |
| REWRITE | 0 |
| RETIRE | 0 |
| MANUAL_REVIEW | 0 |
| Dimension-mappable | 600 |
| Unmappable | 0 |
| Social-answer risk | 0 |
| IQ answer/logic risk signals | 0 |
| Localization issues | 0 |
| Security/exposure issues | 0 |

**Recommended next action:** Attach canonical metadata / migrate aliases before reuse

### Canonical dimension distribution (where mapped)

| Dimension | Count |
|---|---:|
| `communication_pace` | 100 |
| `depth_preference` | 100 |
| `disclosure_pace` | 100 |
| `social_energy` | 100 |
| `spontaneity` | 100 |
| `stability` | 100 |

## LEGACY_FLAT

| Metric | Value |
|---|---:|
| Total sets | 1 |
| Total items | 22 |
| Unique question ids | 22 |
| Near-duplicate groups | 0 |
| Near-duplicate items | 0 |
| Missing-metadata signals | 22 |
| KEEP | 0 |
| KEEP_WITH_METADATA | 0 |
| REWRITE | 0 |
| RETIRE | 22 |
| MANUAL_REVIEW | 0 |
| Dimension-mappable | 0 |
| Unmappable | 22 |
| Social-answer risk | 12 |
| IQ answer/logic risk signals | 10 |
| Localization issues | 0 |
| Security/exposure issues | 0 |

**Recommended next action:** Selective rewrite with manual construct review

### Canonical dimension distribution (where mapped)

_None mappable with current metadata._

## Totals across audited sources

| Classification | Count |
|---|---:|
| KEEP | 0 |
| KEEP_WITH_METADATA | 842 |
| REWRITE | 500 |
| RETIRE | 22 |
| MANUAL_REVIEW | 258 |

## Coverage findings

- IQ items lack canonical domain metadata → unmappable to 4 IQ domains without rewrite/enrichment.
- EQ items use `correctAnswer` and lack canonical EQ dimensions → treat as REWRITE before persona handoff.
- Frequency items map 1:1 via legacy aliases to all 6 canonical Frequency dims (100 each in sets), but need schema-v3 Likert evidence deltas.
- Legacy flat IQ/EQ lists are RETIRE candidates (superseded by assessment_sets).

## Uncertainty

MANUAL_REVIEW and heuristic social-risk flags are uncertain. Expert construct review is required before any item becomes `active`.

