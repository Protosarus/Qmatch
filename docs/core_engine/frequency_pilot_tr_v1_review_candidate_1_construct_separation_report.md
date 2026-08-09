# Frequency Pilot TR v1 Review Candidate 1 — Construct Separation Report

**Source:** `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json`  
**Parent reference:** `docs/core_engine/frequency_pilot_tr_v1_construct_separation_report.md`  
**Dimension contract:** `docs/core_engine/frequency_dimension_contract_v1.md`  
**Red-team phase:** P2A-2D-2  

## EQ / Frequency module separation

Frequency candidate items must write `dimension_deltas` **only** to the six canonical Frequency dimensions.
EQ dimensions must never appear in Frequency evidence vectors.

- EQ dimension deltas found in candidate bank: **0** — **PASS**
- Forbidden `emotional_openness` / `emotionalOpenness` strings: **0** — **PASS**
- No IQ dimensions written — **PASS**
- No Frequency type / persona / compatibility fields — **PASS**

## Critical construct pairs

### `disclosure_pace` vs EQ `emotional_openness`

| Construct | Module | Meaning |
|---|---|---|
| `disclosure_pace` | Frequency | Preferred **speed/sequencing** of sharing personal material |
| `emotional_openness` | EQ | Willingness to disclose feelings/needs as an EQ construct |

Legacy Frequency alias `emotionalOpenness` maps conceptually to **`disclosure_pace` only**.  
Candidate retains Frequency-only framing; no EQ writes. Expert wording review still pending.

### `communication_pace` vs EQ assertiveness / affection assumptions

Measures cadence and spacing preference only. Must not mean interest, affection, reliability, or assertiveness.

### Other separations retained

| Frequency dim | Must not absorb |
|---|---|
| `depth_preference` | Intelligence, verbal ability, EQ empathy |
| `social_energy` | Social skill, popularity |
| `spontaneity` | Impulsivity, irresponsibility |
| `stability` | Emotional stability, loyalty, commitment quality |

## Per-dimension contamination guardrails

### `depth_preference`

- **Intended:** reflective/substantive vs lighter/practical interaction preference
- **Nearest competing:** intelligence / EQ empathy
- **Primary IDs:** `frequency_tr_v1_depth_preference_001` … `_009`
- **Mitigation:** Frequency-only deltas; non-moral poles; length-balanced options in candidate
- **Residual:** expert wording review that depth ≠ ability

### `communication_pace`

- **Intended:** reply cadence / continuity vs space
- **Nearest competing:** interest / affection / assertiveness
- **Primary IDs:** `frequency_tr_v1_communication_pace_001` … `_009`
- **Mitigation:** trade-off secondaries; pole-neutral wording
- **Residual:** users may still moralize reply speed; interviews pending

### `social_energy`

- **Intended:** interaction intensity and recovery preference
- **Nearest competing:** social skill / popularity
- **Primary IDs:** `frequency_tr_v1_social_energy_001` … `_008`
- **Mitigation:** recovery-space trade-offs retained; length fix on `_003`
- **Residual:** low energy must not read as incompetence

### `spontaneity`

- **Intended:** planning flexibility / novelty preference
- **Nearest competing:** impulsivity / irresponsibility
- **Primary IDs:** `frequency_tr_v1_spontaneity_001` … `_008`
- **Mitigation:** planning options framed as preference, not virtue
- **Residual:** expert review for “careless” leakage

### `stability`

- **Intended:** routine/continuity preference
- **Nearest competing:** emotional stability / loyalty
- **Primary IDs:** `frequency_tr_v1_stability_001` … `_008`
- **Mitigation:** variable-rhythm options remain non-defective
- **Residual:** commitment-quality contamination risk

### `disclosure_pace`

- **Intended:** disclosure timing/sequencing preference
- **Nearest competing:** EQ emotional_openness / honesty
- **Primary IDs:** `frequency_tr_v1_disclosure_pace_001` … `_008`
- **Mitigation:** no EQ deltas; gradual disclosure not framed as secrecy
- **Residual:** high human-review priority

## Evidence-strength independence

- Allowed band `{0.50, 0.55, 0.60, 0.65, 0.70}` maintained
- Flat 0.72: **PASS (none)**
- Options where strength equals `|primary|`: **0** — **PASS**

## Reverse-pair construct note

Reverse pairs share dimension and **behaviorally keyed** primary vectors (same-sign for same trait pole).  
Declared mode: `behavioral_correspondence` under `reverse_pair_consistency_contract_v1.md`.  
TraitScoringService reverse RVI compatibility: **PASS**.  
RVI must never alter trait direction; candidate preserves trait-correct deltas.

## Readiness

**Automated separation checks:** **PASS**  
**Expert psychological review:** **pending**  
**Cognitive interviews:** **pending**
