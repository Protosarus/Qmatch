#!/usr/bin/env python3
"""Strict validator for assets/data/assessment_v3/iq/iq_bank_tr_v1.json."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

EXPECTED_DIMS = {
    "logical_reasoning": 100,
    "pattern_reasoning": 80,
    "verbal_reasoning": 80,
    "spatial_reasoning": 80,
}
EXPECTED_ANSWERS = {"a": 97, "b": 86, "c": 81, "d": 76}
EXPECTED_REWRITTEN = {
    "logical_reasoning": 1,
    "pattern_reasoning": 14,
    "verbal_reasoning": 9,
    "spatial_reasoning": 16,
}
CONTROL_RE = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F]")
HEADER_FOOTER_RE = re.compile(
    r"(sayfa\s+\d+|page\s+\d+|qmatch\s*bilişsel muhakeme soru bankası v2)",
    re.IGNORECASE,
)
LEADING_NUM_RE = re.compile(r"^\d+\.\s+")


def normalize(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "").strip().lower())


def validate(bank: dict) -> dict:
    errors: list[dict] = []
    warnings: list[dict] = []

    def err(code: str, message: str, **extra):
        errors.append({"code": code, "message": message, **extra})

    def warn(code: str, message: str, **extra):
        warnings.append({"code": code, "message": message, **extra})

    if bank.get("schema_version") != "qmatch_iq_bank_v1":
        err("schema_version", f"Unexpected schema_version={bank.get('schema_version')}")
    if bank.get("locale") != "tr-TR":
        err("locale", f"Unexpected locale={bank.get('locale')}")

    items = bank.get("items")
    if not isinstance(items, list):
        err("items", "items must be a list")
        return {"errors": errors, "warnings": warnings}

    if len(items) != 340:
        err("count", f"Expected 340 items, found {len(items)}")

    ids = [i.get("id") for i in items]
    if len(set(ids)) != len(ids):
        err("duplicate_ids", "Duplicate item IDs present")
    if len(set(ids)) != 340 and len(items) == 340:
        err("unique_ids", f"Expected 340 unique IDs, found {len(set(ids))}")

    prompts = [normalize(i.get("prompt", "")) for i in items]
    if any(not p for p in prompts):
        err("missing_prompt", "One or more empty prompts")
    if len(set(prompts)) != len(prompts):
        err("duplicate_prompts", "Duplicate normalized prompts present")

    dims = Counter(i.get("dimension") for i in items)
    for d, n in EXPECTED_DIMS.items():
        if dims.get(d, 0) != n:
            err("dimension_distribution", f"{d}: expected {n}, found {dims.get(d, 0)}")
    if "numerical" in dims:
        err("retired_numerical", "Retired numerical dimension present")
    unsupported = set(dims) - set(EXPECTED_DIMS)
    if unsupported:
        err("unsupported_dimension", f"Unsupported dimensions: {sorted(unsupported)}")

    families = defaultdict(list)
    for i in items:
        fam = i.get("template_family_id")
        if not fam:
            err("missing_family", "Missing template_family_id", item_id=i.get("id"))
        else:
            families[fam].append(i.get("id"))
    if len(families) != 170:
        err("family_count", f"Expected 170 families, found {len(families)}")
    bad_families = {f: ids_ for f, ids_ in families.items() if len(ids_) != 2}
    if bad_families:
        err(
            "family_variants",
            f"{len(bad_families)} families do not have exactly 2 variants",
            examples=dict(list(bad_families.items())[:5]),
        )

    answers = Counter()
    rewritten = Counter()
    for i in items:
        opts = i.get("options")
        if not isinstance(opts, list) or len(opts) != 4:
            err("option_count", "Expected exactly 4 options", item_id=i.get("id"))
            continue
        opt_ids = [o.get("id") for o in opts]
        if opt_ids != ["a", "b", "c", "d"]:
            err("option_ids", f"Option IDs must be a/b/c/d, got {opt_ids}", item_id=i.get("id"))
        if len(set(opt_ids)) != 4:
            err("duplicate_option_id", "Duplicate option IDs", item_id=i.get("id"))
        texts = [normalize(o.get("text", "")) for o in opts]
        if any(not t for t in texts):
            err("empty_option", "Empty option text", item_id=i.get("id"))
        if len(set(texts)) != 4:
            err("duplicate_option_text", "Duplicate option texts", item_id=i.get("id"))
        correct = i.get("correct_option_id")
        if correct not in {"a", "b", "c", "d"}:
            err("correct_option_id", f"Invalid correct_option_id={correct}", item_id=i.get("id"))
        elif correct not in opt_ids:
            err("missing_correct_option", "correct_option_id not in options", item_id=i.get("id"))
        else:
            answers[correct] += 1
        prompt = i.get("prompt", "")
        if CONTROL_RE.search(prompt) or any(CONTROL_RE.search(o.get("text", "")) for o in opts):
            err("control_chars", "Control characters present", item_id=i.get("id"))
        if HEADER_FOOTER_RE.search(prompt):
            err("header_footer_leak", "Prompt looks like header/footer", item_id=i.get("id"))
        if LEADING_NUM_RE.match(prompt):
            err("question_number_prefix", "Prompt starts with question number", item_id=i.get("id"))
        rev = i.get("revision_status")
        if rev == "rewritten_v2":
            rewritten[i.get("dimension")] += 1
        elif rev != "retained_v2":
            err("revision_status", f"Unexpected revision_status={rev}", item_id=i.get("id"))
        if i.get("review_status") != "desk_reviewed_candidate":
            err(
                "review_status",
                f"Unexpected review_status={i.get('review_status')}",
                item_id=i.get("id"),
            )

    if sum(rewritten.values()) != 40:
        err("rewritten_count", f"Expected 40 rewritten, found {sum(rewritten.values())}")
    for d, n in EXPECTED_REWRITTEN.items():
        if rewritten.get(d, 0) != n:
            err(
                "rewritten_distribution",
                f"{d}: expected {n} rewritten, found {rewritten.get(d, 0)}",
            )

    for letter, n in EXPECTED_ANSWERS.items():
        if answers.get(letter, 0) != n:
            err(
                "answer_distribution",
                f"{letter}: expected {n}, found {answers.get(letter, 0)}",
            )

    # Exactly one answer key per item already implied by required field + uniqueness of ids
    return {
        "ok": not errors,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "summary": {
            "item_count": len(items),
            "unique_ids": len(set(ids)),
            "unique_prompts": len(set(prompts)),
            "dimension_counts": dict(dims),
            "family_count": len(families),
            "rewritten_counts": dict(rewritten),
            "answer_position_counts": dict(answers),
            "missing_metadata": [
                "difficulty",
                "rationale",
                "subskill",
                "estimated_completion_time",
                "psychometric_parameters",
            ],
            "fabricated_metadata": False,
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--bank",
        default="assets/data/assessment_v3/iq/iq_bank_tr_v1.json",
    )
    ap.add_argument(
        "--report",
        default="assets/data/assessment_v3/iq/reports/iq_bank_tr_v1_validation.json",
    )
    args = ap.parse_args()
    path = Path(args.bank)
    if not path.exists():
        print(f"MISSING {path}", file=sys.stderr)
        return 2
    raw = path.read_bytes()
    try:
        bank = json.loads(raw.decode("utf-8"))
    except Exception as exc:  # noqa: BLE001
        print(f"JSON_DECODE_FAIL {exc}", file=sys.stderr)
        return 1
    report = validate(bank)
    report["bank_path"] = path.as_posix()
    report["bank_sha256"] = hashlib.sha256(raw).hexdigest()
    out = Path(args.report)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": report["ok"], "error_count": report["error_count"]}, ensure_ascii=False))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
