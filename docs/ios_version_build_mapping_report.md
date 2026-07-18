# iOS Version / Build Mapping Report (Phase 3P-A32C)

Date: 2026-07-18  
Mode: Fix stale Flutter → Xcode version mapping only — no Android / Firebase / deploy

---

## 1. Before (observed)

| Item | Observed |
|------|----------|
| Xcode Display Name | Qmatch (OK) |
| Xcode Bundle ID | `com.qmatch.app` (OK) |
| Xcode Version / Build | Wrong / stale — **Build appeared as `0.1.0`** |
| `pubspec.yaml` | Already `1.0.0+1` |
| `ios/Flutter/Generated.xcconfig` (stale) | `FLUTTER_BUILD_NAME=0.1.0`, **`FLUTTER_BUILD_NUMBER=0.1.0`**, `FLUTTER_TARGET` pointed at a tool dart file |

Root cause: stale `Generated.xcconfig` left `CURRENT_PROJECT_VERSION=$(FLUTTER_BUILD_NUMBER)` resolving to **0.1.0**, so Xcode’s Build field showed the old marketing version string.

---

## 2. After (expected / verified on disk)

| Item | Value |
|------|--------|
| Source of truth | `pubspec.yaml` → **`1.0.0+1`** |
| `FLUTTER_BUILD_NAME` | **`1.0.0`** |
| `FLUTTER_BUILD_NUMBER` | **`1`** |
| `FLUTTER_TARGET` | **`lib/main.dart`** |
| Runner `MARKETING_VERSION` | **`$(FLUTTER_BUILD_NAME)`** → 1.0.0 |
| Runner `CURRENT_PROJECT_VERSION` | **`$(FLUTTER_BUILD_NUMBER)`** → 1 |
| Info.plist `CFBundleShortVersionString` | `$(FLUTTER_BUILD_NAME)` → **1.0.0** |
| Info.plist `CFBundleVersion` | `$(FLUTTER_BUILD_NUMBER)` → **1** |

**Xcode General tab should show:** Version **1.0.0**, Build **1** (after reopen / clean if UI cached).

---

## 3. Files changed

| File | Change |
|------|--------|
| `ios/Flutter/Generated.xcconfig` | Regenerated via `flutter build ios --config-only` (1.0.0 / 1 / lib/main.dart) |
| `ios/Runner.xcodeproj/project.pbxproj` | Added `MARKETING_VERSION = "$(FLUTTER_BUILD_NAME)"` to Runner Debug / Profile / Release |

**Unchanged:** `pubspec.yaml` (already 1.0.0+1), `Info.plist` mapping (already correct), Android, Firebase configs.

---

## 4. Commands run

```bash
flutter pub get
flutter build ios --config-only
flutter analyze
```

---

## 5. How to verify in Xcode

1. Quit Xcode if open (clears stale UI).  
2. `open ios/Runner.xcworkspace`  
3. Select **Runner** target → **General**:  
   - Display Name: **Qmatch**  
   - Bundle Identifier: **com.qmatch.app**  
   - Version: **1.0.0**  
   - Build: **1**  
4. If still stale: Product → Clean Build Folder, then re-check.  
5. Optional CLI check: reopen `ios/Flutter/Generated.xcconfig` and confirm `FLUTTER_BUILD_NAME=1.0.0` / `FLUTTER_BUILD_NUMBER=1`.

---

## 6. Next archive step

```bash
open ios/Runner.xcworkspace
# Runner → Any iOS Device (arm64)
# Product → Archive → Distribute → TestFlight
```

Then run `docs/release_binary_smoke_test_checklist.md` on the TestFlight/device build.

---

## Explicit non-actions

No Android changes · no Firebase writes · no hosting/DNS · no commit/push  

---

## Related

- `docs/ios_release_identity_cleanup_report.md`  
- `docs/ios_release_identity_cleanup_plan.md`  
