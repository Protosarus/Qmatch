# QMatch Phase 7G.4C — Trusted Discover production cutover

Date: 2026-09-04
Mode: controlled production cutover
Firebase project: `qmatch-53d62`

This record documents the operational cutover of trusted Discover eligibility
and Firestore completion-flag protection. It is not a Flutter release,
Frequency V2 activation, grandfather rerun, or user-data rewrite.

---

## Recovery source

| Item | Value |
|------|--------|
| Repository | Protosarus/Qmatch |
| Source commit | `1699bdc6a9323807d3b2ecf3ad6cd515b201e926` |
| Branch | `main` |
| `HEAD` / `origin/main` at cutover | identical to the commit above |
| Working tree at cutover start | clean |

---

## Pre-deploy trusted audit

Command:

```text
python3 tool/trusted_discover_cutover_dry_run_v1.py --execute-dry-run
```

| Field | Count |
|-------|------:|
| `total_users_scanned` | 40 |
| `stored_true_derived_true` | 10 |
| `stored_false_derived_false` | 30 |
| `stored_true_derived_false` | 0 |
| `stored_false_derived_true` | 0 |
| `trusted_v1_eligible` | 0 |
| `grandfather_eligible` | 10 |
| `derived_eligible_total` | 10 |
| `mismatches_total` | 0 |

`writes_performed`: **false**
Timestamp (UTC): `2026-09-04T05:07:21.353989+00:00`

Pre-cutover Discover backfill: **NOT REQUIRED**.

---

## Function deploy

| Item | Value |
|------|--------|
| Function | `recomputeDiscoverEligibleOnUserWrite` |
| Region | `us-central1` |
| Runtime | Node.js 22 (2nd Gen) |
| Trigger | `google.cloud.firestore.document.v1.written` |
| Command | `firebase deploy --only functions:recomputeDiscoverEligibleOnUserWrite --project qmatch-53d62 --non-interactive` |
| Result | **Successful update operation** |
| Other functions deployed | **NO** |
| `finalizeIq` / `finalizeEq` / `finalizeFrequency` | Present — `europe-west1` |
| `finalizeFrequencyV2` | **Absent** |

No production user mutation was used as a smoke test. No manufactured
Firestore event.

---

## Post-function trusted audit

Timestamp (UTC): `2026-09-04T05:11:52.534577+00:00`

| Field | Count |
|-------|------:|
| `total_users_scanned` | 40 |
| `stored_true_derived_true` | 10 |
| `stored_false_derived_false` | 30 |
| `stored_true_derived_false` | 0 |
| `stored_false_derived_true` | 0 |
| `trusted_v1_eligible` | 0 |
| `grandfather_eligible` | 10 |
| `derived_eligible_total` | 10 |
| `mismatches_total` | 0 |

`writes_performed`: **false**

---

## Client-writer check before rules

Live Frequency pipeline does not write `test_completed` or
`assessment_flow_completed`.

`AssessmentProgressService.markAssessmentFlowCompleted()` leftover does not
write those flags.

`AuthService.updateTestCompletion()` still exists and can set
`test_completed=true`, but it has **no live caller**.

Signup still writes `test_completed=false` (allowed).

---

## Firestore rules deploy

| Item | Value |
|------|--------|
| Command | `firebase deploy --only firestore:rules --project qmatch-53d62 --non-interactive` |
| Compilation | `firestore.rules` compiled successfully |
| Result | **released rules `firestore.rules` to cloud.firestore** |
| Functions in same command | **NO** |
| Indexes published | **NO** — CLI read `firestore.indexes.json` only |
| Hosting / storage / other products | **NO** |
| Real production user mutation test | **NO** |
| Emulator rules suite | **157** passing |

Protected after deploy:

- client cannot self-grant `test_completed=true`
- client cannot self-grant `assessment_flow_completed=true`
- client cannot arbitrarily mutate `test_completed_at`
- owner cannot write `assessment_verification_v1`

Create still allows omitted flags or `test_completed=false` /
`assessment_flow_completed=false`.

---

## Final trusted audit

Timestamp (UTC): `2026-09-04T05:23:25.057103+00:00`

| Field | Count |
|-------|------:|
| `total_users_scanned` | 40 |
| `stored_true_derived_true` | 10 |
| `stored_false_derived_false` | 30 |
| `stored_true_derived_false` | 0 |
| `stored_false_derived_true` | 0 |
| `trusted_v1_eligible` | 0 |
| `grandfather_eligible` | 10 |
| `derived_eligible_total` | 10 |
| `mismatches_total` | 0 |

`writes_performed`: **false**

Stored eligibility stayed stable through cutover. The 10 eligible users remain
the reviewed grandfather cohort. Trusted V1 production eligible is still 0.

---

## Security state after cutover

Discover `true` now requires:

- trusted IQ + EQ + Frequency V1, **or** reviewed `pre_c2_preserved` +
  `pre_trust_migration_preserved`
- plus `active`, `profile_completed`, valid photo, and
  `account_deletion_requested != true`

Client `test_completed=true` or `assessment_flow_completed=true` alone cannot
grant Discover. Clients also cannot newly self-grant those true values under
production rules.

Historical `test_completed` / `assessment_flow_completed` / `test_completed_at`
were **not** deleted. The 10 grandfather users were **not** rewritten.

---

## Explicit non-actions

| Action | Executed |
|--------|----------|
| Discover backfill | **NOT REQUIRED / NOT RUN** |
| Manual production user writes | **NO** |
| Grandfather migration rerun | **NO** |
| Assessment results changed | **NO** |
| `canonical_v1` changed | **NO** |
| Matching changed | **NO** |
| Flutter source changed | **NO** |
| Frequency V2 deployed / activated | **NO** |
| `runtime_selectable` flipped | **NO** — remains `false` |
| Other Cloud Functions deployed | **NO** |
