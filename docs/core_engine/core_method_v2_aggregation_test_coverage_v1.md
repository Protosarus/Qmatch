# Core Method v2 Aggregation Test Coverage v1

Phase: **P2B-4**. Mapped from explicit requirements to
`test/core_method_v2_aggregation_service_test.dart` and offline tools.

Coverage status values: `covered` | `partial` | `missing`.

| Req | Requirement | Dart test / tool | Assertion/helper | Status | Notes |
|----:|-------------|------------------|------------------|--------|-------|
| 1 | Config parses | `Aggregation config parses` | `loadConfig` | covered | |
| 2 | Schema passes | `Aggregation config schema passes` | schema required keys | covered | |
| 3 | Five components | `Exactly five configured components` | key set | covered | |
| 4 | Weights sum to 1 | `Component weights sum to 1` | fold sum | covered | |
| 5 | Weight derivation documented | `Weight derivation is documented` | decision md | covered | |
| 6 | Weights finite | `All weights are finite` | `isFinite` | covered | |
| 7 | Weights positive | `All weights are positive` | `>0` | covered | |
| 8 | Raw uses available only | `Available-only aggregation` | miss vs full | covered | |
| 9 | Available weights renormalized | same | raw stays 0.8 | covered | |
| 10 | Missing ≠ 0 | same | `isNot(0)` | covered | |
| 11 | Missing ≠ 0.5 | same | `isNot(0.5)` | covered | |
| 12 | Missing ≠ 0.42 | same | `isNot(0.42)` | covered | |
| 13 | Missing lowers mass | `Missing component lowers available weight mass` | mass 0.92 | covered | |
| 14 | Missing can leave raw unchanged | `Missing component can leave raw score unchanged` | equal scores | covered | |
| 15 | Contributions sum to raw | `Component weighted contributions sum` | fold | covered | |
| 16 | Confidence contrib sum | `Confidence contributions sum` | fold | covered | |
| 17 | Q_available_mean | `Q_available_mean, M_available...` | mean 0.8 | covered | |
| 18 | M_available | same | mass 0.92 | covered | |
| 19 | Q_overall | same | 0.736 | covered | |
| 20 | Q = M × mean | same | identity | covered | |
| 21 | Q bounded | `Scores and confidence remain bounded` | [0,1] | covered | |
| 22 | Raw bounded | same | [0,1] | covered | |
| 23 | Adjusted bounded | same | [0,1] | covered | |
| 24 | Q=1 preserves raw | `Q=1 preserves raw score` | equality | covered | |
| 25 | Q=0 → neutral | `Q=0 moves a valid raw score to neutral` | 0.5 | covered | |
| 26 | Lower Q moves high raw down | `Lower Q moves high/low raw` | inequalities | covered | |
| 27 | Lower Q moves low raw up | same | inequalities | covered | |
| 28 | Neutral raw stays | `Neutral raw score remains neutral` | 0.5 | covered | |
| 29 | Never farther from neutral | `Adjustment never moves farther` | abs distance | covered | |
| 30 | Insufficient ≠ fabricate 0.5 | `Insufficient evidence nulls scores` | null ≠ 0.5 | covered | |
| 31 | Below min count → null | same | null | covered | |
| 32 | Below min mass → null | same | null | covered | |
| 33 | Exact min count may score | `Exactly minimum count/mass may score` | count=2 | covered | |
| 34 | Exact min mass may score | same | mass=0.5 cfg | covered | |
| 35 | Zero weight no /0 | `Zero available weight does not divide by zero` | null status | covered | |
| 36 | IQ maps | `Source field mapping` | component id | covered | via contribution path |
| 37 | EQ maps | same | | covered | |
| 38 | Frequency maps | same | | covered | |
| 39 | Preference maps | same | | covered | |
| 40 | Values maps | same | | covered | |
| 41 | Invalid score fails | `Invalid score/confidence/NaN/Infinity` | invalid_input | covered | |
| 42 | Invalid confidence fails | same | | covered | |
| 43 | NaN fails | same | | covered | |
| 44 | Infinity fails | same | | covered | |
| 45 | Invalid weight fails | `Invalid weight / neutral score` | throws | covered | |
| 46 | Invalid neutral fails | same | throws | covered | |
| 47 | Registry mismatch | `Registry/config mismatch policy` | invalid_input | covered | |
| 48 | Config mismatch | same | flagged diag | covered | |
| 49 | Partial scoreable | `Partial/insufficient/invalid` | included | covered | |
| 50 | Insufficient excluded | same | excluded | covered | |
| 51 | Invalid source diagnostics | same | invalid_input | covered | |
| 52 | Hard failed blocks | `Hard failed blocks scores...` | null | covered | |
| 53 | Hard failed ≠ 0 | same | `isNot(0)` | covered | |
| 54 | Hard failed audit | same | 5 contributions | covered | |
| 55 | Hard unknown ≠ passed | `Hard unknown retains scores...` | | covered | |
| 56 | Hard unknown ≠ failed | same | | covered | |
| 57 | Hard unknown keeps scores | same | non-null | covered | |
| 58 | Hard unknown not publishable | same | false | covered | |
| 59 | Hard unknown not ranking | same | false | covered | |
| 60 | Hard passed allows | `Hard passed/not_applicable` | non-null | covered | |
| 61 | Hard n/a allows | same | non-null | covered | |
| 62 | n/a not relabelled passed | same | outcome check | covered | |
| 63 | Soft ≠ alter raw | `Soft severity diagnostics only` | equality | covered | |
| 64 | Soft ≠ alter adjusted | same | | covered | |
| 65 | Soft ≠ alter Q | same | | covered | |
| 66 | High soft ≠ hard fail | same | status | covered | |
| 67 | Pref asymmetry ≠ raw | `Asymmetry diagnostics only` | | covered | |
| 68 | Value asymmetry ≠ raw | same | | covered | |
| 69 | Asymmetry retained | same | codes | covered | |
| 70 | No soft penalty | same | policy + flag | covered | |
| 71 | No complementarity | `No complementarity/temporal/...` | flags | covered | |
| 72 | No temporal | same | | covered | |
| 73 | No persona | same | | covered | |
| 74 | No Frequency type | same | | covered | |
| 75 | No AI score | same | | covered | |
| 76 | No structural service call | `Aggregation service does not call...` | source scan | covered | |
| 77 | No preference service call | same | | covered | |
| 78 | No value service call | same | | covered | |
| 79 | Source services unchanged | same + prior validators | isolation | covered | regression via validators |
| 80 | Module results visible | `Module source results remain...` | contributions | covered | |
| 81 | Serialization deterministic | `Serialization, order, fingerprint` | round-trip | covered | |
| 82 | Map order invariant | same | fingerprint | covered | |
| 83 | Component order invariant | same | raw | covered | |
| 84 | Fingerprint stable | same | equality | covered | |
| 85 | Timestamp injected | `Evaluation timestamp is injected` | equality | covered | |
| 86 | 20d registry unaffected | `Registry and 24d fixture` | count=20 | covered | |
| 87 | 24d fixture supported | same | exists | covered | |
| 88 | CompatibilityScoring no import | `Production ... isolation` | file scan | covered | |
| 89 | Discover no import | same | | covered | |
| 90 | QuestionService/screens no import | same | | covered | |
| 91 | No Firebase dependency | `No Firebase/ranking...` | source scan | covered | |
| 92 | No Firestore write | same | | covered | |
| 93 | No production ranking | same | flags | covered | |
| 94 | No live match action | same | liveRankingEligible | covered | |
| 95 | Current user behavior unchanged | same | offline_only | covered | offline-only confirmation |

Additional offline coverage:

- `tool/validate_core_method_v2_aggregation_v1.dart`
- `tool/simulate_core_method_v2_aggregation_v1.dart` (90 contiguous scenarios)

**Summary:** 95/95 requirements mapped with status `covered`.
