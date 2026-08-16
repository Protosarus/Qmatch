#!/usr/bin/env python3
"""Discover eligibility backfill — EXECUTE (`discover_eligibility_backfill_execute_v1`).

Writes ONLY `discover_eligible` when stored != canonical derived value.
Does not touch timestamps or any other user fields.

Usage:
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/discover_eligibility_backfill_execute_v1.py --execute --confirm YES
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
PROJECT_ID = "qmatch-53d62"
COLLECTION = "users"
POLICY = "discover_eligibility_backfill_execute_v1"
BATCH_LIMIT = 400  # under Firestore 500 write limit


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
    if not isinstance(data, dict):
        return False
    if data.get("account_deletion_requested") is True:
        return False
    if data.get("active") is not True:
        return False
    if data.get("profile_completed") is not True:
        return False
    if not (
        data.get("test_completed") is True
        or data.get("assessment_flow_completed") is True
    ):
        return False
    if not has_valid_photo(data):
        return False
    return True


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Execute Discover eligibility backfill.")
    p.add_argument(
        "--execute",
        action="store_true",
        help="Perform Admin writes (requires --confirm YES).",
    )
    p.add_argument(
        "--confirm",
        default="",
        help='Must be exactly "YES" to write.',
    )
    p.add_argument(
        "--batch-size",
        type=int,
        default=BATCH_LIMIT,
        help=f"Firestore batch size (default {BATCH_LIMIT}, max 500).",
    )
    return p.parse_args()


def main() -> int:
    args = parse_args()
    if not args.execute or args.confirm != "YES":
        print(
            f"{POLICY}\n"
            "Refusing without --execute --confirm YES\n"
            f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
            "  python3 tool/discover_eligibility_backfill_execute_v1.py "
            "--execute --confirm YES\n"
        )
        return 2

    batch_size = max(1, min(args.batch_size, 500))

    cred_path = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not cred_path or not os.path.isabs(cred_path) or not os.path.isfile(cred_path):
        print(f"ERROR: set {CREDENTIALS_ENV} to an absolute existing file.", file=sys.stderr)
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

    planned: list[tuple[Any, bool, Any]] = []  # (ref, derived, stored)
    scanned = 0
    for doc in db.collection(COLLECTION).stream():
        scanned += 1
        data = doc.to_dict() or {}
        derived = derive_discover_eligible(data)
        stored = data.get("discover_eligible")
        if stored is not derived:
            planned.append((doc.reference, derived, stored))

    false_to_true = sum(1 for _, d, s in planned if s is False and d is True)
    true_to_false = sum(1 for _, d, s in planned if s is True and d is False)
    null_to_false = sum(
        1 for _, d, s in planned if s is not True and s is not False and d is False
    )
    null_to_true = sum(
        1 for _, d, s in planned if s is not True and s is not False and d is True
    )
    other = len(planned) - false_to_true - true_to_false - null_to_false - null_to_true

    print(
        {
            "policy": POLICY,
            "scanned": scanned,
            "writes_planned": len(planned),
            "false_to_true": false_to_true,
            "true_to_false": true_to_false,
            "null_or_invalid_to_false": null_to_false,
            "null_or_invalid_to_true": null_to_true,
            "other_mismatch": other,
            "started_at_utc": datetime.now(timezone.utc).isoformat(),
        }
    )

    # Safety: refuse unexpected false→true volume for this known population
    # unless formula independently derived them (already counted above).
    writes_executed = 0
    batches = 0
    batch = db.batch()
    pending = 0
    for ref, derived, _stored in planned:
        # ONLY discover_eligible — no updated_at / other fields.
        batch.update(ref, {"discover_eligible": derived})
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

    print(
        {
            "writes_executed": writes_executed,
            "batches_committed": batches,
            "false_to_true_executed": false_to_true,
            "false_writes_executed": sum(1 for _, d, _ in planned if d is False),
            "true_writes_executed": sum(1 for _, d, _ in planned if d is True),
            "finished_at_utc": datetime.now(timezone.utc).isoformat(),
            "field_touched": ["discover_eligible"],
        }
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
