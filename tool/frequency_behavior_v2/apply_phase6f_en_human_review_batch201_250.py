#!/usr/bin/env python3
"""Apply Phase 6F human EN semantic review for batch 201-250.

English user-facing wording and translation_review_status only.
Preserves later en_human_review markdown batches from HEAD after rebuild.
q0227: REVIEWED with possible_cultural_mismatch flag preserved.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
BATCH_005 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_005.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
Q0227_ID = "frequency_v2_q0227"

REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(201, 251)]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0201": {
        "options": {
            "frequency_v2_q0201_b": "We each keep to our own schedule.",
        },
    },
    "frequency_v2_q0202": {
        "options": {
            "frequency_v2_q0202_a": "I'd get them something in return on our next date.",
            "frequency_v2_q0202_c": "I'd get them something small right away to even things out.",
            "frequency_v2_q0202_d": "I generally prefer to take gift-giving slowly.",
        },
    },
    "frequency_v2_q0204": {
        "options": {
            "frequency_v2_q0204_a": 'I\'d gently remind them, "Can we watch this together?"',
            "frequency_v2_q0204_b": "I'd go back to doing my own thing.",
            "frequency_v2_q0204_d": "I'd keep watching and not let it bother me.",
        },
    },
    "frequency_v2_q0205": {
        "prompt": (
            "In the first few months, your partner often calls or texts to say they miss you. "
            "You prefer a slower pace."
        ),
        "options": {
            "frequency_v2_q0205_a": "I'd start using the same kind of language.",
            "frequency_v2_q0205_d": "If it became more intense, I'd pull back.",
        },
    },
    "frequency_v2_q0207": {
        "options": {
            "frequency_v2_q0207_b": "I'd be fine with them coming.",
            "frequency_v2_q0207_d": "I'd rather it be a surprise.",
        },
    },
    "frequency_v2_q0208": {
        "options": {
            "frequency_v2_q0208_b": "I'd let them pay.",
            "frequency_v2_q0208_c": 'I\'d say, "You get this one; I\'ll get the next."',
        },
    },
    "frequency_v2_q0209": {
        "options": {
            "frequency_v2_q0209_d": "I'd carry on as usual without giving it much thought.",
        },
    },
    "frequency_v2_q0210": {
        "options": {
            "frequency_v2_q0210_d": (
                "If physical touch takes longer to happen, I'd stay emotionally distant too."
            ),
        },
    },
    "frequency_v2_q0213": {
        "options": {
            "frequency_v2_q0213_c": (
                "I'd say I'd rather keep seeing each other a little longer before meeting them."
            ),
        },
    },
    "frequency_v2_q0218": {
        "options": {
            "frequency_v2_q0218_a": "I'd start the conversation right away.",
        },
    },
    "frequency_v2_q0219": {
        "options": {
            "frequency_v2_q0219_a": "I'd understand and keep doing it on my own.",
        },
    },
    "frequency_v2_q0222": {
        "options": {
            "frequency_v2_q0222_a": "I'd adjust how close I am with that friend.",
            "frequency_v2_q0222_c": "I'd suggest the three of us spend time together.",
        },
    },
    "frequency_v2_q0223": {
        "prompt": (
            "You're getting to know someone new. They like to plan things carefully; "
            "you're more spontaneous."
        ),
        "options": {
            "frequency_v2_q0223_d": "I'd try to find a middle ground.",
        },
    },
    "frequency_v2_q0224": {
        "options": {
            "frequency_v2_q0224_c": "I'd send a brief message to let them know I'm there for them.",
        },
    },
    "frequency_v2_q0225": {
        "prompt": (
            "For the first time, your partner openly expresses feelings like love, attachment, "
            "or imagining a future together."
        ),
    },
    "frequency_v2_q0228": {
        "options": {
            "frequency_v2_q0228_c": 'I\'d say, "I tend to keep my messages short."',
        },
    },
    "frequency_v2_q0229": {
        "prompt": (
            "You disagree about something. Your partner thinks they're right, "
            "and you're insisting on your own view."
        ),
    },
    "frequency_v2_q0232": {
        "prompt": (
            'After a few dates, the person you\'re seeing says, "I\'m starting to see this as serious." '
            "You're not there yet."
        ),
    },
    "frequency_v2_q0236": {
        "prompt": (
            "You're getting to know someone new. They're very touch-oriented—linking arms, "
            "touching your shoulder—while you prefer more physical distance."
        ),
    },
    "frequency_v2_q0237": {
        "options": {
            "frequency_v2_q0237_b": "I'd be a little disappointed.",
        },
    },
    "frequency_v2_q0238": {
        "prompt": (
            "Your partner wants to bring up a topic like money, the future, or children, "
            "but you're not ready yet."
        ),
    },
    "frequency_v2_q0240": {
        "prompt": "When your partner asks you something about one of your exes.",
        "options": {
            "frequency_v2_q0240_b": "I'd give them the broad outline.",
        },
    },
    "frequency_v2_q0241": {
        "options": {
            "frequency_v2_q0241_a": "I'd start telling my friends about them too.",
        },
    },
    "frequency_v2_q0246": {
        "prompt": (
            "When choosing a movie or series together, you keep disagreeing about which genre to watch."
        ),
    },
    "frequency_v2_q0248": {
        "prompt": (
            "You're getting to know someone new. They're very clear about what they want, "
            "while you're still figuring things out."
        ),
        "options": {
            "frequency_v2_q0248_a": "I'd try to get clearer about what I want too.",
        },
    },
    "frequency_v2_q0249": {
        "prompt": "Your partner apologized for something, but you're still uncomfortable.",
    },
}

LATER_REVIEW_FILES = [
    "frequency_v2_en_review_251_300.md",
    "frequency_v2_en_review_301_350.md",
    "frequency_v2_en_review_351_400.md",
    "frequency_v2_en_review_401_426.md",
]


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
    ]:
        path = batch_dir / f"frequency_v2_en_semantic_text_batch_{batch_no:03d}.json"
        batch = json.loads(path.read_text(encoding="utf-8"))
        for i in range(lo, hi + 1):
            iid = f"frequency_v2_q{i:04d}"
            if batch["items"][iid].get("translation_review_status") != "REVIEWED":
                raise SystemExit(f"{path.name} item not REVIEWED: {iid}")


def head_bytes_for_review(rel_path: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(ROOT), "show", f"HEAD:{rel_path}"])


def restore_later_review_files() -> None:
    rel_dir = "tool/frequency_behavior_v2/out/en_human_review"
    for name in LATER_REVIEW_FILES:
        path = OUT / "en_human_review" / name
        path.write_bytes(head_bytes_for_review(f"{rel_dir}/{name}"))


def preserve_q0227_cultural_metadata(en_review: dict) -> None:
    for row in en_review["items"]:
        if row["item_id"] != Q0227_ID:
            continue
        row["translation_review_status"] = "REVIEWED"
        flags = list(row.get("translation_review_flags") or [])
        if "possible_cultural_mismatch" not in flags:
            flags.append("possible_cultural_mismatch")
        row["translation_review_flags"] = flags
        return
    raise SystemExit("q0227 missing from EN review metadata")


def recompute_review_stats(en_review: dict) -> None:
    from collections import Counter

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


def main() -> None:
    assert_prior_batches_unchanged()
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }
    q0227_en_before = json.loads(BATCH_005.read_text(encoding="utf-8"))["items"][Q0227_ID]

    batch = json.loads(BATCH_005.read_text(encoding="utf-8"))
    items = batch["items"]

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 005: {iid}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    if items[Q0227_ID]["prompt"] != q0227_en_before["prompt"]:
        raise SystemExit("q0227 EN text changed unexpectedly")
    if items[Q0227_ID]["options"] != q0227_en_before["options"]:
        raise SystemExit("q0227 EN options changed unexpectedly")
    items[Q0227_ID]["translation_review_flags"] = ["possible_cultural_mismatch"]

    BATCH_005.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()

    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    preserve_q0227_cultural_metadata(en_review)
    recompute_review_stats(en_review)
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    rev = {r["item_id"]: r for r in en_review["items"]}
    by_id = {it["item_id"]: it for it in en_pool["items"]}

    q229 = by_id["frequency_v2_q0229"]["prompt"]
    assert (
        "Your partner thinks they're right, and you're insisting on your own view."
        in q229
    )
    assert "you think your partner is right" not in q229.lower()
    q236 = by_id["frequency_v2_q0236"]["prompt"]
    assert "very touch-oriented" in q236
    assert "very touchy" not in q236.lower()
    assert "They like to plan things carefully" in by_id["frequency_v2_q0223"]["prompt"]
    assert "imagining a future together" in by_id["frequency_v2_q0225"]["prompt"]
    q240b = next(
        o["text"] for o in by_id["frequency_v2_q0240"]["options"] if o["option_id"].endswith("_b")
    )
    assert q240b == "I'd give them the broad outline."
    assert "still figuring things out" in by_id["frequency_v2_q0248"]["prompt"]
    assert "open up right away" not in by_id["frequency_v2_q0218"]["options"][0]["text"].lower()

    q227 = rev[Q0227_ID]
    assert q227["translation_review_status"] == "REVIEWED"
    assert "possible_cultural_mismatch" in (q227.get("translation_review_flags") or [])

    for i in range(1, 251):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(251, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 250

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    print("Phase 6F batch 201-250 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")
    print("q0227 REVIEWED with possible_cultural_mismatch preserved.")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
