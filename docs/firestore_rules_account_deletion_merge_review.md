# Firestore Rules Merge Review — Account Deletion (Phase 3P-A8)

Date: 2026-07-18
Project: `qmatch-53d62`
Status: **LOCAL MERGE ONLY — NOT DEPLOYED**

---

## Explicit statement

**These candidate rules were NOT deployed.**
No `firebase deploy`, no Console publish, no Firestore writes, no user data deletion in this phase.

---

## Files inspected

| File | Role |
|------|------|
| `docs/firestore_rules_current_snapshot_NOT_DEPLOYED.rules` | Captured production rules (source of truth for merge) |
| `docs/firestore_rules_account_deletion_patch_draft.md` | Patch draft (3P-A7) |
| `lib/features/settings/services/account_deletion_request_service.dart` | Client write shape |
| `lib/core/utils/firestore_paths.dart` | `account_deletion_requests/{uid}`, `users/{uid}` |

---

## Candidate output

**`docs/firestore_rules_candidate_account_deletion_NOT_DEPLOYED.rules`**

Built by copying the production snapshot and adding **only** the account deletion request match block.

---

## What was added

Marked in candidate with:

- `// BEGIN account deletion request patch`
- `// END account deletion request patch`

New path:

```
match /account_deletion_requests/{uid}
```

| Op | Rule |
|----|------|
| `read` | `isOwner(uid)` only |
| `create` | owner + payload allowlist / acknowledgements / `status == 'requested'` / `source == 'in_app'` |
| `update` | same + forbid ops fields (`processed_at`, `processed_by`, `deleted_at`, `admin_notes`, `final_deletion_status`) |
| `delete` | `false` |

Uses existing top-level `isOwner(uid)` from production snapshot (no duplicate owner helper).

Allowed client keys (subset / `hasOnly`):

- `uid`, `email_or_phone_masked`, `status`, `requested_at`, `source`, `app_version`, `platform`, `locale`, `user_acknowledged_irreversible`, `user_acknowledged_timeline`, `updated_at`

---

## What existing rules were preserved

Unchanged from snapshot (behavior preserved):

- Global helpers (`isSignedIn`, `isOwner`, match/thread helpers)
- Default deny `match /{document=**}`
- `users/{uid}` + subcollections (`assessment_assignments`, `assessments`, `swipes`, `blocks`)
- `assessment_sets` (read signed-in; write denied)
- `questions` (read signed-in; write denied)
- `matches`, `threads`, `messages`
- `reports` (create-only for reporter)

No invented full ruleset. No replacement of production collections.

---

## Whether `users/{uid}` soft marker rule was merged or deferred

**Deferred — no change to `users/{uid}` allow expressions.**

Reason:

Production already has:

```
allow create, update: if isOwner(uid);
```

That already permits the signed-in user to merge soft markers on **their own** doc:

- `account_deletion_requested`
- `account_deletion_requested_at`
- `updated_at`

Narrowing `users/{uid}` to marker-only diffs would **break** existing profile / assessment field updates and is out of scope. A short comment was added on the existing `users/{uid}` block noting soft markers are already covered — comment-only, not a permission widen.

---

## Local validation

| Check | Result |
|-------|--------|
| Firebase CLI present | Yes (~15.x) |
| `firebase deploy` | **Not run** (forbidden this phase) |
| Brace / structure sanity | Candidate mirrors snapshot + one closed `match` block |
| Emulator / Playground | **Manual next** (see below) |

No deploy dry-run was executed (would still be a deploy-path command / risk touching project config).

---

## Risks

1. **Deploying without Playground review** — syntax or `hasOnly` edge cases on merge updates.
2. **Merge + `hasOnly`:** after ops adds forbidden fields, client re-submit may correctly fail (document keys no longer subset) — acceptable; ops owns lifecycle.
3. **`users/{uid}` remains broad for owners** — pre-existing MVP tradeoff; this merge does not worsen or fix it.
4. **Catch-all deny remains** — new collection must stay as an explicit match (added); removing it would re-deny writes.
5. **Accidental Console paste of wrong file** — use candidate only after Playground; never invent a minimal ruleset.

---

## Exact manual Rules Playground tests to run

In Firebase Console → Firestore → Rules → load/paste **candidate** in the editor **without publishing**, then Playground:

1. **Allow create own request**
   - Auth: uid `USER_A`
   - Op: `create` → `account_deletion_requests/USER_A`
   - Data: allowed fields only, `status: "requested"`, `source: "in_app"`, both acks `true`, `uid: "USER_A"`
   - Expect: **Allow**

2. **Deny create other user’s request**
   - Auth: uid `USER_A`
   - Op: `create` → `account_deletion_requests/USER_B`
   - Expect: **Deny**

3. **Deny read other user’s request**
   - Auth: uid `USER_A`
   - Op: `get` → `account_deletion_requests/USER_B`
   - Expect: **Deny**

4. **Allow read own request**
   - Auth: uid `USER_A`
   - Op: `get` → `account_deletion_requests/USER_A`
   - Expect: **Allow**

5. **Deny ops fields from client**
   - Auth: uid `USER_A`
   - Op: `create`/`update` including `processed_at` or `final_deletion_status`
   - Expect: **Deny**

6. **Deny client delete**
   - Auth: uid `USER_A`
   - Op: `delete` → `account_deletion_requests/USER_A`
   - Expect: **Deny**

7. **Soft marker still allowed (unchanged users rule)**
   - Auth: uid `USER_A`
   - Op: `update` → `users/USER_A` with `account_deletion_requested: true` (+ timestamps)
   - Expect: **Allow** (existing owner update)

8. **Regression smoke (optional)**
   - Signed-in read `assessment_sets/{id}` → Allow
   - Client write `assessment_sets/{id}` → Deny

Then **discard / do not Publish** until an explicitly approved deploy phase.

---

## Recommended next step

**3P-A9 (approval-gated):** Human Playground tests on the candidate → explicit deploy approval → publish Console rules (or approved CLI deploy) → re-run `tool/runtime_qa_account_deletion_request.dart`.

---

## Explicit non-actions (this phase)

- No deploy
- No Firestore writes
- No Admin SDK
- No commit / push
- No narrowing of `users/{uid}` production allows
