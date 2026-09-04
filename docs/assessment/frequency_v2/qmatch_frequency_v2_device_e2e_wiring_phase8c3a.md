# Frequency V2 — device E2E wiring (Phase 8C.3A)

**Status:** source + tests only. **No Firebase deploy. No physical-device E2E.**
**Date:** 2026-09-04
**Baseline:** `231d38cbe0690b1f26ca7081b3f9613cd42ca040`
**`runtime_selectable`:** `false`
**Live ranking:** `structural_l2_v1`
**`finalizeFrequencyV2`:** already deployed in 8C.2 (`europe-west1`)

This micro-phase wires the internal Frequency V2 UI to the existing pending
finalization pipeline so a later physical-device run can actually call the
deployed callable. It does **not** activate release V2, write production
results, or deploy Discover triggers.

---

## Discovered gap

`FrequencyV2TestScreen` locked the 50-item session and optionally fired
`onLocked`. `FrequencyIntroScreen` opened `const FrequencyV2TestScreen()`
with no callback.

The pipeline already existed:

locked session → `finalizeFrequencyV2` → local `markRemoteFinalized` →
`dormantCompletion`

but the real runtime path never invoked it. A 50-question device run would
not have been a true finalize E2E.

---

## Exact fix

- Reused `FrequencyV2PendingFinalizationPipeline` (not rewritten).
- Added `FrequencyV2PendingFinalizationPipeline.live()` using
  `FrequencyV2FinalizeCallableClient` (`europe-west1` / `finalizeFrequencyV2`)
  and the V2 session manager's `markRemoteFinalized`.
- `FrequencyV2TestScreen` now owns/injects the pipeline.
- `FrequencyV2ScreenFinalizeCoordinator` enforces one in-flight callable and
  one automatic bootstrap retry.

---

## UI → server sequence

1. Answer 50 items.
2. Lock local session (`completedPendingPersistence`).
3. Screen runs the pending pipeline (no external `onLocked` required).
4. Callable `finalizeFrequencyV2` writes `users/{uid}/assessments/frequency_v2`.
5. On success (including same-session `idempotent=true`), local
   `remote_finalized` is marked.
6. Screen shows internal copy: `Frequency V2 internal test completed`.

`onLocked` remains a test hook only.

---

## Crash recovery

If the screen loads an existing `completedPendingPersistence` session, it
schedules **one** automatic pipeline retry for that lifecycle.

Covers:

- app kill
- network interruption
- crash between lock and finalize
- crash after server success before local `remote_finalized`

Retry always goes through the callable. Local `remote_finalized` is never
inferred from a remote document.

Same-session idempotent success is treated as success.
`FREQUENCY_V2_ALREADY_FINALIZED` (different session) is **not** success;
the local pending session is kept.

---

## Success destination

Internal dormant completion only. No navigation into V1 Persona, no
`canonical_v1`, no product/scientific result screen.

---

## Authority exclusions

Client path does **not** write:

- `users/{uid}/assessments/frequency_v2` (callable only)
- `frequency_completed` / `test_completed` / `assessment_flow_completed`
- `discover_eligible`
- `assessment_verification_v1`
- `users/{uid}/profiles/canonical_v1`
- V1 `assessments/frequency`

Cold-start reconciler still only routes to the Frequency screen when the
runtime track is V2. It does not finalize.

---

## Runtime

| Track | Screen |
|-------|--------|
| release/default | V1 `FrequencyTestScreen` |
| debug/default | V1 |
| debug + `QMATCH_FREQUENCY_V2_INTERNAL=true` | wired `FrequencyV2TestScreen` |

`FrequencyIntroScreen` still uses only
`FrequencyRuntimeSelectionPolicy.resolve()`.

---

## Remaining

Physical-device authenticated E2E belongs to a later 8C.3 step.
Discover V2 trigger deploy remains 8C.4.
Release runtime activation remains 8C.5.
