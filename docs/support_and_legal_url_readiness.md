# Support Mailbox & Hosted Legal URL Readiness (Phase 3P-A20)

Date: 2026-07-18  
Mode: **Documentation & drafts only** — no hosting deploy, no Firebase writes, no commits  

Related: `docs/store_privacy_questionnaire_pack.md`, `docs/launch_readiness_consolidated_audit.md`, in-app ARB legal copy, `lib/core/constants/app_support.dart`

---

## 1. Current support email in the app

| Item | Value |
|------|--------|
| Constant | `AppSupport.email` = **`support@qmatch.app`** |
| Mailto | `mailto:support@qmatch.app` |
| Used in | Help, About/legal flows, deletion UX, Privacy/Terms contact lines, FAQ |

### Mailbox status

**Pending / NEEDS CONFIRMATION** — engineering has not verified that the mailbox receives mail, sends replies, or is monitored. Treat as a **P0 store-submit blocker** until confirmed.

---

## 2. Recommended mailbox setup checks

Operator (founder/ops) should confirm:

- [ ] Domain `qmatch.app` email DNS (MX / SPF / DKIM / DMARC as applicable)  
- [ ] Inbox **can receive** mail to `support@qmatch.app`  
- [ ] Account **can send** replies (not only forward-only)  
- [ ] Monitored on a defined cadence (**daily** recommended at launch; at least **weekly** minimum)  
- [ ] Named **owner** assigned  
- [ ] Deletion requests labeled/tracked (folder, tag, or ticket) and tied to ops runbook  
- [ ] Auto-reply optional: “We received your message; deletion requests are processed within 30 days…”  
- [ ] Spam/junk reviewed so deletion/support mail is not missed  

See also: `docs/account_deletion_manual_ops_runbook.md` (EN/TR reply templates).

---

## 3. Required hosted URLs (for stores / public)

| Page | Why needed |
|------|------------|
| Privacy Policy | App Store Connect / Play Console privacy fields; public transparency |
| Terms of Use | Often required or expected for consumer apps |
| Support / Contact | Store support URL; user help |
| Account deletion instructions | Helpful for Play Data Safety / Apple deletion clarity; mirrors in-app flow |

### Suggested final URLs (placeholders until domain hosting confirmed)

| Purpose | Suggested URL |
|---------|----------------|
| Privacy | `https://qmatch.app/privacy` |
| Terms | `https://qmatch.app/terms` |
| Support | `https://qmatch.app/support` |
| Account deletion | `https://qmatch.app/account-deletion` |

**Domain ownership / DNS / TLS:** NEEDS CONFIRMATION (`qmatch.app` is the intended brand domain; bundle id `com.qmatch.app` exists in Firebase options — hosting not configured in this repo).

Locale note: EN/TR drafts both exist. Hosting may use one primary language per URL with language toggle, or paths like `/tr/privacy` later — NEEDS CONFIRMATION.

---

## 4. Web draft files created (not published)

Under `docs/legal_web_drafts/`:

| File | Language |
|------|----------|
| `privacy_policy_en.md` | EN |
| `privacy_policy_tr.md` | TR |
| `terms_of_use_en.md` | EN |
| `terms_of_use_tr.md` | TR |
| `account_deletion_en.md` | EN |
| `account_deletion_tr.md` | TR |
| `support_en.md` | EN |
| `support_tr.md` | TR |

Source: existing in-app ARB Privacy/Terms/Help/deletion copy.  
Quality: **launch draft**. Not counsel-approved. `support@qmatch.app` marked **NEEDS CONFIRMATION** in drafts.

---

## 5. Hosting target (document only — not deployed)

| Option | Status in repo |
|--------|----------------|
| Firebase Hosting | **Not configured** — `firebase.json` is FlutterFire platforms only (no `hosting` block) |
| Flutter `web/` | Default Flutter web shell only — not a marketing/legal site |
| Custom domain `qmatch.app` | Referenced as brand intent; **not verified here** |
| GitHub Pages / Cloudflare / other | Not present |

**Recommendation (ops, later phase):** Firebase Hosting or static host serving the markdown→HTML pages at the suggested paths; wire custom domain; then paste URLs into store forms and optionally deep-link from the app.

**This phase does not modify `firebase.json` or deploy hosting.**

---

## 6. Open questions (NEEDS CONFIRMATION)

1. Is `qmatch.app` owned and DNS-controllable by the team?  
2. Is `support@qmatch.app` provisioned and monitored?  
3. Preferred host (Firebase Hosting vs other)?  
4. Single URL language vs EN/TR path strategy?  
5. Should the app later open hosted URLs instead of in-app `LegalDocumentScreen` only?  
6. Counsel review timeline before public URLs go live?  
7. Will Play/App Store use the same four URLs?  

---

## 7. Final pre-submit checklist

- [ ] Confirm domain ownership (`qmatch.app` or chosen domain)  
- [ ] Confirm / monitor `support@qmatch.app` mailbox  
- [ ] Convert drafts to public HTML (or CMS) and **publish** legal pages  
- [ ] Verify URLs open publicly over HTTPS (incognito, no auth)  
- [ ] Update App Store / Play forms with final Privacy, Terms, Support URLs  
- [ ] Ensure account-deletion page matches in-app flow (Settings → Delete account, 30 days, support email)  
- [ ] Legal review of Privacy/Terms (and optionally deletion/support pages)  
- [ ] Update `docs/store_privacy_questionnaire_pack.md` checklist items once URLs are live  
- [ ] Optional: add hosted URLs to in-app About/Help as external links  

---

## Explicit non-actions (this phase)

- No hosting deploy / website publish  
- No Firestore writes  
- No Admin SDK / rules / Functions deploy  
- No assessment/scoring changes  
- No commit / push  
