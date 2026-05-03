#!/usr/bin/env python3
"""Generate assets/data/assessment_sets/iq_sets.json — 50 sets × 10 IQ questions (Step 15C)."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/data/assessment_sets/iq_sets.json"

# Per set: 3× difficulty 1, 4× difficulty 2, 3× difficulty 3
DIFF_BY_SLOT = [1, 1, 1, 2, 2, 2, 2, 3, 3, 3]

# Slots: 0–1 number seq, 2–3 logic, 4–5 pattern text, 6 analogy, 7 odd-one-out, 8 spatial, 9 mixed


def pack(question: str, ordered_four: list[str], correct_idx_natural: int, forced_idx: int) -> dict:
    """Place correct answer at forced_idx; ordered_four[correct_idx_natural] is correct."""
    assert len(ordered_four) == 4
    assert len(set(ordered_four)) == 4
    correct_val = ordered_four[correct_idx_natural]
    distractors = [ordered_four[i] for i in range(4) if i != correct_idx_natural]
    out_opts: list[str | None] = [None, None, None, None]
    out_opts[forced_idx] = correct_val
    di = 0
    for i in range(4):
        if i == forced_idx:
            continue
        out_opts[i] = distractors[di]
        di += 1
    assert None not in out_opts
    return {"question": question, "options": out_opts, "correctAnswer": forced_idx}


def num_sequence_pair(set_idx: int, slot: int, forced_idx: int) -> dict:
    if slot == 0:
        # Distinct (start, ratio) pairs across all 50 sets.
        r = 2 + (set_idx % 7)
        s = 2 + ((set_idx // 7) % 9)
        terms = [s * (r**i) for i in range(4)]
        nxt = s * (r**4)
        distractors: list[str] = []
        for delta in (1, 3, 5, 7, 9, 11, 13, 17, 19, 23, 29):
            for sign in (1, -1):
                v = nxt + sign * delta * max(s, 1)
                if v <= 0:
                    continue
                st = str(v)
                if st != str(nxt) and st not in distractors:
                    distractors.append(st)
                if len(distractors) == 3:
                    break
            if len(distractors) == 3:
                break
        assert len(distractors) == 3
        ordered = distractors + [str(nxt)]
        opts_unique_list(ordered)
        idx_nat = ordered.index(str(nxt))
        q = f"Which number comes next?\n{terms[0]}, {terms[1]}, {terms[2]}, {terms[3]}, ?"
        return pack(q, ordered, idx_nat, forced_idx)
    t0 = 10 + set_idx
    d1 = 2 + (set_idx % 5)
    d2 = d1 + 1 + ((set_idx // 5) % 2)
    d3 = d2 + 1
    t1 = t0 + d1
    t2 = t1 + d2
    t3 = t2 + d3
    d4 = d3 + 1 + ((set_idx // 10) % 2)
    nxt = t3 + d4
    distractors = [str(nxt + 7), str(t3), str(nxt - d1)]
    ordered = distractors + [str(nxt)]
    opts_unique_list(ordered)
    idx_nat = ordered.index(str(nxt))
    q = f"What comes next in the sequence?\n{t0}, {t1}, {t2}, {t3}, ?"
    return pack(q, ordered, idx_nat, forced_idx)


def opts_unique_list(opts: list[str]) -> None:
    assert len(opts) == len(set(opts)), opts


def logical_pair(set_idx: int, slot: int, forced_idx: int) -> dict:
    # Unique labels per set so premises never repeat across the library.
    n = set_idx + 1
    A, B, C = f"V{n}", f"K{n}", f"R{n}"
    if slot == 2:
        q = (
            f"All {A}s are {B}s. All {B}s are {C}s. "
            f"Which statement must be true?"
        )
        correct = f"Every {A} is a {C}."
        w1 = f"Every {C} is a {A}."
        w2 = f"Some {B}s are not {A}s."
        w3 = f"No {A} is a {B}."
        ordered = [w1, w2, w3, correct]
        opts_unique_list(ordered)
        idx_nat = ordered.index(correct)
        return pack(q, ordered, idx_nat, forced_idx)
    q = (
        f"No {A} is a {B}. Some {C}s are {B}s. "
        f"Which statement cannot be true?"
    )
    impossible = f"Every {C} is a {A}."
    w1 = f"Some {C}s are not {B}s."
    w2 = f"Some {B}s are not {C}s."
    w3 = f"Some {A}s are not {C}s."
    ordered = [w1, w2, w3, impossible]
    opts_unique_list(ordered)
    idx_nat = ordered.index(impossible)
    return pack(q, ordered, idx_nat, forced_idx)


def pattern_pair(set_idx: int, slot: int, forced_idx: int) -> dict:
    pool = [
        "circle",
        "square",
        "triangle",
        "diamond",
        "oval",
        "hexagon",
        "ring",
        "cross",
        "dot",
        "arc",
    ]
    if slot == 4:
        i = set_idx % len(pool)
        j = (set_idx // len(pool) + i + 3) % len(pool)
        if i == j:
            j = (j + 1) % len(pool)
        a, b = pool[i], pool[j]
        correct = b.capitalize()
        q = (
            f"A pattern lists shapes: {a}, {b}, {a}, {b}, {a}. "
            f"What comes next?"
        )
        distractors: list[str] = []
        for delta in range(1, len(pool) + 5):
            cand = pool[(i + delta) % len(pool)].capitalize()
            if cand != correct and cand != a.capitalize() and cand not in distractors:
                distractors.append(cand)
            if len(distractors) == 3:
                break
        assert len(distractors) == 3
        ordered = distractors + [correct]
        opts_unique_list(ordered)
        idx_nat = ordered.index(correct)
        return pack(q, ordered, idx_nat, forced_idx)
    letters = "ABCDEFGHJKLMNPQRSTUVWXYZ"
    n = len(letters)
    i = set_idx % n
    band = set_idx // n
    j = (band + i + 1) % n
    if j == i:
        j = (j + 1) % n
    L1 = letters[i]
    L2 = letters[j]
    if L1 == L2:
        j = (j + 1) % n
        L2 = letters[j]
    correct = L2
    q = (
        f"A code repeats as {L1}, {L2}, {L1}, {L2}, {L1}. "
        f"What is the next symbol?"
    )
    distractors: list[str] = []
    base = set_idx * 5 + 13
    for delta in range(len(letters) + 10):
        cand = letters[(base + delta) % len(letters)]
        if cand != correct and cand != L1 and cand not in distractors:
            distractors.append(cand)
        if len(distractors) == 3:
            break
    assert len(distractors) == 3
    ordered = distractors + [correct]
    opts_unique_list(ordered)
    idx_nat = ordered.index(correct)
    return pack(q, ordered, idx_nat, forced_idx)


def analogy_q(set_idx: int, forced_idx: int) -> dict:
    a_list = [
        "finger",
        "wheel",
        "chapter",
        "tile",
        "stanza",
        "seed",
        "note",
        "rim",
        "switch",
        "scene",
    ]
    b_list = [
        "hand",
        "car",
        "book",
        "floor",
        "poem",
        "tree",
        "scale",
        "wheel",
        "panel",
        "stage",
    ]
    c_list = [
        "leaf",
        "pixel",
        "scene",
        "brick",
        "act",
        "fruit",
        "melody",
        "spoke",
        "bulb",
        "page",
    ]
    d_list = [
        "branch",
        "screen",
        "film",
        "wall",
        "play",
        "orchard",
        "chord",
        "hub",
        "circuit",
        "chapter",
    ]
    i = set_idx % len(a_list)
    a, b, c, d_target = (
        a_list[i],
        b_list[(i + set_idx // 10) % len(b_list)],
        c_list[(i + 3) % len(c_list)],
        d_list[(i + set_idx) % len(d_list)],
    )
    q = f"{a.title()} is to {b} as {c} is to ?"
    correct = d_target.capitalize()
    distractors: list[str] = []
    for lst in (d_list, c_list, b_list, a_list):
        for item in lst:
            cap = item.capitalize()
            if cap != correct and cap not in distractors:
                distractors.append(cap)
            if len(distractors) == 3:
                break
        if len(distractors) == 3:
            break
    assert len(distractors) == 3
    ordered = distractors + [correct]
    opts_unique_list(ordered)
    idx_nat = ordered.index(correct)
    return pack(q, ordered, idx_nat, forced_idx)


def odd_one_out(set_idx: int, forced_idx: int) -> dict:
    # Unique quadruples per set: three multiples of k, one not a multiple.
    k = 2 + (set_idx % 7)
    base = 4 + (set_idx % 11)
    m1, m2, m3 = base * k, (base + 1) * k, (base + 2) * k
    out = m1 + 1
    while out % k == 0 or out in (m1, m2, m3):
        out += 1
    nums = [str(m1), str(m2), str(m3), str(out)]
    assert len(set(nums)) == 4
    ans = str(out)
    rule = f"Three numbers are multiples of {k}; one is not."
    q = f"Which number does not fit the same rule?\n{', '.join(nums)}\n({rule})"
    ordered = nums[:]
    opts_unique_list(ordered)
    idx_nat = ordered.index(ans)
    return pack(q, ordered, idx_nat, forced_idx)


def spatial_text(set_idx: int, forced_idx: int) -> dict:
    letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    chars: list[str] = []
    idx = (set_idx * 3) % 26
    while len(chars) < 6:
        ch = letters[idx % 26]
        if ch not in chars:
            chars.append(ch)
        idx += 1
    fa, fb, fc, fd, fe, ff = chars
    sid = set_idx + 1
    q = (
        f"A cube (layout {sid}) pairs opposite faces as {fa}-{fd}, {fb}-{fe}, {fc}-{ff}. "
        f"Which face is opposite {fb}?"
    )
    correct = fe
    ordered = [fa, fc, fd, fe]
    opts_unique_list(ordered)
    idx_nat = ordered.index(correct)
    return pack(q, ordered, idx_nat, forced_idx)


def mixed_reasoning(set_idx: int, forced_idx: int) -> dict:
    code = 15 + set_idx
    tens = code // 10
    ones = code % 10
    big = tens * 10 + ones
    res = big - (tens + ones)
    cands: list[str] = []
    for delta in (11, -7, 19, -3, 22, -11, 31, 17):
        v = res + delta + set_idx  # tie-break rare ties
        if v <= 0:
            continue
        s = str(v)
        if s != str(res) and s not in cands:
            cands.append(s)
        if len(cands) == 3:
            break
    assert len(cands) == 3
    ordered = cands + [str(res)]
    opts_unique_list(ordered)
    idx_nat = ordered.index(str(res))
    q = (
        f"The two-digit number with tens {tens} and ones {ones}, "
        f"minus ({tens}+{ones}), equals what?"
    )
    return pack(q, ordered, idx_nat, forced_idx)


def build_question(set_idx: int, slot: int) -> dict:
    diff = DIFF_BY_SLOT[slot]
    forced_idx = (set_idx * 10 + slot) % 4
    if slot == 0:
        raw = num_sequence_pair(set_idx, 0, forced_idx)
    elif slot == 1:
        raw = num_sequence_pair(set_idx, 1, forced_idx)
    elif slot == 2:
        raw = logical_pair(set_idx, 2, forced_idx)
    elif slot == 3:
        raw = logical_pair(set_idx, 3, forced_idx)
    elif slot == 4:
        raw = pattern_pair(set_idx, 4, forced_idx)
    elif slot == 5:
        raw = pattern_pair(set_idx, 5, forced_idx)
    elif slot == 6:
        raw = analogy_q(set_idx, forced_idx)
    elif slot == 7:
        raw = odd_one_out(set_idx, forced_idx)
    elif slot == 8:
        raw = spatial_text(set_idx, forced_idx)
    else:
        raw = mixed_reasoning(set_idx, forced_idx)

    sid = set_idx + 1
    qid = f"iq_set_{sid:03d}_q{slot + 1:02d}"
    return {
        "id": qid,
        "question": raw["question"],
        "options": raw["options"],
        "correctAnswer": raw["correctAnswer"],
        "difficulty": diff,
    }


def validate_sets(sets: list[dict]) -> None:
    assert len(sets) == 50
    texts: set[str] = set()
    qids: set[str] = set()
    sids: set[str] = set()
    for st in sets:
        assert st["id"] not in sids
        sids.add(st["id"])
        assert st["type"] == "iq"
        assert st["active"] is True
        assert st["version"] == "2026_01"
        assert int(st["id"].split("_")[-1]) == st["set_number"]
        qs = st["questions"]
        assert len(qs) == 10
        assert st["question_count"] == 10
        diff_counts = {1: 0, 2: 0, 3: 0}
        for q in qs:
            assert q["id"] not in qids
            qids.add(q["id"])
            txt = q["question"].strip()
            assert txt not in texts, txt[:120]
            texts.add(txt)
            assert len(q["options"]) == 4
            ca = q["correctAnswer"]
            assert ca in (0, 1, 2, 3)
            assert q["options"][ca] in q["options"]
            d = q["difficulty"]
            assert d in (1, 2, 3)
            diff_counts[d] += 1
        assert diff_counts == {1: 3, 2: 4, 3: 3}, diff_counts


def main() -> None:
    sets_out = []
    for s in range(50):
        qs = [build_question(s, slot) for slot in range(10)]
        sets_out.append(
            {
                "id": f"iq_set_{s + 1:03d}",
                "type": "iq",
                "set_number": s + 1,
                "version": "2026_01",
                "active": True,
                "question_count": 10,
                "questions": qs,
            }
        )
    validate_sets(sets_out)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"sets": sets_out}, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} (50 sets, 500 questions)")


if __name__ == "__main__":
    main()
