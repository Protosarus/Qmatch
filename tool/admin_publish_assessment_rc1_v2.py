#!/usr/bin/env python3
"""Admin SDK one-shot publisher for Assessment Content RC1 (*_v2 only).

Default mode is **dry-run** (no Firestore connection, no writes).

Real publish (DO NOT RUN unless explicitly approved):
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/qmatch-sa.json
  python3 tool/admin_publish_assessment_rc1_v2.py \\
    --dry-run=false \\
    --confirmation-phrase=SYNC_LOCALIZED_ASSESSMENT_SETS

Safety:
  - Loads only build/assessment_sets_v2/all_assessment_sets_v2.json
  - Refuses if set count != 150
  - Refuses if any id does not end with _v2
  - Writes only assessment_sets/{id}
  - Never prints service account / private key contents
  - Never writes users/messages/matches/profiles/questions

See docs/firestore_admin_publish_plan_rc1.md
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
DEFAULT_SOURCE = ROOT / "build" / "assessment_sets_v2" / "all_assessment_sets_v2.json"
RESULT_PATH = ROOT / "build" / "firestore_admin_publish_rc1_result.json"

TARGET_COLLECTION = "assessment_sets"
REQUIRED_DOC_COUNT = 150
REQUIRED_PHRASE = "SYNC_LOCALIZED_ASSESSMENT_SETS"
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"

FORBIDDEN_COLLECTIONS = frozenset(
    {"users", "messages", "matches", "profiles", "questions"}
)


def _parse_dry_run(value: str) -> bool:
    v = value.strip().lower()
    if v in {"true", "1", "yes"}:
        return True
    if v in {"false", "0", "no"}:
        return False
    raise argparse.ArgumentTypeError("dry-run must be true or false")


def load_sets(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        raise FileNotFoundError(
            f"Missing v2 export: {path}. Run: python3 scripts/export_assessment_sets_v2.py"
        )
    data = json.loads(path.read_text(encoding="utf-8"))
    sets = data.get("sets")
    if not isinstance(sets, list):
        raise ValueError("all_assessment_sets_v2.json: 'sets' must be a list")
    return sets


def validate_payload(
    sets: list[dict[str, Any]],
    *,
    collection: str,
) -> list[str]:
    errors: list[str] = []
    if collection != TARGET_COLLECTION:
        errors.append(
            f"target collection must be exactly {TARGET_COLLECTION!r}, got {collection!r}"
        )
    if collection in FORBIDDEN_COLLECTIONS:
        errors.append(f"refused forbidden collection: {collection}")
    if len(sets) != REQUIRED_DOC_COUNT:
        errors.append(
            f"doc count must be exactly {REQUIRED_DOC_COUNT}, got {len(sets)}"
        )

    ids: list[str] = []
    for i, doc in enumerate(sets):
        if not isinstance(doc, dict):
            errors.append(f"sets[{i}] is not an object")
            continue
        doc_id = doc.get("id")
        if not isinstance(doc_id, str) or not doc_id:
            errors.append(f"sets[{i}] missing string id")
            continue
        if not doc_id.endswith("_v2"):
            errors.append(f"id does not end with _v2: {doc_id}")
        if "/" in doc_id or doc_id.startswith(f"{TARGET_COLLECTION}/"):
            errors.append(f"id must be bare document id, not a path: {doc_id}")
        ids.append(doc_id)

    if len(ids) != len(set(ids)):
        errors.append("duplicate document ids in payload")

    iq = sum(1 for x in ids if x.startswith("iq_set_") and x.endswith("_v2"))
    eq = sum(1 for x in ids if x.startswith("eq_set_") and x.endswith("_v2"))
    fr = sum(
        1 for x in ids if x.startswith("frequency_set_") and x.endswith("_v2")
    )
    if iq != 50 or eq != 50 or fr != 50:
        errors.append(f"expected 50/50/50 IQ/EQ/Frequency v2 ids, got {iq}/{eq}/{fr}")

    return errors


def credentials_path_from_env() -> Path | None:
    raw = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not raw:
        return None
    return Path(raw).expanduser()


def assert_credentials_safe(path: Path) -> None:
    """Refuse missing/unreadable keys; never print key contents."""
    if not path.is_file():
        raise FileNotFoundError(
            f"{CREDENTIALS_ENV} points to missing file: {path}"
        )
    resolved = path.resolve()
    try:
        resolved.relative_to(ROOT.resolve())
        raise RuntimeError(
            f"REFUSED: service account file must stay OUTSIDE the repo. "
            f"Got path under repo: {resolved}"
        )
    except ValueError:
        # Not under ROOT — good.
        pass
    # Touch-readability only; do not print JSON.
    if path.stat().st_size < 32:
        raise RuntimeError(f"credentials file looks empty: {path}")


def write_result(payload: dict[str, Any]) -> Path:
    RESULT_PATH.parent.mkdir(parents=True, exist_ok=True)
    RESULT_PATH.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return RESULT_PATH


def publish_with_admin(
    sets: list[dict[str, Any]],
    *,
    cred_path: Path,
) -> tuple[int, list[str]]:
    """Real write path — only called when dry-run=false and gates pass."""
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
        from google.cloud.firestore import SERVER_TIMESTAMP
    except ImportError as e:
        raise RuntimeError(
            "firebase-admin is not installed. "
            "Install outside commit: pip install firebase-admin"
        ) from e

    # Initialize without logging credential JSON.
    if not firebase_admin._apps:
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)

    db = firestore.client()
    written = 0
    errors: list[str] = []
    batch_size = 400  # under 500 Firestore batch limit
    batch = db.batch()
    ops = 0

    for doc in sets:
        doc_id = doc["id"]
        if not str(doc_id).endswith("_v2"):
            errors.append(f"refused non-v2 id at write time: {doc_id}")
            continue
        ref = db.collection(TARGET_COLLECTION).document(doc_id)
        payload = dict(doc)
        payload["published_at"] = SERVER_TIMESTAMP
        payload["updated_at"] = SERVER_TIMESTAMP
        if "created_at" not in payload:
            payload["created_at"] = SERVER_TIMESTAMP
        batch.set(ref, payload, merge=True)
        ops += 1
        written += 1
        if ops >= batch_size:
            batch.commit()
            batch = db.batch()
            ops = 0

    if ops:
        batch.commit()

    return written, errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Admin SDK RC1 assessment_sets *_v2 publisher (dry-run default)."
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to all_assessment_sets_v2.json",
    )
    parser.add_argument(
        "--collection",
        default=TARGET_COLLECTION,
        help="Must be exactly assessment_sets",
    )
    parser.add_argument(
        "--dry-run",
        type=_parse_dry_run,
        default=True,
        help="Default true. Set false only for approved real publish.",
    )
    parser.add_argument(
        "--confirmation-phrase",
        default="",
        help=f"Required when --dry-run=false: {REQUIRED_PHRASE}",
    )
    args = parser.parse_args(argv)

    dry_run: bool = args.dry_run
    collection: str = args.collection
    phrase: str = args.confirmation_phrase

    report: dict[str, Any] = {
        "mode": "dryRun" if dry_run else "write",
        "sdk": "python_firebase_admin",
        "source": str(args.source),
        "targetCollection": collection,
        "dryRun": dry_run,
        "confirmationAccepted": phrase == REQUIRED_PHRASE,
        "credentialsEnv": CREDENTIALS_ENV,
        "credentialsConfigured": bool(os.environ.get(CREDENTIALS_ENV, "").strip()),
        # Never include credential path contents or key material.
        "docsConsidered": 0,
        "docsWritten": 0,
        "writesPerformed": False,
        "versionedIdCount": 0,
        "errors": [],
        "warnings": [],
        "documentIdsSample": [],
        "generatedAt": datetime.now(timezone.utc).isoformat(),
    }

    try:
        sets = load_sets(args.source)
    except Exception as e:
        report["errors"].append(str(e))
        write_result(report)
        print(json.dumps(report, indent=2))
        return 1

    report["docsConsidered"] = len(sets)
    ids = [str(s.get("id")) for s in sets if isinstance(s, dict)]
    report["versionedIdCount"] = sum(1 for i in ids if i.endswith("_v2"))
    report["documentIdsSample"] = {
        "first": ids[0] if ids else None,
        "last": ids[-1] if ids else None,
        "count": len(ids),
    }

    val_errors = validate_payload(sets, collection=collection)
    if val_errors:
        report["errors"].extend(val_errors)
        write_result(report)
        print(json.dumps(report, indent=2))
        print("REFUSED: payload/collection validation failed (no Firestore writes).")
        return 1

    if dry_run:
        report["warnings"].append("DRY RUN ONLY — no Firestore writes performed")
        write_result(report)
        print(json.dumps(report, indent=2))
        print(
            f"DRY RUN OK: would write {REQUIRED_DOC_COUNT} docs to "
            f"{TARGET_COLLECTION}/{{id}}_v2. Result: {RESULT_PATH}"
        )
        return 0

    # ---- Real publish gates ----
    if phrase != REQUIRED_PHRASE:
        report["errors"].append(
            f"confirmation phrase mismatch (need {REQUIRED_PHRASE})"
        )
        write_result(report)
        print(json.dumps(report, indent=2))
        print("REFUSED: confirmation phrase required for real publish.")
        return 2

    cred_path = credentials_path_from_env()
    if cred_path is None:
        report["errors"].append(
            f"missing env {CREDENTIALS_ENV}=/absolute/path/outside/repo/sa.json"
        )
        write_result(report)
        print(json.dumps(report, indent=2))
        print("REFUSED: credentials env not set (no Firestore writes).")
        return 2

    try:
        assert_credentials_safe(cred_path)
    except Exception as e:
        report["errors"].append(str(e))
        write_result(report)
        print(json.dumps(report, indent=2))
        print("REFUSED: credentials gate failed (no Firestore writes).")
        return 2

    report["warnings"].append(
        "Real publish path entered — writing assessment_sets/*_v2 only."
    )
    try:
        written, write_errors = publish_with_admin(sets, cred_path=cred_path)
        report["docsWritten"] = written
        report["writesPerformed"] = written > 0
        report["errors"].extend(write_errors)
    except Exception as e:
        # Do not include credential material if exception strings leak paths only.
        report["errors"].append(f"publish failed: {type(e).__name__}: {e}")
        write_result(report)
        print(json.dumps(report, indent=2))
        return 1

    write_result(report)
    print(json.dumps(report, indent=2))
    if report["writesPerformed"] and report["docsWritten"] == REQUIRED_DOC_COUNT:
        print(f"WRITE OK: {written} docs. Result: {RESULT_PATH}")
        return 0
    print("WRITE INCOMPLETE OR FAILED — see errors in result JSON.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
