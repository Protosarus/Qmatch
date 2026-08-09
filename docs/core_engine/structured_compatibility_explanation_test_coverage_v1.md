# Structured Compatibility Explanation Test Coverage v1

Phase: **P2B-5**. Mapped to
`test/core_method_v2_structured_explanation_service_test.dart` and offline tools.

| Req | Requirement | Test / tool | Status |
|----:|-------------|----------------|--------|
| 1-2 | Config parse/schema | `1-2. Explanation config...` | covered |
| 3-6 | Registry parse/schema/keys | `3-6. Code registry...` | covered |
| 5 | Emitted codes in registry | `5,11-23...` | covered |
| 7-10 | Categories/polarities/bands/sources | `7-10...` | covered |
| 11-12 | Salience finite/bounded | `5,11-23...` | covered |
| 13-16 | Rank/order/dedupe | `13-16,18...` | covered |
| 17-18 | Blocking retained; hard first | `13-16,18` + `17,34-37` | covered |
| 19-23 | Caps / diversity / EQ cap | `5,11-23` + simulator | covered |
| 24-33 | Source fields / no recompute | `24-33...` | covered |
| 34-37 | Hard categorical rules | `17,34-37...` | covered |
| 38-40 | Missing / insufficient | `38-40,46-52...` | covered |
| 41-45 | Score/contribution preservation | `5,11-23...` | covered |
| 46-52 | Shrink params/directions | `38-40,46-52...` | covered |
| 53-58 | Direction/asymmetry/soft no score change | `53-58...` | covered |
| 59-62 | Privacy redaction | `59-62...` | covered |
| 63-75 | Localization / prohibitions / ser / fp / ts | `63-75...` | covered |
| 76-83 | Invalid/registry/fixtures | `76-83...` | covered |
| 84-95 | No service calls / production isolation | `84-95...` | covered |

Additional: `tool/validate_structured_compatibility_explanation_v1.dart`,
`tool/simulate_structured_compatibility_explanation_v1.dart` (90 scenarios).

**Summary:** 95/95 requirements mapped with status `covered`.
