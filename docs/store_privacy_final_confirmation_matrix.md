# Store Privacy Final Confirmation Matrix (Phase 3P-A25)

Date: 2026-07-18
Project: Qmatch (`qmatch-53d62`)
Mode: **Founder-review matrix only** — not legal advice; no app/Firebase/deploy changes in this phase

Sources: `pubspec.yaml`, `lib/`, `firebase.json`, Android/iOS manifests,
`docs/store_privacy_questionnaire_pack.md`, `docs/launch_readiness_consolidated_audit.md`,
`docs/qmatch_site_live_verification.md`, `docs/qmatch_site_support_mailbox_verification.md`,
`docs/account_deletion_manual_ops_runbook.md`, `docs/account_deletion_processor_plan.md`

### Confidence legend

| Label | Meaning |
|-------|---------|
| **Confirmed** | Strong evidence in code/docs for the recommended store answer |
| **Needs Founder Confirmation** | Incomplete proof, Console-only possibility, product/legal judgment, or stub/UI ambiguity |
| **Not Present** | Package/API/path not found in `pubspec` / `lib` (or stub-only with no collection) |

### Verified public contacts (3P-A24 — do not re-block)

| Field | Value |
|-------|--------|
| Privacy | `https://qmatch.site/privacy/` |
| Terms | `https://qmatch.site/terms/` |
| Support | `https://qmatch.site/support/` |
| Account deletion | `https://qmatch.site/account-deletion/` |
| Support email | `support@qmatch.site` → `sirinumit@gmail.com` (receive confirmed) |

---

## Master matrix

| # | Item | Current evidence from code/docs | Recommended store answer | Confidence | Notes |
|---|------|---------------------------------|--------------------------|------------|-------|
| A1 | Phone number | Firebase Phone Auth is primary welcome path (`WelcomeScreen` → `PhoneSignupScreen`); `AuthService` phone credential flow | **Collect: Yes.** Linked to user. Not used for tracking. Purposes: App Functionality, Account Management | Confirmed | Required for phone signup path |
| A2 | Email address | Email/password signup & login exist (`signUpWithEmail`, `SocialLoginScreen` email form, email verification screens) | **Collect: Yes** (when email path used). Linked. Not tracking. App Functionality / Account Management | Confirmed | Optional vs phone path; still declare if email auth ships |
| B1 | Name / display name | Required in profile setup; stored on Firestore user (`UserProfileModel.name`) | **Collect: Yes.** Linked. App Functionality | Confirmed | Shown to other users in Discover/chat |
| B2 | Age | Required (≥18) in profile setup; stored as `age` | **Collect: Yes.** Linked. App Functionality | Confirmed | Eligibility + matching |
| B3 | Bio | Required in setup; `bio` on user doc | **Collect: Yes** (Other User Content / User Content). Linked. App Functionality | Confirmed | |
| B4 | Gender | Required; `gender` field | **Collect: Yes.** Linked. App Functionality | Confirmed | Dating preference context — see Q1 |
| B5 | Looking-for / age range / distance preference | `lookingFor`, `ageRange`, `distancePreference` in profile model | **Collect: Yes.** Linked. App Functionality / Product Personalization | Confirmed | |
| B6 | Interests / lifestyle | Interests + lifestyle fields (occupation, drinking, smoking, pets, children, religion, etc.) | **Collect: Yes.** Linked. App Functionality / Personalization | Confirmed | |
| C1 | Profile photos | `PhotoUploadService` → Firebase Storage `profile_photos/{uid}/…`; URLs on user doc | **Collect: Yes** (Photos). Linked. App Functionality | Confirmed | Visible to other users |
| C2 | Chat / messages | `threads` + messages via chat feature | **Collect: Yes** (Other User Content / Messages). Linked. App Functionality | Confirmed | Shared with match participant via Firebase |
| C3 | Reports / blocks | `SafetyService` / reports + blocks | **Collect: Yes** (Other User Content / safety). Linked. App Functionality / Fraud Prevention | Confirmed | Reports may be retained per ops plan |
| D1 | Assessment answers | IQ/EQ/Frequency tests write answers/results | **Collect: Yes.** Linked. App Functionality | Confirmed | Required to unlock main loop |
| D2 | Assessment results / archetype / category | Scores/tags/vectors/archetype on user | **Collect: Yes** (Other Data / User Content as appropriate). Linked. App Functionality | Confirmed | App-specific signals — not clinical IQ/EQ certificates |
| D3 | Compatibility scores | Used in Discover/match `compat` | **Collect: Yes** (derived). Linked. App Functionality | Confirmed | |
| E1 | Approximate location text | Optional share; reverse-geocoded city/region string → `location_text` | **Collect: Yes** (Coarse Location) if user enables. Linked. App Functionality | Confirmed | Optional in basic info step |
| E2 | Lat/lng GeoPoint | `Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)` then `GeoPoint` stored | **Declare Precise Location as collected** if shipping this binary as-is, **or** change accuracy/storage before submit | Needs Founder Confirmation | Privacy copy says “approximate,” but code requests **high** accuracy and stores full coordinates. iOS `Info.plist` currently lacks explicit `NSLocation*` strings in repo (plugin may still request at runtime — founder must validate binary entitlements/prompts) |
| F1 | Firebase Auth UID | Always present for signed-in users | **User ID: Yes.** Linked. App Functionality / Account Management | Confirmed | |
| F2 | Device ID / advertising ID | No `device_info`, Ads, ATT, or advertising ID APIs in `pubspec`/`lib` | **Do not declare** device/advertising IDs unless Console/SDK proof appears | Needs Founder Confirmation | Confirm Firebase Console / binary has no Analytics/Ads ID collection |
| G1 | Swipes | Stored under user swipes | **Collect: Yes** (Product Interaction / Other Usage). Linked. App Functionality | Confirmed | |
| G2 | Matches | `matches/{id}` | **Collect: Yes.** Linked. App Functionality | Confirmed | Other user retains relationship |
| G3 | Chat activity metadata | Thread metadata + messages | **Collect: Yes.** Linked. App Functionality | Confirmed | |
| G4 | Assessment progress | Assignment/result docs | **Collect: Yes.** Linked. App Functionality | Confirmed | |
| H1 | Firebase Analytics SDK | Not in `pubspec.yaml`; no Analytics imports in `lib` | **App Analytics SDK: Not collected via app package** | Confirmed (app deps) | |
| H2 | Crashlytics / Performance | Not in `pubspec`; no Crashlytics imports | **Crash data via Crashlytics package: Not Present** | Confirmed (app deps) | |
| H3 | Console-only / Google diagnostics | Unknown without Firebase Console inspection | Confirm whether Google Analytics/Crashlytics/Performance enabled on project | Needs Founder Confirmation | Could affect store diagnostics answers |
| I1 | Push / FCM | No `firebase_messaging` in `pubspec`; notification toggles are local `setState` only (`NotificationsSettingsScreen`); MVP note in UI | **Push notifications not implemented** — do not claim FCM delivery | Confirmed | UI placeholders only; not persisted / not sent to server in inspected code |
| J1 | Google Sign-In | `google_sign_in` in `pubspec` but **no import/usage in `lib`**; Social UI button `onPressed` empty stub | **Not collecting Google account data via Sign-In** for current shipping path | Confirmed (not wired) | Founder should confirm: hide stub buttons or implement before marketing “Continue with Google” |
| J2 | Sign in with Apple | `sign_in_with_apple` in `pubspec`; **no import/usage**; Apple button stub | **Not collecting Apple account data via Sign in with Apple** | Confirmed (not wired) | Same UI risk as Google |
| J3 | Primary auth shipping path | Welcome → phone signup | Phone-first is the real path | Confirmed | Email/password also real if that screen ships |
| K1 | Third-party sharing (sale) | Privacy/policy + inventory: no ads/sale SDKs found | **Do not sell personal data** | Confirmed (code inventory) | |
| K2 | Service providers | Firebase Auth / Firestore / Storage / Hosting stack; Cloudflare for web/email routing | **Share with processors to operate service (Google/Firebase; Cloudflare for site/email)** — not “sold” | Needs Founder Confirmation | Exact subprocessor list / legal wording needs founder/legal |
| L1 | Advertising / ATT tracking | No ads SDKs; no ATT APIs found | **No advertising; no cross-app tracking declared** | Confirmed (code inventory) | |
| L2 | Google Fonts network fetch | `google_fonts` used widely (`AppTheme`, many screens) — typically fetches from Google at runtime unless bundled | Confirm whether fonts are cached/bundled offline; Apple “tracking” interpretation | Needs Founder Confirmation | Not an ads SDK; still a third-party network call |
| M1 | Encryption in transit | Firebase/HTTPS for Auth, Firestore, Storage; site HTTPS on `qmatch.site` | **Yes — data encrypted in transit** | Confirmed | Standard TLS; wording “encryption at rest” still Needs Founder Confirmation if form asks beyond Firebase defaults |
| N1 | Account deletion path | In-app Settings → Delete account request; web `https://qmatch.site/account-deletion/`; email `support@qmatch.site` | **Users can request deletion**; process within **30 days** | Confirmed | Initiation live; fulfillment manual |
| O1 | Retention / manual ops | `EXECUTE_IMPLEMENTED` off; runbook + processor plan: manual wipe; reports may retain/anonymize | Declare deletion + limited safety/legal retention as in policy | Needs Founder Confirmation | Founder must staff B1 ops; confirm retention wording matches practice |
| P1 | Photo library | `image_picker` gallery / `pickMultipleMedia`; iOS photo usage strings; Android media/storage permissions | **Photos permission used for profile uploads** | Confirmed | |
| P2 | Camera | Android `CAMERA` permission + iOS `NSCameraUsageDescription`; current upload code paths use **gallery** / media picker, not explicit `ImageSource.camera` | Declare camera only if binary can open camera; else remove unused permission/strings | Needs Founder Confirmation | Mismatch risk: permission present, primary code path is gallery |
| Q1 | Sensitive / health classification | Assessments described as app compatibility signals; religion/lifestyle may be sensitive under some regimes | **Do not declare Health/clinical categories** for IQ/EQ/Frequency; founder/legal on Sensitive Info | Needs Founder Confirmation | Dating + religion fields may need counsel judgment |
| R1 | Payments | No IAP/payment SDK in `pubspec` | **No payment info collected** | Not Present | |
| R2 | Address book / contacts | Not found | **Not collected** | Not Present | |
| R3 | `shared_preferences` / `url_launcher` / standalone `http` | Not in `pubspec` | N/A | Not Present | Privacy toggles are ephemeral local UI state only |
| R4 | Ads ID / ATT | Not found | **Not Present** | Not Present | |

---

## Grouped founder checklist (fill before store submit)

### Confirmed store-ready (engineering evidence)

- [x] Phone (+ optional email) contact info collected for auth
- [x] Profile fields (name, age, gender, bio, interests, preferences, lifestyle)
- [x] Photos, chat, reports/blocks
- [x] Assessment answers/results/compatibility
- [x] Coarse location **text** when user shares location
- [x] Firebase UID
- [x] Swipes / matches / chat / assessment usage data
- [x] No Analytics/Crashlytics/FCM packages in app deps
- [x] Google/Apple Sign-In **not wired** (stubs only)
- [x] No ads/ATT SDKs found
- [x] Deletion **request** path + public URLs + support email receive
- [x] Encryption in transit via Firebase/HTTPS

### Needs Founder Confirmation (block store form submit until answered)

1. **Precise vs coarse location** — high-accuracy GPS + `GeoPoint` vs “approximate” marketing copy
2. **Firebase Console** Analytics / Crashlytics / Performance / Google diagnostics enabled?
3. **Device / advertising IDs** beyond Auth UID — none in app code; confirm Console/binary
4. **Camera** declaration vs gallery-only upload code + unused-looking camera permission strings
5. **Google Fonts** network behavior / whether to note third-party font fetch
6. **Subprocessor list** wording (Google Firebase, Cloudflare)
7. **Encryption at rest** form wording beyond Firebase defaults
8. **Retention** of reports/logs after deletion — align ops practice + policy
9. **Sensitive data** (religion, dating prefs, assessments) counsel classification
10. **Ship decision** on SocialLoginScreen Apple/Google stub buttons (hide vs implement)
11. **Deletion fulfillment staffing** (manual ops within 30 days) — launch blocker B1

### Not Present / not used (do not over-declare)

- Firebase Analytics / Crashlytics / Performance packages
- `firebase_messaging` / real push delivery
- Working Google Sign-In / Sign in with Apple collection
- Ads / ATT / advertising ID SDKs
- `shared_preferences`, `url_launcher`, standalone `http` packages
- Payments / address book

---

## Remaining launch blockers (from audit + this matrix)

| ID | Item | Status |
|----|------|--------|
| B1 | Deletion fulfillment ops (manual) | Still open |
| B3 | Founder confirmation of this matrix’s NFC rows | Still open — use this doc |
| — | Optional counsel review | Recommended, not engineering-blocked |
| — | Optional Gmail send-as `support@qmatch.site` | Not a launch blocker |

Cleared earlier: hosted legal URLs · support mailbox receive/monitor.

---

## Explicit non-actions (this phase)

- No app behavior changes
- No Firestore rules / Firebase writes
- No hosting deploy / DNS
- No Admin SDK
- No assessment JSON / scoring changes
- No commit / push

---

## Related

- `docs/store_privacy_questionnaire_pack.md`
- `docs/launch_readiness_consolidated_audit.md`
- `docs/qmatch_site_live_verification.md`
- `docs/qmatch_site_support_mailbox_verification.md`
