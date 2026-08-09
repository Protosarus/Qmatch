# QMatch Frequency Canonical Runtime Contract v1

**Phase:** P2C-2A-8R2  
**Session policy:** `frequency_50_full_bank_deterministic_v1`  
**Scoring policy:** `frequency_6d_uncalibrated_signed_evidence_v1`  
**Persisted session schema:** `qmatch_frequency_persisted_session_v1`

## Live path

```
FrequencyIntroScreen → FrequencyTestScreen
  → FrequencyCanonicalRuntimeService
  → TR/EN frequency_bank_*_v1 (50 items)
  → FrequencySessionManager (deterministic seed, shuffled option order, resume)
  → CanonicalFrequencyScorer
  → assessments/frequency (qmatch_frequency_6d_live_result_v1)
  → FrequencyTo20dRuntimeAdapter
  → profiles/canonical_v1 (20/20, canonical_profile_ready=true)
  → AssessmentFlowCompleteScreen (no Persona)
```

## Non-goals

* Persona computation / reveal
* Matching / QRCF / Discover ranking
* Quantum-inspired runtime
* RVI gating from quality checks
* Psychometric calibration claims
