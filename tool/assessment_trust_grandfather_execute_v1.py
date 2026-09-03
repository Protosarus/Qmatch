#!/usr/bin/env python3
"""Assessment-trust grandfather — EXECUTE.

Writes ONLY users.assessment_verification_v1 for grandfather candidates.
Does not touch Discover, completion mirrors, photos, or Frequency V2.

IMPLEMENT AND TEST ONLY in Phase 7G.1.
DO NOT run this against production.

Usage:
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/assessment_trust_grandfather_execute_v1.py \\
    --execute --confirm PRE_TRUST_MIGRATION_V1
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TOOL_DIR = Path(__file__).resolve().parent
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
PROJECT_ID = "qmatch-53d62"
COLLECTION = "users"
POLICY = "assessment_trust_grandfather_execute_v1"
CONFIRM = "PRE_TRUST_MIGRATION_V1"
BATCH_LIMIT = 400  # under Firestore 500 write limit

if str(TOOL_DIR) not in sys.path:
    sys.path.insert(0, str(TOOL_DIR))

from assessment_trust_grandfather_policy_v1 import (  # noqa: E402
    assert_verification_only_write,
    empty_counts,
    increment_count,
    plan_grandfather_write,
    public_counts,
)


def execute_authorized(*, execute: bool, confirm: str) -> bool:
    return execute is True and confirm == CONFIRM


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Execute assessment-trust grandfather.")
    p.add_argument(
        "--execute",
        action="store_true",
        help="Perform Admin writes (requires --confirm PRE_TRUST_MIGRATION_V1).",
    )
    p.add_argument(
        "--confirm",
        default="",
        help='Must be exactly "PRE_TRUST_MIGRATION_V1" to write.',
    )
    p.add_argument(
        "--batch-size",
        type=int,
        default=BATCH_LIMIT,
        help=f"Firestore batch size (default {BATCH_LIMIT}, max 400).",
    )
    p.add_argument(
        "--self-check-only",
        action="store_true",
        help="Print whether write mode would be enabled; no Firebase connection.",
    )
    return p.parse_args(argv)


def print_refuse() -> None:
    print(
        f"{POLICY}\n"
        "Refusing without --execute --confirm PRE_TRUST_MIGRATION_V1\n"
        f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
        "  python3 tool/assessment_trust_grandfather_execute_v1.py "
        "--execute --confirm PRE_TRUST_MIGRATION_V1\n"
        "\n"
        "Phase 7G.1: implement and test only. Do NOT run against production.\n"
    )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    authorized = execute_authorized(execute=args.execute, confirm=args.confirm)

    if args.self_check_only:
        print(
            json.dumps(
                {
                    "policy": POLICY,
                    "write_mode": authorized,
                    "confirm_expected": CONFIRM,
                },
                sort_keys=True,
            )
        )
        return 0

    if not authorized:
        print_refuse()
        return 2

    batch_size = max(1, min(args.batch_size, BATCH_LIMIT))

    cred_path = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not cred_path or not os.path.isabs(cred_path) or not os.path.isfile(cred_path):
        print(
            f"ERROR: set {CREDENTIALS_ENV} to an absolute existing file.",
            file=sys.stderr,
        )
        return 2
    try:
        Path(cred_path).resolve().relative_to(ROOT.resolve())
        print("ERROR: credentials must live outside the repo.", file=sys.stderr)
        return 2
    except ValueError:
        pass

    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(cred_path),
            {"projectId": PROJECT_ID},
        )
    db = firestore.client()

    counts = empty_counts()
    writes_executed = 0
    batches = 0
    batch = db.batch()
    pending = 0

    for doc in db.collection(COLLECTION).stream():
        counts["total_users_scanned"] += 1
        data: dict[str, Any] = doc.to_dict() or {}
        planned = plan_grandfather_write(data)
        increment_count(counts, planned["classification"])
        write = planned["write"]
        if write is None:
            continue
        assert_verification_only_write(write)
        counts["planned_writes"] += 1
        # ONLY assessment_verification_v1 — no extra user fields.
        batch.update(doc.reference, write)
        pending += 1
        writes_executed += 1
        if pending >= batch_size:
            batch.commit()
            batches += 1
            batch = db.batch()
            pending = 0

    if pending:
        batch.commit()
        batches += 1

    counts["writes_performed"] = writes_executed
    print(
        json.dumps(
            {
                "policy": POLICY,
                "project_id": PROJECT_ID,
                "started_at_utc": datetime.now(timezone.utc).isoformat(),
                **public_counts(counts),
                "writes_executed": writes_executed,
                "batches_committed": batches,
                "field_touched": ["assessment_verification_v1"],
            },
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
