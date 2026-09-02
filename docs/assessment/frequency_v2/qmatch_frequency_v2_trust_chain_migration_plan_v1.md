# Frequency V2 — Trust-chain migration plan v1

**Status:** architecture freeze (Phase 7E.2) — documentation only
**Authority:** Phase 7E.1 trust-chain audit of the post-7D repository
**Runtime:** dormant — `runtime_selectable` remains `false`

This document freezes the migration decision from client-trusted assessment completion toward server-trusted verification **without implementing it**. It does **not** change Cloud Functions, Firestore rules, Flutter, Discover eligibility, or Frequency V2 activation.

Phase 7D implemented `finalizeFrequencyV2` (registered locally, **not deployed**). That callable writes only `users/{uid}/assessments/frequency_v2`. It does not grant Discover, does not write completion mirrors, and does not activate V2.

**Persistence / finalization readiness does not constitute activation approval.**

---

## Mandatory assertions

- **`users/{uid}/assessments/frequency_v2` is currently the trusted V2 proof.**
- **`assessment_verification_v1.frequency` remains V1-only.**
- **No `frequency_v2` verification sibling is added in Phase 7E.2.**
- **Discover formula remains unchanged.**
- **Completion rules remain unchanged.**
- **Current Discover assessment trust remains spoofable through client completion flags.**
- **This security gap must be fixed before claiming trusted global completion.**
- **Historical completion cannot be retrospectively proven.**
- **No activation occurs.**
- **`runtime_selectable=false`.**

---

## Concept separation (do not collapse)

These are six different authorities. One flag must never stand for all of them.

| # | Concept | Current Frequency V2 state |
|---|---------|----------------------------|
| 1 | **Assessment RESULT authority** | **READY** — server scores and persists `qmatch_frequency_behavior_v2_result_v1` |
| 2 | **Assessment COMPLETION authority** | **READY** through the private V2 result document (`status: completed`, Admin-written) |
| 3 | **Onboarding ROUTING mirrors** | Unchanged client mirrors (`iq_completed` / `eq_completed` / `frequency_completed` / flow flags). V2 does not write them |
| 4 | **Discover ELIGIBILITY authority** | Server-writes `discover_eligible`, but **derives it from client-writable completion inputs**. Trusted Discover migration: **NOT READY** |
| 5 | **Matching SCORE consumption** | Still V1 6D via `canonical_v1`. V2 12D is unused. No 12D → 6D adapter |
| 6 | **Runtime ACTIVATION** | **NOT APPROVED.** Flutter is not wired. `runtime_selectable=false`. Callable not deployed |

Specifically:

- Frequency V2 **result authority:** READY
- Frequency V2 **completion proof:** READY through the private result document
- **Global trusted assessment battery:** NOT READY
- **Trusted Discover migration:** NOT READY
- **V2 Flutter runtime:** NOT WIRED
- **V2 activation:** NOT APPROVED

Do not present Phase 7D or this plan as completing the security migration.

---

## 1. Current trust state

Authority: live code inspected in Phase 7E.1.

### Discover grant (`trusted_discover_eligibility_authority_v1`)

Writer: `recomputeDiscoverEligibleOnUserWrite` → `deriveDiscoverEligible` in `functions/src/discover_eligibility.js`.

Canonical condition (unchanged by this phase):

```
active == true
AND (test_completed == true OR assessment_flow_completed == true)
AND profile_completed == true
AND hasPhoto
AND account_deletion_requested != true
```

`discover_eligible=true` may be written only by Admin SDK. Clients may set `discover_eligible=false`. The Cloud Function re-grants `true` if the formula still holds.

### What Discover does **not** read

- `iq_completed`, `eq_completed`, `frequency_completed`
- `assessment_verification_v1`
- `users/{uid}/assessments/frequency_v2`
- `users/{uid}/assessments/{iq,eq,frequency}`
- `canonical_v1`

### Module completion proofs today

| Module | Server finalize | User-doc verification | Result document | Client completion mirrors |
|--------|-----------------|----------------------|-----------------|---------------------------|
| IQ | `finalizeIq` (`admin_finalize_iq_v1`) — **structure only**, not score | `assessment_verification_v1.iq` | Client `assessments/iq` after local score | `iq_completed` (server **and** client) |
| EQ | **None** (`finalizeEq` does not exist) | `assessment_verification_v1.eq` never populated in production | Client `assessments/eq` | `eq_completed` client-writable |
| Frequency V1 | **No live callable.** `validateFrequencyStructure()` is unused in production | `assessment_verification_v1.frequency` reserved for V1; unused in production | Client `assessments/frequency` | `frequency_completed`, `test_completed`, `assessment_flow_completed` client-writable |
| Frequency V2 | `finalizeFrequencyV2` (`admin_finalize_frequency_v2_v1`) — session + **server score** | **Not written.** Sibling deferred | **Trusted:** `assessments/frequency_v2` | **Not written** |

Flutter does not read `assessment_verification_v1`. Routing uses assessment docs, assignments, and user-doc mirrors (`AssessmentProgressService`).

`test_completed` and `assessment_flow_completed` are owner-writable (`firestore.rules` `userProtectedKeysUnchanged` does not protect them). Rules tests currently assert those mirrors remain writable.

---

## 2. Threat model / Discover spoof surface

### Pre-existing gap (not created by V2)

A client can currently satisfy the Discover **assessment** condition by writing:

- `test_completed=true`, **or**
- `assessment_flow_completed=true`

provided `active == true`, `profile_completed == true`, a valid photo exists, and `account_deletion_requested != true`.

Therefore:

**GLOBAL DISCOVER ASSESSMENT TRUST IS NOT YET SERVER-AUTHORITATIVE.**

This is a **pre-existing system-level trust gap**. Frequency V2 does not create it. Phase 7D does not worsen it (`finalizeFrequencyV2` does not write those flags or `users/{uid}`).

Frequency V2 **must not** be presented as completing the security migration.

### Minimal spoof (repo-true)

Signup seeds `active: true` and `discover_eligible: false`. Owner then sets `test_completed` (or `assessment_flow_completed`), `profile_completed`, and a non-empty photo URL. The eligibility Cloud Function grants `discover_eligible=true`. `syncPublicProfileOnUserWrite` copies that boolean onto `public_profiles/{uid}`.

No IQ/EQ/Frequency session is required for that grant. Module mirrors (`iq_completed` / `eq_completed` / `frequency_completed`) are irrelevant to Discover.

### What V2 does **not** change

- Does not add a new client-writable Discover input
- Does not make `frequency_v2` client-writable
- Does not grant `discover_eligible`
- Does not write `test_completed` / `assessment_flow_completed`

---

## 3. Frequency V2 proof decision

**Canonical trusted Frequency V2 result/proof remains:**

```
users/{uid}/assessments/frequency_v2
```

Schema: `qmatch_frequency_behavior_v2_result_v1`
Source: `admin_finalize_frequency_v2_v1`
Writer: Admin SDK via `finalizeFrequencyV2` (`europe-west1`)
Client: owner **read** allowed; create/update/delete **denied**

This document is:

- the **scoring / result authority** (12D `dimensions` + `summary`, integrity hashes)
- the **V2 completion proof** (`status: completed`, session identity, hashes)

Phase 7E.2 does **not** add any user-doc mirror of that proof.

---

## 4. Why `assessment_verification_v1.frequency` is forbidden for V2

`deriveProgressionFlow` in `functions/src/assessment_verification_flow_v1.js` treats `map.frequency` as the **Frequency V1** module:

- `iq + eq + frequency` trusted → `complete`
- Trust is boolean (`status` ∈ `{verified, grandfathered}`)
- There is **no** version/type discriminator on that slot

Reusing `.frequency` for V2 would:

- mark the **V1** battery complete without a V1 Frequency session
- collide with a future `finalizeFrequency` (V1)
- create ambiguity between live 6D Frequency and dormant 12D V2

**Decision frozen:** `assessment_verification_v1.frequency` belongs to Frequency V1 semantics only. V2 must never occupy it.

---

## 5. Why a `frequency_v2` verification sibling is deferred

A future key:

```
assessment_verification_v1.frequency_v2
```

remains an **acceptable design option**. It is **intentionally deferred**. Phase 7E.2 does **not** create it.

Reasons:

1. The V2 result document is already an Admin/server-written proof.
2. No current Flutter or Discover reader needs a sibling.
3. Adding another proof now provides **no live security benefit** (Discover ignores verification entirely).
4. Existing `assessment_verification_v1` writers/readers must first be made **explicitly coexistence-safe** (today the only live writer is `finalizeIq`; Flutter has zero readers; `deriveProgressionFlow` is V1-shaped).
5. V1 `.frequency` must never be confused with V2.
6. Avoid unnecessary duplicate completion state before a consumer exists.

If introduced later, the sibling is a **completion proof only**, not the scoring source of truth. Scoring/result authority remains `users/{uid}/assessments/frequency_v2`.

---

## 6. Result authority vs completion authority

| Layer | V2 today | Must not become |
|-------|----------|-----------------|
| Result / score | Server-derived 12D on `assessments/frequency_v2` | Client-submitted `normalized_behavior` / confidence |
| V2 completion | Same document, `status: completed` | A Discover flag, a routing mirror, or V1 `.frequency` |
| Routing mirrors | Unwritten by V2 | The definition of “V2 done” for Discover |
| Discover | Unrelated until a later trusted-migration phase | “V2 result exists ⇒ eligible” without EQ/V1 (or explicit product retirement) work |
| Matching | Does not consume V2 | Silent 12D → 6D leakage into `canonical_v1` |

IQ already demonstrates the split: `finalizeIq` proves **session structure** (completion-ish); client still **scores**. V2 is stricter on scores (server-authoritative) and still must not be used as global battery/Discover proof.

---

## 7. Legacy-user limitation

The server **cannot** distinguish legitimate historical completions from spoofed client flags.

Implied cohorts (code, not a census):

- Legacy IQ+EQ users (`test_completed` without `assessment_flow_version`) — Discover-eligible without Frequency
- Flow v2 IQ+EQ+Frequency V1 users (`assessment_flow_version == 2` + client mirrors / owner-writable assessment docs)
- Users with `assessment_flow_completed` and/or `test_completed` only
- Users with `assessment_verification_v1.iq` only (IQ structure after C2)
- Users with no verification object (almost all EQ/Frequency users; pre-`finalizeIq` IQ)
- Future V2 users (`assessments/frequency_v2`) — **can** be proven if they used `finalizeFrequencyV2`

There is **no** production migrator that stamps `grandfathered` verification onto existing users. Test-only grandfather shapes in `finalize_iq_v1` tests are not historical proof.

**Do not invent historical proof that does not exist.**

---

## 8. Grandfather semantics

Any future legacy grandfather marker must mean only:

> Eligible under the pre-trust migration system at cutover.

It must **not** claim:

> Server-verified assessment completion.

Honest freeze of `discover_eligible == true` (or an explicit `grant_reason` such as `pre_trust_migration_preserved`) is eligibility continuity, not assessment honesty. Spoofers who already meet the client-flag formula would remain eligible under that freeze.

Existing users still require a grandfather strategy before Discover can require trusted verification. That strategy is **not** implemented in Phase 7E.2.

---

## 9. Required EQ trust work

EQ has no server finalize. `eq_completed` and `assessments/eq` are client-authoritative. `assessment_verification_v1.eq` is unused in production.

Discover does **not** currently require EQ. Onboarding **does** (`AssessmentProgressService` v2 route: IQ → EQ → Frequency).

Before claiming a **trusted global assessment battery**, EQ must receive trusted server-side **completion** verification. Initial implementation may preserve existing client-side EQ **scoring/result** behavior (IQ pattern: structure/completion server-side first).

Do **not** implement `finalizeEq` in this phase.

---

## 10. Required Frequency V1 trust work

Frequency V1 has no live server finalize. Completion flags that **do** feed Discover (`test_completed`, `assessment_flow_completed`) are set by the client at V1 Frequency complete (`AssessmentProgressService.markAssessmentFlowCompleted`, and `FrequencyService.buildUserMirrorFields` if that writer is used).

Before migrating Discover to trusted assessment completion, **either**:

- **B.** Frequency V1 receives trusted server-side completion verification,

**or**

- there is an **explicit product decision** that new users no longer use Frequency V1, plus a migration plan that safely replaces that module (V2 activation is a **separate** decision and is **not** approved here).

Existing users still need §8 grandfathering.

Do **not** implement Frequency V1 finalize in this phase.

---

## 11. Future trusted Discover model

Desired **eventual** model (not this phase):

1. **IQ** — trusted server completion proof (already started; scores still client).
2. **EQ** — trusted server completion proof.
3. **Frequency V1** — trusted server completion proof **or** explicitly retired from the new-user flow.
4. **Frequency V2** — server-authoritative private result/proof (already true for the result document).
5. Server derives trusted **overall** assessment completion (version-aware; V1/V2 coexistence explicit).
6. Discover consumes **that** trusted completion — not client `test_completed` / `assessment_flow_completed`.
7. Clients can no longer self-grant `completion=true` (or Discover inputs).
8. Flutter may **read** completion mirrors for routing but does not authoritatively grant them.
9. `public_profiles` continues to expose only derived `discover_eligible`, never assessment bodies.

Until steps 2–3 (or explicit V1 retirement) plus grandfathering exist, Discover stays on the current formula.

---

## 12. Deployment ordering

Frozen order. Do not skip.

1. **Now (post-7D / 7E.2):** `finalizeFrequencyV2` registered locally, **not deployed**. `runtime_selectable=false`. No Flutter V2 wiring. Discover and completion rules unchanged. V2 proof = `assessments/frequency_v2` only.
2. **Do not** add `assessment_verification_v1.frequency_v2` until a consumer exists and V1/V2 slot coexistence is coded explicitly.
3. **Phase 7F (next, design first):** server-trust completion foundation for **live** modules — `finalizeEq` and Frequency V1 finalize — without activating V2.
4. **Then:** grandfather currently eligible users with §8 semantics.
5. **Then:** change `deriveDiscoverEligible` to trusted completion; lock client true-grants on assessment completion inputs.
6. **Last, separate product decision:** Flutter V2 wiring + `runtime_selectable` + optional Discover consumption of V2. **Not implied by this document.**

Callable deployment of `finalizeFrequencyV2` without Flutter is still **not** V2 activation. It also is **not** required to freeze this plan.

---

## 13. Rollback strategy

- **V2 result docs:** stop calling / disable `finalizeFrequencyV2`; ignore or delete `assessments/frequency_v2`. V1 Frequency, `canonical_v1`, matching, and Discover remain as they are.
- **This plan:** documentation only; revert the markdown. No runtime rollback.
- **Future Discover formula change (not yet):** restore `deriveDiscoverEligible` to the current OR of `test_completed` / `assessment_flow_completed`; keep grandfather markers so already-frozen users are not dropped without a product decision.
- **Never roll Discover forward** until EQ + Frequency V1 (or explicit V1 retirement) and grandfathering are in place.

---

## 14. Activation blockers

V2 must **not** activate while any of the following remain true (this list is not exhaustive of product/UX blockers; it is the **trust** subset):

| Blocker | Status after 7E.2 |
|---------|-------------------|
| `runtime_selectable=false` | Must remain false |
| No Flutter `finalizeFrequencyV2` caller | Must remain unwired |
| Discover still uses client completion flags | Unchanged; **do not** claim trusted Discover |
| EQ lacks server completion verification | Unresolved |
| Frequency V1 lacks live server completion verification | Unresolved |
| No grandfather semantics for existing eligibles | Unresolved |
| No 12D → 6D adapter (intentional) | Matching must not silently consume V2 |
| Global battery not server-trusted | Must not be claimed |

**Security debt — explicit activation blocker:** client-writable `test_completed` / `assessment_flow_completed` can satisfy Discover’s assessment condition. That gap must be fixed before claiming trusted global completion. Fixing it is **out of scope** for Frequency V2 activation itself; it is a **system** trust migration (Phase 7F+).

---

## 15. Explicit next phase

**PHASE 7F — SERVER-TRUST COMPLETION FOUNDATION FOR EXISTING LIVE MODULES**

Separate project phase. **Do not implement in 7E.2.**

Before coding 7F, perform a narrow architecture/design step for:

- `finalizeEq`
- `finalizeFrequency` (Frequency **V1**)

Goal of that design: make **completion proof** server-trusted while **initially preserving** existing client-side scoring/result behavior (IQ-like split).

7F is **not**:

- Frequency V2 activation
- Discover formula change
- Flutter V2 wiring
- `assessment_verification_v1.frequency_v2`
- a 12D → 6D adapter

---

## 16. Non-goals (Phase 7E.2)

- Modify runtime code, Cloud Functions, `firestore.rules`, or Flutter
- Deploy `finalizeFrequencyV2`
- Activate Frequency V2 or EN routing
- Set `runtime_selectable` to `true`
- Change Discover eligibility
- Make completion mirrors server-only
- Create `assessment_verification_v1.frequency_v2`
- Reuse `assessment_verification_v1.frequency` for V2
- Write `users/{uid}` completion / Discover / `canonical_v1` / V1 Frequency / `public_profiles`
- Implement `finalizeEq` or Frequency V1 finalize
- Invent historical assessment proof
- Claim the global assessment battery is server-trusted

---

## V1 / V2 coexistence (reasserted)

- V1 `users/{uid}/assessments/frequency` remains untouched by V2
- V2 `users/{uid}/assessments/frequency_v2` is a separate document
- There is **no** 12D → 6D adapter
- V2 does **not** write `users/{uid}/profiles/canonical_v1`
- V2 does **not** write legacy Frequency mirrors (`frequency_vector`, `frequency_type`, `frequency_tags`, `frequency_score`, `frequency_status`)
- V2 does **not** affect current matching
- V2 does **not** affect the current Discover formula
- `assessment_verification_v1.frequency` remains V1-only

---

## Frozen architecture decisions (checklist)

1. Canonical trusted Frequency V2 result/proof = `users/{uid}/assessments/frequency_v2`
2. Do **not** add `assessment_verification_v1.frequency_v2` yet
3. Do **not** reuse `assessment_verification_v1.frequency` for V2
4. Do **not** change Discover eligibility yet
5. Do **not** make completion mirrors server-only yet
6. Do **not** claim the global assessment battery is server-trusted yet
7. Frequency V2 persistence/finalization readiness does **not** constitute activation approval

---

## References

| Artifact | Path |
|----------|------|
| Phase 7B result contract | `docs/assessment/frequency_v2/qmatch_frequency_v2_result_persistence_contract_v1.md` |
| V2 finalize handler | `functions/src/finalize_frequency_v2_v1.js` |
| Discover derivation | `functions/src/discover_eligibility.js` |
| Verification flow (V1-shaped) | `functions/src/assessment_verification_flow_v1.js` |
| IQ finalize | `functions/src/finalize_iq_v1.js` |
| Routing / client mirrors | `lib/features/assessment/services/assessment_progress_service.dart` |
| Firestore rules | `firestore.rules` |
