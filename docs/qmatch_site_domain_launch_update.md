# qmatch.site Domain Launch Update (Phase 3P-A20B)

Date: 2026-07-18
Mode: Placeholder swap only — **no hosting deploy**, no Firebase writes, no commit

---

## Summary

Launch support/legal references moved from **`qmatch.app` placeholders** to the purchased domain **`qmatch.site`**.

| | Old | New |
|--|-----|-----|
| Support email | `support@qmatch.app` | `support@qmatch.site` |
| Privacy URL | `https://qmatch.app/privacy` | `https://qmatch.site/privacy` |
| Terms URL | `https://qmatch.app/terms` | `https://qmatch.site/terms` |
| Support URL | `https://qmatch.app/support` | `https://qmatch.site/support` |
| Account deletion URL | `https://qmatch.app/account-deletion` | `https://qmatch.site/account-deletion` |

Note: `qmatch.com` was unavailable; `qmatch.site` is the confirmed purchase.
iOS/Android bundle id **`com.qmatch.app`** and macOS product name **`qmatch.app`** were **not** changed (build identifiers, not web domain).

---

## Mailbox status (updated 3P-A24)

`support@qmatch.site` — **confirmed receiving**

- Cloudflare Email Routing → `sirinumit@gmail.com`
- Test email received successfully; monitored via that Gmail inbox
- Gmail “Send mail as support@qmatch.site” — optional / future (not a launch blocker)
- See `docs/qmatch_site_support_mailbox_verification.md`

---

## Hosted URL status (updated 3P-A24)

Legal/support pages — **live and manually verified** on Cloudflare Pages (`qmatch.site`).

- Public EN/TR URLs open in incognito
- Store-facing copy verified (no launch-draft / NEEDS CONFIRMATION / “future hosting” wording)
- See `docs/qmatch_site_live_verification.md`

---


## Files changed (high level)

- `lib/core/constants/app_support.dart`
- `lib/l10n/app_en.arb`, `app_tr.arb`, generated `app_localizations*.dart`
- `docs/store_privacy_questionnaire_pack.md`
- `docs/support_and_legal_url_readiness.md`
- `docs/legal_web_drafts/*`
- `docs/legal_static_site/**`
- `docs/legal_static_site_package_report.md`
- Related launch/deletion docs that referenced `support@qmatch.app` / `https://qmatch.app`

---

## Remaining steps

1. ~~Configure / verify `support@qmatch.site` receive~~ → Done (3P-A24)
2. ~~Choose hosting + verify live URLs~~ → Done (Cloudflare Pages)
3. Paste Privacy / Terms / Support / Account-deletion URLs into store forms
4. Finish store privacy questionnaire items still marked NEEDS CONFIRMATION
5. Staff deletion fulfillment ops (manual runbook)
6. Optional: counsel review; Gmail send-as `support@qmatch.site`

---

## Explicit non-actions

No deploy, no Firestore writes, no commit/push in this phase.
