# Directional Preference-Fit Simulation Manifest v1

Phase: **P2B-2.1** (completion / coverage audit)

Source report: `tool/core_method_v2_out/directional_preference_fit_simulation_v1_report.json`
Simulator: `tool/simulate_directional_preference_fit_v1.dart`

Counts below are **derived** from the scenario collection in the JSON report
(not hand-stated).

- scenario_count: **41**
- passed_count: **41**
- failed_count: **0**
- deterministic_fingerprint: `599b789307612437`
- scenario_ids: `01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41`

| # | scenario ID | name | requirement represented | input summary | expected mathematical property | actual result | pass/fail | report location |
|---|-------------|------|-------------------------|---------------|--------------------------------|---------------|-----------|-----------------|
| 1 | `01` / `range_inside` | Range target exactly inside interval | Range target exactly inside interval | pref[0.4,0.6] partner=0.5 | raw_fit == 1 | raw_fit=1.0; status=complete | pass | `scenarios[0]` id=`01` |
| 2 | `02` / `range_lower_boundary` | Range target at lower boundary | Range target at lower boundary | pref[0.4,0.6] partner=0.4 | raw_fit == 1 | raw_fit=1.0; status=complete | pass | `scenarios[1]` id=`02` |
| 3 | `03` / `range_upper_boundary` | Range target at upper boundary | Range target at upper boundary | pref[0.4,0.6] partner=0.6 | raw_fit == 1 | raw_fit=1.0; status=complete | pass | `scenarios[2]` id=`03` |
| 4 | `04` / `slightly_below` | Slightly below preferred range | Slightly below preferred range | partner=0.35 | 0 < raw_fit < 1 | raw_fit=0.9756109800648459; status=complete | pass | `scenarios[3]` id=`04` |
| 5 | `05` / `far_below` | Far below preferred range | Far below preferred range | partner=0.0 | raw_fit < slightly_below | raw_fit=0.2059242464341986; status=complete | pass | `scenarios[4]` id=`05` |
| 6 | `06` / `slightly_above` | Slightly above preferred range | Slightly above preferred range | partner=0.65 | 0 < raw_fit < 1 | raw_fit=0.9756109800648459; status=complete | pass | `scenarios[5]` id=`06` |
| 7 | `07` / `far_above` | Far above preferred range | Far above preferred range | partner=1.0 | raw_fit < slightly_above | raw_fit=0.2059242464341986; status=complete | pass | `scenarios[6]` id=`07` |
| 8 | `08` / `strict_flexibility` | Strict flexibility increases penalty | Strict flexibility | f=0 partner=0.2 | raw_fit < high_flexibility | raw_fit=0.1353352832366127; status=complete | pass | `scenarios[7]` id=`08` |
| 9 | `09` / `high_flexibility` | High flexibility reduces penalty | High flexibility | f=1 partner=0.2 | raw_fit > strict | raw_fit=0.8493658165683124; status=complete | pass | `scenarios[8]` id=`09` |
| 10 | `10` / `similarity_identical` | Similarity-to-self identical scores | Similarity-to-self identical scores | self=0.55 partner=0.55 | raw_fit == 1 | raw_fit=1.0; status=complete | pass | `scenarios[9]` id=`10` |
| 11 | `11` / `similarity_small_diff` | Similarity-to-self small difference | Similarity-to-self small difference | self=0.55 partner=0.60 | raw_fit < 1 and > large_diff | raw_fit=0.9756109800648459; status=complete | pass | `scenarios[10]` id=`11` |
| 12 | `12` / `similarity_large_diff` | Similarity-to-self large difference | Similarity-to-self large difference | self=0.55 partner=0.95 | raw_fit < small_diff | raw_fit=0.20592424643419882; status=complete | pass | `scenarios[11]` id=`12` |
| 13 | `13` / `high_confidence_partner` | High-confidence measured partner | High-confidence measured partner | partner score=0.2 conf=0.95 | evidence_q high; raw_fit defined | raw_fit=0.6736384553447267; status=complete | pass | `scenarios[12]` id=`13` |
| 14 | `14` / `low_confidence_partner` | Low-confidence measured partner | Low-confidence measured partner | partner score=0.2 conf=0.15 | evidence_q lower than high-conf case | raw_fit=0.6736384553447267; status=complete | pass | `scenarios[13]` id=`14` |
| 15 | `15` / `one_dim_high_confidence` | One preference dimension with high confidence | One preference dimension with high confidence | single dim conf=0.9 out-of-range | raw_fit defined | raw_fit=0.4111122905071873; status=complete | pass | `scenarios[14]` id=`15` |
| 16 | `16` / `one_dim_low_confidence` | Same one preference dimension with low confidence | Same one preference dimension with low confidence | single dim conf=0.2 same scores | raw_fit unchanged; evidence_q decreases | raw_fit=0.4111122905071873; status=complete | pass | `scenarios[15]` id=`16` |
| 17 | `17` / `multi_dim_high_conf_discrepancy` | Multiple dimensions with one high-confidence discrepancy | Multiple dimensions with one high-confidence discrepancy | dim discrepant conf=0.95; dim2 matched | raw_fit < multi_low_conf discrepancy case | raw_fit=0.47974347180171634; status=complete | pass | `scenarios[16]` id=`17` |
| 18 | `18` / `multi_dim_low_conf_discrepancy` | Multiple dimensions with one low-confidence discrepancy | Multiple dimensions with one low-confidence discrepancy | dim discrepant conf=0.1; dim2 matched | raw_fit higher than high-conf discrepancy | raw_fit=0.8676540410723664; status=complete | pass | `scenarios[17]` id=`18` |
| 19 | `19` / `explicit_open` | Explicit open preference | Explicit open preference | mode=open | null raw_fit; open listed; not scored 1/0.5 | raw_fit=None; status=insufficient_evidence; exclusions=preference_open | pass | `scenarios[18]` id=`19` |
| 20 | `20` / `unavailable_preference` | Unavailable preference | Unavailable preference | mode=unavailable | excluded preference_unavailable | raw_fit=None; status=insufficient_evidence; exclusions=preference_unavailable | pass | `scenarios[19]` id=`20` |
| 21 | `21` / `missing_partner_measurement` | Missing partner measurement | Missing partner measurement | B has no EQ measurement | missing_partner_measurement | raw_fit=None; status=insufficient_evidence; exclusions=missing_partner_measurement | pass | `scenarios[20]` id=`21` |
| 22 | `22` / `missing_self_measurement_similarity` | Missing self measurement for similarity mode | Missing self measurement for similarity mode | similarity_to_self without A measurement | missing_self_measurement | raw_fit=None; status=insufficient_evidence; exclusions=missing_self_measurement | pass | `scenarios[21]` id=`22` |
| 23 | `23` / `non_publishable_partner` | Non-publishable partner measurement | Non-publishable partner measurement | publishability=false | non_publishable_partner_measurement | raw_fit=None; status=insufficient_evidence; exclusions=non_publishable_partner_measurement | pass | `scenarios[22]` id=`23` |
| 24 | `24` / `zero_importance` | Zero importance | Zero importance | importance=0 | zero_importance; null raw_fit | raw_fit=None; status=insufficient_evidence; exclusions=zero_importance | pass | `scenarios[23]` id=`24` |
| 25 | `25` / `one_way_directional_only` | One-way directional fit only | One-way directional fit only | A has prefs; B has none | mutual null; A<-B available | {"A_to_B":1.0,"B_to_A":null,"mutual":null} | pass | `scenarios[24]` id=`25` |
| 26 | `26` / `strong_A_weak_B` | Strong A<-B and weak B<-A | Strong A<-B and weak B<-A | A wants mid; B wants high; both measured mid | A_to_B > B_to_A; mutual = geometric mean | {"A_to_B":1.0,"B_to_A":0.4111122905071873,"asymmetry":0.5888877094928127,"mutual":0.6411803884299545} | pass | `scenarios[25]` id=`26` |
| 27 | `27` / `weak_A_strong_B` | Weak A<-B and strong B<-A | Weak A<-B and strong B<-A | roles swapped vs 26 | A_to_B < B_to_A | {"A_to_B":0.4111122905071873,"B_to_A":1.0,"mutual":0.6411803884299545} | pass | `scenarios[26]` id=`27` |
| 28 | `28` / `both_directions_strong` | Both directions strong | Both directions strong | both prefer mid; both measured mid | both near 1; mutual near 1 | {"A_to_B":1.0,"B_to_A":1.0,"mutual":1.0} | pass | `scenarios[27]` id=`28` |
| 29 | `29` / `both_directions_weak` | Both directions weak | Both directions weak | both prefer high; both measured 0 | both raw_fit low | {"A_to_B":0.0017981666618475782,"B_to_A":0.0017981666618475782,"mutual":0.0017981666618475782} | pass | `scenarios[28]` id=`29` |
| 30 | `30` / `pair_input_reversed` | Pair input reversed | Pair input reversed | reverse of scenario 26 pair | mutual/asymmetry/fingerprint invariant | {"asymmetry_equal":true,"directions_swapped":true,"fingerprint_equal":true,"mutual_equal":true} | pass | `scenarios[29]` id=`30` |
| 31 | `31` / `map_order_shuffled` | Map order shuffled | Map order shuffled | preference/measurement insert order reversed | same raw_fit and fingerprint | {"fit_a":0.7901961498644672,"fit_b":0.7901961498644672,"fp_equal":true} | pass | `scenarios[30]` id=`31` |
| 32 | `32` / `registry_24d` | 24-dimension registry | 24-dimension registry | fixture registry with 24 entries | raw_fit == 1 without service code changes | raw_fit=1.0; status=complete | pass | `scenarios[31]` id=`32` |
| 33 | `33` / `invalid_score` | Invalid score | Invalid score | partner score=1.5 | invalid_partner_score | raw_fit=None; status=insufficient_evidence; exclusions=invalid_partner_score | pass | `scenarios[32]` id=`33` |
| 34 | `34` / `invalid_importance` | Invalid importance | Invalid importance | importance=1.5 | invalid_importance | raw_fit=None; status=insufficient_evidence; exclusions=invalid_importance | pass | `scenarios[33]` id=`34` |
| 35 | `35` / `invalid_flexibility` | Invalid flexibility | Invalid flexibility | flexibility=-0.1 | invalid_flexibility | raw_fit=None; status=insufficient_evidence; exclusions=invalid_flexibility | pass | `scenarios[34]` id=`35` |
| 36 | `36` / `nan_rejection` | NaN rejection | NaN rejection | partner score=NaN | invalid_partner_score | raw_fit=None; status=insufficient_evidence; exclusions=invalid_partner_score | pass | `scenarios[35]` id=`36` |
| 37 | `37` / `infinity_rejection` | Infinity rejection | Infinity rejection | partner confidence=+inf | invalid_partner_confidence | raw_fit=None; status=insufficient_evidence; exclusions=invalid_partner_confidence | pass | `scenarios[36]` id=`37` |
| 38 | `38` / `registry_mismatch` | Registry mismatch | Registry mismatch | config.registry_version != registry | throws validation error | {"threw":"CoreMethodValidationException"} | pass | `scenarios[37]` id=`38` |
| 39 | `39` / `scoring_contract_mismatch` | Scoring-contract mismatch | Scoring-contract mismatch | similarity mode with differing scoring contracts | scoring_contract_mismatch | raw_fit=None; status=insufficient_evidence; exclusions=scoring_contract_mismatch | pass | `scenarios[38]` id=`39` |
| 40 | `40` / `high_structural_low_preference` | High structural similarity with low preference fit | High structural similarity with low preference fit | independent structural + preference evaluations | structural high AND preference low; not aggregated | {"aggregated":false,"preference_raw_fit":0.2059242464341986,"structural_eq_similarity":1.0} | pass | `scenarios[39]` id=`40` |
| 41 | `41` / `low_structural_high_preference` | Low structural similarity with high preference fit | Low structural similarity with high preference fit | independent structural + preference evaluations | structural low AND preference high; not aggregated | {"aggregated":false,"preference_raw_fit":1.0,"structural_eq_similarity":0.016879884148789895} | pass | `scenarios[40]` id=`41` |

## Notes

- Scenarios 40 and 41 compute structural similarity and preference fit separately;
  they do not aggregate the two engines.
- Pre-audit report incorrectly stated 24 scenarios while referencing IDs 26 and 30;
  the prior collection had sparse IDs (gaps) totaling 24 entries including a `meta` row.
