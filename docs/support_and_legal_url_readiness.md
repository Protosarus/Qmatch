# Support Mailbox & Hosted Legal URL Readiness

Date: 2026-07-18
Origin: Phase 3P-A20 · **Updated 3P-A24** after manual live URL + mailbox verification
Mode: Documentation only — no hosting deploy / DNS / Firebase by agent in 3P-A24

Related: `docs/qmatch_site_live_verification.md`, `docs/qmatch_site_support_mailbox_verification.md`, `docs/store_privacy_questionnaire_pack.md`, `lib/core/constants/app_support.dart`

---

## 1. Current support email in the app

| Item | Value |
|------|--------|
| Constant | `AppSupport.email` = **`support@qmatch.site`** |
| Mailto | `mailto:support@qmatch.site` |
| Used in | Help, About/legal flows, deletion UX, Privacy/Terms contact lines, FAQ |

### Mailbox status (3P-A24)

**Confirmed receiving.** Cloudflare Email Routing delivers `support@qmatch.site` → **`sirinumit@gmail.com`**. Test email received successfully. Monitored via that Gmail inbox unless otherwise stated.

**Optional / not a launch blocker:** configure Gmail “Send mail as `support@qmatch.site`” for branded outbound replies.

See: `docs/qmatch_site_support_mailbox_verification.md`

---

## 2. Mailbox setup checklist

- [x] Routing for `support@qmatch.site` (Cloudflare Email Routing)
- [x] Inbox **can receive** mail (test passed → `sirinumit@gmail.com`)
- [x] Monitored via destination Gmail
- [ ] Optional: Gmail “Send mail as support@qmatch.site”
- [ ] Deletion requests labeled/tracked (folder/tag) + ops runbook cadence
- [ ] Auto-reply optional
- [ ] Spam/junk reviewed so deletion/support mail is not missed

See also: `docs/account_deletion_manual_ops_runbook.md`

---

## 3. Required hosted URLs (for stores / public)

| Page | Why needed |
|------|------------|
| Privacy Policy | App Store Connect / Play Console privacy fields |
| Terms of Use | Often required or expected |
| Support / Contact | Store support URL |
| Account deletion instructions | Play / Apple deletion clarity |

### Public URLs (manually verified live — 3P-A24)

| Purpose | Live URL | Status |
|---------|----------|--------|
| Hub | `https://qmatch.site/` | Verified |
| Privacy | `https://qmatch.site/privacy/` | Verified |
| Terms | `https://qmatch.site/terms/` | Verified |
| Support | `https://qmatch.site/support/` | Verified |
| Account deletion | `https://qmatch.site/account-deletion/` | Verified |
| TR variants | `https://qmatch.site/tr/…` | Verified |

**Host:** Cloudflare Pages. Public pages verified free of launch-draft / NEEDS CONFIRMATION / “future hosting” wording.
Bundle id `com.qmatch.app` unchanged.

See: `docs/qmatch_site_live_verification.md`

---

## 4. Web draft files (source history)

Under `docs/legal_web_drafts/` — markdown sources used to build the static site. Public HTML is the live source of truth on `qmatch.site`. Counsel review of Privacy/Terms remains **optional / recommended**.

---

## 5. Hosting target

| Option | Status |
|--------|--------|
| **Cloudflare Pages** | **Live** + store-facing copy verified |
| Firebase Hosting | Not configured in `firebase.json` |

**Next ops step for stores:** paste verified URLs into App Store Connect / Play Console; finish questionnaire pack items still marked NEEDS CONFIRMATION.

---

## 6. Open questions

1. ~~Hosted on Cloudflare?~~ → Yes, verified.
2. ~~`support@qmatch.site` receive/monitor?~~ → Yes, verified (3P-A24).
3. Should the app later open hosted URLs instead of in-app legal screens only?
4. Counsel review timeline for Privacy/Terms? (optional / recommended)
5. Gmail send-as for branded outbound? (optional)

---

## 7. Final pre-submit checklist

- [x] Domain `qmatch.site` live on Cloudflare Pages
- [x] `support@qmatch.site` receive + monitor confirmed
- [x] Public URLs verified (incognito); store-facing copy live
- [ ] Paste Privacy / Terms / Support / Account-deletion URLs into store forms
- [ ] Finish store privacy questionnaire founder/legal **NEEDS CONFIRMATION** items
- [ ] Deletion fulfillment ops staffed (manual runbook; automation still off)
- [ ] Optional: counsel review of Privacy/Terms
- [ ] Optional: Gmail send-as `support@qmatch.site`
- [ ] Optional: deep-link in-app About/Help to hosted URLs

---

## Explicit non-actions (doc phases)

- No hosting deploy / DNS / Cloudflare changes by agent in 3P-A24
- No Firestore writes / Admin SDK / rules / Functions
- No assessment/scoring changes
- No commit / push
