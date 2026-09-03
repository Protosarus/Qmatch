# QMatch Phase 7G.4A — Grandfather production apply record

Date: 2026-09-03
Mode: controlled production migration
Firebase project: `qmatch-53d62`

This record stores aggregate facts only. It is not a Discover cutover, rules
change, Flutter release, function deploy, or Frequency V2 activation.

Write scope was exclusively `users/{uid}.assessment_verification_v1` for
users classified as `grandfather_candidate`.

---

## Recovery source

| Item | Value |
|------|--------|
| Repository | Protosarus/Qmatch |
| Source commit | `04bcc6ffa97614c7bc8743e272110b37e9979971` |
| Branch | `main` |
| `HEAD` / `origin/main` at apply | identical to the commit above |
| Working tree at apply | clean |

---

## Pre-apply dry-run

Command:

```text
python3 tool/assessment_trust_grandfather_dry_run_v1.py --execute-dry-run
```

Timestamp (UTC): `2026-09-03T19:26:48.885910+00:00`

| Field | Count |
|-------|------:|
| `total_users_scanned` | 40 |
| `grandfather_candidates` | 10 |
| `already_trusted_complete` | 0 |
| `already_pre_c2_preserved` | 0 |
| `stored_eligible_but_formula_false` | 0 |
| `formula_true_but_stored_false` | 0 |
| `not_eligible` | 30 |
| `malformed_verification` | 0 |
| `planned_writes` | 10 |

Matched the reviewed 7G.3 cohort exactly. Apply proceeded.

---

## Execute

| Item | Value |
|------|--------|
| Command | `python3 tool/assessment_trust_grandfather_execute_v1.py --execute --confirm PRE_TRUST_MIGRATION_V1` |
| Confirmation gate | `PRE_TRUST_MIGRATION_V1` |
| Policy | `assessment_trust_grandfather_execute_v1` |
| Timestamp (UTC) | `2026-09-03T19:27:56.906965+00:00` |
| `writes_executed` | **10** |
| `batches_committed` | 1 |
| Field scope | `assessment_verification_v1` only |
| Expected flow | `pre_c2_preserved` |
| Expected grant_reason | `pre_trust_migration_preserved` |
| Expected schema_version | `assessment_verification_v1` |
| Catalog version | preserved if valid, else `assessment_finalize_catalog_v1` |
| Fake module verification created | **NO** |
| `frequency_v2` created | **NO** |

---

## Post-apply dry-run

Command:

```text
python3 tool/assessment_trust_grandfather_dry_run_v1.py --execute-dry-run
```

Timestamp (UTC): `2026-09-03T19:28:05.105364+00:00`

| Field | Count |
|-------|------:|
| `total_users_scanned` | 40 |
| `grandfather_candidates` | 0 |
| `already_trusted_complete` | 0 |
| `already_pre_c2_preserved` | 10 |
| `stored_eligible_but_formula_false` | 0 |
| `formula_true_but_stored_false` | 0 |
| `not_eligible` | 30 |
| `malformed_verification` | 0 |
| `planned_writes` | 0 |

Population remained 40. Idempotency: `grandfather_candidates = 0`, `planned_writes = 0`. Execute was **not** run a second time.

---

## Explicit non-actions

| Action | Executed |
|--------|----------|
| Discover changed | **NO** |
| `firestore.rules` changed / deployed | **NO** |
| Cloud Functions deployed | **NO** |
| `assessments/*` changed | **NO** |
| `profiles/canonical_v1` changed | **NO** |
| `public_profiles` changed | **NO** |
| Frequency V2 changed / activated | **NO** |
| `runtime_selectable` flipped | **NO** — remains `false` |
| Flutter / AssessmentProgressService changed | **NO** |
| Trusted Discover cutover | **NOT THIS PHASE** |

---

## Production trusted-finalize inventory (list only)

| Function | Production status |
|----------|-------------------|
| `finalizeIq` | Present — v2 callable, `europe-west1` |
| `finalizeEq` | Present — v2 callable, `europe-west1` |
| `finalizeFrequency` | Present — v2 callable, `europe-west1` |
| `finalizeFrequencyV2` | **Not deployed** |

Frequency V2 remains dormant. `runtime_selectable=false`.
