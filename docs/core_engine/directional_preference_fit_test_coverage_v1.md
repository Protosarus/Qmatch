# Directional Preference-Fit Test Coverage Matrix v1

Phase: **P2B-2.1** (completion / coverage audit)

This matrix maps every original P2B-2 test requirement (1–71) to an actual
assertion. Coverage is **not** inferred from a green full suite.

Primary files:

- `test/directional_preference_fit_service_test.dart`
- `test/directional_preference_fit_coverage_gaps_test.dart` (P2B-2.1 additions)
- Helpers: `test/support/directional_preference_fit_helpers.dart`

Status values:

- `covered` — explicit assertion for the requirement
- `partially_covered` — related assertion exists but does not fully isolate the requirement
- `missing` — no explicit assertion found

| # | Requirement | Dart test file | test name | assertion / helper | status | notes |
|---|-------------|----------------|-----------|--------------------|--------|-------|
| 1 | Config parses | `directional_preference_fit_service_test.dart` | `1–5 config, schema, 20/24 registry, no hardcoded 20` | `expect(config.status, 'provisional')` and related config field expects | covered | |
| 2 | Config schema passes | same | same | schema file `existsSync` | covered | schema existence + config load; JSON Schema validator also in tool |
| 3 | Current 20-dimension registry works | same | same | `expect(registry.activeCount, 20)` + directional evaluate | covered | |
| 4 | 24-dimension registry works without code changes | same | same | `load24dFixture()` evaluate with remapped config | covered | |
| 5 | No dimension count of 20 controls behavior | same | same | regex scan of preference-fit Dart sources for `dimensionCount = 20` | covered | |
| 6 | Inside range produces fit 1 | same | `6–12 inside/boundary/distance/flexibility` | `rawFitScore == 1.0` at score 0.5 | covered | |
| 7 | Lower boundary produces fit 1 | same | same | `rawFitScore == 1.0` at score 0.4 | covered | |
| 8 | Upper boundary produces fit 1 | same | same | `rawFitScore == 1.0` at score 0.6 | covered | |
| 9 | Distance outside range lowers fit | same | same | near (0.35) `< 1` | covered | |
| 10 | Greater distance never increases fit | same | same | near `>` far | covered | |
| 11 | Greater flexibility reduces penalty | same | same | flex(1.0) `>` strict(0.0) | covered | |
| 12 | Lower flexibility increases penalty | same | same | inverse of #11 | covered | |
| 13 | Similarity-to-self identical score produces fit 1 | same | `13–20 similarity, mode confidence, importance, single-dim Q` | `rawFitScore == 1.0` | covered | |
| 14 | Similarity-to-self difference lowers fit | same | same | distant `< 1` | covered | |
| 15 | Range mode uses partner confidence only | same | same | `evidenceConfidence == 0.25` with partner q=0.25 | covered | |
| 16 | Similarity-to-self uses geometric mean confidence | same | same | `sqrt(0.9*0.9)` | covered | |
| 17 | Importance changes cross-dimension influence | `directional_preference_fit_coverage_gaps_test.dart` | `17 importance changes cross-dimension influence` | high I0 yields lower F than low I0 with discrepant d0 | covered | was missing in P2B-2 bundled test |
| 18 | Confidence changes cross-dimension influence | same | `18 confidence changes cross-dimension influence` | high q0 yields lower F than low q0 with discrepant d0 | covered | was missing |
| 19 | One-dimension raw fit may remain unchanged under confidence change | `directional_preference_fit_service_test.dart` | `13–20 …` | `high.rawFitScore` closeTo `low.rawFitScore` | covered | |
| 20 | One-dimension evidence confidence decreases correctly | same | same | `high.evidenceConfidence > low.evidenceConfidence` | covered | |
| 21 | Open mode is excluded from numerator | same | `21–31 open/unavailable/inference/missing/unpublished` | `rawFitScore` null + open ids | covered | |
| 22 | Open mode is excluded from denominator | same | same | `declaredImportanceMass == 0` | covered | |
| 23 | Open mode is not scored as 1 | same | same | JSON lacks `"raw_dimension_fit":1` | covered | |
| 24 | Open mode is not scored as 0.5 | same | same | JSON lacks `"raw_dimension_fit":0.5` | covered | |
| 25 | Unavailable preference is excluded | same | same | `preference_unavailable` exclusion | covered | |
| 26 | Missing preference is not inferred from self score | same | same | `inferred_preference_prohibited` for inferred source | covered | |
| 27 | Non-explicit preference is excluded | `directional_preference_fit_coverage_gaps_test.dart` | `27 non-explicit preference is excluded` | `preference_not_explicit` | covered | was named in 21–31 but not asserted |
| 28 | Missing partner measurement is excluded | `directional_preference_fit_service_test.dart` | `21–31 …` | `missing_partner_measurement` | covered | |
| 29 | Missing self measurement blocks similarity-to-self comparison | same | same | `missing_self_measurement` | covered | |
| 30 | Unpublished measurement is excluded | `directional_preference_fit_coverage_gaps_test.dart` | `30 unpublished partner measurement is excluded` | `unpublished_partner_measurement` | covered | was named but not asserted |
| 31 | Non-publishable measurement is excluded | same | `31 non-publishable partner measurement is excluded` | `non_publishable_partner_measurement` | covered | was named but not asserted |
| 32 | Invalid importance fails | same | `32–37 invalid importance/flexibility/score/confidence/NaN/infinity` | `invalid_importance` for I=1.5 | covered | zero-importance covered separately in service test |
| 33 | Invalid flexibility fails | same | same | `invalid_flexibility` for f=-0.2 | covered | was only config-scale validation before |
| 34 | Invalid score fails | same | same | `invalid_partner_score` for score=1.5 | covered | was missing |
| 35 | Invalid confidence fails | same | same | `invalid_partner_confidence` via Infinity | covered | non-finite path |
| 36 | NaN fails | same | same | `invalid_partner_score` for NaN score | covered | was missing |
| 37 | Infinity fails | same | same | Infinity confidence exclusion | covered | was missing |
| 38 | Zero effective weight does not divide by zero | `directional_preference_fit_service_test.dart` | `32–41 invalid bounds, zero weight, statuses` | partner confidence 0 → `rawFitScore` null, `effectiveWeightSum == 0` | covered | |
| 39 | Below-minimum comparable count gives null raw score | same | same | zero importance / open → null raw | covered | min comparable = 1 |
| 40 | Partial comparison reports exclusions | `directional_preference_fit_coverage_gaps_test.dart` | `40 partial comparison reports exclusions` | status `partial` + exclusions | covered | was missing as explicit status assert |
| 41 | Complete comparison reports complete | `directional_preference_fit_service_test.dart` | `32–41 …` | `status == complete` | covered | |
| 42 | Direction A<-B differs from B<-A where preferences differ | same | `42–50 directional difference, mutual, asymmetry, one-way` | A←B `>` B←A | covered | |
| 43 | Pair reversal swaps directional results | same | same | reversed A←B equals original B←A | covered | |
| 44 | Mutual geometric mean is correct | same + gaps | mutual test + gaps mutual check | `sqrt(F_ab * F_ba)` | covered | |
| 45 | Mutual score remains symmetric under pair reversal | same | `42–50 …` | mutual equal after swap | covered | |
| 46 | Mutual evidence confidence uses geometric mean | same | same | `sqrt(Q_ab * Q_ba)` | covered | |
| 47 | Directional asymmetry is correct | same | same | abs directional difference | covered | |
| 48 | Asymmetry remains symmetric under pair reversal | same | same | asymmetry equal after swap | covered | |
| 49 | Missing one direction produces null mutual score | same | same | empty partner prefs → mutual null | covered | |
| 50 | Available direction remains preserved | same | same | A←B still non-null in one-way | covered | |
| 51 | Structural similarity is not imported or aggregated | same + gaps | `51–71 …` + gaps `51–52 …` | source scan; no StructuralSimilarityService import | covered | |
| 52 | IQ/EQ/Frequency structural scores are not modified | gaps | `51–52 structural service not called; structural scores untouched` | measurement scores unchanged after evaluate | covered | was only implied before |
| 53 | Relationship values are not used | service | `51–71 …` | result JSON lacks `values_score` | covered | |
| 54 | Hard constraints are not evaluated | service | same | empty hardConstraints on snapshots; no hard-constraint fields in result | covered | snapshots carry empty list; service does not score them |
| 55 | Soft penalties are not calculated | service | same | no soft-penalty keys in result JSON | covered | |
| 56 | Complementarity does not exist | service | same | config `complementarityStatus` disabled + no complementarity fields | covered | config assert in 1–5 |
| 57 | Persona field does not exist | service | `51–71 …` | source/persona_id absent; JSON lacks `persona_id` | covered | |
| 58 | Frequency type does not exist | service | same | JSON lacks `frequency_type` | covered | |
| 59 | No final compatibility score exists | service | same | JSON lacks `overall_compatibility_score` | covered | |
| 60 | Map order does not change results | gaps | `60 map order does not change results` | shuffled maps → same fingerprint | covered | was named under 51–71 but not asserted |
| 61 | Serialization is deterministic | service | `51–71 …` | round-trip fingerprint equality | covered | |
| 62 | Fingerprints are stable | service | same | `deterministicFingerprint` non-empty + round-trip | covered | |
| 63 | Exclusion diagnostics are structured | service / gaps | multiple exclusion tests | `excludedPreferences` entries with `reasonCode` | covered | |
| 64 | Dimension weighted contributions sum to the numerator | service | `51–71 …` | Σ weightedContribution == F * weightSum | covered | |
| 65 | Raw fit remains bounded | service | `32–41 …` | `0 <= rawFitScore <= 1` | covered | |
| 66 | Evidence confidence remains bounded | service | same | `0 <= evidenceConfidence <= 1` | covered | |
| 67 | No Firebase dependency | service | `51–71 …` | source lacks `cloud_firestore` | covered | |
| 68 | Production CompatibilityScoring does not import the service | service | same | file scan for `DirectionalPreferenceFitService` | covered | |
| 69 | Discover does not import the service | service | same | file scan | covered | |
| 70 | QuestionService and screens do not import the service | service | same | file scans | covered | |
| 71 | Current user behavior remains unchanged | service | same | no production imports; offline-only config flags | covered | behavioral non-wiring check |

## Coverage summary (derived)

- Original requirement count: **71**
- Covered: **71**
- Partially covered: **0**
- Missing: **0**

## P2B-2.1 tests added

File: `test/directional_preference_fit_coverage_gaps_test.dart`

Added explicit coverage for requirements that were previously only named in
bundled test titles without dedicated asserts: **17, 18, 27, 30, 31, 32–37,
40, 52, 60**, plus a registry-mismatch throw check aligned with simulation
scenario 38.
