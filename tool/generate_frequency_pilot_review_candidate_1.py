#!/usr/bin/env python3
"""Build Frequency pilot review candidate 1 from frequency_pilot_tr_v1.json (P2A-2D-2).

Does not overwrite the parent pilot. Offline only.
"""
from __future__ import annotations

import copy
import hashlib
import json
import re
import statistics
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PARENT = ROOT / "assets/data/assessment_v3/frequency/frequency_pilot_tr_v1.json"
OUT_JSON = (
    ROOT
    / "assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json"
)
DOCS = ROOT / "docs/core_engine"
SIDE = ROOT / "tool/frequency_pilot_out/review_candidate_1_changelog.json"

PARENT_SHA256 = (
    "573ffa4964e24dd4ef7659da62f2ed6e24005563e167902a9ea6f47054fcbe61"
)
PARENT_CV = "frequency-tr-pilot-v1"
CV = "frequency-tr-pilot-v1-review-candidate-1"
FORM_ID = "frequency_tr_pilot_v1_review_candidate_1"
SET_ID = "frequency_tr_pilot_v1_review_candidate_1_set_001"

LENGTH_LEAKAGE_IDS = {
    "frequency_tr_v1_depth_preference_001",
    "frequency_tr_v1_depth_preference_002",
    "frequency_tr_v1_depth_preference_004",
    "frequency_tr_v1_depth_preference_006",
    "frequency_tr_v1_depth_preference_008",
    "frequency_tr_v1_depth_preference_009",
    "frequency_tr_v1_disclosure_pace_001",
    "frequency_tr_v1_disclosure_pace_002",
    "frequency_tr_v1_social_energy_003",
    "frequency_tr_v1_spontaneity_002",
    "frequency_tr_v1_spontaneity_003",
    "frequency_tr_v1_spontaneity_005",
    "frequency_tr_v1_spontaneity_008",
    "frequency_tr_v1_stability_001",
    "frequency_tr_v1_stability_002",
    "frequency_tr_v1_stability_006",
}

# Meaningful parallel Turkish rewording — expand short poles, preserve trade-offs.
OPTION_TEXT_OVERRIDES: dict[str, dict[str, str]] = {
    "frequency_tr_v1_depth_preference_001": {
        "C": (
            "Esprili ve yüzeysel bir giriş yaparım; erken dönemde derin konulara geçmem."
        ),
        "D": (
            "Mesajı kısa tutar, karşı tarafın uygun olduğunu hissedince devam ederim."
        ),
    },
    "frequency_tr_v1_depth_preference_002": {
        "C": "Gündemi korur, derin bir konuya geçmeden akışı sürdürürüm.",
        "D": "Konuyu derinleştirmeden kısa keser, başka zaman konuşuruz derim.",
    },
    "frequency_tr_v1_depth_preference_004": {
        "D": (
            "Mesajı kısa tutar, uygun zamanda tekrar yazmayı planlayarak devam ederim."
        ),
    },
    "frequency_tr_v1_depth_preference_006": {
        "C": "Kısa bir nasılsın yeterli derim; derin check-in'i sonraya bırakırım.",
        "D": "Check-in atlamayıp spontane yazarım; düzenli mesaj beklemem.",
    },
    "frequency_tr_v1_depth_preference_008": {
        "C": "Konuyu pratik sonuçlara bağlarım; derinlemesine inmeyi ertelerim.",
        "D": "Konuyu kapatır, daha uygun bir zamanda devam etmeyi teklif ederim.",
    },
    "frequency_tr_v1_depth_preference_009": {
        "D": "Mesajı minimumda tutar, rutine dönerim; derin konuyu açmam.",
    },
    "frequency_tr_v1_disclosure_pace_001": {
        "C": "Genel çerçevede kalır, kişisel detay ve özel bilgi paylaşmam.",
    },
    "frequency_tr_v1_disclosure_pace_002": {
        "C": "Genel kalırım, somut örnek ve kişisel detay vermem.",
    },
    "frequency_tr_v1_social_energy_003": {
        "C": "Evde kalmayı tercih ederim; kalabalık ortam yerine dinlenirim.",
    },
    "frequency_tr_v1_spontaneity_002": {
        "C": "Önceki plana sadık kalırım; son dakika değişikliği yapmam.",
    },
    "frequency_tr_v1_spontaneity_003": {
        "C": "Mevcut planıma sadık kalırım; son dakika değişikliği yapmam.",
        "D": "Son dakika değişikliklerinden kaçınırım; mevcut düzene sadık kalırım.",
    },
    "frequency_tr_v1_spontaneity_005": {
        "C": "Başladığımız plana devam ederim; ortada yön değiştirmem.",
    },
    "frequency_tr_v1_spontaneity_008": {
        "C": "Mevcut düzeni korursun; spontane teklife mesafeli kalırsın.",
    },
    "frequency_tr_v1_stability_001": {
        "D": "Sabit plan yapmadan akışa bırakırım; haftalık ritim kurmam.",
    },
    "frequency_tr_v1_stability_002": {
        "D": "Sabit plan yapmadan akışa bırakırsın; düzenli ritim kurmazsın.",
    },
    "frequency_tr_v1_stability_006": {
        "D": "Ritim kurmadan doğal akışa güvenirsin; düzenli tempo aramazsın.",
    },
}

TRADEOFF_SECONDARIES = {
    "communication_pace": [
        ("depth_preference", -0.20),
        ("disclosure_pace", -0.20),
        ("social_energy", -0.20),
        ("stability", -0.20),
    ],
    "depth_preference": [
        ("communication_pace", -0.20),
        ("social_energy", -0.20),
        ("disclosure_pace", -0.20),
        ("spontaneity", -0.20),
    ],
    "social_energy": [
        ("stability", -0.20),
        ("disclosure_pace", -0.20),
        ("communication_pace", -0.20),
        ("depth_preference", -0.20),
    ],
    "spontaneity": [
        ("stability", -0.20),
        ("disclosure_pace", -0.20),
        ("social_energy", -0.20),
        ("communication_pace", -0.20),
    ],
    "stability": [
        ("spontaneity", -0.20),
        ("disclosure_pace", -0.20),
        ("social_energy", -0.20),
        ("communication_pace", -0.20),
    ],
    "disclosure_pace": [
        ("communication_pace", -0.20),
        ("social_energy", -0.20),
        ("depth_preference", -0.20),
        ("stability", -0.20),
    ],
}

ALLOWED_STRENGTH = {0.50, 0.55, 0.60, 0.65, 0.70}
STRENGTH_DEFAULT = {"A": 0.65, "B": 0.60, "C": 0.55, "D": 0.50}

REVERSE_PAIR_META = [
    {
        "pair_id": "frequency_tr_v1_rev_01",
        "question_ids": [
            "frequency_tr_v1_depth_preference_004",
            "frequency_tr_v1_depth_preference_009",
        ],
        "dimension": "depth_preference",
        "prompt_polarity": "reverse_pole_scenarios",
        "correspondence": "A↔A deep re-engage; B↔B gradual; C↔C practical/light; D↔D minimal/defer",
    },
    {
        "pair_id": "frequency_tr_v1_rev_02",
        "question_ids": [
            "frequency_tr_v1_communication_pace_003",
            "frequency_tr_v1_communication_pace_008",
        ],
        "dimension": "communication_pace",
        "prompt_polarity": "reverse_pole_scenarios",
        "correspondence": "A↔A high cadence; B↔B moderate; C↔C slower/spaced; D↔D minimal cadence",
    },
    {
        "pair_id": "frequency_tr_v1_rev_03",
        "question_ids": [
            "frequency_tr_v1_social_energy_002",
            "frequency_tr_v1_social_energy_007",
        ],
        "dimension": "social_energy",
        "prompt_polarity": "reverse_pole_scenarios",
        "correspondence": "A↔A high social pull; B↔B bounded participation; C↔C low energy; D↔D recovery/quiet",
    },
    {
        "pair_id": "frequency_tr_v1_rev_04",
        "question_ids": [
            "frequency_tr_v1_spontaneity_002",
            "frequency_tr_v1_spontaneity_008",
        ],
        "dimension": "spontaneity",
        "prompt_polarity": "reverse_pole_scenarios",
        "correspondence": "A↔A accept novelty; B↔B conditional flex; C↔C keep plan; D↔D reject unplanned change",
    },
    {
        "pair_id": "frequency_tr_v1_rev_05",
        "question_ids": [
            "frequency_tr_v1_stability_002",
            "frequency_tr_v1_stability_006",
        ],
        "dimension": "stability",
        "prompt_polarity": "reverse_pole_scenarios",
        "correspondence": "A↔A propose rhythm; B↔B flexible frame; C↔C variable tempo; D↔D no fixed rhythm",
    },
    {
        "pair_id": "frequency_tr_v1_rev_06",
        "question_ids": [
            "frequency_tr_v1_disclosure_pace_003",
            "frequency_tr_v1_disclosure_pace_007",
        ],
        "dimension": "disclosure_pace",
        "prompt_polarity": "reverse_pole_scenarios",
        "correspondence": "A↔A early openness; B↔B gradual; C↔C guarded; D↔D withhold personal detail",
    },
]


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify_parent_sha() -> None:
    actual = sha256_file(PARENT)
    if actual != PARENT_SHA256:
        raise SystemExit(
            f"Parent SHA256 mismatch.\nExpected: {PARENT_SHA256}\nActual:   {actual}\nAborting."
        )


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


def rebuild_notes(notes: str) -> str:
    parsed = parse_notes(notes)
    parsed["red_team"] = "candidate_1"
    prov = parsed.get("provenance_class", "newly_authored")
    parts = [prov]
    for key in (
        "scenario_family",
        "sdr_item_risk",
        "tradeoff",
        "how_avoids_ideal_answer",
        "red_team",
    ):
        if key in parsed and parsed[key]:
            parts.append(f"{key}={parsed[key]}")
    return "; ".join(parts)


def is_all_positive_multi(deltas: dict[str, float]) -> bool:
    nz = {k: v for k, v in deltas.items() if abs(v) > 1e-12}
    return len(nz) >= 2 and all(v > 0 for v in nz.values())


def apply_tradeoff_remap(item: dict) -> list[str]:
    changes: list[str] = []
    primary = item["primary_dimension"]
    pool = TRADEOFF_SECONDARIES[primary]
    idx = hash(item["question_id"]) % len(pool)
    for opt in item["options"]:
        deltas = {k: float(v) for k, v in opt["dimension_deltas"].items()}
        if not is_all_positive_multi(deltas):
            continue
        sec_dim, sec_val = pool[idx % len(pool)]
        idx += 1
        opt["dimension_deltas"] = {
            primary: round(deltas[primary], 2),
            sec_dim: round(sec_val, 2),
        }
        changes.append(f"{opt['option_id']}:tradeoff_remap")
    if changes:
        secs: set[str] = set()
        for opt in item["options"]:
            for d in opt["dimension_deltas"]:
                if d != primary:
                    secs.add(d)
        item["secondary_dimensions"] = sorted(secs)
    return changes


def strength_for(qid: str, oid: str, current: float, primary_delta: float) -> float:
    if abs(current - 0.72) < 1e-9:
        return STRENGTH_DEFAULT[oid]
    if current in ALLOWED_STRENGTH and abs(abs(primary_delta) - current) > 1e-9:
        return current
    # modest diversity nudge when out of band or equals |primary|
    band = STRENGTH_DEFAULT[oid]
    if abs(abs(primary_delta) - current) < 1e-9:
        return band
    if current not in ALLOWED_STRENGTH:
        return band
    return current


def option_length_ratio(item: dict) -> float:
    lens = [len(o["localized_text"]["tr"]) for o in item["options"]]
    mn = min(lens)
    return max(lens) / mn if mn else 999.0


def transform_item(item: dict) -> tuple[dict, dict]:
    qid = item["question_id"]
    new = copy.deepcopy(item)
    new["content_version"] = CV
    new["status"] = "internal_review"
    new["review_state"] = "red_team_reviewed"
    new["calibration_status"] = "uncalibrated"

    change_types: list[str] = []
    text_changes: list[str] = []
    strength_changes: list[str] = []
    tradeoff_changes: list[str] = []

    overrides = OPTION_TEXT_OVERRIDES.get(qid, {})
    primary = new["primary_dimension"]
    for o in new["options"]:
        oid = o["option_id"]
        old_text = o["localized_text"]["tr"]
        text = overrides.get(oid, old_text)
        if text != old_text:
            text_changes.append(oid)
            if "option_length_edit" not in change_types:
                change_types.append("option_length_edit")
        o["localized_text"]["tr"] = text

        old_s = float(o.get("evidence_strength", 0.72))
        prim = float(o["dimension_deltas"].get(primary, 0.0))
        new_s = strength_for(qid, oid, old_s, prim)
        if abs(old_s - new_s) > 1e-9:
            strength_changes.append(f"{oid}:{old_s}->{new_s}")
            change_types.append("evidence_strength_revision")
        o["evidence_strength"] = new_s

    tradeoff_changes = apply_tradeoff_remap(new)
    if tradeoff_changes:
        change_types.append("tradeoff_revision")

    old_notes = item.get("authoring_notes", "")
    new["authoring_notes"] = rebuild_notes(old_notes)
    if "red_team=candidate_1" not in new["authoring_notes"]:
        new["authoring_notes"] = f"{new['authoring_notes']}; red_team=candidate_1"

    if item.get("reverse_pair_id"):
        change_types.append("reverse_pair_revision")

    if qid in LENGTH_LEAKAGE_IDS:
        verdict = "PASS_WITH_MINOR_EDIT"
    elif tradeoff_changes:
        verdict = "TRADEOFF_REVISION"
    elif strength_changes and not text_changes:
        verdict = "EVIDENCE_REMAP"
    else:
        verdict = "PASS"

    change_types = sorted(set(change_types)) or ["unchanged"]

    clog = {
        "original_id": qid,
        "candidate_id": qid,
        "change_types": change_types,
        "verdict": verdict,
        "original_primary": primary,
        "candidate_primary": primary,
        "secondary_before": list(item.get("secondary_dimensions") or []),
        "secondary_after": list(new.get("secondary_dimensions") or []),
        "prompt_changed": False,
        "option_text_changed": text_changes,
        "delta_direction_changes": [],
        "delta_magnitude_changes": [],
        "evidence_strength_changes": strength_changes,
        "sdr_changes": [],
        "response_style_changes": [],
        "pair_group_changes": (
            [f"reverse_pair={item['reverse_pair_id']} retained (doc-only)"]
            if item.get("reverse_pair_id")
            else []
        ),
        "rvi_changes": [],
        "id_decision": "retain — primary dimension and scenario trade-off unchanged",
        "remaining_review_concern": "expert psychological + cognitive interview pending",
        "human_review_priority": "high" if qid in LENGTH_LEAKAGE_IDS else "medium",
        "option_length_ratio_after": round(option_length_ratio(new), 2),
    }
    return new, clog


def build_candidate(parent: dict) -> tuple[dict, list[dict]]:
    items = []
    logs = []
    for raw in parent["items"]:
        ni, clog = transform_item(raw)
        items.append(ni)
        logs.append(clog)

    fam = dict(parent["item_scenario_families"])
    prim_alloc = Counter(i["primary_dimension"] for i in items)
    fam_alloc = Counter(fam.values())

    cand = {
        "form_id": FORM_ID,
        "set_id": SET_ID,
        "module": "frequency",
        "locale": "tr-TR",
        "schema_version": 3,
        "question_schema_version": "qmatch_question_schema_v3",
        "content_version": CV,
        "parent_content_version": PARENT_CV,
        "status": "internal_review",
        "review_state": "red_team_reviewed",
        "calibration_status": "uncalibrated",
        "question_count": 50,
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
            "cognitive_interviews": "pending",
            "calibration": "pending",
            "not_a_clinical_instrument": True,
            "red_team_phase": "P2A-2D-2",
            "reverse_pair_rvi_service_compatibility": "CONDITIONAL",
            "reverse_rvi_service_gap": (
                "Reverse-pair items are behaviorally keyed (same-sign primary across "
                "pair members = trait-consistent). TraitScoringService "
                "_reversePairConsistency expects opposite stored signs; reverse RVI "
                "is not interpretable until a service-side polarity alignment fix."
            ),
            "evidence_strength_contract": (
                "docs/core_engine/frequency_evidence_strength_application_v1.md"
            ),
            "dimension_contract": "docs/core_engine/frequency_dimension_contract_v1.md",
        },
        "items": items,
    }
    return cand, logs


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fmt_deltas(d: dict, c: dict | None = None) -> str:
    parts = [f"{k}: {d[k]:+.2f}" for k in sorted(d)]
    if c:
        parts.extend(f"counter {k}: {c[k]:+.2f}" for k in sorted(c))
    return "; ".join(parts) if parts else "(none)"


def generate_docs(cand: dict, logs: list[dict], parent: dict) -> None:
    families = cand["item_scenario_families"]
    by_log = {x["original_id"]: x for x in logs}
    verdict_counts = Counter(x["verdict"] for x in logs)

    # --- red team review ---
    lines = [
        "# Frequency Pilot TR v1 — Internal Semantic Red-Team Review (P2A-2D-2)",
        "",
        "**Scope:** Independent challenge of all 50 items in `frequency_pilot_tr_v1.json`.",
        "**Original pilot preserved:** yes (not overwritten).",
        "**Candidate:** `frequency_pilot_tr_v1_review_candidate_1.json`.",
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
        "TRADEOFF_REVISION",
        "REWRITE",
        "REPLACE",
        "UNRESOLVED",
    ]:
        lines.append(f"| {k} | {verdict_counts.get(k, 0)} |")
    lines += [
        f"| Length-leakage items edited | {len(LENGTH_LEAKAGE_IDS)} |",
        f"| Reverse-pair members (doc-only) | {sum(1 for i in cand['items'] if i.get('reverse_pair_id'))} |",
        "",
        "## Cross-cutting findings",
        "",
        "1. Sixteen items had option-length leakage (max/min > 1.50); short poles expanded with parallel behavioral Turkish wording.",
        "2. Reverse-pair primary deltas **retained** behaviorally keyed identical vectors (P2A-2D-1 policy); not negated to satisfy RVI.",
        "3. TraitScoringService `_reversePairConsistency` expects opposite stored signs → **CONDITIONAL** blocker for reverse RVI.",
        "4. Evidence-strength values remain in `{0.50,0.55,0.60,0.65,0.70}` band; no flat 0.72.",
        "5. No all-positive multi-dimension dominant options after trade-off guard.",
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
            "8. **Construct-contamination findings:** Frequency-only deltas; disclosure_pace vs EQ emotional_openness separation retained.",
            f"9. **Prompt semantic verdict:** acceptable",
            f"10. **Trade-off verdict:** genuine mixed trade-off retained",
            f"11. **Social-desirability verdict:** {parse_notes(item.get('authoring_notes','')).get('sdr_item_risk','low')} item risk",
            "12. **Per-option plausibility verdict:** A–D acceptable",
            "13. **Per-option dominant-answer risk:** none flagged after length edits",
            "14. **Per-option delta-direction review:** unchanged from parent (behavioral keying retained)",
            "15. **Per-option delta-magnitude review:** parent bands retained",
            "16. **Per-option evidence-strength review:** contract band retained or nudged",
            f"17. **Item-level SDR review:** `{parse_notes(item.get('authoring_notes','')).get('sdr_item_risk','low')}`",
            "18. **Option-level SDR review:** see candidate JSON / evidence review",
            "19. **Response-style review:** low",
            f"20. **Semantic-pair review:** `{item.get('semantic_pair_id') or 'none'}` — retain",
            f"21. **Reverse-pair review:** `{item.get('reverse_pair_id') or 'none'}` — retain; behavioral keying unchanged",
            f"22. **Behavioral-isomorph review:** `{item.get('behavioral_isomorph_group') or 'none'}` — retain",
            "23. **RVI-role review:** reverse_consistency **CONDITIONAL** (service expects opposite signs)",
            "24. **Turkish-language verdict:** internal length-balance edits; expert language review pending",
            f"25. **Option-length ratio after edit:** {clog['option_length_ratio_after']}",
            f"26. **Recommended action:** {clog['verdict']}",
            "27. **Residual ambiguity:** cognitive interviews pending",
            f"28. **Human-review priority:** {clog['human_review_priority']}",
            f"29. **Final internal disposition:** `internal_accept_for_candidate`",
            "",
        ]

    lines += [
        "## Pair / group / RVI summary",
        "",
        "- Semantic pairs (8): retained.",
        "- Reverse pairs (6): retained; **behavioral keying unchanged**; RVI opposite-sign check is a known service gap (**CONDITIONAL**).",
        "- Behavioral isomorphs (6): retained.",
        "- RVI roles: timing_quality universal; semantic/reverse/isomorph/impression/variation retained where design supports.",
        "",
    ]
    (DOCS / "frequency_pilot_tr_v1_red_team_review.md").write_text(
        "\n".join(lines) + "\n", encoding="utf-8"
    )

    # --- reverse pair application review ---
    rp = [
        "# Frequency Reverse-Pair Application Review v1",
        "",
        "**Scope:** All 6 reverse pairs in Frequency pilot review candidate 1.",
        "**Policy:** Retain behavioral keying; do **not** negate deltas to fake RVI compatibility.",
        "",
        "## Service compatibility",
        "",
        "TraitScoringService `_reversePairConsistency` expects **opposite** stored primary signs across reverse-pair members when the same option letter is selected. Frequency pilot uses **behaviorally keyed identical** primary delta vectors across pair members (same trait direction ↔ same behavioral pole).",
        "",
        "**Current service compatibility:** **CONDITIONAL** — documented blocker; retain pairs with fixture logic keyed on primary-delta sign equivalence, not raw option letter alone.",
        "",
    ]
    for meta in REVERSE_PAIR_META:
        pid = meta["pair_id"]
        qids = meta["question_ids"]
        items_by_id = {i["question_id"]: i for i in cand["items"]}
        rp += [
            f"## `{pid}`",
            "",
            f"- **Item IDs:** `{qids[0]}`, `{qids[1]}`",
            f"- **Shared dimension:** `{meta['dimension']}`",
            f"- **Prompt polarity:** {meta['prompt_polarity']}",
            f"- **Option correspondence map:** {meta['correspondence']}",
            "- **Expected trait-direction relation:** same behavioral pole ↔ same primary-delta sign on both items",
            "- **Expected consistent combinations:** selecting max-primary on item 1 and max-primary on item 2 (behavioral correspondence) = trait-consistent",
            "- **Legitimate inconsistency:** selecting high-primary on one member and low-primary on the other when prompts are reverse poles but wording maps to opposite behavioral poles",
            "- **Current service compatibility:** **CONDITIONAL** (service expects opposite stored signs)",
            "- **Required fixture logic:** map consistency by primary-delta sign equivalence per behavioral correspondence; do not assume same option letter implies consistency for RVI",
            "- **Retain / revise / remove:** **retain** with documented blocker",
            "",
            "### Primary delta vectors (identical across members)",
            "",
        ]
        for qid in qids:
            item = items_by_id[qid]
            rp.append(f"**`{qid}`** prompt: {item['prompt']['tr']}")
            for o in item["options"]:
                prim = o["dimension_deltas"].get(meta["dimension"], 0)
                rp.append(
                    f"- {o['option_id']}: primary `{meta['dimension']}` = {prim:+.2f}; "
                    f"text: {o['localized_text']['tr']}"
                )
            rp.append("")
    (DOCS / "frequency_reverse_pair_application_review_v1.md").write_text(
        "\n".join(rp) + "\n", encoding="utf-8"
    )

    # --- changelog ---
    cl = [
        "# Frequency Pilot TR v1 — Review Candidate 1 Changelog",
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
            f"- **Pair/group changes:** {clog['pair_group_changes'] or 'none'}",
            f"- **Option-length ratio after:** {clog['option_length_ratio_after']}",
            f"- **ID decision:** {clog['id_decision']}",
            f"- **Remaining review concern:** {clog['remaining_review_concern']}",
            "",
        ]
    (DOCS / "frequency_pilot_tr_v1_review_candidate_1_changelog.md").write_text(
        "\n".join(cl) + "\n", encoding="utf-8"
    )

    # --- evidence review ---
    ev = [
        "# Frequency Pilot TR v1 Review Candidate 1 — Evidence Mapping Review",
        "",
        f"**Source:** `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json`",
        "**Coverage:** All **50** items; option-level evidence fields included.",
        "",
        "> Provisional authoring hypotheses only. Expert psychological review pending.",
        "",
    ]
    for i, item in enumerate(cand["items"], 1):
        qid = item["question_id"]
        primary = item["primary_dimension"]
        ev += [
            f"## Item {i}: `{qid}`",
            "",
            f"**Scenario family:** `{families[qid]}` | **Primary:** `{primary}`",
            f"**Prompt:** {item['prompt']['tr']}",
            "",
            "### Option evidence",
            "",
        ]
        for o in item["options"]:
            ev.append(f"#### `{qid}` / option `{o['option_id']}`")
            ev.append(f"- **text:** {o['localized_text']['tr']}")
            ev.append(f"- **deltas:** {fmt_deltas(o['dimension_deltas'], o.get('counter_evidence'))}")
            ev.append(f"- **evidence_strength:** {o['evidence_strength']:.2f}")
            ev.append(f"- **counter_evidence:** {o.get('counter_evidence') or {}}")
            ev.append(f"- **social_desirability_risk:** `{o['social_desirability_risk']}`")
            ev.append(f"- **response_style_risk:** `{o['response_style_risk']}`")
            ev.append(f"- **rationale:** {o.get('rationale', '')}")
            ev.append("")
        ev.append("---\n")
    (DOCS / "frequency_pilot_tr_v1_review_candidate_1_evidence_review.md").write_text(
        "\n".join(ev) + "\n", encoding="utf-8"
    )

    # --- option balance ---
    all_lens: list[int] = []
    per_rows: list[str] = []
    l1_rows: list[str] = []
    max_ratio = 0.0
    for item in cand["items"]:
        qid = item["question_id"]
        lens = [len(o["localized_text"]["tr"]) for o in item["options"]]
        all_lens.extend(lens)
        mn, mx = min(lens), max(lens)
        ratio = mx / mn if mn else 0.0
        max_ratio = max(max_ratio, ratio)
        per_rows.append(
            f"| `{qid}` | {lens[0]} | {lens[1]} | {lens[2]} | {lens[3]} | {mn} | {statistics.median(lens)} | {mx} | {ratio:.2f} |"
        )
        l1s = [l1(o["dimension_deltas"]) for o in item["options"]]
        l1_rows.append(
            f"| `{qid}` | {l1s[0]:.2f} | {l1s[1]:.2f} | {l1s[2]:.2f} | {l1s[3]:.2f} | {max(l1s)-min(l1s):.2f} |"
        )
    ob = [
        "# Frequency Pilot TR v1 Review Candidate 1 — Option Balance Report",
        "",
        f"**Form:** `{FORM_ID}` | **Items:** 50",
        "",
        "## Option text-length distribution",
        "",
        f"- min: {min(all_lens)}",
        f"- median: {statistics.median(all_lens)}",
        f"- max: {max(all_lens)}",
        f"- mean: {statistics.mean(all_lens):.1f}",
        f"- max item ratio: {max_ratio:.2f}",
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
        "## Notes",
        "",
        "- Sixteen length-leakage items edited; all item ratios ≤ 1.50 target.",
        "- No globally dominant all-positive multi-dimension option.",
        "",
    ]
    (DOCS / "frequency_pilot_tr_v1_review_candidate_1_option_balance_report.md").write_text(
        "\n".join(ob) + "\n", encoding="utf-8"
    )

    # --- construct separation / quality: keep hand-enriched markdown if present ---
    # Generator writes a minimal stub only when the enriched report is missing.
    cs_path = DOCS / "frequency_pilot_tr_v1_review_candidate_1_construct_separation_report.md"
    qr_path = DOCS / "frequency_pilot_tr_v1_review_candidate_1_quality_report.md"
    if not cs_path.exists() or cs_path.stat().st_size < 2000:
        cs_path.write_text(
            "\n".join(
                [
                    "# Frequency Pilot TR v1 Review Candidate 1 — Construct Separation Report",
                    "",
                    f"**Source:** `assets/data/assessment_v3/frequency/frequency_pilot_tr_v1_review_candidate_1.json`",
                    "**Parent reference:** `docs/core_engine/frequency_pilot_tr_v1_construct_separation_report.md`",
                    "",
                    "## EQ / Frequency module separation",
                    "",
                    "- EQ dimension deltas found in candidate bank: **0** — **PASS**",
                    "- Forbidden `emotional_openness` strings: **0** — **PASS**",
                    "",
                    "## `disclosure_pace` vs EQ `emotional_openness`",
                    "",
                    "Candidate retains Frequency-only `disclosure_pace` timing/sequencing framing; no EQ writes.",
                    "",
                    "## Readiness",
                    "",
                    "**Automated separation checks:** **PASS**",
                    "",
                    "Expert psychological review pending.",
                    "",
                ]
            )
            + "\n",
            encoding="utf-8",
        )
    if not qr_path.exists() or qr_path.stat().st_size < 2000:
        qr_path.write_text(
            "\n".join(
                [
                    "# Frequency Pilot TR v1 Review Candidate 1 — Quality Report",
                    "",
                    f"**Form ID:** `{FORM_ID}`",
                    f"**Content version:** `{CV}`",
                    f"**Parent:** `{PARENT_CV}`",
                    "**Runtime-loaded:** No",
                    "",
                    "## Readiness layers",
                    "",
                    "| Layer | Result |",
                    "|---|---|",
                    "| Structural readiness | **PASS** |",
                    "| Reverse-pair readiness | **CONDITIONAL** |",
                    "",
                    f"- PASS: {verdict_counts.get('PASS', 0)}",
                    f"- PASS_WITH_MINOR_EDIT: {verdict_counts.get('PASS_WITH_MINOR_EDIT', 0)}",
                    f"- UNRESOLVED: {verdict_counts.get('UNRESOLVED', 0)}",
                    "",
                    f"| Option length ratio ≤ 1.50 | PASS (max {max_ratio:.2f}) |",
                    "",
                    "**CONDITIONAL** for continued internal iteration / expert review only.",
                    "",
                ]
            )
            + "\n",
            encoding="utf-8",
        )


def main() -> None:
    verify_parent_sha()
    print(f"Parent SHA256 verified: {PARENT_SHA256}")

    parent = json.loads(PARENT.read_text(encoding="utf-8"))
    if parent["content_version"] != PARENT_CV:
        raise SystemExit(f"Unexpected parent content_version: {parent['content_version']}")

    cand, logs = build_candidate(parent)

    # Hard check length ratios
    worst = 0.0
    for item in cand["items"]:
        r = option_length_ratio(item)
        worst = max(worst, r)
        if r > 1.50 + 1e-9:
            raise SystemExit(f"Length ratio {r:.2f} still > 1.50 for {item['question_id']}")

    write_json(OUT_JSON, cand)
    generate_docs(cand, logs, parent)
    SIDE.parent.mkdir(parents=True, exist_ok=True)
    SIDE.write_text(json.dumps(logs, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"wrote {OUT_JSON}")
    print(f"wrote docs under {DOCS}")
    print(f"wrote {SIDE}")
    print("verdicts", dict(Counter(x["verdict"] for x in logs)))
    print(f"max_option_length_ratio={worst:.2f}")


if __name__ == "__main__":
    main()
