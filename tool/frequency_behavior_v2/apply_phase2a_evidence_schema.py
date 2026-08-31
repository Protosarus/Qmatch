#!/usr/bin/env python3
"""Phase 2A: migrate dormant V2 evidence_meta schema. Do not assign numeric scores."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
REVIEW_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
PLAN_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json"
REPORT_PATH = OUT_DIR / "frequency_behavior_v2_phase2a_evidence_contract_report.md"

PENDING_EVIDENCE = {
    "version": "frequency_evidence_prior_v1",
    "calibration_status": "uncalibrated",
    "review_status": "pending",
    "social_desirability": None,
    "obviousness": None,
    "behavioral_plausibility": None,
    "self_presentation_risk": None,
    "diagnostic_value": None,
    "ambiguity": None,
}


def fingerprint(pool: dict) -> str:
    rows = []
    for it in pool["items"]:
        opts = [
            (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
            for o in it["options"]
        ]
        rows.append((it["item_id"], it["prompt"], opts))
    blob = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(blob.encode("utf-8")).hexdigest()


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    before = fingerprint(pool)
    item_ids = [it["item_id"] for it in pool["items"]]
    option_ids = [o["option_id"] for it in pool["items"] for o in it["options"]]
    if len(item_ids) != 426 or len(option_ids) != 1704:
        raise SystemExit(f"archive counts {len(item_ids)}/{len(option_ids)}")

    numeric_before = 0
    for it in pool["items"]:
        for o in it["options"]:
            em = o.get("evidence_meta") or {}
            for k, v in em.items():
                if k in {
                    "social_desirability",
                    "obviousness",
                    "behavioral_plausibility",
                    "self_presentation_risk",
                    "diagnostic_value",
                    "ambiguity",
                    "directness",
                } and v is not None:
                    numeric_before += 1
    if numeric_before:
        raise SystemExit(f"STOP: numeric evidence already present ({numeric_before})")

    migrated = 0
    for it in pool["items"]:
        for o in it["options"]:
            o["evidence_meta"] = dict(PENDING_EVIDENCE)
            migrated += 1
    if migrated != 1704:
        raise SystemExit(f"migrated {migrated}")

    after = fingerprint(pool)
    if after != before:
        raise SystemExit("STOP: prompt/option-text/weight fingerprint changed")

    if pool.get("runtime_selectable") is not False:
        raise SystemExit("runtime_selectable drifted")
    pool["runtime_selectable"] = False
    pool["status"] = "draft_not_runtime"
    pool["calibration_status"] = "uncalibrated"
    pool["evidence_meta_version"] = "frequency_evidence_prior_v1"
    pool["evidence_meta_phase"] = "phase2a_schema_only"

    review = json.loads(REVIEW_PATH.read_text(encoding="utf-8"))
    review["evidence_meta_policy"] = (
        "frequency_evidence_prior_v1_uncalibrated_null_pending"
    )
    review["phase2a"] = {
        "evidence_numeric_values_assigned": False,
        "schema_migrated_options": 1704,
        "prompt_weight_fingerprint_sha256": after,
        "runtime_selectable": False,
    }

    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    notes = list(plan.get("notes") or [])
    notes.append(
        "Phase 2A: evidence_meta schema migrated to frequency_evidence_prior_v1; all six scores remain null/pending/uncalibrated."
    )
    plan["notes"] = notes

    write_json(POOL_PATH, pool)
    write_json(REVIEW_PATH, review)
    write_json(PLAN_PATH, plan)

    report = f"""# Frequency V2 Phase 2A — Evidence metadata contract

Status: **schema only**. No evidence numeric values were assigned.
V2 remains `runtime_selectable=false`.

Contract: `docs/assessment/frequency_v2/frequency_evidence_metadata_v1_contract.md`

## Current pool

- Archive questions: 426
- Archive options: 1704
- Dormant selectable questions: 408
- DROP archived/non-selectable: 18
- Rewrite pending: 0
- Selectable dual-primary: 0
- `runtime_selectable`: false
- `evidence_meta`: all six fields null, `review_status=pending`, `calibration_status=uncalibrated`
- Prompt / option-text / behavioral-weight fingerprint SHA-256: `{after}`
- Fingerprint unchanged by schema migration: true
- Options whose `evidence_meta` object was reshaped (null placeholders only): 1704

## Allowed values (not yet assigned)

`0.00` · `0.25` · `0.50` · `0.75` · `1.00`

## Data shape (every option)

```text
evidence_meta:
  version: frequency_evidence_prior_v1
  calibration_status: uncalibrated
  review_status: pending
  social_desirability: null
  obviousness: null
  behavioral_plausibility: null
  self_presentation_risk: null
  diagnostic_value: null
  ambiguity: null
```

Legacy `directness` was removed from the placeholder. It was never scored.

## Relative scoring rule (for a later assign phase)

Scores are relative to the other three options in the same question.
They are not personality, moral, truth/lie, or clinical values.
`behavioral_weights` stay the behavioral meaning; evidence describes interpretation confidence.

## Safety

- Frequency V1 banks not modified
- pubspec.yaml not modified
- Live locale routing not modified
- Discover / Persona / matching / canonical_v1 / C2 / FrequencyTo20dRuntimeAdapter not modified
- No 12D→6D map
- No Firebase deploy
- No commit/push
- `discrimination_power` and response time are not authored

FREQUENCY V2 PHASE 2A EVIDENCE METADATA CONTRACT READY — NO EVIDENCE VALUES ASSIGNED — V2 STILL DORMANT
"""
    REPORT_PATH.write_text(report, encoding="utf-8")
    print("migrated", migrated)
    print("fingerprint", after)
    print("runtime", pool["runtime_selectable"])
    print("wrote", REPORT_PATH)


if __name__ == "__main__":
    main()
