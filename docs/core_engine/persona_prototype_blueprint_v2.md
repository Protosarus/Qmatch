# Persona Prototype Blueprint v2 (PROVISIONAL)

**Status:** provisional hypotheses — not validated psychological norms.
**Persona profile version:** `persona_profiles_v2_20d.0`
**Dimension registry:** `canonical_dimension_registry_v1`
**Scoring config:** `persona_scoring_config_v2.0`

This document defines mathematical and behavioral identity for the 18 canonical personas **before** any production `PersonaScoringService`. It is offline-only and must not be loaded by Flutter runtime.

## Non-moral interpretation rules

- Low/high values are descriptive, not defects or virtues.
- Low social energy may mean selective/inward interaction.
- Low spontaneity may mean planning preference.
- High emotional openness does not imply better boundaries.
- High assertiveness does not imply better empathy.
- High stability does not imply better adaptability.
- No persona is better, healthier, smarter, or more valuable than another.

## Group weights (apply after within-group normalization)

- IQ: 0.15
- EQ: 0.3
- Frequency: 0.55

## Canonical dimensions (20)

- IQ (4): logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning
- EQ (10): empathy, perspective_taking, self_awareness, emotion_regulation, emotional_openness, boundary_setting, assertiveness, conflict_approach, repair_orientation, social_awareness
- Frequency (6): depth_preference, social_energy, spontaneity, stability, disclosure_pace, communication_pace

Note: Frequency emotional expression uses `disclosure_pace`. EQ emotional expression uses `emotional_openness`. Do not mix.

## Offline scoring formula (provisional)

For user profile `x` and persona `p`, with evidence weights `q_j`:

1. Group level distance `D_level,p,g` = weighted MSE of `(x_j - t_p,j)` within group `g`.
2. Shape vectors `s_j = x_j - x_bar_g`, `s_p,j = t_p,j - t_bar_p,g`.
3. Group shape distance `D_shape,p,g` = weighted MSE of shape residuals.
4. `D_p,g = 0.65 * D_level + 0.35 * D_shape`.
5. `D_base,p = 0.15*D_IQ + 0.30*D_EQ + 0.55*D_Frequency`.
6. `D_p = D_base + γ*A_p + δ*M_p` (bounded anti-trait and missing-evidence penalties).
7. `S_p = exp(-D_p / T)` — **similarity, not probability**.
8. Confidence is separate (coverage + top-2 margin). Deterministic tie-break by `tie_break_rank` then `persona_id`.

---

## Personas

### `uygulayici` — Uygulayıcı / Executor

1. **persona_id:** `uygulayici`
2. **Turkish display name:** Uygulayıcı
3. **English display name:** Executor
4. **Core definition:** Plans and completes concrete steps with steady rhythm.
5. **Full behavioral definition:** Expresses reliability through follow-through, regulated pacing, and practical assertiveness. Prefers clear next actions over open-ended exploration.
6. **Represents:** Execution consistency, planned delivery, stable decision closure.
7. **Does not represent:** Creative ideation primacy, high improvisation, or protective caregiving focus.
8. **Primary differentiating dimensions:** stability, assertiveness, emotion_regulation
9. **Secondary supporting dimensions:** boundary_setting, communication_pace, logical_reasoning
10. **Approximately neutral dimensions:** pattern_reasoning, verbal_reasoning, spatial_reasoning, empathy, perspective_taking, self_awareness
11. **Anti-traits (provisional):**
    - `stability` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with uygulayici peak on stability.
    - `assertiveness` below 0.31 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with uygulayici peak on assertiveness.
    - `emotion_regulation` below 0.33 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with uygulayici peak on emotion_regulation.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['stability', 'assertiveness', 'emotion_regulation']; total coverage ≥ 0.45
13. **Expected peaks:** stability=0.90, emotion_regulation=0.78, assertiveness=0.76, logical_reasoning=0.72, boundary_setting=0.70
14. **Expected valleys:** spontaneity=0.22, emotional_openness=0.32, disclosure_pace=0.36, empathy=0.40, depth_preference=0.42
15. **Closest competitors:** kararli, stratejist, muhafiz
16. **Separator dimensions vs competitors:**
    - vs `kararli`: spontaneity, communication_pace, logical_reasoning
    - vs `stratejist`: pattern_reasoning, perspective_taking, spontaneity
    - vs `muhafiz`: empathy, conflict_approach, disclosure_pace
17. **Relationship-expression pattern:** Shows care by keeping agreements and reducing uncertainty.
18. **Communication pattern:** Direct, task-oriented, moderate disclosure pace.
19. **Decision-making pattern:** Chooses workable options quickly once criteria are clear.
20. **Stress-expression pattern:** Tightens structure; may reduce spontaneity further.
21. **Typical strengths (descriptive):** Follow-through; Stability under load; Clear action framing
22. **Possible blind spots (descriptive):** May underweight exploratory options; May move before emotional context is shared
23. **Low-confidence conditions:** Missing Frequency stability/spontaneity evidence; Profile mid on both stability and spontaneity; Near-tie with kararli or stratejist
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['stability', 'assertiveness', 'emotion_regulation']; tie_break_rank=1.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.7200 (w=1.1500)
pattern_reasoning: 0.5400 (w=0.8000)
verbal_reasoning: 0.4600 (w=0.7000)
spatial_reasoning: 0.5000 (w=0.7500)
empathy: 0.4000 (w=0.6500)
perspective_taking: 0.4800 (w=0.7000)
self_awareness: 0.6000 (w=0.9000)
emotion_regulation: 0.7800 (w=1.3000)
emotional_openness: 0.3200 (w=0.6000)
boundary_setting: 0.7000 (w=1.1000)
assertiveness: 0.7600 (w=1.3500)
conflict_approach: 0.6000 (w=0.8500)
repair_orientation: 0.5200 (w=0.8000)
social_awareness: 0.5000 (w=0.7500)
depth_preference: 0.4200 (w=0.7000)
social_energy: 0.5800 (w=0.8500)
spontaneity: 0.2200 (w=0.9500)
stability: 0.9000 (w=1.5500)
disclosure_pace: 0.3600 (w=0.6500)
communication_pace: 0.7000 (w=1.1000)
```

</details>

### `koruyucu` — Koruyucu / Guardian

1. **persona_id:** `koruyucu`
2. **Turkish display name:** Koruyucu
3. **English display name:** Guardian
4. **Core definition:** Protects relational safety through empathy, boundaries, and repair.
5. **Full behavioral definition:** Orients toward keeping people safe while remaining emotionally available. Combines care with limit-setting and follow-up after rupture.
6. **Represents:** Protective care, repair after strain, bounded openness.
7. **Does not represent:** Detached enforcement without warmth, or fusion without boundaries.
8. **Primary differentiating dimensions:** empathy, boundary_setting, repair_orientation, stability
9. **Secondary supporting dimensions:** disclosure_pace, depth_preference, perspective_taking
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning, self_awareness, emotion_regulation
11. **Anti-traits (provisional):**
    - `empathy` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with koruyucu peak on empathy.
    - `boundary_setting` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with koruyucu peak on boundary_setting.
    - `repair_orientation` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with koruyucu peak on repair_orientation.
    - `stability` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with koruyucu peak on stability.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['empathy', 'boundary_setting', 'repair_orientation']; total coverage ≥ 0.45
13. **Expected peaks:** empathy=0.88, stability=0.88, repair_orientation=0.84, boundary_setting=0.82, depth_preference=0.80
14. **Expected valleys:** spontaneity=0.24, spatial_reasoning=0.42, pattern_reasoning=0.44, logical_reasoning=0.46, conflict_approach=0.48
15. **Closest competitors:** muhafiz, sifaci, empat
16. **Separator dimensions vs competitors:**
    - vs `muhafiz`: empathy, repair_orientation, disclosure_pace, conflict_approach
    - vs `sifaci`: boundary_setting, assertiveness, conflict_approach
    - vs `empat`: boundary_setting, emotion_regulation, stability
17. **Relationship-expression pattern:** Prioritizes safety, loyalty, and recovery after conflict.
18. **Communication pattern:** Warm, paced disclosure, depth-preferring.
19. **Decision-making pattern:** Weighs impact on others' security before committing.
20. **Stress-expression pattern:** Increases vigilance and boundary emphasis.
21. **Typical strengths (descriptive):** Repair orientation; Boundary clarity with care; Depth preference
22. **Possible blind spots (descriptive):** May over-index on protection vs exploration; May delay decisive confrontation
23. **Low-confidence conditions:** Ambiguous empathy vs muhafiz conflict signature; Weak repair_orientation evidence
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['empathy', 'boundary_setting', 'repair_orientation', 'stability']; tie_break_rank=2.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.4600 (w=0.7000)
pattern_reasoning: 0.4400 (w=0.6500)
verbal_reasoning: 0.5400 (w=0.8500)
spatial_reasoning: 0.4200 (w=0.6000)
empathy: 0.8800 (w=1.5000)
perspective_taking: 0.7200 (w=1.0500)
self_awareness: 0.6600 (w=0.9500)
emotion_regulation: 0.7400 (w=1.0500)
emotional_openness: 0.7400 (w=1.1500)
boundary_setting: 0.8200 (w=1.3500)
assertiveness: 0.5200 (w=0.8000)
conflict_approach: 0.4800 (w=0.7500)
repair_orientation: 0.8400 (w=1.4000)
social_awareness: 0.7000 (w=1.0500)
depth_preference: 0.8000 (w=1.2000)
social_energy: 0.4800 (w=0.8000)
spontaneity: 0.2400 (w=0.8500)
stability: 0.8800 (w=1.4000)
disclosure_pace: 0.7400 (w=1.1500)
communication_pace: 0.5000 (w=0.8000)
```

</details>

### `bilge` — Bilge / Sage

1. **persona_id:** `bilge`
2. **Turkish display name:** Bilge
3. **English display name:** Sage
4. **Core definition:** Integrates perspective-taking and self-awareness into reflective depth.
5. **Full behavioral definition:** Favors meaning-making, verbal nuance, and inward social energy. Decisions emerge from contextual understanding rather than speed.
6. **Represents:** Reflective insight, perspective breadth, depth preference.
7. **Does not represent:** Pure analytic detachment, rapid social leadership, or improvisational flair.
8. **Primary differentiating dimensions:** self_awareness, perspective_taking, depth_preference, verbal_reasoning
9. **Secondary supporting dimensions:** emotion_regulation, verbal_reasoning, social_awareness
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, spatial_reasoning, empathy, emotional_openness, boundary_setting
11. **Anti-traits (provisional):**
    - `self_awareness` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bilge peak on self_awareness.
    - `perspective_taking` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bilge peak on perspective_taking.
    - `depth_preference` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bilge peak on depth_preference.
    - `verbal_reasoning` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bilge peak on verbal_reasoning.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['self_awareness', 'perspective_taking', 'depth_preference']; total coverage ≥ 0.45
13. **Expected peaks:** self_awareness=0.90, perspective_taking=0.88, depth_preference=0.88, verbal_reasoning=0.82, emotion_regulation=0.76
14. **Expected valleys:** social_energy=0.26, spontaneity=0.28, communication_pace=0.28, assertiveness=0.34, conflict_approach=0.44
15. **Closest competitors:** analist, sezgisel, yargic
16. **Separator dimensions vs competitors:**
    - vs `analist`: depth_preference, emotional_openness, self_awareness, logical_reasoning
    - vs `sezgisel`: verbal_reasoning, social_energy, emotion_regulation
    - vs `yargic`: conflict_approach, boundary_setting, emotional_openness
17. **Relationship-expression pattern:** Offers understanding and measured counsel.
18. **Communication pattern:** Slow-paced, depth-first, lower social energy.
19. **Decision-making pattern:** Delays closure until perspectives are integrated.
20. **Stress-expression pattern:** Withdraws into analysis; may reduce assertiveness.
21. **Typical strengths (descriptive):** Perspective taking; Self-awareness; Verbal nuance
22. **Possible blind spots (descriptive):** May under-communicate urgency; May be mistaken for pure analyst
23. **Low-confidence conditions:** High logic with low depth_preference; Near-tie with analist
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['self_awareness', 'perspective_taking', 'depth_preference', 'verbal_reasoning']; tie_break_rank=3.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.6400 (w=0.9500)
pattern_reasoning: 0.6200 (w=0.9000)
verbal_reasoning: 0.8200 (w=1.3500)
spatial_reasoning: 0.4800 (w=0.7000)
empathy: 0.6000 (w=0.9000)
perspective_taking: 0.8800 (w=1.4500)
self_awareness: 0.9000 (w=1.5000)
emotion_regulation: 0.7600 (w=1.1500)
emotional_openness: 0.5600 (w=0.8500)
boundary_setting: 0.5600 (w=0.8500)
assertiveness: 0.3400 (w=0.6500)
conflict_approach: 0.4400 (w=0.7000)
repair_orientation: 0.6200 (w=0.9500)
social_awareness: 0.6400 (w=0.9500)
depth_preference: 0.8800 (w=1.4000)
social_energy: 0.2600 (w=0.8500)
spontaneity: 0.2800 (w=0.8000)
stability: 0.7200 (w=1.0000)
disclosure_pace: 0.5200 (w=0.8500)
communication_pace: 0.2800 (w=0.9000)
```

</details>

### `lider` — Lider / Leader

1. **persona_id:** `lider`
2. **Turkish display name:** Lider
3. **English display name:** Leader
4. **Core definition:** Coordinates people through assertiveness, social awareness, and outward energy.
5. **Full behavioral definition:** Mobilizes others with clear stance and social scanning. Prefers visible coordination over solitary planning.
6. **Represents:** Directional social coordination and assertive conflict engagement.
7. **Does not represent:** Solo execution without social framing, or vision without interpersonal mobilization.
8. **Primary differentiating dimensions:** assertiveness, social_awareness, social_energy, conflict_approach
9. **Secondary supporting dimensions:** verbal_reasoning, communication_pace, perspective_taking
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, spatial_reasoning, empathy, self_awareness, emotion_regulation
11. **Anti-traits (provisional):**
    - `assertiveness` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with lider peak on assertiveness.
    - `social_awareness` below 0.41 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with lider peak on social_awareness.
    - `social_energy` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with lider peak on social_energy.
    - `conflict_approach` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with lider peak on conflict_approach.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['assertiveness', 'social_awareness', 'social_energy']; total coverage ≥ 0.45
13. **Expected peaks:** assertiveness=0.92, social_energy=0.90, social_awareness=0.86, conflict_approach=0.82, communication_pace=0.82
14. **Expected valleys:** disclosure_pace=0.28, spontaneity=0.34, depth_preference=0.38, emotional_openness=0.40, empathy=0.48
15. **Closest competitors:** vizyoner, uygulayici, donusturucu
16. **Separator dimensions vs competitors:**
    - vs `vizyoner`: assertiveness, social_energy, pattern_reasoning, spontaneity
    - vs `uygulayici`: social_awareness, social_energy, stability
    - vs `donusturucu`: stability, repair_orientation, conflict_approach
17. **Relationship-expression pattern:** Initiates structure and clarifies roles.
18. **Communication pattern:** High social energy, faster communication pace.
19. **Decision-making pattern:** Chooses direction and rallies alignment.
20. **Stress-expression pattern:** Increases assertiveness; may compress listening.
21. **Typical strengths (descriptive):** Assertiveness; Social awareness; Conflict approach
22. **Possible blind spots (descriptive):** May outpace quieter partners; May be confused with vizyoner without separator evidence
23. **Low-confidence conditions:** High pattern_reasoning with low social_energy; Near-tie with vizyoner/uygulayici
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['assertiveness', 'social_awareness', 'social_energy', 'conflict_approach']; tie_break_rank=4.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.6600 (w=0.9500)
pattern_reasoning: 0.5600 (w=0.8500)
verbal_reasoning: 0.7200 (w=1.1500)
spatial_reasoning: 0.5000 (w=0.7000)
empathy: 0.4800 (w=0.8500)
perspective_taking: 0.6600 (w=1.0500)
self_awareness: 0.6200 (w=0.9500)
emotion_regulation: 0.6800 (w=1.0000)
emotional_openness: 0.4000 (w=0.7500)
boundary_setting: 0.6800 (w=0.9000)
assertiveness: 0.9200 (w=1.5500)
conflict_approach: 0.8200 (w=1.2500)
repair_orientation: 0.5600 (w=0.9000)
social_awareness: 0.8600 (w=1.4000)
depth_preference: 0.3800 (w=0.8500)
social_energy: 0.9000 (w=1.3500)
spontaneity: 0.3400 (w=0.8500)
stability: 0.7400 (w=0.9500)
disclosure_pace: 0.2800 (w=0.7000)
communication_pace: 0.8200 (w=1.1500)
```

</details>

### `muhafiz` — Muhafız / Sentinel

1. **persona_id:** `muhafiz`
2. **Turkish display name:** Muhafız
3. **English display name:** Sentinel
4. **Core definition:** Defends limits and stability through firm boundaries and conflict stance.
5. **Full behavioral definition:** Prioritizes structure, containment, and rule clarity. Empathy may be present but secondary to perimeter holding.
6. **Represents:** Boundary enforcement, stability, regulated containment.
7. **Does not represent:** Warm protective repair leadership (koruyucu) or nurturing healing focus (sifaci).
8. **Primary differentiating dimensions:** boundary_setting, stability, conflict_approach, assertiveness
9. **Secondary supporting dimensions:** emotion_regulation, logical_reasoning
10. **Approximately neutral dimensions:** pattern_reasoning, verbal_reasoning, spatial_reasoning, empathy, perspective_taking, self_awareness
11. **Anti-traits (provisional):**
    - `boundary_setting` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with muhafiz peak on boundary_setting.
    - `stability` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with muhafiz peak on stability.
    - `conflict_approach` below 0.41 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with muhafiz peak on conflict_approach.
    - `assertiveness` below 0.35 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with muhafiz peak on assertiveness.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['boundary_setting', 'stability', 'conflict_approach']; total coverage ≥ 0.45
13. **Expected peaks:** boundary_setting=0.92, stability=0.92, conflict_approach=0.86, emotion_regulation=0.82, assertiveness=0.80
14. **Expected valleys:** spontaneity=0.18, disclosure_pace=0.24, emotional_openness=0.28, social_energy=0.38, empathy=0.42
15. **Closest competitors:** koruyucu, kararli, yargic
16. **Separator dimensions vs competitors:**
    - vs `koruyucu`: empathy, repair_orientation, disclosure_pace, conflict_approach
    - vs `kararli`: conflict_approach, boundary_setting, spontaneity
    - vs `yargic`: perspective_taking, empathy, disclosure_pace
17. **Relationship-expression pattern:** Creates predictability via clear limits.
18. **Communication pattern:** Low disclosure pace, controlled emotional openness.
19. **Decision-making pattern:** Chooses options that preserve order and thresholds.
20. **Stress-expression pattern:** Hardens boundaries; reduces spontaneity.
21. **Typical strengths (descriptive):** Boundary setting; Stability; Conflict firmness
22. **Possible blind spots (descriptive):** May be read as cold when repair cues are missing; May over-contain
23. **Low-confidence conditions:** High empathy + high repair with low conflict_approach; Near-tie with koruyucu
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['boundary_setting', 'stability', 'conflict_approach', 'assertiveness']; tie_break_rank=5.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.6000 (w=0.8500)
pattern_reasoning: 0.5200 (w=0.7500)
verbal_reasoning: 0.4800 (w=0.7500)
spatial_reasoning: 0.4600 (w=0.7000)
empathy: 0.4200 (w=0.7000)
perspective_taking: 0.5400 (w=0.8000)
self_awareness: 0.6200 (w=0.9000)
emotion_regulation: 0.8200 (w=1.2500)
emotional_openness: 0.2800 (w=0.5500)
boundary_setting: 0.9200 (w=1.5500)
assertiveness: 0.8000 (w=1.3000)
conflict_approach: 0.8600 (w=1.4500)
repair_orientation: 0.4600 (w=0.7500)
social_awareness: 0.5600 (w=0.8500)
depth_preference: 0.5200 (w=0.8500)
social_energy: 0.3800 (w=0.7500)
spontaneity: 0.1800 (w=0.9500)
stability: 0.9200 (w=1.5500)
disclosure_pace: 0.2400 (w=0.7000)
communication_pace: 0.4600 (w=0.8000)
```

</details>

### `sifaci` — Şifacı / Healer

1. **persona_id:** `sifaci`
2. **Turkish display name:** Şifacı
3. **English display name:** Healer
4. **Core definition:** Moves toward others' distress with repair action and regulated care.
5. **Full behavioral definition:** Combines high empathy with active repair orientation and paced disclosure. Differs from empat by action toward recovery and emotion regulation.
6. **Represents:** Care-in-action, repair after distress, supportive depth.
7. **Does not represent:** Passive resonance only, or protective enforcement without healing intent.
8. **Primary differentiating dimensions:** repair_orientation, empathy, disclosure_pace, emotion_regulation
9. **Secondary supporting dimensions:** depth_preference, emotional_openness, perspective_taking
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning, self_awareness, boundary_setting
11. **Anti-traits (provisional):**
    - `repair_orientation` below 0.49 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sifaci peak on repair_orientation.
    - `empathy` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sifaci peak on empathy.
    - `disclosure_pace` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sifaci peak on disclosure_pace.
    - `emotion_regulation` below 0.31 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sifaci peak on emotion_regulation.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['repair_orientation', 'empathy', 'disclosure_pace']; total coverage ≥ 0.45
13. **Expected peaks:** repair_orientation=0.94, empathy=0.90, disclosure_pace=0.84, depth_preference=0.80, emotional_openness=0.78
14. **Expected valleys:** conflict_approach=0.28, assertiveness=0.30, spontaneity=0.30, spatial_reasoning=0.42, logical_reasoning=0.44
15. **Closest competitors:** empat, koruyucu, iletisimci
16. **Separator dimensions vs competitors:**
    - vs `empat`: repair_orientation, emotion_regulation, boundary_setting, stability
    - vs `koruyucu`: assertiveness, boundary_setting, conflict_approach
    - vs `iletisimci`: depth_preference, social_energy, communication_pace
17. **Relationship-expression pattern:** Attends to hurt and seeks restoration.
18. **Communication pattern:** Open disclosure, moderate social energy, depth preference.
19. **Decision-making pattern:** Favors options that restore connection.
20. **Stress-expression pattern:** May over-function in caretaking roles.
21. **Typical strengths (descriptive):** Repair orientation; Empathy; Disclosure willingness
22. **Possible blind spots (descriptive):** Boundaries may lag care impulse; May blur with empat without regulation evidence
23. **Low-confidence conditions:** High empathy with low repair_orientation; Missing emotion_regulation evidence
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['repair_orientation', 'empathy', 'disclosure_pace', 'emotion_regulation']; tie_break_rank=6.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.4400 (w=0.6500)
pattern_reasoning: 0.4600 (w=0.7000)
verbal_reasoning: 0.5600 (w=0.8500)
spatial_reasoning: 0.4200 (w=0.6000)
empathy: 0.9000 (w=1.5000)
perspective_taking: 0.7600 (w=1.1500)
self_awareness: 0.7000 (w=1.0000)
emotion_regulation: 0.7600 (w=1.2000)
emotional_openness: 0.7800 (w=1.2000)
boundary_setting: 0.4800 (w=0.8500)
assertiveness: 0.3000 (w=0.6000)
conflict_approach: 0.2800 (w=0.5500)
repair_orientation: 0.9400 (w=1.6000)
social_awareness: 0.7400 (w=1.1000)
depth_preference: 0.8000 (w=1.2500)
social_energy: 0.4600 (w=0.8000)
spontaneity: 0.3000 (w=0.7500)
stability: 0.7400 (w=1.1000)
disclosure_pace: 0.8400 (w=1.3000)
communication_pace: 0.4400 (w=0.7500)
```

</details>

### `yargic` — Yargıç / Judge

1. **persona_id:** `yargic`
2. **Turkish display name:** Yargıç
3. **English display name:** Judge
4. **Core definition:** Evaluates fairness with perspective-taking, regulation, and conflict clarity.
5. **Full behavioral definition:** Applies standards under emotional control. Social awareness informs judgment without requiring high improvisation.
6. **Represents:** Principled evaluation, regulated conflict stance.
7. **Does not represent:** Pure data analysis without evaluative stance, or warm caregiving primacy.
8. **Primary differentiating dimensions:** perspective_taking, emotion_regulation, conflict_approach, logical_reasoning
9. **Secondary supporting dimensions:** boundary_setting, social_awareness, stability
10. **Approximately neutral dimensions:** pattern_reasoning, verbal_reasoning, spatial_reasoning, empathy, self_awareness, emotional_openness
11. **Anti-traits (provisional):**
    - `perspective_taking` below 0.41 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yargic peak on perspective_taking.
    - `emotion_regulation` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yargic peak on emotion_regulation.
    - `conflict_approach` below 0.35 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yargic peak on conflict_approach.
    - `logical_reasoning` below 0.33 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yargic peak on logical_reasoning.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['perspective_taking', 'emotion_regulation', 'conflict_approach']; total coverage ≥ 0.45
13. **Expected peaks:** emotion_regulation=0.88, perspective_taking=0.86, boundary_setting=0.82, conflict_approach=0.80, stability=0.80
14. **Expected valleys:** spontaneity=0.20, emotional_openness=0.24, disclosure_pace=0.26, social_energy=0.34, communication_pace=0.38
15. **Closest competitors:** analist, muhafiz, bilge
16. **Separator dimensions vs competitors:**
    - vs `analist`: conflict_approach, social_awareness, boundary_setting
    - vs `muhafiz`: perspective_taking, empathy, logical_reasoning
    - vs `bilge`: conflict_approach, depth_preference, emotional_openness
17. **Relationship-expression pattern:** Seeks fairness and clear accountability.
18. **Communication pattern:** Measured disclosure, moderate pace.
19. **Decision-making pattern:** Applies criteria and closes with justification.
20. **Stress-expression pattern:** Increases evaluative rigidity.
21. **Typical strengths (descriptive):** Perspective taking; Emotion regulation; Conflict clarity
22. **Possible blind spots (descriptive):** May underweight emotional openness; May confuse with analist
23. **Low-confidence conditions:** High logic with low conflict_approach; Near-tie with analist
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['perspective_taking', 'emotion_regulation', 'conflict_approach', 'logical_reasoning']; tie_break_rank=7.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.7800 (w=1.2500)
pattern_reasoning: 0.6800 (w=1.0500)
verbal_reasoning: 0.7000 (w=1.1000)
spatial_reasoning: 0.4800 (w=0.7000)
empathy: 0.4200 (w=0.7500)
perspective_taking: 0.8600 (w=1.4000)
self_awareness: 0.7400 (w=1.1000)
emotion_regulation: 0.8800 (w=1.4000)
emotional_openness: 0.2400 (w=0.5500)
boundary_setting: 0.8200 (w=1.2500)
assertiveness: 0.6800 (w=1.0000)
conflict_approach: 0.8000 (w=1.3000)
repair_orientation: 0.5000 (w=0.8500)
social_awareness: 0.7400 (w=1.1500)
depth_preference: 0.7000 (w=0.9000)
social_energy: 0.3400 (w=0.7500)
spontaneity: 0.2000 (w=0.8000)
stability: 0.8000 (w=1.1500)
disclosure_pace: 0.2600 (w=0.6000)
communication_pace: 0.3800 (w=0.7500)
```

</details>

### `empat` — Empat / Empath

1. **persona_id:** `empat`
2. **Turkish display name:** Empat
3. **English display name:** Empath
4. **Core definition:** Resonates with others' affect through empathy and emotional openness.
5. **Full behavioral definition:** High felt attunement and disclosure. Separation from sifaci uses repair action, regulation, and boundaries rather than empathy alone.
6. **Represents:** Affective resonance and open emotional signaling.
7. **Does not represent:** Structured healing action primacy or high-assertiveness leadership.
8. **Primary differentiating dimensions:** empathy, emotional_openness, disclosure_pace, social_awareness
9. **Secondary supporting dimensions:** depth_preference, perspective_taking, repair_orientation
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning, self_awareness, emotion_regulation
11. **Anti-traits (provisional):**
    - `empathy` below 0.49 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with empat peak on empathy.
    - `emotional_openness` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with empat peak on emotional_openness.
    - `disclosure_pace` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with empat peak on disclosure_pace.
    - `social_awareness` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with empat peak on social_awareness.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['empathy', 'emotional_openness', 'disclosure_pace']; total coverage ≥ 0.45
13. **Expected peaks:** empathy=0.94, emotional_openness=0.90, disclosure_pace=0.88, perspective_taking=0.82, social_awareness=0.82
14. **Expected valleys:** assertiveness=0.28, conflict_approach=0.30, boundary_setting=0.32, emotion_regulation=0.36, logical_reasoning=0.40
15. **Closest competitors:** sifaci, iletisimci, sezgisel
16. **Separator dimensions vs competitors:**
    - vs `sifaci`: repair_orientation, emotion_regulation, boundary_setting, emotional_openness
    - vs `iletisimci`: empathy, depth_preference, social_energy, communication_pace
    - vs `sezgisel`: disclosure_pace, assertiveness, pattern_reasoning
17. **Relationship-expression pattern:** Mirrors and validates feeling states.
18. **Communication pattern:** High disclosure pace, emotionally open.
19. **Decision-making pattern:** Feels into options; may delay hard closure.
20. **Stress-expression pattern:** Absorption of others' affect; regulation may drop.
21. **Typical strengths (descriptive):** Empathy; Emotional openness; Social awareness
22. **Possible blind spots (descriptive):** Boundary lag; Repair may be under-specified
23. **Low-confidence conditions:** High repair_orientation + regulation resembling sifaci; Missing disclosure_pace evidence
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['empathy', 'emotional_openness', 'disclosure_pace', 'social_awareness']; tie_break_rank=8.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.4000 (w=0.6000)
pattern_reasoning: 0.4600 (w=0.7000)
verbal_reasoning: 0.5800 (w=0.9000)
spatial_reasoning: 0.4200 (w=0.6000)
empathy: 0.9400 (w=1.6000)
perspective_taking: 0.8200 (w=1.2500)
self_awareness: 0.7200 (w=1.0500)
emotion_regulation: 0.3600 (w=0.7500)
emotional_openness: 0.9000 (w=1.4500)
boundary_setting: 0.3200 (w=0.7000)
assertiveness: 0.2800 (w=0.5500)
conflict_approach: 0.3000 (w=0.5500)
repair_orientation: 0.6600 (w=1.0500)
social_awareness: 0.8200 (w=1.2500)
depth_preference: 0.7600 (w=1.1500)
social_energy: 0.5200 (w=0.8500)
spontaneity: 0.4600 (w=0.8000)
stability: 0.4600 (w=0.8000)
disclosure_pace: 0.8800 (w=1.4000)
communication_pace: 0.5000 (w=0.8000)
```

</details>

### `cesur` — Cesur / Brave

1. **persona_id:** `cesur`
2. **Turkish display name:** Cesur
3. **English display name:** Brave
4. **Core definition:** Engages risk and conflict with high spontaneity and assertiveness.
5. **Full behavioral definition:** Moves quickly into uncertain situations. Differs from kararli by low stability and high improvisation rather than grit alone.
6. **Represents:** Approach under uncertainty, bold conflict engagement.
7. **Does not represent:** Long-horizon stability planning or quiet independent withdrawal.
8. **Primary differentiating dimensions:** spontaneity, assertiveness, conflict_approach, social_energy
9. **Secondary supporting dimensions:** spatial_reasoning, communication_pace, emotional_openness
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, verbal_reasoning, empathy, perspective_taking, self_awareness
11. **Anti-traits (provisional):**
    - `spontaneity` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with cesur peak on spontaneity.
    - `assertiveness` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with cesur peak on assertiveness.
    - `conflict_approach` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with cesur peak on conflict_approach.
    - `social_energy` below 0.33 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with cesur peak on social_energy.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['spontaneity', 'assertiveness', 'conflict_approach']; total coverage ≥ 0.45
13. **Expected peaks:** spontaneity=0.90, assertiveness=0.88, conflict_approach=0.82, social_energy=0.78, communication_pace=0.74
14. **Expected valleys:** stability=0.26, emotion_regulation=0.34, boundary_setting=0.38, empathy=0.42, repair_orientation=0.44
15. **Closest competitors:** kararli, donusturucu, lider
16. **Separator dimensions vs competitors:**
    - vs `kararli`: spontaneity, stability, emotion_regulation
    - vs `donusturucu`: repair_orientation, social_awareness, stability
    - vs `lider`: social_awareness, stability, spontaneity
17. **Relationship-expression pattern:** Initiates intensity and novelty.
18. **Communication pattern:** Fast pace, high social energy, spontaneous turns.
19. **Decision-making pattern:** Commits under incomplete information.
20. **Stress-expression pattern:** Accelerates; may reduce regulation.
21. **Typical strengths (descriptive):** Spontaneity; Assertiveness; Conflict approach
22. **Possible blind spots (descriptive):** Stability may be underweighted; May confuse with kararli without stability evidence
23. **Low-confidence conditions:** High stability with low spontaneity; Near-tie with kararli
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['spontaneity', 'assertiveness', 'conflict_approach', 'social_energy']; tie_break_rank=9.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.5200 (w=0.8000)
pattern_reasoning: 0.5400 (w=0.8500)
verbal_reasoning: 0.5000 (w=0.7500)
spatial_reasoning: 0.6400 (w=1.0000)
empathy: 0.4200 (w=0.7000)
perspective_taking: 0.4800 (w=0.7500)
self_awareness: 0.5200 (w=0.8000)
emotion_regulation: 0.3400 (w=0.7000)
emotional_openness: 0.5600 (w=0.9000)
boundary_setting: 0.3800 (w=0.7000)
assertiveness: 0.8800 (w=1.4500)
conflict_approach: 0.8200 (w=1.3500)
repair_orientation: 0.4400 (w=0.7000)
social_awareness: 0.5800 (w=0.9000)
depth_preference: 0.4600 (w=0.7500)
social_energy: 0.7800 (w=1.2000)
spontaneity: 0.9000 (w=1.5500)
stability: 0.2600 (w=0.8500)
disclosure_pace: 0.5400 (w=0.8500)
communication_pace: 0.7400 (w=1.1000)
```

</details>

### `kararli` — Kararlı / Determined

1. **persona_id:** `kararli`
2. **Turkish display name:** Kararlı
3. **English display name:** Determined
4. **Core definition:** Holds course through stability, regulation, and assertive persistence.
5. **Full behavioral definition:** Persistence without requiring improvisation. Differs from cesur via high stability and low spontaneity.
6. **Represents:** Endurance, regulated persistence, planned firmness.
7. **Does not represent:** Thrill-seeking spontaneity or visionary pattern leaps.
8. **Primary differentiating dimensions:** stability, emotion_regulation, assertiveness
9. **Secondary supporting dimensions:** logical_reasoning, boundary_setting, communication_pace
10. **Approximately neutral dimensions:** pattern_reasoning, verbal_reasoning, spatial_reasoning, empathy, perspective_taking, self_awareness
11. **Anti-traits (provisional):**
    - `stability` below 0.49 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with kararli peak on stability.
    - `emotion_regulation` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with kararli peak on emotion_regulation.
    - `assertiveness` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with kararli peak on assertiveness.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['stability', 'emotion_regulation', 'assertiveness']; total coverage ≥ 0.45
13. **Expected peaks:** stability=0.94, emotion_regulation=0.84, assertiveness=0.82, boundary_setting=0.72, logical_reasoning=0.70
14. **Expected valleys:** spontaneity=0.16, emotional_openness=0.34, disclosure_pace=0.34, empathy=0.44, social_energy=0.46
15. **Closest competitors:** cesur, uygulayici, muhafiz
16. **Separator dimensions vs competitors:**
    - vs `cesur`: spontaneity, stability, emotion_regulation
    - vs `uygulayici`: communication_pace, logical_reasoning, spontaneity
    - vs `muhafiz`: conflict_approach, disclosure_pace, empathy
17. **Relationship-expression pattern:** Provides reliability and consistent stance.
18. **Communication pattern:** Steady pace, moderate disclosure.
19. **Decision-making pattern:** Locks decision and maintains it.
20. **Stress-expression pattern:** Doubles down on plan; reduces flexibility.
21. **Typical strengths (descriptive):** Stability; Emotion regulation; Assertiveness
22. **Possible blind spots (descriptive):** May under-adapt; May resemble uygulayici
23. **Low-confidence conditions:** High spontaneity profiles; Near-tie with cesur/uygulayici
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['stability', 'emotion_regulation', 'assertiveness']; tie_break_rank=10.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.7000 (w=1.0500)
pattern_reasoning: 0.5800 (w=0.8500)
verbal_reasoning: 0.5000 (w=0.7500)
spatial_reasoning: 0.4800 (w=0.7000)
empathy: 0.4400 (w=0.7000)
perspective_taking: 0.5200 (w=0.8000)
self_awareness: 0.6400 (w=0.9500)
emotion_regulation: 0.8400 (w=1.3500)
emotional_openness: 0.3400 (w=0.6500)
boundary_setting: 0.7200 (w=1.1500)
assertiveness: 0.8200 (w=1.3000)
conflict_approach: 0.6400 (w=0.9500)
repair_orientation: 0.5000 (w=0.8000)
social_awareness: 0.5400 (w=0.8500)
depth_preference: 0.5000 (w=0.8000)
social_energy: 0.4600 (w=0.8000)
spontaneity: 0.1600 (w=1.0000)
stability: 0.9400 (w=1.6000)
disclosure_pace: 0.3400 (w=0.6500)
communication_pace: 0.6000 (w=0.9500)
```

</details>

### `vizyoner` — Vizyoner / Visionary

1. **persona_id:** `vizyoner`
2. **Turkish display name:** Vizyoner
3. **English display name:** Visionary
4. **Core definition:** Projects pattern-based futures with verbal framing and flexible spontaneity.
5. **Full behavioral definition:** Sees trajectories and narrates them. Differs from lider by pattern/verbal vision weight over social mobilization.
6. **Represents:** Future patterning, narrative foresight, exploratory spontaneity.
7. **Does not represent:** Day-to-day execution primacy or enforcement of boundaries.
8. **Primary differentiating dimensions:** pattern_reasoning, verbal_reasoning, perspective_taking, spontaneity
9. **Secondary supporting dimensions:** depth_preference, social_awareness, assertiveness
10. **Approximately neutral dimensions:** logical_reasoning, spatial_reasoning, empathy, self_awareness, emotion_regulation, emotional_openness
11. **Anti-traits (provisional):**
    - `pattern_reasoning` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with vizyoner peak on pattern_reasoning.
    - `verbal_reasoning` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with vizyoner peak on verbal_reasoning.
    - `perspective_taking` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with vizyoner peak on perspective_taking.
    - `spontaneity` below 0.35 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with vizyoner peak on spontaneity.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['pattern_reasoning', 'verbal_reasoning', 'perspective_taking']; total coverage ≥ 0.45
13. **Expected peaks:** pattern_reasoning=0.88, perspective_taking=0.84, depth_preference=0.84, verbal_reasoning=0.82, spontaneity=0.80
14. **Expected valleys:** stability=0.24, boundary_setting=0.38, emotion_regulation=0.44, disclosure_pace=0.48, empathy=0.50
15. **Closest competitors:** lider, yaratici, stratejist
16. **Separator dimensions vs competitors:**
    - vs `lider`: assertiveness, social_energy, pattern_reasoning, spontaneity
    - vs `yaratici`: spatial_reasoning, emotional_openness, perspective_taking
    - vs `stratejist`: spontaneity, stability, assertiveness
17. **Relationship-expression pattern:** Invites shared future images.
18. **Communication pattern:** Idea-forward, variable pace, moderate-high disclosure.
19. **Decision-making pattern:** Chooses direction from pattern insight.
20. **Stress-expression pattern:** Escapes into possibilities; stability may drop.
21. **Typical strengths (descriptive):** Pattern reasoning; Verbal framing; Perspective taking
22. **Possible blind spots (descriptive):** Execution gaps; May confuse with lider/yaratici
23. **Low-confidence conditions:** High assertiveness+social_energy without pattern peaks; Near-tie with lider
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['pattern_reasoning', 'verbal_reasoning', 'perspective_taking', 'spontaneity']; tie_break_rank=11.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.5800 (w=0.9500)
pattern_reasoning: 0.8800 (w=1.4500)
verbal_reasoning: 0.8200 (w=1.3000)
spatial_reasoning: 0.6000 (w=0.8500)
empathy: 0.5000 (w=0.8000)
perspective_taking: 0.8400 (w=1.3000)
self_awareness: 0.7400 (w=1.1000)
emotion_regulation: 0.4400 (w=0.8000)
emotional_openness: 0.6200 (w=0.9000)
boundary_setting: 0.3800 (w=0.7000)
assertiveness: 0.6600 (w=1.0000)
conflict_approach: 0.5200 (w=0.8500)
repair_orientation: 0.5400 (w=0.8500)
social_awareness: 0.6800 (w=1.0000)
depth_preference: 0.8400 (w=1.1500)
social_energy: 0.6200 (w=0.9500)
spontaneity: 0.8000 (w=1.1500)
stability: 0.2400 (w=0.8000)
disclosure_pace: 0.4800 (w=0.8500)
communication_pace: 0.5600 (w=0.9000)
```

</details>

### `yaratici` — Yaratıcı / Creator

1. **persona_id:** `yaratici`
2. **Turkish display name:** Yaratıcı
3. **English display name:** Creator
4. **Core definition:** Generates novel forms via pattern/spatial play and spontaneity.
5. **Full behavioral definition:** Explores through making. Differs from donusturucu by generative craft over conflict-driven change leadership.
6. **Represents:** Novelty generation, aesthetic/spatial play, improvisation.
7. **Does not represent:** Organizational transformation leadership or solitary boundary primacy.
8. **Primary differentiating dimensions:** spontaneity, pattern_reasoning, spatial_reasoning, emotional_openness
9. **Secondary supporting dimensions:** disclosure_pace, depth_preference, social_awareness
10. **Approximately neutral dimensions:** logical_reasoning, verbal_reasoning, empathy, perspective_taking, self_awareness, emotion_regulation
11. **Anti-traits (provisional):**
    - `spontaneity` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yaratici peak on spontaneity.
    - `pattern_reasoning` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yaratici peak on pattern_reasoning.
    - `spatial_reasoning` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yaratici peak on spatial_reasoning.
    - `emotional_openness` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with yaratici peak on emotional_openness.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['spontaneity', 'pattern_reasoning', 'spatial_reasoning']; total coverage ≥ 0.45
13. **Expected peaks:** spontaneity=0.92, pattern_reasoning=0.84, spatial_reasoning=0.82, emotional_openness=0.82, disclosure_pace=0.78
14. **Expected valleys:** stability=0.22, boundary_setting=0.30, emotion_regulation=0.38, conflict_approach=0.42, logical_reasoning=0.46
15. **Closest competitors:** donusturucu, sezgisel, vizyoner
16. **Separator dimensions vs competitors:**
    - vs `donusturucu`: spatial_reasoning, conflict_approach, assertiveness, spontaneity
    - vs `sezgisel`: spatial_reasoning, social_awareness, assertiveness
    - vs `vizyoner`: spatial_reasoning, verbal_reasoning, stability
17. **Relationship-expression pattern:** Connects through shared making and discovery.
18. **Communication pattern:** Associative, disclosure may be medium-high.
19. **Decision-making pattern:** Prototypes options rather than closing early.
20. **Stress-expression pattern:** Scatters into alternatives.
21. **Typical strengths (descriptive):** Spontaneity; Pattern/spatial reasoning; Emotional openness
22. **Possible blind spots (descriptive):** Stability valleys; May confuse with donusturucu/sezgisel
23. **Low-confidence conditions:** High conflict_approach without generative peaks; Near-tie with donusturucu
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['spontaneity', 'pattern_reasoning', 'spatial_reasoning', 'emotional_openness']; tie_break_rank=12.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.4600 (w=0.8000)
pattern_reasoning: 0.8400 (w=1.3500)
verbal_reasoning: 0.5400 (w=0.9000)
spatial_reasoning: 0.8200 (w=1.3000)
empathy: 0.5200 (w=0.8500)
perspective_taking: 0.5800 (w=0.9500)
self_awareness: 0.6800 (w=0.9500)
emotion_regulation: 0.3800 (w=0.7500)
emotional_openness: 0.8200 (w=1.2000)
boundary_setting: 0.3000 (w=0.6500)
assertiveness: 0.4800 (w=0.8500)
conflict_approach: 0.4200 (w=0.8000)
repair_orientation: 0.5000 (w=0.8500)
social_awareness: 0.5600 (w=0.9000)
depth_preference: 0.7200 (w=0.9500)
social_energy: 0.5400 (w=0.9000)
spontaneity: 0.9200 (w=1.4500)
stability: 0.2200 (w=0.7500)
disclosure_pace: 0.7800 (w=1.1500)
communication_pace: 0.5000 (w=0.8500)
```

</details>

### `iletisimci` — İletişimci / Communicator

1. **persona_id:** `iletisimci`
2. **Turkish display name:** İletişimci
3. **English display name:** Communicator
4. **Core definition:** Keeps interaction flowing via verbal skill, social energy, and pace.
5. **Full behavioral definition:** Bridge-building talk and tempo. Differs from empat by social/communication energy over affective absorption.
6. **Represents:** Conversational bridging, high social energy, fast communication pace.
7. **Does not represent:** Silent depth solitude or pure empathic absorption.
8. **Primary differentiating dimensions:** communication_pace, social_energy, verbal_reasoning, social_awareness
9. **Secondary supporting dimensions:** emotional_openness, assertiveness, disclosure_pace
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, spatial_reasoning, empathy, perspective_taking, self_awareness
11. **Anti-traits (provisional):**
    - `communication_pace` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with iletisimci peak on communication_pace.
    - `social_energy` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with iletisimci peak on social_energy.
    - `verbal_reasoning` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with iletisimci peak on verbal_reasoning.
    - `social_awareness` below 0.41 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with iletisimci peak on social_awareness.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['communication_pace', 'social_energy', 'verbal_reasoning']; total coverage ≥ 0.45
13. **Expected peaks:** social_energy=0.92, communication_pace=0.92, verbal_reasoning=0.88, social_awareness=0.86, emotional_openness=0.78
14. **Expected valleys:** depth_preference=0.34, stability=0.40, boundary_setting=0.42, spatial_reasoning=0.44, logical_reasoning=0.48
15. **Closest competitors:** empat, lider, donusturucu
16. **Separator dimensions vs competitors:**
    - vs `empat`: empathy, depth_preference, social_energy, communication_pace
    - vs `lider`: depth_preference, stability, conflict_approach
    - vs `donusturucu`: stability, conflict_approach, depth_preference
17. **Relationship-expression pattern:** Maintains contact and clarifies messages.
18. **Communication pattern:** High pace, high social energy, open disclosure.
19. **Decision-making pattern:** Talks options into clarity with others.
20. **Stress-expression pattern:** Over-talks; depth may thin.
21. **Typical strengths (descriptive):** Communication pace; Verbal reasoning; Social awareness
22. **Possible blind spots (descriptive):** Depth preference may lag; May confuse with empat
23. **Low-confidence conditions:** High empathy/depth with low social_energy; Near-tie with empat
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['communication_pace', 'social_energy', 'verbal_reasoning', 'social_awareness']; tie_break_rank=13.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.4800 (w=0.7500)
pattern_reasoning: 0.5000 (w=0.7500)
verbal_reasoning: 0.8800 (w=1.5000)
spatial_reasoning: 0.4400 (w=0.6500)
empathy: 0.6800 (w=1.0000)
perspective_taking: 0.7000 (w=1.0500)
self_awareness: 0.5800 (w=0.9000)
emotion_regulation: 0.5200 (w=0.8500)
emotional_openness: 0.7800 (w=1.2000)
boundary_setting: 0.4200 (w=0.7000)
assertiveness: 0.7400 (w=1.1500)
conflict_approach: 0.5200 (w=0.8000)
repair_orientation: 0.6000 (w=0.9500)
social_awareness: 0.8600 (w=1.4000)
depth_preference: 0.3400 (w=0.7000)
social_energy: 0.9200 (w=1.5000)
spontaneity: 0.6800 (w=1.0500)
stability: 0.4000 (w=0.7500)
disclosure_pace: 0.7600 (w=1.1500)
communication_pace: 0.9200 (w=1.5500)
```

</details>

### `analist` — Analist / Analyst

1. **persona_id:** `analist`
2. **Turkish display name:** Analist
3. **English display name:** Analyst
4. **Core definition:** Structures reality through logical and pattern reasoning with regulated affect.
5. **Full behavioral definition:** Evidence-first, lower emotional openness. Differs from bilge by cognitive structure over reflective depth/self-awareness primacy.
6. **Represents:** Analytical structuring, regulated evaluation of information.
7. **Does not represent:** Warm interpretive counsel primacy or assertive social leadership.
8. **Primary differentiating dimensions:** logical_reasoning, pattern_reasoning, emotion_regulation
9. **Secondary supporting dimensions:** perspective_taking, self_awareness, stability
10. **Approximately neutral dimensions:** verbal_reasoning, spatial_reasoning, empathy, emotional_openness, boundary_setting, assertiveness
11. **Anti-traits (provisional):**
    - `logical_reasoning` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with analist peak on logical_reasoning.
    - `pattern_reasoning` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with analist peak on pattern_reasoning.
    - `emotion_regulation` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with analist peak on emotion_regulation.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['logical_reasoning', 'pattern_reasoning', 'emotion_regulation']; total coverage ≥ 0.45
13. **Expected peaks:** logical_reasoning=0.92, pattern_reasoning=0.90, emotion_regulation=0.82, perspective_taking=0.76, self_awareness=0.70
14. **Expected valleys:** spontaneity=0.20, emotional_openness=0.24, disclosure_pace=0.26, social_energy=0.28, empathy=0.34
15. **Closest competitors:** bilge, yargic, stratejist
16. **Separator dimensions vs competitors:**
    - vs `bilge`: depth_preference, emotional_openness, logical_reasoning, self_awareness
    - vs `yargic`: conflict_approach, social_awareness, pattern_reasoning
    - vs `stratejist`: assertiveness, stability, spontaneity
17. **Relationship-expression pattern:** Offers clarity via structure and evidence.
18. **Communication pattern:** Lower disclosure pace, lower social energy.
19. **Decision-making pattern:** Computes tradeoffs before closing.
20. **Stress-expression pattern:** Narrows to data; openness drops.
21. **Typical strengths (descriptive):** Logical/pattern reasoning; Emotion regulation
22. **Possible blind spots (descriptive):** Emotional openness valleys; May confuse with bilge/yargic/stratejist
23. **Low-confidence conditions:** High depth_preference + self_awareness like bilge; Near-tie with bilge
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['logical_reasoning', 'pattern_reasoning', 'emotion_regulation']; tie_break_rank=14.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.9200 (w=1.5500)
pattern_reasoning: 0.9000 (w=1.5000)
verbal_reasoning: 0.6600 (w=1.0500)
spatial_reasoning: 0.5800 (w=0.8500)
empathy: 0.3400 (w=0.6000)
perspective_taking: 0.7600 (w=1.2000)
self_awareness: 0.7000 (w=1.0500)
emotion_regulation: 0.8200 (w=1.3000)
emotional_openness: 0.2400 (w=0.5000)
boundary_setting: 0.6400 (w=0.9500)
assertiveness: 0.4400 (w=0.7000)
conflict_approach: 0.4800 (w=0.8000)
repair_orientation: 0.4000 (w=0.7000)
social_awareness: 0.5200 (w=0.8000)
depth_preference: 0.6200 (w=0.9000)
social_energy: 0.2800 (w=0.7500)
spontaneity: 0.2000 (w=0.8000)
stability: 0.6800 (w=1.0000)
disclosure_pace: 0.2600 (w=0.5500)
communication_pace: 0.3400 (w=0.7000)
```

</details>

### `donusturucu` — Dönüştürücü / Transformer

1. **persona_id:** `donusturucu`
2. **Turkish display name:** Dönüştürücü
3. **English display name:** Transformer
4. **Core definition:** Drives change through conflict approach, assertiveness, and social awareness.
5. **Full behavioral definition:** Turns systems by confronting stuck patterns. Differs from yaratici by change leadership over generative craft.
6. **Represents:** Transformative confrontation and mobilizing change.
7. **Does not represent:** Quiet craft novelty or protective conservation.
8. **Primary differentiating dimensions:** conflict_approach, assertiveness, spontaneity, social_awareness
9. **Secondary supporting dimensions:** repair_orientation, social_energy, emotional_openness
10. **Approximately neutral dimensions:** logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning, empathy, perspective_taking
11. **Anti-traits (provisional):**
    - `conflict_approach` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with donusturucu peak on conflict_approach.
    - `assertiveness` below 0.41 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with donusturucu peak on assertiveness.
    - `spontaneity` below 0.43 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with donusturucu peak on spontaneity.
    - `social_awareness` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with donusturucu peak on social_awareness.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['conflict_approach', 'assertiveness', 'spontaneity']; total coverage ≥ 0.45
13. **Expected peaks:** conflict_approach=0.90, spontaneity=0.88, assertiveness=0.86, social_awareness=0.82, repair_orientation=0.76
14. **Expected valleys:** stability=0.18, boundary_setting=0.40, emotion_regulation=0.46, spatial_reasoning=0.52, logical_reasoning=0.56
15. **Closest competitors:** yaratici, lider, cesur
16. **Separator dimensions vs competitors:**
    - vs `yaratici`: conflict_approach, assertiveness, spatial_reasoning, repair_orientation
    - vs `lider`: stability, spontaneity, repair_orientation
    - vs `cesur`: repair_orientation, social_awareness, stability
17. **Relationship-expression pattern:** Challenges patterns that block growth.
18. **Communication pattern:** Direct, energetic, repair may follow rupture.
19. **Decision-making pattern:** Chooses disruptive-but-aimed moves.
20. **Stress-expression pattern:** Pushes harder; stability drops.
21. **Typical strengths (descriptive):** Conflict approach; Assertiveness; Social awareness
22. **Possible blind spots (descriptive):** May underweight stability needs; May confuse with yaratici/lider
23. **Low-confidence conditions:** High spatial/spontaneity without conflict peaks; Near-tie with yaratici
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['conflict_approach', 'assertiveness', 'spontaneity', 'social_awareness']; tie_break_rank=15.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.5600 (w=0.8500)
pattern_reasoning: 0.6600 (w=0.9500)
verbal_reasoning: 0.6400 (w=0.9500)
spatial_reasoning: 0.5200 (w=0.8000)
empathy: 0.5600 (w=0.9500)
perspective_taking: 0.6600 (w=1.0000)
self_awareness: 0.6000 (w=0.9500)
emotion_regulation: 0.4600 (w=0.8500)
emotional_openness: 0.6800 (w=1.0000)
boundary_setting: 0.4000 (w=0.7500)
assertiveness: 0.8600 (w=1.4000)
conflict_approach: 0.9000 (w=1.5000)
repair_orientation: 0.7600 (w=1.2000)
social_awareness: 0.8200 (w=1.2500)
depth_preference: 0.7000 (w=0.9000)
social_energy: 0.7600 (w=1.1000)
spontaneity: 0.8800 (w=1.2500)
stability: 0.1800 (w=0.8000)
disclosure_pace: 0.6800 (w=0.9500)
communication_pace: 0.7400 (w=1.0500)
```

</details>

### `bagimsiz` — Bağımsız / Independent

1. **persona_id:** `bagimsiz`
2. **Turkish display name:** Bağımsız
3. **English display name:** Independent
4. **Core definition:** Preserves autonomy via boundaries, self-awareness, and selective social energy.
5. **Full behavioral definition:** Self-directed with low social energy. Differs from sezgisel by boundary/assertiveness autonomy over social-awareness intuition.
6. **Represents:** Autonomous self-direction and selective engagement.
7. **Does not represent:** Fused empathic openness or high social orchestration.
8. **Primary differentiating dimensions:** boundary_setting, self_awareness, assertiveness, social_energy
9. **Secondary supporting dimensions:** emotion_regulation, stability, logical_reasoning
10. **Approximately neutral dimensions:** pattern_reasoning, verbal_reasoning, spatial_reasoning, empathy, perspective_taking, emotional_openness
11. **Anti-traits (provisional):**
    - `boundary_setting` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bagimsiz peak on boundary_setting.
    - `self_awareness` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bagimsiz peak on self_awareness.
    - `assertiveness` below 0.33 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with bagimsiz peak on assertiveness.
    - `social_energy` above 0.56 (severity 0.3; min evidence 2) — PROVISIONAL: strongly conflicts with bagimsiz valley on social_energy.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['boundary_setting', 'self_awareness', 'assertiveness']; total coverage ≥ 0.45
13. **Expected peaks:** boundary_setting=0.92, self_awareness=0.84, assertiveness=0.78, emotion_regulation=0.74, stability=0.70
14. **Expected valleys:** social_energy=0.16, disclosure_pace=0.24, emotional_openness=0.30, repair_orientation=0.32, empathy=0.36
15. **Closest competitors:** sezgisel, muhafiz, kararli
16. **Separator dimensions vs competitors:**
    - vs `sezgisel`: boundary_setting, empathy, social_awareness, assertiveness
    - vs `muhafiz`: empathy, conflict_approach, social_energy
    - vs `kararli`: social_energy, repair_orientation, spontaneity
17. **Relationship-expression pattern:** Keeps space; connects on chosen terms.
18. **Communication pattern:** Lower social energy, slower disclosure.
19. **Decision-making pattern:** Decides alone then optionally shares.
20. **Stress-expression pattern:** Withdraws further; repair may lag.
21. **Typical strengths (descriptive):** Boundary setting; Self-awareness; Selective social energy
22. **Possible blind spots (descriptive):** May under-signal care; May confuse with sezgisel
23. **Low-confidence conditions:** High empathy/social_awareness without boundary peaks; Near-tie with sezgisel
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['boundary_setting', 'self_awareness', 'assertiveness', 'social_energy']; tie_break_rank=16.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.6400 (w=0.9500)
pattern_reasoning: 0.5600 (w=0.8500)
verbal_reasoning: 0.5400 (w=0.8500)
spatial_reasoning: 0.5000 (w=0.7500)
empathy: 0.3600 (w=0.6500)
perspective_taking: 0.5600 (w=0.9000)
self_awareness: 0.8400 (w=1.3000)
emotion_regulation: 0.7400 (w=1.1000)
emotional_openness: 0.3000 (w=0.6500)
boundary_setting: 0.9200 (w=1.5500)
assertiveness: 0.7800 (w=1.2500)
conflict_approach: 0.6200 (w=0.9500)
repair_orientation: 0.3200 (w=0.6500)
social_awareness: 0.4200 (w=0.7000)
depth_preference: 0.6000 (w=0.8500)
social_energy: 0.1600 (w=1.0000)
spontaneity: 0.4200 (w=0.8500)
stability: 0.7000 (w=1.0000)
disclosure_pace: 0.2400 (w=0.7000)
communication_pace: 0.3800 (w=0.7500)
```

</details>

### `sezgisel` — Sezgisel / Intuitive

1. **persona_id:** `sezgisel`
2. **Turkish display name:** Sezgisel
3. **English display name:** Intuitive
4. **Core definition:** Reads social-emotional fields via social awareness, empathy, and pattern cues.
5. **Full behavioral definition:** Senses undercurrents. Differs from bagimsiz by attunement over autonomy walls; from yaratici by sensing over making.
6. **Represents:** Field sensitivity, empathic pattern reading.
7. **Does not represent:** Hard boundary autonomy primacy or craft-first creation.
8. **Primary differentiating dimensions:** social_awareness, empathy, emotional_openness, pattern_reasoning
9. **Secondary supporting dimensions:** perspective_taking, disclosure_pace, depth_preference
10. **Approximately neutral dimensions:** logical_reasoning, verbal_reasoning, spatial_reasoning, self_awareness, emotion_regulation, boundary_setting
11. **Anti-traits (provisional):**
    - `social_awareness` below 0.47 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sezgisel peak on social_awareness.
    - `empathy` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sezgisel peak on empathy.
    - `emotional_openness` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sezgisel peak on emotional_openness.
    - `pattern_reasoning` below 0.31 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with sezgisel peak on pattern_reasoning.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['social_awareness', 'empathy', 'emotional_openness']; total coverage ≥ 0.45
13. **Expected peaks:** social_awareness=0.92, empathy=0.82, emotional_openness=0.82, disclosure_pace=0.80, perspective_taking=0.78
14. **Expected valleys:** assertiveness=0.32, conflict_approach=0.36, communication_pace=0.36, logical_reasoning=0.38, social_energy=0.40
15. **Closest competitors:** bagimsiz, yaratici, empat
16. **Separator dimensions vs competitors:**
    - vs `bagimsiz`: boundary_setting, empathy, social_awareness, assertiveness
    - vs `yaratici`: spatial_reasoning, social_awareness, spontaneity
    - vs `empat`: pattern_reasoning, assertiveness, emotion_regulation
17. **Relationship-expression pattern:** Anticipates unspoken needs.
18. **Communication pattern:** Variable disclosure; socially aware pacing.
19. **Decision-making pattern:** Uses felt pattern before formal criteria.
20. **Stress-expression pattern:** Over-reads signals; assertiveness may drop.
21. **Typical strengths (descriptive):** Social awareness; Empathy; Pattern reasoning
22. **Possible blind spots (descriptive):** Boundary lag; May confuse with empat/yaratici/bagimsiz
23. **Low-confidence conditions:** High boundary_setting + low empathy; Near-tie with bagimsiz/yaratici
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['social_awareness', 'empathy', 'emotional_openness', 'pattern_reasoning']; tie_break_rank=17.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.3800 (w=0.6500)
pattern_reasoning: 0.7600 (w=1.2000)
verbal_reasoning: 0.6200 (w=0.9500)
spatial_reasoning: 0.4800 (w=0.7500)
empathy: 0.8200 (w=1.2500)
perspective_taking: 0.7800 (w=1.2000)
self_awareness: 0.7600 (w=1.1500)
emotion_regulation: 0.4400 (w=0.8000)
emotional_openness: 0.8200 (w=1.2500)
boundary_setting: 0.4200 (w=0.7500)
assertiveness: 0.3200 (w=0.6000)
conflict_approach: 0.3600 (w=0.6500)
repair_orientation: 0.5600 (w=0.9000)
social_awareness: 0.9200 (w=1.5500)
depth_preference: 0.7400 (w=1.1000)
social_energy: 0.4000 (w=0.8000)
spontaneity: 0.5400 (w=0.8500)
stability: 0.4200 (w=0.8000)
disclosure_pace: 0.8000 (w=1.2000)
communication_pace: 0.3600 (w=0.7500)
```

</details>

### `stratejist` — Stratejist / Strategist

1. **persona_id:** `stratejist`
2. **Turkish display name:** Stratejist
3. **English display name:** Strategist
4. **Core definition:** Sequences long-horizon moves via logic, pattern, and stability.
5. **Full behavioral definition:** Plans contingencies. Differs from uygulayici by foresight/pattern weight; from analist by assertive stability of plan execution.
6. **Represents:** Contingent planning, pattern foresight, stable sequencing.
7. **Does not represent:** Improvisational bravery or pure reflective wisdom without plan structure.
8. **Primary differentiating dimensions:** logical_reasoning, pattern_reasoning, perspective_taking, stability
9. **Secondary supporting dimensions:** assertiveness, emotion_regulation, boundary_setting
10. **Approximately neutral dimensions:** verbal_reasoning, spatial_reasoning, empathy, self_awareness, emotional_openness, conflict_approach
11. **Anti-traits (provisional):**
    - `logical_reasoning` below 0.45 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with stratejist peak on logical_reasoning.
    - `pattern_reasoning` below 0.41 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with stratejist peak on pattern_reasoning.
    - `perspective_taking` below 0.37 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with stratejist peak on perspective_taking.
    - `stability` below 0.39 (severity 0.35; min evidence 2) — PROVISIONAL: strongly conflicts with stratejist peak on stability.
12. **Minimum required evidence:** groups ['eq', 'frequency']; critical ['logical_reasoning', 'pattern_reasoning', 'perspective_taking']; total coverage ≥ 0.45
13. **Expected peaks:** logical_reasoning=0.90, pattern_reasoning=0.86, stability=0.84, perspective_taking=0.82, emotion_regulation=0.80
14. **Expected valleys:** spontaneity=0.14, emotional_openness=0.28, disclosure_pace=0.28, social_energy=0.36, empathy=0.40
15. **Closest competitors:** analist, uygulayici, vizyoner
16. **Separator dimensions vs competitors:**
    - vs `analist`: assertiveness, stability, social_awareness
    - vs `uygulayici`: pattern_reasoning, perspective_taking, communication_pace
    - vs `vizyoner`: spontaneity, stability, emotional_openness
17. **Relationship-expression pattern:** Offers maps and sequenced options.
18. **Communication pattern:** Measured pace, moderate disclosure.
19. **Decision-making pattern:** Builds decision trees then commits.
20. **Stress-expression pattern:** Over-plans; spontaneity drops.
21. **Typical strengths (descriptive):** Logical/pattern reasoning; Perspective taking; Stability
22. **Possible blind spots (descriptive):** May delay action; May confuse with analist/uygulayici
23. **Low-confidence conditions:** High spontaneity profiles; Near-tie with analist
24. **Mathematical distinctness:** unique provisional target vector + dimension_weights; primary set ['logical_reasoning', 'pattern_reasoning', 'perspective_taking', 'stability']; tie_break_rank=18.

<details><summary>Provisional 20D target vector</summary>

```
logical_reasoning: 0.9000 (w=1.4500)
pattern_reasoning: 0.8600 (w=1.4000)
verbal_reasoning: 0.7000 (w=1.0500)
spatial_reasoning: 0.5400 (w=0.8000)
empathy: 0.4000 (w=0.7000)
perspective_taking: 0.8200 (w=1.2500)
self_awareness: 0.7400 (w=1.1000)
emotion_regulation: 0.8000 (w=1.2000)
emotional_openness: 0.2800 (w=0.6000)
boundary_setting: 0.7400 (w=1.0500)
assertiveness: 0.7600 (w=1.1500)
conflict_approach: 0.7000 (w=1.0500)
repair_orientation: 0.4600 (w=0.8000)
social_awareness: 0.6600 (w=0.9500)
depth_preference: 0.7200 (w=0.9000)
social_energy: 0.3600 (w=0.8000)
spontaneity: 0.1400 (w=0.9500)
stability: 0.8400 (w=1.1500)
disclosure_pace: 0.2800 (w=0.6500)
communication_pace: 0.6000 (w=0.8500)
```

</details>

---

## Difficult persona-pair distinctions

All distinctions are multi-dimensional. Do not separate pairs with a single arbitrary threshold.

### `koruyucu` vs `muhafiz`

**Summary:** Both protect structure; koruyucu pairs empathy+repair with boundaries; muhafiz leads with conflict/containment and low disclosure.

1. **Shared dimensions (overlap):** boundary_setting, stability
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** empathy, repair_orientation, disclosure_pace, conflict_approach
4. **Direction of each difference (provisional targets):**
    - `empathy`: koruyucu=0.88 vs muhafiz=0.42
    - `repair_orientation`: koruyucu=0.84 vs muhafiz=0.46
    - `disclosure_pace`: koruyucu=0.74 vs muhafiz=0.24
    - `conflict_approach`: koruyucu=0.48 vs muhafiz=0.86
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** empathy, repair_orientation, disclosure_pace, conflict_approach
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `bilge` vs `analist`

**Summary:** Both think carefully; bilge peaks self-awareness/depth/verbal; analist peaks logic/pattern with lower openness.

1. **Shared dimensions (overlap):** (no primary overlap; may still share mid-range traits)
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** depth_preference, emotional_openness, self_awareness, logical_reasoning
4. **Direction of each difference (provisional targets):**
    - `depth_preference`: bilge=0.88 vs analist=0.62
    - `emotional_openness`: bilge=0.56 vs analist=0.24
    - `self_awareness`: bilge=0.90 vs analist=0.70
    - `logical_reasoning`: bilge=0.64 vs analist=0.92
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** depth_preference, emotional_openness, self_awareness, logical_reasoning
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `empat` vs `sifaci`

**Summary:** Both high empathy; sifaci adds repair+regulation+stability action; empat peaks openness/disclosure resonance.

1. **Shared dimensions (overlap):** disclosure_pace, empathy
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** repair_orientation, emotion_regulation, boundary_setting, emotional_openness
4. **Direction of each difference (provisional targets):**
    - `repair_orientation`: empat=0.66 vs sifaci=0.94
    - `emotion_regulation`: empat=0.36 vs sifaci=0.76
    - `boundary_setting`: empat=0.32 vs sifaci=0.48
    - `emotional_openness`: empat=0.90 vs sifaci=0.78
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** repair_orientation, emotion_regulation, boundary_setting, emotional_openness
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `lider` vs `vizyoner`

**Summary:** Both directional; lider mobilizes via assertiveness/social_energy; vizyoner via pattern/verbal foresight/spontaneity.

1. **Shared dimensions (overlap):** (no primary overlap; may still share mid-range traits)
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** assertiveness, social_energy, pattern_reasoning, spontaneity
4. **Direction of each difference (provisional targets):**
    - `assertiveness`: lider=0.92 vs vizyoner=0.66
    - `social_energy`: lider=0.90 vs vizyoner=0.62
    - `pattern_reasoning`: lider=0.56 vs vizyoner=0.88
    - `spontaneity`: lider=0.34 vs vizyoner=0.80
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** assertiveness, social_energy, pattern_reasoning, spontaneity
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `cesur` vs `kararli`

**Summary:** Both assertive; cesur high spontaneity/low stability; kararli inverse.

1. **Shared dimensions (overlap):** assertiveness
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** spontaneity, stability, emotion_regulation
4. **Direction of each difference (provisional targets):**
    - `spontaneity`: cesur=0.90 vs kararli=0.16
    - `stability`: cesur=0.26 vs kararli=0.94
    - `emotion_regulation`: cesur=0.34 vs kararli=0.84
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** spontaneity, stability, emotion_regulation
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `yaratici` vs `donusturucu`

**Summary:** Both change-oriented; yaratici generative spatial/spontaneity; donusturucu conflict-driven transformation.

1. **Shared dimensions (overlap):** spontaneity
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** spatial_reasoning, conflict_approach, assertiveness, spontaneity
4. **Direction of each difference (provisional targets):**
    - `spatial_reasoning`: yaratici=0.82 vs donusturucu=0.52
    - `conflict_approach`: yaratici=0.42 vs donusturucu=0.90
    - `assertiveness`: yaratici=0.48 vs donusturucu=0.86
    - `spontaneity`: yaratici=0.92 vs donusturucu=0.88
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** spatial_reasoning, conflict_approach, assertiveness, spontaneity
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `uygulayici` vs `stratejist`

**Summary:** Both stable planners; uygulayici execution/communication pace; stratejist pattern foresight/perspective.

1. **Shared dimensions (overlap):** stability
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** pattern_reasoning, perspective_taking, spontaneity
4. **Direction of each difference (provisional targets):**
    - `pattern_reasoning`: uygulayici=0.54 vs stratejist=0.86
    - `perspective_taking`: uygulayici=0.48 vs stratejist=0.82
    - `spontaneity`: uygulayici=0.22 vs stratejist=0.14
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** pattern_reasoning, perspective_taking, spontaneity
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `bagimsiz` vs `sezgisel`

**Summary:** Both selective socially; bagimsiz boundary/autonomy; sezgisel social_awareness/empathy sensing.

1. **Shared dimensions (overlap):** (no primary overlap; may still share mid-range traits)
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** boundary_setting, empathy, social_awareness, assertiveness
4. **Direction of each difference (provisional targets):**
    - `boundary_setting`: bagimsiz=0.92 vs sezgisel=0.42
    - `empathy`: bagimsiz=0.36 vs sezgisel=0.82
    - `social_awareness`: bagimsiz=0.42 vs sezgisel=0.92
    - `assertiveness`: bagimsiz=0.78 vs sezgisel=0.32
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** boundary_setting, empathy, social_awareness, assertiveness
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `iletisimci` vs `empat`

**Summary:** Both socially open; iletisimci pace/social_energy/verbal; empat empathy/openness/disclosure depth.

1. **Shared dimensions (overlap):** social_awareness
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** empathy, depth_preference, social_energy, communication_pace
4. **Direction of each difference (provisional targets):**
    - `empathy`: iletisimci=0.68 vs empat=0.94
    - `depth_preference`: iletisimci=0.34 vs empat=0.76
    - `social_energy`: iletisimci=0.92 vs empat=0.52
    - `communication_pace`: iletisimci=0.92 vs empat=0.50
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** empathy, depth_preference, social_energy, communication_pace
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `yargic` vs `analist`

**Summary:** Both evaluative; yargic conflict/social_awareness judgment; analist logic/pattern structure.

1. **Shared dimensions (overlap):** emotion_regulation, logical_reasoning
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** conflict_approach, social_awareness, boundary_setting
4. **Direction of each difference (provisional targets):**
    - `conflict_approach`: yargic=0.80 vs analist=0.48
    - `social_awareness`: yargic=0.74 vs analist=0.52
    - `boundary_setting`: yargic=0.82 vs analist=0.64
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** conflict_approach, social_awareness, boundary_setting
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `lider` vs `uygulayici`

**Summary:** Both directional; lider social mobilization; uygulayici solo-stable execution.

1. **Shared dimensions (overlap):** assertiveness
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** social_awareness, social_energy, stability
4. **Direction of each difference (provisional targets):**
    - `social_awareness`: lider=0.86 vs uygulayici=0.50
    - `social_energy`: lider=0.90 vs uygulayici=0.58
    - `stability`: lider=0.74 vs uygulayici=0.90
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** social_awareness, social_energy, stability
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `sezgisel` vs `yaratici`

**Summary:** Both pattern-sensitive; sezgisel social-emotional field; yaratici spatial/making spontaneity.

1. **Shared dimensions (overlap):** emotional_openness, pattern_reasoning
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** spatial_reasoning, social_awareness, spontaneity
4. **Direction of each difference (provisional targets):**
    - `spatial_reasoning`: sezgisel=0.48 vs yaratici=0.82
    - `social_awareness`: sezgisel=0.92 vs yaratici=0.56
    - `spontaneity`: sezgisel=0.54 vs yaratici=0.92
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** spatial_reasoning, social_awareness, spontaneity
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `stratejist` vs `analist`

**Summary:** Both cognitive; stratejist assertive stable sequencing; analist lower assertiveness/openness.

1. **Shared dimensions (overlap):** logical_reasoning, pattern_reasoning
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** assertiveness, stability, social_awareness
4. **Direction of each difference (provisional targets):**
    - `assertiveness`: stratejist=0.76 vs analist=0.44
    - `stability`: stratejist=0.84 vs analist=0.68
    - `social_awareness`: stratejist=0.66 vs analist=0.52
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** assertiveness, stability, social_awareness
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

### `koruyucu` vs `sifaci`

**Summary:** Both caring; koruyucu boundaries+assertive protection; sifaci repair action with softer conflict.

1. **Shared dimensions (overlap):** empathy, repair_orientation
2. **Shared behavioral patterns:** both can appear competent/stable in overlapping social contexts; ambiguity rises when separator dims lack evidence.
3. **Primary differentiating dimensions:** boundary_setting, assertiveness, conflict_approach
4. **Direction of each difference (provisional targets):**
    - `boundary_setting`: koruyucu=0.82 vs sifaci=0.48
    - `assertiveness`: koruyucu=0.52 vs sifaci=0.30
    - `conflict_approach`: koruyucu=0.48 vs sifaci=0.28
5. **Secondary differentiating dimensions:** compare supporting sets and Frequency valleys/peaks not listed above.
6. **Must not use alone to separate:** any single shared high trait (e.g. empathy alone for empat/sifaci); IQ alone; any moral framing.
7. **Expected ambiguous profiles:** midpoints on separator dims with both primaries elevated.
8. **Suggested adaptive separator dimensions:** boundary_setting, assertiveness, conflict_approach
9. **Suggested adaptive scenario themes:** short scenarios that force tradeoffs among the separator dims (still offline design only).
10. **Anti-trait differences:** see each persona's anti_traits; opposing directions on the same dim are especially informative.
11. **Minimum evidence to resolve:** ≥2 evidence on each separator dim + Frequency group coverage ≥ 0.5.
12. **Expected top-2 margin behavior:** margins stay small until separator dims diverge; low confidence until then.

---

## Anti-trait policy

- Bounded penalties; never create negative similarity.
- Never decide a persona alone.
- Never apply when evidence < minimum_evidence_required.
- Provisional until calibrated.

## Missing evidence policy

- Missing dims reduce coverage / `q_j` → 0.
- Never fill with 0, 0.5, 0.42, neutral target match, or fabricated low/high traits.
- Insufficient evidence blocks persona assignment.

## Runtime integration

**None in this phase.** Do not load these assets in production Flutter code.
