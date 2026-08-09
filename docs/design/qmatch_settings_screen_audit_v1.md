# QMatch Settings screen audit v1 (P2C-1C-5 / 5B)

**Branch:** `main` @ `4bbd6cb`  
**Scope:** Settings list rows and destinations before visual migration.

## Runtime entry

`ProfileScreen` → `Navigator` → `SettingsScreen`  
(`lib/features/settings/screens/settings_screen.dart`)

## Row inventory

| Row | Destination / action | Reachable? | Implemented? | R/W | Release-safe? | Notes |
|-----|----------------------|------------|--------------|-----|---------------|-------|
| Notifications | `NotificationsSettingsScreen` | Yes | UI only | Local state only | **Partial** | Switches do not persist / no FCM wiring; screen shows MVP note |
| Privacy | `PrivacySettingsScreen` | Yes | UI only | Local state only | **Partial** | Discover/location toggles not written to Firestore; MVP note present |
| Blocked users | `BlockedUsersScreen` | Yes | Yes | Read `users/{uid}/blocks` | Yes | Real stream; errors currently may surface raw text |
| Help & Support | `HelpSupportScreen` | Yes | Yes | None (clipboard email) | Yes | Content + support email |
| About | `AboutScreen` | Yes | Yes | None | Yes | Links to legal docs |
| Delete account | `AccountDeletionRequestScreen` | Yes | Yes | Write deletion request | Yes | Pending banner via `AccountDeletionRequestService` |
| Debug | `DebugHomeScreen` | `kDebugMode` only | Yes | Admin tools | Debug-only | Hard-coded EN strings today — localize for debug |
| Logout | `AuthService.signOut` → `AuthWrapper` | Yes | Yes | Auth sign-out | Yes | Confirm dialog |

## Placeholder / blocked honesty

- **Notifications / Privacy destinations are navigable but preference persistence is device-local / non-authoritative.** Keep rows; use honest subtitles referencing existing MVP notes (do not imply server-backed push/privacy controls).
- No fully dead Settings rows with zero destination.
- Destination screen redesign is **out of scope** for P2C-1C-5.

## Visual migration constraints

- Preserve all routes/actions above.
- Group: Preferences · Privacy & Safety · Help · Account · Developer (debug).
- Separate logout vs delete visually.
- Back: system AppBar / leading (Settings is a pushed route; add explicit back).
- Do not invent FCM enablement claims.

## P2C-1C-5 post-migration notes

- Settings list uses compact header + `QMatchCosmicBackground` + glass groups.
- Notifications / Privacy rows remain navigable with **honest** subtitles; destination screens still local-MVP (not redesigned).
- Debug row gated by `kDebugMode` (tests: `debugForceDebugRow`).
- Delete account stays in Account group; Logout is a separate emphasized tile below.
- Goldens / contact sheet: `test/goldens/settings/` — **not** release sign-off by themselves.
- Open: live iOS visual pass; FCM / privacy persistence product work.

## P2C-1C-5B destination follow-up

- Reachable destination screens are audited in `qmatch_settings_destination_audit_v1.md`.
- Shared pushed-screen navigation now uses `QMatchPushedScreenHeader`.
- Shared modern CTA now uses `QMatchPrimaryAction`.
- Privacy / Notifications / Help / About / legal / delete-account / Debug were visually migrated without changing routes or data behavior.
