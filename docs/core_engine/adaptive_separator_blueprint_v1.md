# Adaptive Separator Blueprint v1

**Status:** planning only (P2A-1) — **no runtime adaptive logic in this phase**  
**Trigger source:** PersonaScoringService top-2 margin / ambiguous status  
**Max additional items:** 8  

## Rules

- Select by information value between top candidate personas.  
- Never ask identity questions (“Are you an Empath/Healer/Leader?”).  
- Never show persona names as answer keys.  
- User may remain `ambiguous` after all separators — **do not force a persona**.  

## Shared stopping rule (provisional)

1. Stop when `top2Margin ≥ config.top2_margin_threshold` **and** critical separator dims have ≥ min evidence.  
2. Stop when max separators (8) reached.  
3. Stop early if RVI becomes `invalid`.  
4. Otherwise end as unresolved ambiguity (keep top-2 + separator targets).  

## Confidence update rule (provisional)

Recompute profile → re-score personas → refresh confidence components (coverage, margin). Separators add evidence only; they do not rewrite prior answers.

## Exposure / reuse

- Prefer unused separator items for the user.  
- Reuse allowed only across sessions with cooldown and construct overlap validity.  
- Max 2 items from same `behavioral_isomorph_group` in one adaptive phase.

---

## Pair plans

### empat vs sifaci

| Field | Plan |
|---|---|
| Target dims | repair_orientation (+sifaci), emotion_regulation (+sifaci), boundary_setting (+sifaci), emotional_openness (+empat), disclosure_pace |
| Direction | sifaci: repair/regulation/boundaries up; empat: openness/disclosure up without repair action |
| Suitable themes | Friend in distress — listen vs help plan; aftercare after conflict |
| Unsuitable | “Who is more caring?” moral contests |
| Min / max items | 2 / 4 |
| Unresolved | remain ambiguous; surface separatorTargets |

### kararli vs uygulayici

| Field | Plan |
|---|---|
| Target dims | spontaneity, communication_pace, logical_reasoning, stability |
| Direction | kararli: very high stability / low spontaneity persistence; uygulayici: execution + communication pace / planning action |
| Suitable themes | Stuck project: push vs replan; schedule disruption |
| Unsuitable | Courage lectures |
| Min / max | 2 / 3 |

### analist vs bagimsiz

| Field | Plan |
|---|---|
| Target dims | logical_reasoning, pattern_reasoning, boundary_setting, social_energy, emotional_openness |
| Direction | analist: cognitive peaks + lower openness; bagimsiz: boundaries + low social_energy autonomy |
| Suitable themes | Solo decision with incomplete data; declining a group invite |
| Unsuitable | “Are you independent or smart?” |
| Min / max | 2 / 4 |

### cesur vs donusturucu

| Field | Plan |
|---|---|
| Target dims | spontaneity, conflict_approach, repair_orientation, social_awareness, stability |
| Direction | cesur: risk/spontaneity; donusturucu: change leadership + repair after rupture |
| Suitable themes | Challenge a stuck group norm vs thrill-seeking alone |
| Unsuitable | Bravery moralizing |
| Min / max | 2 / 4 |

### empat vs sezgisel

| Field | Plan |
|---|---|
| Target dims | pattern_reasoning, social_awareness, assertiveness, disclosure_pace, empathy |
| Direction | sezgisel: social_awareness + pattern cues; empat: empathy/openness absorption |
| Suitable themes | Reading a room vs feeling with one person |
| Unsuitable | Mystical “intuition gift” framing |
| Min / max | 2 / 3 |

### koruyucu vs muhafiz

| Field | Plan |
|---|---|
| Target dims | empathy, repair_orientation, disclosure_pace, conflict_approach, boundary_setting |
| Direction | koruyucu: care+repair+disclosure with boundaries; muhafiz: containment/conflict firmness, low disclosure |
| Suitable themes | Partner crossed a line — warm limit vs hard perimeter |
| Unsuitable | “Protector quiz” labels |
| Min / max | 2 / 4 |

### bilge vs analist

| Field | Plan |
|---|---|
| Target dims | depth_preference, self_awareness, emotional_openness, logical_reasoning, social_energy |
| Direction | bilge: depth/self-awareness; analist: logic/pattern, lower openness/energy |
| Suitable themes | Advice request — meaning vs structure |
| Unsuitable | IQ flex contests |
| Min / max | 2 / 3 |

### lider vs vizyoner

| Field | Plan |
|---|---|
| Target dims | assertiveness, social_energy, pattern_reasoning, spontaneity, social_awareness |
| Direction | lider: mobilize people; vizyoner: pattern/verbal foresight + exploratory spontaneity |
| Suitable themes | Team stuck — rally vs reframe future path |
| Unsuitable | “Are you a leader?” |
| Min / max | 2 / 4 |

### yaratici vs donusturucu

| Field | Plan |
|---|---|
| Target dims | spatial_reasoning / pattern play, conflict_approach, assertiveness, spontaneity, repair_orientation |
| Direction | yaratici: generative making; donusturucu: confront-to-change |
| Suitable themes | Broken process — invent new artifact vs confront owners |
| Unsuitable | Artist vs activist identity |
| Min / max | 2 / 4 |

### uygulayici vs stratejist

| Field | Plan |
|---|---|
| Target dims | pattern_reasoning, perspective_taking, spontaneity, communication_pace, stability |
| Direction | stratejist: foresight/pattern; uygulayici: execute now with pace |
| Suitable themes | Ambiguous long project — map contingencies vs ship milestone |
| Unsuitable | Strategy buzzword quiz |
| Min / max | 2 / 3 |

## Bank requirement

≥ **8–12 reviewed separator items per difficult pair** in the authoring bank before enabling adaptive runtime (future phase).
