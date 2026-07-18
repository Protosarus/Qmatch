# Legal Static Site Package Report (Phase 3P-A21)

Date: 2026-07-18
Package root: `docs/legal_static_site/`
Mode: **Static files only — not deployed**

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

HTML comments note: `support@qmatch.site` mailbox **NEEDS CONFIRMATION**.

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

When hosted at `qmatch.site` (**domain purchased**; hosting not live yet — planned URLs pending deploy):

| Planned public URL | Static path |
|------------|-------------|
| `https://qmatch.site/` | `index.html` |
| `https://qmatch.site/privacy` | `privacy/index.html` |
| `https://qmatch.site/terms` | `terms/index.html` |
| `https://qmatch.site/support` | `support/index.html` |
| `https://qmatch.site/account-deletion` | `account-deletion/index.html` |
| `https://qmatch.site/tr/` | `tr/index.html` |
| `https://qmatch.site/tr/privacy` | `tr/privacy/index.html` |
| `https://qmatch.site/tr/terms` | `tr/terms/index.html` |
| `https://qmatch.site/tr/support` | `tr/support/index.html` |
| `https://qmatch.site/tr/account-deletion` | `tr/account-deletion/index.html` |

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

**Firebase Hosting** (or Cloudflare Pages if Firebase Hosting is delayed): upload/`firebase deploy --only hosting` of `docs/legal_static_site` (or a copied `public/` folder) after domain + mailbox confirmation. Do **not** deploy in this phase.

---

## What remains before deploy

1. Confirm DNS for **`qmatch.site`** (domain purchased; wire hosting + email)
2. Confirm **`support@qmatch.site`** mailbox receive/send/monitor (**NEEDS CONFIRMATION**)
3. Legal review of Privacy/Terms drafts
4. Choose hosting provider
5. Deploy static package
6. Verify URLs open publicly over HTTPS (incognito)
7. Paste URLs into App Store Connect / Play Console (+ store privacy pack)
8. Optional later: deep-link from in-app About/Help to hosted URLs

---

## Explicit non-actions (this phase)

- No hosting deploy / publish
- No Firebase writes
- No app runtime behavior changes
- No commit / push

Related: `docs/support_and_legal_url_readiness.md`
