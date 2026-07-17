# Assessment Content RC1 — Local Runtime QA

**Phase:** 3O-A2
**RC:** Assessment Content RC1
**Date:** 2026-07-17
**Mode:** Diagnostic / manual QA only — no assessment JSON edits, no Firestore publish/write, no commit/push

Related docs:
- `docs/assessment_content_release_candidate.md`
- `docs/assessment_final_content_audit.md`
- `docs/assessment_data_architecture.md`

---

## 1. Code-verified runtime verdicts (pre-manual)

### 1.1 Runtime source priority — PASS

Implemented in `AssessmentSetService` (`lib/features/assessment/services/assessment_set_service.dart`):

1. Firestore `assessment_sets` (valid, non-empty; for random pick also `active == true`)
2. Bundled localized `assets/data/assessment_sets/{iq,eq,frequency}_sets.json` → `source=bundled_assets`
3. Legacy Firestore `questions/{setId}` → last resort
4. Flat legacy `iq_questions.json` / `eq_questions.json` → emergency, IQ/EQ only

**When Firestore `assessment_sets` is empty or not published yet:** the app falls through to **bundled localized assets**. That is the expected RC1 QA path.

### 1.2 Locale behavior — PASS

| Piece | Behavior |
|-------|----------|
| Supported languages | `en`, `tr` via `AssessmentLanguage` |
| Unsupported locale | Falls back to **`en`** |
| Question text | `LocalizedTextResolver.resolve` on `{en,tr}` maps |
| IQ/EQ options | `label.{en,tr}` via `resolveOptionLabels` |
| Frequency questions | Localized `{en,tr}` question text only |
| Frequency Likert chrome | App l10n (`stronglyDisagree` … `stronglyAgree`), not set options |

### 1.3 Assignment behavior — PASS

| Behavior | Verified in code |
|----------|------------------|
| One persisted set per type | `users/{uid}/assessment_assignments/{iq\|eq\|frequency}` |
| Survives restart | Reuses existing assignment `set_id` |
| Stable question order | `question_order` written once at assign |
| Stable option order | `option_orders` for IQ; EQ/Frequency typically `{}` |
| Completed protected | Legacy recovery skipped when `completed == true` |
| Debug reset | `AssessmentAssignmentResetHelper` — current user only; never touches global `assessment_sets` |

### 1.4 RC1 content presence in bundled assets — PASS

Static check of the same files the runtime loads:

| Check | Result |
|-------|--------|
| EQ unique EN stems | **500 / 500** |
| EQ “Withdraw affection…” caricature | **0** |
| EQ “Acknowledge the…” patterned wins | **0** |
| Frequency abstract EN heuristic hits | **0** |
| Frequency UX length overs | **0** |
| Polish markers present | “Pull back…”, “Yeni tanıştığın kişi…”, “şart değil…” |
| IQ file | Present; not edited in polish/publish phases |

### 1.5 Admin safety — PASS

`AssessmentAdminScreen` exposes:
- Firestore Preflight Compare (read-only)
- Versioned v2 Sync **Dry Run** only
- Current-user assignment / full assessment resets

**No** Firestore write/publish/upload button for assessment sets.
`UploadAssessmentSetsHelper.dryRunVersionedV2AssessmentSync()` always uses `dryRun: true`.

---

## 2. Expected debug log markers

In a **debug** build, when an assessment set loads, look for:

```text
[AssessmentLocalization] type=iq set_id=iq_set_0XX source=bundled_assets languageCode=tr firstQuestion=Map resolvedFrom=tr preview="…"
[AssessmentLocalization] type=eq set_id=eq_set_0XX source=bundled_assets languageCode=en firstQuestion=Map resolvedFrom=en preview="…"
[AssessmentLocalization] type=frequency set_id=frequency_set_0XX source=bundled_assets languageCode=tr firstQuestion=Map resolvedFrom=tr preview="…"
```

Also expect:

```text
Assessment assignment: type=… set=… language=…
```

### Source values to accept during RC1 local QA

| `source=` | Meaning | Expected for RC1 local (no Firestore publish) |
|-----------|---------|-----------------------------------------------|
| `bundled_assets` | Bundled RC1 JSON | **Yes — preferred** |
| `firestore_assessment_sets` | Live Firestore docs | Only if collection already has content |
| `firestore_questions_legacy_last_resort` | Old `questions` collection | Should not be primary |
| `bundled_flat_legacy_emergency` | Flat IQ/EQ JSON | Emergency only |

### Locale values

| Marker | Expected |
|--------|----------|
| `languageCode=tr` | Device/app Turkish |
| `languageCode=en` | Device/app English or unsupported-locale fallback |
| `resolvedFrom=tr` | Question map used Turkish key |
| `resolvedFrom=en` | Question map used English key |

**Recommendation (no code change in this phase):** Existing `[AssessmentLocalization]` logs are sufficient for RC1 QA. Optional later: log Frequency Likert source as `l10n` vs set options for clarity.

---

## 3. Manual QA checklist

### Prerequisites

- [ ] Debug build only (`flutter run` / Xcode debug / Android Studio debug)
- [ ] Signed-in test user
- [ ] Firestore `assessment_sets` empty **or** known to be stale — prefer empty so `source=bundled_assets`
- [ ] Do **not** enable `QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC`
- [ ] Do **not** call any write sync API
- [ ] Console/logcat visible for `[AssessmentLocalization]` lines

### A. Launch and open Assessment Admin

1. [ ] Run the app in **debug** mode
2. [ ] Open **Settings**
3. [ ] Tap **Debug** (debug builds only) → **QMatch Debug Mode**
4. [ ] Open **Assessment Admin**
5. [ ] Confirm the screen states there are **no sync/upload/write** actions for publishing sets

### B. Preflight / dry-run only (safe)

1. [ ] Run **Firestore Preflight Compare** (read-only)
2. [ ] Run **Versioned v2 Sync Dry Run**
3. [ ] Confirm UI/logs show dry-run / **no Firestore writes**
4. [ ] Confirm you did **not** see any publish/write success for `assessment_sets`

### C. Reset current-user assessment state

1. [ ] On Assessment Admin, run **Reset My Full Assessment State** (or reset IQ + EQ + Frequency individually)
2. [ ] Confirm this only clears **your** assignment/result fields — not global content
3. [ ] Restart the app once after reset (optional but recommended)

### D. Turkish locale pass

1. [ ] Set device/app locale to **Turkish**
2. [ ] Restart app if needed so locale applies
3. [ ] Reset assessment state again if a prior English assignment exists
4. [ ] Complete **at least 1 IQ set**
   - [ ] All question stems Turkish
   - [ ] All option labels Turkish
   - [ ] **No English** mixed into question/option cards
5. [ ] Complete **at least 1 EQ set**
   - [ ] Scenario + options Turkish
   - [ ] No English option leftovers
6. [ ] Complete **at least 1 Frequency set**
   - [ ] Question text Turkish
   - [ ] Likert labels Turkish (`Kesinlikle katılmıyorum` … `Kesinlikle katılıyorum`)
7. [ ] Check results / archetype / Frequency result labels display in Turkish where localized
8. [ ] Logs show `languageCode=tr`, `resolvedFrom=tr`, `source=bundled_assets`, and `set_id=iq_set_…` / `eq_set_…` / `frequency_set_…`

### E. English locale pass

1. [ ] Set device/app locale to **English**
2. [ ] Reset full assessment state for a clean assignment
3. [ ] Complete **at least 1 IQ set** — English only, no Turkish in stems/options
4. [ ] Complete **at least 1 EQ set** — English only
5. [ ] Complete **at least 1 Frequency set** — English questions + English Likert (`Strongly disagree` … `Strongly agree`)
6. [ ] Results/archetypes show English labels
7. [ ] Logs show `languageCode=en`, `resolvedFrom=en`, `source=bundled_assets`

### F. Assignment stability

1. [ ] Mid-IQ (or after first question), force-quit and relaunch
2. [ ] Confirm same `set_id` and same question sequence resume
3. [ ] For IQ, confirm option order does not reshuffle across restart
4. [ ] After completing a type, confirm Admin reset is required before a new set is assigned (completed assignment not silently replaced)

### G. Mobile layout / overflow

On a small iPhone (or narrow simulator, e.g. iPhone SE):

1. [ ] IQ long stems still fit / scroll without clipping options
2. [ ] EQ scenarios + 4 options readable without overflow
3. [ ] Frequency question card + Likert row readable; no cut-off Turkish text
4. [ ] No horizontal overflow on question cards

### H. Publish / write guardrails

1. [ ] Throughout this QA, Firestore `assessment_sets` was **not** written
2. [ ] No write button used
3. [ ] No dart-define sync flag enabled for write
4. [ ] Dry-run only if sync UI was touched

---

## 4. Pass / fail criteria

| Area | Pass if |
|------|---------|
| Source | Logs show `source=bundled_assets` when Firestore unpublished/empty |
| Turkish | No English in TR assessment cards; Likert TR |
| English | No Turkish in EN assessment cards; Likert EN |
| Assignment | Same set/order after restart; completed not overwritten |
| Content | Feels like polished RC1 (no caricature distractors / no abstract Frequency slogans) |
| Safety | Zero Firestore assessment-set writes |

---

## 5. Automated validation snapshot (this phase)

Run locally:

```bash
python3 scripts/validate_assessment_sets.py
python3 scripts/audit_assessment_content_quality.py
python3 scripts/audit_assessment_firestore_sync.py
flutter analyze
```

Record results in the session notes. Expected (RC1):
- Validator: **PASS**
- Content audit: **PASS WITH NOTES** (remaining TR flags = IQ math false positives + idiomatic EQ)
- Firestore sync audit: **PASS** dry-run, no writes
- flutter analyze: clean

---

## 6. Recommended next phase

**Phase 3O-A3 / controlled Firestore publish decision** — only after this manual checklist is signed off for both locales.

Not automatic. Prefer immutable `*_v2` document IDs. Do not overwrite legacy `iq_set_001` in place.

---

## 7. Session attempt — 2026-07-17 ~22:52 +03

| Step | Status | Notes |
|------|--------|-------|
| 1. Debug run | **Done** | `flutter run` on iPhone 16e simulator; app launched signed-in on Discover |
| Simulator locale | **Set** | `AppleLanguages=tr-TR`, `AppleLocale=tr_TR` |
| 2–4. Admin / preflight / reset | **Blocked** | macOS Accessibility permission denied for automated Simulator taps (`osascript` -1719) |
| 5–10. TR/EN assessment flows + logs | **Not run** | Needs human navigation in Simulator; no `[AssessmentLocalization]` lines yet |
| Screenshot | Captured | `build/qa_screen_01.png` — Discover empty state (hardcoded EN copy in `discover_screen.dart`, **not** an assessment locale signal) |

**Agent limitation:** Without Accessibility (or Flutter Driver / DTD widget tree), the agent cannot open Settings → Debug → Assessment Admin or complete IQ/EQ/Frequency taps. Interactive QA must be finished on the running Simulator; agent can then scrape the `flutter run` console for `source=` / `languageCode=` / `resolvedFrom=` markers.
