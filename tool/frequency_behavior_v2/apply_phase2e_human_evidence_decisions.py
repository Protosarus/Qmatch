#!/usr/bin/env python3
"""Apply Phase 2E human 2D decisions. Authority wins over Cursor 2D.

- Proposal-only evidence corrections (ADJUST + DV_TOO_LOW)
- 10 human rewrites onto the dormant pool
- 2 new archived DROPs (q0123, q0332)
- Fresh proposal-only evidence for the 10 rewritten questions
Does not write numeric evidence_meta into the dormant pool.
Does not activate V2 or touch V1.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUTHORITY = ROOT / "docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt"
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PLAN_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json"
PROPOSAL_2B = OUT_DIR / "frequency_behavior_v2_phase2b_evidence_prior_proposal.json"
REVISED_PROPOSAL = OUT_DIR / "frequency_behavior_v2_phase2e_evidence_prior_revised_proposal.json"
FRESH_10 = OUT_DIR / "frequency_behavior_v2_phase2e_rewritten_10_evidence_proposal.json"
FRESH_10_MD = OUT_DIR / "frequency_behavior_v2_phase2e_rewritten_10_evidence_review.md"
APPLY_REPORT = OUT_DIR / "frequency_behavior_v2_phase2e_apply_report.md"

CANONICAL_12D = [
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
]
CANONICAL_SET = set(CANONICAL_12D)
ALLOWED_WEIGHTS = {-2.0, -1.0, 1.0, 2.0}
FIELDS = (
    "social_desirability",
    "obviousness",
    "behavioral_plausibility",
    "self_presentation_risk",
    "diagnostic_value",
    "ambiguity",
)
GRID = {0.00, 0.25, 0.50, 0.75, 1.00}

REWRITE_IDS = [
    "frequency_v2_q0020",
    "frequency_v2_q0026",
    "frequency_v2_q0030",
    "frequency_v2_q0035",
    "frequency_v2_q0213",
    "frequency_v2_q0317",
    "frequency_v2_q0377",
    "frequency_v2_q0393",
    "frequency_v2_q0409",
    "frequency_v2_q0410",
]
NEW_DROP_IDS = ["frequency_v2_q0123", "frequency_v2_q0332"]
KEEP_IDS = [
    "frequency_v2_q0015",
    "frequency_v2_q0156",
    "frequency_v2_q0159",
    "frequency_v2_q0186",
    "frequency_v2_q0197",
    "frequency_v2_q0278",
    "frequency_v2_q0375",
]
DV_TOO_LOW = {
    "frequency_v2_q0001_c": 0.75,
    "frequency_v2_q0006_c": 0.50,
    "frequency_v2_q0018_b": 0.75,
    "frequency_v2_q0082_b": 0.50,
    "frequency_v2_q0101_c": 0.75,
    "frequency_v2_q0105_c": 0.50,
}
DV_JUSTIFIED = [
    "frequency_v2_q0062_d",
    "frequency_v2_q0129_c",
    "frequency_v2_q0133_d",
    "frequency_v2_q0145_b",
]
CULTURAL_REWRITE = {"frequency_v2_q0213", "frequency_v2_q0377"}
OLD_FINGERPRINT = "d03b2d8c77843d72baf072219c2c0dcae07a0d093dd1bf8c5268f0ef4ca6d56d"


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


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def order_weights(w: dict[str, float]) -> dict[str, float]:
    return {d: w[d] for d in CANONICAL_12D if d in w}


def expand_oid(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("frequency_v2_"):
        return raw
    if re.fullmatch(r"q\d{4}_[abcd]", raw):
        return "frequency_v2_" + raw
    raise SystemExit(f"unrecognized option id {raw}")


def parse_adjustments(text: str) -> list[dict]:
    body = text.split("B. ADJUST EVIDENCE ONLY", 1)[1].split("C. DROP FROM SELECTABLE", 1)[0]
    rows = []
    for line in body.splitlines():
        m = re.match(
            r"^-\s+(q\d{4}_[abcd]|frequency_v2_q\d{4}_[abcd])\s+"
            r"(social_desirability|obviousness|behavioral_plausibility|"
            r"self_presentation_risk|diagnostic_value|ambiguity):\s*"
            r"([0-9.]+)\s*->\s*([0-9.]+)\s*$",
            line.strip(),
        )
        if not m:
            continue
        old, new = float(m.group(3)), float(m.group(4))
        if old not in GRID or new not in GRID:
            raise SystemExit(f"off-grid adjustment {line}")
        rows.append(
            {
                "option_id": expand_oid(m.group(1)),
                "field": m.group(2),
                "old": old,
                "new": new,
            }
        )
    if len(rows) != 23:
        raise SystemExit(f"expected 23 ADJUST field rows, got {len(rows)}")
    qids = {r["option_id"][:-2] for r in rows}
    if len(qids) != 10:
        raise SystemExit(f"expected 10 ADJUST questions, got {len(qids)}")
    if "frequency_v2_q0375" in qids:
        raise SystemExit("q0375 must not be in ADJUST")
    if "frequency_v2_q0332" in qids:
        raise SystemExit("q0332 DROP must not be in ADJUST")
    return rows


def parse_rewrites(text: str) -> dict[str, dict]:
    body = text.split("D. REWRITE REQUIRED", 1)[1].split("E. ±1 DIAGNOSTIC", 1)[0]
    starts = list(re.finditer(r"^(\d+)\)\s+(frequency_v2_q\d{4})\s*$", body, re.M))
    if len(starts) != 10:
        raise SystemExit(f"expected 10 rewrite blocks, got {len(starts)}")
    out: dict[str, dict] = {}
    for i, m in enumerate(starts):
        qid = m.group(2)
        start = m.end()
        end = starts[i + 1].start() if i + 1 < len(starts) else len(body)
        block = body[start:end]
        pm = re.search(r"^primary_dimension:\s*([a-z_]+)\s*$", block, re.M)
        sm = re.search(r"^secondary_dimensions:\s*(.+?)\s*$", block, re.M)
        stem_m = re.search(r"STEM:\s*\n(.+?)\nA:", block, re.S)
        if not pm or not sm or not stem_m:
            raise SystemExit(f"malformed rewrite block for {qid}")
        primary = pm.group(1)
        if primary not in CANONICAL_SET:
            raise SystemExit(f"non-canonical primary on {qid}: {primary}")
        if sm.group(1).strip() != "none":
            raise SystemExit(f"{qid} secondary must be none")
        prompt = stem_m.group(1).strip()
        opts = []
        for letter in "ABCD":
            om = re.search(
                rf"^{letter}:\s*(.+)\nweight:\s*([a-z_]+)\s*([+-]?\d+)\s*$",
                block,
                re.M,
            )
            if not om:
                raise SystemExit(f"missing option {letter} for {qid}")
            dim = om.group(2)
            val = float(int(om.group(3)))
            if dim != primary:
                raise SystemExit(f"{qid} {letter} weight dim {dim} != {primary}")
            if val not in ALLOWED_WEIGHTS:
                raise SystemExit(f"{qid} {letter} weight {val}")
            opts.append(
                {
                    "option_id": f"{qid}_{letter.lower()}",
                    "text": om.group(1).strip(),
                    "weights": order_weights({dim: val}),
                }
            )
        signs = [next(iter(o["weights"].values())) for o in opts]
        if sorted(signs) != [-2.0, -1.0, 1.0, 2.0]:
            raise SystemExit(f"{qid} signs {signs}")
        out[qid] = {"primary": primary, "prompt": prompt, "options": opts}
    if list(out) != REWRITE_IDS:
        raise SystemExit(f"rewrite id order mismatch {list(out)}")
    return out


def set_primary(item: dict, primary: str) -> None:
    item["primary_dimensions"] = [primary]
    item["secondary_dimensions"] = []
    ctx = (item.get("context") or ["unassigned"])[0]
    item["semantic_cluster"] = f"{primary}:{ctx}"
    item["crosscheck_group_ids"] = [f"cc_{primary}_v2"]


def score_rewritten(item: dict) -> dict:
    """Sibling-relative uncalibrated priors for a clean ±2/+1/−1/−2 rewrite.

    Ties are intentional. ±2 is not automatically more diagnostic.
    High desirability is not treated as falsehood.
    """
    qid = item["item_id"]
    primary = item["primary_dimensions"][0]
    cultural = qid in CULTURAL_REWRITE
    base = {
        "social_desirability": 0.50,
        "obviousness": 0.50,
        "behavioral_plausibility": 0.75,
        "self_presentation_risk": 0.50,
        "diagnostic_value": 0.75,
        "ambiguity": 0.25,
    }
    scored_opts = []
    for opt in item["options"]:
        w = dict(opt["behavioral_weights"])
        mag = abs(next(iter(w.values())))
        rationale = (
            "The rewritten four-way contrast is readable on the named primary; "
            "this option is a distinct pole among its siblings."
        )
        if mag == 1.0:
            rationale = (
                "A milder ±1 pole can be as informative as ±2 when the wording is specific. "
                "Diagnostic value is not taken from weight magnitude."
            )
        if cultural:
            rationale = (
                "The axis contrast is readable, but the scenario can shift across cultures. "
                "Priors stay uncalibrated and are not treated as truth or health scores."
            )
        em = {
            "version": "frequency_evidence_prior_v1",
            "calibration_status": "uncalibrated",
            "review_status": "proposed",
            **base,
            "reviewer_rationale": rationale,
        }
        scored_opts.append(
            {
                "option_id": opt["option_id"],
                "option_text": opt["text"],
                "behavioral_weights": w,
                "evidence_meta": em,
            }
        )
    quality = "MEDIUM" if cultural else "HIGH"
    needs = cultural
    reasons = ["wording_may_shift_across_cultures"] if cultural else []
    return {
        "question_id": qid,
        "primary_dimension": primary,
        "question_evidence_quality": quality,
        "needs_human_review": needs,
        "needs_human_review_reasons": reasons,
        "options": scored_opts,
    }


def main() -> None:
    authority = AUTHORITY.read_text(encoding="utf-8")
    if "HUMAN AUTHORITY" not in authority:
        raise SystemExit("missing HUMAN AUTHORITY marker")
    adjustments = parse_adjustments(authority)
    rewrites = parse_rewrites(authority)

    proposal_hash_before = file_sha256(PROPOSAL_2B)
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    proposal = json.loads(PROPOSAL_2B.read_text(encoding="utf-8"))
    fp_before = fingerprint(pool)
    if fp_before != OLD_FINGERPRINT:
        raise SystemExit(f"unexpected pre-2E fingerprint {fp_before}")
    if pool.get("runtime_selectable") is not False:
        raise SystemExit("runtime_selectable")

    items_by = {it["item_id"]: it for it in pool["items"]}
    review_by = {r["item_id"]: r for r in review["items"]}
    if len(items_by) != 426:
        raise SystemExit("archive questions")
    option_ids_before = [o["option_id"] for it in pool["items"] for o in it["options"]]
    if len(option_ids_before) != 1704:
        raise SystemExit("archive options")
    item_ids_before = [it["item_id"] for it in pool["items"]]

    existing_drop = {
        r["item_id"] for r in review["items"] if r.get("drop_from_selectable") is True
    }
    if len(existing_drop) != 18:
        raise SystemExit(f"expected 18 existing DROP, got {len(existing_drop)}")
    if set(NEW_DROP_IDS) & existing_drop:
        raise SystemExit("new DROP ids already dropped")

    other_fp = {}
    for iid, it in items_by.items():
        if iid in rewrites:
            continue
        other_fp[iid] = (
            it["prompt"],
            tuple(
                (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
                for o in it["options"]
            ),
        )
    drop_content = {
        iid: other_fp[iid]
        for iid in NEW_DROP_IDS
    }

    # --- pool: rewrites ---
    rewritten_options = 0
    for qid, spec in rewrites.items():
        it = items_by[qid]
        if len(it["options"]) != 4:
            raise SystemExit(f"{qid} option count")
        it["prompt"] = spec["prompt"]
        set_primary(it, spec["primary"])
        for i, opt_spec in enumerate(spec["options"]):
            opt = it["options"][i]
            if opt["option_id"] != opt_spec["option_id"]:
                raise SystemExit(f"option id drift {opt['option_id']}")
            opt["text"] = opt_spec["text"]
            opt["behavioral_weights"] = opt_spec["weights"]
            em = opt.get("evidence_meta") or {}
            for f in FIELDS:
                if em.get(f) is not None:
                    raise SystemExit(f"{opt['option_id']} pool evidence already numeric")
            if em.get("review_status") != "pending":
                raise SystemExit(f"{opt['option_id']} pool evidence not pending")
            rewritten_options += 1
        r = review_by[qid]
        r["rewrite_pending"] = False
        r["selector_eligible"] = True
        r["selector_exclusion_reason"] = None
        r["primary_review_pending"] = False
        r["drop_from_selectable"] = False
        r["review_status"] = "pending"
        r["phase2e_status"] = "rewrite_applied"
        r["construct_probe"] = spec["primary"]
        issues = [
            x
            for x in (r.get("issues") or [])
            if x not in {"rewrite_pending", "primary_review_pending", "no_canonical_primary"}
        ]
        r["issues"] = sorted(set(issues))
        flags = [
            f
            for f in (r.get("selector_flags") or [])
            if f
            not in {
                "rewrite_pending",
                "primary_review_pending",
                "selector_ineligible",
                "selector_eligible",
                "drop_from_selectable_pool",
            }
        ]
        flags.append("selector_eligible")
        r["selector_flags"] = flags

    if rewritten_options != 40:
        raise SystemExit(f"rewritten options {rewritten_options}")

    # --- pool: new DROPs (content preserved) ---
    for qid in NEW_DROP_IDS:
        it = items_by[qid]
        now = (
            it["prompt"],
            tuple(
                (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
                for o in it["options"]
            ),
        )
        if now != drop_content[qid]:
            raise SystemExit(f"DROP content mutated before flag {qid}")
        r = review_by[qid]
        r["drop_from_selectable"] = True
        r["selector_eligible"] = False
        r["selector_exclusion_reason"] = "drop_from_selectable_pool"
        r["rewrite_pending"] = False
        r["primary_review_pending"] = False
        r["review_status"] = "dropped_from_selectable"
        r["phase2e_status"] = "dropped_from_selectable"
        issues = [
            x
            for x in (r.get("issues") or [])
            if x not in {"rewrite_pending", "primary_review_pending"}
        ]
        if "dropped_from_selectable_pool" not in issues:
            issues.append("dropped_from_selectable_pool")
        r["issues"] = sorted(set(issues))
        flags = [
            f
            for f in (r.get("selector_flags") or [])
            if f
            not in {
                "selector_eligible",
                "selector_ineligible",
                "drop_from_selectable_pool",
                "rewrite_pending",
                "primary_review_pending",
            }
        ]
        flags.extend(["selector_ineligible", "drop_from_selectable_pool"])
        r["selector_flags"] = flags

    for iid, fp in other_fp.items():
        it = items_by[iid]
        now = (
            it["prompt"],
            tuple(
                (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
                for o in it["options"]
            ),
        )
        if now != fp:
            raise SystemExit(f"non-target item mutated: {iid}")

    option_ids_after = [o["option_id"] for it in pool["items"] for o in it["options"]]
    if option_ids_after != option_ids_before:
        raise SystemExit("option IDs changed")
    if [it["item_id"] for it in pool["items"]] != item_ids_before:
        raise SystemExit("question IDs/order changed")
    if len(pool["items"]) != 426 or len(option_ids_after) != 1704:
        raise SystemExit("archive counts drifted")

    drop_ids = [
        r["item_id"] for r in review["items"] if r.get("drop_from_selectable") is True
    ]
    if len(drop_ids) != 20:
        raise SystemExit(f"total DROP {len(drop_ids)}")
    if not set(NEW_DROP_IDS).issubset(set(drop_ids)):
        raise SystemExit("new DROP missing")
    if not existing_drop.issubset(set(drop_ids)):
        raise SystemExit("legacy DROP lost")

    selectable_ids = [
        r["item_id"] for r in review["items"] if r.get("selector_eligible") is True
    ]
    if len(selectable_ids) != 406:
        raise SystemExit(f"selectable {len(selectable_ids)}")
    rewrite_pending = [r["item_id"] for r in review["items"] if r.get("rewrite_pending")]
    if rewrite_pending:
        raise SystemExit(f"rewrite pending {rewrite_pending}")

    dual_selectable = []
    for iid in selectable_ids:
        prim = items_by[iid].get("primary_dimensions") or []
        if len(prim) != 1 or prim[0] not in CANONICAL_SET:
            raise SystemExit(f"selectable without one primary {iid}")
        if len(prim) > 1:
            dual_selectable.append(iid)
        secs = items_by[iid].get("secondary_dimensions") or []
        if iid in rewrites and secs:
            raise SystemExit(f"{iid} secondary not empty")
    if dual_selectable:
        raise SystemExit(f"selectable dual {dual_selectable}")

    for it in pool["items"]:
        for o in it["options"]:
            em = o.get("evidence_meta") or {}
            if em.get("review_status") != "pending":
                raise SystemExit(f"pool evidence not pending {o['option_id']}")
            for f in FIELDS:
                if em.get(f) is not None:
                    raise SystemExit(f"pool evidence numeric {o['option_id']} {f}")

    # --- revised proposal (396) ---
    skip = set(REWRITE_IDS) | set(NEW_DROP_IDS)
    prop_by = {q["question_id"]: q for q in proposal["items"]}
    revised_items = []
    applied_adjust = 0
    applied_dv = 0
    justified_kept = 0
    for q in proposal["items"]:
        qid = q["question_id"]
        if qid in skip:
            continue
        q2 = json.loads(json.dumps(q))
        for o in q2["options"]:
            em = o["evidence_meta"]
            oid = o["option_id"]
            for adj in adjustments:
                if adj["option_id"] != oid:
                    continue
                cur = float(em[adj["field"]])
                if abs(cur - adj["old"]) > 1e-9:
                    raise SystemExit(
                        f"{oid} {adj['field']} expected {adj['old']} got {cur}"
                    )
                em[adj["field"]] = adj["new"]
                applied_adjust += 1
            if oid in DV_TOO_LOW:
                if abs(float(em["diagnostic_value"]) - 0.25) > 1e-9:
                    raise SystemExit(f"{oid} DV not 0.25 before correction")
                em["diagnostic_value"] = DV_TOO_LOW[oid]
                applied_dv += 1
            if oid in DV_JUSTIFIED:
                if abs(float(em["diagnostic_value"]) - 0.25) > 1e-9:
                    raise SystemExit(f"{oid} DV_JUSTIFIED drifted")
                justified_kept += 1
            em["review_status"] = "proposed"
            em["calibration_status"] = "uncalibrated"
        revised_items.append(q2)

    if len(revised_items) != 396:
        raise SystemExit(f"revised proposal n={len(revised_items)}")
    if applied_adjust != 23:
        raise SystemExit(f"adjust count {applied_adjust}")
    if applied_dv != 6:
        raise SystemExit(f"dv too low count {applied_dv}")
    if justified_kept != 4:
        raise SystemExit(f"justified kept {justified_kept}")
    revised_ids = {q["question_id"] for q in revised_items}
    if revised_ids & skip:
        raise SystemExit("DROP/rewrite leaked into revised proposal")
    if "frequency_v2_q0375" not in revised_ids:
        raise SystemExit("q0375 KEEP missing from revised proposal")
    q0375 = next(q for q in revised_items if q["question_id"] == "frequency_v2_q0375")
    b = next(o for o in q0375["options"] if o["option_id"].endswith("_b"))
    if abs(float(b["evidence_meta"]["behavioral_plausibility"]) - 0.50) > 1e-9:
        raise SystemExit("q0375_b plausibility was changed")

    for q in revised_items:
        for o in q["options"]:
            em = o["evidence_meta"]
            for f in FIELDS:
                if em[f] not in GRID:
                    raise SystemExit(f"off-grid revised {o['option_id']} {f}")

    fp_after = fingerprint(pool)

    revised = {
        "schema": "qmatch_frequency_behavior_v2_phase2e_evidence_prior_revised_proposal",
        "applied_to_pool": False,
        "version": "frequency_evidence_prior_v1",
        "calibration_status": "uncalibrated",
        "review_status": "proposed",
        "human_authority": "docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt",
        "source_phase2b_proposal_sha256": proposal_hash_before,
        "source_pool_fingerprint_sha256_before": fp_before,
        "source_pool_fingerprint_sha256_after_rewrites": fp_after,
        "runtime_selectable": False,
        "selectable_question_count_in_this_file": 396,
        "excluded_new_drop_ids": NEW_DROP_IDS,
        "excluded_rewritten_ids_stale_evidence_invalidated": REWRITE_IDS,
        "question_field_corrections_applied": applied_adjust,
        "dv_too_low_corrections_applied": applied_dv,
        "dv_justified_left_unchanged": justified_kept,
        "q0375_keep_override": True,
        "items": revised_items,
    }
    write_json(REVISED_PROPOSAL, revised)

    # --- fresh 10 ---
    fresh_items = [score_rewritten(items_by[qid]) for qid in REWRITE_IDS]
    if len(fresh_items) != 10:
        raise SystemExit("fresh 10")
    if sum(len(q["options"]) for q in fresh_items) != 40:
        raise SystemExit("fresh 40")
    for q in fresh_items:
        src = items_by[q["question_id"]]
        if q["options"][0]["option_text"] != src["options"][0]["text"]:
            raise SystemExit("fresh text mismatch")
        for o in q["options"]:
            em = o["evidence_meta"]
            for f in FIELDS:
                if em[f] not in GRID:
                    raise SystemExit(f"fresh off-grid {o['option_id']}")
            if em["review_status"] != "proposed":
                raise SystemExit("fresh review_status")

    fresh = {
        "schema": "qmatch_frequency_behavior_v2_phase2e_rewritten_10_evidence_proposal",
        "applied_to_pool": False,
        "version": "frequency_evidence_prior_v1",
        "calibration_status": "uncalibrated",
        "review_status": "proposed",
        "human_authority": "docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt",
        "runtime_selectable": False,
        "question_count": 10,
        "option_count": 40,
        "stale_phase2b_evidence_invalidated": True,
        "items": fresh_items,
    }
    write_json(FRESH_10, fresh)

    def opt_block(q: dict) -> str:
        lines = [
            f"### `{q['question_id']}`",
            "",
            f"- primary_dimension: `{q['primary_dimension']}`",
            f"- question_evidence_quality: {q['question_evidence_quality']}",
            f"- needs_human_review: {str(q['needs_human_review']).lower()}",
        ]
        if q["needs_human_review"]:
            lines.append(
                "- needs_human_review_reason: "
                + ", ".join(q["needs_human_review_reasons"])
            )
        src = items_by[q["question_id"]]
        lines.append(f"- question text: {src['prompt']}")
        lines.append("")
        for letter, o in zip("ABCD", q["options"]):
            em = o["evidence_meta"]
            w = json.dumps(o["behavioral_weights"], ensure_ascii=False)
            scores = ", ".join(f"{k}={em[k]:.2f}" for k in FIELDS)
            lines.append(f"**{letter}.** `{o['option_id']}`")
            lines.append(f"- text: {o['option_text']}")
            lines.append(f"- behavioral_weight: `{w}`")
            lines.append(f"- evidence: {scores}")
            lines.append(f"- rationale: {em['reviewer_rationale']}")
            lines.append("")
        return "\n".join(lines)

    fresh_md = [
        "# Frequency V2 Phase 2E — Fresh evidence proposal for 10 rewritten questions",
        "",
        "Status: **proposal only**. Not written into dormant-pool `evidence_meta`.",
        "Old Phase 2B evidence for these 40 options is invalid.",
        "Ties are allowed. ±2 is not automatically more diagnostic.",
        "High social desirability does not mean false.",
        "",
        f"Pool fingerprint after rewrites: `{fp_after}`",
        "",
    ]
    for q in fresh_items:
        fresh_md.append(opt_block(q))
        fresh_md.append("---")
        fresh_md.append("")
    fresh_md.append("FREQUENCY V2 PHASE 2E HUMAN DECISIONS APPLIED — 10 REWRITES FRESHLY RESCORED — NO EVIDENCE VALUES APPLIED TO POOL — V2 STILL DORMANT")
    fresh_md.append("")
    FRESH_10_MD.write_text("\n".join(fresh_md), encoding="utf-8")

    # --- pool metadata / plan ---
    pool["runtime_selectable"] = False
    pool["status"] = "draft_not_runtime"
    pool["human_decision_phase"] = "phase2e"
    pool["human_decision_file"] = "docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt"

    one_primary = sum(1 for it in pool["items"] if len(it.get("primary_dimensions") or []) == 1)
    empty_primary = [it["item_id"] for it in pool["items"] if not (it.get("primary_dimensions") or [])]
    dual_any = [it["item_id"] for it in pool["items"] if len(it.get("primary_dimensions") or []) > 1]
    review["stats"]["selector_eligible_count"] = 406
    review["stats"]["phase2e_rewritten_question_count"] = 10
    review["stats"]["phase2e_rewritten_option_count"] = 40
    review["stats"]["phase2e_new_drop_count"] = 2
    review["stats"]["drop_from_selectable_count"] = 20
    review["stats"]["exactly_one_primary_count"] = one_primary
    review["stats"]["empty_primary_count"] = len(empty_primary)
    review["stats"]["dual_primary_count"] = len(dual_any)
    review["stats"]["dual_primary_selectable_count"] = 0
    review["stats"]["primary_review_pending_count"] = 0
    review["stats"]["primary_review_pending_item_ids"] = []
    review["phase2e"] = {
        "human_decision_file": "docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt",
        "keep_scores": 7,
        "adjust_evidence_only": 10,
        "rewrite_required": 10,
        "drop_from_selectable_new": 2,
        "drop_from_selectable_total": 20,
        "question_field_corrections": applied_adjust,
        "dv_too_low_corrections": applied_dv,
        "dv_justified_unchanged": justified_kept,
        "q0375_keep_override": True,
        "evidence_meta_assigned_to_pool": False,
        "runtime_selectable": False,
    }

    selectable_primary = Counter()
    for iid in selectable_ids:
        selectable_primary[items_by[iid]["primary_dimensions"][0]] += 1
    plan["selectable_item_count"] = 406
    plan["selectable_primary_distribution"] = dict(selectable_primary)
    notes = list(plan.get("notes") or [])
    notes.append(
        "Phase 2E: 10 human rewrites applied; q0123 and q0332 archived DROP; "
        "selectable=406; evidence_meta still pending/null."
    )
    plan["notes"] = notes

    write_json(POOL_PATH, pool)
    write_json(REVIEW_PATH, review)
    write_json(PLAN_PATH, plan)

    if file_sha256(PROPOSAL_2B) != proposal_hash_before:
        raise SystemExit("Phase 2B proposal file was modified")
    if fingerprint(json.loads(POOL_PATH.read_text(encoding="utf-8"))) != fp_after:
        raise SystemExit("pool fingerprint unstable after write")
    for it in json.loads(POOL_PATH.read_text(encoding="utf-8"))["items"]:
        for o in it["options"]:
            em = o.get("evidence_meta") or {}
            for f in FIELDS:
                if em.get(f) is not None:
                    raise SystemExit("pool evidence written")

    report = f"""# Frequency V2 Phase 2E — Apply human 2D decisions

Human authority: `docs/qmatch_frequency_v2_phase2d_final_human_evidence_decisions.txt`
Human authority wins over the Phase 2D Cursor packet.

## Archive / selectable

- Archive questions/options: **426 / 1704**
- Total DROP archived/non-selectable: **20**
- Dormant selectable: **406**
- Rewrite pending: **0**
- Selectable dual-primary: **0**

Legacy Phase 1F DROP (18) unchanged. New Phase 2E DROP:
- `frequency_v2_q0123` (near-duplicate of q0015)
- `frequency_v2_q0332` (near-duplicate of q0227)

## Rewrites

- 10 rewritten questions: exact human-authority match
- 40 rewritten options: exact human-authority match
- secondary_dimensions empty on all 10
- option IDs `_a/_b/_c/_d` preserved
- old Phase 2B evidence for these 10 **invalidated** (absent from revised proposal)
- new fresh evidence proposal: **10 questions / 40 options**
- fresh scores **not** written into pool `evidence_meta`

## Proposal-only evidence corrections

- human question-field corrections: **{applied_adjust}**
- six DV_TOO_LOW corrections: **{applied_dv}**
- four DV_JUSTIFIED left unchanged: **{justified_kept}**
- q0375 KEEP override: **plausibility of q0375_b remains 0.50**

Revised proposal questions: **396** (408 − 2 new DROP − 10 rewritten)

## Safety

- pool evidence_meta still pending/null
- runtime_selectable=false
- Phase 2B proposal file SHA-256 unchanged: `{proposal_hash_before}`
- pool fingerprint before: `{fp_before}`
- pool fingerprint after rewrites: `{fp_after}`
- V1 hashes unchanged (not touched)
- live routing unchanged
- C2 unchanged

FREQUENCY V2 PHASE 2E HUMAN DECISIONS APPLIED — 10 REWRITES FRESHLY RESCORED — NO EVIDENCE VALUES APPLIED TO POOL — V2 STILL DORMANT
"""
    APPLY_REPORT.write_text(report, encoding="utf-8")

    print("archive", 426, 1704)
    print("DROP", 20)
    print("selectable", 406)
    print("adjust", applied_adjust, "dv_too_low", applied_dv, "dv_justified", justified_kept)
    print("fp_after", fp_after)
    print("FREQUENCY V2 PHASE 2E HUMAN DECISIONS APPLIED — 10 REWRITES FRESHLY RESCORED — NO EVIDENCE VALUES APPLIED TO POOL — V2 STILL DORMANT")


if __name__ == "__main__":
    main()
