# Frequency V2 Phase 2A — Evidence metadata contract

Status: **schema only**. No evidence numeric values were assigned.
V2 remains `runtime_selectable=false`.

Contract: `docs/assessment/frequency_v2/frequency_evidence_metadata_v1_contract.md`

## Current pool

- Archive questions: 426
- Archive options: 1704
- Dormant selectable questions: 408
- DROP archived/non-selectable: 18
- Rewrite pending: 0
- Selectable dual-primary: 0
- `runtime_selectable`: false
- `evidence_meta`: all six fields null, `review_status=pending`, `calibration_status=uncalibrated`
- Prompt / option-text / behavioral-weight fingerprint SHA-256: `d03b2d8c77843d72baf072219c2c0dcae07a0d093dd1bf8c5268f0ef4ca6d56d`
- Fingerprint unchanged by schema migration: true
- Options whose `evidence_meta` object was reshaped (null placeholders only): 1704

## Allowed values (not yet assigned)

`0.00` · `0.25` · `0.50` · `0.75` · `1.00`

## Data shape (every option)

```text
evidence_meta:
  version: frequency_evidence_prior_v1
  calibration_status: uncalibrated
  review_status: pending
  social_desirability: null
  obviousness: null
  behavioral_plausibility: null
  self_presentation_risk: null
  diagnostic_value: null
  ambiguity: null
```

Legacy `directness` was removed from the placeholder. It was never scored.

## Relative scoring rule (for a later assign phase)

Scores are relative to the other three options in the same question.
They are not personality, moral, truth/lie, or clinical values.
`behavioral_weights` stay the behavioral meaning; evidence describes interpretation confidence.

## Safety

- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push
- `discrimination_power` and response time are not authored

FREQUENCY V2 PHASE 2A EVIDENCE METADATA CONTRACT READY — NO EVIDENCE VALUES ASSIGNED — V2 STILL DORMANT
