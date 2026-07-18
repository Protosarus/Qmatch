# Store Privacy Form Answer Sheet (Phase 3P-A26)

Date: 2026-07-18  
Project: Qmatch (`qmatch-53d62`)  
Mode: **Practical form fill-in sheet** — not legal advice; no app/Firebase/deploy changes in this phase

**Source of truth:** `docs/store_privacy_final_confirmation_matrix.md` (+ pack, launch audit, live site/mailbox docs, `pubspec.yaml`, `lib/`)

### Paste into store consoles (verified)

| Field | Value |
|-------|--------|
| Privacy Policy URL | `https://qmatch.site/privacy/` |
| Terms of Use URL | `https://qmatch.site/terms/` |
| Support URL | `https://qmatch.site/support/` |
| Account deletion URL | `https://qmatch.site/account-deletion/` |
| Support email | `support@qmatch.site` |

### Confidence

| Label | Meaning |
|-------|---------|
| Confirmed | Safe to enter as shown (engineering evidence) |
| Needs Founder Confirmation (NFC) | Decide before submit; conservative default noted |
| Not Present | Do not declare as collected |

---

## 1. App Store Connect — App Privacy

**Do you collect data?** → **Yes**

**Do you or your third-party partners use data for tracking?** → **No** (no ads/ATT SDKs in app; Confirmed).  
NFC: Google Fonts network fetch / Console Analytics — still treat as **not ATT tracking** unless counsel says otherwise.

**Privacy Policy URL:** `https://qmatch.site/privacy/`

### 1.1 Contact Info

| Data type | Collected? | Linked to user? | Used for tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|-----------------|--------------------|------------|------------|-------|
| Phone Number | **Yes** | Yes | No | App Functionality, Account Management | Confirmed | Primary auth (phone) |
| Email Address | **Yes** | Yes | No | App Functionality, Account Management | Confirmed | If email signup/login ships |
| Name | **Yes** | Yes | No | App Functionality | Confirmed | Profile display name |
| Physical Address | No | — | — | — | Not Present | |
| Other User Contact Info | No | — | — | — | Not Present | Support email is outbound contact, not collected contact book |

### 1.2 User Content

| Data type | Collected? | Linked? | Tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|---------|-----------|------------|------------|-------|
| Photos or Videos | **Yes** | Yes | No | App Functionality | Confirmed | Profile photos → Storage |
| Audio Data | No | — | — | — | Not Present | |
| Customer Support | **Possible** | Yes | No | App Functionality / Other | Confirmed | Via `support@qmatch.site` if user emails |
| Other User Content | **Yes** | Yes | No | App Functionality; Other (safety) | Confirmed | Bio, chat messages, reports, assessment text answers |

### 1.3 Identifiers

| Data type | Collected? | Linked? | Tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|---------|-----------|------------|------------|-------|
| User ID | **Yes** | Yes | No | App Functionality, Account Management | Confirmed | Firebase Auth UID |
| Device ID | **No** (draft) | — | — | — | NFC | No device_info/ads ID in app; confirm Console/binary |
| Advertising Data / ID | **No** | — | — | — | Not Present / NFC | No ads SDKs found |

### 1.4 Location

| Data type | Collected? | Linked? | Tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|---------|-----------|------------|------------|-------|
| Coarse Location | **Yes** (if user enables) | Yes | No | App Functionality | Confirmed | City/region `location_text` |
| Precise Location | **Yes — conservative** until founder decides | Yes | No | App Functionality | NFC | Code: `LocationAccuracy.high` + stores `GeoPoint`. Conservative form answer: **declare Precise** if shipping as-is; or lower accuracy / stop storing lat/lng then declare Coarse only |

### 1.5 Usage Data

| Data type | Collected? | Linked? | Tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|---------|-----------|------------|------------|-------|
| Product Interaction | **Yes** | Yes | No | App Functionality | Confirmed | Swipes, matches, assessment progress, chat activity |
| Advertising Data | No | — | — | — | Not Present | |
| Other Usage Data | **Possible** | Yes | No | App Functionality | NFC | Firebase infrastructure logs — confirm Console |

### 1.6 Diagnostics

| Data type | Collected? | Linked? | Tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|---------|-----------|------------|------------|-------|
| Crash Data | **No** via app Crashlytics package | — | — | — | Confirmed (deps) | NFC: Console-only Crashlytics? |
| Performance Data | **No** via app package | — | — | — | Confirmed (deps) | NFC: Console Performance? |
| Other Diagnostic Data | **Unknown** | — | — | — | NFC | Confirm Firebase Console |

**Recommended draft until Console check:** Do **not** declare Crash/Performance unless Console shows them enabled for this app.

### 1.7 Sensitive Info

| Data type | Collected? | Linked? | Tracking? | Purpose(s) | Confidence | Notes |
|-----------|------------|---------|-----------|------------|------------|-------|
| Sensitive Info | **NFC with counsel** | Likely Yes if declared | No | App Functionality | NFC | Gender, looking-for, religion, lifestyle, dating context. **Do not** label IQ/EQ/Frequency as Health. Counsel: whether Apple “Sensitive Info” applies |

### 1.8 Other Data

| Item | Collected? | Linked? | Tracking? | Purpose | Confidence | Notes |
|------|------------|---------|-----------|---------|------------|-------|
| Assessment answers / results / compatibility vectors | **Yes** | Yes | No | App Functionality | Confirmed | App-specific signals, not clinical tests |
| Lifestyle / preferences fields | **Yes** | Yes | No | App Functionality | Confirmed | May overlap Sensitive Info (NFC) |

### 1.9 Tracking / ATT

| Question | Recommended answer | Confidence | Notes |
|----------|-------------------|------------|-------|
| Used for tracking (cross-app/website advertising)? | **No** | Confirmed | No ATT/ads SDKs |
| Third-party advertising? | **No** | Confirmed | |
| Data used to track user? | **No** | Confirmed | |

### 1.10 Third-party sharing (Apple framing)

| Question | Recommended answer | Confidence | Notes |
|----------|-------------------|------------|-------|
| Sell data to data brokers? | **No** | Confirmed | |
| Share with third parties for their advertising? | **No** | Confirmed | |
| Use processors (Firebase/Google, Cloudflare site/email)? | **Yes — to operate the app** | NFC wording | Not “sold”; list processors per legal preference |

---

## 2. Google Play — Data Safety

**Privacy policy:** `https://qmatch.site/privacy/`  
**Account deletion:** In-app + `https://qmatch.site/account-deletion/` + `support@qmatch.site`  
**Data collected?** → **Yes**  
**Data shared with third parties?** → **Yes — service providers / processors** (Firebase/Google to run backend). **Not sold.** Exact checklist wording → NFC.  
**Data encrypted in transit?** → **Yes** (Confirmed)  
**Users can request deletion?** → **Yes** (Confirmed; fulfillment manual within ~30 days)

### 2.1 Personal info

| Data type | Collected? | Shared? | Required / optional | Purpose | Ephemeral? | Deletion request? | Confidence | Notes |
|-----------|------------|---------|---------------------|---------|------------|-------------------|------------|-------|
| Name | Yes | Yes (Firebase; visible to other users) | Required for profile | App functionality | No | Yes | Confirmed | |
| Email | Yes | Yes (Firebase Auth) | Optional vs phone | Account mgmt | No | Yes | Confirmed | |
| Phone | Yes | Yes (Firebase Auth) | Required for phone path | Account mgmt | No | Yes | Confirmed | |
| User IDs | Yes | Yes (Firebase) | Required | Account mgmt | No | Yes | Confirmed | Auth UID |
| Address | No | — | — | — | — | — | Not Present | |
| Race / ethnicity | No | — | — | — | — | — | Not Present | |
| Political / religious beliefs | **Possible** (`religion` field) | Yes (Firebase; may show on profile) | Optional field | App functionality | No | Yes | NFC | Sensitive classification |
| Sexual orientation | **Not explicit field found** | — | — | — | — | — | NFC | Gender + looking-for may imply dating prefs — counsel |
| Other personal info | Yes (age, gender, bio, interests, lifestyle, looking-for) | Yes | Mostly required to complete setup | App functionality / personalization | No | Yes | Confirmed | |

### 2.2 Photos and videos

| Data type | Collected? | Shared? | Required / optional | Purpose | Ephemeral? | Deletion? | Confidence | Notes |
|-----------|------------|---------|---------------------|---------|------------|-----------|------------|-------|
| Photos | Yes | Yes (Firebase Storage; other users) | Optional upload (encouraged) | App functionality | No | Yes | Confirmed | Gallery path confirmed; camera NFC |

### 2.3 Messages

| Data type | Collected? | Shared? | Required / optional | Purpose | Ephemeral? | Deletion? | Confidence | Notes |
|-----------|------------|---------|---------------------|---------|------------|-----------|------------|-------|
| Emails / SMS / MMS in-app | No | — | — | — | — | — | Not Present | Auth SMS is carrier/Firebase, not in-app SMS content store |
| Other in-app messages | Yes | Yes (match participant + Firebase) | Optional feature | App functionality | No | Yes | Confirmed | Chat threads |

### 2.4 App activity

| Data type | Collected? | Shared? | Required / optional | Purpose | Ephemeral? | Deletion? | Confidence | Notes |
|-----------|------------|---------|---------------------|---------|------------|-----------|------------|-------|
| App interactions | Yes | Yes (Firebase) | Required to use Discover/assessments | App functionality | No | Yes | Confirmed | Swipes, assessments, matches |
| In-app search history | No | — | — | — | — | — | Not Present | |
| Installed apps | No | — | — | — | — | — | Not Present | |
| Other user-generated content | Yes | Yes | Various | App functionality / safety | No | Yes (reports may retain) | Confirmed / NFC retention | Reports, blocks |

### 2.5 App info and performance

| Data type | Collected? | Shared? | Purpose | Ephemeral? | Deletion? | Confidence | Notes |
|-----------|------------|---------|---------|------------|-----------|------------|-------|
| Crash logs | No (no Crashlytics package) | — | — | — | — | Confirmed deps / NFC Console | Confirm Console |
| Diagnostics | Unknown | — | — | — | — | NFC | |
| Other app performance | No (no Performance package) | — | — | — | — | Confirmed deps / NFC Console | |

**Draft:** Answer **No** for crash/diagnostics unless Firebase Console proves otherwise.

### 2.6 Device or other IDs

| Data type | Collected? | Shared? | Purpose | Ephemeral? | Deletion? | Confidence | Notes |
|-----------|------------|---------|---------|------------|-----------|------------|-------|
| Device or other IDs | **UID yes; advertising/device ID no in app** | UID via Firebase | Account / functionality | No | Yes | Confirmed UID / NFC device | Do not declare Ads ID |

### 2.7 Location

| Data type | Collected? | Shared? | Required / optional | Purpose | Ephemeral? | Deletion? | Confidence | Notes |
|-----------|------------|---------|---------------------|---------|------------|-----------|------------|-------|
| Approximate location | Yes | Yes (Firebase; may show approx to others) | Optional | App functionality | No | Yes | Confirmed | `location_text` |
| Precise location | **Conservative Yes** | Yes (GeoPoint in Firestore) | Optional | App functionality | No | Yes | NFC | High accuracy GPS + GeoPoint — declare Precise until code/product change |

### 2.8 Financial info

| Collected? | Answer | Confidence |
|------------|--------|------------|
| Any financial / payment / credit | **No** | Not Present |

### 2.9 Contacts

| Collected? | Answer | Confidence |
|------------|--------|------------|
| Address book / contacts | **No** | Not Present |

### 2.10 Health and fitness

| Collected? | Answer | Confidence | Notes |
|------------|--------|------------|-------|
| Health / fitness / clinical | **No** | Confirmed guidance | IQ/EQ/Frequency are **app compatibility signals**, not medical/health data. Do **not** declare Health |

### 2.11 Sensitive info / relationship preference risk

| Topic | Recommended stance | Confidence | Notes |
|-------|-------------------|------------|-------|
| Sexual orientation | No dedicated field found | NFC | Counsel on gender/looking-for |
| Relationship preferences | Collected (`lookingFor`, preferences) | Confirmed collect | May be sensitive under Play/local law — NFC labeling |
| Religion | Optional lifestyle field | NFC | |

### 2.12 Account deletion (Play)

| Question | Recommended answer | Confidence | Notes |
|----------|-------------------|------------|-------|
| Can users request deletion? | **Yes** | Confirmed | Settings → Delete account; web instructions; email support |
| How | In-app request + `https://qmatch.site/account-deletion/` + `support@qmatch.site` | Confirmed | |
| Timeline | Within **30 days** | Confirmed (product promise) | Fulfillment is **manual ops** (B1) |
| Automated wipe? | Not yet (`EXECUTE_IMPLEMENTED=false`) | Confirmed | Do not claim instant automated wipe |

### 2.13 Encryption in transit

| Question | Answer | Confidence | Notes |
|----------|--------|------------|-------|
| Data encrypted in transit? | **Yes** | Confirmed | HTTPS / Firebase TLS |
| Encryption at rest? | Firebase defaults typical | NFC | Confirm form wording if asked |

---

## 3. Founder Decision Checklist

Complete before submitting store forms:

| # | Decision | Options / conservative default | Status |
|---|----------|--------------------------------|--------|
| 1 | Precise vs approximate location | **Conservative:** declare Precise Location (code stores high-accuracy GeoPoint). Or change code to coarse-only then declare Approximate only | ☐ |
| 2 | Console Analytics / Crashlytics / Performance | If off → leave Diagnostics **No**. If on → declare and match Console | ☐ |
| 3 | Camera vs gallery permissions | Gallery confirmed; camera permission strings present — declare camera only if usable, else remove unused permission | ☐ |
| 4 | Sensitive info classification | Counsel: religion / dating prefs / gender / looking-for under Apple Sensitive / Play sensitive | ☐ |
| 5 | Retention after deletion | Align policy + ops: wipe profile/media/assessments; retain/anonymize safety reports as needed | ☐ |
| 6 | Subprocessors wording | Google/Firebase (+ Cloudflare for site/email). Not sold | ☐ |
| 7 | Encryption at rest wording | Confirm if Play/Apple asks beyond “in transit” | ☐ |
| 8 | Deletion ops staffing | Named owner + weekly pending review (B1) within 30-day SLA | ☐ |
| 9 | Gmail send-as `support@qmatch.site` | Optional — **not** a launch blocker | ☐ |
| 10 | Apple/Google stub buttons | Hide stubs or implement before marketing Continue with Google/Apple | ☐ |

---

## 4. Quick “do not declare” list

- Advertising / ATT tracking  
- Payments / financial info  
- Contacts / address book  
- Health & fitness (clinical)  
- FCM / working push notifications  
- Working Google Sign-In / Sign in with Apple account collection  
- Analytics/Crashlytics **packages** (unless Console proves otherwise)  
- Device advertising ID (unless Console/binary proves otherwise)  

---

## 5. Remaining launch blockers (context)

| Item | Status |
|------|--------|
| Manual deletion fulfillment ops (B1) | Open |
| Founder NFC decisions above (B3) | Open — use this sheet |
| Hosted legal URLs + support mailbox | Cleared (3P-A24) |
| Optional counsel / Gmail send-as | Optional |

---

## Explicit non-actions (this phase)

No app behavior changes · no Firebase writes · no deploy · no DNS · no commit/push

Related: `docs/store_privacy_final_confirmation_matrix.md`, `docs/store_privacy_questionnaire_pack.md`
