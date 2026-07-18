# Legal, Help, Privacy & Safety Launch Content Audit (Phase 3P-A4)

**Date:** 2026-07-18  
**Mode:** Launch-facing copy + l10n only — **no** assessment JSON, scoring, compatibility weights, Firestore writes, publish, commit, or push  

**Disclaimer:** In-app Privacy Policy and Terms are **product launch drafts**, not final legal advice. A formal legal review is recommended before public launch.

---

## 1. Files inspected

| Area | Paths |
|------|--------|
| Settings / About / Help | `lib/features/settings/screens/{settings,about,help_support,privacy_settings,notifications_settings,blocked_users}_screen.dart` |
| Safety | `lib/features/safety/{services/safety_service.dart,models/*}`, chat report/block in `chat_detail_screen.dart` |
| Auth consent | `welcomeTermsPrivacy` in ARB; signup/login flows |
| Age | Profile age range min **18** (`preferences_step.dart`, profile models) |
| L10n | `lib/l10n/app_en.arb`, `app_tr.arb`, generated localizations |

---

## 2. Files changed

| File | Change |
|------|--------|
| `lib/l10n/app_en.arb` | Privacy/Terms bodies, FAQs, support, delete-account copy; removed TODO-facing MVP notes |
| `lib/l10n/app_tr.arb` | Same in Turkish |
| `lib/l10n/app_localizations*.dart` | Regenerated via `flutter gen-l10n` |
| `lib/features/settings/screens/about_screen.dart` | Links to full Privacy / Terms screens |
| `lib/features/settings/screens/help_support_screen.dart` | Expanded FAQ + support email copy-to-clipboard |
| `lib/features/settings/screens/legal_document_screen.dart` | **New** scrollable legal viewer |
| `lib/features/settings/screens/settings_screen.dart` | Delete-account request dialog (support path) |
| `lib/core/constants/app_support.dart` | **New** `support@qmatch.app` constant |
| `docs/legal_help_privacy_launch_content_audit.md` | This report |

---

## 3. Screens / content updated

- **About** — description + open Privacy Policy / Terms of Use  
- **Help & Support** — FAQs (product, scores disclaimer, data, age, block/report, offline safety, deletion) + support contact  
- **Settings** — “Delete account” → explains email request to support  
- **Privacy settings / Notifications** — MVP TODOs replaced with honest device-local preference notes  

---

## 4. Placeholders removed

- `Privacy Policy (TODO)` / `Kullanım Şartları (TODO)` → full draft documents  
- Help “TODO: Add in-app support…” → `support@qmatch.app` copy + clipboard  
- Privacy/notifications “TODO: Persist to Firestore…” → non-TODO product wording  

---

## 5. Remaining placeholders / follow-ups

| Item | Status |
|------|--------|
| `support@qmatch.app` | **Placeholder inbox** — confirm mailbox before public launch |
| In-app one-tap account deletion | **Not implemented** — request-via-email path only |
| Privacy toggles cloud sync | Still device-local for some switches |
| Hosted web Privacy/Terms URLs | Not added (in-app text only) |
| Formal counsel sign-off | **Recommended** before store launch |

Legacy ARB keys `privacyPolicyTodo` / `termsOfUseTodo` / `helpSupportContactTodo` remain as aliases with non-TODO text for compatibility.

---

## 6. Support email

**Used:** `support@qmatch.app` (`AppSupport.email`)  
**Requires final confirmation** that this address is monitored before launch.

---

## 7. Account deletion flow status

| Capability | Status |
|------------|--------|
| Settings entry + dialog explaining email request | **Yes** |
| FAQ how-to-delete | **Yes** |
| Automated wipe of Auth + Firestore user data | **Not built** |

---

## 8. Report / block status

| Capability | Status |
|------------|--------|
| Chat menu Report / Block | **Implemented** (`SafetyService`) |
| Blocked users list + unblock | **Implemented** |
| FAQ copy for both | **Updated** |

---

## 9. Privacy / Terms status

| Doc | Status |
|-----|--------|
| Privacy Policy (EN/TR) | **Launch draft in-app** — covers product purpose, age 18+, auth/profile/assessments/messages/reports, choices, offline safety, contact |
| Terms of Use (EN/TR) | **Launch draft in-app** — eligibility, service limits, user responsibilities, safety tools, deletion via support, disclaimer |
| Legal review | **Pending** |

---

## 10. TR / EN localization

| Locale | Status |
|--------|--------|
| English | Full draft strings in `app_en.arb` |
| Turkish | Matching draft strings in `app_tr.arb` |
| `flutter analyze` | Clean after `gen-l10n` |

---

## 11. Risks before launch

1. Support mailbox not yet confirmed.  
2. No automated account deletion pipeline.  
3. Draft legal text needs counsel review (jurisdiction, store requirements).  
4. Some privacy/notification toggles not cloud-persisted.  
5. Offline safety is advisory only—moderation capacity still needed for reports.

---

## 12. Recommended next phase

1. Confirm `support@qmatch.app` (or final address) and update constant + ARB if needed.  
2. Implement authenticated account deletion / export if stores require it.  
3. Legal review of Privacy + Terms; publish canonical web URLs if required.  
4. Optional: deep-link Terms/Privacy from signup `welcomeTermsPrivacy`.  
5. Then commit/push this content when approved.
