#!/usr/bin/env python3
"""Read-only discovery of pending account deletion requests (Phase 3P-A11).

Default: print usage and exit — **no Firebase connection**.

List mode (read-only Admin SDK; still no writes):
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/discover_account_deletion_requests_readonly.py --list-pending

Safety:
  - Never deletes Auth users, Storage, or Firestore docs
  - Never updates account_deletion_requests or users
  - Never touches assessment_sets
  - Prints masked UIDs only (first 6 chars + ellipsis)
  - Does not print service account / private key contents

See docs/account_deletion_processor_plan.md
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import Any

CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
COLLECTION = "account_deletion_requests"


def mask_uid(uid: str) -> str:
    if not uid:
        return "(empty)"
    if len(uid) <= 6:
        return "***"
    return f"{uid[:6]}…"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Read-only list of pending account deletion requests."
    )
    p.add_argument(
        "--list-pending",
        action="store_true",
        help="Query Firestore for status==requested (requires Admin credentials).",
    )
    p.add_argument(
        "--limit",
        type=int,
        default=100,
        help="Max docs to list (default 100).",
    )
    return p.parse_args()


def print_usage_default() -> None:
    print(
        "discover_account_deletion_requests_readonly.py — READ ONLY\n"
        "\n"
        "Default mode: no Firebase connection.\n"
        "\n"
        "To list pending requests (still non-destructive):\n"
        f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
        "  python3 tool/discover_account_deletion_requests_readonly.py --list-pending\n"
        "\n"
        "This tool never deletes or updates user data.\n"
    )


def list_pending(limit: int) -> int:
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
        firebase_admin.initialize_app(credentials.Certificate(cred_path))

    db = firestore.client()
    query = (
        db.collection(COLLECTION)
        .where("status", "==", "requested")
        .limit(limit)
    )
    docs = list(query.stream())

    print(f"pending_count_listed={len(docs)} (limit={limit})")
    print("masked_uids:")
    for doc in docs:
        data: dict[str, Any] = doc.to_dict() or {}
        uid = str(data.get("uid") or doc.id)
        source = data.get("source")
        print(f"  - {mask_uid(uid)} source={source} doc_id_masked={mask_uid(doc.id)}")

    print(
        "\nREAD-ONLY complete. No deletes/updates performed. "
        "No Auth/Storage/assessment_sets access."
    )
    return 0


def main() -> int:
    args = parse_args()
    if not args.list_pending:
        print_usage_default()
        return 0
    return list_pending(args.limit)


if __name__ == "__main__":
    raise SystemExit(main())
