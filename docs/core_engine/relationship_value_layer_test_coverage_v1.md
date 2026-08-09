# Relationship Value Layer Test Coverage Matrix v1

Phase: **P2B-3**

Primary file: `test/relationship_value_layer_service_test.dart`  
Helpers: `test/support/relationship_value_layer_helpers.dart`  
Additional: validators + `tool/simulate_relationship_value_layer_v1.dart` (65 scenarios)

| # | Requirement | Test / artifact | status |
|---|-------------|-----------------|--------|
| 1 | Config parses | `1–7 config/schema/matrix validation` | covered |
| 2 | Schema exists | same | covered |
| 3 | Configured fields exist | same | covered |
| 4 | Allowed values handled | exact/matrix/ordered/set tests | covered |
| 5 | Missing matrix cell fails | incomplete matrix throws in `1–7` | covered |
| 6 | Symmetric matrix validation | config `validateAgainstRegistry` | covered |
| 7 | Directional matrix remains directional | sim 06 + mutual asymmetry test | covered |
| 8–9 | Exact match 1/0 | `8–15` (flex=0) | covered |
| 10–11 | Ordered identity/monotonic | `8–15` | covered |
| 12–14 | Set identity/partial/disjoint | `8–15` | covered |
| 15 | Missing ≠ empty set | empty selectedValues exclusion | covered |
| 16–18 | Flexibility 0/1/monotonic | `16–25` | covered |
| 19 | Importance cross-field | sim 16–17 | covered |
| 20 | Zero importance excluded | `26–40` | covered |
| 21–25 | Directional/mutual/reversal/asymmetry | `16–25` | covered |
| 26–29 | Missing not imputed 0/0.5/0.42 | `26–40` + helper | covered |
| 30–32 | Private/permission/pending | `26–40` | covered |
| 33–37 | Invalid / NaN / Inf | sims 32–36 | covered |
| 38–40 | Bounds + coverage | service tests + coverage fields | covered |
| 41–55 | Hard enable/disable/pass/fail/unknown/precedence/no numeric | `41–55` + sims 37–50 | covered |
| 56–63 | Soft severity/bands/max/non-blocking | `56–70` + sims 51–59 | covered |
| 64–66 | No structural/preference/module aggregation | `56–70` import checks + sims 60–61 | covered |
| 67–70 | No final score/persona/Frequency/AI | layer JSON checks | covered |
| 71–74 | Serialization/fingerprint/map order/exclusions | `71–81` | covered |
| 75–76 | 20/24 registry unaffected | `71–81` + sim 63 | covered |
| 77–81 | No Firebase/production imports/behavior unchanged | `71–81` file scans | covered |

## Coverage summary

- Original requirement count: **81**
- Covered: **81**
- Missing: **0**
