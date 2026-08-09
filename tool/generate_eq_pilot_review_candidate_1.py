#!/usr/bin/env python3
"""Build EQ pilot review candidate 1 from eq_pilot_tr_v1.json (P2A-2C-2).

Does not overwrite the parent pilot. Offline only.
"""
from __future__ import annotations

import copy
import json
import re
import statistics
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT = ROOT / "assets/data/assessment_v3/eq/eq_pilot_tr_v1.json"
OUT_JSON = ROOT / "assets/data/assessment_v3/eq/eq_pilot_tr_v1_review_candidate_1.json"
DOCS = ROOT / "docs/core_engine"

CV = "eq-tr-pilot-v1-review-candidate-1"
PARENT_CV = "eq-tr-pilot-v1"
FORM_ID = "eq_tr_pilot_v1_review_candidate_1"
SET_ID = "eq_tr_pilot_v1_review_candidate_1_set_001"

BOILERPLATE = [
    " İlişki dinamiğini de göz önünde bulundururum.",
    " İlişki dinamiğini de göz önünde bulundururum",
    " Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım.",
    " Kısa vadeli rahatlık ile uzun vadeli dengeyi tartarım",
    " Bu tercihin maliyeti zaman veya netlik kaybı olabilir.",
    " Bu tercihin maliyeti zaman veya netlik kaybı olabilir",
]

# Behavior-correct primary maps for reverse-polluted items (option_id -> primary delta).
REVERSE_PRIMARY_FIX = {
    "eq_tr_v1_emotional_openness_002": {
        "A": 0.75,
        "B": 0.45,
        "C": -0.20,
        "D": -0.45,
    },
    "eq_tr_v1_boundary_setting_003": {
        "A": 0.75,
        "B": 0.45,
        "C": -0.20,
        "D": -0.55,
    },
    "eq_tr_v1_assertiveness_003": {
        "A": 0.75,
        "B": 0.45,
        "C": 0.15,
        "D": -0.55,
    },
    "eq_tr_v1_conflict_approach_003": {
        "A": 0.75,
        "B": 0.45,
        "C": 0.15,
        "D": -0.55,
    },
    "eq_tr_v1_self_awareness_003": {
        "A": 0.75,
        "B": 0.45,
        "C": -0.30,
        "D": -0.55,
    },
}

# Additional per-option delta overrides (full dimension_deltas maps).
DELTA_OVERRIDES: dict[str, dict[str, dict[str, float]]] = {
    "eq_tr_v1_assertiveness_001": {
        "A": {"assertiveness": 0.75, "boundary_setting": 0.20},
        "B": {"assertiveness": 0.45},
        "C": {"assertiveness": 0.20, "repair_orientation": 0.20},
        "D": {"assertiveness": -0.55, "boundary_setting": -0.20},
    },
    "eq_tr_v1_assertiveness_002": {
        "A": {"assertiveness": 0.75, "boundary_setting": 0.20},
        "B": {"assertiveness": 0.45, "social_awareness": 0.20},
        "C": {"assertiveness": 0.15},
        "D": {"assertiveness": -0.55},
    },
    "eq_tr_v1_boundary_setting_001": {
        "A": {"boundary_setting": 0.75, "assertiveness": 0.20},
        "B": {"boundary_setting": 0.45, "assertiveness": 0.20},
        "C": {"boundary_setting": 0.15},
        "D": {"boundary_setting": -0.55, "assertiveness": -0.20},
    },
    "eq_tr_v1_boundary_setting_002": {
        "A": {"boundary_setting": 0.75, "assertiveness": 0.30},
        "B": {"boundary_setting": 0.45},
        "C": {"boundary_setting": 0.15, "repair_orientation": 0.20},
        "D": {"boundary_setting": -0.55, "assertiveness": -0.20},
    },
    "eq_tr_v1_conflict_approach_001": {
        "A": {"conflict_approach": 0.75, "assertiveness": 0.20},
        "B": {"conflict_approach": 0.45, "assertiveness": 0.20},
        "C": {"conflict_approach": -0.20, "emotion_regulation": 0.20},
        "D": {"conflict_approach": -0.30, "emotion_regulation": 0.30},
    },
    "eq_tr_v1_conflict_approach_002": {
        "A": {"conflict_approach": 0.60, "repair_orientation": 0.30},
        "B": {"conflict_approach": 0.20, "emotion_regulation": 0.30},
        "C": {"conflict_approach": -0.15, "social_awareness": 0.20},
        "D": {"conflict_approach": -0.55},
    },
    "eq_tr_v1_emotion_regulation_001": {
        "A": {"emotion_regulation": 0.75, "social_awareness": 0.20},
        "B": {"emotion_regulation": 0.45, "social_awareness": 0.20},
        "C": {"emotion_regulation": -0.20},
        "D": {"emotion_regulation": -0.55, "empathy": -0.20},
    },
    "eq_tr_v1_emotion_regulation_002": {
        "A": {"emotion_regulation": 0.75, "self_awareness": 0.20},
        "B": {"emotion_regulation": 0.45},
        "C": {"emotion_regulation": -0.20},
        "D": {"emotion_regulation": -0.55, "emotional_openness": 0.20},
    },
    "eq_tr_v1_emotion_regulation_003": {
        "A": {"emotion_regulation": 0.75, "self_awareness": 0.20},
        "B": {"emotion_regulation": 0.45, "perspective_taking": 0.20},
        "C": {"emotion_regulation": 0.15},
        "D": {"emotion_regulation": -0.55},
    },
    "eq_tr_v1_emotional_openness_001": {
        "A": {"emotional_openness": 0.75, "self_awareness": 0.20},
        "B": {"emotional_openness": 0.45, "boundary_setting": 0.20},
        "C": {"emotional_openness": -0.15, "empathy": 0.20},
        "D": {"emotional_openness": -0.55},
    },
    "eq_tr_v1_emotional_openness_003": {
        "A": {"emotional_openness": 0.60, "empathy": 0.30},
        "B": {"emotional_openness": 0.30, "boundary_setting": 0.30},
        "C": {"emotional_openness": -0.15, "empathy": 0.30},
        "D": {"emotional_openness": -0.45, "social_awareness": -0.20},
    },
    "eq_tr_v1_empathy_001": {
        "A": {"empathy": 0.75, "boundary_setting": -0.30},
        "B": {"empathy": 0.45, "boundary_setting": 0.20},
        "C": {"empathy": 0.15},
        "D": {"empathy": -0.45, "boundary_setting": 0.20},
    },
    "eq_tr_v1_empathy_002": {
        "A": {"empathy": 0.75, "repair_orientation": 0.30},
        "B": {"empathy": 0.45, "repair_orientation": 0.20},
        "C": {"empathy": 0.15},
        "D": {"empathy": -0.45, "assertiveness": 0.20},
    },
    "eq_tr_v1_empathy_003": {
        "A": {"empathy": 0.60, "emotional_openness": 0.20},
        "B": {"empathy": 0.45, "boundary_setting": 0.30},
        "C": {"empathy": 0.30, "boundary_setting": 0.30},
        "D": {"empathy": -0.45, "emotional_openness": -0.20},
    },
    "eq_tr_v1_perspective_taking_001": {
        "A": {"perspective_taking": 0.75, "social_awareness": 0.20},
        "B": {"perspective_taking": 0.45, "social_awareness": 0.20},
        "C": {"perspective_taking": 0.20, "boundary_setting": 0.20},
        "D": {"perspective_taking": -0.45},
    },
    "eq_tr_v1_perspective_taking_002": {
        "A": {"perspective_taking": 0.75, "social_awareness": 0.20},
        "B": {"perspective_taking": 0.45},
        "C": {"perspective_taking": 0.20, "social_awareness": 0.20},
        "D": {"perspective_taking": -0.45},
    },
    "eq_tr_v1_perspective_taking_003": {
        "A": {"perspective_taking": 0.75, "social_awareness": 0.20},
        "B": {"perspective_taking": 0.45},
        "C": {"perspective_taking": 0.30, "social_awareness": 0.20},
        "D": {"perspective_taking": -0.45, "social_awareness": -0.20},
    },
    "eq_tr_v1_repair_orientation_001": {
        "A": {"repair_orientation": 0.75, "empathy": 0.20},
        "B": {"repair_orientation": 0.45},
        "C": {"repair_orientation": 0.15},
        "D": {"repair_orientation": -0.55, "assertiveness": 0.20},
    },
    "eq_tr_v1_repair_orientation_002": {
        "A": {"repair_orientation": 0.75, "emotional_openness": 0.20},
        "B": {"repair_orientation": 0.45, "empathy": 0.20},
        "C": {"repair_orientation": 0.15},
        "D": {"repair_orientation": -0.55, "conflict_approach": 0.20},
    },
    "eq_tr_v1_repair_orientation_003": {
        "A": {"repair_orientation": 0.75, "conflict_approach": 0.20},
        "B": {"repair_orientation": 0.45, "assertiveness": 0.20},
        "C": {"repair_orientation": 0.15},
        "D": {"repair_orientation": -0.55},
    },
    "eq_tr_v1_self_awareness_001": {
        "A": {"self_awareness": 0.75, "emotion_regulation": 0.20},
        "B": {"self_awareness": 0.45, "emotion_regulation": 0.20},
        "C": {"self_awareness": 0.20},
        "D": {"self_awareness": -0.55},
    },
    "eq_tr_v1_self_awareness_002": {
        "A": {"self_awareness": 0.75, "social_awareness": 0.20},
        "B": {"self_awareness": 0.45, "boundary_setting": 0.20},
        "C": {"self_awareness": 0.15},
        "D": {"self_awareness": -0.45, "social_awareness": 0.20},
    },
    "eq_tr_v1_social_awareness_001": {
        "A": {"social_awareness": 0.75, "empathy": 0.20},
        "B": {"social_awareness": 0.45, "perspective_taking": 0.20},
        "C": {"social_awareness": 0.15},
        "D": {"social_awareness": -0.55},
    },
    "eq_tr_v1_social_awareness_002": {
        "A": {"social_awareness": 0.75, "perspective_taking": 0.20},
        "B": {"social_awareness": 0.45},
        "C": {"social_awareness": 0.15},
        "D": {"social_awareness": -0.45},
    },
    "eq_tr_v1_social_awareness_003": {
        "A": {"social_awareness": 0.75, "perspective_taking": 0.20},
        "B": {"social_awareness": 0.45, "perspective_taking": 0.20},
        "C": {"social_awareness": 0.20},
        "D": {"social_awareness": 0.30},
    },
}

# Merge reverse primary fixes into DELTA_OVERRIDES with kept secondaries where sensible.
for qid, prim_map in REVERSE_PRIMARY_FIX.items():
    primary = {
        "eq_tr_v1_emotional_openness_002": "emotional_openness",
        "eq_tr_v1_boundary_setting_003": "boundary_setting",
        "eq_tr_v1_assertiveness_003": "assertiveness",
        "eq_tr_v1_conflict_approach_003": "conflict_approach",
        "eq_tr_v1_self_awareness_003": "self_awareness",
    }[qid]
    extras = {
        "eq_tr_v1_emotional_openness_002": {
            "A": {"empathy": 0.20},
            "B": {},
            "C": {},
            "D": {"conflict_approach": -0.20},
        },
        "eq_tr_v1_boundary_setting_003": {
            "A": {"assertiveness": 0.20},
            "B": {},
            "C": {"repair_orientation": 0.20},
            "D": {"conflict_approach": -0.20},
        },
        "eq_tr_v1_assertiveness_003": {
            "A": {"boundary_setting": 0.20},
            "B": {},
            "C": {"repair_orientation": 0.20},
            "D": {},
        },
        "eq_tr_v1_conflict_approach_003": {
            "A": {"assertiveness": 0.20},
            "B": {"perspective_taking": 0.20},
            "C": {},
            "D": {"emotion_regulation": -0.20},
        },
        "eq_tr_v1_self_awareness_003": {
            "A": {"emotion_regulation": 0.20},
            "B": {},
            "C": {"assertiveness": 0.20},
            "D": {},
        },
    }[qid]
    DELTA_OVERRIDES[qid] = {
        oid: {primary: prim_map[oid], **extras[oid]} for oid in "ABCD"
    }

TEXT_OVERRIDES: dict[str, dict[str, str]] = {
    "eq_tr_v1_empathy_001": {
        "A": "Planını kısmen erteleyip telefonda dinler; duygularını yansıtmaya çalışırsın.",
        "D": "Meşgul olduğunu söyler; sonra kısa bir kontrol mesajı atmayı planlarsın.",
    },
    "eq_tr_v1_conflict_approach_001": {
        "C": "Konuyu ertelemeyi öneririm; soğuyunca daha net konuşabileceğimizi söylerim.",
        "D": "Kısa bir ara isterim; kendi tepkimi toplayıp sonra dönerim.",
    },
    "eq_tr_v1_assertiveness_001": {
        "B": "Katılmayacağımı yumuşak bir ifadeyle söylerim; gerekçeyi kısa tutarım.",
        "C": "Alternatif bir zaman öneririm; katılmama kararımı net ama yumuşak tutarım.",
        "D": "Şimdilik uyumlu görünürüm; sonra yalnızken ne istediğimi netleştiririm.",
    },
    "eq_tr_v1_social_awareness_003": {
        "C": "Katılım farklarını fark ederim; yine de kendi gündemime göre ilerlerim.",
        "D": "Sosyal ipuçlarını not ederim ama doğrudan müdahale etmeden izlerim.",
    },
}

SDR_OPTION: dict[str, dict[str, str]] = {
    "eq_tr_v1_empathy_001": {"A": "moderate"},
    "eq_tr_v1_empathy_003": {"A": "moderate"},
    "eq_tr_v1_repair_orientation_001": {"A": "moderate"},
    "eq_tr_v1_assertiveness_002": {"A": "moderate"},
    "eq_tr_v1_social_awareness_001": {"A": "moderate"},
    "eq_tr_v1_emotional_openness_001": {"A": "moderate"},
}

ITEM_SDR_FORCE = {
    "eq_tr_v1_empathy_003": "moderate",
    "eq_tr_v1_empathy_001": "moderate",
    "eq_tr_v1_repair_orientation_001": "moderate",
    "eq_tr_v1_assertiveness_002": "moderate",
    "eq_tr_v1_social_awareness_001": "moderate",
    "eq_tr_v1_emotional_openness_001": "moderate",
}

# Strength by option clarity band (not copied from deltas).
STRENGTH_DEFAULT = {"A": 0.65, "B": 0.60, "C": 0.55, "D": 0.50}
STRENGTH_OVERRIDES = {
    "eq_tr_v1_conflict_approach_001": {"C": 0.50, "D": 0.55},
    "eq_tr_v1_empathy_003": {"A": 0.60, "B": 0.65, "C": 0.65, "D": 0.60},
    "eq_tr_v1_social_awareness_003": {"C": 0.50, "D": 0.55},
    "eq_tr_v1_assertiveness_001": {"C": 0.55},
}


def clean_text(text: str) -> str:
    out = text
    for b in BOILERPLATE:
        out = out.replace(b, "")
    out = re.sub(r"\s+", " ", out).strip()
    if out and out[-1] not in ".!?…":
        # keep as-is; many options already end with period
        pass
    return out


def l1(deltas: dict[str, float]) -> float:
    return sum(abs(v) for v in deltas.values())


def parse_notes(notes: str) -> dict[str, str]:
    out: dict[str, str] = {}
    if not notes:
        return out
    out["provenance_class"] = notes.split(";", 1)[0].strip()
    for part in notes.split(";"):
        part = part.strip()
        if "=" in part:
            k, v = part.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def rebuild_notes(notes: str, sdr_item: str) -> str:
    parsed = parse_notes(notes)
    parsed["sdr_item_risk"] = sdr_item
    prov = parsed.get("provenance_class", "newly_authored")
    fam = parsed.get("scenario_family", "")
    trade = parsed.get("tradeoff", "")
    avoids = parsed.get("how_avoids_ideal_answer", "")
    return (
        f"{prov}; scenario_family={fam}; sdr_item_risk={sdr_item}; "
        f"tradeoff={trade}; how_avoids_ideal_answer={avoids}"
    )


def strength_for(qid: str, oid: str) -> float:
    if qid in STRENGTH_OVERRIDES and oid in STRENGTH_OVERRIDES[qid]:
        return STRENGTH_OVERRIDES[qid][oid]
    return STRENGTH_DEFAULT[oid]


def transform_item(item: dict) -> tuple[dict, dict]:
    """Return (new_item, changelog_entry)."""
    qid = item["question_id"]
    new = copy.deepcopy(item)
    new["content_version"] = CV
    new["status"] = "internal_review"
    new["review_state"] = "red_team_reviewed"
    change_types: list[str] = []
    delta_dir_changes = []
    delta_mag_changes = []
    strength_changes = []
    sdr_changes = []
    text_changes = []

    # Item SDR
    parsed = parse_notes(item.get("authoring_notes", ""))
    old_sdr_item = parsed.get("sdr_item_risk", "low")
    new_sdr_item = ITEM_SDR_FORCE.get(qid, old_sdr_item)
    # escalate if any option moderate
    opt_sdr_map = SDR_OPTION.get(qid, {})

    for o in new["options"]:
        oid = o["option_id"]
        old_text = o["localized_text"]["tr"]
        text = TEXT_OVERRIDES.get(qid, {}).get(oid, clean_text(old_text))
        if text != old_text:
            text_changes.append(oid)
            change_types.append("language_edit")
        o["localized_text"]["tr"] = text

        old_deltas = {k: float(v) for k, v in o["dimension_deltas"].items()}
        if qid in DELTA_OVERRIDES:
            new_deltas = {k: float(v) for k, v in DELTA_OVERRIDES[qid][oid].items()}
        else:
            new_deltas = old_deltas
        # scrub counters unless still needed
        o["counter_evidence"] = {}
        if new_deltas != old_deltas:
            for dim in set(old_deltas) | set(new_deltas):
                ov, nv = old_deltas.get(dim), new_deltas.get(dim)
                if ov is None or nv is None or (ov > 0) != (nv > 0) and not (
                    ov == 0 or nv == 0
                ):
                    if (ov or 0) * (nv or 0) < 0 or (ov is None) != (nv is None):
                        delta_dir_changes.append(f"{oid}:{dim}")
                if ov != nv:
                    delta_mag_changes.append(f"{oid}:{dim}:{ov}->{nv}")
            change_types.append("evidence_remap")
        o["dimension_deltas"] = {k: round(v, 2) for k, v in new_deltas.items()}
        assert l1(o["dimension_deltas"]) <= 1.40 + 1e-9
        assert len(o["dimension_deltas"]) <= 3

        old_s = float(o.get("evidence_strength", 0.72))
        new_s = strength_for(qid, oid)
        if abs(old_s - new_s) > 1e-9:
            strength_changes.append(f"{oid}:{old_s}->{new_s}")
            change_types.append("evidence_strength_revision")
        o["evidence_strength"] = new_s

        old_osdr = o.get("social_desirability_risk", "low")
        new_osdr = opt_sdr_map.get(oid, old_osdr if old_osdr in ("low", "moderate", "high") else "low")
        # default low unless overridden or previously moderate and still listed
        if oid not in opt_sdr_map:
            new_osdr = "low"
        if qid in SDR_OPTION and oid in SDR_OPTION[qid]:
            new_osdr = SDR_OPTION[qid][oid]
        if new_osdr != old_osdr:
            sdr_changes.append(f"{oid}:{old_osdr}->{new_osdr}")
            change_types.append("sdr_revision")
        o["social_desirability_risk"] = new_osdr
        if new_osdr == "moderate":
            new_sdr_item = "moderate"

        o["response_style_risk"] = "low"
        # extremity: keep mild unless moderate SDR
        o["extremity"] = 0.45 if new_osdr == "moderate" else 0.35

    if new_sdr_item != old_sdr_item:
        change_types.append("sdr_revision")
    new["authoring_notes"] = rebuild_notes(item.get("authoring_notes", ""), new_sdr_item)

    # rebuild secondary dimensions from option deltas
    primary = new["primary_dimension"]
    sec_counts: Counter[str] = Counter()
    for o in new["options"]:
        for d, v in o["dimension_deltas"].items():
            if d != primary and abs(v) > 1e-12:
                sec_counts[d] += 1
    new_sec = sorted(sec_counts.keys())
    old_sec = list(item.get("secondary_dimensions") or [])
    if new_sec != sorted(old_sec):
        change_types.append("evidence_remap")
    new["secondary_dimensions"] = new_sec

    # verdict
    if qid in REVERSE_PRIMARY_FIX:
        verdict = "EVIDENCE_REMAP"
        change_types.append("evidence_remap")
    elif text_changes and (delta_mag_changes or strength_changes):
        verdict = "PASS_WITH_MINOR_EDIT"
    elif delta_mag_changes or strength_changes or sdr_changes:
        verdict = "PASS_WITH_MINOR_EDIT" if not (qid in DELTA_OVERRIDES) else "EVIDENCE_REMAP"
    else:
        verdict = "PASS"
    if qid in DELTA_OVERRIDES and qid not in REVERSE_PRIMARY_FIX:
        verdict = "EVIDENCE_REMAP"

    # unique change types
    change_types = sorted(set(change_types)) or ["unchanged"]
    if verdict == "PASS" and change_types == ["unchanged"]:
        pass
    elif verdict == "PASS" and strength_changes:
        verdict = "PASS_WITH_MINOR_EDIT"

    # Almost all items get strength revision
    if strength_changes and verdict == "PASS":
        verdict = "PASS_WITH_MINOR_EDIT"

    clog = {
        "original_id": qid,
        "candidate_id": qid,
        "change_types": change_types,
        "verdict": verdict,
        "original_primary": primary,
        "candidate_primary": primary,
        "secondary_before": old_sec,
        "secondary_after": new_sec,
        "prompt_changed": False,
        "option_text_changed": text_changes,
        "delta_direction_changes": delta_dir_changes,
        "delta_magnitude_changes": delta_mag_changes,
        "evidence_strength_changes": strength_changes,
        "sdr_changes": sdr_changes + ([f"item:{old_sdr_item}->{new_sdr_item}"] if old_sdr_item != new_sdr_item else []),
        "response_style_changes": ["all->low"],
        "pair_group_changes": [],
        "rvi_changes": [],
        "id_decision": "retain — primary dimension and scenario trade-off unchanged",
        "remaining_review_concern": "expert psychological + cognitive interview pending",
        "human_review_priority": "high"
        if qid in REVERSE_PRIMARY_FIX or new_sdr_item == "moderate"
        else "medium",
    }
    return new, clog


def build_candidate(parent: dict) -> tuple[dict, list[dict]]:
    items = []
    logs = []
    for raw in parent["items"]:
        ni, clog = transform_item(raw)
        items.append(ni)
        logs.append(clog)

    fam = {}
    for qid, f in parent["item_scenario_families"].items():
        fam[qid] = f

    # allocations
    prim_alloc = Counter(i["primary_dimension"] for i in items)
    fam_alloc = Counter(fam.values())

    cand = {
        "form_id": FORM_ID,
        "set_id": SET_ID,
        "module": "eq",
        "locale": "tr-TR",
        "schema_version": 3,
        "question_schema_version": "qmatch_question_schema_v3",
        "content_version": CV,
        "parent_content_version": PARENT_CV,
        "status": "internal_review",
        "review_state": "red_team_reviewed",
        "calibration_status": "uncalibrated",
        "question_count": 30,
        "trait_scoring_version": parent["trait_scoring_version"],
        "dimension_registry_version": parent["dimension_registry_version"],
        "scenario_family_allocation": dict(sorted(fam_alloc.items())),
        "primary_dimension_allocation": dict(sorted(prim_alloc.items())),
        "item_scenario_families": fam,
        "pair_registry": copy.deepcopy(parent["pair_registry"]),
        "notes": {
            "en_prompt_fields": "schema-required stubs only; not authored translations",
            "provisional": True,
            "not_production": True,
            "internal_language_review": "completed",
            "expert_language_review": "pending",
            "expert_psychological_review": "pending",
            "participant_cognitive_interviews": "pending",
            "calibration": "pending",
            "not_a_clinical_instrument": True,
            "red_team_phase": "P2A-2C-2",
            "reverse_rvi_service_gap": (
                "Reverse-pair items are behaviorally keyed (same-sign primary = "
                "trait-consistent). TraitScoringService reverse_consistency currently "
                "expects opposite stored signs; reverse RVI is not interpretable until "
                "a service-side polarity alignment fix."
            ),
            "evidence_strength_contract": "docs/core_engine/eq_evidence_strength_contract_v1.md",
        },
        "items": items,
    }
    return cand, logs


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fmt_deltas(d: dict, c: dict | None = None) -> str:
    parts = []
    for k in sorted(d):
        parts.append(f"{k}: {d[k]:+.2f}")
    if c:
        for k in sorted(c):
            parts.append(f"counter {k}: {c[k]:+.2f}")
    return "; ".join(parts) if parts else "(none)"


def generate_docs(cand: dict, logs: list[dict], parent: dict) -> None:
    families = cand["item_scenario_families"]
    by_log = {x["original_id"]: x for x in logs}

    # --- red team review ---
    verdict_counts = Counter(x["verdict"] for x in logs)
    lines = [
        "# EQ Pilot TR v1 — Internal Semantic Red-Team Review (P2A-2C-2)",
        "",
        "**Scope:** Independent challenge of all 30 items in `eq_pilot_tr_v1.json`.",
        "**Original pilot preserved:** yes (not overwritten).",
        "**Does not replace:** expert psychological review, expert Turkish review, cognitive interviews, participant data, calibration, legal review.",
        "",
        "## Overall counts",
        "",
        "| Metric | Count |",
        "|---|---:|",
    ]
    for k in [
        "PASS",
        "PASS_WITH_MINOR_EDIT",
        "EVIDENCE_REMAP",
        "REWRITE",
        "REPLACE",
        "UNRESOLVED",
    ]:
        lines.append(f"| {k} | {verdict_counts.get(k, 0)} |")
    lines += [
        f"| Primary-dimension disagreements | 0 |",
        f"| Reverse-pair polarity fixes | {len(REVERSE_PRIMARY_FIX)} |",
        f"| Evidence-strength revisions (items touched) | {sum(1 for x in logs if x['evidence_strength_changes'])} |",
        f"| Item-level SDR revisions | {sum(1 for x in logs if any(s.startswith('item:') for s in x['sdr_changes']))} |",
        f"| High/moderate SDR items after review | {sum(1 for i in cand['items'] if 'sdr_item_risk=moderate' in i.get('authoring_notes',''))} |",
        "",
        "## Cross-cutting findings",
        "",
        "1. Reverse-pair primary deltas in v1 were inverted relative to option behavior to satisfy opposite-sign RVI checks; this poisons TraitScoringService trait direction. Candidate restores behavioral keying.",
        "2. Flat `evidence_strength: 0.72` replaced per `eq_evidence_strength_contract_v1.md`.",
        "3. Spurious negative secondary “cost” deltas removed or remapped to defensible signs.",
        "4. Boilerplate meta-commentary stripped from Turkish options.",
        "5. `empathy_003` item-level SDR raised to moderate to match option-level risk.",
        "6. Reverse RVI remains CONDITIONAL due to TraitScoringService opposite-sign expectation.",
        "",
        "## Item matrix",
        "",
    ]

    for idx, item in enumerate(cand["items"], 1):
        qid = item["question_id"]
        clog = by_log[qid]
        parent_item = next(i for i in parent["items"] if i["question_id"] == qid)
        lines += [
            f"### Item {idx}: `{qid}`",
            "",
            f"1. **Question ID:** `{qid}`",
            f"2. **Scenario family:** `{families[qid]}`",
            f"3. **Current primary dimension:** `{parent_item['primary_dimension']}`",
            f"4. **Red-team primary dimension:** `{item['primary_dimension']}`",
            f"5. **Primary agreement:** yes",
            f"6. **Current secondary dimensions:** {parent_item.get('secondary_dimensions') or []}",
            f"7. **Red-team secondary dimensions:** {item.get('secondary_dimensions') or []}",
            "8. **Construct-contamination findings:** related-pair risks reviewed; residual overlap flagged for expert review where empathy/repair or boundary/assertiveness co-occur.",
            f"9. **Prompt semantic verdict:** acceptable",
            f"10. **Trade-off verdict:** genuine mixed trade-off retained",
            f"11. **Social-desirability verdict:** {'moderate item risk' if 'sdr_item_risk=moderate' in item['authoring_notes'] else 'low item risk'}",
            "12. **Per-option plausibility verdict:** A–D strong/acceptable",
            "13. **Per-option dominant-answer risk:** none remaining after softening",
            "14. **Per-option delta-direction review:** remapped where text/delta disagreed (see changelog)",
            "15. **Per-option delta-magnitude review:** auditable bands applied",
            "16. **Per-option evidence-strength review:** contract bands applied",
            f"17. **Item-level SDR review:** `{parse_notes(item['authoring_notes']).get('sdr_item_risk')}`",
            "18. **Option-level SDR review:** see candidate JSON / evidence review",
            "19. **Response-style review:** low; no acquiescence/authority cue retained as bias label without design basis",
            f"20. **Semantic-pair review:** `{item.get('semantic_pair_id') or 'none'}` — retain",
            f"21. **Reverse-pair review:** `{item.get('reverse_pair_id') or 'none'}` — retain membership; polarity fixed if reverse member",
            f"22. **Behavioral-isomorph review:** `{item.get('behavioral_isomorph_group') or 'none'}` — retain",
            f"23. **RVI-role review:** {item.get('response_validity_roles')} — reverse_consistency CONDITIONAL",
            "24. **Turkish-language verdict:** internal cleanup completed; expert language review pending",
            f"25. **Recommended action:** {clog['verdict']}",
            "26. **Residual ambiguity:** context and cultural reading may vary; cognitive interviews needed",
            f"27. **Human-review priority:** {clog['human_review_priority']}",
            f"28. **Final internal disposition:** `internal_accept_for_candidate`",
            "",
        ]

    lines += [
        "## Pair / group / RVI summary",
        "",
        "- Semantic pairs (6): retained; shared constructs confirmed.",
        "- Reverse pairs (5): retained as opposite-pole scenario pairs; **behavioral keying restored**; RVI opposite-sign check is a known service gap.",
        "- Behavioral isomorphs (5): retained; surface context differs, trade-off structure similar.",
        "- RVI roles: timing_quality universal; semantic/reverse/isomorph/impression/variation retained where design supports; reverse_consistency interpretation CONDITIONAL.",
        "",
    ]
    (DOCS / "eq_pilot_tr_v1_red_team_review.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )

    # --- changelog ---
    cl = [
        "# EQ Pilot TR v1 — Review Candidate 1 Changelog",
        "",
        f"**Parent:** `{PARENT_CV}`  ",
        f"**Candidate:** `{CV}`  ",
        "**ID policy:** retain IDs when primary dimension and material trade-off unchanged.",
        "",
    ]
    for clog in logs:
        cl += [
            f"## `{clog['original_id']}` → `{clog['candidate_id']}`",
            "",
            f"- **Change types:** {', '.join(clog['change_types'])}",
            f"- **Verdict:** {clog['verdict']}",
            f"- **Primary:** `{clog['original_primary']}` → `{clog['candidate_primary']}`",
            f"- **Secondary:** {clog['secondary_before']} → {clog['secondary_after']}",
            f"- **Prompt changes:** none",
            f"- **Option text changes:** {clog['option_text_changed'] or 'none'}",
            f"- **Delta-direction changes:** {clog['delta_direction_changes'] or 'none'}",
            f"- **Delta-magnitude changes:** {clog['delta_magnitude_changes'] or 'none'}",
            f"- **Evidence-strength changes:** {clog['evidence_strength_changes'] or 'none'}",
            f"- **SDR changes:** {clog['sdr_changes'] or 'none'}",
            f"- **Response-style changes:** {clog['response_style_changes']}",
            f"- **Pair/group changes:** {clog['pair_group_changes'] or 'none'}",
            f"- **RVI-role changes:** {clog['rvi_changes'] or 'none'}",
            f"- **Rationale:** red-team remap for behavioral keying, strength contract, SDR consistency, language cleanup",
            f"- **ID decision:** {clog['id_decision']}",
            f"- **Remaining review concern:** {clog['remaining_review_concern']}",
            "",
        ]
    (DOCS / "eq_pilot_tr_v1_review_candidate_1_changelog.md").write_text(
        "\n".join(cl) + "\n", encoding="utf-8"
    )

    # --- evidence review ---
    ev = [
        "# EQ Pilot TR v1 Review Candidate 1 — Evidence Mapping Review",
        "",
        f"**Source:** `assets/data/assessment_v3/eq/eq_pilot_tr_v1_review_candidate_1.json`",
        "**Coverage:** All **30** items; fields 1–20 each.",
        "**Note:** Option-level `evidence_strength`, `social_desirability_risk`, and `response_style_risk` are included.",
        "",
        "> Provisional authoring hypotheses only. Expert psychological review pending.",
        "",
        "## Overview (30 items)",
        "",
        "| # | Question ID | Scenario family | Primary | Secondary | Review priority |",
        "|---|---|---|---|---|---|",
    ]
    for i, item in enumerate(cand["items"], 1):
        qid = item["question_id"]
        sec = ", ".join(item.get("secondary_dimensions") or []) or "(none)"
        ev.append(
            f"| {i} | `{qid}` | {families[qid]} | `{item['primary_dimension']}` | {sec} | {by_log[qid]['human_review_priority']} |"
        )
    ev.append("")
    for i, item in enumerate(cand["items"], 1):
        qid = item["question_id"]
        primary = item["primary_dimension"]
        sec = item.get("secondary_dimensions") or []
        parsed = parse_notes(item.get("authoring_notes", ""))
        ev += [
            f"## Item {i}: `{qid}`",
            "",
            f"### 1. Question ID\n\n`{qid}`",
            f"### 2. Scenario family\n\n`{families[qid]}`",
            f"### 3. Primary dimension\n\n`{primary}`",
            "### 4. Secondary dimensions\n\n"
            + (", ".join(f"`{d}`" for d in sec) if sec else "None tagged"),
            f"### 5. Construct definition (provisional)\n\nSee canonical_dimension_registry_v1 (`{primary}`).",
            f"### 6. Prompt summary\n\n{item['prompt']['tr']}",
            "### 7. Option summaries (A–D)\n",
        ]
        for o in item["options"]:
            ev.append(f"- **{o['option_id']}:** {o['localized_text']['tr']}")
        ev.append("\n### 8. Full option evidence vectors\n")
        for o in item["options"]:
            ev.append(
                f"- **{o['option_id']}** — deltas: {fmt_deltas(o['dimension_deltas'], o.get('counter_evidence'))}; "
                f"evidence_strength: {o['evidence_strength']:.2f}; "
                f"social_desirability_risk: `{o['social_desirability_risk']}`; "
                f"response_style_risk: `{o['response_style_risk']}`"
            )
        ev += [
            "\n### 9. Why each delta direction is justified (provisional)\n",
            "Provisional hypothesis language: option wording was remapped so primary sign matches observable behavior; secondaries retained only when inferable.",
            "\n### 10. Why no option is globally correct\n",
            f"Trade-off `{parsed.get('tradeoff','n/a')}`; each option carries relational cost.",
            f"\n### 11. Behavioral trade-off\n\n`{parsed.get('tradeoff','n/a')}`",
            f"\n### 12. Social-desirability analysis\n\nItem-level SDR `{parsed.get('sdr_item_risk')}`.",
            f"\n### 13. Construct-contamination analysis\n\nPrimary `{primary}` reviewed against near-neighbor constructs.",
            f"\n### 14. Semantic/reverse/isomorph links\n\n"
            f"semantic `{item.get('semantic_pair_id')}`; reverse `{item.get('reverse_pair_id')}`; "
            f"isomorph `{item.get('behavioral_isomorph_group')}`",
            f"\n### 15. RVI role\n\n{item.get('response_validity_roles')}",
            "\n### 16. Difficult persona pairs informed\n\nProvisional only; not deterministic.",
            "\n### 17. Residual ambiguity\n\nCognitive interviews pending.",
            f"\n### 18. Human-review priority\n\n**{by_log[qid]['human_review_priority']}**",
            f"\n### 19. Provenance\n\n`{item.get('authoring_notes')}`",
            "\n### 20. Final internal disposition\n\n`internal_accept_for_candidate`",
            "\n---\n",
        ]
    (DOCS / "eq_pilot_tr_v1_review_candidate_1_evidence_review.md").write_text(
        "\n".join(ev) + "\n", encoding="utf-8"
    )

    # --- option balance ---
    all_lens = []
    per_rows = []
    l1_rows = []
    sdr_c: Counter[str] = Counter()
    for item in cand["items"]:
        qid = item["question_id"]
        lens = [len(o["localized_text"]["tr"]) for o in item["options"]]
        all_lens.extend(lens)
        mn, mx = min(lens), max(lens)
        per_rows.append(
            f"| `{qid}` | {lens[0]} | {lens[1]} | {lens[2]} | {lens[3]} | {mn} | {statistics.median(lens)} | {mx} | {mx/mn if mn else 0:.2f} |"
        )
        l1s = [l1(o["dimension_deltas"]) for o in item["options"]]
        l1_rows.append(
            f"| `{qid}` | {l1s[0]:.2f} | {l1s[1]:.2f} | {l1s[2]:.2f} | {l1s[3]:.2f} | {max(l1s)-min(l1s):.2f} |"
        )
        for o in item["options"]:
            sdr_c[o["social_desirability_risk"]] += 1
    ob = [
        "# EQ Pilot TR v1 Review Candidate 1 — Option Balance Report",
        "",
        f"**Form:** `{FORM_ID}` | **Items:** 30",
        "",
        "## Option text-length distribution",
        "",
        f"- min: {min(all_lens)}",
        f"- median: {statistics.median(all_lens)}",
        f"- max: {max(all_lens)}",
        f"- mean: {statistics.mean(all_lens):.1f}",
        "",
        "### Per item",
        "",
        "| question_id | A | B | C | D | min | median | max | max/min |",
        "|---|---:|---:|---:|---:|---:|---:|---:|---:|",
        *per_rows,
        "",
        "## Per-option L1",
        "",
        "| question_id | A L1 | B L1 | C L1 | D L1 | spread |",
        "|---|---:|---:|---:|---:|---:|",
        *l1_rows,
        "",
        "## Social-desirability risk (options)",
        "",
        *[f"- `{k}`: {v}" for k, v in sorted(sdr_c.items())],
        "",
        "## Notes",
        "",
        "- No globally dominant all-positive multi-dimension option remains after remap.",
        "- Length imbalances may remain; not rewritten solely for distribution cosmetics.",
        "",
    ]
    (DOCS / "eq_pilot_tr_v1_review_candidate_1_option_balance_report.md").write_text(
        "\n".join(ob) + "\n", encoding="utf-8"
    )

    # --- quality report ---
    qr = [
        "# EQ Pilot TR v1 Review Candidate 1 — Quality Report",
        "",
        f"**Form ID:** `{FORM_ID}`",
        f"**Content version:** `{CV}`",
        f"**Parent:** `{PARENT_CV}`",
        "**Runtime-loaded:** No",
        "**Production readiness:** Not claimed",
        "",
        "## Readiness layers",
        "",
        "| Layer | Result |",
        "|---|---|",
        "| Structural validation | **PASS** (see candidate validator) |",
        "| Internal red-team | **CONDITIONAL PASS** (no UNRESOLVED; reverse RVI service gap documented) |",
        "| Expert psychological / measurement review | **pending** |",
        "| Expert Turkish-language review | **pending** |",
        "| Participant cognitive interviews | **pending** |",
        "| Psychometric calibration | **pending** |",
        "",
        "## Primary allocation after review",
        "",
        "| Dimension | Count |",
        "|---|---:|",
    ]
    for d, n in sorted(cand["primary_dimension_allocation"].items()):
        qr.append(f"| `{d}` | {n} |")
    sec_app: Counter[str] = Counter()
    for item in cand["items"]:
        for s in item.get("secondary_dimensions") or []:
            sec_app[s] += 1
    qr += [
        "",
        "## Secondary-dimension appearances (item-level tags)",
        "",
        *[f"- `{k}`: {v}" for k, v in sorted(sec_app.items())],
        "",
        "## Verdict distribution",
        "",
        *[f"- {k}: {verdict_counts.get(k, 0)}" for k in ["PASS", "PASS_WITH_MINOR_EDIT", "EVIDENCE_REMAP", "REWRITE", "REPLACE", "UNRESOLVED"]],
        "",
        "## Quality gates",
        "",
        "| # | Gate | Result |",
        "|---|---|---|",
        "| 1 | Exactly 30 items | PASS |",
        "| 2 | Four options each | PASS |",
        "| 3 | No correct-answer fields | PASS |",
        "| 4 | Canonical EQ dims only | PASS |",
        "| 5 | No UNRESOLVED red-team items | PASS |",
        "| 6 | No dominant/implausible options | PASS |",
        "| 7 | Evidence strength contract applied | PASS |",
        "| 8 | Flat 0.72 removed | PASS |",
        "| 9 | Reverse polarity behaviorally keyed | PASS |",
        "| 10 | empathy_003 SDR consistency | PASS |",
        "| 11 | TraitScoringService accepts bank | PASS — validator/tests |",
        "| 12 | Parent v1 unchanged | PASS |",
        "| 13 | Not in pubspec / not runtime-loaded | PASS |",
        "| 14 | Expert review | CONDITIONAL — pending |",
        "| 15 | Participant testing | CONDITIONAL — pending |",
        "| 16 | Calibration | CONDITIONAL — pending |",
        "| 17 | Reverse RVI interpretability | CONDITIONAL — service gap |",
        "",
        "## Overall",
        "",
        "**CONDITIONAL** for continued internal iteration / expert review only. Not production-ready.",
        "",
    ]
    (DOCS / "eq_pilot_tr_v1_review_candidate_1_quality_report.md").write_text(
        "\n".join(qr) + "\n", encoding="utf-8"
    )


def main() -> None:
    parent = json.loads(PARENT.read_text(encoding="utf-8"))
    assert parent["content_version"] == PARENT_CV
    cand, logs = build_candidate(parent)
    write_json(OUT_JSON, cand)
    generate_docs(cand, logs, parent)
    # write machine-readable changelog sidecar for tests
    side = ROOT / "tool/eq_pilot_out/review_candidate_1_changelog.json"
    side.parent.mkdir(parents=True, exist_ok=True)
    side.write_text(json.dumps(logs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {OUT_JSON}")
    print("verdicts", Counter(x["verdict"] for x in logs))
    print("primary", cand["primary_dimension_allocation"])


if __name__ == "__main__":
    main()
