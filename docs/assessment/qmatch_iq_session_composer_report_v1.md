# QMatch IQ Session Composer Report v1

**Phase:** P2C-2A-2
**Selection policy:** `iq_session_selection_v1`
**RNG:** `xorshift32_fnv1a32_v1`
**Bank:** `assets/data/assessment_v3/iq/iq_bank_tr_v1.json` (`tr_v2_340`)

---

## Composer invariants

| Check | Result |
|-------|--------|
| Session size | 25 |
| Quotas | logical 7 / pattern 6 / verbal 6 / spatial 6 |
| Unique item IDs | pass |
| Unique template families | pass |
| Option IDs remain source of truth | pass (`correct_option_id` unchanged) |
| Displayed options = permutation | pass |
| Answer-position balance (spread ≤ 1) | pass |
| Same seed reproducibility | pass |
| Different seeds vary | pass |
| Bank immutability | pass |
| Strict seen-family (no silent reuse) | pass |

---

## 10,000-session exposure simulation

Source: `assets/data/assessment_v3/iq/reports/iq_session_composer_exposure_v1.json`

| Metric | Value |
|--------|-------|
| Sessions | 10,000 |
| Failures | 0 |
| Items never selected | 0 |
| Families never selected | 0 |
| Item exposure min / median / max | 632 / 740 / 828 |
| Item exposure CV | 0.0468 |
| Family exposure min / median / max | 1283 / 1484 / 1585 |
| Family exposure CV | 0.0395 |
| Displayed correct positions (0..3) | ~62500 each (balanced) |

**Disclaimer:** Algorithmic fairness/exposure testing only — not psychometric calibration.

---

## Tools

```bash
dart run tool/assessment/compose_iq_session_v1.dart --seed demo-seed-1
dart run tool/assessment/simulate_iq_session_exposure_v1.dart --sessions 10000
python3 tool/assessment/validate_iq_bank_v1.py --bank assets/data/assessment_v3/iq/iq_bank_tr_v1.json
```

---

## Status

| Capability | Status |
|------------|--------|
| Canonical 340-item bank | IMPLEMENTED_OFFLINE |
| 25-question session composer | IMPLEMENTED_OFFLINE |
| Session persistence/resume | IMPLEMENTED_OFFLINE |
| Runtime IQ wiring | NOT_STARTED |
| Canonical 4D IQ scoring | NOT_STARTED |
