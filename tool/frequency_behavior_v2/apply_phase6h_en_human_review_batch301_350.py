#!/usr/bin/env python3
"""Apply Phase 6H human EN semantic review for batch 301-350.

English user-facing wording and translation_review_status only.
Preserves later en_human_review markdown batches from HEAD after rebuild.
q0341: SOURCE_TR_ISSUE — TR/EN unchanged, stays PENDING_HUMAN_REVIEW.
Preserves q0227 / q0260 cultural metadata from prior phases.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
BATCH_007 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_007.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_301_350 = OUT / "en_human_review/frequency_v2_en_review_301_350.md"
SOURCE_TR_ISSUE_ID = "frequency_v2_q0341"
Q0227_ID = "frequency_v2_q0227"
Q0260_ID = "frequency_v2_q0260"
Q0227_FLAGS = ["possible_cultural_mismatch"]
Q0260_FLAGS = ["possible_cultural_mismatch", "possible_intensity_drift"]

REVIEWED_IDS = [
    f"frequency_v2_q{i:04d}" for i in range(301, 351) if i != 341
]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0301": {
        "options": {
            "frequency_v2_q0301_d": (
                "I'd rather spend the whole evening together than be alone that night."
            ),
        },
    },
    "frequency_v2_q0303": {
        "prompt": "While living together, you have different standards of cleanliness.",
        "options": {
            "frequency_v2_q0303_c": "I'd move closer to their standard.",
        },
    },
    "frequency_v2_q0304": {
        "prompt": (
            "Your partner unexpectedly shows up to see you. "
            "You wanted to be alone at that moment."
        ),
    },
    "frequency_v2_q0305": {
        "options": {
            "frequency_v2_q0305_a": "I'd start bringing them small gifts too.",
            "frequency_v2_q0305_d": (
                "If the pace started to feel too fast, I'd slow down the gift-giving."
            ),
        },
    },
    "frequency_v2_q0306": {
        "options": {
            "frequency_v2_q0306_b": "I'd turn cold too.",
            "frequency_v2_q0306_c": "I'd try to bring the emotions into the open.",
            "frequency_v2_q0306_d": "I'd postpone the conversation and change the setting.",
        },
    },
    "frequency_v2_q0308": {
        "prompt": (
            "You're getting to know someone new. Very early on, they start saying things like, "
            "\"I feel like you're special.\""
        ),
        "options": {
            "frequency_v2_q0308_c": "I'd say, \"Let's slow things down a little.\"",
            "frequency_v2_q0308_d": "If the intensity increased, I'd pull back.",
        },
    },
    "frequency_v2_q0309": {
        "options": {
            "frequency_v2_q0309_d": "I'd say, \"You plan it, I'll go along.\"",
        },
    },
    "frequency_v2_q0312": {
        "prompt": (
            "You've been seeing someone new for a few weeks. "
            "You haven't started spending time in a shared friend group yet."
        ),
        "options": {
            "frequency_v2_q0312_a": "I'd be the one to suggest it.",
            "frequency_v2_q0312_b": "If they suggested it, I'd join.",
            "frequency_v2_q0312_c": "I'd wait a little longer.",
        },
    },
    "frequency_v2_q0313": {
        "prompt": (
            "Your partner wants to bring up something personal about you—your financial situation, "
            "a family problem, or your health—but you don't feel close enough yet."
        ),
        "options": {
            "frequency_v2_q0313_c": "I'd say, \"We can talk about it when I'm ready.\"",
        },
    },
    "frequency_v2_q0316": {
        "prompt": (
            "You're getting to know someone new. They want each date to last longer than the last."
        ),
        "options": {
            "frequency_v2_q0316_b": "I'd stick to my own time limit.",
            "frequency_v2_q0316_d": (
                "If the pace started getting faster, I'd reduce how often we met."
            ),
        },
    },
    "frequency_v2_q0317": {
        "options": {
            "frequency_v2_q0317_a": (
                "I'd send a message soon saying that, when they're ready, "
                "I'd like us to talk and sort things out."
            ),
            "frequency_v2_q0317_b": (
                "I'd give them a little time, then bring the conversation up again later that same day."
            ),
            "frequency_v2_q0317_d": (
                "If my partner didn't bring it up again, I wouldn't either."
            ),
        },
    },
    "frequency_v2_q0318": {
        "prompt": (
            "Your partner can't decide whether to stay home or go out; "
            "they keep wanting both at once."
        ),
    },
    "frequency_v2_q0320": {
        "options": {
            "frequency_v2_q0320_c": "I'd say, \"Can we slow down on the introductions a little?\"",
            "frequency_v2_q0320_d": "After a while, I'd step away for a bit.",
        },
    },
    "frequency_v2_q0322": {
        "prompt": (
            "After a long separation, you're back together. "
            "Your partner wants to return to your previous level of closeness right away."
        ),
        "options": {
            "frequency_v2_q0322_a": "I'd reciprocate.",
            "frequency_v2_q0322_b": "I'd ease back into the closeness gradually.",
            "frequency_v2_q0322_d": "I'd clearly stick to my own pace.",
        },
    },
    "frequency_v2_q0323": {
        "options": {
            "frequency_v2_q0323_d": "I'd push for us to make a decision.",
        },
    },
    "frequency_v2_q0324": {
        "prompt": (
            "Your partner gently criticizes something about you, "
            "such as your communication style or time management."
        ),
    },
    "frequency_v2_q0325": {
        "prompt": (
            "After a few dates, the person you're seeing says, "
            "\"I'm looking for a serious relationship.\" You're not that sure yet."
        ),
        "options": {
            "frequency_v2_q0325_c": "I'd say, \"Let's see what happens over time.\"",
        },
    },
    "frequency_v2_q0327": {
        "prompt": "Your partner keeps asking questions about one of your exes.",
    },
    "frequency_v2_q0328": {
        "options": {
            "frequency_v2_q0328_c": "I'd just say a quick \"okay\" and go back to what I was doing.",
        },
    },
    "frequency_v2_q0330": {
        "prompt": (
            "For the first time, your partner openly expresses a positive feeling toward you, "
            "such as missing you or feeling attached."
        ),
        "options": {
            "frequency_v2_q0330_a": "I'd respond in kind.",
        },
    },
    "frequency_v2_q0331": {
        "options": {
            "frequency_v2_q0331_a": "I'd look for a middle ground.",
        },
    },
    "frequency_v2_q0332": {
        "options": {
            "frequency_v2_q0332_a": "I'd cancel my existing plans and go.",
        },
    },
    "frequency_v2_q0333": {
        "prompt": (
            "While texting someone new, they write very long messages, "
            "while you prefer to keep yours short and to the point."
        ),
    },
    "frequency_v2_q0334": {
        "options": {
            "frequency_v2_q0334_a": "I'd understand and keep doing the hobby on my own.",
            "frequency_v2_q0334_c": "I'd also choose not to join some of the things they do.",
        },
    },
    "frequency_v2_q0335": {
        "prompt": (
            "When choosing a movie together, you keep disagreeing about which genre to watch."
        ),
    },
    "frequency_v2_q0336": {
        "options": {
            "frequency_v2_q0336_c": "I'd wait for them to make themselves clear.",
        },
    },
    "frequency_v2_q0337": {
        "options": {
            "frequency_v2_q0337_a": "I'd carry on as normal.",
            "frequency_v2_q0337_d": "I'd be happy and pick up the pace again.",
        },
    },
    "frequency_v2_q0339": {
        "prompt": (
            "After a few dates, the person you're seeing starts increasing the pace of physical contact."
        ),
        "options": {
            "frequency_v2_q0339_a": "I'd adapt to their pace.",
            "frequency_v2_q0339_c": "I'd say, \"Let's slow down a little.\"",
            "frequency_v2_q0339_d": (
                "If the pace didn't feel right for me, I'd pull back."
            ),
        },
    },
    "frequency_v2_q0342": {
        "prompt": (
            "You had plans. At the last minute, your partner says, \"I'm just not feeling it.\""
        ),
        "options": {
            "frequency_v2_q0342_b": "I'd be a little disappointed.",
        },
    },
    "frequency_v2_q0343": {
        "prompt": (
            "Your partner reacts less strongly than you expected to one of your achievements "
            "or moments of happiness."
        ),
    },
    "frequency_v2_q0344": {
        "options": {
            "frequency_v2_q0344_a": (
                "I'd call the waiter over on their behalf and politely ask for the dish to be replaced."
            ),
            "frequency_v2_q0344_b": (
                "I'd ask a few times, \"Are you sure? We can send it back,\" "
                "but if they didn't want to, I wouldn't push."
            ),
            "frequency_v2_q0344_d": (
                "On the way out, I'd say, \"Next time, let's say something; "
                "it's hard for me to just let it go like that.\""
            ),
        },
    },
    "frequency_v2_q0346": {
        "prompt": (
            "You're on vacation in an unfamiliar city. Your partner takes charge of navigation "
            "but leads you completely the wrong way and gets you lost."
        ),
        "options": {
            "frequency_v2_q0346_c": (
                "I'd quietly open the map on my own phone and give them little hints toward "
                "the right route without making it obvious."
            ),
        },
    },
    "frequency_v2_q0347": {
        "options": {
            "frequency_v2_q0347_a": (
                "I'd say, \"I hope everything's okay,\" and immediately make another plan, "
                "either on my own or with friends."
            ),
            "frequency_v2_q0347_c": (
                "I'd ask, \"Is there anything I can do?\" and stay available to support them."
            ),
            "frequency_v2_q0347_d": (
                "I'd wait for them to arrange the next date to make up for the cancellation, "
                "leaving the initiative entirely to them."
            ),
        },
    },
    "frequency_v2_q0348": {
        "options": {
            "frequency_v2_q0348_b": (
                "Even though it's their own money, I'd feel really hurt that they didn't tell me "
                "beforehand because we're sharing a life together."
            ),
        },
    },
    "frequency_v2_q0349": {
        "options": {
            "frequency_v2_q0349_d": (
                "I'd suggest having a professional assemble it, or, if they really wanted to do it "
                "themselves, letting them build it alone while I just watched."
            ),
        },
    },
    "frequency_v2_q0350": {
        "prompt": (
            "By nature, your partner is very warm and playful and uses a lot of casual physical touch "
            "with everyone—waitstaff, people of the opposite sex, coworkers."
        ),
        "options": {
            "frequency_v2_q0350_b": (
                "I'd feel quietly uncomfortable that the special boundary—the sense of distance—"
                "between how they are with me and with other people isn't clearer."
            ),
            "frequency_v2_q0350_c": (
                "When we're out, I'd try to rein them in a little and get them to focus more on \"us.\""
            ),
            "frequency_v2_q0350_d": (
                "While they socialize, I'd mingle with other people in a similar way, independently of them."
            ),
        },
    },
}

LATER_REVIEW_FILES = [
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
        (5, 201, 250),
        (6, 251, 300),
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


def annotate_q0341_source_issue() -> None:
    text = REVIEW_301_350.read_text(encoding="utf-8")
    marker = f"## {SOURCE_TR_ISSUE_ID}"
    if marker not in text:
        raise SystemExit(f"missing {SOURCE_TR_ISSUE_ID} section in review markdown")
    if "SOURCE_TR_ISSUE" in text:
        return
    insert = (
        "\n- **human_review_decision:** `SOURCE_TR_ISSUE`\n"
        "- **human_review_note:** Turkish stem says the partner shared a secret about the user, "
        "but answer options imply the partner shared their own personal secret with the user. "
        "TR and EN text unchanged pending explicit source correction.\n"
        "- **recommended_source_correction_tr:** "
        "Partneriniz kendisiyle ilgili bir sırrı sizinle paylaştı ve \"kimseye söyleme\" dedi.\n"
        "- **recommended_source_correction_en:** "
        "Your partner shared a personal secret about themselves with you and said, "
        "\"Don't tell anyone.\"\n"
    )
    pattern = re.compile(
        rf"(## {re.escape(SOURCE_TR_ISSUE_ID)}\n\n"
        rf"- \*\*primary_dimension:\*\*[^\n]+\n"
        rf"- \*\*semantic_cluster:\*\*[^\n]+\n"
        rf"- \*\*translation_review_status:\*\* `PENDING_HUMAN_REVIEW`)"
    )
    updated, n = pattern.subn(r"\1" + insert, text, count=1)
    if n != 1:
        raise SystemExit("failed to annotate q0341 SOURCE_TR_ISSUE in review markdown")
    REVIEW_301_350.write_text(updated, encoding="utf-8")


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


def main() -> None:
    assert_prior_batches_unchanged()
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    batch = json.loads(BATCH_007.read_text(encoding="utf-8"))
    items = batch["items"]
    q0341_prompt_before = items[SOURCE_TR_ISSUE_ID]["prompt"]
    q0341_options_before = dict(items[SOURCE_TR_ISSUE_ID]["options"])

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 007: {iid}")
    if SOURCE_TR_ISSUE_ID not in items:
        raise SystemExit(f"Missing item in batch 007: {SOURCE_TR_ISSUE_ID}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    if items[SOURCE_TR_ISSUE_ID]["prompt"] != q0341_prompt_before:
        raise SystemExit("q0341 prompt changed unexpectedly")
    if items[SOURCE_TR_ISSUE_ID]["options"] != q0341_options_before:
        raise SystemExit("q0341 options changed unexpectedly")
    items[SOURCE_TR_ISSUE_ID]["translation_review_status"] = "PENDING_HUMAN_REVIEW"

    BATCH_007.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()
    annotate_q0341_source_issue()

    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    preserve_prior_flag_metadata(en_review)
    for row in en_review["items"]:
        if row["item_id"] == SOURCE_TR_ISSUE_ID:
            row["translation_review_status"] = "PENDING_HUMAN_REVIEW"
            break
    else:
        raise SystemExit("q0341 missing from EN review metadata")
    recompute_review_stats(en_review)
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    rev = {r["item_id"]: r for r in en_review["items"]}
    by_id = {it["item_id"]: it for it in en_pool["items"]}

    q313 = by_id["frequency_v2_q0313"]["prompt"]
    assert "personal about you" in q313
    assert "your financial situation" in q313
    q332 = by_id["frequency_v2_q0332"]
    q332a = next(o["text"] for o in q332["options"] if o["option_id"].endswith("_a"))
    assert q332a == "I'd cancel my existing plans and go."
    assert rev["frequency_v2_q0332"]["drop_from_selectable"] is True
    q341 = by_id[SOURCE_TR_ISSUE_ID]
    assert q341["prompt"] == q0341_prompt_before
    for opt in q341["options"]:
        assert opt["text"] == q0341_options_before[opt["option_id"]]
    assert rev[SOURCE_TR_ISSUE_ID]["translation_review_status"] == "PENDING_HUMAN_REVIEW"
    q350 = by_id["frequency_v2_q0350"]["prompt"]
    assert "touchy" not in q350.lower()
    assert "casual physical touch" in q350

    for i in range(1, 341):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    assert rev[SOURCE_TR_ISSUE_ID]["translation_review_status"] == "PENDING_HUMAN_REVIEW"
    for i in range(342, 351):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(351, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 349

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    assert "SOURCE_TR_ISSUE" in REVIEW_301_350.read_text(encoding="utf-8")
    assert len(PATCHES) == 36

    print("Phase 6H batch 301-350 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")
    print("q0341 SOURCE_TR_ISSUE left PENDING_HUMAN_REVIEW (TR/EN unchanged).")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
