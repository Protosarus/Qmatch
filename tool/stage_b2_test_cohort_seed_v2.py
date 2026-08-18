#!/usr/bin/env python3
"""Stage B2 v2 viewer-referenced test cohort seeder.

Replaces the 8 `qmatch_stage_b2_seed_01`…`08` users using the viewer's actual
`canonical_v1` 20D. Never invents viewer values. Does not write the viewer
user doc or fabricate viewer IQ/EQ/category/archetype.

Default is dry-run (no Firebase init, no writes).

Seed:
  export QMATCH_FIRESTORE_ADMIN_CREDENTIALS=/absolute/path/OUTSIDE/repo/sa.json
  python3 tool/stage_b2_test_cohort_seed_v2.py \\
    --viewer-uid YOUR_UID --execute --confirm SEED_STAGE_B2_COHORT_V2
"""

from __future__ import annotations

import argparse
import math
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
CREDENTIALS_ENV = "QMATCH_FIRESTORE_ADMIN_CREDENTIALS"
PROJECT_ID = "qmatch-53d62"
POLICY = "stage_b2_test_cohort_seed_v2"
COHORT_ID = "stage_b2_dual_path_v2"
SEED_CONFIRM = "SEED_STAGE_B2_COHORT_V2"

# Deterministic fixed deltas. "Away" = toward the farther end of [0, 1].
FAR_DELTA = 0.40
MED_DELTA = 0.18

LEGACY_FREQ_KEYS = (
    "depth",
    "socialEnergy",
    "spontaneity",
    "stability",
    "emotionalOpenness",
    "conversationPace",
)

UID_PREFIX = "qmatch_stage_b2_seed_"
SEED_UIDS = tuple(f"{UID_PREFIX}{i:02d}" for i in range(1, 9))

IQ_IDS = (
    "logical_reasoning",
    "pattern_reasoning",
    "verbal_reasoning",
    "spatial_reasoning",
)
EQ_IDS = (
    "empathy",
    "perspective_taking",
    "self_awareness",
    "emotion_regulation",
    "emotional_openness",
    "boundary_setting",
    "assertiveness",
    "conflict_approach",
    "repair_orientation",
    "social_awareness",
)
FREQ_CANONICAL = (
    "depth_preference",
    "social_energy",
    "spontaneity",
    "stability",
    "disclosure_pace",
    "communication_pace",
)
FREQ_LEGACY_TO_CANONICAL = {
    "depth": "depth_preference",
    "socialEnergy": "social_energy",
    "spontaneity": "spontaneity",
    "stability": "stability",
    "emotionalOpenness": "disclosure_pace",
    "conversationPace": "communication_pace",
}
ALL_20D = IQ_IDS + EQ_IDS + FREQ_CANONICAL

W_IQ = 0.133333
W_EQ = 0.400000
W_FREQ = 0.466667

DISJOINT_POOL = (
    "chess",
    "pottery",
    "night_running",
    "origami",
    "birdwatching",
    "stamp_collecting",
)


def clamp01(v: float) -> float:
    return max(0.0, min(1.0, v))


def shift_away(value: float, delta: float) -> tuple[float, bool]:
    """Move `delta` toward the farther bound of [0, 1]. Returns (value, clamped)."""
    if value <= 0.5:
        raw = value + delta
        out = clamp01(raw)
    else:
        raw = value - delta
        out = clamp01(raw)
    return out, abs(out - raw) > 1e-12


def shift_ids(
    base: dict[str, float], ids: tuple[str, ...], delta: float
) -> tuple[dict[str, float], int]:
    out = dict(base)
    clamped = 0
    for dim in ids:
        out[dim], hit = shift_away(base[dim], delta)
        if hit:
            clamped += 1
    return out, clamped


def valid_measured(v: Any) -> float | None:
    if v is None or isinstance(v, bool) or not isinstance(v, (int, float)):
        return None
    f = float(v)
    if not math.isfinite(f) or f < 0.0 or f > 1.0:
        return None
    return f


def module_mse(
    ids: tuple[str, ...], a: dict[str, float], b: dict[str, float]
) -> tuple[float | None, int]:
    n = 0
    s = 0.0
    for dim in ids:
        va = valid_measured(a.get(dim))
        vb = valid_measured(b.get(dim))
        if va is None or vb is None:
            continue
        d = va - vb
        s += d * d
        n += 1
    if n == 0:
        return None, 0
    return s / n, n


def structural_distance(
    a: dict[str, float], b: dict[str, float]
) -> tuple[float | None, float, int]:
    iq, niq = module_mse(IQ_IDS, a, b)
    eq, neq = module_mse(EQ_IDS, a, b)
    fr, nfr = module_mse(FREQ_CANONICAL, a, b)
    mods: list[tuple[float, float]] = []
    if iq is not None:
        mods.append((W_IQ, iq))
    if eq is not None:
        mods.append((W_EQ, eq))
    if fr is not None:
        mods.append((W_FREQ, fr))
    ncomp = niq + neq + nfr
    cov = ncomp / 20.0
    if not mods:
        return None, cov, ncomp
    wsum = sum(w for w, _ in mods)
    d2 = sum((w / wsum) * mse for w, mse in mods)
    return math.sqrt(d2), cov, ncomp


def frequency_type_and_tags(legacy: dict[str, float]) -> tuple[str, list[str]]:
    depth = legacy["depth"]
    social_energy = legacy["socialEnergy"]
    spontaneity = legacy["spontaneity"]
    stability = legacy["stability"]
    emotional_openness = legacy["emotionalOpenness"]
    conversation_pace = legacy["conversationPace"]
    if depth >= 0.75 and stability >= 0.65:
        ftype = "Deep Connector"
    elif social_energy >= 0.70 and spontaneity >= 0.60:
        ftype = "Social Spark"
    elif stability >= 0.75 and conversation_pace <= 0.55:
        ftype = "Slow Burner"
    elif emotional_openness >= 0.75 and depth >= 0.60:
        ftype = "Emotional Explorer"
    elif spontaneity >= 0.70 and emotional_openness >= 0.60:
        ftype = "Open Current"
    else:
        ftype = "Balanced Frequency"
    tags: list[str] = []
    if depth >= 0.70:
        tags.append("deep_talker")
    if social_energy >= 0.70:
        tags.append("social_energy")
    if spontaneity >= 0.70:
        tags.append("spontaneous")
    if stability >= 0.70:
        tags.append("stability_first")
    if emotional_openness >= 0.70:
        tags.append("emotionally_open")
    if conversation_pace <= 0.45:
        tags.append("slow_bond")
    if conversation_pace >= 0.70:
        tags.append("fast_connection")
    return ftype, tags


def legacy_freq_from_20d(scores: dict[str, float]) -> dict[str, float]:
    return {
        legacy: scores[canon] for legacy, canon in FREQ_LEGACY_TO_CANONICAL.items()
    }


def measured_dimensions(scores: dict[str, float]) -> list[dict[str, Any]]:
    rows = []
    for dim in ALL_20D:
        if dim in IQ_IDS:
            module = "iq"
            source = "canonical_iq"
            source_version = "iq_to_20d_runtime_adapter_v1"
        elif dim in EQ_IDS:
            module = "eq"
            source = "canonical_eq"
            source_version = "eq_to_20d_runtime_adapter_v1"
        else:
            module = "frequency"
            source = "canonical_frequency"
            source_version = "frequency_to_20d_runtime_adapter_v1"
        rows.append(
            {
                "dimension_id": dim,
                "module": module,
                "measurement_state": "measured",
                "value": scores[dim],
                "source": source,
                "source_version": source_version,
                "calibration_status": "not_calibrated",
                "reliability_status": "not_calibrated",
            }
        )
    return rows


def load_viewer_20d(db: Any, viewer_uid: str) -> dict[str, float]:
    snap = (
        db.collection("users")
        .document(viewer_uid)
        .collection("profiles")
        .document("canonical_v1")
        .get()
    )
    if not snap.exists:
        raise SystemExit(
            f"ERROR: viewer {viewer_uid} has no canonical_v1. Refusing to invent 20D."
        )
    data = snap.to_dict() or {}
    rows = data.get("measured_dimensions")
    if not isinstance(rows, list):
        raise SystemExit("ERROR: viewer canonical_v1 has no measured_dimensions list.")
    out: dict[str, float] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        if row.get("measurement_state") != "measured":
            continue
        dim = row.get("dimension_id")
        value = valid_measured(row.get("value"))
        if dim in ALL_20D and value is not None:
            out[dim] = value
    missing = [dim for dim in ALL_20D if dim not in out]
    if missing:
        raise SystemExit(
            f"ERROR: viewer canonical_v1 missing {len(missing)}/20 measured dims: "
            f"{missing}. Refusing to invent values."
        )
    return out


def load_viewer_interests(db: Any, viewer_uid: str) -> list[str]:
    snap = db.collection("users").document(viewer_uid).get()
    if not snap.exists:
        raise SystemExit(f"ERROR: viewer {viewer_uid} user doc missing.")
    data = snap.to_dict() or {}
    raw = data.get("interests")
    if not isinstance(raw, list):
        return []
    return [str(x) for x in raw if str(x).strip()]


def disjoint_interests(viewer_interests: list[str]) -> list[str]:
    taken = {s.strip().lower() for s in viewer_interests if s.strip()}
    out: list[str] = []
    for label in DISJOINT_POOL:
        if label.lower() not in taken:
            out.append(label)
        if len(out) >= 3:
            break
    if len(out) < 3:
        raise SystemExit("ERROR: could not build 3 disjoint interests without overlap.")
    return out


def designs_for(
    viewer_20d: dict[str, float],
    viewer_interests: list[str],
    now: datetime,
) -> list[dict[str, Any]]:
    clone = dict(viewer_20d)
    iq_far, c_iq = shift_ids(clone, IQ_IDS, FAR_DELTA)
    eq_far, c_eq = shift_ids(clone, EQ_IDS, FAR_DELTA)
    freq_far, c_fr = shift_ids(clone, FREQ_CANONICAL, FAR_DELTA)
    all_far, c_all = shift_ids(clone, ALL_20D, FAR_DELTA)
    medium, c_med = shift_ids(clone, ALL_20D, MED_DELTA)
    clamped = c_iq + c_eq + c_fr + c_all + c_med
    if clamped:
        raise SystemExit(
            f"ERROR: {clamped} dimension(s) hit [0,1] walls at FAR={FAR_DELTA} "
            f"MED={MED_DELTA}. Refusing compressed deltas."
        )

    shared = list(viewer_interests)
    disjoint = disjoint_interests(viewer_interests)
    stale = now - timedelta(days=90)

    specs = [
        {
            "slot": 1,
            "key": "exact_clone_fresh_shared",
            "title": "[TEST] B2-01 Exact structural clone",
            "purpose": "Exact viewer 20D; fresh recency; shared interests.",
            "scores": clone,
            "interests": shared,
            "last_active": now,
            "interest_mode": "shared",
            "recency": "fresh",
            "shift": "none",
        },
        {
            "slot": 2,
            "key": "exact_clone_stale_disjoint",
            "title": "[TEST] B2-02 Clone 20D / stale extras",
            "purpose": "Same 20D as B2-01; 90-day recency; disjoint interests.",
            "scores": dict(clone),
            "interests": disjoint,
            "last_active": stale,
            "interest_mode": "disjoint",
            "recency": "stale_90d",
            "shift": "none",
        },
        {
            "slot": 3,
            "key": "iq_only_far",
            "title": "[TEST] B2-03 IQ-only far",
            "purpose": "IQ dims shifted away by FAR_DELTA; EQ+Frequency exact clone.",
            "scores": iq_far,
            "interests": shared,
            "last_active": now,
            "interest_mode": "shared",
            "recency": "fresh",
            "shift": f"iq_away_{FAR_DELTA}",
        },
        {
            "slot": 4,
            "key": "eq_only_far",
            "title": "[TEST] B2-04 EQ-only far",
            "purpose": "EQ dims shifted away by FAR_DELTA; IQ+Frequency exact clone.",
            "scores": eq_far,
            "interests": shared,
            "last_active": now,
            "interest_mode": "shared",
            "recency": "fresh",
            "shift": f"eq_away_{FAR_DELTA}",
        },
        {
            "slot": 5,
            "key": "frequency_only_far",
            "title": "[TEST] B2-05 Frequency-only far",
            "purpose": "Frequency dims shifted away by FAR_DELTA; IQ+EQ exact clone.",
            "scores": freq_far,
            "interests": shared,
            "last_active": now,
            "interest_mode": "shared",
            "recency": "fresh",
            "shift": f"frequency_away_{FAR_DELTA}",
        },
        {
            "slot": 6,
            "key": "all_20d_far_fresh_shared",
            "title": "[TEST] B2-06 All 20D far / live extras close",
            "purpose": "All 20D shifted away by FAR_DELTA; fresh recency; shared interests.",
            "scores": all_far,
            "interests": shared,
            "last_active": now,
            "interest_mode": "shared",
            "recency": "fresh",
            "shift": f"all_away_{FAR_DELTA}",
        },
        {
            "slot": 7,
            "key": "all_20d_far_stale_disjoint",
            "title": "[TEST] B2-07 All 20D far / stale extras",
            "purpose": "Same 20D as B2-06; 90-day recency; disjoint interests.",
            "scores": dict(all_far),
            "interests": disjoint,
            "last_active": stale,
            "interest_mode": "disjoint",
            "recency": "stale_90d",
            "shift": f"all_away_{FAR_DELTA}",
        },
        {
            "slot": 8,
            "key": "medium_all_20d",
            "title": "[TEST] B2-08 Medium 20D perturbation",
            "purpose": "All 20D shifted away by MED_DELTA; fresh recency; shared interests.",
            "scores": medium,
            "interests": shared,
            "last_active": now,
            "interest_mode": "shared",
            "recency": "fresh",
            "shift": f"all_away_{MED_DELTA}",
        },
    ]
    for spec in specs:
        dist, cov, ncomp = structural_distance(viewer_20d, spec["scores"])
        spec["expected_l2"] = dist
        spec["coverage"] = cov
        spec["comparable"] = ncomp
    return specs


def build_user_doc(spec: dict[str, Any], viewer_uid: str) -> dict[str, Any]:
    scores: dict[str, float] = spec["scores"]
    legacy_freq = legacy_freq_from_20d(scores)
    ftype, tags = frequency_type_and_tags(legacy_freq)
    slot = spec["slot"]
    uid = SEED_UIDS[slot - 1]
    photo = f"https://example.com/qmatch-stage-b2-seed/{uid}.jpg"
    # Deliberately omit iq_normalized, eq_normalized, category, archetype.
    # Viewer lacks those signals; do not fabricate them on seeds either.
    return {
        "uid": uid,
        "name": spec["title"],
        "bio": (
            f"TEST DATA {COHORT_ID} slot={slot} key={spec['key']}. "
            "Disposable Stage B2 v2 seed. Not a real person."
        ),
        "age": 24 + slot,
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
        "seed_slot": slot,
        "seed_key": spec["key"],
        "seed_shift": spec["shift"],
        "seed_interest_mode": spec["interest_mode"],
        "seed_recency": spec["recency"],
        "seed_far_delta": FAR_DELTA,
        "seed_med_delta": MED_DELTA,
    }


def build_canonical_doc(spec: dict[str, Any], uid: str) -> dict[str, Any]:
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
        "measured_dimensions": measured_dimensions(scores),
        "missing_dimension_ids": [],
        "missing_groups": [],
        "source_assessment_type": "frequency",
        "source_scoring_policy_version": "frequency_6d_uncalibrated_signed_evidence_v1",
        "source_bank_version": POLICY,
        "source_bank_locale": "en",
        "source_session_id": f"{uid}_synthetic_v2",
        "calibration_status": "not_calibrated",
        "reliability_status": "not_calibrated",
        "updated_at": spec["last_active"].isoformat(),
        "is_test_data": True,
        "test_cohort_id": COHORT_ID,
        "seed_policy": POLICY,
        "seed_slot": spec["slot"],
        "seed_key": spec["key"],
        "seed_shift": spec["shift"],
        "seed_far_delta": FAR_DELTA,
        "seed_med_delta": MED_DELTA,
    }


def build_legacy_assessment_doc(user: dict[str, Any]) -> dict[str, Any]:
    vector = user["frequency_vector"]
    return {
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
        "dimension_evidence_counts": {k: 3 for k in LEGACY_FREQ_KEYS},
        "is_test_data": True,
        "test_cohort_id": COHORT_ID,
        "seed_policy": POLICY,
    }


def assert_l1_eligible(user: dict[str, Any]) -> None:
    if user.get("account_deletion_requested") is True:
        raise RuntimeError("seed would fail L1: account_deletion_requested")
    if user.get("active") is not True:
        raise RuntimeError("seed would fail L1: active")
    if user.get("profile_completed") is not True:
        raise RuntimeError("seed would fail L1: profile_completed")
    if not (
        user.get("test_completed") is True
        or user.get("assessment_flow_completed") is True
    ):
        raise RuntimeError("seed would fail L1: assessments")
    url = user.get("profile_photo_url")
    if not (isinstance(url, str) and url.strip()):
        raise RuntimeError("seed would fail L1: photo")
    if user.get("discover_eligible") is not True:
        raise RuntimeError("seed would fail L1: discover_eligible")


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


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Seed Stage B2 v2 viewer-referenced cohort.")
    p.add_argument("--viewer-uid", required=True, help="Viewer uid (read-only).")
    p.add_argument("--execute", action="store_true", help="Write the 8 seed users.")
    p.add_argument("--confirm", default="", help="Confirmation phrase.")
    return p.parse_args()


def print_plan(specs: list[dict[str, Any]], viewer_uid: str) -> None:
    print(f"{POLICY} project={PROJECT_ID} cohort={COHORT_ID} viewer={viewer_uid}")
    print(f"FAR_DELTA={FAR_DELTA} MED_DELTA={MED_DELTA} clamp=[0,1] direction=away")
    for spec in specs:
        uid = SEED_UIDS[spec["slot"] - 1]
        d = spec["expected_l2"]
        print(
            f"  {uid} {spec['key']} L2={None if d is None else f'{d:.6f}'} "
            f"cov={spec['comparable']}/20 recency={spec['recency']} "
            f"interests={spec['interest_mode']}"
        )
        print(f"    {spec['purpose']}")


def expected_l2_ranks(specs: list[dict[str, Any]]) -> list[tuple[int, str, float]]:
    rows = []
    for spec in specs:
        d = spec["expected_l2"]
        if d is None:
            raise SystemExit(f"ERROR: seed {spec['slot']} has no L2 distance.")
        rows.append((spec["slot"], spec["key"], d))
    rows.sort(key=lambda r: (r[2], r[0]))
    return rows


def clear_viewer_seed_swipes(db: Any, viewer_uid: str) -> int:
    deleted = 0
    for uid in SEED_UIDS:
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
    for uid in SEED_UIDS:
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
            f"ERROR: {remaining} viewer swipe doc(s) toward seeds still exist."
        )
    return deleted


def scores_from_canonical(data: dict[str, Any]) -> dict[str, float]:
    out: dict[str, float] = {}
    for row in data.get("measured_dimensions") or []:
        if not isinstance(row, dict):
            continue
        if row.get("measurement_state") != "measured":
            continue
        dim = row.get("dimension_id")
        value = valid_measured(row.get("value"))
        if dim in ALL_20D and value is not None:
            out[dim] = value
    return out


def seed(db: Any, viewer_uid: str) -> None:
    if viewer_uid in SEED_UIDS:
        raise SystemExit("ERROR: --viewer-uid must not be a seed uid.")
    now = datetime.now(timezone.utc)
    viewer_20d = load_viewer_20d(db, viewer_uid)
    viewer_interests = load_viewer_interests(db, viewer_uid)
    specs = designs_for(viewer_20d, viewer_interests, now)
    print_plan(specs, viewer_uid)
    print("Expected L2 order (closer first; slot tiebreak):")
    for i, (slot, key, dist) in enumerate(expected_l2_ranks(specs), 1):
        print(f"  {i}. B2-{slot:02d} {key} d={dist:.6f}")

    batch = db.batch()
    for spec in specs:
        uid = SEED_UIDS[spec["slot"] - 1]
        user = build_user_doc(spec, viewer_uid)
        assert_l1_eligible(user)
        if "iq_normalized" in user or "eq_normalized" in user:
            raise SystemExit("ERROR: refused to write fabricated IQ/EQ on seeds.")
        if "category" in user or "archetype" in user:
            raise SystemExit("ERROR: refused to write fabricated category/archetype.")
        canonical = build_canonical_doc(spec, uid)
        user_ref = db.collection("users").document(uid)
        canon_ref = user_ref.collection("profiles").document("canonical_v1")
        batch.set(user_ref, user)
        batch.set(canon_ref, canonical)
        batch.set(
            user_ref.collection("assessments").document("frequency"),
            build_legacy_assessment_doc(user),
        )
    batch.commit()
    print(f"Wrote {len(SEED_UIDS)} users + canonical_v1 (viewer {viewer_uid} not written).")

    deleted_swipes = clear_viewer_seed_swipes(db, viewer_uid)
    print(f"Cleared viewer swipes toward these 8 seeds: deleted={deleted_swipes} remaining=0")

    print("Post-write confirmation:")
    all_ok = True
    for spec in specs:
        uid = SEED_UIDS[spec["slot"] - 1]
        user_snap = db.collection("users").document(uid).get()
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
        got = scores_from_canonical(canon)
        dist, cov, ncomp = structural_distance(viewer_20d, got)
        freq = data.get("frequency_vector") or {}
        freq_ok = isinstance(freq, dict) and all(
            k in freq and valid_measured(freq.get(k)) is not None
            for k in LEGACY_FREQ_KEYS
        )
        eligible = data.get("discover_eligible") is True
        active = data.get("active") is True
        photo = isinstance(data.get("profile_photo_url"), str) and bool(
            str(data.get("profile_photo_url")).strip()
        )
        no_fabricated = all(
            k not in data
            for k in ("iq_normalized", "eq_normalized", "category", "archetype")
        )
        ok = (
            eligible
            and active
            and photo
            and data.get("is_test_data") is True
            and data.get("test_cohort_id") == COHORT_ID
            and ncomp == 20
            and freq_ok
            and no_fabricated
            and dist is not None
        )
        all_ok = all_ok and ok
        print(
            f"  {uid} eligible={eligible} active={active} photo={photo} "
            f"canonical={ncomp}/20 L2={None if dist is None else f'{dist:.6f}'} "
            f"freq6={freq_ok} no_iq_eq_cat_arch={no_fabricated} ok={ok}"
        )
    if not all_ok:
        raise SystemExit("ERROR: one or more seeds failed v2 confirmation.")


def main() -> int:
    args = parse_args()
    viewer_uid = args.viewer_uid.strip()
    if not args.execute:
        print(
            f"{POLICY} dry-run (no writes). FAR_DELTA={FAR_DELTA} MED_DELTA={MED_DELTA}\n"
            f"  export {CREDENTIALS_ENV}=/absolute/path/OUTSIDE/repo/sa.json\n"
            "  python3 tool/stage_b2_test_cohort_seed_v2.py "
            f"--viewer-uid {viewer_uid} --execute --confirm {SEED_CONFIRM}"
        )
        return 0
    if args.confirm != SEED_CONFIRM:
        print(f"{POLICY}\nSeed refused without --execute --confirm {SEED_CONFIRM}\n")
        return 2
    seed(init_db(), viewer_uid)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
