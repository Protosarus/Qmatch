# Frequency behavioral V2 draft tooling

Offline normalizer for `docs/qmatch_frequency_v2_426_unique_source_pool_tr.txt`.

```bash
python3 tool/frequency_behavior_v2/normalize_frequency_behavior_pool_v2.py
python3 tool/frequency_behavior_v2/apply_phase1c_human_decisions.py
python3 tool/frequency_behavior_v2/apply_phase1f_human_primaries.py
python3 tool/frequency_behavior_v2/generate_phase1f_rewrite_packet.py
python3 tool/frequency_behavior_v2/apply_phase1g_human_rewrites.py
python3 tool/frequency_behavior_v2/apply_phase2a_evidence_schema.py
python3 tool/frequency_behavior_v2/generate_phase2b_evidence_prior_proposal.py
python3 tool/frequency_behavior_v2/generate_phase2c_evidence_triage.py
python3 tool/frequency_behavior_v2/generate_phase2d_human_evidence_decision_packet.py
python3 tool/frequency_behavior_v2/apply_phase2e_human_evidence_decisions.py
python3 tool/frequency_behavior_v2/apply_phase2f_finalize_evidence.py
dart run tool/frequency_behavior_v2/simulate_phase3a_selector.dart
dart run tool/frequency_behavior_v2/simulate_phase3b_selector.dart
dart run tool/frequency_behavior_v2/simulate_phase3c_selector.dart
dart run tool/frequency_behavior_v2/simulate_phase4a_scorer.dart
dart run tool/frequency_behavior_v2/simulate_phase4b_confidence.dart
dart run tool/frequency_behavior_v2/simulate_phase4c_telemetry.dart
dart run tool/frequency_behavior_v2/simulate_phase5a_quantum_state.dart
dart run tool/frequency_behavior_v2/simulate_phase5b_mixed_density.dart
dart run tool/frequency_behavior_v2/simulate_phase5c_pair_relation.dart
dart run tool/frequency_behavior_v2/simulate_phase5d_pair_fit.dart
python3 tool/frequency_behavior_v2/build_phase6a_en_semantic_parity_pool.py
```

Writes only under `tool/frequency_behavior_v2/out/`. Does not modify live V1 banks, pubspec, or Frequency locale routing.

Do not re-run the source normalizer after Phase 1C/1F/1G.

Phase 1C apply uses `docs/qmatch_frequency_v2_phase1b_human_decisions.txt` as human authority for option weights/rewrites. It does not assign evidence-layer values.

Phase 1F apply uses `docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt` as human authority for single-primary assignment and selector exclusion. The rewrite packet is historical/proposal-only.

Phase 1G apply uses `docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt` as human authority for the 26 rewrite stems, options, primaries, and weights. It does not assign evidence-layer values.

Phase 2A migrates the dormant `evidence_meta` schema to `frequency_evidence_prior_v1` (six fields, allowed grid, uncalibrated). It does **not** assign numeric evidence values.

Phase 2B writes a proposal-only evidence-prior JSON for the 1632 selectable options. It does **not** apply those values to the dormant pool and does not score DROP options.

Phase 2C triages the Phase 2B proposal (KEEP vs CLEAR human-review flags). It does **not** modify proposal scores or the dormant pool.

Phase 2D writes a human evidence decision packet for the 29 REAL_REVIEW_REQUIRED questions and 10 leakage-suspect ±1 options. It does **not** apply scores or rewrite items.

Phase 2E applies `docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt` as human authority: proposal-only evidence corrections, 10 rewrites, 2 additional archived DROPs, and a fresh proposal-only rescore of the 10 rewritten questions. It does **not** write numeric `evidence_meta` into the dormant pool.

Phase 2F applies `docs/qmatch_frequency_v2_phase2e_final_human_evidence_review.txt` as human authority: combines 396 + 9 evidence scores, archives `q0409` as DROP, and writes reviewed uncalibrated priors onto 405 dormant selectable questions / 1620 options. DROP options stay pending/null. V2 remains dormant.

Phase 3A implements `frequency_behavior_v2_selector_v1`: a dormant seeded 50-question session composer (4 per 12D plus two rotating extra slots). Phase 3B patches candidate ordering so singleton-cluster items are not mandatory. Phase 3C replaces the hard max-two-per-semantic-cluster cap with a bounded soft cluster preference. Phase 4A adds a dormant 12D opportunity-aware scorer and separate confidence primitives. Phase 4B adds a provisional per-dimension confidence heuristic (`frequency_behavior_v2_confidence_v1`) that does not move behavioral direction. Phase 4C adds a dormant calibration telemetry contract and offline aggregator (`frequency_v2_calibration_telemetry_v1`); live collection stays off and telemetry never feeds scoring, confidence, selector, or evidence priors. Phase 5A adds a dormant 24-amplitude signed-pole quantum-inspired behavioral state (`frequency_v2_quantum_state_encoding_v1`) so opposite 12D profiles stay distinguishable; it does not define mixedness or pair compatibility. Phase 5B adds a dormant confidence-aware mixed density (`frequency_v2_mixed_density_v1`): `rho_user = (1-λ) rho_behavior + λ I/24`, with λ from equal-mean Phase 4B support. Phase 5C adds dormant quantum-inspired pair-relation primitives (`frequency_v2_pair_relation_v1`) — same-pole, axis fidelity, pair support — without a compatibility score. Phase 5D adds a provisional uncalibrated relationship-fit model (`frequency_pair_fit_policy_v1`) that produces a dormant Frequency Fit index from signed distance and support-aware fit. It does **not** activate V2 or change pool text, weights, evidence values, or selector behavior.

Phase 6A builds an English semantic parity bank (`frequency_behavior_pool_en_v2_draft1`) from the TR master via `build_phase6a_en_semantic_parity_pool.py`. Translation batches live under `out/en_translation_batches/`. Human review packets under `out/en_human_review/`. All items start `PENDING_HUMAN_REVIEW`. V2 and EN routing remain dormant (`runtime_selectable=false`).
