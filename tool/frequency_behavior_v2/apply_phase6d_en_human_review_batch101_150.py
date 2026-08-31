#!/usr/bin/env python3
"""Apply Phase 6D human EN semantic review for batch 101-150.

English user-facing wording and translation_review_status only.
Does not modify TR pool, weights, evidence, or runtime flags.
Preserves en_human_review/frequency_v2_en_review_151_200.md byte-for-byte.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
BATCH_003 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_003.json"
BATCH_002 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_002.json"
BATCH_001 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_001.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_151_200 = OUT / "en_human_review/frequency_v2_en_review_151_200.md"

REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(101, 151)]
PRIOR_REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(1, 101)]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0101": {
        "prompt": "The second date went well. By noon the next day, you still haven't heard from them. Which behavior is closest to yours?",
        "options": {
            "frequency_v2_q0101_d": "I'd keep to my own routine for a few days and let contact resume naturally.",
        },
    },
    "frequency_v2_q0102": {
        "options": {
            "frequency_v2_q0102_c": "I don't change my own communication rhythm; I text when I think of them.",
        }
    },
    "frequency_v2_q0103": {
        "options": {
            "frequency_v2_q0103_b": "I listen carefully, but save sharing equally personal things about myself for later.",
            "frequency_v2_q0103_c": "I ask about what I'm curious about, but keep what I share about myself limited.",
        }
    },
    "frequency_v2_q0104": {
        "options": {
            "frequency_v2_q0104_a": "At some point, I'd bring it up and try to clarify where we're headed.",
            "frequency_v2_q0104_c": "I give myself a time frame and watch how things unfold until then.",
        }
    },
    "frequency_v2_q0105": {
        "prompt": "It's noon on Saturday and you still don't have a plan for the day together.",
        "options": {
            "frequency_v2_q0105_a": "I come up with two or three options and suggest we pick one.",
        }
    },
    "frequency_v2_q0106": {
        "prompt": "Someone you've been seeing for three weeks invites you to spend an evening with their close friends.",
        "options": {
            "frequency_v2_q0106_a": "I'd be happy to go; I like meeting the people close to them early on.",
            "frequency_v2_q0106_d": "I'd suggest a smaller get-together with just a few people instead of a crowd.",
        }
    },
    "frequency_v2_q0107": {
        "prompt": "You were thinking of spending the weekend together, but your partner says, \"I need some alone time this weekend.\"",
        "options": {
            "frequency_v2_q0107_a": "I'd make my own plans; needing that space feels natural to me.",
            "frequency_v2_q0107_d": "If they wanted, I'd suggest being in the same place while each of us does our own thing.",
        }
    },
    "frequency_v2_q0109": {
        "prompt": "You get a midday message: \"I need to talk to you about something tonight,\" and then they get busy.",
        "options": {
            "frequency_v2_q0109_a": "I ask for a quick hint about what it's about.",
        }
    },
    "frequency_v2_q0110": {
        "prompt": "At an earlier stage than you expected, they openly tell you they miss you and really like you.",
        "options": {
            "frequency_v2_q0110_d": "I'd be curious what those words mean to them and talk about it a little.",
        }
    },
    "frequency_v2_q0111": {
        "options": {
            "frequency_v2_q0111_a": "That feels great to me; I'd leave the whole day open.",
            "frequency_v2_q0111_c": "I'd take care of a few things on my own first, then join them and go with the flow.",
            "frequency_v2_q0111_d": "I'm happy to go with whatever they're in the mood for that day.",
        }
    },
    "frequency_v2_q0112": {
        "options": {
            "frequency_v2_q0112_a": "I'd pick another day, then get on with my evening.",
            "frequency_v2_q0112_c": "I'd be okay with it, but I'd want to agree on a new date right away.",
            "frequency_v2_q0112_d": "I wouldn't make a big deal of it; I'd wait for them to make the next plan.",
        }
    },
    "frequency_v2_q0113": {
        "options": {
            "frequency_v2_q0113_a": "I'd stick with my own plan and not join them this time.",
            "frequency_v2_q0113_b": "I'd join them briefly, then go back to what I'd planned.",
            "frequency_v2_q0113_c": "I'd change most of my plans and reorganize my evening around the guests.",
        }
    },
    "frequency_v2_q0114": {
        "prompt": "You're planning a trip of a few days together.",
        "options": {
            "frequency_v2_q0114_b": "I'd want the overall framework set, but let most of the days take shape once we're there.",
        }
    },
    "frequency_v2_q0115": {
        "prompt": "You've started spending long stretches of time together. You're an early bird; your partner is a night owl.",
        "options": {
            "frequency_v2_q0115_a": "We each keep our own schedule; I wouldn't change my sleep pattern just to sync up.",
            "frequency_v2_q0115_c": "I'd adjust my schedule quite a bit so we can spend more time together.",
            "frequency_v2_q0115_d": "We'd keep our own schedules, but create a small shared ritual before bed or after waking up.",
        }
    },
    "frequency_v2_q0116": {
        "prompt": "Your partner wants to join a hobby you've enjoyed doing on your own for years.",
        "options": {
            "frequency_v2_q0116_a": "I'd be happy about it; fully sharing this part of my life could strengthen our bond.",
            "frequency_v2_q0116_c": "I'd clearly say I'd prefer to keep this hobby as my personal space.",
        }
    },
    "frequency_v2_q0117": {
        "prompt": "After a month packed with social interaction, you finally have a completely free Sunday.",
        "options": {
            "frequency_v2_q0117_c": "Going out with my partner and close friends would feel better to me.",
            "frequency_v2_q0117_d": "Ideally, I'd spend part of the day alone and the rest with my partner.",
        }
    },
    "frequency_v2_q0119": {
        "prompt": "Your partner doesn't want to join you when you spend time with a friend group or do a hobby you really love.",
        "options": {
            "frequency_v2_q0119_c": "I might spend less time in that setting to make them more comfortable.",
            "frequency_v2_q0119_d": "I'd try to find something new that we'd both enjoy doing together.",
        }
    },
    "frequency_v2_q0120": {
        "options": {
            "frequency_v2_q0120_a": "I'd keep my own routine and try to make long distance work.",
            "frequency_v2_q0120_b": "If the circumstances made sense, I'd be genuinely open to moving with them.",
        }
    },
    "frequency_v2_q0122": {
        "prompt": "During an argument, they noticeably raise their voice.",
        "options": {
            "frequency_v2_q0122_a": "I'd keep speaking in a firmer, clearer tone too.",
            "frequency_v2_q0122_c": "I'd rather keep working through it right then so the issue isn't left unresolved.",
        }
    },
    "frequency_v2_q0124": {
        "options": {
            "frequency_v2_q0124_d": "I'd assess how fundamental this incompatibility is for me.",
        }
    },
    "frequency_v2_q0125": {
        "options": {
            "frequency_v2_q0125_a": "I'd bring it up again the same day; letting it sit unresolved bothers me more.",
            "frequency_v2_q0125_b": "I'd set a time to talk calmly the next day.",
            "frequency_v2_q0125_c": "If things go back to normal between us, I can let it go without another conversation.",
        }
    },
    "frequency_v2_q0126": {
        "prompt": "It's clear your partner is upset, but they say, \"Nothing's wrong, I'm fine.\"",
        "options": {
            "frequency_v2_q0126_d": "Having an unspoken issue between us bothers me, so I'd check in a little more.",
        }
    },
    "frequency_v2_q0127": {
        "options": {
            "frequency_v2_q0127_b": "I'd break the problem down and think through possible solutions together.",
        }
    },
    "frequency_v2_q0129": {
        "prompt": "Your partner forgot to do something important for you, and it cost you time.",
    },
    "frequency_v2_q0130": {
        "prompt": "You realize that you see an important issue in life very differently.",
    },
    "frequency_v2_q0131": {
        "prompt": "In a long-term relationship, which view on phones and digital privacy feels closest to you?",
        "options": {
            "frequency_v2_q0131_b": "Passwords are part of my personal space; I'd rather not share them.",
            "frequency_v2_q0131_d": "I feel more comfortable when our digital lives are mostly open to each other.",
        }
    },
    "frequency_v2_q0132": {
        "prompt": "You notice your partner interacting again on social media with someone they used to date; there's no obvious problem.",
        "options": {
            "frequency_v2_q0132_d": "I'd think about where my boundaries are around online interactions and talk about it later.",
        }
    },
    "frequency_v2_q0134": {
        "options": {
            "frequency_v2_q0134_a": "I'd want at least a small, regular point of contact during the day.",
            "frequency_v2_q0134_b": "I'd focus more on my own life and try to live with the difference.",
            "frequency_v2_q0134_d": "If it keeps feeling one-sided, I'd reduce how much I invest in the relationship.",
        }
    },
    "frequency_v2_q0136": {
        "prompt": "When would it feel most natural to share a major regret from your past with a new partner?",
        "options": {
            "frequency_v2_q0136_d": "Only if it comes up naturally and doesn't affect the current relationship.",
        }
    },
    "frequency_v2_q0137": {
        "prompt": "Someone you're still in the early stages with tells you something very personal and heavy.",
        "options": {
            "frequency_v2_q0137_b": "I'd listen and stay present, but keep my own pace of opening up.",
            "frequency_v2_q0137_d": "I'd focus more on understanding what it means to them.",
        }
    },
    "frequency_v2_q0138": {
        "options": {
            "frequency_v2_q0138_d": "I'd mostly let the timing follow how things naturally unfold in their life.",
        }
    },
    "frequency_v2_q0139": {
        "options": {
            "frequency_v2_q0139_b": "I'd accept it, but say that moving this fast makes me uncomfortable.",
            "frequency_v2_q0139_d": "I don't read too much into what the gift says about the relationship; I'd enjoy the moment.",
        }
    },
    "frequency_v2_q0141": {
        "prompt": "Your partner goes on a busy week-long work trip in a different time zone.",
        "options": {
            "frequency_v2_q0141_c": "I'd mostly let their workload determine how much we communicate.",
            "frequency_v2_q0141_d": "I'd focus more on my own life that week and reconnect more deeply when they're back.",
        }
    },
    "frequency_v2_q0142": {
        "options": {
            "frequency_v2_q0142_c": "Being in separate rooms and getting on with our own things feels completely natural to me.",
        }
    },
    "frequency_v2_q0143": {
        "options": {
            "frequency_v2_q0143_a": "I'd listen to what they're noticing and factor it into my own judgment.",
            "frequency_v2_q0143_b": "I'd keep my friendships and relationship separate and continue both.",
            "frequency_v2_q0143_c": "I'd create a few more shared situations where they can spend time together under different circumstances.",
        }
    },
    "frequency_v2_q0145": {
        "options": {
            "frequency_v2_q0145_c": "If the rest of the relationship is good, I don't attach too much meaning to one date.",
        }
    },
    "frequency_v2_q0146": {
        "options": {
            "frequency_v2_q0146_d": "I like some periods to be routine and others to be more active.",
        }
    },
    "frequency_v2_q0147": {
        "options": {
            "frequency_v2_q0147_c": "I'd give them space, but want a small routine of contact so we don't completely disconnect.",
            "frequency_v2_q0147_d": "I'd give myself more space too and see how the relationship settles into a new rhythm.",
        }
    },
    "frequency_v2_q0148": {
        "options": {
            "frequency_v2_q0148_a": "I'd try spending noticeably more time together.",
            "frequency_v2_q0148_b": "I'd ask what \"more closeness\" actually means to them in practice.",
        }
    },
    "frequency_v2_q0149": {
        "options": {
            "frequency_v2_q0149_a": "Talking through the big milestones and rough timing together feels good to me.",
            "frequency_v2_q0149_c": "I'd keep my own career and life plans clear first, and let the relationship take shape alongside them.",
        }
    },
    "frequency_v2_q0150": {
        "prompt": "Someone new you're seeing is moving noticeably faster and is much clearer about what they want from the relationship than you are.",
        "options": {
            "frequency_v2_q0150_c": "I'd talk about the difference and look for a pace that feels comfortable for both of us.",
            "frequency_v2_q0150_d": "If the difference in pace keeps being noticeable, I'd pull back a little.",
        }
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
    for path, lo, hi in [
        (BATCH_001, 1, 50),
        (BATCH_002, 51, 100),
    ]:
        batch = json.loads(path.read_text(encoding="utf-8"))
        for i in range(lo, hi + 1):
            iid = f"frequency_v2_q{i:04d}"
            if batch["items"][iid].get("translation_review_status") != "REVIEWED":
                raise SystemExit(f"{path.name} item not REVIEWED: {iid}")


def head_bytes_for_review_151_200() -> bytes:
    rel = REVIEW_151_200.relative_to(ROOT)
    return subprocess.check_output(["git", "-C", str(ROOT), "show", f"HEAD:{rel}"])


def restore_review_151_200(head_bytes: bytes) -> None:
    REVIEW_151_200.write_bytes(head_bytes)
    if REVIEW_151_200.read_bytes() != head_bytes:
        raise SystemExit("failed to restore review_151_200 byte-for-byte")


def main() -> None:
    assert_prior_batches_unchanged()
    review_151_head = head_bytes_for_review_151_200()

    batch = json.loads(BATCH_003.read_text(encoding="utf-8"))
    items = batch["items"]

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 003: {iid}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    BATCH_003.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_review_151_200(review_151_head)

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    en_review = json.loads(
        (OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json").read_text()
    )
    by_id = {it["item_id"]: it for it in en_pool["items"]}
    rev = {r["item_id"]: r for r in en_review["items"]}

    q101 = by_id["frequency_v2_q0101"]["prompt"]
    assert "By noon the next day, you still haven't heard from them." in q101
    assert "didn't hear from them until noon" not in q101
    assert "It's noon on Saturday" in by_id["frequency_v2_q0105"]["prompt"]
    assert "At an earlier stage than you expected" in by_id["frequency_v2_q0110"]["prompt"]
    q115 = by_id["frequency_v2_q0115"]["prompt"]
    assert "spending long stretches of time together" in q115
    assert "living together" not in q115.lower()
    assert "forgot to do something important for you" in by_id["frequency_v2_q0129"]["prompt"]
    q132 = by_id["frequency_v2_q0132"]["prompt"]
    assert "someone they used to date" in q132
    assert "old flame" not in q132.lower()
    q141 = by_id["frequency_v2_q0141"]["prompt"].lower()
    assert "abroad" not in q141
    assert "big time difference" not in q141
    assert "much clearer about what they want from the relationship" in by_id["frequency_v2_q0150"]["prompt"]

    for i in range(1, 151):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(151, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    print("Phase 6D batch 101-150 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")
    print("Preserved frequency_v2_en_review_151_200.md byte-for-byte.")


if __name__ == "__main__":
    main()
