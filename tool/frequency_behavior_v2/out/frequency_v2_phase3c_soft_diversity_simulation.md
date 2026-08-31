# Frequency V2 Phase 3C — Soft-diversity selector simulation

Status: **offline / dormant**. `runtime_selectable` remains false.
Selector: `frequency_behavior_v2_selector_v1`
Bank: `frequency_behavior_pool_tr_v2_draft1`
Seeds: `phase3c-sim-0` … `phase3c-sim-9999`
Sessions: **10000**
Soft cluster lookahead: **2**

Candidate order is a per-question FNV rank from
`selector_version + bank_version + session_seed + primary_dimension + question_id`
**before** diversity. Repeating a semantic cluster prefers a different cluster
only inside that bounded lookahead. Frequencies were not retuned after seeing
the numbers. Evidence scores are not pick keys.

## Phase 3B invariants

- Sessions with != 50 unique question IDs: **0**
- Coverage failures (not 4/5 with exactly two fives): **0**
- DROP / ineligible leaks: **0**
- Archive DROP IDs: **21**
- Selectable IDs tracked: **405**
- Extra-slot min/max/mean: 1605 / 1760 / 1666.67 (expected 1666.67)
- Near-duplicate co-selection violations: **0**

- `contact_need`: 1743 (17.43%)
- `closeness_pace`: 1678 (16.78%)
- `initiative`: 1632 (16.32%)
- `autonomy`: 1667 (16.67%)
- `reassurance_need`: 1651 (16.51%)
- `uncertainty_tolerance`: 1643 (16.43%)
- `disclosure_pace`: 1760 (17.60%)
- `boundary_firmness`: 1646 (16.46%)
- `repair_style`: 1610 (16.10%)
- `social_energy`: 1699 (16.99%)
- `structure_preference`: 1605 (16.05%)
- `adaptability`: 1666 (16.66%)

## Consecutive same-dimension

- adjacent pairs: 490000
- adjacent same-primary pairs: 16 (0.003%)
- sessions with at least one 2-streak: 16
- max streak observed: 2 (cap is 2)

## Option-position distribution

Total placements per slot: 500000

- display slot 0: a=124832, b=125168, c=124756, d=125244
- display slot 1: a=125000, b=124489, c=125574, d=124937
- display slot 2: a=125561, b=125015, c=124901, d=124523
- display slot 3: a=124607, b=125328, c=124769, d=125296

## Question selection frequency (405 selectable)

- min count / pct: **564** / **5.64%**
- median count / pct: **1136.0** / **11.36%**
- mean count / pct: **1234.568** / **12.35%**
- max count / pct: **2909** / **29.09%**
- questions ever selected: **405**
- questions never selected: **0**
- questions selected in every session: **0**

### Never selected

- none

### Selected in 100% of sessions

- none

No question was selected in 100% of sessions. Smallest dimension pool is 20, which is larger than the max per-dimension quota (5), so 100% coverage is not mathematically required.

### Former hard-cap inflated items (q0145 / q0156 / q0281)

- `frequency_v2_q0145` (repair_style, cluster=`repair_style:support`): 2411 (24.11%); dim expected 16.67%; ratio 1.45
- `frequency_v2_q0156` (closeness_pace, cluster=`closeness_pace:established`): 1566 (15.66%); dim expected 10.68%; ratio 1.47
- `frequency_v2_q0281` (closeness_pace, cluster=`closeness_pace:social`): 1538 (15.38%); dim expected 10.68%; ratio 1.44

### Top 20 most-selected

- `frequency_v2_q0187` (contact_need): 2909 (29.09%); dim expected 20.83%; ratio 1.40
- `frequency_v2_q0175` (social_energy): 2772 (27.72%); dim expected 18.12%; ratio 1.53
- `frequency_v2_q0279` (contact_need): 2705 (27.05%); dim expected 20.83%; ratio 1.30
- `frequency_v2_q0397` (social_energy): 2665 (26.65%); dim expected 18.12%; ratio 1.47
- `frequency_v2_q0169` (contact_need): 2652 (26.52%); dim expected 20.83%; ratio 1.27
- `frequency_v2_q0141` (contact_need): 2651 (26.51%); dim expected 20.83%; ratio 1.27
- `frequency_v2_q0254` (contact_need): 2644 (26.44%); dim expected 20.83%; ratio 1.27
- `frequency_v2_q0134` (contact_need): 2584 (25.84%); dim expected 20.83%; ratio 1.24
- `frequency_v2_q0280` (social_energy): 2557 (25.57%); dim expected 18.12%; ratio 1.41
- `frequency_v2_q0041` (contact_need): 2546 (25.46%); dim expected 20.83%; ratio 1.22
- `frequency_v2_q0118` (social_energy): 2531 (25.31%); dim expected 18.12%; ratio 1.40
- `frequency_v2_q0205` (contact_need): 2473 (24.73%); dim expected 20.83%; ratio 1.19
- `frequency_v2_q0058` (contact_need): 2420 (24.20%); dim expected 20.83%; ratio 1.16
- `frequency_v2_q0145` (repair_style): 2411 (24.11%); dim expected 16.67%; ratio 1.45
- `frequency_v2_q0302` (contact_need): 2395 (23.95%); dim expected 20.83%; ratio 1.15
- `frequency_v2_q0124` (repair_style): 2380 (23.80%); dim expected 16.67%; ratio 1.43
- `frequency_v2_q0088` (repair_style): 2232 (22.32%); dim expected 16.67%; ratio 1.34
- `frequency_v2_q0147` (reassurance_need): 2099 (20.99%); dim expected 16.03%; ratio 1.31
- `frequency_v2_q0359` (initiative): 2043 (20.43%); dim expected 14.37%; ratio 1.42
- `frequency_v2_q0365` (reassurance_need): 2018 (20.18%); dim expected 16.03%; ratio 1.26

### Bottom 20 least-selected

- `frequency_v2_q0303` (autonomy): 564 (5.64%); dim expected 7.31%; ratio 0.77
- `frequency_v2_q0301` (autonomy): 565 (5.65%); dim expected 7.31%; ratio 0.77
- `frequency_v2_q0072` (autonomy): 567 (5.67%); dim expected 7.31%; ratio 0.78
- `frequency_v2_q0291` (autonomy): 568 (5.68%); dim expected 7.31%; ratio 0.78
- `frequency_v2_q0253` (autonomy): 568 (5.68%); dim expected 7.31%; ratio 0.78
- `frequency_v2_q0258` (autonomy): 571 (5.71%); dim expected 7.31%; ratio 0.78
- `frequency_v2_q0379` (autonomy): 573 (5.73%); dim expected 7.31%; ratio 0.78
- `frequency_v2_q0201` (autonomy): 573 (5.73%); dim expected 7.31%; ratio 0.78
- `frequency_v2_q0161` (autonomy): 574 (5.74%); dim expected 7.31%; ratio 0.79
- `frequency_v2_q0107` (autonomy): 575 (5.75%); dim expected 7.31%; ratio 0.79
- `frequency_v2_q0090` (autonomy): 577 (5.77%); dim expected 7.31%; ratio 0.79
- `frequency_v2_q0012` (autonomy): 577 (5.77%); dim expected 7.31%; ratio 0.79
- `frequency_v2_q0367` (autonomy): 584 (5.84%); dim expected 7.31%; ratio 0.80
- `frequency_v2_q0117` (autonomy): 592 (5.92%); dim expected 7.31%; ratio 0.81
- `frequency_v2_q0304` (autonomy): 594 (5.94%); dim expected 7.31%; ratio 0.81
- `frequency_v2_q0238` (boundary_firmness): 598 (5.98%); dim expected 8.01%; ratio 0.75
- `frequency_v2_q0424` (boundary_firmness): 599 (5.99%); dim expected 8.01%; ratio 0.75
- `frequency_v2_q0371` (boundary_firmness): 599 (5.99%); dim expected 8.01%; ratio 0.75
- `frequency_v2_q0296` (boundary_firmness): 601 (6.01%); dim expected 8.01%; ratio 0.75
- `frequency_v2_q0219` (autonomy): 601 (6.01%); dim expected 7.31%; ratio 0.82

## Selection frequency by primary dimension

Expected allocations per session per dimension: 4 + 2/12 = 4.1667.

- `contact_need`: pool=20; selections=41743 (expected 41666.7); expected mean per question 2083.3 (20.83%)
- `closeness_pace`: pool=39; selections=41678 (expected 41666.7); expected mean per question 1068.4 (10.68%)
- `initiative`: pool=29; selections=41632 (expected 41666.7); expected mean per question 1436.8 (14.37%)
- `autonomy`: pool=57; selections=41667 (expected 41666.7); expected mean per question 731.0 (7.31%)
- `reassurance_need`: pool=26; selections=41651 (expected 41666.7); expected mean per question 1602.6 (16.03%)
- `uncertainty_tolerance`: pool=27; selections=41643 (expected 41666.7); expected mean per question 1543.2 (15.43%)
- `disclosure_pace`: pool=35; selections=41760 (expected 41666.7); expected mean per question 1190.5 (11.90%)
- `boundary_firmness`: pool=52; selections=41646 (expected 41666.7); expected mean per question 801.3 (8.01%)
- `repair_style`: pool=25; selections=41610 (expected 41666.7); expected mean per question 1666.7 (16.67%)
- `social_energy`: pool=23; selections=41699 (expected 41666.7); expected mean per question 1811.6 (18.12%)
- `structure_preference`: pool=36; selections=41605 (expected 41666.7); expected mean per question 1157.4 (11.57%)
- `adaptability`: pool=36; selections=41666 (expected 41666.7); expected mean per question 1157.4 (11.57%)

## Same-cluster occupancy

Occupancy groups (session × dimension × cluster with at least one pick):
- 1: 309234
- 2: 43240
- 3: 18915
- 4+: 11585

Sessions whose max same-cluster occupancy (within a dimension) is:
- 1: 0
- 2: 22
- 3: 2079
- 4+: 7899

## Semantic-cluster representation per dimension

### `contact_need` (pool 20)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `contact_need:established` | 10 | 9806 | 98.06 | 15764 |
| `contact_need:early_dating` | 3 | 6814 | 68.14 | 7288 |
| `contact_need:support` | 2 | 5184 | 51.84 | 5296 |
| `contact_need:uncertainty` | 2 | 5069 | 50.69 | 5251 |
| `contact_need:unclassified` | 2 | 5101 | 51.01 | 5235 |
| `contact_need:boundaries` | 1 | 2909 | 29.09 | 2909 |

### `closeness_pace` (pool 39)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `closeness_pace:early_dating` | 34 | 10000 | 100.00 | 34355 |
| `closeness_pace:uncertainty` | 3 | 4056 | 40.56 | 4219 |
| `closeness_pace:established` | 1 | 1566 | 15.66 | 1566 |
| `closeness_pace:social` | 1 | 1538 | 15.38 | 1538 |

### `initiative` (pool 29)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `initiative:established` | 8 | 8693 | 86.93 | 10412 |
| `initiative:planning` | 8 | 8693 | 86.93 | 10324 |
| `initiative:early_dating` | 6 | 7716 | 77.16 | 8597 |
| `initiative:unclassified` | 4 | 6172 | 61.72 | 6331 |
| `initiative:conflict` | 1 | 1916 | 19.16 | 1916 |
| `initiative:social` | 1 | 2043 | 20.43 | 2043 |
| `initiative:support` | 1 | 2009 | 20.09 | 2009 |

### `autonomy` (pool 57)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `autonomy:established` | 20 | 9019 | 90.19 | 11682 |
| `autonomy:boundaries` | 10 | 6753 | 67.53 | 7407 |
| `autonomy:unclassified` | 9 | 6310 | 63.10 | 6865 |
| `autonomy:support` | 6 | 4808 | 48.08 | 4991 |
| `autonomy:planning` | 5 | 4203 | 42.03 | 4321 |
| `autonomy:social` | 3 | 2684 | 26.84 | 2706 |
| `autonomy:uncertainty` | 2 | 1780 | 17.80 | 1789 |
| `autonomy:conflict` | 1 | 985 | 9.85 | 985 |
| `autonomy:early_dating` | 1 | 921 | 9.21 | 921 |

### `reassurance_need` (pool 26)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `reassurance_need:uncertainty` | 7 | 8338 | 83.38 | 9350 |
| `reassurance_need:early_dating` | 5 | 7297 | 72.97 | 7796 |
| `reassurance_need:established` | 5 | 7110 | 71.10 | 7476 |
| `reassurance_need:social` | 3 | 5173 | 51.73 | 5300 |
| `reassurance_need:planning` | 2 | 3769 | 37.69 | 3791 |
| `reassurance_need:support` | 2 | 3788 | 37.88 | 3821 |
| `reassurance_need:boundaries` | 1 | 2099 | 20.99 | 2099 |
| `reassurance_need:conflict` | 1 | 2018 | 20.18 | 2018 |

### `uncertainty_tolerance` (pool 27)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `uncertainty_tolerance:uncertainty` | 9 | 9138 | 91.38 | 11529 |
| `uncertainty_tolerance:planning` | 6 | 7845 | 78.45 | 8804 |
| `uncertainty_tolerance:conflict` | 4 | 6386 | 63.86 | 6777 |
| `uncertainty_tolerance:early_dating` | 4 | 6345 | 63.45 | 6710 |
| `uncertainty_tolerance:support` | 2 | 3898 | 38.98 | 3943 |
| `uncertainty_tolerance:unclassified` | 2 | 3818 | 38.18 | 3880 |

### `disclosure_pace` (pool 35)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `disclosure_pace:early_dating` | 24 | 9982 | 99.82 | 23810 |
| `disclosure_pace:established` | 3 | 4513 | 45.13 | 4716 |
| `disclosure_pace:support` | 3 | 4538 | 45.38 | 4758 |
| `disclosure_pace:uncertainty` | 2 | 3265 | 32.65 | 3360 |
| `disclosure_pace:unclassified` | 2 | 3307 | 33.07 | 3380 |
| `disclosure_pace:conflict` | 1 | 1736 | 17.36 | 1736 |

### `boundary_firmness` (pool 52)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `boundary_firmness:established` | 25 | 9747 | 97.47 | 15909 |
| `boundary_firmness:conflict` | 8 | 6492 | 64.92 | 7209 |
| `boundary_firmness:boundaries` | 7 | 5959 | 59.59 | 6515 |
| `boundary_firmness:social` | 7 | 5919 | 59.19 | 6378 |
| `boundary_firmness:early_dating` | 2 | 2266 | 22.66 | 2279 |
| `boundary_firmness:planning` | 1 | 1087 | 10.87 | 1087 |
| `boundary_firmness:support` | 1 | 1095 | 10.95 | 1095 |
| `boundary_firmness:uncertainty` | 1 | 1174 | 11.74 | 1174 |

### `repair_style` (pool 25)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `repair_style:conflict` | 22 | 10000 | 100.00 | 34587 |
| `repair_style:established` | 2 | 4410 | 44.10 | 4612 |
| `repair_style:support` | 1 | 2411 | 24.11 | 2411 |

### `social_energy` (pool 23)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `social_energy:social` | 12 | 9966 | 99.66 | 18815 |
| `social_energy:established` | 7 | 9236 | 92.36 | 12359 |
| `social_energy:unclassified` | 2 | 4896 | 48.96 | 5088 |
| `social_energy:early_dating` | 1 | 2665 | 26.65 | 2665 |
| `social_energy:planning` | 1 | 2772 | 27.72 | 2772 |

### `structure_preference` (pool 36)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `structure_preference:planning` | 17 | 9801 | 98.01 | 16049 |
| `structure_preference:established` | 9 | 8404 | 84.04 | 10369 |
| `structure_preference:unclassified` | 4 | 5360 | 53.60 | 5675 |
| `structure_preference:early_dating` | 2 | 3077 | 30.77 | 3176 |
| `structure_preference:social` | 2 | 3190 | 31.90 | 3227 |
| `structure_preference:support` | 2 | 3069 | 30.69 | 3109 |

### `adaptability` (pool 36)

| cluster | pool | sessions_with_≥1 | pct | total_picks |
|---|---:|---:|---:|---:|
| `adaptability:established` | 10 | 8345 | 83.45 | 9670 |
| `adaptability:support` | 8 | 7702 | 77.02 | 8529 |
| `adaptability:planning` | 5 | 5783 | 57.83 | 6092 |
| `adaptability:early_dating` | 4 | 4914 | 49.14 | 5063 |
| `adaptability:unclassified` | 4 | 4972 | 49.72 | 5127 |
| `adaptability:boundaries` | 2 | 2829 | 28.29 | 2847 |
| `adaptability:conflict` | 2 | 2833 | 28.33 | 2849 |
| `adaptability:social` | 1 | 1489 | 14.89 | 1489 |

## All 405 questions

| question_id | dimension | count | pct | dim_expected_pct | ratio |
|---|---|---:|---:|---:|---:|
| `frequency_v2_q0001` | `initiative` | 1514 | 15.14 | 14.37 | 1.05 |
| `frequency_v2_q0002` | `structure_preference` | 939 | 9.39 | 11.57 | 0.81 |
| `frequency_v2_q0004` | `social_energy` | 1587 | 15.87 | 18.12 | 0.88 |
| `frequency_v2_q0005` | `uncertainty_tolerance` | 1726 | 17.26 | 15.43 | 1.12 |
| `frequency_v2_q0006` | `uncertainty_tolerance` | 1674 | 16.74 | 15.43 | 1.08 |
| `frequency_v2_q0007` | `autonomy` | 638 | 6.38 | 7.31 | 0.87 |
| `frequency_v2_q0008` | `disclosure_pace` | 1736 | 17.36 | 11.90 | 1.46 |
| `frequency_v2_q0009` | `closeness_pace` | 1041 | 10.41 | 10.68 | 0.97 |
| `frequency_v2_q0010` | `contact_need` | 1562 | 15.62 | 20.83 | 0.75 |
| `frequency_v2_q0011` | `adaptability` | 1293 | 12.93 | 11.57 | 1.12 |
| `frequency_v2_q0012` | `autonomy` | 577 | 5.77 | 7.31 | 0.79 |
| `frequency_v2_q0013` | `disclosure_pace` | 1032 | 10.32 | 11.90 | 0.87 |
| `frequency_v2_q0014` | `initiative` | 1293 | 12.93 | 14.37 | 0.90 |
| `frequency_v2_q0015` | `repair_style` | 1586 | 15.86 | 16.67 | 0.95 |
| `frequency_v2_q0016` | `boundary_firmness` | 634 | 6.34 | 8.01 | 0.79 |
| `frequency_v2_q0017` | `social_energy` | 1571 | 15.71 | 18.12 | 0.87 |
| `frequency_v2_q0018` | `uncertainty_tolerance` | 1983 | 19.83 | 15.43 | 1.28 |
| `frequency_v2_q0019` | `structure_preference` | 1142 | 11.42 | 11.57 | 0.99 |
| `frequency_v2_q0020` | `uncertainty_tolerance` | 1960 | 19.60 | 15.43 | 1.27 |
| `frequency_v2_q0021` | `social_energy` | 1830 | 18.30 | 18.12 | 1.01 |
| `frequency_v2_q0022` | `structure_preference` | 928 | 9.28 | 11.57 | 0.80 |
| `frequency_v2_q0024` | `boundary_firmness` | 937 | 9.37 | 8.01 | 1.17 |
| `frequency_v2_q0025` | `uncertainty_tolerance` | 1293 | 12.93 | 15.43 | 0.84 |
| `frequency_v2_q0026` | `uncertainty_tolerance` | 1683 | 16.83 | 15.43 | 1.09 |
| `frequency_v2_q0027` | `autonomy` | 832 | 8.32 | 7.31 | 1.14 |
| `frequency_v2_q0028` | `boundary_firmness` | 941 | 9.41 | 8.01 | 1.17 |
| `frequency_v2_q0030` | `uncertainty_tolerance` | 1353 | 13.53 | 15.43 | 0.88 |
| `frequency_v2_q0031` | `adaptability` | 899 | 8.99 | 11.57 | 0.78 |
| `frequency_v2_q0032` | `structure_preference` | 1602 | 16.02 | 11.57 | 1.38 |
| `frequency_v2_q0033` | `disclosure_pace` | 970 | 9.70 | 11.90 | 0.81 |
| `frequency_v2_q0034` | `autonomy` | 758 | 7.58 | 7.31 | 1.04 |
| `frequency_v2_q0035` | `disclosure_pace` | 1603 | 16.03 | 11.90 | 1.35 |
| `frequency_v2_q0036` | `reassurance_need` | 1907 | 19.07 | 16.03 | 1.19 |
| `frequency_v2_q0037` | `boundary_firmness` | 940 | 9.40 | 8.01 | 1.17 |
| `frequency_v2_q0038` | `adaptability` | 937 | 9.37 | 11.57 | 0.81 |
| `frequency_v2_q0039` | `structure_preference` | 1205 | 12.05 | 11.57 | 1.04 |
| `frequency_v2_q0040` | `initiative` | 1271 | 12.71 | 14.37 | 0.88 |
| `frequency_v2_q0041` | `contact_need` | 2546 | 25.46 | 20.83 | 1.22 |
| `frequency_v2_q0042` | `closeness_pace` | 1025 | 10.25 | 10.68 | 0.96 |
| `frequency_v2_q0043` | `autonomy` | 837 | 8.37 | 7.31 | 1.15 |
| `frequency_v2_q0044` | `autonomy` | 697 | 6.97 | 7.31 | 0.95 |
| `frequency_v2_q0045` | `structure_preference` | 1379 | 13.79 | 11.57 | 1.19 |
| `frequency_v2_q0046` | `uncertainty_tolerance` | 1955 | 19.55 | 15.43 | 1.27 |
| `frequency_v2_q0048` | `adaptability` | 1274 | 12.74 | 11.57 | 1.10 |
| `frequency_v2_q0049` | `reassurance_need` | 1376 | 13.76 | 16.03 | 0.86 |
| `frequency_v2_q0050` | `structure_preference` | 976 | 9.76 | 11.57 | 0.84 |
| `frequency_v2_q0051` | `initiative` | 1469 | 14.69 | 14.37 | 1.02 |
| `frequency_v2_q0052` | `reassurance_need` | 1525 | 15.25 | 16.03 | 0.95 |
| `frequency_v2_q0053` | `disclosure_pace` | 1006 | 10.06 | 11.90 | 0.85 |
| `frequency_v2_q0054` | `uncertainty_tolerance` | 1452 | 14.52 | 15.43 | 0.94 |
| `frequency_v2_q0055` | `social_energy` | 1651 | 16.51 | 18.12 | 0.91 |
| `frequency_v2_q0056` | `repair_style` | 1601 | 16.01 | 16.67 | 0.96 |
| `frequency_v2_q0057` | `reassurance_need` | 1562 | 15.62 | 16.03 | 0.97 |
| `frequency_v2_q0058` | `contact_need` | 2420 | 24.20 | 20.83 | 1.16 |
| `frequency_v2_q0059` | `social_energy` | 1870 | 18.70 | 18.12 | 1.03 |
| `frequency_v2_q0060` | `disclosure_pace` | 997 | 9.97 | 11.90 | 0.84 |
| `frequency_v2_q0061` | `structure_preference` | 1158 | 11.58 | 11.57 | 1.00 |
| `frequency_v2_q0062` | `adaptability` | 1246 | 12.46 | 11.57 | 1.08 |
| `frequency_v2_q0063` | `uncertainty_tolerance` | 1310 | 13.10 | 15.43 | 0.85 |
| `frequency_v2_q0064` | `repair_style` | 1517 | 15.17 | 16.67 | 0.91 |
| `frequency_v2_q0065` | `adaptability` | 1368 | 13.68 | 11.57 | 1.18 |
| `frequency_v2_q0066` | `social_energy` | 1855 | 18.55 | 18.12 | 1.02 |
| `frequency_v2_q0067` | `closeness_pace` | 1021 | 10.21 | 10.68 | 0.96 |
| `frequency_v2_q0068` | `reassurance_need` | 1446 | 14.46 | 16.03 | 0.90 |
| `frequency_v2_q0069` | `structure_preference` | 938 | 9.38 | 11.57 | 0.81 |
| `frequency_v2_q0070` | `autonomy` | 779 | 7.79 | 7.31 | 1.07 |
| `frequency_v2_q0071` | `reassurance_need` | 1649 | 16.49 | 16.03 | 1.03 |
| `frequency_v2_q0072` | `autonomy` | 567 | 5.67 | 7.31 | 0.78 |
| `frequency_v2_q0073` | `boundary_firmness` | 911 | 9.11 | 8.01 | 1.14 |
| `frequency_v2_q0074` | `uncertainty_tolerance` | 1669 | 16.69 | 15.43 | 1.08 |
| `frequency_v2_q0075` | `adaptability` | 1467 | 14.67 | 11.57 | 1.27 |
| `frequency_v2_q0076` | `closeness_pace` | 1458 | 14.58 | 10.68 | 1.36 |
| `frequency_v2_q0077` | `contact_need` | 1567 | 15.67 | 20.83 | 0.75 |
| `frequency_v2_q0078` | `initiative` | 1289 | 12.89 | 14.37 | 0.90 |
| `frequency_v2_q0079` | `initiative` | 1296 | 12.96 | 14.37 | 0.90 |
| `frequency_v2_q0080` | `initiative` | 1349 | 13.49 | 14.37 | 0.94 |
| `frequency_v2_q0081` | `closeness_pace` | 1054 | 10.54 | 10.68 | 0.99 |
| `frequency_v2_q0082` | `uncertainty_tolerance` | 1482 | 14.82 | 15.43 | 0.96 |
| `frequency_v2_q0083` | `repair_style` | 1609 | 16.09 | 16.67 | 0.97 |
| `frequency_v2_q0084` | `boundary_firmness` | 654 | 6.54 | 8.01 | 0.82 |
| `frequency_v2_q0085` | `adaptability` | 1489 | 14.89 | 11.57 | 1.29 |
| `frequency_v2_q0086` | `disclosure_pace` | 1001 | 10.01 | 11.90 | 0.84 |
| `frequency_v2_q0087` | `uncertainty_tolerance` | 1699 | 16.99 | 15.43 | 1.10 |
| `frequency_v2_q0088` | `repair_style` | 2232 | 22.32 | 16.67 | 1.34 |
| `frequency_v2_q0089` | `disclosure_pace` | 993 | 9.93 | 11.90 | 0.83 |
| `frequency_v2_q0090` | `autonomy` | 577 | 5.77 | 7.31 | 0.79 |
| `frequency_v2_q0091` | `initiative` | 1443 | 14.43 | 14.37 | 1.00 |
| `frequency_v2_q0092` | `autonomy` | 891 | 8.91 | 7.31 | 1.22 |
| `frequency_v2_q0093` | `uncertainty_tolerance` | 1209 | 12.09 | 15.43 | 0.78 |
| `frequency_v2_q0094` | `initiative` | 1280 | 12.80 | 14.37 | 0.89 |
| `frequency_v2_q0095` | `initiative` | 1607 | 16.07 | 14.37 | 1.12 |
| `frequency_v2_q0096` | `adaptability` | 1279 | 12.79 | 11.57 | 1.11 |
| `frequency_v2_q0097` | `repair_style` | 1575 | 15.75 | 16.67 | 0.94 |
| `frequency_v2_q0098` | `social_energy` | 1510 | 15.10 | 18.12 | 0.83 |
| `frequency_v2_q0099` | `initiative` | 1349 | 13.49 | 14.37 | 0.94 |
| `frequency_v2_q0100` | `closeness_pace` | 983 | 9.83 | 10.68 | 0.92 |
| `frequency_v2_q0101` | `initiative` | 1435 | 14.35 | 14.37 | 1.00 |
| `frequency_v2_q0102` | `reassurance_need` | 1550 | 15.50 | 16.03 | 0.97 |
| `frequency_v2_q0103` | `disclosure_pace` | 995 | 9.95 | 11.90 | 0.84 |
| `frequency_v2_q0104` | `uncertainty_tolerance` | 1254 | 12.54 | 15.43 | 0.81 |
| `frequency_v2_q0105` | `initiative` | 1280 | 12.80 | 14.37 | 0.89 |
| `frequency_v2_q0106` | `closeness_pace` | 992 | 9.92 | 10.68 | 0.93 |
| `frequency_v2_q0107` | `autonomy` | 575 | 5.75 | 7.31 | 0.79 |
| `frequency_v2_q0108` | `contact_need` | 1580 | 15.80 | 20.83 | 0.76 |
| `frequency_v2_q0109` | `uncertainty_tolerance` | 1254 | 12.54 | 15.43 | 0.81 |
| `frequency_v2_q0110` | `closeness_pace` | 1097 | 10.97 | 10.68 | 1.03 |
| `frequency_v2_q0111` | `structure_preference` | 1111 | 11.11 | 11.57 | 0.96 |
| `frequency_v2_q0112` | `structure_preference` | 933 | 9.33 | 11.57 | 0.81 |
| `frequency_v2_q0113` | `structure_preference` | 1625 | 16.25 | 11.57 | 1.40 |
| `frequency_v2_q0114` | `structure_preference` | 948 | 9.48 | 11.57 | 0.82 |
| `frequency_v2_q0115` | `adaptability` | 1007 | 10.07 | 11.57 | 0.87 |
| `frequency_v2_q0116` | `autonomy` | 758 | 7.58 | 7.31 | 1.04 |
| `frequency_v2_q0117` | `autonomy` | 592 | 5.92 | 7.31 | 0.81 |
| `frequency_v2_q0118` | `social_energy` | 2531 | 25.31 | 18.12 | 1.40 |
| `frequency_v2_q0119` | `autonomy` | 879 | 8.79 | 7.31 | 1.20 |
| `frequency_v2_q0120` | `adaptability` | 1193 | 11.93 | 11.57 | 1.03 |
| `frequency_v2_q0121` | `boundary_firmness` | 884 | 8.84 | 8.01 | 1.10 |
| `frequency_v2_q0122` | `repair_style` | 1562 | 15.62 | 16.67 | 0.94 |
| `frequency_v2_q0124` | `repair_style` | 2380 | 23.80 | 16.67 | 1.43 |
| `frequency_v2_q0125` | `repair_style` | 1504 | 15.04 | 16.67 | 0.90 |
| `frequency_v2_q0126` | `reassurance_need` | 1340 | 13.40 | 16.03 | 0.84 |
| `frequency_v2_q0129` | `repair_style` | 1564 | 15.64 | 16.67 | 0.94 |
| `frequency_v2_q0130` | `uncertainty_tolerance` | 1658 | 16.58 | 15.43 | 1.07 |
| `frequency_v2_q0131` | `autonomy` | 762 | 7.62 | 7.31 | 1.04 |
| `frequency_v2_q0132` | `reassurance_need` | 1326 | 13.26 | 16.03 | 0.83 |
| `frequency_v2_q0133` | `adaptability` | 1314 | 13.14 | 11.57 | 1.14 |
| `frequency_v2_q0134` | `contact_need` | 2584 | 25.84 | 20.83 | 1.24 |
| `frequency_v2_q0136` | `disclosure_pace` | 1016 | 10.16 | 11.90 | 0.85 |
| `frequency_v2_q0137` | `disclosure_pace` | 1723 | 17.23 | 11.90 | 1.45 |
| `frequency_v2_q0138` | `closeness_pace` | 1026 | 10.26 | 10.68 | 0.96 |
| `frequency_v2_q0139` | `closeness_pace` | 996 | 9.96 | 10.68 | 0.93 |
| `frequency_v2_q0140` | `structure_preference` | 1415 | 14.15 | 11.57 | 1.22 |
| `frequency_v2_q0141` | `contact_need` | 2651 | 26.51 | 20.83 | 1.27 |
| `frequency_v2_q0142` | `contact_need` | 1586 | 15.86 | 20.83 | 0.76 |
| `frequency_v2_q0143` | `boundary_firmness` | 865 | 8.65 | 8.01 | 1.08 |
| `frequency_v2_q0144` | `structure_preference` | 1565 | 15.65 | 11.57 | 1.35 |
| `frequency_v2_q0145` | `repair_style` | 2411 | 24.11 | 16.67 | 1.45 |
| `frequency_v2_q0146` | `structure_preference` | 1188 | 11.88 | 11.57 | 1.03 |
| `frequency_v2_q0147` | `reassurance_need` | 2099 | 20.99 | 16.03 | 1.31 |
| `frequency_v2_q0148` | `adaptability` | 1479 | 14.79 | 11.57 | 1.28 |
| `frequency_v2_q0149` | `structure_preference` | 918 | 9.18 | 11.57 | 0.79 |
| `frequency_v2_q0150` | `closeness_pace` | 979 | 9.79 | 10.68 | 0.92 |
| `frequency_v2_q0151` | `structure_preference` | 1560 | 15.60 | 11.57 | 1.35 |
| `frequency_v2_q0152` | `uncertainty_tolerance` | 1668 | 16.68 | 15.43 | 1.08 |
| `frequency_v2_q0154` | `initiative` | 1367 | 13.67 | 14.37 | 0.95 |
| `frequency_v2_q0155` | `autonomy` | 845 | 8.45 | 7.31 | 1.16 |
| `frequency_v2_q0156` | `closeness_pace` | 1566 | 15.66 | 10.68 | 1.47 |
| `frequency_v2_q0157` | `disclosure_pace` | 994 | 9.94 | 11.90 | 0.83 |
| `frequency_v2_q0158` | `boundary_firmness` | 857 | 8.57 | 8.01 | 1.07 |
| `frequency_v2_q0159` | `structure_preference` | 1616 | 16.16 | 11.57 | 1.40 |
| `frequency_v2_q0160` | `closeness_pace` | 1041 | 10.41 | 10.68 | 0.97 |
| `frequency_v2_q0161` | `autonomy` | 574 | 5.74 | 7.31 | 0.79 |
| `frequency_v2_q0162` | `reassurance_need` | 1954 | 19.54 | 16.03 | 1.22 |
| `frequency_v2_q0163` | `adaptability` | 1008 | 10.08 | 11.57 | 0.87 |
| `frequency_v2_q0164` | `uncertainty_tolerance` | 1710 | 17.10 | 15.43 | 1.11 |
| `frequency_v2_q0165` | `autonomy` | 734 | 7.34 | 7.31 | 1.00 |
| `frequency_v2_q0166` | `repair_style` | 1660 | 16.60 | 16.67 | 1.00 |
| `frequency_v2_q0167` | `reassurance_need` | 1884 | 18.84 | 16.03 | 1.18 |
| `frequency_v2_q0168` | `adaptability` | 955 | 9.55 | 11.57 | 0.83 |
| `frequency_v2_q0169` | `contact_need` | 2652 | 26.52 | 20.83 | 1.27 |
| `frequency_v2_q0170` | `boundary_firmness` | 906 | 9.06 | 8.01 | 1.13 |
| `frequency_v2_q0171` | `reassurance_need` | 1347 | 13.47 | 16.03 | 0.84 |
| `frequency_v2_q0172` | `structure_preference` | 1109 | 11.09 | 11.57 | 0.96 |
| `frequency_v2_q0173` | `uncertainty_tolerance` | 1532 | 15.32 | 15.43 | 0.99 |
| `frequency_v2_q0174` | `boundary_firmness` | 674 | 6.74 | 8.01 | 0.84 |
| `frequency_v2_q0175` | `social_energy` | 2772 | 27.72 | 18.12 | 1.53 |
| `frequency_v2_q0176` | `adaptability` | 986 | 9.86 | 11.57 | 0.85 |
| `frequency_v2_q0177` | `disclosure_pace` | 1059 | 10.59 | 11.90 | 0.89 |
| `frequency_v2_q0178` | `contact_need` | 1591 | 15.91 | 20.83 | 0.76 |
| `frequency_v2_q0179` | `autonomy` | 601 | 6.01 | 7.31 | 0.82 |
| `frequency_v2_q0180` | `structure_preference` | 1544 | 15.44 | 11.57 | 1.33 |
| `frequency_v2_q0181` | `closeness_pace` | 998 | 9.98 | 10.68 | 0.93 |
| `frequency_v2_q0182` | `structure_preference` | 1446 | 14.46 | 11.57 | 1.25 |
| `frequency_v2_q0183` | `boundary_firmness` | 1095 | 10.95 | 8.01 | 1.37 |
| `frequency_v2_q0184` | `autonomy` | 766 | 7.66 | 7.31 | 1.05 |
| `frequency_v2_q0185` | `boundary_firmness` | 893 | 8.93 | 8.01 | 1.11 |
| `frequency_v2_q0186` | `repair_style` | 1628 | 16.28 | 16.67 | 0.98 |
| `frequency_v2_q0187` | `contact_need` | 2909 | 29.09 | 20.83 | 1.40 |
| `frequency_v2_q0188` | `social_energy` | 1599 | 15.99 | 18.12 | 0.88 |
| `frequency_v2_q0189` | `structure_preference` | 865 | 8.65 | 11.57 | 0.75 |
| `frequency_v2_q0190` | `uncertainty_tolerance` | 1925 | 19.25 | 15.43 | 1.25 |
| `frequency_v2_q0192` | `autonomy` | 857 | 8.57 | 7.31 | 1.17 |
| `frequency_v2_q0193` | `disclosure_pace` | 1582 | 15.82 | 11.90 | 1.33 |
| `frequency_v2_q0194` | `social_energy` | 1558 | 15.58 | 18.12 | 0.86 |
| `frequency_v2_q0195` | `uncertainty_tolerance` | 1302 | 13.02 | 15.43 | 0.84 |
| `frequency_v2_q0196` | `initiative` | 1253 | 12.53 | 14.37 | 0.87 |
| `frequency_v2_q0197` | `autonomy` | 829 | 8.29 | 7.31 | 1.13 |
| `frequency_v2_q0198` | `adaptability` | 1086 | 10.86 | 11.57 | 0.94 |
| `frequency_v2_q0199` | `disclosure_pace` | 930 | 9.30 | 11.90 | 0.78 |
| `frequency_v2_q0200` | `boundary_firmness` | 610 | 6.10 | 8.01 | 0.76 |
| `frequency_v2_q0201` | `autonomy` | 573 | 5.73 | 7.31 | 0.78 |
| `frequency_v2_q0202` | `closeness_pace` | 1088 | 10.88 | 10.68 | 1.02 |
| `frequency_v2_q0203` | `boundary_firmness` | 1148 | 11.48 | 8.01 | 1.43 |
| `frequency_v2_q0204` | `contact_need` | 1539 | 15.39 | 20.83 | 0.74 |
| `frequency_v2_q0205` | `contact_need` | 2473 | 24.73 | 20.83 | 1.19 |
| `frequency_v2_q0206` | `boundary_firmness` | 610 | 6.10 | 8.01 | 0.76 |
| `frequency_v2_q0207` | `autonomy` | 894 | 8.94 | 7.31 | 1.22 |
| `frequency_v2_q0208` | `autonomy` | 921 | 9.21 | 7.31 | 1.26 |
| `frequency_v2_q0209` | `boundary_firmness` | 650 | 6.50 | 8.01 | 0.81 |
| `frequency_v2_q0210` | `closeness_pace` | 979 | 9.79 | 10.68 | 0.92 |
| `frequency_v2_q0211` | `structure_preference` | 939 | 9.39 | 11.57 | 0.81 |
| `frequency_v2_q0212` | `repair_style` | 1605 | 16.05 | 16.67 | 0.96 |
| `frequency_v2_q0213` | `closeness_pace` | 981 | 9.81 | 10.68 | 0.92 |
| `frequency_v2_q0214` | `social_energy` | 1834 | 18.34 | 18.12 | 1.01 |
| `frequency_v2_q0215` | `disclosure_pace` | 941 | 9.41 | 11.90 | 0.79 |
| `frequency_v2_q0216` | `autonomy` | 769 | 7.69 | 7.31 | 1.05 |
| `frequency_v2_q0217` | `structure_preference` | 1001 | 10.01 | 11.57 | 0.86 |
| `frequency_v2_q0218` | `initiative` | 1916 | 19.16 | 14.37 | 1.33 |
| `frequency_v2_q0219` | `autonomy` | 601 | 6.01 | 7.31 | 0.82 |
| `frequency_v2_q0220` | `closeness_pace` | 1011 | 10.11 | 10.68 | 0.95 |
| `frequency_v2_q0221` | `boundary_firmness` | 649 | 6.49 | 8.01 | 0.81 |
| `frequency_v2_q0222` | `boundary_firmness` | 899 | 8.99 | 8.01 | 1.12 |
| `frequency_v2_q0223` | `adaptability` | 1298 | 12.98 | 11.57 | 1.12 |
| `frequency_v2_q0224` | `autonomy` | 985 | 9.85 | 7.31 | 1.35 |
| `frequency_v2_q0225` | `disclosure_pace` | 932 | 9.32 | 11.90 | 0.78 |
| `frequency_v2_q0226` | `initiative` | 1303 | 13.03 | 14.37 | 0.91 |
| `frequency_v2_q0227` | `adaptability` | 1002 | 10.02 | 11.57 | 0.87 |
| `frequency_v2_q0228` | `adaptability` | 1272 | 12.72 | 11.57 | 1.10 |
| `frequency_v2_q0229` | `repair_style` | 1579 | 15.79 | 16.67 | 0.95 |
| `frequency_v2_q0230` | `disclosure_pace` | 985 | 9.85 | 11.90 | 0.83 |
| `frequency_v2_q0231` | `autonomy` | 769 | 7.69 | 7.31 | 1.05 |
| `frequency_v2_q0232` | `closeness_pace` | 1037 | 10.37 | 10.68 | 0.97 |
| `frequency_v2_q0233` | `boundary_firmness` | 602 | 6.02 | 8.01 | 0.75 |
| `frequency_v2_q0234` | `social_energy` | 1462 | 14.62 | 18.12 | 0.81 |
| `frequency_v2_q0235` | `boundary_firmness` | 852 | 8.52 | 8.01 | 1.06 |
| `frequency_v2_q0236` | `closeness_pace` | 957 | 9.57 | 10.68 | 0.90 |
| `frequency_v2_q0237` | `adaptability` | 1141 | 11.41 | 11.57 | 0.99 |
| `frequency_v2_q0238` | `boundary_firmness` | 598 | 5.98 | 8.01 | 0.75 |
| `frequency_v2_q0239` | `disclosure_pace` | 1541 | 15.41 | 11.90 | 1.29 |
| `frequency_v2_q0240` | `disclosure_pace` | 907 | 9.07 | 11.90 | 0.76 |
| `frequency_v2_q0241` | `closeness_pace` | 959 | 9.59 | 10.68 | 0.90 |
| `frequency_v2_q0242` | `repair_style` | 1544 | 15.44 | 16.67 | 0.93 |
| `frequency_v2_q0243` | `social_energy` | 1644 | 16.44 | 18.12 | 0.91 |
| `frequency_v2_q0244` | `closeness_pace` | 1414 | 14.14 | 10.68 | 1.32 |
| `frequency_v2_q0245` | `boundary_firmness` | 656 | 6.56 | 8.01 | 0.82 |
| `frequency_v2_q0246` | `adaptability` | 971 | 9.71 | 11.57 | 0.84 |
| `frequency_v2_q0247` | `initiative` | 1594 | 15.94 | 14.37 | 1.11 |
| `frequency_v2_q0248` | `closeness_pace` | 946 | 9.46 | 10.68 | 0.89 |
| `frequency_v2_q0249` | `repair_style` | 1553 | 15.53 | 16.67 | 0.93 |
| `frequency_v2_q0250` | `initiative` | 1302 | 13.02 | 14.37 | 0.91 |
| `frequency_v2_q0251` | `structure_preference` | 1155 | 11.55 | 11.57 | 1.00 |
| `frequency_v2_q0253` | `autonomy` | 568 | 5.68 | 7.31 | 0.78 |
| `frequency_v2_q0254` | `contact_need` | 2644 | 26.44 | 20.83 | 1.27 |
| `frequency_v2_q0255` | `adaptability` | 1059 | 10.59 | 11.57 | 0.91 |
| `frequency_v2_q0256` | `disclosure_pace` | 1018 | 10.18 | 11.90 | 0.86 |
| `frequency_v2_q0257` | `social_energy` | 1611 | 16.11 | 18.12 | 0.89 |
| `frequency_v2_q0258` | `autonomy` | 571 | 5.71 | 7.31 | 0.78 |
| `frequency_v2_q0259` | `contact_need` | 1548 | 15.48 | 20.83 | 0.74 |
| `frequency_v2_q0260` | `boundary_firmness` | 922 | 9.22 | 8.01 | 1.15 |
| `frequency_v2_q0261` | `repair_style` | 1605 | 16.05 | 16.67 | 0.96 |
| `frequency_v2_q0262` | `disclosure_pace` | 1674 | 16.74 | 11.90 | 1.41 |
| `frequency_v2_q0263` | `boundary_firmness` | 619 | 6.19 | 8.01 | 0.77 |
| `frequency_v2_q0264` | `disclosure_pace` | 1595 | 15.95 | 11.90 | 1.34 |
| `frequency_v2_q0265` | `social_energy` | 1685 | 16.85 | 18.12 | 0.93 |
| `frequency_v2_q0266` | `boundary_firmness` | 1087 | 10.87 | 8.01 | 1.36 |
| `frequency_v2_q0267` | `uncertainty_tolerance` | 1427 | 14.27 | 15.43 | 0.92 |
| `frequency_v2_q0268` | `adaptability` | 996 | 9.96 | 11.57 | 0.86 |
| `frequency_v2_q0269` | `autonomy` | 728 | 7.28 | 7.31 | 1.00 |
| `frequency_v2_q0270` | `reassurance_need` | 1288 | 12.88 | 16.03 | 0.80 |
| `frequency_v2_q0271` | `adaptability` | 1078 | 10.78 | 11.57 | 0.93 |
| `frequency_v2_q0272` | `reassurance_need` | 1523 | 15.23 | 16.03 | 0.95 |
| `frequency_v2_q0273` | `structure_preference` | 982 | 9.82 | 11.57 | 0.85 |
| `frequency_v2_q0274` | `contact_need` | 1614 | 16.14 | 20.83 | 0.77 |
| `frequency_v2_q0275` | `autonomy` | 852 | 8.52 | 7.31 | 1.17 |
| `frequency_v2_q0276` | `disclosure_pace` | 1036 | 10.36 | 11.90 | 0.87 |
| `frequency_v2_q0277` | `structure_preference` | 968 | 9.68 | 11.57 | 0.84 |
| `frequency_v2_q0278` | `boundary_firmness` | 918 | 9.18 | 8.01 | 1.15 |
| `frequency_v2_q0279` | `contact_need` | 2705 | 27.05 | 20.83 | 1.30 |
| `frequency_v2_q0280` | `social_energy` | 2557 | 25.57 | 18.12 | 1.41 |
| `frequency_v2_q0281` | `closeness_pace` | 1538 | 15.38 | 10.68 | 1.44 |
| `frequency_v2_q0282` | `autonomy` | 866 | 8.66 | 7.31 | 1.18 |
| `frequency_v2_q0283` | `reassurance_need` | 1867 | 18.67 | 16.03 | 1.17 |
| `frequency_v2_q0284` | `disclosure_pace` | 1593 | 15.93 | 11.90 | 1.34 |
| `frequency_v2_q0285` | `structure_preference` | 1435 | 14.35 | 11.57 | 1.24 |
| `frequency_v2_q0286` | `reassurance_need` | 1749 | 17.49 | 16.03 | 1.09 |
| `frequency_v2_q0287` | `boundary_firmness` | 908 | 9.08 | 8.01 | 1.13 |
| `frequency_v2_q0288` | `initiative` | 1319 | 13.19 | 14.37 | 0.92 |
| `frequency_v2_q0289` | `reassurance_need` | 1284 | 12.84 | 16.03 | 0.80 |
| `frequency_v2_q0290` | `autonomy` | 763 | 7.63 | 7.31 | 1.04 |
| `frequency_v2_q0291` | `autonomy` | 568 | 5.68 | 7.31 | 0.78 |
| `frequency_v2_q0293` | `disclosure_pace` | 1686 | 16.86 | 11.90 | 1.42 |
| `frequency_v2_q0294` | `autonomy` | 745 | 7.45 | 7.31 | 1.02 |
| `frequency_v2_q0295` | `disclosure_pace` | 1560 | 15.60 | 11.90 | 1.31 |
| `frequency_v2_q0296` | `boundary_firmness` | 601 | 6.01 | 8.01 | 0.75 |
| `frequency_v2_q0297` | `autonomy` | 718 | 7.18 | 7.31 | 0.98 |
| `frequency_v2_q0298` | `adaptability` | 1136 | 11.36 | 11.57 | 0.98 |
| `frequency_v2_q0299` | `social_energy` | 1540 | 15.40 | 18.12 | 0.85 |
| `frequency_v2_q0300` | `autonomy` | 844 | 8.44 | 7.31 | 1.15 |
| `frequency_v2_q0301` | `autonomy` | 565 | 5.65 | 7.31 | 0.77 |
| `frequency_v2_q0302` | `contact_need` | 2395 | 23.95 | 20.83 | 1.15 |
| `frequency_v2_q0303` | `autonomy` | 564 | 5.64 | 7.31 | 0.77 |
| `frequency_v2_q0304` | `autonomy` | 594 | 5.94 | 7.31 | 0.81 |
| `frequency_v2_q0305` | `closeness_pace` | 1026 | 10.26 | 10.68 | 0.96 |
| `frequency_v2_q0306` | `repair_style` | 1608 | 16.08 | 16.67 | 0.96 |
| `frequency_v2_q0307` | `social_energy` | 1636 | 16.36 | 18.12 | 0.90 |
| `frequency_v2_q0308` | `closeness_pace` | 1023 | 10.23 | 10.68 | 0.96 |
| `frequency_v2_q0309` | `structure_preference` | 995 | 9.95 | 11.57 | 0.86 |
| `frequency_v2_q0310` | `repair_style` | 1565 | 15.65 | 16.67 | 0.94 |
| `frequency_v2_q0311` | `boundary_firmness` | 663 | 6.63 | 8.01 | 0.83 |
| `frequency_v2_q0312` | `initiative` | 1387 | 13.87 | 14.37 | 0.97 |
| `frequency_v2_q0313` | `boundary_firmness` | 1131 | 11.31 | 8.01 | 1.41 |
| `frequency_v2_q0314` | `initiative` | 1308 | 13.08 | 14.37 | 0.91 |
| `frequency_v2_q0315` | `reassurance_need` | 1485 | 14.85 | 16.03 | 0.93 |
| `frequency_v2_q0316` | `closeness_pace` | 1011 | 10.11 | 10.68 | 0.95 |
| `frequency_v2_q0317` | `repair_style` | 1549 | 15.49 | 16.67 | 0.93 |
| `frequency_v2_q0318` | `initiative` | 1259 | 12.59 | 14.37 | 0.88 |
| `frequency_v2_q0319` | `disclosure_pace` | 1007 | 10.07 | 11.90 | 0.85 |
| `frequency_v2_q0320` | `social_energy` | 1520 | 15.20 | 18.12 | 0.84 |
| `frequency_v2_q0322` | `closeness_pace` | 1347 | 13.47 | 10.68 | 1.26 |
| `frequency_v2_q0323` | `uncertainty_tolerance` | 1451 | 14.51 | 15.43 | 0.94 |
| `frequency_v2_q0324` | `adaptability` | 1382 | 13.82 | 11.57 | 1.19 |
| `frequency_v2_q0325` | `closeness_pace` | 1050 | 10.50 | 10.68 | 0.98 |
| `frequency_v2_q0326` | `initiative` | 1321 | 13.21 | 14.37 | 0.92 |
| `frequency_v2_q0327` | `disclosure_pace` | 1002 | 10.02 | 11.90 | 0.84 |
| `frequency_v2_q0328` | `autonomy` | 706 | 7.06 | 7.31 | 0.97 |
| `frequency_v2_q0329` | `adaptability` | 1214 | 12.14 | 11.57 | 1.05 |
| `frequency_v2_q0330` | `disclosure_pace` | 993 | 9.93 | 11.90 | 0.83 |
| `frequency_v2_q0331` | `repair_style` | 1465 | 14.65 | 16.67 | 0.88 |
| `frequency_v2_q0334` | `autonomy` | 617 | 6.17 | 7.31 | 0.84 |
| `frequency_v2_q0335` | `adaptability` | 987 | 9.87 | 11.57 | 0.85 |
| `frequency_v2_q0336` | `initiative` | 1597 | 15.97 | 14.37 | 1.11 |
| `frequency_v2_q0337` | `uncertainty_tolerance` | 1256 | 12.56 | 15.43 | 0.81 |
| `frequency_v2_q0338` | `boundary_firmness` | 674 | 6.74 | 8.01 | 0.84 |
| `frequency_v2_q0339` | `closeness_pace` | 982 | 9.82 | 10.68 | 0.92 |
| `frequency_v2_q0340` | `boundary_firmness` | 607 | 6.07 | 8.01 | 0.76 |
| `frequency_v2_q0341` | `disclosure_pace` | 948 | 9.48 | 11.90 | 0.80 |
| `frequency_v2_q0342` | `adaptability` | 1219 | 12.19 | 11.57 | 1.05 |
| `frequency_v2_q0343` | `reassurance_need` | 1432 | 14.32 | 16.03 | 0.89 |
| `frequency_v2_q0344` | `boundary_firmness` | 897 | 8.97 | 8.01 | 1.12 |
| `frequency_v2_q0345` | `autonomy` | 759 | 7.59 | 7.31 | 1.04 |
| `frequency_v2_q0346` | `adaptability` | 1052 | 10.52 | 11.57 | 0.91 |
| `frequency_v2_q0347` | `reassurance_need` | 1549 | 15.49 | 16.03 | 0.97 |
| `frequency_v2_q0348` | `autonomy` | 895 | 8.95 | 7.31 | 1.22 |
| `frequency_v2_q0349` | `structure_preference` | 943 | 9.43 | 11.57 | 0.81 |
| `frequency_v2_q0350` | `reassurance_need` | 1803 | 18.03 | 16.03 | 1.13 |
| `frequency_v2_q0351` | `boundary_firmness` | 939 | 9.39 | 8.01 | 1.17 |
| `frequency_v2_q0352` | `autonomy` | 719 | 7.19 | 7.31 | 0.98 |
| `frequency_v2_q0353` | `boundary_firmness` | 675 | 6.75 | 8.01 | 0.84 |
| `frequency_v2_q0354` | `disclosure_pace` | 1052 | 10.52 | 11.90 | 0.88 |
| `frequency_v2_q0355` | `structure_preference` | 1115 | 11.15 | 11.57 | 0.96 |
| `frequency_v2_q0356` | `autonomy` | 768 | 7.68 | 7.31 | 1.05 |
| `frequency_v2_q0357` | `adaptability` | 930 | 9.30 | 11.57 | 0.80 |
| `frequency_v2_q0358` | `autonomy` | 936 | 9.36 | 7.31 | 1.28 |
| `frequency_v2_q0359` | `initiative` | 2043 | 20.43 | 14.37 | 1.42 |
| `frequency_v2_q0360` | `closeness_pace` | 1006 | 10.06 | 10.68 | 0.94 |
| `frequency_v2_q0362` | `adaptability` | 1304 | 13.04 | 11.57 | 1.13 |
| `frequency_v2_q0363` | `boundary_firmness` | 986 | 9.86 | 8.01 | 1.23 |
| `frequency_v2_q0364` | `boundary_firmness` | 1174 | 11.74 | 8.01 | 1.47 |
| `frequency_v2_q0365` | `reassurance_need` | 2018 | 20.18 | 16.03 | 1.26 |
| `frequency_v2_q0366` | `structure_preference` | 901 | 9.01 | 11.57 | 0.78 |
| `frequency_v2_q0367` | `autonomy` | 584 | 5.84 | 7.31 | 0.80 |
| `frequency_v2_q0368` | `autonomy` | 799 | 7.99 | 7.31 | 1.09 |
| `frequency_v2_q0369` | `autonomy` | 859 | 8.59 | 7.31 | 1.18 |
| `frequency_v2_q0370` | `uncertainty_tolerance` | 1298 | 12.98 | 15.43 | 0.84 |
| `frequency_v2_q0371` | `boundary_firmness` | 599 | 5.99 | 8.01 | 0.75 |
| `frequency_v2_q0372` | `boundary_firmness` | 943 | 9.43 | 8.01 | 1.18 |
| `frequency_v2_q0374` | `boundary_firmness` | 909 | 9.09 | 8.01 | 1.13 |
| `frequency_v2_q0375` | `autonomy` | 923 | 9.23 | 7.31 | 1.26 |
| `frequency_v2_q0376` | `autonomy` | 778 | 7.78 | 7.31 | 1.06 |
| `frequency_v2_q0377` | `adaptability` | 1041 | 10.41 | 11.57 | 0.90 |
| `frequency_v2_q0378` | `autonomy` | 765 | 7.65 | 7.31 | 1.05 |
| `frequency_v2_q0379` | `autonomy` | 573 | 5.73 | 7.31 | 0.78 |
| `frequency_v2_q0381` | `boundary_firmness` | 908 | 9.08 | 8.01 | 1.13 |
| `frequency_v2_q0382` | `initiative` | 2009 | 20.09 | 14.37 | 1.40 |
| `frequency_v2_q0383` | `adaptability` | 1069 | 10.69 | 11.57 | 0.92 |
| `frequency_v2_q0384` | `structure_preference` | 1186 | 11.86 | 11.57 | 1.02 |
| `frequency_v2_q0385` | `disclosure_pace` | 1657 | 16.57 | 11.90 | 1.39 |
| `frequency_v2_q0386` | `contact_need` | 1624 | 16.24 | 20.83 | 0.78 |
| `frequency_v2_q0387` | `reassurance_need` | 1389 | 13.89 | 16.03 | 0.87 |
| `frequency_v2_q0388` | `structure_preference` | 948 | 9.48 | 11.57 | 0.82 |
| `frequency_v2_q0389` | `boundary_firmness` | 947 | 9.47 | 8.01 | 1.18 |
| `frequency_v2_q0390` | `repair_style` | 1573 | 15.73 | 16.67 | 0.94 |
| `frequency_v2_q0391` | `reassurance_need` | 1748 | 17.48 | 16.03 | 1.09 |
| `frequency_v2_q0392` | `autonomy` | 603 | 6.03 | 7.31 | 0.82 |
| `frequency_v2_q0393` | `adaptability` | 1235 | 12.35 | 11.57 | 1.07 |
| `frequency_v2_q0394` | `boundary_firmness` | 655 | 6.55 | 8.01 | 0.82 |
| `frequency_v2_q0395` | `closeness_pace` | 1055 | 10.55 | 10.68 | 0.99 |
| `frequency_v2_q0396` | `boundary_firmness` | 651 | 6.51 | 8.01 | 0.81 |
| `frequency_v2_q0397` | `social_energy` | 2665 | 26.65 | 18.12 | 1.47 |
| `frequency_v2_q0398` | `closeness_pace` | 924 | 9.24 | 10.68 | 0.86 |
| `frequency_v2_q0399` | `repair_style` | 1582 | 15.82 | 16.67 | 0.95 |
| `frequency_v2_q0400` | `boundary_firmness` | 647 | 6.47 | 8.01 | 0.81 |
| `frequency_v2_q0401` | `contact_need` | 1553 | 15.53 | 20.83 | 0.75 |
| `frequency_v2_q0402` | `closeness_pace` | 1064 | 10.64 | 10.68 | 1.00 |
| `frequency_v2_q0403` | `boundary_firmness` | 615 | 6.15 | 8.01 | 0.77 |
| `frequency_v2_q0404` | `uncertainty_tolerance` | 1460 | 14.60 | 15.43 | 0.95 |
| `frequency_v2_q0406` | `boundary_firmness` | 631 | 6.31 | 8.01 | 0.79 |
| `frequency_v2_q0407` | `closeness_pace` | 999 | 9.99 | 10.68 | 0.94 |
| `frequency_v2_q0408` | `boundary_firmness` | 642 | 6.42 | 8.01 | 0.80 |
| `frequency_v2_q0410` | `closeness_pace` | 1052 | 10.52 | 10.68 | 0.98 |
| `frequency_v2_q0411` | `initiative` | 1246 | 12.46 | 14.37 | 0.87 |
| `frequency_v2_q0412` | `structure_preference` | 927 | 9.27 | 11.57 | 0.80 |
| `frequency_v2_q0413` | `boundary_firmness` | 940 | 9.40 | 8.01 | 1.17 |
| `frequency_v2_q0414` | `disclosure_pace` | 962 | 9.62 | 11.90 | 0.81 |
| `frequency_v2_q0415` | `reassurance_need` | 1551 | 15.51 | 16.03 | 0.97 |
| `frequency_v2_q0416` | `closeness_pace` | 979 | 9.79 | 10.68 | 0.92 |
| `frequency_v2_q0417` | `social_energy` | 1521 | 15.21 | 18.12 | 0.84 |
| `frequency_v2_q0418` | `disclosure_pace` | 1034 | 10.34 | 11.90 | 0.87 |
| `frequency_v2_q0419` | `closeness_pace` | 968 | 9.68 | 10.68 | 0.91 |
| `frequency_v2_q0420` | `initiative` | 1533 | 15.33 | 14.37 | 1.07 |
| `frequency_v2_q0421` | `boundary_firmness` | 694 | 6.94 | 8.01 | 0.87 |
| `frequency_v2_q0422` | `closeness_pace` | 1005 | 10.05 | 10.68 | 0.94 |
| `frequency_v2_q0423` | `social_energy` | 1690 | 16.90 | 18.12 | 0.93 |
| `frequency_v2_q0424` | `boundary_firmness` | 599 | 5.99 | 8.01 | 0.75 |
| `frequency_v2_q0425` | `repair_style` | 1553 | 15.53 | 16.67 | 0.93 |

## Safety

- V2 not activated
- pool text / weights / evidence values not modified by this simulation
- option shuffle stream `options|{question_id}` unchanged
- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter

FREQUENCY V2 PHASE 3C SOFT-DIVERSITY SELECTOR AUDIT COMPLETE — V2 STILL DORMANT
