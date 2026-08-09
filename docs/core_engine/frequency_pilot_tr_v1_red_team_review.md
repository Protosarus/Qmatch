# Frequency Pilot TR v1 — Internal Semantic Red-Team Review (P2A-2D-2)

**Scope:** Independent challenge of all 50 items in `frequency_pilot_tr_v1.json`.
**Original pilot preserved:** yes (not overwritten).
**Candidate:** `frequency_pilot_tr_v1_review_candidate_1.json`.
**Does not replace:** expert psychological review, expert Turkish review, cognitive interviews, participant data, calibration, legal review.

## Overall counts

| Metric | Count |
|---|---:|
| PASS | 34 |
| PASS_WITH_MINOR_EDIT | 16 |
| EVIDENCE_REMAP | 0 |
| TRADEOFF_REVISION | 0 |
| REWRITE | 0 |
| REPLACE | 0 |
| UNRESOLVED | 0 |
| Length-leakage items edited | 16 |
| Reverse-pair members (doc-only) | 12 |

## Cross-cutting findings

1. Sixteen items had option-length leakage (max/min > 1.50); short poles expanded with parallel behavioral Turkish wording.
2. Reverse-pair primary deltas **retained** behaviorally keyed identical vectors (P2A-2D-1 policy); not negated to satisfy RVI.
3. TraitScoringService `_reversePairConsistency` expects opposite stored signs → **CONDITIONAL** blocker for reverse RVI.
4. Evidence-strength values remain in `{0.50,0.55,0.60,0.65,0.70}` band; no flat 0.72.
5. No all-positive multi-dimension dominant options after trade-off guard.

## Item matrix

### Item 1: `frequency_tr_v1_communication_pace_001`

1. **Question ID:** `frequency_tr_v1_communication_pace_001`
2. **Scenario family:** `early_messaging_first_contact`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_02` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.24
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 2: `frequency_tr_v1_communication_pace_002`

1. **Question ID:** `frequency_tr_v1_communication_pace_002`
2. **Scenario family:** `longer_term_communication_rhythm`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['social_energy', 'spontaneity', 'stability']
7. **Red-team secondary dimensions:** ['social_energy', 'spontaneity', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_02` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.47
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 3: `frequency_tr_v1_communication_pace_003`

1. **Question ID:** `frequency_tr_v1_communication_pace_003`
2. **Scenario family:** `silence_space_reconnection`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_02` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.24
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 4: `frequency_tr_v1_communication_pace_004`

1. **Question ID:** `frequency_tr_v1_communication_pace_004`
2. **Scenario family:** `shared_activities_novelty`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_02` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.41
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 5: `frequency_tr_v1_communication_pace_005`

1. **Question ID:** `frequency_tr_v1_communication_pace_005`
2. **Scenario family:** `longer_term_communication_rhythm`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'spontaneity']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_08` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.42
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 6: `frequency_tr_v1_communication_pace_006`

1. **Question ID:** `frequency_tr_v1_communication_pace_006`
2. **Scenario family:** `one_to_one_vs_group`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['social_energy', 'stability']
7. **Red-team secondary dimensions:** ['social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_02` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.47
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 7: `frequency_tr_v1_communication_pace_007`

1. **Question ID:** `frequency_tr_v1_communication_pace_007`
2. **Scenario family:** `planning_scheduling_last_minute`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_08` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.31
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 8: `frequency_tr_v1_communication_pace_008`

1. **Question ID:** `frequency_tr_v1_communication_pace_008`
2. **Scenario family:** `routine_continuity_habits`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_02` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.23
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 9: `frequency_tr_v1_communication_pace_009`

1. **Question ID:** `frequency_tr_v1_communication_pace_009`
2. **Scenario family:** `conversation_depth_topic_progression`
3. **Current primary dimension:** `communication_pace`
4. **Red-team primary dimension:** `communication_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.19
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 10: `frequency_tr_v1_depth_preference_001`

1. **Question ID:** `frequency_tr_v1_depth_preference_001`
2. **Scenario family:** `early_messaging_first_contact`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_07` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.23
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 11: `frequency_tr_v1_depth_preference_002`

1. **Question ID:** `frequency_tr_v1_depth_preference_002`
2. **Scenario family:** `conversation_depth_topic_progression`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_01` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.45
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 12: `frequency_tr_v1_depth_preference_003`

1. **Question ID:** `frequency_tr_v1_depth_preference_003`
2. **Scenario family:** `conversation_depth_topic_progression`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_01` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.42
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 13: `frequency_tr_v1_depth_preference_004`

1. **Question ID:** `frequency_tr_v1_depth_preference_004`
2. **Scenario family:** `silence_space_reconnection`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_01` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.46
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 14: `frequency_tr_v1_depth_preference_005`

1. **Question ID:** `frequency_tr_v1_depth_preference_005`
2. **Scenario family:** `one_to_one_vs_group`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.35
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 15: `frequency_tr_v1_depth_preference_006`

1. **Question ID:** `frequency_tr_v1_depth_preference_006`
2. **Scenario family:** `one_to_one_vs_group`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'spontaneity', 'stability']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'spontaneity', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_07` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.42
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 16: `frequency_tr_v1_depth_preference_007`

1. **Question ID:** `frequency_tr_v1_depth_preference_007`
2. **Scenario family:** `shared_activities_novelty`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_01` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.48
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 17: `frequency_tr_v1_depth_preference_008`

1. **Question ID:** `frequency_tr_v1_depth_preference_008`
2. **Scenario family:** `personal_disclosure_trust`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'spontaneity', 'stability']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'spontaneity', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_01` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.47
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 18: `frequency_tr_v1_depth_preference_009`

1. **Question ID:** `frequency_tr_v1_depth_preference_009`
2. **Scenario family:** `routine_continuity_habits`
3. **Current primary dimension:** `depth_preference`
4. **Red-team primary dimension:** `depth_preference`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_01` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.12
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 19: `frequency_tr_v1_disclosure_pace_001`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_001`
2. **Scenario family:** `personal_disclosure_trust`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_06` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.42
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 20: `frequency_tr_v1_disclosure_pace_002`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_002`
2. **Scenario family:** `personal_disclosure_trust`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_06` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.09
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 21: `frequency_tr_v1_disclosure_pace_003`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_003`
2. **Scenario family:** `early_messaging_first_contact`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_06` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.49
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 22: `frequency_tr_v1_disclosure_pace_004`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_004`
2. **Scenario family:** `personal_disclosure_trust`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_06` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.2
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 23: `frequency_tr_v1_disclosure_pace_005`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_005`
2. **Scenario family:** `silence_space_reconnection`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.24
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 24: `frequency_tr_v1_disclosure_pace_006`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_006`
2. **Scenario family:** `one_to_one_vs_group`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.25
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 25: `frequency_tr_v1_disclosure_pace_007`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_007`
2. **Scenario family:** `longer_term_communication_rhythm`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_06` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.21
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 26: `frequency_tr_v1_disclosure_pace_008`

1. **Question ID:** `frequency_tr_v1_disclosure_pace_008`
2. **Scenario family:** `personal_disclosure_trust`
3. **Current primary dimension:** `disclosure_pace`
4. **Red-team primary dimension:** `disclosure_pace`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_06` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.34
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 27: `frequency_tr_v1_social_energy_001`

1. **Question ID:** `frequency_tr_v1_social_energy_001`
2. **Scenario family:** `social_outings_groups_recovery`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_03` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.12
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 28: `frequency_tr_v1_social_energy_002`

1. **Question ID:** `frequency_tr_v1_social_energy_002`
2. **Scenario family:** `one_to_one_vs_group`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_03` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.41
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 29: `frequency_tr_v1_social_energy_003`

1. **Question ID:** `frequency_tr_v1_social_energy_003`
2. **Scenario family:** `social_outings_groups_recovery`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_03` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.41
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 30: `frequency_tr_v1_social_energy_004`

1. **Question ID:** `frequency_tr_v1_social_energy_004`
2. **Scenario family:** `shared_activities_novelty`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_03` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.36
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 31: `frequency_tr_v1_social_energy_005`

1. **Question ID:** `frequency_tr_v1_social_energy_005`
2. **Scenario family:** `early_messaging_first_contact`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.28
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 32: `frequency_tr_v1_social_energy_006`

1. **Question ID:** `frequency_tr_v1_social_energy_006`
2. **Scenario family:** `social_outings_groups_recovery`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_03` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.28
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 33: `frequency_tr_v1_social_energy_007`

1. **Question ID:** `frequency_tr_v1_social_energy_007`
2. **Scenario family:** `silence_space_reconnection`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_03` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.33
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 34: `frequency_tr_v1_social_energy_008`

1. **Question ID:** `frequency_tr_v1_social_energy_008`
2. **Scenario family:** `conversation_depth_topic_progression`
3. **Current primary dimension:** `social_energy`
4. **Red-team primary dimension:** `social_energy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.07
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 35: `frequency_tr_v1_spontaneity_001`

1. **Question ID:** `frequency_tr_v1_spontaneity_001`
2. **Scenario family:** `planning_scheduling_last_minute`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_04` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.38
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 36: `frequency_tr_v1_spontaneity_002`

1. **Question ID:** `frequency_tr_v1_spontaneity_002`
2. **Scenario family:** `shared_activities_novelty`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_04` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.26
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 37: `frequency_tr_v1_spontaneity_003`

1. **Question ID:** `frequency_tr_v1_spontaneity_003`
2. **Scenario family:** `planning_scheduling_last_minute`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_04` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.44
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 38: `frequency_tr_v1_spontaneity_004`

1. **Question ID:** `frequency_tr_v1_spontaneity_004`
2. **Scenario family:** `social_outings_groups_recovery`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_04` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.34
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 39: `frequency_tr_v1_spontaneity_005`

1. **Question ID:** `frequency_tr_v1_spontaneity_005`
2. **Scenario family:** `shared_activities_novelty`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_04` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.3
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 40: `frequency_tr_v1_spontaneity_006`

1. **Question ID:** `frequency_tr_v1_spontaneity_006`
2. **Scenario family:** `planning_scheduling_last_minute`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.18
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 41: `frequency_tr_v1_spontaneity_007`

1. **Question ID:** `frequency_tr_v1_spontaneity_007`
2. **Scenario family:** `early_messaging_first_contact`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['disclosure_pace', 'stability']
7. **Red-team secondary dimensions:** ['disclosure_pace', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.39
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 42: `frequency_tr_v1_spontaneity_008`

1. **Question ID:** `frequency_tr_v1_spontaneity_008`
2. **Scenario family:** `routine_continuity_habits`
3. **Current primary dimension:** `spontaneity`
4. **Red-team primary dimension:** `spontaneity`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'stability']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_04` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.37
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 43: `frequency_tr_v1_stability_001`

1. **Question ID:** `frequency_tr_v1_stability_001`
2. **Scenario family:** `routine_continuity_habits`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_05` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.23
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 44: `frequency_tr_v1_stability_002`

1. **Question ID:** `frequency_tr_v1_stability_002`
2. **Scenario family:** `longer_term_communication_rhythm`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'disclosure_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'disclosure_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_05` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.27
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 45: `frequency_tr_v1_stability_003`

1. **Question ID:** `frequency_tr_v1_stability_003`
2. **Scenario family:** `planning_scheduling_last_minute`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['depth_preference', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['depth_preference', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_05` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.32
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 46: `frequency_tr_v1_stability_004`

1. **Question ID:** `frequency_tr_v1_stability_004`
2. **Scenario family:** `routine_continuity_habits`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `frequency_tr_v1_sem_05` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.27
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 47: `frequency_tr_v1_stability_005`

1. **Question ID:** `frequency_tr_v1_stability_005`
2. **Scenario family:** `longer_term_communication_rhythm`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'disclosure_pace', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'disclosure_pace', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.35
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 48: `frequency_tr_v1_stability_006`

1. **Question ID:** `frequency_tr_v1_stability_006`
2. **Scenario family:** `silence_space_reconnection`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'disclosure_pace', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'disclosure_pace', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `frequency_tr_v1_rev_05` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.17
26. **Recommended action:** PASS_WITH_MINOR_EDIT
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** high
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 49: `frequency_tr_v1_stability_007`

1. **Question ID:** `frequency_tr_v1_stability_007`
2. **Scenario family:** `social_outings_groups_recovery`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'depth_preference', 'social_energy', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `frequency_tr_v1_iso_05` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.22
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

### Item 50: `frequency_tr_v1_stability_008`

1. **Question ID:** `frequency_tr_v1_stability_008`
2. **Scenario family:** `conversation_depth_topic_progression`
3. **Current primary dimension:** `stability`
4. **Red-team primary dimension:** `stability`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['communication_pace', 'disclosure_pace', 'spontaneity']
7. **Red-team secondary dimensions:** ['communication_pace', 'disclosure_pace', 'spontaneity']
8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D acceptable
13. **Per-option dominant-answer risk:** none flagged after length edits
14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)
15. **Per-option delta-magnitude review:** parent bands retained
16. **Per-option evidence-strength review:** contract band retained or nudged
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain; behavioral keying unchanged
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)
24. **Turkish-language verdict:** internal length-balance edits; expert language review pending
25. **Option-length ratio after edit:** 1.41
26. **Recommended action:** PASS
27. **Residual ambiguity:** cognitive interviews pending
28. **Human-review priority:** medium
29. **Final internal disposition:** `internal_accept_for_candidate`

## Pair / group / RVI summary

- Semantic pairs (8): retained.
- Reverse pairs (6): retained; **behavioral keying unchanged**; RVI opposite-sign check is a known service gap (**CONDITIONAL**).
- Behavioral isomorphs (6): retained.
- RVI roles: timing_quality universal; semantic/reverse/isomorph/impression/variation retained where design supports.

