# QMatch IQ Source Inventory v1

**Phase:** P2C-2A-0  
**HEAD:** `4bbd6cb` (at audit start)  
**Method:** Parsed structured files on disk; counts are not inferred from filenames alone.  
**Machine report:** `assets/data/assessment_v3/iq/reports/iq_source_inventory_v1_report.json`

---

## Executive summary

| Question | Answer |
|----------|--------|
| Runtime IQ bank users see today | Legacy **10-item** sets via Firestore / `iq_sets.json` |
| Canonical 25-item pilot | Exists offline; **not** pubspec-registered; **not** production-reachable |
| Canonical 340-item bank | **Recovered offline** — content **FOUND_RECOVERABLE**; JSON **IMPLEMENTED_OFFLINE**; runtime **NOT_STARTED** |
| PDFs / DOCX recoverable banks | Source package preserved under `docs/source/assessment/iq/` |

**Honest statement:** The canonical 340-item IQ bank exists as validated offline JSON recovered from the verified DOCX source. It is **not** runtime-wired, **not** RELEASE_READY, and must not be treated as expert-reviewed or calibrated.

---

## Sources (parsed)

### 1. `assets/data/assessment_sets/iq_sets.json`

| Field | Value |
|-------|-------|
| File type | JSON |
| Item count | **500** (50 sets × 10) |
| Unique IDs | 500 |
| Language | Legacy bilingual option labels (`label.en` / `label.tr`) |
| Dimension distribution | **None** — no `primary_dimension` / `dimension` field |
| Difficulty | editorial ints: 1→150, 2→200, 3→150 |
| Answer keys | yes (`correctAnswer`) |
| Explanations | **no** |
| Runtime-loaded | **yes** |
| Pubspec | yes (`assets/data/assessment_sets/`) |
| Production reachable | **yes** |
| Classification | `legacy_runtime` |
| Duplicate IDs | no |
| Near-duplicate prompts | not treated as canonical; legacy bank may contain template families |
| Retired `numerical` | not as a dimension field |
| Can contribute to canonical bank | **No** without full re-authoring + schema migration + review |
| Confidence | high |

### 2. `assets/data/iq_questions.json`

| Field | Value |
|-------|-------|
| Item count | **10** |
| Classification | `legacy_runtime_fallback` |
| Runtime / pubspec / production | yes / yes / yes |
| Dimensions | none |
| Answer keys | yes |
| Explanations | no |
| Can contribute | **No** (emergency flat bank) |
| Confidence | high |

### 3. `assets/data/assessment_v3/iq/iq_pilot_tr_v1.json`

| Field | Value |
|-------|-------|
| Item count | **25** |
| Locale | `tr-TR` |
| Dimensions | logical **7** / pattern **6** / verbal **6** / spatial **6** |
| Difficulty encoding | easy=2 (8), medium=3 (12), hard=4 (5) |
| Answer keys | yes (`correct_option_id`) |
| Rationales | yes (`solution_method` on all 25) |
| Runtime-loaded | **no** |
| Pubspec | **no** (`assessment_v3` not registered) |
| Production reachable | **no** |
| Classification | `pilot_offline` |
| Duplicate IDs / prompts | none |
| Retired `numerical` | no |
| Can contribute | **Yes** as seed / review corpus (not auto-import without promotion) |
| Confidence | high |

### 4. `assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json`

| Field | Value |
|-------|-------|
| Item count | **25** |
| Classification | `candidate_offline` |
| Runtime / pubspec / production | no / no / no |
| Dimensions | 7/6/6/6 |
| Status | `internal_review` |
| Can contribute | Yes as reviewed candidate lineage |
| Confidence | high |

### 5. `test/fixtures/trait_scoring/valid_iq_bank.json`

| Field | Value |
|-------|-------|
| Item count | **16** |
| Classification | `test_fixture` |
| Runtime | no |
| Can contribute | no |

### 6. `assets/data/assessment_v3/iq/iq_bank_tr_v1.json`

| Field | Value |
|-------|-------|
| Item count | **340** |
| Locale | `tr-TR` |
| Dimensions | logical **100** / pattern **80** / verbal **80** / spatial **80** |
| Template families | **170** (exactly 2 variants each) |
| Rewritten v2 | **40** |
| Answer keys | yes (`correct_option_id` a/b/c/d) |
| Runtime-loaded | **no** |
| Pubspec | **no** |
| Production reachable | **no** |
| Classification | `canonical_recovered_offline` |
| Source package | `docs/source/assessment/iq/QMatch_Bilissel_Muhakeme_Soru_Bankasi_v2_340.{docx,pdf}` |
| Existing content status | **FOUND_RECOVERABLE** |
| Canonical JSON status | **IMPLEMENTED_OFFLINE** |
| Runtime IQ integration | **NOT_STARTED** |
| Confidence | high |

### 7. Tooling / docs (non-bank)

| Path | Role |
|------|------|
| `tool/assessment/convert_iq_bank_v2.py` | DOCX → canonical JSON converter |
| `tool/assessment/validate_iq_bank_v1.py` | Strict recovered-bank validator |
| `tool/assessment/crosscheck_iq_bank_pdf_v1.py` | Secondary PDF cross-check |
| `tool/validate_iq_pilot_v1.dart` | Offline pilot validator |
| `tool/generate_iq_pilot_tr_v1.py` | Pilot generator history |
| `scripts/generate_iq_sets_50.py` | Legacy set generator |
| `docs/core_engine/iq_pilot_tr_v1_*.md` | Pilot quality / red-team / provenance |
| `docs/release/qmatch_question_bank_inventory_v1.md` | Prior inventory (P2C-0) |
| `docs/assessment/qmatch_iq_bank_conversion_report_v1.md` | P2C-2A-1 conversion report |

### 8. Dart constants / screens

| Path | Role | Runtime questions? |
|------|------|--------------------|
| `lib/features/assessment/services/question_service.dart` | Loads IQ sets | yes (legacy) |
| `lib/features/assessment/services/assessment_set_service.dart` | Set assignment | yes |
| `lib/features/assessment/screens/iq_test_screen.dart` | UI | yes (10) |
| `lib/features/assessment/services/iq_recovery.dart` | Score recovery metadata | no bank |
| `lib/features/assessment/domain/iq_bank/*` | Canonical contract + recovered parser | **no** |

---

## Count rollup (structured JSON only)

| Classification | Items |
|----------------|------:|
| legacy_runtime | 500 |
| legacy_runtime_fallback | 10 |
| pilot_offline | 25 |
| candidate_offline | 25 |
| test_fixture | 16 |
| canonical_recovered_offline | 340 |
| **Canonical 340 unique (offline)** | **340** |
| **Canonical 340 runtime-wired** | **0** |

---

## 340-item claim

**Existing question content: FOUND_RECOVERABLE**  
**Canonical JSON: IMPLEMENTED_OFFLINE**  
**Runtime IQ integration: NOT_STARTED**  
**Dynamic 25-question session: NOT_STARTED**  
**Psychometric calibration: NOT_STARTED**  
**Expert review: NOT_STARTED**

Evidence (P2C-2A-1):

1. Source DOCX/PDF preserved under `docs/source/assessment/iq/`.
2. `iq_bank_tr_v1.json` present with 340 validated items (not in pubspec).
3. Conversion did not generate or rewrite question wording.
4. Production still loads legacy 10-item sets; bank is not RELEASE_READY.
5. Missing per-item difficulty/rationale/subskill/psychometrics were **not** fabricated.

See `docs/assessment/qmatch_iq_bank_conversion_report_v1.md`.
