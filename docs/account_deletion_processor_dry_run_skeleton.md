# Account Deletion Processor — Dry-Run Skeleton (Phase 3P-A12)

Date: 2026-07-18  
Status: **DRY-RUN SKELETON ONLY — NOT AN EXECUTION PROCESSOR**

Related: `docs/account_deletion_processor_plan.md`

---

## Warning

This is **not** an execution processor yet.

- It never deletes Auth users, Storage files, or Firestore data.
- It refuses `--dry-run=false`.
- Future execute mode (confirmation phrase `PROCESS_ACCOUNT_DELETION_REQUESTS`) is **not implemented**.

---

## How to run dry-run for one UID

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json

python3 tool/account_deletion_processor_dry_run.py --uid=<FIREBASE_UID>
```

Optional local safety scan (no Firebase):

```bash
python3 tool/account_deletion_processor_dry_run.py --uid=placeholder --self-check-only
```

(`--uid` is still required by argparse; self-check does not use it.)

---

## What it reads (Admin SDK, read-only)

For the explicit `--uid` only:

| Area | Access |
|------|--------|
| `account_deletion_requests/{uid}` | get |
| `users/{uid}` | get (field keys + deletion marker + photo refs) |
| `users/{uid}/assessment_assignments` | count / sample ids |
| `users/{uid}/assessments` | count / sample ids |
| `users/{uid}/swipes` | count / sample ids |
| `users/{uid}/blocks` | count / sample ids |
| `matches` where `users` array_contains uid | query |
| `threads` where `participants` array_contains uid | query |
| `threads/.../messages` | sample counts (capped) |
| `reports` where reporter/reported == uid | query |
| Storage prefix `profile_photos/{uid}/` | list (if bucket configured) |
| Firebase Auth | `get_user` existence only |

UIDs in the JSON report are **masked** (`faUts7…` style). Phone/email are not printed.

---

## What it does not do

- No Firestore `set` / `update` / `delete` / `batch.commit`
- No Auth `delete_user`
- No Storage object delete
- No writes to `assessment_sets` or `questions`
- No status changes on `account_deletion_requests`
- No Cloud Function deploy

The only write allowed: **local** JSON under `build/`.

---

## Forbidden operation guards

1. **CLI:** `--dry-run=false` → refuse and exit  
2. **Runtime:** `runtime_guard` requires `dryRun is True`  
3. **AST self-check:** scans this script for forbidden call attrs (`.delete`, `.update`, `.set`, `.commit`, `.delete_user`, …) before inventory  
4. **Credentials:** must be absolute path **outside** the repo; key contents never printed  

---

## Expected output

Console:

```text
dryRun=true uid_masked=<masked>
report=build/account_deletion_processor_dry_run_<masked>.json
destructiveOperationsPerformed=false
firestoreWritesPerformed=false authDeletePerformed=false storageDeletePerformed=false
```

JSON report fields include:

- `dryRun: true`
- `destructiveOperationsPerformed: false`
- `authDeletePerformed` / `storageDeletePerformed` / `firestoreWritesPerformed`: false  
- `collections_inventoried`, `doc_counts_summary`  
- `unresolved_manual_review_items`, `warnings`  
- `proposed_deletion_anonymization_sequence`  

---

## Phase 3P-A12 run status

| Item | Status |
|------|--------|
| Script created | Yes |
| Docs created | Yes |
| Live inventory against disposable QA user | **Not run** — full UID not available in-repo (only masked `faUts7…` from prior QA). Per phase rules: do not invent/run without explicit UID. |

When the ops operator has the disposable phone test UID:

```bash
python3 tool/account_deletion_processor_dry_run.py --uid=<that_uid>
```

---

## Next steps before any real execution

1. Run dry-run for one disposable test UID; review `build/account_deletion_processor_dry_run_*.json`  
2. Confirm matches/threads/reports queries and Storage listing succeed (indexes/IAM)  
3. Implement execute processor in a **separate** file/phase with:  
   - default dry-run  
   - `--dry-run=false`  
   - `--confirmation-phrase=PROCESS_ACCOUNT_DELETION_REQUESTS`  
   - explicit `--uid`  
   - step checkpoints / idempotency from the plan  
4. Test execute only on disposable accounts  
5. Then consider Cloud Function automation  

---

## Explicit non-actions (this phase)

- No real deletion  
- No Auth/Storage deletion  
- No Firestore writes (except local `build/` report if a dry-run inventory is later executed)  
- No commit / push  
