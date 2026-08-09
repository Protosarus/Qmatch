# EQ Pilot TR v1 Review Candidate 1 — Evidence Mapping Review

**Source:** `assets/data/assessment_v3/eq/eq_pilot_tr_v1_review_candidate_1.json`
**Coverage:** All **30** items; fields 1–20 each.
**Note:** Option-level `evidence_strength`, `social_desirability_risk`, and `response_style_risk` are included.

> Provisional authoring hypotheses only. Expert psychological review pending.

## Overview (30 items)

| # | Question ID | Scenario family | Primary | Secondary | Review priority |
|---|---|---|---|---|---|
| 1 | `eq_tr_v1_assertiveness_001` | boundary_and_request_conflicts | `assertiveness` | boundary_setting, repair_orientation | medium |
| 2 | `eq_tr_v1_assertiveness_002` | competing_values_and_tradeoffs | `assertiveness` | boundary_setting, social_awareness | high |
| 3 | `eq_tr_v1_assertiveness_003` | repeated_behavioral_patterns | `assertiveness` | boundary_setting, repair_orientation | high |
| 4 | `eq_tr_v1_boundary_setting_001` | boundary_and_request_conflicts | `boundary_setting` | assertiveness | medium |
| 5 | `eq_tr_v1_boundary_setting_002` | competing_values_and_tradeoffs | `boundary_setting` | assertiveness, repair_orientation | medium |
| 6 | `eq_tr_v1_boundary_setting_003` | repeated_behavioral_patterns | `boundary_setting` | assertiveness, conflict_approach, repair_orientation | high |
| 7 | `eq_tr_v1_conflict_approach_001` | boundary_and_request_conflicts | `conflict_approach` | assertiveness, emotion_regulation | medium |
| 8 | `eq_tr_v1_conflict_approach_002` | repair_after_disagreement | `conflict_approach` | emotion_regulation, repair_orientation, social_awareness | medium |
| 9 | `eq_tr_v1_conflict_approach_003` | competing_values_and_tradeoffs | `conflict_approach` | assertiveness, emotion_regulation, perspective_taking | high |
| 10 | `eq_tr_v1_emotion_regulation_001` | internal_emotional_awareness | `emotion_regulation` | empathy, social_awareness | medium |
| 11 | `eq_tr_v1_emotion_regulation_002` | stress_and_regulation | `emotion_regulation` | emotional_openness, self_awareness | medium |
| 12 | `eq_tr_v1_emotion_regulation_003` | stress_and_regulation | `emotion_regulation` | perspective_taking, self_awareness | medium |
| 13 | `eq_tr_v1_emotional_openness_001` | internal_emotional_awareness | `emotional_openness` | boundary_setting, empathy, self_awareness | high |
| 14 | `eq_tr_v1_emotional_openness_002` | emotional_disclosure | `emotional_openness` | conflict_approach, empathy | high |
| 15 | `eq_tr_v1_emotional_openness_003` | emotional_disclosure | `emotional_openness` | boundary_setting, empathy, social_awareness | medium |
| 16 | `eq_tr_v1_empathy_001` | interpersonal_support | `empathy` | boundary_setting | high |
| 17 | `eq_tr_v1_empathy_002` | repair_after_disagreement | `empathy` | assertiveness, repair_orientation | medium |
| 18 | `eq_tr_v1_empathy_003` | emotional_disclosure | `empathy` | boundary_setting, emotional_openness | high |
| 19 | `eq_tr_v1_perspective_taking_001` | perspective_taking_family | `perspective_taking` | boundary_setting, social_awareness | medium |
| 20 | `eq_tr_v1_perspective_taking_002` | perspective_taking_family | `perspective_taking` | social_awareness | medium |
| 21 | `eq_tr_v1_perspective_taking_003` | social_context_awareness | `perspective_taking` | social_awareness | medium |
| 22 | `eq_tr_v1_repair_orientation_001` | interpersonal_support | `repair_orientation` | assertiveness, empathy | high |
| 23 | `eq_tr_v1_repair_orientation_002` | repair_after_disagreement | `repair_orientation` | conflict_approach, emotional_openness, empathy | medium |
| 24 | `eq_tr_v1_repair_orientation_003` | repeated_behavioral_patterns | `repair_orientation` | assertiveness, conflict_approach | medium |
| 25 | `eq_tr_v1_self_awareness_001` | internal_emotional_awareness | `self_awareness` | emotion_regulation | medium |
| 26 | `eq_tr_v1_self_awareness_002` | social_context_awareness | `self_awareness` | boundary_setting, social_awareness | medium |
| 27 | `eq_tr_v1_self_awareness_003` | stress_and_regulation | `self_awareness` | assertiveness, emotion_regulation | high |
| 28 | `eq_tr_v1_social_awareness_001` | interpersonal_support | `social_awareness` | empathy, perspective_taking | high |
| 29 | `eq_tr_v1_social_awareness_002` | perspective_taking_family | `social_awareness` | perspective_taking | medium |
| 30 | `eq_tr_v1_social_awareness_003` | social_context_awareness | `social_awareness` | perspective_taking | medium |

## Item 1: `eq_tr_v1_assertiveness_001`

### 1. Question ID

`eq_tr_v1_assertiveness_001`
### 2. Scenario family

`boundary_and_request_conflicts`
### 3. Primary dimension

`assertiveness`
### 4. Secondary dimensions

`boundary_setting`, `repair_orientation`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`assertiveness`).
### 6. Prompt summary

Arkadaşın senin adına bir plan yaptı; katılmak istemiyorsun ama hayır demek onu kırabilir. Ne söylersin?
### 7. Option summaries (A–D)

- **A:** Teşekkür eder, katılamayacağını ve nedenini açıkça belirtirsin.
- **B:** Katılmayacağımı yumuşak bir ifadeyle söylerim; gerekçeyi kısa tutarım.
- **C:** Alternatif bir zaman öneririm; katılmama kararımı net ama yumuşak tutarım.
- **D:** Şimdilik uyumlu görünürüm; sonra yalnızken ne istediğimi netleştiririm.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.75; boundary_setting: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: assertiveness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: assertiveness: +0.20; repair_orientation: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: -0.55; boundary_setting: -0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `açık ret vs uyum`; each option carries relational cost.

### 11. Behavioral trade-off

`açık ret vs uyum`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `assertiveness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_04`; reverse `eq_tr_v1_rev_03`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=boundary_and_request_conflicts; sdr_item_risk=low; tradeoff=açık ret vs uyum; how_avoids_ideal_answer=hayır demek kırıcı olmak zorunda değildir`

### 20. Final internal disposition

`internal_accept_for_candidate`

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

See canonical_dimension_registry_v1 (`assertiveness`).
### 6. Prompt summary

Toplantıda fikrin kesildi; tekrar söz almak istiyorsun. Ortam rekabetçi. Nasıl davranırsın?
### 7. Option summaries (A–D)

- **A:** Kibarca söz isteyip görüşünü tamamlarsın.
- **B:** Chat üzerinden «devam etmek isterim» yazıp söz alırsın.
- **C:** Konu geçene kadar beklersin, sonra kısaca eklersin.
- **D:** Söylenmeyen kısmı önemsemeden susarsın.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.75; boundary_setting: +0.20; evidence_strength: 0.65; social_desirability_risk: `moderate`; response_style_risk: `low`
- **B** — deltas: assertiveness: +0.45; social_awareness: +0.20; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: assertiveness: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `ses alma vs grup akışı`; each option carries relational cost.

### 11. Behavioral trade-off

`ses alma vs grup akışı`

### 12. Social-desirability analysis

Item-level SDR `moderate`.

### 13. Construct-contamination analysis

Primary `assertiveness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_04`; reverse `None`; isomorph `eq_tr_v1_iso_02`

### 15. RVI role

['repeated_context_stability', 'semantic_consistency', 'social_impression_risk', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=competing_values_and_tradeoffs; sdr_item_risk=moderate; tradeoff=ses alma vs grup akışı; how_avoids_ideal_answer=farklı iletişim kanalları eşit derecede geçerli`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 3: `eq_tr_v1_assertiveness_003`

### 1. Question ID

`eq_tr_v1_assertiveness_003`
### 2. Scenario family

`repeated_behavioral_patterns`
### 3. Primary dimension

`assertiveness`
### 4. Secondary dimensions

`boundary_setting`, `repair_orientation`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`assertiveness`).
### 6. Prompt summary

Partnerin sürekli son dakika plan değiştiriyor; sen buna tepki göstermek istiyorsun. Uzun vadede ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Değişikliklerin seni zorladığını ve önceden haber vermesini istersin.
- **B:** Esnek olduğun ve olmadığın durumları örnekle açıklarsın.
- **C:** Bir kez söylersin ama sonra yine uyum sağlarsın.
- **D:** Alışkanlık haline getirir, şikâyet etmezsin.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.75; boundary_setting: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: assertiveness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: assertiveness: +0.15; repair_orientation: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `plan güvenilirliği vs esneklik`; each option carries relational cost.

### 11. Behavioral trade-off

`plan güvenilirliği vs esneklik`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `assertiveness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_03`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=repeated_behavioral_patterns; sdr_item_risk=low; tradeoff=plan güvenilirliği vs esneklik; how_avoids_ideal_answer=tekrarlayan davranış net konuşmayı gerektirebilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

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

See canonical_dimension_registry_v1 (`boundary_setting`).
### 6. Prompt summary

Aile toplantısında seni rahatsız eden bir konu yine gündeme geliyor. Her seferinde konu değiştirilmişti. Bu sefer ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Sakin ama net bir şekilde bu konuyu konuşmak istemediğini söylersin.
- **B:** Neden rahatsız olduğunu kısaca açıklayıp alternatif konu önerirsin.
- **C:** Yine konuyu değiştirmeye çalışırsın, doğrudan söylemezsin.
- **D:** Konuyu savuştururum; ilişkiyi germemek için sınırımı şimdilik sessiz tutarım.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.20; boundary_setting: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: assertiveness: +0.20; boundary_setting: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: boundary_setting: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: -0.20; boundary_setting: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `net sınır vs huzur koruma`; each option carries relational cost.

### 11. Behavioral trade-off

`net sınır vs huzur koruma`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `boundary_setting` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_03`; reverse `eq_tr_v1_rev_02`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`adapted_from_legacy_scenario; scenario_family=boundary_and_request_conflicts; sdr_item_risk=low; tradeoff=net sınır vs huzur koruma; how_avoids_ideal_answer=doğrudan söylemek veya dolaylı yönlendirmek savunulabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

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

See canonical_dimension_registry_v1 (`boundary_setting`).
### 6. Prompt summary

İş arkadaşın sürekli mesai saati dışında yazıyor. Bu ritim seni yoruyor. Nasıl yaklaşırsın?
### 7. Option summaries (A–D)

- **A:** Mesai dışı yanıt vermeyeceğini ve acil durum tanımını netleştirirsin.
- **B:** Yorgun olduğunu söyleyip ertesi gün dönüş yapacağını belirtirsin.
- **C:** Çoğu mesaja yine cevap verirsin ama geciktirirsin.
- **D:** İlişkiyi bozmamak için her mesaja anında dönersin.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.30; boundary_setting: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: boundary_setting: +0.15; repair_orientation: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: -0.20; boundary_setting: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `iş-yaşam sınırı vs erişilebilirlik`; each option carries relational cost.

### 11. Behavioral trade-off

`iş-yaşam sınırı vs erişilebilirlik`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `boundary_setting` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_03`; reverse `None`; isomorph `eq_tr_v1_iso_02`

### 15. RVI role

['repeated_context_stability', 'semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=competing_values_and_tradeoffs; sdr_item_risk=low; tradeoff=iş-yaşam sınırı vs erişilebilirlik; how_avoids_ideal_answer=hem net kural hem esnek yanıt makul`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 6: `eq_tr_v1_boundary_setting_003`

### 1. Question ID

`eq_tr_v1_boundary_setting_003`
### 2. Scenario family

`repeated_behavioral_patterns`
### 3. Primary dimension

`boundary_setting`
### 4. Secondary dimensions

`assertiveness`, `conflict_approach`, `repair_orientation`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`boundary_setting`).
### 6. Prompt summary

Flörtün plansız sık sık gelmek istiyor; sen düzenli programını korumak istiyorsun. Tekrarlayan durumda ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Ortak bir görüşme ritmi önerir, hangi günler uygun olduğunu netleştirirsin.
- **B:** Esnek olduğun günleri söyler, diğerlerinde meşgul olduğunu hatırlatırsın.
- **C:** Hayır demekte zorlanır, programını sık sık değiştirirsin.
- **D:** Rahatsız ettiğini söylemeden uzak durmaya çalışırsın.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.20; boundary_setting: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: boundary_setting: -0.20; repair_orientation: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: boundary_setting: -0.55; conflict_approach: -0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `program vs spontane yakınlık`; each option carries relational cost.

### 11. Behavioral trade-off

`program vs spontane yakınlık`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `boundary_setting` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_02`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=repeated_behavioral_patterns; sdr_item_risk=low; tradeoff=program vs spontane yakınlık; how_avoids_ideal_answer=düzen isteği ile esneklik gerçek bir gerilimdir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 7: `eq_tr_v1_conflict_approach_001`

### 1. Question ID

`eq_tr_v1_conflict_approach_001`
### 2. Scenario family

`boundary_and_request_conflicts`
### 3. Primary dimension

`conflict_approach`
### 4. Secondary dimensions

`assertiveness`, `emotion_regulation`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`conflict_approach`).
### 6. Prompt summary

Ev arkadaşın ortak alanı farklı kullanıyor; bu seni rahatsız ediyor. Henüz konuşmadınız. İlk hamlen ne olur?
### 7. Option summaries (A–D)

- **A:** Ortak kuralları konuşmak için uygun bir zaman ayırırsın.
- **B:** Kısa bir mesajla rahatsızlığını belirtip yüz yüze konuşmayı önerirsin.
- **C:** Konuyu ertelemeyi öneririm; soğuyunca daha net konuşabileceğimizi söylerim.
- **D:** Kısa bir ara isterim; kendi tepkimi toplayıp sonra dönerim.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.20; conflict_approach: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: assertiveness: +0.20; conflict_approach: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: conflict_approach: -0.20; emotion_regulation: +0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: conflict_approach: -0.30; emotion_regulation: +0.30; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `erken konuşma vs bekleme`; each option carries relational cost.

### 11. Behavioral trade-off

`erken konuşma vs bekleme`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `conflict_approach` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_04`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=boundary_and_request_conflicts; sdr_item_risk=low; tradeoff=erken konuşma vs bekleme; how_avoids_ideal_answer=hem doğrudan hem dolaylı giriş makul`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 8: `eq_tr_v1_conflict_approach_002`

### 1. Question ID

`eq_tr_v1_conflict_approach_002`
### 2. Scenario family

`repair_after_disagreement`
### 3. Primary dimension

`conflict_approach`
### 4. Secondary dimensions

`emotion_regulation`, `repair_orientation`, `social_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`conflict_approach`).
### 6. Prompt summary

İki arkadaşın senin yanında tartışmaya başladı. Arabuluculuk yapmak mı, tarafsız kalmak mı — eğilimin ne?
### 7. Option summaries (A–D)

- **A:** Her ikisinin de duyulmasını sağlayıp sakinleştirmeye çalışırsın.
- **B:** Kendi görüşünü söylemeden konuyu ertelemeyi teklif edersin.
- **C:** Taraf tutmadan dinler, müdahale etmezsin.
- **D:** Ortamdan uzaklaşırsın, sorun kendi haline kalsın.

### 8. Full option evidence vectors

- **A** — deltas: conflict_approach: +0.60; repair_orientation: +0.30; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: conflict_approach: +0.20; emotion_regulation: +0.30; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: conflict_approach: -0.15; social_awareness: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: conflict_approach: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `arabuluculuk vs tarafsızlık`; each option carries relational cost.

### 11. Behavioral trade-off

`arabuluculuk vs tarafsızlık`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `conflict_approach` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `None`

### 15. RVI role

['response_variation', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=repair_after_disagreement; sdr_item_risk=low; tradeoff=arabuluculuk vs tarafsızlık; how_avoids_ideal_answer=müdahale etmemek de bir tercihtir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 9: `eq_tr_v1_conflict_approach_003`

### 1. Question ID

`eq_tr_v1_conflict_approach_003`
### 2. Scenario family

`competing_values_and_tradeoffs`
### 3. Primary dimension

`conflict_approach`
### 4. Secondary dimensions

`assertiveness`, `emotion_regulation`, `perspective_taking`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`conflict_approach`).
### 6. Prompt summary

İş yerinde ekip içi bir anlaşmazlık büyüyor; sen farklı bir çözüm görüyorsun. Toplantıda nasıl katılırsın?
### 7. Option summaries (A–D)

- **A:** Alternatif çözümünü gerekçeleriyle sunar, diyaloğu açarsın.
- **B:** Endişeni kısaca belirtir, başkalarının fikrini sorarsın.
- **C:** Tartışmayı kısa keserim; ortak bir ara çözüm önermeden önce nabız yoklarım.
- **D:** Meslektaşların yanında sert bir şekilde karşı çıkarsın.

### 8. Full option evidence vectors

- **A** — deltas: assertiveness: +0.20; conflict_approach: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: conflict_approach: +0.45; perspective_taking: +0.20; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: conflict_approach: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: conflict_approach: -0.55; emotion_regulation: -0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `muhalefet vs grup uyumu`; each option carries relational cost.

### 11. Behavioral trade-off

`muhalefet vs grup uyumu`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `conflict_approach` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_04`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=competing_values_and_tradeoffs; sdr_item_risk=low; tradeoff=muhalefet vs grup uyumu; how_avoids_ideal_answer=sert karşı çıkma ile susmak farklı maliyetler taşır`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 10: `eq_tr_v1_emotion_regulation_001`

### 1. Question ID

`eq_tr_v1_emotion_regulation_001`
### 2. Scenario family

`internal_emotional_awareness`
### 3. Primary dimension

`emotion_regulation`
### 4. Secondary dimensions

`empathy`, `social_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`emotion_regulation`).
### 6. Prompt summary

Gergin bir ekip toplantısında bir meslektaşın gözyaşlarına hakim olamadı. İlk içgüdün ne olur?
### 7. Option summaries (A–D)

- **A:** Ortamı yumuşatmak için kısa bir ara önerir, tonunu sakin tutarsın.
- **B:** Konuyu daha sonra ele almak üzere toplantıyı yönlendirirsin.
- **C:** Tartışmaya devam edersin; duyguların zamanla yatışacağını düşünürsün.
- **D:** Rahatsız edici bulup konuyu değiştirirsin, duyguyu görmezden gelirsin.

### 8. Full option evidence vectors

- **A** — deltas: emotion_regulation: +0.75; social_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: emotion_regulation: +0.45; social_awareness: +0.20; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: emotion_regulation: -0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: emotion_regulation: -0.55; empathy: -0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `duygusal tempo vs gündem baskısı`; each option carries relational cost.

### 11. Behavioral trade-off

`duygusal tempo vs gündem baskısı`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `emotion_regulation` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_06`; reverse `None`; isomorph `None`

### 15. RVI role

['semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`adapted_from_legacy_scenario; scenario_family=internal_emotional_awareness; sdr_item_risk=low; tradeoff=duygusal tempo vs gündem baskısı; how_avoids_ideal_answer=ara vermek, devam etmek veya yönlendirmek makul seçenekler`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 11: `eq_tr_v1_emotion_regulation_002`

### 1. Question ID

`eq_tr_v1_emotion_regulation_002`
### 2. Scenario family

`stress_and_regulation`
### 3. Primary dimension

`emotion_regulation`
### 4. Secondary dimensions

`emotional_openness`, `self_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`emotion_regulation`).
### 6. Prompt summary

Flörtünle mesajlaşırken ani bir gerilim hissediyorsun. Yazmadan önce duygunu nasıl yönetirsin?
### 7. Option summaries (A–D)

- **A:** Birkaç dakika ara verir, ne hissettiğini adlandırıp sonra yanıtlarsın.
- **B:** Tonunu yumuşatmak için mesajı yeniden yazarsın.
- **C:** Hızlıca yanıt verirsin ama sonra gereksiz olduğunu fark edersin.
- **D:** Hissettiklerini olduğu gibi yazarsın, pişman olma ihtimalini göze alırsın.

### 8. Full option evidence vectors

- **A** — deltas: emotion_regulation: +0.75; self_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: emotion_regulation: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: emotion_regulation: -0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: emotion_regulation: -0.55; emotional_openness: +0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `duraklama vs anlık ifade`; each option carries relational cost.

### 11. Behavioral trade-off

`duraklama vs anlık ifade`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `emotion_regulation` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_06`; reverse `None`; isomorph `eq_tr_v1_iso_05`

### 15. RVI role

['repeated_context_stability', 'semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=stress_and_regulation; sdr_item_risk=low; tradeoff=duraklama vs anlık ifade; how_avoids_ideal_answer=hem erteleme hem anlık yanıt gerçek tercihlerdir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 12: `eq_tr_v1_emotion_regulation_003`

### 1. Question ID

`eq_tr_v1_emotion_regulation_003`
### 2. Scenario family

`stress_and_regulation`
### 3. Primary dimension

`emotion_regulation`
### 4. Secondary dimensions

`perspective_taking`, `self_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`emotion_regulation`).
### 6. Prompt summary

İş yerinde eleştiri aldın; öğle arasında hâlâ içinde kalıyor. Öğleden sonraki toplantıya girmeden önce ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Kısa bir yürüyüş veya nefes egzersiziyle duygunu sakinleştirirsin.
- **B:** Eleştiriden çıkarılacak bir nokta bulup zihnini oraya odaklarsın.
- **C:** Duyguyu bastırıp profesyonel görünmeye çalışırsın.
- **D:** Eleştiriyi düşünerek toplantıya girersin, odaklanmakta zorlanırsın.

### 8. Full option evidence vectors

- **A** — deltas: emotion_regulation: +0.75; self_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: emotion_regulation: +0.45; perspective_taking: +0.20; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: emotion_regulation: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: emotion_regulation: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `sakinleştirme vs bastırma`; each option carries relational cost.

### 11. Behavioral trade-off

`sakinleştirme vs bastırma`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `emotion_regulation` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `eq_tr_v1_iso_05`

### 15. RVI role

['repeated_context_stability', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=stress_and_regulation; sdr_item_risk=low; tradeoff=sakinleştirme vs bastırma; how_avoids_ideal_answer=profesyonellik ile duygu işleme farklı yollar gerektirir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 13: `eq_tr_v1_emotional_openness_001`

### 1. Question ID

`eq_tr_v1_emotional_openness_001`
### 2. Scenario family

`internal_emotional_awareness`
### 3. Primary dimension

`emotional_openness`
### 4. Secondary dimensions

`boundary_setting`, `empathy`, `self_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`emotional_openness`).
### 6. Prompt summary

Yeni tanıştığın biri sana kişisel bir şey anlatmaya başladı. Sen de benzer bir deneyimini paylaşmayı düşünüyorsun. Ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Deneyimini açıkça anlatır, duygularını da paylaşırsın.
- **B:** Deneyimini özetler ama tüm ayrıntıları vermezsin.
- **C:** Dinler, kendi hikâyeni paylaşmadan destekleyici kalırsın.
- **D:** Konuyu daha genel tutup kişisel detay vermezsin.

### 8. Full option evidence vectors

- **A** — deltas: emotional_openness: +0.75; self_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `moderate`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.20; emotional_openness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: emotional_openness: -0.15; empathy: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: emotional_openness: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `açıklık vs mahremiyet`; each option carries relational cost.

### 11. Behavioral trade-off

`açıklık vs mahremiyet`

### 12. Social-desirability analysis

Item-level SDR `moderate`.

### 13. Construct-contamination analysis

Primary `emotional_openness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_01`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'social_impression_risk', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=internal_emotional_awareness; sdr_item_risk=moderate; tradeoff=açıklık vs mahremiyet; how_avoids_ideal_answer=erken aşamada tam açıklık her zaman gerekli değildir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 14: `eq_tr_v1_emotional_openness_002`

### 1. Question ID

`eq_tr_v1_emotional_openness_002`
### 2. Scenario family

`emotional_disclosure`
### 3. Primary dimension

`emotional_openness`
### 4. Secondary dimensions

`conflict_approach`, `empathy`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`emotional_openness`).
### 6. Prompt summary

Partnerin duygularını paylaşmanı istiyor; sen genelde içini pek açmazsın. Bu akşam nasıl davranırsın?
### 7. Option summaries (A–D)

- **A:** Bugün neler hissettiğini dürüstçe anlatmaya çalışırsın.
- **B:** Bir-iki duygu adı söyler, derinleşmeden devam edersin.
- **C:** İyi olduğunu söyler, detaya girmezsin.
- **D:** Konuyu başka bir gündeme kaydırırsın.

### 8. Full option evidence vectors

- **A** — deltas: emotional_openness: +0.75; empathy: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: emotional_openness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: emotional_openness: -0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: conflict_approach: -0.20; emotional_openness: -0.45; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `istenen yakınlık vs alışkanlık`; each option carries relational cost.

### 11. Behavioral trade-off

`istenen yakınlık vs alışkanlık`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `emotional_openness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_01`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=emotional_disclosure; sdr_item_risk=low; tradeoff=istenen yakınlık vs alışkanlık; how_avoids_ideal_answer=kademeli açıklık da geçerli bir yanıttır`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 15: `eq_tr_v1_emotional_openness_003`

### 1. Question ID

`eq_tr_v1_emotional_openness_003`
### 2. Scenario family

`emotional_disclosure`
### 3. Primary dimension

`emotional_openness`
### 4. Secondary dimensions

`boundary_setting`, `empathy`, `social_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`emotional_openness`).
### 6. Prompt summary

Arkadaş grubunda biri zor bir dönemini anlatıyor. Sen de benzer bir şey yaşamıştın ama herkesin önünde anlatmak istemiyorsun.
### 7. Option summaries (A–D)

- **A:** Yine de kısaca kendi deneyimini paylaşır, grubu desteklersin.
- **B:** Sonra özel konuşmak üzere teklif edersin, şimdilik dinlersin.
- **C:** Destekleyici kalır ama kendi hikâyeni paylaşmazsın.
- **D:** Konuyu hafife alıp ortamı neşelendirmeye çalışırsın.

### 8. Full option evidence vectors

- **A** — deltas: emotional_openness: +0.60; empathy: +0.30; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.30; emotional_openness: +0.30; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: emotional_openness: -0.15; empathy: +0.30; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: emotional_openness: -0.45; social_awareness: -0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `grup açıklığı vs özel paylaşım`; each option carries relational cost.

### 11. Behavioral trade-off

`grup açıklığı vs özel paylaşım`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `emotional_openness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `None`

### 15. RVI role

['response_variation', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=emotional_disclosure; sdr_item_risk=low; tradeoff=grup açıklığı vs özel paylaşım; how_avoids_ideal_answer=herkesin önünde açılmak zorunlu değildir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 16: `eq_tr_v1_empathy_001`

### 1. Question ID

`eq_tr_v1_empathy_001`
### 2. Scenario family

`interpersonal_support`
### 3. Primary dimension

`empathy`
### 4. Secondary dimensions

`boundary_setting`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`empathy`).
### 6. Prompt summary

Yakın bir arkadaşın zor bir ayrılık yaşıyor ve mesaj atıp duygularını anlatıyor. Bu akşam başka planların var ama onu duymak istiyorsun. Ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Planını kısmen erteleyip telefonda dinler; duygularını yansıtmaya çalışırsın.
- **B:** Kısa ama sıcak bir mesaj atıp yarın yüz yüze konuşmayı teklif edersin.
- **C:** Pratik bir tavsiye listesi gönderir, kendi deneyiminden bir örnek eklersin.
- **D:** Meşgul olduğunu söyler; sonra kısa bir kontrol mesajı atmayı planlarsın.

### 8. Full option evidence vectors

- **A** — deltas: boundary_setting: -0.30; empathy: +0.75; evidence_strength: 0.65; social_desirability_risk: `moderate`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.20; empathy: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: empathy: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: boundary_setting: +0.20; empathy: -0.45; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `destek vs zaman sınırı`; each option carries relational cost.

### 11. Behavioral trade-off

`destek vs zaman sınırı`

### 12. Social-desirability analysis

Item-level SDR `moderate`.

### 13. Construct-contamination analysis

Primary `empathy` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_01`; reverse `None`; isomorph `eq_tr_v1_iso_01`

### 15. RVI role

['repeated_context_stability', 'semantic_consistency', 'social_impression_risk', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`adapted_from_legacy_scenario; scenario_family=interpersonal_support; sdr_item_risk=moderate; tradeoff=destek vs zaman sınırı; how_avoids_ideal_answer=dinleme, tavsiye ve mesafe seçenekleri eşit derecede savunulabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 17: `eq_tr_v1_empathy_002`

### 1. Question ID

`eq_tr_v1_empathy_002`
### 2. Scenario family

`repair_after_disagreement`
### 3. Primary dimension

`empathy`
### 4. Secondary dimensions

`assertiveness`, `repair_orientation`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`empathy`).
### 6. Prompt summary

İş arkadaşınla tartıştıktan sonra o soğuk davranıyor; sen barışmak istiyorsun ama hâlâ kırgınsın. İlk adımı nasıl atarsın?
### 7. Option summaries (A–D)

- **A:** Onun bakış açısını anlamaya çalışır, duygusunu doğrudan sorarsın.
- **B:** Bir süre bekler, ortam sakinleşince kısa bir özür ve ortak zemin ararsın.
- **C:** Konuyu iş gündemine bağlayarak mesleki iletişimi sürdürürsün.
- **D:** Kendi haklılığını koruyup mesafeyi sürdürürsün.

### 8. Full option evidence vectors

- **A** — deltas: empathy: +0.75; repair_orientation: +0.30; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: empathy: +0.45; repair_orientation: +0.20; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: empathy: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: +0.20; empathy: -0.45; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `onarım vs korunma`; each option carries relational cost.

### 11. Behavioral trade-off

`onarım vs korunma`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `empathy` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_01`; reverse `None`; isomorph `None`

### 15. RVI role

['semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=repair_after_disagreement; sdr_item_risk=low; tradeoff=onarım vs korunma; how_avoids_ideal_answer=hem duygusal yakınlaşma hem mesafe makul gerekçelere dayanır`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 18: `eq_tr_v1_empathy_003`

### 1. Question ID

`eq_tr_v1_empathy_003`
### 2. Scenario family

`emotional_disclosure`
### 3. Primary dimension

`empathy`
### 4. Secondary dimensions

`boundary_setting`, `emotional_openness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`empathy`).
### 6. Prompt summary

Flörtün duygusal bir konuyu açmak istiyor ama sen yorgunsun. Açmak istediği şey seni de etkileyebilir. Nasıl karşılık verirsin?
### 7. Option summaries (A–D)

- **A:** Yorgun olsan da dinlemeye hazır olduğunu söyler, dikkatini verirsin.
- **B:** Dinlemek istediğini ama kısa tutmayı tercih ettiğini açıkça belirtirsin.
- **C:** Yarın daha uygun bir zaman önerir, kısa bir destek mesajı eklersin.
- **D:** Konuyu hafife alıp başka bir şeye yönlendirmeye çalışırsın.

### 8. Full option evidence vectors

- **A** — deltas: emotional_openness: +0.20; empathy: +0.60; evidence_strength: 0.60; social_desirability_risk: `moderate`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.30; empathy: +0.45; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: boundary_setting: +0.30; empathy: +0.30; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: emotional_openness: -0.20; empathy: -0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `açıklık vs dinlenme ihtiyacı`; each option carries relational cost.

### 11. Behavioral trade-off

`açıklık vs dinlenme ihtiyacı`

### 12. Social-desirability analysis

Item-level SDR `moderate`.

### 13. Construct-contamination analysis

Primary `empathy` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `eq_tr_v1_iso_01`

### 15. RVI role

['repeated_context_stability', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=emotional_disclosure; sdr_item_risk=moderate; tradeoff=açıklık vs dinlenme ihtiyacı; how_avoids_ideal_answer=yorgunluk ve duygusal hazır olma gerçek bir gerilim oluşturur`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 19: `eq_tr_v1_perspective_taking_001`

### 1. Question ID

`eq_tr_v1_perspective_taking_001`
### 2. Scenario family

`perspective_taking_family`
### 3. Primary dimension

`perspective_taking`
### 4. Secondary dimensions

`boundary_setting`, `social_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`perspective_taking`).
### 6. Prompt summary

Arkadaşın seni bir davetiye konusunda eleştiriyor; sen katılamayacağını söylemiştin. Onun neden kırgın olabileceğini düşünürsün — ilk iç tepkin ne olur?
### 7. Option summaries (A–D)

- **A:** Belki kendini değersiz hissetti; davetin onun için önemli olduğunu hatırlarsın.
- **B:** İki tarafın da haklı yanları olabileceğini, iletişim eksikliği olabileceğini düşünürsün.
- **C:** Onun gerekçesini dinlerim ama kendi önceliğimi de kısaca koyarım.
- **D:** Durumu kendi açımdan özetlerim; karşı tarafın bağlamını sonra sorarım.

### 8. Full option evidence vectors

- **A** — deltas: perspective_taking: +0.75; social_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: perspective_taking: +0.45; social_awareness: +0.20; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: boundary_setting: +0.20; perspective_taking: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: perspective_taking: -0.45; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `başkasının çerçevesi vs kendi gerekçen`; each option carries relational cost.

### 11. Behavioral trade-off

`başkasının çerçevesi vs kendi gerekçen`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `perspective_taking` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_02`; reverse `None`; isomorph `None`

### 15. RVI role

['semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=perspective_taking_family; sdr_item_risk=low; tradeoff=başkasının çerçevesi vs kendi gerekçen; how_avoids_ideal_answer=eleştiriyi tamamen haklı veya haksız saymak zorunda değilsin`

### 20. Final internal disposition

`internal_accept_for_candidate`

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

See canonical_dimension_registry_v1 (`perspective_taking`).
### 6. Prompt summary

Takım toplantısında sessiz kalan bir meslektaşın vardı. Sonradan fikrinin göz ardı edildiğini fark ediyorsun. Onun yerinde olsan ne hissederdin?
### 7. Option summaries (A–D)

- **A:** Görünmez kalmış ve saygısızlık hissetmiş olabileceğini düşünürsün.
- **B:** Belki konuşmak istemediğini ama yine de dışlanmış hissetmiş olabileceğini varsayarsın.
- **C:** Toplantı dinamiğinin herkesi eşit davet etmediğini genel olarak değerlendirirsin.
- **D:** Sessiz kalmasının kendi tercihi olduğunu ve fazla yorum yapmazsın.

### 8. Full option evidence vectors

- **A** — deltas: perspective_taking: +0.75; social_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: perspective_taking: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: perspective_taking: +0.20; social_awareness: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: perspective_taking: -0.45; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `sessizlik yorumu vs dışlanma olasılığı`; each option carries relational cost.

### 11. Behavioral trade-off

`sessizlik yorumu vs dışlanma olasılığı`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `perspective_taking` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_02`; reverse `None`; isomorph `eq_tr_v1_iso_04`

### 15. RVI role

['repeated_context_stability', 'response_variation', 'semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=perspective_taking_family; sdr_item_risk=low; tradeoff=sessizlik yorumu vs dışlanma olasılığı; how_avoids_ideal_answer=sessizlik hem tercih hem dışlanma olabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 21: `eq_tr_v1_perspective_taking_003`

### 1. Question ID

`eq_tr_v1_perspective_taking_003`
### 2. Scenario family

`social_context_awareness`
### 3. Primary dimension

`perspective_taking`
### 4. Secondary dimensions

`social_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`perspective_taking`).
### 6. Prompt summary

Bir arkadaş grubunda biri espri yaptı; başka biri gülmedi ve ortam gerildi. Gülmeyen kişinin içinde ne geçiyor olabilir diye düşünürsün.
### 7. Option summaries (A–D)

- **A:** Espriyi incitici bulmuş veya kendini hedef alınmış hissetmiş olabilir.
- **B:** O an dikkati dağılmış ya da mizah anlayışı farklı olabilir diye düşünürsün.
- **C:** Grup baskısı hissetmiş olabileceğini kısaca not edersin.
- **D:** Abartıyor olabileceğini düşünüp konuyu kapatırsın.

### 8. Full option evidence vectors

- **A** — deltas: perspective_taking: +0.75; social_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: perspective_taking: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: perspective_taking: +0.30; social_awareness: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: perspective_taking: -0.45; social_awareness: -0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `grup dinamiği vs bireysel duygu`; each option carries relational cost.

### 11. Behavioral trade-off

`grup dinamiği vs bireysel duygu`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `perspective_taking` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `eq_tr_v1_iso_04`

### 15. RVI role

['repeated_context_stability', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=social_context_awareness; sdr_item_risk=low; tradeoff=grup dinamiği vs bireysel duygu; how_avoids_ideal_answer=gülmeme tek bir nedene indirgenmez`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 22: `eq_tr_v1_repair_orientation_001`

### 1. Question ID

`eq_tr_v1_repair_orientation_001`
### 2. Scenario family

`interpersonal_support`
### 3. Primary dimension

`repair_orientation`
### 4. Secondary dimensions

`assertiveness`, `empathy`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`repair_orientation`).
### 6. Prompt summary

Arkadaşına kaba bir mesaj attığını fark ettin; o henüz cevap vermedi. Ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Özür diler, niyetini açıklar ve konuşmak istediğini söylersin.
- **B:** Mesajını düzelten kısa bir takip gönderirsin.
- **C:** Zaman geçsin, kendiliğinden düzelir diye beklersin.
- **D:** Haklı olduğunu düşünüp mesajına dokunmazsın.

### 8. Full option evidence vectors

- **A** — deltas: empathy: +0.20; repair_orientation: +0.75; evidence_strength: 0.65; social_desirability_risk: `moderate`; response_style_risk: `low`
- **B** — deltas: repair_orientation: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: repair_orientation: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: assertiveness: +0.20; repair_orientation: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `özür vs zaman`; each option carries relational cost.

### 11. Behavioral trade-off

`özür vs zaman`

### 12. Social-desirability analysis

Item-level SDR `moderate`.

### 13. Construct-contamination analysis

Primary `repair_orientation` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_05`; reverse `None`; isomorph `None`

### 15. RVI role

['semantic_consistency', 'social_impression_risk', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=interpersonal_support; sdr_item_risk=moderate; tradeoff=özür vs zaman; how_avoids_ideal_answer=hem aktif onarım hem bekleme savunulabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 23: `eq_tr_v1_repair_orientation_002`

### 1. Question ID

`eq_tr_v1_repair_orientation_002`
### 2. Scenario family

`repair_after_disagreement`
### 3. Primary dimension

`repair_orientation`
### 4. Secondary dimensions

`conflict_approach`, `emotional_openness`, `empathy`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`repair_orientation`).
### 6. Prompt summary

Partnerinle tartıştınız; gece boyunca konuşmadınız. Sabah ne yaparsın?
### 7. Option summaries (A–D)

- **A:** İletişimi yeniden açmak için sakin bir mesaj veya kahve teklifi yaparsın.
- **B:** Önce özür veya ortak zemin cümlesiyle diyaloğu başlatırsın.
- **C:** O adım atana kadar normal davranırsın, konuyu açmazsın.
- **D:** Hâlâ haklı olduğunu düşünerek mesafe korursun.

### 8. Full option evidence vectors

- **A** — deltas: emotional_openness: +0.20; repair_orientation: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: empathy: +0.20; repair_orientation: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: repair_orientation: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: conflict_approach: +0.20; repair_orientation: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `ilk adım vs bekleme`; each option carries relational cost.

### 11. Behavioral trade-off

`ilk adım vs bekleme`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `repair_orientation` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `eq_tr_v1_sem_05`; reverse `None`; isomorph `eq_tr_v1_iso_03`

### 15. RVI role

['repeated_context_stability', 'semantic_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=repair_after_disagreement; sdr_item_risk=low; tradeoff=ilk adım vs bekleme; how_avoids_ideal_answer=sabah yakınlaşması zorunlu değildir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 24: `eq_tr_v1_repair_orientation_003`

### 1. Question ID

`eq_tr_v1_repair_orientation_003`
### 2. Scenario family

`repeated_behavioral_patterns`
### 3. Primary dimension

`repair_orientation`
### 4. Secondary dimensions

`assertiveness`, `conflict_approach`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`repair_orientation`).
### 6. Prompt summary

İş yerinde yanlış anlaşılma yüzünden meslektaşın sana kırgın. Bu tür durumlar daha önce de oldu. Genelde ne yaparsın?
### 7. Option summaries (A–D)

- **A:** Yanlış anlaşılmayı netleştirip özür veya açıklama yaparsın.
- **B:** Kısa bir kontrol mesajı atıp yüz yüze konuşmayı planlarsın.
- **C:** Zamanla geçer diye müdahale etmezsin.
- **D:** Sorumluluğu tamamen karşı tarafa bırakırsın.

### 8. Full option evidence vectors

- **A** — deltas: conflict_approach: +0.20; repair_orientation: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: assertiveness: +0.20; repair_orientation: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: repair_orientation: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: repair_orientation: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `tekrarlayan onarım alışkanlığı`; each option carries relational cost.

### 11. Behavioral trade-off

`tekrarlayan onarım alışkanlığı`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `repair_orientation` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `eq_tr_v1_iso_03`

### 15. RVI role

['repeated_context_stability', 'response_variation', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=repeated_behavioral_patterns; sdr_item_risk=low; tradeoff=tekrarlayan onarım alışkanlığı; how_avoids_ideal_answer=her yanlış anlaşılma hemen konuşmayı gerektirmez`

### 20. Final internal disposition

`internal_accept_for_candidate`

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

See canonical_dimension_registry_v1 (`self_awareness`).
### 6. Prompt summary

Partnerin bugün mesafeli; sen gerginsin ve bunun nedenini tam bilmiyorsun. Kendi iç durumuna bakınca ilk fark ettiğin ne olur?
### 7. Option summaries (A–D)

- **A:** Onun davranışını kişisel algıladığını ve kaygının arttığını fark edersin.
- **B:** Yorgunluk ve stresin tepkini şişirdiğini düşünürsün.
- **C:** Henüz net bir duygu adı koyamazsın ama rahatsız olduğunu bilirsin.
- **D:** Sorun partnerde olduğu için kendi halini sorgulamazsın.

### 8. Full option evidence vectors

- **A** — deltas: emotion_regulation: +0.20; self_awareness: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: emotion_regulation: +0.20; self_awareness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: self_awareness: +0.20; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: self_awareness: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `iç tetik vs dış atfetme`; each option carries relational cost.

### 11. Behavioral trade-off

`iç tetik vs dış atfetme`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `self_awareness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_05`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`substantially_rewritten_legacy_concept; scenario_family=internal_emotional_awareness; sdr_item_risk=low; tradeoff=iç tetik vs dış atfetme; how_avoids_ideal_answer=mesafe hem kişisel hem bağlamsal yorumlanabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 26: `eq_tr_v1_self_awareness_002`

### 1. Question ID

`eq_tr_v1_self_awareness_002`
### 2. Scenario family

`social_context_awareness`
### 3. Primary dimension

`self_awareness`
### 4. Secondary dimensions

`boundary_setting`, `social_awareness`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`self_awareness`).
### 6. Prompt summary

Bir sosyal ortamda aniden içe kapanma isteği duyuyorsun. Bu tepkinin altında ne olabileceğini nasıl değerlendirirsin?
### 7. Option summaries (A–D)

- **A:** Sosyal yorgunluk veya tetiklenen bir anı olabileceğini fark edersin.
- **B:** Ortamın gürültülü olduğunu ve sınırlarının dolmakta olduğunu düşünürsün.
- **C:** Basitçe modunun düşük olduğunu söylersin, derinine inmezsin.
- **D:** Ortamın seni rahatsız ettiğini düşünür, kendini sorgulamazsın.

### 8. Full option evidence vectors

- **A** — deltas: self_awareness: +0.75; social_awareness: +0.20; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: boundary_setting: +0.20; self_awareness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: self_awareness: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: self_awareness: -0.45; social_awareness: +0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `iç geri çekilme vs ortam etkisi`; each option carries relational cost.

### 11. Behavioral trade-off

`iç geri çekilme vs ortam etkisi`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `self_awareness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `None`

### 15. RVI role

['response_variation', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=social_context_awareness; sdr_item_risk=low; tradeoff=iç geri çekilme vs ortam etkisi; how_avoids_ideal_answer=kapanma hem içsel hem dışsal nedenlerle açıklanabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 27: `eq_tr_v1_self_awareness_003`

### 1. Question ID

`eq_tr_v1_self_awareness_003`
### 2. Scenario family

`stress_and_regulation`
### 3. Primary dimension

`self_awareness`
### 4. Secondary dimensions

`assertiveness`, `emotion_regulation`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`self_awareness`).
### 6. Prompt summary

Yoğun bir günün ardından küçük bir yorum seni aşırı derecede kızdırdı. Tepkinin büyüklüğü hakkında kendine ne dersin?
### 7. Option summaries (A–D)

- **A:** Biriktirilmiş stresin bu tepkiyi büyüttüğünü fark edersin.
- **B:** Konunun sana dokunan bir yönü olabileceğini kabul edersin.
- **C:** Haklı öfke olduğunu düşünür, kendi rolünü sorgulamazsın.
- **D:** Diğer kişinin kasıtlı provokasyon yaptığını varsayarsın.

### 8. Full option evidence vectors

- **A** — deltas: emotion_regulation: +0.20; self_awareness: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: self_awareness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: assertiveness: +0.20; self_awareness: -0.30; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: self_awareness: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `birikmiş stres vs haklı öfke`; each option carries relational cost.

### 11. Behavioral trade-off

`birikmiş stres vs haklı öfke`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `self_awareness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `eq_tr_v1_rev_05`; isomorph `None`

### 15. RVI role

['reverse_consistency', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=stress_and_regulation; sdr_item_risk=low; tradeoff=birikmiş stres vs haklı öfke; how_avoids_ideal_answer=aşırı tepki hem birikim hem değer ihlali olabilir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 28: `eq_tr_v1_social_awareness_001`

### 1. Question ID

`eq_tr_v1_social_awareness_001`
### 2. Scenario family

`interpersonal_support`
### 3. Primary dimension

`social_awareness`
### 4. Secondary dimensions

`empathy`, `perspective_taking`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`social_awareness`).
### 6. Prompt summary

Bir davette yalnız oturan birini fark ettin; grup halinde sohbet ediliyor. Ortamın dinamiğini nasıl okursun?
### 7. Option summaries (A–D)

- **A:** Kişinin dahil edilmediğini ve muhtemelen dışlanmış hissettiğini düşünürsün.
- **B:** Belki yorgun veya tanıdık aradığını, henüz emin olmadığını varsayarsın.
- **C:** Kendi sohbetine odaklanır, fazla yorum yapmazsın.
- **D:** Tercih meselesi olduğunu düşünüp dikkat etmezsin.

### 8. Full option evidence vectors

- **A** — deltas: empathy: +0.20; social_awareness: +0.75; evidence_strength: 0.65; social_desirability_risk: `moderate`; response_style_risk: `low`
- **B** — deltas: perspective_taking: +0.20; social_awareness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: social_awareness: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: social_awareness: -0.55; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `dışlanma sinyali vs kişisel tercih`; each option carries relational cost.

### 11. Behavioral trade-off

`dışlanma sinyali vs kişisel tercih`

### 12. Social-desirability analysis

Item-level SDR `moderate`.

### 13. Construct-contamination analysis

Primary `social_awareness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `None`

### 15. RVI role

['social_impression_risk', 'timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**high**

### 19. Provenance

`newly_authored; scenario_family=interpersonal_support; sdr_item_risk=moderate; tradeoff=dışlanma sinyali vs kişisel tercih; how_avoids_ideal_answer=yalnız oturmak tek anlama gelmez`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 29: `eq_tr_v1_social_awareness_002`

### 1. Question ID

`eq_tr_v1_social_awareness_002`
### 2. Scenario family

`perspective_taking_family`
### 3. Primary dimension

`social_awareness`
### 4. Secondary dimensions

`perspective_taking`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`social_awareness`).
### 6. Prompt summary

Arkadaş grubunda biri espri yaptıktan sonra ortamın gerildiğini hissediyorsun. Ne fark edersin?
### 7. Option summaries (A–D)

- **A:** Espriyi yanlış yorumlayan veya incinen biri olabileceğini düşünürsün.
- **B:** Genel olarak mizahın o an uygun olmadığını sezersin.
- **C:** Sadece kısa bir sessizlik olduğunu sanır, fazla anlam yüklemezsin.
- **D:** Gerilimi fark etmez, sohbete devam edersin.

### 8. Full option evidence vectors

- **A** — deltas: perspective_taking: +0.20; social_awareness: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: social_awareness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: social_awareness: +0.15; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: social_awareness: -0.45; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `grup tonu vs bireysel tepki`; each option carries relational cost.

### 11. Behavioral trade-off

`grup tonu vs bireysel tepki`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `social_awareness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `None`

### 15. RVI role

['timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=perspective_taking_family; sdr_item_risk=low; tradeoff=grup tonu vs bireysel tepki; how_avoids_ideal_answer=gerilim her zaman kişisel değildir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

## Item 30: `eq_tr_v1_social_awareness_003`

### 1. Question ID

`eq_tr_v1_social_awareness_003`
### 2. Scenario family

`social_context_awareness`
### 3. Primary dimension

`social_awareness`
### 4. Secondary dimensions

`perspective_taking`
### 5. Construct definition (provisional)

See canonical_dimension_registry_v1 (`social_awareness`).
### 6. Prompt summary

Yeni bir iş ekibine katıldın; toplantıda kimlerin söz aldığını ve kimlerin geri planda kaldığını fark ediyorsun. İlk izlenimin ne?
### 7. Option summaries (A–D)

- **A:** Resmi hiyerarşi ve informal grupların katılımı etkilediğini düşünürsün.
- **B:** Bazı konuların belirli kişileri daha çok devreye soktuğunu not edersin.
- **C:** Katılım farklarını fark ederim; yine de kendi gündemime göre ilerlerim.
- **D:** Sosyal ipuçlarını not ederim ama doğrudan müdahale etmeden izlerim.

### 8. Full option evidence vectors

- **A** — deltas: perspective_taking: +0.20; social_awareness: +0.75; evidence_strength: 0.65; social_desirability_risk: `low`; response_style_risk: `low`
- **B** — deltas: perspective_taking: +0.20; social_awareness: +0.45; evidence_strength: 0.60; social_desirability_risk: `low`; response_style_risk: `low`
- **C** — deltas: social_awareness: +0.20; evidence_strength: 0.50; social_desirability_risk: `low`; response_style_risk: `low`
- **D** — deltas: social_awareness: +0.30; evidence_strength: 0.55; social_desirability_risk: `low`; response_style_risk: `low`

### 9. Why each delta direction is justified (provisional)

Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.

### 10. Why no option is globally correct

Trade-off `güç dinamiği vs eşit katılım varsayımı`; each option carries relational cost.

### 11. Behavioral trade-off

`güç dinamiği vs eşit katılım varsayımı`

### 12. Social-desirability analysis

Item-level SDR `low`.

### 13. Construct-contamination analysis

Primary `social_awareness` reviewed against near-neighbor constructs.

### 14. Semantic/reverse/isomorph links

semantic `None`; reverse `None`; isomorph `None`

### 15. RVI role

['timing_quality']

### 16. Difficult persona pairs informed

Provisional only; not deterministic.

### 17. Residual ambiguity

Cognitive interviews pending.

### 18. Human-review priority

**medium**

### 19. Provenance

`newly_authored; scenario_family=social_context_awareness; sdr_item_risk=low; tradeoff=güç dinamiği vs eşit katılım varsayımı; how_avoids_ideal_answer=erken izlenimler kesin hüküm değildir`

### 20. Final internal disposition

`internal_accept_for_candidate`

---

