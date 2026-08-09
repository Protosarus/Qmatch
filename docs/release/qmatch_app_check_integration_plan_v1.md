# QMatch App Check Integration Plan v1

Phase: **P2C-1A** · Plan only — **App Check was not enabled in Firebase Console.**  
Status: **unverified** until Console + physical-device checks complete.

---

## Current state

| check | result |
|-------|--------|
| `firebase_app_check` (or related) in `pubspec.yaml` | **absent** |
| App Check initialization in `lib/` | **absent** |
| Debug / Play Integrity / DeviceCheck wiring | **absent** |
| Console enforcement | **unknown / not enabled by this phase** |

---

## Provider requirements

| platform | production provider | notes |
|----------|---------------------|-------|
| Android | **Play Integrity** (preferred) or SafetyNet legacy only if unavoidable | Requires Play-enabled app signing + Cloud project linkage |
| iOS | **DeviceCheck** (baseline) or **App Attest** where supported | Requires Apple Developer Team capability |

---

## Debug development strategy

1. Use App Check **debug providers** only on local/dev builds (`kDebugMode` / flavor).
2. Register debug tokens in Firebase Console → App Check → Manage debug tokens.
3. Never ship debug provider in release/profile store builds.
4. Keep a compile-time or flavor flag: `USE_APP_CHECK_DEBUG`.

---

## Production enforcement dependency

| dependency | owner |
|------------|-------|
| Register Android + iOS apps under App Check in Console | ops |
| Enable Play Integrity API / DeviceCheck | ops |
| Turn on **enforcement** for Auth, Firestore, Storage (gradually) | ops |
| Monitor rejected requests before full enforce | ops + eng |

Enforcement before providers are correctly installed will lock out real users.

---

## Firebase Console actions (do not perform in P2C-1A)

1. Open App Check for project.
2. Register Android app `com.qmatch.app` (after Android Firebase app exists).
3. Register iOS app `com.qmatch.app`.
4. Add debug tokens for engineering devices.
5. Start in **monitoring** mode; switch to **enforced** per product after soak.

---

## Code changes still required (later phase)

1. Add `firebase_app_check` dependency.
2. Initialize after `Firebase.initializeApp`:
   - Android: `AndroidPlayIntegrityProvider` (prod) / `AndroidDebugProvider` (debug).
   - iOS: `AppleProvider` / `AppleDebugProvider`.
3. Ensure initialize order before Auth/Firestore/Storage usage.
4. Document QA steps on physical devices (emulator Play Integrity limitations).

---

## Rollout order

1. Fix Android Firebase package registration for `com.qmatch.app`.
2. Integrate SDK + debug tokens (dev only).
3. Console monitoring mode.
4. Soft-launch enforce on Storage → Firestore → Auth (or project-preferred order).
5. Full enforce after error-rate acceptable.

---

## Rollback considerations

- Console can disable enforcement immediately without an app release.
- Keep a remote-config or build flag only if needed for SDK init crashes (prefer Console rollback first).
- Removing the package requires an app release; prefer leaving SDK installed with providers disabled via Console.

---

## Acceptance

App Check remains **unverified** and **release-blocking (G-032)** until:

- providers configured in Console for `com.qmatch.app`,
- production build attaches tokens on real devices,
- enforcement soak passes without mass rejection.
