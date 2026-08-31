#!/usr/bin/env python3
"""Apply Phase 1C approved human 12D decisions onto the dormant V2 draft.

Reads docs/qmatch_frequency_v2_phase1b_human_decisions.txt as authority.
Does not write live Frequency V1 banks, pubspec, or runtime routing.
Does not assign evidence-layer values. Does not invent 12D→6D maps.
"""
from __future__ import annotations

import json
import re
from collections import Counter
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DECISIONS = ROOT / "docs/qmatch_frequency_v2_phase1b_human_decisions.txt"
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PLAN_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json"
APPLY_REPORT = OUT_DIR / "frequency_behavior_v2_phase1c_apply_report.md"
PRIMARY_REPORT = OUT_DIR / "frequency_behavior_v2_primary_semantic_review.md"

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
DROPPED_LABELS = {
    "processing_style",
    "conflict_approach",
    "baseline",
    "reciprocity",
    "trust",
}
WEIGHT_RE = re.compile(
    r"^(frequency_v2_q\d{4}_[a-d])\s*=\s*(.+)$"
)
DIM_W_RE = re.compile(r"([a-z_]+)\s*([+-]?\d+)")


def parse_weight_list(blob: str) -> dict[str, float]:
    out: dict[str, float] = {}
    for dim, num in DIM_W_RE.findall(blob.strip()):
        if dim not in CANONICAL_SET:
            raise ValueError(f"non-canonical dimension in decision: {dim} ({blob})")
        out[dim] = float(int(num))
    if not out:
        raise ValueError(f"no weights parsed from: {blob}")
    return order_weights(out)


def order_weights(w: dict[str, float]) -> dict[str, float]:
    return {d: w[d] for d in CANONICAL_12D if d in w}


def parse_decisions(text: str) -> dict:
    option_weights: dict[str, dict[str, float]] = {}
    stem_rewrites: dict[str, dict] = {}
    option_rewrites: dict[str, dict] = {}

    # A + B exact option weights
    in_ab = False
    for line in text.splitlines():
        if line.startswith("A. CLEAR_REMAP") or line.startswith("B. HUMAN_DECISION"):
            in_ab = True
            continue
        if line.startswith("C. STEM REWRITES") or line.startswith("D. SINGLE-OPTION"):
            in_ab = False
        if not in_ab:
            continue
        m = WEIGHT_RE.match(line.strip())
        if m:
            option_weights[m.group(1)] = parse_weight_list(m.group(2))

    # C stems
    stem_blocks = re.split(r"\n(?=\d+\)\s+frequency_v2_q\d{4}\n)", text)
    for block in stem_blocks:
        hm = re.search(r"(\d+)\)\s+(frequency_v2_q\d{4})\n", block)
        if not hm or "FINAL QUESTION:" not in block:
            continue
        qid = hm.group(2)
        q_m = re.search(
            r"FINAL QUESTION:\n(.+?)\n\nA:",
            block,
            re.S,
        )
        if not q_m:
            raise ValueError(f"missing FINAL QUESTION for {qid}")
        prompt = q_m.group(1).strip()
        opts = []
        for letter in "ABCD":
            om = re.search(
                rf"{letter}:\s*(.+?)\nweights:\s*(.+)",
                block,
            )
            if not om:
                raise ValueError(f"missing option {letter} for {qid}")
            oid = f"{qid}_{letter.lower()}"
            w = parse_weight_list(om.group(2))
            opts.append({"option_id": oid, "text": om.group(1).strip(), "weights": w})
            option_weights[oid] = w
        stem_rewrites[qid] = {"prompt": prompt, "options": opts}

    # D single-option rewrites
    d_sec = text.split("D. SINGLE-OPTION REWRITES", 1)[1].split("E. UNKNOWN", 1)[0]
    for m in re.finditer(
        r"(frequency_v2_q\d{4}_[a-d])\nFINAL OPTION:\n(.+?)\nweights:\s*(.+)",
        d_sec,
    ):
        oid = m.group(1)
        w = parse_weight_list(m.group(3))
        option_rewrites[oid] = {"text": m.group(2).strip(), "weights": w}
        option_weights[oid] = w

    if len(option_weights) < 19 + 37:
        raise ValueError(f"too few A/B weights: {len(option_weights)}")
    if len(stem_rewrites) != 4:
        raise ValueError(f"expected 4 stem rewrites, got {len(stem_rewrites)}")
    if len(option_rewrites) != 4:
        raise ValueError(f"expected 4 option rewrites, got {len(option_rewrites)}")
    return {
        "option_weights": option_weights,
        "stem_rewrites": stem_rewrites,
        "option_rewrites": option_rewrites,
    }


def weights_equal(a: dict, b: dict) -> bool:
    if set(a) != set(b):
        return False
    return all(float(a[k]) == float(b[k]) for k in a)


def fmt_w(w: dict) -> str:
    if not w:
        return "(none)"
    parts = []
    for k, v in order_weights({k: float(v) for k, v in w.items()}).items():
        iv = int(v) if float(v) == int(v) else v
        sign = "+" if v > 0 else ""
        parts.append(f"{k} {sign}{iv}")
    return ", ".join(parts)


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def apply() -> dict:
    decisions = parse_decisions(DECISIONS.read_text(encoding="utf-8"))
    pool_doc = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    review_doc = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    items_by_id = {it["item_id"]: it for it in pool_doc["items"]}
    review_by_id = {r["item_id"]: r for r in review_doc["items"]}

    changed_weight_oids: list[str] = []
    stem_rewritten: list[str] = []
    option_text_rewritten: list[str] = []
    missing_oids: list[str] = []

    # 1. full-stem rewrites (text + weights)
    for qid, spec in decisions["stem_rewrites"].items():
        it = items_by_id[qid]
        it["prompt"] = spec["prompt"]
        by_oid = {o["option_id"]: o for o in spec["options"]}
        for opt in it["options"]:
            src = by_oid[opt["option_id"]]
            if opt["text"] != src["text"]:
                option_text_rewritten.append(opt["option_id"])
            opt["text"] = src["text"]
            before = {k: float(v) for k, v in (opt.get("behavioral_weights") or {}).items()}
            after = src["weights"]
            if not weights_equal(before, after):
                changed_weight_oids.append(opt["option_id"])
            opt["behavioral_weights"] = after
        stem_rewritten.append(qid)

    # 2. single-option text rewrites
    for oid, spec in decisions["option_rewrites"].items():
        qid = oid.rsplit("_", 1)[0]
        it = items_by_id[qid]
        opt = next(o for o in it["options"] if o["option_id"] == oid)
        if opt["text"] != spec["text"]:
            if oid not in option_text_rewritten:
                option_text_rewritten.append(oid)
        opt["text"] = spec["text"]
        before = {k: float(v) for k, v in (opt.get("behavioral_weights") or {}).items()}
        after = spec["weights"]
        if not weights_equal(before, after) and oid not in changed_weight_oids:
            changed_weight_oids.append(oid)
        opt["behavioral_weights"] = after

    # 3. remaining exact option weights from A/B (stems already applied)
    for oid, w in decisions["option_weights"].items():
        qid = oid.rsplit("_", 1)[0]
        it = items_by_id.get(qid)
        if it is None:
            missing_oids.append(oid)
            continue
        opt = next((o for o in it["options"] if o["option_id"] == oid), None)
        if opt is None:
            missing_oids.append(oid)
            continue
        before = {k: float(v) for k, v in (opt.get("behavioral_weights") or {}).items()}
        if not weights_equal(before, w):
            if oid not in changed_weight_oids:
                changed_weight_oids.append(oid)
        opt["behavioral_weights"] = w

    if missing_oids:
        raise SystemExit(f"missing option ids in pool: {missing_oids}")

    # 4. drop leftover unknown labels from review metadata; do not invent primaries
    dropped_label_events = 0
    processing_remaining_weights = 0
    unknown_remaining: Counter = Counter()
    pending_primary: list[str] = []
    historically_processing: list[str] = []

    for r in review_doc["items"]:
        qid = r["item_id"]
        it = items_by_id[qid]
        hist = bool(r.get("processing_style_present")) or "processing_style" in (
            r.get("source_primary_raw") or []
        ) + (r.get("source_secondary_raw") or [])
        if hist:
            historically_processing.append(qid)
        r["processing_style_source_present"] = hist

        for orev in r.get("options") or []:
            kept = []
            for uw in orev.get("unresolved_weights") or []:
                dim = uw.get("dimension")
                if dim in DROPPED_LABELS:
                    dropped_label_events += 1
                    continue
                kept.append(uw)
                if dim == "processing_style":
                    processing_remaining_weights += 1
                elif dim not in CANONICAL_SET:
                    unknown_remaining[dim] += 1
            orev["unresolved_weights"] = kept

        unresolved = []
        for lab in r.get("unresolved_dimension_labels") or []:
            if lab in DROPPED_LABELS:
                dropped_label_events += 1
                continue
            unresolved.append(lab)
            if lab not in CANONICAL_SET:
                unknown_remaining[lab] += 1
        r["unresolved_dimension_labels"] = unresolved
        r["processing_style_present"] = any(
            (uw.get("dimension") == "processing_style")
            for orev in r.get("options") or []
            for uw in orev.get("unresolved_weights") or []
        ) or ("processing_style" in unresolved)

        # primary: keep existing 12D primary; mark empty as pending
        prim = list(it.get("primary_dimensions") or [])
        valid_primary = [d for d in prim if d in CANONICAL_SET]
        it["primary_dimensions"] = valid_primary
        if not valid_primary:
            r["primary_review_pending"] = True
            pending_primary.append(qid)
            issues = [x for x in (r.get("issues") or []) if x != "processing_style_manual_review"]
            if "no_canonical_primary" not in issues:
                issues.append("no_canonical_primary")
            if "primary_review_pending" not in issues:
                issues.append("primary_review_pending")
            r["issues"] = sorted(set(issues))
            r["review_status"] = "primary_review_pending"
            r["construct_probe"] = None
        else:
            r["primary_review_pending"] = False
            issues = [
                x
                for x in (r.get("issues") or [])
                if x
                not in {
                    "processing_style_manual_review",
                    "unknown_or_blocked_dimension_labels",
                    "option_missing_canonical_weights",
                    "primary_review_pending",
                }
            ]
            # drop no_canonical_primary if we now have one
            if valid_primary:
                issues = [x for x in issues if x != "no_canonical_primary"]
            empty_opt = any(not o.get("behavioral_weights") for o in it["options"])
            if empty_opt:
                issues.append("option_missing_canonical_weights")
            r["issues"] = sorted(set(issues))
            if r["processing_style_present"] or r["unresolved_dimension_labels"]:
                r["review_status"] = "manual_review"
            elif r["issues"]:
                r["review_status"] = "manual_review"
            else:
                r["review_status"] = "pending"
            r["construct_probe"] = valid_primary[0]

        flags = list(r.get("selector_flags") or [])
        flags = [f for f in flags if f != "primary_review_pending"]
        if r.get("primary_review_pending"):
            flags.append("primary_review_pending")
        r["selector_flags"] = flags

    # pool header: still dormant
    pool_doc["runtime_selectable"] = False
    pool_doc["status"] = "draft_not_runtime"
    pool_doc["human_decision_phase"] = "phase1c"
    pool_doc["human_decision_file"] = "docs/qmatch_frequency_v2_phase1b_human_decisions.txt"

    # remaining unknown labels in pool weights
    dims_used = set()
    zero_evidence_options = []
    unscorable_questions = []
    leaked = []
    for it in pool_doc["items"]:
        scorable = 0
        for o in it["options"]:
            w = o.get("behavioral_weights") or {}
            for k in w:
                if k not in CANONICAL_SET:
                    leaked.append(f"{o['option_id']}:{k}")
                else:
                    dims_used.add(k)
            if not w:
                zero_evidence_options.append(o["option_id"])
            else:
                scorable += 1
        if scorable == 0:
            unscorable_questions.append(it["item_id"])

    review_doc["stats"]["processing_style_item_count"] = sum(
        1 for r in review_doc["items"] if r.get("processing_style_present")
    )
    review_doc["stats"]["processing_style_source_item_count"] = len(historically_processing)
    review_doc["stats"]["processing_style_source_item_ids"] = historically_processing
    review_doc["stats"]["unknown_labels"] = dict(unknown_remaining)
    review_doc["stats"]["phase1c_dropped_legacy_label_events"] = dropped_label_events
    review_doc["stats"]["primary_review_pending_count"] = len(pending_primary)
    review_doc["stats"]["primary_review_pending_item_ids"] = pending_primary
    review_doc["phase1c"] = {
        "human_decision_file": "docs/qmatch_frequency_v2_phase1b_human_decisions.txt",
        "option_weight_sets_changed": len(changed_weight_oids),
        "full_stems_rewritten": len(stem_rewritten),
        "individual_options_rewritten": 4,
        "evidence_meta_assigned": False,
        "runtime_selectable": False,
    }

    # selector plan
    primary_counts = Counter()
    context_counts = Counter()
    clusters = set()
    for it in pool_doc["items"]:
        for d in it["primary_dimensions"] or ["unassigned"]:
            primary_counts[d] += 1
        for c in it.get("context") or []:
            context_counts[c] += 1
        clusters.add(it.get("semantic_cluster"))
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    plan["pool_primary_distribution"] = dict(primary_counts)
    plan["pool_context_distribution"] = dict(context_counts)
    plan["semantic_cluster_count"] = len(clusters)
    plan["notes"] = [
        "Phase 1C applied: processing_style leftovers rescored or dropped; unknown labels dropped.",
        "Items with empty or pending primary are not selected; primaries are not inferred from abs-mass.",
        "V1 sessions remain bound to frequency_bank_*_v1 via existing locale+bank_version persistence.",
        "V2 remains runtime_selectable=false.",
    ]

    write_json(POOL_PATH, pool_doc)
    write_json(REVIEW_PATH, review_doc)
    write_json(PLAN_PATH, plan)

    # apply report
    apply_lines = [
        "# Frequency V2 Phase 1C — Apply approved 12D decisions",
        "",
        "Status: **draft_not_runtime**. V2 remains dormant. Evidence-layer values were not assigned.",
        "",
        f"Authority: `{DECISIONS.relative_to(ROOT)}`",
        "If this file differed from the Phase 1B packet, the human file won.",
        "",
        "## Counts",
        "",
        f"- **Option weight sets changed:** {len(changed_weight_oids)}",
        f"- **Full stems rewritten:** {len(stem_rewritten)} (`{', '.join(stem_rewritten)}`)",
        f"- **Individual options rewritten:** {len(decisions['option_rewrites'])} (`{', '.join(decisions['option_rewrites'])}`)",
        f"- **Legacy/unknown labels remaining (review unresolved):** {dict(unknown_remaining) or '{}'}",
        f"- **processing_style weights remaining (option unresolved_weights):** {processing_remaining_weights}",
        f"- **12D dimensions used in pool behavioral_weights:** {', '.join(d for d in CANONICAL_12D if d in dims_used)}",
        f"- **Options with zero canonical behavioral evidence:** {len(zero_evidence_options)}{(' — ' + ', '.join(zero_evidence_options)) if zero_evidence_options else ''}",
        f"- **Questions with no scorable options:** {len(unscorable_questions)}{(' — ' + ', '.join(unscorable_questions)) if unscorable_questions else ''}",
        f"- **Questions with pending primary review:** {len(pending_primary)}",
        "- **evidence_meta:** still all `null` / `review_status=pending` (unassigned)",
        "- **V1 SHA-256:** not modified in this phase (confirmed by tests)",
        "- **Live runtime:** unchanged (locale still loads `frequency_bank_*_v1`; `runtime_selectable=false`)",
        f"- **Non-canonical weight leaks in pool JSON:** {len(leaked)}{(' — ' + ', '.join(leaked)) if leaked else ''}",
        "",
        "## repair_style orientation (enforced as documentation, not a moral score)",
        "",
        "- `+2` = immediate / active repair engagement",
        "- `+1` = mildly active repair / constructive revisit",
        "- `-1` = delayed / partial / mixed repair, often pause-then-return",
        "- `-2` = blocked / withdrawn / shut-down repair with no explicit return in the option",
        "",
        "Negative values are a pacing/engagement direction, not unhealthy/toxic/bad.",
        "",
        "## Stem rewrites applied",
        "",
    ]
    for qid in stem_rewritten:
        spec = decisions["stem_rewrites"][qid]
        apply_lines.append(f"### `{qid}`")
        apply_lines.append("")
        apply_lines.append(spec["prompt"])
        apply_lines.append("")
        for o in spec["options"]:
            apply_lines.append(f"- `{o['option_id']}`: {o['text']}")
            apply_lines.append(f"  - {fmt_w(o['weights'])}")
        apply_lines.append("")
    apply_lines += [
        "## Single-option rewrites applied",
        "",
    ]
    for oid, spec in decisions["option_rewrites"].items():
        apply_lines.append(f"- `{oid}`: {spec['text']}")
        apply_lines.append(f"  - {fmt_w(spec['weights'])}")
    apply_lines += [
        "",
        "## Option IDs whose canonical weights changed",
        "",
    ]
    for oid in changed_weight_oids:
        apply_lines.append(f"- `{oid}` → {fmt_w(decisions['option_weights'][oid])}")
    apply_lines += [
        "",
        "## Safety",
        "",
        "- Source pool text file not modified",
        "- Frequency V1 banks not modified",
        "- pubspec.yaml not modified",
        "- Live locale routing not modified",
        "- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified",
        "- No 12D→6D map",
        "- No Firebase deploy",
        "- No commit/push",
        "",
        "FREQUENCY V2 PHASE 1C APPROVED 12D DECISIONS APPLIED — V2 STILL DORMANT",
        "",
    ]
    APPLY_REPORT.write_text("\n".join(apply_lines), encoding="utf-8")

    # primary semantic review — no mass-derived assignment
    prim_lines = [
        "# Frequency V2 — semantic primary-dimension review",
        "",
        "Phase 1C did **not** auto-set `primary_dimensions` from absolute-weight mass.",
        "The 30 Phase 1B packet leads were **not** applied.",
        "",
        "Rule:",
        "",
        "1. Keep a clearly valid existing 12D `primary_dimensions` value.",
        "2. If primary is missing (empty), mark `primary_review_pending` in developer review metadata.",
        "3. Selector eligibility must not depend on an invented primary.",
        "",
        f"**Pending count:** {len(pending_primary)}",
        "",
        "## Pending items",
        "",
    ]
    for qid in pending_primary:
        it = items_by_id[qid]
        r = review_by_id[qid]
        used = Counter()
        for o in it["options"]:
            for k, v in (o.get("behavioral_weights") or {}).items():
                used[k] += abs(float(v))
        mass_hint = ", ".join(f"{k} abs={int(v) if v==int(v) else v}" for k, v in used.most_common())
        prim_lines.append(f"### `{qid}`")
        prim_lines.append("")
        prim_lines.append(f"- Prompt: {it['prompt']}")
        prim_lines.append(f"- Source primary raw: {r.get('source_primary_raw')}")
        prim_lines.append(f"- Source secondary raw: {r.get('source_secondary_raw')}")
        prim_lines.append(f"- Current pool primary: {it.get('primary_dimensions') or '(empty)'}")
        prim_lines.append(
            f"- Option 12D abs-mass (review hint only, **not assigned**): {mass_hint or '(none)'}"
        )
        prim_lines.append("- Status: `primary_review_pending`")
        prim_lines.append("")
    prim_lines += [
        "## Not pending",
        "",
        "All other items kept their existing canonical 12D primary (including items that gained new option-level dimensions such as `repair_style`). Those new option weights do not rewrite item primary in this phase.",
        "",
        "Selector: items with empty primary or `primary_review_pending=true` are excluded from production-like 50-draws. That is a missing-primary gate, not a guessed-primary assignment.",
        "",
    ]
    PRIMARY_REPORT.write_text("\n".join(prim_lines), encoding="utf-8")

    return {
        "changed_weights": len(changed_weight_oids),
        "stems": len(stem_rewritten),
        "option_rewrites": len(decisions["option_rewrites"]),
        "unknown_remaining": dict(unknown_remaining),
        "processing_remaining_weights": processing_remaining_weights,
        "dims_used": sorted(dims_used),
        "zero_evidence": zero_evidence_options,
        "unscorable": unscorable_questions,
        "pending_primary": pending_primary,
        "leaked": leaked,
        "ab_plus_rewrite_oids": len(decisions["option_weights"]),
    }


if __name__ == "__main__":
    stats = apply()
    print(json.dumps(stats, ensure_ascii=False, indent=2))
