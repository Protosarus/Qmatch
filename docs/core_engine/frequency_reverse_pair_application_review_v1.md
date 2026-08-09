# Frequency Reverse-Pair Application Review v1

**Scope:** All 6 reverse pairs in Frequency pilot / review candidate 1.  
**Contract:** `docs/core_engine/reverse_pair_consistency_contract_v1.md`  
**Policy:** Retain behavioral keying; trait deltas never negated for RVI.

## Service compatibility (P2A-2D-2.1)

| Field | Value |
|---|---|
| Declared mode | `behavioral_correspondence` |
| Trait scoring | Unchanged — signed deltas accumulate as authored |
| Reverse RVI | Compares same primary-delta **sign** across pair members |
| Option letters | Never assumed to correspond without declared mode/map |
| Missing metadata | Reverse component unavailable (not fabricated fail) |
| Compatibility | **PASS** under frozen reverse-pair consistency contract |

Historical note: before P2A-2D-2.1, TraitScoringService blindly expected opposite
stored signs, so Frequency reverse RVI was CONDITIONAL. That gap is closed by
explicit mode metadata + mode-aware evaluation.

## Fixture logic

- Consistent: same primary-delta sign on both members (e.g. both high-pole).
- Inconsistent: opposite primary-delta signs across members.
- Do not use raw option letter alone unless `explicit_option_mapping` is declared.

## `frequency_tr_v1_rev_01`

- **Item IDs:** `frequency_tr_v1_depth_preference_004`, `frequency_tr_v1_depth_preference_009`
- **Shared dimension:** `depth_preference`
- **Prompt polarity:** reverse_pole_scenarios
- **consistency_mode:** `behavioral_correspondence`
- **Option correspondence map (audit):** A↔A deep re-engage; B↔B gradual; C↔C practical/light; D↔D minimal/defer
- **Expected trait-direction relation:** same behavioral pole ↔ same primary-delta sign
- **Expected consistent combinations:** max-primary on both members
- **Legitimate inconsistency:** high pole on one member and low pole on the other
- **Current service compatibility:** **PASS**
- **Retain / revise / remove:** **retain**

## `frequency_tr_v1_rev_02`

- **Item IDs:** `frequency_tr_v1_communication_pace_003`, `frequency_tr_v1_communication_pace_008`
- **Shared dimension:** `communication_pace`
- **consistency_mode:** `behavioral_correspondence`
- **Current service compatibility:** **PASS**
- **Retain / revise / remove:** **retain**

## `frequency_tr_v1_rev_03`

- **Item IDs:** `frequency_tr_v1_social_energy_002`, `frequency_tr_v1_social_energy_007`
- **Shared dimension:** `social_energy`
- **consistency_mode:** `behavioral_correspondence`
- **Current service compatibility:** **PASS**
- **Retain / revise / remove:** **retain**

## `frequency_tr_v1_rev_04`

- **Item IDs:** `frequency_tr_v1_spontaneity_002`, `frequency_tr_v1_spontaneity_008`
- **Shared dimension:** `spontaneity`
- **consistency_mode:** `behavioral_correspondence`
- **Current service compatibility:** **PASS**
- **Retain / revise / remove:** **retain**

## `frequency_tr_v1_rev_05`

- **Item IDs:** `frequency_tr_v1_stability_002`, `frequency_tr_v1_stability_006`
- **Shared dimension:** `stability`
- **consistency_mode:** `behavioral_correspondence`
- **Current service compatibility:** **PASS**
- **Retain / revise / remove:** **retain**

## `frequency_tr_v1_rev_06`

- **Item IDs:** `frequency_tr_v1_disclosure_pace_003`, `frequency_tr_v1_disclosure_pace_007`
- **Shared dimension:** `disclosure_pace`
- **consistency_mode:** `behavioral_correspondence`
- **Current service compatibility:** **PASS**
- **Retain / revise / remove:** **retain**
