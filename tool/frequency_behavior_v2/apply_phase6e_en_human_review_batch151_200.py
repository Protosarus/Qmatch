#!/usr/bin/env python3
"""Apply Phase 6E human EN semantic review for batch 151-200.

English user-facing wording and translation_review_status only.
Skips q0160 (SOURCE_TR_ISSUE — TR/EN unchanged, stays PENDING_HUMAN_REVIEW).
Preserves later en_human_review markdown batches from HEAD after rebuild.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
BATCH_004 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_004.json"
BATCH_003 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_003.json"
BATCH_002 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_002.json"
BATCH_001 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_001.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
REVIEW_151_200 = OUT / "en_human_review/frequency_v2_en_review_151_200.md"
SOURCE_TR_ISSUE_ID = "frequency_v2_q0160"

REVIEWED_IDS = [
    f"frequency_v2_q{i:04d}"
    for i in range(151, 201)
    if i != 160
]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0151": {
        "options": {
            "frequency_v2_q0151_d": (
                "I'd feel safer ending things while the conversation is at its peak "
                "and leaving the rest for our next planned date."
            ),
        },
    },
    "frequency_v2_q0153": {
        "options": {
            "frequency_v2_q0153_c": (
                "If I'm free, I'd answer. If I'm busy, I'd decline the call and get back "
                "to them later. I'd see it as normal."
            ),
        },
    },
    "frequency_v2_q0155": {
        "options": {
            "frequency_v2_q0155_b": (
                "I'd drop off or order what they need—medicine, food—and give them space to rest."
            ),
        },
    },
    "frequency_v2_q0156": {
        "options": {
            "frequency_v2_q0156_b": (
                "I'd go, but getting involved with family this early would make me feel a little pressured."
            ),
            "frequency_v2_q0156_c": (
                "I'd gladly go, but I'd spend more of the evening observing them than talking about myself."
            ),
            "frequency_v2_q0156_d": (
                "I'd take the lead in conversation and make jokes to ease the atmosphere and make a good impression."
            ),
        },
    },
    "frequency_v2_q0157": {
        "options": {
            "frequency_v2_q0157_d": (
                "I don't like living out a relationship in public; I'd suggest keeping it between us."
            ),
        },
    },
    "frequency_v2_q0158": {
        "options": {
            "frequency_v2_q0158_d": (
                "Whenever they're late, I'd make a pointed joke about it, but I wouldn't turn it into a big argument."
            ),
        },
    },
    "frequency_v2_q0159": {
        "prompt": (
            "On the first few dates, which way of handling the bill would make you feel most comfortable?"
        ),
        "options": {
            "frequency_v2_q0159_b": (
                "If I pay one time and they pay the whole bill the next time, that feels more natural to me."
            ),
        },
    },
    "frequency_v2_q0162": {
        "prompt": (
            "Your partner gets the major promotion they've been waiting months for, but the company requires "
            "them to attend a last-minute celebration dinner that evening. Your plans are cancelled."
        ),
        "options": {
            "frequency_v2_q0162_a": (
                "I'd be happy for them, but I'd quietly feel a little disappointed that we didn't celebrate together."
            ),
            "frequency_v2_q0162_c": (
                'I\'d keep in touch by texting them during the evening, saying things like, "I wish I were there too."'
            ),
            "frequency_v2_q0162_d": (
                "I'd quickly make other plans for my evening and get on with my own life until they're finished and back."
            ),
        },
    },
    "frequency_v2_q0163": {
        "options": {
            "frequency_v2_q0163_b": (
                "I'd say I'm tired and try to find a pace that works for both of us."
            ),
            "frequency_v2_q0163_d": (
                "I'd stay in my own mood and prefer to keep the evening short."
            ),
        },
    },
    "frequency_v2_q0164": {
        "prompt": 'You get an unusually cold message from your partner: "Fine, okay, it\'s up to you."',
        "options": {
            "frequency_v2_q0164_c": (
                "I'd take the message literally and carry on as normal without looking for a hidden meaning."
            ),
            "frequency_v2_q0164_d": (
                "I wouldn't reply; I'd wait for them to calm down or bring up the issue clearly themselves."
            ),
        },
    },
    "frequency_v2_q0165": {
        "options": {
            "frequency_v2_q0165_b": (
                "The surprise is nice, but I'd find it a little odd that my opinion wasn't asked about "
                "a choice in our shared living space."
            ),
        },
    },
    "frequency_v2_q0166": {
        "prompt": (
            "You're on a long drive when voices rise over an issue and it turns into an argument. "
            "What's your ideal way to handle it?"
        ),
        "options": {
            "frequency_v2_q0166_c": (
                'I\'d cut it short with "You\'re right, let\'s drop it" so the argument doesn\'t spoil the rest of the trip.'
            ),
            "frequency_v2_q0166_d": (
                "I'd lay out all my logical arguments and make it clear where I think they're wrong."
            ),
        },
    },
    "frequency_v2_q0167": {
        "prompt": (
            "It's your only free day to spend together. Your partner says a close friend is going through "
            "a major crisis, such as a breakup, and they need to go be with them."
        ),
        "options": {
            "frequency_v2_q0167_a": (
                "I'd support them going—of course they should—and I'd be fine spending the day on my own."
            ),
            "frequency_v2_q0167_b": (
                "I'd be okay with them going, but I'd still feel a little disappointed that our plans fell through."
            ),
            "frequency_v2_q0167_c": (
                'I\'d offer, "I can come too, and we can support them together."'
            ),
        },
    },
    "frequency_v2_q0168": {
        "options": {
            "frequency_v2_q0168_a": (
                "I'd have breakfast, go out and run my errands, and let them join me when they wake up."
            ),
        },
    },
    "frequency_v2_q0169": {
        "prompt": (
            "Things in your life are going badly. During a period like this, how do you handle communication "
            "and support with your partner?"
        ),
        "options": {
            "frequency_v2_q0169_b": (
                "I'd suggest sharing practical tasks like meals or bills and ask them to take one of them on."
            ),
            "frequency_v2_q0169_c": (
                "I'd reduce contact and withdraw into myself until I'm ready to bring it up."
            ),
            "frequency_v2_q0169_d": (
                "I'd suggest doing something to take my mind off things, like going out or doing something light."
            ),
        },
    },
    "frequency_v2_q0170": {
        "options": {
            "frequency_v2_q0170_d": (
                'I\'d calmly explain why talking right now could make things worse and set a clear time boundary, '
                'like "Let\'s talk tonight."'
            ),
        },
    },
    "frequency_v2_q0171": {
        "options": {
            "frequency_v2_q0171_b": (
                "I'd find it amusing; if I fully trust my partner, I might even enjoy seeing them get attention."
            ),
            "frequency_v2_q0171_c": (
                'I\'d step in and use physical contact or conversation to signal to the bartender that my partner is "mine."'
            ),
            "frequency_v2_q0171_d": (
                "After we leave, I'd bring it up jokingly and gauge my partner's reaction."
            ),
        },
    },
    "frequency_v2_q0172": {
        "prompt": (
            "You're shopping for furniture for the home you'll share. How do you usually make the choices?"
        ),
        "options": {
            "frequency_v2_q0172_a": (
                "Before we go, we'd make a list, take measurements, stick closely to the plan, and get out quickly."
            ),
            "frequency_v2_q0172_c": (
                "I'd choose most of the details because I think I have a better eye and am more organized; "
                "they'd usually approve."
            ),
        },
    },
    "frequency_v2_q0173": {
        "options": {
            "frequency_v2_q0173_a": (
                'I\'d test the idea with practical, structured questions like, "What\'s plan B? How long can our budget last?"'
            ),
        },
    },
    "frequency_v2_q0174": {
        "options": {
            "frequency_v2_q0174_b": (
                "I'd keep doing the morning walks without complaining; after all, the dog is now both our responsibility."
            ),
            "frequency_v2_q0174_c": (
                "I'd make a schedule that clearly sets which days each of us handles the walk."
            ),
            "frequency_v2_q0174_d": (
                "I'd occasionally make a joking but pointed comment to remind them of their responsibility, "
                "without turning it into a major conflict."
            ),
        },
    },
    "frequency_v2_q0175": {
        "options": {
            "frequency_v2_q0175_b": (
                "A lively, social resort or trip with other couples or friends around and lots of activities."
            ),
        },
    },
    "frequency_v2_q0176": {
        "prompt": (
            "Your partner watches a documentary and decides to go fully vegan or start a very strict diet."
        ),
        "options": {
            "frequency_v2_q0176_a": (
                'I\'d follow their rule of keeping anything they consider "harmful" out of the house and change my diet to join them.'
            ),
            "frequency_v2_q0176_b": (
                "I'd respect their decision, but I wouldn't give up the foods I eat; we'd prepare two different meals at home."
            ),
            "frequency_v2_q0176_d": (
                "I'd watch from a distance at first to see how long they can keep it up, then adjust depending on how it goes."
            ),
        },
    },
    "frequency_v2_q0177": {
        "options": {
            "frequency_v2_q0177_d": (
                "I'd explain it briefly and clearly, almost like stating a fact, without dramatizing it."
            ),
        },
    },
    "frequency_v2_q0178": {
        "prompt": (
            "You're on a 40-minute drive. Your partner turns off the radio, looks at the road, and doesn't say anything."
        ),
        "options": {
            "frequency_v2_q0178_c": (
                "I'd get bored, turn the music back on, or bring up something funny to liven things up."
            ),
            "frequency_v2_q0178_d": (
                "I'd assume something is bothering them and offer support by holding their hand or touching their leg."
            ),
        },
    },
    "frequency_v2_q0179": {
        "prompt": (
            "Your partner has become intensely absorbed in a new hobby or project. For three days, they've barely "
            "left the computer and have hardly talked to you."
        ),
        "options": {
            "frequency_v2_q0179_a": (
                "I'd feel unvalued because I'm getting so little attention and ask them to put an end to this situation."
            ),
            "frequency_v2_q0179_b": (
                "I'd appreciate their passion, but I'd insist that we at least have dinner together so we don't lose our connection."
            ),
            "frequency_v2_q0179_d": (
                "I'd bring them coffee and snacks to support the project and quietly stay present in the background."
            ),
        },
    },
    "frequency_v2_q0180": {
        "options": {
            "frequency_v2_q0180_a": (
                "I'd immediately write down exactly how much we're short and the steps we'll take to close the gap."
            ),
            "frequency_v2_q0180_b": (
                "I'd at least clarify the first step and when we'll look at the situation again."
            ),
            "frequency_v2_q0180_c": (
                "I'd wait a few days and make a plan later."
            ),
            "frequency_v2_q0180_d": (
                "For now, I'd carry on with our daily routine without making a special plan."
            ),
        },
    },
    "frequency_v2_q0181": {
        "prompt": (
            'You\'re only two months into the relationship. During a conversation, your partner jokes, '
            '"We\'ll give our future kids this name."'
        ),
        "options": {
            "frequency_v2_q0181_a": (
                "I'd feel a warm rush; I'd like knowing they look at the relationship with as much hope as I do."
            ),
            "frequency_v2_q0181_c": (
                'I\'d joke back, but internally I\'d think, "It\'s still very early," and make a mental note of it.'
            ),
            "frequency_v2_q0181_d": (
                "I'd laugh it off so I don't spoil the moment, but I'd quickly change the subject in case it starts becoming serious."
            ),
        },
    },
    "frequency_v2_q0182": {
        "prompt": (
            'It\'s Friday afternoon. Your partner shows up at your workplace and says, "Pack a couple of things—we have '
            'a flight in an hour. We\'re going away for the weekend!"'
        ),
        "options": {
            "frequency_v2_q0182_a": (
                "I'd be wildly excited; I love them taking control and pulling off huge surprises like this."
            ),
            "frequency_v2_q0182_b": (
                'I\'d be happy, but I might interrupt the moment with practical questions like, "Where are we going? '
                'Is the accommodation booked? What\'s the weather like?"'
            ),
            "frequency_v2_q0182_c": (
                "I'd be very stressed. I already had my own plans and things I needed to take care of; "
                "I'd have wanted them to ask me first."
            ),
            "frequency_v2_q0182_d": (
                "I'd get organized, pack quickly, and have no trouble adapting to whatever they have planned."
            ),
        },
    },
    "frequency_v2_q0183": {
        "options": {
            "frequency_v2_q0183_b": (
                "I'd ask them to listen first and save the suggestions for later."
            ),
            "frequency_v2_q0183_c": (
                "Even though I'd prefer something different, I'd keep listening to their suggestions without stopping them."
            ),
            "frequency_v2_q0183_d": (
                "I wouldn't say what I need; I'd let the conversation continue in the direction they take it."
            ),
        },
    },
    "frequency_v2_q0184": {
        "prompt": (
            'Your partner is preparing for an intense exam or project and says, "We might not be able to see each other '
            'on weekends this month—I need to study."'
        ),
        "options": {
            "frequency_v2_q0184_c": (
                "If that's what they need to do for their future, I'd fully respect the arrangement and encourage them."
            ),
        },
    },
    "frequency_v2_q0185": {
        "options": {
            "frequency_v2_q0185_b": (
                "I'd take it seriously and think it through; my friend might see something from the outside that I can't."
            ),
            "frequency_v2_q0185_d": (
                "I'd be emotionally affected; my friend's disapproval would leave me feeling uneasy inside."
            ),
        },
    },
    "frequency_v2_q0187": {
        "prompt": (
            "You're watching a movie together, but your partner keeps using their phone, smiling and messaging people."
        ),
        "options": {
            "frequency_v2_q0187_a": (
                "I'd be very bothered; I'd see being on the phone while we're spending time together as disrespectful to me."
            ),
            "frequency_v2_q0187_b": (
                "I wouldn't mind; them messaging friends while we're watching the movie wouldn't bother me."
            ),
        },
    },
    "frequency_v2_q0188": {
        "prompt": (
            "You're invited to your partner's cousin's 500-person wedding, with lots of dancing. You don't know anyone there."
        ),
        "options": {
            "frequency_v2_q0188_a": (
                "Crowds, noise, and people I don't know wear me out; I'd say I don't want to go and let my partner go without me."
            ),
            "frequency_v2_q0188_b": (
                "I'd go for their sake and stay close to them all night to get through it."
            ),
            "frequency_v2_q0188_d": (
                'I\'d make an agreement upfront: "I\'ll come, but we\'ll stay for two hours and leave early."'
            ),
        },
    },
    "frequency_v2_q0189": {
        "prompt": (
            "After weeks, you finally have a completely free day off with nothing planned. How does your day start?"
        ),
        "options": {
            "frequency_v2_q0189_a": (
                'I\'d start with a list of goals like, "Clean the house, watch that movie, finish that book."'
            ),
            "frequency_v2_q0189_b": (
                "I'd spend hours in bed, doing whatever I feel like in the moment and even losing track of time."
            ),
            "frequency_v2_q0189_c": (
                'I\'d ask my partner, "What are we doing today? What\'s your plan?" and wait for them to give the day some direction.'
            ),
            "frequency_v2_q0189_d": (
                "I'd head out as soon as I wake up—into the streets, cafés, and around other people."
            ),
        },
    },
    "frequency_v2_q0190": {
        "prompt": (
            "At noon on the weekend, you send your partner a message. They read it but don't reply for a full six hours."
        ),
        "options": {
            "frequency_v2_q0190_c": (
                "I'd get annoyed that they read it and left it there, and decide I won't message again until they do."
            ),
        },
    },
    "frequency_v2_q0191": {
        "prompt": (
            "Once your relationship settles into a daily routine, what feels most natural to you for keeping the connection going?"
        ),
        "options": {
            "frequency_v2_q0191_a": (
                'A few times during the day, I\'d openly say things like "I\'m here for you" or "I\'m glad you\'re in my life" '
                "to keep verbal closeness alive."
            ),
            "frequency_v2_q0191_b": (
                "I'd spend time side by side even without talking; quiet companionship is enough for me."
            ),
            "frequency_v2_q0191_c": (
                "During the day we'd each do our own thing, then come together for shared time in the evening."
            ),
            "frequency_v2_q0191_d": (
                "I'd keep our shared calendar and financial plans clear; I like knowing what is happening and when."
            ),
        },
    },
    "frequency_v2_q0192": {
        "options": {
            "frequency_v2_q0192_a": (
                "I'd say I want to be alone for a while."
            ),
            "frequency_v2_q0192_b": (
                "I'd want them to stay in the same home, but I'd retreat into my own space a little."
            ),
            "frequency_v2_q0192_c": (
                "I'd let them sit with me and spend most of the time together."
            ),
        },
    },
    "frequency_v2_q0193": {
        "prompt": (
            "On your birthday, your partner gives you a gift that's clearly not your style and seems to have been chosen "
            "without much thought or based on a misunderstanding of your taste."
        ),
        "options": {
            "frequency_v2_q0193_a": (
                "I wouldn't let it show. I'd tell myself that the thought is what matters, act happy, and keep the gift."
            ),
            "frequency_v2_q0193_b": (
                'I\'d thank them, but openly say, "This isn\'t really my style—should we exchange it together?"'
            ),
            "frequency_v2_q0193_c": (
                "I'd thank them in the moment, use the gift very little afterward, and bring it up indirectly later."
            ),
            "frequency_v2_q0193_d": (
                'I\'d joke, "Did you seriously get this for me?" and use humor to soften the moment while making my opinion clear.'
            ),
        },
    },
    "frequency_v2_q0194": {
        "prompt": (
            "You have very different friend groups that don't get along particularly well. You need to decide what to do on Friday night."
        ),
        "options": {
            "frequency_v2_q0194_a": (
                "We'd each go out with our own friends; I'd see that as a kind of freedom for both of us."
            ),
            "frequency_v2_q0194_b": (
                "I wouldn't force the groups together, but I'd suggest spending one Friday with their group and the next with mine."
            ),
            "frequency_v2_q0194_c": (
                "I'd rather skip seeing friends and make a plan for just the two of us; I'd see that as the more reliable option."
            ),
            "frequency_v2_q0194_d": (
                "I'd arrange a big shared event, like a concert, and hope it forces the two groups to mix a little."
            ),
        },
    },
    "frequency_v2_q0195": {
        "options": {
            "frequency_v2_q0195_a": (
                "It would eat at me; when they're asleep or in the shower, I'd enter their password and secretly read the message."
            ),
            "frequency_v2_q0195_b": (
                'I\'d pick up the phone and confront them right there: "Who is that message from?"'
            ),
            "frequency_v2_q0195_d": (
                "I'd watch from a distance for days to see whether more messages appear or their behavior seems unusual."
            ),
        },
    },
    "frequency_v2_q0196": {
        "prompt": (
            "It's Sunday morning. You have no plans and you're both sitting on the couch."
        ),
        "options": {
            "frequency_v2_q0196_a": (
                'I\'d say, "Come on, get up—we\'re going to that place for breakfast," raise the energy, and get the day started myself.'
            ),
            "frequency_v2_q0196_b": (
                'I\'d quietly keep reading my book or scrolling on my phone until they ask, "What should we do?"'
            ),
            "frequency_v2_q0196_c": (
                "I think Sundays shouldn't be planned at all; I'd happily spend the whole day in pajamas."
            ),
            "frequency_v2_q0196_d": (
                'I\'d ask questions like, "What do you want to eat? Should we go out or stay in?" so we can decide together.'
            ),
        },
    },
    "frequency_v2_q0197": {
        "prompt": (
            "In a future marriage or serious long-term relationship, how would you expect finances to be handled?"
        ),
        "options": {
            "frequency_v2_q0197_a": (
                'There should be one joint account, and the idea of "your money" and "my money" should disappear completely.'
            ),
            "frequency_v2_q0197_b": (
                "There should be a shared pool for household expenses, while each person's salary and personal savings stay in their own account."
            ),
            "frequency_v2_q0197_c": (
                "I'd want to handle the finances; I'd feel more comfortable managing the bills and budget."
            ),
            "frequency_v2_q0197_d": (
                "I wouldn't set strict rules in advance; we'd find a natural balance based on the circumstances, income, and needs."
            ),
        },
    },
    "frequency_v2_q0198": {
        "prompt": (
            "For no clear reason, your partner is very grouchy that day, objects to everything, and gives off a lot of negative energy."
        ),
        "options": {
            "frequency_v2_q0198_b": (
                "I'd leave them alone and keep some physical and emotional distance until their mood improves."
            ),
            "frequency_v2_q0198_c": (
                "I'd do things they like and make jokes to try to lift their mood."
            ),
            "frequency_v2_q0198_d": (
                'I\'d keep asking, "What\'s wrong? Why are you like this?" until I get an explanation that makes sense to me.'
            ),
        },
    },
    "frequency_v2_q0199": {
        "prompt": (
            "You're still in the early stages of getting to know each other. Your partner keeps talking about old memories, high school, and childhood."
        ),
        "options": {
            "frequency_v2_q0199_b": (
                "I'd listen with interest, but give more surface-level answers because I'm not ready to open up that much yet."
            ),
            "frequency_v2_q0199_c": (
                "I'd get bored with so much focus on the past; I'd rather focus on life now and the future."
            ),
            "frequency_v2_q0199_d": (
                "I'd try to steer the conversation toward lighter, more social topics like music, movies, or current events."
            ),
        },
    },
    "frequency_v2_q0200": {
        "prompt": (
            'Your partner keeps suggesting changes to your clothes or hairstyle, saying, "You\'d look better if you did it this way."'
        ),
        "options": {
            "frequency_v2_q0200_a": (
                "I'd trust their taste and happily try the style to make them happy."
            ),
            "frequency_v2_q0200_b": (
                "I might try it a few times, but fundamentally I'd stick with what I like."
            ),
            "frequency_v2_q0200_c": (
                "My appearance is entirely my own; I'd clearly say that I don't like them interfering with it."
            ),
            "frequency_v2_q0200_d": (
                "If I think the criticism makes sense, I'd take it on board, but I wouldn't change my style just because they want me to."
            ),
        },
    },
}

LATER_REVIEW_FILES = [
    "frequency_v2_en_review_201_250.md",
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
    for path, lo, hi in [
        (BATCH_001, 1, 50),
        (BATCH_002, 51, 100),
        (BATCH_003, 101, 150),
    ]:
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
        rel = f"{rel_dir}/{name}"
        path = OUT / "en_human_review" / name
        path.write_bytes(head_bytes_for_review(rel))


def annotate_q0160_source_issue() -> None:
    text = REVIEW_151_200.read_text(encoding="utf-8")
    marker = f"## {SOURCE_TR_ISSUE_ID}"
    if marker not in text:
        raise SystemExit(f"missing {SOURCE_TR_ISSUE_ID} section in review markdown")
    if "SOURCE_TR_ISSUE" in text:
        return
    insert = (
        "\n- **human_review_decision:** `SOURCE_TR_ISSUE`\n"
        "- **human_review_note:** Turkish stem places the overnight stay at the partner's home, "
        "but option logic treats the toothbrush/T-shirt as entering the user's personal space. "
        "TR and EN text unchanged pending explicit source correction.\n"
    )
    pattern = re.compile(
        rf"(## {re.escape(SOURCE_TR_ISSUE_ID)}\n\n"
        rf"- \*\*primary_dimension:\*\*[^\n]+\n"
        rf"- \*\*semantic_cluster:\*\*[^\n]+\n"
        rf"- \*\*translation_review_status:\*\* `PENDING_HUMAN_REVIEW`)"
    )
    updated, n = pattern.subn(r"\1" + insert, text, count=1)
    if n != 1:
        raise SystemExit("failed to annotate q0160 SOURCE_TR_ISSUE in review markdown")
    REVIEW_151_200.write_text(updated, encoding="utf-8")


def main() -> None:
    assert_prior_batches_unchanged()
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    batch = json.loads(BATCH_004.read_text(encoding="utf-8"))
    items = batch["items"]
    q0160_prompt_before = items[SOURCE_TR_ISSUE_ID]["prompt"]
    q0160_options_before = dict(items[SOURCE_TR_ISSUE_ID]["options"])

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 004: {iid}")
    if SOURCE_TR_ISSUE_ID not in items:
        raise SystemExit(f"Missing item in batch 004: {SOURCE_TR_ISSUE_ID}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    if items[SOURCE_TR_ISSUE_ID]["prompt"] != q0160_prompt_before:
        raise SystemExit("q0160 prompt changed unexpectedly")
    if items[SOURCE_TR_ISSUE_ID]["options"] != q0160_options_before:
        raise SystemExit("q0160 options changed unexpectedly")
    items[SOURCE_TR_ISSUE_ID]["translation_review_status"] = "PENDING_HUMAN_REVIEW"

    BATCH_004.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()
    annotate_q0160_source_issue()

    # Force q0160 pending after build in case triage flags override explicit status.
    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    for row in en_review["items"]:
        if row["item_id"] == SOURCE_TR_ISSUE_ID:
            row["translation_review_status"] = "PENDING_HUMAN_REVIEW"
            break
    else:
        raise SystemExit("q0160 missing from EN review metadata")
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    rev = {r["item_id"]: r for r in en_review["items"]}
    by_id = {it["item_id"]: it for it in en_pool["items"]}

    q178 = by_id["frequency_v2_q0178"]["prompt"]
    assert "You're on a 40-minute drive." in q178
    assert "Forty minutes into a drive" not in q178
    q189 = by_id["frequency_v2_q0189"]["prompt"]
    assert "completely free day off" in q189
    q190 = by_id["frequency_v2_q0190"]["prompt"]
    assert "At noon on the weekend" in q190
    assert "Saturday afternoon" not in q190
    q193a = next(
        o["text"] for o in by_id["frequency_v2_q0193"]["options"] if o["option_id"].endswith("_a")
    )
    assert "keep the gift" in q193a
    assert "stash the gift" not in q193a.lower()
    q195a = next(
        o["text"] for o in by_id["frequency_v2_q0195"]["options"] if o["option_id"].endswith("_a")
    )
    assert "enter their password and secretly read the message" in q195a

    for i in range(1, 160):
        iid = f"frequency_v2_q{i:04d}"
        if i == 160:
            assert rev[iid]["translation_review_status"] == "PENDING_HUMAN_REVIEW", iid
        else:
            assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(161, 201):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(201, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 199

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    assert "SOURCE_TR_ISSUE" in REVIEW_151_200.read_text(encoding="utf-8")

    print("Phase 6E batch 151-200 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")
    print("q0160 SOURCE_TR_ISSUE left PENDING_HUMAN_REVIEW (TR/EN unchanged).")
    print(f"Total REVIEWED after apply: {reviewed_count}")


if __name__ == "__main__":
    main()
