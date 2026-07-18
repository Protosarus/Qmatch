#!/usr/bin/env python3
"""Account deletion processor — DRY-RUN skeleton only (Phase 3P-A12).

Inventories what *would* be affected for one explicit --uid.
Does **not** delete, update, or set any Firestore / Auth / Storage data.

Usage:
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  export QMATCH_FIREBASE_STORAGE_BUCKET="qmatch-53d62.firebasestorage.app"  # optional
  python3 tool/account_deletion_processor_dry_run.py --uid=<FIREBASE_UID>

Safety:
  - Requires --uid (refuses otherwise)
  - Dry-run only; refuses --dry-run=false
  - Never calls delete/update/set/batch.commit
  - Never deletes Auth users or Storage objects (no blob.delete)
  - Never writes assessment_sets or questions
  - Never prints service account key contents
  - Storage inventory requires QMATCH_FIREBASE_STORAGE_BUCKET; if missing, dry-run continues with a warning
  - May write only a local JSON report under build/

See docs/account_deletion_processor_plan.md
     docs/account_deletion_processor_dry_run_skeleton.md
"""

from __future__ import annotations

import argparse
import ast
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build"
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
STORAGE_BUCKET_ENV = "QMATCH_FIREBASE_STORAGE_BUCKET"
THIS_FILE = Path(__file__).resolve()

# Forbidden method names on Firestore/Auth/Storage mutation paths.
# Source self-check fails if these appear as Call attributes in this file
# (excluding this frozenset / comment strings handled via AST).
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
        "commit",  # batch.commit / WriteBatch.commit
    }
)


def mask_uid(uid: str) -> str:
    if not uid:
        return "(empty)"
    if len(uid) <= 6:
        return "***"
    return f"{uid[:6]}…"


def mask_storage_object_name(name: str, uid: str) -> str:
    """Replace full uid segments in object paths for report safety."""
    if not name:
        return name
    return name.replace(uid, mask_uid(uid))


def storage_bucket_from_env() -> str | None:
    raw = os.environ.get(STORAGE_BUCKET_ENV, "").strip()
    return raw or None


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=(
            "Dry-run inventory for one account deletion UID. "
            "Never modifies Firebase data."
        )
    )
    p.add_argument(
        "--uid",
        required=True,
        help="Exact Firebase Auth / users/{uid} document id to inventory.",
    )
    p.add_argument(
        "--dry-run",
        default="true",
        help="Must be true. false is refused (this skeleton has no execute mode).",
    )
    p.add_argument(
        "--self-check-only",
        action="store_true",
        help="Run source forbidden-call scan only; no Firebase connection.",
    )
    return p.parse_args(argv)


def assert_dry_run_only(dry_run_raw: str) -> None:
    v = dry_run_raw.strip().lower()
    if v in {"false", "0", "no"}:
        raise RuntimeError(
            "REFUSED: this skeleton is dry-run only. "
            "--dry-run=false is not supported. "
            "No execute processor exists yet."
        )
    if v not in {"true", "1", "yes"}:
        raise RuntimeError(
            f"REFUSED: invalid --dry-run={dry_run_raw!r}; only true is allowed."
        )


def assert_uid(uid: str) -> str:
    u = uid.strip()
    if not u:
        raise RuntimeError("REFUSED: --uid is required and must be non-empty.")
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
    """AST-scan this file for forbidden mutation call attributes."""
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
            # Allow mentions only if somehow wrapped — any Call is forbidden.
            errors.append(
                f"forbidden call attr .{attr}() at line {node.lineno}"
            )
    return errors


def runtime_guard(dry_run: bool) -> None:
    if dry_run is not True:
        raise RuntimeError("REFUSED: runtime guard — dryRun must be True.")


def count_collection(col: Any) -> int:
    # Prefer count aggregation when available; fall back to streaming ids only.
    try:
        agg = col.count().get()
        # google-cloud-firestore AggregationQuery
        for result in agg:
            return int(result[0].value)
    except Exception:
        pass
    return sum(1 for _ in col.stream())


def list_doc_ids(col: Any, *, limit: int = 50) -> list[str]:
    ids: list[str] = []
    for i, doc in enumerate(col.stream()):
        if i >= limit:
            break
        ids.append(doc.id)
    return ids


def safe_get_doc(db: Any, path_parts: list[str]) -> dict[str, Any]:
    ref = db.collection(path_parts[0]).document(path_parts[1])
    for i in range(2, len(path_parts), 2):
        ref = ref.collection(path_parts[i]).document(path_parts[i + 1])
    snap = ref.get()
    return {
        "exists": bool(snap.exists),
        "id": snap.id,
        "field_keys": sorted((snap.to_dict() or {}).keys()) if snap.exists else [],
    }


def inventory_uid(uid: str) -> dict[str, Any]:
    runtime_guard(True)
    cred_path = credentials_path_from_env()

    try:
        import firebase_admin
        from firebase_admin import auth, credentials, firestore
    except ImportError as e:
        raise RuntimeError(
            "firebase_admin is not installed. "
            "pip install firebase-admin (ops machine only)."
        ) from e

    # Import storage only for read/list; never delete / never blob.delete().
    try:
        from firebase_admin import storage as fb_storage
    except Exception:
        fb_storage = None  # type: ignore

    bucket_name = storage_bucket_from_env()
    if not firebase_admin._apps:
        # Certificate path only — never print file contents.
        init_options: dict[str, Any] = {}
        if bucket_name:
            init_options["storageBucket"] = bucket_name
        firebase_admin.initialize_app(
            credentials.Certificate(str(cred_path)),
            options=init_options or None,
        )

    db = firestore.client()
    warnings: list[str] = []
    unresolved: list[str] = []
    collections: dict[str, Any] = {}

    # --- account_deletion_requests/{uid} ---
    req = safe_get_doc(db, ["account_deletion_requests", uid])
    req_data = {}
    if req["exists"]:
        snap = db.collection("account_deletion_requests").document(uid).get()
        req_data = snap.to_dict() or {}
        # Strip / mask sensitive-ish fields in report
        req_summary = {
            "exists": True,
            "status": req_data.get("status"),
            "source": req_data.get("source"),
            "uid_matches_doc": req_data.get("uid") == uid,
            "user_acknowledged_irreversible": req_data.get(
                "user_acknowledged_irreversible"
            ),
            "user_acknowledged_timeline": req_data.get(
                "user_acknowledged_timeline"
            ),
            "field_keys": sorted(req_data.keys()),
        }
    else:
        req_summary = {"exists": False}
        warnings.append("No account_deletion_requests/{uid} doc found.")
    collections["account_deletion_requests"] = req_summary

    # --- users/{uid} ---
    user_summary = safe_get_doc(db, ["users", uid])
    photo_urls: list[str] = []
    storage_prefix = f"profile_photos/{uid}/"
    if user_summary["exists"]:
        user_snap = db.collection("users").document(uid).get()
        user_data = user_snap.to_dict() or {}
        user_summary["account_deletion_requested"] = user_data.get(
            "account_deletion_requested"
        )
        user_summary["has_profile_photo_url"] = bool(
            user_data.get("profile_photo_url")
        )
        photos = user_data.get("photos")
        if isinstance(photos, list):
            user_summary["photos_count"] = len(photos)
            for p in photos:
                if isinstance(p, str) and p:
                    photo_urls.append(p)
        else:
            user_summary["photos_count"] = 0
        if isinstance(user_data.get("profile_photo_url"), str):
            photo_urls.append(user_data["profile_photo_url"])
    else:
        warnings.append("users/{uid} document missing.")
    collections["users"] = user_summary

    # --- subcollections ---
    user_ref = db.collection("users").document(uid)
    for sub in ("assessment_assignments", "assessments", "swipes", "blocks"):
        col = user_ref.collection(sub)
        try:
            n = count_collection(col)
            sample_ids = list_doc_ids(col, limit=20)
            collections[f"users/{uid}/{sub}"] = {
                "doc_count": n,
                "sample_ids_masked": [mask_uid(i) for i in sample_ids],
            }
        except Exception as e:
            collections[f"users/{uid}/{sub}"] = {"error": type(e).__name__}
            unresolved.append(f"Failed counting users/.../{sub}: {type(e).__name__}")

    # --- matches (arrayContains) ---
    try:
        matches = list(
            db.collection("matches").where("users", "array_contains", uid).stream()
        )
        collections["matches"] = {
            "doc_count": len(matches),
            "sample_ids_masked": [mask_uid(d.id) for d in matches[:20]],
            "query": "users array_contains uid",
        }
    except Exception as e:
        collections["matches"] = {"error": type(e).__name__}
        unresolved.append(
            f"matches query failed ({type(e).__name__}); may need index or perms."
        )

    # --- threads ---
    try:
        threads = list(
            db.collection("threads")
            .where("participants", "array_contains", uid)
            .stream()
        )
        thread_ids = [d.id for d in threads]
        collections["threads"] = {
            "doc_count": len(threads),
            "sample_ids_masked": [mask_uid(i) for i in thread_ids[:20]],
            "query": "participants array_contains uid",
        }
        # Message counts (cap threads scanned)
        msg_total = 0
        sender_msg_total = 0
        previews_with_text = 0
        for d in threads[:25]:
            data = d.to_dict() or {}
            preview = data.get("last_message_preview")
            if isinstance(preview, str) and preview.strip():
                previews_with_text += 1
            try:
                msgs = list(d.reference.collection("messages").stream())
                msg_total += len(msgs)
                sender_msg_total += sum(
                    1
                    for m in msgs
                    if (m.to_dict() or {}).get("sender_id") == uid
                )
            except Exception:
                unresolved.append(
                    f"messages under thread {mask_uid(d.id)} not fully counted"
                )
        collections["threads_messages_sample"] = {
            "threads_scanned": min(len(threads), 25),
            "messages_total_in_scanned": msg_total,
            "messages_from_uid_in_scanned": sender_msg_total,
            "threads_with_preview_text": previews_with_text,
            "note": "Full message purge counts may need deeper scan in execute phase.",
        }
    except Exception as e:
        collections["threads"] = {"error": type(e).__name__}
        unresolved.append(
            f"threads query failed ({type(e).__name__}); may need index or perms."
        )

    # --- reports (reporter or reported) ---
    reports_reporter = 0
    reports_reported = 0
    try:
        reports_reporter = len(
            list(
                db.collection("reports")
                .where("reporter_uid", "==", uid)
                .stream()
            )
        )
    except Exception as e:
        unresolved.append(f"reports by reporter_uid failed: {type(e).__name__}")
    try:
        reports_reported = len(
            list(
                db.collection("reports")
                .where("reported_uid", "==", uid)
                .stream()
            )
        )
    except Exception as e:
        unresolved.append(f"reports by reported_uid failed: {type(e).__name__}")
    collections["reports"] = {
        "as_reporter_count": reports_reporter,
        "as_reported_count": reports_reported,
        "retention_note": "Plan: retain/anonymize; do not wipe for safety.",
    }

    # --- Storage prefix listing (read-only) ---
    # Requires QMATCH_FIREBASE_STORAGE_BUCKET. Missing env → skip, do not fail dry-run.
    storage_prefix_masked = f"profile_photos/{mask_uid(uid)}/"
    storage_info: dict[str, Any] = {
        "prefix_masked": storage_prefix_masked,
        "profile_url_refs_count": len(photo_urls),
        "listed_object_count": None,
        "list_attempted": False,
        "storage_bucket_env": STORAGE_BUCKET_ENV,
        "storage_bucket_configured": bool(bucket_name),
        "read_only": True,
    }
    if not bucket_name:
        storage_info["skipped"] = True
        storage_info["skip_reason"] = f"{STORAGE_BUCKET_ENV} not set"
        unresolved.append(
            "Storage bucket env missing; storage inventory skipped."
        )
    elif fb_storage is None:
        storage_info["skipped"] = True
        unresolved.append("firebase_admin.storage unavailable for prefix list.")
    else:
        try:
            # Explicit bucket name — avoids ValueError when default bucket unset.
            bucket = fb_storage.bucket(bucket_name)
            storage_info["list_attempted"] = True
            blobs = list(bucket.list_blobs(prefix=storage_prefix, max_results=100))
            storage_info["listed_object_count"] = len(blobs)
            storage_info["sample_names_masked"] = [
                mask_storage_object_name(b.name, uid) for b in blobs[:10]
            ]
            # Never call blob.delete() — inventory only.
        except Exception as e:
            storage_info["list_error"] = type(e).__name__
            unresolved.append(
                f"Storage list for {storage_prefix_masked} failed: {type(e).__name__}"
            )
    collections["storage_profile_photos"] = storage_info

    # --- Auth existence (read-only get_user) ---
    auth_info: dict[str, Any] = {"lookup_attempted": True}
    try:
        record = auth.get_user(uid)
        auth_info["exists"] = True
        auth_info["disabled"] = bool(record.disabled)
        auth_info["provider_ids"] = [
            p.provider_id for p in (record.provider_data or [])
        ]
        # Do not print phone/email.
    except auth.UserNotFoundError:
        auth_info["exists"] = False
    except Exception as e:
        auth_info["exists"] = None
        auth_info["error"] = type(e).__name__
        unresolved.append(f"Auth get_user failed: {type(e).__name__}")
    collections["firebase_auth"] = auth_info

    # Hard deny inventory of global content collections (mention only).
    collections["assessment_sets"] = {
        "inventoried": False,
        "note": "FORBIDDEN to mutate; not scanned for deletion.",
    }
    collections["questions"] = {
        "inventoried": False,
        "note": "FORBIDDEN to mutate; not scanned for deletion.",
    }

    proposed_sequence = [
        "Claim request status requested→processing (execute only; skipped in dry-run)",
        "Close/anonymize matches involving uid",
        "Close threads; redact last_message_preview if needed",
        "Redact or delete messages where sender_id==uid (policy)",
        "Delete users/{uid}/assessment_assignments/*",
        "Delete users/{uid}/assessments/*",
        "Delete users/{uid}/swipes/*",
        "Delete users/{uid}/blocks/* (after optional retention snapshot)",
        "Delete Storage profile_photos/{uid}/**",
        "Delete or tombstone users/{uid}",
        "Delete Firebase Auth user (last)",
        "Finalize account_deletion_requests/{uid} status=completed + audit fields",
        "Retain reports (anonymize if required); never delete assessment_sets/questions",
    ]

    return {
        "uid_masked": mask_uid(uid),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "dryRun": True,
        "destructiveOperationsPerformed": False,
        "authDeletePerformed": False,
        "storageDeletePerformed": False,
        "firestoreWritesPerformed": False,
        "collections_inventoried": collections,
        "doc_counts_summary": {
            "assessment_assignments": collections.get(
                f"users/{uid}/assessment_assignments", {}
            ).get("doc_count"),
            "assessments": collections.get(f"users/{uid}/assessments", {}).get(
                "doc_count"
            ),
            "swipes": collections.get(f"users/{uid}/swipes", {}).get("doc_count"),
            "blocks": collections.get(f"users/{uid}/blocks", {}).get("doc_count"),
            "matches": collections.get("matches", {}).get("doc_count"),
            "threads": collections.get("threads", {}).get("doc_count"),
            "reports_as_reporter": reports_reporter,
            "reports_as_reported": reports_reported,
            "storage_objects_listed": storage_info.get("listed_object_count"),
        },
        "unresolved_manual_review_items": unresolved,
        "proposed_deletion_anonymization_sequence": proposed_sequence,
        "warnings": warnings,
        "credentials_env": CREDENTIALS_ENV,
        "credentials_path_configured": True,
        "note": (
            "DRY-RUN skeleton only. No execute mode. "
            "Future execute would require --dry-run=false plus "
            "confirmation phrase PROCESS_ACCOUNT_DELETION_REQUESTS."
        ),
    }


def write_report(report: dict[str, Any]) -> Path:
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    masked = report["uid_masked"].replace("…", "").replace("...", "")
    # filesystem-safe
    masked_fs = re.sub(r"[^a-zA-Z0-9_-]", "", masked) or "unknown"
    out = BUILD_DIR / f"account_deletion_processor_dry_run_{masked_fs}.json"
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return out


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    # Source safety scan always runs.
    scan_errors = source_self_check()
    if scan_errors:
        print("SELF-CHECK FAILED:", file=sys.stderr)
        for e in scan_errors:
            print(f"  - {e}", file=sys.stderr)
        return 3

    if args.self_check_only:
        print("self_check=ok forbidden_mutation_calls=0")
        print("dry_run_skeleton=ready (no Firebase connection)")
        return 0

    try:
        assert_dry_run_only(args.dry_run)
        uid = assert_uid(args.uid)
        runtime_guard(True)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    try:
        report = inventory_uid(uid)
        out = write_report(report)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    print(f"dryRun=true uid_masked={report['uid_masked']}")
    print(f"report={out}")
    print("destructiveOperationsPerformed=false")
    print("firestoreWritesPerformed=false authDeletePerformed=false storageDeletePerformed=false")
    if report["warnings"]:
        print("warnings:")
        for w in report["warnings"]:
            print(f"  - {w}")
    if report["unresolved_manual_review_items"]:
        print("unresolved:")
        for u in report["unresolved_manual_review_items"]:
            print(f"  - {u}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
