# Frequency Pilot TR v1 — Construct Separation Report

**Source:** `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json`
**Contract:** `docs/core_engine/frequency_dimension_contract_v1.md`

## EQ / Frequency module separation

Frequency pilot items must write `dimension_deltas` **only** to the six canonical Frequency dimensions.
EQ dimensions (`empathy`, `emotional_openness`, etc.) must never appear in Frequency item evidence vectors.

- EQ dimension deltas found in bank: **0** — **PASS (none)**
- Forbidden `emotional_openness` / `emotionalOpenness` strings in bank blob: **0** — **PASS (none)**

## `disclosure_pace` vs EQ `emotional_openness`

| Construct | Module | Meaning |
|---|---|---|
| `disclosure_pace` | Frequency | Preferred **speed/sequencing** of sharing personal material |
| `emotional_openness` | EQ | Willingness to **disclose feelings/needs** as an EQ construct |

Legacy Frequency alias `emotionalOpenness` maps conceptually to **`disclosure_pace` only**.
It must **never** write EQ `emotional_openness` deltas or reuse EQ disclosure wording as a proxy.

- Primary `disclosure_pace` items in pilot: **8**
- Cross-dimension deltas on disclosure items target Frequency dims only (see evidence mapping).
- Expert review must confirm prompts measure **timing/sequencing preference**, not EQ affective openness skill.

## Evidence-strength independence

- Unique `evidence_strength` values across bank: `[0.5, 0.55, 0.6, 0.65, 0.7]`
- Flat 0.72 default: **PASS (not flat 0.72)**
- Options where strength equals |primary delta|: **0** — **PASS**

## Per-dimension contamination guardrails

### `depth_preference`

- **Intended construct:** Preference for reflective/substantive vs lighter/practical interaction depth.
- **Nearest competing construct:** intelligence / EQ empathy
- **Must not absorb:** IQ verbal reasoning or EQ empathy without preference-for-depth framing.
- **Primary item IDs (sample / highest review attention):** `frequency_tr_v1_depth_preference_001`, `frequency_tr_v1_depth_preference_002`, `frequency_tr_v1_depth_preference_003`
- **All primary IDs:** `frequency_tr_v1_depth_preference_001`, `frequency_tr_v1_depth_preference_002`, `frequency_tr_v1_depth_preference_003`, `frequency_tr_v1_depth_preference_004`, `frequency_tr_v1_depth_preference_005`, `frequency_tr_v1_depth_preference_006`, `frequency_tr_v1_depth_preference_007`, `frequency_tr_v1_depth_preference_008`, `frequency_tr_v1_depth_preference_009`
- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.
- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.

### `communication_pace`

- **Intended construct:** Preferred cadence, timing, and spacing of communication.
- **Nearest competing construct:** EQ assertiveness / affection assumptions
- **Must not absorb:** Interest, affection, reliability, or assertiveness.
- **Primary item IDs (sample / highest review attention):** `frequency_tr_v1_communication_pace_001`, `frequency_tr_v1_communication_pace_002`, `frequency_tr_v1_communication_pace_003`
- **All primary IDs:** `frequency_tr_v1_communication_pace_001`, `frequency_tr_v1_communication_pace_002`, `frequency_tr_v1_communication_pace_003`, `frequency_tr_v1_communication_pace_004`, `frequency_tr_v1_communication_pace_005`, `frequency_tr_v1_communication_pace_006`, `frequency_tr_v1_communication_pace_007`, `frequency_tr_v1_communication_pace_008`, `frequency_tr_v1_communication_pace_009`
- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.
- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.

### `social_energy`

- **Intended construct:** Preferred amount, intensity, and recovery space for social interaction.
- **Nearest competing construct:** social skill / popularity
- **Must not absorb:** Popularity, social skill, or EQ social_awareness.
- **Primary item IDs (sample / highest review attention):** `frequency_tr_v1_social_energy_001`, `frequency_tr_v1_social_energy_002`, `frequency_tr_v1_social_energy_003`
- **All primary IDs:** `frequency_tr_v1_social_energy_001`, `frequency_tr_v1_social_energy_002`, `frequency_tr_v1_social_energy_003`, `frequency_tr_v1_social_energy_004`, `frequency_tr_v1_social_energy_005`, `frequency_tr_v1_social_energy_006`, `frequency_tr_v1_social_energy_007`, `frequency_tr_v1_social_energy_008`
- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.
- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.

### `spontaneity`

- **Intended construct:** Preference for unplanned choices, flexibility, and novelty in shared activities.
- **Nearest competing construct:** impulsivity / irresponsibility
- **Must not absorb:** Impulsivity, irresponsibility, or EQ emotion_regulation.
- **Primary item IDs (sample / highest review attention):** `frequency_tr_v1_spontaneity_001`, `frequency_tr_v1_spontaneity_002`, `frequency_tr_v1_spontaneity_003`
- **All primary IDs:** `frequency_tr_v1_spontaneity_001`, `frequency_tr_v1_spontaneity_002`, `frequency_tr_v1_spontaneity_003`, `frequency_tr_v1_spontaneity_004`, `frequency_tr_v1_spontaneity_005`, `frequency_tr_v1_spontaneity_006`, `frequency_tr_v1_spontaneity_007`, `frequency_tr_v1_spontaneity_008`
- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.
- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.

### `stability`

- **Intended construct:** Preference for continuity, predictable routines, and consistent relational rhythms.
- **Nearest competing construct:** emotional stability / loyalty
- **Must not absorb:** Emotional stability, loyalty, or commitment quality.
- **Primary item IDs (sample / highest review attention):** `frequency_tr_v1_stability_001`, `frequency_tr_v1_stability_002`, `frequency_tr_v1_stability_003`
- **All primary IDs:** `frequency_tr_v1_stability_001`, `frequency_tr_v1_stability_002`, `frequency_tr_v1_stability_003`, `frequency_tr_v1_stability_004`, `frequency_tr_v1_stability_005`, `frequency_tr_v1_stability_006`, `frequency_tr_v1_stability_007`, `frequency_tr_v1_stability_008`
- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.
- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.

### `disclosure_pace`

- **Intended construct:** Preferred speed and sequencing for sharing personal or emotionally significant information.
- **Nearest competing construct:** EQ emotional_openness / honesty
- **Must not absorb:** EQ emotional_openness, honesty, trustworthiness, or intimacy capacity.
- **Primary item IDs (sample / highest review attention):** `frequency_tr_v1_disclosure_pace_001`, `frequency_tr_v1_disclosure_pace_002`, `frequency_tr_v1_disclosure_pace_003`
- **All primary IDs:** `frequency_tr_v1_disclosure_pace_001`, `frequency_tr_v1_disclosure_pace_002`, `frequency_tr_v1_disclosure_pace_003`, `frequency_tr_v1_disclosure_pace_004`, `frequency_tr_v1_disclosure_pace_005`, `frequency_tr_v1_disclosure_pace_006`, `frequency_tr_v1_disclosure_pace_007`, `frequency_tr_v1_disclosure_pace_008`
- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.
- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.

## Readiness

**Automated separation checks:** **PASS**

Human psychological review must still confirm scenario wording does not collapse Frequency preferences into EQ ability constructs.