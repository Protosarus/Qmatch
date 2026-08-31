# Frequency behavioral V2 pool contract (draft)

**Status:** dormant draft — not live-selectable  
**schema_version:** `qmatch_frequency_behavior_pool_v2`  
**pool_version:** `frequency_behavior_pool_tr_v2_draft1`  
**scoring_policy_version:** `frequency_behavior_12d_signed_evidence_v2`

This contract coexists with live Frequency V1 (`qmatch_frequency_bank_v1`, 6D). It does **not** replace V1 banks, does **not** write `canonical_v1` Frequency 6D slots, and does **not** define a 12D→6D map.

Live routing remains:

```
FrequencyCanonicalRuntimeService.assetPathForLocale
  tr-TR → frequency_bank_tr_v1.json
  en-US → frequency_bank_en_v1.json
```

---

## 1. Taxonomy (exactly 12)

`contact_need`, `closeness_pace`, `initiative`, `autonomy`, `reassurance_need`, `uncertainty_tolerance`, `disclosure_pace`, `boundary_firmness`, `repair_style`, `social_energy`, `structure_preference`, `adaptability`

Safe alias normalization only:

| Source label | Canonical |
|---|---|
| `initiative_tendency` | `initiative` |
| `autonomy_need` | `autonomy` |
| `boundary_style` | `boundary_firmness` |
| `rhythm_adaptation` | `adaptability` |

**Never auto-map:** `processing_style` → `repair_style`. Phase 1C human decisions rescore or drop leftovers; they do not create an alias.

Unknown labels (`reciprocity`, `conflict_approach`, `baseline`, `trust` as a dimension id) are **dropped** in Phase 1C. They are not 12D IDs and must not leak into `behavioral_weights`.

`conflict_approach` is an EQ 20D id. It must not leak into Frequency 12D.

### repair_style orientation (behavioral direction, not a moral score)

| Weight | Meaning |
|---|---|
| `+2` | immediate / active repair engagement |
| `+1` | mildly active repair / constructive revisit |
| `-1` | delayed / partial / mixed repair, often pause-then-return |
| `-2` | blocked / withdrawn / shut-down repair with no explicit return in the option |

Do not label negative values as unhealthy, toxic, or bad. This is pacing/engagement, not health.

Selectable questions have **exactly one** `primary_dimensions` entry and zero or more `secondary_dimensions`. Do **not** infer `primary_dimensions` from absolute-weight mass, from how many options carry a weight, or from an old dual `primary_dimensions` list. Dual IDs are not a workaround.

Phase 1F:

- 54 items received a human-approved single primary (and optional secondary).
- 26 items were rewrite-pending until Phase 1G.
- 18 DROP items stay in the archive (IDs, text, options, weights, provenance preserved) but `selector_eligible=false`. Archive count is not reduced.

Phase 1G:

- The 26 rewrite-pending items received human-approved stems, four option texts, a single primary, empty secondaries, and ±1/±2 primary-only weights.
- Signs are behavioral-axis directions, not good/bad scores. Stems do not name the latent construct. Wording is situational and respondent-behavior based.
- Evidence-layer fields stay null/`pending`. No `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, or `ambiguity` numbers in this phase.

---

## 2. Bank JSON vs developer metadata

User-facing draft pool (`tool/frequency_behavior_v2/out/frequency_behavior_pool_tr_v2_draft1.json`):

- `item_id`, `prompt`, `context`, `primary_dimensions`, `secondary_dimensions`, `semantic_cluster`, `crosscheck_group_ids`
- `options[].option_id`, `text`, `behavioral_weights` (explicit keys only)
- `options[].evidence_meta`: selectable options store **reviewed uncalibrated priors** (`frequency_evidence_prior_v1`, all six grid fields). Archived DROP options stay **null scores + `review_status=pending`**.

Developer-only review file:

- source provenance (`source_fq`, `source_set`, `source_item_id`)
- alias applications
- `processing_style_present` (current leftover; false after Phase 1C rescore/drop)
- `processing_style_source_present` (historical source tag)
- `primary_review_pending`
- `selector_eligible` / `selector_exclusion_reason` (`drop_from_selectable_pool` | `rewrite_pending` | null)
- `rewrite_pending` / `drop_from_selectable`
- unresolved labels
- heuristic review flags
- exact/near duplicate reports

Scoring uses `option_id` only. Display order may be shuffled. Missing weight key ≠ explicit `0`.

Signed weight range: **[-2, +2]**.

---

## 3. Second evidence layer (Phase 2A schema; Phase 2F authored priors)

Canonical contract: [`frequency_evidence_metadata_v1_contract.md`](frequency_evidence_metadata_v1_contract.md)

Six relative-to-siblings fields: `social_desirability`, `obviousness`, `behavioral_plausibility`, `self_presentation_risk`, `diagnostic_value`, `ambiguity`.

Allowed numeric grid: **0.00, 0.25, 0.50, 0.75, 1.00**.

Phase 2F writes authored priors onto the dormant selectable pool:

- `version`: `frequency_evidence_prior_v1`
- `calibration_status`: `uncalibrated`
- selectable (405 questions / 1620 options): `review_status=reviewed` and all six scores on-grid
- archived DROP (21 questions / 84 options): `review_status=pending` and all six scores **null**

Evidence metadata is structurally independent of `behavioral_weights`. High social desirability ≠ false. `discrimination_power` and response time are not authored here. Forbidden names: `truth_score`, `lie_score`, `deception_score`, `honesty_score`.

Draft validator accepts mixed pending DROP metadata and complete reviewed selectable metadata. Production-ready validator **rejects** unresolved evidence (DROP items remain unresolved). Reviewed status requires all six fields together on the allowed grid.

Legacy placeholder `directness` is not part of the v1 contract. V2 remains `runtime_selectable=false`.

---

## 4. Cross-check / confidence (design)

Metadata fields:

- `semantic_cluster` — construct + coarse context; selector avoids adjacent repeats
- `construct_probe` — primary dimension after alias normalization
- `crosscheck_group_ids` — `cc_{dimension}_v2` for items sharing a primary
- `perspective_direction` — `self_initiated` / `partner_initiated` / `both` / null

Asymmetry themes to encode in later human review (not auto-scored as lies):

- user’s need vs partner’s need
- giving space vs receiving space
- disclosing vs receiving disclosure
- one-off disruption vs repeated disruption

Inconsistency may later affect `cross_context_stability`, `behavioral_uncertainty`, `response_confidence`.

It must **not** affect eligibility, Discover access, punishment, or moral labels.

---

## 5. 50-of-405 selection (Phase 3A)

Canonical selector: [`frequency_v2_selector_v1_contract.md`](frequency_v2_selector_v1_contract.md)

Policy: `frequency_behavior_v2_selector_v1` (RNG `xorshift32_fnv1a32_v1`)

Historical draft note: `frequency_behavior_50_of_426_seeded_quota_v2_draft1` described an earlier composer sketch and remains on the generated selector-plan file as a lineage label.

Not pure random. Seeded quota:

- 4 items per 12 dimensions (48) + 2 extra slots on two **seed-chosen distinct** dimensions
- exclude unresolved leftover labels, `processing_style_present`, empty primary, dual primary, `primary_review_pending`, `rewrite_pending`, and `drop_from_selectable`
- selectable items must have exactly one canonical primary
- do not invent a primary from score mass
- Phase 3B: per-question seeded candidate rank **before** diversity; at most 2 items per `semantic_cluster` in a dimension (does not hunt singleton clusters first)
- Phase 3C: hard per-cluster cap removed; bounded lookahead (`softClusterLookahead=2`) may prefer a nearby different cluster when the next ranked item would repeat one, without scanning the bank for rare clusters
- cap consecutive same primary at 2
- persist `question_id` + shuffled `presented_option_order`; score by `option_id`
- resume must reload the **same pool_version** / `bank_version`

Evidence metadata is **not** a Phase 3C pick key. `diagnostic_value` is not a pick key. Social desirability does not exclude items.

See generated `frequency_behavior_pool_tr_v2_draft1_selector_plan.json` for actual pool distributions.

V1 sessions remain bound to `frequency_bank_*_v1`.

---

## 6. Version / locale

- TR draft may exist dormant.
- Do not switch users to V2.
- Do not runtime-AI-translate.
- Future EN V2 must keep the same `item_id`, `option_id`, dimensions, weights, and metadata keys. Text may be naturalized; intent must match.
- Future live loader **must** key by `bank_version`/`pool_version` + locale. Locale-only load is unsafe for in-progress V1 sessions.

Registry: `FrequencyBehaviorV2BankRegistry` (always `runtime_selectable=false` for draft versions).

---

## 7. Quantum-inspired boundary

Object: `FrequencyBehaviorV2LatentHandoff`

Fields only: `behavioral_mean_12d`, `behavioral_uncertainty_12d`, `cross_context_stability`, `social_desirability_pressure`, `response_quality`, `response_confidence`, `model_version`.

Not implemented: density matrices, amplitudes, entanglement, “true personality,” or claims that a person is a quantum system. A later compatibility layer may consume these numbers as a mathematical representation only.

---

## 8. C2 finalize versioning (documentation only)

`finalizeFrequency` is not part of this phase.

When V2 is later cataloged:

- add new `SOURCES` entries; **keep** `frequency_bank_tr_v1` / `frequency_bank_en_v1`
- do not run V2 assets through the V1 30/12/6/2 blueprint extractor
- lookup already keys `assessment_type + bank_version + bank_locale`
- `catalog:check` must still pass for V1

No Functions catalog generator or validator files were changed in this phase.

---

## 9. Regeneration

```text
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

Do **not** re-run the source normalizer after Phase 1C/1F/1G; it would wipe applied human decisions. Phase 1G apply reads `docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt` and patches only those 26 dormant items. Phase 2A only reshapes null `evidence_meta` placeholders. Phase 2B writes a proposal-only prior file and does not apply scores to the pool. Phase 2C triages that proposal and does not apply scores. Phase 2D writes a human decision packet and does not apply scores or rewrites. Phase 2E applies the human 2D authority file: proposal-only evidence corrections, 10 rewrites, two additional archived DROPs, and a fresh proposal-only rescore of those 10 items. It does not write numeric evidence into the dormant pool. Phase 2F applies the human 2E final evidence review: 405 selectable reviewed priors, `q0409` archived DROP, 21 DROP options left pending/null. Phase 3A adds a dormant 50-question selector (`frequency_behavior_v2_selector_v1`) and does not activate V2. Phase 3B patches per-question seeded candidate rank so singleton-cluster items are not structural always-winners; it does not activate V2. Phase 3C replaces the hard max-two-per-cluster cap with a bounded soft cluster preference; it does not activate V2. Phase 4A adds `frequency_behavior_v2_scorer_v1` (opportunity-aware 12D direction + separate evidence/consistency primitives) and does not activate V2. Phase 4B adds `frequency_behavior_v2_confidence_v1`, a provisional per-dimension confidence heuristic that does not change `normalized_behavior`. Phase 4C adds dormant calibration telemetry (`frequency_v2_calibration_telemetry_v1_contract.md`) with offline aggregates only; live collection is off and telemetry does not change scoring, confidence, selector, or evidence priors. Phase 5A adds a dormant 24-amplitude signed-pole quantum-inspired behavioral state (`frequency_v2_quantum_state_encoding_v1_contract.md`) that preserves polarity of the 12D vector; it does not define mixedness or pair compatibility. Phase 5B adds a dormant confidence-aware mixed density (`frequency_v2_mixed_density_v1_contract.md`) that depolarizes `rho_behavior` using support-derived λ and does not change `psi`. Phase 5C adds dormant pair-relation primitives (`frequency_v2_pair_relation_v1_contract.md`) that measure same-pole orientation and axis fidelity without emitting a compatibility score. Phase 5D adds a provisional relationship-fit model (`frequency_v2_pair_fit_v1_contract.md`) with equal-weight `frequency_pair_fit_policy_v1`; it is not live matching. Phase 6A builds an EN semantic parity bank from the TR master (`frequency_v2_en_semantic_parity_v1_contract.md`); human review is required before activation and V2/EN routing stay dormant.
