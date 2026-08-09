# Persona Prototype Simulation Report v2 (PROVISIONAL)

## 1. Executive summary

Offline synthetic validation of provisional 20D persona prototypes (`persona_profiles_v2_20d.0`) with config `persona_scoring_config_v2.0`.
- Simulated **200000** profiles (seed **42**).
- Assigned **186673**; insufficient-evidence blocked **13327**.
- Normalized entropy **0.9550**; max share **0.1284** (`bagimsiz`); min share **0.0207** (`stratejist`).
- Exact-prototype recovery **1.0**; near-prototype recovery **0.9988**.
- Unreachable personas: **none**.
- Central forced-label max share **0.2651** (`sezgisel`), but central ambiguous rate **0.9542** — central profiles are mostly low-margin/low-confidence rather than confident collapse.
- **Production PersonaScoringService is NOT claimed ready**; this phase is synthetic validation only.

## 2. Prototype version

`persona_profiles_v2_20d.0`

## 3. Config version

`persona_scoring_config_v2.0`

## 4. Simulation methodology

- Offline Dart simulator: `tool/persona_prototype_simulator.dart`
- No Firebase, no network, fixed seed RNG
- Formula: group-normalized level (α=0.65) + shape (β=0.35) distances; group weights IQ 0.15 / EQ 0.30 / Frequency 0.55; `S=exp(-D/T)` with T=0.22
- Similarity is **not** probability; confidence uses coverage + top-2 margin
- No persona quotas; no random tie-break

## 5. Simulation seed

42

## 6. Generator definitions

- `uniform`: 32000
- `cluster_0_5`: 20000
- `low_variance_central`: 16000
- `high_variance`: 16000
- `all_high`: 6000
- `all_low`: 6000
- `alternating`: 10000
- `correlated_eq`: 10000
- `correlated_freq`: 10000
- `near_prototype`: 24000
- `between_pairs`: 16000
- `exact_prototype`: 4000
- `missing_iq`: 6000
- `missing_eq`: 6000
- `missing_frequency`: 6000
- `random_missing`: 8000
- `exact_tie_synth`: 2000
- `near_tie_synth`: 2000

## 7. Total simulated profiles

200000 (processed 200000)

## 8. Assignment distribution

| Persona | Count | Share |
|---|---:|---:|
| `bagimsiz` | 23974 | 0.1284 |
| `empat` | 17665 | 0.0946 |
| `sezgisel` | 17323 | 0.0928 |
| `uygulayici` | 16269 | 0.0872 |
| `vizyoner` | 14534 | 0.0779 |
| `cesur` | 13048 | 0.0699 |
| `iletisimci` | 10876 | 0.0583 |
| `analist` | 10155 | 0.0544 |
| `yaratici` | 9237 | 0.0495 |
| `koruyucu` | 7417 | 0.0397 |
| `lider` | 7283 | 0.0390 |
| `donusturucu` | 7206 | 0.0386 |
| `bilge` | 6865 | 0.0368 |
| `sifaci` | 5902 | 0.0316 |
| `kararli` | 5514 | 0.0295 |
| `muhafiz` | 4957 | 0.0266 |
| `yargic` | 4593 | 0.0246 |
| `stratejist` | 3855 | 0.0207 |

## 9. Normalized entropy

0.954951 (1.0 = uniform over 18)

## 10. Maximum and minimum persona shares

- Max: 0.1284
- Min: 0.0207
- Unequal shares are acceptable; no quota correction applied.

## 11. Unreachable persona analysis

Unreachable list: `[]` — **PASS** (all 18 reachable).

## 12. Central-collapse analysis

- Central assignment max: `sezgisel` share=0.2651
- Central ambiguous rate: 0.9542
- Among non-ambiguous central only: max `bagimsiz` share=0.2759 (n=1649)
- Interpretation: near-0.5 profiles correctly produce tiny top-2 margins; forced primary labels are not high-confidence identity claims.
- Gate judgment: **CONDITIONAL** (improved vs earlier vizyoner~47% collapse; still watch central label concentration).

## 13. Prototype recovery accuracy

- Exact: 1.0
- Near: 0.998833

## 14. Difficult-pair confusion analysis

Most frequent primary|secondary co-occurrences (not probabilities):

- `empat|sifaci`: 12220
- `kararli|uygulayici`: 12125
- `analist|bagimsiz`: 10170
- `cesur|donusturucu`: 9453
- `empat|sezgisel`: 9139
- `donusturucu|iletisimci`: 7021
- `sezgisel|vizyoner`: 6761
- `koruyucu|sifaci`: 6546
- `vizyoner|yaratici`: 6303
- `bagimsiz|uygulayici`: 4909
- `bagimsiz|sezgisel`: 4769
- `lider|uygulayici`: 4417

Documented separator dimensions exist for required difficult pairs in blueprint + JSON `separator_targets`.

## 15. Top-2 margin analysis

- p10=0.003938
- p50=0.027558
- p90=0.102361
- near-tie count (margin < threshold 0.035): 106402
- exact-tie count: 0

## 16. Low-confidence analysis

- low_confidence_count=106402 of assigned 186673 (0.570)
- Confidence is separate from similarity; low confidence often tracks small top-2 margins.

## 17. Missing-data behavior

- Generators `missing_iq`=6000, `missing_eq`=6000, `missing_frequency`=6000, `random_missing`=8000
- Overall insufficient-evidence blocks: 13327
- Missing Frequency/EQ coverage fails minimum group coverage rather than filling 0.5.
- Missing dims use q_j=0 (excluded from distance), never imputed as neutral trait values.

## 18. Anti-trait behavior

- Anti-traits add bounded penalty `γ * A_p` with γ=0.12; A capped at 1.
- Not applied when evidence < minimum_evidence_required.
- Cannot alone select a persona; never produces negative similarity.
- Provisional; not calibrated on real users.

## 19. Group-weight behavior

- Frequency-first weighting preserved (0.55). Within-group normalization precedes group mix.
- Personas with distinctive Frequency peaks/valleys separate more strongly than IQ-only differences.

## 20. Level-versus-shape comparison

- α=0.65 level, β=0.35 shape.
- Shape term prevents “all high” / “all low” profiles from matching only by absolute level when relative peaks differ.
- At central profiles, shape distance penalizes peaked prototypes; combined with tiny margins → ambiguity (desired).

## 21. Determinism test

- Two runs with seed=42, n=200000: fingerprints identical; assignment counts identical; `fingerprint_sha_like` matched.
- **PASS**

## 22. Manual adjustments made

1. Increased Frequency extremity across prototypes to reduce mid-profile magnets.
2. Strengthened lider/donusturucu/yargic/yaratici/stratejist Frequency variance after observing flatter Frequency signatures winning the center.
3. Lowered similarity temperature 0.35 → 0.22 to stretch margins (still provisional).
4. top2_margin_threshold 0.04 → 0.035; low_confidence_threshold 0.55 → 0.50.
5. Simulator metrics extended with central ambiguous / non-ambiguous shares.

## 23. Before/after results for every adjustment

| Adjustment | Before | After |
|---|---|---|
| Frequency retune + T=0.22 | central_max vizyoner ~0.47; entropy ~0.939 | central_max sezgisel ~0.265; entropy ~0.955; amb_rate ~0.954 |
| Exact/near recovery | 1.0 / ~0.993 | 1.0 / ~0.999 |
| Max overall share | bagimsiz ~0.154 | bagimsiz ~0.128 |

## 24. Failed experiments

- Attempting to eliminate all central forced-label concentration while keeping peaked prototypes: mathematically limited because all-0.5 vectors sit between prototypes; tiny margins remain. Treating this as ambiguity rather than forcing equal shares (quota forbidden).
- Level-only ranking of center distance did not predict final winners once shape term included.

## 25. Remaining risks

- Provisional targets are synthetic hypotheses, not clinical norms.
- High near-tie rate implies adaptive separators will be important later.
- Difficult pairs (empat|sifaci, kararli|uygulayici) remain most confused.
- No real-user calibration; Frequency item mapping to 6D still depends on assessment pipeline integrity.
- Contract tests do not prove relational validity.

## 26. Production-readiness decision

**NOT production-ready.** Safe to begin implementing a *pure offline/library* PersonaScoringService behind flags only after this design is accepted; **not** safe to wire into live assessment, Firestore persona docs, or Discover.

---

## Quality gates

| # | Gate | Result | Evidence |
|---|---|---|---|
| 1 | All 18 reachable | PASS | unreachable=[] |
| 2 | Exact prototype recovery | PASS | 1.0 |
| 3 | Near prototype recovery high | PASS | 0.9988 |
| 4 | No excessive central collapse | CONDITIONAL | max_share=0.265, amb_rate=0.954 |
| 5 | Prototypes distinguishable | PASS | contract pairwise distance + uniqueness |
| 6 | Difficult pairs have separators | PASS | blueprint + JSON separator_targets |
| 7 | Missing groups reduce coverage | PASS | q_j=0; insufficient on missing EQ/Frequency |
| 8 | Insufficient evidence blocks persona | PASS | blocked=13327 |
| 9 | Deterministic same seed/input | PASS | fingerprint cmp identical |
| 10 | No random persona selection | PASS | deterministic tie-break policy |
| 11 | No persona quota | PASS | config notes + no post-hoc redistribution |
| 12 | No legacy HH/HM grid IDs | PASS | contract + grep |
| 13 | No Frequency descriptive types as personas | PASS | contract |
| 14 | Similarity ≠ confidence | PASS | separate fields/thresholds |
| 15 | Frequency-first group weights | PASS | 0.15/0.30/0.55 |

## Runtime integration confirmation

Code search: `persona_profiles_v2_20d.json` / `persona_scoring_config_v2.json` are referenced only by offline tool + contract test — **not** by `lib/` production Flutter code. No production PersonaScoringService, no assessment routing changes, no Firestore persona writes in this phase.
