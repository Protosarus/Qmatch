#!/usr/bin/env python3
"""Generate assets/data/assessment_sets/eq_sets.json — 50 sets × 10 questions (Step 15B)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/data/assessment_sets/eq_sets.json"

# --- 25 × 20 = 500 unique scenario stems (English), dating/social-focused ---
WHO = [
    "Someone you've been seeing for a few weeks",
    "A person you're newly dating",
    "Someone you've matched with and have met twice",
    "Your partner on an ordinary weekday evening",
    "A close friend you're texting late evening",
    "Someone you're casually dating",
    "A friend you're planning a trip with",
    "Someone you've started seeing exclusively",
    "Your partner before an important family dinner",
    "A newer friend in your wider social circle",
    "Someone you're dating long-distance this month",
    "A roommate you're friendly with",
    "Someone you're seeing who shares your hobby group",
    "Your partner after a stressful work week",
    "A friend who knows your dating history well",
    "Someone you're messaging consistently but haven't labeled yet",
    "A coworker you've begun spending social time with",
    "Someone you're dating who travels often for work",
    "Your partner when you're both tired",
    "A friend who's going through a rough patch",
    "Someone you're seeing who is quieter than you",
    "A partner when plans suddenly change",
    "Someone new you're dating who is very busy",
    "A friend after you canceled plans once",
    "Someone you're seeing who brings up sensitive topics lightly",
]

WHAT = [
    "seems quieter than usual and answers in short replies.",
    "forgets to confirm evening plans until the last minute.",
    "mentions an ex casually during a date-night conversation.",
    "looks tense when you bring up meeting each other's friends.",
    "changes the subject when you ask how they're really doing.",
    "double-texts apologies after you replied slower than usual.",
    "shares good news and watches closely for your reaction.",
    "interrupts once while you're explaining something personal.",
    "admits they're jealous without much context yet.",
    "asks for reassurance after you seemed distracted on a call.",
    "teases you in front of others in a way that lands awkwardly.",
    "posts something vague online that might be about your argument.",
    "asks you to skip an event you'd already invited them to.",
    "mentions feeling insecure about their appearance tonight.",
    "shares stress about money when you've planned something pricey.",
    "questions your tone after a message that wasn't meant sharply.",
    "asks why you liked someone's photo from years ago.",
    "needs alone time right after an emotionally heavy conversation.",
    "compares their habits to yours in a competitive tone.",
    "says they're fine even though their body language disagrees.",
]


def stem_for_index(i: int) -> str:
    return (
        f"{WHO[i % len(WHO)]} {WHAT[(i // len(WHO)) % len(WHAT)]} "
        "What's your most likely response?"
    )


# Option quartets aligned with WHAT[] clause index (same order as WHAT list above).
# Each tuple: (four options, index of strongest EQ choice before rotation).
EQ_BANKS_BY_WHAT_IDX: list[tuple[list[str], int]] = [
    (
        [
            "Assume they're busy and wait silently for weeks",
            "Check in kindly, name what you noticed, and ask what would help",
            "Send a long analysis of what they might be feeling",
            "Match short replies to teach them a lesson",
        ],
        1,
    ),
    (
        [
            "Assume they're flaky and start dating others immediately without a word",
            "Ask for a quick clarity window and offer flexibility if they're stretched",
            "Lecture them about communication etiquette",
            "Pretend you didn't notice and hope it resolves",
        ],
        1,
    ),
    (
        [
            "Tell them never to mention their past again",
            "Stay curious and ask how those memories land for them—without interrogating",
            "Immediately compare them to your ex to lighten the mood",
            "Withdraw affection to show you're offended",
        ],
        1,
    ),
    (
        [
            "Push them to commit to a firm date this minute",
            "Acknowledge the tension and explore what would feel comfortable step by step",
            "Assume they're ashamed of you",
            "Cancel all social plans to avoid the conversation",
        ],
        1,
    ),
    (
        [
            "Push harder until they explain fully tonight",
            "Acknowledge the dodge and offer to revisit when they're ready",
            "Assume they're hiding something serious",
            "Send ten follow-up questions immediately",
        ],
        1,
    ),
    (
        [
            "Tell them to calm down and stop apologizing",
            "Reassure proportionately and clarify your bandwidth without shame",
            "Ignore the extra messages",
            "Match anxiety with rapid-fire replies every minute",
        ],
        1,
    ),
    (
        [
            "Downplay so they don't get a big head",
            "Mirror enthusiasm and ask follow-ups that show you're genuinely happy for them",
            "Make it about your own news immediately",
            "Tease them for caring too much",
        ],
        1,
    ),
    (
        [
            "Interrupt back to regain floor time",
            "Pause and invite them to finish—then share your piece calmly",
            "Shut down and stop talking",
            "Correct them sharply for cutting you off",
        ],
        1,
    ),
    (
        [
            "Dismiss it as irrational immediately",
            "Stay steady, thank them for honesty, and explore what's underneath",
            "Punish them with sarcasm",
            "Offer exhaustive proof without listening",
        ],
        1,
    ),
    (
        [
            "Tell them they're too needy",
            "Validate the worry and ask what reassurance would actually help",
            "Perform elaborate reassurance theater without listening",
            "Punish them by acting colder",
        ],
        1,
    ),
    (
        [
            "Make the same joke louder so everyone laughs",
            "Privately tell them it landed awkwardly and reset kindly",
            "Call them out sharply in front of the group",
            "Withdraw and stay cold the rest of the night",
        ],
        1,
    ),
    (
        [
            "Reply passive-aggressively online",
            "Address it directly in private without turning it into a trial",
            "Post something vague back",
            "Ask mutual friends to investigate",
        ],
        1,
    ),
    (
        [
            "Say yes anyway and resent it quietly",
            "Name your limit kindly and propose an alternative",
            "Cancel everything dramatically",
            "Guilt them into changing their plans",
        ],
        1,
    ),
    (
        [
            "Tell them they're being dramatic",
            "Affirm what you appreciate about them and invite them to share what's underneath",
            "Compare them to someone confident",
            "Ignore because compliments should fix everything",
        ],
        1,
    ),
    (
        [
            "Take their stress personally and escalate",
            "Validate pressure and ask what realistic version of the plan feels doable",
            "Ignore the money worry",
            "Insist they owe you the expensive plan",
        ],
        1,
    ),
    (
        [
            "Mirror sarcasm until they stop",
            "Clarify intent calmly and invite them to share their read",
            "Cold-shoulder them for days",
            "Screenshot and escalate publicly",
        ],
        1,
    ),
    (
        [
            "Demand passwords to feel safe",
            "Acknowledge discomfort and discuss boundaries without interrogation",
            "Retaliate by liking random posts",
            "Assume cheating without conversation",
        ],
        1,
    ),
    (
        [
            "Chase them for constant reassurance",
            "Support space and schedule a gentle check-in later",
            "Punish withdrawal with silence",
            "Show up uninvited to force closeness",
        ],
        1,
    ),
    (
        [
            "Escalate into a competition spiral",
            "Name the pattern lightly and steer toward teamwork instead of scorekeeping",
            "Withdraw affection to win",
            "One-up them harder next time",
        ],
        1,
    ),
    (
        [
            "Force them to admit they're upset immediately",
            "Name what you observe gently and invite honesty without pressure",
            "Mirror their 'fine' and go icy",
            "List evidence until they concede",
        ],
        1,
    ),
]


def option_quartets(what_idx: int, seed: int) -> tuple[list[str], int]:
    """Return (four options, correctAnswer index 0..3). Best EQ answer position rotates by seed."""
    opts, best = EQ_BANKS_BY_WHAT_IDX[what_idx % len(EQ_BANKS_BY_WHAT_IDX)]
    shift = seed % 4
    rotated = opts[shift:] + opts[:shift]
    correct = (best - shift) % 4
    return rotated, correct


def difficulty_for(i: int) -> int:
    return [1, 2, 2, 3][i % 4]


def build_questions() -> list[dict]:
    out: list[dict] = []
    for i in range(500):
        what_idx = (i // len(WHO)) % len(WHAT)
        opts, correct = option_quartets(what_idx, seed=i)
        set_idx = i // 10 + 1
        q_idx = i % 10 + 1
        qid = f"eq_set_{set_idx:03d}_q{q_idx:02d}"
        out.append(
            {
                "id": qid,
                "question": stem_for_index(i),
                "options": opts,
                "correctAnswer": correct,
                "difficulty": difficulty_for(i),
            }
        )
    return out


def build_sets() -> list[dict]:
    qs = build_questions()
    sets_out: list[dict] = []
    for s in range(50):
        chunk = qs[s * 10 : (s + 1) * 10]
        sets_out.append(
            {
                "id": f"eq_set_{s + 1:03d}",
                "type": "eq",
                "set_number": s + 1,
                "version": "2026_01",
                "active": True,
                "question_count": 10,
                "questions": chunk,
            }
        )
    return sets_out


def validate(sets: list[dict]) -> None:
    assert len(EQ_BANKS_BY_WHAT_IDX) == len(WHAT)
    assert len(sets) == 50
    texts: set[str] = set()
    qids: set[str] = set()
    sids: set[str] = set()
    for st in sets:
        assert st["id"] not in sids
        sids.add(st["id"])
        assert st["type"] == "eq"
        assert st["active"] is True
        assert st["version"] == "2026_01"
        assert int(st["id"].split("_")[-1]) == st["set_number"]
        qs = st["questions"]
        assert len(qs) == 10
        assert st["question_count"] == 10
        for q in qs:
            assert q["id"] not in qids
            qids.add(q["id"])
            txt = q["question"].strip()
            assert txt not in texts, txt[:90]
            texts.add(txt)
            assert len(q["options"]) == 4
            ca = q["correctAnswer"]
            assert ca in (0, 1, 2, 3)
            assert q["difficulty"] in (1, 2, 3)


def main() -> None:
    sets = build_sets()
    validate(sets)
    OUT.write_text(json.dumps({"sets": sets}, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(sets)} sets, {len(sets)*10} questions)")


if __name__ == "__main__":
    main()
