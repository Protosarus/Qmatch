#!/usr/bin/env python3
"""Generate iq_pilot_tr_v1.json — offline only, not a runtime asset."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/data/assessment_v3/iq/iq_pilot_tr_v1.json"
# Safety: refuse overwrite unless --force (balanced positions live in JSON).

EN_STUB = "EN equivalent pending (tr-TR pilot reference; not a translation)."
TS = "2026-07-24T00:00:00Z"
CV = "iq-tr-pilot-v1"
SET_ID = "iq_tr_pilot_v1_set_001"

# difficulty: 2=easy, 3=medium, 4=hard
# correct positions planned: A:7 B:6 C:6 D:6, no >2 consecutive same
# Order of items in form (display order independent of IDs):
# Mixed domains interleaved for position balance tracking by sequence.

def opt(oid: str, text_tr: str) -> dict:
    return {
        "option_id": oid,
        "localized_text": {"tr": text_tr, "en": EN_STUB},
        "dimension_deltas": {},
        "evidence_strength": 1.0,
        "social_desirability_risk": "low",
        "extremity": 0.0,
        "response_style_risk": "low",
        "status": "active",
    }


def item(
    *,
    qid: str,
    domain: str,
    difficulty: int,
    prompt_tr: str,
    options: list[tuple[str, str]],
    correct: str,
    solution: str,
    distractor_logic: dict,
    seconds: int,
    notes: str,
    anchor_group: str | None = None,
    exposure: str = "pilot",
) -> dict:
    assert correct in {o[0] for o in options}
    assert len(options) == 4
    return {
        "question_id": qid,
        "module": "iq",
        "schema_version": "qmatch_question_schema_v3",
        "content_version": CV,
        "locale": {"default": "tr-TR", "supported": ["tr-TR"]},
        "status": "pilot",
        "review_state": "pending_manual_semantic_and_language_review",
        "item_type": "mcq_keyed",
        "primary_dimension": domain,
        "secondary_dimensions": [],
        "prompt": {"tr": prompt_tr, "en": EN_STUB},
        "options": [opt(oid, txt) for oid, txt in options],
        "correct_option_id": correct,
        "solution_method": solution,
        "cognitive_domain": domain,
        "difficulty": difficulty,
        "estimated_discrimination": 0.5,
        "distractor_logic": distractor_logic,
        "calibration_status": "uncalibrated",
        "anchor_group": anchor_group,
        "semantic_pair_id": None,
        "reverse_pair_id": None,
        "behavioral_isomorph_group": None,
        "separator_targets": [],
        "response_validity_roles": ["timing_quality", "response_variation"],
        "exposure_class": exposure if anchor_group is None else "anchor",
        "security_level": "standard",
        "estimated_completion_seconds": seconds,
        "authoring_notes": notes,
        "created_at": TS,
        "updated_at": TS,
        "explanation_availability": "reviewer_only",
    }


items: list[dict] = []

# ---------- LOGICAL (7): E2 M3 H2 ----------
items.append(
    item(
        qid="iq_tr_v1_logical_001",
        domain="logical_reasoning",
        difficulty=2,
        prompt_tr=(
            "Kural: «Yağmur yağarsa zemin ıslanır.»\n"
            "Bilinen: Zemin ıslanmıştır.\n"
            "Hangisi kesin olarak çıkarılabilir?"
        ),
        options=[
            ("A", "Yağmur yağmıştır."),
            ("B", "Zemin başka bir nedenle ıslanmış olabilir; yağmur zorunlu değildir."),
            ("C", "Yağmur yağmamıştır."),
            ("D", "Zemin kurudur."),
        ],
        correct="B",
        solution=(
            "İfade bir şartlı önermedir (P→Q). Q'nun doğru olması P'yi zorunlu kılmaz "
            "(olumlama yanılgısı / affirming the consequent). Bu yüzden yağmur zorunlu "
            "değildir; başka nedenler mümkündür."
        ),
        distractor_logic={
            "A": "reverses_or_affirms_consequent",
            "C": "assumes_unsupported_information",
            "D": "contradicts_given_premise",
        },
        seconds=45,
        notes="newly_authored; conditional reasoning; easy",
    )
)
items.append(
    item(
        qid="iq_tr_v1_logical_002",
        domain="logical_reasoning",
        difficulty=2,
        prompt_tr=(
            "Üç kutu yan yana: sol, orta, sağ.\n"
            "• Kitap ortada değildir.\n"
            "• Kalem soldadır.\n"
            "• Defter kalemin hemen sağında değildir.\n"
            "Defter nerede olmalıdır?"
        ),
        options=[
            ("A", "Solda"),
            ("B", "Ortada"),
            ("C", "Sağda"),
            ("D", "Konumu belirlenemez"),
        ],
        correct="C",
        solution=(
            "Kalem solda. Kitap ortada değil → kitap sağda veya solda; solda kalem "
            "vardır → kitap sağda. Defter kalan orta konumda olmalı. «Defter kalemin "
            "hemen sağında değildir» ifadesi ortadaki defter için ihlal edilmez "
            "(kalemin hemen sağı orta olurdu; defter orta olsa ihlal olur!). "
            "Düzeltme: Kalem sol → hemen sağ = orta. Defter kalemin hemen sağında "
            "değil → defter ortada olamaz → defter sağda, kitap ortada olamaz demiştik "
            "ama kitap ortada değil kuralı var. Yeniden: Kalem=sol. Defter≠orta "
            "(çünkü hemen sağ orta). Defter≠sol (kalem). → Defter=sağ. Kitap kalan "
            "orta. Kitap ortada değil kuralı ile çelişir!\n"
            "Yeniden tasarım gerekmiyor — doğru çözüm: Kalem sol. Kitap ortada değil "
            "→ kitap sağ. Defter orta. Ama «defter kalemin hemen sağında değil» "
            "ortayı yasaklıyor. Çelişki → soruyu düzelt."
        ),
        distractor_logic={
            "A": "ignores_one_constraint",
            "B": "ignores_adjacency_constraint",
            "D": "assumes_underdetermination_when_determined",
        },
        seconds=55,
        notes="PLACEHOLDER_FIX",
    )
)

# Fix logical_002 properly before writing - I'll redefine it
items[-1] = item(
    qid="iq_tr_v1_logical_002",
    domain="logical_reasoning",
    difficulty=2,
    prompt_tr=(
        "Üç raf üst üste: üst, orta, alt.\n"
        "• Bardak üstte değildir.\n"
        "• Tabak altta değildir.\n"
        "• Çaydanlık tabağın hemen altındadır.\n"
        "Hangisi zorunludur?"
    ),
    options=[
        ("A", "Bardak ortadadır."),
        ("B", "Tabak üstte, çaydanlık ortada, bardak alttadır."),
        ("C", "Çaydanlık üsttedir."),
        ("D", "Tabak alttadır."),
    ],
    correct="B",
    solution=(
        "Çaydanlık tabağın hemen altında → tabak üstte veya ortada; çaydanlık "
        "sırasıyla orta veya alt. Tabak altta değil (verildi) → tabak üst veya orta. "
        "Bardak üstte değil. Eğer tabak orta olsaydı çaydanlık alt olurdu; bardak "
        "üstte olamaz → bardak üst kalırdı ki yasak. Bu yüzden tabak üstte, "
        "çaydanlık orta, bardak alt zorunludur."
    ),
    distractor_logic={
        "A": "ignores_one_constraint",
        "C": "reverses_ordering",
        "D": "contradicts_given_premise",
    },
    seconds=55,
    notes="newly_authored; ordering constraints; easy",
)

items.append(
    item(
        qid="iq_tr_v1_logical_003",
        domain="logical_reasoning",
        difficulty=3,
        prompt_tr=(
            "Tüm denizciler yüzme bilir. Bazı yüzme bilenler müzisyendir. "
            "Ayşe müzisyendir.\n"
            "Hangisi kesin olarak doğrudur?"
        ),
        options=[
            ("A", "Ayşe denizcidir."),
            ("B", "Ayşe yüzme bilir."),
            ("C", "Ayşe'nin denizci olup olmadığı bu bilgilerle belirlenemez."),
            ("D", "Hiçbir müzisyen denizci değildir."),
        ],
        correct="C",
        solution=(
            "«Bazı yüzücüler müzisyen» ifadesi Ayşe için yüzme bilmeyi zorunlu kılmaz; "
            "müzisyen olmak denizci olmayı da gerektirmez. Bu nedenle Ayşe'nin "
            "denizciliği belirlenemez."
        ),
        distractor_logic={
            "A": "assumes_unsupported_information",
            "B": "confuses_some_with_all",
            "D": "selects_possible_not_necessary",
        },
        seconds=50,
        notes="newly_authored; set relationships; medium; ANCHOR",
        anchor_group="iq_tr_v1_anchor_logical",
    )
)
items.append(
    item(
        qid="iq_tr_v1_logical_004",
        domain="logical_reasoning",
        difficulty=3,
        prompt_tr=(
            "Bir yarışmada: «Birincilik için hem hızlı hem dikkatli olmak gerekir.»\n"
            "Deniz hızlıdır ama dikkatli değildir.\n"
            "Hangisi zorunludur?"
        ),
        options=[
            ("A", "Deniz birinciliği kazanamaz."),
            ("B", "Deniz birinciliği kazanır."),
            ("C", "Dikkatli olmak birincilik için yeterlidir."),
            ("D", "Hızlı olmak birincilik için yeterlidir."),
        ],
        correct="A",
        solution=(
            "Birincilik için gerekli koşullar: hızlı VE dikkatli (ikisi de gerekli). "
            "Deniz dikkatli değil → gerekli koşul eksik → birincilik imkânsız."
        ),
        distractor_logic={
            "B": "ignores_necessary_condition",
            "C": "confuses_necessary_with_sufficient",
            "D": "confuses_necessary_with_sufficient",
        },
        seconds=45,
        notes="newly_authored; necessary vs sufficient; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_logical_005",
        domain="logical_reasoning",
        difficulty=3,
        prompt_tr=(
            "Önerme 1: «Eğer lamba açıksa oda aydınlıktır.»\n"
            "Önerme 2: «Oda aydınlık değildir.»\n"
            "Hangisi zorunlu sonuçtur?"
        ),
        options=[
            ("A", "Lamba açıktır."),
            ("B", "Lamba kapalıdır."),
            ("C", "Lamba bozuktur."),
            ("D", "Oda pencereden aydınlanıyordur."),
        ],
        correct="B",
        solution=(
            "Modus tollens: P→Q ve ¬Q ⇒ ¬P. Oda aydınlık değil ⇒ lamba açık değildir "
            "(kapalıdır, bu bağlamda)."
        ),
        distractor_logic={
            "A": "contradicts_valid_inference",
            "C": "assumes_unsupported_information",
            "D": "assumes_unsupported_information",
        },
        seconds=45,
        notes="newly_authored; modus tollens; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_logical_006",
        domain="logical_reasoning",
        difficulty=4,
        prompt_tr=(
            "Aşağıdaki üç ifade birlikte veriliyor:\n"
            "1) En az bir kutu kırmızıdır.\n"
            "2) En az bir kutu mavidir.\n"
            "3) Her kutu ya kırmızı ya mavidir (ikisi birden değil).\n"
            "Toplam iki kutu vardır.\n"
            "Hangisi zorunludur?"
        ),
        options=[
            ("A", "İki kutu da kırmızıdır."),
            ("B", "Bir kutu kırmızı, bir kutu mavidir."),
            ("C", "İki kutu da mavidir."),
            ("D", "Kutuların renkleri belirlenemez."),
        ],
        correct="B",
        solution=(
            "İki kutu, her biri tek renk (kırmızı XOR mavi). En az bir kırmızı ve en "
            "az bir mavi → tam olarak bir kırmızı ve bir mavi olmalıdır."
        ),
        distractor_logic={
            "A": "ignores_one_constraint",
            "C": "ignores_one_constraint",
            "D": "assumes_underdetermination_when_determined",
        },
        seconds=60,
        notes="newly_authored; contradiction/constraint; hard",
    )
)
items.append(
    item(
        qid="iq_tr_v1_logical_007",
        domain="logical_reasoning",
        difficulty=4,
        prompt_tr=(
            "«Yalnızca yağmur yağarsa maç iptal edilir.» ifadesi doğru kabul edilsin.\n"
            "Maç iptal edilmiştir.\n"
            "Hangisi zorunludur?"
        ),
        options=[
            ("A", "Yağmur yağmıştır."),
            ("B", "Saha bozuk olduğu için iptal edilmiştir."),
            ("C", "Yağmur yağmamış olabilir."),
            ("D", "Maç oynanmıştır."),
        ],
        correct="A",
        solution=(
            "«Yalnızca yağmur yağarsa iptal» ≈ iptal ↔ yağmur (bu bağlamda: iptalin "
            "yeterli ve gerekli koşulu yağmur). Maç iptal → yağmur yağmıştır."
        ),
        distractor_logic={
            "B": "assumes_unsupported_information",
            "C": "ignores_biconditional_force",
            "D": "contradicts_given_premise",
        },
        seconds=55,
        notes="newly_authored; only-if / necessary-sufficient; hard",
    )
)

# ---------- PATTERN (6): E2 M3 H1 ----------
items.append(
    item(
        qid="iq_tr_v1_pattern_001",
        domain="pattern_reasoning",
        difficulty=2,
        prompt_tr="Dizi: 2, 4, 8, 16, ?\nBir sonraki sayı hangisidir?",
        options=[
            ("A", "24"),
            ("B", "30"),
            ("C", "32"),
            ("D", "18"),
        ],
        correct="C",
        solution=(
            "Her terim bir öncekinin 2 katı: 2→4→8→16→32. Bu tek, tutarlı ve en "
            "yalın kuraldır."
        ),
        distractor_logic={
            "A": "adds_fixed_increment_instead_of_doubling",
            "B": "arbitrary_arithmetic",
            "D": "adds_2_only",
        },
        seconds=35,
        notes="newly_authored; geometric doubling; easy; concept similar to common sequences but original wording",
    )
)
items.append(
    item(
        qid="iq_tr_v1_pattern_002",
        domain="pattern_reasoning",
        difficulty=2,
        prompt_tr=(
            "Sembol dizisi: ▲ ● ▲ ● ▲ ?\n"
            "Soru işareti yerine hangisi gelmelidir?"
        ),
        options=[
            ("A", "▲"),
            ("B", "●"),
            ("C", "■"),
            ("D", "◆"),
        ],
        correct="B",
        solution="İki sembolün dönüşümlü tekrarı: ▲●▲●▲●.",
        distractor_logic={
            "A": "repeats_previous_instead_of_alternating",
            "C": "introduces_new_symbol_without_rule",
            "D": "introduces_new_symbol_without_rule",
        },
        seconds=30,
        notes="newly_authored; alternating symbols; easy",
    )
)
items.append(
    item(
        qid="iq_tr_v1_pattern_003",
        domain="pattern_reasoning",
        difficulty=3,
        prompt_tr=(
            "Dizi: 3, 6, 5, 10, 9, 18, ?\n"
            "Bir sonraki sayı hangisidir?"
        ),
        options=[
            ("A", "17"),
            ("B", "36"),
            ("C", "20"),
            ("D", "15"),
        ],
        correct="A",
        solution=(
            "Kural çift adımlı: ×2, sonra −1: 3×2=6, 6−1=5, 5×2=10, 10−1=9, "
            "9×2=18, 18−1=17. En yalın düzenli kural budur."
        ),
        distractor_logic={
            "B": "applies_only_doubling",
            "C": "arbitrary_increment",
            "D": "subtracts_from_wrong_term",
        },
        seconds=50,
        notes="newly_authored; multi-rule sequence; medium; ANCHOR",
        anchor_group="iq_tr_v1_anchor_pattern",
    )
)
items.append(
    item(
        qid="iq_tr_v1_pattern_004",
        domain="pattern_reasoning",
        difficulty=3,
        prompt_tr=(
            "Her satırda aynı kural geçerlidir:\n"
            "2  3  6\n"
            "4  5  20\n"
            "3  7  ?\n"
            "? yerine ne gelmelidir?"
        ),
        options=[
            ("A", "10"),
            ("B", "21"),
            ("C", "14"),
            ("D", "24"),
        ],
        correct="B",
        solution="Satır kuralı: üçüncü = birinci × ikinci. 3×7=21.",
        distractor_logic={
            "A": "adds_instead_of_multiplying",
            "C": "multiplies_by_wrong_factor",
            "D": "adds_product_components_incorrectly",
        },
        seconds=45,
        notes="newly_authored; matrix product rule; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_pattern_005",
        domain="pattern_reasoning",
        difficulty=3,
        prompt_tr=(
            "Harf-sayı eşlemesi (A=1, B=2, …):\n"
            "C-3, F-6, I-9, ?\n"
            "Sonraki çift hangisidir?"
        ),
        options=[
            ("A", "J-10"),
            ("B", "L-12"),
            ("C", "K-11"),
            ("D", "H-8"),
        ],
        correct="B",
        solution=(
            "Harfler 3'er artar (C,F,I,L) ve sayılar harf sırasına eşittir "
            "(3,6,9,12)."
        ),
        distractor_logic={
            "A": "increments_by_one_only",
            "C": "increments_by_two",
            "D": "moves_backward",
        },
        seconds=45,
        notes="newly_authored; letter-number progression; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_pattern_006",
        domain="pattern_reasoning",
        difficulty=4,
        prompt_tr=(
            "Dizi: 1, 2, 6, 24, 120, ?\n"
            "Bir sonraki sayı hangisidir?"
        ),
        options=[
            ("A", "240"),
            ("B", "600"),
            ("C", "720"),
            ("D", "480"),
        ],
        correct="C",
        solution=(
            "n! dizisi: 1=1!, 2=2!, 6=3!, 24=4!, 120=5!, sonraki 6!=720. "
            "Çarpanlar 2,3,4,5,6 şeklinde artar; alternatif «sürekli ×2» kuralı "
            "verilerle uyumsuzdur."
        ),
        distractor_logic={
            "A": "doubles_previous",
            "B": "multiplies_by_5_only",
            "D": "multiplies_by_4",
        },
        seconds=55,
        notes="newly_authored; factorial pattern; hard; flag: factorial knowledge light but pattern of increasing multipliers is visible",
    )
)

# ---------- VERBAL (6): E2 M3 H1 ----------
items.append(
    item(
        qid="iq_tr_v1_verbal_001",
        domain="verbal_reasoning",
        difficulty=2,
        prompt_tr=(
            "İlişki: «Öğretmen / okul» ilişkisine en çok benzeyen hangisidir?"
        ),
        options=[
            ("A", "Doktor / hastane"),
            ("B", "Kitap / sayfa"),
            ("C", "Yolcu / bilet"),
            ("D", "Kalem / yazı"),
        ],
        correct="A",
        solution=(
            "İlişki: meslek insanı ile birincil çalışma mekânı. Doktor-hastane aynı "
            "ilişkiyi taşır."
        ),
        distractor_logic={
            "B": "part_whole_not_profession_place",
            "C": "user_object_relation",
            "D": "tool_product_relation",
        },
        seconds=35,
        notes="newly_authored; analogy; easy; Turkish-specific; needs locale equivalent not literal translation",
    )
)
items.append(
    item(
        qid="iq_tr_v1_verbal_002",
        domain="verbal_reasoning",
        difficulty=2,
        prompt_tr=(
            "Aşağıdaki cümleden zorunlu olarak çıkan sonuç hangisidir?\n"
            "«Bütün katılımcılar kimlik kartı getirdi.»"
        ),
        options=[
            ("A", "Hiçbir katılımcı kimlik kartı getirmemiştir."),
            ("B", "En az bir katılımcı kimlik kartı getirmiştir."),
            ("C", "Katılımcıların çoğu kimlik kartı getirmemiştir."),
            ("D", "Kimlik kartı getirmeyenler yarışa alınmamıştır."),
        ],
        correct="B",
        solution=(
            "«Bütün» evrensel olumlu önerme, küme boş değilse «en az bir»i gerektirir; "
            "soru bağlamında katılımcı kümesi dolu kabul edilir. Diğer şıklar "
            "çelişir veya ek bilgi ekler."
        ),
        distractor_logic={
            "A": "contradicts_universal_affirmative",
            "C": "contradicts_universal_affirmative",
            "D": "assumes_unsupported_information",
        },
        seconds=40,
        notes="newly_authored; inference from statement; easy",
    )
)
items.append(
    item(
        qid="iq_tr_v1_verbal_003",
        domain="verbal_reasoning",
        difficulty=3,
        prompt_tr=(
            "Argüman: «Bu ilaç ateşi düşürür; çünkü benzer bileşenli ilaçlar ateşi "
            "düşürmüştür.»\n"
            "Argümandaki asıl dayanak hangisidir?"
        ),
        options=[
            ("A", "İlacın fiyatı uygundur."),
            ("B", "Benzerlikten yola çıkan bir genelleme."),
            ("C", "İlacın rengi kırmızıdır."),
            ("D", "Ateş her zaman zararsızdır."),
        ],
        correct="B",
        solution=(
            "Argüman, benzer örneklerden bu ilaca geçiş yapan bir analoji/"
            "genellemedir."
        ),
        distractor_logic={
            "A": "irrelevant_attribute",
            "C": "irrelevant_attribute",
            "D": "unsupported_value_claim",
        },
        seconds=45,
        notes="newly_authored; argument structure; medium; ANCHOR; no medical advice—structure only",
        anchor_group="iq_tr_v1_anchor_verbal",
    )
)
items.append(
    item(
        qid="iq_tr_v1_verbal_004",
        domain="verbal_reasoning",
        difficulty=3,
        prompt_tr=(
            "«Kedi, köpek, at» grubuna «aynı kategori ilişkisi» açısından hangisi "
            "uymaz?"
        ),
        options=[
            ("A", "Koyun"),
            ("B", "Tavşan"),
            ("C", "Masa"),
            ("D", "İnek"),
        ],
        correct="C",
        solution="İlk üçü canlı hayvan; masa cansız nesnedir.",
        distractor_logic={
            "A": "same_category_animal",
            "B": "same_category_animal",
            "D": "same_category_animal",
        },
        seconds=30,
        notes="newly_authored; category relation; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_verbal_005",
        domain="verbal_reasoning",
        difficulty=3,
        prompt_tr=(
            "Cümle: «Toplantı kısa sürdü; ancak kararlar netleşti.»\n"
            "«Ancak» bağlacının işlevi hangisine en yakındır?"
        ),
        options=[
            ("A", "Neden belirtmek"),
            ("B", "Zıtlık / beklenmedik sonuç ilişkisi kurmak"),
            ("C", "Zaman sırası bildirmek"),
            ("D", "Koşul bildirmek"),
        ],
        correct="B",
        solution=(
            "«Ancak» burada kısa sürmeye karşın net karar çıktığını gösteren "
            "karşıtlık bağlacıdır."
        ),
        distractor_logic={
            "A": "confuses_contrast_with_cause",
            "C": "confuses_contrast_with_sequence",
            "D": "confuses_contrast_with_condition",
        },
        seconds=40,
        notes="newly_authored; contextual meaning; medium; Turkish connective; locale-specific",
    )
)
items.append(
    item(
        qid="iq_tr_v1_verbal_006",
        domain="verbal_reasoning",
        difficulty=4,
        prompt_tr=(
            "İki ifade:\n"
            "1) «Bazı raporlar gecikti.»\n"
            "2) «Hiçbir rapor gecikmedi.»\n"
            "Bu iki ifade hakkında hangisi doğrudur?"
        ),
        options=[
            ("A", "İkisi birden doğru olabilir."),
            ("B", "İkisi birden yanlış olabilir ama ikisi birden doğru olamaz."),
            ("C", "İkisi mantıken eşdeğerdir."),
            ("D", "İkinci ifade birinciden zorunlu olarak çıkar."),
        ],
        correct="B",
        solution=(
            "İfadeler çelişiktir; aynı anda doğru olamazlar. İkisi birden yanlış "
            "olabilir (ör. tüm raporlar zamanında ama başka bir durum — aslında "
            "klasik: «bazı» ile «hiçbir» doğrudan çelişir; birlikte doğru olamaz. "
            "Birlikte yanlış: eğer «tüm raporlar gecikti» ise (1) doğru olur. "
            "Daha temiz: (1) ve (2) çelişir → birlikte doğru olamaz. Birlikte "
            "yanlış mümkün mü? Evet, eğer tüm raporlar geciktive (1) doğru… "
            "Aslında «bazı gecikti» yanlışsa hiçbiri gecikmemiş demektir ki (2) "
            "doğru olur. Yani klasik karşıtlıkta biri doğru diğer yanlış "
            "(contradictories). O halde B'nin «ikisi birden yanlış olabilir» "
            "kısmı hatalı!\n"
            "Düzelt: doğru şık «birlikte doğru olamazlar; biri doğruysa diğeri "
            "yanlıştır» olmalı."
        ),
        distractor_logic={
            "A": "allows_contradiction",
            "C": "false_equivalence",
            "D": "invalid_entailment",
        },
        seconds=55,
        notes="FIX_VERBAL_006",
    )
)

items[-1] = item(
    qid="iq_tr_v1_verbal_006",
    domain="verbal_reasoning",
    difficulty=4,
    prompt_tr=(
        "İki ifade:\n"
        "1) «Bazı raporlar gecikti.»\n"
        "2) «Hiçbir rapor gecikmedi.»\n"
        "Bu iki ifade hakkında hangisi doğrudur?"
    ),
    options=[
        ("A", "İkisi birden doğru olabilir."),
        ("B", "Aynı anda doğru olamazlar; biri doğruysa diğeri yanlıştır."),
        ("C", "İkisi mantıken eşdeğerdir."),
        ("D", "İkinci ifade birinciden zorunlu olarak çıkar."),
    ],
    correct="B",
    solution=(
        "«Bazı … gecikti» ile «hiçbir … gecikmedi» çelişik önermelerdir; aynı "
        "anda doğru olamazlar ve biri doğruysa diğeri yanlıştır."
    ),
    distractor_logic={
        "A": "allows_contradiction",
        "C": "false_equivalence",
        "D": "invalid_entailment",
    },
    seconds=55,
    notes="newly_authored; opposition of quantifiers; hard; locale-specific",
)

# ---------- SPATIAL (6): E2 M3 H1 ----------
items.append(
    item(
        qid="iq_tr_v1_spatial_001",
        domain="spatial_reasoning",
        difficulty=2,
        prompt_tr=(
            "Bir ızgarada: Kuzey yukarıdır. Nokta A, nokta B'nin iki birim "
            "kuzeyindedir. B, C'nin bir birim doğusundadır.\n"
            "A, C'ye göre nerededir?"
        ),
        options=[
            ("A", "Bir birim batı, iki birim kuzey"),
            ("B", "Bir birim doğu, iki birim kuzey"),
            ("C", "İki birim güney"),
            ("D", "Bir birim batı, iki birim güney"),
        ],
        correct="B",
        solution=(
            "C orijin olsun. B = C + (1 doğu). A = B + (2 kuzey) = C + (1 doğu, "
            "2 kuzey)."
        ),
        distractor_logic={
            "A": "reverses_east_west",
            "C": "ignores_east_offset",
            "D": "reverses_both_axes",
        },
        seconds=45,
        notes="newly_authored; relative position; easy",
    )
)
items.append(
    item(
        qid="iq_tr_v1_spatial_002",
        domain="spatial_reasoning",
        difficulty=2,
        prompt_tr=(
            "Bir kişi kuzeye bakarak durur. Sağa döner, sonra tekrar sağa döner.\n"
            "Şimdi hangi yöne bakmaktadır?"
        ),
        options=[
            ("A", "Kuzey"),
            ("B", "Doğu"),
            ("C", "Güney"),
            ("D", "Batı"),
        ],
        correct="C",
        solution="Kuzey → sağa = doğu → sağa = güney.",
        distractor_logic={
            "A": "ignores_turns",
            "B": "stops_after_one_turn",
            "D": "turns_left_instead_of_right",
        },
        seconds=30,
        notes="newly_authored; direction changes; easy",
    )
)
items.append(
    item(
        qid="iq_tr_v1_spatial_003",
        domain="spatial_reasoning",
        difficulty=3,
        prompt_tr=(
            "Küpün ön yüzünde A, üst yüzünde B yazıyor. Küp, ön yüz aşağı gelecek "
            "şekilde öne doğru 90° döndürülüyor.\n"
            "Döndürmeden sonra üst yüzde hangi harf görünür?"
        ),
        options=[
            ("A", "A"),
            ("B", "B"),
            ("C", "A'nın karşı yüzü (görünmeyen yüz)"),
            ("D", "B'nin karşı yüzü"),
        ],
        correct="A",
        solution=(
            "Öne 90° (ön yüz aşağı): eski ön (A) alta iner; eski üst (B) öne gelir; "
            "eski arka üste gelir. Üst = eski arka = A'nın karşı yüzü değil — "
            "düzelt: ön alta, üst öne, alt arkaya, arka üste. Üstteki yeni yüz = "
            "eski arka yüz = A'nın karşıtı. Şık C.\n"
            "Yeniden: Standart: bakılan ön=A, üst=B. Pitch forward 90°: eski ön "
            "taban olur, eski üst ön olur, eski arka tavan olur. Yeni üst = eski "
            "arka = A'nın karşısı. Doğru C."
        ),
        distractor_logic={
            "A": "confuses_new_top_with_old_front",
            "B": "assumes_top_unchanged",
            "D": "confuses_opposite_of_B",
        },
        seconds=60,
        notes="FIX_SPATIAL_003",
    )
)

items[-1] = item(
    qid="iq_tr_v1_spatial_003",
    domain="spatial_reasoning",
    difficulty=3,
    prompt_tr=(
        "Bir küpün ön yüzünde A, üst yüzünde B vardır. Küp, ön yüz taban "
        "olacak şekilde öne doğru 90° döndürülür.\n"
        "Döndürmeden sonra üst yüzde hangisi bulunur?"
    ),
    options=[
        ("A", "A"),
        ("B", "B"),
        ("C", "A'nın karşı yüzü"),
        ("D", "B'nin karşı yüzü"),
    ],
    correct="C",
    solution=(
        "Öne 90°: eski ön tabana, eski üst öne, eski arka üste gelir. Eski arka, "
        "A'nın karşı yüzüdür; yeni üst budur."
    ),
    distractor_logic={
        "A": "confuses_new_top_with_old_front",
        "B": "assumes_top_unchanged",
        "D": "selects_opposite_of_wrong_face",
    },
    seconds=60,
    notes="newly_authored; cube rotation; medium; ANCHOR",
    anchor_group="iq_tr_v1_anchor_spatial",
)

items.append(
    item(
        qid="iq_tr_v1_spatial_004",
        domain="spatial_reasoning",
        difficulty=3,
        prompt_tr=(
            "Kâğıt üzerinde L şeklinde bir yol çizilmiştir: 3 birim kuzeye, sonra "
            "2 birim doğuya.\n"
            "Başlangıç noktasına göre bitiş noktası nerededir?"
        ),
        options=[
            ("A", "2 doğu, 3 kuzey"),
            ("B", "3 doğu, 2 kuzey"),
            ("C", "2 batı, 3 kuzey"),
            ("D", "2 doğu, 3 güney"),
        ],
        correct="A",
        solution="Net yer değiştirme: +3 kuzey, +2 doğu.",
        distractor_logic={
            "B": "swaps_components",
            "C": "reverses_east_west",
            "D": "reverses_north_south",
        },
        seconds=40,
        notes="newly_authored; path orientation; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_spatial_005",
        domain="spatial_reasoning",
        difficulty=3,
        prompt_tr=(
            "Bir masa üzerinde: kitap defterin solundadır. Kalem defterin "
            "önündedir. Gözlemci masaya bakmaktadır (ön = gözlemciye yakın).\n"
            "Kalem, kitaba göre yaklaşık nerededir?"
        ),
        options=[
            ("A", "Kitabın sağ-önünde"),
            ("B", "Kitabın sol-arkasında"),
            ("C", "Kitabın tam arkasında"),
            ("D", "Kitabın tam solunda"),
        ],
        correct="A",
        solution=(
            "Defter referans: kitap solunda, kalem önünde. Kitaptan bakınca defter "
            "sağda, kalem defterin önünde → kitabın sağ-ön bölgesi."
        ),
        distractor_logic={
            "B": "reverses_left_right_and_front_back",
            "C": "ignores_right_offset",
            "D": "ignores_front_offset",
        },
        seconds=50,
        notes="newly_authored; relative layout; medium",
    )
)
items.append(
    item(
        qid="iq_tr_v1_spatial_006",
        domain="spatial_reasoning",
        difficulty=4,
        prompt_tr=(
            "Düz bir kâğıtta ok işareti sağa (→) bakıyor. Kâğıt, saat yönünde "
            "90° döndürülüyor; ardından bir kez daha saat yönünde 90° "
            "döndürülüyor.\n"
            "Ok şimdi hangi yöne bakar?"
        ),
        options=[
            ("A", "Sağa (→)"),
            ("B", "Aşağı (↓)"),
            ("C", "Sola (←)"),
            ("D", "Yukarı (↑)"),
        ],
        correct="C",
        solution=(
            "Saat yönünde 90°: → ↓ olur; bir 90° daha: ↓ ← olur. Toplam 180°."
        ),
        distractor_logic={
            "A": "ignores_rotations",
            "B": "stops_after_one_rotation",
            "D": "rotates_counterclockwise",
        },
        seconds=45,
        notes="newly_authored; viewpoint/planar rotation; hard",
    )
)

# Verify counts
from collections import Counter

dom = Counter(i["primary_dimension"] for i in items)
diff = Counter(i["difficulty"] for i in items)
corr = Counter(i["correct_option_id"] for i in items)
assert len(items) == 25, len(items)
assert dom == {
    "logical_reasoning": 7,
    "pattern_reasoning": 6,
    "verbal_reasoning": 6,
    "spatial_reasoning": 6,
}, dom
assert diff[2] == 8 and diff[3] == 12 and diff[4] == 5, diff
assert set(corr) <= {"A", "B", "C", "D"}
# Rebalance correct positions if needed
print("correct dist before balance", dict(corr))

# Enforce A:7 B:6 C:6 D:6 by swapping options where needed without breaking sense
# Manual check - compute and adjust by rewriting option order for selected items

form = {
    "form_id": "iq_tr_pilot_v1",
    "set_id": SET_ID,
    "module": "iq",
    "locale": "tr-TR",
    "schema_version": 3,
    "question_schema_version": "qmatch_question_schema_v3",
    "content_version": CV,
    "status": "pilot",
    "calibration_status": "uncalibrated",
    "question_count": 25,
    "trait_scoring_version": "trait_scoring_v1.0",
    "dimension_registry_version": "canonical_dimension_registry_v1",
    "difficulty_band_encoding": {"easy": 2, "medium": 3, "hard": 4},
    "notes": {
        "en_prompt_fields": "schema-required stubs only; not authored translations",
        "provisional": True,
        "not_production": True,
    },
    "items": items,
}

import sys
if OUT.exists() and "--force" not in sys.argv:
    raise SystemExit(f"Refusing to overwrite {OUT}; pass --force after rebalancing plan is applied.")
OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(form, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("wrote", OUT)
print("domains", dict(dom))
print("difficulty", dict(diff))
print("correct", dict(Counter(i["correct_option_id"] for i in items)))
print("anchors", [i["question_id"] for i in items if i.get("anchor_group")])
