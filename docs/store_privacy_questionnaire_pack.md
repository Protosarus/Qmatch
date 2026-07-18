# Store Privacy Questionnaire Pack (Phase 3P-A19)

Date: 2026-07-18
Project: Qmatch (`qmatch-53d62`)
Mode: **Draft for App Store App Privacy + Google Play Data Safety**
Status: Engineering-derived draft — **not legal advice**; confirm with founder/legal before store submit

Sources inspected: `pubspec.yaml`, Auth/Profile/Assessment/Discover/Chat/Safety/Settings/Deletion services, Firebase usage, in-app Privacy draft, launch audit.

---

## Disclaimer

- Do **not** overclaim. Items marked **NEEDS CONFIRMATION** must be resolved before submitting store forms.
- In-app Privacy/Terms are product drafts.
- Account deletion **request** is in-app; fulfillment is currently **manual ops** within ~30 days.
- No dedicated analytics/crash SDK was found in `pubspec.yaml` (Firebase Analytics / Crashlytics / Sentry **not** listed).

---

## 1. Third-party / SDK inventory (from `pubspec.yaml` + code)

| SDK / service | In app? | Notes |
|---------------|---------|--------|
| Firebase Auth | Yes | Phone + email/password paths |
| Cloud Firestore | Yes | Profiles, assessments, matches, threads, reports, deletion requests |
| Firebase Storage | Yes | `profile_photos/{uid}/…` |
| Firebase Core | Yes | Init |
| `google_sign_in` | Dependency present | Social screen exists; **welcome primary path is phone** — NEEDS CONFIRMATION if shipped live |
| `sign_in_with_apple` | Dependency present | Same — NEEDS CONFIRMATION if shipped live |
| `geolocator` / `geocoding` | Yes | Optional approximate location in profile setup |
| `image_picker` / `permission_handler` | Yes | Photos + permissions |
| `google_fonts` | Yes | May fetch fonts over network at runtime — NEEDS CONFIRMATION (privacy/network) |
| `flutter_riverpod` | Yes | Local state; not a data broker |
| `intl_phone_field` / Font Awesome | Yes | UI |
| `flutter_windowmanager` | Yes | Likely screenshot/secure flag — not user data collection |
| Firebase Analytics | **No** (not in pubspec) | Declare “not collected via Analytics SDK” unless Console/other tooling adds it — NEEDS CONFIRMATION |
| Firebase Crashlytics / Performance | **No** (not in pubspec) | NEEDS CONFIRMATION (Console-only enablement?) |
| Firebase Cloud Messaging / push | **No FCM package** | Notification toggles appear **device-local UI**; push delivery not implemented in inspected deps — NEEDS CONFIRMATION |
| Ads / ATT tracking SDKs | **Not found** | Draft assumes **no advertising tracking** unless founder adds later |

**Processors (typical Firebase stack):** Google LLC / Firebase as infrastructure. Treat as **third-party service providers** used to operate the app (not “sold” data). Exact subprocessors list — NEEDS CONFIRMATION with legal.

---

## 2. Data inventory table

| Data type | Collected? | Required / optional | Purpose | Stored where | Shared with third parties? | Linked to user? | Used for tracking? | Retention notes | Deletion notes |
|-----------|------------|---------------------|---------|--------------|---------------------------|-----------------|--------------------|-----------------|----------------|
| Phone number | Yes (phone auth) | Required for phone signup | Account / auth | Firebase Auth (+ may mirror on user profile fields) | Yes — Firebase/Google as processor | Yes | No (app purpose); NEEDS CONFIRMATION re: any ads ID | While account active; Auth until deleted | Requested via in-app deletion; manual wipe; Auth delete last (ops) |
| Email | Yes if email login/signup used | Optional vs phone path | Account / auth / verification | Firebase Auth / user docs | Firebase/Google | Yes | No | Same | Same |
| Name / display name | Yes | Required for profile | Profile / matching UX | Firestore `users/{uid}` | Firebase; visible to other signed-in users (Discover/chat) | Yes | No | While account active | Deleted/anonymized on fulfillment |
| Age / birth-related age | Yes | Required (≥18) | Eligibility / matching filters | Firestore users | Firebase; may be shown to others | Yes | No | While account active | Deleted on fulfillment |
| Bio, interests, lifestyle, preferences | Yes | Mostly required to complete setup | Profile / personalization / matching | Firestore users | Firebase; shown to others per product | Yes | No | While account active | Deleted on fulfillment |
| Approximate location (GeoPoint / text) | Yes if user enables | Optional | Matching / profile | Firestore users | Firebase; may be shown approx. to others | Yes | No | While account active | Deleted on fulfillment |
| Profile photos | Yes if uploaded | Optional for wizard; encouraged | Profile / discovery | Firebase Storage `profile_photos/{uid}/` + URLs on user doc | Firebase; shown to other users | Yes | No | While account active | Storage prefix delete on fulfillment |
| Assessment answers (IQ/EQ/Frequency) | Yes | Required to unlock app loop | Compatibility / app functionality | Firestore user assignments/results; scores/tags/vectors on user | Firebase; derived signals may be shown (archetype etc.) | Yes | No | While account active | Subcollections deleted on fulfillment |
| Compatibility / Frequency vector / scores | Yes (derived) | Generated from assessments | Matching / ranking | Firestore users / match `compat` | Firebase; used in Discover | Yes | No | While account active | Cleared with user data |
| Swipes | Yes | Required to use Discover | Matching | `users/{uid}/swipes` | Firebase | Yes | No | While account active | Deleted on fulfillment |
| Matches | Yes | If mutual like | Relationship graph / chat entry | `matches/{id}` | Firebase; other participant retains relationship | Yes | No | While either party active | Close/anonymize on deletion (other user retained) |
| Chat messages / thread metadata | Yes | Optional feature | Communication | `threads` + `messages` | Firebase; other participant | Yes | No | While thread active | Redact/delete sender content on fulfillment (policy) |
| Reports | Yes | Optional (user-initiated) | Safety / abuse | `reports` | Firebase; ops may review | Yes | No | May retain for safety/legal | **Retain / anonymize** — not wiped with profile |
| Blocks | Yes | Optional | Safety | `users/{uid}/blocks` | Firebase | Yes | No | While account active | Deleted with user subcollections (ops may snapshot) |
| Account deletion request metadata | Yes | When user requests | Account management / compliance | `account_deletion_requests/{uid}` + soft marker | Firebase | Yes | No | Audit retain after completion | Request doc retained; status updated by ops |
| Notification preference toggles | Local UI | Optional | UX | Device-local (per settings note) | No (if truly local only) | Indirectly | No | Device | Cleared with app uninstall; NEEDS CONFIRMATION if later synced |
| Device identifiers / advertising ID | Unknown | — | — | — | — | — | **NEEDS CONFIRMATION** | — | — |
| Crash logs / diagnostics | Unknown | — | — | — | — | — | **NEEDS CONFIRMATION** | — | — |
| Analytics events | Not found in app deps | — | — | — | — | — | Draft: **No** unless Console enabled | — | — |
| Payment / purchase info | No | — | — | — | — | — | No | — | — |
| Health / clinical data | No (assessments are app signals, not medical) | — | — | — | — | — | No — do not label as Health | — | — |
| Precise contacts from address book | No | — | — | — | — | — | No | — | — |

---

## 3. Apple App Privacy (App Store Connect) — draft

Use as a starting checklist in App Privacy. Adjust after NEEDS CONFIRMATION items.

### Contact Info
| Type | Collect? | Linked to user? | Used for tracking? | Purpose(s) |
|------|----------|-----------------|--------------------|------------|
| Phone Number | Yes | Yes | No | App Functionality, Account Management |
| Email Address | Yes (if email auth used) | Yes | No | App Functionality, Account Management |
| Name | Yes | Yes | No | App Functionality |

### User Content
| Type | Collect? | Linked? | Tracking? | Purpose(s) |
|------|----------|---------|-----------|------------|
| Photos or Videos | Yes (profile photos) | Yes | No | App Functionality |
| Customer Support | Possible via email to support | Yes | No | App Functionality / Other |
| Other User Content | Bio, chat messages, reports | Yes | No | App Functionality, Other (safety) |

### Identifiers
| Type | Collect? | Linked? | Tracking? | Notes |
|------|----------|---------|-----------|-------|
| User ID | Yes (Firebase Auth uid) | Yes | No | Account / functionality |
| Device ID | Unknown | — | — | **NEEDS CONFIRMATION** |

### Location
| Type | Collect? | Linked? | Tracking? | Purpose(s) |
|------|----------|---------|-----------|------------|
| Coarse Location | Yes if enabled | Yes | No | App Functionality |
| Precise Location | Possible via geolocator accuracy — **NEEDS CONFIRMATION** (treat as coarse if only approx shown) | Yes | No | App Functionality |

### Usage Data
| Type | Collect? | Notes |
|------|----------|-------|
| Product Interaction | Likely via product Firestore writes (swipes, etc.) — declare as collected if you consider server-side activity “collected” | Linked; not tracking |
| Advertising Data | No (no ads SDK found) | — |
| Other Usage Data | **NEEDS CONFIRMATION** (Firebase automatic logs) | |

### Diagnostics
| Type | Collect? | Notes |
|------|----------|-------|
| Crash Data | **NEEDS CONFIRMATION** | Not in pubspec |
| Performance Data | **NEEDS CONFIRMATION** | |
| Other Diagnostic Data | **NEEDS CONFIRMATION** | |

### Sensitive Info
| Type | Collect? | Notes |
|------|----------|-------|
| Sensitive Info | **Generally No** for medical/health categories | IQ/EQ/Frequency are **app compatibility signals**, not clinical diagnoses — do **not** claim Health Research / clinical Health unless legal says otherwise. Dating preferences may still be sensitive under some regimes — **NEEDS CONFIRMATION** with counsel |

### Photos / media
- Collected: **Yes** when user uploads
- Linked: **Yes**
- Tracking: **No** (draft)
- Purpose: App Functionality

### Messages
- Collected: **Yes** if user chats
- Linked: **Yes**
- Tracking: **No**
- Purpose: App Functionality

### Assessment answers / results
- Declare under **User Content** and/or **Other Data** as product questionnaire/results used for matching
- Linked: **Yes**
- Tracking: **No**
- Purpose: App Functionality, Product Personalization (matching)

### Tracking
- Draft assumption: **App does not track** users across apps/websites for ads (no ATT tracking SDK found).
- If Google Fonts or Firebase telemetry is interpreted as tracking under Apple’s definition — **NEEDS CONFIRMATION** with legal.
- Recommend: do not enable advertising networks without updating this pack.

### Open questions (Apple) — NEEDS CONFIRMATION
1. Is Sign in with Apple / Google Sign-In shipping in the binary under review?
2. Exact location precision collected (coarse vs precise)?
3. Any Crashlytics / Analytics enabled only in Firebase Console?
4. Privacy Policy **public URL** for App Store Connect field?
5. Account deletion: in-app path sufficient for listing, plus support email?
6. Counsel classification of assessment/preference data as “sensitive”?

---

## 4. Google Play Data Safety — draft

### Data collected (yes)

- Personal info: name, email (if used), phone, user IDs
- Photos
- Messages (chat)
- App activity: swipes, matches, in-app assessment interactions (server-side)
- Location: approximate if user opts in
- Other: assessment results / compatibility signals; reports/blocks; deletion request records

### Data shared

- Draft: **Data is shared with service providers** (Google Firebase) to operate the app.
- Draft: **Not sold**.
- Draft: **Shared with other users** as part of product (profile, photos, chat with matches) — declare appropriately under “sharing” / “visible to others” per Play form wording.
- Ads sharing: **No** (not found).

### Encryption in transit

- Draft: **Yes** — Firebase/HTTPS for Auth, Firestore, Storage (standard).
- Encryption at rest: Firebase defaults — **NEEDS CONFIRMATION** for form wording.

### User can request deletion

- Draft: **Yes**
  - In-app: Settings → Delete account (request)
  - Email: `support@qmatch.site`
  - Processing: within **30 days** (manual ops currently)
- Account deletion URL (web): `https://qmatch.site/account-deletion/` (**verified live**, 3P-A24)

### Required vs optional (Play)

| Data | Required to use core app? |
|------|---------------------------|
| Phone (or email auth) | Required for account |
| Name, age, profile steps | Required to complete onboarding |
| Assessments | Required to enter main app loop |
| Photos | Optional (upload path exists) |
| Location | Optional |
| Chat | Optional |
| Reports/blocks | Optional |

### Purposes (map)

| Purpose | Applies? |
|---------|----------|
| App functionality | Yes |
| Account management | Yes |
| Personalization / matching | Yes (compatibility, Discover) |
| Safety / security / fraud prevention | Yes (reports, blocks, ops retention) |
| Analytics | **NEEDS CONFIRMATION** — no Analytics SDK in pubspec |
| Advertising / marketing | No (not found) |
| Developer communications | Possible via support email only |

### Open questions (Play) — NEEDS CONFIRMATION
1. ~~Independent privacy policy / terms HTTPS URLs~~ → `https://qmatch.site/privacy/` and `/terms/` verified live (3P-A24).
2. ~~Data deletion instructions URL~~ → `https://qmatch.site/account-deletion/` verified live.
3. Remaining founder/legal items below (analytics, diagnostics, Sign in with Apple/Google if shipped, etc.).
3. Whether Firebase Analytics/Crashlytics are on for the Android app ID.
4. Whether any Play families / ads declarations apply (draft: no ads).
5. Data retention period beyond “account lifetime + safety exceptions”.

---

## 5. Support / legal URL status (updated 3P-A24)

| Item | Current state | Store impact |
|------|---------------|--------------|
| `support@qmatch.site` | **Receive confirmed** → `sirinumit@gmail.com`; monitored via Gmail | Ready for support field |
| Privacy Policy URL | `https://qmatch.site/privacy/` **verified live** | Ready to paste |
| Terms of Use URL | `https://qmatch.site/terms/` **verified live** | Ready to paste |
| Support URL | `https://qmatch.site/support/` **verified live** | Ready to paste |
| Account deletion URL | `https://qmatch.site/account-deletion/` **verified live** | Ready to paste |
| Legal counsel sign-off | Still optional / recommended | HIGH before heavy marketing |
| Gmail send-as support@ | Optional | Not a launch blocker |

See: `docs/qmatch_site_live_verification.md`, `docs/qmatch_site_support_mailbox_verification.md`

---

## 6. Pre-submit checklist

- [x] Confirm `support@qmatch.site` mailbox receives and is monitored (3P-A24)
- [x] Public legal/support URLs verified live (store-facing copy)
- [x] Confirm store URLs: privacy / terms / support / account-deletion
- [ ] Paste **Privacy Policy** HTTPS URL into store consoles
- [ ] Paste **Terms of Use** HTTPS URL where required
- [ ] Confirm account deletion instructions match store answers (in-app + web + email)
- [ ] Confirm final **SDK list** for the binary under review (esp. Apple/Google Sign-In) — still NEEDS CONFIRMATION
- [ ] Confirm analytics / crash reporting status (Console + binary) — still NEEDS CONFIRMATION
- [ ] Confirm data retention / safety-report retention policy in writing
- [ ] Confirm legal review of Privacy/Terms + this questionnaire pack (optional / recommended)
- [ ] Confirm ops owner for 30-day deletion fulfillment (manual ops)
- [ ] Confirm location precision declaration (coarse vs precise)
- [ ] Confirm no advertising / ATT tracking before shipping
- [ ] Align Play Data Safety + Apple App Privacy answers with the same inventory

---

## 7. Related product docs

- `docs/launch_readiness_consolidated_audit.md`
- `docs/legal_help_privacy_launch_content_audit.md`
- `docs/account_deletion_manual_ops_runbook.md`
- `docs/account_deletion_pending_ux.md`

---

## Explicit non-actions (this phase)

Documentation only — no Firestore writes, no deploys, no commits, no code behavior changes.
