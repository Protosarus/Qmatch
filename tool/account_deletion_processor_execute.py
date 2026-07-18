#!/usr/bin/env python3
"""Account deletion processor — GATED EXECUTE skeleton (Phase 3P-A14).

Builds a **planned** deletion/anonymization sequence for one explicit --uid.
Destructive Firebase operations are **not implemented** and must not run.

Default:
  --dry-run=true  → planning only (read-only inventory + local JSON plan)

Attempting:
  --dry-run=false --confirmation-phrase=PROCESS_ACCOUNT_DELETION_REQUESTS
validates gates, then **still refuses** actual mutation because
EXECUTE_IMPLEMENTED=False (NotImplemented). No deletes/updates occur.

Usage (planning):
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"
  python3 tool/account_deletion_processor_execute.py --uid=<FIREBASE_UID>

Safety:
  - Requires explicit --uid (no batch, no wildcards)
  - Default dry-run=true
  - dry-run=false requires exact confirmation phrase
  - Never prints service account key contents
  - Masks UID in logs/reports
  - AST self-check forbids mutation call attrs in this file
  - May write only a local JSON plan under build/

See docs/account_deletion_processor_plan.md
     docs/account_deletion_execute_processor_skeleton.md
"""

from __future__ import annotations

import argparse
import ast
import importlib.util
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
TOOL_DIR = Path(__file__).resolve().parent
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
STORAGE_BUCKET_ENV = "QMATCH_FIREBASE_STORAGE_BUCKET"
CONFIRMATION_PHRASE = "PROCESS_ACCOUNT_DELETION_REQUESTS"
THIS_FILE = Path(__file__).resolve()

# Hard gate: this skeleton must not perform destructive work.
EXECUTE_IMPLEMENTED = False

FORBIDDEN_CALL_ATTRS = frozenset(
    {
        "delete",
        "update",
        "set",
        "create",
        "add",
        "delete_user",
        "delete_users",
        "update_user",
        "commit",
    }
)


def mask_uid(uid: str) -> str:
    if not uid:
        return "(empty)"
    if len(uid) <= 6:
        return "***"
    return f"{uid[:6]}…"


def storage_bucket_from_env() -> str | None:
    raw = os.environ.get(STORAGE_BUCKET_ENV, "").strip()
    return raw or None


def parse_dry_run(value: str) -> bool:
    v = value.strip().lower()
    if v in {"true", "1", "yes"}:
        return True
    if v in {"false", "0", "no"}:
        return False
    raise argparse.ArgumentTypeError("dry-run must be true or false")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=(
            "Gated account deletion execute skeleton — planning only in 3P-A14. "
            "Destructive ops are not implemented."
        )
    )
    p.add_argument(
        "--uid",
        required=True,
        help="Exact single Firebase uid (required; no batch/wildcards).",
    )
    p.add_argument(
        "--dry-run",
        type=parse_dry_run,
        default=True,
        help="Default true (planning). false requires confirmation phrase; "
        "destructive execute still disabled in this skeleton.",
    )
    p.add_argument(
        "--confirmation-phrase",
        default="",
        help=f"Required when --dry-run=false. Exact value: {CONFIRMATION_PHRASE}",
    )
    p.add_argument(
        "--self-check-only",
        action="store_true",
        help="AST forbidden-call scan only; no Firebase connection.",
    )
    return p.parse_args(argv)


def assert_uid(uid: str) -> str:
    u = (uid or "").strip()
    if not u:
        raise RuntimeError("REFUSED: --uid is required and must be non-empty.")
    if u in {"*", "all", "ANY", "%"}:
        raise RuntimeError("REFUSED: wildcard / batch UID not allowed.")
    if "," in u or " " in u:
        raise RuntimeError("REFUSED: only a single explicit --uid is allowed (no batch).")
    if "/" in u or u.startswith("users/"):
        raise RuntimeError("REFUSED: --uid must be a bare uid, not a path.")
    if len(u) > 128:
        raise RuntimeError("REFUSED: --uid looks invalid (too long).")
    return u


def credentials_path_from_env() -> Path:
    raw = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not raw:
        raise RuntimeError(
            f"REFUSED: set {CREDENTIALS_ENV} to an absolute path outside the repo."
        )
    path = Path(raw).expanduser()
    if not path.is_absolute():
        raise RuntimeError("REFUSED: credentials path must be absolute.")
    if not path.is_file():
        raise FileNotFoundError(f"credentials file not found: {path}")
    resolved = path.resolve()
    try:
        resolved.relative_to(ROOT.resolve())
        raise RuntimeError(
            "REFUSED: service account file must stay OUTSIDE the repo."
        )
    except ValueError:
        pass
    if path.stat().st_size < 32:
        raise RuntimeError("credentials file looks empty")
    return path


def source_self_check() -> list[str]:
    errors: list[str] = []
    tree = ast.parse(THIS_FILE.read_text(encoding="utf-8"), filename=str(THIS_FILE))
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        func = node.func
        attr = None
        if isinstance(func, ast.Attribute):
            attr = func.attr
        if attr in FORBIDDEN_CALL_ATTRS:
            errors.append(f"forbidden call attr .{attr}() at line {node.lineno}")
    if EXECUTE_IMPLEMENTED:
        errors.append("EXECUTE_IMPLEMENTED must be False in 3P-A14 skeleton")
    return errors


def assert_safety_gates(
    *,
    uid: str,
    dry_run: bool,
    confirmation_phrase: str,
    require_storage_bucket: bool,
) -> dict[str, Any]:
    """Validate CLI/env gates. Does not enable destructive work."""
    assert_uid(uid)
    credentials_path_from_env()  # validates path; never prints contents
    bucket = storage_bucket_from_env()

    gates = {
        "uid_explicit": True,
        "single_uid_only": True,
        "credentials_outside_repo": True,
        "storage_bucket_configured": bool(bucket),
        "dry_run": dry_run,
        "confirmation_phrase_ok": None,
        "execute_implemented": EXECUTE_IMPLEMENTED,
        "destructive_path_enabled": False,
    }

    if dry_run:
        gates["confirmation_phrase_ok"] = "n/a_dry_run"
        if require_storage_bucket and not bucket:
            # Planning still allowed; Storage planned deletes marked unresolved.
            gates["storage_bucket_required_for_execute_planning"] = False
        return gates

    # dry_run == False
    if confirmation_phrase != CONFIRMATION_PHRASE:
        raise RuntimeError(
            "REFUSED: --dry-run=false requires "
            f"--confirmation-phrase={CONFIRMATION_PHRASE}"
        )
    gates["confirmation_phrase_ok"] = True

    if not bucket:
        raise RuntimeError(
            f"REFUSED: {STORAGE_BUCKET_ENV} is required for Storage execution planning "
            "when --dry-run=false."
        )
    gates["storage_bucket_configured"] = True

    if not EXECUTE_IMPLEMENTED:
        raise RuntimeError(
            "REFUSED: destructive execute path is not implemented "
            "(EXECUTE_IMPLEMENTED=False / Phase 3P-A14). "
            "Re-run with --dry-run=true for planning only."
        )

    # Unreachable while EXECUTE_IMPLEMENTED is False.
    gates["destructive_path_enabled"] = True
    return gates


def perform_destructive_operations(_plan: dict[str, Any]) -> None:
    """TODO(3P-A15+): gated Auth/Storage/Firestore mutations.

    Intentionally empty of any Firebase mutation calls so AST self-check stays green.
    """
    raise NotImplementedError(
        "Destructive account deletion execute path is not implemented. "
        "EXECUTE_IMPLEMENTED=False (Phase 3P-A14)."
    )


def load_dry_run_inventory(uid: str) -> dict[str, Any]:
    """Reuse read-only inventory from the dry-run tool (no mutations)."""
    dry_path = TOOL_DIR / "account_deletion_processor_dry_run.py"
    spec = importlib.util.spec_from_file_location(
        "account_deletion_processor_dry_run", dry_path
    )
    if spec is None or spec.loader is None:
        raise RuntimeError("Failed to load dry-run inventory module")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.inventory_uid(uid)


def build_planned_operations(uid: str, inventory: dict[str, Any]) -> dict[str, Any]:
    """Translate inventory counts into a planned mutation sequence (not executed)."""
    counts = inventory.get("doc_counts_summary") or {}
    coll = inventory.get("collections_inventoried") or {}
    unresolved = list(inventory.get("unresolved_manual_review_items") or [])
    warnings = list(inventory.get("warnings") or [])

    bucket = storage_bucket_from_env()
    if not bucket:
        unresolved.append(
            "Storage bucket env missing; storage delete planning incomplete."
        )

    aa = counts.get("assessment_assignments") or 0
    assessments = counts.get("assessments") or 0
    swipes = counts.get("swipes") or 0
    blocks = counts.get("blocks") or 0
    matches = counts.get("matches") or 0
    threads = counts.get("threads") or 0
    storage_n = counts.get("storage_objects_listed")
    reports_reporter = counts.get("reports_as_reporter") or 0
    reports_reported = counts.get("reports_as_reported") or 0

    msg_info = coll.get("threads_messages_sample") or {}
    msgs_from_uid = msg_info.get("messages_from_uid_in_scanned")

    planned_firestore_deletes = [
        {
            "action": "delete_subcollection_docs",
            "path": f"users/{{uid}}/assessment_assignments/*",
            "estimated_docs": aa,
        },
        {
            "action": "delete_subcollection_docs",
            "path": f"users/{{uid}}/assessments/*",
            "estimated_docs": assessments,
        },
        {
            "action": "delete_subcollection_docs",
            "path": f"users/{{uid}}/swipes/*",
            "estimated_docs": swipes,
        },
        {
            "action": "delete_subcollection_docs",
            "path": f"users/{{uid}}/blocks/*",
            "estimated_docs": blocks,
            "note": "Optional short retention snapshot before wipe (ops policy).",
        },
        {
            "action": "delete_or_tombstone_user_doc",
            "path": "users/{uid}",
            "estimated_docs": 1 if (coll.get("users") or {}).get("exists") else 0,
        },
    ]

    planned_firestore_anonymizations = [
        {
            "action": "close_anonymize_matches",
            "path": "matches where users array_contains uid",
            "estimated_docs": matches,
        },
        {
            "action": "close_threads_redact_previews",
            "path": "threads where participants array_contains uid",
            "estimated_docs": threads,
        },
        {
            "action": "redact_or_delete_sender_messages",
            "path": "threads/{threadId}/messages where sender_id==uid",
            "estimated_docs_in_sample": msgs_from_uid,
            "note": "Sample-capped in inventory; full scan required at execute time.",
        },
        {
            "action": "retain_anonymize_reports",
            "path": "reports (reporter_uid or reported_uid)",
            "estimated_as_reporter": reports_reporter,
            "estimated_as_reported": reports_reported,
            "note": "Do not wipe; retain for safety/legal.",
        },
    ]

    planned_storage_deletes = [
        {
            "action": "delete_prefix",
            "prefix_masked": f"profile_photos/{mask_uid(uid)}/",
            "estimated_objects": storage_n,
            "bucket_configured": bool(bucket),
            "note": "Read-only listed when bucket env set; no blob deletes in 3P-A14.",
        }
    ]

    planned_auth_delete = {
        "action": "auth_delete_user",
        "order": "last",
        "auth_exists": (coll.get("firebase_auth") or {}).get("exists"),
        "note": "Not called in 3P-A14.",
    }

    planned_status_updates = [
        {
            "action": "claim_request",
            "path": "account_deletion_requests/{uid}",
            "fields": {
                "status": "processing",
                "processing_started_at": "serverTimestamp",
                "processed_by": "service_account_or_job_id",
            },
            "note": "Not written in 3P-A14.",
        },
        {
            "action": "finalize_request",
            "path": "account_deletion_requests/{uid}",
            "fields": {
                "status": "completed",
                "processed_at": "serverTimestamp",
                "final_deletion_status": "completed",
            },
            "note": "Retain audit doc; never delete request in v1. Not written in 3P-A14.",
        },
    ]

    planned_sequence = [
        "Validate gates (uid, credentials, dry-run/phrase, storage bucket for execute)",
        "Read-only inventory (reuse dry-run inventory)",
        "Claim account_deletion_requests/{uid}: requested → processing",
        "Close/anonymize matches involving uid",
        "Close threads; redact last_message_preview if needed",
        "Redact or delete messages where sender_id==uid (policy)",
        "Delete users/{uid}/assessment_assignments/*",
        "Delete users/{uid}/assessments/*",
        "Delete users/{uid}/swipes/*",
        "Delete users/{uid}/blocks/* (after optional retention)",
        "Delete Storage profile_photos/{uid}/**",
        "Delete or tombstone users/{uid}",
        "Delete Firebase Auth user (last)",
        "Finalize account_deletion_requests/{uid} status=completed + audit fields",
        "Retain reports; never mutate assessment_sets or questions",
    ]

    planned_operation_counts = {
        "firestore_delete_groups": len(planned_firestore_deletes),
        "firestore_anonymization_groups": len(planned_firestore_anonymizations),
        "storage_delete_groups": len(planned_storage_deletes),
        "auth_delete_groups": 1,
        "status_update_groups": len(planned_status_updates),
        "estimated_subcollection_docs": aa + assessments + swipes + blocks,
        "estimated_matches": matches,
        "estimated_threads": threads,
        "estimated_storage_objects": storage_n,
    }

    forbidden = {
        "assessment_sets": "never mutate",
        "questions": "never mutate",
        "other_users_profiles": "never delete users/{otherUid}",
    }

    return {
        "planned_firestore_deletes": planned_firestore_deletes,
        "planned_firestore_anonymizations": planned_firestore_anonymizations,
        "planned_storage_deletes": planned_storage_deletes,
        "planned_auth_delete": planned_auth_delete,
        "planned_status_updates": planned_status_updates,
        "planned_sequence": planned_sequence,
        "planned_operation_counts": planned_operation_counts,
        "forbidden_targets": forbidden,
        "unresolved_items": unresolved,
        "warnings": warnings,
        "inventory_dry_run_flags": {
            "destructiveOperationsPerformed": inventory.get(
                "destructiveOperationsPerformed"
            ),
            "firestoreWritesPerformed": inventory.get("firestoreWritesPerformed"),
            "authDeletePerformed": inventory.get("authDeletePerformed"),
            "storageDeletePerformed": inventory.get("storageDeletePerformed"),
        },
    }


def write_plan_report(report: dict[str, Any]) -> Path:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    masked = str(report["uid_masked"]).replace("…", "").replace("...", "")
    masked_fs = re.sub(r"[^a-zA-Z0-9_-]", "", masked) or "unknown"
    out = BUILD_DIR / f"account_deletion_execute_plan_{masked_fs}.json"
    out.write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    return out


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    scan_errors = source_self_check()
    if scan_errors:
        print("SELF-CHECK FAILED:", file=sys.stderr)
        for e in scan_errors:
            print(f"  - {e}", file=sys.stderr)
        return 3

    if args.self_check_only:
        print("self_check=ok forbidden_mutation_calls=0")
        print(f"EXECUTE_IMPLEMENTED={EXECUTE_IMPLEMENTED}")
        print("execute_skeleton=planning_only (no Firebase connection)")
        return 0

    try:
        uid = assert_uid(args.uid)
        # Planning mode: allow missing storage bucket (recorded as unresolved).
        # dry-run=false: assert_safety_gates refuses without bucket + phrase,
        # and still refuses because EXECUTE_IMPLEMENTED is False.
        gates = assert_safety_gates(
            uid=uid,
            dry_run=args.dry_run,
            confirmation_phrase=args.confirmation_phrase,
            require_storage_bucket=False,
        )
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    # Never call perform_destructive_operations in 3P-A14.
    if not args.dry_run:
        # Should have been refused above while EXECUTE_IMPLEMENTED is False.
        print("ERROR: unexpected non-dry-run path", file=sys.stderr)
        return 2

    try:
        inventory = load_dry_run_inventory(uid)
        planned = build_planned_operations(uid, inventory)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    report = {
        "uid_masked": mask_uid(uid),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "dryRun": True,
        "executeEnabled": False,
        "EXECUTE_IMPLEMENTED": EXECUTE_IMPLEMENTED,
        "destructiveOperationsPerformed": False,
        "firestoreWritesPerformed": False,
        "authDeletePerformed": False,
        "storageDeletePerformed": False,
        "plannedOperationCounts": planned["planned_operation_counts"],
        "plannedSequence": planned["planned_sequence"],
        "planned_firestore_deletes": planned["planned_firestore_deletes"],
        "planned_firestore_anonymizations": planned[
            "planned_firestore_anonymizations"
        ],
        "planned_storage_deletes": planned["planned_storage_deletes"],
        "planned_auth_delete": planned["planned_auth_delete"],
        "planned_status_updates": planned["planned_status_updates"],
        "forbidden_targets": planned["forbidden_targets"],
        "unresolvedItems": planned["unresolved_items"],
        "warnings": planned["warnings"],
        "safetyGates": gates,
        "nextManualReviewRequired": True,
        "note": (
            "Phase 3P-A14 execute skeleton: planning only. "
            "No Firestore/Auth/Storage mutations. "
            f"Future execute requires EXECUTE_IMPLEMENTED=True plus "
            f"--dry-run=false --confirmation-phrase={CONFIRMATION_PHRASE}."
        ),
    }

    out = write_plan_report(report)
    print(f"dryRun=true executeEnabled=false uid_masked={report['uid_masked']}")
    print(f"report={out}")
    print(
        "destructiveOperationsPerformed=false "
        "firestoreWritesPerformed=false "
        "authDeletePerformed=false "
        "storageDeletePerformed=false"
    )
    print("nextManualReviewRequired=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
