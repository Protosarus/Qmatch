# QMatch Settings destination audit v1 (P2C-1C-5B)

**Branch:** `main` @ `4bbd6cb`  
**Scope:** every route reachable from `SettingsScreen`.

## Destination inventory

| Route entry | Screen file | Reachable at runtime? | Functionality status | Placeholder? | Visual system before P2C-1C-5B | QMatch cosmic now? | Shared header now? | Legacy app bar / naked arrow before? | Legacy slabs / borders before? | Release visible? |
|---|---|---:|---|---:|---|---:|---:|---:|---:|---:|
| Notifications | `lib/features/settings/screens/notifications_settings_screen.dart` | Yes | Local-only notification toggles | Partial MVP | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| Privacy | `lib/features/settings/screens/privacy_settings_screen.dart` | Yes | Local-only privacy toggles | Partial MVP | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| Blocked users | `lib/features/settings/screens/blocked_users_screen.dart` | Yes | Real Firestore read of `users/{uid}/blocks` | No | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| Help & Support | `lib/features/settings/screens/help_support_screen.dart` | Yes | FAQ + legal links + copy support email | No | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| About | `lib/features/settings/screens/about_screen.dart` | Yes | Product copy + legal links | No | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| Privacy Policy / Terms | `lib/features/settings/screens/legal_document_screen.dart` | Indirect via Help/About | Static legal text | No | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| Delete account | `lib/features/settings/screens/account_deletion_request_screen.dart` | Yes | Real deletion-request flow | No | Legacy black/gold | Yes | Yes | Yes | Yes | Yes |
| Debug | `lib/features/debug/debug_home_screen.dart` | `kDebugMode` only | Real debug routes | No | Legacy black/gold | Yes | Yes | N/A (custom body) | Yes | Debug-only |

## Honest destination status

- **Notifications** remains visually modernized but still device-local / MVP only. No FCM or server-backed claims were added.
- **Privacy** remains visually modernized but still local-only / MVP. No new controls or persistence paths were added.
- **Blocked users** still exposes a disabled `Unblock` affordance, which accurately preserves the current non-implemented state instead of inventing a working action.
- **Debug** remains unavailable outside debug builds.

## Visual migration notes

- Shared navigation chrome is now `QMatchPushedScreenHeader`.
- Shared background is `QMatchCosmicBackground`.
- Shared modern CTA is `QMatchPrimaryAction`.
- Destination screens no longer use the legacy naked gold back arrow or solid-black empty scaffold.
- Functional gaps remain functional gaps; this audit does **not** mark any destination release-ready by visuals alone.
