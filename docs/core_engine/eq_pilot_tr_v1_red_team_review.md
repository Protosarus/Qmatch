# EQ Pilot TR v1 — Internal Semantic Red-Team Review (P2A-2C-2)

**Scope:** Independent challenge of all 30 items in `eq_pilot_tr_v1.json`.
**Original pilot preserved:** yes (not overwritten).
**Does not replace:** expert psychological review, expert Turkish review, cognitive interviews, participant data, calibration, legal review.

## Overall counts

| Metric | Count |
|---|---:|
| PASS | 0 |
| PASS_WITH_MINOR_EDIT | 0 |
| EVIDENCE_REMAP | 30 |
| REWRITE | 0 |
| REPLACE | 0 |
| UNRESOLVED | 0 |
| Primary-dimension disagreements | 0 |
| Reverse-pair polarity fixes | 5 |
| Evidence-strength revisions (items touched) | 30 |
| Item-level SDR revisions | 1 |
| High/moderate SDR items after review | 6 |

## Cross-cutting findings

1. Reverse-pair primary deltas in v1 were inverted relative to option behavior to satisfy opposite-sign RVI checks; this poisons TraitScoringService trait direction. Candidate restores behavioral keying.
2. Flat `evidence_strength: 0.72` replaced per `eq_evidence_strength_contract_v1.md`.
3. Spurious negative secondary “cost” deltas removed or remapped to defensible signs.
4. Boilerplate meta-commentary stripped from Turkish options.
5. `empathy_003` item-level SDR raised to moderate to match option-level risk.
6. Reverse RVI remains CONDITIONAL due to TraitScoringService opposite-sign expectation.

## Item matrix

### Item 1: `eq_tr_v1_assertiveness_001`

1. **Question ID:** `eq_tr_v1_assertiveness_001`
2. **Scenario family:** `boundary_and_request_conflicts`
3. **Current primary dimension:** `assertiveness`
4. **Red-team primary dimension:** `assertiveness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['emotion_regulation', 'repair_orientation']
7. **Red-team secondary dimensions:** ['boundary_setting', 'repair_orientation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_04` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_03` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 2: `eq_tr_v1_assertiveness_002`

1. **Question ID:** `eq_tr_v1_assertiveness_002`
2. **Scenario family:** `competing_values_and_tradeoffs`
3. **Current primary dimension:** `assertiveness`
4. **Red-team primary dimension:** `assertiveness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['boundary_setting', 'social_awareness']
7. **Red-team secondary dimensions:** ['boundary_setting', 'social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_04` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_02` — retain
23. **RVI-role review:** ['repeated_context_stability', 'semantic_consistency', 'social_impression_risk', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 3: `eq_tr_v1_assertiveness_003`

1. **Question ID:** `eq_tr_v1_assertiveness_003`
2. **Scenario family:** `repeated_behavioral_patterns`
3. **Current primary dimension:** `assertiveness`
4. **Red-team primary dimension:** `assertiveness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** []
7. **Red-team secondary dimensions:** ['boundary_setting', 'repair_orientation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_03` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 4: `eq_tr_v1_boundary_setting_001`

1. **Question ID:** `eq_tr_v1_boundary_setting_001`
2. **Scenario family:** `boundary_and_request_conflicts`
3. **Current primary dimension:** `boundary_setting`
4. **Red-team primary dimension:** `boundary_setting`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['assertiveness']
7. **Red-team secondary dimensions:** ['assertiveness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_03` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_02` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 5: `eq_tr_v1_boundary_setting_002`

1. **Question ID:** `eq_tr_v1_boundary_setting_002`
2. **Scenario family:** `competing_values_and_tradeoffs`
3. **Current primary dimension:** `boundary_setting`
4. **Red-team primary dimension:** `boundary_setting`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['assertiveness', 'repair_orientation']
7. **Red-team secondary dimensions:** ['assertiveness', 'repair_orientation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_03` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_02` — retain
23. **RVI-role review:** ['repeated_context_stability', 'semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 6: `eq_tr_v1_boundary_setting_003`

1. **Question ID:** `eq_tr_v1_boundary_setting_003`
2. **Scenario family:** `repeated_behavioral_patterns`
3. **Current primary dimension:** `boundary_setting`
4. **Red-team primary dimension:** `boundary_setting`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** []
7. **Red-team secondary dimensions:** ['assertiveness', 'conflict_approach', 'repair_orientation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_02` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 7: `eq_tr_v1_conflict_approach_001`

1. **Question ID:** `eq_tr_v1_conflict_approach_001`
2. **Scenario family:** `boundary_and_request_conflicts`
3. **Current primary dimension:** `conflict_approach`
4. **Red-team primary dimension:** `conflict_approach`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['perspective_taking', 'assertiveness']
7. **Red-team secondary dimensions:** ['assertiveness', 'emotion_regulation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_04` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 8: `eq_tr_v1_conflict_approach_002`

1. **Question ID:** `eq_tr_v1_conflict_approach_002`
2. **Scenario family:** `repair_after_disagreement`
3. **Current primary dimension:** `conflict_approach`
4. **Red-team primary dimension:** `conflict_approach`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['emotion_regulation', 'repair_orientation']
7. **Red-team secondary dimensions:** ['emotion_regulation', 'repair_orientation', 'social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['response_variation', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 9: `eq_tr_v1_conflict_approach_003`

1. **Question ID:** `eq_tr_v1_conflict_approach_003`
2. **Scenario family:** `competing_values_and_tradeoffs`
3. **Current primary dimension:** `conflict_approach`
4. **Red-team primary dimension:** `conflict_approach`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['boundary_setting']
7. **Red-team secondary dimensions:** ['assertiveness', 'emotion_regulation', 'perspective_taking']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_04` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 10: `eq_tr_v1_emotion_regulation_001`

1. **Question ID:** `eq_tr_v1_emotion_regulation_001`
2. **Scenario family:** `internal_emotional_awareness`
3. **Current primary dimension:** `emotion_regulation`
4. **Red-team primary dimension:** `emotion_regulation`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['self_awareness', 'social_awareness']
7. **Red-team secondary dimensions:** ['empathy', 'social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_06` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 11: `eq_tr_v1_emotion_regulation_002`

1. **Question ID:** `eq_tr_v1_emotion_regulation_002`
2. **Scenario family:** `stress_and_regulation`
3. **Current primary dimension:** `emotion_regulation`
4. **Red-team primary dimension:** `emotion_regulation`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['self_awareness']
7. **Red-team secondary dimensions:** ['emotional_openness', 'self_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_06` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_05` — retain
23. **RVI-role review:** ['repeated_context_stability', 'semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 12: `eq_tr_v1_emotion_regulation_003`

1. **Question ID:** `eq_tr_v1_emotion_regulation_003`
2. **Scenario family:** `stress_and_regulation`
3. **Current primary dimension:** `emotion_regulation`
4. **Red-team primary dimension:** `emotion_regulation`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['self_awareness', 'perspective_taking']
7. **Red-team secondary dimensions:** ['perspective_taking', 'self_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_05` — retain
23. **RVI-role review:** ['repeated_context_stability', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 13: `eq_tr_v1_emotional_openness_001`

1. **Question ID:** `eq_tr_v1_emotional_openness_001`
2. **Scenario family:** `internal_emotional_awareness`
3. **Current primary dimension:** `emotional_openness`
4. **Red-team primary dimension:** `emotional_openness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['self_awareness', 'boundary_setting']
7. **Red-team secondary dimensions:** ['boundary_setting', 'empathy', 'self_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_01` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'social_impression_risk', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 14: `eq_tr_v1_emotional_openness_002`

1. **Question ID:** `eq_tr_v1_emotional_openness_002`
2. **Scenario family:** `emotional_disclosure`
3. **Current primary dimension:** `emotional_openness`
4. **Red-team primary dimension:** `emotional_openness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** []
7. **Red-team secondary dimensions:** ['conflict_approach', 'empathy']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_01` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 15: `eq_tr_v1_emotional_openness_003`

1. **Question ID:** `eq_tr_v1_emotional_openness_003`
2. **Scenario family:** `emotional_disclosure`
3. **Current primary dimension:** `emotional_openness`
4. **Red-team primary dimension:** `emotional_openness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['empathy', 'boundary_setting']
7. **Red-team secondary dimensions:** ['boundary_setting', 'empathy', 'social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['response_variation', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 16: `eq_tr_v1_empathy_001`

1. **Question ID:** `eq_tr_v1_empathy_001`
2. **Scenario family:** `interpersonal_support`
3. **Current primary dimension:** `empathy`
4. **Red-team primary dimension:** `empathy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['boundary_setting', 'assertiveness']
7. **Red-team secondary dimensions:** ['boundary_setting']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_01` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_01` — retain
23. **RVI-role review:** ['repeated_context_stability', 'semantic_consistency', 'social_impression_risk', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 17: `eq_tr_v1_empathy_002`

1. **Question ID:** `eq_tr_v1_empathy_002`
2. **Scenario family:** `repair_after_disagreement`
3. **Current primary dimension:** `empathy`
4. **Red-team primary dimension:** `empathy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['repair_orientation', 'conflict_approach']
7. **Red-team secondary dimensions:** ['assertiveness', 'repair_orientation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_01` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 18: `eq_tr_v1_empathy_003`

1. **Question ID:** `eq_tr_v1_empathy_003`
2. **Scenario family:** `emotional_disclosure`
3. **Current primary dimension:** `empathy`
4. **Red-team primary dimension:** `empathy`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['emotional_openness', 'boundary_setting']
7. **Red-team secondary dimensions:** ['boundary_setting', 'emotional_openness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_01` — retain
23. **RVI-role review:** ['repeated_context_stability', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 19: `eq_tr_v1_perspective_taking_001`

1. **Question ID:** `eq_tr_v1_perspective_taking_001`
2. **Scenario family:** `perspective_taking_family`
3. **Current primary dimension:** `perspective_taking`
4. **Red-team primary dimension:** `perspective_taking`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['social_awareness', 'boundary_setting']
7. **Red-team secondary dimensions:** ['boundary_setting', 'social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_02` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 20: `eq_tr_v1_perspective_taking_002`

1. **Question ID:** `eq_tr_v1_perspective_taking_002`
2. **Scenario family:** `perspective_taking_family`
3. **Current primary dimension:** `perspective_taking`
4. **Red-team primary dimension:** `perspective_taking`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['social_awareness']
7. **Red-team secondary dimensions:** ['social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_02` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_04` — retain
23. **RVI-role review:** ['repeated_context_stability', 'response_variation', 'semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 21: `eq_tr_v1_perspective_taking_003`

1. **Question ID:** `eq_tr_v1_perspective_taking_003`
2. **Scenario family:** `social_context_awareness`
3. **Current primary dimension:** `perspective_taking`
4. **Red-team primary dimension:** `perspective_taking`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['conflict_approach', 'social_awareness']
7. **Red-team secondary dimensions:** ['social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_04` — retain
23. **RVI-role review:** ['repeated_context_stability', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 22: `eq_tr_v1_repair_orientation_001`

1. **Question ID:** `eq_tr_v1_repair_orientation_001`
2. **Scenario family:** `interpersonal_support`
3. **Current primary dimension:** `repair_orientation`
4. **Red-team primary dimension:** `repair_orientation`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['empathy']
7. **Red-team secondary dimensions:** ['assertiveness', 'empathy']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_05` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['semantic_consistency', 'social_impression_risk', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 23: `eq_tr_v1_repair_orientation_002`

1. **Question ID:** `eq_tr_v1_repair_orientation_002`
2. **Scenario family:** `repair_after_disagreement`
3. **Current primary dimension:** `repair_orientation`
4. **Red-team primary dimension:** `repair_orientation`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['emotional_openness', 'empathy']
7. **Red-team secondary dimensions:** ['conflict_approach', 'emotional_openness', 'empathy']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `eq_tr_v1_sem_05` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_03` — retain
23. **RVI-role review:** ['repeated_context_stability', 'semantic_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 24: `eq_tr_v1_repair_orientation_003`

1. **Question ID:** `eq_tr_v1_repair_orientation_003`
2. **Scenario family:** `repeated_behavioral_patterns`
3. **Current primary dimension:** `repair_orientation`
4. **Red-team primary dimension:** `repair_orientation`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['conflict_approach', 'assertiveness']
7. **Red-team secondary dimensions:** ['assertiveness', 'conflict_approach']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `eq_tr_v1_iso_03` — retain
23. **RVI-role review:** ['repeated_context_stability', 'response_variation', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 25: `eq_tr_v1_self_awareness_001`

1. **Question ID:** `eq_tr_v1_self_awareness_001`
2. **Scenario family:** `internal_emotional_awareness`
3. **Current primary dimension:** `self_awareness`
4. **Red-team primary dimension:** `self_awareness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['emotion_regulation']
7. **Red-team secondary dimensions:** ['emotion_regulation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_05` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 26: `eq_tr_v1_self_awareness_002`

1. **Question ID:** `eq_tr_v1_self_awareness_002`
2. **Scenario family:** `social_context_awareness`
3. **Current primary dimension:** `self_awareness`
4. **Red-team primary dimension:** `self_awareness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['social_awareness', 'boundary_setting']
7. **Red-team secondary dimensions:** ['boundary_setting', 'social_awareness']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['response_variation', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 27: `eq_tr_v1_self_awareness_003`

1. **Question ID:** `eq_tr_v1_self_awareness_003`
2. **Scenario family:** `stress_and_regulation`
3. **Current primary dimension:** `self_awareness`
4. **Red-team primary dimension:** `self_awareness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['conflict_approach']
7. **Red-team secondary dimensions:** ['assertiveness', 'emotion_regulation']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `eq_tr_v1_rev_05` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['reverse_consistency', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 28: `eq_tr_v1_social_awareness_001`

1. **Question ID:** `eq_tr_v1_social_awareness_001`
2. **Scenario family:** `interpersonal_support`
3. **Current primary dimension:** `social_awareness`
4. **Red-team primary dimension:** `social_awareness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['empathy', 'boundary_setting']
7. **Red-team secondary dimensions:** ['empathy', 'perspective_taking']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** moderate item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `moderate`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['social_impression_risk', 'timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** high
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 29: `eq_tr_v1_social_awareness_002`

1. **Question ID:** `eq_tr_v1_social_awareness_002`
2. **Scenario family:** `perspective_taking_family`
3. **Current primary dimension:** `social_awareness`
4. **Red-team primary dimension:** `social_awareness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['perspective_taking', 'boundary_setting']
7. **Red-team secondary dimensions:** ['perspective_taking']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

### Item 30: `eq_tr_v1_social_awareness_003`

1. **Question ID:** `eq_tr_v1_social_awareness_003`
2. **Scenario family:** `social_context_awareness`
3. **Current primary dimension:** `social_awareness`
4. **Red-team primary dimension:** `social_awareness`
5. **Primary agreement:** yes
6. **Current secondary dimensions:** ['repair_orientation', 'perspective_taking']
7. **Red-team secondary dimensions:** ['perspective_taking']
8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.
9. **Prompt semantic verdict:** acceptable
10. **Trade-off verdict:** genuine mixed trade-off retained
11. **Social-desirability verdict:** low item risk
12. **Per-option plausibility verdict:** A–D strong/acceptable
13. **Per-option dominant-answer risk:** none remaining after softening
14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)
15. **Per-option delta-magnitude review:** auditable bands applied
16. **Per-option evidence-strength review:** contract bands applied
17. **Item-level SDR review:** `low`
18. **Option-level SDR review:** see candidate JSON / evidence review
19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis
20. **Semantic-pair review:** `none` — retain
21. **Reverse-pair review:** `none` — retain membership; polarity fixed if reverse member
22. **Behavioral-isomorph review:** `none` — retain
23. **RVI-role review:** ['timing_quality'] — reverse_consistency CONDITIONAL
24. **Turkish-language verdict:** internal cleanup completed; expert language review pending
25. **Recommended action:** EVIDENCE_REMAP
26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed
27. **Human-review priority:** medium
28. **Final internal disposition:** `internal_accept_for_candidate`

## Pair / group / RVI summary

- Semantic pairs (6): retained; shared constructs confirmed.
- Reverse pairs (5): retained as opposite-pole scenario pairs; **behavioral keying restored**; RVI opposite-sign check is a known service gap.
- Behavioral isomorphs (5): retained; surface context differs, trade-off structure similar.
- RVI roles: timing_quality universal; semantic/reverse/isomorph/impression/variation retained where design supports; reverse_consistency interpretation CONDITIONAL.

