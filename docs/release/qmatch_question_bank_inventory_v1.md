# QMatch Question Bank Inventory v1

Phase: **P2C-0** · Counts derived from files on disk · HEAD `4bbd6cb`

---

## Summary counts

| category | count |
|----------|------:|
| Question bank artifacts found (runtime + offline + fixtures + flat) | **18+** (see tables) |
| Runtime-loadable via pubspec / AssessmentSetService path | **5** (`iq_sets`, `eq_sets`, `frequency_sets`, flat IQ, flat EQ) |
| Non-runtime (v3 pilots/candidates + fixtures + generators) | **12+** |
| PDFs/DOCX question sources in repo | **0** |
| Production Core Method v3 banks wired to screens | **0** |

---

## A. Runtime / production banks

| path | module | count | schema | pubspec | QuestionService / loader | screens | status |
|------|--------|------:|--------|---------|--------------------------|---------|--------|
| `assets/data/assessment_sets/iq_sets.json` | iq | 50 sets × 10 = **500** items | legacy `2026_01` | yes (`assessment_sets/`) | `AssessmentSetService` | `iq_test_screen` | LEGACY_ACTIVE |
| `assets/data/assessment_sets/eq_sets.json` | eq | 50 × 10 = **500** | legacy | yes | same | `eq_test_screen` | LEGACY_ACTIVE |
| `assets/data/assessment_sets/frequency_sets.json` | frequency | 50 × 12 = **600** | legacy | yes | `FrequencyService` | `frequency_test_screen` | LEGACY_ACTIVE |
| `assets/data/iq_questions.json` | iq | **10** | flat legacy | yes | emergency fallback | via set service | LEGACY_ACTIVE |
| `assets/data/eq_questions.json` | eq | **12** | flat legacy | yes | emergency fallback | via set service | LEGACY_ACTIVE |
| Firestore `assessment_sets/{id}` | all | unknown remote | set docs | n/a | priority 1 | all three | RUNTIME_WIRED_UNVERIFIED / UNKNOWN content |
| Firestore `questions/{id}` | iq/eq | unknown | legacy | n/a | last-resort | via set service | LEGACY_ACTIVE |
| `FrequencyService.getFrequencyQuestions()` | frequency | **12** hardcoded | none | n/a | fallback | frequency screen | LEGACY_ACTIVE / DUPLICATED |

### Load priority (`assessment_set_service.dart`)

1. Firestore `assessment_sets`  
2. Bundled `assessment_sets/*_sets.json`  
3. Legacy Firestore `questions`  
4. Flat `iq_questions.json` / `eq_questions.json` (IQ/EQ)

---

## B. Schema-v3 pilots / review candidates (offline)

| path | module | count | pubspec | runtime | status |
|------|--------|------:|---------|---------|--------|
| `assets/data/assessment_v3/iq/iq_pilot_tr_v1.json` | iq | **25** | no | no | IMPLEMENTED_OFFLINE |
| `.../iq/iq_pilot_tr_v1_review_candidate_1.json` | iq | **25** | no | no | IMPLEMENTED_OFFLINE |
| `.../eq/eq_pilot_tr_v1.json` | eq | **30** | no | no | IMPLEMENTED_OFFLINE |
| `.../eq/eq_pilot_tr_v1_review_candidate_1.json` | eq | **30** | no | no | IMPLEMENTED_OFFLINE |
| `.../frequency/frequency_pilot_tr_v1.json` | frequency | **50** | no | no | IMPLEMENTED_OFFLINE |
| `.../frequency/frequency_pilot_tr_v1_review_candidate_1.json` | frequency | **50** | no | no | IMPLEMENTED_OFFLINE |

Freeze manifest (`p2a_assessment_engineering_freeze_manifest_v1.json`):  
`runtime_loaded: false`, `production_wired: false` for these banks.  
`lib/` contains **zero** references to `assessment_v3` / `review_candidate`.

---

## C. Explicit product questions

| question | answer | status |
|----------|--------|--------|
| Final **340**-question IQ bank as runtime JSON? | **No** — artifact absent. Plan docs target **150–240**, not 340. Closest live inventory is 500 unique items across 50×10 legacy sets. | NOT_STARTED |
| Is 25-question IQ pilot runtime-loaded? | **No** | IMPLEMENTED_OFFLINE |
| Is EQ review candidate 1 runtime-loaded? | **No** | IMPLEMENTED_OFFLINE |
| Is Frequency review candidate 1 runtime-loaded? | **No** | IMPLEMENTED_OFFLINE |
| Which bank do users currently see? | Assigned legacy set: **10 IQ / 10 EQ / 12 Frequency** (Firestore if present, else bundled sets) | LEGACY_ACTIVE |

---

## D. Dynamic IQ session composition

| capability | production-called? | status |
|------------|-------------------|--------|
| 7 logical / 6 pattern / 6 verbal / 6 spatial | no (pilot fixed forms only) | DESIGNED_ONLY |
| Difficulty / option-position balancing | no runtime balancer | DESIGNED_ONLY |
| Template-family / history exclusion | no | DESIGNED_ONLY |
| Anchor policy | pilot metadata only | IMPLEMENTED_OFFLINE |
| Live behavior | pick one prebuilt 10-item set + shuffle | LEGACY_ACTIVE |

---

## E. Fixtures / generators (non-runtime)

Trait-scoring fixtures under `test/fixtures/trait_scoring/`.  
Generators: `tool/generate_*_pilot*`, `tool/generate_*_review_candidate*`,  
`scripts/generate_*_sets_50.py`, batch rewrite scripts.  
**PDFs/DOCX:** none in repository.
