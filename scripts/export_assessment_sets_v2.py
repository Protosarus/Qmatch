#!/usr/bin/env python3
"""Export localized legacy assessment assets into immutable versioned v2 docs.

Dry-run / local export only:
  - Reads assets/data/assessment_sets/{iq,eq,frequency}_sets.json
  - Writes generated files under build/assessment_sets_v2/
  - Does NOT modify original asset JSON
  - Does NOT connect to or write Firestore

Usage:
  python3 scripts/export_assessment_sets_v2.py

Then validate exports:
  python3 scripts/validate_assessment_sets.py --from-dir build/assessment_sets_v2
"""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "data" / "assessment_sets"
OUT_DIR = ROOT / "build" / "assessment_sets_v2"

VERSION = 2
STATUS = "published"
LANGUAGE_MODE = "localized"

SOURCE_FILES = {
    "iq": ASSETS / "iq_sets.json",
    "eq": ASSETS / "eq_sets.json",
    "frequency": ASSETS / "frequency_sets.json",
}

OUTPUT_FILES = {
    "iq": OUT_DIR / "iq_sets_v2.json",
    "eq": OUT_DIR / "eq_sets_v2.json",
    "frequency": OUT_DIR / "frequency_sets_v2.json",
}
ALL_OUTPUT = OUT_DIR / "all_assessment_sets_v2.json"

# Allow `import validate_assessment_sets` when run as a script.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import validate_assessment_sets as vas  # noqa: E402


def convert_set_to_v2(source: dict[str, Any], expected_type: str) -> dict[str, Any]:
    """Convert one legacy set into a versioned v2 document (questions untouched)."""
    raw_id = source.get("id")
    if not isinstance(raw_id, str) or not raw_id.strip():
        raise ValueError(f"set missing id: {source!r}")

    base_id = raw_id.strip()
    parsed = vas.parse_set_id(base_id)
    if parsed.kind != "legacy":
        raise ValueError(
            f"source set id must be legacy (got {base_id!r}, kind={parsed.kind})"
        )
    if parsed.type_name != expected_type:
        raise ValueError(
            f"{base_id}: type {parsed.type_name!r} does not match {expected_type!r}"
        )

    questions = copy.deepcopy(source.get("questions"))
    if not isinstance(questions, list):
        raise ValueError(f"{base_id}: questions must be a list")

    set_number = parsed.set_number
    if set_number is None:
        sn = source.get("set_number")
        if isinstance(sn, int) and not isinstance(sn, bool):
            set_number = sn
        else:
            raise ValueError(f"{base_id}: cannot determine set_number")

    # Soft string version (e.g. "2026_01") and legacy id are replaced intentionally.
    # Questions / order / scoring fields are preserved via deep copy.
    return {
        "id": f"{base_id}_v{VERSION}",
        "base_id": base_id,
        "type": expected_type,
        "set_number": set_number,
        "version": VERSION,
        "active": True,
        "status": STATUS,
        "language_mode": LANGUAGE_MODE,
        "question_count": len(questions),
        "questions": questions,
    }


def load_sets(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    sets = data.get("sets") if isinstance(data, dict) else None
    if not isinstance(sets, list):
        raise ValueError(f"{path}: top-level 'sets' array required")
    out: list[dict[str, Any]] = []
    for i, item in enumerate(sets):
        if not isinstance(item, dict):
            raise ValueError(f"{path}: sets[{i}] is not an object")
        out.append(item)
    return out


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def export_all() -> dict[str, Any]:
    source_counts: dict[str, int] = {}
    source_questions: dict[str, int] = {}
    exported_by_type: dict[str, list[dict[str, Any]]] = {}
    notes: list[str] = []

    for type_name, src_path in SOURCE_FILES.items():
        if not src_path.exists():
            raise FileNotFoundError(src_path)
        legacy_sets = load_sets(src_path)
        source_counts[type_name] = len(legacy_sets)
        q_total = 0
        converted: list[dict[str, Any]] = []
        for s in legacy_sets:
            q = s.get("questions")
            if isinstance(q, list):
                q_total += len(q)
            # Soft calendar version string is superseded by integer version: 2.
            if isinstance(s.get("version"), str):
                notes.append(
                    f"{s.get('id')}: replaced soft version {s.get('version')!r} "
                    f"with integer version {VERSION}"
                )
            converted.append(convert_set_to_v2(s, type_name))
        source_questions[type_name] = q_total
        exported_by_type[type_name] = converted
        write_json(OUTPUT_FILES[type_name], {"sets": converted})

    all_sets = (
        exported_by_type["iq"]
        + exported_by_type["eq"]
        + exported_by_type["frequency"]
    )
    write_json(
        ALL_OUTPUT,
        {
            "schema": "assessment_sets_v2",
            "version": VERSION,
            "status": STATUS,
            "language_mode": LANGUAGE_MODE,
            "active": True,
            "set_count": len(all_sets),
            "sets": all_sets,
        },
    )

    return {
        "source_counts": source_counts,
        "source_questions": source_questions,
        "exported_by_type": {k: len(v) for k, v in exported_by_type.items()},
        "exported_questions": {
            k: sum(len(s["questions"]) for s in v)
            for k, v in exported_by_type.items()
        },
        "notes": notes,
        "exported_payloads": {
            k: {"sets": v} for k, v in exported_by_type.items()
        },
    }


def validate_exports(payloads: dict[str, dict[str, Any]]) -> tuple[bool, dict[str, vas.TypeResult]]:
    results = {
        t: vas.validate_type_data(t, payloads[t], source_label=OUTPUT_FILES[t].name)
        for t in ("iq", "eq", "frequency")
    }
    ok = vas.print_report(results)
    return ok, results


def print_export_report(
    meta: dict[str, Any],
    validation_ok: bool,
) -> None:
    sc = meta["source_counts"]
    sq = meta["source_questions"]
    ec = meta["exported_by_type"]
    eq = meta["exported_questions"]
    src_docs = sum(sc.values())
    src_q = sum(sq.values())
    exp_docs = sum(ec.values())
    exp_q = sum(eq.values())

    print("Assessment v2 Export Report")
    print()
    print("Source:")
    print(f"- legacy docs read: {src_docs}")
    print(
        f"- IQ/EQ/Frequency: {sc['iq']}/{sc['eq']}/{sc['frequency']}"
    )
    print(f"- source questions: {src_q}")
    print()
    print("Export:")
    print(f"- versioned docs generated: {exp_docs}")
    print(
        f"- IQ/EQ/Frequency: {ec['iq']}/{ec['eq']}/{ec['frequency']}"
    )
    print(f"- exported questions: {exp_q}")
    print(f"- version: {VERSION}")
    print(f"- status: {STATUS}")
    print("- active: true")
    print(f"- language_mode: {LANGUAGE_MODE}")
    print(f"- output files written to: {OUT_DIR}/")
    for name in (
        "iq_sets_v2.json",
        "eq_sets_v2.json",
        "frequency_sets_v2.json",
        "all_assessment_sets_v2.json",
    ):
        print(f"  · {name}")
    print()
    print("Conversion notes:")
    print(
        "- Soft string `version` fields from legacy assets are replaced by "
        f"integer version {VERSION}."
    )
    print("- Question text, order, options, correctAnswer, dimensions unchanged.")
    print(f"- Soft-version replacements noted: {len(meta['notes'])}")
    print()
    print("Validation:")
    print(f"- {'PASS' if validation_ok else 'FAIL'}")
    print("- legacy source unchanged: yes")
    print("- Firestore writes performed: no")
    print()


def main() -> int:
    try:
        meta = export_all()
    except Exception as e:
        print(f"Export FAILED: {e}", file=sys.stderr)
        return 1

    print("=" * 72)
    print("Validating generated v2 export…")
    print("=" * 72)
    ok, _ = validate_exports(meta["exported_payloads"])
    print()
    print_export_report(meta, ok)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
