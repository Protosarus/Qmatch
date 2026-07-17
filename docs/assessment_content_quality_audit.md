# Assessment Content Quality Audit (Phase 3K)

**Date:** 2026-07-17
**Scope:** Bundled assets only (`assets/data/assessment_sets/*.json`)
**Mode:** Read-only diagnostic — no JSON edits, no Firestore writes, no runtime changes
**Tooling:** `scripts/audit_assessment_content_quality.py` + `scripts/validate_assessment_sets.py`

---

## Executive summary

The bundled assessment bank is **structurally valid and fully localized** (`{en, tr}`), but it is **not product-ready for a premium global dating app** without a substantial EQ rewrite and targeted Frequency/Turkish polish.

| Assessment | Questions | Structural verdict | Content verdict |
|------------|-----------|-------------------|-----------------|
| **IQ** | 500 | Acceptable variety | Mostly fine; some stems long in TR |
| **EQ** | 500 | **Critical template reuse** | **Fail** — obvious answers, repetitive scenarios |
| **Frequency** | 600 | Dimension-balanced | Too abstract/poetic; mobile-length risk in TR |

### Overall readiness

**FAIL — rewrite recommended before publish**

Blockers:
1. EQ uses only **20 unique situations**, each repeated **25×** via relationship-context swaps.
2. EQ Turkish uses a **literal test prompt** on all 500 items (`En olası tepkin hangisi olur?`).
3. EQ has **20 fixed winning-answer archetypes** — pattern-matchable after limited exposure.
4. Frequency items often read as **abstract self-help statements**, not concrete connection behavior.

Non-blockers:
- IQ items are unique per stem (no exact duplicates), evenly distributed correct-index positions, and reasonably distinct from EQ/Frequency.
- Localization coverage is complete; validator PASS.

---

## Counts by type

| Metric | IQ | EQ | Frequency |
|--------|----|----|-----------|
| Sets | 50 | 50 | 50 |
| Questions | 500 | 500 | 600 |
| Exact duplicate EN stems | 0 | 0 | 0 |
| Exact duplicate TR stems | 0 | 0 | 0 |
| Unique normalized situations (EQ-style) | — | **20** | — |
| Max repeats of one EQ situation | — | **25** | — |
| Unique EQ option archetype sets | — | **20** | — |
| Money/pricey-plan EQ scenarios | — | **25** | — |
| UX length flags (questions TR >170) | 0 | 1 | 16 |
| UX length flags (options TR >90) | 0 | 25 | 0 |
| Design/scoring flags (heuristic) | 0 | 150 | 194 |

### Automated issue totals (heuristic; overlaps possible)

| Category | Count |
|----------|------:|
| Duplicate / near-duplicate | 40 |
| Turkish quality | 925 |
| English quality | 870 |
| UX length | 42 |
| Design / scoring | 344 |

---

## 1. Duplicate / near-duplicate findings

### EQ — systemic template architecture (critical)

The EQ bank is not 500 independent scenarios. It is:

- **20 situation templates**
- × **25 relationship-context variants** each
- × **1 winning answer archetype per template** (always the “emotionally skilled” option)
- with **20 reused four-option sets** (distractors are often caricatures)

**Worst repeated templates (each appears 25×):**

| Situation (normalized) | Count | Notes |
|------------------------|------:|-------|
| seems quieter than usual and answers in short replies | 25 | Same set pattern across all relationship labels |
| forgets to confirm evening plans until the last minute | 25 | Planning reliability template |
| mentions an ex casually during a date-night conversation | 25 | Jealousy/trigger template |
| looks tense when you bring up meeting each other's friends | 25 | Milestone anxiety template |
| changes the subject when you ask how they're really doing | 25 | Emotional avoidance template |
| double-texts apologies after you replied slower than usual | 25 | Reassurance template |
| shares good news and watches closely for your reaction | 25 | Validation template |
| interrupts once while you're explaining something personal | 25 | Listening template |
| admits they're jealous without much context yet | 25 | Jealousy template |
| asks for reassurance after you seemed distracted on a call | 25 | Reassurance template |
| teases you in front of others in a way that lands awkwardly | 25 | Social embarrassment template |
| posts something vague online that might be about your argument | 25 | Conflict template |
| **shares stress about money when you've planned something pricey** | **25** | **Money stress — relationship swap only** |
| questions your tone after a message that wasn't meant sharply | 25 | Tone misread template |
| (+ 6 additional 25× families) | 25 each | Full list in audit script output |

**Example (money stress):**
- `eq_set_012_q04` — EN: “Someone you've been seeing for a few weeks shares stress about money when you've planned something pricey. What's your most likely response?”
- Same situation body with 24 other relationship openers.

**Within-set pattern:** Most sets contain **10 questions that are 10 relationship swaps of 1–2 scenarios**, not 10 distinct emotional dilemmas.

### EQ — repeated option sets

Each of **20 option archetype sets** appears **25 times**. Example winning archetype (25×):
> “Check in kindly, name what you noticed, and ask what would help”

Caricature distractors repeat across templates, e.g.:
> “Match short replies to teach them a lesson”
> “Assume they're flaky and start dating others immediately without a word”

### IQ — near-duplicates

- **No exact duplicate stems** across 500 IQ items.
- Item types (heuristic): ~200 sequence, ~250 numeric/pattern, ~50 other.
- **Correct answer index** evenly distributed (125 per slot 0–3) — good for anti-gaming at index level, but EQ pattern-matching is a bigger risk.

### Frequency — near-duplicates

- **No exact duplicate EN stems** across 600 items.
- Strong **phrase-family repetition** (e.g. messaging rhythm / thoughtful questions / depth vs small talk) with wording variants across sets — feels like template rotation rather than 600 distinct behavioral probes.

---

## 2. Turkish quality findings

### P0 — Literal prompt on all EQ items (500/500)

| Field | Value |
|-------|-------|
| set_id | `eq_set_001` (all EQ sets) |
| question_id | e.g. `eq_set_001_q01` |
| Current TR | Birkaç haftadır görüştüğün biri her zamankinden daha suskun görünüyor ve kısa cevaplar veriyor. **En olası tepkin hangisi olur?** |
| Issue type | `literal_prompt` — test-language, not app copy |
| Rewrite direction | Use natural phrasing: “Bu durumda genelde ne yaparsın?” / “İlk tepkin ne olur?” — avoid psychometric wording |

### P1 — Generic “biri” overuse (338+ flags)

| set_id | question_id | Current TR | Issue | Rewrite direction |
|--------|-------------|------------|-------|-------------------|
| `eq_set_001` | `eq_set_001_q01` | …görüştüğün **biri**… | Generic referent | Keep relationship specificity already in EN (“partner”, “eşleşme”) — don’t collapse to anonymous “biri” |
| `iq_set_001` | `iq_set_001_q08` | …2'nin katıdır; **biri** değildir. | Acceptable in logic context | No change needed for math items |

### P1 — Frequency: em-dash clause stacking + formal tone

| set_id | question_id | Current TR (excerpt) | Issue | Rewrite direction |
|--------|-------------|----------------------|-------|-------------------|
| `frequency_set_004` | `frequency_set_004_q11` | Mesajlaşmanın karşılıklı hissettirmesini isterim—her zaman kusursuz dengeli olmak zorunda değil ama… (202 chars) | `dash_clauses` + long | One sentence, conversational, <150 chars |
| `frequency_set_001` | `frequency_set_001_q11` | İlgilendiğimde düşünceli mesajları severim—sürekli olmak zorunda değil ama hissedilir olması önemli. | Poetic + long | “İlgilendiğim kişiden ara sıra düşünceli mesajlar almak bana iyi gelir.” |
| `frequency_set_018` | `frequency_set_018_q01` | Hikâyeler yalnızca öne çıkanları değil kırılganlığı da içerdiğinde güvenin filizlendiğini hissederim | Abstract/poetic | Anchor in behavior: “İnsan kendini açıkça anlatınca güvenim artar.” |

### P2 — EQ option Turkish length / gerund stacks

| set_id | question_id | Current TR option | Issue |
|--------|-------------|-----------------|-------|
| `eq_set_003` | `eq_set_003_q06` | Nazikçe yazıp fark ettiğimi söylemek ve neyin iyi geleceğini sormak (95 chars) | Option TR >90 |

---

## 3. English quality findings

### EQ — repetitive assessment-test framing (500/500)

| set_id | question_id | Current EN | Issue | Rewrite direction |
|--------|-------------|------------|-------|-------------------|
| `eq_set_001` | `eq_set_001_q01` | …What's your most likely response? | `template_prompt` | Vary stems: “What do you do first?”, “How do you respond that night?” |

### EQ — caricature distractors (100+ items flagged)

| set_id | question_id | Option EN | Issue | Rewrite direction |
|--------|-------------|-----------|-------|-------------------|
| `eq_set_001` | `eq_set_001_q01` | Match short replies to teach them a lesson | Cartoonish wrong answer | Plausible but avoidant: “Pull back and wait for them to open up” |

### EQ — moralizing model answers (25× per archetype)

| set_id | question_id | Winning option EN | Issue | Rewrite direction |
|--------|-------------|---------------------|-------|-------------------|
| `eq_set_001` | `eq_set_001_q01` | Check in kindly, name what you noticed, and ask what would help | Therapy-speak “correct” answer | Add nuance; make 2 options defensible |

### Frequency — abstract / self-help tone (194 flagged)

| set_id | question_id | Current EN | Issue | Rewrite direction |
|--------|-------------|------------|-------|-------------------|
| `frequency_set_001` | `frequency_set_001_q02` | I prefer pacing that allows curiosity rather than racing through checkpoints. | Abstract preference | “I like when early dates leave room for curiosity, not a checklist.” |

### IQ — English quality (low concern)

- Stems are concise, neutral, and puzzle-focused.
- No emoji/symbol gimmick reliance detected.
- Aligns reasonably with “Minds First” cognitive positioning.

---

## 4. Assessment design audit

| Dimension | IQ | EQ | Frequency |
|-----------|----|----|-----------|
| Distinct purpose | ✅ Reasoning/patterns | ⚠️ Intended emotional judgment | ⚠️ Intended rhythm/style |
| Obvious answers | Low | **High** | N/A (Likert) |
| Preachy tone | Low | **High** | Medium |
| Gameability | Low–medium | **High** (template + model answer) | Medium (social desirability) |
| Cultural breadth | OK | Narrow relationship scripts | OK but abstract |

### EQ design risks
- Users can learn: **pick the kind, curious, non-punitive response**.
- Wrong answers are often **strawmen**, not realistic alternative styles.
- **Money stress** scenario over-used with cosmetic relationship edits only.

### Frequency design risks
- Items read like **identity statements** (“I prefer…”, “I am energized when…”) rather than behavioral frequency probes.
- Poetic phrasing may reduce answer honesty and mobile comprehension.
- Dimensions are balanced (100 items × 6 dimensions) — structure is sound; copy needs grounding.

### IQ design risks
- Minor: heavy numeric/sequence load may feel samey over 10-question sessions.
- No major moralizing or preachiness concerns.

---

## 5. UX length audit

Thresholds used:
- Question TR > **170** chars
- Option TR > **90** chars
- Question EN > **160** chars
- Option EN > **85** chars

| Flag | IQ | EQ | Frequency |
|------|----|----|-------------|
| Long question TR | 0 | 1 | **16** |
| Long option TR | 0 | **25** | 0 |
| Long question EN | 0 | 0 | 0 |
| Long option EN | 0 | 0 | 0 |

**Highest-risk items:**
1. `frequency_set_004_q11` — TR question **202** chars (messaging rhythm family)
2. `frequency_set_029_q11` — TR question **186** chars (same family)
3. `frequency_set_001_q11` — TR question **181** chars
4. `eq_set_003_q06–q08` — TR options **95** chars (communicative response archetype)

**Consecutive long runs:** No EQ set has 3+ consecutive long TR questions; Frequency has isolated long items, often `q11`/`q12` slots.

---

## 6. Scoring / design risks

1. **EQ pattern learning** — 20 templates × fixed winner → score inflation after repeat exposure.
2. **EQ caricature distractors** — reduces measurement validity; feels condescending for premium brand.
3. **Frequency social desirability** — abstract positive self-descriptions skew toward “healthy” answers.
4. **IQ** — balanced correct-index distribution; lower structural risk.

---

## Top 20 most urgent items to fix

| # | Priority | Item | Action |
|---|----------|------|--------|
| 1 | P0 | EQ bank = 20 situations × 25 swaps | Rebuild to 200+ distinct scenarios; max 2–3 swaps per stem |
| 2 | P0 | TR prompt “En olası tepkin hangisi olur?” ×500 | Replace with conversational Turkish |
| 3 | P0 | 20 EQ winning-answer archetypes | Add plausible alternatives; reduce therapy-speak |
| 4 | P0 | Caricature EQ distractors | Rewrite as realistic suboptimal strategies |
| 5 | P1 | Money/pricey-plan scenario ×25 | One canonical item; diversify financial stress stories |
| 6 | P1 | “Quieter than usual / short replies” ×25 | Retire or deeply vary follow-up dynamics |
| 7 | P1 | “Forgot to confirm evening plans” ×25 | Same |
| 8 | P1 | “Mentions ex on date night” ×25 | Same |
| 9 | P1 | “Tone misread after message” family ×25 | Same |
| 10 | P1 | EQ EN prompt “What's your most likely response?” ×500 | Vary question endings |
| 11 | P2 | Frequency abstract “I prefer…” statements ×194 | Rewrite as concrete behavior frequency |
| 12 | P2 | Frequency TR em-dash multi-clause items | Shorten to single mobile-friendly sentence |
| 13 | P2 | `frequency_set_004_q11` (202 TR chars) | Split/shorten |
| 14 | P2 | EQ TR options >90 chars (25 items) | Compress gerund chains |
| 15 | P2 | Generic “biri” in EQ TR | Use specific relationship nouns |
| 16 | P2 | Frequency phrase families (depth/small talk/messaging) | Increase behavioral specificity per item |
| 17 | P3 | IQ sequence/numeric sameness | Add more verbal/analogy variety across sets |
| 18 | P3 | EQ relationship label rotation | Keep labels but only after scenario diversity fixed |
| 19 | P3 | Frequency `q11`/`q12` length hotspot | Standardize shorter copy for late-set items |
| 20 | P3 | English “check in kindly…” winner phrase | Rebrand to natural dating-app voice |

---

## Recommended rewrite strategy for Phase 3L

### Phase 3L-A — EQ full rebuild (highest ROI)
1. Define **scenario library** (200+ stems) across conflict, repair, boundaries, jealousy, money, pace, family, communication styles.
2. Cap template reuse: **≤3 relationship variants per stem**.
3. Write **4 plausible options** per stem; only 1 “best” but 2 should feel reasonable.
4. Localize TR/EN together — native Turkish dating voice, not literal back-translation.
5. Re-validate `correctAnswer` distribution and difficulty tags.

### Phase 3L-B — Frequency copy pass
1. Rewrite to **observable behaviors** (“In the first two weeks, I usually…”) not identity poetry.
2. Enforce mobile limits: TR question ≤150 chars, TR option N/A (Likert is UI).
3. Keep dimension balance (100 per dimension).

### Phase 3L-C — IQ polish (light)
1. Review longest TR stems in numeric items.
2. Add ~20% verbal reasoning variety if sessions feel repetitive.

### Phase 3L-D — Validation gates
1. `python3 scripts/validate_assessment_sets.py` — must PASS
2. `python3 scripts/audit_assessment_content_quality.py` — target:
   - EQ unique situations ≥200
   - `literal_prompt` TR flags = 0
   - UX length flags <10
3. Manual QA on iPhone 15-sized simulator for 10 IQ + 10 EQ + 12 Frequency items in `tr`.

---

## How to re-run this audit

```bash
python3 scripts/audit_assessment_content_quality.py
python3 scripts/audit_assessment_content_quality.py --json
python3 scripts/validate_assessment_sets.py
```

---

*This document is diagnostic only. No assessment JSON was modified in Phase 3K.*
