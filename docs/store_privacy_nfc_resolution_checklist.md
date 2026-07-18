# Store Privacy NFC Resolution Checklist (Phase 3P-A27)

Date: 2026-07-18  
Mode: **Repo evidence pass** — no app/Firebase/deploy changes  
Sources: `pubspec.yaml`, `pubspec.lock`, `ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`, `firebase.json`, `lib/`, answer sheet + matrix

### How to use

| Column | Meaning |
|--------|---------|
| Resolved from repo? | Engineering can lock a **store-form answer** for the current binary |
| Remaining founder action | Human/Console/legal/ops only |

---

## Resolution table

| ID | Item | Evidence found | Resolved from repo? | Recommended final answer | Remaining founder action | Risk |
|----|------|----------------|---------------------|--------------------------|--------------------------|------|
| A | Precise vs approximate location | `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)`; stores `GeoPoint` lat/lng + `location_text`; optional user action in `basic_info_step.dart`. App `AndroidManifest` has **no** explicit `ACCESS_FINE_LOCATION` (plugin may still request at runtime). iOS `Info.plist` has **no** `NSLocation*UsageDescription` in repo. | **Yes** (for form, shipping as-is) | Declare **Precise Location = Yes** and **Coarse Location = Yes** (when user enables). Linked. Not tracking. Purpose: App Functionality | Optional later: change code to coarse-only / stop storing GeoPoint, then drop Precise. Also add proper iOS location usage strings before shipping location feature if missing causes runtime failure | **High** if declare Coarse-only while GeoPoint + high accuracy ship |
| B | Camera vs gallery / photo permissions | Code: `ImageSource.gallery`, `pickMultipleMedia` only — **no** `ImageSource.camera`. iOS: `NSCameraUsageDescription` + photo library strings. Android: `CAMERA`, `READ_MEDIA_IMAGES`, storage. `permission_handler` in pubspec but **unused in `lib/`** | **Yes** (data collection path) | **Photos collected: Yes** (library/media picker). Do **not** claim the app’s photo pipeline is camera-capture. App Privacy “Photos” still Yes | Decide: remove unused camera permission/strings **or** implement camera. Review App Store permission-string honesty | **Medium** (unused camera permission / review questions) |
| C | Analytics / Crashlytics packages | Not in pubspec; Console: Analytics 0 events; Crashlytics/Performance **Add SDK** (3P-A29) | **Yes** | Diagnostics / Analytics / Crash / Performance = **No** | None for launch | Low |
| D | FCM / push packages | No firebase_messaging; Messaging = create campaign only (3P-A29) | **Yes** | Push = **No** | None | Low |
| E | Google / Apple Sign-In wiring | Packages in pubspec; **zero** `lib` imports; SocialLoginScreen buttons empty stubs | **Yes** | **Not collecting** Google/Apple account data via Sign-In | Hide stub buttons or implement before marketing “Continue with Google/Apple”. Google URL scheme exists in Info.plist (Firebase/Google config residue) | **Medium** (UI implies capability) |
| F | Device / advertising IDs | No `device_info`, ads, ATT, `AppTrackingTransparency` in deps/`lib` | **Yes** (app code) | Advertising ID / ATT: **No**. Device ID: **No** in app | Spot-check Console / binary for unexpected ID collection | **Low–Medium** |
| G | Google Fonts / external fonts | `google_fonts` dependency; widespread `GoogleFonts.playfairDisplay` / `GoogleFonts.inter` — default behavior fetches from Google when not bundled | **Yes** (network font use likely) | Not an ads/ATT SDK. Treat as **third-party network dependency** for fonts. Tracking answer remains **No** unless counsel says otherwise | Confirm whether fonts are runtime-fetched or pre-bundled in release build; optional: bundle fonts offline | **Low** for store privacy forms |
| H | Sensitive-data classification | Fields: `gender`, `lookingFor`, optional `religion`, lifestyle; assessments are app signals (not clinical). No dedicated sexual-orientation field found | **Partial** | **Health: No.** Collect gender/looking-for/religion as profile data. Apple “Sensitive Info” / Play sensitive labeling → **counsel** | Legal/founder: declare Sensitive Info or not; relationship-preference wording | **High** (legal) |
| I | Retention after deletion | Runbook §11: retain `reports`; anonymize/close matches; wipe profile/media/assessments; Auth last; `EXECUTE_IMPLEMENTED=false`; 30-day SLA | **Yes** (documented ops intent) | Users can request deletion; fulfillment manual ≤30 days; **limited safety/legal retention** (reports) as stated in policy/runbook | Staff ops owner (B1); ensure live privacy page matches retention practice | **High** if ops unstaffed |
| J | Subprocessors wording | Firebase Auth/Firestore/Storage in app; Cloudflare Pages + Email Routing for `qmatch.site` / support | **Partial** | Data shared with **processors to operate service** (Google/Firebase; Cloudflare for site/email). **Not sold** | Legal finalize subprocessor list / DPA language | **Medium** (legal) |
| K | Encryption at rest wording | Transit: Firebase/HTTPS Confirmed. At-rest: Firebase defaults (not separately configured in repo) | **Partial** | In transit: **Yes**. At rest: “Firebase/Google default encryption” if form asks — do not invent custom claims | Confirm exact Play/Apple form wording with founder | **Low–Medium** |
| L | Deletion ops staffing | Docs require manual fulfillment; automation off | **Yes (ops)** | Staffed: **Ümit**, weekly, ≤30 days (3P-A29) | Maintain cadence | Ops |
| M | Gmail send-as | Mailbox receive confirmed to `sirinumit@gmail.com` (3P-A24) | **Yes** (optional) | **Not required** for store submit | Optional Gmail “Send mail as support@qmatch.site” | **None** |

---

## Summary: resolved vs still human

### Resolved from repository (lock these form answers)

1. **Precise + Coarse location** — declare both for current binary  
2. **Photos** — yes, via gallery/media picker  
3. **Camera capture pipeline** — not used in code (permission strings still present)  
4. **No Analytics/Crashlytics/FCM packages**  
5. **No wired Google/Apple Sign-In collection**  
6. **No ads/ATT / advertising ID in app**  
7. **Google Fonts in use** (network dependency; not ATT tracking by engineering view)  
8. **Deletion request available**; retention of reports documented in runbook  
9. **Gmail send-as** optional  

### Still requires founder / legal (optional for submit)

| Priority | Action |
|----------|--------|
| P1 | Legal: Sensitive Info (religion / dating prefs / gender) |
| P1 | Legal: subprocessors + encryption-at-rest form wording |
| P2 | Product: remove unused camera permission **or** implement camera |
| P2 | Product: hide Google/Apple stub buttons |
| P2 | Optional: Gmail send-as; offline-bundle fonts |

~~Console Analytics/Crashlytics/FCM~~ — verified **No** (3P-A29)  
~~Deletion ops owner~~ — **Ümit**

---

## Platform permission snapshot (repo)

| Platform | Declared in project manifests | Notes |
|----------|------------------------------|-------|
| iOS | Camera + Photo Library (+ Add) usage strings | **No** `NSLocation*UsageDescription` in `Info.plist` despite geolocator use — verify before release |
| Android app manifest | `CAMERA`, `READ_MEDIA_IMAGES`, storage R/W | **No** explicit location permissions in app manifest; geolocator may still need them added for release |
| `firebase.json` | FlutterFire only | No hosting/Analytics blocks |

---

## Explicit non-actions (this phase)

No app behavior changes · no Firebase writes · no deploy · no DNS · no commit/push

Related: `docs/store_privacy_form_answer_sheet.md`, `docs/store_privacy_final_confirmation_matrix.md`
