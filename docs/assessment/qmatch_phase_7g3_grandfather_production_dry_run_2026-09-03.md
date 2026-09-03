# QMatch Phase 7G.3 — Grandfather production dry-run record

Date: 2026-09-03
Mode: production read-only audit
Firebase project: `qmatch-53d62`

This record stores aggregate classification counts only. It is not a migration
apply, function deploy, Discover change, rules change, Flutter release, or
Frequency V2 activation.

---

## Recovery source

| Item | Value |
|------|--------|
| Repository | Protosarus/Qmatch |
| Source commit | `07eef5f311c8a124d9621ac59c37e0fab34735fb` |
| Branch | `main` |
| `HEAD` / `origin/main` at scan | identical to the commit above |
| Working tree at scan | clean |

---

## Dry-run command

```text
python3 tool/assessment_trust_grandfather_dry_run_v1.py --execute-dry-run
```

| Item | Value |
|------|--------|
| Policy | `assessment_trust_grandfather_dry_run_v1` |
| Collection | `users` |
| Mode | `dry_run_read_only` |
| Timestamp (UTC) | `2026-09-03T19:23:35.538631+00:00` |
| Execute tool | **NOT RUN** |
| `--execute` / `--confirm PRE_TRUST_MIGRATION_V1` | **NOT USED** |

---

## Aggregate counts

Exact fields emitted by the tool:

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

`writes_performed`: **false**

Classification sum 10 + 0 + 0 + 0 + 0 + 30 + 0 = 40, matching `total_users_scanned`.

---

## Safety interpretation

| Check | Result |
|-------|--------|
| `planned_writes` == `grandfather_candidates` | **Yes** — 10 == 10 |
| `already_trusted_complete` would be written | **No** — count 0; policy write is `None` |
| `already_pre_c2_preserved` would be written | **No** — count 0; policy write is `None` |
| `stored_eligible_but_formula_false` grandfathered | **No** — count 0; not a candidate |
| `formula_true_but_stored_false` grandfathered | **No** — count 0; not a candidate |
| `malformed_verification` automatically written | **No** — count 0; not a candidate |
| Fake module verification created | **No** — dry-run does not write |

---

## Explicit non-actions

| Action | Executed |
|--------|----------|
| Firestore writes executed | **0** |
| Production data changed | **NO** |
| `assessment_trust_grandfather_execute_v1.py` | **NOT RUN** |
| Discover changed | **NO** |
| `firestore.rules` changed / deployed | **NO** |
| Cloud Functions deployed | **NO** |
| Flutter released | **NO** |
| Frequency V2 deployed / activated | **NO** |
| `runtime_selectable` flipped | **NO** — remains `false` |

---

## Production trusted-finalize inventory (unchanged this phase)

Observed in Phase 7G.2 / 7G.3 list; this phase deployed nothing.

| Function | Production status |
|----------|-------------------|
| `finalizeIq` | Present — v2 callable, `europe-west1` |
| `finalizeEq` | Present — v2 callable, `europe-west1` |
| `finalizeFrequency` | Present — v2 callable, `europe-west1` |
| `finalizeFrequencyV2` | **Not deployed** |

Frequency V2 remains dormant. `runtime_selectable=false`.
