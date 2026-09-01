#!/usr/bin/env python3
"""Apply Phase 6H.1 human-approved TR/EN source fix for q0341 only.

Updates TR stem in dormant TR pool + TR manifest, EN stem in batch 007,
marks q0341 REVIEWED, rebuilds EN parity artifacts, preserves later review markdown.
"""
from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
ITEM_ID = "frequency_v2_q0341"
TR_POOL = OUT / "frequency_behavior_pool_tr_v2_draft1.json"
TR_MANIFEST = OUT / "frequency_v2_phase6a_tr_text_manifest.json"
BATCH_007 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_007.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_301_350 = OUT / "en_human_review/frequency_v2_en_review_301_350.md"
Q0227_ID = "frequency_v2_q0227"
Q0260_ID = "frequency_v2_q0260"
Q0227_FLAGS = ["possible_cultural_mismatch"]
Q0260_FLAGS = ["possible_cultural_mismatch", "possible_intensity_drift"]

TR_PROMPT_NEW = (
    "Partneriniz kendisiyle ilgili bir sırrı sizinle paylaştı ve “kimseye söyleme” dedi."
)
EN_PROMPT_NEW = (
    'Your partner shared a personal secret about themselves with you and said, '
    '"Don\'t tell anyone."'
)

LATER_REVIEW_FILES = [
    "frequency_v2_en_review_351_400.md",
    "frequency_v2_en_review_401_426.md",
]


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


def head_bytes_for_review(rel_path: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(ROOT), "show", f"HEAD:{rel_path}"])


def restore_later_review_files() -> None:
    rel_dir = "tool/frequency_behavior_v2/out/en_human_review"
    for name in LATER_REVIEW_FILES:
        path = OUT / "en_human_review" / name
        path.write_bytes(head_bytes_for_review(f"{rel_dir}/{name}"))


def preserve_prior_flag_metadata(en_review: dict) -> None:
    targets = {
        Q0227_ID: Q0227_FLAGS,
        Q0260_ID: Q0260_FLAGS,
    }
    rev_by_id = {r["item_id"]: r for r in en_review["items"]}
    for iid, flags in targets.items():
        row = rev_by_id.get(iid)
        if row is None:
            raise SystemExit(f"{iid} missing from EN review metadata")
        row["translation_review_status"] = "REVIEWED"
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


def patch_tr_pool() -> dict:
    pool = json.loads(TR_POOL.read_text(encoding="utf-8"))
    item = next(it for it in pool["items"] if it["item_id"] == ITEM_ID)
    options_before = json.dumps(item["options"], ensure_ascii=False, sort_keys=True)
    item["prompt"] = TR_PROMPT_NEW
    TR_POOL.write_text(json.dumps(pool, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"options": options_before}


def patch_tr_manifest() -> None:
    manifest = json.loads(TR_MANIFEST.read_text(encoding="utf-8"))
    row = next(it for it in manifest if it["item_id"] == ITEM_ID)
    row["prompt"] = TR_PROMPT_NEW
    TR_MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def patch_batch_007() -> dict:
    batch = json.loads(BATCH_007.read_text(encoding="utf-8"))
    item = batch["items"][ITEM_ID]
    options_before = json.dumps(item["options"], ensure_ascii=False, sort_keys=True)
    item["prompt"] = EN_PROMPT_NEW
    item["translation_review_status"] = "REVIEWED"
    BATCH_007.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"options": options_before}


def main() -> None:
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    tr_before = patch_tr_pool()
    patch_tr_manifest()
    en_before = patch_batch_007()

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()

    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    preserve_prior_flag_metadata(en_review)
    recompute_review_stats(en_review)
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    tr_pool = json.loads(TR_POOL.read_text(encoding="utf-8"))
    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    tr_item = next(it for it in tr_pool["items"] if it["item_id"] == ITEM_ID)
    en_item = next(it for it in en_pool["items"] if it["item_id"] == ITEM_ID)
    rev = {r["item_id"]: r for r in en_review["items"]}

    tr_opts = json.dumps(tr_item["options"], ensure_ascii=False, sort_keys=True)
    en_opts = json.dumps(
        {o["option_id"]: o["text"] for o in en_item["options"]},
        ensure_ascii=False,
        sort_keys=True,
    )
    if tr_opts != tr_before["options"]:
        raise SystemExit("q0341 TR options changed unexpectedly")
    if en_opts != en_before["options"]:
        raise SystemExit("q0341 EN options changed unexpectedly")

    assert tr_item["prompt"] == TR_PROMPT_NEW
    assert en_item["prompt"] == EN_PROMPT_NEW
    assert rev[ITEM_ID]["translation_review_status"] == "REVIEWED"

    for i in range(1, 351):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(351, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    review_md = REVIEW_301_350.read_text(encoding="utf-8")
    if "SOURCE_TR_ISSUE" in review_md:
        raise SystemExit("SOURCE_TR_ISSUE marker still present in review markdown")

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 350

    print("Phase 6H.1 q0341 source fix applied successfully.")
    print("TR/EN stems updated; options unchanged.")
    print("q0341 marked REVIEWED; SOURCE_TR_ISSUE marker removed.")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
