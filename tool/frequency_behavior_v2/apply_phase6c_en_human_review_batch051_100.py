#!/usr/bin/env python3
"""Apply Phase 6C human EN semantic review for batch 051-100.

English user-facing wording and translation_review_status only.
Does not modify TR pool, weights, evidence, or runtime flags.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
BATCH_002 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_002.json"
BATCH_001 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_001.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"

REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(51, 101)]
PRIOR_REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(1, 51)]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0051": {
        "options": {
            "frequency_v2_q0051_c": "I'd drop a subtle hint and see how they respond.",
        }
    },
    "frequency_v2_q0053": {
        "prompt": "On a first date, the conversation gets deeper and they start sharing personal things.",
        "options": {
            "frequency_v2_q0053_a": "I'd share something at a similar level of depth.",
            "frequency_v2_q0053_d": "I'd stay curious and ask questions to keep it going, but keep what I share about myself limited.",
        },
    },
    "frequency_v2_q0054": {
        "prompt": "You didn't make a clear plan for the weekend. It's Saturday afternoon and you still haven't decided what to do.",
    },
    "frequency_v2_q0055": {
        "prompt": "While you're together, a plan comes up to spend the evening with their group of friends.",
        "options": {
            "frequency_v2_q0055_b": "I'd say \"not this time\" — I'd rather spend time one-on-one.",
            "frequency_v2_q0055_c": "I'd go, but keep open the option of leaving early.",
        },
    },
    "frequency_v2_q0056": {
        "options": {
            "frequency_v2_q0056_b": "I'd rather find a practical solution and move on.",
        }
    },
    "frequency_v2_q0057": {
        "options": {
            "frequency_v2_q0057_b": "I'd give myself more space and see if they come closer.",
        }
    },
    "frequency_v2_q0058": {
        "prompt": "You've just matched with someone. You're both messaging, but the pace is slow.",
        "options": {
            "frequency_v2_q0058_b": "I'd match their pace.",
            "frequency_v2_q0058_c": "I'd pause for a few days, then try again.",
        },
    },
    "frequency_v2_q0059": {
        "options": {
            "frequency_v2_q0059_c": "I'd go, but leave after a certain time.",
        }
    },
    "frequency_v2_q0060": {
        "options": {
            "frequency_v2_q0060_b": "I'd listen, thank them for sharing, and share something of my own later.",
            "frequency_v2_q0060_d": "I'd say \"I'm glad you shared that\" and gently steer the conversation elsewhere.",
        },
    },
    "frequency_v2_q0061": {
        "prompt": "You don't have a set routine for weekday evenings.",
        "options": {
            "frequency_v2_q0061_c": "I'd plan some evenings and leave others open.",
        },
    },
    "frequency_v2_q0062": {
        "options": {
            "frequency_v2_q0062_b": "I'd be a little disappointed, and I'd let it show.",
        }
    },
    "frequency_v2_q0063": {
        "options": {
            "frequency_v2_q0063_a": "At some point, I'd want to clarify what we are.",
        }
    },
    "frequency_v2_q0064": {
        "prompt": "There's silence after an argument.",
        "options": {
            "frequency_v2_q0064_b": "I'd wait for them to reach out.",
            "frequency_v2_q0064_c": "I'd send a quick \"Want to talk?\"",
        },
    },
    "frequency_v2_q0065": {
        "prompt": "Your partner clearly expresses a boundary with you for the first time — about time, a topic, or a behavior.",
        "options": {
            "frequency_v2_q0065_d": "I'd find it a little difficult, but I'd respect it.",
        }
    },
    "frequency_v2_q0066": {
        "prompt": "After a long day, you're both tired. How would you like to spend the evening?",
        "options": {
            "frequency_v2_q0066_a": "I'd like a quiet evening at home together.",
            "frequency_v2_q0066_b": "I'd want to go out and get some air.",
            "frequency_v2_q0066_c": "I'd rather we each do our own thing for a while, then reconnect.",
            "frequency_v2_q0066_d": "I'd want a short chat and an early night.",
        },
    },
    "frequency_v2_q0067": {
        "prompt": "You've started seeing someone new. The first few dates pass without the subject of physical closeness coming up.",
        "options": {
            "frequency_v2_q0067_d": "If physical closeness is moving slowly, I'd slow down emotionally too.",
        },
    },
    "frequency_v2_q0068": {
        "options": {
            "frequency_v2_q0068_c": "I'd suggest shorter ways to stay in touch.",
        }
    },
    "frequency_v2_q0071": {
        "prompt": "After your first few exchanges, they don't ask things like \"How are you?\" or \"How was your day?\"",
        "options": {
            "frequency_v2_q0071_b": "It doesn't matter — we can connect in other ways.",
            "frequency_v2_q0071_d": "That kind of lack of interest makes me less interested too.",
        },
    },
    "frequency_v2_q0072": {
        "prompt": "While living together, you both have separate social plans scheduled for the same time.",
        "options": {
            "frequency_v2_q0072_b": "We'd each go ahead with our own plans.",
            "frequency_v2_q0072_c": "I'd cancel one plan and go with the other.",
        },
    },
    "frequency_v2_q0073": {
        "options": {
            "frequency_v2_q0073_a": "I'd raise my voice too and match their level.",
            "frequency_v2_q0073_c": "I'd step away from the situation.",
        },
    },
    "frequency_v2_q0074": {
        "prompt": "You've been seeing someone new for a few weeks. You haven't called it a relationship yet.",
        "options": {
            "frequency_v2_q0074_a": "At some point, I'd want to clarify what we are.",
        },
    },
    "frequency_v2_q0075": {
        "options": {
            "frequency_v2_q0075_d": "I'd make it a two-way conversation where we can both raise criticisms.",
        }
    },
    "frequency_v2_q0076": {
        "prompt": "You're reuniting after a long time apart because of work travel or family.",
        "options": {
            "frequency_v2_q0076_d": "I'd plan a deliberate evening for us to reconnect.",
        },
    },
    "frequency_v2_q0079": {
        "prompt": "For a while, you've had a sense that something might be off in the relationship, but neither of you has talked about it.",
        "options": {
            "frequency_v2_q0079_b": "If they bring it up, we'll talk.",
        },
    },
    "frequency_v2_q0080": {
        "prompt": "After a first date with someone new, you're at the \"How did that go?\" stage.",
    },
    "frequency_v2_q0082": {
        "prompt": "You have plans. You're getting ready, but they're giving you the impression they might cancel.",
        "options": {
            "frequency_v2_q0082_a": "I'd get a clear answer.",
            "frequency_v2_q0082_c": "I'd push them to make a decision.",
        },
    },
    "frequency_v2_q0083": {
        "prompt": "The argument is over, but you still feel something has been left unresolved.",
    },
    "frequency_v2_q0084": {
        "options": {
            "frequency_v2_q0084_b": "I'd make it clear indirectly.",
            "frequency_v2_q0084_c": "I'd create some distance myself.",
        },
    },
    "frequency_v2_q0086": {
        "options": {
            "frequency_v2_q0086_c": "I'd say, \"We don't need to get into that yet.\"",
        }
    },
    "frequency_v2_q0087": {
        "options": {
            "frequency_v2_q0087_a": "I'd understand and wait.",
            "frequency_v2_q0087_d": "If that's the pace, I'd slow down too.",
        },
    },
    "frequency_v2_q0089": {
        "prompt": "They tell you they feel something positive toward you — that they like you, miss you, or feel attached.",
        "options": {
            "frequency_v2_q0089_b": "I'd thank them and keep going at my own pace.",
        },
    },
    "frequency_v2_q0090": {
        "options": {
            "frequency_v2_q0090_d": "I'd carry on without replying and text back later.",
        }
    },
    "frequency_v2_q0093": {
        "options": {
            "frequency_v2_q0093_a": "I'd just carry on as normal.",
            "frequency_v2_q0093_c": "I'd reply a little more distantly.",
            "frequency_v2_q0093_d": "I'd be happy to hear from them and pick up the pace.",
        },
    },
    "frequency_v2_q0094": {
        "options": {
            "frequency_v2_q0094_a": "I'd bring it up and try to clarify the next step.",
            "frequency_v2_q0094_b": "I'd start by suggesting a time or a concrete option.",
        },
    },
    "frequency_v2_q0095": {
        "prompt": "They're indirectly hinting at something involving you — a fear, jealousy, or a need.",
        "options": {
            "frequency_v2_q0095_c": "I'd wait for them to say it clearly.",
        },
    },
    "frequency_v2_q0096": {
        "prompt": "In the early months, they're very plan-oriented and you're more spontaneous — or vice versa.",
        "options": {
            "frequency_v2_q0096_d": "I'd see whether this difference actually causes problems.",
        },
    },
    "frequency_v2_q0097": {
        "options": {
            "frequency_v2_q0097_b": "I'd explain the situation and apologize as part of it.",
            "frequency_v2_q0097_d": "I'd wait and assume it'll fade with time.",
        },
    },
    "frequency_v2_q0098": {
        "prompt": "Your partner has several social plans happening around the same time and wants to include you.",
    },
    "frequency_v2_q0099": {
        "options": {
            "frequency_v2_q0099_c": "I'd observe a while longer and see if things change on their own.",
        },
    },
    "frequency_v2_q0100": {
        "prompt": "You're getting to know someone new. They're very clear about what they want while you're still figuring things out — or vice versa.",
        "options": {
            "frequency_v2_q0100_a": "I'd move toward greater clarity.",
            "frequency_v2_q0100_b": "I'd keep my own pace.",
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


def assert_prior_batch_unchanged() -> None:
    batch001 = json.loads(BATCH_001.read_text(encoding="utf-8"))
    for iid in PRIOR_REVIEWED_IDS:
        item = batch001["items"][iid]
        if item.get("translation_review_status") != "REVIEWED":
            raise SystemExit(f"Batch 001 item not REVIEWED: {iid}")


def main() -> None:
    assert_prior_batch_unchanged()

    batch = json.loads(BATCH_002.read_text(encoding="utf-8"))
    items = batch["items"]

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 002: {iid}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    BATCH_002.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    en_review = json.loads(
        (OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json").read_text()
    )
    by_id = {it["item_id"]: it for it in en_pool["items"]}
    rev = {r["item_id"]: r for r in en_review["items"]}

    q62b = next(o for o in by_id["frequency_v2_q0062"]["options"] if o["option_id"].endswith("_b"))
    assert "I'd be a little disappointed" in q62b["text"]
    assert "You haven't called it a relationship yet." in by_id["frequency_v2_q0074"]["prompt"]
    assert "vibes" not in by_id["frequency_v2_q0082"]["prompt"].lower()
    q100 = by_id["frequency_v2_q0100"]["prompt"]
    assert "very clear about what they want" in q100
    assert "very direct" not in q100.lower()

    for i in range(1, 101):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(101, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    print("Phase 6C batch 051-100 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")


if __name__ == "__main__":
    main()
