#!/usr/bin/env python3
"""Dry-run audit: what would be synced from localized assets to Firestore.

Usage:
  python3 scripts/audit_assessment_firestore_sync.py

DRY RUN ONLY — does not connect to Firebase, does not write to Firestore,
does not modify assessment JSON.

Mirrors existing upload helper behavior:
  lib/features/debug/helpers/upload_assessment_sets_helper.dart
  → collection `assessment_sets`
  → document ID = set `id`
  → SetOptions(merge: true)
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "data" / "assessment_sets"

FILES = {
    "iq": ASSETS / "iq_sets.json",
    "eq": ASSETS / "eq_sets.json",
    "frequency": ASSETS / "frequency_sets.json",
}

EXPECTED = {
    "iq": {
        "count": 50,
        "id_prefix": "iq_set_",
        "questions_per_set": 10,
        "has_options": True,
        "requires_correct_answer": True,
    },
    "eq": {
        "count": 50,
        "id_prefix": "eq_set_",
        "questions_per_set": 10,
        "has_options": True,
        "requires_correct_answer": True,
    },
    "frequency": {
        "count": 50,
        "id_prefix": "frequency_set_",
        "questions_per_set": 12,
        "has_options": False,
        "requires_correct_answer": False,
    },
}

COLLECTION = "assessment_sets"


def non_empty_str(v: Any) -> bool:
    return isinstance(v, str) and bool(v.strip())


def question_text_raw(q: dict[str, Any]) -> Any:
    if "text" in q:
        return q["text"]
    return q.get("question")


def is_localized_text(raw: Any) -> bool:
    if not isinstance(raw, dict):
        return False
    return non_empty_str(raw.get("en")) and non_empty_str(raw.get("tr"))


def option_label_map(opt: Any) -> dict[str, Any] | None:
    if not isinstance(opt, dict):
        return None
    label = opt.get("label")
    if isinstance(label, dict):
        return label
    if "en" in opt or "tr" in opt:
        return opt
    text = opt.get("text")
    if isinstance(text, dict):
        return text
    return None


def is_localized_option(opt: Any) -> bool:
    m = option_label_map(opt)
    if m is None:
        return False
    return non_empty_str(m.get("en")) and non_empty_str(m.get("tr"))


def expected_ids(prefix: str, count: int) -> list[str]:
    return [f"{prefix}{i:03d}" for i in range(1, count + 1)]


class TypeAudit:
    def __init__(self, type_name: str):
        self.type_name = type_name
        self.issues: list[str] = []
        self.doc_ids: list[str] = []
        self.set_count = 0
        self.question_total = 0
        self.fully_localized_sets = 0
        self.fully_localized_questions = 0
        self.active_true = 0
        self.with_version = 0
        self.correct_answer_ok = True
        self.sample_fields: dict[str, Any] | None = None


def audit_type(type_name: str) -> TypeAudit:
    cfg = EXPECTED[type_name]
    path = FILES[type_name]
    result = TypeAudit(type_name)

    if not path.exists():
        result.issues.append(f"Missing file: {path}")
        return result

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        result.issues.append(f"Invalid JSON in {path.name}: {e}")
        return result

    sets = data.get("sets") if isinstance(data, dict) else None
    if not isinstance(sets, list):
        result.issues.append(f"{path.name}: top-level 'sets' array is required")
        return result

    result.set_count = len(sets)
    expect = expected_ids(cfg["id_prefix"], cfg["count"])
    by_id: dict[str, dict[str, Any]] = {}

    for i, s in enumerate(sets):
        if not isinstance(s, dict):
            result.issues.append(f"{type_name}: sets[{i}] is not an object")
            continue
        sid = s.get("id")
        if not non_empty_str(sid):
            result.issues.append(f"{type_name}: sets[{i}] missing id")
            continue
        sid = str(sid)
        if sid in by_id:
            result.issues.append(f"{type_name}: duplicate set id {sid}")
            continue
        by_id[sid] = s

    if result.set_count != cfg["count"]:
        result.issues.append(
            f"{type_name}: expected {cfg['count']} sets, found {result.set_count}"
        )

    missing = [x for x in expect if x not in by_id]
    unexpected = [x for x in by_id if x not in expect]
    if missing:
        result.issues.append(
            f"{type_name}: missing set ids: {', '.join(missing[:10])}"
            + (" ..." if len(missing) > 10 else "")
        )
    if unexpected:
        result.issues.append(
            f"{type_name}: unexpected set ids: {', '.join(unexpected[:10])}"
            + (" ..." if len(unexpected) > 10 else "")
        )

    for sid in expect:
        s = by_id.get(sid)
        if s is None:
            continue

        result.doc_ids.append(sid)
        if result.sample_fields is None:
            result.sample_fields = {
                "id": s.get("id"),
                "type": s.get("type"),
                "set_number": s.get("set_number"),
                "version": s.get("version"),
                "active": s.get("active"),
                "question_count": s.get("question_count"),
                "top_level_keys": sorted(s.keys()),
            }

        if s.get("active") is True:
            result.active_true += 1
        if non_empty_str(s.get("version")):
            result.with_version += 1

        questions = s.get("questions")
        if not isinstance(questions, list):
            result.issues.append(f"{sid}: questions must be a list")
            continue

        qn = len(questions)
        result.question_total += qn
        if qn != cfg["questions_per_set"]:
            result.issues.append(
                f"{sid}: expected {cfg['questions_per_set']} questions, found {qn}"
            )

        set_fully_localized = True
        for qi, q in enumerate(questions):
            if not isinstance(q, dict):
                result.issues.append(f"{sid} q[{qi}]: not an object")
                set_fully_localized = False
                continue

            qid = q.get("id") or f"{sid}_q_{qi + 1}"
            raw = question_text_raw(q)
            q_loc = is_localized_text(raw)
            if not q_loc:
                result.issues.append(
                    f"{qid}: question text must be localized {{en,tr}} "
                    "(Phase 2O expects all sets fully localized)"
                )
                set_fully_localized = False

            if cfg["has_options"]:
                opts = q.get("options")
                if not isinstance(opts, list) or not opts:
                    result.issues.append(f"{qid}: options must be non-empty")
                    set_fully_localized = False
                    continue
                for oi, opt in enumerate(opts):
                    if not is_localized_option(opt):
                        result.issues.append(
                            f"{qid} option[{oi}]: missing en+tr labels"
                        )
                        set_fully_localized = False

                ca = q.get("correctAnswer")
                if cfg["requires_correct_answer"]:
                    if isinstance(ca, bool) or not isinstance(ca, int):
                        if isinstance(ca, float) and ca.is_integer():
                            ca = int(ca)
                        else:
                            result.issues.append(
                                f"{qid}: correctAnswer must be int index "
                                f"(got {type(ca).__name__}: {ca!r})"
                            )
                            result.correct_answer_ok = False
                            set_fully_localized = False
                            continue
                    if ca < 0 or ca >= len(opts):
                        result.issues.append(
                            f"{qid}: correctAnswer {ca} out of range "
                            f"for {len(opts)} options"
                        )
                        result.correct_answer_ok = False
                        set_fully_localized = False

                if q_loc and all(is_localized_option(o) for o in opts):
                    result.fully_localized_questions += 1
                else:
                    set_fully_localized = False
            else:
                if not non_empty_str(q.get("dimension")):
                    result.issues.append(f"{qid}: missing dimension")
                    set_fully_localized = False
                if "reverseScored" in q and not isinstance(
                    q["reverseScored"], bool
                ):
                    result.issues.append(
                        f"{qid}: reverseScored must be boolean if present"
                    )
                    set_fully_localized = False
                if q_loc:
                    result.fully_localized_questions += 1
                else:
                    set_fully_localized = False

        if set_fully_localized and qn == cfg["questions_per_set"]:
            result.fully_localized_sets += 1

    return result


def print_report(results: dict[str, TypeAudit]) -> bool:
    print("=" * 72)
    print("Firestore Assessment Sets Sync Audit (DRY RUN)")
    print("=" * 72)
    print()
    print("DRY RUN ONLY — no Firestore writes performed")
    print("No Firebase credentials required; no network connection used.")
    print()

    print("Existing upload helper findings")
    print("-" * 40)
    print(
        "Helper: lib/features/debug/helpers/upload_assessment_sets_helper.dart"
    )
    print(f"Collection: {COLLECTION}")
    print("Document IDs: set `id` (e.g. iq_set_001, eq_set_042, frequency_set_050)")
    print("Write mode: set(..., SetOptions(merge: true))")
    print("Timestamps: writes/merges created_at + updated_at (serverTimestamp)")
    print("Payload: full set object from assets (id, type, set_number, version,")
    print("         active, question_count, questions[...])")
    print("Language fields: none at set top-level; localization lives inside")
    print("                 question/option maps ({en,tr} / label.{en,tr})")
    print("Dry-run mode in helper: default (Phase 2Q); writes need gates")
    print("Write gates: kDebugMode + dart-define")
    print("            QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true")
    print("            + dryRun:false + confirmation phrase")
    print("Production UI auto-call: not referenced from app UI currently")
    print("                         (callable only if something invokes the helper)")
    print("App load order: Firestore assessment_sets first, then assets fallback")
    print()

    overall_ok = True
    total_docs = 0
    total_questions = 0

    for key in ("iq", "eq", "frequency"):
        r = results[key]
        cfg = EXPECTED[key]
        label = key.upper() if key != "frequency" else "Frequency"
        expected_q = cfg["count"] * cfg["questions_per_set"]
        total_docs += len(r.doc_ids)
        total_questions += r.question_total

        print(f"{label}")
        print("-" * 40)
        print(f"- Asset file: {FILES[key].relative_to(ROOT)}")
        print(f"- Sets / docs that would sync: {len(r.doc_ids)}/{cfg['count']}")
        print(f"- Questions: {r.question_total} (expected {expected_q})")
        print(
            f"- Fully localized sets: "
            f"{r.fully_localized_sets}/{cfg['count']}"
        )
        print(
            f"- Fully localized questions: "
            f"{r.fully_localized_questions}/{r.question_total or expected_q}"
        )
        print(f"- active=true: {r.active_true}/{len(r.doc_ids)}")
        print(f"- with non-empty version: {r.with_version}/{len(r.doc_ids)}")
        print(
            f"- correctAnswer indices valid: "
            f"{'yes' if r.correct_answer_ok else 'NO'}"
        )
        if r.doc_ids:
            print(
                f"- Firestore paths (first/last): "
                f"{COLLECTION}/{r.doc_ids[0]} … "
                f"{COLLECTION}/{r.doc_ids[-1]}"
            )
        if r.sample_fields:
            print(f"- Sample top-level keys: {r.sample_fields['top_level_keys']}")
            print(
                f"- Sample metadata: type={r.sample_fields['type']!r} "
                f"version={r.sample_fields['version']!r} "
                f"active={r.sample_fields['active']!r}"
            )
        print(f"- Issues: {len(r.issues)}")
        if r.issues:
            overall_ok = False
            for issue in r.issues[:30]:
                print(f"  ✗ {issue}")
            if len(r.issues) > 30:
                print(f"  … and {len(r.issues) - 30} more")
        print()

    print("Would-be sync summary")
    print("-" * 40)
    print(f"- Collection: {COLLECTION}")
    print(f"- Total documents: {total_docs}")
    print(f"- IQ documents: {len(results['iq'].doc_ids)}")
    print(f"- EQ documents: {len(results['eq'].doc_ids)}")
    print(f"- Frequency documents: {len(results['frequency'].doc_ids)}")
    print(f"- Total questions: {total_questions}")
    print(
        "- Write semantics (if a future sync phase runs the helper): "
        "merge=true by set id"
    )
    print()

    print("Recommended safe sync strategy (for a later approved phase)")
    print("-" * 40)
    print("1. Run: python3 scripts/validate_assessment_sets.py  (must PASS)")
    print("2. Run this dry-run audit again and review counts/IDs.")
    print("3. Preferred publish source: versioned v2 export (do not overwrite")
    print("   legacy iq_set_001 in-place):")
    print("   python3 scripts/export_assessment_sets_v2.py")
    print("   → build/assessment_sets_v2/ (local only; not Firestore)")
    print("4. Back up existing Firestore collection `assessment_sets`.")
    print("5. Sync immutable v2 doc IDs (iq_set_001_v2, …) in an approved phase.")
    print("6. Prefer merge only if field shapes are compatible;")
    print("   otherwise replace per-doc carefully after backup.")
    print("7. Preserve/confirm active/status/version as used by assignment.")
    print("8. Test with one debug account before any broad rollout.")
    print("9. Archive legacy v1 docs for *new* assignment only after verification.")
    print("10. Actual Firestore upload must be a separate explicitly approved phase.")
    print()

    print("Overall audit:")
    print(f"- {'PASS' if overall_ok else 'FAIL'}")
    print("- DRY RUN ONLY — no Firestore writes performed")
    return overall_ok


def main() -> int:
    results = {t: audit_type(t) for t in ("iq", "eq", "frequency")}
    ok = print_report(results)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
