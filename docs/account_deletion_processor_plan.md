# Privileged Account Deletion Processor Plan (Phase 3P-A11)

Date: 2026-07-18
Project: `qmatch-53d62`
Status: **DESIGN ONLY — NO DESTRUCTIVE EXECUTION**

Related:

- In-app request flow: Settings → Delete account → `account_deletion_requests/{uid}`
- Soft marker: `users/{uid}.account_deletion_requested = true`
- Published rules allow owner request writes (verified 3P-A10)
- User-facing promise: process within **30 days**

---

## 1. Goal

Build a **privileged** processor (Admin SDK / service account) that fulfills pending deletion requests by removing or anonymizing personal data while retaining limited safety/legal records — **without** relying on the mobile client to wipe Auth, Storage, or relational data.

This document does **not** delete anything. No Cloud Function deploy. No destructive Admin SDK run.

---

## 2. Data model inventory (inspected)

| Area | Path / usage |
|------|----------------|
| User profile | `users/{uid}` — name, age, photos[], `profile_photo_url`, bio, preferences, IQ/EQ/Frequency fields, `frequency_vector`, soft deletion markers |
| Assignments | `users/{uid}/assessment_assignments/{iq\|eq\|frequency}` |
| Assessment results | `users/{uid}/assessments/{docId}` (e.g. frequency) |
| Swipes | `users/{uid}/swipes/{targetUid}` |
| Blocks | `users/{uid}/blocks/{blockedUid}` |
| Deletion requests | `account_deletion_requests/{uid}` |
| Matches | `matches/{matchId}` — `users` array, reveal state, `thread_id` |
| Threads | `threads/{threadId}` — `participants`, previews, unread |
| Messages | `threads/{threadId}/messages/{messageId}` — `sender_id`, text |
| Reports | `reports/{reportId}` — `reporter_uid`, `reported_uid`, reason, status |
| Assessment content | `assessment_sets/*`, `questions/*` — **global; never delete for a user** |
| Auth | Firebase Auth (phone / email providers) |
| Storage | `profile_photos/{uid}/{fileName}` (+ URLs on user doc) |

---

## 3. Recommended processor style

### Choice: **Hybrid — local Admin SDK one-shot first, Cloud Function later**

| Option | Pros | Cons | Fit now |
|--------|------|------|---------|
| Cloud Function scheduled/manual | Automation, SLA | Needs deploy, IAM, monitoring, harder to dry-run safely at this stage | Later |
| Local Admin SDK one-shot | Explicit ops approval, dry-run + confirmation phrase, matches existing `tool/admin_publish_*` pattern | Manual SLA | **Best first** |
| Hybrid | Prove delete order on 1–2 test accounts, then automate | Two stages | **Recommended** |

**Why safer for current stage**

1. Project already uses credential-gated, phrase-gated Admin one-shots for sensitive work.
2. Deletion is irreversible; a human-gated first processor reduces blast radius.
3. Cloud Function before proven dry-run/idempotency risks silent mass deletes.
4. After 3–5 successful test-account runs + audit logs, promote the same steps to a scheduled Function with the same gates (status machine, dry-run flag off only in prod with alerts).

---

## 4. What should be deleted

For a target `uid` with `account_deletion_requests/{uid}.status == "requested"` (or `"processing"`):

### Firestore — delete (prefer) or clear

| Path | Action |
|------|--------|
| `users/{uid}/assessment_assignments/*` | Delete all docs |
| `users/{uid}/assessments/*` | Delete all docs |
| `users/{uid}/swipes/*` | Delete all docs |
| `users/{uid}/blocks/*` | Delete all docs (see retention note if needed for mutual safety) |
| `users/{uid}` | Delete doc **after** subcollections + media (or replace with tombstone — see anonymization) |
| Messages sent by user in their threads | Delete message docs where `sender_id == uid` **or** redact text (policy choice; see §5) |
| Orphaned empty threads | Optional cleanup after both sides gone |

### Storage

| Path | Action |
|------|--------|
| `profile_photos/{uid}/**` | Delete all objects under prefix |
| URLs on profile | Cleared when user doc deleted/anonymized |

### Firebase Auth

| Step | Action |
|------|--------|
| Last step (after data) | `auth.delete_user(uid)` so the account cannot sign in again |

### Never delete for user deletion

- `assessment_sets/*`
- `questions/*`
- Other users’ profiles
- Entire `matches` / `threads` documents without handling the **other** participant (see §5–§6)

---

## 5. What may need anonymization instead of hard delete

| Data | Recommendation |
|------|----------------|
| `matches/{matchId}` where user is a member | **Anonymize / close**, do not leave live Discoverable profile. Set `state` to `closed`/`deleted_user`, replace display refs, strip reveal photo consent to safe defaults. Keep doc so the other user’s history does not break queries mid-migration. |
| `threads/{threadId}` | Set `status: closed`, `closed_reason: account_deleted`, clear `last_message_preview` if it contains PII, zero unread for deleted uid. |
| Message bodies from deleted user | Prefer **redact** to `[deleted]` + clear attachments rather than breaking thread pagination; or hard-delete sender messages if product prefers. |
| `reports` where user is reporter or reported | **Retain** with uid → opaque `deleted_user_<hash>` remapping **or** keep raw uid in a sealed compliance store (see retention). Do **not** delete all reports involving the user. |
| `account_deletion_requests/{uid}` | **Retain** as audit; update status to `completed` (do not delete the request doc). |

---

## 6. What may need temporary retention (safety / legal)

| Record | Retention intent |
|--------|------------------|
| Safety reports (`reports`) | Keep for abuse prevention / legal; strip or hash contact fields if any |
| Block graph involving the user | Optional short retention of “user X was blocked / blocked Y” in ops logs before wiping `users/{uid}/blocks` |
| Deletion request audit | Keep `account_deletion_requests/{uid}` indefinitely or per policy (status, timestamps, processor id) |
| Auth UID | May remain in retained reports as opaque identifier after Auth user is deleted |
| Server logs / analytics | Follow existing log retention; avoid exporting full profiles into long-lived logs |

Align copy already shown in-app: safety reports and limited compliance logs may be kept for a limited time; dating profile must not stay active.

---

## 7. Firestore / Storage / Auth paths (processor checklist)

**Inputs**

- `account_deletion_requests/{uid}` (`status == requested`)
- Optional filter: `requested_at` older than N hours (cooling period) for automation later

**Mutations (privileged only)**

1. Request → `status: processing`, `processing_started_at`, `processed_by`
2. Close/anonymize matches + threads for uid
3. Redact/delete messages as policy
4. Delete user subcollections
5. Delete Storage `profile_photos/{uid}/`
6. Delete or tombstone `users/{uid}`
7. Delete Auth user
8. Request → `status: completed`, `processed_at`, `final_deletion_status: completed`, counts/summary
9. On failure → `status: failed` or return to `requested` with `last_error` (see retry)

**Forbidden**

- Any write to `assessment_sets`
- Client SDK execution of this processor
- Deleting another user’s `users/{otherUid}` doc

---

## 8. Order of operations (recommended)

```
0. Preconditions
   - Service account credentials present
   - --dry-run default true
   - --confirmation-phrase required when dry-run=false
   - Target uid(s) explicitly listed OR single-doc mode
   - status is requested (or processing + stale lock reclaim)

1. Claim request (idempotent)
   - Transition requested → processing if still requested
   - Write processing_started_at, processed_by, attempt++

2. Inventory (read-only pass even in execute mode)
   - Count swipes, blocks, assessments, matches, threads, storage objects
   - Log masked uid + counts (no phone/email plaintext in logs)

3. Relational close (other user still exists)
   - matches: close/anonymize
   - threads: close + redact previews
   - messages: redact or delete per policy

4. Personal data purge
   - Delete subcollections under users/{uid}
   - Delete Storage profile_photos/{uid}/
   - Delete or anonymize users/{uid}

5. Auth delete
   - auth.delete_user(uid)
   - If Auth already gone: treat as success for this step (idempotent)

6. Finalize request doc
   - status=completed, processed_at, summary counts
   - Never delete the request audit doc in v1

7. Emit audit record (optional collection account_deletion_audit/{id})
```

**Rationale for Auth last:** if Auth is deleted first, recovery/debug of partial Firestore state is harder while the user cannot re-auth; finishing data first then Auth matches “account closed” semantics. If Auth delete fails after data wipe, mark `failed` with `auth_delete_pending` for retry (Auth-only step).

---

## 9. Idempotency strategy

| Mechanism | Detail |
|-----------|--------|
| Status machine | `requested` → `processing` → `completed` \| `failed` |
| Claim with precondition | Only claim if `status == requested` (or `processing` and `processing_started_at` older than lock TTL, e.g. 1h) |
| Per-step checkpoints | Store `steps_completed: ["matches_closed", "storage_deleted", …]` on the request doc |
| Skip completed steps | Re-run reads “already missing” as OK |
| Deterministic match/thread ids | Safe to re-query `users` arrayContains uid |
| Auth delete | `user-not-found` ⇒ step OK |
| Storage delete | Missing prefix ⇒ step OK |
| Single flight | One processor worker per uid |

---

## 10. Failure / retry strategy

| Failure | Action |
|---------|--------|
| Transient Firestore/Storage | Retry with backoff; leave `processing` + increment `attempt` |
| Permanent (bad data) | `status=failed`, `last_error`, alert ops; do **not** auto Auth-delete if inventory incomplete |
| Partial success | Keep checkpoints; next run resumes |
| Exceeded attempts | Stay `failed`; manual ops review |
| Do not silently revert to empty rules / wipe other collections | |

Alerts: email/Slack when `requested_at` > 25 days still not `completed` (SLA buffer before 30-day promise).

---

## 11. Audit fields (on `account_deletion_requests/{uid}`)

Ops-only fields (clients already forbidden by rules):

| Field | Purpose |
|-------|---------|
| `status` | `requested` \| `processing` \| `completed` \| `failed` \| `cancelled` |
| `processing_started_at` | Claim time |
| `processed_at` | Completion time |
| `processed_by` | Service account email / job id |
| `final_deletion_status` | Mirror of outcome |
| `admin_notes` | Human notes |
| `deleted_at` | Optional synonym for completion |
| `steps_completed` | Array of step ids |
| `attempt` | Integer |
| `last_error` | Truncated error string |
| `summary` | Counts deleted/redacted |

---

## 12. Dry-run mode requirement

**Default `dry-run=true`.**

Dry-run must:

- Authenticate with Admin SDK (read)
- List targets and print planned actions + counts
- **Not** call delete/update on user data, Auth, or Storage
- **Not** change request status (or only write to a separate dry-run log file locally)

Execute mode (`dry-run=false`) additionally requires confirmation phrase (below).

---

## 13. Confirmation phrase requirement

Mirror existing admin publish safety:

```text
Required phrase (example): PROCESS_ACCOUNT_DELETION_REQUESTS
```

Refuse execute mode unless:

1. `QMATCH_FIRESTORE_ADMIN_CREDENTIALS` points to a key **outside** the repo
2. `--dry-run=false`
3. `--confirmation-phrase=PROCESS_ACCOUNT_DELETION_REQUESTS`
4. Explicit `--uid=<single>` for v1 (no “process all” without a second phrase like `PROCESS_ALL_PENDING_DELETIONS`)

---

## 14. Service account / privileged execution requirement

| Requirement | Detail |
|-------------|--------|
| Execution | Admin SDK only (bypasses client rules) |
| Credentials | Env var path outside git; never commit JSON keys |
| IAM | Least privilege: Firestore read/write on needed collections, Storage objectAdmin on `profile_photos/`, Auth Admin delete user |
| Forbidden | Client app, anonymous auth, CI without manual approval |
| Humans | Ops runbook; dual control optional for “process all” |

---

## 15. Rollback limitations

**Deletion is largely irreversible.**

| After step | Rollback |
|------------|----------|
| Matches closed / messages redacted | Partial restore from backups only (if any) |
| Storage deleted | Restore from Storage versioning/backup if enabled (assume **not** unless configured) |
| User doc deleted | Restore from backup only |
| Auth deleted | User must re-register; old uid cannot be restored as same Auth user easily |

Therefore: dry-run + single-uid execute + test accounts first. Do not promise Console “undo.”

---

## 16. Privacy risks

| Risk | Mitigation |
|------|------------|
| Leaving Discoverable profile after “deleted” | Soft marker + Discover filter short-term; hard purge in processor |
| Orphan PII in message previews | Redact thread previews |
| Reports deleted too aggressively | Retain / anonymize, don’t wipe |
| Logs printing phone/email | Mask contacts (already on request doc) |
| Wrong uid processed | Require explicit `--uid`; refuse batch without second phrase |
| assessment_sets wiped by bug | Hard-code deny list; refuse any write to `assessment_sets` / `questions` |

---

## 17. Launch readiness recommendation

| Item | Status |
|------|--------|
| In-app request + rules | Done |
| User-facing 30-day copy | Done |
| Privileged processor | **Not built** — plan only (this doc) |
| Soft-hide pending users from Discover | Recommended quick client follow-up (non-destructive) |
| SLA monitoring | Needed before calling launch “complete” for deletion |

**App Store / privacy:** Initiation is satisfied; **fulfillment** must exist in ops capacity within 30 days. For launch, a **manual Admin one-shot** + monitored `support@qmatch.site` can be acceptable if documented in runbook and capacity is real. Automate after proven.

**Launch readiness for deletion fulfillment:** **Conditional / Medium** until at least dry-run inventory + one test-account execute succeeds.

---

## 18. Non-destructive discovery helper

See `tool/discover_account_deletion_requests_readonly.py`:

- Lists pending `status == requested` via Admin SDK when credentials provided
- Prints **count** + **masked UIDs** only
- **No** deletes, updates, Auth, or Storage calls

Default without credentials: prints usage and exits (no network required).

---

## 19. Explicit non-actions (this phase)

- No real user data deleted
- No Auth / Storage deletion
- No destructive Admin SDK script run
- No Cloud Function deploy
- No Firestore rules deploy
- No `assessment_sets` writes
- No commit / push

---

## 20. Recommended next implementation phase

**3P-A12:** Implement Admin SDK processor skeleton with **dry-run only** inventory for one `--uid`, then a gated execute path tested on a disposable test account — still refusing `assessment_sets` and requiring confirmation phrase.
