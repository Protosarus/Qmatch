# Full App Localization — P0 Patch Report (Phase 3P-A2)

**Date:** 2026-07-17
**Mode:** Targeted P0 localization foundation — no redesign, no assessment JSON edits, no Firestore writes, no commit/push
**Baseline audit:** `docs/full_app_localization_audit.md` (Phase 3P-A1)

---

## Executive summary

Qmatch now has an explicit **unsupported-locale → English** fallback, a much richer shared ARB catalog (**48 → 253 keys**), and primary production chrome wired to `AppLocalizations` for:

- Bottom navigation / shell
- Phone auth funnel (welcome, phone signup, login)
- Discover (including compatibility label/reason keys)
- Messages / chat safety menus
- Settings + About / Help / Privacy / Notifications / Blocked
- Profile shell, name selection, photo edit, setup chrome + validation

Assessment localization (`AssessmentLanguage`, `LocalizedTextResolver`, assessment JSON) was **not changed** and remains PASS.

Heuristic audit: **P0 233 → 103** (~56% reduction). Remaining P0 is mostly secondary email auth, Turkish profile option catalogs (stored values), and a few stubs/TODOs.

---

## 1. Unsupported-locale fallback

**File:** `lib/main.dart`

```dart
localeResolutionCallback: (locale, supportedLocales) {
  if (locale == null) return const Locale('en');
  for (final supported in supportedLocales) {
    if (supported.languageCode == locale.languageCode) {
      return supported;
    }
  }
  return const Locale('en');
},
```

| Locale | Result |
|--------|--------|
| `en` / `en_*` | English |
| `tr` / `tr_*` | Turkish |
| Unsupported (e.g. `de`) | English |
| `null` | English |

Device-locale behavior for `en`/`tr` is preserved.

---

## 2. ARB keys

| Metric | Value |
|--------|------:|
| Keys before (3P-A1) | 48 |
| Keys after (3P-A2) | **253** |
| Keys added | **~205** |
| `app_en.arb` / `app_tr.arb` | Matched |

Coverage added for: common actions, nav, welcome/phone/login, discover, messages/chat, settings, about/help legal **labels**, profile shell/setup chrome, compatibility labels/reasons, help FAQ.

---

## 3. Screens / features localized

| Area | Status |
|------|--------|
| Bottom nav (`main_navigation_screen.dart`) | Localized |
| Welcome / phone signup / login | Localized |
| Discover + match dialog + empty/error | Localized |
| Compatibility labels/reasons (keys → UI) | Localized |
| Messages list + chat detail menus/dialogs | Localized |
| Settings + logout confirm | Localized |
| About / Help FAQ / Privacy / Notifications / Blocked | Localized (labels + FAQ) |
| Profile shell / name selection / photo edit | Localized |
| Profile setup title/continue/finish + validation | Localized |
| Profile step **chrome** titles (basic/bio/interests/lifestyle/preferences) | Localized |
| Success dialog continue button | Localized |

---

## 4. Files changed (primary)

**Infrastructure / l10n**

- `lib/main.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_tr.arb`
- Generated: `lib/l10n/app_localizations*.dart` (via `flutter gen-l10n`)

**Shell / auth / discover / messages**

- `lib/core/navigation/main_navigation_screen.dart`
- `lib/core/widgets/success_dialog.dart`
- `lib/core/utils/compatibility_scoring.dart` (stable keys only; no scoring math change)
- `lib/features/auth/screens/welcome_screen.dart`
- `lib/features/auth/screens/phone_signup_screen.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/discover/screens/discover_screen.dart`
- `lib/features/messages/screens/messages_screen.dart`
- `lib/features/messages/screens/chat_detail_screen.dart`

**Settings**

- `lib/features/settings/screens/settings_screen.dart`
- `lib/features/settings/screens/about_screen.dart`
- `lib/features/settings/screens/help_support_screen.dart`
- `lib/features/settings/screens/privacy_settings_screen.dart`
- `lib/features/settings/screens/notifications_settings_screen.dart`
- `lib/features/settings/screens/blocked_users_screen.dart`

**Profile**

- `lib/features/profile/screens/profile_screen.dart`
- `lib/features/profile/screens/profile_setup_screen.dart`
- `lib/features/profile/screens/name_selection_screen.dart`
- `lib/features/profile/screens/profile_photo_edit_screen.dart`
- `lib/features/profile/screens/steps/basic_info_step.dart` (titles/labels)
- `lib/features/profile/screens/steps/bio_step.dart`
- `lib/features/profile/screens/steps/interests_step.dart` (title/counter)
- `lib/features/profile/screens/steps/lifestyle_step.dart` (title/subtitle)
- `lib/features/profile/screens/steps/preferences_step.dart` (title/subtitle/looking-for label)

**Docs**

- `docs/full_app_localization_p0_patch_report.md` (this file)

---

## 5. Audit script remaining counts

`python3 scripts/audit_flutter_localization.py` (heuristic):

| Priority | 3P-A1 baseline | After 3P-A2 |
|----------|---------------:|------------:|
| **P0** | 233 | **103** |
| **P1** | (in audit doc ~est.) | **4** |
| **P2** | (debug) | **35** |
| Total findings | — | **142** |

### Remaining P0 (real vs noise)

**Still real / deferred intentionally**

- Secondary email auth: `email_signup_screen`, `email_verification_screen`, `signup_screen`, `verification_screen`, `social_login_screen` (phone is primary funnel)
- Profile setup **option catalogs** still Turkish storage values (gender, education, looking-for, lifestyle dropdowns, interest tags) — needs bilingual display map without breaking Firestore values → **Phase 3P-A3**
- Location helper copy in `basic_info_step` (permission / “sharing location” strings)
- `main_app_screen.dart` stub copy (if still reachable)
- A few settings MVP TODO footnotes still Turkish

**Often noise / non-user chrome**

- `auth_service.dart` callback/log-style strings flagged by Turkish-char heuristic
- Debug row labels on Settings (`kDebugMode` only) counted in settings P0 sample but production-gated

### P1 deferred

- Full bilingual profile option/interest catalogs + data migration strategy
- Secondary email/social auth polish
- In-app language switcher (not required for device-locale global behavior)

### P2 deferred

- Debug / Assessment Admin strings (intentionally English, `kDebugMode` gated)

---

## 6. Legal / help / privacy / terms status

| Item | Status |
|------|--------|
| Privacy Policy **label** | Localized as `privacyPolicyTodo` — **no real policy content** |
| Terms of Use **label** | Localized as `termsOfUseTodo` — **no real terms content** |
| Help FAQ | Localized EN/TR |
| Contact support | Localized TODO placeholder (`helpSupportContactTodo`) |
| Real legal URLs / documents | **Deferred → Phase 3P-A4** |

---

## 7. Debug / admin exclusion

| Check | Result |
|-------|--------|
| Debug routes registered only in `kDebugMode` | Unchanged / confirmed in `main.dart` |
| Settings → Debug entry | Still `kDebugMode` only; left English intentionally |
| Assessment Admin / dry-run strings | Not modified; remain P2 |
| Production users cannot reach admin in release | Confirmed by prior RC1 / unchanged gating |

---

## 8. Assessment localization confirmation

| Item | Result |
|------|--------|
| Assessment JSON | **Not edited** |
| Scoring | **Not edited** (compatibility scoring returns stable **display keys** only; weights unchanged) |
| `AssessmentLanguage` | **Unchanged** |
| `LocalizedTextResolver` | **Unchanged** |
| `validate_assessment_sets.py` | **PASS** |
| `audit_assessment_content_quality.py` | **PASS WITH NOTES** (pre-existing TR `biri` notes; IQ/EQ content not touched this phase) |

---

## 9. Validation commands run

```text
flutter gen-l10n
flutter analyze  → No issues found (P0-touched scopes)
python3 scripts/validate_assessment_sets.py  → PASS
python3 scripts/audit_assessment_content_quality.py  → PASS WITH NOTES
python3 scripts/audit_flutter_localization.py  → P0=103, P1=4, P2=35
```

---

## 10. Recommended next phase

**Phase 3P-A3 — Profile option catalog + secondary auth localization**

1. Introduce stable option IDs (or display maps) for gender/education/looking-for/lifestyle/interests without breaking existing Turkish Firestore values.
2. Localize remaining email/social auth screens.
3. Clear remaining location / stub chrome strings.
4. Re-run localization audit; target P0 &lt; 40 for true user chrome.

**Phase 3P-A4 — Legal / support content**

Ship real Privacy Policy / Terms destinations and a real support contact path (replace TODO labels).

---

## Constraints respected

- No commit / push
- No Firestore writes
- No assessment JSON edits
- No UI redesign
- No final legal policy body text
- Debug/admin left debug-only
