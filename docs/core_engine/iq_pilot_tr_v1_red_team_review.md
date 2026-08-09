# IQ Pilot TR v1 — Internal Semantic Red-Team Review (P2A-2B-2)

**Scope:** Independent solve + challenge of all 25 items in `iq_pilot_tr_v1.json`.  
**Does not replace:** expert Turkish review, measurement review, participant data, IRT calibration, legal review.  
**Original pilot preserved:** yes (not overwritten).

## Overall summary

| Metric | Count |
|---|---|
| PASS | 17 |
| PASS_WITH_MINOR_EDIT | 6 |
| REWRITE | 1 |
| REPLACE | 1 |
| UNRESOLVED | 0 |
| Answer-key disagreements | 0 |
| Alternative plausible answers (material) | 1 (`spatial_003` viewpoint risk) |
| High construct contamination remaining in v1 | 1 (`pattern_006` factorial familiarity) |
| Items requiring a visual | 1 (`spatial_003`) |
| High/critical human-review priority | 4 |

Verdict legend: PASS / PASS_WITH_MINOR_EDIT / REWRITE / REPLACE / UNRESOLVED.

---

## Item matrix

### iq_tr_v1_logical_001
- Domain: logical_reasoning
- Prompt: rain→wet ground; ground wet; what follows?
- Stored: A · Independent: A · Agreement: yes
- Semantic: **PASS** · Language: PASS · Construct: PASS (low contamination)
- Distractors: B invalid-strong (affirm consequent), C invalid-strong, D invalid-strong
- Alternatives: none material
- Assumptions: none beyond classical conditional
- Difficulty: 2→2 · Action: keep · Priority: low · Residual: none

### iq_tr_v1_logical_002
- Domain: logical_reasoning
- Prompt: three shelves; glass not top; plate not bottom; kettle under plate
- Stored: C · Independent: C · Agreement: yes
- Enumerated arrangements: only plate-top / kettle-mid / glass-bottom valid
- Semantic: **PASS** · Language: PASS · Construct: PASS
- Distractors: A/B/D weak-to-acceptable (ignore constraints)
- Difficulty: 2→2 · Action: keep · Priority: low

### iq_tr_v1_logical_003 (anchor)
- Stored: B · Independent: B · Agreement: yes
- Semantic: **PASS** · Language: PASS · Construct: PASS
- C is strong distractor (some↔all confusion)
- Difficulty: 3→3 · Action: keep anchor · Priority: medium (set relations)

### iq_tr_v1_logical_004
- Stored: D · Independent: D · Agreement: yes
- Semantic: **PASS** · Necessary∧necessary clear
- Difficulty: 3→3 · Action: keep · Priority: low

### iq_tr_v1_logical_005
- Stored: A · Independent: A · Agreement: yes
- Semantic: **PASS_WITH_MINOR_EDIT** — binary open/closed was implicit
- Language: minor clarity · Construct: PASS
- Difficulty: 3→3 · Action: clarify two-state · Priority: medium

### iq_tr_v1_logical_006
- Stored: D · Independent: D · Agreement: yes
- Semantic: **PASS** · Difficulty: 4→4 · Action: keep · Priority: low

### iq_tr_v1_logical_007
- Stored: B · Independent: B · Agreement: yes
- Semantic: **PASS_WITH_MINOR_EDIT** — «yalnızca … olursa» can be misread
- Language: needs disambiguation · Construct: PASS (low)
- Difficulty: 4→4 · Action: rewrite only-if wording · Priority: **high**

### iq_tr_v1_pattern_001
- Stored: C · Independent: C · Agreement: yes
- Competing rule +2,+4,+8,+16 also yields 32 — still unique answer
- Semantic: **PASS** · Difficulty: 2→2 · Priority: low

### iq_tr_v1_pattern_002
- Stored: A · Independent: A · Agreement: yes · **PASS** · Priority: low

### iq_tr_v1_pattern_003 (anchor)
- Stored: B · Independent: B · Agreement: yes
- Intended ×2/−1; competing rules do not fit all terms as cleanly
- Semantic: **PASS** · Difficulty: 3→3 · keep anchor · Priority: medium

### iq_tr_v1_pattern_004
- Stored: D · Independent: D · Agreement: yes · product rule unique · **PASS**

### iq_tr_v1_pattern_005
- Stored: C · Independent: C · Agreement: yes · **PASS** · Priority: low

### iq_tr_v1_pattern_006 ⚠
- Stored: B (720) · Independent: B · Agreement: yes numerically
- Intended: increasing multipliers / n!
- Competing underdetermined rules weaker once “çarpanları artan” read carefully, but factorial familiarity is a contaminating construct
- Semantic: **REWRITE** · Construct contamination: **high** (school factorial)
- Difficulty: 4→3 (after making multipliers explicit) · Priority: **critical**
- Action: explicit step-by-step multipliers in stem

### iq_tr_v1_verbal_001
- Stored: A · Independent: A · Agreement: yes · **PASS** · Priority: low

### iq_tr_v1_verbal_002
- Stored: D · Independent: D · Agreement: yes (with non-empty set)
- Vacuous-truth edge case if empty participants
- Semantic: **PASS_WITH_MINOR_EDIT** · Priority: medium
- Action: state “en az bir katılımcı vardır”

### iq_tr_v1_verbal_003 (anchor)
- Stored: C · Independent: C · Agreement: yes · **PASS** · Priority: medium
- Medical surface content is argument-structure only

### iq_tr_v1_verbal_004
- Stored: A · Independent: A · Agreement: yes
- Semantic: **PASS** / difficulty **PASS_WITH_MINOR_EDIT** (too easy for medium)
- Difficulty: 3→2 · Priority: low

### iq_tr_v1_verbal_005 (connective)
- Stored: D · Independent: D · Agreement: yes
- Semantic: **PASS** · Turkish «ancak» contrast natural
- Two educated speakers unlikely to disagree · Priority: medium (expert confirm)

### iq_tr_v1_verbal_006 (quantifier opposition)
- Stored: B · Independent: B · Agreement: yes (contradictories)
- Semantic: **PASS** · Priority: **high** (expert logic-language confirm)

### iq_tr_v1_spatial_001
- Stored: C · Independent: C · Agreement: yes · **PASS**

### iq_tr_v1_spatial_002
- Stored: A · Independent: A · Agreement: yes · **PASS**

### iq_tr_v1_spatial_003 ⚠ (was anchor)
- Stored: B · Independent: B under standard viewer convention
- Alternative: “öne doğru” viewpoint not uniquely fixed without figure
- Semantic: **REPLACE** · Requires visual: **yes** · Contamination: moderate reading+imagery
- Priority: **critical** · Action: replace with unambiguous map displacement; new ID; transfer anchor

### iq_tr_v1_spatial_004
- Stored: D · Independent: D · Agreement: yes · **PASS**

### iq_tr_v1_spatial_005
- Stored: A · Independent: A · Agreement: yes
- Semantic: **PASS_WITH_MINOR_EDIT** — define ön/arka/sol/sağ axes
- Priority: medium

### iq_tr_v1_spatial_006
- Stored: C · Independent: C · Agreement: yes · **PASS** · Priority: low

---

## Cross-cutting findings

### Answer-key disagreements
None (0). Independent solves matched stored keys; failures were ambiguity/contamination, not wrong keys.

### Logical findings
Ordering item uniquely determined. «Yalnızca» item needs clearer only-if gloss.

### Pattern findings
`pattern_006` rewritten as candidate `pattern_007` (new ID) to remove factorial prerequisite while preserving numerical answer.

### Verbal findings
Connective (`verbal_005`) and quantifier (`verbal_006`) pass internal review; expert Turkish still pending. `verbal_002` existential fix applied in candidate.

### Spatial findings
Cube item replaced. Map displacement item is text-fair.

### Distractor findings
No invalid-as-correct distractors found. One length-leakage risk already mitigated in v1. All candidate distractors rated acceptable or strong after edits.

### Difficulty review
Honest post-review allocation in candidate: **easy 9 / medium 12 / hard 4** (not forced back to 8/12/5).

### Construct contamination
High: `pattern_006` (mitigated by rewrite → `pattern_007`). Moderate: retired `spatial_003` (replaced by `spatial_007`). Others none/low.

### Turkish language (internal)
`internal_language_review: completed`  
`expert_language_review: pending`
