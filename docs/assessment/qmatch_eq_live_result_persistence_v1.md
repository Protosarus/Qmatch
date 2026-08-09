# QMatch EQ Live Result Persistence v1

**Schema:** `qmatch_eq_10d_live_result_v1`  
**Path:** `users/{uid}/assessments/eq`

## Allowed fields (conceptual)

* schema / scoring / bank / locale / session metadata
* dimension normalized scores + signed evidence + evidence counts
* calibration_status = uncalibrated
* reliability_status = not_calibrated
* rvi_runtime_gate = NOT_CALIBRATED / NOT_ACTIVE
* canonical_profile_ready = false

## Forbidden

* overall EQ scalar / percentile
* correct_count / answer keys
* fabricated reliability / clinical labels
* PII

Builder: `CanonicalAssessmentPersistence.buildCanonicalEq10dPayload`
