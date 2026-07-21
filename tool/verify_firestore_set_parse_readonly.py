#!/usr/bin/env python3
"""Read-only simulation: can RC1 Firestore docs parse like AssessmentSetModel.fromFirestore?

Does not write Firestore. Uses Admin credentials only to READ one sample doc.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def coerce_version(v):
    if v is None:
        return ""
    if isinstance(v, str):
        return v
    if isinstance(v, (int, float)):
        return str(int(v))
    return str(v)


def main() -> int:
    cred = os.environ.get("QMATCH_FIRESTORE_ADMIN_CREDENTIALS", "").strip()
    if not cred:
        # Fallback known out-of-repo path (do not print key contents)
        candidate = Path.home() / "Secrets/qmatch/qmatch-53d62-firebase-adminsdk-fbsvc-03e08211d5.json"
        if candidate.is_file():
            cred = str(candidate)
        else:
            print("No credentials; skipping live sample read")
            return 0

    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        firebase_admin.initialize_app(credentials.Certificate(cred))
    db = firestore.client()
    doc = db.collection("assessment_sets").document("iq_set_001_v2").get()
    if not doc.exists:
        print("MISSING iq_set_001_v2")
        return 1
    data = doc.to_dict() or {}
    # Simulate OLD broken cast
    old_ok = isinstance(data.get("version"), str) or data.get("version") is None
    new_version = coerce_version(data.get("version"))
    sample = {
        "id": data.get("id") or doc.id,
        "type": data.get("type"),
        "version_raw_type": type(data.get("version")).__name__,
        "version_raw": data.get("version"),
        "version_coerced": new_version,
        "active": data.get("active"),
        "status": data.get("status"),
        "language_mode": data.get("language_mode"),
        "question_count": data.get("question_count"),
        "old_string_cast_would_succeed": old_ok,
        "parse_ok_with_coerce": new_version == "2" and data.get("active") is True,
        "writesPerformed": False,
    }
    print(json.dumps(sample, indent=2))
    return 0 if sample["parse_ok_with_coerce"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
