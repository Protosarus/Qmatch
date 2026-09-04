# Frequency V2 — finalizeFrequencyV2 production deploy (Phase 8C.2)

**Date:** 2026-09-04
**Mode:** controlled production deployment — one callable only
**Firebase project:** `qmatch-53d62`

This record documents deploying `finalizeFrequencyV2` to production. It is not
a Flutter V2 activation, Discover trigger deploy, rules change, ranking change,
or authenticated finalization.

---

## Source

| Item | Value |
|------|--------|
| Repository | Protosarus/Qmatch |
| Branch | `main` |
| Commit deployed from | `cd7d86f1edb52f8bfc932e9559d649226131c8a7` |
| `HEAD` / `origin/main` at deploy | identical to the commit above |
| Working tree at deploy | clean |

Source contract (unchanged this phase):

| Item | Value |
|------|--------|
| Callable | `finalizeFrequencyV2` |
| Region | `europe-west1` |
| Runtime | Node.js 22 (2nd Gen) |
| Source | `admin_finalize_frequency_v2_v1` |
| Result path | `users/{uid}/assessments/frequency_v2` |
| Writes `users/{uid}` / `discover_eligible` / `assessment_verification_v1` / completion flags / `canonical_v1` / V1 Frequency / matching | **No** |

`recomputeDiscoverEligibleOnFrequencyV2Write` remains source-registered in
`functions/index.js` and was **not** selected for deploy.

---

## Pre-deploy production inventory

Observed with `firebase functions:list --project qmatch-53d62` before any deploy.

| Function | Pre-deploy production status |
|----------|------------------------------|
| `finalizeFrequencyV2` | **Absent** |
| `finalizeIq` | Present — v2 callable, `europe-west1`, nodejs22 |
| `finalizeEq` | Present — v2 callable, `europe-west1`, nodejs22 |
| `finalizeFrequency` | Present — v2 callable, `europe-west1`, nodejs22 |
| `recomputeDiscoverEligibleOnFrequencyV2Write` | **Not deployed** |
| `recomputeDiscoverEligibleOnUserWrite` | Present — v2 Firestore written, `us-central1` (unchanged; not selected) |

---

## Test gate

Run in `functions/` against commit `cd7d86f1edb52f8bfc932e9559d649226131c8a7`
before deploy.

| Suite | Result |
|-------|--------|
| Functions lint/require | ok |
| `catalog:check` | `assessment_finalize_catalog_v1.generated.js is current` |
| Focused Frequency V2 (catalog, session validation, finalizeFrequencyV2, parser, pair-fit, fusion, Discover trust) | **135 passing** |
| Full Functions suite | **727 passing**, 0 failing |
| `git diff --check` | ok |

---

## Deploy

| Item | Value |
|------|--------|
| Command | `firebase deploy --only functions:finalizeFrequencyV2 --project qmatch-53d62 --non-interactive` |
| Deployed function | `finalizeFrequencyV2` only |
| Region | `europe-west1` |
| Runtime | Node.js 22 (2nd Gen) |
| CLI result | Successful create — `functions[finalizeFrequencyV2(europe-west1)] Successful create operation.` |
| Other functions created/updated/deleted | **No** |
| Firestore rules / storage / indexes / hosting | **Not deployed** |

---

## Post-deploy inventory

Observed with `firebase functions:list --project qmatch-53d62` after deploy.

Compared to the pre-deploy list, this phase added only:

- `finalizeFrequencyV2` (`europe-west1`, v2 callable, nodejs22)

| Function | Post-deploy status |
|----------|--------------------|
| `finalizeFrequencyV2` | **Present** — v2 callable, `europe-west1`, nodejs22 |
| `finalizeIq` | Present — `europe-west1` (not redeployed) |
| `finalizeEq` | Present — `europe-west1` (not redeployed) |
| `finalizeFrequency` | Present — `europe-west1` (not redeployed) |
| `recomputeDiscoverEligibleOnFrequencyV2Write` | **Still not deployed** |
| `recomputeDiscoverEligibleOnUserWrite` | Present — `us-central1` (not redeployed) |

---

## Unauthenticated smoke test

| Item | Value |
|------|--------|
| Request | `POST https://europe-west1-qmatch-53d62.cloudfunctions.net/finalizeFrequencyV2` body `{"data":{}}` |
| Auth token | none |
| Result | HTTP **401** — `UNAUTHENTICATED` / "Authentication required to finalize Frequency V2." |
| Authenticated finalization | **NO** |
| Production Frequency V2 result writes | **0** |

Auth is checked before the Firestore transaction, so this smoke test created
no `users/{uid}/assessments/frequency_v2` documents.

---

## Activation / ranking / Discover (unchanged)

| Item | Status |
|------|--------|
| `FrequencyBehaviorV2BankRegistry.isRuntimeSelectable()` | `false` |
| Release/default Frequency track | V1 |
| Debug/default Frequency track | V1 |
| Internal debug V2 dart-define | not used this phase |
| Live Discover ranking | `structural_l2_v1` |
| V2 Discover grant source | prepared, **not live** |
| Grandfather cohort | unchanged |
| Stage B2 / pair-fit / fusion | not deployed / not switched |

---

## Explicit non-actions

| Action | Executed |
|--------|----------|
| Deploy `recomputeDiscoverEligibleOnFrequencyV2Write` | **NO** |
| Redeploy `recomputeDiscoverEligibleOnUserWrite` | **NO** |
| Deploy `finalizeIq` / `finalizeEq` / `finalizeFrequency` | **NO** |
| Deploy Stage B2 / pair-fit / fusion / ranking | **NO** |
| Deploy `firestore.rules` / storage / indexes / hosting | **NO** |
| Authenticated `finalizeFrequencyV2` invoke | **NO** (reserved for 8C.3) |
| Flutter V2 release activation | **NO** |
| Production user / result writes | **NO** |
| Grandfather migration | **NO** |
| `runtime_selectable` flipped | **NO** — remains `false` |

Authenticated physical-device V2 end-to-end testing belongs to Phase 8C.3.
V2-aware Discover trigger deploy belongs to Phase 8C.4.
