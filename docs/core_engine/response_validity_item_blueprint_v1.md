# Response Validity Item Blueprint v1

**Status:** provisional (P2A-1)  
**Principle:** RVI affects confidence, publishability, retest guidance, and matching eligibility — **not** trait direction as punishment.

## Non-negotiables

- Do not call inconsistent users liars.  
- Do not use humiliating trick questions.  
- Do not permanently ban solely for assessment inconsistency.  
- Do not alter trait scores to punish response style.  

---

## Components

### 1. Semantic consistency

| Field | Value |
|---|---|
| Required evidence | ≥3 semantic pairs administered (bank must provide) |
| Comparison | Agreement after keying/reverse on paired items |
| Missing | Pair incomplete → component `unknown`, no fail |
| Provisional threshold | Agreement < 0.45 → flag `semantic_inconsistency` |
| Reason codes | `rvi_semantic_low` |
| Retest | Offer optional clarification module; do not auto-void traits |

### 2. Reverse consistency

| Field | Value |
|---|---|
| Required evidence | ≥3 reverse pairs with **declared** consistency mode |
| Comparison | Per `reverse_pair_consistency_contract_v1.md` mode (`opposite_trait_sign`, `behavioral_correspondence`, or `explicit_option_mapping`) |
| Missing | Pair incomplete **or** mode metadata missing → component `unknown` (never fabricate inconsistency) |
| Threshold | Low agreement under declared mode → flag |
| Reason codes | `rvi_reverse_inconsistent`, `rvi_reverse_metadata_unavailable` |
| Retest | Guided retest of affected family |
| Non-negotiable | Never invert trait direction to satisfy reverse RVI |

### 3. Timing quality

| Field | Value |
|---|---|
| Required evidence | Per-item timestamps when available |
| Comparison | Item time vs `estimated_completion_seconds` bands |
| Missing | No timings → component omitted |
| Threshold | Median time << 0.25× estimate on many items → `too_fast` |
| Reason codes | `rvi_too_fast` |
| Retest | Soft warning; high severity may block publishable persona |

### 4. Person-fit (provisional)

| Field | Value |
|---|---|
| Required evidence | Full module responses |
| Comparison | Unusual response pattern vs form norms (pilot later) |
| Missing | No norms → always `unknown` at launch |
| Threshold | Deferred until calibration |
| Reason codes | `rvi_person_fit_deferred` |
| Retest | N/A until calibrated |

### 5. Response variation

| Field | Value |
|---|---|
| Required evidence | ≥10 Likert or multi-option responses |
| Comparison | Unique option/value entropy |
| Missing | Short forms → skip |
| Threshold | Near-zero variation → `straightlining_flag` |
| Reason codes | `rvi_straightlining` |
| Retest | Encourage retest; block high-confidence persona |

### 6. Social-impression risk

| Field | Value |
|---|---|
| Required evidence | Items tagged `social_impression_risk` + high SDR options |
| Comparison | Rate of high-SDR choices |
| Missing | Untagged bank → limited signal |
| Threshold | Extreme SDR clustering → confidence ↓ only |
| Reason codes | `rvi_impression_management_risk` |
| Retest | Not punishment; optional balanced retest |

### 7. Repeated-context stability

| Field | Value |
|---|---|
| Required evidence | ≥2 behavioral isomorph groups |
| Comparison | Rank-order stability across isomorphs |
| Missing | `unknown` |
| Threshold | Large flips without context change → flag |
| Reason codes | `rvi_context_unstable` |
| Retest | Targeted isomorph re-admin |

---

## Aggregation (provisional)

```json
{
  "rvi_version": "rvi_v1_provisional",
  "quality_band": "unknown|low|moderate|adequate",
  "publishable_for_persona": true,
  "flags": [],
  "reason_codes": []
}
```

Mapping to `PersonaScoringInput.responseValidityStatus`:

| Band / flags | Status |
|---|---|
| severe too-fast + straightlining | `invalid` |
| multiple moderate flags | `suspect` |
| adequate / unknown early | `valid` or `unknown` |

`invalid` must block publishable persona primary (already supported by pure service).
