# QMatch Frequency→20D Runtime Adapter v1

**Adapter:** `frequency_to_20d_runtime_adapter_v1`  
**Policy:** `frequency_6d_uncalibrated_signed_evidence_v1`

Maps exactly:

```text
depth_preference, social_energy, spontaneity,
stability, disclosure_pace, communication_pace
```

Preserves existing IQ (4) and EQ (10) measurements exactly.

On success:

```text
measured_dimension_count = 20
missing_dimension_ids = []
profile_status = complete
canonical_profile_ready = true
```

Readiness uses registry ID verification (`FrequencyTo20dRuntimeAdapter.registryComplete`), not mere count==20.

Does not invoke Persona, Matching, QRCF, or quantum.
