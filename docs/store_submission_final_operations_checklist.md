# Store Submission Final Operations Checklist

Date: 2026-07-18
Origin: Phase 3P-A28 · **Updated 3P-A29** (Console verification + ops staffing recorded)
Project: Qmatch (`qmatch-53d62`)
Mode: **Operations checklist** — no app/Firebase/deploy/DNS changes in doc phases

Related:

- `docs/firebase_console_store_submission_verification.md` (**3P-A29**)
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
| Support inbox owner | **Ümit** |
| Gmail “Send mail as” | Optional — **not** a submit blocker |

---

## 2. Privacy answers locked (use answer sheet)

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
| Analytics | **No** app-side SDK; Console has no event data (3P-A29) |
| Crashlytics / Performance | **No** (Console Add SDK + no packages) |
| FCM / push | **No** (no package; Messaging not configured for launch) |
| Google / Apple Sign-In collection | **Not wired** |
| Encryption in transit | **Yes** |
| Account deletion request | **Yes** (in-app + web + email; manual ≤30 days; owner Ümit) |
| Sell data | **No** |
| Processors | Firebase/Google (+ Cloudflare for site/email) — not sold |

Full tables: `docs/store_privacy_form_answer_sheet.md`

---

## 3. Remaining items (optional / founder judgment)

| # | Item | Who | Blocking submit? |
|---|------|-----|------------------|
| 1 | Sensitive Info / religion / dating-pref labeling | Founder / counsel | Prefer decide before forms; not an SDK blocker |
| 2 | Subprocessors / encryption-at-rest form wording | Founder / counsel | Prefer before submit |
| 3 | Unused camera permission cleanup | Eng (optional) | No — accepted risk |
| 4 | Hide Google/Apple stub buttons | Eng (optional) | No — accepted risk |
| 5 | Counsel review of Privacy/Terms | Optional | Recommended |
| 6 | Gmail send-as | Optional | No |
| 7 | Optional font bundling | Eng (optional) | No |

~~Firebase Console Analytics/Crashlytics/FCM~~ — **verified 3P-A29**
~~Deletion ops owner~~ — **Ümit (staffed, manual)**

---

## 4. Firebase Console checks (project `qmatch-53d62`) — verified 3P-A29

| Check | Result | Evidence |
|-------|--------|----------|
| **Analytics collecting app events?** | **No** | Dashboard exists but **no user/event data**; Events = 0 / no data; no `firebase_analytics` package |
| **Crashlytics configured?** | **No** | Console shows **Add SDK**; no `firebase_crashlytics` package |
| **Performance Monitoring configured?** | **No** | Console shows **Add SDK**; no `firebase_performance` package |
| **Messaging / FCM configured for launch?** | **No** | Console shows **Create your first campaign**; no `firebase_messaging` package |

Details: `docs/firebase_console_store_submission_verification.md`

**Store form action:** Diagnostics / Analytics / Crash / Performance / Push = **No**.

---

## 5. Deletion ops staffing — staffed (manual)

| Item | Status |
|------|--------|
| In-app deletion request | Live |
| Automated wipe | **Off** (`EXECUTE_IMPLEMENTED=false`) |
| Fulfillment method | **Manual** — `docs/account_deletion_manual_ops_runbook.md` |
| SLA | Within **30 days** |
| Deletion ops owner | **Ümit** |
| Check frequency | **Weekly** |
| Support inbox owner | **Ümit** (`support@qmatch.site` → `sirinumit@gmail.com`) |

### Weekly deletion request check procedure

1. Owner: **Ümit**.
2. **Weekly**:
   ```bash
   python3 tool/discover_account_deletion_requests_readonly.py --list-pending
   ```
   (Admin credentials per runbook — **read-only** discovery.)
3. Check `support@qmatch.site` / `sirinumit@gmail.com` for email deletion requests.
4. For each pending request: verify → dry-run plan → manual fulfill per runbook → reply.
5. Escalate if approaching **~25 days**.
6. Do **not** enable automated execute without a separate approved phase.

---

## 6. Legal / counsel (optional)

| Item | Recommendation |
|------|----------------|
| Privacy / Terms on `qmatch.site` | Live; counsel review **optional / recommended** |
| Sensitive Info category | Counsel before declaring Apple Sensitive / Play sensitive |
| Subprocessors list | Counsel finalize Google/Firebase + Cloudflare |

---

## 7. Founder fill-in (3P-A29)

| Field | Value |
|-------|--------|
| Deletion ops owner | **Ümit** |
| Support inbox owner | **Ümit** |
| Support inbox | `support@qmatch.site` → `sirinumit@gmail.com` |
| Deletion check frequency | **Weekly** |
| Deletion SLA | Manual fulfillment within **30 days** |
| Analytics collecting events? | **No** (3P-A29) |
| Crashlytics configured? | **No** (3P-A29) |
| Messaging/FCM configured? | **No** (3P-A29) |
| Performance configured? | **No** (3P-A29) |
| Sensitive info decision | ________________________ (optional counsel) |
| Retention policy decision | Default: wipe profile/media/assessments; retain reports per runbook — confirm if needed |
| Store submission owner | ________________________ |
| Target submission date | ________________________ |
| App Store privacy form filled? | ☐ |
| Play Data Safety form filled? | ☐ |
| URLs pasted into both consoles? | ☐ |

---

## 8. Final pre-submit checklist

### Cleared (ops/docs)

- [x] `qmatch.site` live + URLs verified
- [x] `support@qmatch.site` receive confirmed; owner **Ümit**
- [x] Privacy answer sheet + NFC resolution ready
- [x] Firebase Console Analytics/Crashlytics/Performance/Messaging verified (3P-A29)
- [x] Deletion ops owner **Ümit** + weekly cadence + 30-day manual SLA
- [x] Account deletion **request** path live

### Complete at submit time

- [ ] App Store Connect App Privacy filled from answer sheet
- [ ] Play Console Data Safety filled from answer sheet
- [ ] Privacy / Terms / Support / Account-deletion URLs pasted
- [ ] Support email `support@qmatch.site` on store listings
- [ ] Age rating / 18+ metadata aligned
- [ ] Release binary smoke-tested (auth, assessments, Discover, chat, deletion request)
- [ ] Sensitive info / subprocessor wording decided (or founder accepts default from answer sheet)

### Optional before review

- [ ] Remove unused camera permission/strings **or** implement camera
- [ ] Hide Google/Apple stub buttons
- [ ] Counsel pass on Privacy/Terms
- [ ] Gmail send-as
- [ ] Offline-bundle Google Fonts

---

## 9. Go / no-go recommendation

| Dimension | Verdict |
|-----------|---------|
| Product loop | **Go** (conditional on release QA) |
| Legal URLs + support mailbox | **Go** |
| Privacy form content (repo + Console) | **Go** |
| Deletion fulfillment | **Go** — staffed (**Ümit**, weekly, manual ≤30 days). Automation still **off** |
| Counsel | **Optional** |
| **Overall store submit (ops/privacy)** | **Go** if founder accepts **manual deletion ops responsibility** and fills store privacy forms from the answer sheet |

Remaining items are **optional** or founder/legal judgment (counsel, stubs, camera permission, Gmail send-as, font bundling, sensitive-info labeling) — not engineering blockers for ops/privacy readiness.

---

## Explicit non-actions (doc phases)

- No app behavior / legal HTML changes
- No Firebase writes / Admin SDK / rules / Functions / SDK adds
- No hosting deploy / DNS / email changes
- No commit / push

---

## Quick reference — document map

| Need | Doc |
|------|-----|
| Console verification | `docs/firebase_console_store_submission_verification.md` |
| Fill store privacy forms | `docs/store_privacy_form_answer_sheet.md` |
| Repo NFC locks | `docs/store_privacy_nfc_resolution_checklist.md` |
| Deletion how-to | `docs/account_deletion_manual_ops_runbook.md` |
| Mailbox proof | `docs/qmatch_site_support_mailbox_verification.md` |
| URL proof | `docs/qmatch_site_live_verification.md` |
