# QMatch Frequency Live Result Persistence v1

**Schema:** `qmatch_frequency_6d_live_result_v1`  
**Path:** `users/{uid}/assessments/frequency`

Key fields: scoring/session/bank versions, six dimension scores + evidence counts + raw signed evidence, quality_signals (protocol-only), calibration/reliability = uncalibrated/not_calibrated.

Explicit absences: overall Frequency score, percentile, persona, matching, quantum, correctness.

Quality signals do not gate completion or alter trait scores.
