#!/usr/bin/env python3
"""Apply Phase 6G human EN semantic review for batch 251-300.

English user-facing wording and translation_review_status only.
Preserves later en_human_review markdown batches from HEAD after rebuild.
q0260: REVIEWED with possible_cultural_mismatch + possible_intensity_drift preserved.
Does not assign structural metadata for q0252 / q0292.
"""
from __future__ import annotations

import json
import subprocess
import sys
from collections import Counter
from pathlib import Path

OUT = Path(__file__).resolve().parent / "out"
ROOT = Path(__file__).resolve().parents[2]
TR_POOL = OUT / "frequency_behavior_pool_tr_v2_draft1.json"
BATCH_006 = OUT / "en_translation_batches/frequency_v2_en_semantic_text_batch_006.json"
MERGED = OUT / "frequency_v2_en_semantic_text_v1.json"
BUILD = Path(__file__).resolve().parent / "build_phase6a_en_semantic_parity_pool.py"
Q0260_ID = "frequency_v2_q0260"
STRUCTURAL_GUARD_IDS = ("frequency_v2_q0252", "frequency_v2_q0292")

REVIEWED_IDS = [f"frequency_v2_q{i:04d}" for i in range(251, 301)]

PATCHES: dict[str, dict] = {
    "frequency_v2_q0251": {
        "prompt": (
            "You're doing the weekly grocery shopping together. "
            "How would you most naturally handle it?"
        ),
        "options": {
            "frequency_v2_q0251_a": (
                "I'd stick to a list I made at home, move through the aisles quickly, "
                "and make sure we get everything on it."
            ),
            "frequency_v2_q0251_b": (
                "I wouldn't stick too closely to the list; I'd browse the shelves "
                "and add whatever we're in the mood for."
            ),
            "frequency_v2_q0251_c": (
                "I'd mostly let them lead, go along with what they choose, and push the cart."
            ),
            "frequency_v2_q0251_d": (
                'Before going in, I\'d split the shopping: "You get these, I\'ll get those," '
                "and we'd meet at the checkout."
            ),
        },
    },
    "frequency_v2_q0252": {
        "options": {
            "frequency_v2_q0252_b": (
                'Even though I\'d be very upset, I\'d say, "It\'s okay, don\'t worry about it," '
                "so they don't feel bad, and I'd drop the subject completely."
            ),
            "frequency_v2_q0252_d": (
                'I\'d calmly say, "What\'s done is done," and focus only on quickly cleaning up the pieces.'
            ),
        },
    },
    "frequency_v2_q0253": {
        "options": {
            "frequency_v2_q0253_a": (
                "I'd never watch it alone. I'd wait for days if necessary until they're ready, "
                "because I wouldn't want to spoil something we do together."
            ),
            "frequency_v2_q0253_b": (
                "I'd give in and watch one episode, but I wouldn't tell them I'd watched it "
                "or give anything away."
            ),
            "frequency_v2_q0253_c": (
                'I\'d say, "I\'m going to keep watching; you can catch up later," and continue on my own.'
            ),
            "frequency_v2_q0253_d": (
                'I\'d try to set a specific day for us to watch together: "So when should we watch it?"'
            ),
        },
    },
    "frequency_v2_q0254": {
        "prompt": (
            "You have a fever and are spending the whole day resting at home. Your partner is home too. "
            "How much contact would you want with them during the day?"
        ),
        "options": {
            "frequency_v2_q0254_a": (
                "I'd want them to come over to me often and stay close for much of the day."
            ),
            "frequency_v2_q0254_b": (
                "Having them check on me now and then or having a few short conversations would be enough."
            ),
            "frequency_v2_q0254_c": (
                "I'd call for them when I need something; otherwise I'd keep to myself."
            ),
            "frequency_v2_q0254_d": (
                "Until I felt better, I'd keep contact to a minimum and spend most of the time alone."
            ),
        },
    },
    "frequency_v2_q0255": {
        "options": {
            "frequency_v2_q0255_a": (
                "I'd get extremely frustrated in the car, complain about what happened, "
                "and bring down the mood for the rest of the evening."
            ),
            "frequency_v2_q0255_b": (
                'I\'d be disappointed that the tickets went to waste, but I\'d quickly make a new plan: '
                '"In that case, let\'s go eat somewhere."'
            ),
            "frequency_v2_q0255_c": (
                'I\'d stay calm and go along with whatever my partner suggests: "Either is fine—let\'s do that."'
            ),
        },
    },
    "frequency_v2_q0256": {
        "prompt": (
            "You got your partner a gift, but from a split-second expression when they opened it, "
            "you could tell they didn't like it at all."
        ),
        "options": {
            "frequency_v2_q0256_b": (
                'I\'d immediately ask, "You didn\'t like it, did you? Please be honest," '
                "because I'd want to know what they really think."
            ),
            "frequency_v2_q0256_d": (
                "I'd feel a little disappointed, but I'd try not to let it show."
            ),
        },
    },
    "frequency_v2_q0257": {
        "prompt": (
            "You meet your partner's coworkers for the first time. The conversation topics—office gossip "
            "and the like—feel unfamiliar and boring to you."
        ),
        "options": {
            "frequency_v2_q0257_b": (
                "I'd try to understand their world, ask questions, and make an effort to join the conversation."
            ),
            "frequency_v2_q0257_c": (
                "Even if I were bored, I'd act interested and keep smiling so my partner didn't feel left on their own."
            ),
            "frequency_v2_q0257_d": (
                'I\'d text or signal to my partner, "I\'m bored—can we leave soon?"'
            ),
        },
    },
    "frequency_v2_q0258": {
        "prompt": (
            'You share a book or article you find deep and really enjoy with your partner, but they dismiss it with, '
            '"That sounds really boring."'
        ),
        "options": {
            "frequency_v2_q0258_a": (
                "I'd see it as completely normal that we have different tastes and wouldn't bring it up again."
            ),
            "frequency_v2_q0258_c": (
                "Deep down, I'd feel an intellectual disconnect, and it would make me pull back a little."
            ),
        },
    },
    "frequency_v2_q0259": {
        "prompt": "When you wake up in the morning, how do you usually like to start the day?",
        "options": {
            "frequency_v2_q0259_b": (
                "I need at least half an hour of quiet and my coffee; talking first thing wears me out."
            ),
            "frequency_v2_q0259_d": (
                "I'd get out of bed quickly and start getting ready for work or the day; "
                "I don't spend much time on romantic morning routines."
            ),
        },
    },
    "frequency_v2_q0260": {
        "prompt": (
            'A close friend suddenly texts, "I\'m downstairs—I\'m coming up for coffee," '
            "while you're at home with your partner, who looks a bit disheveled."
        ),
        "options": {
            "frequency_v2_q0260_a": (
                'I\'d tell my friend, "Now isn\'t a good time; let\'s make plans for later," '
                "to protect my partner's space."
            ),
            "frequency_v2_q0260_b": (
                'I\'d let my friend in and tell my partner, "It\'s fine, they\'re not a stranger," '
                "expecting them to go along with it."
            ),
            "frequency_v2_q0260_c": (
                'I\'d panic and tell my partner, "My friend is coming up—quick, get ready," '
                "while hurriedly tidying the place."
            ),
            "frequency_v2_q0260_d": (
                'I\'d tell my partner, "You can hang out in the bedroom if you want; we\'ll sit in the living room," '
                "so they have somewhere to retreat."
            ),
        },
    },
    "frequency_v2_q0261": {
        "prompt": (
            "You have a minor misunderstanding. Your partner tries to explain it at length and in great detail, "
            "repeatedly defending themselves."
        ),
        "options": {
            "frequency_v2_q0261_c": (
                "While they're explaining, I'd feel the need to spend just as long describing how the situation made me feel."
            ),
            "frequency_v2_q0261_d": (
                'I\'d feel overwhelmed by how long it\'s going on and say, "Okay, it\'s not important—let\'s move on."'
            ),
        },
    },
    "frequency_v2_q0262": {
        "prompt": (
            "You receive an unexpectedly large bonus at work. You've only been together for four months."
        ),
        "options": {
            "frequency_v2_q0262_a": (
                "I'd call them right away and excitedly share both my happiness and the amount."
            ),
            "frequency_v2_q0262_c": (
                "Because I see it as my own financial achievement, I wouldn't even feel a need to mention it."
            ),
            "frequency_v2_q0262_d": (
                'On our next date, I\'d treat them to something nice, say, "Work went well," and leave it at that.'
            ),
        },
    },
    "frequency_v2_q0263": {
        "prompt": (
            "While you're working or sitting together, a repetitive sound your partner is making—tapping a pen, "
            "bouncing a leg, etc.—starts to irritate you intensely."
        ),
        "options": {
            "frequency_v2_q0263_b": (
                "I'd hesitate to say anything, put up with it, or leave the room and deal with it on my own."
            ),
            "frequency_v2_q0263_c": (
                "I'd show that it bothers me indirectly, with a joke or an exaggerated reaction such as sighing."
            ),
            "frequency_v2_q0263_d": (
                "I'd put on music or shift my attention elsewhere and try to tolerate the sound."
            ),
        },
    },
    "frequency_v2_q0264": {
        "prompt": "You receive very bad news about something in your own life. How would you tell your partner?",
        "options": {
            "frequency_v2_q0264_a": (
                "In the shock of the moment, I'd call them right away and tell them while crying or panicking."
            ),
            "frequency_v2_q0264_b": (
                "I'd process it on my own first, decide what to do, and then only tell them where things stand."
            ),
            "frequency_v2_q0264_c": (
                'To avoid upsetting them too much, I\'d soften how I tell it and use a "we\'ll deal with it" tone.'
            ),
        },
    },
    "frequency_v2_q0265": {
        "prompt": (
            "You're out with your partner, and they're having a great time. But your social battery is completely "
            "drained and you want to go home."
        ),
        "options": {
            "frequency_v2_q0265_a": (
                'I\'d say, "You stay and keep having fun; I\'m taking a cab home," and head back on my own.'
            ),
            "frequency_v2_q0265_b": (
                "I wouldn't say anything because I wouldn't want to spoil their fun; even though I'm drained, "
                "I'd stay with them until the night is over."
            ),
        },
    },
    "frequency_v2_q0267": {
        "prompt": (
            "You're one year into the relationship. Your partner tells you about the country they'd like to live in "
            "five years from now or the kind of home they dream of having."
        ),
        "options": {
            "frequency_v2_q0267_b": (
                "I'd say it sounds great, but making plans that far ahead always gives me a sense of uncertainty."
            ),
            "frequency_v2_q0267_c": (
                "I'd question how realistic those dreams are, both logically and financially."
            ),
            "frequency_v2_q0267_d": (
                'I\'d listen, but say, "Five years is a long way off; let\'s focus on the present first," '
                "and bring the conversation back to now."
            ),
        },
    },
    "frequency_v2_q0268": {
        "options": {
            "frequency_v2_q0268_b": (
                "I'd negotiate until we find a reasonable middle ground, such as agreeing on a set AC temperature."
            ),
            "frequency_v2_q0268_c": (
                "I'd suggest spending time in different rooms so each of us can be comfortable."
            ),
            "frequency_v2_q0268_d": (
                'I\'d say, "I\'m freezing—close it," and firmly insist on my own physical comfort.'
            ),
        },
    },
    "frequency_v2_q0269": {
        "prompt": (
            "You sign up for a new hobby class—ceramics, coding, etc.—that takes up two evenings a week and is just for you."
        ),
        "options": {
            "frequency_v2_q0269_a": (
                "I'd treat it as my own private space and world, talk about it very little, "
                "and preserve that part of my individuality."
            ),
            "frequency_v2_q0269_b": (
                "After each class, I'd tell them in detail what I learned so they feel mentally included in the experience."
            ),
            "frequency_v2_q0269_c": (
                "If they wanted to join too, I'd be very happy and suggest turning the class into a shared activity."
            ),
            "frequency_v2_q0269_d": (
                "To keep them from feeling that the time I spend on my hobby is pulling me away, "
                "I'd give them more attention on the other days."
            ),
        },
    },
    "frequency_v2_q0271": {
        "prompt": (
            "The room you're staying in on vacation isn't what you expected, and you need to make a quick decision "
            "about what to do that day. What do you do?"
        ),
        "options": {
            "frequency_v2_q0271_a": (
                "I'd make a clear change to the plan based on the situation and find a different way to spend the day."
            ),
            "frequency_v2_q0271_b": (
                "I'd try a small fix first; if it didn't work, I'd change the plan."
            ),
            "frequency_v2_q0271_c": (
                "I'd wait for a while to see if the original situation could be fixed, and only then change the plan."
            ),
            "frequency_v2_q0271_d": (
                "I wouldn't want to change the current plan until the conditions we expected were actually available."
            ),
        },
    },
    "frequency_v2_q0272": {
        "options": {
            "frequency_v2_q0272_a": (
                "I wouldn't get hung up on their relationship history; I'd focus on the point of the story—the movie—and keep the conversation going."
            ),
            "frequency_v2_q0272_d": (
                "I'd take it as a sign of honesty and openness and share a similar memory from my own past."
            ),
        },
    },
    "frequency_v2_q0275": {
        "options": {
            "frequency_v2_q0275_a": (
                'I\'d take pride in their achievement almost as if it were my own and proudly tell people about it with a "We did it" attitude.'
            ),
        },
    },
    "frequency_v2_q0276": {
        "options": {
            "frequency_v2_q0276_a": (
                "Without thinking much, I'd openly tell them the deeper story behind it, very honestly and without filtering myself."
            ),
        },
    },
    "frequency_v2_q0277": {
        "options": {
            "frequency_v2_q0277_d": (
                "We'd make a shared list. I'd do my share and leave it up to them when they do theirs."
            ),
        },
    },
    "frequency_v2_q0279": {
        "prompt": (
            "You're out with friends, your phone has died, and you've been unable to contact your partner for five hours."
        ),
        "options": {
            "frequency_v2_q0279_a": (
                "It wouldn't bother me; I'd focus on my time with my friends and charge my phone when I got home."
            ),
            "frequency_v2_q0279_b": (
                "I'd think my partner might worry, so I'd use someone else's phone or a venue's phone to give them a quick update."
            ),
            "frequency_v2_q0279_c": (
                "They'd stay on my mind, and I'd keep stressing about whether they'd sent me something while I was offline."
            ),
        },
    },
    "frequency_v2_q0280": {
        "options": {
            "frequency_v2_q0280_d": (
                'I\'d say, "You go have fun; I\'ll rest at home and wait for you," and let them enjoy the evening without me.'
            ),
        },
    },
    "frequency_v2_q0281": {
        "prompt": (
            "You're in the first weeks of a new relationship. While you're walking together, your partner starts "
            "becoming noticeably more physically affectionate. What do you do?"
        ),
        "options": {
            "frequency_v2_q0281_a": (
                "I'd comfortably reciprocate and let the physical closeness grow naturally."
            ),
            "frequency_v2_q0281_c": (
                "I'd keep the physical closeness more limited and want a little more time."
            ),
            "frequency_v2_q0281_d": (
                "I'd clearly say that I'd prefer physical closeness to develop more slowly for now."
            ),
        },
    },
    "frequency_v2_q0282": {
        "prompt": (
            "Your partner makes what you consider a luxury purchase, such as an expensive bag or watch. "
            "You're someone who prefers to save money."
        ),
        "options": {
            "frequency_v2_q0282_b": (
                "I'd start privately thinking about whether our different attitudes toward money could become a problem in the future."
            ),
            "frequency_v2_q0282_c": (
                'I\'d jokingly say, "You paid that much for this?" and make my own view on spending clear.'
            ),
            "frequency_v2_q0282_d": (
                "I'd focus on how much they're enjoying it and adapt, reminding myself that spending money can be one of life's pleasures."
            ),
        },
    },
    "frequency_v2_q0283": {
        "prompt": (
            "You wake up at 3 a.m. with intense anxiety or fear about the future. Your partner is asleep beside you."
        ),
        "options": {
            "frequency_v2_q0283_a": (
                "I'd wake them up and ask them to hug me and talk with me until I calm down."
            ),
            "frequency_v2_q0283_c": (
                "I'd just hold them more tightly; even if they stayed asleep, their body warmth would reassure me."
            ),
        },
    },
    "frequency_v2_q0285": {
        "prompt": (
            'You\'re driving or walking somewhere together when your partner says, "We\'ve never gone down this street before—want to turn here?"'
        ),
        "options": {
            "frequency_v2_q0285_a": (
                "I'd think it's a great idea; I enjoy getting a little lost or discovering new routes more than just heading straight to the destination."
            ),
            "frequency_v2_q0285_b": (
                "I'd say okay, but privately I'd start calculating whether it would take much longer or whether there might be traffic."
            ),
            "frequency_v2_q0285_c": (
                'I\'d say, "Let\'s not take a road we don\'t know; let\'s follow the GPS," and stick to the plan.'
            ),
            "frequency_v2_q0285_d": (
                'I\'d say, "Either way is fine." If they\'re leading the way, I\'d relax and enjoy it.'
            ),
        },
    },
    "frequency_v2_q0289": {
        "prompt": (
            "Your partner openly shows you a birthday message from their ex, says, \"My ex wished me a happy birthday,\" and then deletes it."
        ),
        "options": {
            "frequency_v2_q0289_c": (
                'I\'d ask why they deleted it and analyze what that meant: "You didn\'t need to delete it."'
            ),
            "frequency_v2_q0289_d": (
                'I\'d draw a clear boundary by asking, "You\'re not going to reply, right?"'
            ),
        },
    },
    "frequency_v2_q0290": {
        "options": {
            "frequency_v2_q0290_a": (
                "I'd take them to the hospital against their will or physically stop them from going to work, "
                "making the decision for them because I think it's best for them."
            ),
            "frequency_v2_q0290_c": (
                "I'd offer to go to work with them or stay on a video call all day so I could keep an eye on them."
            ),
            "frequency_v2_q0290_d": (
                "I'd try to explain, using medical or practical evidence, why their body needs rest."
            ),
        },
    },
    "frequency_v2_q0291": {
        "prompt": (
            "In a relationship, how do you feel about having access to each other's digital calendars—work, appointments, where you'll be and when?"
        ),
        "options": {
            "frequency_v2_q0291_a": (
                'I\'d think it\'s a great idea. We wouldn\'t have to keep asking, "What\'s your plan today?" '
                "and everything would be transparent and organized."
            ),
            "frequency_v2_q0291_b": (
                "Not for me. I wouldn't want to share a calendar in a way that feels like I have to account for where I am all the time."
            ),
            "frequency_v2_q0291_d": (
                "I don't really like keeping a calendar anyway; I'd rather just check in with each other as things come up during the day."
            ),
        },
    },
    "frequency_v2_q0292": {
        "options": {
            "frequency_v2_q0292_a": (
                "My immediate reaction would be to yell and get angry, letting the stress show physically."
            ),
            "frequency_v2_q0292_b": (
                "I'd show no emotion at first; I'd grab a cloth and focus only on cleaning up and assessing the damage."
            ),
            "frequency_v2_q0292_c": (
                'If they were panicking, I\'d focus more on calming them than on the computer and say, "It\'s okay."'
            ),
            "frequency_v2_q0292_d": (
                "Even if I were very upset, I'd hold it in and go quiet because they hadn't done it on purpose."
            ),
        },
    },
    "frequency_v2_q0293": {
        "prompt": (
            "How much of the everyday gossip from work or your friend group do you share with your partner?"
        ),
        "options": {
            "frequency_v2_q0293_a": (
                "I'd excitedly tell them every detail—who said what to whom—as soon as I got home."
            ),
            "frequency_v2_q0293_b": (
                "I'd only mention it briefly if it involved someone they know or something they'd genuinely find interesting."
            ),
            "frequency_v2_q0293_c": (
                "I keep my outside social world separate from my relationship; I wouldn't spend our time at home on that kind of gossip."
            ),
        },
    },
    "frequency_v2_q0294": {
        "prompt": (
            "When you sleep, you like your side of the bed warm while your partner likes theirs cool. "
            "How do you handle the temperature difference?"
        ),
        "options": {
            "frequency_v2_q0294_a": (
                "I'd use separate duvets or blankets of different weights so each of us could have our own temperature zone."
            ),
            "frequency_v2_q0294_c": (
                "I'd set the heating or AC to an exact middle temperature so neither of us gets completely their own way."
            ),
            "frequency_v2_q0294_d": (
                "I'd adjust my own covers after they fell asleep rather than turn it into something we negotiate in bed."
            ),
        },
    },
    "frequency_v2_q0296": {
        "options": {
            "frequency_v2_q0296_d": (
                "I'd be happy to see them enjoying their food, laugh as I turn down the offer, and not make an issue of it."
            ),
        },
    },
    "frequency_v2_q0297": {
        "options": {
            "frequency_v2_q0297_a": (
                'I\'d get really annoyed; it would feel like they\'re intruding on my space. I\'d say, "I can do it myself—let me handle it."'
            ),
            "frequency_v2_q0297_b": (
                "I'd gladly let them take over; I'd like that they made the task easier and took some of the load off me."
            ),
            "frequency_v2_q0297_c": (
                'I\'d immediately turn it into teamwork: "Let\'s do it together—you hold it, I\'ll tighten it."'
            ),
            "frequency_v2_q0297_d": (
                "I'd watch them do it while giving advice, trying to keep some logical control over the process."
            ),
        },
    },
    "frequency_v2_q0298": {
        "options": {
            "frequency_v2_q0298_a": (
                "I'd be really upset that the day was ruined and complain about our bad luck for hours."
            ),
            "frequency_v2_q0298_b": (
                "Even with the rain, I'd create a festival atmosphere at home—put on music and have a picnic in the middle of the living room."
            ),
            "frequency_v2_q0298_c": (
                'I\'d say, "Nothing we can do," and immediately switch to a normal day at home in my pajamas.'
            ),
            "frequency_v2_q0298_d": (
                "I'd immediately look up indoor Plan B options, like a movie or museum, and suggest them."
            ),
        },
    },
    "frequency_v2_q0299": {
        "prompt": (
            "You're at a party together, the atmosphere is really dull, and your partner says they're bored too. How do you leave?"
        ),
        "options": {
            "frequency_v2_q0299_a": (
                'I\'d say, "Let\'s go," and we\'d slip out without telling anyone, or just send the host a message.'
            ),
            "frequency_v2_q0299_b": (
                "We'd politely say goodbye to everyone one by one, make some excuse about being tired, and leave."
            ),
        },
    },
    "frequency_v2_q0300": {
        "prompt": (
            "In the third year of your relationship, your partner goes in a completely different spiritual or philosophical direction—for example, minimalism or a retreat-oriented lifestyle."
        ),
        "options": {
            "frequency_v2_q0300_a": (
                "I know what my own path and beliefs are. I'd respect theirs, but I wouldn't involve myself in this new philosophy."
            ),
            "frequency_v2_q0300_b": (
                "I'd really want to go on that journey with them and explore the philosophy together."
            ),
            "frequency_v2_q0300_c": (
                'The speed of the change would scare me, and I\'d resist adapting by asking, "What happened to how we used to be?"'
            ),
        },
    },
}

LATER_REVIEW_FILES = [
    "frequency_v2_en_review_301_350.md",
    "frequency_v2_en_review_351_400.md",
    "frequency_v2_en_review_401_426.md",
]

Q0260_FLAGS = ["possible_cultural_mismatch", "possible_intensity_drift"]


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


def preserve_q0260_metadata(en_review: dict) -> None:
    for row in en_review["items"]:
        if row["item_id"] != Q0260_ID:
            continue
        row["translation_review_status"] = "REVIEWED"
        flags = list(row.get("translation_review_flags") or [])
        for flag in Q0260_FLAGS:
            if flag not in flags:
                flags.append(flag)
        row["translation_review_flags"] = flags
        return
    raise SystemExit("q0260 missing from EN review metadata")


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


def main() -> None:
    assert_prior_batches_unchanged()
    structural_before = load_structural_snapshot()
    later_heads = {
        name: head_bytes_for_review(f"tool/frequency_behavior_v2/out/en_human_review/{name}")
        for name in LATER_REVIEW_FILES
    }

    batch = json.loads(BATCH_006.read_text(encoding="utf-8"))
    items = batch["items"]

    for iid in REVIEWED_IDS:
        if iid not in items:
            raise SystemExit(f"Missing item in batch 006: {iid}")

    for iid, patch in PATCHES.items():
        if iid not in items:
            raise SystemExit(f"Patch target missing: {iid}")
        apply_patches_to_item(items[iid], patch)

    for iid in REVIEWED_IDS:
        items[iid]["translation_review_status"] = "REVIEWED"

    items[Q0260_ID]["translation_review_flags"] = list(Q0260_FLAGS)

    BATCH_006.write_text(json.dumps(batch, ensure_ascii=False, indent=2), encoding="utf-8")

    merged = merge_batches(OUT / "en_translation_batches")
    MERGED.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")

    result = subprocess.run([sys.executable, str(BUILD)], check=False)
    if result.returncode != 0:
        raise SystemExit(result.returncode)

    restore_later_review_files()
    assert_structural_snapshot_unchanged(structural_before)

    en_review_path = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
    en_review = json.loads(en_review_path.read_text(encoding="utf-8"))
    preserve_q0260_metadata(en_review)
    recompute_review_stats(en_review)
    en_review_path.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")

    en_pool = json.loads((OUT / "frequency_behavior_pool_en_v2_draft1.json").read_text())
    rev = {r["item_id"]: r for r in en_review["items"]}
    by_id = {it["item_id"]: it for it in en_pool["items"]}

    q258 = by_id["frequency_v2_q0258"]["prompt"]
    assert "dismiss it with" in q258.lower()
    assert "cut you off" not in q258.lower()
    q260 = by_id[Q0260_ID]["prompt"]
    assert "looks a bit disheveled" in q260
    q260c = next(o["text"] for o in by_id[Q0260_ID]["options"] if o["option_id"].endswith("_c"))
    assert "panic-text" not in q260c.lower()
    q265 = by_id["frequency_v2_q0265"]["prompt"]
    assert "they're having a great time" in q265.lower()
    q268d = next(o["text"] for o in by_id["frequency_v2_q0268"]["options"] if o["option_id"].endswith("_d"))
    assert q268d == 'I\'d say, "I\'m freezing—close it," and firmly insist on my own physical comfort.'
    q281 = by_id["frequency_v2_q0281"]["prompt"]
    assert q281.startswith("You're in the first weeks")
    assert "In the first weeks of a new relationship." not in q281
    q285d = next(o["text"] for o in by_id["frequency_v2_q0285"]["options"] if o["option_id"].endswith("_d"))
    assert "leading the way" in q285d
    assert "steering" not in q285d.lower()
    q294 = by_id["frequency_v2_q0294"]["prompt"]
    assert "balance achieved in bed" not in q294.lower()
    q229 = by_id["frequency_v2_q0229"]["prompt"]
    assert "Your partner thinks they're right, and you're insisting on your own view." in q229
    assert "you think your partner is right" not in q229.lower()
    q223 = by_id["frequency_v2_q0223"]["prompt"]
    assert "They like to plan things carefully" in q223
    q225 = by_id["frequency_v2_q0225"]["prompt"]
    assert "imagining a future together" in q225
    q240b = next(o["text"] for o in by_id["frequency_v2_q0240"]["options"] if o["option_id"].endswith("_b"))
    assert q240b == "I'd give them the broad outline."
    q248 = by_id["frequency_v2_q0248"]["prompt"]
    assert "still figuring things out" in q248
    q236 = by_id["frequency_v2_q0236"]["prompt"]
    assert "very touch-oriented" in q236
    assert "very touchy" not in q236.lower()

    q260_rev = rev[Q0260_ID]
    assert q260_rev["translation_review_status"] == "REVIEWED"
    for flag in Q0260_FLAGS:
        assert flag in (q260_rev.get("translation_review_flags") or [])

    for i in range(1, 301):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] == "REVIEWED", iid
    for i in range(301, 427):
        iid = f"frequency_v2_q{i:04d}"
        assert rev[iid]["translation_review_status"] != "REVIEWED", iid

    reviewed_count = sum(
        1 for r in en_review["items"] if r.get("translation_review_status") == "REVIEWED"
    )
    assert reviewed_count == 300

    for name, head in later_heads.items():
        path = OUT / "en_human_review" / name
        if path.read_bytes() != head:
            raise SystemExit(f"later review file changed: {name}")

    print("Phase 6G batch 251-300 applied successfully.")
    print(f"Patched items with wording changes: {len(PATCHES)}")
    print(f"Marked REVIEWED: {len(REVIEWED_IDS)}")
    print("q0260 REVIEWED with cultural flags preserved.")
    print(f"Total REVIEWED: {reviewed_count}")


if __name__ == "__main__":
    main()
