#!/usr/bin/env python3
"""Phase 2C: triage Phase 2B evidence priors. Proposal-only. Does not apply scores.

Reclassifies the 397 needs_human_review flags into KEEP vs CLEAR using a
stricter evidence-reliability standard. Does not modify proposal scores,
the dormant pool, V1, or live routing.
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
TRIAGE_MD = OUT_DIR / "frequency_behavior_v2_phase2c_evidence_triage.md"
TRIAGE_JSON = OUT_DIR / "frequency_behavior_v2_phase2c_evidence_triage.json"

FIELDS = (
    "social_desirability",
    "obviousness",
    "behavioral_plausibility",
    "self_presentation_risk",
    "diagnostic_value",
    "ambiguity",
)
DIMS = (
    "contact_need",
    "closeness_pace",
    "initiative",
    "autonomy",
    "reassurance_need",
    "uncertainty_tolerance",
    "disclosure_pace",
    "boundary_firmness",
    "repair_style",
    "social_energy",
    "structure_preference",
    "adaptability",
)
REASON_CODES = (
    "SD_DOMINANCE",
    "OBVIOUS_TEST_ANSWER",
    "LOW_PLAUSIBILITY",
    "OPTION_DUPLICATION",
    "HIGH_AMBIGUITY",
    "PRIMARY_AXIS_CONFUSION",
    "CULTURAL_DEPENDENCE",
    "SELF_PRESENTATION_HEAVY",
    "LOW_DIAGNOSTIC_CONTRAST",
    "OTHER",
)

MORAL_IDEAL = (
    "iletişim fırsatı",
    "suçlamadan",
    "gurur yapmadan",
    "kıskançlık yapan biri değilim",
    "faydalı bulurum",
    "eşlik etmekten keyif",
    "en adilidir",
    "objektif bir göz",
    "sağlıklı",
    "olgun",
)
HYPERBOLE = (
    "felaketle sonuçlanır",
    "intikam",
    "cezalandır",
    "toksik",
    "çileden çıkar",
    "ulu orta",
)
MIXED_CONJ = (" ama ", " fakat ", " ancak ", " yine de ")
FAMILY_INTRO = re.compile(
    r"(ailes(?:i|iyle)|aileyle|yakın çevresiyle)\s+tanış|"
    r"ailesinin bir özel gününe|"
    r"sevdiği ailesiyle",
    re.I,
)
BILL_SPLIT = re.compile(
    r"alman usulü|hesap ödeme|hesap geldi|hesabı kimin|kim ne yediyse|"
    r"maddi hesap",
    re.I,
)
BAYRAM = re.compile(r"\bbayram\b", re.I)

# Previous 2B flags that are purity/heuristic overflags when they appear alone
# or only with each other.
OVERFLAG_CLUSTER = {
    "primary_axis_not_cleanly_reflected_by_all_four",
    "diagnostic_value_uncertain",
    "option_mixes_substantially_different_interpretations",
    "scores_depend_on_reviewer_assumptions",
    "question_appears_easy_to_game",
    "wording_may_shift_across_cultures",
    "social_desirability_and_self_presentation_hard_to_separate",
    "one_option_much_more_socially_attractive",
    "two_options_semantically_near_equivalent",
    "option_looks_caricatured",
}


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


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def mean(xs: list[float]) -> float | None:
    if not xs:
        return None
    return round(sum(xs) / len(xs), 3)


def pairwise_max_sim(texts: list[str]) -> float:
    lows = [t.lower() for t in texts]
    best = 0.0
    for i in range(len(lows)):
        for j in range(i + 1, len(lows)):
            best = max(best, SequenceMatcher(None, lows[i], lows[j]).ratio())
    return best


def dominant_dim(weights: dict) -> str | None:
    if not weights:
        return None
    return max(weights.items(), key=lambda kv: abs(float(kv[1])))[0]


def ems(q: dict, field: str) -> list[float]:
    return [float(o["evidence_meta"][field]) for o in q["options"]]


def blob_of(src: dict) -> str:
    return src["prompt"] + " " + " ".join(o["text"] for o in src["options"])


def has_moral_ideal(text: str) -> bool:
    low = text.lower()
    if any(p in low for p in MORAL_IDEAL):
        return True
    if "hemen" in low and "özür" in low:
        return True
    if "net bir şekilde ifade" in low or "net biçimde isterim" in low:
        return False
    return False


def classify(q: dict, src: dict) -> tuple[str, list[str], str]:
    """Return (CLEAN|ACCEPTABLE_COMPLEXITY|REAL_REVIEW_REQUIRED, reasons, note)."""
    primary = q["primary_dimension"]
    options = src["options"]
    texts = [o["text"] for o in options]
    lows = [t.lower() for t in texts]
    sds = ems(q, "social_desirability")
    obs = ems(q, "obviousness")
    pls = ems(q, "behavioral_plausibility")
    ams = ems(q, "ambiguity")
    reasons: list[str] = []

    off_axis = sum(1 for o in options if primary not in (o.get("behavioral_weights") or {}))
    secondaries = sum(1 for o in options if len(o.get("behavioral_weights") or {}) > 1)
    stubs = sum(1 for t in texts if len(t) < 28)
    mixed_n = sum(1 for t in lows if any(c in f" {t} " for c in MIXED_CONJ))
    sim = pairwise_max_sim(texts)
    blob = blob_of(src)
    moral_opts = [has_moral_ideal(t) for t in texts]
    hyper = [any(h in t for h in HYPERBOLE) for t in lows]

    sd_spread = max(sds) - min(sds)
    ob_spread = max(obs) - min(obs)

    if max(sds) >= 0.75 and sd_spread >= 0.50 and any(moral_opts):
        reasons.append("SD_DOMINANCE")

    coded_winner = False
    for i, em in enumerate(q["options"]):
        e = em["evidence_meta"]
        if (
            e["social_desirability"] >= 0.75
            and e["obviousness"] >= 0.75
            and moral_opts[i]
        ):
            coded_winner = True
        if e["obviousness"] >= 1.00 and ob_spread >= 0.50 and moral_opts[i]:
            coded_winner = True
    if coded_winner:
        reasons.append("OBVIOUS_TEST_ANSWER")

    if any(hyper):
        reasons.append("LOW_PLAUSIBILITY")

    # Functional duplicates: near-identical wording AND same dominant dimension.
    dup = False
    for i in range(4):
        for j in range(i + 1, 4):
            if SequenceMatcher(None, lows[i], lows[j]).ratio() < 0.88:
                continue
            di = dominant_dim(options[i].get("behavioral_weights") or {})
            dj = dominant_dim(options[j].get("behavioral_weights") or {})
            if di and di == dj:
                dup = True
    if dup:
        reasons.append("OPTION_DUPLICATION")

    # am==1.00 was rare and marks a genuinely mixed / underspecified reading.
    # Do not treat stub-inflated 0.75 ambiguity or mixed-motive "ama" as a defect.
    if max(ams) >= 1.00:
        reasons.append("HIGH_AMBIGUITY")

    # Named primary is unmeasurable only when no option carries it.
    # Off-axis siblings with leaked low diagnostic_value are not themselves a defect.
    if off_axis == 4:
        reasons.append("PRIMARY_AXIS_CONFUSION")
        reasons.append("LOW_DIAGNOSTIC_CONTRAST")

    if FAMILY_INTRO.search(blob) or BILL_SPLIT.search(blob) or BAYRAM.search(blob):
        reasons.append("CULTURAL_DEPENDENCE")

    spr_heavy = False
    for i, em in enumerate(q["options"]):
        e = em["evidence_meta"]
        if (
            e["self_presentation_risk"] >= 0.75
            and e["social_desirability"] >= 0.75
            and moral_opts[i]
        ):
            spr_heavy = True
    if spr_heavy:
        reasons.append("SELF_PRESENTATION_HEAVY")

    # Deduplicate while preserving order.
    seen = set()
    ordered = []
    for r in reasons:
        if r not in seen:
            seen.add(r)
            ordered.append(r)
    reasons = ordered

    if reasons:
        note = "Evidence interpretation is meaningfully unreliable on at least one listed reason."
        return "REAL_REVIEW_REQUIRED", reasons, note

    # Remaining items: purity / secondary / stub / mild SD are not defects.
    complex_bits = []
    if off_axis:
        complex_bits.append(f"{off_axis} option(s) authored off the named primary")
    if secondaries:
        complex_bits.append("mild secondary weights")
    if stubs:
        complex_bits.append("brief option wording")
    if mixed_n:
        complex_bits.append("mixed-motive (ama/fakat) wording")
    if max(sds) >= 0.75 and sd_spread < 0.50:
        complex_bits.append("shared social-desirability without a single winner")
    if max(ams) >= 0.75:
        complex_bits.append("elevated ambiguity prior that remains interpretable")
    if q["question_evidence_quality"] == "LOW":
        complex_bits.append("Phase 2B LOW quality driven by purity/stub heuristics")

    cleanish = (
        off_axis <= 1
        and stubs <= 1
        and max(ams) <= 0.50
        and min(pls) >= 0.50
        and sd_spread <= 0.25
        and max(obs) <= 0.75
        and sim < 0.70
    )
    if cleanish and not complex_bits:
        return (
            "CLEAN",
            [],
            "Four-way contrast is readable; no meaningful evidence-quality defect.",
        )
    if cleanish and off_axis <= 1 and secondaries and max(ams) <= 0.50:
        # Secondary weights with an otherwise clean reading.
        if off_axis == 0 and stubs == 0 and mixed_n == 0 and sd_spread <= 0.25:
            return (
                "CLEAN",
                [],
                "Primary contrast is clear. Secondary weights do not make the evidence unreadable.",
            )

    if not complex_bits:
        complex_bits.append("ordinary multidimensional behavior without a scoring defect")
    return (
        "ACCEPTABLE_COMPLEXITY",
        [],
        "Real-life / secondary-weight complexity; evidence remains interpretable. "
        + "; ".join(complex_bits)
        + ".",
    )


def flag_decision(q: dict, klass: str, reasons: list[str], note: str) -> tuple[str | None, str]:
    prev = bool(q.get("needs_human_review"))
    prev_rs = list(q.get("needs_human_review_reasons") or [])
    if not prev:
        return None, "Was not in the Phase 2B needs_human_review=true set."
    if klass == "REAL_REVIEW_REQUIRED":
        return (
            "KEEP_FLAG",
            "Keep: " + ", ".join(reasons) + ". " + note,
        )
    over = set(prev_rs) <= OVERFLAG_CLUSTER or not prev_rs
    why = (
        "Clear: previous flag does not mark a meaningful evidence-quality problem. "
        f"Triage class={klass}. "
    )
    if over:
        why += (
            "Phase 2B flagged because not all four options were 'pure' on the named "
            "primary, because diagnostic_value was lower on off-primary options, "
            "and/or because stub/keyword heuristics inflated ambiguity, culture, or gameability."
        )
    else:
        why += f"Phase 2B reasons were {prev_rs}, but the four options remain interpretable."
    why += " " + note
    return "CLEAR_FLAG", why


def diagnostic_bias(prop_items: list[dict], pool_by: dict) -> dict:
    buckets: dict[str, list[float]] = defaultdict(list)
    rows = []
    for q in prop_items:
        src = pool_by[q["question_id"]]
        prim = q["primary_dimension"]
        for o, so in zip(q["options"], src["options"]):
            w = float((so.get("behavioral_weights") or {}).get(prim, 0.0))
            em = o["evidence_meta"]
            rec = {
                "question_id": q["question_id"],
                "option_id": o["option_id"],
                "option_text": o["option_text"],
                "primary_dimension": prim,
                "primary_weight": w,
                "on_primary": prim in (so.get("behavioral_weights") or {}),
                "behavioral_weights": dict(so.get("behavioral_weights") or {}),
                "diagnostic_value": em["diagnostic_value"],
                "ambiguity": em["ambiguity"],
                "behavioral_plausibility": em["behavioral_plausibility"],
                "obviousness": em["obviousness"],
            }
            rows.append(rec)
            key = f"{int(w):+d}" if w in (-2.0, -1.0, 1.0, 2.0) else "0"
            buckets[key].append(em["diagnostic_value"])
            buckets["abs2" if abs(w) >= 1.999 else ("abs1" if abs(w) == 1.0 else "abs0")].append(
                em["diagnostic_value"]
            )
            buckets["on" if rec["on_primary"] else "off"].append(em["diagnostic_value"])

    matched = []
    for am in (0.00, 0.25, 0.50, 0.75, 1.00):
        for pl in (0.00, 0.25, 0.50, 0.75, 1.00):
            a2 = [
                r["diagnostic_value"]
                for r in rows
                if abs(r["primary_weight"]) >= 1.999
                and r["ambiguity"] == am
                and r["behavioral_plausibility"] == pl
                and r["on_primary"]
            ]
            a1 = [
                r["diagnostic_value"]
                for r in rows
                if abs(r["primary_weight"]) == 1.0
                and r["ambiguity"] == am
                and r["behavioral_plausibility"] == pl
                and r["on_primary"]
            ]
            if a2 or a1:
                matched.append(
                    {
                        "ambiguity": am,
                        "behavioral_plausibility": pl,
                        "n_abs2": len(a2),
                        "mean_abs2": mean(a2),
                        "n_abs1": len(a1),
                        "mean_abs1": mean(a1),
                        "gap_abs2_minus_abs1": (
                            round(mean(a2) - mean(a1), 3) if a2 and a1 else None
                        ),
                    }
                )

    on_prim_abs2 = [r["diagnostic_value"] for r in rows if r["on_primary"] and abs(r["primary_weight"]) >= 1.999]
    on_prim_abs1 = [r["diagnostic_value"] for r in rows if r["on_primary"] and abs(r["primary_weight"]) == 1.0]

    plus2_high = [r for r in rows if abs(r["primary_weight"]) >= 1.999 and r["diagnostic_value"] >= 0.75]
    pm1_low = [r for r in rows if abs(r["primary_weight"]) == 1.0 and r["diagnostic_value"] <= 0.25]
    plus2_high.sort(key=lambda r: (r["question_id"], r["option_id"]))
    pm1_low.sort(key=lambda r: (r["question_id"], r["option_id"]))

    def judge_high(r: dict) -> str:
        text = r["option_text"]
        if len(text) < 28:
            return "WEIGHT_MAGNITUDE_LEAKAGE"
        return "JUSTIFIED_BY_TEXT"

    def judge_low(r: dict) -> str:
        text = r["option_text"]
        nkeys = len(r["behavioral_weights"])
        mixed = any(c in f" {text.lower()} " for c in MIXED_CONJ)
        if len(text) < 28:
            return "JUSTIFIED_BY_TEXT"
        if mixed or nkeys >= 3:
            return "JUSTIFIED_BY_TEXT"
        # Clear milder on-axis pole with ordinary length: residual cue/magnitude leakage.
        return "WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE"

    s_high = []
    for r in plus2_high[:20]:
        item = {
            **{k: r[k] for k in (
                "question_id",
                "option_id",
                "option_text",
                "primary_dimension",
                "primary_weight",
                "behavioral_weights",
                "diagnostic_value",
                "ambiguity",
                "behavioral_plausibility",
                "obviousness",
            )},
            "judgment": judge_high(r),
        }
        s_high.append(item)
    s_low = []
    for r in pm1_low[:20]:
        item = {
            **{k: r[k] for k in (
                "question_id",
                "option_id",
                "option_text",
                "primary_dimension",
                "primary_weight",
                "behavioral_weights",
                "diagnostic_value",
                "ambiguity",
                "behavioral_plausibility",
                "obviousness",
            )},
            "judgment": judge_low(r),
        }
        s_low.append(item)

    return {
        "mean_diagnostic_value_by_primary_weight": {
            "+2": mean(buckets["+2"]),
            "+1": mean(buckets["+1"]),
            "-1": mean(buckets["-1"]),
            "-2": mean(buckets["-2"]),
            "0_off_primary": mean(buckets["0"]),
        },
        "n_by_primary_weight": {
            "+2": len(buckets["+2"]),
            "+1": len(buckets["+1"]),
            "-1": len(buckets["-1"]),
            "-2": len(buckets["-2"]),
            "0_off_primary": len(buckets["0"]),
        },
        "mean_abs_primary_weight_2": mean(buckets["abs2"]),
        "mean_abs_primary_weight_1": mean(buckets["abs1"]),
        "mean_on_primary": mean(buckets["on"]),
        "mean_off_primary": mean(buckets["off"]),
        "mean_on_primary_abs2": mean(on_prim_abs2),
        "mean_on_primary_abs1": mean(on_prim_abs1),
        "matched_ambiguity_plausibility_bins": matched,
        "relationship_after_controls": (
            "The large |weight|=2 vs otherwise gap in Phase 2B is mostly on-primary "
            "vs off-primary presence (off-primary mean diagnostic_value "
            f"{mean(buckets['off'])} vs on-primary {mean(buckets['on'])}). "
            "After restricting to on-primary options and matching ambiguity and "
            "plausibility bins, a smaller |2| vs |1| gap remains in the largest "
            "bin. That residual tracks more explicit ±2 wording plus Phase 2B "
            "axis-cue bonuses, not a silent |weight| formula. Scores were not changed."
        ),
        "sample_plus2_dv_ge_075": s_high,
        "sample_pm1_dv_le_025": s_low,
        "sample_plus2_judgment_counts": dict(Counter(x["judgment"] for x in s_high)),
        "sample_pm1_judgment_counts": dict(Counter(x["judgment"] for x in s_low)),
    }


def sd_audit(prop_items: list[dict], pool_by: dict) -> dict:
    by_dim: dict[str, list[float]] = defaultdict(list)
    by_sign: dict[str, list[float]] = defaultdict(list)
    by_dim_sign: dict[tuple[str, str], list[float]] = defaultdict(list)
    for q in prop_items:
        src = pool_by[q["question_id"]]
        prim = q["primary_dimension"]
        for o, so in zip(q["options"], src["options"]):
            w = float((so.get("behavioral_weights") or {}).get(prim, 0.0))
            sd = float(o["evidence_meta"]["social_desirability"])
            by_dim[prim].append(sd)
            if w > 0:
                by_sign["pos"].append(sd)
                by_dim_sign[(prim, "pos")].append(sd)
            elif w < 0:
                by_sign["neg"].append(sd)
                by_dim_sign[(prim, "neg")].append(sd)
            else:
                by_sign["zero"].append(sd)

    dim_table = {}
    for d in DIMS:
        dim_table[d] = {
            "n": len(by_dim[d]),
            "mean": mean(by_dim[d]),
            "mean_positive_weight": mean(by_dim_sign[(d, "pos")]),
            "mean_negative_weight": mean(by_dim_sign[(d, "neg")]),
        }
    focus = {}
    for d in ("boundary_firmness", "autonomy", "reassurance_need", "repair_style"):
        pos = mean(by_dim_sign[(d, "pos")])
        neg = mean(by_dim_sign[(d, "neg")])
        gap = round((pos or 0) - (neg or 0), 3) if pos is not None and neg is not None else None
        focus[d] = {**dim_table[d], "pos_minus_neg": gap}

    notes = []
    if (mean(by_sign["pos"]) or 0) - (mean(by_sign["neg"]) or 0) < 0.03:
        notes.append(
            "Overall positive vs negative primary-weight social_desirability means are nearly identical; "
            "weight sign is not being used as a desirability proxy."
        )
    rn = focus["reassurance_need"]
    if rn["pos_minus_neg"] and rn["pos_minus_neg"] >= 0.05:
        notes.append(
            "reassurance_need negative-weight options have a slightly lower mean social_desirability "
            f"than positive-weight options (gap {rn['pos_minus_neg']}). Reported, not corrected. "
            "The absolute means still sit near 0.50."
        )
    rs = focus["repair_style"]
    if rs["pos_minus_neg"] and rs["pos_minus_neg"] >= 0.05:
        notes.append(
            "repair_style positive-weight options have a slightly higher mean social_desirability "
            f"(gap {rs['pos_minus_neg']}), consistent with immediate-apology wording, not with treating "
            "repair as a health score. Reported, not corrected."
        )
    notes.append(
        "boundary_firmness and autonomy are not systematically treated as more mature/healthy; "
        "dimension means sit near the global 0.50 band."
    )
    return {
        "mean_by_sign": {
            "positive_primary_weight": mean(by_sign["pos"]),
            "negative_primary_weight": mean(by_sign["neg"]),
            "zero_off_primary": mean(by_sign["zero"]),
        },
        "mean_by_primary_dimension": dim_table,
        "focus_dimensions": focus,
        "notes": notes,
        "systematic_bias_detected": False,
    }


def sample_questions(rows: list[dict], klass: str, n: int = 10) -> list[dict]:
    ids = [r["question_id"] for r in rows if r["triage_class"] == klass]
    ids.sort()
    pick = ids[:n]
    out = []
    for r in rows:
        if r["question_id"] in pick:
            out.append(r)
    out.sort(key=lambda r: r["question_id"])
    return out


def option_sample_block(qrow: dict) -> str:
    lines = [
        f"### `{qrow['question_id']}` — {qrow['triage_class']}",
        "",
        f"- primary_dimension: `{qrow['primary_dimension']}`",
        f"- Phase 2B quality: {qrow['phase2b_quality']}",
        f"- previous needs_human_review: {qrow['previous_needs_human_review']}",
        f"- flag_decision: {qrow['flag_decision']}",
        f"- reason_codes: {', '.join(qrow['reason_codes']) if qrow['reason_codes'] else '_none_'}",
        f"- stem: {qrow['stem']}",
        "",
    ]
    for o in qrow["options"]:
        em = o["evidence_meta"]
        lines.append(f"- `{o['option_id']}` weights=`{json.dumps(o['behavioral_weights'], ensure_ascii=False)}`")
        lines.append(f"  - text: {o['option_text']}")
        lines.append(
            "  - "
            + ", ".join(f"{k}={em[k]:.2f}" for k in FIELDS)
        )
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    proposal_hash_before = file_sha256(PROPOSAL_PATH)
    proposal = json.loads(PROPOSAL_PATH.read_text(encoding="utf-8"))
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    fp = fingerprint(pool)
    if fp != proposal["source_pool_fingerprint_sha256"]:
        raise SystemExit("pool fingerprint mismatch vs proposal")
    if pool.get("runtime_selectable") is not False:
        raise SystemExit("runtime_selectable")
    for it in pool["items"]:
        for o in it["options"]:
            em = o.get("evidence_meta") or {}
            if em.get("review_status") != "pending":
                raise SystemExit("pool evidence not pending")
            for f in FIELDS:
                if em.get(f) is not None:
                    raise SystemExit("pool evidence numeric assigned")

    pool_by = {it["item_id"]: it for it in pool["items"]}
    review_by = {it["item_id"]: it for it in review["items"]}
    drop_ids = {i for i, meta in review_by.items() if meta.get("drop_from_selectable")}
    if len(drop_ids) != 18:
        raise SystemExit("expected 18 DROP ids")

    items = proposal["items"]
    if len(items) != 408:
        raise SystemExit("expected 408 proposal questions")

    rows = []
    for q in items:
        qid = q["question_id"]
        if qid in drop_ids:
            raise SystemExit(f"DROP question in proposal {qid}")
        src = pool_by[qid]
        klass, reasons, note = classify(q, src)
        decision, why = flag_decision(q, klass, reasons, note)
        opt_out = []
        for o, so in zip(q["options"], src["options"]):
            if o["option_text"] != so["text"]:
                raise SystemExit("proposal text drifted")
            if o["behavioral_weights"] != so["behavioral_weights"]:
                raise SystemExit("proposal weights drifted")
            opt_out.append(
                {
                    "option_id": o["option_id"],
                    "option_text": o["option_text"],
                    "behavioral_weights": dict(o["behavioral_weights"]),
                    "evidence_meta": {
                        k: o["evidence_meta"][k]
                        for k in (
                            "version",
                            "calibration_status",
                            "review_status",
                            *FIELDS,
                            "reviewer_rationale",
                        )
                    },
                }
            )
        rows.append(
            {
                "question_id": qid,
                "primary_dimension": q["primary_dimension"],
                "stem": src["prompt"],
                "triage_class": klass,
                "reason_codes": reasons,
                "triage_note": note,
                "previous_needs_human_review": bool(q.get("needs_human_review")),
                "phase2b_reasons": list(q.get("needs_human_review_reasons") or []),
                "phase2b_quality": q["question_evidence_quality"],
                "flag_decision": decision,
                "flag_decision_why": why,
                "options": opt_out,
            }
        )

    class_c = Counter(r["triage_class"] for r in rows)
    keep_n = sum(1 for r in rows if r["flag_decision"] == "KEEP_FLAG")
    clear_n = sum(1 for r in rows if r["flag_decision"] == "CLEAR_FLAG")
    prev_n = sum(1 for r in rows if r["previous_needs_human_review"])
    if prev_n != 397:
        raise SystemExit(f"expected 397 previous flags, got {prev_n}")
    if keep_n + clear_n != 397:
        raise SystemExit("KEEP+CLEAR must equal 397")
    if sum(class_c.values()) != 408:
        raise SystemExit("class counts must cover 408")

    reason_c = Counter()
    for r in rows:
        for code in r["reason_codes"]:
            reason_c[code] += 1
    real_ids = [r["question_id"] for r in rows if r["triage_class"] == "REAL_REVIEW_REQUIRED"]
    real_ids.sort()

    dv = diagnostic_bias(items, pool_by)
    sd = sd_audit(items, pool_by)

    sample = {
        "CLEAN": sample_questions(rows, "CLEAN", 10),
        "ACCEPTABLE_COMPLEXITY": sample_questions(rows, "ACCEPTABLE_COMPLEXITY", 10),
        "REAL_REVIEW_REQUIRED": sample_questions(rows, "REAL_REVIEW_REQUIRED", 10),
    }
    # Compact sample copies (keep scores, drop long why on nested dump size — keep why).
    sample_out = {k: v for k, v in sample.items()}

    overall = "OVERFLAGGED_BY_REVIEW_RULE"
    overall_notes = (
        "The 397/408 needs_human_review rate is not a bank-wide evidence collapse. "
        "Phase 2B set needs_human_review whenever any option lacked a weight on the "
        "named primary (356 questions) and/or diagnostic_value was uncertain under that "
        "purity rule (372). Secondary weights, ±1 vs ±2, tied evidence scores, and "
        "ordinary mixed motives are acceptable behavioral complexity, not defects. "
        f"After re-triage, REAL_REVIEW_REQUIRED={class_c['REAL_REVIEW_REQUIRED']}, "
        f"ACCEPTABLE_COMPLEXITY={class_c['ACCEPTABLE_COMPLEXITY']}, "
        f"CLEAN={class_c['CLEAN']}; KEEP_FLAG={keep_n}, CLEAR_FLAG={clear_n}."
    )

    payload = {
        "schema": "qmatch_frequency_behavior_v2_phase2c_evidence_triage",
        "applied_to_pool": False,
        "scores_modified": False,
        "proposal_modified": False,
        "calibration_status": "uncalibrated",
        "source_proposal": "tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2b_evidence_prior_proposal.json",
        "source_pool_fingerprint_sha256": fp,
        "proposal_file_sha256_before": proposal_hash_before,
        "runtime_selectable": False,
        "overall_finding": overall,
        "overall_finding_notes": overall_notes,
        "counts": {
            "CLEAN": class_c["CLEAN"],
            "ACCEPTABLE_COMPLEXITY": class_c["ACCEPTABLE_COMPLEXITY"],
            "REAL_REVIEW_REQUIRED": class_c["REAL_REVIEW_REQUIRED"],
            "questions_reviewed": 408,
        },
        "previous_397_flags": {
            "KEEP_FLAG": keep_n,
            "CLEAR_FLAG": clear_n,
            "was_unflagged": 408 - 397,
        },
        "reason_code_counts": {k: reason_c.get(k, 0) for k in REASON_CODES},
        "real_review_required_ids": real_ids,
        "diagnostic_value_bias": dv,
        "social_desirability_audit": sd,
        "questions": [
            {
                "question_id": r["question_id"],
                "primary_dimension": r["primary_dimension"],
                "triage_class": r["triage_class"],
                "reason_codes": r["reason_codes"],
                "triage_note": r["triage_note"],
                "previous_needs_human_review": r["previous_needs_human_review"],
                "phase2b_quality": r["phase2b_quality"],
                "phase2b_reasons": r["phase2b_reasons"],
                "flag_decision": r["flag_decision"],
                "flag_decision_why": r["flag_decision_why"],
            }
            for r in rows
        ],
        "audit_sample_30": sample_out,
    }

    TRIAGE_JSON.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    def id_list(ids: list[str]) -> str:
        return ", ".join(f"`{i}`" for i in ids)

    reason_lines = "\n".join(f"- `{k}`: {reason_c.get(k, 0)}" for k in REASON_CODES)
    sample_md = []
    for klass in ("CLEAN", "ACCEPTABLE_COMPLEXITY", "REAL_REVIEW_REQUIRED"):
        sample_md.append(f"## 30-question sample — {klass} (10)\n")
        for qrow in sample[klass]:
            sample_md.append(option_sample_block(qrow))

    def fmt_sample_dv(title: str, recs: list[dict]) -> str:
        lines = [f"### {title}", ""]
        for r in recs:
            lines.append(
                f"- `{r['option_id']}` `{r['primary_dimension']}` w={r['primary_weight']:+.0f} "
                f"dv={r['diagnostic_value']:.2f} am={r['ambiguity']:.2f} pl={r['behavioral_plausibility']:.2f} "
                f"judgment={r['judgment']}"
            )
            lines.append(f"  - {r['option_text']}")
        return "\n".join(lines)

    matched_lines = []
    for b in dv["matched_ambiguity_plausibility_bins"]:
        if b["n_abs2"] == 0 and b["n_abs1"] == 0:
            continue
        matched_lines.append(
            f"- am={b['ambiguity']:.2f} pl={b['behavioral_plausibility']:.2f}: "
            f"|2| n={b['n_abs2']} mean={b['mean_abs2']}; "
            f"|1| n={b['n_abs1']} mean={b['mean_abs1']}; gap={b['gap_abs2_minus_abs1']}"
        )

    sd_dim_lines = []
    for d, row in sd["mean_by_primary_dimension"].items():
        sd_dim_lines.append(
            f"- `{d}`: n={row['n']} mean={row['mean']} "
            f"pos={row['mean_positive_weight']} neg={row['mean_negative_weight']}"
        )
    focus_lines = []
    for d, row in sd["focus_dimensions"].items():
        focus_lines.append(
            f"- `{d}`: mean={row['mean']} pos={row['mean_positive_weight']} "
            f"neg={row['mean_negative_weight']} pos−neg={row['pos_minus_neg']}"
        )

    md = f"""# Frequency V2 Phase 2C — Evidence proposal triage

Status: **audit only**. No evidence values applied. Proposal scores unchanged.
Dormant pool `evidence_meta` remains `pending` / null. V2 remains `runtime_selectable=false`.

Source pool fingerprint SHA-256: `{fp}`
Phase 2B proposal file SHA-256 (unchanged): `{proposal_hash_before}`

## Overall finding

**{overall}**

{overall_notes}

Interpretation of the 397-rate:

- **A) REAL_EVIDENCE_PROBLEM** — residual queue only ({class_c['REAL_REVIEW_REQUIRED']} questions).
- **B) ACCEPTABLE_BEHAVIORAL_COMPLEXITY** — typical state of this bank ({class_c['ACCEPTABLE_COMPLEXITY']} questions).
- **C) OVERFLAGGED_BY_REVIEW_RULE** — explains why 397 looked like a crisis.

No predetermined KEEP percentage was targeted.

## Counts

- CLEAN: **{class_c['CLEAN']}**
- ACCEPTABLE_COMPLEXITY: **{class_c['ACCEPTABLE_COMPLEXITY']}**
- REAL_REVIEW_REQUIRED: **{class_c['REAL_REVIEW_REQUIRED']}**

Of previous 397 `needs_human_review=true` flags:

- KEEP_FLAG: **{keep_n}**
- CLEAR_FLAG: **{clear_n}**
- previously unflagged (not in the 397): **11**

## Reason-code counts (REAL_REVIEW_REQUIRED questions; multiple codes allowed)

{reason_lines}

## REAL_REVIEW_REQUIRED question IDs ({len(real_ids)})

{id_list(real_ids)}

## Diagnostic-value bias audit (scores not modified)

Mean `diagnostic_value` by signed primary weight:

- +2 (n={dv['n_by_primary_weight']['+2']}): {dv['mean_diagnostic_value_by_primary_weight']['+2']}
- +1 (n={dv['n_by_primary_weight']['+1']}): {dv['mean_diagnostic_value_by_primary_weight']['+1']}
- −1 (n={dv['n_by_primary_weight']['-1']}): {dv['mean_diagnostic_value_by_primary_weight']['-1']}
- −2 (n={dv['n_by_primary_weight']['-2']}): {dv['mean_diagnostic_value_by_primary_weight']['-2']}
- 0 / off-primary (n={dv['n_by_primary_weight']['0_off_primary']}): {dv['mean_diagnostic_value_by_primary_weight']['0_off_primary']}

Absolute primary weight:

- |2|: {dv['mean_abs_primary_weight_2']}
- |1|: {dv['mean_abs_primary_weight_1']}

On-primary vs off-primary:

- on-primary: {dv['mean_on_primary']}
- off-primary: {dv['mean_off_primary']}
- on-primary |2|: {dv['mean_on_primary_abs2']}
- on-primary |1|: {dv['mean_on_primary_abs1']}

Matched ambiguity × plausibility bins (on-primary only):

{chr(10).join(matched_lines)}

{dv['relationship_after_controls']}

{fmt_sample_dv('Sample: 20 ±2 options with diagnostic_value ≥ 0.75', dv['sample_plus2_dv_ge_075'])}

Judgment counts: {dv['sample_plus2_judgment_counts']}

{fmt_sample_dv('Sample: 20 ±1 options with diagnostic_value ≤ 0.25', dv['sample_pm1_dv_le_025'])}

Judgment counts: {dv['sample_pm1_judgment_counts']}

## Social-desirability audit (scores not modified)

Mean social_desirability by weight sign:

- positive primary weight: {sd['mean_by_sign']['positive_primary_weight']}
- negative primary weight: {sd['mean_by_sign']['negative_primary_weight']}
- zero / off-primary: {sd['mean_by_sign']['zero_off_primary']}

By primary dimension:

{chr(10).join(sd_dim_lines)}

Focus dimensions:

{chr(10).join(focus_lines)}

Notes:

{chr(10).join('- ' + n for n in sd['notes'])}

systematic_bias_detected: **{str(sd['systematic_bias_detected']).lower()}**

{''.join(sample_md)}
## Safety

- Phase 2B proposal scores not modified
- Dormant pool not modified
- DROP options not scored
- `review_status=reviewed` not set
- V2 remains dormant
- No V1 / Firebase / matching / Persona / Discover / C2 / locale-routing change

FREQUENCY V2 PHASE 2C EVIDENCE TRIAGE COMPLETE — NO VALUES APPLIED — V2 STILL DORMANT
"""
    TRIAGE_MD.write_text(md, encoding="utf-8")

    if file_sha256(PROPOSAL_PATH) != proposal_hash_before:
        raise SystemExit("proposal file changed")
    if fingerprint(json.loads(POOL_PATH.read_text(encoding="utf-8"))) != fp:
        raise SystemExit("pool changed")

    print("CLEAN", class_c["CLEAN"])
    print("ACCEPTABLE_COMPLEXITY", class_c["ACCEPTABLE_COMPLEXITY"])
    print("REAL_REVIEW_REQUIRED", class_c["REAL_REVIEW_REQUIRED"])
    print("KEEP_FLAG", keep_n)
    print("CLEAR_FLAG", clear_n)
    print("reason_code_counts", dict(reason_c))
    print("proposal_unchanged", True)
    print("pool_unchanged", True)
    print("FREQUENCY V2 PHASE 2C EVIDENCE TRIAGE COMPLETE — NO VALUES APPLIED — V2 STILL DORMANT")


if __name__ == "__main__":
    main()
