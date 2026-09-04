# Frequency V2 — Activation readiness (Phase 8C.1)

**Status:** source + tests only. **Not activated. Not deployed.**
**Date:** 2026-09-04
**Baseline:** `7b4bd98583e907e5a9a8a6ff87cbc61deff9ea3a`
**`runtime_selectable`:** `false`
**Live Discover ranking:** `structural_l2_v1` (unchanged)
**Firebase project:** `qmatch-53d62`

This phase prepares everything required **before** the first controlled
Frequency V2 production/device test. It does **not** deploy
`finalizeFrequencyV2`, flip release runtime to V2, change live ranking, or
write production users.

---

## EXISTS / MISSING / BUILD NOW

### EXISTS / REUSE

| Piece | Location |
|-------|----------|
| 12D contract, 426/405/21, selector, scorer, confidence | `frequency_behavior_v2_*` |
| Reviewed TR/EN pools + review metadata | `tool/frequency_behavior_v2/out/` |
| `finalizeFrequencyV2` (registered, not deployed) | `functions/src/finalize_frequency_v2_v1.js` |
| Flutter V2 runtime bridge / session / pending pipeline | `lib/features/assessment/domain/frequency_v2_runtime/` |
| Strict V2 result parser | `functions/src/frequency_behavior_v2_result_parser.js` |
| Server pair-fit + 8B.2 fusion | `frequency_behavior_v2_pair_fit.js`, `compatibility_fusion_v2.js` |
| Trusted Discover V1 grant + grandfather | `discover_eligibility.js`, `assessment_verification_flow_v1.js` |
| Owner-read / client-write-denied `frequency_v2` rules | `firestore.rules` |

### MISSING / BUILT IN 8C.1

| Gap | Built |
|-----|--------|
| Reviewed banks not Flutter assets | `assets/assessment/frequency_v2/` + `pubspec.yaml` |
| Drift between `tool/` and runtime copies | `tool/sync_frequency_v2_runtime_assets.py --check/--sync` |
| Loader defaulted to `Directory.current` / `tool/` | AssetBundle default; filesystem injection remains |
| No debug-only device route | `QMATCH_FREQUENCY_V2_INTERNAL` in `FrequencyRuntimeSelectionPolicy` |
| Discover could not see V2 (user-doc-only derive) | `deriveDiscoverEligibleWithAssessmentProof` |
| V2 result writes do not trigger `users/{uid}` onWrite | `recomputeDiscoverEligibleOnFrequencyV2Write` (source, not deployed) |
| User-write handler could revoke V2-only users | Admin-read V2 when PATH A/C do not already grant |

### OUT OF SCOPE (not done here)

- `firebase deploy`
- `isRuntimeSelectable() = true`
- Live ranking switch to fusion
- 6D → 12D conversion
- Grandfather auto-V2
- Writing `assessment_verification_v1.frequency` from V2

---

## Runtime asset architecture

Reviewed source of truth:

`tool/frequency_behavior_v2/out/`

Runtime copies (exact byte copies, no question rewrites):

| Asset | Version |
|-------|---------|
| `assets/assessment/frequency_v2/frequency_behavior_pool_tr_v2_draft1.json` | `frequency_behavior_pool_tr_v2_draft1` / `tr-TR` |
| `assets/assessment/frequency_v2/frequency_behavior_pool_tr_v2_draft1_review_metadata.json` | drop/selectable + near-duplicate clusters |
| `assets/assessment/frequency_v2/frequency_behavior_pool_en_v2_draft1.json` | `frequency_behavior_pool_en_v2_draft1` / `en-US` |
| `assets/assessment/frequency_v2/frequency_behavior_pool_en_v2_draft1_review_metadata.json` | EN review metadata |

Review metadata **is** bundled because the selector needs drop exclusions and
near-duplicate clusters.

Exact copies of the reviewed `tool/` artifacts. Byte SHA-256 / canonical JSON
SHA-256:

| File | byte SHA256 | canonical JSON SHA256 |
|------|-------------|------------------------|
| TR pool | `028801a8496f1103700f611315a8a9cfdb18149f47f2c684a1157ceea57f3930` | `4b09e94c0beb296e14fde598625445dc425f557397abf0d56571f9df2a14cda9` |
| TR review | `41112252105c6cd4bcf750ec1098274665809fc42b7796d417e92567d3855c8d` | `84b3f9982ed0497e075ad1829cffebc7935db8d69e392e59a7b5d0fccf127a75` |
| EN pool | `4f22083f2ba6d750173dfa6d36c068555a1d6c15b79914761da46ee8d4c874b4` | `73aa71dbec2bc3b5adab7dd9b5ccb80466143cdf3bfda960abceac01d092aea2` |
| EN review | `ae148770312edd629f4c54014f156cfd6cadd535c5d4e94cf88c59c82b4020c1` | `b46f09335fd8682b043f6a700a338035d410dbb7b4baca667d0a81315f7ac556` |

Parity:

```
python3 tool/sync_frequency_v2_runtime_assets.py --check
python3 tool/sync_frequency_v2_runtime_assets.py --sync
```

`--check` requires byte equality and SHA-256 / canonical JSON SHA-256 match.

`FrequencyV2BankLoader` default uses `rootBundle` and
`assets/assessment/frequency_v2/…`. Tests/tooling may pass `repoRoot` to read
`tool/` sources. Production does not use `Directory.current`.

---

## Debug-only V2 route

`FrequencyRuntimeSelectionPolicy` is the only reader of:

`--dart-define=QMATCH_FREQUENCY_V2_INTERNAL=true`

Rules:

| Build | Track |
|-------|--------|
| release / profile / default | **V1** |
| debug without define | **V1** |
| debug + define | **V2** (test access only) |

`FrequencyBehaviorV2BankRegistry.isRuntimeSelectable()` remains **false**.
Screens must not inspect the define.

Conceptual later device command (not run in 8C.1, because finalize is undeployed):

```
flutter run --dart-define=QMATCH_FREQUENCY_V2_INTERNAL=true
```

---

## Trusted Discover grant (`trusted_discover_assessment_grant_v2`)

Profile requirements unchanged:

`active == true` AND `profile_completed == true` AND valid photo AND
`account_deletion_requested != true`

Assessment trust:

| Path | Proof |
|------|--------|
| A — V1 | trusted IQ **and** EQ **and** Frequency V1 (`assessment_verification_v1`) |
| B — V2 | trusted IQ **and** EQ **and** parser-accepted `users/{uid}/assessments/frequency_v2` |
| C — grandfather | `flow=pre_c2_preserved` AND `grant_reason=pre_trust_migration_preserved` |

`assessment_verification_v1.frequency` remains **Frequency V1 only**. V2 is a
separate document. No 12D→6D. No manufactured `frequency_completed` /
`test_completed` / `assessment_flow_completed`.

Wrong schema / source / status / type / dimensions / ranges **do not grant**.

`deriveDiscoverEligible(userData)` stays the user-only V1/grandfather helper.
Shared production derivation is:

```
deriveDiscoverEligibleWithAssessmentProof(userData, { frequencyV2Result })
```

V2 proof is never copied onto `users/{uid}`.

---

## Cross-document triggers (source-registered, not deployed in 8C.1)

| Trigger | Region | When | Read | Write |
|---------|--------|------|------|--------|
| `recomputeDiscoverEligibleOnUserWrite` | `us-central1` (existing) | `users/{uid}` write | user doc; Admin-read V2 only if PATH A/C do not already grant | `discover_eligible` only |
| `recomputeDiscoverEligibleOnFrequencyV2Write` | `europe-west1` | `users/{uid}/assessments/frequency_v2` write | current user doc + this V2 result | `discover_eligible` only |

Same derivation. Write only when stored ≠ derived. No `updated_at` churn.
No completion / canonical / `assessment_verification_v1.frequency` writes.

`finalizeFrequencyV2` still writes **only**
`users/{uid}/assessments/frequency_v2`. Discover recomputation belongs to the
authority trigger (after 8C.4 deploy).

Firestore rules are unchanged: owner read, client create/update/delete denied.
Admin triggers are not constrained by client rules.

---

## Grandfather continuity

The existing 10 grandfather users remain eligible **without** V2.

- grandfather + no V2 → eligible
- grandfather + valid V2 → eligible
- grandfather + malformed V2 → still eligible (PATH C independent)

Do not downgrade them. Do not auto-issue a V2 result.

---

## Legacy / V2 transition (not live)

Grandfather and current V1 users keep Discover access.

There is **no** V1 6D → V2 12D conversion. Users may complete a **real** V2
later. Only server-finalized V2 results participate in `compatibility_v2`.

Until a pair has real V2 on both sides, `compatibility_v2` may be unavailable.
Therefore live ranking stays `structural_l2_v1` during rollout/testing.

Do **not**:

- mix `structural_distance` and `compatibility_index` on one scale
- rank all V2 users ahead of legacy users merely because V2 exists
- invent a fake migration result

---

## Remaining sequence (do not perform now)

1. **8C.2** — deploy `finalizeFrequencyV2` ONLY + smoke/auth verification
2. **8C.3** — controlled physical-device V2 E2E on a dedicated test account
3. **8C.4** — deploy V2-aware trusted Discover authority triggers after
   read-only/predeploy verification
4. **8C.5** — release runtime V2 activation for the assessment flow
5. **8C.6** — measure real V2 coverage; migrate existing users through real V2
   completion
6. **8C.7** — only when rollout criteria are met, switch live Discover ranking
   from `structural_l2_v1` to `qmatch_compatibility_fusion_v2_policy_v1`

**Activation is not complete. Ranking is unchanged. Release is still V1.**
