# QMatch display-name field audit (P2C-1C-4A)

**Branch:** `main` @ `4bbd6cb` (audit time)  
**Scope:** inventory of identity fields; root cause of Profile `, 26`.

## Verdict

Profile renders `, 26` because `profile_screen.dart` formats `'${name}, ${age}'` with no empty-name guard while the reachable phone onboarding path never collects a display name. Firestore key for identity today is `users/{uid}.name`. Domain property for this phase is **`displayName`**; canonical Firestore key remains **`name`** (existing convention).

## Profile `, 26` root cause

| Step | Evidence |
|------|----------|
| UI (pre-fix) | `profile_screen.dart` — `'${_profile!.name}, ${_profile!.age}'` with no empty-name guard |
| Model | `UserProfileModel.fromFirestore` — `name: data['name'] ?? ''` |
| Phone create | `AuthService.ensureUserDocumentForPhoneUser` — seeded Auth `displayName` (often null/missing) |
| Profile setup | Copies Auth `displayName` (often empty); no name step |
| Gate (pre-fix) | `AuthWrapper` never routed to `NameSelectionScreen` (orphaned) |

**Fix (this phase):** shared `UserIdentityResolver.formatNameAndAge` (never `", 26"`); display-name completion gate before assessments/main; canonical merge-write to `users/{uid}.name`.

**Closure hardening (P2C-1C-4A-CLOSE):** `ProfileSetupScreen` no longer writes Auth `displayName` into Firestore `name`. It reads the canonical value via `DisplayNameService`, and `UserProfileModel.toFirestore` omits empty `name` so merge cannot erase it.

## Field inventory (summary)

| Location | Key | R/W | Path | Notes |
|----------|-----|-----|------|-------|
| `UserProfileModel` | `name` | R/W | `users/{uid}` | Canonical public-facing store |
| `UserModel` | `name` | R/W | `users/{uid}` | Lighter mirror |
| `DiscoverUserModel` | `name` | R | `users/{uid}` | Discover card |
| Chat public profile | `name` | R | `users/{uid}` | Messages / Chat Detail |
| Firebase Auth | `displayName` | R/W | Auth | Not Profile UI source; phone often null |
| `NameSelectionScreen` | Auth only | W | Auth | Orphaned; does not write Firestore |
| Signup screens | `name` | W | Auth + Firestore | Orphaned / secondary vs phone Welcome |

**Absent as user identity keys:** `display_name`, `displayName` (Firestore), `full_name`, `nickname`, `username`, `first_name`.

## Legacy read aliases (documented)

1. Firestore `name` (canonical)
2. Prefill-only: Firebase Auth `displayName` (completion screen prefill; never public fallback)
3. Missing → no UID/email/phone fallback

## Profile Edit

No general Profile Edit screen. Only `ProfilePhotoEditScreen` is wired. Display-name edit deferred to later gap.

## Security

`firestore.rules`: owner update allowed if protected keys unchanged. `name` is not protected — owner may update. No field allowlist; no server-side length validation.
