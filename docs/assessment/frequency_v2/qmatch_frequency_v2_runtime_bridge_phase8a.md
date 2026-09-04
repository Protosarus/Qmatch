# Frequency V2 — Runtime Bridge Foundation (Phase 8A)

**Status:** source + tests only. **Not activated. Not deployed.**
**Date:** 2026-09-04
**Baseline:** `8fcf3cd386ea81d3e87534a4bce060cbb0b4bfdd`
**`runtime_selectable`:** `false`

This document records the dormant Flutter runtime bridge around the existing
Frequency V2 domain and `finalizeFrequencyV2` backend. It does **not** claim
activation, production deploy, matching integration, or Discover treatment
for V2.

---

## Implementation matrix

### EXISTS / REUSE

| Piece | Location |
|-------|----------|
| 12D contract, 426/405/21/50 pins | `lib/features/assessment/domain/frequency_behavior_v2/frequency_behavior_v2_contract.dart` |
| Bank registry (`isRuntimeSelectable` always false) | `frequency_behavior_v2_bank_registry.dart` |
| Seeded 50-of-405 selector | `frequency_behavior_v2_selector.dart` |
| 12D scorer / confidence / pair-fit math | existing V2 domain modules |
| Reviewed TR/EN pools | `tool/frequency_behavior_v2/out/frequency_behavior_pool_*_v2_draft1.json` |
| Server catalog + session validation + scorer | `functions/src/frequency_behavior_v2_*.js` |
| `finalizeFrequencyV2` callable (registered, **not deployed**) | `functions/src/finalize_frequency_v2_v1.js` / `functions/index.js` (`europe-west1`) |
| Owner-read / client-write-denied `assessments/frequency_v2` | `firestore.rules` (unchanged in 8A) |
| V1 Frequency session / pending pipeline / screens | live V1 path, left in place |

### MISSING / BUILT IN 8A

| Piece | Location |
|-------|----------|
| Version+locale bank loader + validation | `lib/features/assessment/domain/frequency_v2_runtime/frequency_v2_bank_loader.dart` |
| Dedicated V2 persisted session + prefs keys | `frequency_v2_persisted_session_state.dart`, `frequency_v2_session_repository.dart` |
| Deterministic session orchestration | `frequency_v2_session_manager.dart` |
| Response controller | `frequency_v2_session_controller.dart` |
| `finalizeFrequencyV2` request mapper | `frequency_v2_finalize_request_mapper.dart` |
| Callable client (`europe-west1`) | `lib/features/assessment/services/frequency_v2_finalize_callable_client.dart` |
| V2 pending pipeline (no client result write) | `frequency_v2_pending_finalization_pipeline.dart` |
| Central V1/V2 runtime gate | `frequency_runtime_selection_policy.dart` |
| Dormant V2 UI using V1 presentation widgets | `lib/features/assessment/screens/frequency_v2_test_screen.dart` |
| Dormant cold-start V2 branch | `assessment_cold_start_pending_reconciler.dart` (gated; unreachable today) |
| Intro uses the centralized gate (still resolves V1) | `frequency_intro_screen.dart` |

### OUT OF SCOPE (unchanged)

- `finalizeIq` / `finalizeEq` / `finalizeFrequency` V1
- Trusted Discover / grandfather / completion-flag rules
- V1 Frequency scorer / `canonical_v1` / Stage B2
- V2 selector/scorer/catalog/EN-TR semantic review math
- Production deploy of `finalizeFrequencyV2`
- Flipping `runtime_selectable` / `isRuntimeSelectable()`
- 12D → 6D adapter
- Client writes to `users/{uid}/assessments/frequency_v2`

---

## Runtime selection today

`FrequencyRuntimeSelectionPolicy.resolve()` returns **V1** because
`FrequencyBehaviorV2BankRegistry.isRuntimeSelectable(...)` is **false** for
both reviewed TR and EN pool versions.

Even with V2 banks loadable locally, live Frequency intro still opens
`FrequencyTestScreen`.

---

## V2 result write authority

Authoritative V2 result remains server-only:

`users/{uid}/assessments/frequency_v2`

The 8A client pipeline calls `finalizeFrequencyV2` then marks the **local**
V2 session `remote_finalized`. It does not write:

- `frequency_completed` / `test_completed` / `assessment_flow_completed`
- `discover_eligible`
- `assessment_verification_v1.frequency`
- `canonical_v1`
- V1 `assessments/frequency`

Firestore rules already allow owner read and deny client create/update/delete
of `frequency_v2`. **Rules were not changed in 8A.**

---

## Cold-start

A pending locked V2 session is only resumed when the centralized gate
resolves **V2**. While the gate is V1, V2 pending is ignored and existing
IQ → EQ → Frequency V1 cold-start is unchanged.

---

## Matching integration point (not implemented)

Live Stage B2 (`functions/src/stage_b2_l2_callable.js`,
`handleCompareStageB2Structural`) Admin-reads:

`users/{uid}/profiles/canonical_v1`

for viewer + candidates and runs the existing 20D structural comparison.
It does **not** read `assessments/frequency_v2`.

**Future (not 8A):** the server should read
`users/{viewer}/assessments/frequency_v2` and
`users/{candidate}/assessments/frequency_v2`, compute pair diagnostics /
pair-fit on the server, and return **only** those outputs. Do **not**:

- convert 12D → 6D
- merge V2 into `canonical_v1` Frequency slots
- expose peer 12D vectors to clients

---

## 50% Frequency product requirement (next matching phase)

Product intent: Frequency compatibility should be the **dominant** component,
approximately **50%** of final compatibility.

This phase does **not** invent remaining weights.

Current audited contracts (do not silently assume 25/25/50):

| Surface | IQ | EQ | Frequency | Notes |
|---------|----|----|-----------|--------|
| Live Discover structural L2 | n/a (20D group-normalized inside `canonical_v1`) | same | same | Stage B2; no V2 12D |
| Dart structural replica `Canonical20dGroupNormalizedShadowContract` | **0.133333** | **0.400000** | **0.466667** | Frozen 20D module weights; not live Discover ranking |
| Persona shadow `PersonaShadowContract` | **0.15** | **0.30** | **0.55** | Persona, not Discover ranking |

A later matching phase must choose an explicit weighting policy for V2 12D
pair-fit vs remaining IQ/EQ/structural/activity signals. That policy is
**not** defined here.

---

## STILL MISSING BEFORE ACTIVATION

- Production deploy of `finalizeFrequencyV2`
- Actual runtime V2 selection flip (`isRuntimeSelectable` / bank
  `runtime_selectable=true`) after an explicit product decision
- Production / device test of the V2 session + pending pipeline
- Server-side 12D matching integration (Stage B2 or successor) without
  12D→6D conversion and without exposing peer 12D vectors
- Final compatibility weighting policy (Frequency ~50% product requirement)
- Discover / trust treatment for V2 completion, if/when product requires it
  (`assessment_verification_v1` Frequency V2 is **not** a grant path today)
- Flutter asset bundling of reviewed V2 pools (8A loader reads repo
  `tool/frequency_behavior_v2/out/` for tests; V2 JSON is intentionally
  **not** listed in `pubspec.yaml` so existing dormant-bundle contracts stay
  true)
- Optional: retake policy, telemetry live collection, EN/TR device locale
  routing polish

**Activation is not complete.**
