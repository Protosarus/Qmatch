#!/usr/bin/env python3
"""Finalize Frequency V2 evidence priors into the dormant selectable pool.

- Combine 396 Phase 2E revised scores + 9 retained rewritten scores
- Apply Phase 2E final human evidence overrides
- Archive q0409 as DROP (content preserved, evidence pending/null)
- Write reviewed numeric evidence_meta onto 405 selectable questions / 1620 options
Does not activate V2 or touch V1.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
AUTHORITY = ROOT / "docs/qmatch_frequency_v2_phase2e_final_human_evidence_review.txt"
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PLAN_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json"
PROPOSAL_2B = OUT_DIR / "frequency_behavior_v2_phase2b_evidence_prior_proposal.json"
REVISED_PROPOSAL = OUT_DIR / "frequency_behavior_v2_phase2e_evidence_prior_revised_proposal.json"
FRESH_10 = OUT_DIR / "frequency_behavior_v2_phase2e_rewritten_10_evidence_proposal.json"
FINAL_EVIDENCE = OUT_DIR / "frequency_behavior_v2_phase2f_final_evidence_prior.json"
APPLY_REPORT = OUT_DIR / "frequency_behavior_v2_phase2f_final_evidence_apply_report.md"

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
FIELDS = (
    "social_desirability",
    "obviousness",
    "behavioral_plausibility",
    "self_presentation_risk",
    "diagnostic_value",
    "ambiguity",
)
GRID = (0.00, 0.25, 0.50, 0.75, 1.00)
GRID_SET = set(GRID)

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
NEW_DROP_ID = "frequency_v2_q0409"
UNCHANGED_RETAINED_IDS = [
    "frequency_v2_q0213",
    "frequency_v2_q0377",
    "frequency_v2_q0410",
]
RETAINED_REWRITE_IDS = [qid for qid in REWRITE_IDS if qid != NEW_DROP_ID]
EXPECTED_OVERRIDE_COUNT = 33
EXPECTED_OVERRIDE_QUESTIONS = {
    "frequency_v2_q0020",
    "frequency_v2_q0026",
    "frequency_v2_q0030",
    "frequency_v2_q0035",
    "frequency_v2_q0317",
    "frequency_v2_q0393",
}
HUMAN_AUTHORITY_REL = "docs/qmatch_frequency_v2_phase2e_final_human_evidence_review.txt"
V1_TR = "1ab16a99f75b4d5122bda3b9cd450e13cb7da87895ffadfb5459dc5cf4fe4744"
V1_EN = "367836025990121ed0fbc8703dcaabcba8ab39dd49ceb36d97e175c8f33afba4"
CONTENT_FP_PHASE2E = "6acb86e18f1567890ea1c112fa54c0ffcdde2d9cda11f1c61e2ca0164d170518"


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


def on_grid(v) -> bool:
    try:
        x = float(v)
    except (TypeError, ValueError):
        return False
    return any(abs(x - g) < 1e-9 for g in GRID)


def grid_eq(a, b) -> bool:
    return abs(float(a) - float(b)) < 1e-9


def fmt_grid(v) -> str:
    x = float(v)
    for g in GRID:
        if abs(x - g) < 1e-9:
            return f"{g:.2f}"
    raise SystemExit(f"off-grid value {v}")


def mean(xs: list[float]) -> float | None:
    if not xs:
        return None
    return sum(xs) / len(xs)


def fmt_mean(v: float | None) -> str:
    if v is None:
        return "n/a"
    return f"{v:.3f}"


def expand_oid(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("frequency_v2_"):
        return raw
    if re.fullmatch(r"q\d{4}_[abcd]", raw):
        return "frequency_v2_" + raw
    raise SystemExit(f"unrecognized option id {raw}")


def parse_overrides(text: str) -> list[dict]:
    body = text.split("B. KEEP SELECTABLE — HUMAN EVIDENCE ADJUSTMENTS", 1)[1].split(
        "C. DROP FROM SELECTABLE", 1
    )[0]
    rows = []
    current_oid = None
    for line in body.splitlines():
        s = line.strip()
        header = re.fullmatch(r"(q\d{4}_[abcd]|frequency_v2_q\d{4}_[abcd]):", s)
        if header:
            current_oid = expand_oid(header.group(1))
            continue
        m = re.fullmatch(
            r"-\s+(social_desirability|obviousness|behavioral_plausibility|"
            r"self_presentation_risk|diagnostic_value|ambiguity):\s*"
            r"([0-9.]+)\s*->\s*([0-9.]+)",
            s,
        )
        if not m:
            continue
        if current_oid is None:
            raise SystemExit(f"override without option id: {s}")
        old, new = float(m.group(2)), float(m.group(3))
        if not on_grid(old) or not on_grid(new):
            raise SystemExit(f"off-grid override {s}")
        rows.append(
            {
                "option_id": current_oid,
                "field": m.group(1),
                "old": old,
                "new": new,
            }
        )
    if len(rows) != EXPECTED_OVERRIDE_COUNT:
        raise SystemExit(f"expected {EXPECTED_OVERRIDE_COUNT} override fields, got {len(rows)}")
    qids = {r["option_id"][:-2] for r in rows}
    if qids != EXPECTED_OVERRIDE_QUESTIONS:
        raise SystemExit(f"override questions drifted: {sorted(qids)}")
    return rows


def pending_evidence() -> dict:
    return {
        "version": "frequency_evidence_prior_v1",
        "calibration_status": "uncalibrated",
        "review_status": "pending",
        "social_desirability": None,
        "obviousness": None,
        "behavioral_plausibility": None,
        "self_presentation_risk": None,
        "diagnostic_value": None,
        "ambiguity": None,
    }


def pool_evidence_from_item(em: dict) -> dict:
    out = {
        "version": "frequency_evidence_prior_v1",
        "calibration_status": "uncalibrated",
        "review_status": "reviewed",
    }
    for f in FIELDS:
        if em.get(f) is None or not on_grid(em[f]):
            raise SystemExit(f"incomplete or off-grid evidence field {f}")
        out[f] = float(em[f])
    return out


def primary_weight(option: dict, primary: str) -> float | None:
    w = option.get("behavioral_weights") or {}
    if primary not in w:
        return None
    return float(w[primary])


def main() -> None:
    authority = AUTHORITY.read_text(encoding="utf-8")
    if "HUMAN AUTHORITY" not in authority:
        raise SystemExit("authority file missing HUMAN AUTHORITY")
    if "frequency_v2_q0409" not in authority:
        raise SystemExit("authority missing q0409 DROP")
    overrides = parse_overrides(authority)

    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    revised = json.loads(REVISED_PROPOSAL.read_text(encoding="utf-8"))
    fresh = json.loads(FRESH_10.read_text(encoding="utf-8"))
    proposal_2b_hash_before = file_sha256(PROPOSAL_2B)
    revised_hash_before = file_sha256(REVISED_PROPOSAL)
    fresh_hash_before = file_sha256(FRESH_10)
    fp_before = fingerprint(pool)
    if fp_before != CONTENT_FP_PHASE2E:
        raise SystemExit(f"content fingerprint drifted before 2F: {fp_before}")

    if pool.get("runtime_selectable") is not False:
        raise SystemExit("pool already runtime selectable")
    if len(pool["items"]) != 426:
        raise SystemExit("archive question count drifted")
    option_ids_before = [o["option_id"] for it in pool["items"] for o in it["options"]]
    item_ids_before = [it["item_id"] for it in pool["items"]]
    if len(option_ids_before) != 1704:
        raise SystemExit("archive option count drifted")
    items_by = {it["item_id"]: it for it in pool["items"]}
    review_by = {r["item_id"]: r for r in review["items"]}

    existing_drop = {
        r["item_id"] for r in review["items"] if r.get("drop_from_selectable") is True
    }
    if len(existing_drop) != 20:
        raise SystemExit(f"expected 20 DROP before 2F, got {len(existing_drop)}")
    if NEW_DROP_ID in existing_drop:
        raise SystemExit("q0409 already DROP")

    q0409_before = items_by[NEW_DROP_ID]
    q0409_content = (
        q0409_before["prompt"],
        tuple(
            (
                o["option_id"],
                o["text"],
                json.dumps(o["behavioral_weights"], sort_keys=True),
            )
            for o in q0409_before["options"]
        ),
    )
    q0409_option_ids = [o["option_id"] for o in q0409_before["options"]]
    if len(q0409_option_ids) != 4:
        raise SystemExit("q0409 option count")

    revised_items = revised["items"]
    if len(revised_items) != 396:
        raise SystemExit(f"revised proposal n={len(revised_items)}")
    revised_ids = {q["question_id"] for q in revised_items}
    if NEW_DROP_ID in revised_ids or any(qid in revised_ids for qid in REWRITE_IDS):
        raise SystemExit("revised proposal leaked rewrite/DROP ids")

    fresh_by = {q["question_id"]: q for q in fresh["items"]}
    if set(fresh_by) != set(REWRITE_IDS):
        raise SystemExit("fresh 10 id set drifted")
    if NEW_DROP_ID not in fresh_by:
        raise SystemExit("fresh 10 missing q0409")

    # Snapshot unchanged retained scores before mutation.
    unchanged_snapshot = {}
    for qid in UNCHANGED_RETAINED_IDS:
        unchanged_snapshot[qid] = json.loads(json.dumps(fresh_by[qid]["options"]))

    combined = []
    for q in revised_items:
        q2 = json.loads(json.dumps(q))
        for o in q2["options"]:
            em = o["evidence_meta"]
            em["version"] = "frequency_evidence_prior_v1"
            em["calibration_status"] = "uncalibrated"
            em["review_status"] = "reviewed"
        combined.append(q2)

    applied_overrides = 0
    for qid in RETAINED_REWRITE_IDS:
        q2 = json.loads(json.dumps(fresh_by[qid]))
        for o in q2["options"]:
            em = o["evidence_meta"]
            oid = o["option_id"]
            for adj in overrides:
                if adj["option_id"] != oid:
                    continue
                cur = float(em[adj["field"]])
                if not grid_eq(cur, adj["old"]):
                    raise SystemExit(
                        f"{oid} {adj['field']} expected {adj['old']} got {cur}"
                    )
                em[adj["field"]] = adj["new"]
                applied_overrides += 1
            em["version"] = "frequency_evidence_prior_v1"
            em["calibration_status"] = "uncalibrated"
            em["review_status"] = "reviewed"
        combined.append(q2)

    if applied_overrides != EXPECTED_OVERRIDE_COUNT:
        raise SystemExit(f"override apply count {applied_overrides}")

    combined_by = {q["question_id"]: q for q in combined}
    if NEW_DROP_ID in combined_by:
        raise SystemExit("q0409 leaked into final evidence")
    if len(combined_by) != 405:
        raise SystemExit(f"combined questions {len(combined_by)}")
    opt_n = sum(len(q["options"]) for q in combined)
    if opt_n != 1620:
        raise SystemExit(f"combined options {opt_n}")
    if set(RETAINED_REWRITE_IDS) - set(combined_by):
        raise SystemExit("retained rewrite missing from final")
    if set(UNCHANGED_RETAINED_IDS) - set(combined_by):
        raise SystemExit("unchanged retained missing from final")

    for qid in UNCHANGED_RETAINED_IDS:
        now_opts = {o["option_id"]: o for o in combined_by[qid]["options"]}
        for src in unchanged_snapshot[qid]:
            now = now_opts[src["option_id"]]
            for f in FIELDS:
                if not grid_eq(now["evidence_meta"][f], src["evidence_meta"][f]):
                    raise SystemExit(f"{qid} unspecified field changed: {f}")

    # Order final items to match archive order of selectable questions.
    ordered_items = []
    for it in pool["items"]:
        qid = it["item_id"]
        if qid in combined_by:
            ordered_items.append(combined_by[qid])
    if len(ordered_items) != 405:
        raise SystemExit("ordered combined count")

    for q in ordered_items:
        src = items_by[q["question_id"]]
        src_opts = {o["option_id"]: o for o in src["options"]}
        if len(q["options"]) != 4:
            raise SystemExit(f"{q['question_id']} not four options")
        for o in q["options"]:
            src_o = src_opts[o["option_id"]]
            if o["option_text"] != src_o["text"]:
                raise SystemExit(f"text mismatch {o['option_id']}")
            if json.dumps(o["behavioral_weights"], sort_keys=True) != json.dumps(
                src_o["behavioral_weights"], sort_keys=True
            ):
                raise SystemExit(f"weight mismatch {o['option_id']}")
            em = o["evidence_meta"]
            if em["version"] != "frequency_evidence_prior_v1":
                raise SystemExit(f"version {o['option_id']}")
            if em["calibration_status"] != "uncalibrated":
                raise SystemExit(f"calibration {o['option_id']}")
            if em["review_status"] != "reviewed":
                raise SystemExit(f"review_status {o['option_id']}")
            for f in FIELDS:
                if em.get(f) is None or not on_grid(em[f]):
                    raise SystemExit(f"missing/off-grid {o['option_id']} {f}")

    final_doc = {
        "schema": "qmatch_frequency_behavior_v2_phase2f_final_evidence_prior",
        "applied_to_pool": True,
        "version": "frequency_evidence_prior_v1",
        "calibration_status": "uncalibrated",
        "review_status": "reviewed",
        "human_authority": HUMAN_AUTHORITY_REL,
        "runtime_selectable": False,
        "source_phase2e_revised_proposal_sha256": revised_hash_before,
        "source_phase2e_rewritten_10_proposal_sha256": fresh_hash_before,
        "source_pool_fingerprint_sha256": fp_before,
        "selectable_question_count": 405,
        "selectable_option_count": 1620,
        "drop_question_count": 21,
        "drop_option_count": 84,
        "excluded_drop_id": NEW_DROP_ID,
        "retained_rewritten_ids": RETAINED_REWRITE_IDS,
        "unchanged_rewritten_ids": UNCHANGED_RETAINED_IDS,
        "human_override_field_change_count": applied_overrides,
        "items": ordered_items,
    }
    write_json(FINAL_EVIDENCE, final_doc)

    # --- archive q0409 as DROP, content preserved ---
    r = review_by[NEW_DROP_ID]
    r["drop_from_selectable"] = True
    r["selector_eligible"] = False
    r["selector_exclusion_reason"] = "drop_from_selectable_pool"
    r["rewrite_pending"] = False
    r["primary_review_pending"] = False
    r["review_status"] = "dropped_from_selectable"
    r["phase2f_status"] = "dropped_from_selectable"
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

    q0409_now = items_by[NEW_DROP_ID]
    q0409_after = (
        q0409_now["prompt"],
        tuple(
            (
                o["option_id"],
                o["text"],
                json.dumps(o["behavioral_weights"], sort_keys=True),
            )
            for o in q0409_now["options"]
        ),
    )
    if q0409_after != q0409_content:
        raise SystemExit("q0409 content mutated")
    if [o["option_id"] for o in q0409_now["options"]] != q0409_option_ids:
        raise SystemExit("q0409 option IDs mutated")

    # --- apply reviewed evidence to selectable options only ---
    evidence_by_oid = {}
    for q in ordered_items:
        for o in q["options"]:
            evidence_by_oid[o["option_id"]] = o

    selectable_ids = []
    drop_ids = []
    reviewed_q = 0
    reviewed_opt = 0
    pending_drop_opt = 0
    for it in pool["items"]:
        qid = it["item_id"]
        rr = review_by[qid]
        is_drop = rr.get("drop_from_selectable") is True
        if is_drop:
            drop_ids.append(qid)
            if rr.get("selector_eligible") is True:
                raise SystemExit(f"DROP still selectable {qid}")
            for o in it["options"]:
                em = o.get("evidence_meta") or {}
                if em.get("review_status") not in (None, "pending"):
                    if qid != NEW_DROP_ID and em.get("review_status") != "pending":
                        raise SystemExit(f"DROP evidence not pending before apply {o['option_id']}")
                o["evidence_meta"] = pending_evidence()
                pending_drop_opt += 1
            continue
        if rr.get("selector_eligible") is not True:
            raise SystemExit(f"non-DROP ineligible {qid}")
        selectable_ids.append(qid)
        if qid not in combined_by:
            raise SystemExit(f"selectable missing from final evidence {qid}")
        qev = combined_by[qid]
        if len(it["primary_dimensions"] or []) != 1:
            raise SystemExit(f"selectable without one primary {qid}")
        if (it["primary_dimensions"] or [None])[0] not in CANONICAL_SET:
            raise SystemExit(f"non-canonical primary {qid}")
        src_opts = {o["option_id"]: o for o in it["options"]}
        for oev in qev["options"]:
            src_o = src_opts[oev["option_id"]]
            src_o["evidence_meta"] = pool_evidence_from_item(oev["evidence_meta"])
            reviewed_opt += 1
        reviewed_q += 1

    if reviewed_q != 405 or reviewed_opt != 1620:
        raise SystemExit(f"reviewed {reviewed_q}/{reviewed_opt}")
    if pending_drop_opt != 84:
        raise SystemExit(f"pending DROP options {pending_drop_opt}")
    if len(drop_ids) != 21:
        raise SystemExit(f"DROP {len(drop_ids)}")
    if len(selectable_ids) != 405:
        raise SystemExit(f"selectable {len(selectable_ids)}")
    if NEW_DROP_ID not in drop_ids:
        raise SystemExit("q0409 not DROP")
    if not existing_drop.issubset(set(drop_ids)):
        raise SystemExit("legacy DROP lost")
    rewrite_pending = [r["item_id"] for r in review["items"] if r.get("rewrite_pending")]
    if rewrite_pending:
        raise SystemExit(f"rewrite pending {rewrite_pending}")
    dual_sel = [
        iid
        for iid in selectable_ids
        if len(items_by[iid].get("primary_dimensions") or []) != 1
    ]
    if dual_sel:
        raise SystemExit(f"selectable dual {dual_sel}")

    if [it["item_id"] for it in pool["items"]] != item_ids_before:
        raise SystemExit("question IDs/order changed")
    option_ids_after = [o["option_id"] for it in pool["items"] for o in it["options"]]
    if option_ids_after != option_ids_before:
        raise SystemExit("option IDs changed")

    fp_after = fingerprint(pool)
    if fp_after != CONTENT_FP_PHASE2E:
        raise SystemExit(f"content fingerprint changed: {fp_after}")

    # Verify DROP remain pending/null including q0409.
    for qid in drop_ids:
        for o in items_by[qid]["options"]:
            em = o["evidence_meta"]
            if em["review_status"] != "pending":
                raise SystemExit(f"DROP not pending {o['option_id']}")
            for f in FIELDS:
                if em[f] is not None:
                    raise SystemExit(f"DROP numeric {o['option_id']} {f}")

    # Verify selectable reviewed.
    for qid in selectable_ids:
        for o in items_by[qid]["options"]:
            em = o["evidence_meta"]
            if em["review_status"] != "reviewed":
                raise SystemExit(f"selectable not reviewed {o['option_id']}")
            if em["version"] != "frequency_evidence_prior_v1":
                raise SystemExit(f"selectable version {o['option_id']}")
            if em["calibration_status"] != "uncalibrated":
                raise SystemExit(f"selectable calibration {o['option_id']}")
            for f in FIELDS:
                if not on_grid(em[f]):
                    raise SystemExit(f"selectable off-grid {o['option_id']} {f}")

    # Verify human overrides landed in the pool.
    for adj in overrides:
        found = None
        for it in pool["items"]:
            for o in it["options"]:
                if o["option_id"] == adj["option_id"]:
                    found = o
                    break
            if found:
                break
        if found is None:
            raise SystemExit(f"override option missing {adj['option_id']}")
        if not grid_eq(found["evidence_meta"][adj["field"]], adj["new"]):
            raise SystemExit(f"override not applied {adj['option_id']} {adj['field']}")

    pool["runtime_selectable"] = False
    pool["status"] = "draft_not_runtime"
    pool["human_decision_phase"] = "phase2f"
    pool["human_decision_file"] = HUMAN_AUTHORITY_REL

    one_primary = sum(1 for it in pool["items"] if len(it.get("primary_dimensions") or []) == 1)
    empty_primary = [it["item_id"] for it in pool["items"] if not (it.get("primary_dimensions") or [])]
    dual_any = [it["item_id"] for it in pool["items"] if len(it.get("primary_dimensions") or []) > 1]
    review["stats"]["selector_eligible_count"] = 405
    review["stats"]["drop_from_selectable_count"] = 21
    review["stats"]["phase2f_new_drop_count"] = 1
    review["stats"]["phase2f_reviewed_question_count"] = 405
    review["stats"]["phase2f_reviewed_option_count"] = 1620
    review["stats"]["phase2f_pending_drop_option_count"] = 84
    review["stats"]["exactly_one_primary_count"] = one_primary
    review["stats"]["empty_primary_count"] = len(empty_primary)
    review["stats"]["dual_primary_count"] = len(dual_any)
    review["stats"]["dual_primary_selectable_count"] = 0
    review["stats"]["primary_review_pending_count"] = 0
    review["stats"]["primary_review_pending_item_ids"] = []
    review["phase2f"] = {
        "human_decision_file": HUMAN_AUTHORITY_REL,
        "retained_rewritten_questions": 9,
        "new_drop_ids": [NEW_DROP_ID],
        "drop_from_selectable_total": 21,
        "selectable_question_count": 405,
        "selectable_option_count": 1620,
        "human_override_field_change_count": applied_overrides,
        "evidence_meta_assigned_to_pool": True,
        "runtime_selectable": False,
        "calibration_status": "uncalibrated",
        "review_status": "reviewed",
    }

    selectable_primary = Counter()
    for iid in selectable_ids:
        selectable_primary[items_by[iid]["primary_dimensions"][0]] += 1
    plan["selectable_item_count"] = 405
    plan["selectable_primary_distribution"] = dict(selectable_primary)
    notes = list(plan.get("notes") or [])
    notes.append(
        "Phase 2F: authored evidence priors written onto 405 dormant selectable "
        "questions / 1620 options; q0409 archived DROP; DROP evidence remains pending/null."
    )
    plan["notes"] = notes

    write_json(POOL_PATH, pool)
    write_json(REVIEW_PATH, review)
    write_json(PLAN_PATH, plan)

    if file_sha256(PROPOSAL_2B) != proposal_2b_hash_before:
        raise SystemExit("Phase 2B proposal file was modified")
    if file_sha256(REVISED_PROPOSAL) != revised_hash_before:
        raise SystemExit("Phase 2E revised proposal was modified")
    if file_sha256(FRESH_10) != fresh_hash_before:
        raise SystemExit("Phase 2E rewritten-10 proposal was modified")
    reloaded = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    if fingerprint(reloaded) != CONTENT_FP_PHASE2E:
        raise SystemExit("pool fingerprint unstable after write")
    if reloaded.get("runtime_selectable") is not False:
        raise SystemExit("runtime_selectable flipped")

    # Distributions / bias audit (report only).
    dist = {f: Counter() for f in FIELDS}
    by_primary = {d: {f: [] for f in FIELDS} for d in CANONICAL_12D}
    sd_pos: list[float] = []
    sd_neg: list[float] = []
    dv_abs1: list[float] = []
    dv_abs2: list[float] = []
    same_value = {f: 0 for f in FIELDS}
    for q in ordered_items:
        primary = q["primary_dimension"]
        q_vals = {f: [] for f in FIELDS}
        for o in q["options"]:
            em = o["evidence_meta"]
            for f in FIELDS:
                v = float(em[f])
                dist[f][fmt_grid(v)] += 1
                by_primary[primary][f].append(v)
                q_vals[f].append(v)
            pw = primary_weight(o, primary)
            if pw is None:
                continue
            sd = float(em["social_desirability"])
            dv = float(em["diagnostic_value"])
            if pw > 0:
                sd_pos.append(sd)
            elif pw < 0:
                sd_neg.append(sd)
            if abs(pw) == 2.0:
                dv_abs2.append(dv)
            elif abs(pw) == 1.0:
                dv_abs1.append(dv)
        for f in FIELDS:
            if len({fmt_grid(v) for v in q_vals[f]}) == 1:
                same_value[f] += 1

    bias_notes = []
    sd50 = dist["social_desirability"]["0.50"]
    ob50 = dist["obviousness"]["0.50"]
    spr50 = dist["self_presentation_risk"]["0.50"]
    if sd50 / 1620 > 0.7:
        bias_notes.append(
            f"social_desirability is piled at 0.50 ({sd50}/1620). This is a residual "
            "uniformity from earlier priors plus limited human sibling-relative lifts; "
            "not auto-corrected."
        )
    if ob50 / 1620 > 0.7:
        bias_notes.append(
            f"obviousness is piled at 0.50 ({ob50}/1620). Report only."
        )
    if spr50 / 1620 > 0.7:
        bias_notes.append(
            f"self_presentation_risk is piled at 0.50 ({spr50}/1620). Report only."
        )
    m1 = mean(dv_abs1)
    m2 = mean(dv_abs2)
    if m1 is not None and m2 is not None:
        bias_notes.append(
            f"Mean diagnostic_value is higher for |primary weight|=2 ({fmt_mean(m2)}) "
            f"than |primary weight|=1 ({fmt_mean(m1)}). Magnitude was not a scoring rule; "
            "residual association is reported, not fixed."
        )
    mpos = mean(sd_pos)
    mneg = mean(sd_neg)
    if mpos is not None and mneg is not None and abs(mpos - mneg) >= 0.05:
        bias_notes.append(
            f"Mean social_desirability differs by primary-weight sign "
            f"(positive {fmt_mean(mpos)} vs negative {fmt_mean(mneg)}). Report only."
        )
    if not bias_notes:
        bias_notes.append(
            "No additional systematic bias beyond expected 0.50 clustering was flagged "
            "for auto-correction. None applied."
        )

    dist_md = []
    for f in FIELDS:
        dist_md.append(f"### {f}")
        dist_md.append("")
        for g in GRID:
            dist_md.append(f"- {g:.2f}: {dist[f][f'{g:.2f}']}")
        dist_md.append("")

    primary_md = []
    for d in CANONICAL_12D:
        cells = ", ".join(
            f"{f}={fmt_mean(mean(by_primary[d][f]))}" for f in FIELDS
        )
        n = len(by_primary[d]["social_desirability"])
        primary_md.append(f"- `{d}` (n={n} options): {cells}")

    report = f"""# Frequency V2 Phase 2F — Finalize evidence priors into dormant pool

Status: **applied to dormant selectable pool only**. V2 remains `runtime_selectable=false`.
All values are **uncalibrated reviewer priors**, not validated coefficients,
truth/lie probabilities, personality probabilities, or empirical discrimination.

Human authority: `{HUMAN_AUTHORITY_REL}`

Content fingerprint SHA-256 (text/weights; unchanged): `{fp_after}`

## Counts

- Archive questions: **426**
- Archive options: **1704**
- DROP questions: **21**
- DROP options: **84**
- Dormant selectable questions: **405**
- Dormant selectable options: **1620**
- Reviewed evidence questions: **405**
- Reviewed evidence options: **1620**
- Pending/null DROP options: **84**
- rewrite_pending: **0**
- selectable dual-primary: **0**

## Combined evidence dataset

- From Phase 2E revised proposal: **396** questions (unspecified scores unchanged)
- From Phase 2E rewritten-10 proposal, retained: **9** questions
- Excluded: `frequency_v2_q0409`
- Human override field-change count: **{applied_overrides}**
- Unchanged retained rewritten evidence: `q0213`, `q0377`, `q0410`

Final file: `tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2f_final_evidence_prior.json`

## Human overrides applied

All six listed questions received only the explicit `0.50 -> 0.75` lifts on
`social_desirability`, `obviousness`, and `self_presentation_risk`:

- `frequency_v2_q0020_b` (3)
- `frequency_v2_q0026_a`, `frequency_v2_q0026_b` (6)
- `frequency_v2_q0030_a`, `frequency_v2_q0030_b` (6)
- `frequency_v2_q0035_b`, `frequency_v2_q0035_c` (6)
- `frequency_v2_q0317_a`, `frequency_v2_q0317_b` (6)
- `frequency_v2_q0393_a`, `frequency_v2_q0393_b` (6)

Total: **33** field changes. No unspecified score was modified.

## q0409 archive DROP

- Question and option IDs preserved
- Text, weights, and provenance preserved
- `selector_eligible=false`, `drop_from_selectable=true`
- evidence_meta remains pending/null (no numeric values)
- Not deleted

## Pool evidence_meta

Selectable (1620 options):

- `version`: `frequency_evidence_prior_v1`
- `calibration_status`: `uncalibrated`
- `review_status`: `reviewed`
- all six numeric fields present and on the 0.00/0.25/0.50/0.75/1.00 grid

DROP (84 options, including q0409): pending/null

## Evidence-field value distributions (1620 selectable options)

{chr(10).join(dist_md)}
## Same-value siblings (all four options identical on a field)

- `social_desirability`: {same_value['social_desirability']} questions
- `obviousness`: {same_value['obviousness']} questions
- `behavioral_plausibility`: {same_value['behavioral_plausibility']} questions
- `self_presentation_risk`: {same_value['self_presentation_risk']} questions
- `diagnostic_value`: {same_value['diagnostic_value']} questions
- `ambiguity`: {same_value['ambiguity']} questions

## Mean evidence fields by primary dimension

{chr(10).join(primary_md)}

## Mean social_desirability by primary weight sign

- positive primary weight: {fmt_mean(mpos)} (n={len(sd_pos)})
- negative primary weight: {fmt_mean(mneg)} (n={len(sd_neg)})

## Mean diagnostic_value for |primary weight| = 1 vs 2

- abs(primary weight)=1: {fmt_mean(m1)} (n={len(dv_abs1)})
- abs(primary weight)=2: {fmt_mean(m2)} (n={len(dv_abs2)})

## Suspicious systematic bias (reported only; not auto-corrected)

{chr(10).join(f'- {n}' for n in bias_notes)}

High social desirability does not mean false. Weight sign is not health or maturity.
`discrimination_power` was not authored.

## Safety

- `runtime_selectable` remains false
- V1 hashes unchanged
- locale/live routing unchanged
- no Firebase / C2 / Discover / Persona / matching changes
- no 12D→6D adapter
- no activation

FREQUENCY V2 PHASE 2F FINAL EVIDENCE PRIORS APPLIED TO 405 DORMANT SELECTABLE QUESTIONS — V2 STILL DORMANT
"""
    APPLY_REPORT.write_text(report, encoding="utf-8")

    v1_tr = file_sha256(ROOT / "assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json")
    v1_en = file_sha256(ROOT / "assets/data/assessment_v3/frequency/frequency_bank_en_v1.json")
    if v1_tr != V1_TR or v1_en != V1_EN:
        raise SystemExit("V1 bank hash changed")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if "frequency_behavior_pool_tr_v2" in pubspec:
        raise SystemExit("pubspec references V2 pool")

    print(
        "FREQUENCY V2 PHASE 2F FINAL EVIDENCE PRIORS APPLIED TO 405 DORMANT "
        "SELECTABLE QUESTIONS — V2 STILL DORMANT"
    )
    print(f"overrides={applied_overrides} selectable=405 drop=21 pending_drop_opts=84")
    print(f"final_evidence={FINAL_EVIDENCE}")
    print(f"report={APPLY_REPORT}")


if __name__ == "__main__":
    main()
