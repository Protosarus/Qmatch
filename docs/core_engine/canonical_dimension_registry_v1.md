# Canonical Dimension Registry v1

**Status:** Contract freeze (P1A)  
**Scope:** All future assessment scoring, persona prototypes, matching, Firestore, UI, and AI explanation work  
**Dimension count:** exactly **20** = 4 IQ + 10 EQ + 6 Frequency  
**Scale:** continuous scores in `[0.0, 1.0]` when present; missing remains missing  

## Hard rules

1. Do not add a fifth IQ dimension. `numerical` is a **legacy alias / retired construct**, not canonical.
2. Missing dimension evidence must never be invented as `0.5`, `0.42`, or any other neutral filler.
3. Low / mid / high values are **descriptive**, not moral rankings, unless a dimension is an explicit safety floor used only in hard filters (none of the 20 are moral scores).
4. Persona prototypes and matching must reference these exact `dimension_id` values.
5. Legacy JSON / Dart names are aliases only; they must be mapped, not promoted.

## Shared field template

Every dimension below uses:

| Field | Meaning |
|---|---|
| `dimension_id` | Stable snake_case ID |
| Display | TR / EN labels for UI |
| Module | `iq` \| `eq` \| `frequency` |
| Construct | Precise definition |
| Measures / Does not measure | Inclusion / exclusion |
| Low / Mid / High | Interpretation |
| Moral valence | Always **non-moral** for these 20 (no better/worse character) |
| Valid evidence | What items may contribute |
| Misleading evidence | What must not be scored as this construct |
| Min evidence | Minimum independent item contributions before the dimension may enter persona/matching as present |
| Item formats | Allowed response formats |
| Reverse support | Whether reverse-keyed items are allowed |
| Persona / Matching / Expectation-fit | How the dimension may be used |
| Initial reliability | Launch requirement before individual feedback |
| Legacy aliases | Current code/JSON names |

---

## IQ — 4 dimensions

### 1. `logical_reasoning`

| Field | Value |
|---|---|
| TR / EN | Mantıksal muhakeme / Logical reasoning |
| Module | IQ |
| Construct | Multi-step inference from explicit rules, premises, and constraints |
| Measures | Rule application, deduction, consistency checking |
| Does not measure | Wisdom, morality, leadership, empathy, creativity as personality |
| Low | Prefers concrete trial-and-error or associative jumps over rule chains |
| Mid | Uses rules when structure is clear; less reliable under nested constraints |
| High | Comfortable chaining premises to a conclusion |
| Moral valence | Non-moral |
| Valid evidence | Objective MCQ with keyed correct answer; timed optional later |
| Misleading evidence | Opinion items; EQ scenarios; “smart sounding” verbal style alone |
| Min evidence | ≥ 3 keyed items for research signal; ≥ 4 before individual domain feedback |
| Item formats | MCQ objective |
| Reverse support | No (keyed correctness, not Likert reverse) |
| Persona usage | Low-weight cognitive-style contribution only |
| Matching usage | Hard eligibility / soft similarity on cognitive profile when reliability sufficient |
| Expectation-fit | Optional mutual preference for conversation style depth/abstraction later |
| Initial reliability | Domain omega provisional; no percentile claims without norms |
| Legacy aliases | `logic`, `iqStyle[0]` in `persona_profiles_v1.json` |

### 2. `pattern_reasoning`

| Field | Value |
|---|---|
| TR / EN | Örüntü muhakemesi / Pattern reasoning |
| Module | IQ |
| Construct | Detecting regularities, analogies, and abstract relations among elements |
| Measures | Series completion, classification, abstract relation spotting |
| Does not measure | Intuition-as-personality, mystical insight, EQ empathic sensing |
| Low | Focuses on isolated details; misses higher-order structure |
| Mid | Finds simple patterns; struggles with nested/abstract ones |
| High | Extracts structure across variants |
| Moral valence | Non-moral |
| Valid evidence | Objective pattern / matrix / series items |
| Misleading evidence | Aesthetic preference; “I notice vibes” self-report |
| Min evidence | ≥ 3 keyed items; ≥ 4 for feedback |
| Item formats | MCQ objective |
| Reverse support | No |
| Persona / Matching / Expectation | Same policy as other IQ dims |
| Initial reliability | Same as IQ group |
| Legacy aliases | `pattern`, `iqStyle[1]` |

### 3. `verbal_reasoning`

| Field | Value |
|---|---|
| TR / EN | Sözel muhakeme / Verbal reasoning |
| Module | IQ |
| Construct | Language-mediated conceptual discrimination, analogy, and implication |
| Measures | Verbal analogy, meaning distinction, language-based inference |
| Does not measure | Charisma, storytelling personality, bilingual fluency as identity, EQ assertiveness |
| Low | Prefers non-verbal representations; weaker verbal discrimination under load |
| Mid | Handles common verbal relations; weak on subtle distinctions |
| High | Precise verbal relational reasoning |
| Moral valence | Non-moral |
| Valid evidence | Objective verbal MCQ; DIF-monitored across TR/EN |
| Misleading evidence | Eloquence preference; social persuasion items |
| Min evidence | ≥ 3 keyed; ≥ 4 for feedback |
| Item formats | MCQ objective |
| Reverse support | No |
| Persona / Matching / Expectation | IQ policy |
| Initial reliability | Extra TR/EN invariance checks required |
| Legacy aliases | `verbal`, `iqStyle[2]` |

### 4. `spatial_reasoning`

| Field | Value |
|---|---|
| TR / EN | Uzamsal muhakeme / Spatial reasoning |
| Module | IQ |
| Construct | Mental transformation of shapes, positions, and visual relations |
| Measures | Rotation, folding, spatial configuration |
| Does not measure | Artistic taste, fashion sense, athletic skill |
| Low | Prefers sequential/symbolic over mental imagery transforms |
| Mid | Handles simple spatial tasks |
| High | Reliable mental spatial transformation |
| Moral valence | Non-moral |
| Valid evidence | Objective spatial MCQ |
| Misleading evidence | “I am a visual learner” self-report |
| Min evidence | ≥ 3 keyed; ≥ 4 for feedback |
| Item formats | MCQ objective (diagram-capable) |
| Reverse support | No |
| Persona / Matching / Expectation | IQ policy |
| Initial reliability | Device/display fairness checks |
| Legacy aliases | `spatial`, `iqStyle[3]` |

### Retired / non-canonical IQ construct

| Alias | Status | Rule |
|---|---|---|
| `numerical` / `iqStyle[4]` in `persona_profiles_v1.json` | **Retired from canonical 20D** | Must not appear in future prototypes, scoring configs, or Firestore `dimension_scores` keys. Existing JSON vectors that include a 5th IQ slot are **invalid for QRCF v1** until remapped. |

---

## EQ — 10 dimensions

EQ items are **behavioral tendency / trade-off** items. No socially obvious correct answer. Options contribute signed evidence to one or more dimensions.

### 5. `empathy`

| Field | Value |
|---|---|
| TR / EN | Empati / Empathy |
| Module | EQ |
| Construct | Noticing and taking another person’s affective state into account |
| Measures | Affect recognition + consideration in choice |
| Does not measure | Agreeableness-as-virtue, clinical diagnosis, mind-reading accuracy tests |
| Low | Task/self-position first; affect less weighted |
| Mid | Notices affect when cued |
| High | Actively weighs the other’s feelings |
| Moral valence | Non-moral (distance can be adaptive) |
| Valid evidence | Scenario choices prioritizing emotional consideration |
| Misleading evidence | “I am a good person” self-flattery; pure perspective cognition without affect |
| Min evidence | ≥ 4 contributing options across ≥ 3 scenarios |
| Item formats | 4-option SJT / trade-off |
| Reverse support | Yes via opposing behavioral options |
| Persona usage | Primary character signal |
| Matching usage | Similarity / tolerance bands |
| Expectation-fit | Mutual desired emotional attunement |
| Initial reliability | Facet-capable; report only if evidence met |
| Legacy aliases | `empathy` |

### 6. `perspective_taking`

| Field | Value |
|---|---|
| TR / EN | Perspektif alma / Perspective taking |
| Module | EQ |
| Construct | Mentally constructing another viewpoint or interpretive frame |
| Measures | Cognitive perspective shift |
| Does not measure | Empathic affect; persuasion skill |
| Low | Stays in one frame |
| Mid | Can reframe when prompted |
| High | Actively weighs multiple frames |
| Moral valence | Non-moral |
| Valid evidence | Scenarios requiring alternate interpretation |
| Misleading evidence | Debating skill; IQ verbal items |
| Min evidence | ≥ 4 contributions / ≥ 3 scenarios |
| Item formats | SJT / trade-off |
| Reverse support | Yes |
| Persona / Matching / Expectation | Character + conflict communication |
| Legacy aliases | `perspectiveTaking` |

### 7. `self_awareness`

| Field | Value |
|---|---|
| TR / EN | Öz-farkındalık / Self-awareness |
| Module | EQ |
| Construct | Early recognition of own emotion, need, and trigger |
| Measures | Naming/owning internal state before/while acting |
| Does not measure | Rumination, clinical insight, IQ meta-cognition puzzles |
| Low | Discovers state through aftermath |
| Mid | Partial/late recognition |
| High | Early internal labeling |
| Moral valence | Non-moral |
| Valid evidence | Scenarios about noticing own state |
| Misleading evidence | Intellectual self-description without behavioral cost |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | `selfAwareness` |

### 8. `emotion_regulation`

| Field | Value |
|---|---|
| TR / EN | Duygu düzenleme / Emotion regulation |
| Module | EQ |
| Construct | Modulating intensity/timing of emotional response under load |
| Measures | Delay, reappraisal, controlled expression choices |
| Does not measure | Emotional suppression as always-good; alexithymia diagnosis |
| Low | Fast/direct externalization or shutdown extremes without modulation |
| Mid | Situational regulation |
| High | Consistent modulation under intensity |
| Moral valence | Non-moral |
| Valid evidence | High-arousal scenarios |
| Misleading evidence | “I never get angry” desirability |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | `emotionalRegulation` |

### 9. `emotional_openness`

| Field | Value |
|---|---|
| TR / EN | Duygusal açıklık / Emotional openness |
| Module | EQ |
| Construct | Willingness to disclose feelings and needs |
| Measures | Sharing vs privacy preference in relational contexts |
| Does not measure | Frequency `disclosure_pace` (timing/rhythm of disclosure). Keep separate. |
| Low | Selective/private sharing |
| Mid | Context-dependent disclosure |
| High | Visible/direct emotional sharing |
| Moral valence | Non-moral |
| Valid evidence | Disclosure trade-offs |
| Misleading evidence | Oversharing pathology framing |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT / Likert hybrid later |
| Reverse support | Yes |
| Legacy aliases | EQ-side uses of `emotionalOpenness` in profiles must be remapped carefully; live Frequency also uses `emotionalOpenness` as **Frequency** rhythm (see `disclosure_pace`) |

### 10. `boundary_setting`

| Field | Value |
|---|---|
| TR / EN | Sınır koyma / Boundary setting |
| Module | EQ |
| Construct | Protecting self limits and respecting others’ limits |
| Measures | Saying no, limiting access, refusing overreach |
| Does not measure | Coldness, dominance, control |
| Low | Priority on access/closeness flexibility |
| Mid | Situational boundaries |
| High | Clear consistent limits |
| Moral valence | Non-moral |
| Valid evidence | Boundary conflict scenarios |
| Misleading evidence | Aggression disguised as boundaries |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | `boundaries` |

### 11. `assertiveness`

| Field | Value |
|---|---|
| TR / EN | Girişkenlik / Assertiveness |
| Module | EQ |
| Construct | Direct expression of needs/views with initiative |
| Measures | Speaking up, initiating clarity |
| Does not measure | Aggression, leadership identity, social energy |
| Low | Waits/observes; indirect |
| Mid | Asserts in safe contexts |
| High | Direct initiative |
| Moral valence | Non-moral |
| Valid evidence | Speak-up trade-offs |
| Misleading evidence | Dominance contests |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | `assertiveness` |

### 12. `conflict_approach`

| Field | Value |
|---|---|
| TR / EN | Çatışma yaklaşımı / Conflict approach |
| Module | EQ |
| Construct | Orientation toward engaging, structuring, delaying, or distancing in disagreement |
| Measures | Conflict engagement style |
| Does not measure | Who is “right”; violence risk (separate safety) |
| Low | Avoidance/distancing preference |
| Mid | Mixed/contextual |
| High | Direct engagement/structuring of conflict |
| Moral valence | Non-moral |
| Valid evidence | Disagreement scenarios |
| Misleading evidence | Debate IQ; aggression |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | **No exact live alias.** Closest retired/non-canonical profile dims: parts of `adaptability` / assertiveness overlap — must not silently equate |

### 13. `repair_orientation`

| Field | Value |
|---|---|
| TR / EN | Onarım yönelimi / Repair orientation |
| Module | EQ |
| Construct | Tendency to restore connection after rupture |
| Measures | Apology, re-contact, repair attempts |
| Does not measure | Self-erasure; staying in unsafe relationships |
| Low | Distance/closure after rupture |
| Mid | Conditional repair |
| High | Active repair moves |
| Moral valence | Non-moral (safety floors separate) |
| Valid evidence | Rupture scenarios |
| Misleading evidence | “Always forgive” desirability |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | `repairOrientation` |

### 14. `social_awareness`

| Field | Value |
|---|---|
| TR / EN | Sosyal farkındalık / Social awareness |
| Module | EQ |
| Construct | Reading situational tone, reciprocity, and interpersonal timing cues |
| Measures | Context/tone/reciprocity sensitivity |
| Does not measure | Popularity; IQ social knowledge quizzes; empathy affect alone |
| Low | Advances mainly by own rhythm |
| Mid | Notices cues when salient |
| High | Adjusts to tone/timing/reciprocity |
| Moral valence | Non-moral |
| Valid evidence | Multi-party / digital tone scenarios |
| Misleading evidence | Gossip skill; status seeking |
| Min evidence | ≥ 4 / ≥ 3 |
| Item formats | SJT |
| Reverse support | Yes |
| Legacy aliases | **No exact live alias.** Partial conceptual overlap with retired `intuitiveSensitivity` — map only after item blueprint approval |

### EQ constructs present in `persona_profiles_v1.json` but NOT canonical

| Legacy ID | Status | Mapping rule |
|---|---|---|
| `autonomy` | Non-canonical for 20D v1 | Do not score into 20D. May later become values/intent layer, not EQ dimension |
| `adaptability` | Non-canonical for 20D v1 | Do not auto-map to `conflict_approach` |
| `intuitiveSensitivity` | Non-canonical for 20D v1 | Do not auto-map to `social_awareness` or Frequency |

---

## Frequency — 6 dimensions

Frequency measures **connection rhythm**, not character virtue.

### 15. `depth_preference`

| Field | Value |
|---|---|
| TR / EN | Derinlik tercihi / Depth preference |
| Module | Frequency |
| Construct | Preference for meaningful/deep vs light/gradual connection content |
| Low | Light/gradual |
| Mid | Mixed |
| High | Seeks depth early/often |
| Moral valence | Non-moral |
| Valid evidence | Likert + micro-scenario + trade-off about conversation depth |
| Misleading evidence | EQ empathy items |
| Min evidence | ≥ 3 items (≥ 1 reverse recommended) |
| Item formats | Likert 1–5, trade-off, micro-scenario |
| Reverse support | Yes |
| Persona usage | Rhythm signature |
| Matching usage | Usually similarity; large gaps = soft risk / hard band |
| Expectation-fit | Desired depth from partner |
| Legacy aliases | `depth` |

### 16. `social_energy`

| Field | Value |
|---|---|
| TR / EN | Sosyal enerji / Social energy |
| Module | Frequency |
| Construct | Preferred intensity/frequency of social interaction |
| Low | Selective/calm |
| High | Lively/frequent |
| Moral valence | Non-moral |
| Min evidence | ≥ 3 |
| Reverse support | Yes |
| Matching | Tolerance band; extreme mismatch soft risk |
| Legacy aliases | `socialEnergy` |

### 17. `spontaneity`

| Field | Value |
|---|---|
| TR / EN | Spontanlık / Spontaneity |
| Module | Frequency |
| Construct | Comfort with unplanned novelty vs planned predictability |
| Low | Planned |
| High | Spontaneous |
| Moral valence | Non-moral |
| Min evidence | ≥ 3 |
| Reverse support | Yes |
| Matching | Controlled complementarity only after similarity gates |
| Legacy aliases | `spontaneity` |

### 18. `stability`

| Field | Value |
|---|---|
| TR / EN | İstikrar / Stability |
| Module | Frequency |
| Construct | Need for continuity, reliability, and predictable follow-through |
| Low | Novelty/variability tolerance |
| High | Continuity need |
| Moral valence | Non-moral |
| Min evidence | ≥ 3 |
| Reverse support | Yes |
| Matching | High similarity preference |
| Legacy aliases | `stability` |

### 19. `disclosure_pace`

| Field | Value |
|---|---|
| TR / EN | Açılma temposu / Disclosure pace |
| Module | Frequency |
| Construct | How quickly and how much personal/emotional material is shared over time |
| Measures | Pace/volume of disclosure in bonding |
| Does not measure | EQ `emotional_openness` (general willingness). Pace ≠ trait openness alone |
| Low | Slow/selective disclosure rhythm |
| High | Fast/high-volume disclosure rhythm |
| Moral valence | Non-moral |
| Min evidence | ≥ 3 |
| Reverse support | Yes |
| Matching | Similarity + tolerance; large gaps soft risk |
| Legacy aliases | Frequency `emotionalOpenness` in live code/JSON |

### 20. `communication_pace`

| Field | Value |
|---|---|
| TR / EN | İletişim temposu / Communication pace |
| Module | Frequency |
| Construct | Preferred messaging frequency, reply expectancy, silence tolerance |
| Low | Reflective/slow tempo |
| High | Fast/frequent tempo |
| Moral valence | Non-moral |
| Min evidence | ≥ 3 |
| Reverse support | Yes |
| Matching | Strong similarity need; candidate hard-band later |
| Legacy aliases | `conversationPace` |

---

## Cross-check table (canonical ↔ common legacy)

| Canonical ID | Common legacy | Module |
|---|---|---|
| logical_reasoning | logic | IQ |
| pattern_reasoning | pattern | IQ |
| verbal_reasoning | verbal | IQ |
| spatial_reasoning | spatial | IQ |
| *(retired)* | numerical | IQ |
| empathy | empathy | EQ |
| perspective_taking | perspectiveTaking | EQ |
| self_awareness | selfAwareness | EQ |
| emotion_regulation | emotionalRegulation | EQ |
| emotional_openness | *(EQ-side new; avoid Frequency collision)* | EQ |
| boundary_setting | boundaries | EQ |
| assertiveness | assertiveness | EQ |
| conflict_approach | *(new; no safe auto-map)* | EQ |
| repair_orientation | repairOrientation | EQ |
| social_awareness | *(new; no safe auto-map)* | EQ |
| depth_preference | depth | Frequency |
| social_energy | socialEnergy | Frequency |
| spontaneity | spontaneity | Frequency |
| stability | stability | Frequency |
| disclosure_pace | emotionalOpenness (Frequency) | Frequency |
| communication_pace | conversationPace | Frequency |

## Validation checklist

- [x] IQ count = 4  
- [x] EQ count = 10  
- [x] Frequency count = 6  
- [x] Total = 20  
- [x] No fifth IQ dimension in canonical set  
- [x] Missing ≠ fabricated neutral  
- [x] Persona vs matching roles specified  
