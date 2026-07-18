# qmatch.site Live Verification

Date: 2026-07-18
Phases: 3P-A22B (local copy cleanup) · **3P-A24 (manual live + mailbox confirmation documented)**
Mode: Documentation updates only in 3P-A24 — **no deploy / DNS / Firebase by this phase**

---

## Deployment status (manually verified)

| Item | Status |
|------|--------|
| Host | **Cloudflare Pages** |
| Live domain | **`qmatch.site`** |
| Connected & opening publicly | **Yes** |
| Store-facing copy on live site | **Yes** — no “NEEDS CONFIRMATION”, “Launch draft”, “not formal legal advice”, or “future hosting” on public pages |
| Manual incognito URL check | **Passed** (see checklist below) |

---

## URL checklist (verified live)

| URL | Status |
|-----|--------|
| `https://qmatch.site/` | Verified |
| `https://qmatch.site/privacy/` | Verified |
| `https://qmatch.site/terms/` | Verified |
| `https://qmatch.site/support/` | Verified |
| `https://qmatch.site/account-deletion/` | Verified |
| `https://qmatch.site/tr/privacy/` | Verified |
| `https://qmatch.site/tr/terms/` | Verified |
| `https://qmatch.site/tr/support/` | Verified |
| `https://qmatch.site/tr/account-deletion/` | Verified |

---

## Support mailbox

| Item | Status |
|------|--------|
| Address | `support@qmatch.site` |
| Routing | Cloudflare Email Routing → `sirinumit@gmail.com` |
| Receive test | **Passed** |
| Monitoring | Via `sirinumit@gmail.com` |
| Send as `support@qmatch.site` from Gmail | Optional / future — **not** a launch blocker |

Details: `docs/qmatch_site_support_mailbox_verification.md`

---

## Legal review

| Item | Status |
|------|--------|
| Formal counsel review of Privacy / Terms | **Still optional / recommended** (not required to clear URL hosting) |
| Public pages store-facing | Verified live |

---

## App Store / Play Store URL mapping

| Store field | URL |
|-------------|-----|
| Privacy Policy | `https://qmatch.site/privacy/` |
| Terms of Use (if asked) | `https://qmatch.site/terms/` |
| Support / Contact | `https://qmatch.site/support/` |
| Account deletion / data deletion help | `https://qmatch.site/account-deletion/` |
| Support email | `support@qmatch.site` |

Related: `docs/store_privacy_questionnaire_pack.md`

---

## Remaining blockers before store submission

1. Account deletion **fulfillment** ops staffed (manual runbook; automation still off).
2. Complete founder/legal confirmation on store privacy questionnaire items still marked **NEEDS CONFIRMATION** (SDK/telemetry/etc.).
3. Optional: counsel review of Privacy/Terms.
4. Optional: Gmail “Send mail as support@qmatch.site”.

**Cleared (ops):** hosted legal URLs · support mailbox receive/monitor.

---

## Explicit non-actions (documentation phases)

- No hosting deploy / DNS / Cloudflare changes by the agent in 3P-A24
- No Firestore writes / Admin SDK / rules / Functions
- No assessment / scoring / weight / app behavior changes
- No commit / push
