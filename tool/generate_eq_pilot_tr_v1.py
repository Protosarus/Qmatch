#!/usr/bin/env python3
"""Generate eq_pilot_tr_v1.json — offline only, not a runtime asset."""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/data/assessment_v3/eq/eq_pilot_tr_v1.json"

EN_STUB = "EN equivalent pending (tr-TR pilot reference; not a translation)."
TS = "2026-07-24T00:00:00Z"
CV = "eq-tr-pilot-v1"
FORM_ID = "eq_tr_pilot_v1"
SET_ID = "eq_tr_pilot_v1_set_001"

DIMENSIONS = [
    "empathy",
    "perspective_taking",
    "self_awareness",
    "emotion_regulation",
    "emotional_openness",
    "boundary_setting",
    "assertiveness",
    "conflict_approach",
    "repair_orientation",
    "social_awareness",
]

FAMILY_ITEMS: dict[str, list[str]] = {
    "interpersonal_support": [
        "eq_tr_v1_empathy_001",
        "eq_tr_v1_repair_orientation_001",
        "eq_tr_v1_social_awareness_001",
    ],
    "internal_emotional_awareness": [
        "eq_tr_v1_self_awareness_001",
        "eq_tr_v1_emotion_regulation_001",
        "eq_tr_v1_emotional_openness_001",
    ],
    "boundary_and_request_conflicts": [
        "eq_tr_v1_boundary_setting_001",
        "eq_tr_v1_assertiveness_001",
        "eq_tr_v1_conflict_approach_001",
    ],
    "repair_after_disagreement": [
        "eq_tr_v1_repair_orientation_002",
        "eq_tr_v1_empathy_002",
        "eq_tr_v1_conflict_approach_002",
    ],
    "perspective_taking_family": [
        "eq_tr_v1_perspective_taking_001",
        "eq_tr_v1_perspective_taking_002",
        "eq_tr_v1_social_awareness_002",
    ],
    "emotional_disclosure": [
        "eq_tr_v1_emotional_openness_002",
        "eq_tr_v1_emotional_openness_003",
        "eq_tr_v1_empathy_003",
    ],
    "social_context_awareness": [
        "eq_tr_v1_social_awareness_003",
        "eq_tr_v1_perspective_taking_003",
        "eq_tr_v1_self_awareness_002",
    ],
    "stress_and_regulation": [
        "eq_tr_v1_emotion_regulation_002",
        "eq_tr_v1_emotion_regulation_003",
        "eq_tr_v1_self_awareness_003",
    ],
    "competing_values_and_tradeoffs": [
        "eq_tr_v1_boundary_setting_002",
        "eq_tr_v1_assertiveness_002",
        "eq_tr_v1_conflict_approach_003",
    ],
    "repeated_behavioral_patterns": [
        "eq_tr_v1_boundary_setting_003",
        "eq_tr_v1_assertiveness_003",
        "eq_tr_v1_repair_orientation_003",
    ],
}

SECONDARY_MAP: dict[str, list[str]] = {
    "eq_tr_v1_repair_orientation_001": ["empathy"],
    "eq_tr_v1_social_awareness_001": ["empathy"],
    "eq_tr_v1_emotion_regulation_001": ["self_awareness"],
    "eq_tr_v1_emotional_openness_001": ["self_awareness"],
    "eq_tr_v1_boundary_setting_001": ["assertiveness"],
    "eq_tr_v1_assertiveness_001": ["emotion_regulation"],
    "eq_tr_v1_conflict_approach_001": ["perspective_taking"],
    "eq_tr_v1_empathy_002": ["repair_orientation"],
    "eq_tr_v1_conflict_approach_002": ["emotion_regulation"],
    "eq_tr_v1_repair_orientation_002": ["emotional_openness"],
    "eq_tr_v1_perspective_taking_001": ["social_awareness"],
    "eq_tr_v1_social_awareness_002": ["perspective_taking"],
    "eq_tr_v1_empathy_003": ["emotional_openness"],
    "eq_tr_v1_social_awareness_003": ["repair_orientation"],
    "eq_tr_v1_perspective_taking_003": ["conflict_approach"],
    "eq_tr_v1_self_awareness_002": ["social_awareness"],
    "eq_tr_v1_boundary_setting_002": ["assertiveness"],
    "eq_tr_v1_assertiveness_002": ["boundary_setting"],
    "eq_tr_v1_conflict_approach_003": ["boundary_setting"],
    "eq_tr_v1_repair_orientation_003": ["conflict_approach"],
}

SEMANTIC_PAIRS = {
    "eq_tr_v1_sem_01": ["eq_tr_v1_empathy_001", "eq_tr_v1_empathy_002"],
    "eq_tr_v1_sem_02": [
        "eq_tr_v1_perspective_taking_001",
        "eq_tr_v1_perspective_taking_002",
    ],
    "eq_tr_v1_sem_03": [
        "eq_tr_v1_boundary_setting_001",
        "eq_tr_v1_boundary_setting_002",
    ],
    "eq_tr_v1_sem_04": [
        "eq_tr_v1_assertiveness_001",
        "eq_tr_v1_assertiveness_002",
    ],
    "eq_tr_v1_sem_05": [
        "eq_tr_v1_repair_orientation_001",
        "eq_tr_v1_repair_orientation_002",
    ],
    "eq_tr_v1_sem_06": [
        "eq_tr_v1_emotion_regulation_001",
        "eq_tr_v1_emotion_regulation_002",
    ],
}

REVERSE_PAIRS = {
    "eq_tr_v1_rev_01": [
        "eq_tr_v1_emotional_openness_001",
        "eq_tr_v1_emotional_openness_002",
    ],
    "eq_tr_v1_rev_02": [
        "eq_tr_v1_boundary_setting_001",
        "eq_tr_v1_boundary_setting_003",
    ],
    "eq_tr_v1_rev_03": [
        "eq_tr_v1_assertiveness_001",
        "eq_tr_v1_assertiveness_003",
    ],
    "eq_tr_v1_rev_04": [
        "eq_tr_v1_conflict_approach_001",
        "eq_tr_v1_conflict_approach_003",
    ],
    "eq_tr_v1_rev_05": [
        "eq_tr_v1_self_awareness_001",
        "eq_tr_v1_self_awareness_003",
    ],
}

ISOMORPH_GROUPS = {
    "eq_tr_v1_iso_01": ["eq_tr_v1_empathy_001", "eq_tr_v1_empathy_003"],
    "eq_tr_v1_iso_02": [
        "eq_tr_v1_boundary_setting_002",
        "eq_tr_v1_assertiveness_002",
    ],
    "eq_tr_v1_iso_03": [
        "eq_tr_v1_repair_orientation_002",
        "eq_tr_v1_repair_orientation_003",
    ],
    "eq_tr_v1_iso_04": [
        "eq_tr_v1_perspective_taking_002",
        "eq_tr_v1_perspective_taking_003",
    ],
    "eq_tr_v1_iso_05": [
        "eq_tr_v1_emotion_regulation_002",
        "eq_tr_v1_emotion_regulation_003",
    ],
}

ANCHORS = {
    "eq_tr_v1_empathy_001": "eq_tr_v1_anchor_empathy",
    "eq_tr_v1_emotion_regulation_001": "eq_tr_v1_anchor_emotion_regulation",
    "eq_tr_v1_boundary_setting_001": "eq_tr_v1_anchor_boundary_setting",
}

SDR_ITEMS = {
    "eq_tr_v1_empathy_001",
    "eq_tr_v1_emotional_openness_001",
    "eq_tr_v1_repair_orientation_001",
    "eq_tr_v1_assertiveness_002",
    "eq_tr_v1_social_awareness_001",
}

RESPONSE_VARIATION_ITEMS = {
    "eq_tr_v1_perspective_taking_002",
    "eq_tr_v1_self_awareness_002",
    "eq_tr_v1_conflict_approach_002",
    "eq_tr_v1_emotional_openness_003",
    "eq_tr_v1_repair_orientation_003",
}


def family_for(qid: str) -> str:
    for fam, ids in FAMILY_ITEMS.items():
        if qid in ids:
            return fam
    raise KeyError(qid)


def pair_lookup(pairs: dict[str, list[str]]) -> dict[str, str]:
    out: dict[str, str] = {}
    for pid, ids in pairs.items():
        for qid in ids:
            out[qid] = pid
    return out


SEM_LOOKUP = pair_lookup(SEMANTIC_PAIRS)
REV_LOOKUP = pair_lookup(REVERSE_PAIRS)
ISO_LOOKUP: dict[str, str] = {}
for gid, ids in ISOMORPH_GROUPS.items():
    for qid in ids:
        ISO_LOOKUP[qid] = gid


def l1(deltas: dict[str, float]) -> float:
    return sum(abs(v) for v in deltas.values())


def make_option(
    oid: str,
    text_tr: str,
    deltas: dict[str, float],
    *,
    primary: str,
    sdr: str = "low",
    extremity: float = 0.35,
    evidence: float = 0.72,
    rationale: str,
    counter: dict | None = None,
    style_risk: str = "low",
) -> dict:
    assert primary in deltas
    assert len(deltas) <= 3
    assert l1(deltas) <= 1.40
    return {
        "option_id": oid,
        "localized_text": {"tr": text_tr, "en": EN_STUB},
        "dimension_deltas": {k: round(v, 2) for k, v in deltas.items()},
        "evidence_strength": evidence,
        "counter_evidence": counter or {},
        "social_desirability_risk": sdr,
        "extremity": extremity,
        "response_style_risk": style_risk,
        "rationale": rationale,
        "status": "active",
    }


def rvi_roles(qid: str) -> list[str]:
    roles = ["timing_quality"]
    if qid in SEM_LOOKUP:
        roles.append("semantic_consistency")
    if qid in REV_LOOKUP:
        roles.append("reverse_consistency")
    if qid in ISO_LOOKUP:
        roles.append("repeated_context_stability")
    if qid in SDR_ITEMS:
        roles.append("social_impression_risk")
    if qid in RESPONSE_VARIATION_ITEMS:
        roles.append("response_variation")
    return sorted(set(roles))


def build_item(
    qid: str,
    primary: str,
    prompt_tr: str,
    option_specs: list[tuple[str, str, dict[str, float], dict]],
    *,
    provenance: str,
    tradeoff: str,
    avoids: str,
    seconds: int = 42,
) -> dict:
    fam = family_for(qid)
    secondaries = SECONDARY_MAP.get(qid, [])
    anchor = ANCHORS.get(qid)
    sdr_item = "moderate" if qid in SDR_ITEMS else "low"
    notes = (
        f"{provenance}; scenario_family={fam}; sdr_item_risk={sdr_item}; "
        f"tradeoff={tradeoff}; how_avoids_ideal_answer={avoids}"
    )
    options = []
    for oid, text_tr, deltas, meta in option_specs:
        options.append(
            make_option(
                oid,
                text_tr,
                deltas,
                primary=primary,
                sdr=meta.get("sdr", "low"),
                extremity=meta.get("extremity", 0.35),
                evidence=meta.get("evidence", 0.72),
                rationale=meta.get("rationale", ""),
                counter=meta.get("counter"),
                style_risk=meta.get("style_risk", "low"),
            )
        )
    return {
        "question_id": qid,
        "module": "eq",
        "schema_version": "qmatch_question_schema_v3",
        "content_version": CV,
        "locale": {"default": "tr-TR", "supported": ["tr-TR"]},
        "status": "pilot",
        "review_state": "internal_review",
        "item_type": "scenario_mcq",
        "primary_dimension": primary,
        "secondary_dimensions": secondaries,
        "prompt": {"tr": prompt_tr, "en": EN_STUB},
        "options": options,
        "explanation_availability": "reviewer_only",
        "calibration_status": "uncalibrated",
        "anchor_group": anchor,
        "semantic_pair_id": SEM_LOOKUP.get(qid),
        "reverse_pair_id": REV_LOOKUP.get(qid),
        "behavioral_isomorph_group": ISO_LOOKUP.get(qid),
        "separator_targets": [],
        "response_validity_roles": rvi_roles(qid),
        "exposure_class": "anchor" if anchor else "pilot",
        "security_level": "standard",
        "estimated_completion_seconds": seconds,
        "authoring_notes": notes,
        "created_at": TS,
        "updated_at": TS,
    }


# Option delta templates keyed by question_id
# Each: list of (option_id, text_tr, dimension_deltas, meta_kwargs)

ITEM_CONTENT: dict[str, dict] = {}


def _spec(
    qid: str,
    primary: str,
    prompt: str,
    opts: list,
    provenance: str,
    tradeoff: str,
    avoids: str,
    seconds: int = 42,
) -> None:
    ITEM_CONTENT[qid] = {
        "primary": primary,
        "prompt": prompt,
        "opts": opts,
        "provenance": provenance,
        "tradeoff": tradeoff,
        "avoids": avoids,
        "seconds": seconds,
    }


# --- empathy ---
_spec(
    "eq_tr_v1_empathy_001",
    "empathy",
    "Yakın bir arkadaşın zor bir ayrılık yaşıyor ve mesaj atıp duygularını anlatıyor. "
    "Bu akşam başka planların var ama onu duymak istiyorsun. Ne yaparsın?",
    [
        (
            "A",
            "Planını erteleyip telefonda uzun süre dinler, hissettiklerini yansıtmaya çalışırsın.",
            {"empathy": 0.72, "boundary_setting": -0.22},
            {
                "sdr": "moderate",
                "extremity": 0.55,
                "rationale": "Yüksek duygusal yanıt; sınır maliyeti taşır.",
                "counter": {"boundary_setting": 0.15},
            },
        ),
        (
            "B",
            "Kısa ama sıcak bir mesaj atıp yarın yüz yüze konuşmayı teklif edersin.",
            {"empathy": 0.38, "boundary_setting": 0.18},
            {
                "rationale": "Orta düzey destek; zaman sınırı korunur.",
            },
        ),
        (
            "C",
            "Pratik bir tavsiye listesi gönderir, kendi deneyiminden bir örnek eklersin.",
            {"empathy": 0.12, "assertiveness": 0.15},
            {
                "rationale": "Destek niyeti var; duygusal yansıtma sınırlı.",
                "counter": {"empathy": -0.1},
            },
        ),
        (
            "D",
            "Meşgul olduğunu söyleyip kafasını dağıtması için etkinlik önerirsin.",
            {"empathy": -0.45, "emotion_regulation": 0.2},
            {
                "rationale": "Kaçınma eğilimi; duygusal ihtiyaç ikinci planda.",
            },
        ),
    ],
    "adapted_from_legacy_scenario",
    "destek vs zaman sınırı",
    "dinleme, tavsiye ve mesafe seçenekleri eşit derecede savunulabilir",
    48,
)

_spec(
    "eq_tr_v1_empathy_002",
    "empathy",
    "İş arkadaşınla tartıştıktan sonra o soğuk davranıyor; sen barışmak istiyorsun "
    "ama hâlâ kırgınsın. İlk adımı nasıl atarsın?",
    [
        (
            "A",
            "Onun bakış açısını anlamaya çalışır, duygusunu doğrudan sorarsın.",
            {"empathy": 0.68, "repair_orientation": 0.28},
            {"rationale": "Empati odaklı onarım girişimi."},
        ),
        (
            "B",
            "Bir süre bekler, ortam sakinleşince kısa bir özür ve ortak zemin ararsın.",
            {"empathy": 0.42, "repair_orientation": 0.22},
            {"rationale": "Ölçülü yakınlaşma; duygusal yoğunluk düşük."},
        ),
        (
            "C",
            "Konuyu iş gündemine bağlayarak mesleki iletişimi sürdürürsün.",
            {"empathy": 0.05, "conflict_approach": 0.18},
            {
                "rationale": "Duygusal konuyu dolaylı ele alır.",
                "counter": {"empathy": -0.08},
            },
        ),
        (
            "D",
            "Kendi haklılığını koruyup mesafeyi sürdürürsün.",
            {"empathy": -0.52, "assertiveness": 0.25},
            {"rationale": "Empatik bağ kurulmaz; savunma öncelikli."},
        ),
    ],
    "newly_authored",
    "onarım vs korunma",
    "hem duygusal yakınlaşma hem mesafe makul gerekçelere dayanır",
)

_spec(
    "eq_tr_v1_empathy_003",
    "empathy",
    "Flörtün duygusal bir konuyu açmak istiyor ama sen yorgunsun. "
    "Açmak istediği şey seni de etkileyebilir. Nasıl karşılık verirsin?",
    [
        (
            "A",
            "Yorgun olsan da dinlemeye hazır olduğunu söyler, dikkatini verirsin.",
            {"empathy": 0.7, "emotional_openness": 0.22},
            {"sdr": "moderate", "rationale": "Yüksek duygusal erişilebilirlik."},
        ),
        (
            "B",
            "Dinlemek istediğini ama kısa tutmayı tercih ettiğini açıkça belirtirsin.",
            {"empathy": 0.45, "boundary_setting": 0.2},
            {"rationale": "Empati ile sınır dengelenir."},
        ),
        (
            "C",
            "Yarın daha uygun bir zaman önerir, kısa bir destek mesajı eklersin.",
            {"empathy": 0.18, "boundary_setting": 0.28},
            {"rationale": "Erteleme; sınırlı duygusal yansıtma."},
        ),
        (
            "D",
            "Konuyu hafife alıp başka bir şeye yönlendirmeye çalışırsın.",
            {"empathy": -0.4, "emotional_openness": -0.22},
            {"rationale": "Duygusal ihtiyaç minimize edilir."},
        ),
    ],
    "newly_authored",
    "açıklık vs dinlenme ihtiyacı",
    "yorgunluk ve duygusal hazır olma gerçek bir gerilim oluşturur",
)

# --- perspective_taking ---
_spec(
    "eq_tr_v1_perspective_taking_001",
    "perspective_taking",
    "Arkadaşın seni bir davetiye konusunda eleştiriyor; sen katılamayacağını "
    "söylemiştin. Onun neden kırgın olabileceğini düşünürsün — ilk iç tepkin ne olur?",
    [
        (
            "A",
            "Belki kendini değersiz hissetti; davetin onun için önemli olduğunu hatırlarsın.",
            {"perspective_taking": 0.75, "social_awareness": 0.25},
            {"rationale": "Güçlü perspektif alma."},
        ),
        (
            "B",
            "İki tarafın da haklı yanları olabileceğini, iletişim eksikliği olabileceğini düşünürsün.",
            {"perspective_taking": 0.48, "social_awareness": 0.15},
            {"rationale": "Dengeli çoklu perspektif."},
        ),
        (
            "C",
            "Öncelikle kendi gerekçeni ve sınırlarını netleştirirsin.",
            {"perspective_taking": 0.1, "boundary_setting": 0.28},
            {
                "rationale": "Öz odaklı çerçeveleme.",
                "counter": {"perspective_taking": -0.1},
            },
        ),
        (
            "D",
            "Aşırı tepki verdiğini düşünüp mesafeye çekilirsin.",
            {"perspective_taking": -0.42, "conflict_approach": -0.18},
            {"rationale": "Karşı taraf perspektifi reddedilir."},
        ),
    ],
    "newly_authored",
    "başkasının çerçevesi vs kendi gerekçen",
    "eleştiriyi tamamen haklı veya haksız saymak zorunda değilsin",
)

_spec(
    "eq_tr_v1_perspective_taking_002",
    "perspective_taking",
    "Takım toplantısında sessiz kalan bir meslektaşın vardı. Sonradan fikrinin "
    "göz ardı edildiğini fark ediyorsun. Onun yerinde olsan ne hissederdin?",
    [
        (
            "A",
            "Görünmez kalmış ve saygısızlık hissetmiş olabileceğini düşünürsün.",
            {"perspective_taking": 0.7, "social_awareness": 0.22},
            {"rationale": "Empatik perspektif simülasyonu."},
        ),
        (
            "B",
            "Belki konuşmak istemediğini ama yine de dışlanmış hissetmiş olabileceğini varsayarsın.",
            {"perspective_taking": 0.45},
            {"rationale": "Belirsizliği tolere eden perspektif."},
        ),
        (
            "C",
            "Toplantı dinamiğinin herkesi eşit davet etmediğini genel olarak değerlendirirsin.",
            {"perspective_taking": 0.2, "social_awareness": 0.18},
            {"rationale": "Sistemik ama kişisel perspektif zayıf."},
        ),
        (
            "D",
            "Sessiz kalmasının kendi tercihi olduğunu ve fazla yorum yapmazsın.",
            {"perspective_taking": -0.38},
            {"rationale": "Perspektif alma düşük."},
        ),
    ],
    "newly_authored",
    "sessizlik yorumu vs dışlanma olasılığı",
    "sessizlik hem tercih hem dışlanma olabilir",
)

_spec(
    "eq_tr_v1_perspective_taking_003",
    "perspective_taking",
    "Bir arkadaş grubunda biri espri yaptı; başka biri gülmedi ve ortam gerildi. "
    "Gülmeyen kişinin içinde ne geçiyor olabilir diye düşünürsün.",
    [
        (
            "A",
            "Espriyi incitici bulmuş veya kendini hedef alınmış hissetmiş olabilir.",
            {"perspective_taking": 0.68, "conflict_approach": 0.2},
            {"rationale": "Olası duygusal etki tahmini."},
        ),
        (
            "B",
            "O an dikkati dağılmış ya da mizah anlayışı farklı olabilir diye düşünürsün.",
            {"perspective_taking": 0.42},
            {"rationale": "Alternatif açıklamalar üretir."},
        ),
        (
            "C",
            "Grup baskısı hissetmiş olabileceğini kısaca not edersin.",
            {"perspective_taking": 0.22, "social_awareness": 0.18},
            {"rationale": "Sınırlı perspektif derinliği."},
        ),
        (
            "D",
            "Abartıyor olabileceğini düşünüp konuyu kapatırsın.",
            {"perspective_taking": -0.45, "social_awareness": -0.15},
            {"rationale": "Perspektif reddi."},
        ),
    ],
    "newly_authored",
    "grup dinamiği vs bireysel duygu",
    "gülmeme tek bir nedene indirgenmez",
)

# --- self_awareness ---
_spec(
    "eq_tr_v1_self_awareness_001",
    "self_awareness",
    "Partnerin bugün mesafeli; sen gerginsin ve bunun nedenini tam bilmiyorsun. "
    "Kendi iç durumuna bakınca ilk fark ettiğin ne olur?",
    [
        (
            "A",
            "Onun davranışını kişisel algıladığını ve kaygının arttığını fark edersin.",
            {"self_awareness": 0.72, "emotion_regulation": -0.18},
            {"rationale": "Tetikleyici farkındalığı yüksek."},
        ),
        (
            "B",
            "Yorgunluk ve stresin tepkini şişirdiğini düşünürsün.",
            {"self_awareness": 0.48, "emotion_regulation": 0.15},
            {"rationale": "Bağlamsal öz-farkındalık."},
        ),
        (
            "C",
            "Henüz net bir duygu adı koyamazsın ama rahatsız olduğunu bilirsin.",
            {"self_awareness": 0.22},
            {
                "rationale": "Kısmi duygusal farkındalık.",
                "counter": {"self_awareness": -0.05},
            },
        ),
        (
            "D",
            "Sorun partnerde olduğu için kendi halini sorgulamazsın.",
            {"self_awareness": -0.55},
            {"rationale": "Öz-farkındalık düşük."},
        ),
    ],
    "substantially_rewritten_legacy_concept",
    "iç tetik vs dış atfetme",
    "mesafe hem kişisel hem bağlamsal yorumlanabilir",
    44,
)

_spec(
    "eq_tr_v1_self_awareness_002",
    "self_awareness",
    "Bir sosyal ortamda aniden içe kapanma isteği duyuyorsun. "
    "Bu tepkinin altında ne olabileceğini nasıl değerlendirirsin?",
    [
        (
            "A",
            "Sosyal yorgunluk veya tetiklenen bir anı olabileceğini fark edersin.",
            {"self_awareness": 0.7, "social_awareness": 0.22},
            {"rationale": "Çok katmanlı öz-gözlem."},
        ),
        (
            "B",
            "Ortamın gürültülü olduğunu ve sınırlarının dolmakta olduğunu düşünürsün.",
            {"self_awareness": 0.44, "boundary_setting": 0.18},
            {"rationale": "Bağlamsal öz analiz."},
        ),
        (
            "C",
            "Basitçe modunun düşük olduğunu söylersin, derinine inmezsin.",
            {"self_awareness": 0.15},
            {"rationale": "Yüzeysel duygu etiketi."},
        ),
        (
            "D",
            "Ortamın seni rahatsız ettiğini düşünür, kendini sorgulamazsın.",
            {"self_awareness": -0.4, "social_awareness": 0.12},
            {"rationale": "Dış atfetme eğilimi."},
        ),
    ],
    "newly_authored",
    "iç geri çekilme vs ortam etkisi",
    "kapanma hem içsel hem dışsal nedenlerle açıklanabilir",
)

_spec(
    "eq_tr_v1_self_awareness_003",
    "self_awareness",
    "Yoğun bir günün ardından küçük bir yorum seni aşırı derecede kızdırdı. "
    "Tepkinin büyüklüğü hakkında kendine ne dersin?",
    [
        (
            "A",
            "Biriktirilmiş stresin bu tepkiyi büyüttüğünü fark edersin.",
            {"self_awareness": 0.68, "emotion_regulation": 0.25},
            {"rationale": "Tetikleyici birikimi fark edilir."},
        ),
        (
            "B",
            "Konunun sana dokunan bir yönü olabileceğini kabul edersin.",
            {"self_awareness": 0.45},
            {"rationale": "Orta düzey öz-yansıma."},
        ),
        (
            "C",
            "Haklı öfke olduğunu düşünür, kendi rolünü sorgulamazsın.",
            {"self_awareness": 0.05, "assertiveness": 0.2},
            {
                "rationale": "Sınırlı öz-farkındalık.",
                "counter": {"self_awareness": -0.08},
            },
        ),
        (
            "D",
            "Diğer kişinin kasıtlı provokasyon yaptığını varsayarsın.",
            {"self_awareness": -0.5, "conflict_approach": 0.18},
            {"rationale": "Öz-farkındalık yerine dış suçlama."},
        ),
    ],
    "newly_authored",
    "birikmiş stres vs haklı öfke",
    "aşırı tepki hem birikim hem değer ihlali olabilir",
)

# --- emotion_regulation ---
_spec(
    "eq_tr_v1_emotion_regulation_001",
    "emotion_regulation",
    "Gergin bir ekip toplantısında bir meslektaşın gözyaşlarına hakim olamadı. "
    "İlk içgüdün ne olur?",
    [
        (
            "A",
            "Ortamı yumuşatmak için kısa bir ara önerir, tonunu sakin tutarsın.",
            {"emotion_regulation": 0.7, "self_awareness": 0.22},
            {"rationale": "Düzenleme odaklı müdahale."},
        ),
        (
            "B",
            "Konuyu daha sonra ele almak üzere toplantıyı yönlendirirsin.",
            {"emotion_regulation": 0.45, "social_awareness": 0.18},
            {"rationale": "Yapılandırılmış sakinleştirme."},
        ),
        (
            "C",
            "Tartışmaya devam edersin; duyguların zamanla yatışacağını düşünürsün.",
            {"emotion_regulation": 0.08, "conflict_approach": 0.15},
            {
                "rationale": "Minimal düzenleme.",
                "counter": {"emotion_regulation": -0.1},
            },
        ),
        (
            "D",
            "Rahatsız edici bulup konuyu değiştirirsin, duyguyu görmezden gelirsin.",
            {"emotion_regulation": -0.48, "empathy": -0.2},
            {"rationale": "Bastırma/kaçınma eğilimi."},
        ),
    ],
    "adapted_from_legacy_scenario",
    "duygusal tempo vs gündem baskısı",
    "ara vermek, devam etmek veya yönlendirmek makul seçenekler",
    50,
)

_spec(
    "eq_tr_v1_emotion_regulation_002",
    "emotion_regulation",
    "Flörtünle mesajlaşırken ani bir gerilim hissediyorsun. "
    "Yazmadan önce duygunu nasıl yönetirsin?",
    [
        (
            "A",
            "Birkaç dakika ara verir, ne hissettiğini adlandırıp sonra yanıtlarsın.",
            {"emotion_regulation": 0.72, "self_awareness": 0.2},
            {"rationale": "Bilinçli düzenleme döngüsü."},
        ),
        (
            "B",
            "Tonunu yumuşatmak için mesajı yeniden yazarsın.",
            {"emotion_regulation": 0.46},
            {"rationale": "Çıktı odaklı düzenleme."},
        ),
        (
            "C",
            "Hızlıca yanıt verirsin ama sonra gereksiz olduğunu fark edersin.",
            {"emotion_regulation": 0.12, "impulsivity_hint": 0.0},
            {
                "rationale": "Gecikmiş farkındalık.",
                "counter": {"emotion_regulation": -0.12},
            },
        ),
        (
            "D",
            "Hissettiklerini olduğu gibi yazarsın, pişman olma ihtimalini göze alırsın.",
            {"emotion_regulation": -0.42, "emotional_openness": 0.22},
            {"rationale": "Düşük ön-düzenleme."},
        ),
    ],
    "newly_authored",
    "duraklama vs anlık ifade",
    "hem erteleme hem anlık yanıt gerçek tercihlerdir",
)

# Fix option C - remove invalid key, use proper deltas only
ITEM_CONTENT["eq_tr_v1_emotion_regulation_002"]["opts"][2] = (
    "C",
    "Hızlıca yanıt verirsin ama sonra gereksiz olduğunu fark edersin.",
    {"emotion_regulation": 0.12},
    {
        "rationale": "Gecikmiş farkındalık.",
        "counter": {"emotion_regulation": -0.12},
    },
)

_spec(
    "eq_tr_v1_emotion_regulation_003",
    "emotion_regulation",
    "İş yerinde eleştiri aldın; öğle arasında hâlâ içinde kalıyor. "
    "Öğleden sonraki toplantıya girmeden önce ne yaparsın?",
    [
        (
            "A",
            "Kısa bir yürüyüş veya nefes egzersiziyle duygunu sakinleştirirsin.",
            {"emotion_regulation": 0.68, "self_awareness": 0.18},
            {"rationale": "Aktif düzenleme stratejisi."},
        ),
        (
            "B",
            "Eleştiriden çıkarılacak bir nokta bulup zihnini oraya odaklarsın.",
            {"emotion_regulation": 0.42, "perspective_taking": 0.15},
            {"rationale": "Bilişsel yeniden çerçeveleme."},
        ),
        (
            "C",
            "Duyguyu bastırıp profesyonel görünmeye çalışırsın.",
            {"emotion_regulation": 0.15, "emotional_openness": -0.2},
            {
                "rationale": "Yüzeysel bastırma.",
                "counter": {"emotion_regulation": -0.15},
            },
        ),
        (
            "D",
            "Eleştiriyi düşünerek toplantıya girersin, odaklanmakta zorlanırsın.",
            {"emotion_regulation": -0.5},
            {"rationale": "Düzenleme başarısız."},
        ),
    ],
    "newly_authored",
    "sakinleştirme vs bastırma",
    "profesyonellik ile duygu işleme farklı yollar gerektirir",
)

# --- emotional_openness ---
_spec(
    "eq_tr_v1_emotional_openness_001",
    "emotional_openness",
    "Yeni tanıştığın biri sana kişisel bir şey anlatmaya başladı. "
    "Sen de benzer bir deneyimini paylaşmayı düşünüyorsun. Ne yaparsın?",
    [
        (
            "A",
            "Deneyimini açıkça anlatır, duygularını da paylaşırsın.",
            {"emotional_openness": 0.78, "self_awareness": 0.18},
            {
                "sdr": "moderate",
                "extremity": 0.6,
                "rationale": "Yüksek duygusal açıklık.",
            },
        ),
        (
            "B",
            "Deneyimini özetler ama tüm ayrıntıları vermezsin.",
            {"emotional_openness": 0.42, "boundary_setting": 0.15},
            {"rationale": "Seçici açıklık."},
        ),
        (
            "C",
            "Dinler, kendi hikâyeni paylaşmadan destekleyici kalırsın.",
            {"emotional_openness": 0.08, "empathy": 0.22},
            {
                "rationale": "Düşük öz-açıklık; dinleme odaklı.",
                "counter": {"emotional_openness": -0.05},
            },
        ),
        (
            "D",
            "Konuyu daha genel tutup kişisel detay vermezsin.",
            {"emotional_openness": -0.48},
            {"rationale": "Kapalı duygusal paylaşım."},
        ),
    ],
    "newly_authored",
    "açıklık vs mahremiyet",
    "erken aşamada tam açıklık her zaman gerekli değildir",
)

_spec(
    "eq_tr_v1_emotional_openness_002",
    "emotional_openness",
    "Partnerin duygularını paylaşmanı istiyor; sen genelde içini pek açmazsın. "
    "Bu akşam nasıl davranırsın?",
    [
        (
            "A",
            "Bugün neler hissettiğini dürüstçe anlatmaya çalışırsın.",
            {"emotional_openness": 0.7, "empathy": 0.18},
            {"rationale": "İstenen açıklığa yanıt."},
        ),
        (
            "B",
            "Bir-iki duygu adı söyler, derinleşmeden devam edersin.",
            {"emotional_openness": 0.38},
            {"rationale": "Kısmi açıklık."},
        ),
        (
            "C",
            "İyi olduğunu söyler, detaya girmezsin.",
            {"emotional_openness": 0.05},
            {
                "rationale": "Yüzeysel yanıt.",
                "counter": {"emotional_openness": -0.08},
            },
        ),
        (
            "D",
            "Konuyu başka bir gündeme kaydırırsın.",
            {"emotional_openness": -0.52, "conflict_approach": -0.15},
            {"rationale": "Açıklıktan kaçınma."},
        ),
    ],
    "newly_authored",
    "istenen yakınlık vs alışkanlık",
    "kademeli açıklık da geçerli bir yanıttır",
)

_spec(
    "eq_tr_v1_emotional_openness_003",
    "emotional_openness",
    "Arkadaş grubunda biri zor bir dönemini anlatıyor. "
    "Sen de benzer bir şey yaşamıştın ama herkesin önünde anlatmak istemiyorsun.",
    [
        (
            "A",
            "Yine de kısaca kendi deneyimini paylaşır, grubu desteklersin.",
            {"emotional_openness": 0.65, "empathy": 0.22},
            {"rationale": "Grup bağlamında açıklık."},
        ),
        (
            "B",
            "Sonra özel konuşmak üzere teklif edersin, şimdilik dinlersin.",
            {"emotional_openness": 0.35, "boundary_setting": 0.22},
            {"rationale": "Erteleme ile sınırlı açıklık."},
        ),
        (
            "C",
            "Destekleyici kalır ama kendi hikâyeni paylaşmazsın.",
            {"emotional_openness": 0.1, "empathy": 0.18},
            {"rationale": "Empati var; öz-açıklık düşük."},
        ),
        (
            "D",
            "Konuyu hafife alıp ortamı neşelendirmeye çalışırsın.",
            {"emotional_openness": -0.42, "social_awareness": -0.18},
            {"rationale": "Duygusal derinlikten kaçınma."},
        ),
    ],
    "newly_authored",
    "grup açıklığı vs özel paylaşım",
    "herkesin önünde açılmak zorunlu değildir",
)

# --- boundary_setting ---
_spec(
    "eq_tr_v1_boundary_setting_001",
    "boundary_setting",
    "Aile toplantısında seni rahatsız eden bir konu yine gündeme geliyor. "
    "Her seferinde konu değiştirilmişti. Bu sefer ne yaparsın?",
    [
        (
            "A",
            "Sakin ama net bir şekilde bu konuyu konuşmak istemediğini söylersin.",
            {"boundary_setting": 0.75, "assertiveness": 0.22},
            {"rationale": "Doğrudan sınır ifadesi."},
        ),
        (
            "B",
            "Neden rahatsız olduğunu kısaca açıklayıp alternatif konu önerirsin.",
            {"boundary_setting": 0.48, "assertiveness": 0.18},
            {"rationale": "Açıklamalı sınır."},
        ),
        (
            "C",
            "Yine konuyu değiştirmeye çalışırsın, doğrudan söylemezsin.",
            {"boundary_setting": 0.12, "conflict_approach": -0.15},
            {
                "rationale": "Dolaylı kaçınma.",
                "counter": {"boundary_setting": -0.1},
            },
        ),
        (
            "D",
            "Huzur bozulmasın diye susar, katlanırsın.",
            {"boundary_setting": -0.55, "assertiveness": -0.2},
            {"rationale": "Sınır ihlali / uyum."},
        ),
    ],
    "adapted_from_legacy_scenario",
    "net sınır vs huzur koruma",
    "doğrudan söylemek veya dolaylı yönlendirmek savunulabilir",
    46,
)

_spec(
    "eq_tr_v1_boundary_setting_002",
    "boundary_setting",
    "İş arkadaşın sürekli mesai saati dışında yazıyor. "
    "Bu ritim seni yoruyor. Nasıl yaklaşırsın?",
    [
        (
            "A",
            "Mesai dışı yanıt vermeyeceğini ve acil durum tanımını netleştirirsin.",
            {"boundary_setting": 0.7, "assertiveness": 0.25},
            {"rationale": "Yapılandırılmış iş sınırı."},
        ),
        (
            "B",
            "Yorgun olduğunu söyleyip ertesi gün dönüş yapacağını belirtirsin.",
            {"boundary_setting": 0.44},
            {"rationale": "Yumuşak sınır."},
        ),
        (
            "C",
            "Çoğu mesaja yine cevap verirsin ama geciktirirsin.",
            {"boundary_setting": 0.1, "repair_orientation": 0.15},
            {
                "rationale": "Tutarsız sınır.",
                "counter": {"boundary_setting": -0.12},
            },
        ),
        (
            "D",
            "İlişkiyi bozmamak için her mesaja anında dönersin.",
            {"boundary_setting": -0.48, "assertiveness": -0.22},
            {"rationale": "Sınır yok sayılır."},
        ),
    ],
    "newly_authored",
    "iş-yaşam sınırı vs erişilebilirlik",
    "hem net kural hem esnek yanıt makul",
)

_spec(
    "eq_tr_v1_boundary_setting_003",
    "boundary_setting",
    "Flörtün plansız sık sık gelmek istiyor; sen düzenli programını korumak istiyorsun. "
    "Tekrarlayan durumda ne yaparsın?",
    [
        (
            "A",
            "Ortak bir görüşme ritmi önerir, hangi günler uygun olduğunu netleştirirsin.",
            {"boundary_setting": 0.68, "assertiveness": 0.2},
            {"rationale": "Tekrarlayan sınır yapılandırması."},
        ),
        (
            "B",
            "Esnek olduğun günleri söyler, diğerlerinde meşgul olduğunu hatırlatırsın.",
            {"boundary_setting": 0.42},
            {"rationale": "Kısmi yapılandırma."},
        ),
        (
            "C",
            "Hayır demekte zorlanır, programını sık sık değiştirirsin.",
            {"boundary_setting": 0.08, "repair_orientation": 0.18},
            {
                "rationale": "Zayıf sınır tutarlılığı.",
                "counter": {"boundary_setting": -0.1},
            },
        ),
        (
            "D",
            "Rahatsız ettiğini söylemeden uzak durmaya çalışırsın.",
            {"boundary_setting": -0.5, "conflict_approach": -0.18},
            {"rationale": "Pasif kaçınma."},
        ),
    ],
    "newly_authored",
    "program vs spontane yakınlık",
    "düzen isteği ile esneklik gerçek bir gerilimdir",
)

# --- assertiveness ---
_spec(
    "eq_tr_v1_assertiveness_001",
    "assertiveness",
    "Arkadaşın senin adına bir plan yaptı; katılmak istemiyorsun ama "
    "hayır demek onu kırabilir. Ne söylersin?",
    [
        (
            "A",
            "Teşekkür eder, katılamayacağını ve nedenini açıkça belirtirsin.",
            {"assertiveness": 0.72, "emotion_regulation": 0.2},
            {"rationale": "Net ve saygılı reddetme."},
        ),
        (
            "B",
            "Alternatif bir zaman veya etkinlik önerirsin.",
            {"assertiveness": 0.45, "repair_orientation": 0.18},
            {"rationale": "Yapıcı assertiveness."},
        ),
        (
            "C",
            "Belirsiz kalır, belki diye cevap verip sonra çekilirsin.",
            {"assertiveness": 0.08, "conflict_approach": -0.15},
            {
                "rationale": "Belirsizlik; düşük assertiveness.",
                "counter": {"assertiveness": -0.1},
            },
        ),
        (
            "D",
            "Kırmamak için katılacağını söylersin.",
            {"assertiveness": -0.52, "boundary_setting": -0.22},
            {"rationale": "Uyum odaklı; ihtiyaç bastırılır."},
        ),
    ],
    "newly_authored",
    "açık ret vs uyum",
    "hayır demek kırıcı olmak zorunda değildir",
)

_spec(
    "eq_tr_v1_assertiveness_002",
    "assertiveness",
    "Toplantıda fikrin kesildi; tekrar söz almak istiyorsun. "
    "Ortam rekabetçi. Nasıl davranırsın?",
    [
        (
            "A",
            "Kibarca söz isteyip görüşünü tamamlarsın.",
            {"assertiveness": 0.7, "boundary_setting": 0.22},
            {
                "sdr": "moderate",
                "rationale": "Doğrudan ama profesyonel assertiveness.",
            },
        ),
        (
            "B",
            "Chat üzerinden «devam etmek isterim» yazıp söz alırsın.",
            {"assertiveness": 0.42, "social_awareness": 0.15},
            {"rationale": "Dolaylı assertiveness kanalı."},
        ),
        (
            "C",
            "Konu geçene kadar beklersin, sonra kısaca eklersin.",
            {"assertiveness": 0.15},
            {
                "rationale": "Geç ve zayıf ifade.",
                "counter": {"assertiveness": -0.08},
            },
        ),
        (
            "D",
            "Söylenmeyen kısmı önemsemeden susarsın.",
            {"assertiveness": -0.48},
            {"rationale": "Geri çekilme."},
        ),
    ],
    "newly_authored",
    "ses alma vs grup akışı",
    "farklı iletişim kanalları eşit derecede geçerli",
)

_spec(
    "eq_tr_v1_assertiveness_003",
    "assertiveness",
    "Partnerin sürekli son dakika plan değiştiriyor; sen buna tepki göstermek "
    "istiyorsun. Uzun vadede ne yaparsın?",
    [
        (
            "A",
            "Değişikliklerin seni zorladığını ve önceden haber vermesini istersin.",
            {"assertiveness": 0.68, "boundary_setting": 0.22},
            {"rationale": "Tekrarlayan davranışa net geri bildirim."},
        ),
        (
            "B",
            "Esnek olduğun ve olmadığın durumları örnekle açıklarsın.",
            {"assertiveness": 0.44},
            {"rationale": "Yapılandırılmış geri bildirim."},
        ),
        (
            "C",
            "Bir kez söylersin ama sonra yine uyum sağlarsın.",
            {"assertiveness": 0.12, "repair_orientation": 0.15},
            {
                "rationale": "Tutarsız assertiveness.",
                "counter": {"assertiveness": -0.1},
            },
        ),
        (
            "D",
            "Alışkanlık haline getirir, şikâyet etmezsin.",
            {"assertiveness": -0.5, "emotion_regulation": -0.15},
            {"rationale": "Bastırılmış ihtiyaç."},
        ),
    ],
    "newly_authored",
    "plan güvenilirliği vs esneklik",
    "tekrarlayan davranış net konuşmayı gerektirebilir",
)

# --- conflict_approach ---
_spec(
    "eq_tr_v1_conflict_approach_001",
    "conflict_approach",
    "Ev arkadaşın ortak alanı farklı kullanıyor; bu seni rahatsız ediyor. "
    "Henüz konuşmadınız. İlk hamlen ne olur?",
    [
        (
            "A",
            "Ortak kuralları konuşmak için uygun bir zaman ayırırsın.",
            {"conflict_approach": 0.72, "perspective_taking": 0.22},
            {"rationale": "Yapılandırılmış çatışma girişi."},
        ),
        (
            "B",
            "Kısa bir mesajla rahatsızlığını belirtip yüz yüze konuşmayı önerirsin.",
            {"conflict_approach": 0.46, "assertiveness": 0.18},
            {"rationale": "Orta düzey doğrudanlık."},
        ),
        (
            "C",
            "Umarım düzelir diye bekler, ipuçları verirsin.",
            {"conflict_approach": 0.1, "boundary_setting": -0.12},
            {
                "rationale": "Pasif beklenti.",
                "counter": {"conflict_approach": -0.08},
            },
        ),
        (
            "D",
            "Rahatsızlığını biriktirip patlama riski taşırsın.",
            {"conflict_approach": -0.55, "emotion_regulation": -0.2},
            {"rationale": "Ertelemeli/agresif uç."},
        ),
    ],
    "newly_authored",
    "erken konuşma vs bekleme",
    "hem doğrudan hem dolaylı giriş makul",
)

_spec(
    "eq_tr_v1_conflict_approach_002",
    "conflict_approach",
    "İki arkadaşın senin yanında tartışmaya başladı. "
    "Arabuluculuk yapmak mı, tarafsız kalmak mı — eğilimin ne?",
    [
        (
            "A",
            "Her ikisinin de duyulmasını sağlayıp sakinleştirmeye çalışırsın.",
            {"conflict_approach": 0.68, "emotion_regulation": 0.25},
            {"rationale": "Aktif arabuluculuk."},
        ),
        (
            "B",
            "Kendi görüşünü söylemeden konuyu ertelemeyi teklif edersin.",
            {"conflict_approach": 0.42, "repair_orientation": 0.18},
            {"rationale": "Erteleme tabanlı yaklaşım."},
        ),
        (
            "C",
            "Taraf tutmadan dinler, müdahale etmezsin.",
            {"conflict_approach": 0.12, "perspective_taking": 0.15},
            {
                "rationale": "Pasif gözlem.",
                "counter": {"conflict_approach": -0.1},
            },
        ),
        (
            "D",
            "Ortamdan uzaklaşırsın, sorun kendi haline kalsın.",
            {"conflict_approach": -0.45, "empathy": -0.15},
            {"rationale": "Kaçınma."},
        ),
    ],
    "newly_authored",
    "arabuluculuk vs tarafsızlık",
    "müdahale etmemek de bir tercihtir",
)

_spec(
    "eq_tr_v1_conflict_approach_003",
    "conflict_approach",
    "İş yerinde ekip içi bir anlaşmazlık büyüyor; sen farklı bir çözüm görüyorsun. "
    "Toplantıda nasıl katılırsın?",
    [
        (
            "A",
            "Alternatif çözümünü gerekçeleriyle sunar, diyaloğu açarsın.",
            {"conflict_approach": 0.7, "boundary_setting": 0.2},
            {"rationale": "Yapıcı muhalefet."},
        ),
        (
            "B",
            "Endişeni kısaca belirtir, başkalarının fikrini sorarsın.",
            {"conflict_approach": 0.44, "perspective_taking": 0.18},
            {"rationale": "Düşük yoğunluklu katılım."},
        ),
        (
            "C",
            "Uyuşmazlık büyümesin diye susarsın.",
            {"conflict_approach": 0.05},
            {
                "rationale": "Uyum odaklı geri çekilme.",
                "counter": {"conflict_approach": -0.08},
            },
        ),
        (
            "D",
            "Meslektaşların yanında sert bir şekilde karşı çıkarsın.",
            {"conflict_approach": -0.52, "emotion_regulation": -0.22},
            {"rationale": "Yıkıcı çatışma tarzı."},
        ),
    ],
    "newly_authored",
    "muhalefet vs grup uyumu",
    "sert karşı çıkma ile susmak farklı maliyetler taşır",
)

# --- repair_orientation ---
_spec(
    "eq_tr_v1_repair_orientation_001",
    "repair_orientation",
    "Arkadaşına kaba bir mesaj attığını fark ettin; o henüz cevap vermedi. "
    "Ne yaparsın?",
    [
        (
            "A",
            "Özür diler, niyetini açıklar ve konuşmak istediğini söylersin.",
            {"repair_orientation": 0.75, "empathy": 0.22},
            {
                "sdr": "moderate",
                "rationale": "Doğrudan onarım girişimi.",
            },
        ),
        (
            "B",
            "Mesajını düzelten kısa bir takip gönderirsin.",
            {"repair_orientation": 0.45, "empathy": 0.15},
            {"rationale": "Yazılı onarım."},
        ),
        (
            "C",
            "Zaman geçsin, kendiliğinden düzelir diye beklersin.",
            {"repair_orientation": 0.08, "conflict_approach": -0.12},
            {
                "rationale": "Pasif beklenti.",
                "counter": {"repair_orientation": -0.1},
            },
        ),
        (
            "D",
            "Haklı olduğunu düşünüp mesajına dokunmazsın.",
            {"repair_orientation": -0.52, "assertiveness": 0.2},
            {"rationale": "Onarım reddi."},
        ),
    ],
    "newly_authored",
    "özür vs zaman",
    "hem aktif onarım hem bekleme savunulabilir",
)

_spec(
    "eq_tr_v1_repair_orientation_002",
    "repair_orientation",
    "Partnerinle tartıştınız; gece boyunca konuşmadınız. "
    "Sabah ne yaparsın?",
    [
        (
            "A",
            "İletişimi yeniden açmak için sakin bir mesaj veya kahve teklifi yaparsın.",
            {"repair_orientation": 0.7, "emotional_openness": 0.22},
            {"rationale": "Proaktif bağ onarımı."},
        ),
        (
            "B",
            "Önce özür veya ortak zemin cümlesiyle diyaloğu başlatırsın.",
            {"repair_orientation": 0.48, "empathy": 0.18},
            {"rationale": "Sözel onarım."},
        ),
        (
            "C",
            "O adım atana kadar normal davranırsın, konuyu açmazsın.",
            {"repair_orientation": 0.12},
            {
                "rationale": "Bekle-gör onarımı.",
                "counter": {"repair_orientation": -0.08},
            },
        ),
        (
            "D",
            "Hâlâ haklı olduğunu düşünerek mesafe korursun.",
            {"repair_orientation": -0.48, "conflict_approach": 0.15},
            {"rationale": "Onarım ertelenir veya reddedilir."},
        ),
    ],
    "newly_authored",
    "ilk adım vs bekleme",
    "sabah yakınlaşması zorunlu değildir",
)

_spec(
    "eq_tr_v1_repair_orientation_003",
    "repair_orientation",
    "İş yerinde yanlış anlaşılma yüzünden meslektaşın sana kırgın. "
    "Bu tür durumlar daha önce de oldu. Genelde ne yaparsın?",
    [
        (
            "A",
            "Yanlış anlaşılmayı netleştirip özür veya açıklama yaparsın.",
            {"repair_orientation": 0.68, "conflict_approach": 0.22},
            {"rationale": "Tekrarlayan onarım kalıbı."},
        ),
        (
            "B",
            "Kısa bir kontrol mesajı atıp yüz yüze konuşmayı planlarsın.",
            {"repair_orientation": 0.42},
            {"rationale": "Rutin düşük yoğunluklu onarım."},
        ),
        (
            "C",
            "Zamanla geçer diye müdahale etmezsin.",
            {"repair_orientation": 0.1},
            {
                "rationale": "Pasif onarım beklentisi.",
                "counter": {"repair_orientation": -0.1},
            },
        ),
        (
            "D",
            "Sorumluluğu tamamen karşı tarafa bırakırsın.",
            {"repair_orientation": -0.5, "conflict_approach": -0.18},
            {"rationale": "Onarım sorumluluğu reddedilir."},
        ),
    ],
    "newly_authored",
    "tekrarlayan onarım alışkanlığı",
    "her yanlış anlaşılma hemen konuşmayı gerektirmez",
)

# --- social_awareness ---
_spec(
    "eq_tr_v1_social_awareness_001",
    "social_awareness",
    "Bir davette yalnız oturan birini fark ettin; grup halinde sohbet ediliyor. "
    "Ortamın dinamiğini nasıl okursun?",
    [
        (
            "A",
            "Kişinin dahil edilmediğini ve muhtemelen dışlanmış hissettiğini düşünürsün.",
            {"social_awareness": 0.72, "empathy": 0.22},
            {
                "sdr": "moderate",
                "rationale": "Yüksek sosyal sinyal okuma.",
            },
        ),
        (
            "B",
            "Belki yorgun veya tanıdık aradığını, henüz emin olmadığını varsayarsın.",
            {"social_awareness": 0.45},
            {"rationale": "Çoklu olasılık okuma."},
        ),
        (
            "C",
            "Kendi sohbetine odaklanır, fazla yorum yapmazsın.",
            {"social_awareness": 0.12},
            {
                "rationale": "Sınırlı ortam taraması.",
                "counter": {"social_awareness": -0.08},
            },
        ),
        (
            "D",
            "Tercih meselesi olduğunu düşünüp dikkat etmezsin.",
            {"social_awareness": -0.48},
            {"rationale": "Sosyal ipuçları göz ardı."},
        ),
    ],
    "newly_authored",
    "dışlanma sinyali vs kişisel tercih",
    "yalnız oturmak tek anlama gelmez",
)

_spec(
    "eq_tr_v1_social_awareness_002",
    "social_awareness",
    "Arkadaş grubunda biri espri yaptıktan sonra ortamın gerildiğini hissediyorsun. "
    "Ne fark edersin?",
    [
        (
            "A",
            "Espriyi yanlış yorumlayan veya incinen biri olabileceğini düşünürsün.",
            {"social_awareness": 0.7, "perspective_taking": 0.22},
            {"rationale": "Gerilim kaynağı hipotezi."},
        ),
        (
            "B",
            "Genel olarak mizahın o an uygun olmadığını sezersin.",
            {"social_awareness": 0.44},
            {"rationale": "Bağlamsal uygunluk farkındalığı."},
        ),
        (
            "C",
            "Sadece kısa bir sessizlik olduğunu sanır, fazla anlam yüklemezsin.",
            {"social_awareness": 0.15},
            {"rationale": "Düşük sosyal okuma."},
        ),
        (
            "D",
            "Gerilimi fark etmez, sohbete devam edersin.",
            {"social_awareness": -0.42},
            {"rationale": "Sosyal sinyal kaçırma."},
        ),
    ],
    "newly_authored",
    "grup tonu vs bireysel tepki",
    "gerilim her zaman kişisel değildir",
)

_spec(
    "eq_tr_v1_social_awareness_003",
    "social_awareness",
    "Yeni bir iş ekibine katıldın; toplantıda kimlerin söz aldığını ve "
    "kimlerin geri planda kaldığını fark ediyorsun. İlk izlenimin ne?",
    [
        (
            "A",
            "Resmi hiyerarşi ve informal grupların katılımı etkilediğini düşünürsün.",
            {"social_awareness": 0.68, "repair_orientation": 0.2},
            {"rationale": "Yapısal sosyal okuma."},
        ),
        (
            "B",
            "Bazı konuların belirli kişileri daha çok devreye soktuğunu not edersin.",
            {"social_awareness": 0.42, "perspective_taking": 0.15},
            {"rationale": "Konu-bazlı dinamik farkındalık."},
        ),
        (
            "C",
            "Henüz yorum yapmak için erken olduğunu düşünürsün.",
            {"social_awareness": 0.12},
            {
                "rationale": "Gözlem erteleme.",
                "counter": {"social_awareness": -0.05},
            },
        ),
        (
            "D",
            "Herkesin eşit fırsat aldığını varsayarsın.",
            {"social_awareness": -0.45},
            {"rationale": "Sosyal dinamikleri okumama."},
        ),
    ],
    "newly_authored",
    "güç dinamiği vs eşit katılım varsayımı",
    "erken izlenimler kesin hüküm değildir",
)

REVERSE_NEGATE_TARGETS = {
    "eq_tr_v1_emotional_openness_002": "eq_tr_v1_emotional_openness_001",
    "eq_tr_v1_boundary_setting_003": "eq_tr_v1_boundary_setting_001",
    "eq_tr_v1_assertiveness_003": "eq_tr_v1_assertiveness_001",
    "eq_tr_v1_conflict_approach_003": "eq_tr_v1_conflict_approach_001",
    "eq_tr_v1_self_awareness_003": "eq_tr_v1_self_awareness_001",
}

SEMANTIC_MIRROR = {
    "eq_tr_v1_empathy_002": "eq_tr_v1_empathy_001",
    "eq_tr_v1_perspective_taking_002": "eq_tr_v1_perspective_taking_001",
    "eq_tr_v1_boundary_setting_002": "eq_tr_v1_boundary_setting_001",
    "eq_tr_v1_assertiveness_002": "eq_tr_v1_assertiveness_001",
    "eq_tr_v1_repair_orientation_002": "eq_tr_v1_repair_orientation_001",
    "eq_tr_v1_emotion_regulation_002": "eq_tr_v1_emotion_regulation_001",
}


def sync_primary_deltas(target_qid: str, source_qid: str, *, negate: bool = False) -> None:
    """Align primary-dimension polarity per option letter; keep target text/secondaries."""
    src_opts = ITEM_CONTENT[source_qid]["opts"]
    tgt_opts = ITEM_CONTENT[target_qid]["opts"]
    src_primary = ITEM_CONTENT[source_qid]["primary"]
    tgt_primary = ITEM_CONTENT[target_qid]["primary"]
    synced = []
    for (oid, text, deltas, meta), (src_oid, _, src_deltas, _) in zip(tgt_opts, src_opts):
        assert oid == src_oid
        src_val = src_deltas[src_primary]
        new_deltas = {k: v for k, v in deltas.items() if k != tgt_primary}
        new_deltas[tgt_primary] = round(-src_val if negate else src_val, 2)
        synced.append((oid, text, new_deltas, meta))
    ITEM_CONTENT[target_qid]["opts"] = synced


for tgt, src in SEMANTIC_MIRROR.items():
    sync_primary_deltas(tgt, src, negate=False)

for tgt, src in REVERSE_NEGATE_TARGETS.items():
    sync_primary_deltas(tgt, src, negate=True)


def build_all_items() -> list[dict]:
    expected = {f"eq_tr_v1_{d}_{n:03d}" for d in DIMENSIONS for n in (1, 2, 3)}
    assert set(ITEM_CONTENT) == expected, (set(ITEM_CONTENT) ^ expected)
    items = []
    for qid in sorted(ITEM_CONTENT):
        spec = ITEM_CONTENT[qid]
        items.append(
            build_item(
                qid,
                spec["primary"],
                spec["prompt"],
                spec["opts"],
                provenance=spec["provenance"],
                tradeoff=spec["tradeoff"],
                avoids=spec["avoids"],
                seconds=spec.get("seconds", 42),
            )
        )
    return items


def validate_items(items: list[dict]) -> None:
    assert len(items) == 30
    dim_counts = Counter(i["primary_dimension"] for i in items)
    assert dim_counts == dict.fromkeys(DIMENSIONS, 3), dim_counts

    fam_counts = Counter(family_for(i["question_id"]) for i in items)
    assert all(v == 3 for v in fam_counts.values()), fam_counts

    sec_counts = Counter()
    for i in items:
        for s in i["secondary_dimensions"]:
            sec_counts[s] += 1
    for d in DIMENSIONS:
        assert sec_counts[d] >= 2, (d, sec_counts[d])

    forbidden = {"correct_option_id", "correctAnswer", "correct", "persona_id"}
    for i in items:
        assert forbidden.isdisjoint(i.keys())
        assert i["item_type"] == "scenario_mcq"
        assert len(i["options"]) == 4
        primary = i["primary_dimension"]
        for opt in i["options"]:
            assert forbidden.isdisjoint(opt.keys())
            assert primary in opt["dimension_deltas"]
            assert len(opt["dimension_deltas"]) <= 3
            assert l1(opt["dimension_deltas"]) <= 1.40
            assert "counter_evidence" in opt
            assert "rationale" in opt

    sdr_moderate_items = {
        i["question_id"]
        for i in items
        if any(o["social_desirability_risk"] == "moderate" for o in i["options"])
    }
    assert len(sdr_moderate_items) >= 4, sdr_moderate_items

    anchors = [i for i in items if i["exposure_class"] == "anchor"]
    assert len(anchors) == 3
    assert len({a["primary_dimension"] for a in anchors}) == 3


def build_form(items: list[dict]) -> dict:
    item_scenario_families = {
        i["question_id"]: family_for(i["question_id"]) for i in items
    }
    return {
        "form_id": FORM_ID,
        "set_id": SET_ID,
        "module": "eq",
        "locale": "tr-TR",
        "schema_version": 3,
        "question_schema_version": "qmatch_question_schema_v3",
        "content_version": CV,
        "status": "pilot",
        "review_state": "internal_review",
        "calibration_status": "uncalibrated",
        "question_count": 30,
        "trait_scoring_version": "trait_scoring_v1.0",
        "dimension_registry_version": "canonical_dimension_registry_v1",
        "scenario_family_allocation": {k: 3 for k in FAMILY_ITEMS},
        "primary_dimension_allocation": {d: 3 for d in DIMENSIONS},
        "item_scenario_families": item_scenario_families,
        "pair_registry": {
            "semantic_pairs": [
                {"pair_id": pid, "question_ids": qids} for pid, qids in SEMANTIC_PAIRS.items()
            ],
            "reverse_pairs": [
                {"pair_id": pid, "question_ids": qids} for pid, qids in REVERSE_PAIRS.items()
            ],
            "behavioral_isomorph_groups": [
                {"group_id": gid, "question_ids": qids}
                for gid, qids in ISOMORPH_GROUPS.items()
            ],
        },
        "notes": {
            "en_prompt_fields": "schema-required stubs only; not authored translations",
            "provisional": True,
            "not_production": True,
            "internal_language_review": "completed",
            "expert_psychological_review": "pending",
            "participant_cognitive_interviews": "pending",
            "calibration": "pending",
            "not_a_clinical_instrument": True,
        },
        "items": items,
    }


def main() -> None:
    if OUT.exists() and "--force" not in sys.argv:
        raise SystemExit(f"Refusing to overwrite {OUT}; pass --force.")
    items = build_all_items()
    validate_items(items)
    form = build_form(items)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(form, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("wrote", OUT)
    print("dimensions", dict(Counter(i["primary_dimension"] for i in items)))
    print("families", dict(Counter(family_for(i["question_id"]) for i in items)))
    print("anchors", [i["question_id"] for i in items if i["exposure_class"] == "anchor"])


if __name__ == "__main__":
    main()
