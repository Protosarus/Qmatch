# Qmatch Assessment Data Architecture Standard

**Phase:** 3A (document only — no live data model changes in this phase)
**Status:** Approved direction for subsequent implementation phases
**Last updated:** 2026-07-14

This document standardizes how Qmatch stores, versions, assigns, localizes, and publishes assessment content (IQ / EQ / Frequency) before any live schema migration.

---

## A. Current architecture summary

### Bundled asset source

Local JSON under `assets/data/assessment_sets/`:

| File | Sets | Questions |
|------|------|-----------|
| `iq_sets.json` | 50 | 500 (10 each) |
| `eq_sets.json` | 50 | 500 (10 each) |
| `frequency_sets.json` | 50 | 600 (12 each) |

Wrapper shape: `{ "sets": [ ... ] }`.

**Current set document fields (assets):**

- `id` — e.g. `iq_set_001`, `eq_set_042`, `frequency_set_050`
- `type` — `iq` | `eq` | `frequency`
- `set_number` — 1–50
- `version` — string calendar tag, currently `"2026_01"` (not an immutable doc suffix)
- `active` — bool (`true` for all bundled sets)
- `question_count`
- `questions[]`

**Question shapes:**

- **IQ / EQ:** `id`, `question: {en,tr}`, `options: [{label:{en,tr}}]`, `correctAnswer` (index), `difficulty`
- **Frequency:** `id`, `question: {en,tr}`, `dimension`, `reverseScored` (Likert chrome is UI-localized; no per-option maps in assets)

### Firestore source

- Collection: `assessment_sets`
- Document ID strategy today: **equals set `id`** (e.g. `assessment_sets/iq_set_001`)
- Upload helper (when gated write is approved later): `set(..., merge: true)` with `created_at` / `updated_at`
- App load order (runtime today): **Firestore first** → legacy `questions/{setId}` → bundled type JSON → flat legacy JSON (IQ/EQ only)

### Assignment documents

Path: `users/{uid}/assessment_assignments/{iq|eq|frequency}`

Typical fields today:

- `type`, `set_id`, `assigned_at`
- `completed`, `completed_at`, `score`
- `question_order`, `option_orders` (IQ option permutations; EQ/frequency usually `{}`)
- `language_used`, `locale_used`

**Persistence behavior:** If an assignment exists with a non-empty `set_id`, the app **reuses** it (does not regenerate or reshuffle for that user). New random pick only when no assignment exists. Completion merges score + language metadata.

**Assignment pick today:** queries Firestore `assessment_sets` by `type` + `active == true`, random among results; falls back to assets. **`version` is not used** in pick logic. There is no `status` / `base_id` / immutable versioned ID yet.

### Validators and tooling

| Tool | Role |
|------|------|
| `scripts/validate_assessment_sets.py` | Counts, IDs, scoring, localization |
| `scripts/audit_assessment_firestore_sync.py` | Dry-run what *would* sync (no network) |
| `UploadAssessmentSetsHelper` | Gated sync; default dry-run |
| `AssessmentSetsPreflightHelper` | Read-only Firestore vs assets compare |
| Assessment Admin (debug-only) | UI for preflight; **no write button** |

### Localization resolution (runtime)

`LocalizedTextResolver`: requested language → `en` → first non-empty map value.
`AssessmentLanguage`: `language_used` ∈ `{en,tr}` (else → `en`); `locale_used` e.g. `tr_TR` / `en_US`.

### Current risks

1. **Firestore may still hold English-only docs** while assets are fully localized — Firestore-first means users may never see localized asset content until sync.
2. **Overwriting `iq_set_001` in place** would silently change content for users already assigned that ID (orders/options/text).
3. **`version` is a soft calendar string**, not a durable document identity.
4. **No `status` (draft/published/archived)** — only `active`.
5. **Result / archetype UX leaks raw IDs:**
   - Frequency tags (e.g. `slow_bond`) shown as chips
   - IQ/EQ archetype category codes (e.g. `ML`, `HH`) shown in places
6. **Question content must remain data**, not hardcoded Flutter strings — keep enforcing that.
7. **Admin cannot safely publish new sets to production yet** without a versioning + assignment contract (this document).

---

## B. Target architecture

| Concern | Target |
|---------|--------|
| Live content source | **Firestore** `assessment_sets` |
| Fallback / dev source | Bundled `assets/data/assessment_sets/*.json` |
| Content nature | **Data-driven** — no hardcoded assessment question text in app logic |
| User-facing copy | Localized maps only; **never show raw internal IDs** |
| Evolution | New immutable versioned set documents |
| Existing users | Assignments remain stable (same `set_id`, same orders) |
| New users | Only **published + active** sets |
| Language | Device/app locale (`en` / `tr`), recorded as `language_used` / `locale_used` |
| Publishing | Validate → audit → preflight → approved upload → debug verify → release |

App Store updates should **not** be required to ship new IQ/EQ/Frequency sets once Firestore publishing works with this model.

---

## C. Recommended Firestore schema

Collection: `assessment_sets/{id}`

### Recommended document shape

```text
id:            "iq_set_001_v2"     // immutable document ID
base_id:       "iq_set_001"       // logical set family
type:          "iq"               // iq | eq | frequency
set_number:    1
version:       2                  // integer content generation (preferred)
active:        true               // may be assigned to *new* users if also published
status:        "published"        // draft | published | archived
language_mode: "localized"        // localized | legacy_en
question_count: 10
created_at:    <timestamp>
updated_at:    <timestamp>
published_at:  <timestamp|null>
questions:     [ ... ]            // same localized question payload as assets
```

**IQ/EQ question items** continue to carry:

- `id`, `question: {en,tr}`, `options: [{label:{en,tr}}]`, `correctAnswer`, `difficulty`

**Frequency question items** continue to carry:

- `id`, `question: {en,tr}`, `dimension`, `reverseScored`

### Why immutable versioned IDs (preferred)

Prefer `iq_set_001_v2` over mutating `iq_set_001` in place:

| Benefit | Detail |
|---------|--------|
| Assignment stability | Existing `set_id` still points at the exact content the user was scored on |
| Safe content updates | New generation is a new doc; old results remain comparable |
| Rollback | Re-activate prior version docs without rewriting history |
| Audit / history | Clear lineage via `base_id` + `version` |
| Partial rollout | Publish subset of `*_v2` while leaving others archived |

**Do not** delete old docs that still have live or completed assignments.

### Mapping from current IDs

| Current | Target v1 (freeze) | Target v2 (localized publish) |
|---------|--------------------|-------------------------------|
| `iq_set_001` | keep as-is, later `active:false`, `status:archived` | `iq_set_001_v2` |
| `eq_set_001` | same | `eq_set_001_v2` |
| `frequency_set_001` | same | `frequency_set_001_v2` |

Until migration runs, current documents without `_vN` suffix are treated as **implicit v1**.

---

## D. Assignment model standard

Path (unchanged):

```text
users/{uid}/assessment_assignments/{iq|eq|frequency}
```

### Recommended fields

```text
set_id:          "iq_set_001_v2"   // immutable versioned ID
base_id:         "iq_set_001"      // optional but recommended
type:            "iq"
version:         2                 // denormalized from set
language_used:   "tr"
locale_used:     "tr_TR"
question_order:  [0,3,1,...]
option_orders:   { "qId": [2,0,1,3], ... }  // IQ; empty/omit for EQ/frequency if unused
completed:       false
score:           null | number
created_at / assigned_at
completed_at
```

### Rules

1. **Completed assignments are never regenerated.**
2. **In-progress assignments are never reshuffled** and never switched to a newer version mid-test.
3. **New users** receive only sets where `status == published` **and** `active == true`.
4. If a set is later deactivated/archived, users already assigned that `set_id` **must still load and finish** it (read by ID, ignore `active` for assigned users).
5. Language metadata is set (or backfilled) from device/app locale without changing question order.

---

## E. Active / current content strategy

| Field | Meaning |
|-------|---------|
| `active` | Eligible for **new** assignment when combined with published status |
| `status` | Lifecycle: `draft` → `published` → `archived` |
| `version` | Integer content generation of this immutable doc |
| `base_id` | Logical set family shared across versions |
| `id` | Actual Firestore document ID (immutable) |

### Assignment eligibility matrix

| status | active | New users | Existing assignees |
|--------|--------|-----------|--------------------|
| draft | * | Never | N/A (should not be assigned) |
| published | true | Yes | Yes (finish allowed) |
| published | false | No | Yes (finish allowed) |
| archived | * | No | Yes (finish / review allowed) |

**Draft** never assigned. **Archived** not assigned to new users. Deactivated old versions remain **readable** by document ID for anyone already holding that `set_id`.

---

## F. Localization standard

1. **Question text** must be maps: `{ "en": "...", "tr": "..." }`.
2. **IQ/EQ option labels** must be maps under `label: {en,tr}` (or equivalent accepted by `LocalizedTextResolver`).
3. **Frequency Likert labels** come from **UI l10n** (not set JSON).
4. **Result / archetype display names, descriptions, tags** must be localized display content — never raw IDs.
5. **Fallback order** (content): user language → `en` → first non-empty value.
6. **Raw IDs** (`slow_bond`, `ML`, internal archetype keys, set IDs) must **never** be shown directly to users. Store them only as internal keys.

Supported assessment languages today: `en`, `tr`. Unsupported device languages normalize to `en` for `language_used`.

---

## G. Result / archetype standard

Internal codes stay internal. User UI uses localized `title` / `description` / `tags`.

### Recommended content shape (Firestore or bundled display catalog)

Example frequency archetype / tag catalog entry:

```text
id: "slow_bond"   // internal only
title: {
  en: "Steady Connection",
  tr: "Yavaş ve Güvenli Bağ"
}
description: {
  en: "...",
  tr: "..."
}
tags: {
  en: ["Slow burn", "Trust-first"],
  tr: ["Yavaş bağ", "Güven odaklı"]
}
```

Possible storage:

- Collection `frequency_archetypes/{archetypeId}`, and/or
- Static localized maps in app data (still data, not inline UX strings tied to logic)

### IQ/EQ archetypes

- Category codes (`HH`, `ML`, `LL`, …) and calculator keys: **internal only**
- User-facing: localized `title` + `description` (emoji optional)
- Profile/Discover must not display bare category codes

### Frequency results

- Scoring may still emit internal tag IDs
- `FrequencyResultScreen` (and any share cards) must resolve tags through the localized catalog
- Type titles such as `"Balanced Frequency"` must come from l10n / localized maps — not English-only hardcoded strings where TR is expected

---

## H. Content validation requirements

`scripts/validate_assessment_sets.py` (and successors) must enforce:

| Check | Notes |
|-------|--------|
| Set counts | 50 per type (until product changes) |
| IDs | Unique; deterministic pattern |
| Localized maps | Non-empty `en` + `tr` for questions; IQ/EQ option labels |
| `correctAnswer` | Integer in option range (IQ/EQ) |
| Option counts | Expected per question type |
| Frequency `dimension` / `reverseScored` | Present and valid |
| No empty localized text | After trim |
| No raw display labels | User-facing result fields must not be raw IDs (future rule) |
| **Future:** versioned IDs | Prefer `*_vN` / `base_id` + integer `version` |
| **Future:** `status` / `active` consistency | draft ⇒ not active for publish |

Dry-run audit and preflight remain mandatory before any write sync.

---

## I. Sync / publishing process

Safe publishing pipeline:

1. Prepare / update local JSON (or generate then localize)
2. Run `python3 scripts/validate_assessment_sets.py` — must **PASS**
3. Run `python3 scripts/audit_assessment_firestore_sync.py`
4. Run read-only Firestore preflight (Assessment Admin / `AssessmentSetsPreflightHelper`)
5. **Upload only in an explicitly approved phase** (gated helper: debug + dart-define + confirmation phrase)
6. Test with one **debug** account
7. Verify **new** user gets published+active versioned sets
8. Verify **existing** user assignments stay on prior `set_id`
9. Release app (if client changes needed) or content-only go-live if client already compatible

Never skip backup before first production overwrite/migration.

---

## J. Migration recommendation

Current Firestore / assets use IDs like `iq_set_001` (implicit v1).

### Preferred path — versioned v2 docs

1. **Keep** existing v1 docs (`iq_set_001`, …) as-is for assignment stability.
2. **Upload** localized content as new docs: `iq_set_001_v2`, `eq_set_001_v2`, `frequency_set_001_v2`, … with `base_id`, integer `version: 2`, `status: published`, `active: true`, `language_mode: localized`.
3. After verification, set v1 docs to `active: false`, `status: archived` so **new** users stop receiving them.
4. Users already on v1 continue loading `assessment_sets/{oldId}` until done; results remain valid.

### Alternative — merge into existing IDs

Merge `{en,tr}` maps into existing `iq_set_001` docs via merge upload.

- **Pros:** Simpler ID surface; fewer docs
- **Cons:** Existing assignees silently see new wording; weaker audit; harder rollback

**Recommendation:** Use the **preferred versioned v2 path**. Do not merge over v1 until product explicitly accepts content mutation for already-assigned users.

---

## K. Open questions / next implementation phases

| Phase | Scope |
|-------|--------|
| **3B** | Update validator for versioned IDs (`*_vN`, `base_id`, integer `version`, optional `status`) — **done** (legacy assets still valid; versioned checks apply only when `*_vN` IDs are present) |
| **3C** | Result / archetype localized display model (frequency tags + IQ/EQ category codes) — **done** (resolver + result UI; storage IDs unchanged) |
| **3D** | Local v2 export dry-run (`scripts/export_assessment_sets_v2.py` → `build/assessment_sets_v2/`) — **done** |
| **3E** | Flutter sync helper: in-memory v2 convert + dry-run preferred path — **done** (Firestore write still gated / separate approved phase) |
| **3F** | Debug Assessment Admin: v2 sync dry-run report UI — **done** (no write button) |
| **3G** | Assignment loader: pick only `published` + `active`; load assigned sets by ID even if archived |
| **3H** | Routing audit: existing vs new users (assignment stability vs new-set eligibility) |
| **3I** | Screenshot prevention consistency for assessment screens |

### Open product questions (resolve before 3D/3E)

- Exact ID regex: `^(iq|eq|frequency)_set_\d{3}_v\d+$`?
- Whether `version` in Firestore must be integer only, or allow dual-read of legacy `"2026_01"` strings during transition
- Whether all 50 sets ship as `_v2` in one cutover or phased batches
- Where archetype catalogs live first: Firestore vs bundled JSON

---

### Result / archetype display (Phase 3C)

- Raw result IDs and codes (`slow_bond`, `ML`, HH–LL, etc.) are **internal only**.
- User-facing result UI must go through
  `lib/features/assessment/utils/assessment_result_display_resolver.dart`.
- Fallback order: user language → `en` → safe generic title
  (“Connection Profile” / “Bağ Profili”) — **never** raw snake_case in visible UI.
- Future Firestore/data-driven archetype catalogs can replace the local resolver maps.

### Versioned v2 local export (Phase 3D)

- `python3 scripts/export_assessment_sets_v2.py` converts legacy localized assets into
  immutable `*_v2` documents under `build/assessment_sets_v2/`.
- Export is **local/generated only** — original assets stay unchanged.
- **Firestore publishing of v2 docs still requires a separate approved phase.**

### Flutter v2 sync dry-run (Phase 3E / 3F)

- `UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2` / `dryRunVersionedV2AssessmentSync`
  converts bundled assets to `*_v2` **in memory** (does not depend on `build/`).
- Default is dry-run; write still requires debug + dart-define + confirmation phrase.
- Preferred publish IDs: `assessment_sets/iq_set_001_v2` (etc.). Legacy in-place sync
  of `iq_set_001` is disabled for writes.
- Does not archive/delete v1 docs. Actual Firestore publish remains a separate approved phase.
- Debug Assessment Admin (**Phase 3F**) can run **Run v2 Sync Dry Run** to show the report UI.
  That action does **not** write to Firestore and has no upload/write button.

## Related tooling

See also: [`scripts/README.md`](../scripts/README.md) for validate, dry-run audit, preflight, and gated sync commands.

**Phase 3A/3B/3C** documents and display layer do not write to Firestore and do not modify assessment JSON content.
