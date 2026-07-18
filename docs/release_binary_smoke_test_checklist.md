# Release Binary Smoke Test Checklist (Phase 3P-A30)

Date: 2026-07-18
Project: Qmatch (`qmatch-53d62`)
App version in repo: `0.1.0` (`pubspec.yaml`) — confirm build number on the binary under test
Mode: **Manual QA checklist only** — no app/Firebase/deploy changes in this phase

Related: `docs/store_submission_final_operations_checklist.md`, `docs/store_privacy_form_answer_sheet.md`, `docs/firebase_console_store_submission_verification.md`, `docs/account_deletion_manual_ops_runbook.md`

### How to use

1. Install the **release** (or TestFlight / Play internal) binary — not a random debug build unless noted.
2. Fill **Actual result** / **Pass/Fail** / **Notes** per row.
3. Apply go/no-go (§4).
4. Complete store preflight (§5) before submit.

### Severity

| Level | Meaning |
|-------|---------|
| **P0** | Blocks store submission |
| **P1** | Founder decision required before submit |
| **P2** | Track after submit / polish |

### Go / no-go rule

- Any **P0 Fail** → **No-go** (do not submit).
- Any **P1 Fail** → founder written decision (fix / defer / accept risk).
- **P2 Fail** → may ship; track in backlog.
- All P0 Pass (+ P1 resolved) → **Go** for smoke dimension.

### Tester setup

| Item | Value / fill |
|------|----------------|
| Binary build ID / version | _______________ |
| Platform | ☐ iOS ☐ Android |
| Firebase test phone number | _______________ (Console test number) |
| Second account (match/chat) | _______________ (optional) |
| Tester | _______________ |
| Date | _______________ |

---

## 1. Smoke test matrix

| Test ID | Area | Steps | Expected result | Actual result | Pass/Fail | Notes | Severity |
|---------|------|-------|-----------------|---------------|-----------|-------|----------|
| ST-01 | Clean install | Uninstall if present → install release binary → launch cold | App opens to Welcome (or auth gate); no crash; splash completes | | ☐ Pass ☐ Fail | | P0 |
| ST-02 | Phone auth (test number) | Welcome → phone signup → enter Firebase **test number** → enter test OTP | Signs in; no SMS required if Console test pair configured; lands in onboarding or main flow | | ☐ Pass ☐ Fail | Use only Console-configured test numbers | P0 |
| ST-03 | Onboarding / profile create | Complete profile steps: name/age/gender, bio, interests, lifestyle, preferences; age ≥18 | Profile saves; `profileCompleted` path unlocks; no permission-denied on user write | | ☐ Pass ☐ Fail | | P0 |
| ST-04 | Profile edit | Open Profile → edit fields (e.g. bio) → save | Changes persist after leave/re-enter screen | | ☐ Pass ☐ Fail | | P1 |
| ST-05 | Photo / gallery | Profile photo edit → pick from gallery → upload | Photo appears; Storage upload succeeds; gallery permission prompt (if first time) is understandable | | ☐ Pass ☐ Fail | Expect **gallery**, not camera. Camera permission may still exist unused | P0 |
| ST-06 | Location permission | Basic info → share location (allow when prompted) | Permission prompt appears; location text and/or location save works **or** clear deny message; no hard crash | | ☐ Pass ☐ Fail | Note: iOS may lack `NSLocation*` strings in repo — if location fails silently, mark Fail + note | P1 |
| ST-07 | Location deny path | Deny location (or skip) | Profile can still complete without location; Discover still usable | | ☐ Pass ☐ Fail | Location is optional | P1 |
| ST-08 | Assessment load (Firestore) | Start IQ/EQ/Frequency intro → load questions | Questions load from Firestore RC1 sets (`*_v2`); not stuck on empty; fallback only if Firestore fails and is expected | | ☐ Pass ☐ Fail | Prefer confirming source via prior QA docs / logs if available | P0 |
| ST-09 | IQ assessment complete | Answer through IQ test → finish | Completes; result/progress saved; can proceed | | ☐ Pass ☐ Fail | | P0 |
| ST-10 | EQ assessment complete | Answer through EQ test → finish | Completes; result saved | | ☐ Pass ☐ Fail | | P0 |
| ST-11 | Frequency assessment complete | Answer Frequency → see result | Completes; archetype/frequency result shown; vector/signals available for matching | | ☐ Pass ☐ Fail | | P0 |
| ST-12 | Discover / compatibility | Open Discover after assessments + profile | Cards/suggestions show; compatibility signals visible or ranking works; no endless spinner | | ☐ Pass ☐ Fail | Cold-start guard should not blank all users unfairly | P0 |
| ST-13 | Like / Pass | On Discover: Pass one profile; Like another | Actions succeed; no crash; liked/passed state consistent | | ☐ Pass ☐ Fail | | P0 |
| ST-14 | Match (if mutual) | With second test account, mutual Like | Match created; entry to chat/messages available | | ☐ Pass ☐ Fail | Skip if no second account — mark Notes “N/A — no second acct” and treat as P1 gap | P1 |
| ST-15 | Messages / chat | Open Messages → open thread → send a message | Message sends and displays; restart shows history | | ☐ Pass ☐ Fail | Requires match (ST-14) | P1 |
| ST-16 | Report | In chat (or available entry): report user with reason | Report submits without crash; confirmation UX | | ☐ Pass ☐ Fail | | P1 |
| ST-17 | Block | Block user from chat/settings path | Block succeeds; user removed from Discover/chat as designed; appears in Blocked users | | ☐ Pass ☐ Fail | | P1 |
| ST-18 | Settings | Open Settings; visit Privacy, Notifications, Help, About, Blocked | Screens open; toggles respond (notifications may be local-only MVP) | | ☐ Pass ☐ Fail | | P1 |
| ST-19 | Legal / support links (in-app) | Settings → Privacy Policy / Terms / Help/Support / Account deletion help | Copy shows; contact mentions `support@qmatch.site`; no crash | | ☐ Pass ☐ Fail | Hosted URLs may be in-app text or external — either OK if accurate | P0 |
| ST-20 | Hosted legal URLs (device browser) | Open on device: privacy / terms / support / account-deletion | HTTPS pages load; store-facing copy (no NEEDS CONFIRMATION / launch draft) | | ☐ Pass ☐ Fail | `https://qmatch.site/privacy/` etc. | P0 |
| ST-21 | Delete account request | Settings → Delete account → read notices → check both boxes → type DELETE → submit | Request succeeds; soft pending state; no wipe of Auth yet | | ☐ Pass ☐ Fail | Use disposable test account | P0 |
| ST-22 | Pending deletion UI | After ST-21: Settings + Delete screen + Discover | Pending banner/status; cannot re-submit duplicate; Discover still usable with banner (current product) | | ☐ Pass ☐ Fail | | P0 |
| ST-23 | Localization EN | Device/app language English → spot-check Welcome, Settings, Delete, Discover | Strings readable EN; no missing-key overflow | | ☐ Pass ☐ Fail | | P1 |
| ST-24 | Localization TR | Switch to Turkish → same screens | TR strings present; layout OK | | ☐ Pass ☐ Fail | | P1 |
| ST-25 | Poor network | Enable airplane mode briefly mid-Discover / mid-assessment save | Graceful error or retry; no hard crash / corrupt state | | ☐ Pass ☐ Fail | | P2 |
| ST-26 | Offline → online | Airplane on → launch → restore network → retry | Recovers; can continue auth or data load | | ☐ Pass ☐ Fail | | P2 |
| ST-27 | App restart persistence | Kill app → relaunch | Stays signed in; profile/assessment progress retained | | ☐ Pass ☐ Fail | | P0 |
| ST-28 | Logout → login | Settings logout → phone login again with test number | Returns to expected gate; data intact | | ☐ Pass ☐ Fail | | P0 |
| ST-29 | No Analytics/Crashlytics/FCM expectation | Use app 5–10 min; check Console optionally | No requirement for Crashlytics/Analytics events; no push campaigns expected | | ☐ Pass ☐ Fail | Matches 3P-A29: SDKs not configured | P2 |
| ST-30 | Google / Apple Sign-In | If SocialLoginScreen reachable: tap Continue with Google / Apple | **Expect stubs do nothing** (or buttons hidden). Phone path remains primary | | ☐ Pass ☐ Fail | Do not expect working Google/Apple collection | P2 |
| ST-31 | Support email | From device mail app, send to `support@qmatch.site` | Arrives at `sirinumit@gmail.com` (Ümit) | | ☐ Pass ☐ Fail | Confirmed infra; re-spot-check before submit | P1 |
| ST-32 | Deletion ops handoff | After ST-21: notify **Ümit**; run weekly discovery when creds available | Owner knows UID/request exists; runbook path clear; **do not** auto-wipe in this smoke | | ☐ Pass ☐ Fail | Docs: `account_deletion_manual_ops_runbook.md` | P1 |

---

## 2. Summary scorecard (fill after run)

| Severity | Pass count | Fail count | Open |
|----------|------------|------------|------|
| P0 | __ / __ | __ | |
| P1 | __ / __ | __ | |
| P2 | __ / __ | __ | |

**Smoke verdict:** ☐ Go ☐ No-go ☐ Go with founder-accepted P1 risks

**Sign-off:** Tester _______________ Founder _______________ Date _______________

---

## 3. Store submission preflight

Complete alongside or after smoke Go.

| # | Item | Status |
|---|------|--------|
| PF-01 | `flutter analyze` clean (no issues) | ☐ |
| PF-02 | Release build created (iOS archive / Android appbundle or APK) | ☐ |
| PF-03 | App version + build number confirmed on binary & store forms (`pubspec` currently `0.1.0` + build) | ☐ |
| PF-04 | Privacy Policy URL pasted: `https://qmatch.site/privacy/` | ☐ |
| PF-05 | Terms URL pasted (if required): `https://qmatch.site/terms/` | ☐ |
| PF-06 | Support URL pasted: `https://qmatch.site/support/` | ☐ |
| PF-07 | Account deletion URL pasted: `https://qmatch.site/account-deletion/` | ☐ |
| PF-08 | Support email pasted: `support@qmatch.site` | ☐ |
| PF-09 | App Privacy / Data Safety filled from `docs/store_privacy_form_answer_sheet.md` | ☐ |
| PF-10 | Screenshots prepared (required device sizes) | ☐ |
| PF-11 | App description / subtitle / keywords prepared (EN; TR if needed) | ☐ |
| PF-12 | Age rating / 18+ metadata aligned | ☐ |
| PF-13 | Tester account / Firebase test phone instructions documented for review if asked | ☐ |
| PF-14 | Deletion ops owner confirmed: **Ümit** (weekly; ≤30 days manual) | ☐ |
| PF-15 | Support inbox owner confirmed: **Ümit** | ☐ |
| PF-16 | Smoke Go (P0 clean) recorded in §2 | ☐ |

### Paste reference

| Field | Value |
|-------|--------|
| Privacy | `https://qmatch.site/privacy/` |
| Terms | `https://qmatch.site/terms/` |
| Support | `https://qmatch.site/support/` |
| Account deletion | `https://qmatch.site/account-deletion/` |
| Support email | `support@qmatch.site` |

---

## 4. Known non-failures (do not mark as product bugs)

| Observation | Why OK for launch |
|-------------|-------------------|
| Google/Apple buttons do nothing | Stubs; phone is primary auth |
| Notification toggles don’t send push | No FCM configured (3P-A29) |
| No Crashlytics/Analytics events | SDKs not in app / not configured |
| Discover usable while deletion pending | Current product (banner only) |
| Deletion does not instantly wipe Auth | Request + manual ops ≤30 days |
| Camera permission present but gallery used | Tracked optional cleanup |

---

## 5. Ops handoff after smoke (Ümit)

1. If ST-21 created a real pending request on a disposable uid, schedule weekly discovery.
2. Do **not** run destructive execute without a separate approved phase.
3. Monitor `support@qmatch.site` → `sirinumit@gmail.com`.
4. Use EN/TR reply templates in `docs/account_deletion_manual_ops_runbook.md`.

---

## Explicit non-actions (this phase)

No app code changes · no Firebase writes · no deploy · no DNS/email · no SDK adds · no commit/push

---

## Related docs

- `docs/store_submission_final_operations_checklist.md`
- `docs/firebase_console_store_submission_verification.md`
- `docs/store_privacy_form_answer_sheet.md`
- `docs/qmatch_site_live_verification.md`
- `docs/qmatch_site_support_mailbox_verification.md`
- `docs/account_deletion_manual_ops_runbook.md`
- `docs/launch_readiness_consolidated_audit.md`
