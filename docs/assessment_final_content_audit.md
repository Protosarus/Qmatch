# Assessment Final Content Audit (Phase 3N-A1)

**Date:** 2026-07-17
**Scope:** Bundled assets only (`assets/data/assessment_sets/{iq,eq,frequency}_sets.json`)
**Mode:** Diagnostic only — no assessment JSON edits, no Firestore writes, no scoring/runtime changes
**Tooling:** `scripts/audit_assessment_content_quality.py`, `scripts/validate_assessment_sets.py`, `scripts/audit_assessment_firestore_sync.py`

---

## Executive summary

After the EQ rewrite (Phase 3L) and Frequency rewrite (Phase 3M), the assessment bank is **structurally valid, fully localized, and publish-ready with notes**. Remaining automated flags are mostly **heuristic noise** (IQ math “biri”) or **light EQ/Frequency phrasing polish**, not structural blockers.

| Assessment | Questions | Verdict | Notes |
|------------|----------:|---------|-------|
| **IQ** | 500 | **Publish-ready** | Unique stems; short options; 50 false-positive `biri` flags on odd-one-out helper text |
| **EQ** | 500 | **Publish-ready with light polish** | 500 unique situations; UX 0; leftover `biri`/`şey` + a few distractor/model-answer flags |
| **Frequency** | 600 | **Publish-ready with minor notes** | UX 0; abstract/self-report 0; 14 mild `formal_passive` heuristic hits |

### Overall readiness verdict

**PASS WITH NOTES**

No P0 structural blockers remain. Recommended next step is a **targeted light-polish batch (Phase 3N-A2)**, not another full rewrite.

---

## Current global counts

| Category | Count | By type |
|----------|------:|---------|
| `duplicate_near_duplicate` | **0** | — |
| `turkish_quality` | **131** | IQ 50 · EQ 67 · Frequency 14 |
| `english_quality` | **15** | EQ 15 |
| `ux_length` | **0** | — |
| `design_scoring` | **12** | EQ 12 |
| EQ unique situations | **500** | max repeat **1** |
| EQ unique option sets | **500** | — |
| EQ money/pricey scenarios | **1** | — |
| Frequency abstract/self-report | **0** | — |

Validator: **PASS** (150 sets / 1600 questions; fully localized).
Firestore sync audit: **PASS** (dry run; no writes).

---

## Before / after — Phase 3K → now

Baseline from `docs/assessment_content_quality_audit.md` (Phase 3K):

| Metric | Phase 3K | Now (3N-A1) | Delta |
|--------|---------:|------------:|------:|
| Readiness | FAIL — rewrite recommended | **PASS WITH NOTES** | recovered |
| Duplicate / near-duplicate | 40 | **0** | −40 |
| Turkish quality | 925 | **131** | −794 |
| English quality | 870 | **15** | −855 |
| UX length | 42 | **0** | −42 |
| Design / scoring | 344 | **12** | −332 |
| EQ unique situations | 20 (×25 repeats) | **500** (×1) | fixed |
| EQ unique option sets | 20 | **500** | fixed |
| EQ money/pricey family | 25 | **1** | fixed |
| Frequency abstract/self-report | 194 (in design bucket) | **0** | fixed |

Work that produced the recovery:
- **Phase 3L** — EQ full rewrite (A1–A5)
- **Phase 3M** — Frequency full rewrite (A1–A5)

---

## Readiness by assessment type

### IQ — publish-ready

| Check | Result |
|-------|--------|
| Exact duplicate EN stems | 0 / 500 unique |
| UX length flags | 0 |
| English quality flags | 0 |
| Design/scoring flags | 0 |
| Turkish quality flags | 50 — all `generic_biri` on `*_q08` odd-one-out helper lines |
| Culture/language riddles | 0 keyword hits |
| Question length | EN max 107 / avg ~65; TR max 103 / avg ~69 |
| Option length | EN max 23 / avg ~6; TR max 28 / avg ~7 |
| Difficulty mix | 1:150 · 2:200 · 3:150 |

**IQ analysis**

- **Repetition:** Stem families rotate by type (“Which number comes next?”, shape patterns, codes, odd-one-out) with unique numbers/content per item — expected for an IQ bank, not copy-paste defects.
- **Explanations/options:** Short; mobile-friendly. No audit UX flags.
- **Turkish:** Natural for logic items. The 50 `biri` flags are **false positives** (`Üç sayı X'in katıdır; biri değildir.` = “one of them is not”).
- **English:** Clean, global, non-idiomatic.
- **Answer choices:** Numeric / short labels; not confusing on mobile.
- **Culture risk:** No proverb/pun/locale-dependent riddle pattern detected.

**Verdict:** Mostly publish-ready. Optional micro-polish only (e.g. rephrase IQ helper “biri değildir” → “biri hariç” / “yalnızca biri uymuyor” if flag hygiene is desired).

### EQ — publish-ready with light polish

| Check | Result |
|-------|--------|
| Duplicate / near-duplicate | **0** |
| Unique situations | **500** (max repeat 1) |
| UX length | **0** |
| Literal TR prompt (`En olası tepkin…`) | **0** |
| EN template prompt | **0** |
| Remaining TR flags | 67 (`generic_biri` 54 + `vague_sey` 13) |
| Remaining EN flags | 15 (caricature 9 · moralizing 4 · abstract 2) |
| Remaining design flags | 12 (`obvious_model_answer`) |

**Verdict:** EQ no longer needs a structural rewrite. Remaining issues are **minor phrasing / distractor polish**.

### Frequency — publish-ready with minor notes

| Check | Result |
|-------|--------|
| UX length | **0** |
| Abstract / self-report | **0** |
| Dimension balance | depth / socialEnergy / spontaneity / stability / emotionalOpenness / conversationPace = **100 each** |
| reverseScored | False **450** · True **150** (unchanged 3:1) |
| Remaining TR flags | 14 `formal_passive` (mostly `…zorunda değil` / `…gerekmez` endings) |
| Remaining EN / design | 0 |

**Verdict:** Frequency does not need another rewrite. Remaining flags are **mild heuristic hits** on natural Turkish negation phrasing.

---

## Remaining issues grouped by assessment type

### Turkish quality (131)

| Type | Count | Subtypes | Severity |
|------|------:|----------|----------|
| IQ | 50 | `generic_biri` ×50 | Low — math false positive |
| EQ | 67 | `generic_biri` ×54 · `vague_sey` ×13 | Medium — light polish |
| Frequency | 14 | `formal_passive` ×14 | Low — natural phrasing |

### English quality (15)

| Type | Count | Subtypes | Severity |
|------|------:|----------|----------|
| EQ | 15 | `caricature_option` ×9 · `moralizing_win` ×4 · `abstract_frequency` ×2 | Medium — light polish |
| IQ / Frequency | 0 | — | — |

### Design / scoring (12)

| Type | Count | Risk | Severity |
|------|------:|------|----------|
| EQ | 12 | `obvious_model_answer` | Medium — light polish |
| IQ / Frequency | 0 | — | — |

### UX length / duplicates

None remaining.

---

## Top remaining Turkish issues (with examples)

### 1. IQ `generic_biri` (50) — false positive

| Field | Example |
|-------|---------|
| set_id / question_id | `iq_set_001` / `iq_set_001_q08` |
| language | tr |
| category | turkish_quality / generic_biri |
| current text | `Hangi sayı aynı kurala uymaz? … (Üç sayı 2'nin katıdır; biri değildir.)` |
| suggested fix direction | Optional: “üçü kurala uyar, biri uymaz” / “yalnızca biri uymuyor” — or document as acceptable math Turkish |

Same pattern on **every** `iq_set_XXX_q08` (001–050).

### 2. EQ `generic_biri` (54)

| Field | Example |
|-------|---------|
| set_id / question_id | `eq_set_007` / `eq_set_007_q01` |
| language | tr |
| category | turkish_quality / generic_biri |
| current text | `Hobi grubundan biri toplu buluşma hikâyesinde eski sevgilisini anıyor. Nasıl karşılık verirsin?` |
| suggested fix direction | Prefer relationship labels already used elsewhere (“eşleşme”, “yeni tanıştığın kişi”, “partner”) instead of anonymous “biri” when context allows |

Concentrated in sets such as `eq_set_007` (4), `eq_set_030` (3), and many “Yeni biri…” / “Yakın biri…” openers.

### 3. EQ `vague_sey` (13)

| Field | Example |
|-------|---------|
| set_id / question_id | `eq_set_001` / `eq_set_001_q06` |
| language | tr |
| category | turkish_quality / vague_sey |
| current text | `Kişisel bir şey paylaştın; görüştüğün kişi yanıtta konuyu değiştiriyor. Nasıl karşılık verirsin?` |
| suggested fix direction | Replace “bir şey” with concrete content (“kişisel bir anı”, “duygusal bir detay”, “kırılgan bir konu”) |

Full IDs: `eq_set_001_q06`, `012_q10`, `019_q01`, `022_q01`, `023_q03`, `029_q03`, `031_q05`, `032_q03`, `041_q04`, `042_q02`, `042_q08`, `044_q04`, `050_q05`.

### 4. Frequency `formal_passive` (14)

| Field | Example |
|-------|---------|
| set_id / question_id | `frequency_set_029` / `frequency_set_029_q10` |
| language | tr |
| category | turkish_quality / formal_passive |
| current text | `… Her duygu anında anlatılmak zorunda değil.` |
| suggested fix direction | Soften endings: “her duyguyu hemen anlatmak şart değil” / “sessiz günler uzaklaşmak demek değil” — keep meaning and reverseScored |

IDs: `027_q12`, `029_q10`, `031_q10`, `033_q11`, `035_q10`, `036_q10`, `038_q11`, `040_q10`, `041_q10`, `043_q11`, `045_q10`, `046_q10`, `048_q11`, `050_q10`.

---

## Top remaining English issues (with examples)

### 1. EQ `caricature_option` (9)

| Field | Example |
|-------|---------|
| set_id / question_id | `eq_set_009` / `eq_set_009_q08` |
| language | en (option) |
| category | english_quality / caricature_option |
| current text | `Withdraw affection to test if they'll chase` |
| suggested fix direction | Replace with a plausible less-skilled response (e.g. go quiet and wait without naming the need) |

Also: `009_q09`, `009_q10`, `010_q01`, `012_q06`, `013_q03`, `016_q04`, `021_q04`, `034_q08` (variant: “…to regain a sense of control”).

### 2. EQ `moralizing_win` (4)

| Field | Example |
|-------|---------|
| set_id / question_id | `eq_set_031` / `eq_set_031_q01` |
| language | en (option) |
| category | english_quality / moralizing_win |
| current text | `Share what you appreciate and ask what would help them feel steadier` |
| suggested fix direction | Keep warmth but reduce therapy-checklist tone; vary winning phrasing |

Also: `034_q02`, `037_q03`, `037_q10`.

### 3. EQ `abstract_frequency` (2) — word collision

| Field | Example |
|-------|---------|
| set_id / question_id | `eq_set_024` / `eq_set_024_q05` |
| language | en |
| category | english_quality / abstract_frequency |
| current text | `…later blames the vibe…` |
| suggested fix direction | Prefer “atmosphere” / “mood of the room” |

| Field | Example |
|-------|---------|
| set_id / question_id | `eq_set_049` / `eq_set_049_q10` |
| current text | `A mismatch in texting rhythm…` |
| suggested fix direction | Prefer “texting pace” / “how often you text” |

---

## Top remaining design / scoring issues (with examples)

All 12 are EQ `obvious_model_answer` (winning option matched `Acknowledge…`):

| Winning option archetype | Question IDs |
|--------------------------|--------------|
| `Acknowledge the tension and ask what pace would feel comfortable` | `eq_set_003_q07`–`q10` (4) |
| `Acknowledge their pace and ask what would feel fair` | `013_q01`, `016_q02`, `019_q03`, `019_q10`, `023_q01`, `026_q02`, `029_q03`, `029_q10` (8) |

**Suggested fix direction:** Diversify winning wording so “Acknowledge…” is not a patterned tell; keep emotional skill without identical stems.

---

## Exact remaining flag inventory

### Design scoring (12) — complete

`eq_set_003_q07`, `003_q08`, `003_q09`, `003_q10`, `013_q01`, `016_q02`, `019_q03`, `019_q10`, `023_q01`, `026_q02`, `029_q03`, `029_q10`

### English quality (15) — complete

- Caricature: `eq_set_009_q08`, `009_q09`, `009_q10`, `010_q01`, `012_q06`, `013_q03`, `016_q04`, `021_q04`, `034_q08`
- Moralizing: `eq_set_031_q01`, `034_q02`, `037_q03`, `037_q10`
- Abstract word: `eq_set_024_q05`, `049_q10`

### Frequency Turkish formal_passive (14) — complete

`frequency_set_027_q12`, `029_q10`, `031_q10`, `033_q11`, `035_q10`, `036_q10`, `038_q11`, `040_q10`, `041_q10`, `043_q11`, `045_q10`, `046_q10`, `048_q11`, `050_q10`

### EQ Turkish vague_sey (13) — complete

`eq_set_001_q06`, `012_q10`, `019_q01`, `022_q01`, `023_q03`, `029_q03`, `031_q05`, `032_q03`, `041_q04`, `042_q02`, `042_q08`, `044_q04`, `050_q05`

### EQ Turkish generic_biri (54)

All EQ `turkish_quality` rows with `issue_type=generic_biri` (see audit `--json` for full texts). Highest concentration: `eq_set_007` (4), `eq_set_030` (3), plus many `Yeni biri…` / `Yakın biri…` items across sets 004–040.

### IQ Turkish generic_biri (50) — complete pattern

Every `iq_set_001_q08` … `iq_set_050_q08`.

---

## Audit script accuracy note (Phase 3N-A1)

`scripts/audit_assessment_content_quality.py` previously printed **stale hardcoded P0 urgent blurbs** (EQ 20 templates / literal TR prompt / 20 winning archetypes) even after those problems were fixed.

**Updated in this phase (reporting only):**
- Urgent list is generated from **current findings**
- Console report adds **issue counts by assessment type**
- JSON output includes `by_type`
- Thresholds unchanged; no issues hidden

---

## Recommended next phase — Phase 3N-A2

**Goal:** Light polish only — do not rewrite banks.

Suggested order:
1. **EQ distractors / winning options** (~15 EN + 12 design) — highest user-visible impact
2. **EQ Turkish** — replace `şey` (13) and reduce anonymous `biri` (54) where relationship labels exist
3. **Frequency Turkish** — soften 14 `…zorunda değil` / `…gerekmez` endings without changing dimension/reverseScored
4. **Optional IQ hygiene** — rephrase 50 odd-one-out helper lines to clear false-positive `biri`
5. Re-run validator + content audit; expect turkish_quality ≪ 131 if heuristics still count IQ math, or document IQ exclusion in a later script tweak (threshold change only if documented)

**Out of scope for 3N-A2:** full IQ rewrite, Firestore publish, scoring changes, runtime UI.

---

## Appendix — heuristic caveats

| Flag | Often means |
|------|-------------|
| IQ `generic_biri` | Natural “one of them” in math Turkish — not dating-copy quality failure |
| Frequency `formal_passive` | Conversational “zorunda değil / gerekmez” — mild, not therapy-speak |
| EQ `abstract_frequency` | Substring match on `vibe` / `rhythm` inside otherwise concrete EQ stems |
| EQ `obvious_model_answer` | Winning option starts with “Acknowledge…” — skillful but patterned |

These heuristics remain useful for regression detection; interpret counts with the caveats above.
