# Account Deletion Pending UX (Phase 3P-A17)

Date: 2026-07-18  
Scope: In-app UX for users who already submitted a deletion request  
Status: **Read-only pending detection + UI — no destructive deletion**

---

## Files inspected

| Area | Path |
|------|------|
| Settings | `lib/features/settings/screens/settings_screen.dart` |
| Delete account screen | `lib/features/settings/screens/account_deletion_request_screen.dart` |
| Deletion service | `lib/features/settings/services/account_deletion_request_service.dart` |
| Discover | `lib/features/discover/screens/discover_screen.dart` |
| Paths | `lib/core/utils/firestore_paths.dart` |
| l10n | `lib/l10n/app_en.arb`, `lib/l10n/app_tr.arb` |
| Ops context | `docs/account_deletion_manual_ops_runbook.md` |

---

## Files changed

- `lib/features/settings/services/account_deletion_request_service.dart`
- `lib/features/settings/screens/settings_screen.dart`
- `lib/features/settings/screens/account_deletion_request_screen.dart`
- `lib/features/discover/screens/discover_screen.dart`
- `lib/l10n/app_en.arb` / `app_tr.arb` (+ generated l10n)
- `docs/account_deletion_pending_ux.md` (this report)

---

## How pending state is detected

`AccountDeletionRequestService.isAccountDeletionPending()` (read-only):

1. Read `users/{uid}.account_deletion_requested == true` (soft marker), **or**
2. Fall back to `account_deletion_requests/{uid}.status == requested`

No writes on detection.

---

## UI surfaces updated

| Surface | Behavior |
|---------|----------|
| **Settings** | Banner when pending; Delete row title → “Account deletion requested” / TR; subtitle points to status; refreshes after returning from delete screen |
| **Delete Account screen** | If pending: status body, 30-day timeline, support email; **no** submit form / checkboxes / DELETE field |
| **Discover** | Non-blocking top banner: “Your account deletion request is pending.” Navigation/swipes unchanged |

No automatic sign-out.

---

## Duplicate requests prevented

| Layer | Behavior |
|-------|----------|
| UI | Pending screen has no submit button |
| Service | `submitRequest` returns early with `alreadyRequested: true` and **does not** call `set` on request or user docs if status is already `requested` |

---

## Discover behavior

**Changed** with a safe non-blocking banner only. Discover load/swipe flow unchanged if pending check fails (defaults to no banner).

---

## Confirmation: no destructive deletion

- No Auth / Storage / profile wipe  
- No Admin SDK  
- No `assessment_sets` / `questions` writes  
- Pending path performs **reads only**; duplicate submit path performs **no Firestore writes**  
- New first-time submit still writes request + soft marker (existing product behavior; not invoked when pending)

---

## Remaining launch notes

- Manual ops still fulfill deletions within 30 days (`docs/account_deletion_manual_ops_runbook.md`)  
- Automated execute still disabled  
- Optional later: hide Discover cards entirely for pending users (not required this phase)  

---

## Explicit non-actions

No commit / push / deploy / Admin SDK / destructive deletion.
