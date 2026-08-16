# QMatch Matching Constraints Contract v1

| Field | Value |
| --- | --- |
| Contract id | `matching_constraints_contract_v1` |
| Document id | `qmatch_matching_constraints_contract_v1` |
| Status | `product_ratified_not_live` |
| Scope | **Docs only.** Ratified product decisions. No Discover wiring, scoring weights, Persona/RVI/temporal/QI, or production code in this freeze. |
| Depends on | [Preferences & constraints audit](./qmatch_preferences_constraints_audit_v1.md), [Final Matching Architecture](./qmatch_final_matching_architecture_v1.md) |
| Explicit non-goals | Inventing `interested_in`; treating `looking_for` as gender preference; inventing fusion weights; creating a new completion flag |

---

## 0. Ratification freeze

Product-ratified v1 decisions (locked):

| Decision | Ratified value |
| --- | --- |
| Reverse-block | **Mandatory L1** hard safety gate |
| `age_range` | **L3 soft preference** — not hard in v1 |
| `distance_preference` | **L3 soft preference** — not hard in v1 |
| `interests` | **L3 soft signal** |
| `looking_for` | Intent-only **soft candidate**, **inactive** until intent semantics are defined |
| `religion` / lifestyle / `children` | **Not Matching inputs** without explicit partner-preference fields |
| `gender` attribute alone | **Must never filter** |
| Fake `interested_in` | **Forbidden**; require a **separate RFC** if added |
| Missing preferences | Remain **unknown** — **never imputed** |
| Assessment completion for eligibility | Use existing canonical source only (§8) — **do not create another completion flag** |

This document freezes **constraints policy**, not Discover implementation.

---

## 1. Purpose

Map **existing** profile / eligibility / safety fields onto Matching layers:

| Class | Layer | Behavior |
| --- | --- | --- |
| **L1 hard constraint** | Architecture L1 | Pass / fail / unknown. Fail ⇒ pair excluded. Not a soft score. |
| **L3 soft preference** | Architecture L3 | Soft signal among L1-eligible pairs. Separate from L2. **No weights here.** |
| **Display-only** | UI | Shown; not L1; not L3 under this contract (unless also listed as L3). |
| **Out of Matching** | — | Must not drive L1 or L3 until a later RFC. |

---

## 2. Ratified L1 hard constraints

| Field / store | Role | Status |
| --- | --- | --- |
| `discover_eligible` | Authoritative candidate query gate | **L1** |
| `active` | Account active | **L1** (eligibility input) |
| `profile_completed` | Profile completeness | **L1** |
| Assessment completion (canonical — §8) | Assessment readiness | **L1** |
| Photo present (`profile_photo_url` or non-empty `photos`) | Media gate | **L1** |
| Not self | Identity | **L1** |
| Swipe exclude (`users/{uid}/swipes/{target}`) | Interaction | **L1** |
| Block-by-me | Safety | **L1** |
| **Reverse-block** (candidate blocked viewer) | Safety | **L1 mandatory** |

**Explicitly not L1 in v1:** `age_range`, `distance_preference`, `looking_for`, `gender`, `religion`, lifestyle, `children`, interests empty-overlap, invented `interested_in`.

---

## 3. Ratified L3 soft preferences

| Field | Status | Notes |
| --- | --- | --- |
| `age_range` | **L3 soft preference** | Not hard in v1. Mutual reciprocity **if/when applied**. Missing → unknown; no imputation. |
| `distance_preference` | **L3 soft preference** | Not hard in v1. Mutual / \(\min\) of both prefs when both locations+prefs present; else unknown. |
| `interests` | **L3 soft signal** | Symmetric overlap; never hard-fail on empty overlap. |
| `looking_for` | **Intent-only soft candidate — inactive** | Not gender preference. No soft-match matrix until intent semantics RFC. |
| Legacy CompatibilityScoring mirrors (`frequency_*`, archetype/category, IQ/EQ bands, recency) | **Rollback only** (`legacy_v1`) | Not live Discover ranking; live order is trusted structural L2 (`structural_l2_v1`) |

Promoting `age_range` or `distance_preference` to L1 requires an **additive RFC** amending this contract.

---

## 4. Display-only

| Field | Notes |
| --- | --- |
| `name`, `bio` | Identity / presentation |
| `age` on card | Display of attribute (Matching use only via soft `age_range` rules if wired later) |
| Own-profile `gender`, `looking_for`, education, drinking, smoking | Display |
| Compatibility chips | Live L2 does **not** show a compatibility %. Rollback (`legacy_v1`) may still attach legacy label/score/reasons |

---

## 5. Out of Matching / deferred

| Field / system | Status |
| --- | --- |
| `gender` as filter | **Forbidden** (attribute alone must never filter) |
| `interested_in` (fake or invented) | **Forbidden**; separate RFC required to add |
| `looking_for` as gender preference | **Forbidden** |
| `religion`, lifestyle (`drinking`, `smoking`, `pets`, `occupation`, `animal_love`), `children` | **Out of Matching** without explicit partner-preference fields |
| CM offline preference-fit / hard constraints | Out of live Matching until persistence + mapping RFC |
| Persona / RVI / temporal L4 / QI L5 | Prohibited as Matching keys per architecture |

**Deferred (need later RFC, not invented here):**

1. Intent soft-match semantics / vocabulary for `looking_for` (or CM `relationship_intent` mapping)  
2. Whether to add real `interested_in` (or equivalent)  
3. Partner-preference counterparts for religion / lifestyle / children  
4. Any L1 promotion of age or distance  
5. Server-side reverse-block enforcement timeline (client L1 still mandatory)

---

## 6. Reciprocity rules (ratified)

| Family | Mode | Rule |
| --- | --- | --- |
| Account eligibility | N/A | Each user independently eligible |
| Swipe / block-by-me / reverse-block | One-way safety | Fail pair for viewer when any applies |
| `age_range` (when soft-applied) | **Mutual** | \(B.\mathrm{age}\in A.\mathrm{age\_range}\) and \(A.\mathrm{age}\in B.\mathrm{age\_range}\); else unknown |
| `distance_preference` (when soft-applied) | **Mutual / stricter** | distance \(\le\min(A,B)\) prefs when both geo+prefs present; else unknown |
| `interests` | Symmetric soft | Overlap only |
| Gender / interested-in | **N/A** | No preference field — must not filter |
| `looking_for` | Inactive | No reciprocity matrix until intent RFC |
| Missing prefs | Unknown | **Never impute** defaults for Matching |

---

## 7. Field semantics (ratified)

### 7.1 `looking_for`

Self **relationship intent** only. Not L1. Soft candidate **inactive** until intent semantics are defined. Must not substitute for gender preference.

### 7.2 `age_range`

`[min, max]` preference over partner `age`. **L3 soft, not hard in v1.** Mutual if applied. Missing/malformed → unknown; never impute.

### 7.3 `distance_preference`

Max km preference. **L3 soft, not hard in v1.** Mutual min-of-two when both locations+prefs exist. `location_text` is not a distance engine. Missing → unknown; never impute.

### 7.4 Gender vs `interested_in`

`gender` = attribute only. **Must never filter.** `interested_in` does not exist — do not fake it; require a separate RFC to add.

### 7.5 Religion / lifestyle / children

Self attributes / status only. **Not Matching inputs** without explicit partner-preference fields. No silent bind to CM offline registries.

### 7.6 Interests

**L3 soft signal.** Display allowed. Never hard-fail.

### 7.7 Blocks

Block-by-me and **reverse-block** are **mandatory L1** hard safety. Never soft. Implementation today: reverse-block incomplete — must be completed before claiming full L1 safety.

---

## 8. Canonical eligibility source (ratified)

| Item | Ratified rule |
| --- | --- |
| Authoritative query gate | `discover_eligible == true` |
| Assessment-completion source | **Existing** flags only: `test_completed \|\| assessment_flow_completed` (same OR already used by `ProfileService.refreshDiscoverEligibility` / auth refresh) |
| New completion flag | **Forbidden** for Matching eligibility (do not invent e.g. another Discover-only completion bit) |
| Full eligibility derivation | `active && (test_completed \|\| assessment_flow_completed) && profile_completed && hasPhoto` → write `discover_eligible` |
| Local Discover re-check | **Must mirror** that derivation (same OR for assessment completion) — must **not** require only `test_completed` |
| Prefs in eligibility | `age_range` / `distance_preference` / intent / gender **must not** fold into `discover_eligible` under v1 |

`test_completed` remains the legacy IQ+EQ completion meaning; `assessment_flow_completed` remains the flow-v2 completion meaning. Eligibility accepts **either** existing flag — no third flag.

---

## 9. Data-model / implementation prerequisites (not done in this freeze)

Before wiring:

| Prerequisite | Why |
| --- | --- |
| Reverse-block readable + enforced on Discover path | Mandatory L1 |
| Align Discover local assessment check with §8 OR | Eligibility consistency |
| If applying L3 age/distance soft signals: expose viewer prefs + candidate age/location on evaluate path | Prefs missing from Discover model today |
| Intent RFC before activating `looking_for` soft-match | Semantics undefined |
| Separate RFC before any `interested_in` | Must not invent |

---

## 10. Exact next implementation step

**Implement mandatory reverse-block as L1 on the Discover candidate path** (client now; server ASAP), and **align local eligibility re-check with the ratified §8 OR** (`test_completed || assessment_flow_completed`) so it matches `discover_eligible` derivation.

Do **not** wire age/distance soft scoring, intent match, or gender filters in that PR. No scoring weights.

---

## 11. Non-goals (restated)

- No Discover preference soft-scoring in this freeze  
- No scoring weights  
- No Persona / RVI / temporal / QI  
- No fake `interested_in`  
- No new assessment-completion flag  

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Initial constraints contract from preferences audit |
| v1 ratify | 2026-08-12 | Status → `product_ratified_not_live`; reverse-block L1; age/distance L3 soft; looking_for inactive; eligibility OR canonical; no fake interested_in |
