# iOS Release Identity Cleanup Report (Phase 3P-A32B)

Date: 2026-07-18  
Mode: **Applied iOS-only identity cleanup** — no Android / Firebase Console / deploy changes  
Plan: `docs/ios_release_identity_cleanup_plan.md`

---

## 1. Before → after

| Item | Before | After |
|------|--------|-------|
| Runner Debug bundle | `com.qmatch.app` | **`com.qmatch.app`** |
| Runner Release bundle | `com.qmatch.app` | **`com.qmatch.app`** |
| Runner Profile bundle | `com.OurSecrets` | **`com.qmatch.app`** |
| `INFOPLIST_KEY_CFBundleDisplayName` (D/R/P) | `OurSecrets` | **`Qmatch`** |
| `Info.plist` `CFBundleDisplayName` | `Qmatch` | **`Qmatch`** (unchanged) |
| `Info.plist` `CFBundleName` | `qmatch` | **`Qmatch`** |
| `pubspec.yaml` version | `0.1.0` | **`1.0.0+1`** |
| Firebase `GoogleService-Info.plist` | `BUNDLE_ID=com.qmatch.app` | **Unchanged** |

RunnerTests targets remain `com.example.qmatch.RunnerTests` (test target only; not OurSecrets).

---

## 2. Files changed

| File | Change |
|------|--------|
| `ios/Runner.xcodeproj/project.pbxproj` | Profile bundle → `com.qmatch.app`; all three display-name keys → `Qmatch` |
| `ios/Runner/Info.plist` | `CFBundleName` → `Qmatch` |
| `pubspec.yaml` | `version: 1.0.0+1` |

**Not changed:** `android/**`, Firebase plists / `firebase_options.dart`, Firestore, legal site, assessment/scoring.

---

## 3. Firebase iOS compatibility

| Check | Status |
|-------|--------|
| Debug/Release/Profile all `com.qmatch.app` | **Yes** |
| Matches `ios/Runner/GoogleService-Info.plist` | **Yes** |
| Matches `lib/firebase_options.dart` `iosBundleId` | **Yes** |
| Regenerated Firebase configs? | **No** (not needed) |

---

## 4. Android parked status

| Item | Status |
|------|--------|
| Android identity | Still `com.example.qmatch` — **parked** |
| Android SDK on this Mac | Missing |
| This phase Android edits | **None** |

---

## 5. Remaining OurSecrets references

| Location | Remaining? |
|----------|------------|
| `ios/` project files after cleanup | **None** in identity settings |
| Historical docs (`production_app_identity_audit.md`, `ios_release_identity_cleanup_plan.md`) | May still **mention** OurSecrets as before-state — expected |

Live iOS config: **no** `OurSecrets` / `com.OurSecrets`.

---

## 6. Remaining release blockers (iOS path)

1. Create Xcode **Archive** / upload to **TestFlight** (signing + App Store Connect app for `com.qmatch.app`).  
2. Run `docs/release_binary_smoke_test_checklist.md` on device.  
3. Store privacy forms / URLs (already prepared in ops docs).  
4. Android path still blocked (SDK + identity) — separate later phase.  

---

## 7. Exact next commands

```bash
flutter analyze
flutter build ios --release --no-codesign   # optional compile check

# Preferred for TestFlight (Xcode UI):
# open ios/Runner.xcworkspace
# Select Runner → Any iOS Device (arm64)
# Product → Archive → Distribute App → App Store Connect / TestFlight
```

Confirm on device: home screen name **Qmatch**, bundle **com.qmatch.app**, version **1.0.0 (1)**.

---

## Explicit non-actions

No Android changes · no Firebase writes/regen · no hosting/DNS · no commit/push  

---

## Related

- `docs/ios_release_identity_cleanup_plan.md`  
- `docs/production_app_identity_audit.md`  
- `docs/release_binary_smoke_test_checklist.md`  
