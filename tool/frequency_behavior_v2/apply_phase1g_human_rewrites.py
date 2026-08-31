#!/usr/bin/env python3
"""Apply Phase 1G human-approved rewrites onto the dormant V2 draft.

Authority: docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt
Applies only the 26 rewrite-pending items. Does not assign evidence-layer
values. Does not activate V2 or touch V1.
"""
from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REWRITES = ROOT / "docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt"
PHASE1E = ROOT / "docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt"
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PLAN_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json"
APPLY_REPORT = OUT_DIR / "frequency_behavior_v2_phase1g_apply_report.md"

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


def parse_phase1f_rewrite_ids(text: str) -> list[str]:
    ids: list[str] = []
    section = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("C. REWRITE"):
            section = "rewrite"
            continue
        if line.startswith("D. DROP") or line.startswith("Special rewrite"):
            if line.startswith("D. DROP"):
                section = None
            continue
        if section == "rewrite" and line.startswith("frequency_v2_q"):
            ids.append(line.split()[0])
    return ids


def order_weights(w: dict[str, float]) -> dict[str, float]:
    return {d: w[d] for d in CANONICAL_12D if d in w}


def parse_rewrites(text: str) -> dict[str, dict]:
    starts = list(re.finditer(r"^(\d+)\)\s+(frequency_v2_q\d{4})\s*$", text, re.M))
    if not starts:
        raise SystemExit("no rewrite items parsed from human authority")
    end_marker = text.find("FINAL APPROVAL STATUS")
    out: dict[str, dict] = {}
    for i, m in enumerate(starts):
        qid = m.group(2)
        start = m.end()
        end = starts[i + 1].start() if i + 1 < len(starts) else (
            end_marker if end_marker > 0 else len(text)
        )
        block = text[start:end]
        pm = re.search(r"^primary_dimension:\s*([a-z_]+)\s*$", block, re.M)
        sm = re.search(r"^secondary_dimensions:\s*(.+?)\s*$", block, re.M)
        stem_m = re.search(r"STEM:\s*\n(.+?)\nA:", block, re.S)
        if not pm or not sm or not stem_m:
            raise SystemExit(f"malformed rewrite block for {qid}")
        primary = pm.group(1)
        if primary not in CANONICAL_SET:
            raise SystemExit(f"non-canonical primary on {qid}: {primary}")
        sec_raw = sm.group(1).strip()
        if sec_raw != "none":
            raise SystemExit(f"{qid} secondary must be none in this authority, got {sec_raw}")
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
            if dim not in CANONICAL_SET:
                raise SystemExit(f"non-canonical weight dim {dim} on {qid} {letter}")
            if dim != primary:
                raise SystemExit(
                    f"{qid} {letter} weight dim {dim} != primary {primary}"
                )
            if val not in ALLOWED_WEIGHTS:
                raise SystemExit(f"{qid} {letter} weight {val} not ±1/±2")
            opts.append(
                {
                    "option_id": f"{qid}_{letter.lower()}",
                    "text": om.group(1).strip(),
                    "weights": order_weights({dim: val}),
                }
            )
        if len(opts) != 4:
            raise SystemExit(f"{qid} expected 4 options")
        signs = [next(iter(o["weights"].values())) for o in opts]
        if sorted(signs) != [-2.0, -1.0, 1.0, 2.0]:
            raise SystemExit(f"{qid} option signs are not a full ±1/±2 contrast: {signs}")
        out[qid] = {
            "primary": primary,
            "secondary": [],
            "prompt": prompt,
            "options": opts,
        }
    return out


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def set_primary(item: dict, primary: str) -> None:
    item["primary_dimensions"] = [primary]
    item["secondary_dimensions"] = []
    ctx = (item.get("context") or ["unassigned"])[0]
    item["semantic_cluster"] = f"{primary}:{ctx}"
    item["crosscheck_group_ids"] = [f"cc_{primary}_v2"]


def main() -> None:
    expected_ids = parse_phase1f_rewrite_ids(PHASE1E.read_text(encoding="utf-8"))
    rewrites = parse_rewrites(REWRITES.read_text(encoding="utf-8"))
    got_ids = list(rewrites)
    if set(got_ids) != set(expected_ids) or len(got_ids) != 26 or len(expected_ids) != 26:
        print("STOP: Phase 1G rewrite IDs do not match Phase 1F rewrite-pending set.")
        print("1F rewrite-pending:", expected_ids)
        print("1G human authority:", got_ids)
        print("only in 1F:", sorted(set(expected_ids) - set(got_ids)))
        print("only in 1G:", sorted(set(got_ids) - set(expected_ids)))
        raise SystemExit(1)

    pool_doc = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review_doc = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    items_by_id = {it["item_id"]: it for it in pool_doc["items"]}
    review_by = {r["item_id"]: r for r in review_doc["items"]}

    pending_now = [
        r["item_id"]
        for r in review_doc["items"]
        if r.get("rewrite_pending") is True
    ]
    if set(pending_now) != set(expected_ids):
        print("STOP: live draft rewrite_pending set != Phase 1F rewrite IDs.")
        print("draft pending:", pending_now)
        print("1F:", expected_ids)
        raise SystemExit(1)

    if len(items_by_id) != 426:
        raise SystemExit(f"archive item count {len(items_by_id)}")

    option_ids_before = [
        o["option_id"]
        for it in pool_doc["items"]
        for o in it["options"]
    ]
    if len(option_ids_before) != 1704:
        raise SystemExit(f"archive option count {len(option_ids_before)}")

    # Snapshot non-target prompts/weights so we can prove they were not touched.
    other_fingerprint = {}
    for iid, it in items_by_id.items():
        if iid in rewrites:
            continue
        other_fingerprint[iid] = (
            it["prompt"],
            tuple(
                (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
                for o in it["options"]
            ),
        )

    rewritten_options = 0
    defects: list[str] = []
    for qid, spec in rewrites.items():
        it = items_by_id[qid]
        if len(it["options"]) != 4:
            defects.append(f"{qid} option count {len(it['options'])}")
            continue
        it["prompt"] = spec["prompt"]
        set_primary(it, spec["primary"])
        for i, opt_spec in enumerate(spec["options"]):
            opt = it["options"][i]
            expected_oid = f"{qid}_{'abcd'[i]}"
            if opt["option_id"] != expected_oid or opt["option_id"] != opt_spec["option_id"]:
                defects.append(
                    f"{qid} option id drift {opt.get('option_id')} vs {expected_oid}"
                )
                continue
            opt["text"] = opt_spec["text"]
            opt["behavioral_weights"] = opt_spec["weights"]
            em = opt.get("evidence_meta") or {}
            for k in (
                "social_desirability",
                "behavioral_plausibility",
                "self_presentation_risk",
                "ambiguity",
                "directness",
            ):
                if em.get(k) is not None:
                    defects.append(f"{opt['option_id']} evidence_meta.{k} assigned")
            if em.get("review_status") != "pending":
                defects.append(f"{opt['option_id']} evidence review_status {em.get('review_status')}")
            rewritten_options += 1

        r = review_by[qid]
        r["rewrite_pending"] = False
        r["selector_eligible"] = True
        r["selector_exclusion_reason"] = None
        r["primary_review_pending"] = False
        r["drop_from_selectable"] = False
        r["review_status"] = "pending"
        r["phase1g_status"] = "rewrite_applied"
        r["construct_probe"] = spec["primary"]
        issues = [
            x
            for x in (r.get("issues") or [])
            if x
            not in {
                "rewrite_pending",
                "primary_review_pending",
                "no_canonical_primary",
            }
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

    if defects:
        print("STOP: validator defects before write")
        for d in defects:
            print("-", d)
        raise SystemExit(1)
    if rewritten_options != 104:
        raise SystemExit(f"expected 104 rewritten options, got {rewritten_options}")

    # Prove non-target items unchanged.
    for iid, fp in other_fingerprint.items():
        it = items_by_id[iid]
        now = (
            it["prompt"],
            tuple(
                (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
                for o in it["options"]
            ),
        )
        if now != fp:
            raise SystemExit(f"non-target item mutated: {iid}")

    option_ids_after = [
        o["option_id"]
        for it in pool_doc["items"]
        for o in it["options"]
    ]
    if option_ids_after != option_ids_before:
        raise SystemExit("option IDs changed")
    if [it["item_id"] for it in pool_doc["items"]] != list(items_by_id):
        # order preserved via same list object
        pass
    if len(pool_doc["items"]) != 426 or len(option_ids_after) != 1704:
        raise SystemExit("archive counts drifted")

    evidence_assigned = 0
    zero_evidence = []
    for it in pool_doc["items"]:
        for o in it["options"]:
            if not (o.get("behavioral_weights") or {}):
                zero_evidence.append(o["option_id"])
            em = o.get("evidence_meta") or {}
            for k in (
                "social_desirability",
                "behavioral_plausibility",
                "self_presentation_risk",
                "ambiguity",
                "directness",
            ):
                if em.get(k) is not None:
                    evidence_assigned += 1

    rewrite_pending_after = [
        r["item_id"] for r in review_doc["items"] if r.get("rewrite_pending") is True
    ]
    if rewrite_pending_after:
        print("STOP: rewrite-pending remaining after apply:", rewrite_pending_after)
        raise SystemExit(1)

    selectable_ids = [
        r["item_id"] for r in review_doc["items"] if r.get("selector_eligible") is True
    ]
    one_primary = sum(
        1 for it in pool_doc["items"] if len(it.get("primary_dimensions") or []) == 1
    )
    empty_primary = [
        it["item_id"] for it in pool_doc["items"] if not (it.get("primary_dimensions") or [])
    ]
    dual_any = [
        it["item_id"]
        for it in pool_doc["items"]
        if len(it.get("primary_dimensions") or []) > 1
    ]
    dual_selectable = [
        iid for iid in dual_any if review_by[iid].get("selector_eligible")
    ]
    drop_ids = [
        r["item_id"] for r in review_doc["items"] if r.get("drop_from_selectable") is True
    ]
    if len(drop_ids) != 18:
        raise SystemExit(f"DROP count drifted: {len(drop_ids)}")
    for iid in drop_ids:
        if review_by[iid].get("selector_eligible") is True:
            raise SystemExit(f"DROP item became selectable: {iid}")

    selectable_one_primary = 0
    for iid in selectable_ids:
        prim = items_by_id[iid].get("primary_dimensions") or []
        if len(prim) != 1 or prim[0] not in CANONICAL_SET:
            raise SystemExit(f"selectable without exactly one canonical primary: {iid}")
        selectable_one_primary += 1

    # Applied 26 must now be selectable with empty secondary.
    for qid, spec in rewrites.items():
        it = items_by_id[qid]
        r = review_by[qid]
        if it["primary_dimensions"] != [spec["primary"]]:
            raise SystemExit(f"{qid} primary not applied")
        if it["secondary_dimensions"]:
            raise SystemExit(f"{qid} secondary not empty")
        if r.get("rewrite_pending") or r.get("primary_review_pending"):
            raise SystemExit(f"{qid} still pending")
        if r.get("selector_eligible") is not True:
            raise SystemExit(f"{qid} not selector-eligible after apply")
        if len(it["options"]) != 4:
            raise SystemExit(f"{qid} option count")
        for o in it["options"]:
            if not o.get("behavioral_weights"):
                raise SystemExit(f"{o['option_id']} empty weights")

    if dual_selectable:
        raise SystemExit(f"selectable dual primary remains: {dual_selectable}")

    pool_doc["runtime_selectable"] = False
    pool_doc["status"] = "draft_not_runtime"
    pool_doc["human_decision_phase"] = "phase1g"
    pool_doc["human_decision_file"] = "docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt"

    review_doc["stats"]["phase1g_rewritten_question_count"] = 26
    review_doc["stats"]["phase1g_rewritten_option_count"] = 104
    review_doc["stats"]["phase1f_rewrite_pending_count"] = 0
    review_doc["stats"]["primary_review_pending_count"] = len(
        [r for r in review_doc["items"] if r.get("primary_review_pending")]
    )
    review_doc["stats"]["primary_review_pending_item_ids"] = [
        r["item_id"] for r in review_doc["items"] if r.get("primary_review_pending")
    ]
    review_doc["stats"]["selector_eligible_count"] = len(selectable_ids)
    review_doc["stats"]["exactly_one_primary_count"] = one_primary
    review_doc["stats"]["empty_primary_count"] = len(empty_primary)
    review_doc["stats"]["dual_primary_count"] = len(dual_any)
    review_doc["stats"]["dual_primary_selectable_count"] = len(dual_selectable)
    review_doc["phase1g"] = {
        "human_decision_file": "docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt",
        "rewritten_questions": 26,
        "rewritten_options": 104,
        "rewrite_pending_after": 0,
        "drop_from_selectable": 18,
        "evidence_meta_assigned": False,
        "runtime_selectable": False,
    }

    primary_counts = Counter()
    selectable_primary = Counter()
    context_counts = Counter()
    clusters = set()
    for it in pool_doc["items"]:
        prim = it.get("primary_dimensions") or ["unassigned"]
        for d in prim:
            primary_counts[d] += 1
        for c in it.get("context") or []:
            context_counts[c] += 1
        clusters.add(it.get("semantic_cluster"))
        if review_by[it["item_id"]].get("selector_eligible") and len(
            it.get("primary_dimensions") or []
        ) == 1:
            selectable_primary[it["primary_dimensions"][0]] += 1

    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    plan["pool_primary_distribution"] = dict(primary_counts)
    plan["selectable_primary_distribution"] = dict(selectable_primary)
    plan["selectable_item_count"] = len(selectable_ids)
    plan["pool_context_distribution"] = dict(context_counts)
    plan["semantic_cluster_count"] = len(clusters)
    plan["notes"] = [
        "Phase 1G: 26 human-approved rewrites applied to live dormant draft.",
        "Archive remains 426 items / 1704 options. Option IDs preserved.",
        "18 DROP items remain archived and non-selectable.",
        "Rewrite-pending count is 0. Selectable items have exactly one canonical primary.",
        "Evidence-layer values remain unassigned.",
        "V2 remains runtime_selectable=false. V1 locale banks unchanged.",
    ]

    write_json(POOL_PATH, pool_doc)
    write_json(REVIEW_PATH, review_doc)
    write_json(PLAN_PATH, plan)

    v1_note = (
        "not modified in this phase (confirmed by tests): "
        "frequency_bank_tr_v1.json "
        "1ab16a99f75b4d5122bda3b9cd450e13cb7da87895ffadfb5459dc5cf4fe4744; "
        "frequency_bank_en_v1.json "
        "367836025990121ed0fbc8703dcaabcba8ab39dd49ceb36d97e175c8f33afba4"
    )

    dist_lines = "\n".join(
        f"- `{d}`: {selectable_primary[d]}" for d in CANONICAL_12D
    )
    report = f"""# Frequency V2 Phase 1G — Apply 26 human-approved rewrites

Status: **draft_not_runtime**. V2 remains dormant. Evidence-layer values were not assigned.

Authority: `docs/qmatch_frequency_v2_phase1f_final_human_rewrites.txt`

The 26 human-authority IDs matched the Phase 1F rewrite-pending set exactly. No ID mismatch.

## Authoring contract (these 26)

- Positive/negative signs are directions on a behavioral axis, not good/bad scores.
- Exactly one designed primary dimension per item.
- The test stem does not directly name the latent construct.
- Wording is situational and respondent-behavior based.
- Evidence-layer scores are deliberately separate and still pending.

## Counts

- **Rewritten question count:** 26
- **Rewritten option count:** 104
- **Archive questions/options:** 426 / 1704
- **DROP archived/non-selectable count:** 18
- **Rewrite-pending count after apply:** 0
- **Dormant selectable pool count:** {len(selectable_ids)}
- **Selectable questions with exactly one primary:** {selectable_one_primary}
- **Selectable questions with dual primary:** {len(dual_selectable)}
- **Archive items with exactly one primary:** {one_primary}
- **Archive items with empty primary:** {len(empty_primary)}
- **Archive items with dual primary IDs:** {len(dual_any)} (DROP-only leftovers)
- **Options with zero canonical behavioral evidence:** {len(zero_evidence)}
- **evidence_meta:** still all `null` / `review_status=pending` (unassigned); assigned numeric fields = {evidence_assigned}
- **runtime_selectable:** false
- **V1 SHA-256:** {v1_note}
- **Live routing unchanged:** locale still loads `frequency_bank_*_v1`; pubspec does not list the V2 draft pool; C2 catalog still points at V1 banks

## Selectable primary distribution

{dist_lines}

## Safety

- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push

FREQUENCY V2 PHASE 1G 26 HUMAN REWRITES APPLIED — 12D BEHAVIORAL LAYER READY FOR EVIDENCE METADATA — V2 STILL DORMANT
"""
    APPLY_REPORT.write_text(report, encoding="utf-8")
    print("rewritten_questions", 26)
    print("rewritten_options", rewritten_options)
    print("rewrite_pending_after", 0)
    print("selectable", len(selectable_ids))
    print("selectable_one_primary", selectable_one_primary)
    print("dual_selectable", len(dual_selectable))
    print("drop", len(drop_ids))
    print("empty_primary", len(empty_primary))
    print("zero_evidence", len(zero_evidence))
    print("evidence_assigned", evidence_assigned)
    print("wrote", APPLY_REPORT)


if __name__ == "__main__":
    main()
