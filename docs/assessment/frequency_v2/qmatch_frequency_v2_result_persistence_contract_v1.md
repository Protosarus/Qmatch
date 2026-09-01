# Frequency V2 — Result Persistence Contract v1

**Status:** contract freeze (Phase 7B) — design only, not implemented
**Schema version:** `qmatch_frequency_behavior_v2_result_v1`
**Firestore path:** `users/{uid}/assessments/frequency_v2`
**Runtime:** dormant — `runtime_selectable` remains `false`

This document freezes the canonical persisted-result contract **before** implementing `finalizeFrequencyV2`. It defines what a future **server-authoritative** finalizer will write. It does **not** implement Cloud Functions, Flutter runtime, Firestore rules, or activation behavior.

---

## 1. Goals and non-goals

### Goals

1. **Exact session reproducibility** — enough information to re-derive the same 50-item presentation and rescoring from versioned server catalog + answers.
2. **Future server-authoritative scoring** — client-submitted scores are never trusted; server derives authoritative 12D output.
3. **Version pinning** — bank, selector, scorer, confidence, and locale/translation pins prevent silent reinterpretation.
4. **Private per-user storage** — single-user assessment artifact only; no public projection.
5. **V1/V2 coexistence** — separate path and schema from live Frequency V1.
6. **Rollback** — V2 can remain dormant or be abandoned without touching V1 artifacts.
7. **Future pair-fit consumption** — persist per-user primitives pair-fit needs; exclude A/B pair outputs from this document.
8. **No V1 matching leakage** — no writes to `canonical_v1` Frequency slots, legacy mirrors, or 6D consumers.

### Non-goals (Phase 7B)

- Implement `finalizeFrequencyV2` or any Cloud Function.
- Wire Flutter runtime, session UI, or routing.
- Modify `firestore.rules` (policy is documented for Phase 7C/7D).
- Activate Frequency V2 (`runtime_selectable` stays `false`).
- Modify Frequency V1, matching, or persona pipelines.
- Define a 12D → 6D adapter.
- Define retake policy, completion mirrors (`test_completed`, `frequency_completed`, `discover_eligible`), or eligibility side effects.
- Include dormant telemetry in the canonical result.
- Persist pair-relation, pair-fit, or 24D density matrices in the user result.

### Mandatory assertions

- **V1** `users/{uid}/assessments/frequency` remains untouched by V2.
- **V2** uses a separate persistence path: `users/{uid}/assessments/frequency_v2`.
- **V2 does not write** `users/{uid}/profiles/canonical_v1`.
- **There is no 12D → 6D adapter.**
- **V2 does not write** legacy Frequency mirrors on `users/{uid}` (`frequency_vector`, `frequency_type`, `frequency_tags`, `frequency_score`, `frequency_status`).
- **V2 result is private** — not projected to `public_profiles`.
- **Pair-fit data is not stored** in the single-user result.
- **Density matrices are not stored** in the base result.
- **Raw response choices are private** (owner-read / server-write policy).
- **Future server derives scores** from catalog + validated session + answers.
- **Direct client-supplied scores are not authoritative.**
- **`runtime_selectable` remains `false`** until an explicit, separate activation decision.
- **Persistence readiness does not equal activation approval.**

---

## 2. Firestore path decision

### Chosen path

```
users/{uid}/assessments/frequency_v2
```

### Rationale

| Check | Result |
|-------|--------|
| Existing subcollection pattern | `users/{uid}/assessments/{docId}` already used for `iq`, `eq`, `frequency`, `persona` (`lib/core/utils/firestore_paths.dart` → `userAssessmentDoc`) |
| Rules compatibility | `firestore.rules` matches `assessments/{docId}` generically for owner read/write today; `frequency_v2` is a new doc ID, not a new collection |
| V1 isolation | Live V1 remains at `assessments/frequency` — distinct doc ID, no overwrite risk |
| Helper reuse | `FirestorePaths.userAssessmentDoc(uid, 'frequency_v2')` works without structural change |
| Contract docs | `docs/core_engine/assessment_result_contract_v1.md` lists V1 module IDs; V2 is intentionally **out of scope** of that v1 contract and documented here |

### Forbidden paths

| Path / field | Reason |
|--------------|--------|
| `users/{uid}/assessments/frequency` | Live V1 canonical result |
| `users/{uid}/profiles/canonical_v1` | 20D merge target for V1 6D Frequency only |
| `users/{uid}.frequency_vector` and related legacy mirrors | V1 legacy / compat hydration |
| `public_profiles/{uid}` | No assessment projection |

**No repo-level conflict** was found that would make `frequency_v2` unsafe. The doc ID is new; coexistence is by separation, not schema migration.

---

## 3. Authority model

### Client may submit (future finalize **request** only)

Reproducible session inputs aligned with `assessment_finalize_session_v1` patterns:

- `schema_version`, `catalog_version` (finalize request contract)
- `session_id`, `owner_uid`
- `assessment_type`: `frequency_v2`
- `bank_version`, `bank_locale`, `selection_policy_version`
- `translation_version` (when `bank_locale` is `en-US`)
- `session_seed`
- `item_plans[]`: `{ item_id, presented_option_order[] }` (length 50, presentation order)
- `answers[]`: `{ item_id, selected_option_id }` (length 50, one per plan)

### Client must NOT submit as authoritative

- `normalized_behavior`, `behavioral_mean_12d`, dimension score maps
- `provisional_confidence`, `confidence_flags`, presentation-pressure fields
- Cross-context consistency/coverage (unless re-submitted only for debug and ignored by server)
- Signed-pole / 24D state, mixed density, pair-relation, pair-fit outputs
- Completion authority: `test_completed`, `assessment_flow_completed`, `frequency_completed`, `discover_eligible`
- Any `FORBIDDEN_AUTHORITY_FIELD` from `functions/src/assessment_finalize_validation_v1.js`

### Server derives and writes (future)

1. Structural validation against `assessment_finalize_catalog_v1` (V2 bank + selector policy).
2. Authoritative 12D scoring via version-pinned scorer + confidence models (`FrequencyBehaviorV2Scorer` semantics).
3. Persisted result document at `users/{uid}/assessments/frequency_v2`.
4. Optional trusted verification map entry: `users/{uid}.assessment_verification_v1.frequency` (separate Phase 7C decision; not required to freeze result body).

**Reserved future `source` value (result document):** `admin_finalize_frequency_v2_v1`
(Do not write this value until the callable exists.)

---

## 4. Full proposed result schema (JSON-like)

Field names are **snake_case** in Firestore. Omit optional fields rather than writing JSON `null` unless noted.

```json
{
  "schema_version": "qmatch_frequency_behavior_v2_result_v1",
  "assessment_type": "frequency_v2",
  "status": "completed",
  "source": "admin_finalize_frequency_v2_v1",
  "session_id": "frequency_v2_sess_<stable_id>",

  "version_pins": {
    "bank_version": "frequency_behavior_pool_tr_v2_draft1",
    "bank_locale": "tr-TR",
    "translation_version": "frequency_v2_en_semantic_v1",
    "selection_policy_version": "frequency_behavior_50_of_426_seeded_quota_v2_draft1",
    "selector_version": "frequency_behavior_v2_selector_v1",
    "scoring_policy_version": "frequency_behavior_12d_signed_evidence_v2",
    "scorer_version": "frequency_behavior_v2_scorer_v1",
    "confidence_model_version": "frequency_behavior_v2_confidence_v1",
    "session_manifest_schema_version": "qmatch_frequency_behavior_v2_session_manifest_v1",
    "finalize_catalog_version": "assessment_finalize_catalog_v1"
  },

  "session_proof": {
    "session_seed": "<caller_seed>",
    "item_count": 50,
    "item_plans": [
      {
        "item_id": "frequency_v2_q0123",
        "presentation_index": 0,
        "presented_option_order": [
          "frequency_v2_q0123_b",
          "frequency_v2_q0123_a",
          "frequency_v2_q0123_d",
          "frequency_v2_q0123_c"
        ]
      }
    ]
  },

  "responses": [
    {
      "item_id": "frequency_v2_q0123",
      "option_id": "frequency_v2_q0123_b"
    }
  ],

  "dimensions": [
    {
      "dimension_id": "contact_need",
      "normalized_behavior": 0.25,
      "provisional_confidence": 0.62,
      "confidence_flags": ["LIMITED_CROSS_CONTEXT"],
      "cross_context_consistency": 0.75,
      "cross_context_coverage": 0.5,
      "confidence_completeness": 1.0,
      "primary_signal_coverage": 0.75
    }
  ],

  "summary": {
    "measured_dimension_count": 12,
    "dimensions_with_behavior": 12,
    "global_support": 0.58
  },

  "integrity": {
    "session_proof_sha256": "<hex>",
    "responses_sha256": "<hex>",
    "result_sha256": "<hex>"
  },

  "verified_at": "<server Timestamp>",
  "created_at": "<server Timestamp>",
  "updated_at": "<server Timestamp>"
}
```

### Notes on shape

- **`dimensions`** is the **single canonical** 12D representation. Do **not** also persist a parallel `behavioral_mean_12d` map (redundant; derive in readers if needed).
- **`translation_version`**: required in `version_pins` when `bank_locale` is `en-US`; omit when `bank_locale` is `tr-TR` (master text bank).
- **`presentation_index`** in `item_plans` is the 0-based order in the administered session (matches selector manifest); aids audit without a separate `question_ids` array.

---

## 5. Field-by-field table

| Field | Type | Required | Authority | Purpose |
|-------|------|----------|-----------|---------|
| `schema_version` | string | yes | server | Result document shape ID |
| `assessment_type` | string | yes | server | Always `frequency_v2` |
| `status` | string | yes | server | `completed` for finalized results; reserve `void` / `superseded` for future retake policy |
| `source` | string | yes | server | `admin_finalize_frequency_v2_v1` when written by finalize callable |
| `session_id` | string | yes | server (from validated request) | Idempotency key; ties to verification map |
| `version_pins` | map | yes | server | Pin all reinterpretation-sensitive versions |
| `version_pins.bank_version` | string | yes | server | Pool JSON identity (`frequency_behavior_pool_*_v2_*`) |
| `version_pins.bank_locale` | string | yes | server | `tr-TR` or `en-US` |
| `version_pins.translation_version` | string | when `en-US` | server | EN semantic text generation (`frequency_v2_en_semantic_v1`) |
| `version_pins.selection_policy_version` | string | yes | server | 50-of-426 quota policy |
| `version_pins.selector_version` | string | yes | server | Selector algorithm ID |
| `version_pins.scoring_policy_version` | string | yes | server | Weight/evidence scoring policy |
| `version_pins.scorer_version` | string | yes | server | Scorer implementation ID |
| `version_pins.confidence_model_version` | string | yes | server | Confidence heuristic ID |
| `version_pins.session_manifest_schema_version` | string | yes | server | Session proof subsection shape |
| `version_pins.finalize_catalog_version` | string | yes | server | Structural validation catalog |
| `session_proof` | map | yes | server | Exact administered session |
| `session_proof.session_seed` | string | yes | server | Reproduces selector draw with pinned versions |
| `session_proof.item_count` | number | yes | server | Must be `50` |
| `session_proof.item_plans` | array | yes | server | Ordered plans; **sole** ordered question list |
| `session_proof.item_plans[].item_id` | string | yes | server | `frequency_v2_q####` |
| `session_proof.item_plans[].presentation_index` | number | yes | server | 0..49 |
| `session_proof.item_plans[].presented_option_order` | string[] | yes | server | Four option IDs per item |
| `responses` | array | yes | server | Validated answer choices |
| `responses[].item_id` | string | yes | server | Matches plan |
| `responses[].option_id` | string | yes | server | Must be in that item's `presented_option_order` |
| `dimensions` | array | yes | server | Authoritative 12D output (length 12, fixed order optional) |
| `dimensions[].dimension_id` | string | yes | server | One of 12 canonical IDs |
| `dimensions[].normalized_behavior` | number \| omitted | yes* | server | `[-1, +1]`; omit key when capacity 0 (*dimension row still present with null semantics via omission + flag, or explicit `measured: false` — implementers: use omission of `normalized_behavior` only when not measured) |
| `dimensions[].provisional_confidence` | number | when measured | server | `[0, 1]` engineering support signal, **not** probability/truth |
| `dimensions[].confidence_flags` | string[] | when non-empty | server | e.g. `HIGH_PRESENTATION_PRESSURE` |
| `dimensions[].cross_context_consistency` | number | when computed | server | Mixed-density / pair-layer input |
| `dimensions[].cross_context_coverage` | number | when computed | server | Mixed-density / pair-layer input |
| `dimensions[].confidence_completeness` | number | when measured | server | `0.8` or `1.0` per confidence contract |
| `dimensions[].primary_signal_coverage` | number | when measured | server | Observability primitive for downstream support |
| `summary` | map | yes | server | Aggregates for UI and pair-prep |
| `summary.measured_dimension_count` | number | yes | server | Always `12` rows; behavior may be null per dim |
| `summary.dimensions_with_behavior` | number | yes | server | Count of dims with non-null `normalized_behavior` |
| `summary.global_support` | number | yes | server | Mean of `provisional_confidence × confidence_completeness` over measured dims (mixed-density λ input) |
| `integrity` | map | recommended | server | Audit / idempotency helpers |
| `integrity.session_proof_sha256` | string | recommended | server | Hash of canonical `session_proof` JSON |
| `integrity.responses_sha256` | string | recommended | server | Hash of canonical `responses` JSON |
| `integrity.result_sha256` | string | recommended | server | Hash of `dimensions` + `summary` + `version_pins` |
| `verified_at` | timestamp | yes | server | Finalize time |
| `created_at` | timestamp | yes | server | First write |
| `updated_at` | timestamp | yes | server | Last write (idempotent retry may leave unchanged) |

---

## 6. Twelve-dimension schema

Fixed canonical set (order in `dimensions[]` should follow `FrequencyBehaviorV2Contract.canonicalDimensions`):

1. `contact_need`
2. `closeness_pace`
3. `initiative`
4. `autonomy`
5. `reassurance_need`
6. `uncertainty_tolerance`
7. `disclosure_pace`
8. `boundary_firmness`
9. `repair_style`
10. `social_energy`
11. `structure_preference`
12. `adaptability`

**Excluded:** all V1 Frequency IDs (`depth_preference`, `social_energy`, `spontaneity`, `stability`, `communication_pace`, etc.). V1 `social_energy` is **not** V2 `social_energy` in meaning or scale — do not conflate.

### Per-dimension persistence decision

| Scorer field | Persist? | Reason |
|--------------|----------|--------|
| `normalized_behavior` | **yes** | Core product primitive; pair-fit input |
| `provisional_confidence` | **yes** | Display + mixed-density support; uncalibrated engineering signal |
| `confidence_flags` | **yes** | Small, stable UX/ops signals; avoids threshold drift on recompute |
| `cross_context_consistency` | **yes** | Needed for mixed density without full session recompute |
| `cross_context_coverage` | **yes** | Same |
| `confidence_completeness` | **yes** | Enters `global_support` / λ |
| `primary_signal_coverage` | **yes** | Observability for support weighting |
| `raw_sum`, `capacity`, `signal_utilization` | **no** | Recomputable from catalog + session + answers |
| `primary_question_count`, nonzero/zero counts | **no** | Debug/intermediate |
| Evidence means (`mean_diagnostic_value`, etc.) | **no** | Recomputable; large; not needed for persisted product surface |
| `presentation_pressure`, `presentation_adjustment` | **no** | Encoded in `provisional_confidence`; flags retained |
| `base_confidence`, `context_component`, `semantic_clarity` | **no** | Intermediate confidence pipeline |

**Canonical representation:** `dimensions[]` only — not a separate `behavioral_mean_12d` object.

---

## 7. Session manifest schema (`session_proof`)

### Design principles

- **Single source of truth for order:** `item_plans` array order **is** presentation order. Do **not** also persist `question_ids[]` (redundant).
- **Expected item count:** `item_count` must be `50`.
- **Selectable only:** every `item_id` must be one of the 405 selector-eligible pool items at finalize time; **DROP** items (21 questions) must never appear.
- **Near-duplicate constraints:** enforced at finalize validation, not duplicated in the result body.
- **Compactness:** persist IDs and option order only — no stems, option text, weights, or evidence.

### Relationship to domain types

Aligns with `FrequencyBehaviorV2SessionManifest` / `FrequencyBehaviorV2SessionItemPlan` (`frequency_behavior_v2_models.dart`) but persisted subset is slimmer: no `primary_dimension` per row (derivable from catalog), no duplicate `question_ids`.

### Regeneration recipe

```
pool(bank_version) + session_seed + selection_policy_version + selector_version
  + review/near-duplicate metadata from catalog
  => must reproduce identical item_plans if selector is deterministic
```

---

## 8. Response schema

```json
"responses": [
  { "item_id": "frequency_v2_q0401", "option_id": "frequency_v2_q0401_c" }
]
```

| Rule | Detail |
|------|--------|
| Length | Exactly 50 entries |
| Coverage | One response per `item_plans[].item_id` |
| Validation | `option_id` ∈ that item's `presented_option_order` |
| Excluded | Option text, weights, evidence priors, timestamps |

### Timestamps

**Not persisted** on individual responses. No current product or integrity requirement mandates per-answer latency in the canonical result. Telemetry (separate contract, dormant) may capture latency later.

---

## 9. Versioning

| Layer | Field | Example (current draft) |
|-------|-------|-------------------------|
| Result document | `schema_version` | `qmatch_frequency_behavior_v2_result_v1` |
| Pool | `version_pins.bank_version` | `frequency_behavior_pool_tr_v2_draft1` / `frequency_behavior_pool_en_v2_draft1` |
| Locale presentation | `version_pins.bank_locale` | `tr-TR`, `en-US` |
| EN semantics | `version_pins.translation_version` | `frequency_v2_en_semantic_v1` (EN only) |
| Selector | `version_pins.selector_version` | `frequency_behavior_v2_selector_v1` |
| Selection policy | `version_pins.selection_policy_version` | `frequency_behavior_50_of_426_seeded_quota_v2_draft1` |
| Scoring | `version_pins.scoring_policy_version` | `frequency_behavior_12d_signed_evidence_v2` |
| Scorer code | `version_pins.scorer_version` | `frequency_behavior_v2_scorer_v1` |
| Confidence | `version_pins.confidence_model_version` | `frequency_behavior_v2_confidence_v1` |
| Finalize validation | `version_pins.finalize_catalog_version` | `assessment_finalize_catalog_v1` |

**Immutability:** finalized `completed` documents are immutable except explicit `status` transitions (`void`, `superseded`) when a future retake policy exists.

**Supersession:** future retake policy may write a new doc or mark old `status: superseded` — **NOT DEFINED** in Phase 7B.

---

## 10. Confidence persistence decision

- **`provisional_confidence` is persisted** per dimension when measured.
- **Semantic:** engineering confidence / support signal for mixed density and future UI bands — **not** probability, clinical certainty, truth, or lie detection.
- **`confidence_flags` are persisted** (not only recomputed) because they are user-facing/ops-facing categorical signals tied to a pinned model version; recomputation is possible but risks threshold-label drift across server deploys.
- **Evidence means and presentation intermediates are not persisted** — recomputable from catalog + answers when auditing.

---

## 11. 24D signed-pole state persistence decision

**Do not persist** in the base user result:

- `behaviorVector12d` (redundant with `dimensions[].normalized_behavior`)
- `poleAmplitudes24d`, `stateVector24d`
- `pureDensityMatrix` or any 24×24 matrix

**Rationale:** `FrequencyBehaviorV2SignedPoleEncoder.encodeFromScore()` deterministically reconstructs 24D artifacts from the complete 12D `normalized_behavior` vector + pinned `signedPoleEncodingVersion`. Persisting 24D would duplicate data and invite inconsistency.

Mixed-density `rho_user` is also **not** persisted in the user result; derive at pair-comparison time from persisted `dimensions` + `summary.global_support`.

---

## 12. Pair-data exclusion

The following are **explicitly excluded** from `users/{uid}/assessments/frequency_v2`:

- `FrequencyBehaviorV2PairRelationResult`
- `FrequencyBehaviorV2PairFitResult`
- `frequencyFitIndex`, alignment/gap dimension lists
- Hilbert–Schmidt overlaps, same/opposite pole expectations
- Any A/B comparison artifact

Pair layers consume **two** private results via Admin SDK at comparison time.

---

## 13. Telemetry exclusion

Do **not** embed in the canonical result:

- `FrequencyBehaviorV2SessionTelemetry`
- `FrequencyBehaviorV2ResponseTelemetryEvent`
- Cohort slices, latency, answer-change sequences

Telemetry requires a separate privacy/retention contract (`frequency_v2_calibration_telemetry_v1_contract.md`). `telemetryLiveCollectionEnabled` remains `false`.

---

## 14. Privacy / public-profile policy

**None** of the following may be projected to `public_profiles/{uid}`:

- Raw `responses`
- `session_proof` / `session_seed` / question or option IDs
- `dimensions` / 12D scores
- `provisional_confidence` / flags
- `integrity` hashes
- `version_pins` / internal version metadata

Future matching may read private assessment data via **Admin SDK** only, under separate authorization — not client-readable peer data.

---

## 15. Intended Firestore write policy (Phase 7C/7D)

Path: `users/{uid}/assessments/frequency_v2`

| Actor | Policy |
|-------|--------|
| **Owner** | `get` allowed (read own result) |
| **Client** | `create` / `update` / `delete` **denied** for authoritative finalized body (or create allowed only for `in_progress` drafts in a future optional phase — **not in 7B**) |
| **Server (Admin SDK)** | Sole writer of `status: completed` finalized documents |
| **Peers / public** | No access |

Align with `assessment_verification_v1` pattern: clients cannot forge verified assessment proof. Today V1 `assessments/{docId}` is owner-writable; **V2 rules should be stricter** at implementation time.

Also document in rules tests (`tool/firebase_rules_tests/test/rules.test.js`).

---

## 16. Idempotency semantics

Future `finalizeFrequencyV2` behavior (mirrors IQ `finalize_iq_v1.js`):

| Case | Expected behavior |
|------|-------------------|
| Same `session_id`, already finalized | **Idempotent** — return success; preserve `verified_at`; no duplicate writes |
| Different `session_id` after verified completion | **Reject** — `failed-precondition` (exact error code TBD in 7C) |
| Retake / replace policy | **NOT DEFINED / FUTURE PRODUCT DECISION** |

Result contract supports idempotency via:

- `session_id` (unique per administered session)
- `integrity.*_sha256` (detect body drift on retry)
- `version_pins` (detect silent reinterpretation)

---

## 17. Integrity hashes

Recommended (optional but **strongly encouraged** for server implementation):

| Hash | Canonical payload | Purpose |
|------|-------------------|---------|
| `session_proof_sha256` | Stable JSON of `session_proof` (sorted keys, UTF-8, no timestamps) | Prove administered session unchanged on retry |
| `responses_sha256` | JSON array of responses sorted by `item_id` | Prove answers unchanged |
| `result_sha256` | `version_pins` + `dimensions` + `summary` | Detect tampering / accidental drift |

Hashes are **not** for client display. They support audit, idempotent finalize, and future integrity checks.

---

## 18. Migration / V1 coexistence

| Concern | Policy |
|---------|--------|
| V1 live path | Unchanged: `assessments/frequency`, 6D, client-authoritative today |
| V2 path | New doc `frequency_v2`; no migration of V1 users required for dormancy |
| `canonical_v1` | V2 does not merge Frequency module |
| 20D / legacy matching | Continues reading V1 6D only |
| User mirrors | V2 does not set `frequency_completed` or legacy vectors in Phase 7B |
| Rollback | Delete/disable V2 finalize + ignore `frequency_v2` docs; V1 unaffected |
| Pool activation | `runtime_selectable: true` is a **separate** gate in pool JSON + registry |

---

## 19. Completion / eligibility (activation blocker — out of scope)

Phase 7A finding: `test_completed`, `assessment_flow_completed`, `frequency_completed` are **client-writable** today. Discover eligibility trusts those inputs indirectly.

Phase 7B **does not**:

- Introduce `frequency_v2_completed`
- Wire V2 into `assessment_flow_completed` or `discover_eligible`
- Solve trusted completion

Trusted completion/eligibility for V2 is a **separate activation blocker** for a later phase, potentially combining:

- `assessment_verification_v1.frequency` server proof
- Server-written completion mirrors
- Discover derivation updates

---

## 20. Open decisions

| ID | Topic | Status |
|----|-------|--------|
| OD-1 | Retake policy (replace vs supersede vs multiple docs) | NOT DEFINED |
| OD-2 | Whether `assessment_verification_v1.frequency` is written alongside result doc | Pending 7C (recommended: yes, mirror IQ) |
| OD-3 | Callable name: `finalizeFrequencyV2` vs `finalizeFrequency` | Pending 7C naming |
| OD-4 | In-progress draft docs before finalize | Not required for MVP finalize |
| OD-5 | Server-side scorer port (Node) vs trusted Dart batch | Pending 7C architecture |
| OD-6 | EN pool `bank_version` value when locale is `en-US` | Use `frequency_behavior_pool_en_v2_draft1` |
| OD-7 | Whether `summary.global_support` formula is normative in contract vs scorer helper | Frozen as mean(`provisional_confidence × confidence_completeness`) over dims with behavior |
| OD-8 | Trusted activation: completion mirrors + Discover | Future phase |

---

## 21. Phase 7C implementation prerequisites

Before implementing `finalizeFrequencyV2`:

1. **Catalog entry** — add V2 bank to `tool/generate_assessment_finalize_catalog_v1.js` / `assessment_finalize_catalog_v1.generated.js` with 50-of-426 selector rules (not V1 full-bank validator).
2. **Validation module** — extend `assessment_finalize_validation_v1.js` for `assessment_type: frequency_v2`, DROP exclusion, selectable 405 set, dimension quota / role checks per selector contract.
3. **Callable handler** — `functions/src/finalize_frequency_v2_v1.js` (pattern from `finalize_iq_v1.js`).
4. **Scoring authority** — server derives `dimensions` + `summary`; never trusts client scores.
5. **Firestore writer** — Admin SDK write to `users/{uid}/assessments/frequency_v2` matching this contract.
6. **Firestore rules** — deny client authoritative writes to `frequency_v2` completed docs.
7. **Flutter request mapper** — `frequency_v2_finalize_request_mapper.dart` (session → `assessment_finalize_session_v1` payload).
8. **Flutter callable client + pipeline** — mirror `IqPendingFinalizationPipeline` (finalize → score → persist local state).
9. **V2 session persistence** — SharedPreferences or equivalent for locked session before finalize.
10. **Path helper** — document `FirestorePaths.userAssessmentDoc(uid, 'frequency_v2')` (optional constant in Dart).
11. **Tests** — `functions/test/finalize_frequency_v2_v1.test.js`, mapper/pipeline tests, rules tests, contract fixture tests.
12. **Verification map** — optional `assessment_verification_v1.frequency` + flow update in `assessment_verification_flow_v1.js`.
13. **Explicit non-goals in 7C** — no `canonical_v1` writes, no legacy mirrors, no `public_profiles` projection, no matching wiring, `runtime_selectable` stays false.

---

## References

| Artifact | Path |
|----------|------|
| V2 pool contract | `docs/assessment/frequency_v2/qmatch_frequency_behavior_pool_v2_contract.md` |
| Scorer contract | `docs/assessment/frequency_v2/frequency_v2_scorer_v1_contract.md` |
| Confidence contract | `docs/assessment/frequency_v2/frequency_v2_confidence_v1_contract.md` |
| Selector contract | `docs/assessment/frequency_v2/frequency_v2_selector_v1_contract.md` |
| V1 result contract | `docs/core_engine/assessment_result_contract_v1.md` |
| IQ finalize pattern | `functions/src/finalize_iq_v1.js` |
| Domain constants | `lib/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_contract.dart` |
| Phase 7A audit | conversation / architecture discovery (2026-09-01) |

---

**Contract freeze date:** 2026-09-01
**Phase:** 7B — no runtime wiring
