# P2A Assessment Engineering Freeze Manifest v1

Phase: **P2B-0**  
Machine-readable twin: `assets/data/core_method_v2/p2a_assessment_engineering_freeze_manifest_v1.json`

## Engineering frozen — definition

**Engineering frozen** means no unreviewed structural/content changes may be introduced while Core Method v2 is being implemented.

It does **not** mean:

- scientifically validated
- psychometrically calibrated
- expert approved
- production ready

## Metadata honesty note

EQ and Frequency pair registries received explicit reverse-pair `consistency_mode` metadata in a prior phase. Therefore:

- question wording was not changed by the reverse-RVI phase
- option wording was not changed by the reverse-RVI phase
- trait deltas were not changed by the reverse-RVI phase
- parent/candidate file SHA values may have changed because metadata changed

This manifest records current hashes honestly. It does not claim byte preservation where metadata was intentionally updated.

## Reference artifacts

| Role | Path | Module | Runtime-loaded | Production-wired |
|------|------|--------|----------------|------------------|
| IQ pilot parent | `assets/data/assessment_v3/iq/iq_pilot_tr_v1.json` | iq | no | no |
| IQ review candidate | `assets/data/assessment_v3/iq/iq_pilot_tr_v1_review_candidate_1.json` | iq | no | no |
| EQ pilot parent | `assets/data/assessment_v3/eq/eq_pilot_tr_v1.json` | eq | no | no |
| EQ review candidate | `assets/data/assessment_v3/eq/eq_pilot_tr_v1_review_candidate_1.json` | eq | no | no |
| Frequency pilot parent | `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json` | frequency | no | no |
| Frequency review candidate | `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json` | frequency | no | no |
| Trait scoring config | `assets/data/trait_scoring_config_v1.json` | — | no | no |
| Canonical registry doc | `docs/core_engine/canonical_dimension_registry_v1.md` | — | no | no |
| Canonical registry JSON | `assets/data/core_method_v2/canonical_dimension_registry_v1.json` | — | no | no |
| Reverse-pair contract | `docs/core_engine/reverse_pair_consistency_contract_v1.md` | — | no | no |

Exact SHA256 digests, freeze fields, pending reviews, and form/content versions are authoritative in the JSON manifest.

## Freeze field meanings

- **question_text_freeze_status / option_text_freeze_status / evidence_delta_freeze_status**: content must not change without reviewed content phase
- **metadata_freeze_status**: structural metadata freeze; EQ/Frequency note acknowledged pair-registry `consistency_mode` updates already applied
- **known_pending_reviews**: expert, language, cognitive interview, and psychometric work remain open
