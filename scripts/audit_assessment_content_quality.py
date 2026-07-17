#!/usr/bin/env python3
"""Read-only content quality audit for Qmatch bundled assessment sets.

Detects duplicate/near-duplicate stems, repeated option sets, UX length risks,
and heuristic Turkish/English quality flags. Does not modify JSON or Firestore.

Usage:
  python3 scripts/audit_assessment_content_quality.py
  python3 scripts/audit_assessment_content_quality.py --json
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "data" / "assessment_sets"

FILES = {
    "iq": ASSETS / "iq_sets.json",
    "eq": ASSETS / "eq_sets.json",
    "frequency": ASSETS / "frequency_sets.json",
}

REL_PATTERNS = [
    r"someone you(?:'|')?ve been seeing for a few weeks",
    r"a person you(?:'|')?re newly dating",
    r"someone you(?:'|')?ve matched with and have met twice",
    r"your partner on an ordinary weekday evening",
    r"a close friend you(?:'|')?re texting late evening",
    r"someone you(?:'|')?re casually dating",
    r"a friend you(?:'|')?re planning a trip with",
    r"someone you(?:'|')?ve started seeing exclusively",
    r"your partner before an important family dinner",
    r"a newer friend in your wider social circle",
    r"someone you(?:'|')?re dating long-distance this month",
    r"a roommate you(?:'|')?re friendly with",
    r"someone you(?:'|')?re seeing who shares your hobby group",
    r"your partner after a stressful work week",
    r"a friend who knows your dating history well",
    r"someone you(?:'|')?re messaging consistently but haven(?:'|')?t labeled yet",
    r"a coworker you(?:'|')?ve begun spending social time with",
    r"someone you(?:'|')?re dating who travels often for work",
    r"your partner when you(?:'|')?re both tired",
    r"a friend who(?:'|')?s going through a rough patch",
    r"someone you(?:'|')?re seeing who is quieter than you",
    r"a partner when plans suddenly change",
    r"someone new you(?:'|')?re dating who is very busy",
    r"a friend after you canceled plans once",
    r"someone you(?:'|')?re seeing who brings up sensitive topics lightly",
    r"your partner",
    r"a close friend",
]

LENGTH_THRESHOLDS = {
    "question_tr": 170,
    "question_en": 160,
    "option_tr": 90,
    "option_en": 85,
}

TR_HEURISTICS: list[tuple[str, str, re.Pattern[str]]] = [
    ("literal_prompt", "Literal machine-style prompt ending", re.compile(r"en olası tepkin hangisi olur", re.I)),
    ("generic_biri", "Overuse of generic 'biri'", re.compile(r"\bbiri\b", re.I)),
    ("vague_sey", "Vague filler 'şey'", re.compile(r"\bşey\b", re.I)),
    ("english_leak", "English word leak in Turkish", re.compile(r"\b(response|dating|feedback|vibe|okay)\b", re.I)),
    ("formal_passive", "Heavy formal/passive gerund stack", re.compile(r"(?:mek|mak) (?:zorunda|gerek)", re.I)),
    ("dash_clauses", "Long em-dash clause stacking", re.compile(r"—.{20,}—")),
]

EN_HEURISTICS: list[tuple[str, str, re.Pattern[str]]] = [
    ("template_prompt", "Repeated template prompt", re.compile(r"what's your most likely response\?", re.I)),
    ("caricature_option", "Caricature distractor option", re.compile(r"teach them a lesson|lecture them|dating others immediately|withdraw affection", re.I)),
    ("moralizing_win", "Moralizing 'model answer' tone", re.compile(r"check in kindly|name what you noticed|ask what would help", re.I)),
    ("generic_frequency", "Generic first-person preference statement", re.compile(r"^i (?:prefer|enjoy|like|need|feel|value|am energized)", re.I)),
    ("abstract_frequency", "Abstract/poetic frequency language", re.compile(r"rhythm|authentic|alignment|resonance|current|frequency|vibe", re.I)),
]


@dataclass
class QuestionRow:
    type: str
    set_id: str
    qid: str
    en: str
    tr: str
    opts_en: list[str]
    opts_tr: list[str]
    correct: int | None
    dimension: str | None = None
    difficulty: int | None = None


@dataclass
class AuditSummary:
    totals: dict[str, int] = field(default_factory=dict)
    issue_counts: dict[str, int] = field(default_factory=dict)
    eq_unique_situations: int = 0
    eq_situation_repeat_max: int = 0
    eq_option_set_count: int = 0
    eq_money_scenarios: int = 0
    frequency_abstract_count: int = 0
    readiness: str = "FAIL"
    top_urgent: list[dict[str, str]] = field(default_factory=list)


def _extract_question(q: dict[str, Any]) -> tuple[str, str]:
    raw = q.get("question") or q.get("text")
    if isinstance(raw, dict):
        return str(raw.get("en", "")).strip(), str(raw.get("tr", "")).strip()
    return str(raw).strip(), ""


def _extract_options(q: dict[str, Any]) -> tuple[list[str], list[str]]:
    en_out: list[str] = []
    tr_out: list[str] = []
    for opt in q.get("options") or []:
        if isinstance(opt, dict) and isinstance(opt.get("label"), dict):
            en_out.append(str(opt["label"].get("en", "")).strip())
            tr_out.append(str(opt["label"].get("tr", "")).strip())
        elif isinstance(opt, dict):
            en_out.append(str(opt.get("en", "")).strip())
            tr_out.append(str(opt.get("tr", "")).strip())
        else:
            en_out.append(str(opt).strip())
            tr_out.append("")
    return en_out, tr_out


def load_rows() -> list[QuestionRow]:
    rows: list[QuestionRow] = []
    for typ, path in FILES.items():
        data = json.loads(path.read_text(encoding="utf-8"))
        for s in data.get("sets", []):
            for q in s.get("questions", []):
                en, tr = _extract_question(q)
                oe, ot = _extract_options(q)
                rows.append(
                    QuestionRow(
                        type=typ,
                        set_id=s.get("id", ""),
                        qid=q.get("id", ""),
                        en=en,
                        tr=tr,
                        opts_en=oe,
                        opts_tr=ot,
                        correct=q.get("correctAnswer"),
                        dimension=q.get("dimension"),
                        difficulty=q.get("difficulty"),
                    )
                )
    return rows


def normalize_ws(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


def normalize_eq_situation(en: str) -> str:
    s = re.sub(r"\s*what's your most likely response\?\s*$", "", en.strip(), flags=re.I)
    for pat in REL_PATTERNS:
        s = re.sub(pat, "REL", s, flags=re.I)
    s = re.sub(r"^rel\s+", "", s, flags=re.I)
    return normalize_ws(s)


def option_signature(opts: list[str]) -> tuple[str, ...]:
    return tuple(sorted(normalize_ws(o) for o in opts))


def audit(rows: list[QuestionRow]) -> dict[str, Any]:
    summary = AuditSummary()
    summary.totals = {
        "iq": sum(1 for r in rows if r.type == "iq"),
        "eq": sum(1 for r in rows if r.type == "eq"),
        "frequency": sum(1 for r in rows if r.type == "frequency"),
        "all": len(rows),
    }

    findings: dict[str, list[dict[str, Any]]] = defaultdict(list)

    # --- Duplicates / templates ---
    eq_situations = Counter(normalize_eq_situation(r.en) for r in rows if r.type == "eq")
    summary.eq_unique_situations = len(eq_situations)
    summary.eq_situation_repeat_max = max(eq_situations.values()) if eq_situations else 0
    for situation, count in eq_situations.most_common():
        if count >= 5:
            sample = next(r for r in rows if r.type == "eq" and normalize_eq_situation(r.en) == situation)
            findings["duplicate_near_duplicate"].append(
                {
                    "type": "eq",
                    "pattern": situation,
                    "count": count,
                    "example_set_id": sample.set_id,
                    "example_question_id": sample.qid,
                    "note": "Relationship-context swap template",
                }
            )

    eq_money = [s for s in eq_situations if "money" in s or "pricey" in s]
    summary.eq_money_scenarios = sum(eq_situations[s] for s in eq_money)

    eq_opt_sets = Counter(
        option_signature(r.opts_en) for r in rows if r.type == "eq" and r.opts_en
    )
    summary.eq_option_set_count = len(eq_opt_sets)
    for sig, count in eq_opt_sets.most_common():
        if count >= 10:
            findings["duplicate_near_duplicate"].append(
                {
                    "type": "eq",
                    "pattern": "repeated_option_set",
                    "count": count,
                    "example_options_en": list(sig)[:2],
                    "note": "Same four-option archetype reused across many scenarios",
                }
            )

    iq_stems = Counter(normalize_ws(r.en) for r in rows if r.type == "iq")
    for stem, count in iq_stems.items():
        if count > 1:
            findings["duplicate_near_duplicate"].append(
                {"type": "iq", "pattern": stem[:120], "count": count}
            )

    # --- Length ---
    for r in rows:
        if len(r.tr) > LENGTH_THRESHOLDS["question_tr"]:
            findings["ux_length"].append(
                {
                    "kind": "question_tr",
                    "type": r.type,
                    "set_id": r.set_id,
                    "question_id": r.qid,
                    "length": len(r.tr),
                    "text": r.tr,
                }
            )
        if len(r.en) > LENGTH_THRESHOLDS["question_en"]:
            findings["ux_length"].append(
                {
                    "kind": "question_en",
                    "type": r.type,
                    "set_id": r.set_id,
                    "question_id": r.qid,
                    "length": len(r.en),
                    "text": r.en,
                }
            )
        for i, o in enumerate(r.opts_tr):
            if len(o) > LENGTH_THRESHOLDS["option_tr"]:
                findings["ux_length"].append(
                    {
                        "kind": "option_tr",
                        "type": r.type,
                        "set_id": r.set_id,
                        "question_id": r.qid,
                        "option_index": i,
                        "length": len(o),
                        "text": o,
                    }
                )
        for i, o in enumerate(r.opts_en):
            if len(o) > LENGTH_THRESHOLDS["option_en"]:
                findings["ux_length"].append(
                    {
                        "kind": "option_en",
                        "type": r.type,
                        "set_id": r.set_id,
                        "question_id": r.qid,
                        "option_index": i,
                        "length": len(o),
                        "text": o,
                    }
                )

    # --- Turkish / English heuristics ---
    for r in rows:
        for key, label, pat in TR_HEURISTICS:
            if pat.search(r.tr):
                findings["turkish_quality"].append(
                    {
                        "issue_type": key,
                        "label": label,
                        "type": r.type,
                        "set_id": r.set_id,
                        "question_id": r.qid,
                        "text_tr": r.tr,
                        "rewrite_direction": _tr_rewrite_direction(key),
                    }
                )
        for key, label, pat in EN_HEURISTICS:
            target = r.en
            if key in {"caricature_option", "moralizing_win"} and r.opts_en:
                for i, o in enumerate(r.opts_en):
                    if pat.search(o):
                        findings["english_quality"].append(
                            {
                                "issue_type": key,
                                "label": label,
                                "type": r.type,
                                "set_id": r.set_id,
                                "question_id": r.qid,
                                "text_en": o,
                                "option_index": i,
                                "rewrite_direction": _en_rewrite_direction(key),
                            }
                        )
                continue
            if pat.search(target):
                findings["english_quality"].append(
                    {
                        "issue_type": key,
                        "label": label,
                        "type": r.type,
                        "set_id": r.set_id,
                        "question_id": r.qid,
                        "text_en": target,
                        "rewrite_direction": _en_rewrite_direction(key),
                    }
                )

    # --- Design / scoring risks ---
    for r in rows:
        if r.type == "eq" and r.correct is not None and r.opts_en:
            win = r.opts_en[r.correct]
            if re.search(r"check in kindly|ask for a quick clarity window|stay curious|acknowledge", win, re.I):
                findings["design_scoring"].append(
                    {
                        "type": "eq",
                        "risk": "obvious_model_answer",
                        "set_id": r.set_id,
                        "question_id": r.qid,
                        "winning_option_en": win,
                    }
                )
        if r.type == "frequency" and re.search(
            r"I (?:prefer|enjoy|like|need|feel|value|am energized)|tercih ederim|severim",
            r.en + " " + r.tr,
            re.I,
        ):
            summary.frequency_abstract_count += 1
            findings["design_scoring"].append(
                {
                    "type": "frequency",
                    "risk": "abstract_self_report",
                    "set_id": r.set_id,
                    "question_id": r.qid,
                    "text_en": r.en,
                }
            )

    summary.issue_counts = {
        "duplicate_near_duplicate": len(findings["duplicate_near_duplicate"]),
        "turkish_quality": len(findings["turkish_quality"]),
        "english_quality": len(findings["english_quality"]),
        "ux_length": len(findings["ux_length"]),
        "design_scoring": len(findings["design_scoring"]),
    }

    by_type: dict[str, dict[str, int]] = {}
    for category, items in findings.items():
        by_type[category] = _count_by_type(items)

    # Readiness: structural EQ duplication + TR prompt literalism are blockers
    blocker = (
        summary.eq_unique_situations <= 25
        or summary.issue_counts["turkish_quality"] > 400
        or summary.issue_counts["design_scoring"] > 300
    )
    summary.readiness = "FAIL — rewrite recommended before publish" if blocker else "PASS WITH NOTES"

    summary.top_urgent = _top_urgent(findings, summary)
    return {
        "summary": summary.__dict__,
        "findings": findings,
        "by_type": by_type,
        "thresholds": LENGTH_THRESHOLDS,
    }


def _tr_rewrite_direction(key: str) -> str:
    return {
        "literal_prompt": "Use natural Turkish such as 'Bu durumda genelde ne yaparsın?' instead of test-language.",
        "generic_biri": "Name the relationship stage more specifically; avoid anonymous 'biri' when context exists.",
        "vague_sey": "Replace vague nouns with concrete emotional behavior.",
        "english_leak": "Localize loanwords into natural Turkish dating-app phrasing.",
        "formal_passive": "Shorten to conversational second-person Turkish.",
        "dash_clauses": "Split into one clear sentence; mobile-friendly length.",
    }.get(key, "Rewrite for conversational premium Turkish tone.")


def _en_rewrite_direction(key: str) -> str:
    return {
        "template_prompt": "Vary prompts; avoid identical assessment-test phrasing across hundreds of items.",
        "caricature_option": "Replace cartoonish wrong answers with plausible but less skilled responses.",
        "moralizing_win": "Add nuance so multiple answers could be reasonable; reduce therapy-speak model answer.",
        "generic_frequency": "Anchor statements in behavior frequency, not abstract self-image.",
        "abstract_frequency": "Make items concrete: texting pace, plan changes, depth of topics.",
    }.get(key, "Tighten for Minds First positioning: intelligent, modern, non-preachy.")


def _count_by_type(items: list[dict[str, Any]]) -> dict[str, int]:
    counts: Counter[str] = Counter(str(i.get("type", "unknown")) for i in items)
    return dict(counts)


def _top_urgent(findings: dict[str, list], summary: AuditSummary) -> list[dict[str, str]]:
    """Build urgent list from *current* findings only (no stale hardcoded blurbs)."""
    urgent: list[dict[str, str]] = []

    # --- Structural EQ (only if still broken) ---
    if summary.eq_unique_situations < 100 or summary.eq_situation_repeat_max >= 5:
        urgent.append(
            {
                "priority": "P0",
                "area": "EQ structure",
                "issue": (
                    f"Only {summary.eq_unique_situations} unique EQ situations across "
                    f"{summary.totals.get('eq', 0)} items; max repeat "
                    f"{summary.eq_situation_repeat_max}×."
                ),
                "action": "Rebuild EQ bank with distinct scenarios; cap template reuse.",
            }
        )

    lit = sum(1 for i in findings["turkish_quality"] if i.get("issue_type") == "literal_prompt")
    if lit >= 50:
        urgent.append(
            {
                "priority": "P0",
                "area": "EQ Turkish",
                "issue": f"{lit} items still use literal prompt phrasing (e.g. 'En olası tepkin hangisi olur?').",
                "action": "Replace with natural conversational Turkish prompts.",
            }
        )

    design_eq = sum(1 for i in findings["design_scoring"] if i.get("type") == "eq")
    if design_eq >= 50:
        urgent.append(
            {
                "priority": "P0",
                "area": "EQ design",
                "issue": f"{design_eq} obvious model-answer / pattern-match risks remain.",
                "action": "Rebalance distractors; add plausible alternatives; reduce moralizing tone.",
            }
        )
    elif design_eq > 0:
        sample = next(i for i in findings["design_scoring"] if i.get("type") == "eq")
        urgent.append(
            {
                "priority": "P2",
                "area": "EQ design",
                "issue": (
                    f"{design_eq} remaining obvious_model_answer flags "
                    f"(e.g. {sample.get('set_id')}/{sample.get('question_id')})."
                ),
                "action": "Light polish of winning options that still read as therapy-speak.",
            }
        )

    if summary.eq_money_scenarios >= 10:
        urgent.append(
            {
                "priority": "P1",
                "area": "EQ money scenario",
                "issue": (
                    f"Money/pricey-plan stress scenario appears "
                    f"{summary.eq_money_scenarios} times with relationship swaps only."
                ),
                "action": "Keep one canonical version; diversify financial-stress scenarios.",
            }
        )

    freq_abs = sum(
        1 for i in findings["design_scoring"] if i.get("risk") == "abstract_self_report"
    )
    if freq_abs >= 20:
        urgent.append(
            {
                "priority": "P1",
                "area": "Frequency abstract",
                "issue": f"{freq_abs} abstract/self-report Frequency items remain.",
                "action": "Rewrite to concrete connection-behavior statements.",
            }
        )

    # --- Remaining category volume by assessment type ---
    for category, priority_base in (
        ("turkish_quality", "P1"),
        ("english_quality", "P1"),
        ("design_scoring", "P2"),
        ("duplicate_near_duplicate", "P1"),
    ):
        items = findings.get(category) or []
        if not items:
            continue
        by_type = _count_by_type(items)
        # Skip if already covered as P0 structural above
        if category == "design_scoring" and design_eq >= 50:
            continue
        issue_types = Counter(
            str(i.get("issue_type") or i.get("risk") or i.get("pattern") or "other")
            for i in items
        )
        top_issue, top_n = issue_types.most_common(1)[0]
        type_bits = ", ".join(f"{t}={n}" for t, n in sorted(by_type.items()))
        urgent.append(
            {
                "priority": priority_base if len(items) >= 20 else "P2",
                "area": category,
                "issue": (
                    f"{len(items)} flags remaining ({type_bits}); "
                    f"top subtype '{top_issue}' ×{top_n}."
                ),
                "action": "See docs/assessment_final_content_audit.md for exact IDs.",
            }
        )

    for item in findings["ux_length"][:5]:
        urgent.append(
            {
                "priority": "P2",
                "area": "UX length",
                "issue": (
                    f"{item['kind']} len={item['length']} at "
                    f"{item['set_id']}/{item['question_id']}"
                ),
                "action": "Shorten for iPhone single-screen readability.",
            }
        )

    if not urgent:
        urgent.append(
            {
                "priority": "P3",
                "area": "readiness",
                "issue": "No high-priority structural blockers in current findings.",
                "action": "Optional light polish only; bank is publish-ready with notes.",
            }
        )

    return urgent[:20]


def print_report(result: dict[str, Any]) -> None:
    s = result["summary"]
    by_type = result.get("by_type") or {}
    print("=" * 72)
    print("Assessment Content Quality Audit (READ ONLY)")
    print("=" * 72)
    print(f"Totals: IQ={s['totals']['iq']} EQ={s['totals']['eq']} Frequency={s['totals']['frequency']}")
    print(f"Readiness: {s['readiness']}")
    print()
    print("Issue counts by category:")
    for k, v in s["issue_counts"].items():
        print(f"  - {k}: {v}")
    print()
    print("Issue counts by assessment type:")
    for category in (
        "duplicate_near_duplicate",
        "turkish_quality",
        "english_quality",
        "ux_length",
        "design_scoring",
    ):
        parts = by_type.get(category) or {}
        if not parts:
            print(f"  - {category}: (none)")
            continue
        bits = ", ".join(f"{t}={n}" for t, n in sorted(parts.items()))
        print(f"  - {category}: {bits}")
    print()
    print(f"EQ unique situations: {s['eq_unique_situations']} (max repeat {s['eq_situation_repeat_max']})")
    print(f"EQ unique option sets: {s['eq_option_set_count']}")
    print(f"EQ money/pricey scenarios: {s['eq_money_scenarios']}")
    print(f"Frequency abstract/self-report flagged: {s['frequency_abstract_count']}")
    print()
    print("Top urgent items (generated from current findings):")
    for item in s["top_urgent"][:10]:
        print(f"  [{item['priority']}] {item['area']}: {item['issue']}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true", help="Print full JSON findings")
    args = parser.parse_args()

    rows = load_rows()
    result = audit(rows)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print_report(result)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
