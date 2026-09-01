#!/usr/bin/env python3
"""Apply Phase 6J final human EN semantic review for batch 401-426.

English user-facing wording and translation_review_status only.
Completes EN human review: all 426 questions REVIEWED.
Preserves machine-triage flags independently of REVIEWED status.
Does not change TR source, weights, DROP/selectable state, or runtime routing.
"""
from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
BATCH_009 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_009.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
Q0227_ID = "frequency_v2_q0227"
Q0260_ID = "frequency_v2_q0260"
Q0227_FLAGS = ["possible_cultural_mismatch"]
Q0260_FLAGS = ["possible_cultural_mismatch", "possible_intensity_drift"]

REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(401, 427)]

ACCEPT_AS_IS_IDS = {
    "frequency_v2_q0401",
    "frequency_v2_q0404",
    "frequency_v2_q0405",
    "frequency_v2_q0408",
    "frequency_v2_q0412",
    "frequency_v2_q0415",
    "frequency_v2_q0418",
    "frequency_v2_q0421",
    "frequency_v2_q0424",
}

FLAG_PRESERVE_IDS = {
    "frequency_v2_q0403": ["possible_intensity_drift"],
    "frequency_v2_q0407": ["possible_intensity_drift"],
    "frequency_v2_q0412": ["possible_intensity_drift"],
    "frequency_v2_q0422": ["possible_intensity_drift"],
    "frequency_v2_q0424": ["possible_intensity_drift"],
    "frequency_v2_q0425": ["possible_intensity_drift"],
}

PATCHES: dict[str, dict] = {
    "frequency_v2_q0402": {
        "prompt": (
            "You've been seeing someone new for a few weeks. They want to tag you on social "
            "media or share a photo of the two of you."
        ),
    },
    "frequency_v2_q0403": {
        "options": {
            "frequency_v2_q0403_b": 'I\'d say, "Don\'t get involved in this."',
        },
    },
    "frequency_v2_q0406": {
        "prompt": (
            "You want to spend a quiet evening together, but your partner wants to start a long, "
            "serious conversation about the relationship right then. What do you do?"
        ),
        "options": {
            "frequency_v2_q0406_a": (
                "I'd clearly suggest leaving that conversation for another time instead of "
                "getting into it tonight."
            ),
        },
    },
    "frequency_v2_q0407": {
        "prompt": (
            "You're getting to know someone new. They say things like \"I miss you\" in almost "
            "every message or every time you meet."
        ),
        "options": {
            "frequency_v2_q0407_c": 'I\'d say, "Let\'s slow down a little."',
        },
    },
    "frequency_v2_q0409": {
        "options": {
            "frequency_v2_q0409_a": (
                "When the moment feels right, I'd bring the issue up myself and suggest that "
                "we sort things out."
            ),
        },
    },
    "frequency_v2_q0410": {
        "options": {
            "frequency_v2_q0410_d": (
                "For now, I'd rather keep seeing each other in shorter stretches than spend an "
                "entire weekend together."
            ),
        },
    },
    "frequency_v2_q0411": {
        "prompt": (
            "Your partner can't decide whether to stay home or go out and keeps wanting both "
            "at once."
        ),
    },
    "frequency_v2_q0413": {
        "options": {
            "frequency_v2_q0413_a": "I'd put some distance between myself and that friend.",
        },
    },
    "frequency_v2_q0414": {
        "options": {
            "frequency_v2_q0414_d": "I'd try to steer the conversation toward lighter topics.",
        },
    },
    "frequency_v2_q0416": {
        "prompt": (
            "You've been seeing someone new for a few weeks. They say, "
            "\"I'm thinking of this as something serious.\""
        ),
    },
    "frequency_v2_q0417": {
        "prompt": (
            "You go to an event together. Your partner is very social, while you're more reserved."
        ),
        "options": {
            "frequency_v2_q0417_c": "After a while, I'd suggest leaving.",
        },
    },
    "frequency_v2_q0419": {
        "prompt": (
            "You're getting to know someone new. They're very physically affectionate, while you "
            "prefer more personal space."
        ),
        "options": {
            "frequency_v2_q0419_c": (
                'I\'d say, "I move a little more slowly with physical closeness."'
            ),
        },
    },
    "frequency_v2_q0420": {
        "prompt": "Your partner is indirectly hinting at a feeling or need involving you.",
    },
    "frequency_v2_q0422": {
        "options": {
            "frequency_v2_q0422_c": "I'd listen, but I wouldn't say much about myself.",
        },
    },
    "frequency_v2_q0423": {
        "prompt": (
            "Your partner is juggling several social plans at once and wants to include you too."
        ),
    },
    "frequency_v2_q0425": {
        "prompt": "On a particular issue, your partner thinks they're right and won't back down.",
    },
    "frequency_v2_q0426": {
        "options": {
            "frequency_v2_q0426_c": 'I\'d say, "I tend to keep my messages short."',
        },
    },
}


def apply_patches_to_item(item: dict, patch: dict) -> None:
    if "prompt" in patch:
        item["prompt"] = patch["prompt"]
    for oid, text in patch.get("options", {}).items():
        item["options"][oid] = text


def merge_batches(batch_dir: Path) -> dict:
    merged: dict = {"items": {}}
    for path in sorted(batch_dir.glob("frequency_v2_en_semantic_text_batch_*.json")):
        chunk = json.loads(path.read_text(encoding="utf-8"))
        for iid, data in chunk.get("items", {}).items():
            if iid in merged["items"]:
                raise SystemExit(f"Duplicate translation item {iid} in {path.name}")
            merged["items"][iid] = data
    merged["translation_version"] = "frequency_v2_en_semantic_v1"
    return merged


def assert_prior_batches_unchanged() -> None:
    batch_dir = OUT / "en_translation_batches"
    for batch_no, lo, hi in [
        (1, 1, 50),
        (2, 51, 100),
        (3, 101, 150),
        (4, 151, 200),
        (5, 201, 250),
        (6, 251, 300),
        (7, 301, 350),
        (8, 351, 400),
    ]:
        path = batch_dir / f"frequency_v2_en_semantic_text_batch_{batch_no:03d}.json"
        batch = json.loads(path.read_text(encoding="utf-8"))
        for i in range(lo, hi + 1):
            iid = f"frequency_v2_q{i:04d}"
            if batch["items"][iid].get("translation_review_status") != "REVIEWED":
                raise SystemExit(f"{path.name} item not REVIEWED: {iid}")


def preserve_flag_metadata(en_review: dict, extra: dict[str, list[str]]) -> None:
    targets = {
        Q0227_ID: Q0227_FLAGS,
        Q0260_ID: Q0260_FLAGS,
        **extra,
    }
    rev_by_id = {r["item_id"]: r for r in en_review["items"]}
    for iid, flags in targets.items():
        row = rev_by_id.get(iid)
        if row is None:
            raise SystemExit(f"{iid} missing from EN review metadata")
        existing = list(row.get("translation_review_flags") or [])
        for flag in flags:
            if flag not in existing:
                existing.append(flag)
        row["translation_review_flags"] = existing


def recompute_review_stats(en_review: dict) -> None:
    status_counts: Counter = Counter()
    flag_counts: Counter = Counter()
    for row in en_review["items"]:
        status = row.get("translation_review_status")
        if status:
            status_counts[status] += 1
        for f in row.get("translation_review_flags") or []:
            flag_counts[f] += 1
    en_review.setdefault("stats", {})
    en_review["stats"]["translation_review_status_counts"] = dict(status_counts)
    en_review["stats"]["translation_review_flag_counts"] = dict(flag_counts)


def snapshot_batch_flags() -> dict[str, list[str]]:
    en_review = json.loads(
        (OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json").read_text(
            encoding="utf-8"
        )
    )
    rev_by_id = {r["item_id"]: r for r in en_review["items"]}
    snap: dict[str, list[str]] = {}
    for iid in FLAG_PRESERVE_IDS:
        snap[iid] = list(rev_by_id[iid].get("translation_review_flags") or [])
    return snap


def main() -> None:
    assert_prior_batches_unchanged()
    flag_snap = snapshot_batch_flags()

    batch = json.loads(BATCH_009.read_text(encoding="utf-8"))
    items = batch["items"]

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 009: {iid}")

    accept_before: dict[str, dict] = {}
    for iid in ACCEPT_AS_IS_IDS:
        accept_before[iid] = {
            "prompt": items[iid]["prompt"],
            "options": dict(items[iid]["options"]),
        }

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"
        if iid in FLAG_PRESERVE_IDS:
            items[iid]["translation_review_flags"] = flag_snap.get(iid, FLAG_PRESERVE_IDS[iid])

    for iid, before in accept_before.items():
        if items[iid]["prompt"] != before["prompt"]:
            raise SystemExit(f"ACCEPT AS-IS prompt changed: {iid}")
        if items[iid]["options"] != before["options"]:
            raise SystemExit(f"ACCEPT AS-IS options changed: {iid}")

    BATCH_009.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    preserve_flag_metadata(en_review, FLAG_PRESERVE_IDS)
    for row in en_review["items"]:
        if row["item_id"] in REVIEWED_IDS:
            row["translation_review_status"] = "REVIEWED"
    recompute_review_stats(en_review)
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    rev = {r["item_id"]: r for r in en_review["items"]}
    by_id = {it["item_id"]: it for it in en_pool["items"]}

    q403b = next(o["text"] for o in by_id["frequency_v2_q0403"]["options"] if o["option_id"].endswith("_b"))
    assert q403b == 'I\'d say, "Don\'t get involved in this."'

    q409 = rev["frequency_v2_q0409"]
    assert q409["translation_review_status"] == "REVIEWED"
    assert q409["drop_from_selectable"] is True
    assert q409["selector_eligible"] is False

    q417c = next(o["text"] for o in by_id["frequency_v2_q0417"]["options"] if o["option_id"].endswith("_c"))
    assert q417c == "After a while, I'd suggest leaving."

    q419 = by_id["frequency_v2_q0419"]
    assert "touchy" not in q419["prompt"].lower()
    assert "physically affectionate" in q419["prompt"].lower()

    q423 = by_id["frequency_v2_q0423"]["prompt"]
    assert "all of them" not in q423.lower()
    assert "include you too" in q423.lower()

    q426c = next(o["text"] for o in by_id["frequency_v2_q0426"]["options"] if o["option_id"].endswith("_c"))
    assert "messages" in q426c.lower()

    for iid, flags in FLAG_PRESERVE_IDS.items():
        existing = rev[iid].get("translation_review_flags") or []
        for flag in flags:
            assert flag in existing, f"{iid} missing flag {flag}"

    for i in range(1, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    pending_count = sum(
        1
        for r in en_review["items"]
        if r.get("translation_review_status") == "PENDING_HUMAN_REVIEW"
    )
    assert reviewed_count == 426
    assert pending_count == 0
    assert len(PATCHES) == 17
    assert len(ACCEPT_AS_IS_IDS) == 9

    print("Phase 6J batch 401-426 applied successfully.")
    print(f"REWRITE_EN_ONLY items: {len(PATCHES)}")
    print(f"ACCEPT AS-IS items: {len(ACCEPT_AS_IS_IDS)}")
    print(f"Total REVIEWED: {reviewed_count}")
    print("PENDING_HUMAN_REVIEW: 0")


if __name__ == "__main__":
    main()
