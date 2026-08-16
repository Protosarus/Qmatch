#!/usr/bin/env python3
"""Discover eligibility backfill — DRY-RUN only (`discover_eligibility_backfill_dry_run_v1`).

Compares stored `discover_eligible` vs canonical derivation for every `users/{uid}` doc.
Never writes Firestore. Never triggers Cloud Functions. Prints counts only.

Usage:
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/discover_eligibility_backfill_dry_run_v1.py --execute-dry-run

Canonical derivation (must match trusted CF):
  active == true &&
  (test_completed == true || assessment_flow_completed == true) &&
  profile_completed == true &&
  hasPhoto == true &&
  account_deletion_requested != true
"""

from __future__ import annotations

import argparse
import ast
import json
import os
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
THIS_FILE = Path(__file__).resolve()
PROJECT_ID = "qmatch-53d62"
COLLECTION = "users"
POLICY = "discover_eligibility_backfill_dry_run_v1"

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


def has_valid_photo(data: dict[str, Any]) -> bool:
    url = data.get("profile_photo_url")
    if isinstance(url, str) and url.strip():
        return True
    photos = data.get("photos")
    if isinstance(photos, list):
        for p in photos:
            if isinstance(p, str) and p.strip():
                return True
    return False


def derive_discover_eligible(data: dict[str, Any] | None) -> bool:
    """Canonical trusted derivation (matches functions/src/discover_eligibility.js)."""
    if not isinstance(data, dict):
        return False
    if data.get("account_deletion_requested") is True:
        return False
    if data.get("active") is not True:
        return False
    if data.get("profile_completed") is not True:
        return False
    assessments_done = (
        data.get("test_completed") is True
        or data.get("assessment_flow_completed") is True
    )
    if not assessments_done:
        return False
    if not has_valid_photo(data):
        return False
    return True


def ineligible_reason_codes(data: dict[str, Any]) -> list[str]:
    """Anonymized why derived==false (no PII)."""
    reasons: list[str] = []
    if data.get("account_deletion_requested") is True:
        reasons.append("account_deletion_requested")
    if data.get("active") is not True:
        reasons.append("active_not_true")
    if data.get("profile_completed") is not True:
        reasons.append("profile_not_completed")
    if not (
        data.get("test_completed") is True
        or data.get("assessment_flow_completed") is True
    ):
        reasons.append("assessment_incomplete")
    if not has_valid_photo(data):
        reasons.append("photo_missing")
    return reasons or ["unknown"]


def assert_no_mutation_calls() -> None:
    tree = ast.parse(THIS_FILE.read_text(encoding="utf-8"))
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute):
            if node.func.attr in FORBIDDEN_CALL_ATTRS:
                # Allow mentioning forbidden names only inside this checker set.
                raise SystemExit(
                    f"REFUSE: forbidden call .{node.func.attr}() found in dry-run script"
                )


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Dry-run Discover eligibility backfill (read-only counts)."
    )
    p.add_argument(
        "--execute-dry-run",
        action="store_true",
        help="Connect with Admin SDK and scan users (still no writes).",
    )
    p.add_argument(
        "--page-size",
        type=int,
        default=500,
        help="Firestore page size (default 500).",
    )
    p.add_argument(
        "--write-local-report",
        action="store_true",
        help="Write count-only JSON under build/ (no UIDs).",
    )
    return p.parse_args()


def print_usage() -> None:
    print(
        f"{POLICY} — DRY RUN ONLY\n"
        "\n"
        "Default: no Firebase connection.\n"
        "\n"
        "Scan (read-only):\n"
        f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
        "  python3 tool/discover_eligibility_backfill_dry_run_v1.py --execute-dry-run\n"
        "\n"
        "Never writes discover_eligible. Never triggers Cloud Functions.\n"
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
    # Refuse credentials inside the git worktree.
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

    total = 0
    already_correct = 0
    false_to_true = 0
    true_to_false = 0
    missing_invalid = 0
    missing_would_become_true = 0
    missing_would_become_false = 0
    true_to_false_reasons: Counter[str] = Counter()
    missing_invalid_kinds: Counter[str] = Counter()

    # stream() is read-only; no writes.
    for doc in db.collection(COLLECTION).stream():
        total += 1
        data = doc.to_dict() or {}
        derived = derive_discover_eligible(data)
        stored = data.get("discover_eligible")

        if stored is True or stored is False:
            if stored is derived:
                already_correct += 1
            elif stored is False and derived is True:
                false_to_true += 1
            elif stored is True and derived is False:
                true_to_false += 1
                for code in ineligible_reason_codes(data):
                    true_to_false_reasons[code] += 1
            else:
                # Unreachable with bool stored + bool derived.
                missing_invalid += 1
                missing_invalid_kinds["bool_logic_anomaly"] += 1
        else:
            missing_invalid += 1
            if stored is None:
                missing_invalid_kinds["missing_or_null"] += 1
            else:
                missing_invalid_kinds[f"non_bool_{type(stored).__name__}"] += 1
            if derived:
                missing_would_become_true += 1
            else:
                missing_would_become_false += 1

        if page_size and total % max(page_size, 1) == 0:
            print(f"… scanned {total} users (progress)", flush=True)

    report = {
        "policy": POLICY,
        "project_id": PROJECT_ID,
        "collection": COLLECTION,
        "mode": "dry_run_read_only",
        "writes_performed": False,
        "scanned_at_utc": datetime.now(timezone.utc).isoformat(),
        "total_users_scanned": total,
        "already_correct": already_correct,
        "false_to_true_needed": false_to_true,
        "true_to_false_needed": true_to_false,
        "missing_invalid_stored_flag": missing_invalid,
        "missing_invalid_would_become_true": missing_would_become_true,
        "missing_invalid_would_become_false": missing_would_become_false,
        "true_to_false_reason_counts": dict(true_to_false_reasons),
        "missing_invalid_kind_counts": dict(missing_invalid_kinds),
        "backfill_writes_required": false_to_true
        + true_to_false
        + missing_invalid,
    }

    print(json.dumps(report, indent=2, sort_keys=True))
    print(
        "\nDRY-RUN complete. No Firestore writes. "
        "Cloud Function not invoked by this tool."
    )

    if write_local_report:
        BUILD_DIR.mkdir(parents=True, exist_ok=True)
        out = BUILD_DIR / "discover_eligibility_backfill_dry_run_v1.json"
        out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
        print(f"local_report={out}")

    return 0


def main() -> int:
    args = parse_args()
    if not args.execute_dry_run:
        print_usage()
        return 0
    return run_dry_run(
        page_size=args.page_size,
        write_local_report=args.write_local_report,
    )


if __name__ == "__main__":
    raise SystemExit(main())
