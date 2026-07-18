# Account Deletion Firestore Rules Plan (Phase 3P-A6)

Date: 2026-07-18
Status: **Proposal only — not deployed**
Project: `qmatch-53d62`
Related: `docs/account_deletion_launch_readiness.md`

## Important warning

**These rules are not deployed from this repository.**
There is **no** `firestore.rules` file and `firebase.json` has **no** `firestore.rules` config.
Do **not** treat this document as a full production ruleset. It is a **least-privilege patch proposal** for the account deletion request flow only.

Do not deploy until explicitly approved.

---

## Exact Firestore paths used by the app (deletion request)

| Path | Client action | Purpose |
|------|---------------|---------|
| `account_deletion_requests/{uid}` | `get` + `set(..., merge: true)` | Create/update deletion **request** for signed-in user |
| `users/{uid}` | `set(..., merge: true)` soft fields only | Marker: `account_deletion_requested`, `account_deletion_requested_at`, `updated_at` |

Implementation: `AccountDeletionRequestService`
Path helpers: `FirestorePaths.accountDeletionRequestDoc(uid)`, `FirestorePaths.userDoc(uid)`
Identity: `uid` always comes from `FirebaseAuth.instance.currentUser.uid` (never from free-form UI input).

### Paths intentionally **not** written by this flow

- `assessment_sets/*`
- Other users’ docs
- `matches`, `threads`, messages
- `reports`
- Storage `profile_photos/{uid}/…`
- Firebase Auth deletion

---

## Required permissions (least privilege)

### `account_deletion_requests/{uid}`

| Op | Who | Condition |
|----|-----|-----------|
| `read` | Signed-in user | `request.auth.uid == uid` (pending-state UX) |
| `create` | Signed-in user | `request.auth.uid == uid` |
| `update` | Signed-in user | `request.auth.uid == uid` |
| `delete` | **Deny clients** | Ops / Admin SDK / privileged backend only |
| Any op | Other users | **Deny** |

### `users/{uid}` soft marker

| Op | Who | Condition |
|----|-----|-----------|
| Merge write of marker fields | Signed-in user | `request.auth.uid == uid` |
| Cross-user write | Anyone else | **Deny** |
| Wipe / cascade delete of profile | Client | **Deny** (not part of this flow) |

Existing production rules for broader `users/{uid}` profile updates are unknown in-repo. This plan only states the **additional** constraints needed for the deletion marker. Do not open the user doc for arbitrary field writes beyond what production already allows for profile editing.

---

## Least-privilege rule shape — `account_deletion_requests`

**Patch fragment (not a full rules file):**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // --- ACCOUNT DELETION REQUESTS (patch) ---
    match /account_deletion_requests/{uid} {
      allow read: if request.auth != null
                  && request.auth.uid == uid;

      allow create: if request.auth != null
                    && request.auth.uid == uid
                    && request.resource.data.uid == uid
                    && request.resource.data.status == 'requested'
                    && request.resource.data.source == 'in_app'
                    && request.resource.data.user_acknowledged_irreversible == true
                    && request.resource.data.user_acknowledged_timeline == true
                    && request.resource.data.keys().hasOnly([
                      'uid',
                      'email_or_phone_masked',
                      'status',
                      'requested_at',
                      'source',
                      'app_version',
                      'platform',
                      'locale',
                      'user_acknowledged_irreversible',
                      'user_acknowledged_timeline',
                      'updated_at'
                    ]);

      // Clients may re-submit / refresh a pending request, but must not
      // self-mark completed/cancelled/processed statuses.
      allow update: if request.auth != null
                    && request.auth.uid == uid
                    && request.resource.data.uid == uid
                    && request.resource.data.status == 'requested'
                    && request.resource.data.source == 'in_app'
                    && request.resource.data.user_acknowledged_irreversible == true
                    && request.resource.data.user_acknowledged_timeline == true
                    && !request.resource.data.diff(resource.data).affectedKeys()
                        .hasAny(['processed_at', 'processed_by', 'ops_notes']);

      allow delete: if false;
    }
  }
}
```

Notes:

- Prefer keeping `status` client-writable only as `'requested'`. Ops backend should set `completed` / `failed` / `cancelled` with Admin SDK (bypasses rules).
- Optional hardening: require `requested_at` / `updated_at` to be timestamps (`request.resource.data.requested_at is timestamp`).

---

## Least-privilege rule shape — user soft marker only

If production already allows users to update their own `users/{uid}` profile, **narrow** deletion-related client writes with a field allowlist when possible.

**Conceptual patch** (integrate into whatever existing `users/{uid}` match you already have):

```
match /users/{uid} {
  // Existing profile read/write rules remain as today.

  // Example: when validating updates, allow deletion marker keys among
  // already-permitted profile keys — never allow clients to clear Auth,
  // impersonate roles, or wipe arbitrary subcollections from rules alone.
  function isSelf() {
    return request.auth != null && request.auth.uid == uid;
  }

  function deletionMarkerOnlyDiff() {
    return request.resource.data.diff(resource.data).affectedKeys()
      .hasOnly([
        'account_deletion_requested',
        'account_deletion_requested_at',
        'updated_at'
      ]);
  }

  // If you introduce a dedicated path for marker-only updates, require:
  // allow update: if isSelf() && deletionMarkerOnlyDiff()
  //               && request.resource.data.account_deletion_requested == true;
}
```

**Practical guidance for current Qmatch client:**

The app uses `set(merge: true)` with only:

- `account_deletion_requested: true`
- `account_deletion_requested_at: serverTimestamp()`
- `updated_at: serverTimestamp()`

So production rules must at least allow the signed-in user to merge those three fields on **their own** doc. Prefer rejecting:

| Reject if client tries to write | Why |
|---------------------------------|-----|
| `role`, `isAdmin`, `admin`, custom claims mirrors | Privilege escalation |
| Another user’s `uid` / identity fields | Impersonation |
| Clearing entire profile / setting `deleted: true` as a fake wipe without ops | Misleading “deleted” state without processor |
| Writing to other collections via rules loopholes | Cross-collection abuse |
| Setting deletion request `status` to `completed` | Only ops should complete |

---

## Fields allowed on `account_deletion_requests/{uid}` (client)

| Field | Type / value | Notes |
|-------|--------------|-------|
| `uid` | string == auth uid | Must match doc id |
| `email_or_phone_masked` | string | Masked contact only |
| `status` | `"requested"` only from client | |
| `requested_at` | timestamp | Prefer server timestamp |
| `source` | `"in_app"` | |
| `app_version` | string (optional) | |
| `platform` | string | ios/android/web/… |
| `locale` | string | language code |
| `user_acknowledged_irreversible` | `true` | |
| `user_acknowledged_timeline` | `true` | |
| `updated_at` | timestamp | |

## Fields that should be rejected from clients

| Field / action | Reason |
|----------------|--------|
| `status: "completed" \| "failed" \| "cancelled"` | Ops-only lifecycle |
| `processed_at`, `processed_by`, `ops_notes` | Ops-only |
| `delete` of the request doc | Prevent cover-up / audit loss |
| Writing `account_deletion_requests/{otherUid}` | Cross-user |
| Writing wipe payloads to `users/{otherUid}` | Cross-user |
| Any Auth/Storage delete from client rules | Out of scope; privileged backend |

---

## Manual Firebase Console / repo integration steps

1. Open Firebase Console → Project `qmatch-53d62` → Firestore → **Rules**.
2. Confirm current production rules (export/copy for backup).
3. Add the `account_deletion_requests` match block with least privilege (above).
4. Confirm `users/{uid}` already allows self-update; if not, add only the soft-marker fields needed.
5. Use Rules Playground:
   - Auth uid `A` create `account_deletion_requests/A` → **allow**
   - Auth uid `A` create `account_deletion_requests/B` → **deny**
   - Auth uid `A` delete `account_deletion_requests/A` → **deny**
   - Unauthenticated create → **deny**
6. Publish rules **only after explicit approval** (not part of this phase).
7. Optional later: add `firestore.rules` + `firebase.json` `"firestore": { "rules": "firestore.rules" }` for version control — still do not invent a full production ruleset here.
8. After deploy: re-run client runtime QA (`tool/runtime_qa_account_deletion_request.dart`).

---

## Launch risk if rules are missing / wrong

| Scenario | Risk |
|----------|------|
| Collection denied by default | In-app submit fails with `permission-denied`; user sees friendly error + email fallback. Apple initiation UX exists, but flow is incomplete until rules allow self-write. |
| Overly permissive (`allow write: if true`) | Any client could forge others’ deletion requests or spam — **do not ship**. |
| Users can set `status: completed` | Users could fake completion without data wipe — compliance/App Review risk. |
| Soft marker denied but request allowed | Partial success / confusing UX; keep both writes permitted for self. |
| Soft marker allowed but request denied | Marker without auditable request doc — bad for ops. |

**App Store:** In-app initiation is present (3P-A5). Rules gap is an **ops/config blocker**, not a missing Settings entry. Actual deletion within 30 days remains a separate backend gap.

---

## Explicit non-actions (this phase)

- No rules deploy
- No full production ruleset authored as a deployable file
- No Admin SDK deletion processor
- No real user data / Auth / Storage deletion
