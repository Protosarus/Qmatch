# QMatch Phase 7G.4B.1 — Trusted Discover pre-deploy audit record

Date: 2026-09-03
Mode: narrow freeze + production read-only audit
Firebase project: `qmatch-53d62`

This record stores aggregate classification counts only. It is not a
Discover deploy, rules deploy, Flutter release, Firestore write, or
Frequency V2 activation.

---

## Recovery source

| Item | Value |
|------|--------|
| Repository | Protosarus/Qmatch |
| 7G.4B baseline | `9a4f5452b07a89044082c4031c86f36b88b6c992` |
| Branch | `main` |
| Working tree at 7G.4B.1 start | clean; `HEAD` == `origin/main` == baseline |

---

## Why this micro-phase ran

1. The frozen PRE-TRUST helper imported live `hasValidPhoto` from
   `discover_eligibility.js`. Historical photo semantics are now inlined as
   `legacyHasValidPhoto` inside
   `functions/src/legacy_discover_eligibility_pre_trust_v1.js` with no live
   Discover import.
2. The 7G grandfather classifier treated stored-false + old-formula-false as
   `not_eligible` before checking trusted V1 modules. Those counts do not
   prove stored-false users stay false under the **new** trusted Discover
   formula. A new read-only audit was required.

7G grandfather cohort semantics were not changed.

---

## Frozen PRE-TRUST photo rule

Valid photo if:

- `profile_photo_url` is a non-empty trimmed string, **OR**
- `photos` contains at least one non-empty trimmed string

Historical formula (unchanged):

```text
active == true
AND (test_completed == true OR assessment_flow_completed == true)
AND profile_completed == true
AND legacyHasValidPhoto
AND account_deletion_requested != true
```

---

## Dry-run command

```text
python3 tool/trusted_discover_cutover_dry_run_v1.py --execute-dry-run
```

Executed with the ops Python that has `firebase-admin` installed.
Credentials: `QMATCH_FIRESTORE_ADMIN_CREDENTIALS` (absolute path outside the
repo). The script contains no Firestore mutation calls.

| Item | Value |
|------|--------|
| Policy | `trusted_discover_cutover_dry_run_v1` |
| Collection | `users` |
| Mode | `dry_run_read_only` |
| Timestamp (UTC) | `2026-09-03T20:01:02.740156+00:00` |
| Grandfather execute tool | **NOT RUN** |
| Discover / rules deploy | **NOT RUN** |

Audit formula matches live JS `deriveDiscoverEligible`:

```text
account_deletion_requested != true
AND active == true
AND profile_completed == true
AND hasValidPhoto
AND (
  trusted IQ + EQ + Frequency V1
  OR pre_c2_preserved + pre_trust_migration_preserved
)
```

Not used as a grant: `test_completed`, `assessment_flow_completed`,
`flow=complete` alone, Frequency V2.

---

## Aggregate counts

Exact fields emitted by the tool. No UIDs, emails, names, phones, photos,
answers, or profile contents.

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

Bucket sum 10 + 30 + 0 + 0 = 40, matching `total_users_scanned`.
`derived_eligible_total` 10 = `trusted_v1_eligible` 0 + `grandfather_eligible` 10.

---

## Interpretation

| Check | Result |
|-------|--------|
| `mismatches_total` == 0 | **Yes** |
| `stored_true_derived_false` | **0** |
| `stored_false_derived_true` | **0** |
| Pre-cutover Discover backfill required | **No** — stored `discover_eligible` already matches the new trusted formula |

The 10 stored-true users are the completed 7G grandfather cohort
(`pre_c2_preserved` + `pre_trust_migration_preserved`). No production user
currently has a full trusted V1 battery (IQ + EQ + Frequency V1). The 30
stored-false users remain false under the new formula.

---

## Explicit non-actions

| Action | Executed |
|--------|----------|
| Firestore writes executed | **0** |
| Production data changed | **NO** |
| `assessment_trust_grandfather_execute_v1.py` | **NOT RUN** |
| Discover Cloud Function deployed | **NO** |
| `firestore.rules` deployed | **NO** |
| Flutter released | **NO** |
| Frequency V2 deployed / activated | **NO** |
| `runtime_selectable` flipped | **NO** — remains `false` |
