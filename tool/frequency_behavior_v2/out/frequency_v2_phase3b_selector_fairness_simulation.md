# Frequency V2 Phase 3B — Selector fairness simulation

Status: **offline / dormant**. `runtime_selectable` remains false.
Selector: `frequency_behavior_v2_selector_v1`
Bank: `frequency_behavior_pool_tr_v2_draft1`
Seeds: `phase3b-sim-0` … `phase3b-sim-9999`
Sessions: **10000**

Candidate order is a per-question FNV rank from
`selector_version + bank_version + session_seed + primary_dimension + question_id`
**before** diversity caps. Frequencies were not retuned after seeing the numbers.

## Phase 3A invariants

- Sessions with != 50 unique question IDs: **0**
- Coverage failures (not 4/5 with exactly two fives): **0**
- DROP / ineligible leaks: **0**
- Archive DROP IDs: **21**
- Selectable IDs tracked: **405**
- Extra-slot min/max/mean: 1599 / 1752 / 1666.67 (expected 1666.67)

- `contact_need`: 1616 (16.16%)
- `closeness_pace`: 1700 (17.00%)
- `initiative`: 1656 (16.56%)
- `autonomy`: 1641 (16.41%)
- `reassurance_need`: 1752 (17.52%)
- `uncertainty_tolerance`: 1631 (16.31%)
- `disclosure_pace`: 1636 (16.36%)
- `boundary_firmness`: 1697 (16.97%)
- `repair_style`: 1695 (16.95%)
- `social_energy`: 1675 (16.75%)
- `structure_preference`: 1702 (17.02%)
- `adaptability`: 1599 (15.99%)

## Consecutive same-dimension

- adjacent pairs: 490000
- adjacent same-primary pairs: 26 (0.005%)
- sessions with at least one 2-streak: 26
- max streak observed: 2 (cap is 2)

## Option-position distribution

Total placements per slot: 500000

- display slot 0: a=125032, b=125552, c=124675, d=124741
- display slot 1: a=124979, b=125019, c=125593, d=124409
- display slot 2: a=124701, b=124968, c=124809, d=125522
- display slot 3: a=125288, b=124461, c=124923, d=125328

## Question selection frequency (405 selectable)

- min count / pct: **542** / **5.42%**
- median count / pct: **1004.0** / **10.04%**
- mean count / pct: **1234.568** / **12.35%**
- max count / pct: **7282** / **72.82%**
- questions ever selected: **405**
- questions never selected: **0**
- questions selected in every session: **0**

### Never selected

- none

### Selected in 100% of sessions

- none

No question was selected in 100% of sessions. Smallest dimension pool is 20, which is larger than the max per-dimension quota (5), so 100% coverage is not mathematically required.

### Former Phase 3A 100% items (must not remain mandatory)

- `frequency_v2_q0145` (repair_style): 7282 (72.82%)
- `frequency_v2_q0156` (closeness_pace): 4771 (47.71%)
- `frequency_v2_q0281` (closeness_pace): 4778 (47.78%)

### Top 20 most-selected

- `frequency_v2_q0145` (repair_style): 7282 (72.82%); dim expected 16.67%; ratio 4.37
- `frequency_v2_q0124` (repair_style): 7215 (72.15%); dim expected 16.67%; ratio 4.33
- `frequency_v2_q0088` (repair_style): 7211 (72.11%); dim expected 16.67%; ratio 4.33
- `frequency_v2_q0076` (closeness_pace): 4825 (48.25%); dim expected 10.68%; ratio 4.52
- `frequency_v2_q0281` (closeness_pace): 4778 (47.78%); dim expected 10.68%; ratio 4.47
- `frequency_v2_q0156` (closeness_pace): 4771 (47.71%); dim expected 10.68%; ratio 4.47
- `frequency_v2_q0244` (closeness_pace): 3726 (37.26%); dim expected 10.68%; ratio 3.49
- `frequency_v2_q0322` (closeness_pace): 3613 (36.13%); dim expected 10.68%; ratio 3.38
- `frequency_v2_q0041` (contact_need): 2602 (26.02%); dim expected 20.83%; ratio 1.25
- `frequency_v2_q0205` (contact_need): 2527 (25.27%); dim expected 20.83%; ratio 1.21
- `frequency_v2_q0187` (contact_need): 2489 (24.89%); dim expected 20.83%; ratio 1.19
- `frequency_v2_q0118` (social_energy): 2483 (24.83%); dim expected 18.12%; ratio 1.37
- `frequency_v2_q0279` (contact_need): 2478 (24.78%); dim expected 20.83%; ratio 1.19
- `frequency_v2_q0169` (contact_need): 2465 (24.65%); dim expected 20.83%; ratio 1.18
- `frequency_v2_q0058` (contact_need): 2450 (24.50%); dim expected 20.83%; ratio 1.18
- `frequency_v2_q0302` (contact_need): 2445 (24.45%); dim expected 20.83%; ratio 1.17
- `frequency_v2_q0134` (contact_need): 2438 (24.38%); dim expected 20.83%; ratio 1.17
- `frequency_v2_q0397` (social_energy): 2424 (24.24%); dim expected 18.12%; ratio 1.34
- `frequency_v2_q0141` (contact_need): 2418 (24.18%); dim expected 20.83%; ratio 1.16
- `frequency_v2_q0280` (social_energy): 2415 (24.15%); dim expected 18.12%; ratio 1.33

### Bottom 20 least-selected

- `frequency_v2_q0210` (closeness_pace): 542 (5.42%); dim expected 10.68%; ratio 0.51
- `frequency_v2_q0232` (closeness_pace): 545 (5.45%); dim expected 10.68%; ratio 0.51
- `frequency_v2_q0248` (closeness_pace): 554 (5.54%); dim expected 10.68%; ratio 0.52
- `frequency_v2_q0139` (closeness_pace): 555 (5.55%); dim expected 10.68%; ratio 0.52
- `frequency_v2_q0416` (closeness_pace): 556 (5.56%); dim expected 10.68%; ratio 0.52
- `frequency_v2_q0419` (closeness_pace): 557 (5.57%); dim expected 10.68%; ratio 0.52
- `frequency_v2_q0360` (closeness_pace): 560 (5.60%); dim expected 10.68%; ratio 0.52
- `frequency_v2_q0100` (closeness_pace): 566 (5.66%); dim expected 10.68%; ratio 0.53
- `frequency_v2_q0236` (closeness_pace): 569 (5.69%); dim expected 10.68%; ratio 0.53
- `frequency_v2_q0407` (closeness_pace): 576 (5.76%); dim expected 10.68%; ratio 0.54
- `frequency_v2_q0160` (closeness_pace): 576 (5.76%); dim expected 10.68%; ratio 0.54
- `frequency_v2_q0067` (closeness_pace): 581 (5.81%); dim expected 10.68%; ratio 0.54
- `frequency_v2_q0340` (boundary_firmness): 583 (5.83%); dim expected 8.01%; ratio 0.73
- `frequency_v2_q0213` (closeness_pace): 583 (5.83%); dim expected 10.68%; ratio 0.55
- `frequency_v2_q0410` (closeness_pace): 585 (5.85%); dim expected 10.68%; ratio 0.55
- `frequency_v2_q0220` (closeness_pace): 587 (5.87%); dim expected 10.68%; ratio 0.55
- `frequency_v2_q0150` (closeness_pace): 587 (5.87%); dim expected 10.68%; ratio 0.55
- `frequency_v2_q0106` (closeness_pace): 587 (5.87%); dim expected 10.68%; ratio 0.55
- `frequency_v2_q0009` (closeness_pace): 588 (5.88%); dim expected 10.68%; ratio 0.55
- `frequency_v2_q0181` (closeness_pace): 590 (5.90%); dim expected 10.68%; ratio 0.55

## Selection frequency by primary dimension

Expected allocations per session per dimension: 4 + 2/12 = 4.1667.

- `contact_need`: pool=20; selections=41616 (expected 41666.7); expected mean per question 2083.3 (20.83%)
- `closeness_pace`: pool=39; selections=41700 (expected 41666.7); expected mean per question 1068.4 (10.68%)
- `initiative`: pool=29; selections=41656 (expected 41666.7); expected mean per question 1436.8 (14.37%)
- `autonomy`: pool=57; selections=41641 (expected 41666.7); expected mean per question 731.0 (7.31%)
- `reassurance_need`: pool=26; selections=41752 (expected 41666.7); expected mean per question 1602.6 (16.03%)
- `uncertainty_tolerance`: pool=27; selections=41631 (expected 41666.7); expected mean per question 1543.2 (15.43%)
- `disclosure_pace`: pool=35; selections=41636 (expected 41666.7); expected mean per question 1190.5 (11.90%)
- `boundary_firmness`: pool=52; selections=41697 (expected 41666.7); expected mean per question 801.3 (8.01%)
- `repair_style`: pool=25; selections=41695 (expected 41666.7); expected mean per question 1666.7 (16.67%)
- `social_energy`: pool=23; selections=41675 (expected 41666.7); expected mean per question 1811.6 (18.12%)
- `structure_preference`: pool=36; selections=41702 (expected 41666.7); expected mean per question 1157.4 (11.57%)
- `adaptability`: pool=36; selections=41599 (expected 41666.7); expected mean per question 1157.4 (11.57%)

## All 405 questions

| question_id | dimension | count | pct | dim_expected_pct | ratio |
|---|---|---:|---:|---:|---:|
| `frequency_v2_q0001` | `initiative` | 1535 | 15.35 | 14.37 | 1.07 |
| `frequency_v2_q0002` | `structure_preference` | 963 | 9.63 | 11.57 | 0.83 |
| `frequency_v2_q0004` | `social_energy` | 1520 | 15.20 | 18.12 | 0.84 |
| `frequency_v2_q0005` | `uncertainty_tolerance` | 1626 | 16.26 | 15.43 | 1.05 |
| `frequency_v2_q0006` | `uncertainty_tolerance` | 1561 | 15.61 | 15.43 | 1.01 |
| `frequency_v2_q0007` | `autonomy` | 706 | 7.06 | 7.31 | 0.97 |
| `frequency_v2_q0008` | `disclosure_pace` | 2042 | 20.42 | 11.90 | 1.72 |
| `frequency_v2_q0009` | `closeness_pace` | 588 | 5.88 | 10.68 | 0.55 |
| `frequency_v2_q0010` | `contact_need` | 1654 | 16.54 | 20.83 | 0.79 |
| `frequency_v2_q0011` | `adaptability` | 1190 | 11.90 | 11.57 | 1.03 |
| `frequency_v2_q0012` | `autonomy` | 644 | 6.44 | 7.31 | 0.88 |
| `frequency_v2_q0013` | `disclosure_pace` | 813 | 8.13 | 11.90 | 0.68 |
| `frequency_v2_q0014` | `initiative` | 1492 | 14.92 | 14.37 | 1.04 |
| `frequency_v2_q0015` | `repair_style` | 937 | 9.37 | 16.67 | 0.56 |
| `frequency_v2_q0016` | `boundary_firmness` | 626 | 6.26 | 8.01 | 0.78 |
| `frequency_v2_q0017` | `social_energy` | 1489 | 14.89 | 18.12 | 0.82 |
| `frequency_v2_q0018` | `uncertainty_tolerance` | 1745 | 17.45 | 15.43 | 1.13 |
| `frequency_v2_q0019` | `structure_preference` | 1216 | 12.16 | 11.57 | 1.05 |
| `frequency_v2_q0020` | `uncertainty_tolerance` | 1698 | 16.98 | 15.43 | 1.10 |
| `frequency_v2_q0021` | `social_energy` | 2179 | 21.79 | 18.12 | 1.20 |
| `frequency_v2_q0022` | `structure_preference` | 1005 | 10.05 | 11.57 | 0.87 |
| `frequency_v2_q0024` | `boundary_firmness` | 1003 | 10.03 | 8.01 | 1.25 |
| `frequency_v2_q0025` | `uncertainty_tolerance` | 1445 | 14.45 | 15.43 | 0.94 |
| `frequency_v2_q0026` | `uncertainty_tolerance` | 1599 | 15.99 | 15.43 | 1.04 |
| `frequency_v2_q0027` | `autonomy` | 764 | 7.64 | 7.31 | 1.05 |
| `frequency_v2_q0028` | `boundary_firmness` | 931 | 9.31 | 8.01 | 1.16 |
| `frequency_v2_q0030` | `uncertainty_tolerance` | 1515 | 15.15 | 15.43 | 0.98 |
| `frequency_v2_q0031` | `adaptability` | 1060 | 10.60 | 11.57 | 0.92 |
| `frequency_v2_q0032` | `structure_preference` | 1395 | 13.95 | 11.57 | 1.21 |
| `frequency_v2_q0033` | `disclosure_pace` | 772 | 7.72 | 11.90 | 0.65 |
| `frequency_v2_q0034` | `autonomy` | 792 | 7.92 | 7.31 | 1.08 |
| `frequency_v2_q0035` | `disclosure_pace` | 2052 | 20.52 | 11.90 | 1.72 |
| `frequency_v2_q0036` | `reassurance_need` | 1763 | 17.63 | 16.03 | 1.10 |
| `frequency_v2_q0037` | `boundary_firmness` | 909 | 9.09 | 8.01 | 1.13 |
| `frequency_v2_q0038` | `adaptability` | 1072 | 10.72 | 11.57 | 0.93 |
| `frequency_v2_q0039` | `structure_preference` | 1255 | 12.55 | 11.57 | 1.08 |
| `frequency_v2_q0040` | `initiative` | 1415 | 14.15 | 14.37 | 0.98 |
| `frequency_v2_q0041` | `contact_need` | 2602 | 26.02 | 20.83 | 1.25 |
| `frequency_v2_q0042` | `closeness_pace` | 605 | 6.05 | 10.68 | 0.57 |
| `frequency_v2_q0043` | `autonomy` | 775 | 7.75 | 7.31 | 1.06 |
| `frequency_v2_q0044` | `autonomy` | 738 | 7.38 | 7.31 | 1.01 |
| `frequency_v2_q0045` | `structure_preference` | 1400 | 14.00 | 11.57 | 1.21 |
| `frequency_v2_q0046` | `uncertainty_tolerance` | 1644 | 16.44 | 15.43 | 1.07 |
| `frequency_v2_q0048` | `adaptability` | 1180 | 11.80 | 11.57 | 1.02 |
| `frequency_v2_q0049` | `reassurance_need` | 1534 | 15.34 | 16.03 | 0.96 |
| `frequency_v2_q0050` | `structure_preference` | 962 | 9.62 | 11.57 | 0.83 |
| `frequency_v2_q0051` | `initiative` | 1558 | 15.58 | 14.37 | 1.08 |
| `frequency_v2_q0052` | `reassurance_need` | 1660 | 16.60 | 16.03 | 1.04 |
| `frequency_v2_q0053` | `disclosure_pace` | 778 | 7.78 | 11.90 | 0.65 |
| `frequency_v2_q0054` | `uncertainty_tolerance` | 1597 | 15.97 | 15.43 | 1.03 |
| `frequency_v2_q0055` | `social_energy` | 1505 | 15.05 | 18.12 | 0.83 |
| `frequency_v2_q0056` | `repair_style` | 947 | 9.47 | 16.67 | 0.57 |
| `frequency_v2_q0057` | `reassurance_need` | 1585 | 15.85 | 16.03 | 0.99 |
| `frequency_v2_q0058` | `contact_need` | 2450 | 24.50 | 20.83 | 1.18 |
| `frequency_v2_q0059` | `social_energy` | 2145 | 21.45 | 18.12 | 1.18 |
| `frequency_v2_q0060` | `disclosure_pace` | 786 | 7.86 | 11.90 | 0.66 |
| `frequency_v2_q0061` | `structure_preference` | 1239 | 12.39 | 11.57 | 1.07 |
| `frequency_v2_q0062` | `adaptability` | 1234 | 12.34 | 11.57 | 1.07 |
| `frequency_v2_q0063` | `uncertainty_tolerance` | 1450 | 14.50 | 15.43 | 0.94 |
| `frequency_v2_q0064` | `repair_style` | 940 | 9.40 | 16.67 | 0.56 |
| `frequency_v2_q0065` | `adaptability` | 1257 | 12.57 | 11.57 | 1.09 |
| `frequency_v2_q0066` | `social_energy` | 2138 | 21.38 | 18.12 | 1.18 |
| `frequency_v2_q0067` | `closeness_pace` | 581 | 5.81 | 10.68 | 0.54 |
| `frequency_v2_q0068` | `reassurance_need` | 1678 | 16.78 | 16.03 | 1.05 |
| `frequency_v2_q0069` | `structure_preference` | 940 | 9.40 | 11.57 | 0.81 |
| `frequency_v2_q0070` | `autonomy` | 779 | 7.79 | 7.31 | 1.07 |
| `frequency_v2_q0071` | `reassurance_need` | 1644 | 16.44 | 16.03 | 1.03 |
| `frequency_v2_q0072` | `autonomy` | 670 | 6.70 | 7.31 | 0.92 |
| `frequency_v2_q0073` | `boundary_firmness` | 918 | 9.18 | 8.01 | 1.15 |
| `frequency_v2_q0074` | `uncertainty_tolerance` | 1587 | 15.87 | 15.43 | 1.03 |
| `frequency_v2_q0075` | `adaptability` | 1255 | 12.55 | 11.57 | 1.08 |
| `frequency_v2_q0076` | `closeness_pace` | 4825 | 48.25 | 10.68 | 4.52 |
| `frequency_v2_q0077` | `contact_need` | 1715 | 17.15 | 20.83 | 0.82 |
| `frequency_v2_q0078` | `initiative` | 1371 | 13.71 | 14.37 | 0.95 |
| `frequency_v2_q0079` | `initiative` | 1415 | 14.15 | 14.37 | 0.98 |
| `frequency_v2_q0080` | `initiative` | 1506 | 15.06 | 14.37 | 1.05 |
| `frequency_v2_q0081` | `closeness_pace` | 597 | 5.97 | 10.68 | 0.56 |
| `frequency_v2_q0082` | `uncertainty_tolerance` | 1511 | 15.11 | 15.43 | 0.98 |
| `frequency_v2_q0083` | `repair_style` | 911 | 9.11 | 16.67 | 0.55 |
| `frequency_v2_q0084` | `boundary_firmness` | 733 | 7.33 | 8.01 | 0.91 |
| `frequency_v2_q0085` | `adaptability` | 1205 | 12.05 | 11.57 | 1.04 |
| `frequency_v2_q0086` | `disclosure_pace` | 835 | 8.35 | 11.90 | 0.70 |
| `frequency_v2_q0087` | `uncertainty_tolerance` | 1670 | 16.70 | 15.43 | 1.08 |
| `frequency_v2_q0088` | `repair_style` | 7211 | 72.11 | 16.67 | 4.33 |
| `frequency_v2_q0089` | `disclosure_pace` | 799 | 7.99 | 11.90 | 0.67 |
| `frequency_v2_q0090` | `autonomy` | 717 | 7.17 | 7.31 | 0.98 |
| `frequency_v2_q0091` | `initiative` | 1483 | 14.83 | 14.37 | 1.03 |
| `frequency_v2_q0092` | `autonomy` | 761 | 7.61 | 7.31 | 1.04 |
| `frequency_v2_q0093` | `uncertainty_tolerance` | 1376 | 13.76 | 15.43 | 0.89 |
| `frequency_v2_q0094` | `initiative` | 1361 | 13.61 | 14.37 | 0.95 |
| `frequency_v2_q0095` | `initiative` | 1529 | 15.29 | 14.37 | 1.06 |
| `frequency_v2_q0096` | `adaptability` | 1240 | 12.40 | 11.57 | 1.07 |
| `frequency_v2_q0097` | `repair_style` | 953 | 9.53 | 16.67 | 0.57 |
| `frequency_v2_q0098` | `social_energy` | 1489 | 14.89 | 18.12 | 0.82 |
| `frequency_v2_q0099` | `initiative` | 1386 | 13.86 | 14.37 | 0.96 |
| `frequency_v2_q0100` | `closeness_pace` | 566 | 5.66 | 10.68 | 0.53 |
| `frequency_v2_q0101` | `initiative` | 1477 | 14.77 | 14.37 | 1.03 |
| `frequency_v2_q0102` | `reassurance_need` | 1622 | 16.22 | 16.03 | 1.01 |
| `frequency_v2_q0103` | `disclosure_pace` | 818 | 8.18 | 11.90 | 0.69 |
| `frequency_v2_q0104` | `uncertainty_tolerance` | 1369 | 13.69 | 15.43 | 0.89 |
| `frequency_v2_q0105` | `initiative` | 1421 | 14.21 | 14.37 | 0.99 |
| `frequency_v2_q0106` | `closeness_pace` | 587 | 5.87 | 10.68 | 0.55 |
| `frequency_v2_q0107` | `autonomy` | 686 | 6.86 | 7.31 | 0.94 |
| `frequency_v2_q0108` | `contact_need` | 1741 | 17.41 | 20.83 | 0.84 |
| `frequency_v2_q0109` | `uncertainty_tolerance` | 1330 | 13.30 | 15.43 | 0.86 |
| `frequency_v2_q0110` | `closeness_pace` | 610 | 6.10 | 10.68 | 0.57 |
| `frequency_v2_q0111` | `structure_preference` | 1296 | 12.96 | 11.57 | 1.12 |
| `frequency_v2_q0112` | `structure_preference` | 938 | 9.38 | 11.57 | 0.81 |
| `frequency_v2_q0113` | `structure_preference` | 1366 | 13.66 | 11.57 | 1.18 |
| `frequency_v2_q0114` | `structure_preference` | 995 | 9.95 | 11.57 | 0.86 |
| `frequency_v2_q0115` | `adaptability` | 1026 | 10.26 | 11.57 | 0.89 |
| `frequency_v2_q0116` | `autonomy` | 741 | 7.41 | 7.31 | 1.01 |
| `frequency_v2_q0117` | `autonomy` | 652 | 6.52 | 7.31 | 0.89 |
| `frequency_v2_q0118` | `social_energy` | 2483 | 24.83 | 18.12 | 1.37 |
| `frequency_v2_q0119` | `autonomy` | 821 | 8.21 | 7.31 | 1.12 |
| `frequency_v2_q0120` | `adaptability` | 1181 | 11.81 | 11.57 | 1.02 |
| `frequency_v2_q0121` | `boundary_firmness` | 884 | 8.84 | 8.01 | 1.10 |
| `frequency_v2_q0122` | `repair_style` | 884 | 8.84 | 16.67 | 0.53 |
| `frequency_v2_q0124` | `repair_style` | 7215 | 72.15 | 16.67 | 4.33 |
| `frequency_v2_q0125` | `repair_style` | 905 | 9.05 | 16.67 | 0.54 |
| `frequency_v2_q0126` | `reassurance_need` | 1599 | 15.99 | 16.03 | 1.00 |
| `frequency_v2_q0129` | `repair_style` | 889 | 8.89 | 16.67 | 0.53 |
| `frequency_v2_q0130` | `uncertainty_tolerance` | 1552 | 15.52 | 15.43 | 1.01 |
| `frequency_v2_q0131` | `autonomy` | 755 | 7.55 | 7.31 | 1.03 |
| `frequency_v2_q0132` | `reassurance_need` | 1448 | 14.48 | 16.03 | 0.90 |
| `frequency_v2_q0133` | `adaptability` | 1248 | 12.48 | 11.57 | 1.08 |
| `frequency_v2_q0134` | `contact_need` | 2438 | 24.38 | 20.83 | 1.17 |
| `frequency_v2_q0136` | `disclosure_pace` | 778 | 7.78 | 11.90 | 0.65 |
| `frequency_v2_q0137` | `disclosure_pace` | 2075 | 20.75 | 11.90 | 1.74 |
| `frequency_v2_q0138` | `closeness_pace` | 595 | 5.95 | 10.68 | 0.56 |
| `frequency_v2_q0139` | `closeness_pace` | 555 | 5.55 | 10.68 | 0.52 |
| `frequency_v2_q0140` | `structure_preference` | 1312 | 13.12 | 11.57 | 1.13 |
| `frequency_v2_q0141` | `contact_need` | 2418 | 24.18 | 20.83 | 1.16 |
| `frequency_v2_q0142` | `contact_need` | 1742 | 17.42 | 20.83 | 0.84 |
| `frequency_v2_q0143` | `boundary_firmness` | 941 | 9.41 | 8.01 | 1.17 |
| `frequency_v2_q0144` | `structure_preference` | 1303 | 13.03 | 11.57 | 1.13 |
| `frequency_v2_q0145` | `repair_style` | 7282 | 72.82 | 16.67 | 4.37 |
| `frequency_v2_q0146` | `structure_preference` | 1305 | 13.05 | 11.57 | 1.13 |
| `frequency_v2_q0147` | `reassurance_need` | 1708 | 17.08 | 16.03 | 1.07 |
| `frequency_v2_q0148` | `adaptability` | 1226 | 12.26 | 11.57 | 1.06 |
| `frequency_v2_q0149` | `structure_preference` | 896 | 8.96 | 11.57 | 0.77 |
| `frequency_v2_q0150` | `closeness_pace` | 587 | 5.87 | 10.68 | 0.55 |
| `frequency_v2_q0151` | `structure_preference` | 1425 | 14.25 | 11.57 | 1.23 |
| `frequency_v2_q0152` | `uncertainty_tolerance` | 1575 | 15.75 | 15.43 | 1.02 |
| `frequency_v2_q0154` | `initiative` | 1453 | 14.53 | 14.37 | 1.01 |
| `frequency_v2_q0155` | `autonomy` | 814 | 8.14 | 7.31 | 1.11 |
| `frequency_v2_q0156` | `closeness_pace` | 4771 | 47.71 | 10.68 | 4.47 |
| `frequency_v2_q0157` | `disclosure_pace` | 817 | 8.17 | 11.90 | 0.69 |
| `frequency_v2_q0158` | `boundary_firmness` | 960 | 9.60 | 8.01 | 1.20 |
| `frequency_v2_q0159` | `structure_preference` | 1513 | 15.13 | 11.57 | 1.31 |
| `frequency_v2_q0160` | `closeness_pace` | 576 | 5.76 | 10.68 | 0.54 |
| `frequency_v2_q0161` | `autonomy` | 697 | 6.97 | 7.31 | 0.95 |
| `frequency_v2_q0162` | `reassurance_need` | 1700 | 17.00 | 16.03 | 1.06 |
| `frequency_v2_q0163` | `adaptability` | 1120 | 11.20 | 11.57 | 0.97 |
| `frequency_v2_q0164` | `uncertainty_tolerance` | 1615 | 16.15 | 15.43 | 1.05 |
| `frequency_v2_q0165` | `autonomy` | 757 | 7.57 | 7.31 | 1.04 |
| `frequency_v2_q0166` | `repair_style` | 931 | 9.31 | 16.67 | 0.56 |
| `frequency_v2_q0167` | `reassurance_need` | 1653 | 16.53 | 16.03 | 1.03 |
| `frequency_v2_q0168` | `adaptability` | 1080 | 10.80 | 11.57 | 0.93 |
| `frequency_v2_q0169` | `contact_need` | 2465 | 24.65 | 20.83 | 1.18 |
| `frequency_v2_q0170` | `boundary_firmness` | 922 | 9.22 | 8.01 | 1.15 |
| `frequency_v2_q0171` | `reassurance_need` | 1559 | 15.59 | 16.03 | 0.97 |
| `frequency_v2_q0172` | `structure_preference` | 1237 | 12.37 | 11.57 | 1.07 |
| `frequency_v2_q0173` | `uncertainty_tolerance` | 1594 | 15.94 | 15.43 | 1.03 |
| `frequency_v2_q0174` | `boundary_firmness` | 651 | 6.51 | 8.01 | 0.81 |
| `frequency_v2_q0175` | `social_energy` | 2382 | 23.82 | 18.12 | 1.31 |
| `frequency_v2_q0176` | `adaptability` | 1110 | 11.10 | 11.57 | 0.96 |
| `frequency_v2_q0177` | `disclosure_pace` | 831 | 8.31 | 11.90 | 0.70 |
| `frequency_v2_q0178` | `contact_need` | 1694 | 16.94 | 20.83 | 0.81 |
| `frequency_v2_q0179` | `autonomy` | 678 | 6.78 | 7.31 | 0.93 |
| `frequency_v2_q0180` | `structure_preference` | 1427 | 14.27 | 11.57 | 1.23 |
| `frequency_v2_q0181` | `closeness_pace` | 590 | 5.90 | 10.68 | 0.55 |
| `frequency_v2_q0182` | `structure_preference` | 1385 | 13.85 | 11.57 | 1.20 |
| `frequency_v2_q0183` | `boundary_firmness` | 939 | 9.39 | 8.01 | 1.17 |
| `frequency_v2_q0184` | `autonomy` | 782 | 7.82 | 7.31 | 1.07 |
| `frequency_v2_q0185` | `boundary_firmness` | 942 | 9.42 | 8.01 | 1.18 |
| `frequency_v2_q0186` | `repair_style` | 946 | 9.46 | 16.67 | 0.57 |
| `frequency_v2_q0187` | `contact_need` | 2489 | 24.89 | 20.83 | 1.19 |
| `frequency_v2_q0188` | `social_energy` | 1567 | 15.67 | 18.12 | 0.86 |
| `frequency_v2_q0189` | `structure_preference` | 963 | 9.63 | 11.57 | 0.83 |
| `frequency_v2_q0190` | `uncertainty_tolerance` | 1672 | 16.72 | 15.43 | 1.08 |
| `frequency_v2_q0192` | `autonomy` | 780 | 7.80 | 7.31 | 1.07 |
| `frequency_v2_q0193` | `disclosure_pace` | 2008 | 20.08 | 11.90 | 1.69 |
| `frequency_v2_q0194` | `social_energy` | 1482 | 14.82 | 18.12 | 0.82 |
| `frequency_v2_q0195` | `uncertainty_tolerance` | 1454 | 14.54 | 15.43 | 0.94 |
| `frequency_v2_q0196` | `initiative` | 1427 | 14.27 | 14.37 | 0.99 |
| `frequency_v2_q0197` | `autonomy` | 744 | 7.44 | 7.31 | 1.02 |
| `frequency_v2_q0198` | `adaptability` | 1112 | 11.12 | 11.57 | 0.96 |
| `frequency_v2_q0199` | `disclosure_pace` | 759 | 7.59 | 11.90 | 0.64 |
| `frequency_v2_q0200` | `boundary_firmness` | 624 | 6.24 | 8.01 | 0.78 |
| `frequency_v2_q0201` | `autonomy` | 672 | 6.72 | 7.31 | 0.92 |
| `frequency_v2_q0202` | `closeness_pace` | 635 | 6.35 | 10.68 | 0.59 |
| `frequency_v2_q0203` | `boundary_firmness` | 936 | 9.36 | 8.01 | 1.17 |
| `frequency_v2_q0204` | `contact_need` | 1635 | 16.35 | 20.83 | 0.78 |
| `frequency_v2_q0205` | `contact_need` | 2527 | 25.27 | 20.83 | 1.21 |
| `frequency_v2_q0206` | `boundary_firmness` | 631 | 6.31 | 8.01 | 0.79 |
| `frequency_v2_q0207` | `autonomy` | 790 | 7.90 | 7.31 | 1.08 |
| `frequency_v2_q0208` | `autonomy` | 777 | 7.77 | 7.31 | 1.06 |
| `frequency_v2_q0209` | `boundary_firmness` | 592 | 5.92 | 8.01 | 0.74 |
| `frequency_v2_q0210` | `closeness_pace` | 542 | 5.42 | 10.68 | 0.51 |
| `frequency_v2_q0211` | `structure_preference` | 988 | 9.88 | 11.57 | 0.85 |
| `frequency_v2_q0212` | `repair_style` | 893 | 8.93 | 16.67 | 0.54 |
| `frequency_v2_q0213` | `closeness_pace` | 583 | 5.83 | 10.68 | 0.55 |
| `frequency_v2_q0214` | `social_energy` | 2181 | 21.81 | 18.12 | 1.20 |
| `frequency_v2_q0215` | `disclosure_pace` | 757 | 7.57 | 11.90 | 0.64 |
| `frequency_v2_q0216` | `autonomy` | 765 | 7.65 | 7.31 | 1.05 |
| `frequency_v2_q0217` | `structure_preference` | 1004 | 10.04 | 11.57 | 0.87 |
| `frequency_v2_q0218` | `initiative` | 1557 | 15.57 | 14.37 | 1.08 |
| `frequency_v2_q0219` | `autonomy` | 676 | 6.76 | 7.31 | 0.92 |
| `frequency_v2_q0220` | `closeness_pace` | 587 | 5.87 | 10.68 | 0.55 |
| `frequency_v2_q0221` | `boundary_firmness` | 735 | 7.35 | 8.01 | 0.92 |
| `frequency_v2_q0222` | `boundary_firmness` | 924 | 9.24 | 8.01 | 1.15 |
| `frequency_v2_q0223` | `adaptability` | 1208 | 12.08 | 11.57 | 1.04 |
| `frequency_v2_q0224` | `autonomy` | 834 | 8.34 | 7.31 | 1.14 |
| `frequency_v2_q0225` | `disclosure_pace` | 775 | 7.75 | 11.90 | 0.65 |
| `frequency_v2_q0226` | `initiative` | 1466 | 14.66 | 14.37 | 1.02 |
| `frequency_v2_q0227` | `adaptability` | 1124 | 11.24 | 11.57 | 0.97 |
| `frequency_v2_q0228` | `adaptability` | 1196 | 11.96 | 11.57 | 1.03 |
| `frequency_v2_q0229` | `repair_style` | 939 | 9.39 | 16.67 | 0.56 |
| `frequency_v2_q0230` | `disclosure_pace` | 790 | 7.90 | 11.90 | 0.66 |
| `frequency_v2_q0231` | `autonomy` | 762 | 7.62 | 7.31 | 1.04 |
| `frequency_v2_q0232` | `closeness_pace` | 545 | 5.45 | 10.68 | 0.51 |
| `frequency_v2_q0233` | `boundary_firmness` | 677 | 6.77 | 8.01 | 0.84 |
| `frequency_v2_q0234` | `social_energy` | 1366 | 13.66 | 18.12 | 0.75 |
| `frequency_v2_q0235` | `boundary_firmness` | 949 | 9.49 | 8.01 | 1.18 |
| `frequency_v2_q0236` | `closeness_pace` | 569 | 5.69 | 10.68 | 0.53 |
| `frequency_v2_q0237` | `adaptability` | 1057 | 10.57 | 11.57 | 0.91 |
| `frequency_v2_q0238` | `boundary_firmness` | 637 | 6.37 | 8.01 | 0.79 |
| `frequency_v2_q0239` | `disclosure_pace` | 2007 | 20.07 | 11.90 | 1.69 |
| `frequency_v2_q0240` | `disclosure_pace` | 735 | 7.35 | 11.90 | 0.62 |
| `frequency_v2_q0241` | `closeness_pace` | 591 | 5.91 | 10.68 | 0.55 |
| `frequency_v2_q0242` | `repair_style` | 878 | 8.78 | 16.67 | 0.53 |
| `frequency_v2_q0243` | `social_energy` | 1822 | 18.22 | 18.12 | 1.01 |
| `frequency_v2_q0244` | `closeness_pace` | 3726 | 37.26 | 10.68 | 3.49 |
| `frequency_v2_q0245` | `boundary_firmness` | 686 | 6.86 | 8.01 | 0.86 |
| `frequency_v2_q0246` | `adaptability` | 1057 | 10.57 | 11.57 | 0.91 |
| `frequency_v2_q0247` | `initiative` | 1296 | 12.96 | 14.37 | 0.90 |
| `frequency_v2_q0248` | `closeness_pace` | 554 | 5.54 | 10.68 | 0.52 |
| `frequency_v2_q0249` | `repair_style` | 892 | 8.92 | 16.67 | 0.54 |
| `frequency_v2_q0250` | `initiative` | 1433 | 14.33 | 14.37 | 1.00 |
| `frequency_v2_q0251` | `structure_preference` | 1212 | 12.12 | 11.57 | 1.05 |
| `frequency_v2_q0253` | `autonomy` | 663 | 6.63 | 7.31 | 0.91 |
| `frequency_v2_q0254` | `contact_need` | 2405 | 24.05 | 20.83 | 1.15 |
| `frequency_v2_q0255` | `adaptability` | 1164 | 11.64 | 11.57 | 1.01 |
| `frequency_v2_q0256` | `disclosure_pace` | 834 | 8.34 | 11.90 | 0.70 |
| `frequency_v2_q0257` | `social_energy` | 1542 | 15.42 | 18.12 | 0.85 |
| `frequency_v2_q0258` | `autonomy` | 659 | 6.59 | 7.31 | 0.90 |
| `frequency_v2_q0259` | `contact_need` | 1658 | 16.58 | 20.83 | 0.80 |
| `frequency_v2_q0260` | `boundary_firmness` | 946 | 9.46 | 8.01 | 1.18 |
| `frequency_v2_q0261` | `repair_style` | 913 | 9.13 | 16.67 | 0.55 |
| `frequency_v2_q0262` | `disclosure_pace` | 2000 | 20.00 | 11.90 | 1.68 |
| `frequency_v2_q0263` | `boundary_firmness` | 666 | 6.66 | 8.01 | 0.83 |
| `frequency_v2_q0264` | `disclosure_pace` | 1975 | 19.75 | 11.90 | 1.66 |
| `frequency_v2_q0265` | `social_energy` | 1557 | 15.57 | 18.12 | 0.86 |
| `frequency_v2_q0266` | `boundary_firmness` | 1029 | 10.29 | 8.01 | 1.28 |
| `frequency_v2_q0267` | `uncertainty_tolerance` | 1621 | 16.21 | 15.43 | 1.05 |
| `frequency_v2_q0268` | `adaptability` | 1171 | 11.71 | 11.57 | 1.01 |
| `frequency_v2_q0269` | `autonomy` | 768 | 7.68 | 7.31 | 1.05 |
| `frequency_v2_q0270` | `reassurance_need` | 1494 | 14.94 | 16.03 | 0.93 |
| `frequency_v2_q0271` | `adaptability` | 1091 | 10.91 | 11.57 | 0.94 |
| `frequency_v2_q0272` | `reassurance_need` | 1639 | 16.39 | 16.03 | 1.02 |
| `frequency_v2_q0273` | `structure_preference` | 983 | 9.83 | 11.57 | 0.85 |
| `frequency_v2_q0274` | `contact_need` | 1728 | 17.28 | 20.83 | 0.83 |
| `frequency_v2_q0275` | `autonomy` | 836 | 8.36 | 7.31 | 1.14 |
| `frequency_v2_q0276` | `disclosure_pace` | 856 | 8.56 | 11.90 | 0.72 |
| `frequency_v2_q0277` | `structure_preference` | 915 | 9.15 | 11.57 | 0.79 |
| `frequency_v2_q0278` | `boundary_firmness` | 945 | 9.45 | 8.01 | 1.18 |
| `frequency_v2_q0279` | `contact_need` | 2478 | 24.78 | 20.83 | 1.19 |
| `frequency_v2_q0280` | `social_energy` | 2415 | 24.15 | 18.12 | 1.33 |
| `frequency_v2_q0281` | `closeness_pace` | 4778 | 47.78 | 10.68 | 4.47 |
| `frequency_v2_q0282` | `autonomy` | 756 | 7.56 | 7.31 | 1.03 |
| `frequency_v2_q0283` | `reassurance_need` | 1612 | 16.12 | 16.03 | 1.01 |
| `frequency_v2_q0284` | `disclosure_pace` | 2119 | 21.19 | 11.90 | 1.78 |
| `frequency_v2_q0285` | `structure_preference` | 1359 | 13.59 | 11.57 | 1.17 |
| `frequency_v2_q0286` | `reassurance_need` | 1672 | 16.72 | 16.03 | 1.04 |
| `frequency_v2_q0287` | `boundary_firmness` | 885 | 8.85 | 8.01 | 1.10 |
| `frequency_v2_q0288` | `initiative` | 1420 | 14.20 | 14.37 | 0.99 |
| `frequency_v2_q0289` | `reassurance_need` | 1545 | 15.45 | 16.03 | 0.96 |
| `frequency_v2_q0290` | `autonomy` | 753 | 7.53 | 7.31 | 1.03 |
| `frequency_v2_q0291` | `autonomy` | 646 | 6.46 | 7.31 | 0.88 |
| `frequency_v2_q0293` | `disclosure_pace` | 2116 | 21.16 | 11.90 | 1.78 |
| `frequency_v2_q0294` | `autonomy` | 773 | 7.73 | 7.31 | 1.06 |
| `frequency_v2_q0295` | `disclosure_pace` | 2005 | 20.05 | 11.90 | 1.68 |
| `frequency_v2_q0296` | `boundary_firmness` | 625 | 6.25 | 8.01 | 0.78 |
| `frequency_v2_q0297` | `autonomy` | 736 | 7.36 | 7.31 | 1.01 |
| `frequency_v2_q0298` | `adaptability` | 1142 | 11.42 | 11.57 | 0.99 |
| `frequency_v2_q0299` | `social_energy` | 1512 | 15.12 | 18.12 | 0.83 |
| `frequency_v2_q0300` | `autonomy` | 741 | 7.41 | 7.31 | 1.01 |
| `frequency_v2_q0301` | `autonomy` | 612 | 6.12 | 7.31 | 0.84 |
| `frequency_v2_q0302` | `contact_need` | 2445 | 24.45 | 20.83 | 1.17 |
| `frequency_v2_q0303` | `autonomy` | 620 | 6.20 | 7.31 | 0.85 |
| `frequency_v2_q0304` | `autonomy` | 655 | 6.55 | 7.31 | 0.90 |
| `frequency_v2_q0305` | `closeness_pace` | 610 | 6.10 | 10.68 | 0.57 |
| `frequency_v2_q0306` | `repair_style` | 909 | 9.09 | 16.67 | 0.55 |
| `frequency_v2_q0307` | `social_energy` | 1800 | 18.00 | 18.12 | 0.99 |
| `frequency_v2_q0308` | `closeness_pace` | 603 | 6.03 | 10.68 | 0.56 |
| `frequency_v2_q0309` | `structure_preference` | 978 | 9.78 | 11.57 | 0.84 |
| `frequency_v2_q0310` | `repair_style` | 868 | 8.68 | 16.67 | 0.52 |
| `frequency_v2_q0311` | `boundary_firmness` | 614 | 6.14 | 8.01 | 0.77 |
| `frequency_v2_q0312` | `initiative` | 1407 | 14.07 | 14.37 | 0.98 |
| `frequency_v2_q0313` | `boundary_firmness` | 916 | 9.16 | 8.01 | 1.14 |
| `frequency_v2_q0314` | `initiative` | 1385 | 13.85 | 14.37 | 0.96 |
| `frequency_v2_q0315` | `reassurance_need` | 1424 | 14.24 | 16.03 | 0.89 |
| `frequency_v2_q0316` | `closeness_pace` | 610 | 6.10 | 10.68 | 0.57 |
| `frequency_v2_q0317` | `repair_style` | 929 | 9.29 | 16.67 | 0.56 |
| `frequency_v2_q0318` | `initiative` | 1363 | 13.63 | 14.37 | 0.95 |
| `frequency_v2_q0319` | `disclosure_pace` | 809 | 8.09 | 11.90 | 0.68 |
| `frequency_v2_q0320` | `social_energy` | 1486 | 14.86 | 18.12 | 0.82 |
| `frequency_v2_q0322` | `closeness_pace` | 3613 | 36.13 | 10.68 | 3.38 |
| `frequency_v2_q0323` | `uncertainty_tolerance` | 1540 | 15.40 | 15.43 | 1.00 |
| `frequency_v2_q0324` | `adaptability` | 1147 | 11.47 | 11.57 | 0.99 |
| `frequency_v2_q0325` | `closeness_pace` | 606 | 6.06 | 10.68 | 0.57 |
| `frequency_v2_q0326` | `initiative` | 1350 | 13.50 | 14.37 | 0.94 |
| `frequency_v2_q0327` | `disclosure_pace` | 771 | 7.71 | 11.90 | 0.65 |
| `frequency_v2_q0328` | `autonomy` | 779 | 7.79 | 7.31 | 1.07 |
| `frequency_v2_q0329` | `adaptability` | 1178 | 11.78 | 11.57 | 1.02 |
| `frequency_v2_q0330` | `disclosure_pace` | 823 | 8.23 | 11.90 | 0.69 |
| `frequency_v2_q0331` | `repair_style` | 829 | 8.29 | 16.67 | 0.50 |
| `frequency_v2_q0334` | `autonomy` | 657 | 6.57 | 7.31 | 0.90 |
| `frequency_v2_q0335` | `adaptability` | 1092 | 10.92 | 11.57 | 0.94 |
| `frequency_v2_q0336` | `initiative` | 1388 | 13.88 | 14.37 | 0.97 |
| `frequency_v2_q0337` | `uncertainty_tolerance` | 1373 | 13.73 | 15.43 | 0.89 |
| `frequency_v2_q0338` | `boundary_firmness` | 627 | 6.27 | 8.01 | 0.78 |
| `frequency_v2_q0339` | `closeness_pace` | 594 | 5.94 | 10.68 | 0.56 |
| `frequency_v2_q0340` | `boundary_firmness` | 583 | 5.83 | 8.01 | 0.73 |
| `frequency_v2_q0341` | `disclosure_pace` | 773 | 7.73 | 11.90 | 0.65 |
| `frequency_v2_q0342` | `adaptability` | 1176 | 11.76 | 11.57 | 1.02 |
| `frequency_v2_q0343` | `reassurance_need` | 1509 | 15.09 | 16.03 | 0.94 |
| `frequency_v2_q0344` | `boundary_firmness` | 949 | 9.49 | 8.01 | 1.18 |
| `frequency_v2_q0345` | `autonomy` | 758 | 7.58 | 7.31 | 1.04 |
| `frequency_v2_q0346` | `adaptability` | 1238 | 12.38 | 11.57 | 1.07 |
| `frequency_v2_q0347` | `reassurance_need` | 1604 | 16.04 | 16.03 | 1.00 |
| `frequency_v2_q0348` | `autonomy` | 725 | 7.25 | 7.31 | 0.99 |
| `frequency_v2_q0349` | `structure_preference` | 978 | 9.78 | 11.57 | 0.84 |
| `frequency_v2_q0350` | `reassurance_need` | 1708 | 17.08 | 16.03 | 1.07 |
| `frequency_v2_q0351` | `boundary_firmness` | 977 | 9.77 | 8.01 | 1.22 |
| `frequency_v2_q0352` | `autonomy` | 713 | 7.13 | 7.31 | 0.98 |
| `frequency_v2_q0353` | `boundary_firmness` | 693 | 6.93 | 8.01 | 0.86 |
| `frequency_v2_q0354` | `disclosure_pace` | 838 | 8.38 | 11.90 | 0.70 |
| `frequency_v2_q0355` | `structure_preference` | 1255 | 12.55 | 11.57 | 1.08 |
| `frequency_v2_q0356` | `autonomy` | 749 | 7.49 | 7.31 | 1.02 |
| `frequency_v2_q0357` | `adaptability` | 1166 | 11.66 | 11.57 | 1.01 |
| `frequency_v2_q0358` | `autonomy` | 753 | 7.53 | 7.31 | 1.03 |
| `frequency_v2_q0359` | `initiative` | 1562 | 15.62 | 14.37 | 1.09 |
| `frequency_v2_q0360` | `closeness_pace` | 560 | 5.60 | 10.68 | 0.52 |
| `frequency_v2_q0362` | `adaptability` | 1213 | 12.13 | 11.57 | 1.05 |
| `frequency_v2_q0363` | `boundary_firmness` | 926 | 9.26 | 8.01 | 1.16 |
| `frequency_v2_q0364` | `boundary_firmness` | 924 | 9.24 | 8.01 | 1.15 |
| `frequency_v2_q0365` | `reassurance_need` | 1683 | 16.83 | 16.03 | 1.05 |
| `frequency_v2_q0366` | `structure_preference` | 1031 | 10.31 | 11.57 | 0.89 |
| `frequency_v2_q0367` | `autonomy` | 667 | 6.67 | 7.31 | 0.91 |
| `frequency_v2_q0368` | `autonomy` | 717 | 7.17 | 7.31 | 0.98 |
| `frequency_v2_q0369` | `autonomy` | 813 | 8.13 | 7.31 | 1.11 |
| `frequency_v2_q0370` | `uncertainty_tolerance` | 1439 | 14.39 | 15.43 | 0.93 |
| `frequency_v2_q0371` | `boundary_firmness` | 689 | 6.89 | 8.01 | 0.86 |
| `frequency_v2_q0372` | `boundary_firmness` | 979 | 9.79 | 8.01 | 1.22 |
| `frequency_v2_q0374` | `boundary_firmness` | 933 | 9.33 | 8.01 | 1.16 |
| `frequency_v2_q0375` | `autonomy` | 723 | 7.23 | 7.31 | 0.99 |
| `frequency_v2_q0376` | `autonomy` | 739 | 7.39 | 7.31 | 1.01 |
| `frequency_v2_q0377` | `adaptability` | 1111 | 11.11 | 11.57 | 0.96 |
| `frequency_v2_q0378` | `autonomy` | 759 | 7.59 | 7.31 | 1.04 |
| `frequency_v2_q0379` | `autonomy` | 676 | 6.76 | 7.31 | 0.92 |
| `frequency_v2_q0381` | `boundary_firmness` | 930 | 9.30 | 8.01 | 1.16 |
| `frequency_v2_q0382` | `initiative` | 1566 | 15.66 | 14.37 | 1.09 |
| `frequency_v2_q0383` | `adaptability` | 1123 | 11.23 | 11.57 | 0.97 |
| `frequency_v2_q0384` | `structure_preference` | 1264 | 12.64 | 11.57 | 1.09 |
| `frequency_v2_q0385` | `disclosure_pace` | 2005 | 20.05 | 11.90 | 1.68 |
| `frequency_v2_q0386` | `contact_need` | 1688 | 16.88 | 20.83 | 0.81 |
| `frequency_v2_q0387` | `reassurance_need` | 1555 | 15.55 | 16.03 | 0.97 |
| `frequency_v2_q0388` | `structure_preference` | 997 | 9.97 | 11.57 | 0.86 |
| `frequency_v2_q0389` | `boundary_firmness` | 933 | 9.33 | 8.01 | 1.16 |
| `frequency_v2_q0390` | `repair_style` | 880 | 8.80 | 16.67 | 0.53 |
| `frequency_v2_q0391` | `reassurance_need` | 1719 | 17.19 | 16.03 | 1.07 |
| `frequency_v2_q0392` | `autonomy` | 666 | 6.66 | 7.31 | 0.91 |
| `frequency_v2_q0393` | `adaptability` | 1149 | 11.49 | 11.57 | 0.99 |
| `frequency_v2_q0394` | `boundary_firmness` | 609 | 6.09 | 8.01 | 0.76 |
| `frequency_v2_q0395` | `closeness_pace` | 605 | 6.05 | 10.68 | 0.57 |
| `frequency_v2_q0396` | `boundary_firmness` | 715 | 7.15 | 8.01 | 0.89 |
| `frequency_v2_q0397` | `social_energy` | 2424 | 24.24 | 18.12 | 1.34 |
| `frequency_v2_q0398` | `closeness_pace` | 630 | 6.30 | 10.68 | 0.59 |
| `frequency_v2_q0399` | `repair_style` | 907 | 9.07 | 16.67 | 0.54 |
| `frequency_v2_q0400` | `boundary_firmness` | 652 | 6.52 | 8.01 | 0.81 |
| `frequency_v2_q0401` | `contact_need` | 1644 | 16.44 | 20.83 | 0.79 |
| `frequency_v2_q0402` | `closeness_pace` | 638 | 6.38 | 10.68 | 0.60 |
| `frequency_v2_q0403` | `boundary_firmness` | 657 | 6.57 | 8.01 | 0.82 |
| `frequency_v2_q0404` | `uncertainty_tolerance` | 1473 | 14.73 | 15.43 | 0.95 |
| `frequency_v2_q0406` | `boundary_firmness` | 643 | 6.43 | 8.01 | 0.80 |
| `frequency_v2_q0407` | `closeness_pace` | 576 | 5.76 | 10.68 | 0.54 |
| `frequency_v2_q0408` | `boundary_firmness` | 650 | 6.50 | 8.01 | 0.81 |
| `frequency_v2_q0410` | `closeness_pace` | 585 | 5.85 | 10.68 | 0.55 |
| `frequency_v2_q0411` | `initiative` | 1326 | 13.26 | 14.37 | 0.92 |
| `frequency_v2_q0412` | `structure_preference` | 1002 | 10.02 | 11.57 | 0.87 |
| `frequency_v2_q0413` | `boundary_firmness` | 939 | 9.39 | 8.01 | 1.17 |
| `frequency_v2_q0414` | `disclosure_pace` | 846 | 8.46 | 11.90 | 0.71 |
| `frequency_v2_q0415` | `reassurance_need` | 1435 | 14.35 | 16.03 | 0.90 |
| `frequency_v2_q0416` | `closeness_pace` | 556 | 5.56 | 10.68 | 0.52 |
| `frequency_v2_q0417` | `social_energy` | 1433 | 14.33 | 18.12 | 0.79 |
| `frequency_v2_q0418` | `disclosure_pace` | 839 | 8.39 | 11.90 | 0.70 |
| `frequency_v2_q0419` | `closeness_pace` | 557 | 5.57 | 10.68 | 0.52 |
| `frequency_v2_q0420` | `initiative` | 1308 | 13.08 | 14.37 | 0.91 |
| `frequency_v2_q0421` | `boundary_firmness` | 675 | 6.75 | 8.01 | 0.84 |
| `frequency_v2_q0422` | `closeness_pace` | 614 | 6.14 | 10.68 | 0.57 |
| `frequency_v2_q0423` | `social_energy` | 1758 | 17.58 | 18.12 | 0.97 |
| `frequency_v2_q0424` | `boundary_firmness` | 638 | 6.38 | 8.01 | 0.80 |
| `frequency_v2_q0425` | `repair_style` | 907 | 9.07 | 16.67 | 0.54 |

## Safety

- V2 not activated
- pool text / weights / evidence values not modified by this simulation
- option shuffle stream `options|{question_id}` unchanged
- no V1 / Firebase / C2 / Discover / Persona / matching / 12D→6D adapter

FREQUENCY V2 PHASE 3B SELECTOR FAIRNESS AUDIT COMPLETE — STRUCTURAL ALWAYS-WINNER BIAS REMOVED — V2 STILL DORMANT
