# Account Deletion Execute Processor Skeleton (Phase 3P-A14)

Date: 2026-07-18
Status: **EXECUTE SKELETON — DESTRUCTIVE PATH DISABLED**
Script: `tool/account_deletion_processor_execute.py`

Related:

- `docs/account_deletion_processor_plan.md`
- `docs/account_deletion_processor_dry_run_skeleton.md`
- `tool/account_deletion_processor_dry_run.py`

---

## Explicit warning

**This phase does not delete anything.**

- No Firestore writes to users / requests / matches / threads
- No Auth `delete_user`
- No Storage `blob.delete`
- `executeEnabled: false`
- `EXECUTE_IMPLEMENTED = False`
- Attempting `--dry-run=false` (even with the confirmation phrase) is **refused** until a later phase implements mutations

Local JSON under `build/` is the only file write allowed.

---

## Why execute is still disabled

1. Dry-run inventory and Storage listing were only recently stabilized.
2. Irreversible Auth/Storage/Firestore deletes need a reviewed plan + disposable-account rehearsal.
3. Keeping planning and mutation in separate phases reduces accidental wipe risk.
4. AST self-check ensures this skeleton contains **no** mutation call attributes (`.delete`, `.update`, `.set`, `.commit`, `.delete_user`, …).

---

## Required gates for future execution

| Gate | Requirement |
|------|-------------|
| Explicit `--uid` | Single bare uid; no batch, commas, wildcards (`*`, `all`) |
| Credentials | `QMATCH_FIRESTORE_ADMIN_CREDENTIALS` absolute path **outside** repo |
| Storage bucket | `QMATCH_FIREBASE_STORAGE_BUCKET` (e.g. `qmatch-53d62.firebasestorage.app`) — **required** when `--dry-run=false` |
| Default mode | `--dry-run=true` (planning) |
| Execute intent | `--dry-run=false` **and** `--confirmation-phrase=PROCESS_ACCOUNT_DELETION_REQUESTS` |
| Implementation flag | `EXECUTE_IMPLEMENTED=True` (still **False** in 3P-A14) |
| Code self-check | AST scan must pass before any future mutation code is added carefully |

---

## How to run planning mode (safe)

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"

python3 tool/account_deletion_processor_execute.py --uid=<FIREBASE_UID>
# equivalent: --dry-run=true
```

Self-check only (no Firebase):

```bash
python3 tool/account_deletion_processor_execute.py --uid=placeholder --self-check-only
```

Refuse examples:

```bash
# missing phrase
python3 tool/account_deletion_processor_execute.py --uid=<UID> --dry-run=false

# phrase present but execute not implemented → still REFUSED
python3 tool/account_deletion_processor_execute.py \
  --uid=<UID> --dry-run=false \
  --confirmation-phrase=PROCESS_ACCOUNT_DELETION_REQUESTS
```

---

## Planned operation order

(Recorded in the plan JSON; **not executed**.)

1. Validate gates
2. Read-only inventory (reuses dry-run inventory)
3. Claim `account_deletion_requests/{uid}` → `processing`
4. Close/anonymize matches
5. Close threads; redact previews
6. Redact/delete sender messages (policy)
7. Delete user subcollections (assignments, assessments, swipes, blocks)
8. Delete Storage `profile_photos/{uid}/**`
9. Delete or tombstone `users/{uid}`
10. Delete Firebase Auth user (**last**)
11. Finalize request → `completed` + audit fields
12. Retain reports; never touch `assessment_sets` / `questions`

---

## Report output

`build/account_deletion_execute_plan_<masked_uid>.json`

Includes:

- `uid_masked`, `dryRun`, `executeEnabled: false`
- `destructiveOperationsPerformed: false` (+ Auth/Storage/Firestore write flags false)
- `plannedOperationCounts`, `plannedSequence`
- Planned delete / anonymize / Storage / Auth / status groups
- `unresolvedItems`, `safetyGates`
- `nextManualReviewRequired: true`

---

## What remains manual

- Human review of the execute plan JSON before any future mutation phase
- Disposable-account-only testing when execute is later enabled
- Ops monitoring of `support@qmatch.app` and pending request SLA (30 days)
- Index/IAM fixes if inventory queries fail
- Legal retention decisions for reports / blocks

---

## How to test only with a disposable account

1. Use the phone test account already used for deletion-request QA (not a real customer).
2. Run dry-run inventory, then this execute **planner** with `--dry-run=true`.
3. Review `build/account_deletion_execute_plan_*.json`.
4. **Do not** enable `EXECUTE_IMPLEMENTED` or pass `--dry-run=false` until a dedicated phase implements and reviews mutations.

---

## Rollback limitations

Once a future phase actually deletes Auth / Storage / Firestore data, rollback is generally **impossible** without backups. Treat execute as one-way. Planning mode has no rollback need (no remote mutations).

---

## Phase 3P-A14 non-actions

- No real deletion
- No Auth / Storage deletion
- No Firestore writes (except local `build/` plan file when planning is run)
- No Cloud Function / rules deploy
- No commit / push
