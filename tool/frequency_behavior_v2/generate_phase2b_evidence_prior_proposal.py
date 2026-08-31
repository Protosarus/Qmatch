#!/usr/bin/env python3
"""Phase 2B: proposal-only uncalibrated evidence priors for selectable V2 options.

Does not modify the dormant pool, DROP options, V1, or live routing.
Scores are reviewer priors relative to the other three options in the same
question. They are not derived from behavioral-weight sign or magnitude.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter, defaultdict
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PROPOSAL_PATH = OUT_DIR / "frequency_behavior_v2_phase2b_evidence_prior_proposal.json"
AUDIT_PATH = OUT_DIR / "frequency_behavior_v2_phase2b_evidence_audit.md"

GRID = (0.00, 0.25, 0.50, 0.75, 1.00)
FIELDS = (
    "social_desirability",
    "obviousness",
    "behavioral_plausibility",
    "self_presentation_risk",
    "diagnostic_value",
    "ambiguity",
)

AXIS_CUES = {
    "contact_need": (
        "yanıma",
        "yanında",
        "temas",
        "yazış",
        "mesaj",
        "arar",
        "sık sık",
        "yalnız kal",
        "az temas",
        "birlikteyken",
    ),
    "closeness_pace": (
        "sarıl",
        "öp",
        "dokun",
        "fiziksel",
        "yavaş",
        "tempo",
        "mesafe",
        "yakınlığ",
        "el tut",
        "dokunsal",
    ),
    "initiative": (
        "öneririm",
        "ben açar",
        "başlat",
        "hadi",
        "ilk adım",
        "beklerim",
        "o başlat",
        "getirene kadar",
        "gündeme",
        "ne yapalım",
    ),
    "autonomy": (
        "kendi plan",
        "kendi iş",
        "kendi hal",
        "alan",
        "yalnız",
        "odama",
        "planımı",
        "bağımsız",
        "kendi başıma",
    ),
    "reassurance_need": (
        "rahatsız",
        "önemli mi",
        "yoklama",
        "ilgisiz",
        "neden soğuk",
        "emin",
        "sorun oldu",
        "hatırlat",
        "beğenmedin",
    ),
    "uncertainty_tolerance": (
        "belirsiz",
        "netleştir",
        "analiz",
        "varsay",
        "açık bırak",
        "bekler",
        "neredeydin",
        "meşgul olduğunu",
        "üstünde durmam",
    ),
    "disclosure_pace": (
        "anlatırım",
        "ayrıntı",
        "saklarım",
        "kendime",
        "paylaş",
        "sır",
        "hissettiğimi",
        "açarım",
        "konuşmak için zaman",
    ),
    "boundary_firmness": (
        "net",
        "durdur",
        "keserim",
        "sınır",
        "olmaz",
        "istemiyorum",
        "izin ver",
        "başlamayalım",
        "telefonu kaldır",
        "katılmam",
    ),
    "repair_style": (
        "özür",
        "yanına gider",
        "konuyu aç",
        "sessiz kal",
        "unutulmasını",
        "yumuşat",
        "masaya sür",
        "haklı",
    ),
    "social_energy": (
        "tanışır",
        "kalabalık",
        "parti",
        "erken kalk",
        "kendi sohbet",
        "yorduğu",
        "davet",
        "katılırım",
    ),
    "structure_preference": (
        "plan",
        "taslak",
        "yazılı",
        "adım",
        "rutin",
        "anlık",
        "kafamıza göre",
        "hesap",
        "bölün",
        "önceden",
    ),
    "adaptability": (
        "uyarım",
        "yaklaşırım",
        "eşlik",
        "planı değiştir",
        "gevşet",
        "kendi yöntem",
        "alışmaya",
        "bozar, giderim",
        "orta bir tempo",
    ),
}

CARICATURE = (
    "toksik",
    "çileden",
    "felaket",
    "evrene",
    "sahiplenici",
    "saygısızlık",
    "ulu orta",
    "gurur yapmadan",
    "tamamen senin haksız",
    "intikam",
    "cezalandır",
)
MORAL = (
    "saygısızlık",
    "adilidir",
    "haksız",
    "doğru gelir",
    "olgun",
    "sağlıklı",
    "sorumlu",
    "alçakgönül",
)
IDEAL_SELF = (
    "açıkça",
    "net biçimde",
    "net bir şekilde",
    "net söyler",
    "özür dilerim",
    "dinlerim",
    "nazikçe",
    "anlayış",
    "eşlik etmekten keyif",
    "objektif",
    "faydalı bulurum",
)
TEST_CODED = (
    "açıkça",
    "net biçimde",
    "net bir şekilde",
    "sadece dinlemeni",
    "şöyle yapmalısın",
    "sınırımı çizerim",
    "sağlıklı",
    "olgun",
)
COLD_ABRUPT = (
    "umursamam",
    "hiç açmam",
    "konuyu tamamen kapatırım",
    "üstünde durmam",
    "kendi dijital",
    "soğuklukta cevap",
    "tavır",
)
COSTLY = (
    "katılmam",
    "erken kalk",
    "uykumu ertele",
    "planımı tamamen",
    "planımı bozar",
    "işi kendim",
    "yalnız kalırım",
    "bu kez katılmam",
    "kendi odama",
)
PEOPLE_PLEASE = (
    "bana uyar",
    "alışmaya",
    "eşlik",
    "planımı bozar",
    "onun enerjisi",
    "hatırı",
    "uyum sağlarım",
    "rahatça karşılık",
)
MIDDLE_PATH = (
    "bir kısmını",
    "kısa süre",
    "arada bir",
    "bir kez",
    "kısaca",
    "kısa bir",
    "biraz sonra",
    "orta bir",
)
TIT_FOR_TAT = (
    "soğuklukta cevap",
    "aynı soğuklukta",
    "tavır",
    "ben de kendi telefon",
)
MIXED = (
    " ama ",
    " fakat ",
    " ancak ",
    " yine de ",
    "sürerse",
    "olmazsa",
    "isterse",
)
CULTURE = (
    "alman usulü",
    "aile",
    "bayram",
    "hesap öde",
    "ev partisine",
    "eski sevgili",
    "eski ilişki",
)


def fingerprint(pool: dict) -> str:
    rows = []
    for it in pool["items"]:
        opts = [
            (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
            for o in it["options"]
        ]
        rows.append((it["item_id"], it["prompt"], opts))
    blob = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(blob.encode("utf-8")).hexdigest()


def to_grid(value: float) -> float:
    value = min(1.0, max(0.0, value))
    return min(GRID, key=lambda g: abs(g - value))


def hits(text: str, cues: tuple[str, ...]) -> int:
    return sum(1 for c in cues if c in text)


def axis_hits(text: str, dim: str) -> int:
    return hits(text, AXIS_CUES.get(dim, ()))


def relative_grid(features: list[float], gain: float = 1.6) -> list[float]:
    """Keep absolute level. Allow ties. Do not force a 0-vs-1 ranking."""
    mean = sum(features) / 4.0
    spread = max(features) - min(features)
    if spread < 0.05:
        g = to_grid(mean)
        return [g] * 4
    return [to_grid(mean + gain * (feat - mean)) for feat in features]


def similarity(a: str, b: str) -> float:
    return SequenceMatcher(None, a, b).ratio()


def score_question(item: dict) -> dict:
    primary = item["primary_dimensions"][0]
    stem = item["prompt"]
    options = item["options"]
    texts = [o["text"] for o in options]
    lows = [t.lower() for t in texts]
    lens = [len(t) for t in texts]

    sd_f, ob_f, pl_f, spr_f, dv_f, am_f = [], [], [], [], [], []
    notes = []
    flags: set[str] = set()

    pair_sim = []
    for i in range(4):
        for j in range(i + 1, 4):
            pair_sim.append(similarity(lows[i], lows[j]))
    if pair_sim and max(pair_sim) >= 0.82:
        flags.add("two_options_semantically_near_equivalent")

    if any(hits(t, CARICATURE) for t in lows):
        flags.add("option_looks_caricatured")
    if any(hits(t, CULTURE) or hits(stem.lower(), CULTURE) for t in lows):
        flags.add("wording_may_shift_across_cultures")

    off_axis = 0
    for i, (low, raw, n) in enumerate(zip(lows, texts, lens)):
        stub = n < 28
        caric = hits(low, CARICATURE)
        moral = hits(low, MORAL)
        ideal = hits(low, IDEAL_SELF)
        coded = hits(low, TEST_CODED)
        cold = hits(low, COLD_ABRUPT)
        costly = hits(low, COSTLY)
        mixed = hits(low, MIXED)
        please = hits(low, PEOPLE_PLEASE)
        middle = hits(low, MIDDLE_PATH)
        tft = hits(low, TIT_FOR_TAT)
        ama = low.count(" ama ") + low.count("ama ")
        verbs = len(re.findall(r"\b(\w+r[ıiüu]m|\w+irim|\w+erim)\b", low))

        prim_h = axis_hits(low, primary)
        other_h = sum(axis_hits(low, d) for d in AXIS_CUES if d != primary)
        weights = options[i].get("behavioral_weights") or {}
        authored_on_primary = primary in weights
        if not authored_on_primary:
            off_axis += 1

        # Wording-based social image, not weight sign.
        sd = 0.50
        sd += 0.16 * min(ideal, 2)
        sd += 0.10 * min(moral, 2)
        sd += 0.10 * min(please, 2)
        sd += 0.08 * min(middle, 2)
        sd -= 0.16 * min(cold, 2)
        sd -= 0.14 * min(caric, 2)
        sd -= 0.14 * min(tft, 2)
        if "özür" in low or "dinlemeni" in low:
            sd += 0.12
        if "kendi işime" in low or "umursamam" in low:
            sd -= 0.10
        if stub:
            sd -= 0.06
        sd_f.append(min(0.95, max(0.08, sd)))

        ob = 0.42
        ob += 0.16 * min(coded, 2)
        ob += 0.10 * min(ideal, 2)
        ob += 0.12 * min(middle, 2)
        if "net" in low and ("söyler" in low or "çizerim" in low or "derim" in low):
            ob += 0.16
        if stub:
            ob -= 0.10
        if caric:
            ob += 0.08
        ob_f.append(min(0.95, max(0.08, ob)))

        pl = 0.78
        if stub:
            pl -= 0.36
        pl -= 0.22 * min(caric, 2)
        if n > 140:
            pl -= 0.10
        if n < 18:
            pl -= 0.10
        if mixed >= 2:
            pl -= 0.06
        if stub and not caric:
            pl = max(pl, 0.34)
        pl_f.append(min(0.95, max(0.12, pl)))

        spr = 0.42
        spr += 0.14 * min(ideal, 2)
        spr += 0.12 * min(coded, 2)
        spr += 0.10 * min(middle, 2)
        spr += 0.08 * min(please, 2)
        spr -= 0.18 * min(costly, 2)
        if stub:
            spr -= 0.08
        if "özür dilerim" in low or "faydalı bulurum" in low:
            spr += 0.12
        spr_f.append(min(0.95, max(0.08, spr)))

        dv = 0.55
        if prim_h:
            dv += 0.12 + 0.08 * min(prim_h, 2)
        if other_h > prim_h + 1:
            dv -= 0.20
        if not authored_on_primary:
            dv -= 0.18
        if stub:
            dv -= 0.16
        if mixed:
            dv -= 0.10
        if caric:
            dv -= 0.12
        dv_f.append(min(0.92, max(0.08, dv)))

        am = 0.26
        am += 0.12 * mixed
        am += 0.10 * min(ama, 2)
        if other_h and prim_h:
            am += 0.12
        if stub:
            am += 0.22
        if verbs >= 3:
            am += 0.08
        if not authored_on_primary:
            am += 0.10
        am_f.append(min(0.95, max(0.08, am)))

        notes.append(
            {
                "stub": stub,
                "caric": caric,
                "ideal": ideal,
                "coded": coded,
                "off_primary": not authored_on_primary,
                "costly": costly,
            }
        )

    sd = relative_grid(sd_f)
    ob = relative_grid(ob_f)
    pl = relative_grid(pl_f)
    spr = relative_grid(spr_f)
    dv = relative_grid(dv_f)
    am = relative_grid(am_f, gain=1.25)

    if max(sd) - min(sd) >= 0.50:
        flags.add("one_option_much_more_socially_attractive")
    if max(am) >= 0.75:
        flags.add("option_mixes_substantially_different_interpretations")
    if min(dv) <= 0.25 or off_axis >= 2:
        flags.add("diagnostic_value_uncertain")
    if off_axis >= 1:
        flags.add("primary_axis_not_cleanly_reflected_by_all_four")
    stub_n = sum(1 for n in notes if n["stub"])
    if stub_n >= 3 or any(s >= 0.75 and o >= 0.75 for s, o in zip(sd, ob)):
        flags.add("question_appears_easy_to_game")
    if any(abs(s - p) >= 0.50 for s, p in zip(sd, spr)):
        flags.add("social_desirability_and_self_presentation_hard_to_separate")
    if stub_n >= 2 or any(n["caric"] for n in notes):
        flags.add("scores_depend_on_reviewer_assumptions")

    scored_opts = []
    for i, opt in enumerate(options):
        meta = {
            "version": "frequency_evidence_prior_v1",
            "calibration_status": "uncalibrated",
            "review_status": "proposed",
            "social_desirability": sd[i],
            "obviousness": ob[i],
            "behavioral_plausibility": pl[i],
            "self_presentation_risk": spr[i],
            "diagnostic_value": dv[i],
            "ambiguity": am[i],
            "reviewer_rationale": rationale(notes[i], sd[i], ob[i], pl[i], spr[i], dv[i], am[i]),
        }
        scored_opts.append(
            {
                "option_id": opt["option_id"],
                "option_text": opt["text"],
                "behavioral_weights": dict(opt["behavioral_weights"]),
                "evidence_meta": meta,
            }
        )

    lowish = (
        "option_looks_caricatured" in flags
        or "two_options_semantically_near_equivalent" in flags
        or off_axis >= 2
        or min(pl) <= 0.25
        or sum(1 for x in dv if x <= 0.25) >= 2
    )
    highish = (
        off_axis == 0
        and min(pl) >= 0.50
        and min(dv) >= 0.50
        and max(am) <= 0.50
        and "option_looks_caricatured" not in flags
        and "two_options_semantically_near_equivalent" not in flags
    )
    quality = "LOW" if lowish else ("HIGH" if highish else "MEDIUM")
    needs = bool(flags) or quality == "LOW"

    return {
        "question_id": item["item_id"],
        "primary_dimension": primary,
        "question_evidence_quality": quality,
        "needs_human_review": needs,
        "needs_human_review_reasons": sorted(flags),
        "options": scored_opts,
    }


def rationale(note: dict, sd, ob, pl, spr, dv, am) -> str:
    parts = []
    if note["stub"]:
        parts.append("The wording is very brief, so interpretation leans on the sibling contrast more than on a fully specified behavior.")
    elif note["caric"]:
        parts.append("Loaded or caricatured phrasing makes ordinary plausibility weaker than the rest of the set.")
    elif note["off_primary"]:
        parts.append("The described behavior is only loosely tied to this question's designed primary axis.")
    elif dv >= 0.75:
        parts.append("If chosen sincerely, this option gives a relatively clear on-axis signal among the four.")
    else:
        parts.append("Relative to its siblings, this option is a usable but not sharply unique reading of the scene.")

    if sd >= 0.75 and spr >= 0.75:
        parts.append("The wording is easy to select as an approved identity, so presentation pressure is comparatively high.")
    elif am >= 0.75:
        parts.append("More than one behavioral motive could produce the same choice.")
    elif pl >= 0.75 and ob <= 0.50:
        parts.append("The reaction reads as ordinary rather than as an obvious test-coded answer.")
    else:
        parts.append("Evidence scores are uncalibrated reviewer priors, not truth or personality probabilities.")
    return " ".join(parts[:2])


def sanity_rows(items: list[dict], pool_by: dict) -> dict:
    """Report associations with weight sign/magnitude. Do not correct scores."""
    buckets = defaultdict(list)
    for q in items:
        src = pool_by[q["question_id"]]
        primary = q["primary_dimension"]
        for opt, src_opt in zip(q["options"], src["options"]):
            w = float((src_opt.get("behavioral_weights") or {}).get(primary, 0.0))
            em = opt["evidence_meta"]
            sign = "pos" if w > 0 else ("neg" if w < 0 else "zero")
            mag2 = abs(w) >= 1.999
            for field in FIELDS:
                buckets[(field, "sign", sign)].append(em[field])
                buckets[(field, "mag2", mag2)].append(em[field])
            buckets[("social_desirability", "dim", primary)].append(em["social_desirability"])
            buckets[("ambiguity", "dim", primary)].append(em["ambiguity"])
            buckets[("diagnostic_value", "dim", primary)].append(em["diagnostic_value"])

    def mean(xs):
        return round(sum(xs) / len(xs), 3) if xs else None

    report = {
        "sd_mean_when_primary_weight_positive": mean(buckets[("social_desirability", "sign", "pos")]),
        "sd_mean_when_primary_weight_negative": mean(buckets[("social_desirability", "sign", "neg")]),
        "ambiguity_mean_when_primary_weight_positive": mean(buckets[("ambiguity", "sign", "pos")]),
        "ambiguity_mean_when_primary_weight_negative": mean(buckets[("ambiguity", "sign", "neg")]),
        "diagnostic_mean_when_abs_primary_weight_is_2": mean(buckets[("diagnostic_value", "mag2", True)]),
        "diagnostic_mean_when_abs_primary_weight_not_2": mean(buckets[("diagnostic_value", "mag2", False)]),
        "sd_by_primary_dimension": {
            d: mean(buckets[("social_desirability", "dim", d)])
            for d in AXIS_CUES
        },
        "ambiguity_by_primary_dimension": {
            d: mean(buckets[("ambiguity", "dim", d)])
            for d in AXIS_CUES
        },
        "diagnostic_by_primary_dimension": {
            d: mean(buckets[("diagnostic_value", "dim", d)])
            for d in AXIS_CUES
        },
    }
    patterns = []
    sd_pos = report["sd_mean_when_primary_weight_positive"]
    sd_neg = report["sd_mean_when_primary_weight_negative"]
    if sd_pos is not None and sd_neg is not None and sd_pos - sd_neg >= 0.12:
        patterns.append(
            "Positive primary-weight options have higher mean social_desirability "
            f"({sd_pos} vs {sd_neg}). Often the authored + pole uses clearer/more approved wording; scores were not auto-corrected."
        )
    am_pos = report["ambiguity_mean_when_primary_weight_positive"]
    am_neg = report["ambiguity_mean_when_primary_weight_negative"]
    if am_pos is not None and am_neg is not None and am_neg - am_pos >= 0.12:
        patterns.append(
            "Negative primary-weight options have higher mean ambiguity "
            f"({am_neg} vs {am_pos}). Not auto-corrected."
        )
    dv2 = report["diagnostic_mean_when_abs_primary_weight_is_2"]
    dvn = report["diagnostic_mean_when_abs_primary_weight_not_2"]
    if dv2 is not None and dvn is not None and dv2 - dvn >= 0.12:
        patterns.append(
            "Options with |primary weight|=2 have higher mean diagnostic_value "
            f"({dv2} vs {dvn}). Magnitude was not used as a scoring rule; residual association is reported, not fixed."
        )
    sd_dim = report["sd_by_primary_dimension"]
    if sd_dim.get("autonomy") is not None and sd_dim.get("reassurance_need") is not None:
        if sd_dim["autonomy"] - sd_dim["reassurance_need"] >= 0.12:
            patterns.append(
                "Autonomy-primary items show higher mean social_desirability than reassurance-primary items "
                f"({sd_dim['autonomy']} vs {sd_dim['reassurance_need']}). Not treated as healthier-by-default in the scorer; residual is reported."
            )
        if sd_dim.get("boundary_firmness") is not None and sd_dim["boundary_firmness"] - sd_dim.get("adaptability", 0) >= 0.12:
            patterns.append(
                "Boundary-primary items show higher mean social_desirability than some other dimensions. Residual association reported, not corrected."
            )
    if sd_dim.get("repair_style") is not None:
        repair_vs = [v for k, v in sd_dim.items() if k != "repair_style" and v is not None]
        if repair_vs and sd_dim["repair_style"] - (sum(repair_vs) / len(repair_vs)) >= 0.12:
            patterns.append(
                "Repair_style items have higher mean social_desirability than the other-dimension average. Not treated as the correct pole; reported only."
            )
    report["suspicious_systematic_bias_notes"] = patterns or [
        "No strong systematic sign/magnitude/dimension bias crossed the 0.12 mean-difference report threshold."
    ]
    return report


def main() -> None:
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    fp_before = fingerprint(pool)
    review_by = {r["item_id"]: r for r in review["items"]}
    pool_by = {it["item_id"]: it for it in pool["items"]}

    selectable = [
        it
        for it in pool["items"]
        if review_by[it["item_id"]].get("selector_eligible") is True
    ]
    drop = [
        it
        for it in pool["items"]
        if review_by[it["item_id"]].get("drop_from_selectable") is True
    ]
    if len(selectable) != 408:
        raise SystemExit(f"expected 408 selectable, got {len(selectable)}")
    if len(drop) != 18:
        raise SystemExit(f"expected 18 DROP, got {len(drop)}")
    drop_opt_ids = [o["option_id"] for it in drop for o in it["options"]]
    if len(drop_opt_ids) != 72:
        raise SystemExit(f"expected 72 DROP options, got {len(drop_opt_ids)}")

    scored = [score_question(it) for it in selectable]
    option_count = sum(len(q["options"]) for q in scored)
    if option_count != 1632:
        raise SystemExit(f"expected 1632 scored options, got {option_count}")

    scored_ids = {o["option_id"] for q in scored for o in q["options"]}
    if scored_ids & set(drop_opt_ids):
        raise SystemExit("DROP option leaked into proposal")

    # Validate grid + six fields.
    for q in scored:
        if len(q["options"]) != 4:
            raise SystemExit(q["question_id"])
        for o in q["options"]:
            em = o["evidence_meta"]
            if em["review_status"] != "proposed":
                raise SystemExit("review_status")
            if em["calibration_status"] != "uncalibrated":
                raise SystemExit("calibration")
            for f in FIELDS:
                if em[f] not in GRID:
                    raise SystemExit(f"off-grid {o['option_id']} {f}={em[f]}")
            if not em.get("reviewer_rationale"):
                raise SystemExit(f"no rationale {o['option_id']}")

    if fingerprint(pool) != fp_before:
        raise SystemExit("STOP: pool fingerprint changed")
    if pool.get("runtime_selectable") is not False:
        raise SystemExit("runtime_selectable")

    # Pool evidence still pending/null.
    for it in pool["items"]:
        for o in it["options"]:
            em = o.get("evidence_meta") or {}
            if em.get("review_status") != "pending":
                raise SystemExit("pool evidence not pending")
            for f in FIELDS:
                if em.get(f) is not None:
                    raise SystemExit("pool evidence numeric assigned")

    quality = Counter(q["question_evidence_quality"] for q in scored)
    needs_n = sum(1 for q in scored if q["needs_human_review"])
    dist = {f: Counter(o["evidence_meta"][f] for q in scored for o in q["options"]) for f in FIELDS}

    def qids_where(pred) -> list[str]:
        return [q["question_id"] for q in scored if pred(q)]

    identical = {f: qids_where(lambda q, field=f: len({o["evidence_meta"][field] for o in q["options"]}) == 1) for f in FIELDS}
    amb75 = qids_where(lambda q: any(o["evidence_meta"]["ambiguity"] >= 0.75 for o in q["options"]))
    sd75 = qids_where(lambda q: any(o["evidence_meta"]["social_desirability"] >= 0.75 for o in q["options"]))
    spr75 = qids_where(lambda q: any(o["evidence_meta"]["self_presentation_risk"] >= 0.75 for o in q["options"]))
    dv_low2 = qids_where(
        lambda q: sum(1 for o in q["options"] if o["evidence_meta"]["diagnostic_value"] <= 0.25) >= 2
    )
    pl25 = qids_where(lambda q: any(o["evidence_meta"]["behavioral_plausibility"] <= 0.25 for o in q["options"]))

    sanity = sanity_rows(scored, pool_by)

    proposal = {
        "schema": "qmatch_frequency_behavior_v2_phase2b_evidence_prior_proposal",
        "applied_to_pool": False,
        "version": "frequency_evidence_prior_v1",
        "calibration_status": "uncalibrated",
        "review_status": "proposed",
        "not_claims": [
            "validated",
            "scientific_coefficients",
            "truth_probabilities",
            "lie_probabilities",
            "personality_probabilities",
            "empirical_discrimination",
            "discrimination_power",
        ],
        "selectable_question_count": 408,
        "selectable_option_count": 1632,
        "drop_question_count_excluded": 18,
        "drop_option_count_excluded": 72,
        "drop_option_ids_excluded": drop_opt_ids,
        "source_pool_fingerprint_sha256": fp_before,
        "runtime_selectable": False,
        "items": scored,
    }
    PROPOSAL_PATH.write_text(
        json.dumps(proposal, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    def dist_block(field: str) -> str:
        c = dist[field]
        lines = [f"### {field}", ""]
        for g in GRID:
            lines.append(f"- {g:.2f}: {c.get(g, 0)}")
        return "\n".join(lines)

    def id_list(ids: list[str], cap: int = 40) -> str:
        if not ids:
            return "_none_"
        shown = ", ".join(f"`{i}`" for i in ids[:cap])
        extra = f" … +{len(ids) - cap}" if len(ids) > cap else ""
        return f"{len(ids)} questions: {shown}{extra}"

    ident_lines = "\n".join(
        f"- `{f}`: {len(identical[f])} questions" for f in FIELDS
    )
    bias_lines = "\n".join(f"- {p}" for p in sanity["suspicious_systematic_bias_notes"])
    sd_dim_lines = "\n".join(
        f"- `{d}`: {sanity['sd_by_primary_dimension'][d]}" for d in AXIS_CUES
    )

    audit = f"""# Frequency V2 Phase 2B — Evidence prior proposal audit

Status: **proposal only**. Not applied to the dormant pool.
All values are **uncalibrated reviewer priors**, not validated coefficients,
truth/lie probabilities, personality probabilities, or empirical discrimination.

Source pool fingerprint SHA-256: `{fp_before}`

## Counts

- Selectable questions scored: **408**
- Selectable options scored: **1632**
- DROP questions left pending/null: **18**
- DROP options left pending/null: **72** (absent from proposal)
- `needs_human_review=true`: **{needs_n}**
- Evidence-quality HIGH: **{quality.get('HIGH', 0)}**
- Evidence-quality MEDIUM: **{quality.get('MEDIUM', 0)}**
- Evidence-quality LOW: **{quality.get('LOW', 0)}**

## Field distributions (1632 scored options)

{dist_block('social_desirability')}

{dist_block('obviousness')}

{dist_block('behavioral_plausibility')}

{dist_block('self_presentation_risk')}

{dist_block('diagnostic_value')}

{dist_block('ambiguity')}

## Same-value siblings

Questions where all four options received the identical grid value:

{ident_lines}

This is allowed. Rankings were not manufactured so that every option differs.

## Flagged subsets

- Any `ambiguity` ≥ 0.75: {id_list(amb75)}
- Any `social_desirability` ≥ 0.75: {id_list(sd75)}
- Any `self_presentation_risk` ≥ 0.75: {id_list(spr75)}
- `diagnostic_value` ≤ 0.25 for two or more options: {id_list(dv_low2)}
- Any `behavioral_plausibility` ≤ 0.25: {id_list(pl25)}

## Sanity audit (reported, not auto-corrected)

Mean social_desirability when primary weight is positive: {sanity['sd_mean_when_primary_weight_positive']}
Mean social_desirability when primary weight is negative: {sanity['sd_mean_when_primary_weight_negative']}
Mean ambiguity when primary weight is positive: {sanity['ambiguity_mean_when_primary_weight_positive']}
Mean ambiguity when primary weight is negative: {sanity['ambiguity_mean_when_primary_weight_negative']}
Mean diagnostic_value when |primary weight| = 2: {sanity['diagnostic_mean_when_abs_primary_weight_is_2']}
Mean diagnostic_value otherwise: {sanity['diagnostic_mean_when_abs_primary_weight_not_2']}

Social desirability means by primary dimension:

{sd_dim_lines}

Notes:

{bias_lines}

## Safety

- Dormant pool not modified
- `review_status=reviewed` not set on the pool
- DROP options not scored
- V2 remains `runtime_selectable=false`
- No V1 / Firebase / matching / Persona / Discover / C2 / locale-routing change
- No `discrimination_power`

FREQUENCY V2 PHASE 2B EVIDENCE PRIOR PROPOSAL COMPLETE — 1632 OPTIONS SCORED — NO VALUES APPLIED — V2 STILL DORMANT
"""
    AUDIT_PATH.write_text(audit, encoding="utf-8")
    print("questions", 408)
    print("options", 1632)
    print("needs_human_review", needs_n)
    print("quality", dict(quality))
    print("fingerprint", fp_before)
    print("wrote", PROPOSAL_PATH)
    print("wrote", AUDIT_PATH)


if __name__ == "__main__":
    main()
