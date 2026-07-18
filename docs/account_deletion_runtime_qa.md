# Account Deletion Runtime QA (Phase 3P-A6)

Date: 2026-07-18
Mode: Flutter **client** debug one-shot
Entry: `tool/runtime_qa_account_deletion_request.dart`
Simulator: **iPhone 16e** (`7D75D798-8F24-42D0-A7E0-E7D8D0DE97B2`)
Constraints: No Auth/Storage/data wipe · no `assessment_sets` writes · no Admin SDK · no rules deploy · no commit/push

Related: `docs/account_deletion_firestore_rules_plan.md`, `docs/account_deletion_launch_readiness.md`

---

## 1. Test user status

| Item | Observed |
|------|----------|
| Authenticated | **Yes** |
| Anonymous | **No** |
| Provider | `phone` |
| UID (masked) | `faUts7…` |
| Session source | Existing simulator Firebase session (same pattern as prior runtime QA) |

---

## 2. Request submission result

| Item | Result |
|------|--------|
| `AccountDeletionRequestService.submitRequest` | **Failed** |
| `ok` | `false` |
| `alreadyRequested` | `false` |
| Error code | **`permission-denied`** |
| Crash | **None** |
| Exit | Tool completed after logging (device disconnect after `exit(0)` is expected) |

Log excerpt:

```text
flutter: [AccountDeletionQA] Authenticated uid (masked): faUts7…
flutter: [AccountDeletionQA] isAnonymous=false providers=phone
flutter: AccountDeletionRequestService failed: permission-denied The caller does not have permission to execute the specified operation.
flutter: [AccountDeletionQA] submit ok=false alreadyRequested=false error=permission-denied
```

---

## 3. Firestore paths written during QA

**None.** Writes were denied by production Firestore rules before any document was created/updated.

Attempted (current user only):

- `account_deletion_requests/{currentUid}` — **denied**
- `users/{currentUid}` soft marker — **not reached** (request write failed first)

Not attempted:

- Other users
- `assessment_sets`
- matches / threads / reports
- Storage / Auth deletion

---

## 4. Destructive deletion

| Action | Occurred? |
|--------|-----------|
| Firebase Auth user deleted | **No** |
| Storage files deleted | **No** |
| Profile / assessments wiped | **No** |
| Matches / messages deleted | **No** |
| Reports / blocks modified for deletion | **No** |

---

## 5. Permission / rules result

| Finding | Detail |
|---------|--------|
| In-repo `firestore.rules` | **Absent** |
| `firebase.json` rules config | **Absent** (Flutter platforms only) |
| Production behavior | Client write to `account_deletion_requests/{uid}` → **`permission-denied`** |
| Interpretation | Collection is not client-writable under current production rules (missing allow rule or default deny) |
| Plan doc | `docs/account_deletion_firestore_rules_plan.md` (proposal only, **not deployed**) |

---

## 6. UI behavior (mapped from service + screen)

In-app `AccountDeletionRequestScreen`:

- On `permission-denied`, service returns `errorMessage: permission-denied`
- Screen maps non-`not_signed_in` failures to `accountDeletionRequestError` (EN/TR friendly copy pointing to retry / `support@qmatch.app`)
- Submit button remains non-destructive; no wipe path exists in client
- Success dialog **does not** show when submit fails (correct)

This QA exercised the **service path** used by the screen; it did not manually drive the Settings UI, but error handling is the same code path.

---

## 7. Errors found

| Severity | Issue |
|----------|-------|
| **Launch blocker (config)** | Production rules deny in-app request write |
| None | Crash / wrong-user write / assessment_sets write / destructive wipe |

---

## 8. Launch readiness status

| Area | Status |
|------|--------|
| In-app initiation UX (Settings → Delete account) | Present (3P-A5) |
| Client request writer + soft marker | Present |
| Friendly permission-denied handling | Present |
| Production rules allowing self request | **Missing / deny** ← confirmed this QA |
| Actual deletion within 30 days | **Not implemented** (ops/backend gap) |
| Rules proposal documented | Yes |

**Overall for 3P-A6:** Runtime QA **completed**. Submission **did not succeed** due to rules. App behaved safely.

---

## 9. Remaining backend / manual gap

1. **Approve and deploy** least-privilege rules for `account_deletion_requests/{uid}` (+ ensure self soft-marker on `users/{uid}`) — see rules plan.
2. Re-run this QA tool; expect `submit ok=true` and read-back of `status=requested`, `source=in_app`, acknowledgements `true`, and `account_deletion_requested=true`.
3. Build privileged deletion processor (Admin SDK / Cloud Function) to fulfill the 30-day promise.
4. Keep `support@qmatch.app` monitored as fallback.

---

## 10. Recommendation for next phase

**3P-A7 (or ops):** After explicit approval, deploy the rules patch from `docs/account_deletion_firestore_rules_plan.md`, re-run `tool/runtime_qa_account_deletion_request.dart`, then implement/schedule the privileged deletion processor.

---

## Explicit non-actions (this phase)

- No rules deploy
- No real data / Auth / Storage deletion
- No `assessment_sets` writes
- No Admin SDK publish/deletion scripts
- No commit / push
