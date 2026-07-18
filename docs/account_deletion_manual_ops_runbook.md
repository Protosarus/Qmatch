# Manual Account Deletion Ops Runbook (Phase 3P-A16)

Date: 2026-07-18
Project: `qmatch-53d62`
Status: **Launch ops guidance — no destructive execution in this document’s creation phase**

Related:

- `docs/account_deletion_processor_plan.md`
- `docs/account_deletion_processor_dry_run_skeleton.md`
- `docs/account_deletion_execute_processor_skeleton.md`
- `docs/account_deletion_execute_plan_review.md`
- `tool/discover_account_deletion_requests_readonly.py`
- `tool/account_deletion_processor_dry_run.py`
- `tool/account_deletion_processor_execute.py`

---

## Current launch posture

| Item | Status |
|------|--------|
| In-app deletion **request** (Settings → Delete account) | **Live** |
| Owner-only Firestore rules for `account_deletion_requests/{uid}` | **Published** |
| Soft marker `users/{uid}.account_deletion_requested` | **Written by app** |
| Destructive automation (`EXECUTE_IMPLEMENTED`) | **Not enabled** |
| Fulfillment method for launch | **Manual ops required** |
| Support mailbox | **`support@qmatch.site` must be monitored** |
| User-facing SLA | Process within **30 days** |

Do **not** run `--dry-run=false` or enable automated wipe until a later, explicitly approved destructive phase.

---

## 1. Purpose

Fulfill user account deletion requests safely and on time when:

- A user submits an in-app request, and/or
- A user emails `support@qmatch.site` asking to delete their account

This runbook covers **discovery, verification, dry-run review, manual fulfillment steps, documentation, and support replies**. It does **not** authorize casual destructive commands.

---

## 2. Who should perform deletion operations

| Role | Allowed |
|------|---------|
| Founder / tech lead with Firebase Admin access | Yes (primary) |
| Designated ops engineer with least-privilege Admin IAM | Yes |
| Customer support (mailbox only) | Triage + templates only — **no** Admin deletes unless dual-trained and approved |
| Contractors / shared laptops without personal accountability | **No** |
| Automated CI without human approval | **No** |

Prefer **two-person review** before any irreversible Auth/Storage wipe.

---

## 3. Required access level

| System | Access |
|--------|--------|
| Firebase Console | Project `qmatch-53d62` — Firestore read; Auth/Storage delete only when executing |
| Service account | Firestore + Auth Admin + Storage object admin on `profile_photos/` (least privilege) |
| Credentials | JSON key path **outside** the git repo |
| Env | `QMATCH_FIRESTORE_ADMIN_CREDENTIALS`, `QMATCH_FIREBASE_STORAGE_BUCKET` |

Never commit service account keys. Never paste private keys into chat/tickets.

---

## 4. Service account safety rules

1. Key file lives **outside** the repository (absolute path only).
2. Never print or log key JSON contents.
3. Rotate keys if leaked or when operators leave.
4. Use env vars:

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"
```

5. Prefer one named operator session; do not share unlocked terminals.
6. For inventory/planning, use **read-only / dry-run** tools only.
7. Refuse batch “delete all pending” without a separate written approval.

---

## 5. How to find pending deletion requests

### A. Read-only discovery (preferred)

```bash
cd "/path/to/Qmatch-main 2"
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json

python3 tool/discover_account_deletion_requests_readonly.py --list-pending
```

Output: pending count + **masked** UIDs only. No writes.

### B. Firebase Console

1. Firestore → collection `account_deletion_requests`
2. Filter / scan where `status == requested`
3. Open doc id (= uid) and note `requested_at`, `source`, acknowledgements

### C. Soft markers

Users with `users/{uid}.account_deletion_requested == true` should also have a request doc; investigate orphans if marker exists without request.

---

## 6. How to verify the requester UID

Before any destructive work:

1. Confirm `account_deletion_requests/{uid}.uid` equals the document id.
2. Confirm `status == requested`.
3. Confirm `user_acknowledged_irreversible == true` and `user_acknowledged_timeline == true`.
4. Confirm `source` (usually `in_app`).
5. Cross-check Auth: user still exists (phone/email providers) — do **not** paste full phone/email into tickets; mask contacts.
6. If request came by email only: verify the sender controls the account phone/email before linking to a uid.
7. If unsure → stop and use the “need more information” template.

---

## 7. How to run dry-run inventory

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"

python3 tool/account_deletion_processor_dry_run.py --uid=<EXACT_FIREBASE_UID>
```

Expect:

- `dryRun=true`
- all `*Performed=false`
- Local report: `build/account_deletion_processor_dry_run_<masked>.json` (under gitignored `/build/`)

---

## 8. How to review affected data (execute planner — planning only)

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"

python3 tool/account_deletion_processor_execute.py --uid=<EXACT_FIREBASE_UID> --dry-run=true
```

Expect:

- `executeEnabled=false`
- `EXECUTE_IMPLEMENTED=false`
- Report: `build/account_deletion_execute_plan_<masked>.json`
- `nextManualReviewRequired=true`

**Do not** pass `--dry-run=false`. Destructive execute is not enabled for launch automation.

---

## 9. What data should be deleted

When manually fulfilling (Console or future gated Admin tools), target **this uid only**:

| Area | Action |
|------|--------|
| `users/{uid}/assessment_assignments/*` | Delete |
| `users/{uid}/assessments/*` | Delete |
| `users/{uid}/swipes/*` | Delete |
| `users/{uid}/blocks/*` | Delete (after optional short retention note) |
| `users/{uid}` | Delete or tombstone after subcollections/media |
| Storage `profile_photos/{uid}/**` | Delete all objects under prefix |
| Firebase Auth user | Delete **last** |

Never delete: `assessment_sets/*`, `questions/*`, other users’ profiles.

---

## 10. What data should be anonymized / closed

| Area | Action |
|------|--------|
| `matches` containing uid | Close / anonymize so the other user is not left with a live profile of the deleted user |
| `threads` containing uid | Close; redact `last_message_preview` if it contains PII |
| Messages with `sender_id == uid` | Redact to `[deleted]` or delete per product policy |
| Display names / photo URLs lingering in caches | Clear as part of match/thread cleanup |

---

## 11. What may be retained (safety / legal)

| Record | Guidance |
|--------|----------|
| `reports` involving the user | **Retain**; optionally anonymize display fields later |
| `account_deletion_requests/{uid}` | **Retain** as audit; set status to `completed` (do not delete the request doc in v1) |
| Limited abuse / compliance logs | Retain per legal policy; not for dating profile reactivation |
| Soft marker history | Covered by request audit + optional tombstone |

Align with in-app copy: safety reports and limited compliance logs may be kept; profile must not remain active.

---

## 12. How to document completion

Create an internal ops note (ticket / shared doc — not in public git unless sanitized):

| Field | Example |
|-------|---------|
| Date | ISO date |
| Operator | Name |
| UID (masked) | `faUts7…` |
| Request `requested_at` | … |
| Dry-run report path | local `build/…` (do not commit) |
| Plan review | Approved by … |
| Steps completed | Auth / Storage / Firestore checklist |
| Exceptions | e.g. “0 storage objects” |
| Support reply sent | Yes/No + template used |

Optional: store `admin_notes` / `processed_by` on the request doc when updating status (Admin SDK / Console).

---

## 13. How to update request status manually later

In Firebase Console → `account_deletion_requests/{uid}` (Admin / privileged only):

| Stage | Suggested fields |
|-------|------------------|
| Start work | `status: processing`, `processing_started_at`, `processed_by` |
| Success | `status: completed`, `processed_at`, `final_deletion_status: completed`, summary counts |
| Failure | `status: failed` or return to `requested`, `last_error` (truncated) |

Clients cannot set ops fields under current rules (by design).

**This runbook creation phase does not perform those writes.**

---

## 14. How to contact the user

Primary: reply to their email if they wrote support.
If only in-app request: use Auth-linked email if present; otherwise reply is optional after completion unless they contacted support.

Always use **`support@qmatch.site`** as the from-address for consistency.
Do not promise instantaneous deletion; reference the 30-day processing window when acknowledging.

Templates: §17.

---

## 15. Timeline / SLA

| Milestone | Target |
|-----------|--------|
| Acknowledge (if email) | ASAP / within a few business days |
| Full fulfillment | **Within 30 days** of `requested_at` |
| Internal alert | Escalate if still `requested` after **~25 days** |

Track pending via discovery script weekly until volume is low.

---

## 16. Rollback limitations

After Auth and Storage deletion, restoration is generally **impossible** without backups (assume none).
Partial Firestore deletes are also hard to undo.
Treat every destructive step as **one-way**. Prefer dry-run + second approval first.

---

## 17. Emergency stop conditions

**Stop immediately** if any of the following occur:

- UID mismatch or wrong account suspected
- Request `status` is not `requested` / already `completed`
- Acknowledgements missing on the request doc
- Dry-run shows unexpected large matches/threads and you lack capacity to anonymize the other party safely
- Tools attempt to touch `assessment_sets` or `questions`
- Operator is unsure / fatigued / using shared credentials
- Legal hold / active safety investigation involving the uid
- Confirmation phrase or execute flags appear in a command you did not intend

Resume only after a second human review.

---

## 18. Checklist before any future destructive deletion

Use this **before** a later approved destructive phase (or careful Console wipe):

- [ ] Confirm exact `--uid` / Console doc id
- [ ] Confirm `account_deletion_requests/{uid}` exists
- [ ] Confirm `status == requested`
- [ ] Confirm `user_acknowledged_irreversible == true`
- [ ] Confirm `user_acknowledged_timeline == true`
- [ ] Run dry-run inventory for that uid
- [ ] Review dry-run JSON + execute plan JSON (`--dry-run=true` only)
- [ ] Verify plan forbids / does not touch `assessment_sets` and `questions`
- [ ] Second human approval recorded
- [ ] Only then may a **future explicit destructive phase** be considered

**No destructive execute command is provided in this runbook.**

---

## 19. Safe commands only (copy/paste)

### Discover pending (read-only)

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
python3 tool/discover_account_deletion_requests_readonly.py --list-pending
```

### Dry-run inventory (one UID)

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"
python3 tool/account_deletion_processor_dry_run.py --uid=<EXACT_FIREBASE_UID>
```

### Execute planner (planning only)

```bash
export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"
python3 tool/account_deletion_processor_execute.py --uid=<EXACT_FIREBASE_UID> --dry-run=true
```

### Forbidden for launch automation

- `tool/account_deletion_processor_execute.py --dry-run=false …`
- Any scripted Auth/Storage/Firestore delete loops
- Writes to `assessment_sets` or `questions`

---

## 20. Customer support templates (EN / TR)

Replace bracketed placeholders. Send from **`support@qmatch.site`**.

### 20.1 Deletion request received

**EN — Subject:** We received your Qmatch deletion request

```text
Hi,

We received your request to delete your Qmatch account.

We will process it within 30 days. This is a permanent deletion request (not temporary deactivation). Some safety or legal records may be kept for a limited time when required.

If you have questions, reply to this email.

— Qmatch Support
support@qmatch.site
```

**TR — Konu:** Qmatch hesap silme talebin alındı

```text
Merhaba,

Qmatch hesabını silme talebinizi aldık.

Talebi 30 gün içinde işleyeceğiz. Bu geçici deaktivasyon değil, kalıcı silme talebidir. Gerekli olduğunda bazı güvenlik veya yasal kayıtlar sınırlı süre saklanabilir.

Soruların için bu e-postaya yanıt verebilirsin.

— Qmatch Destek
support@qmatch.site
```

### 20.2 Deletion processing

**EN — Subject:** Your Qmatch deletion request is being processed

```text
Hi,

We are currently processing your Qmatch account deletion request.

You do not need to take further action. We will follow up when processing is complete (within the 30-day window from your request).

— Qmatch Support
support@qmatch.site
```

**TR — Konu:** Qmatch silme talebin işleniyor

```text
Merhaba,

Qmatch hesap silme talebin şu anda işleniyor.

Ek bir işlem yapman gerekmiyor. İşlem tamamlandığında (talepten itibaren 30 günlük süre içinde) bilgilendireceğiz.

— Qmatch Destek
support@qmatch.site
```

### 20.3 Deletion completed

**EN — Subject:** Your Qmatch account deletion is complete

```text
Hi,

Your Qmatch account deletion request has been completed.

Your profile and related account data have been removed according to our process. Limited safety or legal records may remain where required. You will no longer be able to sign in with this account.

If you believe this was a mistake or need help, reply to this email.

— Qmatch Support
support@qmatch.site
```

**TR — Konu:** Qmatch hesap silme işlemin tamamlandı

```text
Merhaba,

Qmatch hesap silme talebin tamamlandı.

Profilin ve ilgili hesap verilerin sürecimize göre kaldırıldı. Gerekli olduğunda sınırlı güvenlik veya yasal kayıtlar saklanmış olabilir. Bu hesapla artık giriş yapamazsın.

Bunun bir hata olduğunu düşünüyorsan veya yardıma ihtiyacın varsa bu e-postaya yanıt ver.

— Qmatch Destek
support@qmatch.site
```

### 20.4 Cannot verify request / need more information

**EN — Subject:** We need more information to process your Qmatch deletion request

```text
Hi,

We received a message about deleting a Qmatch account, but we could not verify it yet.

Please reply with:
1) The phone number or email used to sign in to Qmatch, and
2) Confirmation that you want permanent account deletion (not temporary deactivation).

We process verified requests within 30 days.

— Qmatch Support
support@qmatch.site
```

**TR — Konu:** Qmatch silme talebin için ek bilgi gerekli

```text
Merhaba,

Hesap silme ile ilgili bir mesaj aldık ancak henüz doğrulayamadık.

Lütfen yanıtında şunları belirt:
1) Qmatch’e girişte kullandığın telefon veya e-posta,
2) Geçici deaktivasyon değil, kalıcı hesap silme istediğin onayı.

Doğrulanan talepleri 30 gün içinde işleriz.

— Qmatch Destek
support@qmatch.site
```

---

## 21. Remaining blockers (engineering / ops)

| Blocker | Notes |
|---------|--------|
| Automated execute disabled | Manual fulfillment required for SLA |
| Dual-control / ticket system | Optional but recommended as volume grows |
| Discover soft-hide for pending users | Product follow-up (non-destructive) |
| Mailbox monitoring | Confirm `support@qmatch.site` is staffed |
| Disposable destructive rehearsal | Only in a later **explicit** approved phase |

---

## 22. Explicit non-actions

Creating or reading this runbook must not include:

- Real user data deletion
- Auth / Storage deletion
- Firestore writes
- Destructive Admin SDK runs
- Rules / Cloud Function deploys
- Git commit / push

---

## 23. Recommended next step

1. Assign an owner for weekly pending-request discovery.
2. Confirm `support@qmatch.site` monitoring.
3. Practice the **safe** commands on a disposable test uid (dry-run + plan only).
4. Keep automated destructive execute for a later, explicitly approved phase.
