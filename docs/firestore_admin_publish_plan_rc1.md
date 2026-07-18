# Firestore Admin SDK Publish Plan — Assessment Content RC1 (Phase 3O-A3C)

**Date:** 2026-07-18  
**Mode:** Plan + dry-run-safe script only — **no Firestore writes**, no real publish, no commit/push  
**Project:** `qmatch-53d62`

---

## 1. Chosen SDK option

**Python + `firebase-admin`**

| Why Python | Why not Node for this repo |
|------------|----------------------------|
| Existing assessment tooling is Python (`export_assessment_sets_v2.py`, validators, audits) | No Node Firebase Admin scripts or `package.json` admin tooling in-repo |
| Same export artifact already produced under `build/assessment_sets_v2/` | Would duplicate validation/export conventions |
| One-shot script fits `tool/` + `scripts/` style | Extra Node toolchain for a single ops publish |

Client Flutter helper remains gated for debug use; **Admin SDK is the preferred one-shot RC1 content publish** after client `permission-denied`.

**Script (dry-run default):** `tool/admin_publish_assessment_rc1_v2.py`

---

## 2. Credential handling rules

| Rule | Detail |
|------|--------|
| Env var | `QMATCH_FIRESTORE_ADMIN_CREDENTIALS` = **absolute path** to service account JSON |
| Location | **Outside** the git repo (script refuses paths under the project root) |
| Never commit | Service account JSON must not enter git, PRs, or Cursor chat |
| Never print | Script never prints private key / full credential JSON |
| Real publish only | Credentials required only when `--dry-run=false` |
| Dry-run | No Firebase init, no network write |

### Recommended file location (outside repo)

```text
~/Secrets/qmatch/qmatch-53d62-firestore-admin.json
```

or

```text
/Users/<you>/Library/Application Support/qmatch/sa-firestore-admin.json
```

Create a dedicated service account in GCP/Firebase Console with **only** the minimum role needed to write Firestore (prefer least privilege; avoid owner). Download the key **once** to the path above.

---

## 3. Payload source

```text
build/assessment_sets_v2/all_assessment_sets_v2.json
```

Regenerate before publish if assets changed:

```bash
python3 scripts/export_assessment_sets_v2.py
python3 scripts/validate_assessment_sets.py --from-dir build/assessment_sets_v2
```

Expected: **150** sets, IDs `iq_set_001_v2` … `frequency_set_050_v2`.

---

## 4. Safety gates (script)

Refuses (no write) if any fail:

1. Source file missing / invalid  
2. `--collection` ≠ `assessment_sets`  
3. Doc count ≠ **150**  
4. Any `id` does not end with **`_v2`**  
5. IQ/EQ/Frequency counts ≠ 50/50/50  
6. Duplicate ids  
7. `--dry-run=false` without exact phrase `SYNC_LOCALIZED_ASSESSMENT_SETS`  
8. Missing `QMATCH_FIRESTORE_ADMIN_CREDENTIALS` on real publish  
9. Credentials path missing, empty, or **inside** the repo  

Writes **only** `assessment_sets/{id}` (bare `*_v2` ids). Never `users`, `messages`, `matches`, `profiles`, `questions`.

Default: **`--dry-run=true`**.

---

## 5. Exact commands

### Dry run (safe — default)

```bash
cd "/path/to/Qmatch-main 2"
python3 scripts/export_assessment_sets_v2.py   # if needed
python3 tool/admin_publish_assessment_rc1_v2.py
# or explicitly:
python3 tool/admin_publish_assessment_rc1_v2.py --dry-run=true
```

Expected dry-run report fields (also written to `build/firestore_admin_publish_rc1_result.json`):

- `mode`: `dryRun`
- `docsConsidered`: `150`
- `docsWritten`: `0`
- `writesPerformed`: `false`
- `versionedIdCount`: `150`
- `targetCollection`: `assessment_sets`

### Real publish — **DO NOT RUN YET**

```bash
# DO NOT RUN YET — requires separate explicit user approval
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS="/Users/<you>/Secrets/qmatch/qmatch-53d62-firestore-admin.json"
pip install firebase-admin   # once, outside repo commit
python3 tool/admin_publish_assessment_rc1_v2.py \
  --dry-run=false \
  --confirmation-phrase=SYNC_LOCALIZED_ASSESSMENT_SETS
```

Expected real publish result:

- `mode`: `write`
- `docsConsidered`: `150`
- `docsWritten`: `150`
- `writesPerformed`: `true`
- `versionedIdCount`: `150`

---

## 6. Final approval phrase required

Before running real publish, user must explicitly approve again (same operational bar as RC1 client attempt), e.g.:

> **EVET, RC1 assessment setlerini Firestore'a Admin SDK ile publish et.**

Plus script gate phrase:

> `SYNC_LOCALIZED_ASSESSMENT_SETS`

---

## 7. Rollback / disable strategy

| Action | Effect |
|--------|--------|
| Set `active: false` on published `*_v2` docs | Assignment skips inactive Firestore sets |
| App fallback | `AssessmentSetService`: Firestore → bundled assets |
| Do not delete blindly | Prefer deactivate; keep v1 untouched |
| Revoke service account key | Stops further Admin publishes |

---

## 8. Relation to Flutter client tool

`tool/publish_assessment_rc1_v2.dart` remains **client** gated helper; anonymous auth disabled. Prefer **this Admin SDK script** for RC1 content publish unless rules are later locked to a known admin UID (option B in `docs/firestore_publish_auth_safety.md`).

---

## 9. Confirmations (this phase)

| Action | Status |
|--------|--------|
| Firestore write | **No** |
| Real publish run | **No** |
| Service account JSON in repo | **No** |
| Assessment JSON edited | **No** |
| Scoring / compatibility changed | **No** |
| Commit / push | **No** |
| Plan doc | **Yes** — this file |
| Dry-run-safe script | **Yes** — `tool/admin_publish_assessment_rc1_v2.py` |
