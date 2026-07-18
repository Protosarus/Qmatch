# Support Mailbox & Hosted Legal URL Readiness (Phase 3P-A20)

Date: 2026-07-18
Mode: **Documentation & drafts only** — no hosting deploy, no Firebase writes, no commits

Related: `docs/store_privacy_questionnaire_pack.md`, `docs/launch_readiness_consolidated_audit.md`, in-app ARB legal copy, `lib/core/constants/app_support.dart`

---

## 1. Current support email in the app

| Item | Value |
|------|--------|
| Constant | `AppSupport.email` = **`support@qmatch.site`** |
| Mailto | `mailto:support@qmatch.site` |
| Used in | Help, About/legal flows, deletion UX, Privacy/Terms contact lines, FAQ |

### Mailbox status

**Pending / NEEDS CONFIRMATION** — engineering has not verified that the mailbox receives mail, sends replies, or is monitored. Treat as a **P0 store-submit blocker** until confirmed.

---

## 2. Recommended mailbox setup checks

Operator (founder/ops) should confirm:

- [ ] Domain `qmatch.site` email DNS (MX / SPF / DKIM / DMARC as applicable)
- [ ] Inbox **can receive** mail to `support@qmatch.site`
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

### Public URLs (Cloudflare Pages — domain live)

| Purpose | Live URL |
|---------|----------|
| Privacy | `https://qmatch.site/privacy/` |
| Terms | `https://qmatch.site/terms/` |
| Support | `https://qmatch.site/support/` |
| Account deletion | `https://qmatch.site/account-deletion/` |

**Domain:** `qmatch.site` purchased and connected. Host: **Cloudflare Pages** (operator-reported live).
**Store-facing copy:** local `docs/legal_static_site/` cleaned in 3P-A22B; **re-upload to Cloudflare still required** so live pages match. See `docs/qmatch_site_live_verification.md`.
**Email DNS / mailbox:** `support@qmatch.site` still **NEEDS CONFIRMATION**.
Bundle id `com.qmatch.app` is unrelated and unchanged.

Locale note: EN primary paths + TR under `/tr/…` are published in the static package.

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
Quality: **launch draft**. Not counsel-approved. `support@qmatch.site` marked **NEEDS CONFIRMATION** in drafts.

---

## 5. Hosting target

| Option | Status |
|--------|--------|
| **Cloudflare Pages** | **Chosen & live** for `qmatch.site` (operator-reported) |
| Firebase Hosting | Not configured in `firebase.json` (FlutterFire only) |
| Flutter `web/` | Not used for legal site |

**Next ops step:** re-upload cleaned `docs/legal_static_site/` after 3P-A22B copy cleanup; then paste verified URLs into store forms.

---

## 6. Open questions (NEEDS CONFIRMATION)

1. ~~Is `qmatch.site` owned / hosted?~~ → Live on Cloudflare Pages (still re-verify HTTPS after copy re-upload).
2. Is `support@qmatch.site` provisioned and monitored?
3. ~~Preferred host?~~ → Cloudflare Pages.
4. ~~EN/TR path strategy?~~ → `/` EN + `/tr/…` TR in static package.
5. Should the app later open hosted URLs instead of in-app `LegalDocumentScreen` only?
6. Counsel review timeline for Privacy/Terms?
7. Will Play/App Store use the same four URLs?

---

## 7. Final pre-submit checklist

- [x] Domain `qmatch.site` live on Cloudflare Pages (operator-reported)
- [ ] Confirm / monitor `support@qmatch.site` mailbox
- [ ] **Re-upload** store-facing `docs/legal_static_site/` (3P-A22B local cleanup)
- [ ] Re-verify URLs over HTTPS (incognito) — no draft / NEEDS CONFIRMATION text
- [ ] Update App Store / Play forms with final Privacy, Terms, Support URLs
- [ ] Ensure account-deletion page matches in-app flow (Settings → Delete account, 30 days, support email)
- [ ] Legal review of Privacy/Terms (and optionally deletion/support pages)
- [ ] Update `docs/store_privacy_questionnaire_pack.md` checklist items once clean URLs are live
- [ ] Optional: add hosted URLs to in-app About/Help as external links

---

## Explicit non-actions (this phase)

- No hosting deploy / website publish
- No Firestore writes
- No Admin SDK / rules / Functions deploy
- No assessment/scoring changes
- No commit / push
