#!/usr/bin/env python3
"""TEST-ONLY Passport geography backfill for Stage B2 seed users.

Writes home_country / home_city / home_geo_updated_at on
`qmatch_stage_b2_seed_01`…`50` only, after aborting unless every target
doc exists and `is_test_data == true`. Does not touch real users.

  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/passport_test_geo_cohort_v1.py
  python3 tool/passport_test_geo_cohort_v1.py --execute --confirm BACKFILL_PASSPORT_TEST_GEO
  python3 tool/passport_test_geo_cohort_v1.py --cleanup --confirm REVERT_PASSPORT_TEST_GEO
"""

from __future__ import annotations

import argparse
import os
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
PROJECT_ID = "qmatch-53d62"
POLICY = "passport_test_geo_cohort_v1"
COHORT_ID = "passport_test_geo_v1"
EXECUTE_CONFIRM = "BACKFILL_PASSPORT_TEST_GEO"
CLEANUP_CONFIRM = "REVERT_PASSPORT_TEST_GEO"
GEO_FIELDS = ("home_country", "home_city", "home_geo_updated_at")
COHORT_FIELD = "passport_geo_cohort_id"

ASSIGNMENTS: dict[int, tuple[str, str]] = {}
for _i in range(1, 11):
    ASSIGNMENTS[_i] = ("TR", "istanbul")
for _i in range(11, 21):
    ASSIGNMENTS[_i] = ("GB", "london")
for _i in range(21, 31):
    ASSIGNMENTS[_i] = ("DE", "berlin")
for _i in range(31, 41):
    ASSIGNMENTS[_i] = ("FR", "paris")
for _i in range(41, 51):
    ASSIGNMENTS[_i] = ("ES", "madrid")

TARGET_UIDS = tuple(f"qmatch_stage_b2_seed_{i:02d}" for i in range(1, 51))


def credentials_path() -> str:
    cred_path = os.environ.get(CREDENTIALS_ENV, "").strip()
    if not cred_path or not os.path.isabs(cred_path) or not os.path.isfile(cred_path):
        raise SystemExit(
            f"ERROR: set {CREDENTIALS_ENV} to an absolute existing file outside the repo."
        )
    try:
        Path(cred_path).resolve().relative_to(ROOT.resolve())
        raise SystemExit("ERROR: credentials must live outside the repo.")
    except ValueError:
        pass
    return cred_path


def init_db():
    import firebase_admin
    from firebase_admin import credentials, firestore

    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(credentials_path()),
            {"projectId": PROJECT_ID},
        )
    return firestore.client()


def planned_geo(uid: str) -> tuple[str, str]:
    slot = int(uid.rsplit("_", 1)[-1])
    return ASSIGNMENTS[slot]


def geo_snapshot(data: dict[str, Any] | None) -> tuple[Any, Any, bool]:
    data = data or {}
    return (
        data.get("home_country"),
        data.get("home_city"),
        data.get("home_geo_updated_at") is not None,
    )


def load_targets(db) -> list[tuple[str, Any, dict[str, Any]]]:
    refs = [db.collection("users").document(uid) for uid in TARGET_UIDS]
    snaps = list(db.get_all(refs))
    by_id = {snap.id: snap for snap in snaps}
    out: list[tuple[str, Any, dict[str, Any]]] = []
    missing: list[str] = []
    not_test: list[str] = []
    for uid in TARGET_UIDS:
        snap = by_id.get(uid)
        if snap is None or not snap.exists:
            missing.append(uid)
            continue
        data = snap.to_dict() or {}
        if data.get("is_test_data") is not True:
            not_test.append(uid)
            continue
        out.append((uid, snap.reference, data))
    if missing or not_test:
        print("ABORT: target set failed pre-write verification.", file=sys.stderr)
        if missing:
            print("  missing:", ", ".join(missing), file=sys.stderr)
        if not_test:
            print("  not is_test_data:", ", ".join(not_test), file=sys.stderr)
        raise SystemExit(2)
    return out


def scan_home_geo(db) -> dict[str, tuple[Any, Any, bool]]:
    found: dict[str, tuple[Any, Any, bool]] = {}
    for doc in db.collection("users").stream():
        data = doc.to_dict() or {}
        snap = geo_snapshot(data)
        if snap != (None, None, False):
            found[doc.id] = snap
    return found


def print_plan(rows: list[tuple[str, Any, dict[str, Any]]]) -> None:
    dist = Counter()
    print(f"{POLICY} plan ({len(rows)} users)")
    for uid, _ref, data in rows:
        country, city = planned_geo(uid)
        dist[f"{country}/{city}"] += 1
        prev_c, prev_city, had_ts = geo_snapshot(data)
        print(
            f"  {uid}  is_test_data={data.get('is_test_data')!r}  "
            f"{prev_c}/{prev_city} -> {country}/{city}  "
            f"had_geo_ts={had_ts}"
        )
    print("planned_distribution", dict(dist))


def execute(db, rows: list[tuple[str, Any, dict[str, Any]]]) -> None:
    from firebase_admin import firestore as fs

    before_others = {
        uid: snap
        for uid, snap in scan_home_geo(db).items()
        if uid not in TARGET_UIDS
    }
    batch = db.batch()
    pending = 0
    for uid, ref, _data in rows:
        country, city = planned_geo(uid)
        batch.update(
            ref,
            {
                "home_country": country,
                "home_city": city,
                "home_geo_updated_at": fs.SERVER_TIMESTAMP,
                COHORT_FIELD: COHORT_ID,
            },
        )
        pending += 1
        if pending >= 400:
            batch.commit()
            batch = db.batch()
            pending = 0
    if pending:
        batch.commit()

    verify(db, rows, before_others)


def verify(
    db,
    rows: list[tuple[str, Any, dict[str, Any]]],
    before_others: dict[str, tuple[Any, Any, bool]],
) -> None:
    refs = [db.collection("users").document(uid) for uid in TARGET_UIDS]
    snaps = {snap.id: snap for snap in db.get_all(refs)}
    dist: Counter[str] = Counter()
    bad: list[str] = []
    for uid, _ref, before in rows:
        snap = snaps.get(uid)
        data = (snap.to_dict() if snap and snap.exists else None) or {}
        country, city = planned_geo(uid)
        ok = (
            data.get("is_test_data") is True
            and data.get("home_country") == country
            and data.get("home_city") == city
            and data.get("home_geo_updated_at") is not None
            and data.get(COHORT_FIELD) == COHORT_ID
        )
        dist[f"{country}/{city}"] += 1
        if not ok:
            bad.append(uid)
            print(
                f"VERIFY FAIL {uid}: "
                f"country={data.get('home_country')!r} city={data.get('home_city')!r} "
                f"cohort={data.get(COHORT_FIELD)!r} is_test_data={data.get('is_test_data')!r}"
            )
        # Forbidden fields were not requested as deletes; confirm they still exist
        # as previously if they were present (location / location_text untouched).
        for key in ("location", "location_text", "discover_eligible"):
            if key in before and key not in data:
                bad.append(uid)
                print(f"VERIFY FAIL {uid}: lost field {key}")

    after_all = scan_home_geo(db)
    unexpected = []
    for uid, after in after_all.items():
        if uid in TARGET_UIDS:
            continue
        if before_others.get(uid) != after:
            unexpected.append(uid)
    vanished = [uid for uid in before_others if uid not in after_all]
    unexpected.extend(vanished)

    print("city_distribution", dict(dist))
    print("targets_ok", len(TARGET_UIDS) - len(set(bad)), "/", len(TARGET_UIDS))
    print("other_uids_geo_changed", unexpected)
    if bad or unexpected:
        raise SystemExit(3)
    expected = {
        "TR/istanbul": 10,
        "GB/london": 10,
        "DE/berlin": 10,
        "FR/paris": 10,
        "ES/madrid": 10,
    }
    if dict(dist) != expected:
        print("VERIFY FAIL distribution", dict(dist), "expected", expected)
        raise SystemExit(3)
    print("VERIFY_OK")


def cleanup(db) -> None:
    from firebase_admin import firestore as fs

    rows = load_targets(db)
    batch = db.batch()
    pending = 0
    deleted = 0
    skipped = 0
    for uid, ref, data in rows:
        if data.get(COHORT_FIELD) != COHORT_ID:
            skipped += 1
            print(f"skip {uid}: {COHORT_FIELD} is {data.get(COHORT_FIELD)!r}")
            continue
        batch.update(
            ref,
            {
                "home_country": fs.DELETE_FIELD,
                "home_city": fs.DELETE_FIELD,
                "home_geo_updated_at": fs.DELETE_FIELD,
                COHORT_FIELD: fs.DELETE_FIELD,
            },
        )
        deleted += 1
        pending += 1
        if pending >= 400:
            batch.commit()
            batch = db.batch()
            pending = 0
    if pending:
        batch.commit()
    print({"cleanup_deleted_fields_on": deleted, "skipped": skipped})


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="TEST-ONLY Passport geo backfill.")
    p.add_argument("--execute", action="store_true")
    p.add_argument("--cleanup", action="store_true")
    p.add_argument("--confirm", default="")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    db = init_db()
    if args.cleanup:
        if args.confirm != CLEANUP_CONFIRM:
            print(f"Refusing cleanup without --cleanup --confirm {CLEANUP_CONFIRM}")
            return 2
        cleanup(db)
        return 0
    rows = load_targets(db)
    print_plan(rows)
    if not args.execute:
        print(
            f"dry-run only. To write:\n"
            f"  python3 tool/passport_test_geo_cohort_v1.py "
            f"--execute --confirm {EXECUTE_CONFIRM}"
        )
        return 0
    if args.confirm != EXECUTE_CONFIRM:
        print(f"Refusing writes without --execute --confirm {EXECUTE_CONFIRM}")
        return 2
    execute(db, rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
