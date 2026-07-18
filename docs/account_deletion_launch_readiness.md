# Account Deletion Launch Readiness (Phase 3P-A5)

Date: 2026-07-18  
Scope: In-app **account deletion request** flow only. No automatic wipe of Auth, Storage, or user data.

## Files inspected

| Area | Paths / notes |
|------|----------------|
| Settings / Account UX | `lib/features/settings/screens/settings_screen.dart` |
| Auth | `lib/core/services/auth_service.dart`, Firebase Auth via `FirebaseAuth.instance` |
| User model / profile | `lib/core/models/user_model.dart`, `lib/features/profile/**` |
| Firestore paths | `lib/core/utils/firestore_paths.dart` — `users`, `matches`, `threads`, `reports`, `assessment_sets`, user subcollections (`swipes`, `blocks`, assessments, assignments) |
| Photos / Storage | `lib/features/profile/services/photo_upload_service.dart` — `profile_photos/{uid}/…` |
| Matches | `lib/features/matching/services/match_service.dart` — `matches` |
| Messages | `lib/features/messages/services/chat_service.dart` — `threads` (+ messages) |
| Safety | `lib/features/safety/services/safety_service.dart` — `reports`; blocks under `users/{uid}/blocks` |
| Assessment results | User doc + assessment subcollections / assignment docs (not wiped by this phase) |
| Legal / Help (3P-A4) | `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb`, About / Help screens |
| Firestore rules | **No `firestore.rules` file in this repository** |

## Files changed

- `lib/core/utils/firestore_paths.dart` — `account_deletion_requests` helpers
- `lib/features/settings/services/account_deletion_request_service.dart` — **new** request writer
- `lib/features/settings/screens/account_deletion_request_screen.dart` — **new** request UX
- `lib/features/settings/screens/settings_screen.dart` — Settings → Delete account navigates to request screen
- `lib/l10n/app_en.arb` / `lib/l10n/app_tr.arb` — deletion UX strings; Privacy / Terms / Help / FAQ updates
- Generated l10n outputs (via `flutter gen-l10n`)
- `docs/account_deletion_launch_readiness.md` — this report

## Deletion request UX

**Route:** Settings → Delete account → `AccountDeletionRequestScreen`

Includes:

- Warning title and intro (request ≠ instant wipe)
- What will be deleted (profile, photos/media refs, assessments, compatibility/Discover-related account data, match/chat access as part of closure)
- What may be retained (safety reports, abuse prevention, limited legal/compliance logs)
- Processing timeline: within **30 days**; not temporary deactivation
- Support contact: `support@qmatch.app`
- Two acknowledgement checkboxes (irreversible + timeline)
- Confirmation input: user must type `DELETE`
- Submit disabled until checkboxes + token match
- Success dialog: request received; contact support; no promise of immediate deletion
- Pending-request banner if `status == requested` already exists

## Firestore paths written by the app

1. **`account_deletion_requests/{uid}`** (create/merge)  
   Fields include: `uid`, `email_or_phone_masked`, `status: "requested"`, `requested_at`, `source: "in_app"`, `app_version` (from About version string when available), `platform`, `locale`, `user_acknowledged_irreversible`, `user_acknowledged_timeline`, `updated_at`

2. **`users/{uid}`** (merge only soft markers)  
   - `account_deletion_requested: true`  
   - `account_deletion_requested_at`  
   - `updated_at`

**Not written:** `assessment_sets`, other users’ docs, global matches/messages/reports mutations for deletion.

## Confirmation safeguards

- Dual checkbox acknowledgement
- Exact confirmation token `DELETE` (case-insensitive trim → upper)
- Submit gated until both complete
- Authenticated user only (`FirebaseAuth.currentUser`)
- Document ID forced to **own** `uid` (cannot target another user from the client path helpers)

## What is NOT deleted automatically yet

- Firebase Auth user
- Storage files under `profile_photos/{uid}/…`
- `users/{uid}` profile fields / photos / assessment payloads
- Matches, threads/messages
- Reports, blocks
- Any bulk cascade delete

This phase only **records a request** for ops / a future backend job.

## Rules / security notes

- **No Firestore rules file is present in the repo.** Production rules must be configured separately.
- Required production posture (do **not** add broad permissive rules):
  - Authenticated user may **create/update only** `account_deletion_requests/{request.auth.uid}`
  - Authenticated user may **read only** their own deletion request (needed for pending-state UX)
  - Users must **not** read/write other users’ deletion requests
  - Soft markers on `users/{uid}` must remain limited to the signed-in user’s own document (existing user self-update rules)
- Client does not weaken rules; if production denies these writes, the UI shows a non-destructive error and points to email support.

### Example rule shape (documentation only — not deployed from this repo)

```
match /account_deletion_requests/{uid} {
  allow read, create, update: if request.auth != null && request.auth.uid == uid;
  allow delete: if false; // ops/admin only
}
```

## Remaining backend / manual ops

1. Deploy Firestore rules for `account_deletion_requests` as above.
2. Ops inbox / dashboard for `status == requested` documents.
3. Implement a **privileged** deletion worker (Admin SDK / Cloud Function) that:
   - Deletes or anonymizes profile + assessments
   - Removes Storage media
   - Closes matches/threads as designed
   - Deletes Firebase Auth user
   - Retains reports/compliance per policy
   - Sets request `status` to `completed` / `failed`
4. Confirm `support@qmatch.app` mailbox is monitored.
5. Optionally hide Discover / soft-disable account while `account_deletion_requested == true` (not in this phase).

## App Store launch risk level

**Medium → Medium-Low for Guideline 5.1.1(v) “Account Deletion” initiation**

- In-app initiation, discoverable in Settings, clear permanence vs deactivation, timeline, and support contact are now covered.
- Residual risk: deletion is **request-only**; if Apple or users expect completed wipe within the stated window, ops must actually process within 30 days. Untuned Firestore rules will make in-app submit fail (email fallback still exists in copy).

## Recommended next phase

**3P-A6 (or backend ops phase):** privileged account deletion processor + rules deploy + soft-disable Discover for pending requests + monitor support mailbox; optional App Store privacy questionnaire sync.

## Explicit non-actions (this phase)

- No assessment JSON / scoring / compatibility weight changes
- No `assessment_sets` writes
- No Admin SDK scripts run
- No commit / push
- No real user data deleted
