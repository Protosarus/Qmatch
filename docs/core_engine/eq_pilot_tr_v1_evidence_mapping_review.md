# EQ Pilot TR v1 — Evidence Mapping Review

**Source:** `assets/data/assessment_v3/eq/eq_pilot_tr_v1.json`
**Status:** Internal review / provisional authoring hypotheses
**Coverage:** All **30** pilot items (ordered). Each item has numbered review fields **1–20** (field schema, not an item-count limit).

> **Important:** All `dimension_deltas` and counter-evidence values are **provisional authoring hypotheses**, not established psychological facts. Expert psychological review is **pending**. Option-level `evidence_strength`, `social_desirability_risk`, and `response_style_risk` live in the JSON source of truth; this review copies deltas/counter-evidence and documents item-level SDR from authoring notes.

## Overview (30 items)

| # | Question ID | Scenario family | Primary dimension | Secondary dimensions | Review priority |
|---|---|---|---|---|---|
| 1 | `eq_tr_v1_assertiveness_001` | boundary_and_request_conflicts | `assertiveness` | emotion_regulation, repair_orientation | high |
| 2 | `eq_tr_v1_assertiveness_002` | competing_values_and_tradeoffs | `assertiveness` | boundary_setting, social_awareness | medium |
| 3 | `eq_tr_v1_assertiveness_003` | repeated_behavioral_patterns | `assertiveness` | (none tagged) | high |
| 4 | `eq_tr_v1_boundary_setting_001` | boundary_and_request_conflicts | `boundary_setting` | assertiveness | high |
| 5 | `eq_tr_v1_boundary_setting_002` | competing_values_and_tradeoffs | `boundary_setting` | assertiveness, repair_orientation | high |
| 6 | `eq_tr_v1_boundary_setting_003` | repeated_behavioral_patterns | `boundary_setting` | (none tagged) | high |
| 7 | `eq_tr_v1_conflict_approach_001` | boundary_and_request_conflicts | `conflict_approach` | perspective_taking, assertiveness | high |
| 8 | `eq_tr_v1_conflict_approach_002` | repair_after_disagreement | `conflict_approach` | emotion_regulation, repair_orientation | medium |
| 9 | `eq_tr_v1_conflict_approach_003` | competing_values_and_tradeoffs | `conflict_approach` | boundary_setting | high |
| 10 | `eq_tr_v1_emotion_regulation_001` | internal_emotional_awareness | `emotion_regulation` | self_awareness, social_awareness | medium |
| 11 | `eq_tr_v1_emotion_regulation_002` | stress_and_regulation | `emotion_regulation` | self_awareness | medium |
| 12 | `eq_tr_v1_emotion_regulation_003` | stress_and_regulation | `emotion_regulation` | self_awareness, perspective_taking | medium |
| 13 | `eq_tr_v1_emotional_openness_001` | internal_emotional_awareness | `emotional_openness` | self_awareness, boundary_setting | high |
| 14 | `eq_tr_v1_emotional_openness_002` | emotional_disclosure | `emotional_openness` | (none tagged) | high |
| 15 | `eq_tr_v1_emotional_openness_003` | emotional_disclosure | `emotional_openness` | empathy, boundary_setting | high |
| 16 | `eq_tr_v1_empathy_001` | interpersonal_support | `empathy` | boundary_setting, assertiveness | high |
| 17 | `eq_tr_v1_empathy_002` | repair_after_disagreement | `empathy` | repair_orientation, conflict_approach | medium |
| 18 | `eq_tr_v1_empathy_003` | emotional_disclosure | `empathy` | emotional_openness, boundary_setting | medium |
| 19 | `eq_tr_v1_perspective_taking_001` | perspective_taking_family | `perspective_taking` | social_awareness, boundary_setting | medium |
| 20 | `eq_tr_v1_perspective_taking_002` | perspective_taking_family | `perspective_taking` | social_awareness | medium |
| 21 | `eq_tr_v1_perspective_taking_003` | social_context_awareness | `perspective_taking` | conflict_approach, social_awareness | medium |
| 22 | `eq_tr_v1_repair_orientation_001` | interpersonal_support | `repair_orientation` | empathy | high |
| 23 | `eq_tr_v1_repair_orientation_002` | repair_after_disagreement | `repair_orientation` | emotional_openness, empathy | medium |
| 24 | `eq_tr_v1_repair_orientation_003` | repeated_behavioral_patterns | `repair_orientation` | conflict_approach, assertiveness | medium |
| 25 | `eq_tr_v1_self_awareness_001` | internal_emotional_awareness | `self_awareness` | emotion_regulation | high |
| 26 | `eq_tr_v1_self_awareness_002` | social_context_awareness | `self_awareness` | social_awareness, boundary_setting | medium |
| 27 | `eq_tr_v1_self_awareness_003` | stress_and_regulation | `self_awareness` | conflict_approach | high |
| 28 | `eq_tr_v1_social_awareness_001` | interpersonal_support | `social_awareness` | empathy, boundary_setting | high |
| 29 | `eq_tr_v1_social_awareness_002` | perspective_taking_family | `social_awareness` | perspective_taking, boundary_setting | medium |
| 30 | `eq_tr_v1_social_awareness_003` | social_context_awareness | `social_awareness` | repair_orientation, perspective_taking | medium |

---

## Item 1: `eq_tr_v1_assertiveness_001`

### 1. Question ID

`eq_tr_v1_assertiveness_001`
### 2. Scenario family

`boundary_and_request_conflicts`
### 3. Primary dimension

`assertiveness`
### 4. Secondary dimensions

`emotion_regulation`, `repair_orientation`
### 5. Construct definition (provisional)

Direct expression of needs and views with relational initiative.
### 6. Prompt summary

Arkadaşın senin adına bir plan yaptı; katılmak istemiyorsun ama hayır demek onu kırabilir. Ne söylersin?
### 7. Option summaries (A–D)

- **A:** Teşekkür eder, katılamayacağını ve nedenini açıkça belirtirsin.
- **B:** Katılmayacağımı yumuşak bir ifadeyle söylerim; gerekçeyi çok açmadan bırakırım.
- **C:** Alternatif bir zaman öneririm; katılmama kararımı net ama yumuşak tutarım.
- **D:** Şimdilik uyumlu görünürüm; sonra yalnızken hissettiğimi not alıp netleştiririm.

### 8. Full option evidence vectors (copy deltas)

- **A** — assertiveness: +0.72; emotion_regulation: -0.20
- **B** — assertiveness: +0.45; repair_orientation: -0.18
- **C** — assertiveness: +0.08 (counter -0.10); conflict_approach: -0.15
- **D** — assertiveness: -0.52; boundary_setting: -0.22

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Net ve saygılı reddetme.; tradeoff_cost_on_emotion_regulation
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
**B:** Yapıcı assertiveness.; tradeoff_cost_on_repair_orientation
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**C:** Belirsizlik; düşük assertiveness.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `assertiveness` (-0.10) offsets apparent primary signal.
**D:** Uyum odaklı; ihtiyaç bastırılır.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (primary-target); magnitude -0.52 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `açık ret vs uyum`; authoring note: hayır demek kırıcı olmak zorunda değildir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`açık ret vs uyum`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `assertiveness` should not absorb: Dominance contests or leadership identity.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_04`; reverse pair `eq_tr_v1_rev_03`
### 15. RVI role

Roles: reverse_consistency, semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `assertiveness` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `assertiveness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=boundary_and_request_conflicts; sdr_item_risk=low; tradeoff=açık ret vs uyum; how_avoids_ideal_answer=hayır demek kırıcı olmak zorunda değildir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 2: `eq_tr_v1_assertiveness_002`

### 1. Question ID

`eq_tr_v1_assertiveness_002`
### 2. Scenario family

`competing_values_and_tradeoffs`
### 3. Primary dimension

`assertiveness`
### 4. Secondary dimensions

`boundary_setting`, `social_awareness`
### 5. Construct definition (provisional)

Direct expression of needs and views with relational initiative.
### 6. Prompt summary

Toplantıda fikrin kesildi; tekrar söz almak istiyorsun. Ortam rekabetçi. Nasıl davranırsın?
### 7. Option summaries (A–D)

- **A:** Kibarca söz isteyip görüşünü tamamlarsın.
- **B:** Chat üzerinden «devam etmek isterim» yazıp söz alırsın.
- **C:** Konu geçene kadar beklersin, sonra kısaca eklersin.
- **D:** Söylenmeyen kısmı önemsemeden susarsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — assertiveness: +0.72; boundary_setting: -0.22
- **B** — assertiveness: +0.45; social_awareness: -0.15
- **C** — assertiveness: +0.08 (counter -0.08)
- **D** — assertiveness: -0.52

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Doğrudan ama profesyonel assertiveness.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Dolaylı assertiveness kanalı.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
**C:** Geç ve zayıf ifade.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `assertiveness` (-0.08) offsets apparent primary signal.
**D:** Geri çekilme.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (primary-target); magnitude -0.52 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `ses alma vs grup akışı`; authoring note: farklı iletişim kanalları eşit derecede geçerli. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`ses alma vs grup akışı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `moderate`. Moderate risk: some options may read as more socially desirable (supportive/listening); delta spread and counter-evidence intended to keep virtuous-sounding choices costly on other dimensions.
### 13. Construct-contamination analysis

Primary `assertiveness` should not absorb: Dominance contests or leadership identity.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_04`; behavioral isomorph `eq_tr_v1_iso_02`
### 15. RVI role

Roles: repeated_context_stability, semantic_consistency, social_impression_risk, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `assertiveness` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `assertiveness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=competing_values_and_tradeoffs; sdr_item_risk=moderate; tradeoff=ses alma vs grup akışı; how_avoids_ideal_answer=farklı iletişim kanalları eşit derecede geçerli`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 3: `eq_tr_v1_assertiveness_003`

### 1. Question ID

`eq_tr_v1_assertiveness_003`
### 2. Scenario family

`repeated_behavioral_patterns`
### 3. Primary dimension

`assertiveness`
### 4. Secondary dimensions

None tagged at item level; cross-dimension evidence may still appear in option deltas.
### 5. Construct definition (provisional)

Direct expression of needs and views with relational initiative.
### 6. Prompt summary

Partnerin sürekli son dakika plan değiştiriyor; sen buna tepki göstermek istiyorsun. Uzun vadede ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Değişikliklerin seni zorladığını ve önceden haber vermesini istersin. Bu tercihin maliyeti zaman veya netlik kaybı olabilir.
- **B:** Esnek olduğun ve olmadığın durumları örnekle açıklarsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **C:** Bir kez söylersin ama sonra yine uyum sağlarsın. Bu tercihin maliyeti zaman veya netlik kaybı olabilir.
- **D:** Alışkanlık haline getirir, şikâyet etmezsin. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.

### 8. Full option evidence vectors (copy deltas)

- **A** — assertiveness: -0.72; boundary_setting: +0.22
- **B** — assertiveness: -0.45
- **C** — assertiveness: -0.08 (counter -0.10); repair_orientation: +0.15
- **D** — assertiveness: +0.52; emotion_regulation: -0.15

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Tekrarlayan davranışa net geri bildirim.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (primary-target); magnitude -0.72 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (secondary/cross); magnitude +0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Yapılandırılmış geri bildirim.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (primary-target); magnitude -0.45 reflects authored trade-off weight, not validated psychometrics.
**C:** Tutarsız assertiveness.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (primary-target); magnitude -0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (secondary/cross); magnitude +0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `assertiveness` (-0.10) offsets apparent primary signal.
**D:** Bastırılmış ihtiyaç.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (primary-target); magnitude +0.52 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `plan güvenilirliği vs esneklik`; authoring note: tekrarlayan davranış net konuşmayı gerektirebilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`plan güvenilirliği vs esneklik`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `assertiveness` should not absorb: Dominance contests or leadership identity.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_03`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `assertiveness` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `assertiveness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=repeated_behavioral_patterns; sdr_item_risk=low; tradeoff=plan güvenilirliği vs esneklik; how_avoids_ideal_answer=tekrarlayan davranış net konuşmayı gerektirebilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 4: `eq_tr_v1_boundary_setting_001`

### 1. Question ID

`eq_tr_v1_boundary_setting_001`
### 2. Scenario family

`boundary_and_request_conflicts`
### 3. Primary dimension

`boundary_setting`
### 4. Secondary dimensions

`assertiveness`
### 5. Construct definition (provisional)

Protecting self limits and respecting others' limits in recurring requests.
### 6. Prompt summary

Aile toplantısında seni rahatsız eden bir konu yine gündeme geliyor. Her seferinde konu değiştirilmişti. Bu sefer ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Sakin ama net bir şekilde bu konuyu konuşmak istemediğini söylersin.
- **B:** Neden rahatsız olduğunu kısaca açıklayıp alternatif konu önerirsin.
- **C:** Yine konuyu değiştirmeye çalışırsın, doğrudan söylemezsin.
- **D:** Konuyu savuştururum; ilişkiyi germemek için sınırımı şimdilik sessiz tutarım.

### 8. Full option evidence vectors (copy deltas)

- **A** — assertiveness: -0.22; boundary_setting: +0.75
- **B** — assertiveness: -0.18; boundary_setting: +0.48
- **C** — boundary_setting: +0.12 (counter -0.10); conflict_approach: -0.15
- **D** — assertiveness: -0.20; boundary_setting: -0.55

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Doğrudan sınır ifadesi.; tradeoff_cost_on_assertiveness
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.75 reflects authored trade-off weight, not validated psychometrics.
**B:** Açıklamalı sınır.; tradeoff_cost_on_assertiveness
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.48 reflects authored trade-off weight, not validated psychometrics.
**C:** Dolaylı kaçınma.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `boundary_setting` (-0.10) offsets apparent primary signal.
**D:** Sınır ihlali / uyum.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (primary-target); magnitude -0.55 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `net sınır vs huzur koruma`; authoring note: doğrudan söylemek veya dolaylı yönlendirmek savunulabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`net sınır vs huzur koruma`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `boundary_setting` should not absorb: Aggression or dominance disguised as limits.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_03`; reverse pair `eq_tr_v1_rev_02`
### 15. RVI role

Roles: reverse_consistency, semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `boundary_setting` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `boundary_setting` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `boundary_setting` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`adapted_from_legacy_scenario; scenario_family=boundary_and_request_conflicts; sdr_item_risk=low; tradeoff=net sınır vs huzur koruma; how_avoids_ideal_answer=doğrudan söylemek veya dolaylı yönlendirmek savunulabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 5: `eq_tr_v1_boundary_setting_002`

### 1. Question ID

`eq_tr_v1_boundary_setting_002`
### 2. Scenario family

`competing_values_and_tradeoffs`
### 3. Primary dimension

`boundary_setting`
### 4. Secondary dimensions

`assertiveness`, `repair_orientation`
### 5. Construct definition (provisional)

Protecting self limits and respecting others' limits in recurring requests.
### 6. Prompt summary

İş arkadaşın sürekli mesai saati dışında yazıyor. Bu ritim seni yoruyor. Nasıl yaklaşırsın?
### 7. Option summaries (A–D)

- **A:** Mesai dışı yanıt vermeyeceğini ve acil durum tanımını netleştirirsin.
- **B:** Yorgun olduğunu söyleyip ertesi gün dönüş yapacağını belirtirsin.
- **C:** Çoğu mesaja yine cevap verirsin ama geciktirirsin.
- **D:** İlişkiyi bozmamak için her mesaja anında dönersin.

### 8. Full option evidence vectors (copy deltas)

- **A** — assertiveness: -0.25; boundary_setting: +0.75
- **B** — boundary_setting: +0.48
- **C** — boundary_setting: +0.12 (counter -0.12); repair_orientation: -0.15
- **D** — assertiveness: -0.22; boundary_setting: -0.55

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yapılandırılmış iş sınırı.; tradeoff_cost_on_assertiveness
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.25 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.75 reflects authored trade-off weight, not validated psychometrics.
**B:** Yumuşak sınır.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.48 reflects authored trade-off weight, not validated psychometrics.
**C:** Tutarsız sınır.; tradeoff_cost_on_repair_orientation
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `boundary_setting` (-0.12) offsets apparent primary signal.
**D:** Sınır yok sayılır.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (primary-target); magnitude -0.55 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `iş-yaşam sınırı vs erişilebilirlik`; authoring note: hem net kural hem esnek yanıt makul. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`iş-yaşam sınırı vs erişilebilirlik`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `boundary_setting` should not absorb: Aggression or dominance disguised as limits.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_03`; behavioral isomorph `eq_tr_v1_iso_02`
### 15. RVI role

Roles: repeated_context_stability, semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `boundary_setting` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `boundary_setting` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `boundary_setting` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=competing_values_and_tradeoffs; sdr_item_risk=low; tradeoff=iş-yaşam sınırı vs erişilebilirlik; how_avoids_ideal_answer=hem net kural hem esnek yanıt makul`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 6: `eq_tr_v1_boundary_setting_003`

### 1. Question ID

`eq_tr_v1_boundary_setting_003`
### 2. Scenario family

`repeated_behavioral_patterns`
### 3. Primary dimension

`boundary_setting`
### 4. Secondary dimensions

None tagged at item level; cross-dimension evidence may still appear in option deltas.
### 5. Construct definition (provisional)

Protecting self limits and respecting others' limits in recurring requests.
### 6. Prompt summary

Flörtün plansız sık sık gelmek istiyor; sen düzenli programını korumak istiyorsun. Tekrarlayan durumda ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Ortak bir görüşme ritmi önerir, hangi günler uygun olduğunu netleştirirsin.
- **B:** Esnek olduğun günleri söyler, diğerlerinde meşgul olduğunu hatırlatırsın.
- **C:** Hayır demekte zorlanır, programını sık sık değiştirirsin.
- **D:** Rahatsız ettiğini söylemeden uzak durmaya çalışırsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — assertiveness: +0.20; boundary_setting: -0.75
- **B** — boundary_setting: -0.48
- **C** — boundary_setting: -0.12 (counter -0.10); repair_orientation: +0.18
- **D** — boundary_setting: +0.55; conflict_approach: -0.18

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Tekrarlayan sınır yapılandırması.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (secondary/cross); magnitude +0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (primary-target); magnitude -0.75 reflects authored trade-off weight, not validated psychometrics.
**B:** Kısmi yapılandırma.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (primary-target); magnitude -0.48 reflects authored trade-off weight, not validated psychometrics.
**C:** Zayıf sınır tutarlılığı.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (primary-target); magnitude -0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (secondary/cross); magnitude +0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `boundary_setting` (-0.10) offsets apparent primary signal.
**D:** Pasif kaçınma.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (primary-target); magnitude +0.55 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `program vs spontane yakınlık`; authoring note: düzen isteği ile esneklik gerçek bir gerilimdir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`program vs spontane yakınlık`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `boundary_setting` should not absorb: Aggression or dominance disguised as limits.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_02`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `boundary_setting` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `boundary_setting` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `boundary_setting` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=repeated_behavioral_patterns; sdr_item_risk=low; tradeoff=program vs spontane yakınlık; how_avoids_ideal_answer=düzen isteği ile esneklik gerçek bir gerilimdir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 7: `eq_tr_v1_conflict_approach_001`

### 1. Question ID

`eq_tr_v1_conflict_approach_001`
### 2. Scenario family

`boundary_and_request_conflicts`
### 3. Primary dimension

`conflict_approach`
### 4. Secondary dimensions

`perspective_taking`, `assertiveness`
### 5. Construct definition (provisional)

Orientation toward engaging, structuring, delaying, or distancing in disagreement.
### 6. Prompt summary

Ev arkadaşın ortak alanı farklı kullanıyor; bu seni rahatsız ediyor. Henüz konuşmadınız. İlk hamlen ne olur?
### 7. Option summaries (A–D)

- **A:** Ortak kuralları konuşmak için uygun bir zaman ayırırsın.
- **B:** Kısa bir mesajla rahatsızlığını belirtip yüz yüze konuşmayı önerirsin.
- **C:** Konuyu ertelemeyi öneririm; soğuyunca daha net konuşabileceğimizi söylerim.
- **D:** Kısa bir ara isterim; kendi tepkimi toplayıp sonra dönerim.

### 8. Full option evidence vectors (copy deltas)

- **A** — conflict_approach: +0.72; perspective_taking: -0.22
- **B** — assertiveness: -0.18; conflict_approach: +0.46
- **C** — boundary_setting: -0.12; conflict_approach: +0.10 (counter -0.08)
- **D** — conflict_approach: -0.55; emotion_regulation: -0.20

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yapılandırılmış çatışma girişi.; tradeoff_cost_on_perspective_taking
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Orta düzey doğrudanlık.; tradeoff_cost_on_assertiveness
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.46 reflects authored trade-off weight, not validated psychometrics.
**C:** Pasif beklenti.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.10 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `conflict_approach` (-0.08) offsets apparent primary signal.
**D:** Ertelemeli/agresif uç.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (primary-target); magnitude -0.55 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `erken konuşma vs bekleme`; authoring note: hem doğrudan hem dolaylı giriş makul. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`erken konuşma vs bekleme`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `conflict_approach` should not absorb: Debate IQ or moral rightness of a side.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_04`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `conflict_approach` between `muhafiz` and adjacent prototypes; provisional evidence may inform separation of `conflict_approach` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=boundary_and_request_conflicts; sdr_item_risk=low; tradeoff=erken konuşma vs bekleme; how_avoids_ideal_answer=hem doğrudan hem dolaylı giriş makul`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 8: `eq_tr_v1_conflict_approach_002`

### 1. Question ID

`eq_tr_v1_conflict_approach_002`
### 2. Scenario family

`repair_after_disagreement`
### 3. Primary dimension

`conflict_approach`
### 4. Secondary dimensions

`emotion_regulation`, `repair_orientation`
### 5. Construct definition (provisional)

Orientation toward engaging, structuring, delaying, or distancing in disagreement.
### 6. Prompt summary

İki arkadaşın senin yanında tartışmaya başladı. Arabuluculuk yapmak mı, tarafsız kalmak mı — eğilimin ne?
### 7. Option summaries (A–D)

- **A:** Her ikisinin de duyulmasını sağlayıp sakinleştirmeye çalışırsın. İlişki dinamiğini de göz önünde bulundururum.
- **B:** Kendi görüşünü söylemeden konuyu ertelemeyi teklif edersin. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **C:** Taraf tutmadan dinler, müdahale etmezsin. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **D:** Ortamdan uzaklaşırsın, sorun kendi haline kalsın. İlişki dinamiğini de göz önünde bulundururum.

### 8. Full option evidence vectors (copy deltas)

- **A** — conflict_approach: +0.68; emotion_regulation: -0.25
- **B** — conflict_approach: +0.42; repair_orientation: -0.18
- **C** — conflict_approach: +0.12 (counter -0.10); perspective_taking: -0.15
- **D** — conflict_approach: -0.45; empathy: -0.15

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Aktif arabuluculuk.; tradeoff_cost_on_emotion_regulation
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.68 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.25 reflects authored trade-off weight, not validated psychometrics.
**B:** Erteleme tabanlı yaklaşım.; tradeoff_cost_on_repair_orientation
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.42 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**C:** Pasif gözlem.; tradeoff_cost_on_perspective_taking
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `conflict_approach` (-0.10) offsets apparent primary signal.
**D:** Kaçınma.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (primary-target); magnitude -0.45 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `arabuluculuk vs tarafsızlık`; authoring note: müdahale etmemek de bir tercihtir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`arabuluculuk vs tarafsızlık`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `conflict_approach` should not absorb: Debate IQ or moral rightness of a side.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

none registered
### 15. RVI role

Roles: response_variation, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `conflict_approach` between `muhafiz` and adjacent prototypes; provisional evidence may inform separation of `conflict_approach` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=repair_after_disagreement; sdr_item_risk=low; tradeoff=arabuluculuk vs tarafsızlık; how_avoids_ideal_answer=müdahale etmemek de bir tercihtir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 9: `eq_tr_v1_conflict_approach_003`

### 1. Question ID

`eq_tr_v1_conflict_approach_003`
### 2. Scenario family

`competing_values_and_tradeoffs`
### 3. Primary dimension

`conflict_approach`
### 4. Secondary dimensions

`boundary_setting`
### 5. Construct definition (provisional)

Orientation toward engaging, structuring, delaying, or distancing in disagreement.
### 6. Prompt summary

İş yerinde ekip içi bir anlaşmazlık büyüyor; sen farklı bir çözüm görüyorsun. Toplantıda nasıl katılırsın?
### 7. Option summaries (A–D)

- **A:** Alternatif çözümünü gerekçeleriyle sunar, diyaloğu açarsın.
- **B:** Endişeni kısaca belirtir, başkalarının fikrini sorarsın.
- **C:** Tartışmayı kısa keserim; ortak bir ara çözüm önermeden önce nabız yoklarım.
- **D:** Meslektaşların yanında sert bir şekilde karşı çıkarsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — boundary_setting: +0.20; conflict_approach: -0.72
- **B** — conflict_approach: -0.46; perspective_taking: +0.18
- **C** — conflict_approach: -0.10 (counter -0.08)
- **D** — conflict_approach: +0.55; emotion_regulation: -0.22

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yapıcı muhalefet.
- Provisional hypothesis: option wording plausibly signals higher `boundary_setting` (secondary/cross); magnitude +0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (primary-target); magnitude -0.72 reflects authored trade-off weight, not validated psychometrics.
**B:** Düşük yoğunluklu katılım.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (primary-target); magnitude -0.46 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (secondary/cross); magnitude +0.18 reflects authored trade-off weight, not validated psychometrics.
**C:** Uyum odaklı geri çekilme.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (primary-target); magnitude -0.10 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `conflict_approach` (-0.08) offsets apparent primary signal.
**D:** Yıkıcı çatışma tarzı.
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (primary-target); magnitude +0.55 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `muhalefet vs grup uyumu`; authoring note: sert karşı çıkma ile susmak farklı maliyetler taşır. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`muhalefet vs grup uyumu`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `conflict_approach` should not absorb: Debate IQ or moral rightness of a side.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_04`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `conflict_approach` between `muhafiz` and adjacent prototypes; provisional evidence may inform separation of `conflict_approach` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=competing_values_and_tradeoffs; sdr_item_risk=low; tradeoff=muhalefet vs grup uyumu; how_avoids_ideal_answer=sert karşı çıkma ile susmak farklı maliyetler taşır`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 10: `eq_tr_v1_emotion_regulation_001`

### 1. Question ID

`eq_tr_v1_emotion_regulation_001`
### 2. Scenario family

`internal_emotional_awareness`
### 3. Primary dimension

`emotion_regulation`
### 4. Secondary dimensions

`self_awareness`, `social_awareness`
### 5. Construct definition (provisional)

Modulating intensity and timing of emotional response under interpersonal load.
### 6. Prompt summary

Gergin bir ekip toplantısında bir meslektaşın gözyaşlarına hakim olamadı. İlk içgüdün ne olur?
### 7. Option summaries (A–D)

- **A:** Ortamı yumuşatmak için kısa bir ara önerir, tonunu sakin tutarsın.
- **B:** Konuyu daha sonra ele almak üzere toplantıyı yönlendirirsin.
- **C:** Tartışmaya devam edersin; duyguların zamanla yatışacağını düşünürsün.
- **D:** Rahatsız edici bulup konuyu değiştirirsin, duyguyu görmezden gelirsin.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotion_regulation: +0.70; self_awareness: -0.22
- **B** — emotion_regulation: +0.45; social_awareness: -0.18
- **C** — conflict_approach: -0.15; emotion_regulation: +0.08 (counter -0.10)
- **D** — emotion_regulation: -0.48; empathy: -0.20

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Düzenleme odaklı müdahale.; tradeoff_cost_on_self_awareness
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.70 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Yapılandırılmış sakinleştirme.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**C:** Minimal düzenleme.; tradeoff_cost_on_conflict_approach
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `emotion_regulation` (-0.10) offsets apparent primary signal.
**D:** Bastırma/kaçınma eğilimi.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (primary-target); magnitude -0.48 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `duygusal tempo vs gündem baskısı`; authoring note: ara vermek, devam etmek veya yönlendirmek makul seçenekler. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`duygusal tempo vs gündem baskısı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `emotion_regulation` should not absorb: Suppression-as-virtue or never-angry social desirability.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_06`
### 15. RVI role

Roles: semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `emotion_regulation` between `empat` and adjacent prototypes; provisional evidence may inform separation of `emotion_regulation` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `emotion_regulation` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`adapted_from_legacy_scenario; scenario_family=internal_emotional_awareness; sdr_item_risk=low; tradeoff=duygusal tempo vs gündem baskısı; how_avoids_ideal_answer=ara vermek, devam etmek veya yönlendirmek makul seçenekler`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 11: `eq_tr_v1_emotion_regulation_002`

### 1. Question ID

`eq_tr_v1_emotion_regulation_002`
### 2. Scenario family

`stress_and_regulation`
### 3. Primary dimension

`emotion_regulation`
### 4. Secondary dimensions

`self_awareness`
### 5. Construct definition (provisional)

Modulating intensity and timing of emotional response under interpersonal load.
### 6. Prompt summary

Flörtünle mesajlaşırken ani bir gerilim hissediyorsun. Yazmadan önce duygunu nasıl yönetirsin?
### 7. Option summaries (A–D)

- **A:** Birkaç dakika ara verir, ne hissettiğini adlandırıp sonra yanıtlarsın. İlişki dinamiğini de göz önünde bulundururum.
- **B:** Tonunu yumuşatmak için mesajı yeniden yazarsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **C:** Hızlıca yanıt verirsin ama sonra gereksiz olduğunu fark edersin. İlişki dinamiğini de göz önünde bulundururum.
- **D:** Hissettiklerini olduğu gibi yazarsın, pişman olma ihtimalini göze alırsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotion_regulation: +0.70; self_awareness: -0.20
- **B** — emotion_regulation: +0.45
- **C** — emotion_regulation: +0.08 (counter -0.12)
- **D** — emotion_regulation: -0.48; emotional_openness: +0.22

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Bilinçli düzenleme döngüsü.; tradeoff_cost_on_self_awareness
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.70 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
**B:** Çıktı odaklı düzenleme.
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
**C:** Gecikmiş farkındalık.
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `emotion_regulation` (-0.12) offsets apparent primary signal.
**D:** Düşük ön-düzenleme.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (primary-target); magnitude -0.48 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (secondary/cross); magnitude +0.22 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `duraklama vs anlık ifade`; authoring note: hem erteleme hem anlık yanıt gerçek tercihlerdir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`duraklama vs anlık ifade`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `emotion_regulation` should not absorb: Suppression-as-virtue or never-angry social desirability.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_06`; behavioral isomorph `eq_tr_v1_iso_05`
### 15. RVI role

Roles: repeated_context_stability, semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `emotion_regulation` between `empat` and adjacent prototypes; provisional evidence may inform separation of `emotion_regulation` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `emotion_regulation` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=stress_and_regulation; sdr_item_risk=low; tradeoff=duraklama vs anlık ifade; how_avoids_ideal_answer=hem erteleme hem anlık yanıt gerçek tercihlerdir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 12: `eq_tr_v1_emotion_regulation_003`

### 1. Question ID

`eq_tr_v1_emotion_regulation_003`
### 2. Scenario family

`stress_and_regulation`
### 3. Primary dimension

`emotion_regulation`
### 4. Secondary dimensions

`self_awareness`, `perspective_taking`
### 5. Construct definition (provisional)

Modulating intensity and timing of emotional response under interpersonal load.
### 6. Prompt summary

İş yerinde eleştiri aldın; öğle arasında hâlâ içinde kalıyor. Öğleden sonraki toplantıya girmeden önce ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Kısa bir yürüyüş veya nefes egzersiziyle duygunu sakinleştirirsin.
- **B:** Eleştiriden çıkarılacak bir nokta bulup zihnini oraya odaklarsın.
- **C:** Duyguyu bastırıp profesyonel görünmeye çalışırsın.
- **D:** Eleştiriyi düşünerek toplantıya girersin, odaklanmakta zorlanırsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotion_regulation: +0.68; self_awareness: -0.18
- **B** — emotion_regulation: +0.42; perspective_taking: -0.15
- **C** — emotion_regulation: +0.15 (counter -0.15); emotional_openness: -0.20
- **D** — emotion_regulation: -0.50

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Aktif düzenleme stratejisi.; tradeoff_cost_on_self_awareness
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.68 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**B:** Bilişsel yeniden çerçeveleme.; tradeoff_cost_on_perspective_taking
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.42 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
**C:** Yüzeysel bastırma.
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (primary-target); magnitude +0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `emotion_regulation` (-0.15) offsets apparent primary signal.
**D:** Düzenleme başarısız.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (primary-target); magnitude -0.50 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `sakinleştirme vs bastırma`; authoring note: profesyonellik ile duygu işleme farklı yollar gerektirir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`sakinleştirme vs bastırma`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `emotion_regulation` should not absorb: Suppression-as-virtue or never-angry social desirability.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

behavioral isomorph `eq_tr_v1_iso_05`
### 15. RVI role

Roles: repeated_context_stability, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `emotion_regulation` between `empat` and adjacent prototypes; provisional evidence may inform separation of `emotion_regulation` between `sifaci` and adjacent prototypes; provisional evidence may inform separation of `emotion_regulation` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=stress_and_regulation; sdr_item_risk=low; tradeoff=sakinleştirme vs bastırma; how_avoids_ideal_answer=profesyonellik ile duygu işleme farklı yollar gerektirir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 13: `eq_tr_v1_emotional_openness_001`

### 1. Question ID

`eq_tr_v1_emotional_openness_001`
### 2. Scenario family

`internal_emotional_awareness`
### 3. Primary dimension

`emotional_openness`
### 4. Secondary dimensions

`self_awareness`, `boundary_setting`
### 5. Construct definition (provisional)

Willingness to disclose feelings and needs in relational contexts.
### 6. Prompt summary

Yeni tanıştığın biri sana kişisel bir şey anlatmaya başladı. Sen de benzer bir deneyimini paylaşmayı düşünüyorsun. Ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Deneyimini açıkça anlatır, duygularını da paylaşırsın.
- **B:** Deneyimini özetler ama tüm ayrıntıları vermezsin.
- **C:** Dinler, kendi hikâyeni paylaşmadan destekleyici kalırsın.
- **D:** Konuyu daha genel tutup kişisel detay vermezsin.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotional_openness: +0.78; self_awareness: -0.18
- **B** — boundary_setting: -0.15; emotional_openness: +0.42
- **C** — emotional_openness: +0.08 (counter -0.05); empathy: -0.22
- **D** — emotional_openness: -0.48

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yüksek duygusal açıklık.; tradeoff_cost_on_self_awareness
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.78 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**B:** Seçici açıklık.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.42 reflects authored trade-off weight, not validated psychometrics.
**C:** Düşük öz-açıklık; dinleme odaklı.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `emotional_openness` (-0.05) offsets apparent primary signal.
**D:** Kapalı duygusal paylaşım.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (primary-target); magnitude -0.48 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `açıklık vs mahremiyet`; authoring note: erken aşamada tam açıklık her zaman gerekli değildir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`açıklık vs mahremiyet`
### 12. Social-desirability analysis

Item-level SDR risk tagged `moderate`. Moderate risk: some options may read as more socially desirable (supportive/listening); delta spread and counter-evidence intended to keep virtuous-sounding choices costly on other dimensions.
### 13. Construct-contamination analysis

Primary `emotional_openness` should not absorb: Frequency disclosure_pace rhythm or oversharing pathology framing.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_01`
### 15. RVI role

Roles: reverse_consistency, social_impression_risk, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `emotional_openness` between `empat` and adjacent prototypes; provisional evidence may inform separation of `emotional_openness` between `muhafiz` and adjacent prototypes; provisional evidence may inform separation of `emotional_openness` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=internal_emotional_awareness; sdr_item_risk=moderate; tradeoff=açıklık vs mahremiyet; how_avoids_ideal_answer=erken aşamada tam açıklık her zaman gerekli değildir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 14: `eq_tr_v1_emotional_openness_002`

### 1. Question ID

`eq_tr_v1_emotional_openness_002`
### 2. Scenario family

`emotional_disclosure`
### 3. Primary dimension

`emotional_openness`
### 4. Secondary dimensions

None tagged at item level; cross-dimension evidence may still appear in option deltas.
### 5. Construct definition (provisional)

Willingness to disclose feelings and needs in relational contexts.
### 6. Prompt summary

Partnerin duygularını paylaşmanı istiyor; sen genelde içini pek açmazsın. Bu akşam nasıl davranırsın?
### 7. Option summaries (A–D)

- **A:** Bugün neler hissettiğini dürüstçe anlatmaya çalışırsın.
- **B:** Bir-iki duygu adı söyler, derinleşmeden devam edersin.
- **C:** İyi olduğunu söyler, detaya girmezsin.
- **D:** Konuyu başka bir gündeme kaydırırsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotional_openness: -0.78; empathy: +0.18
- **B** — emotional_openness: -0.42
- **C** — emotional_openness: -0.08 (counter -0.08)
- **D** — conflict_approach: -0.15; emotional_openness: +0.48

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** İstenen açıklığa yanıt.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (primary-target); magnitude -0.78 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (secondary/cross); magnitude +0.18 reflects authored trade-off weight, not validated psychometrics.
**B:** Kısmi açıklık.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (primary-target); magnitude -0.42 reflects authored trade-off weight, not validated psychometrics.
**C:** Yüzeysel yanıt.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (primary-target); magnitude -0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `emotional_openness` (-0.08) offsets apparent primary signal.
**D:** Açıklıktan kaçınma.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.48 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `istenen yakınlık vs alışkanlık`; authoring note: kademeli açıklık da geçerli bir yanıttır. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`istenen yakınlık vs alışkanlık`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `emotional_openness` should not absorb: Frequency disclosure_pace rhythm or oversharing pathology framing.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_01`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `emotional_openness` between `empat` and adjacent prototypes; provisional evidence may inform separation of `emotional_openness` between `muhafiz` and adjacent prototypes; provisional evidence may inform separation of `emotional_openness` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=emotional_disclosure; sdr_item_risk=low; tradeoff=istenen yakınlık vs alışkanlık; how_avoids_ideal_answer=kademeli açıklık da geçerli bir yanıttır`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 15: `eq_tr_v1_emotional_openness_003`

### 1. Question ID

`eq_tr_v1_emotional_openness_003`
### 2. Scenario family

`emotional_disclosure`
### 3. Primary dimension

`emotional_openness`
### 4. Secondary dimensions

`empathy`, `boundary_setting`
### 5. Construct definition (provisional)

Willingness to disclose feelings and needs in relational contexts.
### 6. Prompt summary

Arkadaş grubunda biri zor bir dönemini anlatıyor. Sen de benzer bir şey yaşamıştın ama herkesin önünde anlatmak istemiyorsun.
### 7. Option summaries (A–D)

- **A:** Yine de kısaca kendi deneyimini paylaşır, grubu desteklersin.
- **B:** Sonra özel konuşmak üzere teklif edersin, şimdilik dinlersin.
- **C:** Destekleyici kalır ama kendi hikâyeni paylaşmazsın.
- **D:** Konuyu hafife alıp ortamı neşelendirmeye çalışırsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotional_openness: +0.65; empathy: -0.22
- **B** — boundary_setting: -0.22; emotional_openness: +0.35
- **C** — emotional_openness: +0.10; empathy: -0.18
- **D** — emotional_openness: -0.42; social_awareness: -0.18

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Grup bağlamında açıklık.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.65 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Erteleme ile sınırlı açıklık.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.35 reflects authored trade-off weight, not validated psychometrics.
**C:** Empati var; öz-açıklık düşük.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals higher `emotional_openness` (primary-target); magnitude +0.10 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**D:** Duygusal derinlikten kaçınma.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (primary-target); magnitude -0.42 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `grup açıklığı vs özel paylaşım`; authoring note: herkesin önünde açılmak zorunlu değildir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`grup açıklığı vs özel paylaşım`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `emotional_openness` should not absorb: Frequency disclosure_pace rhythm or oversharing pathology framing.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

none registered
### 15. RVI role

Roles: response_variation, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `emotional_openness` between `empat` and adjacent prototypes; provisional evidence may inform separation of `emotional_openness` between `muhafiz` and adjacent prototypes; provisional evidence may inform separation of `emotional_openness` between `koruyucu` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=emotional_disclosure; sdr_item_risk=low; tradeoff=grup açıklığı vs özel paylaşım; how_avoids_ideal_answer=herkesin önünde açılmak zorunlu değildir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 16: `eq_tr_v1_empathy_001`

### 1. Question ID

`eq_tr_v1_empathy_001`
### 2. Scenario family

`interpersonal_support`
### 3. Primary dimension

`empathy`
### 4. Secondary dimensions

`boundary_setting`, `assertiveness`
### 5. Construct definition (provisional)

Noticing and taking another person's affective state into account when choosing a response.
### 6. Prompt summary

Yakın bir arkadaşın zor bir ayrılık yaşıyor ve mesaj atıp duygularını anlatıyor. Bu akşam başka planların var ama onu duymak istiyorsun. Ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Planını erteleyip telefonda uzun süre dinler, hissettiklerini yansıtmaya çalışırsın.
- **B:** Kısa ama sıcak bir mesaj atıp yarın yüz yüze konuşmayı teklif edersin.
- **C:** Pratik bir tavsiye listesi gönderir, kendi deneyiminden bir örnek eklersin.
- **D:** Meşgul olduğunu söyleyip kafasını dağıtması için etkinlik önerirsin.

### 8. Full option evidence vectors (copy deltas)

- **A** — boundary_setting: -0.22 (counter +0.15); empathy: +0.72
- **B** — boundary_setting: -0.18; empathy: +0.38
- **C** — assertiveness: -0.15; empathy: +0.12 (counter -0.10)
- **D** — emotion_regulation: +0.20; empathy: -0.45

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yüksek duygusal yanıt; sınır maliyeti taşır.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `boundary_setting` (+0.15) offsets apparent primary signal.
**B:** Orta düzey destek; zaman sınırı korunur.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.38 reflects authored trade-off weight, not validated psychometrics.
**C:** Destek niyeti var; duygusal yansıtma sınırlı.; tradeoff_cost_on_assertiveness
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `empathy` (-0.10) offsets apparent primary signal.
**D:** Kaçınma eğilimi; duygusal ihtiyaç ikinci planda.
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (secondary/cross); magnitude +0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (primary-target); magnitude -0.45 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `destek vs zaman sınırı`; authoring note: dinleme, tavsiye ve mesafe seçenekleri eşit derecede savunulabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`destek vs zaman sınırı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `moderate`. Moderate risk: some options may read as more socially desirable (supportive/listening); delta spread and counter-evidence intended to keep virtuous-sounding choices costly on other dimensions.
### 13. Construct-contamination analysis

Primary `empathy` should not absorb: Pure debate skill or IQ verbal reasoning without affective weighing.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_01`; behavioral isomorph `eq_tr_v1_iso_01`
### 15. RVI role

Roles: repeated_context_stability, semantic_consistency, social_impression_risk, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `empathy` between `empat` and adjacent prototypes; provisional evidence may inform separation of `empathy` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `empathy` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`adapted_from_legacy_scenario; scenario_family=interpersonal_support; sdr_item_risk=moderate; tradeoff=destek vs zaman sınırı; how_avoids_ideal_answer=dinleme, tavsiye ve mesafe seçenekleri eşit derecede savunulabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 17: `eq_tr_v1_empathy_002`

### 1. Question ID

`eq_tr_v1_empathy_002`
### 2. Scenario family

`repair_after_disagreement`
### 3. Primary dimension

`empathy`
### 4. Secondary dimensions

`repair_orientation`, `conflict_approach`
### 5. Construct definition (provisional)

Noticing and taking another person's affective state into account when choosing a response.
### 6. Prompt summary

İş arkadaşınla tartıştıktan sonra o soğuk davranıyor; sen barışmak istiyorsun ama hâlâ kırgınsın. İlk adımı nasıl atarsın?
### 7. Option summaries (A–D)

- **A:** Onun bakış açısını anlamaya çalışır, duygusunu doğrudan sorarsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **B:** Bir süre bekler, ortam sakinleşince kısa bir özür ve ortak zemin ararsın. İlişki dinamiğini de göz önünde bulundururum.
- **C:** Konuyu iş gündemine bağlayarak mesleki iletişimi sürdürürsün. İlişki dinamiğini de göz önünde bulundururum.
- **D:** Kendi haklılığını koruyup mesafeyi sürdürürsün. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.

### 8. Full option evidence vectors (copy deltas)

- **A** — empathy: +0.72; repair_orientation: -0.28
- **B** — empathy: +0.38; repair_orientation: -0.22
- **C** — conflict_approach: -0.18; empathy: +0.12 (counter -0.08)
- **D** — assertiveness: +0.25; empathy: -0.45

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Empati odaklı onarım girişimi.; tradeoff_cost_on_repair_orientation
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (secondary/cross); magnitude -0.28 reflects authored trade-off weight, not validated psychometrics.
**B:** Ölçülü yakınlaşma; duygusal yoğunluk düşük.; tradeoff_cost_on_repair_orientation
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.38 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**C:** Duygusal konuyu dolaylı ele alır.; tradeoff_cost_on_conflict_approach
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `empathy` (-0.08) offsets apparent primary signal.
**D:** Empatik bağ kurulmaz; savunma öncelikli.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (secondary/cross); magnitude +0.25 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (primary-target); magnitude -0.45 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `onarım vs korunma`; authoring note: hem duygusal yakınlaşma hem mesafe makul gerekçelere dayanır. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`onarım vs korunma`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `empathy` should not absorb: Pure debate skill or IQ verbal reasoning without affective weighing.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_01`
### 15. RVI role

Roles: semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `empathy` between `empat` and adjacent prototypes; provisional evidence may inform separation of `empathy` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `empathy` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=repair_after_disagreement; sdr_item_risk=low; tradeoff=onarım vs korunma; how_avoids_ideal_answer=hem duygusal yakınlaşma hem mesafe makul gerekçelere dayanır`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 18: `eq_tr_v1_empathy_003`

### 1. Question ID

`eq_tr_v1_empathy_003`
### 2. Scenario family

`emotional_disclosure`
### 3. Primary dimension

`empathy`
### 4. Secondary dimensions

`emotional_openness`, `boundary_setting`
### 5. Construct definition (provisional)

Noticing and taking another person's affective state into account when choosing a response.
### 6. Prompt summary

Flörtün duygusal bir konuyu açmak istiyor ama sen yorgunsun. Açmak istediği şey seni de etkileyebilir. Nasıl karşılık verirsin?
### 7. Option summaries (A–D)

- **A:** Yorgun olsan da dinlemeye hazır olduğunu söyler, dikkatini verirsin.
- **B:** Dinlemek istediğini ama kısa tutmayı tercih ettiğini açıkça belirtirsin.
- **C:** Yarın daha uygun bir zaman önerir, kısa bir destek mesajı eklersin.
- **D:** Konuyu hafife alıp başka bir şeye yönlendirmeye çalışırsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotional_openness: -0.22; empathy: +0.70
- **B** — boundary_setting: -0.20; empathy: +0.45
- **C** — boundary_setting: -0.28; empathy: +0.18
- **D** — emotional_openness: -0.22; empathy: -0.40

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yüksek duygusal erişilebilirlik.; tradeoff_cost_on_emotional_openness
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.70 reflects authored trade-off weight, not validated psychometrics.
**B:** Empati ile sınır dengelenir.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
**C:** Erteleme; sınırlı duygusal yansıtma.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.28 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `empathy` (primary-target); magnitude +0.18 reflects authored trade-off weight, not validated psychometrics.
**D:** Duygusal ihtiyaç minimize edilir.
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `empathy` (primary-target); magnitude -0.40 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `açıklık vs dinlenme ihtiyacı`; authoring note: yorgunluk ve duygusal hazır olma gerçek bir gerilim oluşturur. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`açıklık vs dinlenme ihtiyacı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `empathy` should not absorb: Pure debate skill or IQ verbal reasoning without affective weighing.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

behavioral isomorph `eq_tr_v1_iso_01`
### 15. RVI role

Roles: repeated_context_stability, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `empathy` between `empat` and adjacent prototypes; provisional evidence may inform separation of `empathy` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `empathy` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=emotional_disclosure; sdr_item_risk=low; tradeoff=açıklık vs dinlenme ihtiyacı; how_avoids_ideal_answer=yorgunluk ve duygusal hazır olma gerçek bir gerilim oluşturur`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 19: `eq_tr_v1_perspective_taking_001`

### 1. Question ID

`eq_tr_v1_perspective_taking_001`
### 2. Scenario family

`perspective_taking_family`
### 3. Primary dimension

`perspective_taking`
### 4. Secondary dimensions

`social_awareness`, `boundary_setting`
### 5. Construct definition (provisional)

Mentally constructing another viewpoint or interpretive frame before acting.
### 6. Prompt summary

Arkadaşın seni bir davetiye konusunda eleştiriyor; sen katılamayacağını söylemiştin. Onun neden kırgın olabileceğini düşünürsün — ilk iç tepkin ne olur?
### 7. Option summaries (A–D)

- **A:** Belki kendini değersiz hissetti; davetin onun için önemli olduğunu hatırlarsın.
- **B:** İki tarafın da haklı yanları olabileceğini, iletişim eksikliği olabileceğini düşünürsün.
- **C:** Onun gerekçesini dinlerim ama kendi önceliğimi de kısaca koyarım.
- **D:** Durumu kendi açımdan özetlerim; karşı tarafın bağlamını sonra sorarım.

### 8. Full option evidence vectors (copy deltas)

- **A** — perspective_taking: +0.75; social_awareness: -0.25
- **B** — perspective_taking: +0.48; social_awareness: -0.15
- **C** — boundary_setting: -0.28; perspective_taking: +0.10 (counter -0.10)
- **D** — conflict_approach: -0.18; perspective_taking: -0.42

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Güçlü perspektif alma.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.75 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.25 reflects authored trade-off weight, not validated psychometrics.
**B:** Dengeli çoklu perspektif.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.48 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
**C:** Öz odaklı çerçeveleme.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.28 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.10 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `perspective_taking` (-0.10) offsets apparent primary signal.
**D:** Karşı taraf perspektifi reddedilir.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (primary-target); magnitude -0.42 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `başkasının çerçevesi vs kendi gerekçen`; authoring note: eleştiriyi tamamen haklı veya haksız saymak zorunda değilsin. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`başkasının çerçevesi vs kendi gerekçen`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `perspective_taking` should not absorb: Persuasion skill or empathy affect without frame shift.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_02`
### 15. RVI role

Roles: semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `perspective_taking` between `yargic` and adjacent prototypes; provisional evidence may inform separation of `perspective_taking` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=perspective_taking_family; sdr_item_risk=low; tradeoff=başkasının çerçevesi vs kendi gerekçen; how_avoids_ideal_answer=eleştiriyi tamamen haklı veya haksız saymak zorunda değilsin`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 20: `eq_tr_v1_perspective_taking_002`

### 1. Question ID

`eq_tr_v1_perspective_taking_002`
### 2. Scenario family

`perspective_taking_family`
### 3. Primary dimension

`perspective_taking`
### 4. Secondary dimensions

`social_awareness`
### 5. Construct definition (provisional)

Mentally constructing another viewpoint or interpretive frame before acting.
### 6. Prompt summary

Takım toplantısında sessiz kalan bir meslektaşın vardı. Sonradan fikrinin göz ardı edildiğini fark ediyorsun. Onun yerinde olsan ne hissederdin?
### 7. Option summaries (A–D)

- **A:** Görünmez kalmış ve saygısızlık hissetmiş olabileceğini düşünürsün.
- **B:** Belki konuşmak istemediğini ama yine de dışlanmış hissetmiş olabileceğini varsayarsın.
- **C:** Toplantı dinamiğinin herkesi eşit davet etmediğini genel olarak değerlendirirsin.
- **D:** Sessiz kalmasının kendi tercihi olduğunu ve fazla yorum yapmazsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — perspective_taking: +0.75; social_awareness: -0.22
- **B** — perspective_taking: +0.48
- **C** — perspective_taking: +0.10; social_awareness: -0.18
- **D** — perspective_taking: -0.42

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Empatik perspektif simülasyonu.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.75 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Belirsizliği tolere eden perspektif.
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.48 reflects authored trade-off weight, not validated psychometrics.
**C:** Sistemik ama kişisel perspektif zayıf.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.10 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**D:** Perspektif alma düşük.
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (primary-target); magnitude -0.42 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `sessizlik yorumu vs dışlanma olasılığı`; authoring note: sessizlik hem tercih hem dışlanma olabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`sessizlik yorumu vs dışlanma olasılığı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `perspective_taking` should not absorb: Persuasion skill or empathy affect without frame shift.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_02`; behavioral isomorph `eq_tr_v1_iso_04`
### 15. RVI role

Roles: repeated_context_stability, response_variation, semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `perspective_taking` between `yargic` and adjacent prototypes; provisional evidence may inform separation of `perspective_taking` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=perspective_taking_family; sdr_item_risk=low; tradeoff=sessizlik yorumu vs dışlanma olasılığı; how_avoids_ideal_answer=sessizlik hem tercih hem dışlanma olabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 21: `eq_tr_v1_perspective_taking_003`

### 1. Question ID

`eq_tr_v1_perspective_taking_003`
### 2. Scenario family

`social_context_awareness`
### 3. Primary dimension

`perspective_taking`
### 4. Secondary dimensions

`conflict_approach`, `social_awareness`
### 5. Construct definition (provisional)

Mentally constructing another viewpoint or interpretive frame before acting.
### 6. Prompt summary

Bir arkadaş grubunda biri espri yaptı; başka biri gülmedi ve ortam gerildi. Gülmeyen kişinin içinde ne geçiyor olabilir diye düşünürsün.
### 7. Option summaries (A–D)

- **A:** Espriyi incitici bulmuş veya kendini hedef alınmış hissetmiş olabilir.
- **B:** O an dikkati dağılmış ya da mizah anlayışı farklı olabilir diye düşünürsün.
- **C:** Grup baskısı hissetmiş olabileceğini kısaca not edersin.
- **D:** Abartıyor olabileceğini düşünüp konuyu kapatırsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — conflict_approach: -0.20; perspective_taking: +0.68
- **B** — perspective_taking: +0.42
- **C** — perspective_taking: +0.22; social_awareness: -0.18
- **D** — perspective_taking: -0.45; social_awareness: -0.15

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Olası duygusal etki tahmini.; tradeoff_cost_on_conflict_approach
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.68 reflects authored trade-off weight, not validated psychometrics.
**B:** Alternatif açıklamalar üretir.
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.42 reflects authored trade-off weight, not validated psychometrics.
**C:** Sınırlı perspektif derinliği.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `perspective_taking` (primary-target); magnitude +0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
**D:** Perspektif reddi.
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (primary-target); magnitude -0.45 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `grup dinamiği vs bireysel duygu`; authoring note: gülmeme tek bir nedene indirgenmez. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`grup dinamiği vs bireysel duygu`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `perspective_taking` should not absorb: Persuasion skill or empathy affect without frame shift.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

behavioral isomorph `eq_tr_v1_iso_04`
### 15. RVI role

Roles: repeated_context_stability, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `perspective_taking` between `yargic` and adjacent prototypes; provisional evidence may inform separation of `perspective_taking` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=social_context_awareness; sdr_item_risk=low; tradeoff=grup dinamiği vs bireysel duygu; how_avoids_ideal_answer=gülmeme tek bir nedene indirgenmez`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 22: `eq_tr_v1_repair_orientation_001`

### 1. Question ID

`eq_tr_v1_repair_orientation_001`
### 2. Scenario family

`interpersonal_support`
### 3. Primary dimension

`repair_orientation`
### 4. Secondary dimensions

`empathy`
### 5. Construct definition (provisional)

Tendency to restore connection after relational rupture.
### 6. Prompt summary

Arkadaşına kaba bir mesaj attığını fark ettin; o henüz cevap vermedi. Ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Özür diler, niyetini açıklar ve konuşmak istediğini söylersin.
- **B:** Mesajını düzelten kısa bir takip gönderirsin.
- **C:** Zaman geçsin, kendiliğinden düzelir diye beklersin.
- **D:** Haklı olduğunu düşünüp mesajına dokunmazsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — empathy: -0.22; repair_orientation: +0.75
- **B** — empathy: -0.15; repair_orientation: +0.45
- **C** — conflict_approach: -0.12; repair_orientation: +0.08 (counter -0.10)
- **D** — assertiveness: +0.20; repair_orientation: -0.52

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Doğrudan onarım girişimi.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.75 reflects authored trade-off weight, not validated psychometrics.
**B:** Yazılı onarım.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
**C:** Pasif beklenti.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `repair_orientation` (-0.10) offsets apparent primary signal.
**D:** Onarım reddi.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (secondary/cross); magnitude +0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (primary-target); magnitude -0.52 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `özür vs zaman`; authoring note: hem aktif onarım hem bekleme savunulabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`özür vs zaman`
### 12. Social-desirability analysis

Item-level SDR risk tagged `moderate`. Moderate risk: some options may read as more socially desirable (supportive/listening); delta spread and counter-evidence intended to keep virtuous-sounding choices costly on other dimensions.
### 13. Construct-contamination analysis

Primary `repair_orientation` should not absorb: Self-erasure or unsafe reconciliation pressure.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_05`
### 15. RVI role

Roles: semantic_consistency, social_impression_risk, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `repair_orientation` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `repair_orientation` between `empat` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=interpersonal_support; sdr_item_risk=moderate; tradeoff=özür vs zaman; how_avoids_ideal_answer=hem aktif onarım hem bekleme savunulabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 23: `eq_tr_v1_repair_orientation_002`

### 1. Question ID

`eq_tr_v1_repair_orientation_002`
### 2. Scenario family

`repair_after_disagreement`
### 3. Primary dimension

`repair_orientation`
### 4. Secondary dimensions

`emotional_openness`, `empathy`
### 5. Construct definition (provisional)

Tendency to restore connection after relational rupture.
### 6. Prompt summary

Partnerinle tartıştınız; gece boyunca konuşmadınız. Sabah ne yaparsın?
### 7. Option summaries (A–D)

- **A:** İletişimi yeniden açmak için sakin bir mesaj veya kahve teklifi yaparsın. İlişki dinamiğini de göz önünde bulundururum.
- **B:** Önce özür veya ortak zemin cümlesiyle diyaloğu başlatırsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **C:** O adım atana kadar normal davranırsın, konuyu açmazsın. İlişki dinamiğini de göz önünde bulundururum.
- **D:** Hâlâ haklı olduğunu düşünerek mesafe korursun. İlişki dinamiğini de göz önünde bulundururum.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotional_openness: -0.22; repair_orientation: +0.75
- **B** — empathy: -0.18; repair_orientation: +0.45
- **C** — repair_orientation: +0.08 (counter -0.08)
- **D** — conflict_approach: +0.15; repair_orientation: -0.52

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Proaktif bağ onarımı.; tradeoff_cost_on_emotional_openness
- Provisional hypothesis: option wording plausibly signals lower `emotional_openness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.75 reflects authored trade-off weight, not validated psychometrics.
**B:** Sözel onarım.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
**C:** Bekle-gör onarımı.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.08 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `repair_orientation` (-0.08) offsets apparent primary signal.
**D:** Onarım ertelenir veya reddedilir.
- Provisional hypothesis: option wording plausibly signals higher `conflict_approach` (secondary/cross); magnitude +0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (primary-target); magnitude -0.52 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `ilk adım vs bekleme`; authoring note: sabah yakınlaşması zorunlu değildir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`ilk adım vs bekleme`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `repair_orientation` should not absorb: Self-erasure or unsafe reconciliation pressure.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

semantic pair `eq_tr_v1_sem_05`; behavioral isomorph `eq_tr_v1_iso_03`
### 15. RVI role

Roles: repeated_context_stability, semantic_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `repair_orientation` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `repair_orientation` between `empat` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=repair_after_disagreement; sdr_item_risk=low; tradeoff=ilk adım vs bekleme; how_avoids_ideal_answer=sabah yakınlaşması zorunlu değildir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 24: `eq_tr_v1_repair_orientation_003`

### 1. Question ID

`eq_tr_v1_repair_orientation_003`
### 2. Scenario family

`repeated_behavioral_patterns`
### 3. Primary dimension

`repair_orientation`
### 4. Secondary dimensions

`conflict_approach`, `assertiveness`
### 5. Construct definition (provisional)

Tendency to restore connection after relational rupture.
### 6. Prompt summary

İş yerinde yanlış anlaşılma yüzünden meslektaşın sana kırgın. Bu tür durumlar daha önce de oldu. Genelde ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Yanlış anlaşılmayı netleştirip özür veya açıklama yaparsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **B:** Kısa bir kontrol mesajı atıp yüz yüze konuşmayı planlarsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.
- **C:** Zamanla geçer diye müdahale etmezsin. İlişki dinamiğini de göz önünde bulundururum.
- **D:** Sorumluluğu tamamen karşı tarafa bırakırsın. Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.

### 8. Full option evidence vectors (copy deltas)

- **A** — conflict_approach: -0.22; repair_orientation: +0.68
- **B** — assertiveness: -0.18; repair_orientation: +0.42
- **C** — repair_orientation: +0.10 (counter -0.10)
- **D** — conflict_approach: -0.18; repair_orientation: -0.50

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Tekrarlayan onarım kalıbı.; tradeoff_cost_on_conflict_approach
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.68 reflects authored trade-off weight, not validated psychometrics.
**B:** Rutin düşük yoğunluklu onarım.
- Provisional hypothesis: option wording plausibly signals lower `assertiveness` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.42 reflects authored trade-off weight, not validated psychometrics.
**C:** Pasif onarım beklentisi.
- Provisional hypothesis: option wording plausibly signals higher `repair_orientation` (primary-target); magnitude +0.10 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `repair_orientation` (-0.10) offsets apparent primary signal.
**D:** Onarım sorumluluğu reddedilir.
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (primary-target); magnitude -0.50 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `tekrarlayan onarım alışkanlığı`; authoring note: her yanlış anlaşılma hemen konuşmayı gerektirmez. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`tekrarlayan onarım alışkanlığı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `repair_orientation` should not absorb: Self-erasure or unsafe reconciliation pressure.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

behavioral isomorph `eq_tr_v1_iso_03`
### 15. RVI role

Roles: repeated_context_stability, response_variation, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `repair_orientation` between `koruyucu` and adjacent prototypes; provisional evidence may inform separation of `repair_orientation` between `empat` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=repeated_behavioral_patterns; sdr_item_risk=low; tradeoff=tekrarlayan onarım alışkanlığı; how_avoids_ideal_answer=her yanlış anlaşılma hemen konuşmayı gerektirmez`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 25: `eq_tr_v1_self_awareness_001`

### 1. Question ID

`eq_tr_v1_self_awareness_001`
### 2. Scenario family

`internal_emotional_awareness`
### 3. Primary dimension

`self_awareness`
### 4. Secondary dimensions

`emotion_regulation`
### 5. Construct definition (provisional)

Early recognition of one's own emotion, need, or trigger before or while acting.
### 6. Prompt summary

Partnerin bugün mesafeli; sen gerginsin ve bunun nedenini tam bilmiyorsun. Kendi iç durumuna bakınca ilk fark ettiğin ne olur?
### 7. Option summaries (A–D)

- **A:** Onun davranışını kişisel algıladığını ve kaygının arttığını fark edersin.
- **B:** Yorgunluk ve stresin tepkini şişirdiğini düşünürsün.
- **C:** Henüz net bir duygu adı koyamazsın ama rahatsız olduğunu bilirsin.
- **D:** Sorun partnerde olduğu için kendi halini sorgulamazsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotion_regulation: -0.18; self_awareness: +0.72
- **B** — emotion_regulation: -0.15; self_awareness: +0.48
- **C** — self_awareness: +0.22 (counter -0.05)
- **D** — self_awareness: -0.55

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Tetikleyici farkındalığı yüksek.
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
**B:** Bağlamsal öz-farkındalık.; tradeoff_cost_on_emotion_regulation
- Provisional hypothesis: option wording plausibly signals lower `emotion_regulation` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.48 reflects authored trade-off weight, not validated psychometrics.
**C:** Kısmi duygusal farkındalık.
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `self_awareness` (-0.05) offsets apparent primary signal.
**D:** Öz-farkındalık düşük.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (primary-target); magnitude -0.55 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `iç tetik vs dış atfetme`; authoring note: mesafe hem kişisel hem bağlamsal yorumlanabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`iç tetik vs dış atfetme`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `self_awareness` should not absorb: Intellectual self-description without behavioral cost.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_05`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `self_awareness` between `empat` and adjacent prototypes; provisional evidence may inform separation of `self_awareness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`substantially_rewritten_legacy_concept; scenario_family=internal_emotional_awareness; sdr_item_risk=low; tradeoff=iç tetik vs dış atfetme; how_avoids_ideal_answer=mesafe hem kişisel hem bağlamsal yorumlanabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 26: `eq_tr_v1_self_awareness_002`

### 1. Question ID

`eq_tr_v1_self_awareness_002`
### 2. Scenario family

`social_context_awareness`
### 3. Primary dimension

`self_awareness`
### 4. Secondary dimensions

`social_awareness`, `boundary_setting`
### 5. Construct definition (provisional)

Early recognition of one's own emotion, need, or trigger before or while acting.
### 6. Prompt summary

Bir sosyal ortamda aniden içe kapanma isteği duyuyorsun. Bu tepkinin altında ne olabileceğini nasıl değerlendirirsin?
### 7. Option summaries (A–D)

- **A:** Sosyal yorgunluk veya tetiklenen bir anı olabileceğini fark edersin.
- **B:** Ortamın gürültülü olduğunu ve sınırlarının dolmakta olduğunu düşünürsün.
- **C:** Basitçe modunun düşük olduğunu söylersin, derinine inmezsin.
- **D:** Ortamın seni rahatsız ettiğini düşünür, kendini sorgulamazsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — self_awareness: +0.70; social_awareness: -0.22
- **B** — boundary_setting: -0.18; self_awareness: +0.44
- **C** — self_awareness: +0.15
- **D** — self_awareness: -0.40; social_awareness: +0.12

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Çok katmanlı öz-gözlem.; tradeoff_cost_on_social_awareness
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.70 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
**B:** Bağlamsal öz analiz.; tradeoff_cost_on_boundary_setting
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.44 reflects authored trade-off weight, not validated psychometrics.
**C:** Yüzeysel duygu etiketi.
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.15 reflects authored trade-off weight, not validated psychometrics.
**D:** Dış atfetme eğilimi.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (primary-target); magnitude -0.40 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (secondary/cross); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `iç geri çekilme vs ortam etkisi`; authoring note: kapanma hem içsel hem dışsal nedenlerle açıklanabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`iç geri çekilme vs ortam etkisi`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `self_awareness` should not absorb: Intellectual self-description without behavioral cost.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

none registered
### 15. RVI role

Roles: response_variation, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `self_awareness` between `empat` and adjacent prototypes; provisional evidence may inform separation of `self_awareness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=social_context_awareness; sdr_item_risk=low; tradeoff=iç geri çekilme vs ortam etkisi; how_avoids_ideal_answer=kapanma hem içsel hem dışsal nedenlerle açıklanabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 27: `eq_tr_v1_self_awareness_003`

### 1. Question ID

`eq_tr_v1_self_awareness_003`
### 2. Scenario family

`stress_and_regulation`
### 3. Primary dimension

`self_awareness`
### 4. Secondary dimensions

`conflict_approach`
### 5. Construct definition (provisional)

Early recognition of one's own emotion, need, or trigger before or while acting.
### 6. Prompt summary

Yoğun bir günün ardından küçük bir yorum seni aşırı derecede kızdırdı. Tepkinin büyüklüğü hakkında kendine ne dersin?
### 7. Option summaries (A–D)

- **A:** Biriktirilmiş stresin bu tepkiyi büyüttüğünü fark edersin.
- **B:** Konunun sana dokunan bir yönü olabileceğini kabul edersin.
- **C:** Haklı öfke olduğunu düşünür, kendi rolünü sorgulamazsın.
- **D:** Diğer kişinin kasıtlı provokasyon yaptığını varsayarsın.

### 8. Full option evidence vectors (copy deltas)

- **A** — emotion_regulation: +0.25; self_awareness: -0.72
- **B** — self_awareness: -0.48
- **C** — assertiveness: +0.20; self_awareness: -0.22 (counter -0.08)
- **D** — conflict_approach: -0.18; self_awareness: +0.55

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Tetikleyici birikimi fark edilir.
- Provisional hypothesis: option wording plausibly signals higher `emotion_regulation` (secondary/cross); magnitude +0.25 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (primary-target); magnitude -0.72 reflects authored trade-off weight, not validated psychometrics.
**B:** Orta düzey öz-yansıma.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (primary-target); magnitude -0.48 reflects authored trade-off weight, not validated psychometrics.
**C:** Sınırlı öz-farkındalık.
- Provisional hypothesis: option wording plausibly signals higher `assertiveness` (secondary/cross); magnitude +0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals lower `self_awareness` (primary-target); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `self_awareness` (-0.08) offsets apparent primary signal.
**D:** Öz-farkındalık yerine dış suçlama.; tradeoff_cost_on_conflict_approach
- Provisional hypothesis: option wording plausibly signals lower `conflict_approach` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `self_awareness` (primary-target); magnitude +0.55 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `birikmiş stres vs haklı öfke`; authoring note: aşırı tepki hem birikim hem değer ihlali olabilir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`birikmiş stres vs haklı öfke`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `self_awareness` should not absorb: Intellectual self-description without behavioral cost.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

reverse pair `eq_tr_v1_rev_05`
### 15. RVI role

Roles: reverse_consistency, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `self_awareness` between `empat` and adjacent prototypes; provisional evidence may inform separation of `self_awareness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=stress_and_regulation; sdr_item_risk=low; tradeoff=birikmiş stres vs haklı öfke; how_avoids_ideal_answer=aşırı tepki hem birikim hem değer ihlali olabilir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 28: `eq_tr_v1_social_awareness_001`

### 1. Question ID

`eq_tr_v1_social_awareness_001`
### 2. Scenario family

`interpersonal_support`
### 3. Primary dimension

`social_awareness`
### 4. Secondary dimensions

`empathy`, `boundary_setting`
### 5. Construct definition (provisional)

Reading situational tone, reciprocity, and interpersonal timing cues.
### 6. Prompt summary

Bir davette yalnız oturan birini fark ettin; grup halinde sohbet ediliyor. Ortamın dinamiğini nasıl okursun?
### 7. Option summaries (A–D)

- **A:** Kişinin dahil edilmediğini ve muhtemelen dışlanmış hissettiğini düşünürsün.
- **B:** Belki yorgun veya tanıdık aradığını, henüz emin olmadığını varsayarsın.
- **C:** Kendi sohbetine odaklanır, fazla yorum yapmazsın. İlişki dinamiğini de göz önünde bulundururum.
- **D:** Tercih meselesi olduğunu düşünüp dikkat etmezsin. İlişki dinamiğini de göz önünde bulundururum.

### 8. Full option evidence vectors (copy deltas)

- **A** — empathy: -0.22; social_awareness: +0.72
- **B** — boundary_setting: -0.18; social_awareness: +0.45
- **C** — social_awareness: +0.12 (counter -0.08)
- **D** — social_awareness: -0.48

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yüksek sosyal sinyal okuma.; tradeoff_cost_on_empathy
- Provisional hypothesis: option wording plausibly signals lower `empathy` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.72 reflects authored trade-off weight, not validated psychometrics.
**B:** Çoklu olasılık okuma.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.45 reflects authored trade-off weight, not validated psychometrics.
**C:** Sınırlı ortam taraması.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `social_awareness` (-0.08) offsets apparent primary signal.
**D:** Sosyal ipuçları göz ardı.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (primary-target); magnitude -0.48 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `dışlanma sinyali vs kişisel tercih`; authoring note: yalnız oturmak tek anlama gelmez. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`dışlanma sinyali vs kişisel tercih`
### 12. Social-desirability analysis

Item-level SDR risk tagged `moderate`. Moderate risk: some options may read as more socially desirable (supportive/listening); delta spread and counter-evidence intended to keep virtuous-sounding choices costly on other dimensions.
### 13. Construct-contamination analysis

Primary `social_awareness` should not absorb: Popularity, gossip skill, or status seeking.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

none registered
### 15. RVI role

Roles: social_impression_risk, timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `social_awareness` between `yargic` and adjacent prototypes; provisional evidence may inform separation of `social_awareness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**high**
### 19. Provenance

`newly_authored; scenario_family=interpersonal_support; sdr_item_risk=moderate; tradeoff=dışlanma sinyali vs kişisel tercih; how_avoids_ideal_answer=yalnız oturmak tek anlama gelmez`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 29: `eq_tr_v1_social_awareness_002`

### 1. Question ID

`eq_tr_v1_social_awareness_002`
### 2. Scenario family

`perspective_taking_family`
### 3. Primary dimension

`social_awareness`
### 4. Secondary dimensions

`perspective_taking`, `boundary_setting`
### 5. Construct definition (provisional)

Reading situational tone, reciprocity, and interpersonal timing cues.
### 6. Prompt summary

Arkadaş grubunda biri espri yaptıktan sonra ortamın gerildiğini hissediyorsun. Ne fark edersin?
### 7. Option summaries (A–D)

- **A:** Espriyi yanlış yorumlayan veya incinen biri olabileceğini düşünürsün.
- **B:** Genel olarak mizahın o an uygun olmadığını sezersin. İlişki dinamiğini de göz önünde bulundururum.
- **C:** Sadece kısa bir sessizlik olduğunu sanır, fazla anlam yüklemezsin.
- **D:** Gerilimi fark etmez, sohbete devam edersin. İlişki dinamiğini de göz önünde bulundururum.

### 8. Full option evidence vectors (copy deltas)

- **A** — perspective_taking: -0.22; social_awareness: +0.70
- **B** — boundary_setting: -0.18; social_awareness: +0.44
- **C** — social_awareness: +0.15
- **D** — social_awareness: -0.42

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Gerilim kaynağı hipotezi.; tradeoff_cost_on_perspective_taking
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (secondary/cross); magnitude -0.22 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.70 reflects authored trade-off weight, not validated psychometrics.
**B:** Bağlamsal uygunluk farkındalığı.
- Provisional hypothesis: option wording plausibly signals lower `boundary_setting` (secondary/cross); magnitude -0.18 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.44 reflects authored trade-off weight, not validated psychometrics.
**C:** Düşük sosyal okuma.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.15 reflects authored trade-off weight, not validated psychometrics.
**D:** Sosyal sinyal kaçırma.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (primary-target); magnitude -0.42 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `grup tonu vs bireysel tepki`; authoring note: gerilim her zaman kişisel değildir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`grup tonu vs bireysel tepki`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `social_awareness` should not absorb: Popularity, gossip skill, or status seeking.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

none registered
### 15. RVI role

Roles: timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `social_awareness` between `yargic` and adjacent prototypes; provisional evidence may inform separation of `social_awareness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=perspective_taking_family; sdr_item_risk=low; tradeoff=grup tonu vs bireysel tepki; how_avoids_ideal_answer=gerilim her zaman kişisel değildir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---

## Item 30: `eq_tr_v1_social_awareness_003`

### 1. Question ID

`eq_tr_v1_social_awareness_003`
### 2. Scenario family

`social_context_awareness`
### 3. Primary dimension

`social_awareness`
### 4. Secondary dimensions

`repair_orientation`, `perspective_taking`
### 5. Construct definition (provisional)

Reading situational tone, reciprocity, and interpersonal timing cues.
### 6. Prompt summary

Yeni bir iş ekibine katıldın; toplantıda kimlerin söz aldığını ve kimlerin geri planda kaldığını fark ediyorsun. İlk izlenimin ne?
### 7. Option summaries (A–D)

- **A:** Resmi hiyerarşi ve informal grupların katılımı etkilediğini düşünürsün.
- **B:** Bazı konuların belirli kişileri daha çok devreye soktuğunu not edersin.
- **C:** Ortamın gerginliğini fark ederim; yine de kendi planıma göre ilerlerim.
- **D:** Sosyal ipuçlarını not ederim ama doğrudan müdahale etmeden izlerim.

### 8. Full option evidence vectors (copy deltas)

- **A** — repair_orientation: -0.20; social_awareness: +0.68
- **B** — perspective_taking: -0.15; social_awareness: +0.42
- **C** — social_awareness: +0.12 (counter -0.05)
- **D** — social_awareness: -0.45

### 9. Why each delta direction is justified (provisional hypothesis language)

**A:** Yapısal sosyal okuma.; tradeoff_cost_on_repair_orientation
- Provisional hypothesis: option wording plausibly signals lower `repair_orientation` (secondary/cross); magnitude -0.20 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.68 reflects authored trade-off weight, not validated psychometrics.
**B:** Konu-bazlı dinamik farkındalık.; tradeoff_cost_on_perspective_taking
- Provisional hypothesis: option wording plausibly signals lower `perspective_taking` (secondary/cross); magnitude -0.15 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.42 reflects authored trade-off weight, not validated psychometrics.
**C:** Gözlem erteleme.
- Provisional hypothesis: option wording plausibly signals higher `social_awareness` (primary-target); magnitude +0.12 reflects authored trade-off weight, not validated psychometrics.
- Provisional hypothesis: counter-evidence on `social_awareness` (-0.05) offsets apparent primary signal.
**D:** Sosyal dinamikleri okumama.
- Provisional hypothesis: option wording plausibly signals lower `social_awareness` (primary-target); magnitude -0.45 reflects authored trade-off weight, not validated psychometrics.

### 10. Why no option is globally correct

Scenario frames `güç dinamiği vs eşit katılım varsayımı`; authoring note: erken izlenimler kesin hüküm değildir. No option dominates all dimensions without trade-off cost.
### 11. Behavioral trade-off

`güç dinamiği vs eşit katılım varsayımı`
### 12. Social-desirability analysis

Item-level SDR risk tagged `low`. Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic.
### 13. Construct-contamination analysis

Primary `social_awareness` should not absorb: Popularity, gossip skill, or status seeking.. Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review.
### 14. Semantic/reverse/isomorph links

none registered
### 15. RVI role

Roles: timing_quality. Supports response-validity checks (consistency/timing) separate from trait scoring.
### 16. Difficult persona pairs informed

provisional evidence may inform separation of `social_awareness` between `yargic` and adjacent prototypes; provisional evidence may inform separation of `social_awareness` between `muhafiz` and adjacent prototypes (cautious; not deterministic).
### 17. Residual ambiguity

Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination.
### 18. Human-review priority

**medium**
### 19. Provenance

`newly_authored; scenario_family=social_context_awareness; sdr_item_risk=low; tradeoff=güç dinamiği vs eşit katılım varsayımı; how_avoids_ideal_answer=erken izlenimler kesin hüküm değildir`
### 20. Final internal disposition

`internal_accept_for_red_team`

---
