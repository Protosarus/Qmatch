#!/usr/bin/env python3
"""Apply Phase 6I.1 human-approved TR source fix for q0353 option a only.

Updates TR option a in dormant TR pool + TR manifest, marks q0353 REVIEWED,
rebuilds EN parity artifacts, preserves later review markdown.
EN text unchanged.
"""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
ITEM_ID = "frequency_v2_q0353"
OPTION_A_ID = "frequency_v2_q0353_a"
TR_POOL = OUT / "frequency_behavior_pool_tr_v2_draft1.json"
TR_MANIFEST = OUT / "frequency_v2_phase6a_tr_text_manifest.json"
BATCH_008 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_008.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_351_400 = OUT / "en_human_review/frequency_v2_en_review_351_400.md"
PHASE1G_DOC = ROOT / "docs/QMatch_Frequency_V2_Phase1F_Final_Human_Rewrites.txt"
PHASE2B_PROPOSAL = OUT / "frequency_behavior_v2_phase2b_evidence_prior_proposal.json"
PHASE2C_TRIAGE = OUT / "frequency_behavior_v2_phase2c_evidence_triage.json"
PHASE2E_REVISED = OUT / "frequency_behavior_v2_phase2e_evidence_prior_revised_proposal.json"
PHASE2F_FINAL = OUT / "frequency_behavior_v2_phase2f_final_evidence_prior.json"
Q0227_ID = "frequency_v2_q0227"
Q0260_ID = "frequency_v2_q0260"
Q0227_FLAGS = ["possible_cultural_mismatch"]
Q0260_FLAGS = ["possible_cultural_mismatch", "possible_intensity_drift"]
STRUCTURAL_GUARD_IDS = ("frequency_v2_q0380",)

TR_OPTION_A_NEW = "Yemek boyunca telefonu kaldırmasını net biçimde isterim."
TR_OPTION_A_OLD = "Yemek boyunca telefonu kaldırmayı önermesini net biçimde isterim."
EN_OPTION_A_EXPECTED = "I'd clearly ask them to put the phone away for the meal."

LATER_REVIEW_FILES = [
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


def load_structural_snapshot() -> dict[str, dict]:
    pool = json.loads(TR_POOL.read_text(encoding="utf-8"))
    snap: dict[str, dict] = {}
    for iid in STRUCTURAL_GUARD_IDS:
        item = next(it for it in pool["items"] if it["item_id"] == iid)
        snap[iid] = {
            "primary_dimensions": item["primary_dimensions"],
            "semantic_cluster": item["semantic_cluster"],
        }
    return snap


def assert_structural_snapshot_unchanged(before: dict[str, dict]) -> None:
    pool = json.loads(TR_POOL.read_text(encoding="utf-8"))
    for iid, expected in before.items():
        item = next(it for it in pool["items"] if it["item_id"] == iid)
        if item["primary_dimensions"] != expected["primary_dimensions"]:
            raise SystemExit(f"{iid} primary_dimensions changed unexpectedly")
        if item["semantic_cluster"] != expected["semantic_cluster"]:
            raise SystemExit(f"{iid} semantic_cluster changed unexpectedly")


def patch_phase1g_doc() -> None:
    text = PHASE1G_DOC.read_text(encoding="utf-8")
    if TR_OPTION_A_OLD not in text:
        if TR_OPTION_A_NEW in text:
            return
        raise SystemExit("q0353 option a not found in Phase 1G rewrite doc")
    PHASE1G_DOC.write_text(text.replace(TR_OPTION_A_OLD, TR_OPTION_A_NEW), encoding="utf-8")


def patch_evidence_option_text(path: Path) -> None:
    text = path.read_text(encoding="utf-8")
    if TR_OPTION_A_OLD not in text:
        if TR_OPTION_A_NEW in text:
            return
        raise SystemExit(f"q0353 option a not found in {path.name}")
    path.write_text(text.replace(TR_OPTION_A_OLD, TR_OPTION_A_NEW), encoding="utf-8")


def patch_proposal_hashes() -> None:
    proposal_hash = hashlib.sha256(PHASE2B_PROPOSAL.read_bytes()).hexdigest()
    triage = json.loads(PHASE2C_TRIAGE.read_text(encoding="utf-8"))
    triage["proposal_file_sha256_before"] = proposal_hash
    PHASE2C_TRIAGE.write_text(json.dumps(triage, ensure_ascii=False, indent=2), encoding="utf-8")
    revised = json.loads(PHASE2E_REVISED.read_text(encoding="utf-8"))
    revised["source_phase2b_proposal_sha256"] = proposal_hash
    PHASE2E_REVISED.write_text(json.dumps(revised, ensure_ascii=False, indent=2), encoding="utf-8")


def patch_tr_pool() -> dict:
    pool = json.loads(TR_POOL.read_text(encoding="utf-8"))
    item = next(it for it in pool["items"] if it["item_id"] == ITEM_ID)
    prompt_before = item["prompt"]
    options_before = {
        o["option_id"]: o["text"] for o in item["options"] if o["option_id"] != OPTION_A_ID
    }
    opt_a = next(o for o in item["options"] if o["option_id"] == OPTION_A_ID)
    opt_a["text"] = TR_OPTION_A_NEW
    TR_POOL.write_text(json.dumps(pool, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"prompt": prompt_before, "options": options_before}


def patch_tr_manifest() -> None:
    manifest = json.loads(TR_MANIFEST.read_text(encoding="utf-8"))
    row = next(it for it in manifest if it["item_id"] == ITEM_ID)
    opt_a = next(o for o in row["options"] if o["option_id"] == OPTION_A_ID)
    opt_a["text"] = TR_OPTION_A_NEW
    TR_MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def patch_batch_008() -> dict:
    batch = json.loads(BATCH_008.read_text(encoding="utf-8"))
    item = batch["items"][ITEM_ID]
    prompt_before = item["prompt"]
    options_before = dict(item["options"])
    item["translation_review_status"] = "REVIEWED"
    BATCH_008.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")
    return {"prompt": prompt_before, "options": options_before}


def main() -> None:
    structural_before = load_structural_snapshot()
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    tr_before = patch_tr_pool()
    patch_tr_manifest()
    patch_phase1g_doc()
    patch_evidence_option_text(PHASE2B_PROPOSAL)
    patch_evidence_option_text(PHASE2E_REVISED)
    patch_evidence_option_text(PHASE2F_FINAL)
    patch_proposal_hashes()
    en_before = patch_batch_008()

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()
    assert_structural_snapshot_unchanged(structural_before)

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

    assert tr_item["prompt"] == tr_before["prompt"]
    assert en_item["prompt"] == en_before["prompt"]
    for opt in tr_item["options"]:
        if opt["option_id"] == OPTION_A_ID:
            assert opt["text"] == TR_OPTION_A_NEW
        else:
            assert opt["text"] == tr_before["options"][opt["option_id"]]
    for opt in en_item["options"]:
        assert opt["text"] == en_before["options"][opt["option_id"]]
    en_a = next(o for o in en_item["options"] if o["option_id"] == OPTION_A_ID)
    assert en_a["text"] == EN_OPTION_A_EXPECTED
    assert rev[ITEM_ID]["translation_review_status"] == "REVIEWED"

    q380 = next(it for it in tr_pool["items"] if it["item_id"] == "frequency_v2_q0380")
    assert q380["primary_dimensions"] == []
    assert q380["semantic_cluster"] == "unassigned:social"

    for i in range(1, 401):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(401, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    review_md = REVIEW_351_400.read_text(encoding="utf-8")
    if "SOURCE_TR_ISSUE" in review_md:
        raise SystemExit("SOURCE_TR_ISSUE marker still present in review markdown")

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 400

    print("Phase 6I.1 q0353 source fix applied successfully.")
    print("TR option a updated; EN unchanged.")
    print("q0353 marked REVIEWED; SOURCE_TR_ISSUE marker removed.")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
