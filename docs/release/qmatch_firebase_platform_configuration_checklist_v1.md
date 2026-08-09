# QMatch Firebase Platform Configuration Checklist v1

Phase: **P2C-1A** · HEAD `4bbd6cb`  
**No secrets or API keys are printed in this document.**  
**No Console actions were performed in this phase.**

Canonical app id: **`com.qmatch.app`**

---

## Classification legend

| status | meaning |
|--------|---------|
| compatible | Identifiers in local config match canonical `com.qmatch.app` |
| incompatible | Local config targets a different package/bundle |
| missing | Required file/field absent |
| externally_blocked | Repo cannot finish without Console/Apple/Google action |
| unverified | Cannot prove without device/Console |

---

## Platform matrix

| platform | artifact | expected id | observed id | classification | notes |
|----------|----------|-------------|-------------|----------------|-------|
| Android | Gradle `applicationId` / `namespace` | `com.qmatch.app` | `com.qmatch.app` | **compatible** (source) | Aligned in P2C-1A |
| Android | `android/app/google-services.json` `package_name` | `com.qmatch.app` | `com.example.qmatch` | **incompatible** / **externally_blocked** | Do not fabricate; replace after Console registration |
| Android | `lib/firebase_options.dart` Android `appId` | app registered for `com.qmatch.app` | existing app id tied to `com.example.qmatch` JSON | **incompatible** / **externally_blocked** | Regenerate after new Android Firebase app |
| iOS | Runner bundle | `com.qmatch.app` | `com.qmatch.app` | **compatible** | Debug/Profile/Release |
| iOS | `GoogleService-Info.plist` `BUNDLE_ID` | `com.qmatch.app` | `com.qmatch.app` | **compatible** | Under `ios/Runner/` |
| iOS | `firebase_options.dart` `iosBundleId` | `com.qmatch.app` | `com.qmatch.app` | **compatible** | |
| iOS | Signing / Team ID / profiles | valid Apple team | not fabricated | **externally_blocked** / **unverified** | Not in repo; required for device/TestFlight |
| Shared | Firebase project id in local configs | production project | `qmatch-53d62` present in FlutterFire artifacts | **unverified** as “correct prod” | Project id is not a secret; prod correctness is ops judgment |
| Shared | App Check | providers configured | not implemented | **missing** / **externally_blocked** | See App Check plan |
| macOS | FirebaseOptions | configured | throws UnsupportedError | **missing** | Out of mobile release path |

---

## Exact user actions required outside the repository

### Firebase Console (Android)

1. Open project that owns the existing iOS app (`qmatch-53d62` in local FlutterFire files — confirm in Console).
2. Add (or migrate) an **Android app** with package name **`com.qmatch.app`** (do not keep `com.example.qmatch` for production).
3. Download the new `google-services.json`.
4. Replace `android/app/google-services.json` in the repo with that file.
5. Run FlutterFire configure (or equivalent) so `lib/firebase_options.dart` Android `appId` matches the new Android app.
6. Enable required Auth providers for the Android app if not already.
7. **Do not** claim Android Firebase launch ready until a debug build initializes Firebase successfully on device/emulator with the new files.

### Firebase Console (iOS)

1. Confirm iOS app bundle **`com.qmatch.app`** is registered (local plist already expects this).
2. Confirm OAuth / Google reversed client URL scheme in `Info.plist` still matches the iOS client after any Console regeneration.
3. No bundle-id change required in this phase.

### Apple Developer / App Store Connect

1. Ensure App ID **`com.qmatch.app`** exists for the correct Team.
2. Create/renew provisioning profiles and signing certificates (not stored in repo).
3. Ensure App Store Connect application record uses **`com.qmatch.app`**.
4. Sign in with Apple capability credentials only when P2C-1B implements Apple auth — do not fabricate now.

### Explicit non-actions completed in P2C-1A

- No Firebase deploy
- No Console edits
- No download of replacement config files
- No rewriting of API keys inside existing configs

---

## Launch gate

| gate | status |
|------|--------|
| Source identity frozen to `com.qmatch.app` | **done** |
| Android Firebase config for `com.qmatch.app` | **not done — externally_blocked** |
| iOS Firebase bundle match | **compatible (file-level)** |
| Production deploy of rules/indexes | **not done (prohibited this phase)** |
| App Check | **not done** |
