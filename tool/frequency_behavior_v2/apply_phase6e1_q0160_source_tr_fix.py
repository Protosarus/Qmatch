#!/usr/bin/env python3
"""Apply Phase 6E.1 human-approved TR/EN source fix for q0160 only.

Updates TR stem in dormant TR pool + TR manifest, EN stem in batch 004,
marks q0160 REVIEWED, rebuilds EN parity artifacts, preserves later review markdown.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
ITEM_ID = "frequency_v2_q0160"
TR_POOL = OUT / "frequency_behavior_pool_tr_v2_draft1.json"
TR_MANIFEST = OUT / "frequency_v2_phase6a_tr_text_manifest.json"
BATCH_004 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_004.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_151_200 = OUT / "en_human_review/frequency_v2_en_review_151_200.md"

TR_PROMPT_NEW = (
    "Partnerin senin evinde ilk defa gece kalıp sabah gittikten sonra, "
    "bilerek diş fırçasını ve tişörtünü banyoda bıraktığını fark ettin."
)
EN_PROMPT_NEW = (
    "After your partner stays over at your place for the first time and leaves the next morning, "
    "you notice they deliberately left their toothbrush and T-shirt in your bathroom."
)

LATER_REVIEW_FILES = [
    "frequency_v2_en_review_201_250.md",
    "frequency_v2_en_review_251_300.md",
    "frequency_v2_en_review_301_350.md",
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


def patch_batch_004() -> dict:
    batch = json.loads(BATCH_004.read_text(encoding="utf-8"))
    item = batch["items"][ITEM_ID]
    options_before = json.dumps(item["options"], ensure_ascii=False, sort_keys=True)
    item["prompt"] = EN_PROMPT_NEW
    item["translation_review_status"] = "REVIEWED"
    BATCH_004.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"options": options_before}


def main() -> None:
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    tr_before = patch_tr_pool()
    patch_tr_manifest()
    en_before = patch_batch_004()

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()

    tr_pool = json.loads(TR_POOL.read_text(encoding="utf-8"))
    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    en_review = json.loads(
        (OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json").read_text()
    )
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
        raise SystemExit("q0160 TR options changed unexpectedly")
    if en_opts != en_before["options"]:
        raise SystemExit("q0160 EN options changed unexpectedly")

    assert "senin evinde" in tr_item["prompt"]
    assert "at your place" in en_item["prompt"]
    assert rev[ITEM_ID]["translation_review_status"] == "REVIEWED"

    for i in range(1, 201):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(201, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    review_md = REVIEW_151_200.read_text(encoding="utf-8")
    if "SOURCE_TR_ISSUE" in review_md:
        raise SystemExit("SOURCE_TR_ISSUE marker still present in review markdown")

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 200

    print("Phase 6E.1 q0160 source fix applied successfully.")
    print("TR/EN stems updated; options unchanged.")
    print("q0160 marked REVIEWED; SOURCE_TR_ISSUE marker removed.")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
