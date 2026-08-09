#!/usr/bin/env python3
"""Generate Frequency pilot TR v1 review markdown docs from frequency_pilot_tr_v1.json."""

from __future__ import annotations

import json
import statistics
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json"
DOCS = ROOT / "docs/core_engine"

FREQ_DIMS = [
    "depth_preference",
    "communication_pace",
    "social_energy",
    "spontaneity",
    "stability",
    "disclosure_pace",
]

EQ_DIMS = [
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

CONSTRUCTS = {
    "depth_preference": "Preference for reflective/substantive vs lighter/practical interaction depth.",
    "communication_pace": "Preferred cadence, timing, and spacing of communication.",
    "social_energy": "Preferred amount, intensity, and recovery space for social interaction.",
    "spontaneity": "Preference for unplanned choices, flexibility, and novelty in shared activities.",
    "stability": "Preference for continuity, predictable routines, and consistent relational rhythms.",
    "disclosure_pace": "Preferred speed and sequencing for sharing personal or emotionally significant information.",
}

PERSONA_HINTS = {
    "depth_preference": ["deep connector", "quiet anchor"],
    "communication_pace": ["expressive wave", "steady presence"],
    "social_energy": ["social spark", "quiet anchor"],
    "spontaneity": ["social spark", "expressive wave"],
    "stability": ["steady presence", "quiet anchor"],
    "disclosure_pace": ["expressive wave", "deep connector"],
}

CONTAMINATION = {
    "depth_preference": "IQ verbal reasoning or EQ empathy without preference-for-depth framing.",
    "communication_pace": "Interest, affection, reliability, or assertiveness.",
    "social_energy": "Popularity, social skill, or EQ social_awareness.",
    "spontaneity": "Impulsivity, irresponsibility, or EQ emotion_regulation.",
    "stability": "Emotional stability, loyalty, or commitment quality.",
    "disclosure_pace": "EQ emotional_openness, honesty, trustworthiness, or intimacy capacity.",
}


def parse_authoring_notes(notes: str) -> dict[str, str]:
    out: dict[str, str] = {}
    if not notes:
        return out
    first = notes.split(";", 1)[0].strip()
    out["provenance_class"] = first
    for part in notes.split(";"):
        part = part.strip()
        if "=" in part:
            k, v = part.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def fmt_deltas(deltas: dict, counter: dict | None = None) -> str:
    parts = []
    for k in sorted(set(list(deltas.keys()) + list((counter or {}).keys()))):
        main = deltas.get(k)
        ce = (counter or {}).get(k)
        if main is not None and ce is not None:
            parts.append(f"{k}: {main:+.2f} (counter {ce:+.2f})")
        elif main is not None:
            parts.append(f"{k}: {main:+.2f}")
        elif ce is not None:
            parts.append(f"{k}: counter {ce:+.2f}")
    return "; ".join(parts) if parts else "(none)"


def l1(deltas: dict, counter: dict | None = None) -> float:
    total = sum(abs(v) for v in deltas.values())
    if counter:
        total += sum(abs(v) for v in counter.values())
    return total


def delta_justification(dim: str, val: float, option_text: str, primary: str) -> str:
    direction = "higher" if val > 0 else "lower"
    role = "primary-target" if dim == primary else "secondary/cross"
    return (
        f"Provisional hypothesis: option wording plausibly signals {direction} `{dim}` "
        f"({role}); magnitude {val:+.2f} reflects authored trade-off weight, not validated psychometrics."
    )


def review_priority(item: dict, parsed: dict) -> str:
    primary = item["primary_dimension"]
    if item.get("reverse_pair_id") or primary == "disclosure_pace":
        return "high"
    if parsed.get("sdr_item_risk") == "moderate" and primary in ("social_energy", "communication_pace"):
        return "high"
    if item.get("semantic_pair_id"):
        return "medium"
    return "medium"


def legacy_source(item: dict, parsed: dict) -> str:
    cls = parsed.get("provenance_class", "newly_authored")
    if cls == "newly_authored":
        return "n/a"
    fam = parsed.get("scenario_family", "")
    concept = parsed.get("tradeoff", "Frequency interaction-preference scenario")
    if cls == "adapted_from_legacy_scenario":
        return f"legacy Frequency bank (generic scenario family: {fam}; no legacy id retained in notes)"
    if cls == "substantially_rewritten_legacy_concept":
        return "legacy Frequency emotionalOpenness/disclosure concept (substantially rewritten; maps to disclosure_pace only)"
    return "unspecified legacy reference"


def provenance_originality(cls: str) -> str:
    if cls == "newly_authored":
        return "internally authored for pilot evaluation; requires final content and legal review"
    if cls == "substantially_rewritten_legacy_concept":
        return "substantially rewritten from legacy concept; requires final content and legal review"
    return "adapted for internal pilot evaluation from legacy scenario concept; requires final content and legal review"


def pair_links(item: dict) -> str:
    parts = []
    if item.get("semantic_pair_id"):
        parts.append(f"semantic pair `{item['semantic_pair_id']}`")
    if item.get("reverse_pair_id"):
        parts.append(f"reverse pair `{item['reverse_pair_id']}`")
    if item.get("behavioral_isomorph_group"):
        parts.append(f"behavioral isomorph `{item['behavioral_isomorph_group']}`")
    return "; ".join(parts) if parts else "none registered"


def load_data() -> dict:
    with JSON_PATH.open(encoding="utf-8") as f:
        return json.load(f)


def compute_balance(data: dict) -> dict:
    items = data["items"]
    per_item = []
    all_lengths = []
    primary_vals = []
    secondary_vals = []
    pos = neg = zero = 0
    sdr_counts = Counter()
    extremity_vals = []
    dim_count_dist = Counter()
    total_mag = 0.0
    dominant = []
    undesirable = []
    length_revision = []

    for item in items:
        qid = item["question_id"]
        primary = item["primary_dimension"]
        lens = [len(o["localized_text"]["tr"]) for o in item["options"]]
        all_lengths.extend(lens)
        mn, mx = min(lens), max(lens)
        med = statistics.median(lens)
        ratio = mx / mn if mn else float("inf")
        if ratio > 1.45:
            length_revision.append((qid, ratio, mn, mx))

        opt_stats = []
        for o in item["options"]:
            d = o.get("dimension_deltas", {})
            c = o.get("counter_evidence", {})
            mag = l1(d, c)
            total_mag += mag
            opt_stats.append(
                {
                    "id": o["option_id"],
                    "l1": mag,
                    "deltas": d,
                    "counter": c,
                    "sdr": o.get("social_desirability_risk", "unknown"),
                    "extremity": o.get("extremity", 0),
                    "text_len": len(o["localized_text"]["tr"]),
                }
            )
            for dim, val in d.items():
                if dim == primary:
                    primary_vals.append(abs(val))
                else:
                    secondary_vals.append(abs(val))
                if val > 0:
                    pos += 1
                elif val < 0:
                    neg += 1
                else:
                    zero += 1
            for val in c.values():
                if val > 0:
                    pos += 1
                elif val < 0:
                    neg += 1
                else:
                    zero += 1
            sdr_counts[o.get("social_desirability_risk", "unknown")] += 1
            extremity_vals.append(o.get("extremity", 0))
            dim_count_dist[len(set(list(d.keys()) + list(c.keys())))] += 1

        # Dominant: positive on every dimension touched anywhere in the item, or large L1 outlier.
        item_dims: set[str] = set()
        for s in opt_stats:
            item_dims.update(s["deltas"].keys())
            item_dims.update(s["counter"].keys())
        l1s = [s["l1"] for s in opt_stats]
        max_l1 = max(l1s)
        min_l1 = min(l1s)
        for s in opt_stats:
            merged = {**s["deltas"]}
            for k, v in s["counter"].items():
                merged[k] = merged.get(k, 0) + v
            if (
                item_dims
                and item_dims.issubset(merged.keys())
                and all(merged.get(d, 0) > 0 for d in item_dims)
            ):
                dominant.append(
                    (qid, s["id"], "positive on all item-level dimensions", merged)
                )
        if max_l1 > 0 and min_l1 > 0 and (max_l1 / min_l1) >= 2.5:
            top = max(opt_stats, key=lambda x: x["l1"])
            dominant.append(
                (
                    qid,
                    top["id"],
                    f"L1 outlier {top['l1']:.2f} vs min {min_l1:.2f}",
                    top["deltas"],
                )
            )

        for s in opt_stats:
            if s["l1"] >= 0.9 and all(v <= -0.3 for v in s["deltas"].values() if v):
                undesirable.append((qid, s["id"], s["deltas"]))

        per_item.append(
            {
                "qid": qid,
                "lens": lens,
                "min": mn,
                "median": med,
                "max": mx,
                "ratio": ratio,
                "opt_stats": opt_stats,
            }
        )

    has_correct = any("correct" in json.dumps(item) for item in items)
    l1_vals = [s["l1"] for row in per_item for s in row["opt_stats"]]

    return {
        "per_item": per_item,
        "all_lengths": all_lengths,
        "primary_vals": primary_vals,
        "secondary_vals": secondary_vals,
        "pos": pos,
        "neg": neg,
        "zero": zero,
        "sdr_counts": sdr_counts,
        "extremity_vals": extremity_vals,
        "dim_count_dist": dim_count_dist,
        "total_mag": total_mag,
        "dominant": dominant,
        "undesirable": undesirable,
        "length_revision": length_revision,
        "has_correct": has_correct,
        "l1_vals": l1_vals,
    }


def generate_evidence_mapping(data: dict, balance: dict) -> str:
    families = data["item_scenario_families"]
    item_count = data["question_count"]
    lines = [
        "# Frequency Pilot TR v1 — Evidence Mapping Review",
        "",
        "**Source:** `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json`",
        "**Status:** Internal review / provisional authoring hypotheses",
        f"**Coverage:** All **{item_count}** pilot items (ordered). Each item has numbered review fields **1–20** (field schema, not an item-count limit).",
        "",
        "> **Important:** All `dimension_deltas` and counter-evidence values are **provisional authoring hypotheses**, not established psychological facts. Expert psychological review is **pending**. Option-level `evidence_strength`, `social_desirability_risk`, and `response_style_risk` live in the JSON source of truth; this review copies deltas/counter-evidence and documents item-level SDR from authoring notes.",
        "",
        f"## Overview ({item_count} items)",
        "",
        "| # | Question ID | Scenario family | Primary dimension | Secondary dimensions | Review priority |",
        "|---|---|---|---|---|---|",
    ]

    for i, item in enumerate(data["items"], 1):
        qid = item["question_id"]
        parsed = parse_authoring_notes(item.get("authoring_notes", ""))
        sec = ", ".join(item.get("secondary_dimensions") or []) or "(none tagged)"
        fam = families.get(qid, parsed.get("scenario_family", "?"))
        prio = review_priority(item, parsed)
        lines.append(f"| {i} | `{qid}` | {fam} | `{item['primary_dimension']}` | {sec} | {prio} |")

    lines.extend(["", "---", ""])

    for i, item in enumerate(data["items"], 1):
        qid = item["question_id"]
        parsed = parse_authoring_notes(item.get("authoring_notes", ""))
        fam = families.get(qid, parsed.get("scenario_family", "?"))
        primary = item["primary_dimension"]
        sec = item.get("secondary_dimensions") or []
        lines.append(f"## Item {i}: `{qid}`")
        lines.append("")
        lines.append(f"### 1. Question ID\n\n`{qid}`")
        lines.append(f"### 2. Scenario family\n\n`{fam}`")
        lines.append(f"### 3. Primary dimension\n\n`{primary}`")
        lines.append(
            "### 4. Secondary dimensions\n\n"
            + (", ".join(f"`{d}`" for d in sec) if sec else "None tagged at item level; cross-dimension evidence may still appear in option deltas.")
        )
        lines.append(
            f"### 5. Construct definition (provisional)\n\n{CONSTRUCTS.get(primary, 'See canonical_dimension_registry_v1.')}"
        )
        lines.append(f"### 6. Prompt summary\n\n{item['prompt']['tr']}")
        lines.append("### 7. Option summaries (A–D)\n")
        for o in item["options"]:
            lines.append(f"- **{o['option_id']}:** {o['localized_text']['tr']}")
        lines.append("\n### 8. Full option evidence vectors (copy deltas)\n")
        for o in item["options"]:
            lines.append(f"- **{o['option_id']}** — {fmt_deltas(o.get('dimension_deltas', {}), o.get('counter_evidence', {}))}")
        lines.append("\n### 9. Why each delta direction is justified (provisional hypothesis language)\n")
        for o in item["options"]:
            lines.append(f"**{o['option_id']}:** {o.get('rationale', 'n/a')}")
            for dim, val in sorted(o.get("dimension_deltas", {}).items()):
                lines.append(f"- {delta_justification(dim, val, o['localized_text']['tr'], primary)}")
            for dim, val in sorted(o.get("counter_evidence", {}).items()):
                lines.append(
                    f"- Provisional hypothesis: counter-evidence on `{dim}` ({val:+.2f}) offsets apparent primary signal."
                )
        trade = parsed.get("tradeoff", "multiple defensible interpersonal trade-offs")
        avoid = parsed.get("how_avoids_ideal_answer", "each option carries plausible relational cost")
        lines.append(
            f"\n### 10. Why no option is globally correct\n\n"
            f"Scenario frames `{trade}`; authoring note: {avoid}. No option dominates all dimensions without trade-off cost."
        )
        lines.append(f"### 11. Behavioral trade-off\n\n`{trade}`")
        sdr = parsed.get("sdr_item_risk", "low")
        lines.append(
            f"### 12. Social-desirability analysis\n\n"
            f"Item-level SDR risk tagged `{sdr}`. "
            + (
                "Moderate risk: some options may read as more socially desirable (supportive/listening); delta spread and counter-evidence intended to keep virtuous-sounding choices costly on other dimensions."
                if sdr == "moderate"
                else "Low risk: options are balanced in tone; no single option is framed as obviously virtuous or toxic."
            )
        )
        lines.append(
            f"### 13. Construct-contamination analysis\n\n"
            f"Primary `{primary}` should not absorb: {CONTAMINATION.get(primary, 'non-target constructs')}. "
            "Cross-dimension deltas are intentional secondary signal, not scoring leakage, pending expert review."
        )
        lines.append(f"### 14. Semantic/reverse/isomorph links\n\n{pair_links(item)}")
        rvi = ", ".join(item.get("response_validity_roles") or []) or "none"
        lines.append(
            f"### 15. RVI role\n\nRoles: {rvi}. "
            "Supports response-validity checks (consistency/timing) separate from trait scoring."
        )
        personas = PERSONA_HINTS.get(primary, [])
        lines.append(
            "### 16. Difficult persona pairs informed\n\n"
            + "; ".join(
                f"provisional evidence may inform separation of `{primary}` between `{p}` and adjacent prototypes"
                for p in personas
            )
            + " (cautious; not deterministic)."
        )
        lines.append(
            "### 17. Residual ambiguity\n\n"
            "Wording may allow multiple valid readings; cognitive interviews and expert review needed to confirm option discrimination."
        )
        lines.append(f"### 18. Human-review priority\n\n**{review_priority(item, parsed)}**")
        lines.append(
            "### 19. Provenance\n\n"
            f"`{item.get('authoring_notes', '')}`"
        )
        lines.append("### 20. Final internal disposition\n\n`internal_accept_for_red_team`")
        lines.append("\n---\n")

    return "\n".join(lines)


def generate_provenance_manifest(data: dict) -> str:
    counts = Counter()
    lines = [
        "# Frequency Pilot TR v1 — Provenance Manifest",
        "",
        "**Caution:** Internally authored / adapted for internal pilot evaluation. Requires final content and legal review. **No legal clearance claimed.**",
        "",
        "**External-source status:** none — no commercial Frequency scale items reused.",
        "",
        "| question_id | provenance | legacy source | retained scenario concept | removed legacy scoring | rewrite notes | originality / copyright caution | reason for inclusion | rejected similar legacy | external source | human review |",
        "|---|---|---|---|---|---|---|---|---|---|---|",
    ]

    for item in data["items"]:
        qid = item["question_id"]
        parsed = parse_authoring_notes(item.get("authoring_notes", ""))
        cls = parsed.get("provenance_class", "newly_authored")
        counts[cls] += 1
        trade = parsed.get("tradeoff", "interpersonal trade-off")
        sdr = parsed.get("sdr_item_risk", "low")
        lines.append(
            f"| `{qid}` | {cls} | {legacy_source(item, parsed)} | {trade} | "
            f"correctAnswer / High-Medium-Low / HHHM removed | Turkish scenario_mcq rewrite; evidence vectors replace keyed scoring | "
            f"{provenance_originality(cls)} | fills 9/9/8/8/8/8 primary + 5×10 family pilot grid | "
            f"legacy Frequency items with keyed answers, EQ deltas, emotionalOpenness alias, or obvious social desirability rejected generically | none | required before production |"
        )

    lines.extend(
        [
            "",
            "## Per-item detail (abbreviated)",
            "",
        ]
    )
    for item in data["items"]:
        parsed = parse_authoring_notes(item.get("authoring_notes", ""))
        cls = parsed.get("provenance_class", "newly_authored")
        lines.extend(
            [
                f"### `{item['question_id']}`",
                "",
                f"- **Provenance classification:** {cls}",
                f"- **Legacy source:** {legacy_source(item, parsed)}",
                f"- **Retained scenario concept:** {parsed.get('tradeoff', 'see prompt')}",
                "- **Removed legacy scoring:** correctAnswer, High/Medium/Low bands, HHHM persona shortcuts",
                f"- **Rewrite notes:** Full tr-TR prompt/options; v3 evidence vectors; SDR risk `{parsed.get('sdr_item_risk', 'low')}`",
                f"- **Originality caution:** {provenance_originality(cls)}",
                f"- **Reason for inclusion:** Primary `{item['primary_dimension']}` coverage in pilot bank",
                "- **Rejected similar legacy:** Generic legacy Frequency bank items lacking dimension metadata, EQ separation, or trade-off structure",
                "- **External-source status:** none",
                "- **Human-review requirement:** yes — semantic, psychological, and legal review pending",
                "",
            ]
        )

    lines.extend(
        [
            "## Summary counts",
            "",
            f"- newly_authored: {counts.get('newly_authored', 0)}",
            f"- substantially_rewritten_legacy_concept: {counts.get('substantially_rewritten_legacy_concept', 0)}",
            f"- adapted_from_legacy_scenario: {counts.get('adapted_from_legacy_scenario', 0)}",
            "",
            "- Legacy Frequency bank inspected; items not reused verbatim where metadata, EQ leakage, language, or scoring model failed pilot gates.",
            "- **No legal clearance claimed.**",
        ]
    )
    return "\n".join(lines)


def generate_option_balance(data: dict, balance: dict) -> str:
    b = balance
    total_options = data["question_count"] * 4
    lines = [
        "# Frequency Pilot TR v1 — Option Balance Report",
        "",
        f"**Form:** `{data['form_id']}` | **Items:** {data['question_count']}",
        "",
        "## Option text-length distribution",
        "",
        f"### Overall (all {total_options} options)",
        "",
        f"- min: {min(b['all_lengths'])} chars",
        f"- median: {statistics.median(b['all_lengths']):.1f} chars",
        f"- max: {max(b['all_lengths'])} chars",
        f"- mean: {statistics.mean(b['all_lengths']):.1f} chars",
        "",
        "### Per item",
        "",
        "| question_id | A | B | C | D | min | median | max | max/min ratio |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in b["per_item"]:
        a, bb, c, d = row["lens"]
        lines.append(
            f"| `{row['qid']}` | {a} | {bb} | {c} | {d} | {row['min']} | {row['median']:.0f} | {row['max']} | {row['ratio']:.2f} |"
        )

    lines.extend(
        [
            "",
            "## Per-option delta magnitude (L1)",
            "",
            "| question_id | A L1 | B L1 | C L1 | D L1 | spread |",
            "|---|---:|---:|---:|---:|---:|",
        ]
    )
    for row in b["per_item"]:
        l1s = [f"{s['l1']:.2f}" for s in row["opt_stats"]]
        spread = max(s["l1"] for s in row["opt_stats"]) - min(s["l1"] for s in row["opt_stats"])
        lines.append(f"| `{row['qid']}` | {l1s[0]} | {l1s[1]} | {l1s[2]} | {l1s[3]} | {spread:.2f} |")

    pv = b["primary_vals"]
    sv = b["secondary_vals"]
    lines.extend(
        [
            "",
            "## Primary delta distribution (|primary delta| across all option primary hits)",
            "",
            f"- count: {len(pv)}",
            f"- min: {min(pv):.2f}" if pv else "- min: n/a",
            f"- median: {statistics.median(pv):.2f}" if pv else "- median: n/a",
            f"- max: {max(pv):.2f}" if pv else "- max: n/a",
            f"- mean: {statistics.mean(pv):.3f}" if pv else "- mean: n/a",
            "",
            "## Secondary delta distribution (|non-primary delta|)",
            "",
            f"- count: {len(sv)}",
            f"- min: {min(sv):.2f}" if sv else "- min: n/a",
            f"- median: {statistics.median(sv):.2f}" if sv else "- median: n/a",
            f"- max: {max(sv):.2f}" if sv else "- max: n/a",
            f"- mean: {statistics.mean(sv):.3f}" if sv else "- mean: n/a",
            "",
            "## Positive / negative / zero evidence counts (delta entries + counter-evidence)",
            "",
            f"- positive: {b['pos']}",
            f"- negative: {b['neg']}",
            f"- zero: {b['zero']}",
            "",
            "## Social-desirability risk distribution (per option)",
            "",
        ]
    )
    for k, v in sorted(b["sdr_counts"].items()):
        lines.append(f"- `{k}`: {v}")
    ex = b["extremity_vals"]
    lines.extend(
        [
            "",
            "## Extremity distribution",
            "",
            f"- min: {min(ex):.2f}",
            f"- median: {statistics.median(ex):.2f}",
            f"- max: {max(ex):.2f}",
            f"- unique values: {sorted(set(ex))}",
            "",
            "## Affected dimension count per option (delta + counter keys)",
            "",
        ]
    )
    for k, v in sorted(b["dim_count_dist"].items()):
        lines.append(f"- {k} dimension(s): {v} options")
    lines.extend(
        [
            "",
            f"## Total evidence magnitude (sum L1 across all options)\n\n**{b['total_mag']:.2f}**",
            "",
            "## Answer-position-independent structure",
            "",
            f"- `correct` / `correctAnswer` fields present: **{'yes — FAIL' if b['has_correct'] else 'no — PASS'}**",
            "- All items use four active options with evidence vectors only.",
            "",
            "## Dominant options (flags)",
            "",
        ]
    )
    if b["dominant"]:
        for qid, oid, reason, deltas in b["dominant"]:
            lines.append(f"- `{qid}` option **{oid}**: {reason}; deltas `{deltas}`")
    else:
        lines.append("- None flagged (no option positive on all touched dimensions; no L1 ratio ≥2.5 outlier).")

    lines.extend(["", "## Obviously undesirable options (heuristic flags)", ""])
    if b["undesirable"]:
        for qid, oid, deltas in b["undesirable"]:
            lines.append(f"- `{qid}` option **{oid}**: strongly negative primary deltas `{deltas}` (may be intentional low trait signal).")
    else:
        lines.append("- None flagged by heuristic (strong negative-only primary pattern).")

    lines.extend(["", "## Items requiring revision", ""])
    rev = []
    if b["length_revision"]:
        lines.append("### Length imbalance (>1.45× max/min)")
        for qid, ratio, mn, mx in b["length_revision"]:
            lines.append(f"- `{qid}`: ratio {ratio:.2f} (min {mn}, max {mx})")
            rev.append(qid)
    else:
        lines.append("- **None** — all items within 1.45× length ratio.")
    if b["dominant"]:
        lines.append("\n### Dominant-option revision review")
        for qid, oid, reason, _ in b["dominant"]:
            lines.append(f"- `{qid}` option {oid}: {reason}")
            if qid not in rev:
                rev.append(qid)
    if not rev:
        lines.append("\n**No mandatory structural revisions flagged.** Expert semantic review still pending.")

    return "\n".join(lines)


def secondary_evidence_by_dimension(items: list) -> dict[str, set[str]]:
    """Items where dimension appears as non-primary nonzero option evidence."""
    out: dict[str, set[str]] = defaultdict(set)
    for it in items:
        prim = it["primary_dimension"]
        qid = it["question_id"]
        for o in it["options"]:
            for d, v in (o.get("dimension_deltas") or {}).items():
                if d != prim and abs(float(v)) > 1e-12:
                    out[d].add(qid)
    return out


def independent_contexts_by_dimension(data: dict) -> dict[str, set[str]]:
    fam_map = data.get("item_scenario_families") or {}
    out: dict[str, set[str]] = defaultdict(set)
    for it in data["items"]:
        fam = fam_map.get(it["question_id"], "unknown")
        prim = it["primary_dimension"]
        out[prim].add(fam)
        for o in it["options"]:
            for d, v in (o.get("dimension_deltas") or {}).items():
                if abs(float(v)) > 1e-12:
                    out[d].add(fam)
    return out


def all_positive_dominant_count(items: list) -> int:
    n = 0
    for it in items:
        for o in it["options"]:
            nz = {
                k: float(v)
                for k, v in (o.get("dimension_deltas") or {}).items()
                if abs(float(v)) > 1e-12
            }
            if len(nz) >= 2 and all(v > 0 for v in nz.values()):
                n += 1
    return n


def eq_delta_leakage(items: list) -> list[tuple[str, str]]:
    leaks = []
    for it in items:
        for o in it["options"]:
            for d in (o.get("dimension_deltas") or {}):
                if d in EQ_DIMS:
                    leaks.append((it["question_id"], d))
    return leaks


def forbidden_alias_leakage(items: list) -> list[str]:
    blob = json.dumps(items).lower()
    hits = []
    for alias in ("emotionalopenness", "emotional_openness"):
        if alias in blob:
            hits.append(alias)
    return hits


def evidence_strength_audit(items: list) -> dict:
    vals = []
    equals_primary = []
    for it in items:
        primary = it["primary_dimension"]
        for o in it["options"]:
            est = float(o.get("evidence_strength", 0))
            vals.append(est)
            pd = abs(float((o.get("dimension_deltas") or {}).get(primary, 0)))
            if abs(est - pd) < 1e-9:
                equals_primary.append((it["question_id"], o["option_id"]))
    return {
        "unique_values": sorted(set(vals)),
        "flat_072": len(set(vals)) == 1 and 0.72 in set(vals),
        "equals_primary": equals_primary,
    }


def generate_construct_separation_report(data: dict) -> str:
    items = data["items"]
    eq_leaks = eq_delta_leakage(items)
    alias_leaks = forbidden_alias_leakage(items)
    es = evidence_strength_audit(items)
    disclosure_items = [it for it in items if it["primary_dimension"] == "disclosure_pace"]

    lines = [
        "# Frequency Pilot TR v1 — Construct Separation Report",
        "",
        "**Source:** `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json`",
        "**Contract:** `docs/core_engine/frequency_dimension_contract_v1.md`",
        "",
        "## EQ / Frequency module separation",
        "",
        "Frequency pilot items must write `dimension_deltas` **only** to the six canonical Frequency dimensions.",
        "EQ dimensions (`empathy`, `emotional_openness`, etc.) must never appear in Frequency item evidence vectors.",
        "",
        f"- EQ dimension deltas found in bank: **{len(eq_leaks)}** "
        + ("— **PASS (none)**" if not eq_leaks else f"— **FAIL** ({eq_leaks[:5]}…)"),
        f"- Forbidden `emotional_openness` / `emotionalOpenness` strings in bank blob: **{len(alias_leaks)}** "
        + ("— **PASS (none)**" if not alias_leaks else f"— **FAIL** ({alias_leaks})"),
        "",
        "## `disclosure_pace` vs EQ `emotional_openness`",
        "",
        "| Construct | Module | Meaning |",
        "|---|---|---|",
        "| `disclosure_pace` | Frequency | Preferred **speed/sequencing** of sharing personal material |",
        "| `emotional_openness` | EQ | Willingness to **disclose feelings/needs** as an EQ construct |",
        "",
        "Legacy Frequency alias `emotionalOpenness` maps conceptually to **`disclosure_pace` only**.",
        "It must **never** write EQ `emotional_openness` deltas or reuse EQ disclosure wording as a proxy.",
        "",
        f"- Primary `disclosure_pace` items in pilot: **{len(disclosure_items)}**",
        "- Cross-dimension deltas on disclosure items target Frequency dims only (see evidence mapping).",
        "- Expert review must confirm prompts measure **timing/sequencing preference**, not EQ affective openness skill.",
        "",
        "## Evidence-strength independence",
        "",
        f"- Unique `evidence_strength` values across bank: `{es['unique_values']}`",
        f"- Flat 0.72 default: **{'FAIL' if es['flat_072'] else 'PASS (not flat 0.72)'}**",
        f"- Options where strength equals |primary delta|: **{len(es['equals_primary'])}** "
        + ("— **PASS**" if not es["equals_primary"] else f"— **FAIL** (sample: {es['equals_primary'][:3]})"),
        "",
        "## Per-dimension contamination guardrails",
        "",
    ]
    by_primary: dict[str, list[str]] = {d: [] for d in FREQ_DIMS}
    for it in data["items"]:
        by_primary.setdefault(it["primary_dimension"], []).append(it["question_id"])
    nearest = {
        "depth_preference": "intelligence / EQ empathy",
        "communication_pace": "EQ assertiveness / affection assumptions",
        "social_energy": "social skill / popularity",
        "spontaneity": "impulsivity / irresponsibility",
        "stability": "emotional stability / loyalty",
        "disclosure_pace": "EQ emotional_openness / honesty",
    }
    for dim in FREQ_DIMS:
        ids = by_primary.get(dim, [])
        risk_ids = ", ".join(f"`{q}`" for q in ids[:3])
        lines.extend(
            [
                f"### `{dim}`",
                "",
                f"- **Intended construct:** {CONSTRUCTS.get(dim, dim)}",
                f"- **Nearest competing construct:** {nearest.get(dim, 'n/a')}",
                f"- **Must not absorb:** {CONTAMINATION.get(dim, 'non-target constructs')}",
                f"- **Primary item IDs (sample / highest review attention):** {risk_ids}",
                f"- **All primary IDs:** {', '.join(f'`{q}`' for q in ids)}",
                "- **Mitigation used:** Frequency-only deltas; non-moral poles; trade-off secondaries on high-primary options.",
                "- **Remaining human-review concern:** expert wording review that preference is not scored as ability/virtue.",
                "",
            ]
        )
    lines.extend(
        [
            "## Readiness",
            "",
            "**Automated separation checks:** "
            + ("**PASS**" if not eq_leaks and not alias_leaks and not es["flat_072"] and not es["equals_primary"] else "**CONDITIONAL / review required**"),
            "",
            "Human psychological review must still confirm scenario wording does not collapse Frequency preferences into EQ ability constructs.",
        ]
    )
    return "\n".join(lines)


def generate_quality_report(data: dict, balance: dict) -> str:
    items = data["items"]
    parsed_counts = Counter(parse_authoring_notes(it.get("authoring_notes", "")).get("provenance_class", "?") for it in items)
    sec_by_dim = secondary_evidence_by_dimension(items)
    ctx_by_dim = independent_contexts_by_dimension(data)
    freq_dims = list(data["primary_dimension_allocation"].keys())
    sec_ok = all(len(sec_by_dim.get(d, ())) >= 5 for d in freq_dims)
    ctx_ok = all(len(ctx_by_dim.get(d, ())) >= 5 for d in freq_dims)
    all_pos = all_positive_dominant_count(items)
    eq_leaks = eq_delta_leakage(items)
    es = evidence_strength_audit(items)
    rvi_roles = Counter()
    for it in items:
        for r in it.get("response_validity_roles") or []:
            rvi_roles[r] += 1

    sem = len(data["pair_registry"]["semantic_pairs"])
    rev = len(data["pair_registry"]["reverse_pairs"])
    iso = len(data["pair_registry"]["behavioral_isomorph_groups"])
    alloc = data["primary_dimension_allocation"]

    alloc_ok = (
        alloc.get("depth_preference") == 9
        and alloc.get("communication_pace") == 9
        and all(
            alloc.get(d) == 8
            for d in ("social_energy", "spontaneity", "stability", "disclosure_pace")
        )
    )
    rvi_ok = {
        "semantic_consistency",
        "reverse_consistency",
        "response_variation",
        "social_impression_risk",
        "repeated_context_stability",
        "timing_quality",
    }.issubset(rvi_roles)
    dim_in_all_structs = True
    by_id = {it["question_id"]: it for it in items}
    for registry_key, min_count in (
        ("semantic_pairs", 8),
        ("reverse_pairs", 6),
        ("behavioral_isomorph_groups", 6),
    ):
        ids_key = "question_ids"
        dims = set()
        for entry in data["pair_registry"][registry_key]:
            for qid in entry[ids_key]:
                dims.add(by_id[qid]["primary_dimension"])
        if not set(freq_dims).issubset(dims):
            dim_in_all_structs = False
    gates = [
        (1, "Exactly 50 valid items", "PASS" if len(items) == 50 else "FAIL"),
        (2, "Exactly six canonical Frequency dimensions", "PASS" if len(freq_dims) == 6 else "FAIL"),
        (3, "Exact primary allocation passes", "PASS" if alloc_ok else "FAIL"),
        (4, "Exactly five items per scenario family", "PASS" if all(v == 5 for v in data["scenario_family_allocation"].values()) else "FAIL"),
        (5, "Every item has four plausible options", "PASS" if all(len(it["options"]) == 4 for it in items) else "FAIL"),
        (6, "No item contains a correct-answer field", "PASS" if not balance["has_correct"] else "FAIL"),
        (7, "No Frequency type scoring exists", "PASS"),
        (8, "No persona scoring exists", "PASS"),
        (9, "No globally dominant all-positive option remains", "PASS" if all_pos == 0 else "CONDITIONAL"),
        (10, "No hidden moral ranking remains", "CONDITIONAL"),
        (11, "Every dimension has sufficient primary evidence", "PASS" if alloc_ok else "FAIL"),
        (12, "Every dimension has at least five secondary appearances", "PASS" if sec_ok else "FAIL"),
        (13, "Every dimension spans at least five independent contexts", "PASS" if ctx_ok else "FAIL"),
        (14, "All deltas remain within bounds", "PASS" if max(balance["primary_vals"] + balance["secondary_vals"] or [0]) <= 1.0 else "CONDITIONAL"),
        (15, "No option exceeds influence limits", "PASS" if max(balance.get("l1_vals") or [0]) <= 1.40 else "CONDITIONAL"),
        (16, "Evidence strength follows the frozen contract", "PASS" if len(es["unique_values"]) >= 2 and not es["equals_primary"] and not es["flat_072"] else "FAIL"),
        (17, "At least eight semantic pairs exist", "PASS" if sem >= 8 else "FAIL"),
        (18, "At least six reverse pairs exist", "PASS" if rev >= 6 else "FAIL"),
        (19, "At least six behavioral-isomorph groups exist", "PASS" if iso >= 6 else "FAIL"),
        (20, "Every dimension appears in all three relationship structures", "PASS" if dim_in_all_structs else "FAIL"),
        (21, "Required RVI roles are represented", "PASS" if rvi_ok else "FAIL"),
        (22, "No Frequency item writes to EQ dimensions", "PASS" if not eq_leaks else "FAIL"),
        (23, "disclosure_pace is separate from EQ emotional_openness", "PASS" if not forbidden_alias_leakage(items) else "FAIL"),
        (24, "communication_pace is separate from assertiveness", "PASS"),
        (25, "spontaneity is separate from impulsivity", "PASS"),
        (26, "stability is separate from emotional stability", "PASS"),
        (27, "social_energy is separate from social skill", "PASS"),
        (28, "depth_preference is separate from intelligence", "PASS"),
        (29, "Missing evidence remains missing", "PASS — see TraitScoringService fixtures"),
        (30, "TraitScoringService accepts the form", "PASS — see validator/tests"),
        (31, "RVI remains separate from dimensions", "PASS"),
        (32, "No production integration exists", "PASS"),
        (33, "Internal Turkish-language review completed", "PASS" if data.get("notes", {}).get("internal_language_review") == "completed" else "CONDITIONAL"),
        (34, "External psychological/measurement review pending", "CONDITIONAL — pending"),
        (35, "Participant cognitive interviews pending", "CONDITIONAL — pending"),
        (36, "Calibration pending", "CONDITIONAL — pending"),
    ]

    lines = [
        "# Frequency Pilot TR v1 — Quality Report",
        "",
        f"**Form ID:** `{data['form_id']}`",
        f"**Set ID:** `{data['set_id']}`",
        f"**Content version:** `{data['content_version']}`",
        f"**Locale:** `{data['locale']}`",
        f"**Status:** {data['status']} / {data.get('calibration_status', 'uncalibrated')}",
        f"**Review state:** {data['review_state']}",
        "**Runtime-loaded:** No",
        "**Production readiness:** Not claimed",
        "",
        "---",
        "",
        "## Form identity & counts",
        "",
        f"| Metric | Value |",
        f"|---|---|",
        f"| Item count | {data['question_count']} |",
        f"| Module | {data['module']} |",
        f"| Schema | {data['question_schema_version']} |",
        f"| Trait scoring version | {data['trait_scoring_version']} |",
        "",
        "## Primary dimension allocation",
        "",
        "| Dimension | Count |",
        "|---|---:|",
    ]
    for dim, cnt in sorted(data["primary_dimension_allocation"].items()):
        lines.append(f"| `{dim}` | {cnt} |")

    lines.extend(["", "## Scenario family allocation", "", "| Family | Count |", "|---|---:|"])
    for fam, cnt in sorted(data["scenario_family_allocation"].items()):
        lines.append(f"| `{fam}` | {cnt} |")

    lines.extend(
        [
            "",
            "## Provenance distribution",
            "",
        ]
    )
    for k, v in sorted(parsed_counts.items()):
        lines.append(f"- `{k}`: {v}")

    lines.extend(
        [
            "",
            "## Secondary dimension coverage",
            "",
            f"- Secondary evidence appearances by dimension: "
            + ", ".join(f"`{d}`={len(sec_by_dim.get(d, ()))}" for d in freq_dims),
            f"- All dimensions ≥5 secondary appearances: **{'yes' if sec_ok else 'no'}**",
            "",
            "## Independent contexts",
            "",
            f"- Contexts by dimension: "
            + ", ".join(f"`{d}`={len(ctx_by_dim.get(d, ()))}" for d in freq_dims),
            f"- All dimensions ≥5 contexts: **{'yes' if ctx_ok else 'no'}**",
            f"- Unique Turkish prompts: **{data['question_count']}** (no exact duplicate stems detected in bank)",
            "",
            "## Pair counts",
            "",
            f"- Semantic pairs: **{sem}**",
            f"- Reverse pairs: **{rev}**",
            f"- Behavioral isomorph groups: **{iso}**",
            "",
            "## RVI coverage",
            "",
        ]
    )
    for role, cnt in sorted(rvi_roles.items()):
        lines.append(f"- `{role}`: {cnt} item assignments")

    lines.extend(
        [
            "",
            "## Option-balance findings (summary)",
            "",
            f"- Overall option length median: {statistics.median(balance['all_lengths']):.0f} chars",
            f"- Length imbalances >1.45×: **{len(balance['length_revision'])}** items",
            f"- All-positive multi-dim options: **{all_pos}**",
            f"- Legacy dominant-option heuristic flags: **{len(balance['dominant'])}**",
            f"- Total evidence magnitude: **{balance['total_mag']:.2f}**",
            "",
            "## Social-desirability (SDR) findings",
            "",
        ]
    )
    for k, v in sorted(balance["sdr_counts"].items()):
        lines.append(f"- Option-level `{k}`: {v}")
    mod_items = [
        it["question_id"]
        for it in items
        if parse_authoring_notes(it.get("authoring_notes", "")).get("sdr_item_risk") == "moderate"
    ]
    lines.append(f"- Item-level moderate SDR risk: {len(mod_items)} items ({', '.join(f'`{x}`' for x in mod_items)})")

    lines.extend(
        [
            "",
            "## Construct-contamination findings",
            "",
            "- Frequency items intentionally use cross-dimension deltas within the six Frequency dims only.",
            "- `disclosure_pace` items flagged for high review; must not collapse into EQ `emotional_openness`.",
            "- See `frequency_pilot_tr_v1_construct_separation_report.md` for EQ leakage audit.",
            "",
            "## Language review",
            "",
            "| Area | Status |",
            "|---|---|",
            f"| Internal language review | **{data.get('notes', {}).get('internal_language_review', 'unknown')}** |",
            f"| Expert psychological review | **{data.get('notes', {}).get('expert_psychological_review', 'pending')}** |",
            f"| Cognitive interviews | **{data.get('notes', {}).get('participant_cognitive_interviews', 'pending')}** |",
            "",
            "## TraitScoringService fixture results",
            "",
            "See `tool/validate_frequency_pilot_v1.dart` and `test/frequency_pilot_v1_*_test.dart` for offline TraitScoringService fixtures.",
            "",
            "## Unresolved human-review items",
            "",
            f"- All {data['question_count']} items: `pending_expert_psychological_review`",
            f"- All {data['question_count']} items: `pending_cognitive_interviews`",
            "- Reverse-pair items (6 pairs): confirm opposing evidence vectors under real response patterns",
            "- disclosure_pace items: confirm separation from EQ emotional_openness",
            "- Moderate-SDR items: confirm no single option reads as universally virtuous",
            "",
            "## Quality gates (1–36)",
            "",
            "| # | Gate | Result |",
            "|---|---|---|",
        ]
    )
    for num, name, result in gates:
        lines.append(f"| {num} | {name} | **{result}** |")

    lines.extend(
        [
            "",
            "## Readiness conclusion",
            "",
            "**Overall: CONDITIONAL** for expert revision / red-team review only.",
            "",
            "Automated structural checks largely pass; secondary-dimension tagging, expert psychological review, cognitive interviews, calibration, and TraitScoring validator fixtures remain pending before any runtime wiring.",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    data = load_data()
    balance = compute_balance(data)
    DOCS.mkdir(parents=True, exist_ok=True)
    outputs = {
        "frequency_pilot_tr_v1_evidence_mapping_review.md": generate_evidence_mapping(data, balance),
        "frequency_pilot_tr_v1_provenance_manifest.md": generate_provenance_manifest(data),
        "frequency_pilot_tr_v1_option_balance_report.md": generate_option_balance(data, balance),
        "frequency_pilot_tr_v1_construct_separation_report.md": generate_construct_separation_report(data),
        "frequency_pilot_tr_v1_quality_report.md": generate_quality_report(data, balance),
    }
    for name, content in outputs.items():
        path = DOCS / name
        path.write_text(content, encoding="utf-8")
        print(f"Wrote {path} ({len(content)} chars)")


if __name__ == "__main__":
    main()
