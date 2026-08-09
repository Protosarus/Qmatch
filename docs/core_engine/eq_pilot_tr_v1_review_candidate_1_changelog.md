# EQ Pilot TR v1 — Review Candidate 1 Changelog

**Parent:** `eq-tr-pilot-v1`  
**Candidate:** `eq-tr-pilot-v1-review-candidate-1`  
**ID policy:** retain IDs when primary dimension and material trade-off unchanged.

## `eq_tr_v1_assertiveness_001` → `eq_tr_v1_assertiveness_001`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `assertiveness` → `assertiveness`
- **Secondary:** ['emotion_regulation', 'repair_orientation'] → ['boundary_setting', 'repair_orientation']
- **Prompt changes:** none
- **Option text changes:** ['B', 'D']
- **Delta-direction changes:** ['A:boundary_setting', 'A:emotion_regulation', 'B:repair_orientation', 'C:conflict_approach', 'C:repair_orientation']
- **Delta-magnitude changes:** ['A:boundary_setting:None->0.2', 'A:emotion_regulation:-0.2->None', 'A:assertiveness:0.72->0.75', 'B:repair_orientation:-0.18->None', 'C:conflict_approach:-0.15->None', 'C:repair_orientation:None->0.2', 'C:assertiveness:0.08->0.2', 'D:boundary_setting:-0.22->-0.2', 'D:assertiveness:-0.52->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_assertiveness_002` → `eq_tr_v1_assertiveness_002`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `assertiveness` → `assertiveness`
- **Secondary:** ['boundary_setting', 'social_awareness'] → ['boundary_setting', 'social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:boundary_setting', 'B:social_awareness']
- **Delta-magnitude changes:** ['A:boundary_setting:-0.22->0.2', 'A:assertiveness:0.72->0.75', 'B:social_awareness:-0.15->0.2', 'C:assertiveness:0.08->0.15', 'D:assertiveness:-0.52->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_assertiveness_003` → `eq_tr_v1_assertiveness_003`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `assertiveness` → `assertiveness`
- **Secondary:** [] → ['boundary_setting', 'repair_orientation']
- **Prompt changes:** none
- **Option text changes:** ['A', 'B', 'C', 'D']
- **Delta-direction changes:** ['A:assertiveness', 'B:assertiveness', 'C:assertiveness', 'D:emotion_regulation', 'D:assertiveness']
- **Delta-magnitude changes:** ['A:boundary_setting:0.22->0.2', 'A:assertiveness:-0.72->0.75', 'B:assertiveness:-0.45->0.45', 'C:repair_orientation:0.15->0.2', 'C:assertiveness:-0.08->0.15', 'D:emotion_regulation:-0.15->None', 'D:assertiveness:0.52->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_boundary_setting_001` → `eq_tr_v1_boundary_setting_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `boundary_setting` → `boundary_setting`
- **Secondary:** ['assertiveness'] → ['assertiveness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:assertiveness', 'B:assertiveness', 'C:conflict_approach']
- **Delta-magnitude changes:** ['A:assertiveness:-0.22->0.2', 'B:boundary_setting:0.48->0.45', 'B:assertiveness:-0.18->0.2', 'C:boundary_setting:0.12->0.15', 'C:conflict_approach:-0.15->None']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_boundary_setting_002` → `eq_tr_v1_boundary_setting_002`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `boundary_setting` → `boundary_setting`
- **Secondary:** ['assertiveness', 'repair_orientation'] → ['assertiveness', 'repair_orientation']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:assertiveness', 'C:repair_orientation']
- **Delta-magnitude changes:** ['A:assertiveness:-0.25->0.3', 'B:boundary_setting:0.48->0.45', 'C:boundary_setting:0.12->0.15', 'C:repair_orientation:-0.15->0.2', 'D:assertiveness:-0.22->-0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_boundary_setting_003` → `eq_tr_v1_boundary_setting_003`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `boundary_setting` → `boundary_setting`
- **Secondary:** [] → ['assertiveness', 'conflict_approach', 'repair_orientation']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:boundary_setting', 'B:boundary_setting', 'D:boundary_setting']
- **Delta-magnitude changes:** ['A:boundary_setting:-0.75->0.75', 'B:boundary_setting:-0.48->0.45', 'C:boundary_setting:-0.12->-0.2', 'C:repair_orientation:0.18->0.2', 'D:boundary_setting:0.55->-0.55', 'D:conflict_approach:-0.18->-0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_conflict_approach_001` → `eq_tr_v1_conflict_approach_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `conflict_approach` → `conflict_approach`
- **Secondary:** ['perspective_taking', 'assertiveness'] → ['assertiveness', 'emotion_regulation']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:assertiveness', 'A:perspective_taking', 'B:assertiveness', 'C:boundary_setting', 'C:conflict_approach', 'C:emotion_regulation', 'D:emotion_regulation']
- **Delta-magnitude changes:** ['A:conflict_approach:0.72->0.75', 'A:assertiveness:None->0.2', 'A:perspective_taking:-0.22->None', 'B:conflict_approach:0.46->0.45', 'B:assertiveness:-0.18->0.2', 'C:boundary_setting:-0.12->None', 'C:conflict_approach:0.1->-0.2', 'C:emotion_regulation:None->0.2', 'D:conflict_approach:-0.55->-0.3', 'D:emotion_regulation:-0.2->0.3']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.5', 'D:0.72->0.55']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_conflict_approach_002` → `eq_tr_v1_conflict_approach_002`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `conflict_approach` → `conflict_approach`
- **Secondary:** ['emotion_regulation', 'repair_orientation'] → ['emotion_regulation', 'repair_orientation', 'social_awareness']
- **Prompt changes:** none
- **Option text changes:** ['A', 'B', 'C', 'D']
- **Delta-direction changes:** ['A:repair_orientation', 'A:emotion_regulation', 'B:repair_orientation', 'B:emotion_regulation', 'C:conflict_approach', 'C:social_awareness', 'C:perspective_taking', 'D:empathy']
- **Delta-magnitude changes:** ['A:conflict_approach:0.68->0.6', 'A:repair_orientation:None->0.3', 'A:emotion_regulation:-0.25->None', 'B:conflict_approach:0.42->0.2', 'B:repair_orientation:-0.18->None', 'B:emotion_regulation:None->0.3', 'C:conflict_approach:0.12->-0.15', 'C:social_awareness:None->0.2', 'C:perspective_taking:-0.15->None', 'D:conflict_approach:-0.45->-0.55', 'D:empathy:-0.15->None']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_conflict_approach_003` → `eq_tr_v1_conflict_approach_003`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `conflict_approach` → `conflict_approach`
- **Secondary:** ['boundary_setting'] → ['assertiveness', 'emotion_regulation', 'perspective_taking']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:boundary_setting', 'A:conflict_approach', 'A:assertiveness', 'B:conflict_approach', 'C:conflict_approach', 'D:conflict_approach']
- **Delta-magnitude changes:** ['A:boundary_setting:0.2->None', 'A:conflict_approach:-0.72->0.75', 'A:assertiveness:None->0.2', 'B:conflict_approach:-0.46->0.45', 'B:perspective_taking:0.18->0.2', 'C:conflict_approach:-0.1->0.15', 'D:conflict_approach:0.55->-0.55', 'D:emotion_regulation:-0.22->-0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_emotion_regulation_001` → `eq_tr_v1_emotion_regulation_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `emotion_regulation` → `emotion_regulation`
- **Secondary:** ['self_awareness', 'social_awareness'] → ['empathy', 'social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:social_awareness', 'A:self_awareness', 'B:social_awareness', 'C:conflict_approach', 'C:emotion_regulation']
- **Delta-magnitude changes:** ['A:social_awareness:None->0.2', 'A:self_awareness:-0.22->None', 'A:emotion_regulation:0.7->0.75', 'B:social_awareness:-0.18->0.2', 'C:conflict_approach:-0.15->None', 'C:emotion_regulation:0.08->-0.2', 'D:emotion_regulation:-0.48->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_emotion_regulation_002` → `eq_tr_v1_emotion_regulation_002`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `emotion_regulation` → `emotion_regulation`
- **Secondary:** ['self_awareness'] → ['emotional_openness', 'self_awareness']
- **Prompt changes:** none
- **Option text changes:** ['A', 'B', 'C', 'D']
- **Delta-direction changes:** ['A:self_awareness', 'C:emotion_regulation']
- **Delta-magnitude changes:** ['A:self_awareness:-0.2->0.2', 'A:emotion_regulation:0.7->0.75', 'C:emotion_regulation:0.08->-0.2', 'D:emotional_openness:0.22->0.2', 'D:emotion_regulation:-0.48->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_emotion_regulation_003` → `eq_tr_v1_emotion_regulation_003`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `emotion_regulation` → `emotion_regulation`
- **Secondary:** ['self_awareness', 'perspective_taking'] → ['perspective_taking', 'self_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:self_awareness', 'B:perspective_taking', 'C:emotional_openness']
- **Delta-magnitude changes:** ['A:self_awareness:-0.18->0.2', 'A:emotion_regulation:0.68->0.75', 'B:emotion_regulation:0.42->0.45', 'B:perspective_taking:-0.15->0.2', 'C:emotional_openness:-0.2->None', 'D:emotion_regulation:-0.5->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_emotional_openness_001` → `eq_tr_v1_emotional_openness_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `emotional_openness` → `emotional_openness`
- **Secondary:** ['self_awareness', 'boundary_setting'] → ['boundary_setting', 'empathy', 'self_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:self_awareness', 'B:boundary_setting', 'C:emotional_openness', 'C:empathy']
- **Delta-magnitude changes:** ['A:emotional_openness:0.78->0.75', 'A:self_awareness:-0.18->0.2', 'B:emotional_openness:0.42->0.45', 'B:boundary_setting:-0.15->0.2', 'C:emotional_openness:0.08->-0.15', 'C:empathy:-0.22->0.2', 'D:emotional_openness:-0.48->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_emotional_openness_002` → `eq_tr_v1_emotional_openness_002`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `emotional_openness` → `emotional_openness`
- **Secondary:** [] → ['conflict_approach', 'empathy']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:emotional_openness', 'B:emotional_openness', 'D:emotional_openness']
- **Delta-magnitude changes:** ['A:emotional_openness:-0.78->0.75', 'A:empathy:0.18->0.2', 'B:emotional_openness:-0.42->0.45', 'C:emotional_openness:-0.08->-0.2', 'D:emotional_openness:0.48->-0.45', 'D:conflict_approach:-0.15->-0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_emotional_openness_003` → `eq_tr_v1_emotional_openness_003`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `emotional_openness` → `emotional_openness`
- **Secondary:** ['empathy', 'boundary_setting'] → ['boundary_setting', 'empathy', 'social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:empathy', 'B:boundary_setting', 'C:emotional_openness', 'C:empathy']
- **Delta-magnitude changes:** ['A:emotional_openness:0.65->0.6', 'A:empathy:-0.22->0.3', 'B:emotional_openness:0.35->0.3', 'B:boundary_setting:-0.22->0.3', 'C:emotional_openness:0.1->-0.15', 'C:empathy:-0.18->0.3', 'D:emotional_openness:-0.42->-0.45', 'D:social_awareness:-0.18->-0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_empathy_001` → `eq_tr_v1_empathy_001`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `empathy` → `empathy`
- **Secondary:** ['boundary_setting', 'assertiveness'] → ['boundary_setting']
- **Prompt changes:** none
- **Option text changes:** ['A', 'D']
- **Delta-direction changes:** ['B:boundary_setting', 'C:assertiveness', 'D:boundary_setting', 'D:emotion_regulation']
- **Delta-magnitude changes:** ['A:boundary_setting:-0.22->-0.3', 'A:empathy:0.72->0.75', 'B:boundary_setting:-0.18->0.2', 'B:empathy:0.38->0.45', 'C:empathy:0.12->0.15', 'C:assertiveness:-0.15->None', 'D:boundary_setting:None->0.2', 'D:emotion_regulation:0.2->None']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_empathy_002` → `eq_tr_v1_empathy_002`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `empathy` → `empathy`
- **Secondary:** ['repair_orientation', 'conflict_approach'] → ['assertiveness', 'repair_orientation']
- **Prompt changes:** none
- **Option text changes:** ['A', 'B', 'C', 'D']
- **Delta-direction changes:** ['A:repair_orientation', 'B:repair_orientation', 'C:conflict_approach']
- **Delta-magnitude changes:** ['A:repair_orientation:-0.28->0.3', 'A:empathy:0.72->0.75', 'B:repair_orientation:-0.22->0.2', 'B:empathy:0.38->0.45', 'C:conflict_approach:-0.18->None', 'C:empathy:0.12->0.15', 'D:assertiveness:0.25->0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_empathy_003` → `eq_tr_v1_empathy_003`

- **Change types:** evidence_remap, evidence_strength_revision, sdr_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `empathy` → `empathy`
- **Secondary:** ['emotional_openness', 'boundary_setting'] → ['boundary_setting', 'emotional_openness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:emotional_openness', 'B:boundary_setting', 'C:boundary_setting']
- **Delta-magnitude changes:** ['A:emotional_openness:-0.22->0.2', 'A:empathy:0.7->0.6', 'B:boundary_setting:-0.2->0.3', 'C:boundary_setting:-0.28->0.3', 'C:empathy:0.18->0.3', 'D:emotional_openness:-0.22->-0.2', 'D:empathy:-0.4->-0.45']
- **Evidence-strength changes:** ['A:0.72->0.6', 'B:0.72->0.65', 'C:0.72->0.65', 'D:0.72->0.6']
- **SDR changes:** ['item:low->moderate']
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_perspective_taking_001` → `eq_tr_v1_perspective_taking_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `perspective_taking` → `perspective_taking`
- **Secondary:** ['social_awareness', 'boundary_setting'] → ['boundary_setting', 'social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:social_awareness', 'B:social_awareness', 'C:boundary_setting', 'D:conflict_approach']
- **Delta-magnitude changes:** ['A:social_awareness:-0.25->0.2', 'B:social_awareness:-0.15->0.2', 'B:perspective_taking:0.48->0.45', 'C:boundary_setting:-0.28->0.2', 'C:perspective_taking:0.1->0.2', 'D:conflict_approach:-0.18->None', 'D:perspective_taking:-0.42->-0.45']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_perspective_taking_002` → `eq_tr_v1_perspective_taking_002`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `perspective_taking` → `perspective_taking`
- **Secondary:** ['social_awareness'] → ['social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:social_awareness', 'C:social_awareness']
- **Delta-magnitude changes:** ['A:social_awareness:-0.22->0.2', 'B:perspective_taking:0.48->0.45', 'C:social_awareness:-0.18->0.2', 'C:perspective_taking:0.1->0.2', 'D:perspective_taking:-0.42->-0.45']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_perspective_taking_003` → `eq_tr_v1_perspective_taking_003`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `perspective_taking` → `perspective_taking`
- **Secondary:** ['conflict_approach', 'social_awareness'] → ['social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:conflict_approach', 'A:social_awareness', 'C:social_awareness']
- **Delta-magnitude changes:** ['A:conflict_approach:-0.2->None', 'A:social_awareness:None->0.2', 'A:perspective_taking:0.68->0.75', 'B:perspective_taking:0.42->0.45', 'C:social_awareness:-0.18->0.2', 'C:perspective_taking:0.22->0.3', 'D:social_awareness:-0.15->-0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_repair_orientation_001` → `eq_tr_v1_repair_orientation_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `repair_orientation` → `repair_orientation`
- **Secondary:** ['empathy'] → ['assertiveness', 'empathy']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:empathy', 'B:empathy', 'C:conflict_approach']
- **Delta-magnitude changes:** ['A:empathy:-0.22->0.2', 'B:empathy:-0.15->None', 'C:repair_orientation:0.08->0.15', 'C:conflict_approach:-0.12->None', 'D:repair_orientation:-0.52->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_repair_orientation_002` → `eq_tr_v1_repair_orientation_002`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `repair_orientation` → `repair_orientation`
- **Secondary:** ['emotional_openness', 'empathy'] → ['conflict_approach', 'emotional_openness', 'empathy']
- **Prompt changes:** none
- **Option text changes:** ['A', 'B', 'C', 'D']
- **Delta-direction changes:** ['A:emotional_openness', 'B:empathy']
- **Delta-magnitude changes:** ['A:emotional_openness:-0.22->0.2', 'B:empathy:-0.18->0.2', 'C:repair_orientation:0.08->0.15', 'D:conflict_approach:0.15->0.2', 'D:repair_orientation:-0.52->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_repair_orientation_003` → `eq_tr_v1_repair_orientation_003`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `repair_orientation` → `repair_orientation`
- **Secondary:** ['conflict_approach', 'assertiveness'] → ['assertiveness', 'conflict_approach']
- **Prompt changes:** none
- **Option text changes:** ['A', 'B', 'C', 'D']
- **Delta-direction changes:** ['A:conflict_approach', 'B:assertiveness', 'D:conflict_approach']
- **Delta-magnitude changes:** ['A:repair_orientation:0.68->0.75', 'A:conflict_approach:-0.22->0.2', 'B:repair_orientation:0.42->0.45', 'B:assertiveness:-0.18->0.2', 'C:repair_orientation:0.1->0.15', 'D:repair_orientation:-0.5->-0.55', 'D:conflict_approach:-0.18->None']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_self_awareness_001` → `eq_tr_v1_self_awareness_001`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `self_awareness` → `self_awareness`
- **Secondary:** ['emotion_regulation'] → ['emotion_regulation']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:emotion_regulation', 'B:emotion_regulation']
- **Delta-magnitude changes:** ['A:self_awareness:0.72->0.75', 'A:emotion_regulation:-0.18->0.2', 'B:self_awareness:0.48->0.45', 'B:emotion_regulation:-0.15->0.2', 'C:self_awareness:0.22->0.2']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_self_awareness_002` → `eq_tr_v1_self_awareness_002`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `self_awareness` → `self_awareness`
- **Secondary:** ['social_awareness', 'boundary_setting'] → ['boundary_setting', 'social_awareness']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:social_awareness', 'B:boundary_setting']
- **Delta-magnitude changes:** ['A:social_awareness:-0.22->0.2', 'A:self_awareness:0.7->0.75', 'B:boundary_setting:-0.18->0.2', 'B:self_awareness:0.44->0.45', 'D:social_awareness:0.12->0.2', 'D:self_awareness:-0.4->-0.45']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_self_awareness_003` → `eq_tr_v1_self_awareness_003`

- **Change types:** evidence_remap, evidence_strength_revision
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `self_awareness` → `self_awareness`
- **Secondary:** ['conflict_approach'] → ['assertiveness', 'emotion_regulation']
- **Prompt changes:** none
- **Option text changes:** none
- **Delta-direction changes:** ['A:self_awareness', 'B:self_awareness', 'D:conflict_approach', 'D:self_awareness']
- **Delta-magnitude changes:** ['A:self_awareness:-0.72->0.75', 'A:emotion_regulation:0.25->0.2', 'B:self_awareness:-0.48->0.45', 'C:self_awareness:-0.22->-0.3', 'D:conflict_approach:-0.18->None', 'D:self_awareness:0.55->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_social_awareness_001` → `eq_tr_v1_social_awareness_001`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `social_awareness` → `social_awareness`
- **Secondary:** ['empathy', 'boundary_setting'] → ['empathy', 'perspective_taking']
- **Prompt changes:** none
- **Option text changes:** ['C', 'D']
- **Delta-direction changes:** ['A:empathy', 'B:boundary_setting', 'B:perspective_taking']
- **Delta-magnitude changes:** ['A:social_awareness:0.72->0.75', 'A:empathy:-0.22->0.2', 'B:boundary_setting:-0.18->None', 'B:perspective_taking:None->0.2', 'C:social_awareness:0.12->0.15', 'D:social_awareness:-0.48->-0.55']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_social_awareness_002` → `eq_tr_v1_social_awareness_002`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `social_awareness` → `social_awareness`
- **Secondary:** ['perspective_taking', 'boundary_setting'] → ['perspective_taking']
- **Prompt changes:** none
- **Option text changes:** ['B', 'D']
- **Delta-direction changes:** ['A:perspective_taking', 'B:boundary_setting']
- **Delta-magnitude changes:** ['A:social_awareness:0.7->0.75', 'A:perspective_taking:-0.22->0.2', 'B:boundary_setting:-0.18->None', 'B:social_awareness:0.44->0.45', 'D:social_awareness:-0.42->-0.45']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.55', 'D:0.72->0.5']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

## `eq_tr_v1_social_awareness_003` → `eq_tr_v1_social_awareness_003`

- **Change types:** evidence_remap, evidence_strength_revision, language_edit
- **Verdict:** EVIDENCE_REMAP
- **Primary:** `social_awareness` → `social_awareness`
- **Secondary:** ['repair_orientation', 'perspective_taking'] → ['perspective_taking']
- **Prompt changes:** none
- **Option text changes:** ['C']
- **Delta-direction changes:** ['A:repair_orientation', 'A:perspective_taking', 'B:perspective_taking', 'D:social_awareness']
- **Delta-magnitude changes:** ['A:social_awareness:0.68->0.75', 'A:repair_orientation:-0.2->None', 'A:perspective_taking:None->0.2', 'B:social_awareness:0.42->0.45', 'B:perspective_taking:-0.15->0.2', 'C:social_awareness:0.12->0.2', 'D:social_awareness:-0.45->0.3']
- **Evidence-strength changes:** ['A:0.72->0.65', 'B:0.72->0.6', 'C:0.72->0.5', 'D:0.72->0.55']
- **SDR changes:** none
- **Response-style changes:** ['all->low']
- **Pair/group changes:** none
- **RVI-role changes:** none
- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup
- **ID decision:** retain — primary dimension and scenario trade-off unchanged
- **Remaining review concern:** expert psychological + cognitive interview pending

