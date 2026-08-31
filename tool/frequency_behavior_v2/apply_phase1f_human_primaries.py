#!/usr/bin/env python3
"""Apply Phase 1F final human primary decisions onto the dormant V2 draft.

Authority: docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt
Does not change option text or 12D option weights.
Does not assign evidence-layer values. Does not activate V2 or touch V1.
"""
from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DECISIONS = ROOT / "docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt"
KEEP_SRC = (
    ROOT
    / "tool/frequency_behavior_v2/out/frequency_behavior_v2_phase1d_primary_semantic_review.md"
)
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PLAN_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json"
APPLY_REPORT = OUT_DIR / "frequency_behavior_v2_phase1f_apply_report.md"

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
DEC_RE = re.compile(
    r"^(frequency_v2_q\d{4}):\s*primary=([a-z_]+);\s*secondary=([a-z_]+|none)\s*$"
)


def parse_authority(text: str) -> dict:
    approved: dict[str, dict] = {}
    rewrite: list[str] = []
    drop: list[str] = []
    section = None
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("A. APPROVED") or line.startswith("B. APPROVED"):
            section = "approved"
            continue
        if line.startswith("C. REWRITE"):
            section = "rewrite"
            continue
        if line.startswith("D. DROP"):
            section = "drop"
            continue
        if line.startswith("E. SAFETY") or line.startswith("NEXT") or line.startswith("Special") or line.startswith("Notable") or line.startswith("Human overrides"):
            if line.startswith("E. SAFETY"):
                section = None
            continue
        if section == "approved":
            m = DEC_RE.match(line)
            if m:
                prim = m.group(2)
                sec = m.group(3)
                if prim not in CANONICAL_SET:
                    raise SystemExit(f"non-canonical primary: {line}")
                if sec != "none" and sec not in CANONICAL_SET:
                    raise SystemExit(f"non-canonical secondary: {line}")
                if prim == sec:
                    raise SystemExit(f"primary equals secondary: {line}")
                approved[m.group(1)] = {
                    "primary": prim,
                    "secondary": [] if sec == "none" else [sec],
                }
        elif section == "rewrite" and line.startswith("frequency_v2_q"):
            rewrite.append(line.split()[0])
        elif section == "drop" and line.startswith("frequency_v2_q"):
            drop.append(line.split()[0])
    if len(approved) != 54:
        raise SystemExit(f"expected 54 approved, got {len(approved)}")
    if len(rewrite) != 26:
        raise SystemExit(f"expected 26 rewrite, got {len(rewrite)}")
    if len(drop) != 18:
        raise SystemExit(f"expected 18 drop, got {len(drop)}")
    overlap = set(approved) & set(rewrite) | set(approved) & set(drop) | set(rewrite) & set(drop)
    if overlap:
        raise SystemExit(f"overlapping decision ids: {sorted(overlap)}")
    return {"approved": approved, "rewrite": rewrite, "drop": drop}


def parse_keep_named_primary(text: str) -> dict[str, str]:
    """Phase 1D KEEP compact lists: one named dominant primary per KEEP item."""
    out: dict[str, str] = {}
    body = text.split("## KEEP (compact)", 1)[1].split("## Dual-listed", 1)[0]
    current = None
    for line in body.splitlines():
        hm = re.match(r"### ([a-z_]+) \((\d+)\)", line.strip())
        if hm:
            current = hm.group(1)
            if current not in CANONICAL_SET:
                raise SystemExit(f"KEEP heading not canonical: {current}")
            continue
        if current and line.startswith("frequency_v2_q"):
            for iid in re.findall(r"frequency_v2_q\d{4}", line):
                out[iid] = current
    if len(out) != 328:
        raise SystemExit(f"expected 328 KEEP named primaries, got {len(out)}")
    return out


def set_primary_secondary(item: dict, primary: str, secondary: list[str]) -> None:
    item["primary_dimensions"] = [primary]
    item["secondary_dimensions"] = [d for d in secondary if d != primary]
    ctx = (item.get("context") or ["unassigned"])[0]
    item["semantic_cluster"] = f"{primary}:{ctx}"
    item["crosscheck_group_ids"] = [f"cc_{primary}_v2"]


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    decisions = parse_authority(DECISIONS.read_text(encoding="utf-8"))
    keep_named = parse_keep_named_primary(KEEP_SRC.read_text(encoding="utf-8"))
    approved = decisions["approved"]
    rewrite = set(decisions["rewrite"])
    drop = set(decisions["drop"])
    queue = set(approved) | rewrite | drop

    pool_doc = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review_doc = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    items_by_id = {it["item_id"]: it for it in pool_doc["items"]}
    if len(items_by_id) != 426:
        raise SystemExit(f"archive item count {len(items_by_id)}")

    collapsed_keep_dual = []
    for iid, spec in approved.items():
        it = items_by_id[iid]
        set_primary_secondary(it, spec["primary"], spec["secondary"])

    for iid in rewrite:
        it = items_by_id[iid]
        # Do not assign a final primary; do not change stem/options/weights.
        it["primary_dimensions"] = []
        it["crosscheck_group_ids"] = []

    for iid in keep_named:
        if iid in queue:
            continue
        it = items_by_id[iid]
        prims = [d for d in (it.get("primary_dimensions") or []) if d in CANONICAL_SET]
        named = keep_named[iid]
        if len(prims) > 1:
            if named not in prims:
                raise SystemExit(
                    f"KEEP named primary {named} not in stored primaries for {iid}: {prims}"
                )
            extras = [d for d in prims if d != named]
            secs = [d for d in (it.get("secondary_dimensions") or []) if d in CANONICAL_SET and d != named]
            for d in extras:
                if d not in secs:
                    secs.append(d)
            set_primary_secondary(it, named, secs)
            collapsed_keep_dual.append(iid)

    review_by = {r["item_id"]: r for r in review_doc["items"]}
    pending_primary = []
    selectable = []
    dual_selectable = []
    dual_any = []

    for r in review_doc["items"]:
        qid = r["item_id"]
        it = items_by_id[qid]
        prim = [d for d in (it.get("primary_dimensions") or []) if d in CANONICAL_SET]
        it["primary_dimensions"] = prim
        if len(prim) > 1:
            dual_any.append(qid)

        r["phase1f_status"] = (
            "approved_primary"
            if qid in approved
            else "rewrite_pending"
            if qid in rewrite
            else "drop_from_selectable"
            if qid in drop
            else "keep_existing"
        )
        r["drop_from_selectable"] = qid in drop
        r["rewrite_pending"] = qid in rewrite

        if qid in rewrite:
            r["selector_eligible"] = False
            r["selector_exclusion_reason"] = "rewrite_pending"
            r["primary_review_pending"] = True
            r["review_status"] = "rewrite_pending"
            r["construct_probe"] = None
            pending_primary.append(qid)
            issues = list(r.get("issues") or [])
            if "primary_review_pending" not in issues:
                issues.append("primary_review_pending")
            if "rewrite_pending" not in issues:
                issues.append("rewrite_pending")
            r["issues"] = sorted(set(issues))
        elif qid in drop:
            r["selector_eligible"] = False
            r["selector_exclusion_reason"] = "drop_from_selectable_pool"
            r["primary_review_pending"] = False
            r["review_status"] = "dropped_from_selectable"
            r["construct_probe"] = prim[0] if len(prim) == 1 else None
            issues = [x for x in (r.get("issues") or []) if x != "primary_review_pending"]
            if "dropped_from_selectable_pool" not in issues:
                issues.append("dropped_from_selectable_pool")
            r["issues"] = sorted(set(issues))
        else:
            one = len(prim) == 1
            r["selector_eligible"] = one
            r["selector_exclusion_reason"] = None if one else "not_exactly_one_primary"
            r["primary_review_pending"] = not one
            r["construct_probe"] = prim[0] if one else None
            if one:
                r["review_status"] = "pending"  # evidence still unassigned
                if qid in approved:
                    r["review_status"] = "pending"
                issues = [
                    x
                    for x in (r.get("issues") or [])
                    if x
                    not in {
                        "no_canonical_primary",
                        "primary_review_pending",
                        "rewrite_pending",
                    }
                ]
                r["issues"] = sorted(set(issues))
                selectable.append(qid)
            else:
                r["review_status"] = "primary_review_pending"
                pending_primary.append(qid)
                issues = list(r.get("issues") or [])
                if "no_canonical_primary" not in issues:
                    issues.append("no_canonical_primary")
                r["issues"] = sorted(set(issues))

        flags = [
            f
            for f in (r.get("selector_flags") or [])
            if f
            not in {
                "primary_review_pending",
                "rewrite_pending",
                "drop_from_selectable_pool",
                "selector_eligible",
            }
        ]
        if r.get("selector_eligible"):
            flags.append("selector_eligible")
        else:
            flags.append("selector_ineligible")
        if r.get("rewrite_pending"):
            flags.append("rewrite_pending")
        if r.get("drop_from_selectable"):
            flags.append("drop_from_selectable_pool")
        if r.get("primary_review_pending"):
            flags.append("primary_review_pending")
        r["selector_flags"] = flags

        if r.get("selector_eligible") and len(prim) != 1:
            dual_selectable.append(qid)
        if r.get("selector_eligible") and len(prim) > 1:
            dual_selectable.append(qid)

    # evidence_meta must remain null/pending
    evidence_assigned = 0
    option_total = 0
    for it in pool_doc["items"]:
        for o in it["options"]:
            option_total += 1
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

    if option_total != 1704:
        raise SystemExit(f"archive option count {option_total}")
    if evidence_assigned:
        raise SystemExit("evidence_meta was assigned; abort")
    if dual_selectable:
        raise SystemExit(f"selectable dual primary remains: {dual_selectable}")

    selectable_ids = [
        r["item_id"] for r in review_doc["items"] if r.get("selector_eligible") is True
    ]
    one_primary = sum(
        1 for it in pool_doc["items"] if len(it.get("primary_dimensions") or []) == 1
    )
    empty_primary = [
        it["item_id"] for it in pool_doc["items"] if not (it.get("primary_dimensions") or [])
    ]
    dual_remaining = [
        it["item_id"]
        for it in pool_doc["items"]
        if len(it.get("primary_dimensions") or []) > 1
    ]
    dual_remaining_selectable = [
        iid
        for iid in dual_remaining
        if review_by[iid].get("selector_eligible")
    ]

    pool_doc["runtime_selectable"] = False
    pool_doc["status"] = "draft_not_runtime"
    pool_doc["human_decision_phase"] = "phase1f"
    pool_doc["human_decision_file"] = str(
        DECISIONS.relative_to(ROOT)
    )

    review_doc["stats"]["phase1f_approved_primary_count"] = 54
    review_doc["stats"]["phase1f_rewrite_pending_count"] = 26
    review_doc["stats"]["phase1f_drop_from_selectable_count"] = 18
    review_doc["stats"]["selector_eligible_count"] = len(selectable_ids)
    review_doc["stats"]["primary_review_pending_count"] = len(pending_primary)
    review_doc["stats"]["primary_review_pending_item_ids"] = pending_primary
    review_doc["stats"]["exactly_one_primary_count"] = one_primary
    review_doc["stats"]["empty_primary_count"] = len(empty_primary)
    review_doc["stats"]["dual_primary_count"] = len(dual_remaining)
    review_doc["stats"]["dual_primary_selectable_count"] = len(dual_remaining_selectable)
    review_doc["phase1f"] = {
        "human_decision_file": "docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt",
        "approved_primary_decisions": 54,
        "rewrite_pending": 26,
        "drop_from_selectable": 18,
        "keep_dual_collapsed_to_one": len(collapsed_keep_dual),
        "evidence_meta_assigned": False,
        "runtime_selectable": False,
        "q0030_override": "uncertainty_tolerance/disclosure_pace",
        "q0033_override": "disclosure_pace/closeness_pace",
        "q0228_kept": True,
        "q0333_dropped": True,
        "q0426_dropped": True,
        "q0373_dropped": True,
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
        rev = review_by[it["item_id"]]
        if rev.get("selector_eligible") and len(it.get("primary_dimensions") or []) == 1:
            selectable_primary[it["primary_dimensions"][0]] += 1

    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    plan["pool_primary_distribution"] = dict(primary_counts)
    plan["selectable_primary_distribution"] = dict(selectable_primary)
    plan["selectable_item_count"] = len(selectable_ids)
    plan["pool_context_distribution"] = dict(context_counts)
    plan["semantic_cluster_count"] = len(clusters)
    plan["notes"] = [
        "Phase 1F: 54 approved single primaries applied; 26 rewrite-pending; 18 dropped from selector.",
        "Archive remains 426 items / 1704 options. DROP items are not deleted.",
        "Selectable items must have exactly one canonical primary_dimension.",
        "KEEP dual primary_dimensions were collapsed using Phase 1D named KEEP primary, extra ID moved to secondary.",
        "Evidence-layer values remain unassigned.",
        "V2 remains runtime_selectable=false. V1 locale banks unchanged.",
    ]

    write_json(POOL_PATH, pool_doc)
    write_json(REVIEW_PATH, review_doc)
    write_json(PLAN_PATH, plan)

    # verify overrides
    q0030 = items_by_id["frequency_v2_q0030"]
    q0033 = items_by_id["frequency_v2_q0033"]
    q0228 = items_by_id["frequency_v2_q0228"]
    if q0030["primary_dimensions"] != ["uncertainty_tolerance"]:
        raise SystemExit("q0030 primary override failed")
    if q0030["secondary_dimensions"] != ["disclosure_pace"]:
        raise SystemExit("q0030 secondary override failed")
    if q0033["primary_dimensions"] != ["disclosure_pace"]:
        raise SystemExit("q0033 primary override failed")
    if q0033["secondary_dimensions"] != ["closeness_pace"]:
        raise SystemExit("q0033 secondary override failed")
    if q0228["primary_dimensions"] != ["adaptability"]:
        raise SystemExit("q0228 primary failed")

    report = f"""# Frequency V2 Phase 1F — Apply final primary decisions

Status: **draft_not_runtime**. V2 remains dormant. Evidence-layer values were not assigned.
Question text and option weights were not rewritten in the live draft.

Authority: `docs/qmatch_frequency_v2_phase1e_final_human_primary_decisions.txt`

## Counts

- **Approved primary decisions applied:** 54
- **Rewrite-pending count:** 26
- **Drop-from-selectable count:** 18
- **Archive question IDs preserved:** 426
- **Archive option IDs preserved:** 1704
- **Selectable pool count after exclusions/pending:** {len(selectable_ids)}
- **Count with exactly one primary (archive-wide):** {one_primary}
- **Count with primary pending (rewrite_pending / not one primary):** {len(pending_primary)}
- **Count with empty primary_dimensions:** {len(empty_primary)}
- **Count with multiple stored primary IDs (archive):** {len(dual_remaining)}
- **Count with multiple stored primary IDs (selectable):** {len(dual_remaining_selectable)} (target 0)
- **KEEP dual collapsed to one named primary:** {len(collapsed_keep_dual)}
- **evidence_meta:** still all `null` / `review_status=pending` (unassigned)
- **V1 SHA-256:** not modified in this phase (confirmed by tests)
- **Live runtime:** unchanged (`runtime_selectable=false`; locale still loads `frequency_bank_*_v1`)

## Human overrides applied

- `frequency_v2_q0030`: primary=`uncertainty_tolerance`; secondary=`disclosure_pace`
- `frequency_v2_q0033`: primary=`disclosure_pace`; secondary=`closeness_pace`
- `frequency_v2_q0228` remains selector-eligible; `q0333` and `q0426` dropped as redundant
- `frequency_v2_q0373` dropped

## Selectable primary distribution

{chr(10).join(f"- `{d}`: {selectable_primary[d]}" for d in CANONICAL_12D)}

## Architecture

Selectable questions: exactly one `primary_dimension`, zero or more `secondary_dimensions`.
DROP items remain in the archive with provenance; `selector_eligible=false`.
REWRITE items keep original stem/options/weights; primary cleared; `selector_eligible=false` until human-approved rewrite.

## Safety

- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push

FREQUENCY V2 PHASE 1F FINAL PRIMARY DECISIONS APPLIED — 26 REWRITES AWAIT HUMAN APPROVAL — V2 STILL DORMANT
"""
    APPLY_REPORT.write_text(report, encoding="utf-8")
    print("approved", 54)
    print("rewrite", 26)
    print("drop", 18)
    print("selectable", len(selectable_ids))
    print("one_primary", one_primary)
    print("pending", len(pending_primary))
    print("empty_primary", len(empty_primary))
    print("dual_archive", len(dual_remaining))
    print("dual_selectable", len(dual_remaining_selectable))
    print("keep_dual_collapsed", len(collapsed_keep_dual))
    print("wrote", APPLY_REPORT)


if __name__ == "__main__":
    main()
