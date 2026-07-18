# qmatch.site Live Verification (Phase 3P-A22B)

Date: 2026-07-18
Mode: **Documentation + local static copy cleanup only**
**This phase did not deploy, modify DNS, or write to Firebase.**

---

## Deployment status (operator-reported)

| Item | Status |
|------|--------|
| Host | **Cloudflare Pages** |
| Live domain | **`qmatch.site`** |
| Connected & opening publicly | **Yes** (per operator) |
| Local package re-uploaded after store-facing copy cleanup | **No** — local HTML updated in this phase; **re-upload still required** |

---

## URLs to manually verify (incognito / logged-out)

Prefer trailing-slash forms (matches `index.html` directories):

| URL | Purpose |
|-----|---------|
| `https://qmatch.site/` | Hub |
| `https://qmatch.site/privacy/` | Privacy Policy |
| `https://qmatch.site/terms/` | Terms of Use |
| `https://qmatch.site/support/` | Support / Contact |
| `https://qmatch.site/account-deletion/` | Account deletion |
| `https://qmatch.site/tr/privacy/` | Privacy (TR) |
| `https://qmatch.site/tr/terms/` | Terms (TR) |
| `https://qmatch.site/tr/support/` | Support (TR) |
| `https://qmatch.site/tr/account-deletion/` | Account deletion (TR) |

Also spot-check: HTTPS padlock, mobile layout, no mixed content, EN↔TR links.

**Known issue at time of this phase:** live landing page still showed internal “launch draft” / **NEEDS CONFIRMATION** wording. Local `docs/legal_static_site/` was cleaned for store-facing copy; Cloudflare still serves the previous upload until re-deployed in a later phase.

---

## Support mailbox

| Item | Status |
|------|--------|
| Address used publicly & in-app | `support@qmatch.site` |
| Receive / send / monitor verified | **Still unconfirmed — NEEDS CONFIRMATION** |
| Do not claim “verified” on public pages or in store forms until ops confirms | Yes |

---

## Legal review

| Item | Status |
|------|--------|
| Formal counsel review of Privacy / Terms | **Still pending** |
| Public pages cleaned of internal draft disclaimers (local only) | Done in this phase |
| Public pages are product policies, not a substitute for counsel sign-off | Keep internal awareness |

---

## App Store / Play Store URL mapping

Use these in App Store Connect / Play Console once live copy is re-uploaded and verified:

| Store field | URL |
|-------------|-----|
| Privacy Policy | `https://qmatch.site/privacy/` |
| Terms of Use (if asked) | `https://qmatch.site/terms/` |
| Support / Contact | `https://qmatch.site/support/` |
| Account deletion / data deletion help (if asked) | `https://qmatch.site/account-deletion/` |

Support email for store forms: `support@qmatch.site` — only after mailbox confirmation.

Related draft answers: `docs/store_privacy_questionnaire_pack.md`.

---

## Remaining blockers before store submission

1. **Re-upload** cleaned `docs/legal_static_site/` to Cloudflare Pages (later phase).
2. **Manually verify** all public URLs after re-upload (no draft / NEEDS CONFIRMATION text).
3. Confirm **`support@qmatch.site`** mailbox (receive, send, monitor) — still a **P0 blocker**.
4. Complete / confirm store privacy questionnaire pack items still marked NEEDS CONFIRMATION.
5. Account deletion **fulfillment** ops ready (manual runbook) — product request path exists; wipe is not automated.
6. Optional but recommended: counsel review of Privacy/Terms before calling them final.

---

## Explicit non-actions (this phase)

- No hosting deploy / re-upload
- No DNS changes
- No Firestore writes
- No Admin SDK / rules / Functions
- No assessment / scoring / weight changes
- No commit / push

---

## Related docs

- `docs/legal_static_site/` — store-facing local package (pending re-upload)
- `docs/qmatch_site_hosting_plan.md`
- `docs/support_and_legal_url_readiness.md`
- `docs/legal_static_site_package_report.md`
- `docs/qmatch_site_domain_launch_update.md`
