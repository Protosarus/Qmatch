# QMatch Frequency Canonical Migration Audit v1

**Phase:** P2C-2A-8R1 + **P2C-2A-8R1A**
**Date:** 2026-08-09
**Tip before R1A:** `9145a67132d244a037ba5584d856c0de1653748b`

**Decision:**

```text
P2C-2A-8R1A = COMPLETE
P2C-2A-8R1 = COMPLETE

Canonical Frequency taxonomy = FROZEN
Canonical Frequency scoring math = FROZEN
CanonicalFrequencyScorer = IMPLEMENTED_OFFLINE
TR/EN 50-item runtime-candidate banks = CREATED_AND_VALIDATED
Live Frequency runtime = NOT_STARTED
Measured profile = 14 / 20 (unchanged)
```

---

## 1. Live Frequency path (unchanged)

Legacy path remains active for production sessions. Offline banks are **not** in pubspec.

---

## 2. LEGACY_CONTENT

`frequency_sets.json` + live screens/services — legacy aliases, reverse Likert, aggregate totals.

---

## 3. CANONICAL_CANDIDATE_CONTENT

| Asset | Notes |
|-------|-------|
| `frequency_pilot_tr_v1.json` | Source for 30 core + 12 isomorph items |
| `frequency_bank_tr_v1.json` | Offline runtime candidate (50) |
| `frequency_bank_en_v1.json` | Structural EN twin (50) |
| Authored separators/quality | P2C-2A-8R1A provisional hypotheses |

Selection policy: sort eligible non-isomorph item IDs; take first 5/dim for core; all 6 isomorph groups for behavioral equivalence.

---

## 4. INCOMPATIBLE_CONTENT

Live sets without signed deltas remain incompatible for canonical scoring.

---

## 5. MISSING_REQUIRED_METADATA (resolved in R1A)

| Prior blocker | Resolution |
|---------------|------------|
| Separators | 6 authored `dimension_boundary` items; `separator_persona_targets = []` |
| Quality-only | 2 authored `response_quality` items; empty deltas; `trait_scoring=false` |

---

## 6. Coverage vs blueprint

| Slot | Count | Status |
|------|------:|--------|
| Core | 30 | PASS |
| Behavioral equivalence | 12 | PASS |
| Separators | 6 | PASS (authored) |
| Quality | 2 | PASS (authored) |
| **Total** | **50** | **PASS** |

---

## 7. Explicit non-goals

Live Frequency wiring, Frequency→20D, Persona, Matching, QRCF, quantum, RVI gating.
