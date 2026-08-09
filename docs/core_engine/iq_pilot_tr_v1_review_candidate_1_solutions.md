# IQ Pilot TR v1 Review Candidate 1 — Solutions

Independently re-evaluated for each candidate item. Not a copy-paste of v1 solutions.

## iq_tr_v1_logical_001

- Domain: `logical_reasoning` · Difficulty hypothesis: easy
- Final correct: `A` — Yağmur zorunlu değildir; başka nedenler olabilir.
- Solution: İfade bir şartlı önermedir (P→Q). Q'nun doğru olması P'yi zorunlu kılmaz (olumlama yanılgısı / affirming the consequent). Bu yüzden yağmur zorunlu değildir; başka nedenler mümkündür.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (Yağmur yağmıştır.): reverses_or_affirms_consequent
  - `C` (Yağmur yağmamıştır.): assumes_unsupported_information
  - `D` (Zemin kurudur.): contradicts_given_premise
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_logical_002

- Domain: `logical_reasoning` · Difficulty hypothesis: easy
- Final correct: `C` — Tabak üstte, çaydanlık ortada, bardak alttadır.
- Solution: Çaydanlık tabağın hemen altında → tabak üstte veya ortada; çaydanlık sırasıyla orta veya alt. Tabak altta değil (verildi) → tabak üst veya orta. Bardak üstte değil. Eğer tabak orta olsaydı çaydanlık alt olurdu; bardak üstte olamaz → bardak üst kalırdı ki yasak. Bu yüzden tabak üstte, çaydanlık orta, bardak alt zorunludur.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Bardak ortadadır.): ignores_one_constraint
  - `B` (Çaydanlık üsttedir.): reverses_ordering
  - `D` (Tabak alttadır.): contradicts_given_premise
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_logical_003

- Domain: `logical_reasoning` · Difficulty hypothesis: medium
- Final correct: `D` — Ayşe'nin denizci olup olmadığı bu bilgilerle belirlenemez.
- Solution: «Bazı yüzücüler müzisyen» ifadesi Ayşe için yüzme bilmeyi zorunlu kılmaz; müzisyen olmak denizci olmayı da gerektirmez. Bu nedenle Ayşe'nin denizciliği belirlenemez.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Ayşe denizcidir.): assumes_unsupported_information
  - `B` (Ayşe yüzme bilir.): confuses_some_with_all
  - `C` (Hiçbir müzisyen denizci değildir.): selects_possible_not_necessary
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_logical_004

- Domain: `logical_reasoning` · Difficulty hypothesis: medium
- Final correct: `B` — Deniz birinciliği kazanamaz.
- Solution: Birincilik için gerekli koşullar: hızlı VE dikkatli (ikisi de gerekli). Deniz dikkatli değil → gerekli koşul eksik → birincilik imkânsız.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Deniz birinciliği kazanır.): ignores_necessary_condition
  - `C` (Dikkatli olmak birincilik için yeterlidir.): confuses_necessary_with_sufficient
  - `D` (Hızlı olmak birincilik için yeterlidir.): confuses_necessary_with_sufficient
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_logical_005

- Domain: `logical_reasoning` · Difficulty hypothesis: medium
- Final correct: `A` — Lamba kapalıdır.
- Solution: Modus tollens: P→Q ve ¬Q ⇒ ¬P. Oda aydınlık değil ⇒ lamba açık değildir. İki durumlu varsayımla lamba kapalıdır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (Lamba açıktır.): contradicts_valid_inference
  - `C` (Lamba bozuktur.): assumes_unsupported_information
  - `D` (Oda pencereden aydınlanıyordur.): assumes_unsupported_information
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_logical_006

- Domain: `logical_reasoning` · Difficulty hypothesis: hard
- Final correct: `D` — Bir kutu kırmızı, bir kutu mavidir.
- Solution: İki kutu, her biri tek renk (kırmızı XOR mavi). En az bir kırmızı ve en az bir mavi → tam olarak bir kırmızı ve bir mavi olmalıdır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (İki kutu da kırmızıdır.): ignores_one_constraint
  - `B` (İki kutu da mavidir.): ignores_one_constraint
  - `C` (Kutuların renkleri belirlenemez.): assumes_underdetermination_when_determined
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_logical_007

- Domain: `logical_reasoning` · Difficulty hypothesis: hard
- Final correct: `C` — Yağmur yağmıştır.
- Solution: «Yalnızca … durumda» burada iptal → yağmur (yağmur gerekli koşul). Maç iptal edildiğinden yağmur yağmış olmalıdır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Saha bozuk olduğu için iptal edilmiştir.): assumes_unsupported_information
  - `B` (Yağmur yağmamış olabilir.): ignores_biconditional_force
  - `D` (Maç oynanmıştır.): contradicts_given_premise
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_pattern_001

- Domain: `pattern_reasoning` · Difficulty hypothesis: easy
- Final correct: `B` — 32
- Solution: Her terim bir öncekinin 2 katı: 2→4→8→16→32. Bu tek, tutarlı ve en yalın kuraldır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (24): adds_fixed_increment_instead_of_doubling
  - `C` (30): arbitrary_arithmetic
  - `D` (18): adds_2_only
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_pattern_002

- Domain: `pattern_reasoning` · Difficulty hypothesis: easy
- Final correct: `A` — ●
- Solution: İki sembolün dönüşümlü tekrarı: ▲●▲●▲●.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (▲): repeats_previous_instead_of_alternating
  - `C` (■): introduces_new_symbol_without_rule
  - `D` (◆): introduces_new_symbol_without_rule
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_pattern_003

- Domain: `pattern_reasoning` · Difficulty hypothesis: medium
- Final correct: `D` — 17
- Solution: Kural çift adımlı: ×2, sonra −1: 3×2=6, 6−1=5, 5×2=10, 10−1=9, 9×2=18, 18−1=17. En yalın düzenli kural budur.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (36): applies_only_doubling
  - `B` (20): arbitrary_increment
  - `C` (15): subtracts_from_wrong_term
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_pattern_004

- Domain: `pattern_reasoning` · Difficulty hypothesis: medium
- Final correct: `B` — 21
- Solution: Satır kuralı: üçüncü = birinci × ikinci. 3×7=21.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (10): adds_instead_of_multiplying
  - `C` (14): multiplies_by_wrong_factor
  - `D` (24): adds_product_components_incorrectly
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_pattern_005

- Domain: `pattern_reasoning` · Difficulty hypothesis: medium
- Final correct: `C` — L-12
- Solution: Harfler 3'er artar (C,F,I,L) ve sayılar harf sırasına eşittir (3,6,9,12).
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (J-10): increments_by_one_only
  - `B` (K-11): increments_by_two
  - `D` (H-8): moves_backward
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_pattern_007 (replaces v1 `iq_tr_v1_pattern_006`)

- Domain: `pattern_reasoning` · Difficulty hypothesis: medium
- Final correct: `A` — 720
- Solution: Verilen kural açıkça artan çarpanlardır: sonraki adım 120×6=720. Faktöriyel adı gerekmez; işlem promptta belirtilmiştir.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (240): doubles_previous
  - `C` (600): multiplies_by_5_only
  - `D` (480): multiplies_by_4
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_verbal_001

- Domain: `verbal_reasoning` · Difficulty hypothesis: easy
- Final correct: `B` — Doktor / hastane
- Solution: İlişki: meslek insanı ile birincil çalışma mekânı. Doktor-hastane aynı ilişkiyi taşır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Kitap / sayfa): part_whole_not_profession_place
  - `C` (Yolcu / bilet): user_object_relation
  - `D` (Kalem / yazı): tool_product_relation
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_verbal_002

- Domain: `verbal_reasoning` · Difficulty hypothesis: easy
- Final correct: `D` — En az bir katılımcı kimlik kartı getirmiştir.
- Solution: Katılımcı kümesi boş değildir ve tüm üyeler kimlik getirmiştir ⇒ en az bir katılımcı kimlik getirmiştir.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Hiçbir katılımcı kimlik kartı getirmemiştir.): contradicts_universal_affirmative
  - `B` (Katılımcıların çoğu kimlik kartı getirmemiştir.): contradicts_universal_affirmative
  - `C` (Kimlik kartı getirmeyenler yarışa alınmamıştır.): assumes_unsupported_information
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_verbal_003

- Domain: `verbal_reasoning` · Difficulty hypothesis: medium
- Final correct: `C` — Benzerlikten yola çıkan bir genelleme.
- Solution: Argüman, benzer örneklerden bu ilaca geçiş yapan bir analoji/genellemedir.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (İlacın fiyatı uygundur.): irrelevant_attribute
  - `B` (İlacın rengi kırmızıdır.): irrelevant_attribute
  - `D` (Ateş her zaman zararsızdır.): unsupported_value_claim
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_verbal_004

- Domain: `verbal_reasoning` · Difficulty hypothesis: easy
- Final correct: `B` — Masa
- Solution: İlk üçü canlı hayvan; masa cansız nesnedir.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Koyun): same_category_animal
  - `C` (Tavşan): same_category_animal
  - `D` (İnek): same_category_animal
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_verbal_005

- Domain: `verbal_reasoning` · Difficulty hypothesis: medium
- Final correct: `A` — Zıtlık / beklenmedik sonuç ilişkisi kurmak
- Solution: «Ancak» burada kısa sürmeye karşın net karar çıktığını gösteren karşıtlık bağlacıdır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (Neden belirtmek): confuses_contrast_with_cause
  - `C` (Zaman sırası bildirmek): confuses_contrast_with_sequence
  - `D` (Koşul bildirmek): confuses_contrast_with_condition
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_verbal_006

- Domain: `verbal_reasoning` · Difficulty hypothesis: hard
- Final correct: `D` — Aynı anda doğru olamazlar; biri doğruysa diğeri yanlıştır.
- Solution: «Bazı … gecikti» ile «hiçbir … gecikmedi» çelişik önermelerdir; aynı anda doğru olamazlar ve biri doğruysa diğeri yanlıştır.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (İkisi birden doğru olabilir.): allows_contradiction
  - `B` (İkisi mantıken eşdeğerdir.): false_equivalence
  - `C` (İkinci ifade birinciden zorunlu olarak çıkar.): invalid_entailment
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_spatial_001

- Domain: `spatial_reasoning` · Difficulty hypothesis: easy
- Final correct: `C` — Bir birim doğu, iki birim kuzey
- Solution: C orijin olsun. B = C + (1 doğu). A = B + (2 kuzey) = C + (1 doğu, 2 kuzey).
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Bir birim batı, iki birim kuzey): reverses_east_west
  - `B` (İki birim güney): ignores_east_offset
  - `D` (Bir birim batı, iki birim güney): reverses_both_axes
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_spatial_002

- Domain: `spatial_reasoning` · Difficulty hypothesis: easy
- Final correct: `A` — Güney
- Solution: Kuzey → sağa = doğu → sağa = güney.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (Kuzey): ignores_turns
  - `C` (Doğu): stops_after_one_turn
  - `D` (Batı): turns_left_instead_of_right
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_spatial_007

- Domain: `spatial_reasoning` · Difficulty hypothesis: medium
- Final correct: `B` — 4 doğu, 3 güney
- Solution: Net yer değiştirme vektörü: +4 doğu ve +3 güney. Bileşenler yer değiştirmez ve yönler tersine çevrilmez.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (3 doğu, 4 güney): swaps_components
  - `C` (4 batı, 3 güney): reverses_east_west
  - `D` (4 doğu, 3 kuzey): reverses_north_south
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_spatial_004

- Domain: `spatial_reasoning` · Difficulty hypothesis: medium
- Final correct: `D` — 2 doğu, 3 kuzey
- Solution: Net yer değiştirme: +3 kuzey, +2 doğu.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (3 doğu, 2 kuzey): swaps_components
  - `B` (2 batı, 3 kuzey): reverses_east_west
  - `C` (2 doğu, 3 güney): reverses_north_south
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_spatial_005

- Domain: `spatial_reasoning` · Difficulty hypothesis: medium
- Final correct: `A` — Kitabın sağ-önünde
- Solution: Defter referans: kitap solda, kalem önde. Kitaptan bakınca defter sağda kalır; kalem defterin önünde olduğundan kitabın sağ-ön bölgesindedir.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `B` (Kitabın sol-arkasında): reverses_left_right_and_front_back
  - `C` (Kitabın tam arkasında): ignores_right_offset
  - `D` (Kitabın tam solunda): ignores_front_offset
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

## iq_tr_v1_spatial_006

- Domain: `spatial_reasoning` · Difficulty hypothesis: hard
- Final correct: `C` — Sola (←)
- Solution: Saat yönünde 90°: → ↓ olur; bir 90° daha: ↓ ← olur. Toplam 180°.
- Uniqueness: keyed answer forced by stated premises/rule; alternatives either violate constraints or add unsupported claims.
- Distractors:
  - `A` (Sağa (→)): ignores_rotations
  - `B` (Aşağı (↓)): stops_after_one_rotation
  - `D` (Yukarı (↑)): rotates_counterclockwise
- Alternative-rule check: completed in red-team; no remaining competing keyed answer.
- Linguistic check: internal Turkish review completed; expert pending.
- Construct purity: see red-team matrix; no high contamination retained.
- Remaining concern: expert language/measurement review pending.

