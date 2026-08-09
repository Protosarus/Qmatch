# QMatch Canonical Application Identity v1

Phase: **P2C-1A** · Branch `main` · HEAD `4bbd6cbfe93c7f10fbbcaf868c81c07f2f67a4b0`  
**Frozen canonical production identifier:** `com.qmatch.app`

Do not introduce a second temporary package identifier.

---

## Freeze decision

| Surface | Required value |
|---------|----------------|
| Android `applicationId` | `com.qmatch.app` |
| Android `namespace` | `com.qmatch.app` |
| Android MainActivity package / source path | `com.qmatch.app` |
| iOS Runner `PRODUCT_BUNDLE_IDENTIFIER` (Debug/Profile/Release) | `com.qmatch.app` |
| iOS RunnerTests | `com.qmatch.app.RunnerTests` |
| Linux `APPLICATION_ID` | `com.qmatch.app` |
| macOS product bundle (desktop) | `com.qmatch.app` |
| Firebase Android package expectation | `com.qmatch.app` |
| Firebase iOS bundle expectation | `com.qmatch.app` |

User-facing display name remains **Qmatch** (not changed in this phase).

---

## Occurrence audit

| file | current value (pre / post P2C-1A) | required | runtime significance | changed? | external dependency | release-blocking |
|------|-----------------------------------|----------|----------------------|----------|---------------------|------------------|
| `android/app/build.gradle.kts` `namespace` | was `com.example.qmatch` → **`com.qmatch.app`** | `com.qmatch.app` | R8/Android package namespace | **changed** | none | was yes; source now aligned |
| `android/app/build.gradle.kts` `applicationId` | was `com.example.qmatch` → **`com.qmatch.app`** | `com.qmatch.app` | Play / device package id | **changed** | Play Console app listing | source aligned; store listing still external |
| `android/app/src/main/kotlin/.../MainActivity.kt` | moved `com.example.qmatch` → **`com.qmatch.app`** | `com.qmatch.app` | FlutterActivity entry | **changed** | none | no (aligned) |
| `android/app/google-services.json` `package_name` | **`com.example.qmatch`** (unchanged) | `com.qmatch.app` | Google Services Gradle plugin / Firebase Android app binding | **unchanged** | Firebase Console: register Android app `com.qmatch.app` + replace JSON | **yes — externally_blocked** |
| `lib/firebase_options.dart` Android `appId` | existing Android app id for example package | must match new Android Firebase app | `Firebase.initializeApp` | **unchanged** | regenerate via FlutterFire after Console app | **yes — externally_blocked** |
| `lib/firebase_options.dart` `iosBundleId` | `com.qmatch.app` | `com.qmatch.app` | iOS FirebaseOptions | unchanged | none for bundle match | no (compatible) |
| `ios/Runner.xcodeproj/project.pbxproj` Runner Debug/Profile/Release | `com.qmatch.app` | `com.qmatch.app` | App Store / device bundle | unchanged | Apple Team / provisioning / ASC | signing external |
| `ios/Runner.xcodeproj/project.pbxproj` RunnerTests | was `com.example.qmatch.RunnerTests` → **`com.qmatch.app.RunnerTests`** | `com.qmatch.app.RunnerTests` | unit test target only | **changed** | none | no |
| `ios/Runner/Info.plist` `CFBundleIdentifier` | `$(PRODUCT_BUNDLE_IDENTIFIER)` | resolves to `com.qmatch.app` | runtime bundle | unchanged | none | no |
| `ios/Runner/Info.plist` URL scheme (Google) | reversed client id present | must match iOS OAuth client | Google/Firebase auth redirects | unchanged | Google Cloud OAuth client | verify on auth phase |
| `ios/Runner/GoogleService-Info.plist` `BUNDLE_ID` | `com.qmatch.app` | `com.qmatch.app` | Firebase iOS config | unchanged | none for bundle | **compatible** |
| `ios/GoogleService-Info.plist` (repo root ios/) | `com.qmatch.app` | `com.qmatch.app` | duplicate/legacy path | unchanged | confirm which file Xcode uses (`Runner/`) | low |
| `linux/CMakeLists.txt` `APPLICATION_ID` | → **`com.qmatch.app`** | `com.qmatch.app` | Linux desktop id | **changed** | n/a for mobile release | no |
| `macos/Runner/Configs/AppInfo.xcconfig` | was `com.example.qmatch` → **`com.qmatch.app`** | `com.qmatch.app` | macOS desktop | **changed** | Firebase macOS not configured | no for mobile |
| `macos/Runner.xcodeproj/project.pbxproj` RunnerTests | → **`com.qmatch.app.RunnerTests`** | aligned | tests | **changed** | none | no |
| Historical docs (`docs/production_app_identity_audit.md`, smoke test runbooks, P2C-0 audit) | document prior `com.example.qmatch` | n/a (historical) | documentation only | **intentionally retained** | none | no — not active build config |
| `docs/release_binary_smoke_test_run_android.md` adb package | still documents old id | update in later release ops | ops docs | **intentionally retained** this phase | none | no |

---

## Intentionally retained `com.example.qmatch` strings

1. **`android/app/google-services.json` `package_name`** — must stay until Console supplies a replacement file registered for `com.qmatch.app`. Replacing package_name alone would fabricate config.
2. **Historical audit / plan markdown** under `docs/` that record the pre-P2C-1A state — not runtime-loaded.
3. **No active Android Gradle/Kotlin production identifier** remains `com.example.qmatch` after this phase.

---

## Validation commands

```bash
rg -n "com\\.example\\.qmatch" android/ ios/Runner.xcodeproj linux/ macos/Runner macos/Runner.xcodeproj lib/
# Expect: only google-services.json (Android Firebase) among active mobile build paths.
```
