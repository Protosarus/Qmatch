#!/usr/bin/env python3
"""Apply Phase 6I human EN semantic review for batch 351-400.

English user-facing wording and translation_review_status only.
Preserves later en_human_review markdown batches from HEAD after rebuild.
q0353: SOURCE_TR_ISSUE — TR/EN unchanged, stays PENDING_HUMAN_REVIEW.
Does not assign structural metadata for q0380.
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
BATCH_008 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_008.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_351_400 = OUT / "en_human_review/frequency_v2_en_review_351_400.md"
SOURCE_TR_ISSUE_ID = "frequency_v2_q0353"
Q0227_ID = "frequency_v2_q0227"
Q0260_ID = "frequency_v2_q0260"
Q0227_FLAGS = ["possible_cultural_mismatch"]
Q0260_FLAGS = ["possible_cultural_mismatch", "possible_intensity_drift"]
STRUCTURAL_GUARD_IDS = ("frequency_v2_q0380",)

REVIEWED_IDS = [
    f"frequency_v2_q{i:04d}" for i in range(351, 401) if i != 353
]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0351": {
        "prompt": (
            "You finish something—a meal, presentation, or drawing—and your partner gives you "
            "fairly constructive but critical feedback even though you didn't ask for their opinion."
        ),
        "options": {
            "frequency_v2_q0351_a": (
                "I'd think the criticism through logically and, if it was fair, "
                "gladly use it to improve."
            ),
            "frequency_v2_q0351_c": (
                "The criticism would take the wind out of my sails in the moment; "
                "my mood would drop and I'd become a little quieter with them."
            ),
        },
    },
    "frequency_v2_q0352": {
        "prompt": (
            "What do you think about combining profiles or sharing passwords on platforms "
            "like Netflix or Spotify?"
        ),
        "options": {
            "frequency_v2_q0352_a": (
                "I'd definitely want us to share; making joint lists and using the same account "
                "would strengthen our bond."
            ),
            "frequency_v2_q0352_b": (
                "We could have a shared account, but I'd prefer my personal recommendations "
                "and viewing or listening history to remain private."
            ),
        },
    },
    "frequency_v2_q0356": {
        "prompt": (
            "On the second day of a week-long beach vacation, you get severe sunstroke or "
            "food poisoning and have to stay in the room."
        ),
        "options": {
            "frequency_v2_q0356_d": (
                "My mood would sink and I'd feel guilty; because their enjoyment was affected too, "
                "I'd suggest ending the vacation altogether."
            ),
        },
    },
    "frequency_v2_q0359": {
        "options": {
            "frequency_v2_q0359_d": (
                "I'd give a loud \"Shhh!\" without addressing anyone directly, trying to solve "
                "the problem without creating a confrontation."
            ),
        },
    },
    "frequency_v2_q0360": {
        "prompt": (
            "You were only meeting for coffee, but your partner shows up with a large, "
            "meaningful gift even though it's not a special occasion."
        ),
        "options": {
            "frequency_v2_q0360_b": (
                "I'd be happy, but I'd feel a little indebted and say, "
                "\"I didn't get you anything—I feel awkward.\""
            ),
        },
    },
    "frequency_v2_q0361": {
        "options": {
            "frequency_v2_q0361_a": (
                "For the first few days, I'd simply be a source of emotional comfort, "
                "spoil them a little, and avoid bringing the issue up."
            ),
            "frequency_v2_q0361_c": (
                "I wouldn't panic. I'd work out how long our budget could carry us "
                "and make a practical plan."
            ),
        },
    },
    "frequency_v2_q0362": {
        "options": {
            "frequency_v2_q0362_d": (
                "I'd expect them to take my hand and slow me down so we could match "
                "each other's pace through physical contact."
            ),
        },
    },
    "frequency_v2_q0363": {
        "options": {
            "frequency_v2_q0363_b": (
                "It wouldn't bother me at all; I love meeting new people and having more "
                "people join the conversation."
            ),
        },
    },
    "frequency_v2_q0364": {
        "prompt": (
            "Your partner has small but recurring bouts of jealousy about the way you dress "
            "or your opposite-sex coworkers."
        ),
        "options": {
            "frequency_v2_q0364_c": (
                "I'd talk in depth about why they're jealous and try to ease their fears "
                "with reasonable reassurance."
            ),
            "frequency_v2_q0364_d": (
                "Deep down, I'd see their jealousy as proof that they love me a lot, "
                "and part of me would enjoy it."
            ),
        },
    },
    "frequency_v2_q0366": {
        "options": {
            "frequency_v2_q0366_a": (
                "I'd want the menu, table setup, and music planned days in advance "
                "and everything to be just right."
            ),
            "frequency_v2_q0366_b": (
                "I'd order the food, stock the fridge with drinks, and prefer a relaxed, "
                "somewhat chaotic atmosphere."
            ),
        },
    },
    "frequency_v2_q0367": {
        "prompt": (
            "We watch what I consider my all-time favorite masterpiece, and they say, "
            "\"That was the worst movie I've ever seen.\""
        ),
        "options": {
            "frequency_v2_q0367_a": (
                "I'd just say we have different tastes; what the film means to me wouldn't "
                "change because of their opinion."
            ),
            "frequency_v2_q0367_d": (
                "To avoid tension, I'd act as if I agreed by saying, \"Yeah, some parts were boring.\""
            ),
        },
    },
    "frequency_v2_q0369": {
        "prompt": (
            "Your partner says they want to switch to an artistic or freelance career they've "
            "dreamed about for years, such as becoming a musician, even though the income "
            "isn't guaranteed."
        ),
        "options": {
            "frequency_v2_q0369_b": (
                "The uncertainty would scare me a lot, so I'd say, \"Save some money first, "
                "then try it,\" and push them to take a more practical approach."
            ),
            "frequency_v2_q0369_c": (
                "It's their life and career; as long as it doesn't put me in serious financial "
                "trouble, I'd support whatever they choose."
            ),
            "frequency_v2_q0369_d": (
                "I'd understand their enthusiasm, but thinking it would lower our standard of "
                "living would make me pull back emotionally."
            ),
        },
    },
    "frequency_v2_q0370": {
        "prompt": (
            "At midnight, a number that isn't saved in your partner's contacts sends them "
            "a single message: \"Are you asleep?\""
        ),
        "options": {
            "frequency_v2_q0370_a": (
                "I'd wake them right away or ask first thing in the morning, \"Who is this?\" "
                "and expect a satisfying answer."
            ),
        },
    },
    "frequency_v2_q0372": {
        "prompt": (
            "There's someone in your partner's friend group who often makes the atmosphere tense. "
            "You're invited to the next group get-together. What do you do?"
        ),
    },
    "frequency_v2_q0373": {
        "options": {
            "frequency_v2_q0373_d": (
                "I'd say, \"It's only a movie—why did it affect you this much?\" and make it clear "
                "I don't really understand such an intense emotional reaction."
            ),
        },
    },
    "frequency_v2_q0374": {
        "options": {
            "frequency_v2_q0374_a": (
                "I'd say, \"Come on, we're basically one,\" and it wouldn't disgust me; "
                "I'd see it as a sign of our closeness."
            ),
            "frequency_v2_q0374_c": (
                "Even if I found it gross, I wouldn't want to hurt them. I'd say, "
                "\"Next time let's buy one from a shop,\" throw that toothbrush away, "
                "and get myself a new one."
            ),
            "frequency_v2_q0374_d": (
                "I'd say, \"You could at least have told me,\" but I wouldn't make a big deal of it; "
                "I'd wash the toothbrush and keep using it."
            ),
        },
    },
    "frequency_v2_q0375": {
        "options": {
            "frequency_v2_q0375_b": (
                "I'd definitely refuse. I think mixing a relationship with work always ends in disaster."
            ),
        },
    },
    "frequency_v2_q0377": {
        "options": {
            "frequency_v2_q0377_d": (
                "If possible, I'd rather not settle the bill a different way until we'd figured out "
                "how to preserve the original payment arrangement."
            ),
        },
    },
    "frequency_v2_q0378": {
        "options": {
            "frequency_v2_q0378_b": (
                "I'd say it's a great idea and enjoy spending that week at home on my own "
                "while they're away."
            ),
            "frequency_v2_q0378_d": (
                "I'd ask, \"Why don't I come too?\" and try to turn it into a trip for the two of us."
            ),
        },
    },
    "frequency_v2_q0379": {
        "prompt": (
            "You've both joined the same gym. What would feel most natural for how you work out there?"
        ),
        "options": {
            "frequency_v2_q0379_a": (
                "We should go together, lift together, and take breaks together; "
                "I'd see it as a couple activity."
            ),
            "frequency_v2_q0379_d": (
                "I'd lead the workout, saying things like, \"Okay, let's move to this next,\" "
                "and motivate both of us to stay in shape."
            ),
        },
    },
    "frequency_v2_q0380": {
        "options": {
            "frequency_v2_q0380_c": (
                "I'd let them have fun, join in myself, and spend the night just as drunk and wild "
                "as they are."
            ),
        },
    },
    "frequency_v2_q0381": {
        "options": {
            "frequency_v2_q0381_d": (
                "I'd ask, \"Why did you read it—do you suspect me of something?\" and turn it into "
                "a discussion about lack of trust."
            ),
        },
    },
    "frequency_v2_q0383": {
        "prompt": (
            "When a difficult situation comes up, you like to plan around possible risks, "
            "while your partner prefers a more relaxed approach. You need to act together. "
            "What do you do?"
        ),
        "options": {
            "frequency_v2_q0383_c": (
                "I'd try to run both approaches side by side while largely sticking to my own method."
            ),
        },
    },
    "frequency_v2_q0384": {
        "options": {
            "frequency_v2_q0384_c": (
                "I'd try to eat when they get hungry and adjust my own eating rhythm to theirs."
            ),
            "frequency_v2_q0384_d": (
                "I'd do the cooking so I could organize what and when we both eat."
            ),
        },
    },
    "frequency_v2_q0385": {
        "prompt": (
            "You sense that your partner has secrets from their past that you don't know, "
            "but that wouldn't harm you."
        ),
        "options": {
            "frequency_v2_q0385_a": (
                "I think everyone should have a private part of themselves. If they don't want to share, "
                "I wouldn't ask or pry."
            ),
        },
    },
    "frequency_v2_q0386": {
        "options": {
            "frequency_v2_q0386_d": (
                "I'd suggest a small routine: \"At least let's have dinner without the computer.\""
            ),
        },
    },
    "frequency_v2_q0387": {
        "options": {
            "frequency_v2_q0387_a": (
                "I'd make it clear that I felt hurt: "
                "\"You're not replying to me, but you're posting stories?\""
            ),
        },
    },
    "frequency_v2_q0388": {
        "options": {
            "frequency_v2_q0388_a": (
                "Weeks in advance, I'd quietly figure out what they need, buy it, and have it wrapped."
            ),
            "frequency_v2_q0388_b": (
                "I'd leave it until the last day and choose whatever feels best in the moment "
                "while I'm at the mall."
            ),
            "frequency_v2_q0388_d": (
                "Instead of buying a gift, I'd make them a nice dinner or plan an experience, "
                "such as tickets to something."
            ),
        },
    },
    "frequency_v2_q0389": {
        "options": {
            "frequency_v2_q0389_d": (
                "I'd immediately start organizing things—figure out where the guest would sleep "
                "and switch into host mode."
            ),
        },
    },
    "frequency_v2_q0390": {
        "options": {
            "frequency_v2_q0390_b": (
                "I'd say, \"This isn't the place for this—we'll talk when we get home,\" "
                "and shut the conversation down immediately."
            ),
        },
    },
    "frequency_v2_q0391": {
        "options": {
            "frequency_v2_q0391_b": (
                "I'd do a quick check-in: \"Did that feel a little awkward?\""
            ),
        },
    },
    "frequency_v2_q0392": {
        "options": {
            "frequency_v2_q0392_a": (
                "I'd ask, \"What made you feel this way—are you tired of it?\" and try to understand "
                "what's behind the change."
            ),
            "frequency_v2_q0392_d": (
                "I'd join them: \"Great idea, let's order pizza,\" and relax the rules for myself too."
            ),
        },
    },
    "frequency_v2_q0394": {
        "options": {
            "frequency_v2_q0394_c": "I'd also mention some of my own slip-ups.",
        },
    },
    "frequency_v2_q0396": {
        "options": {
            "frequency_v2_q0396_d": "I'd start making more noise with my own activities too.",
        },
    },
    "frequency_v2_q0398": {
        "prompt": (
            "While you're getting to know someone new, they start talking very early about future "
            "plans such as vacations or living together."
        ),
        "options": {
            "frequency_v2_q0398_c": (
                "I'd listen, but I wouldn't talk about myself in the same way."
            ),
        },
    },
    "frequency_v2_q0399": {
        "prompt": (
            "In an argument, your partner keeps going off topic instead of getting to the main issue."
        ),
        "options": {
            "frequency_v2_q0399_b": "I'd start going off topic too.",
            "frequency_v2_q0399_d": "I'd try to bring out the emotional side of the issue.",
        },
    },
}

LATER_REVIEW_FILES = [
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
        (7, 301, 350),
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


def annotate_q0353_source_issue() -> None:
    text = REVIEW_351_400.read_text(encoding="utf-8")
    marker = f"## {SOURCE_TR_ISSUE_ID}"
    if marker not in text:
        raise SystemExit(f"missing {SOURCE_TR_ISSUE_ID} section in review markdown")
    if "SOURCE_TR_ISSUE" in text:
        return
    insert = (
        "\n- **human_review_decision:** `SOURCE_TR_ISSUE`\n"
        "- **human_review_note:** Turkish option a literally says asking the partner to "
        "\"suggest putting the phone away,\" but the intended meaning and current English "
        "imply directly asking them to put the phone away. TR and EN text unchanged pending "
        "explicit source correction.\n"
        "- **recommended_source_correction_tr:** "
        "Yemek boyunca telefonu kaldırmasını net biçimde isterim.\n"
        "- **recommended_source_correction_en:** "
        "I'd clearly ask them to put the phone away for the meal.\n"
    )
    pattern = re.compile(
        rf"(## {re.escape(SOURCE_TR_ISSUE_ID)}\n\n"
        rf"- \*\*primary_dimension:\*\*[^\n]+\n"
        rf"- \*\*semantic_cluster:\*\*[^\n]+\n"
        rf"- \*\*translation_review_status:\*\* `PENDING_HUMAN_REVIEW`)"
    )
    updated, n = pattern.subn(r"\1" + insert, text, count=1)
    if n != 1:
        raise SystemExit("failed to annotate q0353 SOURCE_TR_ISSUE in review markdown")
    REVIEW_351_400.write_text(updated, encoding="utf-8")


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
    pool = json.loads((OUT / "frequency_behavior_pool_tr_v2_draft1.json").read_text(encoding="utf-8"))
    snap: dict[str, dict] = {}
    for iid in STRUCTURAL_GUARD_IDS:
        item = next(it for it in pool["items"] if it["item_id"] == iid)
        snap[iid] = {
            "primary_dimensions": item["primary_dimensions"],
            "semantic_cluster": item["semantic_cluster"],
        }
    return snap


def assert_structural_snapshot_unchanged(before: dict[str, dict]) -> None:
    pool = json.loads((OUT / "frequency_behavior_pool_tr_v2_draft1.json").read_text(encoding="utf-8"))
    for iid, expected in before.items():
        item = next(it for it in pool["items"] if it["item_id"] == iid)
        if item["primary_dimensions"] != expected["primary_dimensions"]:
            raise SystemExit(f"{iid} primary_dimensions changed unexpectedly")
        if item["semantic_cluster"] != expected["semantic_cluster"]:
            raise SystemExit(f"{iid} semantic_cluster changed unexpectedly")


def main() -> None:
    assert_prior_batches_unchanged()
    structural_before = load_structural_snapshot()
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    batch = json.loads(BATCH_008.read_text(encoding="utf-8"))
    items = batch["items"]
    q0353_prompt_before = items[SOURCE_TR_ISSUE_ID]["prompt"]
    q0353_options_before = dict(items[SOURCE_TR_ISSUE_ID]["options"])

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 008: {iid}")
    if SOURCE_TR_ISSUE_ID not in items:
        raise SystemExit(f"Missing item in batch 008: {SOURCE_TR_ISSUE_ID}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    if items[SOURCE_TR_ISSUE_ID]["prompt"] != q0353_prompt_before:
        raise SystemExit("q0353 prompt changed unexpectedly")
    if items[SOURCE_TR_ISSUE_ID]["options"] != q0353_options_before:
        raise SystemExit("q0353 options changed unexpectedly")
    items[SOURCE_TR_ISSUE_ID]["translation_review_status"] = "PENDING_HUMAN_REVIEW"

    BATCH_008.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()
    annotate_q0353_source_issue()
    assert_structural_snapshot_unchanged(structural_before)

    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    preserve_prior_flag_metadata(en_review)
    for row in en_review["items"]:
        if row["item_id"] == SOURCE_TR_ISSUE_ID:
            row["translation_review_status"] = "PENDING_HUMAN_REVIEW"
            break
    else:
        raise SystemExit("q0353 missing from EN review metadata")
    recompute_review_stats(en_review)
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    rev = {r["item_id"]: r for r in en_review["items"]}
    by_id = {it["item_id"]: it for it in en_pool["items"]}

    q356 = by_id["frequency_v2_q0356"]["prompt"]
    assert "sunstroke" in q356.lower()
    assert "sunburn" not in q356.lower()
    q370 = by_id["frequency_v2_q0370"]["prompt"]
    assert "isn't saved in your partner's contacts" in q370
    assert "unlisted" not in q370.lower()
    q374c = next(o["text"] for o in by_id["frequency_v2_q0374"]["options"] if o["option_id"].endswith("_c"))
    assert "throw that toothbrush away" in q374c
    assert "get myself a new one" in q374c
    q375b = next(o["text"] for o in by_id["frequency_v2_q0375"]["options"] if o["option_id"].endswith("_b"))
    assert "in my experience" not in q375b.lower()
    q380 = by_id["frequency_v2_q0380"]
    assert q380["primary_dimensions"] == []
    assert q380["semantic_cluster"] == "unassigned:social"
    q391 = by_id["frequency_v2_q0391"]["prompt"]
    assert "your ex's close circle" in q391.lower()
    q353 = by_id[SOURCE_TR_ISSUE_ID]
    assert q353["prompt"] == q0353_prompt_before
    for opt in q353["options"]:
        assert opt["text"] == q0353_options_before[opt["option_id"]]
    assert rev[SOURCE_TR_ISSUE_ID]["translation_review_status"] == "PENDING_HUMAN_REVIEW"

    for i in range(1, 353):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    assert rev[SOURCE_TR_ISSUE_ID]["translation_review_status"] == "PENDING_HUMAN_REVIEW"
    for i in range(354, 401):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(401, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 399

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    assert "SOURCE_TR_ISSUE" in REVIEW_351_400.read_text(encoding="utf-8")
    assert len(PATCHES) == 36

    print("Phase 6I batch 351-400 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")
    print("q0353 SOURCE_TR_ISSUE left PENDING_HUMAN_REVIEW (TR/EN unchanged).")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
