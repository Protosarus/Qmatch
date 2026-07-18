# qmatch.site Hosting Plan (Phase 3P-A21B)

Date: 2026-07-18
Mode: Plan created in 3P-A21B. **Update (3P-A22B):** Cloudflare Pages + `qmatch.site` reported live. Initial deploy done by ops. Local package later cleaned for store-facing copy — **re-upload still DO NOT RUN in 3P-A22B** (later phase).

Source package: `docs/legal_static_site/`
Related: `docs/legal_static_site_package_report.md`, `docs/qmatch_site_domain_launch_update.md`, `docs/qmatch_site_live_verification.md`

---

## 1. Static package check (pre-host)

| Check | Result |
|-------|--------|
| Package present | Yes — `docs/legal_static_site/` |
| Old `qmatch.app` web URLs in package | **None found** |
| Support email in pages | `support@qmatch.site` |
| Mailbox verified | **NEEDS CONFIRMATION** (still) |
| Pages live on HTTPS | **Yes** (Cloudflare Pages / `qmatch.site`) — re-upload cleaned copy still pending |

Output folder to publish (as-is):

```text
docs/legal_static_site/
  index.html
  privacy/index.html
  terms/index.html
  support/index.html
  account-deletion/index.html
  tr/...
  assets/legal.css
```

No build step required (already static HTML/CSS).

---

## 2. Hosting options comparison

| Option | Fit for this package | Pros | Cons |
|--------|----------------------|------|------|
| **Cloudflare Pages** | Excellent | Free tier; Direct Upload of folder; fast CDN; custom domain + auto HTTPS; no change to Flutter `firebase.json` | Separate from Firebase app project |
| **Firebase Hosting** | Good | Same Google project (`qmatch-53d62`); familiar Firebase CLI | Repo `firebase.json` has **no** hosting block today; needs config + CLI deploy |
| **GitHub Pages** | OK | Free; simple for public repos | Branch/`docs` or `gh-pages` path care; custom domain CNAME; less ideal if repo stays private |

### Recommended simplest option

**Cloudflare Pages — Direct Upload** of `docs/legal_static_site/`

Why:

1. Package is already static (no CI build).
2. Avoids editing FlutterFire `firebase.json` / mixing app + legal deploy.
3. Custom domain + HTTPS is straightforward once DNS is pointed.
4. Can later migrate to Firebase Hosting if desired.

**Alternative:** Firebase Hosting if the team wants one vendor for app + legal site.

---

## 3. Recommended path: Cloudflare Pages

### DNS records needed (plan only — DO NOT MODIFY DNS YET)

Exact values come from the Cloudflare Pages custom-domain UI after the project exists. Typical pattern:

| Type | Name | Target / value | Notes |
|------|------|----------------|-------|
| `CNAME` | `@` or `www` | `<project>.pages.dev` (or Cloudflare apex guidance) | Apex may use Cloudflare nameservers or A/AAAA flattened records |
| Email (`MX` / `TXT`) | `@` | Provider-specific for `support@qmatch.site` | **Separate** from Pages; configure with email host |

Keep **website DNS** and **email DNS** coordinated so MX is not broken when attaching the site.

### Build / output folder

| Item | Value |
|------|--------|
| Build command | **None** |
| Output directory | `docs/legal_static_site` (upload this folder’s contents as the site root) |

---

## 4. Deploy steps — DO NOT RUN YET

> **STOP:** The following are future steps for an approved hosting phase.
> **Do not run** in Phase 3P-A21B. **Do not modify DNS** in this phase.

### A. Cloudflare Pages (recommended)

1. Create Cloudflare account / add `qmatch.site` zone **or** use external DNS with CNAME to Pages.
2. Workers & Pages → Create → **Direct Upload**.
3. Upload contents of `docs/legal_static_site/` (so `index.html` is at site root).
4. Project → Custom domains → add `qmatch.site` (and optionally `www`).
5. Apply the DNS records Cloudflare shows (**later**, when approved).
6. Wait for HTTPS active.
7. Run the verification checklist below.

### B. Firebase Hosting (alternative) — DO NOT RUN YET

1. Add a `hosting` block to `firebase.json` pointing `public` at a copy of `docs/legal_static_site` (or symlink).
2. `firebase login` / select `qmatch-53d62`.
3. `firebase hosting:sites:create` (if needed) + `firebase target:apply hosting …`.
4. `firebase deploy --only hosting` — **DO NOT RUN YET**.
5. Firebase Console → Hosting → add custom domain `qmatch.site` → apply DNS — **DO NOT MODIFY DNS YET**.

### C. GitHub Pages (alternative) — DO NOT RUN YET

1. Publish `docs/legal_static_site` via `gh-pages` branch or Actions.
2. Set custom domain `qmatch.site` + `CNAME` file.
3. Configure DNS at registrar — **DO NOT MODIFY DNS YET**.

---

## 5. HTTPS verification checklist (after a future deploy)

- [ ] `https://qmatch.site/` loads hub (padlock / valid cert)
- [ ] HTTP → HTTPS redirect works (if offered)
- [ ] Incognito / logged-out browser
- [ ] Mobile viewport OK
- [ ] No mixed-content warnings
- [ ] No analytics/tracking scripts injected by host (keep package clean)

---

## 6. URL checklist (must open publicly after deploy)

- [ ] `https://qmatch.site/privacy`
- [ ] `https://qmatch.site/terms`
- [ ] `https://qmatch.site/support`
- [ ] `https://qmatch.site/account-deletion`
- [ ] Optional TR: `https://qmatch.site/tr/privacy` (and terms/support/account-deletion)

Then paste into App Store Connect / Play Console + store privacy pack.

---

## 7. Mailbox checklist — `support@qmatch.site`

Still **NEEDS CONFIRMATION** (domain purchase ≠ mailbox live):

- [ ] MX (and SPF/DKIM as applicable) for `qmatch.site`
- [ ] Can **receive** mail to `support@qmatch.site`
- [ ] Can **send** replies
- [ ] Monitored (daily at launch / owner named)
- [ ] Deletion requests labeled/tracked (see ops runbook)
- [ ] Confirm DNS changes for Pages do **not** break MX

---

## 8. Explicit non-actions (this phase)

- No hosting deploy
- No website publish
- No DNS modification
- No Firebase writes
- No Admin SDK
- No commit / push

---

## 9. Recommended next step (after approval)

1. Configure **email** for `support@qmatch.site` first (or in parallel carefully with DNS).
2. Create Cloudflare Pages project and Direct Upload `docs/legal_static_site/`.
3. On approval: attach custom domain + apply DNS.
4. Verify HTTPS URLs → update store forms.
