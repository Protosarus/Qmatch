# QMatch EQ → 20D Runtime Adapter v1

**Adapter:** `eq_to_20d_runtime_adapter_v1`  
**Source:** `canonical_eq`  
**Policy:** `eq_10d_uncalibrated_signed_evidence_v1`

## Behavior

* Maps all 10 EQ normalized scores into measured dimensions
* Requires existing 4 IQ measured dimensions and preserves them exactly
* Leaves 6 Frequency IDs in `missing_dimension_ids` (never 0 / 0.5 / 50)
* `measured_dimension_count = 14`, `required = 20`
* `canonical_profile_ready = false`, `profile_status = partial`
* IQ/EQ groups complete; Frequency incomplete

No Persona / matching / quantum.
