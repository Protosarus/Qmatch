# QMatch IQ Bank Contract v1

**Phase:** P2C-2A-0  
**Intended path:** `assets/data/assessment_v3/iq/iq_bank_tr_v1.json`  
**Schema:** `assets/data/assessment_v3/iq/iq_item_schema_v1.json`  
**Status of file today:** **ABSENT** (target only)

---

## Bank-level targets

| Requirement | Value |
|-------------|------:|
| Unique active items | **340** |
| `logical_reasoning` | **85** |
| `pattern_reasoning` | **85** |
| `verbal_reasoning` | **85** |
| `spatial_reasoning` | **85** |
| Locale | `tr-TR` |
| Retired dimensions | **0** |

This is a **bank target**, not evidence that the file exists.

## Live session target (composition later)

| Dimension | Items |
|-----------|------:|
| logical | 7 |
| pattern | 6 |
| verbal | 6 |
| spatial | 6 |
| **Total** | **25** |

Runtime composition is **out of scope** for this phase.

---

## Hard requirements

- Exactly one `correct_option_id` per item (A–D), never list index
- Rationale required
- Difficulty band required (`easy|medium|hard`) — editorial until calibrated
- Primary subskill required and registry-valid
- No duplicate IDs
- No duplicate / normalized-duplicate prompts
- Near-duplicate families reported for review (warnings)
- No `all of the above` / `none of the above` / Turkish equivalents
- Turkish content review + technical validation + expert review states required
- `runtime_eligible` separate from draft / candidate statuses

---

## Promotion flow

```
DRAFT
→ TECHNICALLY_VALID
→ CONTENT_REVIEWED
→ EXPERT_REVIEWED
→ PILOT_ELIGIBLE
→ RUNTIME_ELIGIBLE
```

Do not claim expert review when it has not occurred.  
Do not place rejected/unreviewed candidates into the runtime bank.

Folder policy:

```
assets/data/assessment_v3/iq/
  iq_item_schema_v1.json
  iq_pilot_tr_v1.json
  candidates/
  rejected/
  reports/
  iq_bank_tr_v1.json   # future only
```

---

## Recovery / creation plan for 340

Given classification **NOT_FOUND**:

1. Keep pilot + review candidate as seed corpus (25 + 25 lineage).
2. Author new items into `candidates/` under `iq_item_schema_v1`.
3. Run `IqItemValidator` + inventory scripts locally (no Firebase).
4. Promote only `expert_reviewed` → `pilot_eligible` → later `runtime_eligible`.
5. Assemble `iq_bank_tr_v1.json` only when 340 unique items pass hard gates and 85/85/85/85 holds.
6. **Do not** recreate duplicates of existing pilot IDs; allocate new `iq_*` IDs.
7. **Do not** silently convert `iq_sets.json` 500 items.

**Conclusion:** New item creation **is required**. Recovery of a ready 340 bank is **not** available.
