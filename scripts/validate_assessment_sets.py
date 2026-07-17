#!/usr/bin/env python3
"""Validate Qmatch assessment set JSON for structure and localization safety.

Supports:
  - Legacy IDs: iq_set_001, eq_set_001, frequency_set_001
  - Versioned IDs: iq_set_001_v2, eq_set_001_v2, frequency_set_001_v2
    (with base_id, integer version, status, active, language_mode)

Current bundled assets remain legacy schema and must still PASS.

Usage:
  python3 scripts/validate_assessment_sets.py

Exits 0 on PASS, non-zero on FAIL.

Does not modify JSON files.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal


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
        "type": "iq",
        "questions_per_set": 10,
        "pilot": "iq_set_001",
        "has_options": True,
        "requires_correct_answer": True,
    },
    "eq": {
        "count": 50,
        "id_prefix": "eq_set_",
        "type": "eq",
        "questions_per_set": 10,
        "pilot": "eq_set_001",
        "has_options": True,
        "requires_correct_answer": True,
    },
    "frequency": {
        "count": 50,
        "id_prefix": "frequency_set_",
        "type": "frequency",
        "questions_per_set": 12,
        "pilot": "frequency_set_001",
        "has_options": False,
        "requires_correct_answer": False,
    },
}

VALID_STATUSES = frozenset({"draft", "published", "archived"})
SchemaKind = Literal["legacy", "versioned", "malformed"]


# ---------------------------------------------------------------------------
# ID parsing helpers
# ---------------------------------------------------------------------------

_LEGACY_RE = re.compile(
    r"^(?P<type>iq|eq|frequency)_set_(?P<num>\d{3})$"
)
_VERSIONED_RE = re.compile(
    r"^(?P<type>iq|eq|frequency)_set_(?P<num>\d{3})_v(?P<ver>\d+)$"
)


@dataclass(frozen=True)
class ParsedSetId:
    kind: SchemaKind
    raw: str
    type_name: str | None = None
    set_number: int | None = None
    version: int | None = None
    base_id: str | None = None


def parse_set_id(set_id: str) -> ParsedSetId:
    """Parse a set id as legacy, versioned, or malformed."""
    sid = (set_id or "").strip()
    m_v = _VERSIONED_RE.fullmatch(sid)
    if m_v:
        type_name = m_v.group("type")
        num = int(m_v.group("num"))
        ver = int(m_v.group("ver"))
        return ParsedSetId(
            kind="versioned",
            raw=sid,
            type_name=type_name,
            set_number=num,
            version=ver,
            base_id=f"{type_name}_set_{num:03d}",
        )
    m_l = _LEGACY_RE.fullmatch(sid)
    if m_l:
        type_name = m_l.group("type")
        num = int(m_l.group("num"))
        return ParsedSetId(
            kind="legacy",
            raw=sid,
            type_name=type_name,
            set_number=num,
            version=None,
            base_id=sid,
        )
    return ParsedSetId(kind="malformed", raw=sid)


def is_legacy_set_id(set_id: str) -> bool:
    return parse_set_id(set_id).kind == "legacy"


def is_versioned_set_id(set_id: str) -> bool:
    return parse_set_id(set_id).kind == "versioned"


def validate_versioned_metadata(
    set_obj: dict[str, Any],
    parsed: ParsedSetId,
    expected_type: str,
) -> list[str]:
    """Validate architecture fields required on versioned (`*_vN`) sets."""
    issues: list[str] = []
    sid = parsed.raw

    if parsed.type_name != expected_type:
        issues.append(
            f"{sid}: versioned id type '{parsed.type_name}' does not match "
            f"file type '{expected_type}'"
        )

    base_id = set_obj.get("base_id")
    if not non_empty_str(base_id):
        issues.append(f"{sid}: versioned set requires non-empty base_id")
    else:
        base_id = str(base_id).strip()
        if base_id != parsed.base_id:
            issues.append(
                f"{sid}: base_id '{base_id}' must equal '{parsed.base_id}'"
            )

    version = set_obj.get("version")
    if isinstance(version, bool) or not isinstance(version, int):
        issues.append(
            f"{sid}: versioned set requires integer version >= 1 "
            f"(got {type(version).__name__}: {version!r})"
        )
    elif version < 1:
        issues.append(f"{sid}: version must be >= 1 (got {version})")
    elif parsed.version is not None and version != parsed.version:
        issues.append(
            f"{sid}: version field {version} does not match id suffix v{parsed.version}"
        )

    type_field = set_obj.get("type")
    if not non_empty_str(type_field):
        issues.append(f"{sid}: versioned set requires type")
    elif str(type_field).strip() != expected_type:
        issues.append(
            f"{sid}: type '{type_field}' must equal '{expected_type}'"
        )

    set_number = set_obj.get("set_number")
    if isinstance(set_number, bool) or not isinstance(set_number, int):
        issues.append(
            f"{sid}: versioned set requires integer set_number "
            f"(got {type(set_number).__name__}: {set_number!r})"
        )
    elif parsed.set_number is not None and set_number != parsed.set_number:
        issues.append(
            f"{sid}: set_number {set_number} does not match id number "
            f"{parsed.set_number}"
        )

    status = set_obj.get("status")
    if not non_empty_str(status):
        issues.append(
            f"{sid}: versioned set requires status "
            f"(draft|published|archived)"
        )
    elif str(status).strip() not in VALID_STATUSES:
        issues.append(
            f"{sid}: status '{status}' must be one of "
            f"{sorted(VALID_STATUSES)}"
        )

    if "active" not in set_obj:
        issues.append(f"{sid}: versioned set requires boolean active")
    elif not isinstance(set_obj.get("active"), bool):
        issues.append(
            f"{sid}: active must be boolean "
            f"(got {type(set_obj.get('active')).__name__})"
        )

    language_mode = set_obj.get("language_mode")
    if not non_empty_str(language_mode):
        issues.append(f"{sid}: versioned set requires language_mode")
    else:
        mode = str(language_mode).strip()
        if mode not in ("localized", "legacy_en"):
            issues.append(
                f"{sid}: language_mode '{mode}' must be "
                f"'localized' or 'legacy_en'"
            )

    questions = set_obj.get("questions")
    q_len = len(questions) if isinstance(questions, list) else None
    qc = set_obj.get("question_count")
    if q_len is None:
        issues.append(f"{sid}: questions must be a list")
    elif isinstance(qc, bool) or not isinstance(qc, int):
        issues.append(
            f"{sid}: versioned set requires integer question_count "
            f"matching questions.length"
        )
    elif qc != q_len:
        issues.append(
            f"{sid}: question_count {qc} does not match "
            f"questions.length {q_len}"
        )

    return issues


def non_empty_str(v: Any) -> bool:
    return isinstance(v, str) and bool(v.strip())


def question_text_raw(q: dict[str, Any]) -> Any:
    if "text" in q:
        return q["text"]
    return q.get("question")


def resolve_en(raw: Any) -> str | None:
    if isinstance(raw, str):
        s = raw.strip()
        return s if s else None
    if isinstance(raw, dict):
        en = raw.get("en")
        return str(en).strip() if non_empty_str(en) else None
    return None


def resolve_tr(raw: Any) -> str | None:
    if isinstance(raw, dict):
        tr = raw.get("tr")
        return str(tr).strip() if non_empty_str(tr) else None
    return None


def is_localized_text(raw: Any) -> bool:
    return resolve_en(raw) is not None and resolve_tr(raw) is not None


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


def option_en(opt: Any) -> str | None:
    if isinstance(opt, str):
        return opt.strip() if opt.strip() else None
    m = option_label_map(opt)
    if m is not None:
        return resolve_en(m)
    if isinstance(opt, dict) and isinstance(opt.get("label"), str):
        return opt["label"].strip() or None
    return None


def option_tr(opt: Any) -> str | None:
    m = option_label_map(opt)
    if m is not None:
        return resolve_tr(m)
    return None


def is_localized_option(opt: Any) -> bool:
    return option_en(opt) is not None and option_tr(opt) is not None


def expected_legacy_ids(prefix: str, count: int) -> list[str]:
    return [f"{prefix}{i:03d}" for i in range(1, count + 1)]


def schema_profile(legacy_n: int, versioned_n: int, malformed_n: int) -> str:
    if malformed_n > 0 and legacy_n == 0 and versioned_n == 0:
        return "malformed"
    if versioned_n == 0 and malformed_n == 0:
        return "legacy"
    if legacy_n == 0 and malformed_n == 0:
        return "versioned"
    return "mixed"


@dataclass
class TypeResult:
    type_name: str
    issues: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    infos: list[str] = field(default_factory=list)
    set_count: int = 0
    question_total: int = 0
    fully_localized_sets: int = 0
    fully_localized_questions: int = 0
    correct_answer_ok: bool = True
    legacy_set_count: int = 0
    versioned_set_count: int = 0
    malformed_id_count: int = 0
    schema_profile: str = "legacy"


def _validate_questions_for_set(
    sid: str,
    s: dict[str, Any],
    cfg: dict[str, Any],
    result: TypeResult,
    *,
    is_pilot: bool,
) -> None:
    questions = s.get("questions")
    if not isinstance(questions, list):
        result.issues.append(f"{sid}: questions must be a list")
        return

    qn = len(questions)
    result.question_total += qn
    if qn != cfg["questions_per_set"]:
        result.issues.append(
            f"{sid}: expected {cfg['questions_per_set']} questions, found {qn}"
        )

    set_ok = True

    for qi, q in enumerate(questions):
        if not isinstance(q, dict):
            result.issues.append(f"{sid} q[{qi}]: question is not an object")
            set_ok = False
            continue

        qid = q.get("id") or f"{sid}_q_{qi + 1}"
        raw_text = question_text_raw(q)
        q_loc = False

        if raw_text is None:
            result.issues.append(f"{qid}: missing question/text")
            set_ok = False
        elif isinstance(raw_text, dict):
            if not non_empty_str(raw_text.get("en")):
                result.issues.append(
                    f"{qid}: localized text missing non-empty 'en'"
                )
                set_ok = False
            if "tr" in raw_text and not non_empty_str(raw_text.get("tr")):
                result.issues.append(f"{qid}: localized text has empty 'tr'")
                set_ok = False
            q_loc = is_localized_text(raw_text)
        elif isinstance(raw_text, str):
            if not raw_text.strip():
                result.issues.append(f"{qid}: empty legacy question string")
                set_ok = False
        else:
            result.issues.append(f"{qid}: unsupported question text type")
            set_ok = False

        if is_pilot and not q_loc:
            result.issues.append(
                f"{qid}: pilot set requires question text with en and tr"
            )
            set_ok = False

        opts_ok = True
        if cfg["has_options"]:
            opts = q.get("options")
            if not isinstance(opts, list) or len(opts) == 0:
                result.issues.append(f"{qid}: options must be a non-empty list")
                set_ok = False
                opts_ok = False
            else:
                for oi, opt in enumerate(opts):
                    if option_en(opt) is None:
                        result.issues.append(
                            f"{qid} option[{oi}]: missing displayable English"
                        )
                        set_ok = False
                        opts_ok = False

                    label_map = option_label_map(opt)
                    if (
                        label_map is not None
                        and "tr" in label_map
                        and not non_empty_str(label_map.get("tr"))
                    ):
                        result.issues.append(
                            f"{qid} option[{oi}]: empty Turkish 'tr'"
                        )
                        set_ok = False
                        opts_ok = False

                    if is_pilot and not is_localized_option(opt):
                        result.issues.append(
                            f"{qid} option[{oi}]: "
                            "pilot set requires en+tr labels"
                        )
                        set_ok = False
                        opts_ok = False

                ca = q.get("correctAnswer")
                if cfg["requires_correct_answer"]:
                    if isinstance(ca, bool):
                        result.issues.append(
                            f"{qid}: correctAnswer must be an integer index "
                            f"(got bool)"
                        )
                        result.correct_answer_ok = False
                        set_ok = False
                    elif isinstance(ca, float) and ca.is_integer():
                        ca = int(ca)
                    elif not isinstance(ca, int):
                        result.issues.append(
                            f"{qid}: correctAnswer must be an integer index "
                            f"(got {type(ca).__name__}: {ca!r})"
                        )
                        result.correct_answer_ok = False
                        set_ok = False
                    elif ca < 0 or ca >= len(opts):
                        result.issues.append(
                            f"{qid}: correctAnswer index {ca} out of range "
                            f"for {len(opts)} options"
                        )
                        result.correct_answer_ok = False
                        set_ok = False

            if (
                q_loc
                and opts_ok
                and all(
                    is_localized_option(o) for o in (q.get("options") or [])
                )
            ):
                result.fully_localized_questions += 1
        else:
            # Frequency — Likert labels are UI chrome; options optional.
            if "options" in q and q["options"] not in (None, []):
                if not isinstance(q["options"], list):
                    result.warnings.append(
                        f"{qid}: options present but not a list"
                    )

            if not non_empty_str(q.get("dimension")):
                result.issues.append(f"{qid}: missing dimension")

            if "reverseScored" in q and not isinstance(
                q["reverseScored"], bool
            ):
                result.issues.append(
                    f"{qid}: reverseScored must be boolean if present "
                    f"(got {type(q['reverseScored']).__name__})"
                )

            if q_loc:
                result.fully_localized_questions += 1

    # Count fully localized set (all questions + options where applicable).
    if qn == cfg["questions_per_set"]:
        if cfg["has_options"]:
            all_q = True
            for q in questions:
                if not isinstance(q, dict):
                    all_q = False
                    break
                if not is_localized_text(question_text_raw(q)):
                    all_q = False
                    break
                opts = q.get("options")
                if not isinstance(opts, list) or not opts:
                    all_q = False
                    break
                if not all(is_localized_option(o) for o in opts):
                    all_q = False
                    break
            if all_q:
                result.fully_localized_sets += 1
        else:
            if all(
                isinstance(q, dict) and is_localized_text(question_text_raw(q))
                for q in questions
            ):
                result.fully_localized_sets += 1

    if is_pilot:
        if cfg["has_options"]:
            pilot_ok = all(
                isinstance(q, dict)
                and is_localized_text(question_text_raw(q))
                and isinstance(q.get("options"), list)
                and all(is_localized_option(o) for o in q["options"])
                for q in questions
            )
        else:
            pilot_ok = all(
                isinstance(q, dict) and is_localized_text(question_text_raw(q))
                for q in questions
            )
        if not pilot_ok and not any(
            sid in x or f"{sid}_" in x for x in result.issues
        ):
            result.issues.append(
                f"{sid}: pilot set is not fully localized (en+tr)"
            )

    _ = set_ok  # reserved for future aggregation


def validate_type(type_name: str, path: Path | None = None) -> TypeResult:
    cfg = EXPECTED[type_name]
    path = path if path is not None else FILES[type_name]
    result = TypeResult(type_name)

    if not path.exists():
        result.issues.append(f"Missing file: {path}")
        return result

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        result.issues.append(f"Invalid JSON in {path.name}: {e}")
        return result

    return validate_type_data(type_name, data, source_label=path.name)


def validate_type_data(
    type_name: str,
    data: Any,
    *,
    source_label: str = "payload",
) -> TypeResult:
    """Validate a `{ \"sets\": [...] }` assessment payload (legacy or versioned)."""
    cfg = EXPECTED[type_name]
    result = TypeResult(type_name)

    sets = data.get("sets") if isinstance(data, dict) else None
    if not isinstance(sets, list):
        result.issues.append(f"{source_label}: top-level 'sets' array is required")
        return result

    result.set_count = len(sets)
    if result.set_count != cfg["count"]:
        result.issues.append(
            f"{type_name}: expected {cfg['count']} sets, found {result.set_count}"
        )

    by_id: dict[str, dict[str, Any]] = {}
    parsed_by_id: dict[str, ParsedSetId] = {}
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
        parsed = parse_set_id(sid)
        parsed_by_id[sid] = parsed
        if parsed.kind == "legacy":
            result.legacy_set_count += 1
            if parsed.type_name != type_name:
                result.issues.append(
                    f"{sid}: legacy id type '{parsed.type_name}' does not "
                    f"match file type '{type_name}'"
                )
        elif parsed.kind == "versioned":
            result.versioned_set_count += 1
            result.issues.extend(
                validate_versioned_metadata(s, parsed, type_name)
            )
        else:
            result.malformed_id_count += 1
            result.issues.append(
                f"{type_name}: malformed set id '{sid}' "
                f"(expected legacy like {cfg['id_prefix']}001 or "
                f"versioned like {cfg['id_prefix']}001_v2)"
            )

    result.schema_profile = schema_profile(
        result.legacy_set_count,
        result.versioned_set_count,
        result.malformed_id_count,
    )

    # --- ID coverage by schema profile ---
    expect_legacy = expected_legacy_ids(cfg["id_prefix"], cfg["count"])

    if result.schema_profile == "legacy":
        missing = [x for x in expect_legacy if x not in by_id]
        unexpected = [x for x in by_id if x not in expect_legacy]
        if missing:
            shown = ", ".join(missing[:10])
            extra = " ..." if len(missing) > 10 else ""
            result.issues.append(
                f"{type_name}: missing set ids: {shown}{extra}"
            )
        if unexpected:
            shown = ", ".join(unexpected[:10])
            extra = " ..." if len(unexpected) > 10 else ""
            result.issues.append(
                f"{type_name}: unexpected set ids: {shown}{extra}"
            )
        result.infos.append(
            "INFO: Current assets use legacy IDs. "
            "Versioned v2 publishing is not active yet."
        )
        result.infos.append(
            "INFO: base_id/status/integer version checks apply only "
            "to versioned IDs."
        )
    elif result.schema_profile == "versioned":
        # Require set_numbers 1..count covered by versioned docs.
        covered = {
            p.set_number
            for p in parsed_by_id.values()
            if p.kind == "versioned" and p.set_number is not None
        }
        missing_nums = [n for n in range(1, cfg["count"] + 1) if n not in covered]
        if missing_nums:
            shown = ", ".join(f"{cfg['id_prefix']}{n:03d}_v*" for n in missing_nums[:10])
            extra = " ..." if len(missing_nums) > 10 else ""
            result.issues.append(
                f"{type_name}: missing versioned coverage for set_number(s): "
                f"{shown}{extra}"
            )
        # Warn on duplicate base_id/version collisions (same id already blocked).
        bases = [
            p.base_id
            for p in parsed_by_id.values()
            if p.kind == "versioned" and p.base_id
        ]
        if len(bases) != len(set(bases)):
            result.warnings.append(
                f"{type_name}: multiple versioned docs share a base_id "
                f"(review intentional multi-version sets)"
            )
    else:
        # mixed or malformed-heavy — still require each set_number 1..N
        # covered by either legacy id or a versioned base.
        covered = set()
        for p in parsed_by_id.values():
            if p.set_number is not None and p.kind in ("legacy", "versioned"):
                covered.add(p.set_number)
        missing_nums = [n for n in range(1, cfg["count"] + 1) if n not in covered]
        if missing_nums:
            shown = ", ".join(str(n) for n in missing_nums[:10])
            extra = " ..." if len(missing_nums) > 10 else ""
            result.issues.append(
                f"{type_name}: mixed schema missing set_number coverage: "
                f"{shown}{extra}"
            )
        result.warnings.append(
            f"{type_name}: schema profile is '{result.schema_profile}' "
            f"(legacy={result.legacy_set_count}, "
            f"versioned={result.versioned_set_count}, "
            f"malformed={result.malformed_id_count})"
        )

    # --- Content validation for every well-formed set ---
    pilot_legacy = cfg["pilot"]
    for sid, s in by_id.items():
        parsed = parsed_by_id[sid]
        if parsed.kind == "malformed":
            continue
        is_pilot = sid == pilot_legacy or (
            parsed.kind == "versioned"
            and parsed.base_id == pilot_legacy
            and parsed.version == 2
        )
        # Also treat any versioned base of pilot as pilot for localization bar.
        if parsed.kind == "versioned" and parsed.base_id == pilot_legacy:
            is_pilot = True
        _validate_questions_for_set(sid, s, cfg, result, is_pilot=is_pilot)

        # Legacy: do not require base_id / integer version / status.
        # Soft string version (e.g. "2026_01") is allowed — informational only.
        if parsed.kind == "legacy":
            ver = s.get("version")
            if isinstance(ver, str):
                # Expected current shape; not a failure.
                pass
            elif isinstance(ver, int):
                result.infos.append(
                    f"INFO: {sid}: legacy id with integer version "
                    f"(accepted; consider migrating to versioned id)"
                )

    return result


def print_report(results: dict[str, TypeResult]) -> bool:
    print("Assessment Set Validation Report")
    print()
    overall_ok = True

    total_legacy = 0
    total_versioned = 0
    total_malformed = 0

    for key in ("iq", "eq", "frequency"):
        r = results[key]
        cfg = EXPECTED[key]
        name = key.upper() if key != "frequency" else "Frequency"
        expected_q = cfg["count"] * cfg["questions_per_set"]
        total_legacy += r.legacy_set_count
        total_versioned += r.versioned_set_count
        total_malformed += r.malformed_id_count

        print(f"{name}:")
        print(f"- Sets: {r.set_count}/{cfg['count']}")
        print(f"- Questions: {r.question_total} total")
        print(f"- Fully localized sets: {r.fully_localized_sets}/{cfg['count']}")
        print(
            f"- Fully localized questions: "
            f"{r.fully_localized_questions}/{r.question_total or expected_q}"
        )
        print(f"- Schema profile: {r.schema_profile}")
        print(f"- Legacy sets: {r.legacy_set_count}")
        print(f"- Versioned sets: {r.versioned_set_count}")
        print(f"- Malformed IDs: {r.malformed_id_count}")
        print(f"- Issues: {len(r.issues)}")
        for info in r.infos[:5]:
            print(f"  · {info}")
        if r.warnings:
            for w in r.warnings[:20]:
                print(f"  · warning: {w}")
        if r.issues:
            overall_ok = False
            for issue in r.issues[:50]:
                print(f"  ✗ {issue}")
            if len(r.issues) > 50:
                print(f"  … and {len(r.issues) - 50} more")
        print()

    overall_profile = schema_profile(
        total_legacy, total_versioned, total_malformed
    )
    print("Schema summary:")
    print(f"- Overall schema profile: {overall_profile}")
    print(f"- Legacy set count: {total_legacy}")
    print(f"- Versioned set count: {total_versioned}")
    print(f"- Malformed ID count: {total_malformed}")
    if overall_profile == "legacy":
        print(
            "- INFO: Current assets use legacy IDs. "
            "Versioned v2 publishing is not active yet."
        )
        print(
            "- INFO: base_id/status/integer version checks apply only "
            "to versioned IDs."
        )
    print()

    print("Overall:")
    print(f"- {'PASS' if overall_ok else 'FAIL'}")
    return overall_ok


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Validate Qmatch assessment set JSON (legacy or versioned)."
    )
    parser.add_argument(
        "--from-dir",
        type=Path,
        default=None,
        help=(
            "Validate versioned export files in a directory "
            "(expects iq_sets_v2.json, eq_sets_v2.json, frequency_sets_v2.json)."
        ),
    )
    args = parser.parse_args(argv)

    if args.from_dir is not None:
        base = args.from_dir
        paths = {
            "iq": base / "iq_sets_v2.json",
            "eq": base / "eq_sets_v2.json",
            "frequency": base / "frequency_sets_v2.json",
        }
        results = {t: validate_type(t, paths[t]) for t in ("iq", "eq", "frequency")}
    else:
        results = {t: validate_type(t) for t in ("iq", "eq", "frequency")}
    ok = print_report(results)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
