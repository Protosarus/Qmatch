# Qmatch Launch Readiness Consolidated Audit (Phase 3P-A18)

Date: 2026-07-18  
**Update:** 3P-A29 — Firebase Console privacy checks verified; deletion/support ops staffed (**Ümit**)  
Project: `qmatch-53d62`  
Mode: **Audit / doc updates only** — no Firestore writes, no deploys, no destructive ops, no code behavior changes

Classification key: **BLOCKER** · **HIGH** · **MEDIUM** · **LOW** · **DONE**

---

## Executive summary

Qmatch has a **coherent product loop** for launch candidates: phone auth → assessments (Firestore RC1) → profile → Discover → match/chat → report/block → Settings with legal drafts and in-app account deletion **requests**.

**Launch readiness is Conditional → near store-ready on ops/privacy.** Hosted legal URLs and `support@qmatch.site` are cleared. Firebase Console Analytics/Crashlytics/Performance/Messaging verified as **not collecting / not configured** for launch (3P-A29). Deletion fulfillment is **staffed manual** (Ümit, weekly, ≤30 days); automation still off. Remaining: fill store forms, optional counsel, optional product cleanups.

Overall: **not blocked on mailbox or Console telemetry** — proceed to form fill if founder accepts manual deletion responsibility.

---

## 1. Completed launch-critical items (DONE)

| Area | Status | Evidence |
|------|--------|----------|
| Phone authentication | DONE | Firebase Phone Auth primary path |
| Assessment content RC1 in Firestore | DONE | 150 `*_v2` sets; runtime QA `source=firestore_assessment_sets` |
| Assessment client load (int `version` coerce) | DONE | Parse fix + runtime QA |
| Compatibility cold-start guard | DONE | Frequency vector + band logic; QA docs |
| Profile setup (core fields) | DONE | Multi-step setup + photo upload path |
| Discover swipe + mutual match | DONE | Discover / Match / Swipe services |
| Messaging threads | DONE | Messages + chat detail |
| Report + block | DONE | `SafetyService`; chat + blocked users |
| Settings shell | DONE | Privacy, notifications, help, about, logout |
| Legal/help in-app drafts (EN/TR) | DONE | Privacy, Terms, FAQ, About |
| Support email constant | DONE | `support@qmatch.site` in app + copy |
| Hosted legal/support URLs | DONE | Cloudflare Pages; manually verified 3P-A24 |
| Support mailbox receive/monitor | DONE | Routes to `sirinumit@gmail.com`; owner **Ümit** |
| Firebase Console telemetry check | DONE | Analytics no events; Crashlytics/Performance Add SDK; Messaging not configured (3P-A29) |
| Deletion ops staffing (manual) | DONE | Owner **Ümit**; weekly check; ≤30-day SLA — automation still off |
| Account deletion **request** UX | DONE | Settings → Delete account; DELETE confirm |
| Deletion Firestore rules (owner request) | DONE | Manually published; post-deploy QA `ok=true` |
| Soft marker + pending UX | DONE | Settings / Delete screen / Discover banner |
| Deletion dry-run + execute **planning** tools | DONE | Destructive path still disabled |
| Manual ops runbook | DONE | `docs/account_deletion_manual_ops_runbook.md` |
| EN/TR localization (core + deletion) | DONE | ARB + generated l10n |

---

## 2. Remaining launch blockers (BLOCKER)

| ID | Item | Why blocker | Mitigation |
|----|------|-------------|------------|
| B1 | ~~Deletion fulfillment capacity~~ | **Cleared 3P-A29 (ops)** — owner **Ümit**; weekly pending discovery; manual ≤30 days. Automation still **off** (`EXECUTE_IMPLEMENTED=false`) | Keep runbook cadence; do not claim automated wipe |
| B2 | ~~`support@qmatch.site` mailbox~~ | **Cleared 3P-A24** — receive confirmed; owner **Ümit** | See mailbox verification doc |
| B3 | ~~Store privacy Console/SDK gaps~~ | **Mostly cleared 3P-A27–A29** — answer sheet + NFC + Console verification. Remaining: founder/counsel **sensitive-info / subprocessor wording** when filling forms | Use `docs/store_privacy_form_answer_sheet.md` |

*No remaining P0 engineering blockers for ops/privacy readiness. Store form paste + release QA remain process steps.*

---

## 3. High-risk technical / product gaps (HIGH)

| ID | Item | Notes |
|----|------|-------|
| H1 | No automated privileged deletion processor | Still true — manual ops staffed; execute disabled — correct for safety |
| H2 | Legal drafts not counsel-reviewed | Privacy/Terms live on web; formal counsel review still **optional / recommended** |
| H3 | ~~No public hosted Privacy/Terms URLs~~ | **DONE (3P-A24)** |
| H4 | Messaging moderation is thin | Report create-only; no in-app moderation queue / CS tooling documented |
| H5 | Users readable widely (MVP rules) | Production snapshot: signed-in users can read other user docs — intentional for Discover; privacy/overshare risk |
| H6 | Photos not gated in core setup wizard | Photos via profile edit; empty-photo Discover quality risk |
| H7 | Rules not versioned as deployable `firestore.rules` in repo | Candidate/snapshot docs exist; CLI deploy path absent — drift risk after Console edits |

---

## 4. Medium-risk UX / content gaps (MEDIUM)

| ID | Item |
|----|------|
| M1 | Discover still usable while deletion pending (banner only — not soft-disabled) |
| M2 | Privacy toggles partly device-local (not fully cloud-synced) |
| M3 | No dedicated Matches tab (matches only via chat) — product choice, may confuse |
| M4 | Social login screens/deps unused on welcome path |
| M5 | Email auth secondary path may need same deletion/support clarity as phone |
| M6 | Report outcomes not surfaced to reporter (“we received your report” only partially) |
| M7 | Age 18+ enforced in profile; store age rating / compliance copy should match |

---

## 5. Low-risk polish (LOW)

| ID | Item |
|----|------|
| L1 | Stale `PROJECT_STATUS_REPORT.md` (Mar 2025) — ignore for launch decisions |
| L2 | Optional Cloud Function later for deletion SLA automation |
| L3 | Dual-control / ticket system for deletion ops as volume grows |
| L4 | Expand FAQ / help for pending-deletion state |
| L5 | iOS UIScene migration warning (Flutter tooling) — not product blocker today |
| L6 | Localization edge cases / option label polish |

---

## 6. Firebase / Firestore / Storage rules status

| Component | Status | Class |
|-----------|--------|-------|
| Assessment `assessment_sets` live RC1 | Published; client read OK; client write denied | DONE |
| Account deletion request rules | Manually published from candidate; post-deploy QA passed | DONE |
| Repo `firestore.rules` for CLI | Absent; Console is source of truth | HIGH (drift) |
| Captured snapshot / candidate docs | Present under `docs/` (`*NOT_DEPLOYED*` filenames = not CLI-deployed) | DONE (docs) |
| Storage rules | Not audited in-repo this phase; app uses `profile_photos/{uid}/` | MEDIUM (confirm Console Storage rules) |
| Auth | Phone + email; no client Auth delete on request | DONE / expected |

---

## 7. Account deletion status

| Layer | Status | Class |
|-------|--------|-------|
| In-app initiation + confirmations | Live | DONE |
| Owner-only request write rules | Verified | DONE |
| Soft marker + pending UX | Live | DONE |
| Duplicate submit prevention | Service + UI | DONE |
| Dry-run inventory / execute plan | Available; no wipe | DONE |
| Automated destructive execute | Disabled | HIGH (until later phase) |
| Manual fulfillment runbook | Written | DONE |
| 30-day SLA ops staffing | **Ümit** assigned; weekly (3P-A29) | DONE (ops) |

**App Store 5.1.1(v):** Initiation risk **low/medium-low**. Fulfillment risk = ops capacity.

---

## 8. Legal / privacy / terms / support status

| Item | Status | Class |
|------|--------|-------|
| In-app Privacy Policy draft EN/TR | Present | DONE |
| In-app Terms draft EN/TR | Present | DONE |
| Help FAQ (incl. deletion) | Present | DONE |
| Counsel-approved legal | Not claimed | HIGH (optional / recommended) |
| Hosted web legal URLs | `qmatch.site` verified live | DONE |
| `support@qmatch.site` in product | Wired | DONE |
| Mailbox operational | Receive/monitor confirmed; owner **Ümit** | DONE |
| Store privacy questionnaire / Console | Answer sheet + Console verified (3P-A29); sensitive-info wording optional counsel | DONE (ops) / optional legal |

---

## 9. Assessment system status

| Item | Status | Class |
|------|--------|-------|
| RC1 content quality / export | Done earlier | DONE |
| Firestore publish (Admin) | Done | DONE |
| Runtime source = Firestore v2 | QA passed | DONE |
| Bundled asset fallback | Present | DONE |
| Scoring / weights this audit | Unchanged; not re-audited | DONE (stable) |
| Client publish of assessment_sets | Correctly denied | DONE |

---

## 10. Report / block / messaging safety

| Item | Status | Class |
|------|--------|-------|
| Block user | Implemented | DONE |
| Report user (Firestore `reports`) | Create from chat | DONE |
| Blocked users list | Settings | DONE |
| Moderation workflow / SLA | Not productized | HIGH |
| Message content filters | Minimal / none documented | MEDIUM |

---

## 11. App Store / Play review risks

| Risk | Level | Note |
|------|-------|------|
| Account deletion initiation missing | Mitigated | In-app request + pending UX |
| Deletion not actually completed in 30 days | HIGH → BLOCKER if ops empty | Manual runbook required |
| Privacy policy incomplete / unreachable | Mitigated for URL | Live on `qmatch.site`; counsel review optional |
| Data collection questionnaire mismatch | BLOCKER until drafted | Align with photos, phone, assessments, chat |
| Dating safety (meet offline guidance) | Partial DONE | Present in privacy draft |
| Login services incomplete (Sign in with Apple) | MEDIUM if shipping Apple sign-in later | Phone-first today |
| Age rating / 18+ | Align store metadata | MEDIUM |

---

## 12. Recommended next phases (priority order)

1. **Store forms (P0):** Paste `qmatch.site` URLs + fill App Privacy / Data Safety from answer sheet.  
2. **Ops maintain (P0):** Ümit weekly deletion discovery + support inbox. Automation remains off.  
3. **Legal harden (P1):** Optional counsel pass (H2); sensitive-info / subprocessor wording.  
4. **Storage rules audit (P1):** Confirm Console Storage rules for `profile_photos/{uid}/`.  
5. **Disposable destructive deletion test (P2):** Explicit phase — gated execute for **test uid only** after approval.  
6. **Pending Discover soft-disable (P2):** Optional product choice (M1).  
7. **Moderation lite (P2):** Ops view of `reports` + response templates (H4).  
8. **Repo rules versioning (P3):** Add `firestore.rules` + firebase.json wiring without blind overwrite (H7).  
9. **Optional polish:** Hide Google/Apple stubs; camera permission cleanup; Gmail send-as; font bundling.

---

## 13. Launch readiness status summary

| Dimension | Verdict |
|-----------|---------|
| Core dating/assessment loop | **Ready** |
| Assessment Firestore | **Ready** |
| Legal/help drafts | **Live on web** + in-app (counsel review optional) |
| Account deletion initiation | **Ready** |
| Account deletion fulfillment | **Staffed manual** (Ümit; automation off) |
| Support | **Ready** (Ümit; mailbox confirmed) |
| Store listing paperwork | **Ready to fill** (answer sheet + Console verified) |
| **Ship decision** | **Go (ops/privacy)** — fill store forms + release QA; accept manual deletion responsibility |

---

## 14. Explicit non-actions (this phase)

- No Firestore / Auth / Storage mutations
- No assessment JSON / scoring / weight changes
- No Admin SDK / deploy / commit / push
- Documentation only

---

## Related docs (index)

- Assessment: `docs/firestore_assessment_runtime_qa.md`, `docs/firestore_publish_rc1_report.md`
- Legal / site: `docs/qmatch_site_live_verification.md`, `docs/qmatch_site_support_mailbox_verification.md`, `docs/firebase_console_store_submission_verification.md`, `docs/store_submission_final_operations_checklist.md`, `docs/store_privacy_form_answer_sheet.md`
- Deletion: `docs/account_deletion_*`, `docs/firestore_rules_*`, `docs/account_deletion_manual_ops_runbook.md`, `docs/account_deletion_pending_ux.md`
