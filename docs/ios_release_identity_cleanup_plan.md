# iOS Release Identity Cleanup Plan (Phase 3P-A32)

Date: 2026-07-18  
Mode: **Plan / report only** — no iOS project edits, no Firebase changes, no Android identity changes  
Related: `docs/production_app_identity_audit.md`, `docs/release_binary_smoke_test_checklist.md`, `docs/store_submission_final_operations_checklist.md`

---

## 1. Decision for this iOS-only path

| Decision | Choice |
|----------|--------|
| iOS bundle identifier for TestFlight / App Store (now) | **Keep `com.qmatch.app`** |
| Migrate iOS to `site.qmatch.app` | **Not in this phase** (later optional) |
| Android identity (`com.example.qmatch` → `site.qmatch.app`) | **Parked** — Android SDK missing on this machine |
| Firebase project / configs | **Do not regenerate** while staying on `com.qmatch.app` |
| Goal of next implementation phase | Remove stale **OurSecrets** identity/display drift; unify Profile to `com.qmatch.app`; display name **Qmatch**; version **1.0.0+1** |

---

## 2. Current iOS bundle identifiers by configuration

| Target | Configuration | `PRODUCT_BUNDLE_IDENTIFIER` | Compatible with Firebase iOS? |
|--------|---------------|------------------------------|-------------------------------|
| Runner | **Debug** | `com.qmatch.app` | **Yes** |
| Runner | **Release** | `com.qmatch.app` | **Yes** |
| Runner | **Profile** | **`com.OurSecrets`** | **No** |
| RunnerTests | Debug / Release / Profile | `com.example.qmatch.RunnerTests` | N/A (tests) |

Source: `ios/Runner.xcodeproj/project.pbxproj`

**Firebase iOS (`ios/Runner/GoogleService-Info.plist` and `ios/GoogleService-Info.plist`):**  
`BUNDLE_ID` = **`com.qmatch.app`** · `GOOGLE_APP_ID` = `1:55490039374:ios:523d1a173f0ba32ac7fd1f`  
Also reflected in `lib/firebase_options.dart` → `iosBundleId: 'com.qmatch.app'`.

Keeping **`com.qmatch.app`** for Debug/Release/Profile avoids Firebase regeneration for the iOS TestFlight path.

---

## 3. Current iOS display name sources

| Source | Value | Notes |
|--------|-------|--------|
| `ios/Runner/Info.plist` → `CFBundleDisplayName` | **`Qmatch`** | Correct brand |
| `ios/Runner/Info.plist` → `CFBundleName` | **`qmatch`** | Short name; OK |
| `project.pbxproj` → `INFOPLIST_KEY_CFBundleDisplayName` (Debug) | **`OurSecrets`** | Stale override |
| `project.pbxproj` → `INFOPLIST_KEY_CFBundleDisplayName` (Release) | **`OurSecrets`** | Stale override |
| `project.pbxproj` → `INFOPLIST_KEY_CFBundleDisplayName` (Profile) | **`OurSecrets`** | Stale override |

Xcode’s `INFOPLIST_KEY_CFBundleDisplayName` can override `Info.plist` at build time → home screen may show **OurSecrets** on device/TestFlight. That is a **P0 branding bug** for release.

---

## 4. Stale OurSecrets references (inventory)

| Location | Setting | Current value |
|----------|---------|---------------|
| `project.pbxproj` Runner **Profile** | `PRODUCT_BUNDLE_IDENTIFIER` | `com.OurSecrets` |
| `project.pbxproj` Runner **Debug** | `INFOPLIST_KEY_CFBundleDisplayName` | `OurSecrets` |
| `project.pbxproj` Runner **Release** | `INFOPLIST_KEY_CFBundleDisplayName` | `OurSecrets` |
| `project.pbxproj` Runner **Profile** | `INFOPLIST_KEY_CFBundleDisplayName` | `OurSecrets` |

No `OurSecrets` in `Info.plist` or `GoogleService-Info.plist` (those already say Qmatch / `com.qmatch.app`).

---

## 5. Firebase iOS compatibility status

| Check | Status |
|-------|--------|
| Debug/Release bundle `com.qmatch.app` vs GoogleService-Info | **Compatible** |
| Profile `com.OurSecrets` vs GoogleService-Info | **Incompatible** — Profile archive may break Firebase Auth/init |
| Need new Firebase iOS app for this cleanup? | **No** — if Profile is fixed to `com.qmatch.app` |
| Need FlutterFire regenerate? | **No** for this plan |
| Future `site.qmatch.app` migration | Separate phase; **would** need new Firebase iOS app + new plist + `firebase_options` |

---

## 6. Android parked status

| Item | Status |
|------|--------|
| Android SDK on this Mac | Missing (`ANDROID_HOME` path absent) |
| Android `applicationId` | Remains `com.example.qmatch` until later phase |
| Android → `site.qmatch.app` | **Parked** (SDK + Firebase Android app + keystore later) |
| This phase Android file changes | **None** (docs may note parked only) |

---

## 7. Exact proposed changes for **next** implementation phase (do not apply now)

### A. `ios/Runner.xcodeproj/project.pbxproj`

1. Runner **Profile**: set `PRODUCT_BUNDLE_IDENTIFIER = com.qmatch.app;` (replace `com.OurSecrets`).  
2. Runner **Debug / Release / Profile**: set `INFOPLIST_KEY_CFBundleDisplayName = Qmatch;` (replace `OurSecrets`).  
   - Or delete the three `INFOPLIST_KEY_CFBundleDisplayName` lines so `Info.plist` `Qmatch` wins.  

### B. `ios/Runner/Info.plist`

- Keep `CFBundleDisplayName` = **Qmatch** (already correct).  
- Optional polish: `CFBundleName` → `Qmatch` (not required for store).  

### C. `pubspec.yaml`

- Set `version: 1.0.0+1` (currently `0.1.0`) for first TestFlight/App Store candidate.  

### D. Apple Developer / App Store Connect (ops, not repo)

- Confirm App ID **`com.qmatch.app`** exists for team `5V5NP5ATH2`.  
- Ensure provisioning / signing for Debug/Release/Profile use that App ID.  
- Create App Store Connect app with bundle **`com.qmatch.app`** if not already.  

### E. What next phase must **NOT** change

- Android `applicationId` / `google-services.json` / Gradle identity  
- Firebase project settings / regenerate FlutterFire for a new bundle  
- Firestore rules / Cloud Functions  
- Cloudflare / `qmatch.site` legal site  
- Assessment JSON / scoring / compatibility weights  

---

## 8. Risks

| Risk | Mitigation |
|------|------------|
| Shipping Profile/TestFlight with `com.OurSecrets` | Fix Profile bundle before archive |
| Home screen shows OurSecrets | Fix or remove `INFOPLIST_KEY_CFBundleDisplayName` |
| Accidental migrate to `site.qmatch.app` without Firebase | Out of scope; stay on `com.qmatch.app` |
| Mixing Android `com.example.qmatch` later | Park Android; do not submit Play until Android identity phase |
| Version still `0.1.0` looks unfinished | Bump to `1.0.0+1` in next phase |

---

## 9. Verification commands for next phase (after edits)

```bash
# Static checks
rg -n 'OurSecrets|com\.OurSecrets' ios/
rg -n 'PRODUCT_BUNDLE_IDENTIFIER|INFOPLIST_KEY_CFBundleDisplayName' ios/Runner.xcodeproj/project.pbxproj
flutter analyze

# Confirm Firebase plist still matches
rg -n 'BUNDLE_ID|com\.qmatch\.app' ios/Runner/GoogleService-Info.plist

# Build (device or simulator)
flutter build ios --release --no-codesign   # compile check
# Prefer Xcode: Product → Archive for TestFlight with signing

# Optional: inspect built Info.plist display name / bundle after archive
```

Manual: install build → home screen name is **Qmatch** → phone auth works with Firebase test number.

Then continue `docs/release_binary_smoke_test_checklist.md` (iOS rows).

---

## 10. Suggested next phase title

**3P-A33 — Apply iOS Identity Cleanup (`com.qmatch.app` + Qmatch display) and bump to 1.0.0+1**

Then: Archive → TestFlight → smoke ST-01…ST-32 on device.

---

## Explicit non-actions (this phase)

- No `pbxproj` / Info.plist / pubspec edits  
- No Firebase writes or config regeneration  
- No Android identity changes  
- No deploy / commit / push  

---

## Quick reference

| Item | Now | After next cleanup phase |
|------|-----|--------------------------|
| Debug/Release bundle | `com.qmatch.app` | `com.qmatch.app` |
| Profile bundle | `com.OurSecrets` | `com.qmatch.app` |
| Display override | `OurSecrets` | `Qmatch` (or removed) |
| Info.plist display | `Qmatch` | `Qmatch` |
| Version | `0.1.0` | `1.0.0+1` |
| Android | Parked | Still parked |
