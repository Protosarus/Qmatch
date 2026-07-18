# Android Release Smoke Test Run Report (Phase 3P-A31)

Date/time: 2026-07-18 (local)  
Branch: `main`  
Mode: Build attempt + execution report prep — **APK not produced** (Android SDK missing)

Related: `docs/release_binary_smoke_test_checklist.md`, `docs/store_submission_final_operations_checklist.md`

---

## 1. Build attempt summary

| Item | Value |
|------|--------|
| Command | `flutter build apk --release` |
| Result | **Failed** |
| Flutter | 3.41.2 (stable) · Dart 3.11.0 |
| Package / application id | **`com.example.qmatch`** (`android/app/build.gradle.kts`) |
| APK path | *N/A — build did not succeed* |
| APK size | *N/A* |
| Error | `[!] No Android SDK found.` · `ANDROID_HOME=/Users/protosarus/Library/Android/sdk` but directory **does not exist** (`flutter doctor`: Android toolchain ✗) |

### Blocker

Install/configure Android SDK (Android Studio or command-line tools) so `ANDROID_HOME` points at a real SDK with platforms + build-tools, then re-run:

```bash
flutter doctor -v
flutter build apk --release
```

Expected APK (when successful):

```text
build/app/outputs/flutter-apk/app-release.apk
```

**No app code was changed** to work around this failure.

---

## 2. Connected devices (at build attempt)

| Device | Type | Notes |
|--------|------|--------|
| iPhone 16e | iOS simulator | Not Android |
| Ümit iPhone’u (wireless) | iOS physical | Not Android |
| macOS | desktop | Not Android |
| Chrome | web | Not Android |
| Onur iPhone’u | wireless browse error | Not available |

**No Android device/emulator connected.** Do not install APK until SDK build succeeds and an Android device is available + install is explicitly confirmed.

---

## 3. Firebase test phone (for ST-02)

| Field | Value |
|-------|--------|
| Country | US **+1** |
| Phone | **6505553434** |
| Code | **654321** |

Must match a Firebase Console Auth test number pair for project `qmatch-53d62`.

---

## 4. Clean install commands (prepare only — do not run until APK exists)

```bash
# 1) Uninstall existing debug/release app
adb uninstall com.example.qmatch

# 2) Install release APK (path after successful build)
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 3) Optional: launch
adb shell monkey -p com.example.qmatch -c android.intent.category.LAUNCHER 1
```

If multiple devices:

```bash
adb devices
adb -s <SERIAL> uninstall com.example.qmatch
adb -s <SERIAL> install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 5. ST-01 … ST-32 execution table

Copy from `docs/release_binary_smoke_test_checklist.md`. Fill after APK install.

| Test ID | Area | Result | Severity | Notes |
|---------|------|--------|----------|-------|
| ST-01 | Clean install | Not Run | P0 | Blocked on APK |
| ST-02 | Phone auth (test number +1 6505553434 / 654321) | Not Run | P0 | |
| ST-03 | Onboarding / profile create | Not Run | P0 | |
| ST-04 | Profile edit | Not Run | P1 | |
| ST-05 | Photo / gallery | Not Run | P0 | |
| ST-06 | Location permission | Not Run | P1 | |
| ST-07 | Location deny / skip | Not Run | P1 | |
| ST-08 | Assessment load (Firestore) | Not Run | P0 | |
| ST-09 | IQ complete | Not Run | P0 | |
| ST-10 | EQ complete | Not Run | P0 | |
| ST-11 | Frequency complete | Not Run | P0 | |
| ST-12 | Discover / compatibility | Not Run | P0 | |
| ST-13 | Like / Pass | Not Run | P0 | |
| ST-14 | Match (mutual) | Not Run | P1 | Needs 2nd account |
| ST-15 | Messages / chat | Not Run | P1 | |
| ST-16 | Report | Not Run | P1 | |
| ST-17 | Block | Not Run | P1 | |
| ST-18 | Settings | Not Run | P1 | |
| ST-19 | Legal / support in-app | Not Run | P0 | |
| ST-20 | Hosted legal URLs | Not Run | P0 | Can run in browser without APK |
| ST-21 | Delete account request | Not Run | P0 | Disposable test user |
| ST-22 | Pending deletion UI | Not Run | P0 | |
| ST-23 | Localization EN | Not Run | P1 | |
| ST-24 | Localization TR | Not Run | P1 | |
| ST-25 | Poor network | Not Run | P2 | |
| ST-26 | Offline → online | Not Run | P2 | |
| ST-27 | App restart persistence | Not Run | P0 | |
| ST-28 | Logout → login | Not Run | P0 | |
| ST-29 | No Analytics/Crashlytics/FCM expectation | Not Run | P2 | |
| ST-30 | Google / Apple stubs | Not Run | P2 | |
| ST-31 | Support email | Not Run | P1 | Can spot-check without APK |
| ST-32 | Deletion ops handoff (Ümit) | Not Run | P1 | |

### Go / no-go rule

- Any **P0 Fail** → blocks submission  
- **P1 Fail** → founder decision  
- **P2 Fail** → may ship and track  

**Current smoke verdict:** **Blocked** — no release APK; all ST rows **Not Run**.

---

## 6. Explicit non-actions (this phase)

- No app code changes  
- No APK install attempted  
- No Firebase Admin / automated writes  
- No hosting / DNS / commit / push  

UI test-user data via the app later is OK after APK exists.

---

## 7. Recommended next step

1. Install Android SDK and fix `ANDROID_HOME`.  
2. Re-run `flutter build apk --release`.  
3. Connect an Android device/emulator.  
4. On explicit confirmation: uninstall `com.example.qmatch` + install APK.  
5. Execute ST-01…ST-32 and update this report’s Result column.  
