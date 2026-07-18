# Account Deletion Processor — Dry-Run Skeleton (Phase 3P-A12 / A13)

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
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"

python3 tool/account_deletion_processor_dry_run.py --uid=<FIREBASE_UID>
```

### Storage bucket env var

| Env | Required? | Purpose |
|-----|-----------|---------|
| `QMATCH_FIRESTORE_ADMIN_CREDENTIALS` | Yes (for inventory) | Admin SDK service account JSON path (outside repo) |
| `QMATCH_FIREBASE_STORAGE_BUCKET` | Optional | Firebase Storage bucket name for **read-only** `profile_photos/{uid}/` listing |

Known console bucket: `qmatch-53d62.firebasestorage.app`

If `QMATCH_FIREBASE_STORAGE_BUCKET` is **missing**:

- Dry-run **continues** (does not fail the whole run)
- Report adds unresolved item: `Storage bucket env missing; storage inventory skipped.`
- No Storage API calls are made

If set:

- Admin app may initialize with `storageBucket`
- Script lists objects under `profile_photos/{uid}/` only
- **Read-only inventory** — never `blob.delete()`, never Storage writes
- Object names in the report are UID-masked

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
| Storage prefix `profile_photos/{uid}/` | list **only if** `QMATCH_FIREBASE_STORAGE_BUCKET` set |
| Firebase Auth | `get_user` existence only |

UIDs in the JSON report are **masked** (`faUts7…` style). Phone/email are not printed.

---

## What it does not do

- No Firestore `set` / `update` / `delete` / `batch.commit`
- No Auth `delete_user`
- No Storage object delete (`blob.delete` never called)
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
5. **Storage:** inventory optional via env; list-only; never delete  

Flags in every report:

- `destructiveOperationsPerformed: false`
- `firestoreWritesPerformed: false`
- `authDeletePerformed: false`
- `storageDeletePerformed: false`

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
- `collections_inventoried` (incl. `storage_profile_photos`)  
- `doc_counts_summary`  
- `unresolved_manual_review_items`, `warnings`  
- `proposed_deletion_anonymization_sequence`  

---

## Phase notes

| Item | Status |
|------|--------|
| Dry-run skeleton (3P-A12) | Yes |
| Storage bucket env fix (3P-A13) | Yes |
| Live re-inventory | Not required this phase unless operator re-runs with UID + bucket env |

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"
python3 tool/account_deletion_processor_dry_run.py --uid=<disposable_test_uid>
```

---

## Next steps before any real execution

1. Re-run dry-run for disposable test UID **with** Storage bucket env; confirm `listed_object_count` (or empty prefix) without `ValueError`  
2. Implement execute processor in a **separate** file/phase with confirmation phrase  
3. Test execute only on disposable accounts  
4. Then consider Cloud Function automation  

---

## Explicit non-actions

- No real deletion  
- No Auth/Storage deletion  
- No Firestore writes (except local `build/` report when inventory is run)  
- No commit / push  
