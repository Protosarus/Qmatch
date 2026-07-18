# Firestore Rules Post-Deploy Verification — Account Deletion (Phase 3P-A10)

Date: 2026-07-18
Project: `qmatch-53d62`
Mode: Verify **manually published** rules; **no re-deploy**

---

## Deploy context

| Item | Status |
|------|--------|
| Local candidate file present | **Yes** — `docs/firestore_rules_candidate_account_deletion_NOT_DEPLOYED.rules` (192 lines) |
| How rules reached production | User manually pasted candidate into Firebase Console → Firestore → Rules → **Publish** |
| This phase redeploy / `firebase deploy` | **Not run** |
| Admin SDK | **Not run** |

---

## Runtime QA environment

| Item | Value |
|------|--------|
| Entry | `tool/runtime_qa_account_deletion_request.dart` |
| Device | iPhone 16e (`7D75D798-8F24-42D0-A7E0-E7D8D0DE97B2`) |
| Auth | Existing non-anonymous phone session |
| UID (masked) | `faUts7…` |
| Anonymous | `false` |

---

## Runtime QA result

**PASSED**

```text
flutter: [AccountDeletionQA] Authenticated uid (masked): faUts7…
flutter: [AccountDeletionQA] isAnonymous=false providers=phone
flutter: [AccountDeletionQA] submit ok=true alreadyRequested=false error=null
flutter: [AccountDeletionQA] request status=requested source=in_app ack_irrev=true ack_time=true
flutter: [AccountDeletionQA] user.account_deletion_requested=true
flutter: [AccountDeletionQA] DONE — no Auth/Storage/data wipe.
```

| Check | Result |
|-------|--------|
| Submit succeeded | **Yes** (`ok=true`) |
| Crash | **No** |
| `permission-denied` | **No** (resolved vs 3P-A6) |
| Destructive wipe | **No** |
| Auth user deleted | **No** |
| Storage deleted | **No** |
| `assessment_sets` write | **No** (not in service path) |

---

## Firestore paths written (current test user only)

| Path | Result |
|------|--------|
| `account_deletion_requests/{currentUid}` | **Created/updated** |
| `users/{currentUid}` soft marker only | **Updated** (`account_deletion_requested`, timestamps) |

No other users, matches, threads, reports, or `assessment_sets` written by this QA.

---

## Positive field verification (read-back)

| Field / condition | Observed |
|-------------------|----------|
| `account_deletion_requests/{uid}` exists | **Yes** |
| `uid` matches current user | **Yes** (service forces auth uid; read-back via owner path) |
| `status` | **`requested`** |
| `source` | **`in_app`** |
| `user_acknowledged_irreversible` | **`true`** |
| `user_acknowledged_timeline` | **`true`** |
| `users/{uid}.account_deletion_requested` | **`true`** |

---

## Negative checks

**No cross-user or `assessment_sets` writes were executed** (safety).

| Check | Method | Status |
|-------|--------|--------|
| Another uid `account_deletion_requests/{other}` create/read | Rules inspection: `allow … if isOwner(uid)` | **Pending manual Playground** — expected **Deny** |
| Forbidden admin fields (`processed_at`, `processed_by`, `deleted_at`, `admin_notes`, `final_deletion_status`) | Rules inspection: `hasOnly` + explicit deny on those keys | **Pending manual Playground** — expected **Deny** |
| Client `delete` on request doc | Rules: `allow delete: if false` | **Pending manual Playground** — expected **Deny** |
| Client write `assessment_sets/{id}` | Rules unchanged: `allow write: if false` | **Pending manual Playground** — expected **Deny**; also not attempted by QA |

Recommended Playground (Console, no publish):

1. Auth `A` → create `account_deletion_requests/B` → Deny
2. Auth `A` → get `account_deletion_requests/B` → Deny
3. Auth `A` → create with `final_deletion_status` → Deny
4. Auth `A` → delete `account_deletion_requests/A` → Deny
5. Auth signed-in → write `assessment_sets/{id}` → Deny

---

## Rollback recommendation

**Not needed** for this verification — runtime positive path succeeded.

If a later regression appears, roll back Console rules to:

`docs/firestore_rules_current_snapshot_NOT_DEPLOYED.rules`

(then re-publish that snapshot only with explicit approval).

---

## Comparison to pre-deploy (3P-A6)

| Phase | Submit |
|-------|--------|
| 3P-A6 (before publish) | `permission-denied` |
| 3P-A10 (after manual publish) | **`ok=true`** |

---

## Remaining gaps (not this phase)

- Privileged deletion processor (Auth / Storage / cascade within 30 days)
- Optional Playground confirmation of negative cases above
- Soft-disable Discover while `account_deletion_requested == true` (product choice)

---

## Explicit non-actions (this phase)

- No rules re-deploy / re-publish
- No `firebase deploy`
- No Admin SDK
- No Auth / Storage / profile wipe
- No `assessment_sets` writes
- No commit / push
