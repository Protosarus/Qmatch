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

## Mailbox status

`support@qmatch.site` — **NEEDS CONFIRMATION**

- Domain purchased does **not** automatically mean email works.
- Still need MX/SPF (etc.), receive/send test, and monitoring owner.

---

## Hosted URL status

Legal/support pages — **live on Cloudflare Pages** at `qmatch.site` (operator-reported, 2026-07-18).

- Static package: `docs/legal_static_site/`
- 3P-A22B: local store-facing copy cleanup done; **Cloudflare re-upload still required** so live pages drop launch-draft / NEEDS CONFIRMATION wording.
- See `docs/qmatch_site_live_verification.md`.

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

1. Configure email for **`support@qmatch.site`** (DNS + mailbox + monitoring) — still **NEEDS CONFIRMATION**
2. ~~Choose hosting~~ → Cloudflare Pages live
3. **Re-upload** cleaned `docs/legal_static_site/` to Cloudflare
4. Re-verify URLs (incognito) after re-upload
5. Update App Store Connect / Play Console forms with final URLs
6. Optional: counsel review before calling pages “final”

---

## Explicit non-actions

No deploy, no Firestore writes, no commit/push in this phase.
