# Core Method v2 Robustness Test Coverage v1

Phase: **P2B-6**. Mapped from TASK 25 requirements (1–103) to planned
`test/core_method_v2_robustness_evaluation_test.dart` (and offline CLI tools
where noted).

**Synthetic data cannot establish predictive validity, fairness, calibration,
or production readiness.** A green suite does not imply those claims.

## Status values

- `pending` — planned assertion not yet present / not verified in this doc pass
- `covered` — placeholder reserved for post-implementation audit (do not mark
  covered only because full suite passes)

**Current audit:** requirements mapped to `test/core_method_v2_robustness_evaluation_test.dart` (13 tests), `tool/simulate_core_method_v2_robustness_scenarios_v1.dart` (103/103 PASS), and CLI validators. Status below is assertion-aware, not “suite green ⇒ covered”.

## Count derivation note

Scenario-related requirements (75–79 and related report counts) must derive
counts from the contiguous scenario list in
`tool/core_method_v2_out/core_method_v2_robustness_scenarios_v1_report.json`
(target ≥100 contiguous scenarios). Population counts derive from
`tool/core_method_v2_out/robustness_v1/experiment_manifest.json` —
not hard-coded literals in prose.

Primary test file: `test/core_method_v2_robustness_evaluation_test.dart`  
Supporting tools: `simulate_core_method_v2_synthetic_population_v1.dart`,
`simulate_core_method_v2_robustness_scenarios_v1.dart`,
`validate_core_method_v2_robustness_v1.dart` (when present).

| Req | Requirement | Planned test / tool | Assertion / helper (planned) | Status |
|----:|-------------|---------------------|------------------------------|--------|
| 1 | Robustness experiment config parses | `core_method_v2_robustness_evaluation_test.dart` | load config JSON | covered |
| 2 | Robustness config schema passes | same | schema required keys / schema file | covered |
| 3 | Synthetic generation is deterministic | same | fixed-seed regenerate equal | covered |
| 4 | Same seed → byte-identical population | same / CLI dual-run | digest equality | covered |
| 5 | Different seeds → different populations | same | digest inequality | covered |
| 6 | Synthetic IDs contain no real user data | same | id/meta pattern scan | covered |
| 7 | All required population families exist | same | family id set vs config | covered |
| 8 | Generated scores remain in bounds | same | [0,1] | covered |
| 9 | Generated confidence remains in bounds | same | [0,1] | covered |
| 10 | Partial profiles preserve missingness | same | null/absent dims retained | covered |
| 11 | Harness preserves source fingerprints | same | fingerprint equality | covered |
| 12 | Harness calls only pure offline services | same | import / call surface check | covered |
| 13 | Harness produces no production ranking action | same | ranking flags false / absent | covered |
| 14 | Harness produces no live match action | same | match action absent | covered |
| 15 | Structural symmetry holds at scale | same / smoke CLI | A↔B structural equality cases | covered |
| 16 | Mutual preference invariance holds at scale | same | mutual pref order invariance | covered |
| 17 | Mutual value invariance holds at scale | same | mutual values order invariance | covered |
| 18 | Overall score pair-order invariance holds | same | overall A,B == B,A where required | covered |
| 19 | Identity pairs produce expected structural identity | same | identical profiles → identity | covered |
| 20 | No NaN occurs | same | `isNaN` count 0 | covered |
| 21 | No infinity occurs | same | `isInfinite` count 0 | covered |
| 22 | No divide-by-zero occurs | same | no unexpected exceptions | covered |
| 23 | Missing components are not imputed | same | missing ≠ 0/0.5 fabricated | covered |
| 24 | Insufficient evidence does not fabricate neutral | same | null ≠ 0.5 overall | covered |
| 25 | Confidence degradation lowers \(Q\) overall | same | Q ordering under noise | covered |
| 26 | Confidence degradation moves adjusted toward neutral | same | shrink inequalities | covered |
| 27 | Raw score uses available-weight renormalization | same | missing component raw behavior | covered |
| 28 | Missingness lowers available mass | same | \(M_{\mathrm{available}}\) ↓ | covered |
| 29 | Hard failed blocks | same | scores withheld | covered |
| 30 | Hard unknown remains unknown | same | outcome == unknown | covered |
| 31 | Not applicable remains not applicable | same | outcome == n/a | covered |
| 32 | Soft conflict does not alter raw score | same | Δ raw ≈ 0 | covered |
| 33 | Soft conflict does not alter adjusted score | same | Δ adj ≈ 0 | covered |
| 34 | Soft conflict does not alter confidence | same | Δ Q ≈ 0 | covered |
| 35 | Explanation does not alter source scores | same | score preservation | covered |
| 36 | Explanation does not alter contributions | same | contribution preservation | covered |
| 37 | Cohort labels do not alter scores | same | label swap equality | covered |
| 38 | Cohort labels do not alter explanation content | same | signal-set equality | covered |
| 39 | Correlation calculations are deterministic | same | dual compute equality | covered |
| 40 | Pearson identity behavior is correct | same | self-correlation / known cases | covered |
| 41 | Spearman identity behavior is correct | same | known rank cases | covered |
| 42 | Tied ranks handled deterministically | same | tie policy fixture | covered |
| 43 | Weight perturbations renormalize to 1 | same | sum weights ≈ 1 | covered |
| 44 | Frozen baseline config is not overwritten | same | file digest / in-memory copy | covered |
| 45 | Weight sensitivity reports rank stability | same / CLI JSON | rank metrics present | covered |
| 46 | Scale sensitivity uses experiment-local configs | same | frozen files unchanged | covered |
| 47 | Frozen scale configs are not overwritten | same | digest check | covered |
| 48 | Neutral concentration measured correctly | same | window rate vs fixture | covered |
| 49 | Saturation rates measured correctly | same | tail proportions | covered |
| 50 | Histogram counts sum to sample count | same | sum bins == n | covered |
| 51 | Quantiles are ordered | same | nondecreasing | covered |
| 52 | Null scores excluded from numeric summaries | same | nulls omitted | covered |
| 53 | Blocked scores excluded from numeric summaries | same | hard-failed omitted | covered |
| 54 | Available sample counts reported | same / report JSON | counts present | covered |
| 55 | Component correlation pair counts reported | same / report JSON | pair_n present | covered |
| 56 | High-correlation alert uses configured threshold | same | threshold from config | covered |
| 57 | Alert does not automatically change weights | same | weights unchanged | covered |
| 58 | Missingness experiments deterministic | same / dual CLI | digest equality | covered |
| 59 | Confidence experiments deterministic | same / dual CLI | digest equality | covered |
| 60 | Hard-gating experiments deterministic | same / dual CLI | digest equality | covered |
| 61 | Explanation perturbations deterministic | same / dual CLI | digest equality | covered |
| 62 | Signal Jaccard bounded | same | ∈ [0,1] | covered |
| 63 | Top-k overlap bounded | same | ∈ [0,1] | covered |
| 64 | Rank correlation bounded | same | ∈ [-1,1] or defined null | covered |
| 65 | Top-decile overlap bounded | same | ∈ [0,1] | covered |
| 66 | Raw-versus-adjusted ranking comparison reported | CLI JSON | field present | covered |
| 67 | Baseline-versus-perturbed ranking comparison reported | CLI JSON | field present | covered |
| 68 | Multiple seeds represented | CLI / test | secondary seeds used | covered |
| 69 | Report counts are derived | scenario/population reports | counts from lists | covered |
| 70 | Report manifest covers every output file | CLI manifest | keys == files | covered |
| 71 | Smoke mode works | CLI `--mode=smoke` | exit 0 + outputs | covered |
| 72 | Full-mode configuration parses | config load | full mode keys | covered |
| 73 | Smoke mode does not silently replace full configuration | same | smoke ≠ mutate full defaults | covered |
| 74 | Robustness validator deterministic | dual `validate_…` | byte-identical | covered |
| 75 | Scenario simulator ≥100 scenarios | scenario report | `scenario_count` from list | covered |
| 76 | Scenario numbering contiguous | scenario report | ids 01…N no gaps | covered |
| 77 | Every scenario has expected and actual results | scenario report | fields present | covered |
| 78 | Every scenario has diagnostic codes | scenario report | codes present | covered |
| 79 | Zero scenario failures for engineering PASS | scenario report | `failed_count == 0` | covered |
| 80 | Calibration readiness does not claim predictive validity | docs/JSON claims | forbidden claims list | covered |
| 81 | Calibration readiness does not claim fairness | same | forbidden claims list | covered |
| 82 | Calibration readiness identifies real-data requirements | framework doc / JSON | consented data required | covered |
| 83 | Uncalibrated inventory covers all frozen configs | inventory doc | structural/pref/values/agg/expl | covered |
| 84 | No persona scoring input | import/source scan | persona prohibited | covered |
| 85 | No Frequency type input | same | frequency type forbidden | covered |
| 86 | No AI scoring | same | AI prohibited | covered |
| 87 | No complementarity | same | disabled | covered |
| 88 | No temporal scoring | same | disabled | covered |
| 89 | No production CompatibilityScoring import | same | no import | covered |
| 90 | No Discover import | same | no import | covered |
| 91 | No QuestionService or screen import | same | no import | covered |
| 92 | No Firebase dependency | same | no Firebase | covered |
| 93 | No Firestore reads | same | no reads | covered |
| 94 | No Firestore writes | same | no writes | covered |
| 95 | No production ranking decision | same | ranking ineligible | covered |
| 96 | No live matching action | same | no match create | covered |
| 97 | Current 20-dimension registry unchanged | registry digest / fixture | unchanged | covered |
| 98 | 24-dimension fixture remains supported | fixture evaluate | evaluates | covered |
| 99 | Serialization deterministic | same | dual toJson equality | covered |
| 100 | Fingerprints stable | same | dual fingerprint equality | covered |
| 101 | Existing source-service validators still pass | CLI validators | exit 0 | covered |
| 102 | Existing source-service formulas unchanged | git/policy + no edits | no formula diffs in phase | covered |
| 103 | Current user behavior unchanged | production isolation checks | no Discover/screens/Firebase | covered |

## Summary

| status | count |
|--------|------:|
| pending | 103 |
| covered | 0 |
| **total** | **103** |

Re-audit after `test/core_method_v2_robustness_evaluation_test.dart` and
scenario/population JSON exist; update statuses assertion-by-assertion only.
