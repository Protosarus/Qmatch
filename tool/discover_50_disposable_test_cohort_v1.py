#!/usr/bin/env python3
"""Add 50 disposable Discover test users (`discover_50_disposable_test_cohort_v1`).

Keeps the existing 10 test users (`qmatch_stage_b2_seed_01`…`10`).
Writes only `qmatch_stage_b2_seed_11`…`60` with L1 discover eligibility,
complete canonical 20D, and names prefixed `[TEST]`.

Never writes the viewer user doc. Never writes any non-seed uid.
Marked `test_cohort_id=discover_50_disposable_v1` so this 50 can be
deleted later without touching the original 10.

Default is dry-run (no Firebase init, no writes).

  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/discover_50_disposable_test_cohort_v1.py \\
    --viewer-uid YOUR_UID --execute --confirm PREPARE_50_DISPOSABLE_DISCOVER_COHORT

Delete later (this 50 only):
  python3 tool/discover_50_disposable_test_cohort_v1.py \\
    --viewer-uid YOUR_UID --delete --confirm DELETE_50_DISPOSABLE_DISCOVER_COHORT
"""

from __future__ import annotations

import argparse
import importlib.util
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
PROJECT_ID = "qmatch-53d62"
POLICY = "discover_50_disposable_test_cohort_v1"
COHORT_ID = "discover_50_disposable_v1"
SEED_CONFIRM = "PREPARE_50_DISPOSABLE_DISCOVER_COHORT"
DELETE_CONFIRM = "DELETE_50_DISPOSABLE_DISCOVER_COHORT"

EXISTING_UIDS = tuple(f"qmatch_stage_b2_seed_{i:02d}" for i in range(1, 11))
NEW_UIDS = tuple(f"qmatch_stage_b2_seed_{i:02d}" for i in range(11, 61))
NEW_SLOTS = tuple(range(11, 61))

_V2_PATH = Path(__file__).with_name("stage_b2_test_cohort_seed_v2.py")
_spec = importlib.util.spec_from_file_location("stage_b2_test_cohort_seed_v2", _V2_PATH)
if _spec is None or _spec.loader is None:
    raise SystemExit(f"ERROR: cannot load {_V2_PATH}")
v2 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(v2)


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

    cred_path = credentials_path()
    if not firebase_admin._apps:
        firebase_admin.initialize_app(
            credentials.Certificate(cred_path),
            {"projectId": PROJECT_ID},
        )
    return firestore.client()


def canonical_coverage(data: dict[str, Any]) -> int:
    got = v2.scores_from_canonical(data)
    return sum(1 for dim in v2.ALL_20D if dim in got)


def unique_scores(base: dict[str, float], slot: int) -> dict[str, float]:
    k = slot - 11
    out: dict[str, float] = {}
    for i, dim in enumerate(v2.ALL_20D):
        value = base[dim]
        delta = 0.004 * (((k + i) % 17) + 1)
        raw = value + delta if (k + i) % 2 == 0 else value - delta
        out[dim] = v2.clamp01(raw)
    return out


def extra_specs(
    viewer_20d: dict[str, float],
    viewer_interests: list[str],
    now: datetime,
) -> list[dict[str, Any]]:
    shared = list(viewer_interests)
    try:
        disjoint = v2.disjoint_interests(viewer_interests)
    except SystemExit:
        disjoint = shared
    specs: list[dict[str, Any]] = []
    for slot in NEW_SLOTS:
        uid = f"qmatch_stage_b2_seed_{slot:02d}"
        scores = unique_scores(viewer_20d, slot)
        use_shared = (slot % 2) == 1
        specs.append(
            {
                "uid": uid,
                "slot": slot,
                "key": f"disposable_{slot:02d}",
                "title": f"[TEST] D-{slot:02d} Disposable",
                "purpose": "Disposable Discover card; complete 20D; L1 eligible.",
                "scores": scores,
                "interests": shared if use_shared else disjoint,
                "last_active": now,
                "interest_mode": "shared" if use_shared else "disjoint",
                "recency": "fresh",
            }
        )
    return specs


def build_user_doc(spec: dict[str, Any], viewer_uid: str) -> dict[str, Any]:
    scores: dict[str, float] = spec["scores"]
    legacy_freq = v2.legacy_freq_from_20d(scores)
    ftype, tags = v2.frequency_type_and_tags(legacy_freq)
    uid = spec["uid"]
    photo = f"https://example.com/qmatch-stage-b2-seed/{uid}.jpg"
    return {
        "uid": uid,
        "name": spec["title"],
        "bio": (
            f"TEST DATA {COHORT_ID} slot={spec['slot']} key={spec['key']}. "
            "Disposable Discover extra seed. Not a real person. "
            f"Delete later via test_cohort_id={COHORT_ID}."
        ),
        "age": 25 + (spec["slot"] % 15),
        "gender": "test",
        "looking_for": "test_only",
        "interests": spec["interests"],
        "profile_photo_url": photo,
        "photos": [photo],
        "active": True,
        "profile_completed": True,
        "test_completed": True,
        "assessment_flow_completed": True,
        "frequency_completed": True,
        "account_deletion_requested": False,
        "discover_eligible": True,
        "frequency_vector": legacy_freq,
        "frequency_type": ftype,
        "frequency_tags": tags,
        "frequency_score": round(
            (sum(legacy_freq.values()) / len(legacy_freq)) * 100.0, 2
        ),
        "frequency_canonical_profile_ready": True,
        "frequency_status": "completed",
        "last_active_at": spec["last_active"],
        "created_at": spec["last_active"],
        "updated_at": spec["last_active"],
        "is_test_data": True,
        "test_cohort_id": COHORT_ID,
        "seed_policy": POLICY,
        "seeded_for_viewer_uid": viewer_uid,
        "seed_slot": spec["slot"],
        "seed_key": spec["key"],
        "seed_interest_mode": spec["interest_mode"],
        "seed_recency": spec["recency"],
        "seed_disposable": True,
    }


def build_canonical_doc(spec: dict[str, Any]) -> dict[str, Any]:
    uid = spec["uid"]
    scores: dict[str, float] = spec["scores"]
    return {
        "schema_version": "qmatch_canonical_profile_v1",
        "registry_version": "canonical_dimension_registry_v1",
        "adapter_version": "frequency_to_20d_runtime_adapter_v1",
        "owner_uid": uid,
        "profile_status": "complete",
        "canonical_profile_ready": True,
        "measured_dimension_count": 20,
        "required_dimension_count": 20,
        "iq_group_status": "complete",
        "eq_group_status": "complete",
        "frequency_group_status": "complete",
        "measured_dimensions": v2.measured_dimensions(scores),
        "missing_dimension_ids": [],
        "missing_groups": [],
        "source_assessment_type": "frequency",
        "source_scoring_policy_version": "frequency_6d_uncalibrated_signed_evidence_v1",
        "source_bank_version": POLICY,
        "source_bank_locale": "en",
        "source_session_id": f"{uid}_synthetic_50card_v1",
        "calibration_status": "not_calibrated",
        "reliability_status": "not_calibrated",
        "updated_at": spec["last_active"].isoformat(),
        "is_test_data": True,
        "test_cohort_id": COHORT_ID,
        "seed_policy": POLICY,
        "seed_slot": spec["slot"],
        "seed_key": spec["key"],
        "seed_disposable": True,
    }


def refuse_if_real_user(snap: Any, uid: str) -> None:
    if not snap.exists:
        return
    data = snap.to_dict() or {}
    if data.get("is_test_data") is True:
        return
    raise SystemExit(
        f"ERROR: {uid} exists and is not is_test_data. Refusing to overwrite a real user."
    )


def inspect_existing_ten(db: Any) -> None:
    missing: list[str] = []
    bad: list[str] = []
    print("Existing 10 test users (read-only, not rewritten):")
    for uid in EXISTING_UIDS:
        user_snap = db.collection("users").document(uid).get()
        if not user_snap.exists:
            missing.append(uid)
            continue
        data = user_snap.to_dict() or {}
        canon = (
            db.collection("users")
            .document(uid)
            .collection("profiles")
            .document("canonical_v1")
            .get()
            .to_dict()
            or {}
        )
        ncomp = canonical_coverage(canon)
        if data.get("is_test_data") is not True:
            raise SystemExit(
                f"ERROR: existing seed {uid} is not is_test_data. Refusing."
            )
        ok = (
            data.get("discover_eligible") is True
            and data.get("active") is True
            and ncomp == 20
        )
        print(
            f"  keep {uid} eligible={data.get('discover_eligible')} "
            f"canonical={ncomp}/20 name={data.get('name')!r} ok={ok}"
        )
        if not ok:
            bad.append(uid)
    if missing:
        raise SystemExit(
            "ERROR: missing existing test seeds "
            f"{missing}. Run stage_b2 v2 + discover_10_card scripts first."
        )
    if bad:
        raise SystemExit(
            f"ERROR: existing seeds failed eligibility/20D check: {bad}"
        )


def clear_viewer_new_swipes(db: Any, viewer_uid: str) -> int:
    deleted = 0
    for uid in NEW_UIDS:
        ref = (
            db.collection("users")
            .document(viewer_uid)
            .collection("swipes")
            .document(uid)
        )
        snap = ref.get()
        if snap.exists:
            ref.delete()
            deleted += 1
    remaining = 0
    for uid in NEW_UIDS:
        snap = (
            db.collection("users")
            .document(viewer_uid)
            .collection("swipes")
            .document(uid)
            .get()
        )
        if snap.exists:
            remaining += 1
    if remaining:
        raise SystemExit(
            f"ERROR: {remaining} viewer swipe doc(s) toward the 50 extras still exist."
        )
    return deleted


def inspect_uid(db: Any, uid: str, viewer_uid: str) -> dict[str, Any]:
    data = db.collection("users").document(uid).get().to_dict() or {}
    canon = (
        db.collection("users")
        .document(uid)
        .collection("profiles")
        .document("canonical_v1")
        .get()
        .to_dict()
        or {}
    )
    ncomp = canonical_coverage(canon)
    eligible = data.get("discover_eligible") is True
    photo = isinstance(data.get("profile_photo_url"), str) and bool(
        str(data.get("profile_photo_url")).strip()
    )
    swipe_exists = (
        db.collection("users")
        .document(viewer_uid)
        .collection("swipes")
        .document(uid)
        .get()
        .exists
    )
    name = str(data.get("name") or "")
    marked = name.startswith("[TEST]")
    return {
        "uid": uid,
        "eligible": eligible,
        "ncomp": ncomp,
        "photo": photo,
        "is_test_data": data.get("is_test_data") is True,
        "cohort": data.get("test_cohort_id"),
        "swipe": swipe_exists,
        "marked": marked,
        "name": name,
        "ok": eligible and ncomp == 20 and photo and data.get("is_test_data") is True,
    }


def verify_total(db: Any, viewer_uid: str) -> int:
    keep_ok = 0
    new_ok = 0
    print("Post-write confirmation (existing 10):")
    for uid in EXISTING_UIDS:
        row = inspect_uid(db, uid, viewer_uid)
        print(
            f"  keep {uid} eligible={row['eligible']} canonical={row['ncomp']}/20 "
            f"photo={row['photo']} is_test_data={row['is_test_data']} "
            f"marked={row['marked']}"
        )
        if row["ok"]:
            keep_ok += 1
    print("Post-write confirmation (new 50):")
    for uid in NEW_UIDS:
        row = inspect_uid(db, uid, viewer_uid)
        print(
            f"  new  {uid} eligible={row['eligible']} canonical={row['ncomp']}/20 "
            f"photo={row['photo']} is_test_data={row['is_test_data']} "
            f"cohort={row['cohort']} marked={row['marked']} "
            f"viewer_swipe={row['swipe']}"
        )
        if (
            row["ok"]
            and row["marked"]
            and row["cohort"] == COHORT_ID
            and not row["swipe"]
        ):
            new_ok += 1
    total = keep_ok + new_ok
    print(
        f"existing_10_ok={keep_ok}/10 new_50_ok={new_ok}/50 "
        f"exact_total_test_candidate_count={total}"
    )
    if keep_ok != 10 or new_ok != 50:
        raise SystemExit("ERROR: 60-card test cohort verification failed.")
    return total


def prepare(db: Any, viewer_uid: str) -> int:
    if viewer_uid in EXISTING_UIDS or viewer_uid in NEW_UIDS:
        raise SystemExit("ERROR: --viewer-uid must not be a seed uid.")
    viewer_snap = db.collection("users").document(viewer_uid).get()
    if not viewer_snap.exists:
        raise SystemExit(f"ERROR: viewer {viewer_uid} user doc missing.")

    print(f"{POLICY} project={PROJECT_ID} viewer={viewer_uid}")
    inspect_existing_ten(db)

    now = datetime.now(timezone.utc)
    viewer_20d = v2.load_viewer_20d(db, viewer_uid)
    viewer_interests = v2.load_viewer_interests(db, viewer_uid)
    specs = extra_specs(viewer_20d, viewer_interests, now)
    print(f"Disposable seeds to write: {len(specs)}")
    for spec in specs[:3]:
        dist, _cov, ncomp = v2.structural_distance(viewer_20d, spec["scores"])
        print(
            f"  {spec['uid']} {spec['key']} "
            f"L2={None if dist is None else f'{dist:.6f}'} cov={ncomp}/20"
        )
    print(f"  ... {len(specs) - 3} more")

    batch = db.batch()
    for spec in specs:
        uid = spec["uid"]
        user_ref = db.collection("users").document(uid)
        refuse_if_real_user(user_ref.get(), uid)
        user = build_user_doc(spec, viewer_uid)
        v2.assert_l1_eligible(user)
        if "iq_normalized" in user or "eq_normalized" in user:
            raise SystemExit("ERROR: refused to write fabricated IQ/EQ.")
        if "category" in user or "archetype" in user:
            raise SystemExit("ERROR: refused to write fabricated category/archetype.")
        if not str(user.get("name") or "").startswith("[TEST]"):
            raise SystemExit(f"ERROR: {uid} name is not marked [TEST].")
        batch.set(user_ref, user)
        batch.set(
            user_ref.collection("profiles").document("canonical_v1"),
            build_canonical_doc(spec),
        )
        vector = user["frequency_vector"]
        batch.set(
            user_ref.collection("assessments").document("frequency"),
            {
                "completed": True,
                "status": "completed",
                "vector": vector,
                "frequency_vector": vector,
                "type": user["frequency_type"],
                "tags": user["frequency_tags"],
                "score_total": user["frequency_score"],
                "legacy_score_total": user["frequency_score"],
                "canonical_profile_ready": True,
                "missing_dimensions": [],
                "dimension_evidence_counts": {k: 3 for k in v2.LEGACY_FREQ_KEYS},
                "is_test_data": True,
                "test_cohort_id": COHORT_ID,
                "seed_policy": POLICY,
            },
        )
    batch.commit()
    print(
        f"Wrote {len(NEW_UIDS)} disposable users + canonical_v1 "
        f"(existing 10 untouched; viewer {viewer_uid} not written)."
    )

    deleted_swipes = clear_viewer_new_swipes(db, viewer_uid)
    print(
        f"Cleared viewer swipes toward these 50 extras: "
        f"deleted={deleted_swipes} remaining=0"
    )
    return verify_total(db, viewer_uid)


def delete_cohort(db: Any, viewer_uid: str) -> int:
    if viewer_uid in EXISTING_UIDS or viewer_uid in NEW_UIDS:
        raise SystemExit("ERROR: --viewer-uid must not be a seed uid.")
    deleted_users = 0
    for uid in NEW_UIDS:
        user_ref = db.collection("users").document(uid)
        snap = user_ref.get()
        if not snap.exists:
            continue
        data = snap.to_dict() or {}
        if data.get("is_test_data") is not True or data.get("test_cohort_id") != COHORT_ID:
            raise SystemExit(
                f"ERROR: {uid} is not this disposable cohort. Refusing delete."
            )
        if uid in EXISTING_UIDS:
            raise SystemExit(f"ERROR: refused to delete kept seed {uid}.")
        user_ref.collection("profiles").document("canonical_v1").delete()
        user_ref.collection("assessments").document("frequency").delete()
        user_ref.delete()
        swipe_ref = (
            db.collection("users")
            .document(viewer_uid)
            .collection("swipes")
            .document(uid)
        )
        if swipe_ref.get().exists:
            swipe_ref.delete()
        deleted_users += 1
    print(
        f"{POLICY} deleted_users={deleted_users} "
        f"(only {COHORT_ID}; existing 10 untouched)."
    )
    return deleted_users


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Add or delete 50 disposable Discover test users."
    )
    p.add_argument("--viewer-uid", required=True, help="Current Discover viewer uid.")
    p.add_argument("--execute", action="store_true", help="Write the 50 extras.")
    p.add_argument(
        "--delete",
        action="store_true",
        help="Delete only the 50 extras (not the original 10).",
    )
    p.add_argument("--confirm", default="", help="Confirmation phrase.")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    viewer_uid = args.viewer_uid.strip()
    if args.delete and args.execute:
        print("ERROR: use either --execute or --delete, not both.")
        return 2
    if args.delete:
        if args.confirm != DELETE_CONFIRM:
            print(
                f"{POLICY} dry-run delete (no writes).\n"
                f"  would delete only {len(NEW_UIDS)} users: "
                f"{NEW_UIDS[0]}…{NEW_UIDS[-1]}\n"
                f"  would refuse unless is_test_data and test_cohort_id={COHORT_ID}\n"
                f"  would not touch {EXISTING_UIDS[0]}…{EXISTING_UIDS[-1]} or real users\n"
                f"  python3 tool/discover_50_disposable_test_cohort_v1.py "
                f"--viewer-uid {viewer_uid} --delete --confirm {DELETE_CONFIRM}"
            )
            return 0
        count = delete_cohort(init_db(), viewer_uid)
        print(f"deleted_disposable_count={count}")
        return 0
    if not args.execute:
        print(
            f"{POLICY} dry-run (no writes).\n"
            f"  keeps {len(EXISTING_UIDS)} existing test seeds\n"
            f"  would write {len(NEW_UIDS)} extras: {NEW_UIDS[0]}…{NEW_UIDS[-1]}\n"
            f"  test_cohort_id={COHORT_ID} (easy later delete)\n"
            f"  would delete only users/{viewer_uid}/swipes/{{seed_uid}} for the 50 extras\n"
            f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
            f"  python3 tool/discover_50_disposable_test_cohort_v1.py "
            f"--viewer-uid {viewer_uid} --execute --confirm {SEED_CONFIRM}"
        )
        return 0
    if args.confirm != SEED_CONFIRM:
        print(f"{POLICY}\nRefused without --execute --confirm {SEED_CONFIRM}\n")
        return 2
    count = prepare(init_db(), viewer_uid)
    print(f"exact_total_test_candidate_count={count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
