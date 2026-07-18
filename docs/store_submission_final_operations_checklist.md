# Store Submission Final Operations Checklist (Phase 3P-A28)

Date: 2026-07-18
Project: Qmatch (`qmatch-53d62`)
Mode: **Operations checklist only** — no app/Firebase/deploy/DNS changes in this phase

Related:

- `docs/store_privacy_form_answer_sheet.md`
- `docs/store_privacy_nfc_resolution_checklist.md`
- `docs/store_privacy_questionnaire_pack.md`
- `docs/launch_readiness_consolidated_audit.md`
- `docs/account_deletion_manual_ops_runbook.md`
- `docs/qmatch_site_live_verification.md`
- `docs/qmatch_site_support_mailbox_verification.md`

---

## 1. URLs and contacts to paste

### App Store Connect

| Field | Paste this |
|-------|------------|
| Privacy Policy URL | `https://qmatch.site/privacy/` |
| Terms of Use (if asked) | `https://qmatch.site/terms/` |
| Support URL | `https://qmatch.site/support/` |
| Marketing / support email | `support@qmatch.site` |
| Account deletion help (if asked) | `https://qmatch.site/account-deletion/` |

### Google Play Console

| Field | Paste this |
|-------|------------|
| Privacy Policy URL | `https://qmatch.site/privacy/` |
| Terms (if asked) | `https://qmatch.site/terms/` |
| Support / contact email | `support@qmatch.site` |
| Data deletion / account deletion URL | `https://qmatch.site/account-deletion/` |
| Support / help URL (if asked) | `https://qmatch.site/support/` |

### Support mailbox (verified)

| Item | Status |
|------|--------|
| Address | `support@qmatch.site` |
| Routing | Cloudflare Email Routing → `sirinumit@gmail.com` |
| Receive test | **Passed** |
| Monitoring | Via destination Gmail |
| Gmail “Send mail as” | Optional — **not** a submit blocker |

---

## 2. Privacy answers locked (use answer sheet)

Fill App Privacy / Data Safety from `docs/store_privacy_form_answer_sheet.md`, with 3P-A27 locks:

| Topic | Locked answer |
|-------|----------------|
| Collect data? | **Yes** |
| Tracking / ATT / ads | **No** |
| Phone / email / name | **Yes**, linked, not tracking |
| Photos | **Yes** (gallery/media picker) |
| Chat / reports / bio | **Yes**, linked |
| Assessments / compatibility | **Yes**, linked (not Health) |
| Coarse location | **Yes** (if user enables) |
| Precise location | **Yes** (if user enables) — current binary |
| User ID (Firebase UID) | **Yes**, linked |
| Device / advertising ID | **No** in app |
| Analytics/Crashlytics packages | **Not Present** in app |
| FCM / push | **Not implemented** |
| Google / Apple Sign-In collection | **Not wired** |
| Encryption in transit | **Yes** |
| Account deletion request | **Yes** (in-app + web + email; ≤30 days; manual fulfillment) |
| Sell data | **No** |
| Processors | Firebase/Google (+ Cloudflare for site/email) — not sold |

Full tables: answer sheet + NFC checklist.

---

## 3. Still requiring manual confirmation

| # | Item | Who | Blocking submit? |
|---|------|-----|------------------|
| 1 | Firebase Console Analytics / Crashlytics / Performance | Founder / eng | **Yes** until checked |
| 2 | Sensitive Info / religion / dating-pref labeling | Founder / counsel | **Yes** if unsure — decide before forms |
| 3 | Subprocessors / encryption-at-rest form wording | Founder / counsel | Prefer before submit |
| 4 | Deletion ops owner + weekly cadence | Founder | **Yes** (launch blocker B1) |
| 5 | Unused camera permission cleanup | Eng (optional) | Prefer before review |
| 6 | Hide Google/Apple stub buttons | Eng (optional) | Prefer before review |
| 7 | Counsel review of Privacy/Terms | Optional | Recommended, not engineering-blocked |
| 8 | Gmail send-as | Optional | No |

---

## 4. Firebase Console checks (project `qmatch-53d62`)

Open Firebase Console → project **qmatch-53d62** and record:

| Check | How | Result (fill in) |
|-------|-----|------------------|
| **Analytics enabled?** | Analytics / Google Analytics for Firebase product | ☐ Yes / ☐ No |
| **Crashlytics enabled?** | Crashlytics product / linked apps | ☐ Yes / ☐ No |
| **Performance Monitoring?** | Performance product | ☐ Yes / ☐ No |
| **Cloud Messaging / FCM?** | Messaging; any FCM setup for iOS/Android apps | ☐ Yes / ☐ No |

### How to apply results

| Console finding | Store form action |
|-----------------|-------------------|
| Analytics **No** | Keep Diagnostics / Analytics = not collected via app |
| Analytics **Yes** | Declare analytics/diagnostics as collected; update answer sheet mentally before submit |
| Crashlytics **No** | Keep Crash Data = No |
| Crashlytics **Yes** | Declare Crash Data |
| FCM **No** / unused | Do **not** claim push notifications |
| FCM **Yes** but app has no `firebase_messaging` | Treat as unused; still do not claim in-app push unless wired |

**Default until Console check completes:** Diagnostics **No**, Push **No** (matches repo packages).

---

## 5. Deletion ops staffing

| Item | Status |
|------|--------|
| In-app deletion request | Live |
| Automated wipe | **Off** (`EXECUTE_IMPLEMENTED=false`) |
| Fulfillment method | **Manual** — `docs/account_deletion_manual_ops_runbook.md` |
| SLA | Within **30 days** |
| Ops owner | **Unassigned in docs** — fill section 7 |

### Weekly deletion request check procedure

1. Assign owner (section 7).
2. **Weekly** (or more often at launch):
   ```bash
   python3 tool/discover_account_deletion_requests_readonly.py --list-pending
   ```
   (Requires Admin credentials per runbook — **read-only** discovery.)
3. Also check `support@qmatch.site` / `sirinumit@gmail.com` for email deletion requests (label folder recommended).
4. For each pending request: verify identity → dry-run plan → manual fulfill per runbook → reply with templates.
5. Escalate if any request approaches **~25 days** without fulfillment.
6. Do **not** enable automated execute without a separate approved phase.

---

## 6. Legal / counsel (optional)

| Item | Recommendation |
|------|----------------|
| Privacy / Terms on `qmatch.site` | Live store-facing copy; counsel review **optional / recommended** |
| Sensitive Info category | Counsel before declaring Apple Sensitive / Play sensitive |
| Subprocessors list | Counsel finalize Google/Firebase + Cloudflare |

---

## 7. Founder fill-in

| Field | Fill in |
|-------|---------|
| Deletion ops owner | ________________________ |
| Support inbox owner | ________________________ (default monitor: `sirinumit@gmail.com`) |
| Analytics enabled? | ☐ Yes ☐ No — date: ______ |
| Crashlytics enabled? | ☐ Yes ☐ No — date: ______ |
| Messaging/FCM enabled? | ☐ Yes ☐ No — date: ______ |
| Sensitive info decision | ________________________ |
| Retention policy decision | ________________________ (default: wipe profile/media/assessments; retain reports per runbook) |
| Store submission owner | ________________________ |
| Target submission date | ________________________ |
| App Store privacy form filled? | ☐ |
| Play Data Safety form filled? | ☐ |
| URLs pasted into both consoles? | ☐ |

---

## 8. Final pre-submit checklist

### Cleared (ops/docs)

- [x] `qmatch.site` live on Cloudflare Pages
- [x] Legal/support URLs verified (incognito)
- [x] Store-facing copy (no launch-draft / NEEDS CONFIRMATION on public pages)
- [x] `support@qmatch.site` receive confirmed
- [x] Privacy answer sheet + NFC resolution docs ready
- [x] Account deletion **request** path live

### Must complete before submit

- [ ] Firebase Console Analytics / Crashlytics / FCM recorded (section 4)
- [ ] Deletion ops owner named + weekly discovery scheduled
- [ ] Sensitive info / subprocessor decisions recorded (or counsel deferred with explicit founder choice)
- [ ] App Store Connect App Privacy filled from answer sheet
- [ ] Play Console Data Safety filled from answer sheet
- [ ] Privacy / Terms / Support / Account-deletion URLs pasted
- [ ] Support email `support@qmatch.site` on store listings
- [ ] Age rating / 18+ metadata aligned
- [ ] Release binary smoke-tested (auth, assessments, Discover, chat, deletion request)

### Prefer before review (non-blocking if accepted risk)

- [ ] Remove unused camera permission/strings **or** implement camera
- [ ] Hide Google/Apple stub buttons on SocialLoginScreen
- [ ] Optional counsel pass on Privacy/Terms
- [ ] Optional Gmail send-as

---

## 9. Go / no-go recommendation

| Dimension | Verdict |
|-----------|---------|
| Product loop | **Go** (conditional on release QA) |
| Legal URLs + support mailbox | **Go** |
| Privacy form content (repo-locked) | **Go** after Console check |
| Deletion fulfillment | **No-go until ops owner assigned** |
| Counsel | **Optional** |
| **Overall store submit** | **Conditional go** — proceed only when section 7 has deletion ops owner + Console Analytics/Crashlytics answers + privacy forms filled |

**Do not submit** if deletion fulfillment is unstaffed (users are promised 30-day processing).

---

## Explicit non-actions (this phase)

- No app behavior / legal HTML changes
- No Firebase writes / Admin SDK / rules / Functions
- No hosting deploy / DNS / email changes
- No commit / push

---

## Quick reference — document map

| Need | Doc |
|------|-----|
| Fill store privacy forms | `docs/store_privacy_form_answer_sheet.md` |
| What was locked from code | `docs/store_privacy_nfc_resolution_checklist.md` |
| Deletion how-to | `docs/account_deletion_manual_ops_runbook.md` |
| Mailbox proof | `docs/qmatch_site_support_mailbox_verification.md` |
| URL proof | `docs/qmatch_site_live_verification.md` |
