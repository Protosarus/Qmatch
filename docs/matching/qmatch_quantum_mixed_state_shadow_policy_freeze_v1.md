# QMatch Quantum Mixed-State Shadow Policy Freeze v1

| Field | Value |
| --- | --- |
| Policy id | `quantum_mixed_state_shadow_policy_freeze_v1` |
| Layer contract | [`l5_mixed_state_qi_contract_v1`](./qmatch_l5_mixed_state_qi_contract_v1.md) |
| Scoring version | `quantum_mixed_state_shadow_v1` |
| Status | `validated_shadow_not_live` |
| Weight policy | `equal_window_v1` (\(p_k=1/K\), \(K\ge 2\)) |
| Stress evidence | [`reports/quantum_mixed_state_shadow_stress_v1.json`](./reports/quantum_mixed_state_shadow_stress_v1.json) |
| Explicitly out of scope | Discover ranking/UI, Persona, RVI, fusion weights, free \(\lambda\), questionnaire states, multi-mode Wave-State, fused \(r_{\mathrm{wave}}\) as L5 |

---

## 0. Freeze decision

This scoring freeze is the **L5 v1 retained candidate**. Mixed-state QI is a **validated research shadow**, non-ranking.

Synthetic stress showed that **mixed-state** QI fidelity varies materially at fixed mean-phase alignment when purity/spread differ (residual vs \(\cos\Delta\bar\phi\) ~63% on the stress draw). The mixed-state layer is therefore retained as a **validated shadow research signal**.

It is **not** live Matching, not Discover-ranked, and not fused with \(D_{\mathrm{structural}}\), L3, L4, `phase_alignment`, or `activity_level_gap`.

**Real-data validation is still pending.** Promotion requires calibrated L4 Class-B gates, a real multi-window cohort, replication on real data, and a separate ranking RFC.

---

## 1. Frozen outputs

| Field | Role |
| --- | --- |
| `purity_A` / `purity_B` | Ensemble concentration diagnostics; **must remain visible separately** |
| `qi_mixed_fidelity` | State-distribution similarity \(F(\rho_A,\rho_B)\) |
| `qi_trace_distance` | Dissimilarity \(\tfrac12\|\mathbf{r}_A-\mathbf{r}_B\|\) |
| `weight_policy_id` | Always `equal_window_v1` in this freeze |
| Bloch / ensemble counts | Provenance and geometry diagnostics |

Same-oscillator provenance gates remain mandatory (`oscillator_id`, \(\omega\), period, reference epoch).

---

## 2. Semantics (hard rules)

1. **Mixed-state QI adds information beyond mean phase alignment** when at least one ensemble is non-degenerate (\(\|\mathbf{r}\|<1\)).
2. **Pure-state QI is redundant** with `phase_alignment`: \(F=\frac{1+\cos\Delta\phi}{2}\) for equatorial pure states. It **must not** be a separate Matching signal.
3. **`qi_mixed_fidelity` measures state-distribution similarity, not compatibility by itself.** Do not treat high \(F\) as a match score or “compatibility %”.
4. **Low purity must remain visible** as its own diagnostic (do not hide it inside a fused score).
5. **No fusion or ranking weights yet** across structural / wave / QI families.
6. **Real-data validation still pending** before any live calibration claim (`gates_calibrated = false`).

---

## 3. Status flags

| Flag | Value |
| --- | --- |
| `policy_status` | `validated_shadow_not_live` |
| `shadow_only` | `true` |
| `validated_shadow_research_signal` | `true` |
| `specification_only_not_live` | `false` (implemented + stress-validated) |
| `real_data_validation_pending` | `true` |
| `live_discover_ranking` | `false` |
| `persona_enabled` / `rvi_enabled` | `false` |
| `ranking_weights_allowed` | `false` |
| `pure_state_qi_as_separate_signal` | `false` |
| `fidelity_is_compatibility_percentage` | `false` |
| `fused_r_wave_is_l5_score` | `false` |
| `multimode_wave_state_in_production` | `false` |
| `fuses_with_*` | all `false` (L2 / L3 / L4 included) |

---

## 4. Implementation pointer

- Layer freeze: [`qmatch_l5_mixed_state_qi_contract_v1.md`](./qmatch_l5_mixed_state_qi_contract_v1.md)
- Dart: `L5MixedStateQiContract` / `QuantumMixedStateShadowMatcher` / `QuantumMixedStateShadowContract`
- Unit tests: `test/l5_mixed_state_qi_contract_v1_test.dart`, `test/quantum_mixed_state_shadow_v1_test.dart`
- Stress harness (kept): `test/quantum_mixed_state_shadow_stress_v1_test.dart`
- Prior contract math: [`qmatch_quantum_mixed_state_shadow_contract_v1.md`](./qmatch_quantum_mixed_state_shadow_contract_v1.md)

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Freeze after synthetic stress; status → `validated_shadow_not_live` |
| v1 L5 | 2026-08-16 | Adopted as L5 v1 retained candidate; Wave-State / fused \(r_{\mathrm{wave}}\) / pure-state QI remain out of L5 |
