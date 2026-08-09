# QMatch EQ Runtime-Candidate Bank Audit v1

**Phase:** P2C-2A-7R1  
**Pilot source tip content:** `assets/data/assessment_v3/eq/eq_pilot_tr_v1.json`  
**Selection:** deterministic — all 30 pilot items (already 3 primary × 10 dims)

---

## Decision

```text
BLOCKED_EQ_BANK_EVIDENCE_COVERAGE = not triggered
BLOCKED_EQ_PRIMARY_EVIDENCE_COVERAGE = not triggered
```

Pilot already provides sufficient direct primary evidence for every canonical EQ dimension.

---

## Pilot inventory (accepted → runtime candidate)

| Field | Value |
|-------|-------|
| Form | `eq_tr_pilot_v1` |
| Items | 30 |
| Locale | `tr-TR` |
| Schema | `qmatch_question_schema_v3` |
| Status | pilot / uncalibrated |
| Review | internal_review; expert psych review **pending** |
| Response format | scenario_mcq (4 options, stable `A`–`D`) |
| Correctness | **none** (signed `dimension_deltas` only) |

### Primary coverage

| Dimension | Primary items |
|-----------|--------------:|
| empathy | 3 |
| perspective_taking | 3 |
| self_awareness | 3 |
| emotion_regulation | 3 |
| emotional_openness | 3 |
| boundary_setting | 3 |
| assertiveness | 3 |
| conflict_approach | 3 |
| repair_orientation | 3 |
| social_awareness | 3 |

Machine-readable selection dump:

`assets/data/assessment_v3/eq/reports/eq_runtime_candidate_selection_v1.json`

### Rejection criteria applied

No pilot item was rejected. Checks included:

* unknown / legacy dimension IDs
* missing option IDs
* deltas outside \([-1,1]\)
* correctness scoring dependency
* malformed / duplicate option IDs
* missing primary construct

---

## Runtime-candidate banks

| Bank | Path | Status |
|------|------|--------|
| TR | `assets/data/assessment_v3/eq/eq_bank_tr_v1.json` | `runtime_candidate` / `uncalibrated` |
| EN | `assets/data/assessment_v3/eq/eq_bank_en_v1.json` | `runtime_candidate` / `uncalibrated` |

Not registered in `pubspec.yaml` until live EQ migration (same isolation pattern as pilots).

Item IDs remapped locale-neutrally: `eq_tr_v1_*` → `eq_v1_*`.

Pair metadata preserved (semantic / reverse) with remapped IDs; **not** used to alter trait scores.

---

## Live wiring

```text
EQ live runtime = NOT_YET_MIGRATED
```

R1 does not replace `EQTestScreen` / keyed sets.
