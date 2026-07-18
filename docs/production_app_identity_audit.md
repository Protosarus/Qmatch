# Production App Identity Audit (Phase 3P-A31B)

Date: 2026-07-18  
Mode: **Audit / report only** — no identifier renames, no Firebase config edits, no deploys  
Project: `qmatch-53d62`

Candidate production identity (founder intent):

| Platform | Candidate |
|----------|-----------|
| Android `applicationId` | **`site.qmatch.app`** |
| iOS bundle identifier | **`site.qmatch.app`** |

---

## 1. Current Android identity

| Item | Current value | Source |
|------|---------------|--------|
| `applicationId` | **`com.example.qmatch`** | `android/app/build.gradle.kts` |
| `namespace` | **`com.example.qmatch`** | `android/app/build.gradle.kts` |
| Kotlin package / MainActivity path | `com.example.qmatch` | `android/app/src/main/kotlin/com/example/qmatch/MainActivity.kt` |
| App label (launcher name) | **`qmatch`** (lowercase) | `android/app/src/main/AndroidManifest.xml` → `android:label` |
| Debug / profile manifests | No package override | `src/debug`, `src/profile` |
| Release signing | **Debug signing config** (not production keystore) | `build.gradle.kts` `signingConfig = debug` |

**Gradle TODO still present:** “Specify your own unique Application ID”.

---

## 2. Current iOS identity

| Item | Current value | Source |
|------|---------------|--------|
| Bundle ID — **Debug** | **`com.qmatch.app`** | `project.pbxproj` Runner Debug |
| Bundle ID — **Release** | **`com.qmatch.app`** | `project.pbxproj` Runner Release |
| Bundle ID — **Profile** | **`com.OurSecrets`** ⚠️ | `project.pbxproj` Runner Profile |
| `CFBundleDisplayName` (Info.plist) | **`Qmatch`** | `ios/Runner/Info.plist` |
| `CFBundleName` (Info.plist) | **`qmatch`** | `ios/Runner/Info.plist` |
| `INFOPLIST_KEY_CFBundleDisplayName` | **`OurSecrets`** ⚠️ (Debug/Release/Profile) | `project.pbxproj` — may override plist at build |
| RunnerTests bundle IDs | `com.example.qmatch.RunnerTests` | `project.pbxproj` |
| Development team | `5V5NP5ATH2` | `project.pbxproj` |

**Display-name conflict:** Xcode build setting still says **OurSecrets** while `Info.plist` says **Qmatch**. Home-screen name may show **OurSecrets** depending on build merge order — treat as branding bug before App Store.

**Profile config drift:** Profile uses **`com.OurSecrets`**, which will **not** match Firebase iOS app `com.qmatch.app`.

---

## 3. Display name summary (product-facing)

| Surface | Value |
|---------|--------|
| Android launcher label | `qmatch` |
| iOS Info.plist display name | `Qmatch` |
| iOS Xcode `INFOPLIST_KEY_CFBundleDisplayName` | `OurSecrets` (stale) |
| In-app / l10n brand | **Qmatch** |
| Recommended store display name | **Qmatch** (capitalize consistently) |

---

## 4. Versioning

| Item | Value |
|------|--------|
| `pubspec.yaml` | **`version: 0.1.0`** (no `+build` suffix → Flutter build number typically **1**) |
| Android `versionName` | `flutter.versionName` → **0.1.0** |
| Android `versionCode` | `flutter.versionCode` → **1** (unless overridden) |
| iOS `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` → **0.1.0** |
| iOS `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` → **1** |

Bump version/`+build` before store submit after identity is fixed.

---

## 5. Firebase config identity mapping

Project: **`qmatch-53d62`**

### Android (`android/app/google-services.json`)

| Field | Value |
|-------|--------|
| `package_name` | **`com.example.qmatch`** |
| `mobilesdk_app_id` | `1:55490039374:android:5c9fd0918fe15626c7fd1f` |
| Matches Gradle `applicationId`? | **Yes** (both `com.example.qmatch`) |

### iOS (`ios/Runner/GoogleService-Info.plist`)

| Field | Value |
|-------|--------|
| `BUNDLE_ID` | **`com.qmatch.app`** |
| `GOOGLE_APP_ID` | `1:55490039374:ios:523d1a173f0ba32ac7fd1f` |
| Matches Debug/Release bundle? | **Yes** (`com.qmatch.app`) |
| Matches Profile bundle? | **No** (`com.OurSecrets`) |

### FlutterFire (`lib/firebase_options.dart` / `firebase.json`)

| Platform | App ID | Bundle / package note |
|----------|--------|------------------------|
| Android | `1:55490039374:android:5c9fd0918fe15626c7fd1f` | Tied to **`com.example.qmatch`** in Console JSON |
| iOS | `1:55490039374:ios:523d1a173f0ba32ac7fd1f` | `iosBundleId: **com.qmatch.app**` |

**There is no Firebase Android/iOS app registered as `site.qmatch.app` in the checked configs.**

---

## 6. Risks of keeping `com.example.qmatch`

| Risk | Severity |
|------|----------|
| Looks like a Flutter template ID — poor store trust / possible Play policy friction | **High** |
| **Permanent** Google Play application id after first publish — cannot rename later | **Critical** |
| Brand mismatch vs `qmatch.site` / candidate `site.qmatch.app` | High |
| Inconsistent with iOS (`com.qmatch.app`) and web domain (`qmatch.site`) | High |
| Team may accidentally ship debug-signed release (also present) | High |

**Do not submit Play with `com.example.qmatch`.**

---

## 7. Recommended production identity

| Platform | Recommended | Notes |
|----------|-------------|--------|
| Android `applicationId` (+ namespace / Kotlin path) | **`site.qmatch.app`** | Aligns with domain-style id; requires Firebase Android app + new `google-services.json` |
| iOS bundle ID (Debug/Release/**Profile**) | **`site.qmatch.app`** | Unify all configs; retire `com.qmatch.app` / `com.OurSecrets` drift |
| Display name (Android + iOS) | **`Qmatch`** | Fix `OurSecrets` / lowercase `qmatch` |
| Firebase apps | New (or remapped) apps for **`site.qmatch.app`** on Android + iOS | Regenerate FlutterFire options |

**Alternative (if founder prefers continuity with existing iOS Firebase app):** keep iOS as `com.qmatch.app` and only change Android away from `com.example.*` — but then Android/iOS IDs stay mismatched. Candidate request is **both `site.qmatch.app`**.

---

## 8. Required follow-up before release builds (do not do in this phase)

### A. Identity rename (future dedicated phase)

1. Confirm final ids: **`site.qmatch.app`** (or founder override).  
2. Android: change `applicationId`, `namespace`, move `MainActivity` package path.  
3. iOS: set **Debug / Release / Profile** `PRODUCT_BUNDLE_IDENTIFIER` to the same id; fix tests bundle if needed.  
4. Display names: Android `android:label="Qmatch"`; remove `OurSecrets` from `INFOPLIST_KEY_CFBundleDisplayName`.  

### B. Firebase regeneration

1. Firebase Console → add Android app with package **`site.qmatch.app`**.  
2. Add iOS app with bundle **`site.qmatch.app`** (or keep/migrate `com.qmatch.app` if founder chooses alternate).  
3. Download new `google-services.json` + `GoogleService-Info.plist`.  
4. Re-run FlutterFire / update `lib/firebase_options.dart` + `firebase.json`.  
5. Verify Auth (phone), SHA-1/256 for Android release keystore, Apple URL schemes / reversed client id.  

### C. Signing & store provisioning

1. Android: create **upload/release keystore**; stop using debug signing for release.  
2. Play Console: create app with package **`site.qmatch.app`** (before first upload).  
3. Apple Developer: App ID + profiles/certificates for **`site.qmatch.app`**.  
4. App Store Connect / Play listings: package/bundle must match binaries.  
5. Update any deep links / OAuth redirect configs if they embed old ids.  

### D. Tooling blockers already known

1. Android SDK still missing on this machine (3P-A31) — needed for APK after identity fix.  
2. Bump `pubspec` version/`+build` for store.  

---

## 9. Release blockers from this audit

| Blocker | Status |
|---------|--------|
| Android `com.example.qmatch` | **P0 — must change before Play submit** |
| iOS Profile `com.OurSecrets` drift | **P0 for Profile builds; fix before shipping** |
| iOS display name `OurSecrets` override | **P0 branding** |
| Firebase configs bound to old package/bundle | **P0 if renaming to `site.qmatch.app`** |
| Android release signed with debug key | **P0 for Play** |
| Android SDK missing (build env) | **P0 for Android APK on this Mac** |
| Identity rename not yet executed | Expected — this phase is audit only |

---

## 10. Explicit non-actions (this phase)

- No package/bundle renames  
- No Firebase Console / config file edits  
- No Firestore / Admin / deploy / DNS  
- No commit / push  

---

## Related

- `docs/release_binary_smoke_test_run_android.md` (APK blocked on SDK)  
- `docs/store_submission_final_operations_checklist.md`  
