#!/usr/bin/env python3
"""Apply Phase 6B human EN semantic review for batch 001-050.

English user-facing wording and translation_review_status only.
Does not modify TR pool, weights, evidence, or runtime flags.
"""
from __future__ import annotations

import copy
import json
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
BATCH_001 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_001.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"

REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(1, 51)]

# Human-authority text patches: item_id -> {prompt?, options: {option_id: text}}
PATCHES: dict[str, dict] = {
    "frequency_v2_q0001": {
        "options": {
            "frequency_v2_q0001_a": "I'd find a funny little detail they'd enjoy and use it to get the conversation going.",
            "frequency_v2_q0001_b": "I'd carry on with my day — I'd rather they make the first move.",
        }
    },
    "frequency_v2_q0002": {
        "options": {
            "frequency_v2_q0002_a": "Great — I love just going with the flow.",
            "frequency_v2_q0002_d": "Works for me — I enjoy going along with whatever they're in the mood for.",
        }
    },
    "frequency_v2_q0003": {
        "prompt": "Your partner comes home stressed and upset from work and tells you what happened. What's your first instinct?",
        "options": {
            "frequency_v2_q0003_b": "Emphasize that they have a point and make sure they feel I'm emotionally on their side.",
        },
    },
    "frequency_v2_q0005": {
        "options": {
            "frequency_v2_q0005_d": "Focus on how they feel and acknowledge their feelings even if I still disagree.",
        }
    },
    "frequency_v2_q0006": {
        "prompt": "You've been dating someone for two months and things are going well, but you've never had a \"what are we?\" talk. How do you feel about that?",
        "options": {
            "frequency_v2_q0006_b": "I don't need a label; I'd enjoy what we have and see where it goes.",
        },
    },
    "frequency_v2_q0007": {
        "options": {
            "frequency_v2_q0007_b": "I'd take it in stride — it also gives me a chance to have some solo time and handle my own stuff.",
            "frequency_v2_q0007_d": "I'd offer to come over so we could quietly rest and do our own thing in the same space.",
        }
    },
    "frequency_v2_q0009": {
        "options": {
            "frequency_v2_q0009_d": "I'd go but mostly observe — I'd keep my boundaries in place at first.",
        }
    },
    "frequency_v2_q0010": {
        "prompt": "You're both having an extremely busy workday. What kind of communication do you expect?",
        "options": {
            "frequency_v2_q0010_c": "I match their pace — I text about as much as they do.",
        },
    },
    "frequency_v2_q0011": {
        "prompt": "You're dressed up for a nice restaurant when your partner calls last minute: \"I'm exhausted — can we have pizza and watch a movie at home instead?\"",
    },
    "frequency_v2_q0012": {
        "prompt": "When you're spending time together at home, how physically close do you usually like to be?",
    },
    "frequency_v2_q0013": {
        "options": {
            "frequency_v2_q0013_b": "When they share something equally personal, I'd open up in return.",
        }
    },
    "frequency_v2_q0015": {
        "options": {
            "frequency_v2_q0015_a": "Go to them right away, hug them, and give them a heartfelt apology.",
            "frequency_v2_q0015_b": "Calmly explain where the stress came from and talk it through to make things right.",
        }
    },
    "frequency_v2_q0016": {
        "options": {
            "frequency_v2_q0016_c": "I'd make a pointed joke about it instead of turning it into a serious discussion.",
        }
    },
    "frequency_v2_q0018": {
        "options": {
            "frequency_v2_q0018_d": "I can't relax until we've clarified the numbers and possible solutions as much as we can that same day.",
        }
    },
    "frequency_v2_q0019": {
        "options": {
            "frequency_v2_q0019_c": "Whatever they want to do works for me — it's easier for me when they handle the planning.",
        }
    },
    "frequency_v2_q0021": {
        "options": {
            "frequency_v2_q0021_d": "I don't need to isolate — sticking to my normal routine is enough.",
        }
    },
    "frequency_v2_q0023": {
        "prompt": "How do you most clearly show someone that you love and value them?",
    },
    "frequency_v2_q0025": {
        "options": {
            "frequency_v2_q0025_c": "I'd assume they're busy and reply in the same short, normal way.",
        }
    },
    "frequency_v2_q0029": {
        "prompt": "Your partner forgot something simple — for example, picking up important paperwork for you — and it cost you time.",
        "options": {
            "frequency_v2_q0029_a": "I'd show that I'm annoyed, but then move into a forgiving mood pretty quickly.",
            "frequency_v2_q0029_b": "I'd say nothing to avoid making it a bigger issue and quickly handle the situation myself.",
        },
    },
    "frequency_v2_q0031": {
        "options": {
            "frequency_v2_q0031_d": "I'd make sure not to wake them when I get up in the morning, and I'd expect them to be considerate when they're still awake at night.",
        }
    },
    "frequency_v2_q0033": {
        "options": {
            "frequency_v2_q0033_b": "I'd wait for time to pass, trust to build, and for me to feel sure rationally too.",
        }
    },
    "frequency_v2_q0036": {
        "prompt": "You have an important celebration dinner planned. Your partner comes home exhausted from work and says, \"I can't go — I have no energy left.\"",
        "options": {
            "frequency_v2_q0036_d": "I'd say \"no worries\" and go out with my friends since I'm already ready.",
        }
    },
    "frequency_v2_q0038": {
        "prompt": "You're very organized; your partner is much messier. How do you handle it?",
    },
    "frequency_v2_q0041": {
        "prompt": "Your partner is on a busy week-long work trip in a different time zone. How should communication work?",
        "options": {
            "frequency_v2_q0041_b": "We should stay in touch through the day by sending photos and sharing little moments, time difference or not.",
            "frequency_v2_q0041_d": "A short but meaningful video call when there's a chance would reassure me.",
        }
    },
    "frequency_v2_q0045": {
        "prompt": "You've eaten and you're already in pajamas. Your partner calls: \"Some friends are hanging out nearby — come join us!\"",
        "options": {
            "frequency_v2_q0045_d": "Even if I don't feel like it, I'd go so I don't disappoint them or leave them on their own.",
        }
    },
    "frequency_v2_q0046": {
        "options": {
            "frequency_v2_q0046_a": "I'd run every scenario in my head — worst case included — and couldn't focus on my work until evening.",
        }
    },
    "frequency_v2_q0049": {
        "prompt": "You notice your partner liked photos of someone they used to date on social media. What's your gut reaction?",
        "options": {
            "frequency_v2_q0049_c": "It would bother me, but I'd hold back to avoid making it a big deal — I might show it indirectly.",
        }
    },
    "frequency_v2_q0050": {
        "options": {
            "frequency_v2_q0050_b": "I feel boxed in — even planning a few months ahead feels too rigid; I live in the moment.",
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


def main() -> None:
    batch = json.loads(BATCH_001.read_text(encoding="utf-8"))
    items = batch["items"]

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 001: {iid}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    BATCH_001.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    # Post-build assertions
    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    en_review = json.loads(
        (OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json").read_text()
    )
    by_id = {it["item_id"]: it for it in en_pool["items"]}
    rev = {r["item_id"]: r for r in en_review["items"]}

    q31d = next(o for o in by_id["frequency_v2_q0031"]["options"] if o["option_id"].endswith("_d"))
    assert "when they're still awake at night" in q31d["text"]
    assert "[place]" not in by_id["frequency_v2_q0045"]["prompt"]
    assert "someone they used to date" in by_id["frequency_v2_q0049"]["prompt"]
    assert " an ex" not in by_id["frequency_v2_q0049"]["prompt"].lower()

    for i in range(1, 51):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(51, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    print("Phase 6B batch 001-050 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")


if __name__ == "__main__":
    main()
