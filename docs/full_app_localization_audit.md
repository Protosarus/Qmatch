# Full App Localization Audit (Phase 3P-A1)

**Date:** 2026-07-17
**Mode:** Diagnostic only — no UI/ARB/runtime edits, no Firestore writes, no commit/push
**Scope:** Production user-facing Flutter UI + assessment localization + debug exclusion
**Tooling:** Manual code review + read-only `scripts/audit_flutter_localization.py`

---

## Executive summary

Qmatch has a **working Flutter l10n pipeline for assessment chrome** (`en` + `tr` ARB → `AppLocalizations`), and **assessment question/option content** resolves by locale from bundled JSON.

However, **most of the rest of the production app does not use `AppLocalizations`**. UI chrome is split by feature:

| Area | Hardcoded language | Effect |
|------|-------------------|--------|
| Auth funnel | English | Turkish-locale users see English welcome/login/phone/signup |
| Bottom nav + Settings + Profile setup | Turkish | English-locale users see Turkish shell |
| Discover | Mixed (TR title, EN body/actions) | Both locales see wrong language on parts of the screen |
| Messages / chat | Mixed (TR title, EN body/actions) | Same split-brain pattern |
| Assessment intro/test/result | Localized via ARB + content maps | **OK for RC1** |

**Global localization readiness verdict: NOT READY for a global English+Turkish launch** until P0 chrome is moved into ARB/`AppLocalizations`. Assessment content itself is publish-ready; **app chrome is the blocker**, not assessment JSON.

---

## Overall readiness verdict

| Layer | Verdict |
|-------|---------|
| Localization infrastructure | **Partial PASS** — `en`/`tr` supported; no `localeResolutionCallback`; ARB coverage thin |
| Assessment content + chrome | **PASS** (with notes) |
| Production UI chrome | **FAIL** — widespread hardcoded EN/TR |
| Debug/admin production safety | **PASS** — `kDebugMode` gated |
| Legal / help / privacy / terms | **FAIL / incomplete** — TODO placeholders |

---

## 1. Localization infrastructure

### Setup

| Item | Status |
|------|--------|
| `pubspec.yaml` → `flutter_localizations` + `generate: true` | Present |
| `l10n.yaml` | `arb-dir: lib/l10n`, template `app_en.arb`, class `AppLocalizations` |
| Generated files | `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart` |
| `MaterialApp.localizationsDelegates` | Set in `lib/main.dart` |
| `MaterialApp.supportedLocales` | `Locale('en')`, `Locale('tr')` |
| `localeResolutionCallback` | **Not set** (Flutter default: device locale if supported, else first supported = `en`) |
| Explicit in-app language switch | **None** |

### ARB coverage

| Metric | Value |
|--------|------:|
| Keys in `app_en.arb` / `app_tr.arb` | **48 / 48** (matched) |
| Domains covered | Photos + assessment intro/test/Likert/result chrome |
| Domains missing | Auth, discover, messages, settings, profile shell, nav, legal |

### Parallel / dead helper

`lib/core/localization/app_strings.dart` — device-locale TR/EN helper for photo strings. **Largely unused**; photo edit screen hardcodes Turkish instead of ARB/`AppStrings`.

### Fallback behavior (expected)

| Device/app locale | UI ARB | Assessment content |
|-------------------|--------|--------------------|
| `tr` | Turkish keys (where wired) | `question.tr` / `label.tr` |
| `en` | English keys (where wired) | `question.en` / `label.en` |
| Unsupported (e.g. `de`) | Falls to first supported / EN via Flutter + assessment `AssessmentLanguage` → `en` | English |

---

## 2. Hardcoded string findings

### Automated heuristic scan

`python3 scripts/audit_flutter_localization.py`:

| Metric | Count |
|--------|------:|
| Total string hits (heuristic) | **272** |
| Priority P0 (heuristic) | **233** |
| Priority P1 (heuristic) | **4** |
| Priority P2 (debug) | **35** |

> Heuristic overcounts some non-UI / false language tags. Curated production counts below are the planning source of truth.

### Curated production findings (by feature)

| Feature | Approx. user-facing hardcoded strings | Dominant hardcoded lang | Uses `AppLocalizations`? |
|---------|--------------------------------------:|-------------------------|--------------------------|
| Auth | ~60+ | EN | No |
| Profile (setup + display + photos + steps) | ~80+ | TR | No |
| Settings (+ help/about/privacy/notifications/blocked) | ~45 | TR | No |
| Messages / chat | ~30 | Mixed (title TR, body EN) | No |
| Discover | ~12 (+ EN compatibility labels) | Mixed | No |
| Main / bottom nav | 3 labels | TR | No |
| Core (`SuccessDialog` `DEVAM`, compatibility labels) | ~10 | TR / EN | No |
| Assessment screens | ~0 chrome leftovers | — | **Yes** |
| Debug | many | EN | N/A (P2) |

### Priority counts (curated for planning)

| Priority | Meaning | Est. count | Notes |
|----------|---------|----------:|-------|
| **P0** | Wrong language for locale on normal user flow | **~180–220** distinct UI strings | Auth EN + shell TR + discover/chat mix |
| **P1** | Mixed UI, unused ARB, maintainability | **~15–25** | Photo ARB unused; resolver maps not in ARB; `Version 1.0.0` |
| **P2** | Debug/admin only | **~35** | Safe if never shipped in release UI |

---

## 3. English-locale risks (phone/app = English)

English users currently still see **Turkish** on:

| Screen / surface | Examples |
|------------------|----------|
| Bottom navigation | `Keşfet`, `Mesajlar`, `Profil` |
| Discover AppBar | `Keşfet` |
| Messages AppBar | `Mesajlar` |
| Settings entire tree | `Ayarlar`, `Bildirimler`, `Gizlilik`, `Çıkış Yap`, FAQ, About body |
| Profile view / setup / name / photos | `Profil Oluştur`, `DEVAM`, `Hakkımda`, lifestyle dropdowns |
| Success dialogs | `DEVAM` |
| Stored profile option values | e.g. `Erkek`, `Ciddi İlişki` shown as chips |

**Top EN-locale P0 files to patch first:**
1. `lib/core/navigation/main_navigation_screen.dart`
2. `lib/features/settings/screens/*.dart`
3. `lib/features/profile/screens/**/*.dart`
4. `lib/core/widgets/success_dialog.dart`
5. `lib/features/discover/screens/discover_screen.dart` (title)

---

## 4. Turkish-locale risks (phone/app = Turkish)

Turkish users currently still see **English** on:

| Screen / surface | Examples |
|------------------|----------|
| Welcome / phone / login / signup / verification | Entire auth funnel |
| Discover empty + actions | `No compatible profiles yet.`, `Retry`, `Pass`, `Like`, match dialog |
| Chat safety menus / snackbars | `Report`, `Unmatch`, `Block`, `Message…` |
| Messages empty/error body | English under Turkish title |
| Compatibility chips | `Exceptional match`, `Strong match`, reason strings |

**Top TR-locale P0 files to patch first:**
1. `lib/features/auth/screens/*.dart` (especially `welcome_screen.dart`, `phone_signup_screen.dart`)
2. `lib/features/discover/screens/discover_screen.dart`
3. `lib/features/messages/screens/chat_detail_screen.dart`
4. `lib/features/messages/screens/messages_screen.dart`
5. `lib/core/utils/compatibility_scoring.dart`

---

## 5. Assessment localization verdict — PASS

| Check | Result |
|-------|--------|
| IQ questions/options from `{en,tr}` maps | Yes (`LocalizedTextResolver`) |
| EQ questions/options | Yes |
| Frequency statements | Yes |
| Frequency Likert chrome | App l10n (`stronglyDisagree`…`stronglyAgree`) |
| Intro / nav buttons | App l10n |
| Result / archetype titles & tags | `AssessmentResultDisplayResolver` EN/TR maps |
| Unsupported locale → English | `AssessmentLanguage` falls back to `en` |
| Runtime source when Firestore empty | `bundled_assets` (confirmed in prior QA logs) |
| Assessment content regression in this phase | **None** (assets not edited) |

**Note (P1 maintainability):** Archetype strings live in Dart maps, not ARB. Works at runtime; migrate later for consistency.

---

## 6. Debug / admin production-safety verdict — PASS

| Control | Status |
|---------|--------|
| Debug routes registered only when `kDebugMode` | Yes (`main.dart`) |
| Settings → Debug row only in debug | Yes |
| `DebugHomeScreen` / `AssessmentAdminScreen` refuse outside debug | Yes |
| Reset helpers refuse outside `kDebugMode` | Yes |
| Firestore sync default dry-run; writes gated | Yes |
| No production write button | Yes |

Debug English strings are **P2** and do **not** block global launch.

---

## 7. Legal / help / privacy / terms findings

| Screen | Finding | Priority |
|--------|---------|----------|
| `about_screen.dart` | Body Turkish; links shown as `Gizlilik Politikası (TODO)` / `Kullanım Şartları (TODO)` — **no real URLs** | **P0 legal** |
| `help_support_screen.dart` | FAQ Turkish; `TODO: Uygulama içi destek talebi veya e-posta bağlantısı ekle.` | **P0/P1** |
| `privacy_settings_screen.dart` | UI Turkish toggles; comments/TODO for persistence | P1 |
| `notifications_settings_screen.dart` | UI Turkish; TODO for wiring | P1 |
| Welcome auth legal line | English “Terms / Privacy” text without verified destinations | P0/P1 |

**No dedicated Terms/Privacy WebView or hosted policy link wired in production settings.**

---

## 8. Findings by feature (representative P0)

### Auth (hardcoded EN)
- `welcome_screen.dart` — `Match minds.`, `Continue with phone`, `Log in`, terms line
- `phone_signup_screen.dart` — `What's your number?`, `Send code`, `Verify`, validation errors
- `login_screen.dart` / `signup_screen.dart` / `social_login_screen.dart` / email flows — full EN chrome

### Discover (mixed)
- Title `Keşfet` (TR)
- `No compatible profiles yet.` / `Retry` / `Pass` / `Like` / `It's a match` (EN)

### Messages (mixed)
- Title `Mesajlar` (TR)
- Empty/error EN; chat `Report` / `Unmatch` / `Block` / snackbars EN

### Profile (hardcoded TR)
- Setup, name, photos, bio, interests, lifestyle, preferences — nearly all TR
- Photo edit ignores existing ARB keys

### Settings (hardcoded TR)
- Full menu + logout dialog TR
- Help FAQ TR; About TR + legal TODO

### Core
- Nav labels TR
- `SuccessDialog` → `DEVAM`
- `compatibility_scoring.dart` labels EN

---

## 9. Recommended patch plan

### Phase 3P-A2 — P0 localization fixes (must before global EN launch)
1. Add ARB keys for bottom nav, settings shell, profile chrome, auth funnel, discover empty/actions, chat safety strings, compatibility labels.
2. Wire screens to `AppLocalizations.of(context)`.
3. Add `localeResolutionCallback` documenting unsupported → `en`.
4. Prefer not changing stored profile enum **values** yet; localize **display** layer first (or dual-write later).

### Phase 3P-A3 — P1 polish
1. Migrate photo edit to existing ARB / remove dead `AppStrings` or unify.
2. Move archetype display strings toward ARB.
3. Soften remaining mixed screens; snackbar/error consistency.

### Phase 3P-A4 — Legal / help / support cleanup
1. Replace TODO Privacy/Terms with real URLs or in-app documents (EN+TR).
2. Add support email / contact path.
3. Localize About/Help fully.

### Phase 3P-A5 — Final EN/TR runtime QA
1. Device `en` + `tr` passes on auth → assessments → discover → chat → settings.
2. Confirm no language leakage; overflow checks; assessment logs `resolvedFrom=en|tr`.

---

## 10. Files most likely to need editing next (3P-A2)

1. `lib/l10n/app_en.arb` + `app_tr.arb`
2. `lib/core/navigation/main_navigation_screen.dart`
3. `lib/features/auth/screens/welcome_screen.dart`
4. `lib/features/auth/screens/phone_signup_screen.dart`
5. `lib/features/discover/screens/discover_screen.dart`
6. `lib/features/messages/screens/chat_detail_screen.dart`
7. `lib/features/messages/screens/messages_screen.dart`
8. `lib/features/settings/screens/settings_screen.dart`
9. `lib/features/profile/screens/profile_setup_screen.dart` + steps
10. `lib/core/utils/compatibility_scoring.dart`
11. `lib/core/widgets/success_dialog.dart`
12. `lib/main.dart` (optional `localeResolutionCallback`)

**Do not touch for chrome localization:** assessment JSON assets, scoring indexes, Firestore helpers.

---

## 11. Validation snapshot (this phase)

Commands:

```bash
flutter analyze
python3 scripts/validate_assessment_sets.py
python3 scripts/audit_assessment_content_quality.py
python3 scripts/audit_flutter_localization.py
```

Results recorded in session notes (expected: analyze clean; assessment validator PASS; content audit PASS WITH NOTES; localization scanner read-only).

---

## 12. Confirmations

- No UI text fixed in this phase
- No ARB content expanded (except tooling script)
- No assessment JSON edits
- No Firestore writes
- No commit / push

**Next step:** Phase **3P-A2** — implement P0 ARB keys and wire highest-traffic screens (nav, auth, discover, chat, settings, profile shell).
