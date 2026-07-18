# Firestore Rules — Account Deletion Patch Draft (Phase 3P-A7)

Date: 2026-07-18
Project: `qmatch-53d62`
Status: **PATCH DRAFT ONLY — NOT DEPLOYED — NOT A FULL RULESET**

Related:

- `docs/account_deletion_firestore_rules_plan.md` (3P-A6 plan)
- `docs/account_deletion_runtime_qa.md` (permission-denied confirmed)
- `docs/account_deletion_launch_readiness.md`

---

## 1. Current repo rules status

| Item | Status |
|------|--------|
| `firestore.rules` | **Absent** |
| `.firebaserc` | **Absent** |
| `firebase.json` → `firestore.rules` | **Absent** (`firebase.json` is FlutterFire platform config only) |
| Firebase CLI on machine | Present (`firebase-tools` ~15.x) — **not used to deploy in this phase** |
| Production rules content in repo | **Unknown / not captured** |
| Snapshot file `docs/firestore_rules_current_snapshot_NOT_DEPLOYED.rules` | **Not created yet** (must be filled from Console by a human) |

**Do not invent a full production ruleset.** Creating `firestore.rules` from scratch and deploying it could **overwrite** live rules and break auth, profiles, matches, assessments, etc.

---

## 2. Why production rules must be captured before any deploy

1. Live rules already govern `users`, matches, threads, reports, `assessment_sets`, etc.
2. 3P-A6 showed `account_deletion_requests/{uid}` writes fail with `permission-denied` — so production is enforcing *some* deny posture, but the rest of the ruleset is opaque to this repo.
3. A “complete” rules file written only from app knowledge would almost certainly be incomplete and, if deployed, would replace Console rules.
4. Safe path: **copy current Console rules → snapshot → merge this patch → review → deploy only after explicit approval.**

---

## 3. Exact account deletion paths needed by the app

| Path | Client ops | Purpose |
|------|------------|---------|
| `account_deletion_requests/{uid}` | `get`, `set(merge: true)` | Deletion **request** for signed-in user only |
| `users/{uid}` | `set(merge: true)` soft fields | Markers only (no wipe) |

Service: `AccountDeletionRequestService`
`uid` always = `FirebaseAuth.currentUser.uid`.

Soft marker fields written on `users/{uid}`:

- `account_deletion_requested: true`
- `account_deletion_requested_at` (server timestamp)
- `updated_at` (server timestamp)

---

## 4. Least-privilege rule snippets (merge into existing rules)

**WARNING:** Paste these into the **existing** production rules document after capture.
**Do not** replace the entire production ruleset with only this block.

### 4.1 `account_deletion_requests/{uid}`

```
// === BEGIN 3P-A7 ACCOUNT DELETION REQUEST PATCH (merge only) ===
match /account_deletion_requests/{uid} {
  function isOwner() {
    return request.auth != null && request.auth.uid == uid;
  }

  function requestPayloadOk() {
    return request.resource.data.uid == uid
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
  }

  allow read: if isOwner();

  allow create: if isOwner() && requestPayloadOk();

  // Clients may re-submit pending request metadata only.
  // Must not set ops/completion fields (see forbidden list).
  allow update: if isOwner()
                && requestPayloadOk()
                && !request.resource.data.keys().hasAny([
                  'processed_at',
                  'processed_by',
                  'deleted_at',
                  'admin_notes',
                  'final_deletion_status'
                ])
                && !request.resource.data.diff(resource.data).affectedKeys()
                    .hasAny([
                      'processed_at',
                      'processed_by',
                      'deleted_at',
                      'admin_notes',
                      'final_deletion_status'
                    ]);

  allow delete: if false; // clients cannot delete request audit docs
}
// === END 3P-A7 ACCOUNT DELETION REQUEST PATCH ===
```

Effects:

- Signed-in user can **create / read / update only** `account_deletion_requests/{theirUid}`
- Signed-in user **cannot** access other users’ deletion requests (`uid` must match `request.auth.uid`)
- Client `status` locked to `"requested"` (ops use Admin SDK for completed/failed)

### 4.2 `users/{uid}` soft marker (additive constraint)

Production already (presumably) allows some self-updates on `users/{uid}` for profile.
**Do not** replace existing `match /users/{uid}` with a marker-only rule.

Instead, when reviewing production rules after capture:

1. Confirm self-update already allows the signed-in user to merge their own doc.
2. Ensure the deletion flow’s three fields are permitted under that self-update policy.
3. Prefer **not** granting new broad write powers. If you add a helper, use it only as an additional check for marker-only diffs when separating from profile updates is practical.

Illustrative helper (merge carefully; adapt to existing `users` match):

```
// === BEGIN 3P-A7 USER DELETION MARKER HELPERS (merge carefully) ===
function isUserOwner(uid) {
  return request.auth != null && request.auth.uid == uid;
}

function deletionMarkerKeysOnly() {
  return request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly([
      'account_deletion_requested',
      'account_deletion_requested_at',
      'updated_at'
    ]);
}

// Example usage IF you introduce a dedicated allow path for marker-only writes:
// allow update: if isUserOwner(uid)
//               && deletionMarkerKeysOnly()
//               && request.resource.data.account_deletion_requested == true;
//
// Prefer keeping existing profile update rules intact and only verifying
// these three fields are already allowed for the signed-in user.
// === END 3P-A7 USER DELETION MARKER HELPERS ===
```

If production already allows broader self `users/{uid}` updates (name, photos, etc.), **do not** narrow that in this phase unless you fully understand profile write paths. Minimum requirement: owner can set the three soft marker fields on **their own** document.

---

## 5. Allowed client fields (`account_deletion_requests`)

| Field | Client allowed? |
|-------|-----------------|
| `uid` | Yes (must equal auth uid / doc id) |
| `status` | Yes — value **`requested` only** |
| `requested_at` | Yes (timestamp) |
| `source` | Yes — **`in_app`** |
| `platform` | Yes |
| `locale` | Yes |
| `app_version` | Yes (optional) |
| `user_acknowledged_irreversible` | Yes — must be `true` |
| `user_acknowledged_timeline` | Yes — must be `true` |
| `email_or_phone_masked` | Yes if present |
| `updated_at` | Yes (timestamp; used by current client) |

---

## 6. Forbidden client-controlled fields

Clients must **not** be able to write:

| Field | Reason |
|-------|--------|
| `processed_at` | Ops-only lifecycle |
| `processed_by` | Ops-only |
| `deleted_at` | Ops / processor only |
| `admin_notes` | Ops-only |
| `final_deletion_status` | Ops-only |

Also deny client `delete` on the request document so users cannot erase audit trails.

---

## 7. Critical merge warning

> **This patch must be merged into the existing production rules, not blindly deployed.**

Forbidden actions for this phase (and until explicitly approved later):

- Creating a brand-new full `firestore.rules` that claims to be production
- `firebase deploy --only firestore:rules`
- Overwriting Console rules with a fragment-only file
- Changing unrelated `users` / `matches` / `assessment_sets` rules without review

---

## 8. Manual Firebase Console checklist

Do these steps **manually** (human operator). This phase does **not** perform them.

1. Open [Firebase Console](https://console.firebase.google.com/) → project **`qmatch-53d62`**
2. Go to **Firestore Database**
3. Open the **Rules** tab
4. **Copy** the entire current rules text
5. Save a local snapshot as:
   - `docs/firestore_rules_current_snapshot_NOT_DEPLOYED.rules`
   - Filename includes `NOT_DEPLOYED` on purpose — capturing ≠ deploying
6. In a working copy (not yet published), **merge** §4.1 into the snapshot:
   - Add the `account_deletion_requests` match inside `match /databases/{database}/documents { ... }`
   - Do not remove existing matches
7. Review §4.2 against existing `users/{uid}` rules; adjust only if soft markers would otherwise remain denied
8. Use **Rules Playground** on the merged draft:
   - Auth `A` → create `account_deletion_requests/A` → allow
   - Auth `A` → create/read `account_deletion_requests/B` → deny
   - Auth `A` → write `processed_at` / `final_deletion_status` → deny
   - Unauthenticated → deny
9. **Stop.** Do not Publish / Deploy until a later explicitly approved phase
10. After a future approved deploy: re-run `tool/runtime_qa_account_deletion_request.dart`

---

## 9. Explicit non-actions (this phase)

- No Firestore rules deploy
- No overwrite of production rules
- No Firestore writes
- No user data deletion
- No Admin SDK scripts
- No Firebase publish/deploy commands
- No commit / push
- No creation of a deployable full production ruleset file
- Snapshot file left for **manual** Console capture (not invented here)

---

## 10. Recommended next step (after this draft)

**3P-A8 (human + approval):** Capture Console rules → save `docs/firestore_rules_current_snapshot_NOT_DEPLOYED.rules` → merge this patch → playground verify → **explicit deploy approval** → re-run deletion-request runtime QA.
