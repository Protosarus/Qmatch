#!/usr/bin/env python3
"""Assessment-trust grandfather — DRY-RUN only.

Classifies every users collection document against the grandfather policy.
Never writes Firestore. Never triggers Cloud Functions. Prints counts only.

Usage:
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/assessment_trust_grandfather_dry_run_v1.py --execute-dry-run
"""

from __future__ import annotations

import argparse
import ast
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOOL_DIR = Path(__file__).resolve().parent
BUILD_DIR = ROOT / "build"
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
THIS_FILE = Path(__file__).resolve()
PROJECT_ID = "qmatch-53d62"
COLLECTION = "users"
POLICY = "assessment_trust_grandfather_dry_run_v1"

if str(TOOL_DIR) not in sys.path:
    sys.path.insert(0, str(TOOL_DIR))

from assessment_trust_grandfather_policy_v1 import (  # noqa: E402
    empty_counts,
    increment_count,
    plan_grandfather_write,
    public_counts,
)

# Self-check: this file must never call these mutation attrs.
FORBIDDEN_CALL_ATTRS = frozenset(
    {
        "delete",
        "update",
        "set",
        "create",
        "add",
        "commit",
        "delete_user",
        "delete_users",
        "update_user",
    }
)


def assert_no_mutation_calls() -> None:
    tree = ast.parse(THIS_FILE.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            if node.func.attr in FORBIDDEN_CALL_ATTRS:
                raise SystemExit(
                    f"REFUSE: forbidden call .{node.func.attr}() found in dry-run script"
                )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Dry-run assessment-trust grandfather (read-only counts)."
    )
    p.add_argument(
        "--execute-dry-run",
        action="store_true",
        help="Connect with Admin SDK and scan users (still no writes).",
    )
    p.add_argument(
        "--self-check-only",
        action="store_true",
        help="Run AST mutation-call scan only; no Firebase connection.",
    )
    p.add_argument(
        "--page-size",
        type=int,
        default=500,
        help="Progress print interval (default 500).",
    )
    p.add_argument(
        "--write-local-report",
        action="store_true",
        help="Write count-only JSON under build/ (no UIDs).",
    )
    return p.parse_args(argv)


def print_usage() -> None:
    print(
        f"{POLICY} — DRY RUN ONLY\n"
        "\n"
        "Default: no Firebase connection.\n"
        "\n"
        "Scan (read-only):\n"
        f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
        "  python3 tool/assessment_trust_grandfather_dry_run_v1.py --execute-dry-run\n"
        "\n"
        "Never writes assessment_verification_v1. Never triggers Cloud Functions.\n"
        "Do NOT run the execute tool against production in Phase 7G.1.\n"
    )


def run_dry_run(*, page_size: int, write_local_report: bool) -> int:
    assert_no_mutation_calls()

    cred_path = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not cred_path:
        print(
            f"ERROR: set {CREDENTIALS_ENV} to an absolute path outside the repo.",
            file=sys.stderr,
        )
        return 2
    if not os.path.isabs(cred_path):
        print("ERROR: credentials path must be absolute.", file=sys.stderr)
        return 2
    if not os.path.isfile(cred_path):
        print("ERROR: credentials file not found.", file=sys.stderr)
        return 2
    try:
        Path(cred_path).resolve().relative_to(ROOT.resolve())
        print("ERROR: credentials must live outside the repo.", file=sys.stderr)
        return 2
    except ValueError:
        pass

    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
    except ImportError:
        print(
            "ERROR: firebase_admin is not installed. "
            "pip install firebase-admin (ops machine only).",
            file=sys.stderr,
        )
        return 2

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(cred_path),
            {"projectId": PROJECT_ID},
        )

    db = firestore.client()
    counts = empty_counts()

    # stream() is read-only; no writes.
    for doc in db.collection(COLLECTION).stream():
        counts["total_users_scanned"] += 1
        data: dict[str, Any] = doc.to_dict() or {}
        planned = plan_grandfather_write(data)
        increment_count(counts, planned["classification"])
        if planned["write"] is not None:
            counts["planned_writes"] += 1

        if page_size and counts["total_users_scanned"] % max(page_size, 1) == 0:
            print(
                f"… scanned {counts['total_users_scanned']} users (progress)",
                flush=True,
            )

    report = {
        "policy": POLICY,
        "project_id": PROJECT_ID,
        "collection": COLLECTION,
        "mode": "dry_run_read_only",
        "writes_performed": False,
        "scanned_at_utc": datetime.now(timezone.utc).isoformat(),
        **public_counts(counts),
    }

    print(json.dumps(report, indent=2, sort_keys=True))
    print(
        "\nDRY-RUN complete. No Firestore writes. "
        "Cloud Function not invoked by this tool."
    )

    if write_local_report:
        BUILD_DIR.mkdir(parents=True, exist_ok=True)
        out = BUILD_DIR / "assessment_trust_grandfather_dry_run_v1.json"
        out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        print(f"local_report={out}")

    return 0


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.self_check_only:
        assert_no_mutation_calls()
        print(json.dumps({"ok": True, "policy": POLICY, "mutation_calls": False}))
        return 0
    if not args.execute_dry_run:
        print_usage()
        return 0
    return run_dry_run(
        page_size=args.page_size,
        write_local_report=args.write_local_report,
    )


if __name__ == "__main__":
    raise SystemExit(main())
