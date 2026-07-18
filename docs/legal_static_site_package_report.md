# Legal Static Site Package Report (Phase 3P-A21)

Date: 2026-07-18
Package root: `docs/legal_static_site/`
Mode: Static package. **Hosting live** on Cloudflare Pages (`qmatch.site`). **3P-A24:** public URLs + store-facing copy manually verified; mailbox receive confirmed.

---

## Files created

| Path | Role |
|------|------|
| `docs/legal_static_site/index.html` | EN hub |
| `docs/legal_static_site/privacy/index.html` | Privacy (EN) |
| `docs/legal_static_site/terms/index.html` | Terms (EN) |
| `docs/legal_static_site/support/index.html` | Support (EN) |
| `docs/legal_static_site/account-deletion/index.html` | Account deletion (EN) |
| `docs/legal_static_site/tr/index.html` | TR hub |
| `docs/legal_static_site/tr/privacy/index.html` | Privacy (TR) |
| `docs/legal_static_site/tr/terms/index.html` | Terms (TR) |
| `docs/legal_static_site/tr/support/index.html` | Support (TR) |
| `docs/legal_static_site/tr/account-deletion/index.html` | Account deletion (TR) |
| `docs/legal_static_site/assets/legal.css` | Local CSS (system fonts only) |

Public pages are store-facing. Mailbox receive confirmed — see `docs/qmatch_site_support_mailbox_verification.md`.

---

## Source drafts used

From `docs/legal_web_drafts/`:

- `privacy_policy_en.md` / `privacy_policy_tr.md`
- `terms_of_use_en.md` / `terms_of_use_tr.md`
- `support_en.md` / `support_tr.md`
- `account_deletion_en.md` / `account_deletion_tr.md`

Content was converted to HTML without inventing new legal claims. Launch-draft disclaimers preserved.

---

## Proposed URL mapping

Live on `qmatch.site` (Cloudflare Pages). Prefer trailing-slash URLs:

| Public URL | Static path |
|------------|-------------|
| `https://qmatch.site/` | `index.html` |
| `https://qmatch.site/privacy/` | `privacy/index.html` |
| `https://qmatch.site/terms/` | `terms/index.html` |
| `https://qmatch.site/support/` | `support/index.html` |
| `https://qmatch.site/account-deletion/` | `account-deletion/index.html` |
| `https://qmatch.site/tr/` | `tr/index.html` |
| `https://qmatch.site/tr/privacy/` | `tr/privacy/index.html` |
| `https://qmatch.site/tr/terms/` | `tr/terms/index.html` |
| `https://qmatch.site/tr/support/` | `tr/support/index.html` |
| `https://qmatch.site/tr/account-deletion/` | `tr/account-deletion/index.html` |

---

## Page features

- Qmatch branding title
- Last updated (July / Temmuz 2026)
- EN ↔ TR language switch on legal pages
- Support contact `mailto:support@qmatch.site`
- Mobile-friendly layout
- **No** external tracking scripts
- **No** analytics
- **No** remote fonts (system / Georgia stack only)
- **No** cookies
- **No** data-collection forms

---

## Hosting options

| Option | Pros | Cons |
|--------|------|------|
| **Firebase Hosting** | Same Google project as app; easy custom domain; `firebase.json` hosting block later | Not configured yet (`firebase.json` is FlutterFire-only today) |
| **Cloudflare Pages** | Fast CDN, free tier, easy Git deploy | Separate vendor |
| **GitHub Pages** | Simple for static dirs | Path/base-url care; custom domain setup |
| **Domain provider static hosting** | Direct on registrar | Varies by provider |

### Recommended simplest option

**Cloudflare Pages** — chosen and live; URLs verified 3P-A24.

---

## What remains

1. ~~Wire hosting for `qmatch.site`~~ → live + verified
2. ~~Confirm `support@qmatch.site` receive/monitor~~ → confirmed (3P-A24)
3. Legal review of Privacy/Terms (optional / recommended)
4. Paste URLs into App Store Connect / Play Console (+ finish questionnaire NEEDS CONFIRMATION items)
5. Staff deletion fulfillment ops (manual)
6. Optional: deep-link from in-app About/Help; Gmail send-as

---

## Explicit non-actions (this phase)

- No hosting deploy / publish
- No Firebase writes
- No app runtime behavior changes
- No commit / push

Related: `docs/support_and_legal_url_readiness.md`
