# Frequency V2 Phase 3A — Selector simulation

Status: **offline / dormant**. `runtime_selectable` remains false.
Selector: `frequency_behavior_v2_selector_v1`
Bank: `frequency_behavior_pool_tr_v2_draft1`
Seeds: `phase3a-sim-0` … `phase3a-sim-9999`
Sessions: **10000**

This report is actual output. Scores and quotas were not retuned after seeing the numbers.

## Invariants

- Sessions with != 50 unique question IDs: **0**
- Coverage failures (not 4/5 with exactly two fives): **0**
- DROP / ineligible leaks: **0**
- Archive DROP IDs: **21**
- Selectable IDs tracked: **405**

## Extra-slot distribution (dimension received 5 questions)

Expected if uniform: 1666.67 per dimension.

min extra=1594, max extra=1733, mean=1666.67

- `contact_need`: 1594 (15.94%)
- `closeness_pace`: 1733 (17.33%)
- `initiative`: 1650 (16.50%)
- `autonomy`: 1679 (16.79%)
- `reassurance_need`: 1669 (16.69%)
- `uncertainty_tolerance`: 1685 (16.85%)
- `disclosure_pace`: 1655 (16.55%)
- `boundary_firmness`: 1712 (17.12%)
- `repair_style`: 1652 (16.52%)
- `social_energy`: 1644 (16.44%)
- `structure_preference`: 1677 (16.77%)
- `adaptability`: 1650 (16.50%)

## Question selection frequency (among 405 selectable)

- min: **301**
- max: **10000**
- mean: **1234.568**
- questions ever selected: **405**
- questions never selected: **0**
- questions selected in every session: **3**

- none
- 3 questions at max: `frequency_v2_q0145` (repair_style), `frequency_v2_q0156` (closeness_pace), `frequency_v2_q0281` (closeness_pace)

## Option-position distribution (authored A/B/C/D vs display slot)

Total placements per slot: 500000

- display slot 0: a=125370, b=124292, c=125098, d=125240
- display slot 1: a=124631, b=125230, c=124876, d=125263
- display slot 2: a=124442, b=125713, c=124957, d=124888
- display slot 3: a=125557, b=124765, c=125069, d=124609

## Consecutive same-dimension

- adjacent pairs: 490000
- adjacent same-primary pairs: 30 (0.006%)
- sessions with at least one 2-streak: 30
- max streak observed: 2 (cap is 2)

## Safety

- V2 not activated
- pool text / weights / evidence values not modified by this simulation
- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter

FREQUENCY V2 PHASE 3A DORMANT 50-QUESTION SELECTOR READY — V2 STILL DORMANT
