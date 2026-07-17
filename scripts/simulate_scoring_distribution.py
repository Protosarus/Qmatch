#!/usr/bin/env python3
"""Read-only simulation of IQ / EQ / Frequency scoring distributions.

Does not write Firestore, does not modify assessment JSON, does not require network.

Mirrors production logic from:
- ArchetypeCalculator (lib/features/assessment/models/archetype_model.dart)
- FrequencyService.calculateResult (lib/features/assessment/services/frequency_service.dart)
"""

from __future__ import annotations

import json
import math
import random
import statistics
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "data" / "assessment_sets"

RNG = random.Random(42)


def load_sets(name: str) -> list[dict]:
    data = json.loads((ASSETS / f"{name}_sets.json").read_text(encoding="utf-8"))
    sets = data.get("sets") or data
    if isinstance(sets, dict):
        sets = list(sets.values())
    return sets


def normalize_score(raw: int, max_score: int) -> int:
    if max_score <= 0:
        return 0
    return int(round((raw / max_score) * 100))


def get_category(normalized: int) -> str:
    if normalized > 66:
        return "H"
    if normalized >= 34:
        return "M"
    return "L"


def archetype(iq_raw: int, eq_raw: int, n: int = 10) -> dict:
    iq_n = normalize_score(iq_raw, n)
    eq_n = normalize_score(eq_raw, n)
    key = f"{get_category(iq_n)}{get_category(eq_n)}"
    return {
        "iq_raw": iq_raw,
        "eq_raw": eq_raw,
        "iq_normalized": iq_n,
        "eq_normalized": eq_n,
        "category": key,
    }


def score_iq_eq_mcq(questions: list[dict], pick) -> int:
    """pick(q, i) -> option index 0..3"""
    correct = 0
    for i, q in enumerate(questions):
        ans = pick(q, i)
        if ans == q.get("correctAnswer"):
            correct += 1
    return correct


def frequency_result(questions: list[dict], answers: dict[str, int]) -> dict:
    by_dim: dict[str, list[float]] = defaultdict(list)
    for q in questions:
        qid = q["id"]
        if qid not in answers:
            continue
        raw = max(1, min(5, int(answers[qid])))
        scored = (6 - raw) if q.get("reverseScored") else raw
        normalized = (scored - 1) / 4.0
        by_dim[q["dimension"]].append(normalized)

    def dim_avg(d: str) -> float:
        vals = by_dim.get(d) or []
        if not vals:
            return 0.5
        return sum(vals) / len(vals)

    dims = [
        "depth",
        "socialEnergy",
        "spontaneity",
        "stability",
        "emotionalOpenness",
        "conversationPace",
    ]
    vector = {d: dim_avg(d) for d in dims}
    score_total = (sum(vector.values()) / len(vector)) * 100.0

    depth = vector["depth"]
    social_energy = vector["socialEnergy"]
    spontaneity = vector["spontaneity"]
    stability = vector["stability"]
    emotional_openness = vector["emotionalOpenness"]
    conversation_pace = vector["conversationPace"]

    if depth >= 0.75 and stability >= 0.65:
        ftype = "Deep Connector"
    elif social_energy >= 0.70 and spontaneity >= 0.60:
        ftype = "Social Spark"
    elif stability >= 0.75 and conversation_pace <= 0.55:
        ftype = "Slow Burner"
    elif emotional_openness >= 0.75 and depth >= 0.60:
        ftype = "Emotional Explorer"
    elif spontaneity >= 0.70 and emotional_openness >= 0.60:
        ftype = "Open Current"
    else:
        ftype = "Balanced Frequency"

    tags = []
    if depth >= 0.70:
        tags.append("deep_talker")
    if social_energy >= 0.70:
        tags.append("social_energy")
    if spontaneity >= 0.70:
        tags.append("spontaneous")
    if stability >= 0.70:
        tags.append("stability_first")
    if emotional_openness >= 0.70:
        tags.append("emotionally_open")
    if conversation_pace <= 0.45:
        tags.append("slow_bond")
    if conversation_pace >= 0.70:
        tags.append("fast_connection")

    return {
        "score_total": score_total,
        "vector": vector,
        "type": ftype,
        "tags": tags,
    }


def buckets(values: list[float], edges: list[int] | None = None) -> dict[str, int]:
    if edges is None:
        edges = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
    counts = Counter()
    for v in values:
        placed = False
        for i in range(len(edges) - 1):
            lo, hi = edges[i], edges[i + 1]
            if lo <= v < hi or (hi == 100 and v == 100):
                counts[f"{lo}-{hi}"] += 1
                placed = True
                break
        if not placed:
            counts["other"] += 1
    return dict(sorted(counts.items(), key=lambda x: x[0]))


def summarize(name: str, values: list[float]) -> dict:
    if not values:
        return {"name": name, "n": 0}
    mid = sum(1 for v in values if 40 <= v <= 60)
    return {
        "name": name,
        "n": len(values),
        "min": round(min(values), 2),
        "max": round(max(values), 2),
        "mean": round(statistics.mean(values), 2),
        "median": round(statistics.median(values), 2),
        "stdev": round(statistics.pstdev(values), 2) if len(values) > 1 else 0.0,
        "mid_40_60_pct": round(100.0 * mid / len(values), 1),
        "buckets": buckets(values),
    }


def main() -> int:
    iq_sets = load_sets("iq")
    eq_sets = load_sets("eq")
    freq_sets = load_sets("frequency")

    print("=" * 72)
    print("Scoring Distribution Simulation (READ ONLY)")
    print("=" * 72)
    print(f"Loaded IQ={len(iq_sets)} EQ={len(eq_sets)} Frequency={len(freq_sets)} sets")
    print("N questions/set: IQ=10 EQ=10 Frequency=12")
    print()
    print(
        "LIMITATION: EQ option text styles (secure/passive/punitive) are not "
        "machine-labeled in JSON. EQ style proxies use correctAnswer vs "
        "non-correct indices only — not semantic option meaning."
    )
    print()

    # --- Deterministic profile templates on set 0 ---
    iq0 = iq_sets[0]["questions"]
    eq0 = eq_sets[0]["questions"]
    fr0 = freq_sets[0]["questions"]

    profiles = []

    def add_mcq(label: str, iq_pick, eq_pick):
        iq_raw = score_iq_eq_mcq(iq0, iq_pick)
        eq_raw = score_iq_eq_mcq(eq0, eq_pick)
        profiles.append({"label": label, **archetype(iq_raw, eq_raw)})

    add_mcq("all_lowest_index", lambda q, i: 0, lambda q, i: 0)
    add_mcq("all_highest_index", lambda q, i: 3, lambda q, i: 3)
    add_mcq(
        "always_correct",
        lambda q, i: q["correctAnswer"],
        lambda q, i: q["correctAnswer"],
    )
    add_mcq(
        "always_wrong",
        lambda q, i: (q["correctAnswer"] + 1) % 4,
        lambda q, i: (q["correctAnswer"] + 1) % 4,
    )
    add_mcq(
        "high_iq_low_eq",
        lambda q, i: q["correctAnswer"],
        lambda q, i: (q["correctAnswer"] + 1) % 4,
    )
    add_mcq(
        "low_iq_high_eq",
        lambda q, i: (q["correctAnswer"] + 1) % 4,
        lambda q, i: q["correctAnswer"],
    )
    add_mcq(
        "eq_secure_proxy_correct",
        lambda q, i: RNG.randrange(4),
        lambda q, i: q["correctAnswer"],
    )
    add_mcq(
        "eq_noncorrect_proxy",
        lambda q, i: RNG.randrange(4),
        lambda q, i: (q["correctAnswer"] + 2) % 4,
    )

    print("--- Deterministic IQ/EQ profiles (set_001) ---")
    for p in profiles:
        print(
            f"  {p['label']}: IQ {p['iq_raw']}/10 ({p['iq_normalized']}) "
            f"EQ {p['eq_raw']}/10 ({p['eq_normalized']}) → {p['category']}"
        )
    print()

    # Frequency deterministic
    freq_profiles = []

    def freq_answers(mode: str) -> dict[str, int]:
        out = {}
        for q in fr0:
            qid = q["id"]
            if mode == "all_1":
                out[qid] = 1
            elif mode == "all_5":
                out[qid] = 5
            elif mode == "neutral":
                out[qid] = 3
            elif mode == "high_depth_stability":
                # After reverse: push scored toward high for depth/stability
                if q["dimension"] in ("depth", "stability"):
                    out[qid] = 1 if q.get("reverseScored") else 5
                else:
                    out[qid] = 3
            elif mode == "high_social_spark":
                if q["dimension"] in ("socialEnergy", "spontaneity"):
                    out[qid] = 1 if q.get("reverseScored") else 5
                else:
                    out[qid] = 3
            else:
                out[qid] = 3
        return out

    for mode in [
        "all_1",
        "all_5",
        "neutral",
        "high_depth_stability",
        "high_social_spark",
    ]:
        r = frequency_result(fr0, freq_answers(mode))
        freq_profiles.append({"label": mode, **r})
        print(
            f"  Frequency {mode}: score={r['score_total']:.1f} "
            f"type={r['type']} tags={r['tags']}"
        )
    print()

    # --- Monte Carlo across all sets ---
    N = 2000
    iq_norms = []
    eq_norms = []
    cats = Counter()
    mid_band = 0

    for _ in range(N):
        iq_set = RNG.choice(iq_sets)["questions"]
        eq_set = RNG.choice(eq_sets)["questions"]
        iq_raw = score_iq_eq_mcq(iq_set, lambda q, i: RNG.randrange(4))
        eq_raw = score_iq_eq_mcq(eq_set, lambda q, i: RNG.randrange(4))
        a = archetype(iq_raw, eq_raw)
        iq_norms.append(float(a["iq_normalized"]))
        eq_norms.append(float(a["eq_normalized"]))
        cats[a["category"]] += 1
        if 40 <= a["iq_normalized"] <= 60 and 40 <= a["eq_normalized"] <= 60:
            mid_band += 1

    # Chance correct ≈ 0.25 → Binomial mean 2.5/10 → ~25 normalized → L band
    # Also simulate "mostly socially desirable EQ" = correctAnswer rate 0.7
    iq_mix, eq_desirable, cats2 = [], [], Counter()
    for _ in range(N):
        iq_set = RNG.choice(iq_sets)["questions"]
        eq_set = RNG.choice(eq_sets)["questions"]

        def iq_pick(q, i):
            return q["correctAnswer"] if RNG.random() < 0.45 else RNG.randrange(4)

        def eq_pick(q, i):
            return q["correctAnswer"] if RNG.random() < 0.70 else RNG.randrange(4)

        iq_raw = score_iq_eq_mcq(iq_set, iq_pick)
        eq_raw = score_iq_eq_mcq(eq_set, eq_pick)
        a = archetype(iq_raw, eq_raw)
        iq_mix.append(float(a["iq_normalized"]))
        eq_desirable.append(float(a["eq_normalized"]))
        cats2[a["category"]] += 1

    freq_scores = []
    freq_types = Counter()
    freq_tag_empty = 0
    freq_neutral_scores = []
    for _ in range(N):
        fr = RNG.choice(freq_sets)["questions"]
        answers = {q["id"]: RNG.randint(1, 5) for q in fr}
        r = frequency_result(fr, answers)
        freq_scores.append(r["score_total"])
        freq_types[r["type"]] += 1
        if not r["tags"]:
            freq_tag_empty += 1

        answers_n = {q["id"]: 3 for q in fr}
        rn = frequency_result(fr, answers_n)
        freq_neutral_scores.append(rn["score_total"])

    print("--- Monte Carlo: uniform random IQ/EQ (p_correct≈0.25) ---")
    print(json.dumps(summarize("iq_normalized", iq_norms), indent=2))
    print(json.dumps(summarize("eq_normalized", eq_norms), indent=2))
    print("archetype_distribution:", dict(cats.most_common()))
    print(
        f"both_scores_in_40_60: {mid_band}/{N} ({100*mid_band/N:.1f}%)"
    )
    print()

    print("--- Monte Carlo: mixed IQ (p≈0.45) + desirable EQ (p≈0.70) ---")
    print(json.dumps(summarize("iq_normalized", iq_mix), indent=2))
    print(json.dumps(summarize("eq_normalized", eq_desirable), indent=2))
    print("archetype_distribution:", dict(cats2.most_common()))
    mm = cats2.get("MM", 0)
    print(f"MM_share: {100*mm/N:.1f}%")
    print()

    print("--- Monte Carlo: Frequency random Likert 1..5 ---")
    print(json.dumps(summarize("frequency_score_total", freq_scores), indent=2))
    print("type_distribution:", dict(freq_types.most_common()))
    print(f"empty_tags_pct: {100*freq_tag_empty/N:.1f}%")
    print(
        "all_neutral_Likert_scores:",
        json.dumps(summarize("freq_neutral", freq_neutral_scores), indent=2),
    )
    print()

    # Compression warnings
    print("--- Warnings ---")
    warnings = []
    if summarize("iq", iq_mix)["mid_40_60_pct"] >= 35:
        warnings.append(
            "IQ mixed responders frequently land in 40–60 (M band feeder)."
        )
    if summarize("eq", eq_desirable)["mean"] >= 55:
        warnings.append(
            "High correctAnswer hit-rate on EQ pushes mean into mid/high — "
            "socially desirable answering can inflate EQ."
        )
    if cats2.most_common(1)[0][1] / N >= 0.20:
        top = cats2.most_common(1)[0]
        warnings.append(
            f"Archetype compression: {top[0]} is {100*top[1]/N:.1f}% under "
            "desirable-EQ mixed simulation."
        )
    if freq_types["Balanced Frequency"] / N >= 0.40:
        warnings.append(
            f"Frequency type cascade collapses to Balanced Frequency "
            f"({100*freq_types['Balanced Frequency']/N:.1f}% of random responders)."
        )
    if freq_tag_empty / N >= 0.40:
        warnings.append(
            f"Empty Frequency tags ({100*freq_tag_empty/N:.1f}%) → type/tag "
            "fallback (cold-start uses missing-neutral 0.42, not free 0.5)."
        )
    if abs(statistics.mean(freq_neutral_scores) - 50) < 1:
        warnings.append(
            "All-neutral Likert maps to ~50 scoreTotal — midpoint attractor."
        )
    warnings.append(
        "With 10 MCQ items, normalized IQ/EQ has only 11 discrete values "
        "(0,10,...,100); cold-start ranking uses H/M/L bands, not raw closeness."
    )
    warnings.append(
        "Cold-start (3R-A2): Frequency vector 0.32 primary; archetype 0.15; "
        "IQ/EQ bands 0.08 each — see compatibility simulation below."
    )

    for w in warnings:
        print(f"  ! {w}")

    print()
    print_compatibility_simulation(freq_sets)

    print()
    print("DONE (no Firestore writes, no JSON modifications).")
    return 0


# --- Phase 3R-A2: lightweight compatibility simulation (mirrors Dart cold-start) ---

FREQ_DIMS = [
    "depth",
    "socialEnergy",
    "spontaneity",
    "stability",
    "emotionalOpenness",
    "conversationPace",
]

# Named weights from CompatibilityScoring (must sum to 1.0)
W_VEC = 0.32
W_TYPE_TAG = 0.10
W_ARCH = 0.15
W_IQ = 0.08
W_EQ = 0.08
W_INT = 0.15
W_REC = 0.12
MISSING = 0.42


def band(n: int | None) -> str | None:
    if n is None:
        return None
    if n > 66:
        return "H"
    if n >= 34:
        return "M"
    return "L"


def band_closeness(a: int | None, b: int | None) -> float:
    ba, bb = band(a), band(b)
    if ba is None or bb is None:
        return MISSING
    if ba == bb:
        return 0.72
    adj = {("H", "M"), ("M", "H"), ("M", "L"), ("L", "M")}
    if (ba, bb) in adj:
        return 0.52
    return 0.32


def archetype_affinity(ca: str | None, cb: str | None) -> float:
    if not ca or not cb:
        return MISSING
    if ca == cb:
        return 0.70
    if ca[0] == cb[0]:
        return 0.58
    if ca[1] == cb[1]:
        return 0.55
    return MISSING


def vector_similarity(va: dict[str, float], vb: dict[str, float]) -> float:
    if not va or not vb:
        return MISSING
    diffs = []
    for k in FREQ_DIMS:
        if k in va and k in vb:
            diffs.append(abs(va[k] - vb[k]))
    if not diffs:
        return MISSING
    return max(0.0, min(1.0, 1.0 - (sum(diffs) / len(diffs))))


def combined_compat(
    *,
    arch: float,
    iq: float,
    eq: float,
    vec: float,
    type_tag: float = MISSING,
    interests: float = MISSING,
    recency: float = 0.4,
) -> float:
    return max(
        0.0,
        min(
            1.0,
            vec * W_VEC
            + type_tag * W_TYPE_TAG
            + arch * W_ARCH
            + iq * W_IQ
            + eq * W_EQ
            + interests * W_INT
            + recency * W_REC,
        ),
    )


def print_compatibility_simulation(freq_sets: list[dict]) -> None:
    print("=" * 72)
    print("COMPATIBILITY SIMULATION (3R-A2 cold-start mirrors)")
    print("=" * 72)
    qs = freq_sets[0]["questions"]

    def make_freq(style: str) -> dict[str, float]:
        answers: dict[str, int] = {}
        for q in qs:
            if style == "deep":
                # Prefer high depth / emotionalOpenness
                dim = q["dimension"]
                answers[q["id"]] = 5 if dim in ("depth", "emotionalOpenness") else 2
                if q.get("reverseScored"):
                    answers[q["id"]] = 6 - answers[q["id"]]
            elif style == "social":
                dim = q["dimension"]
                answers[q["id"]] = 5 if dim in ("socialEnergy", "spontaneity") else 2
                if q.get("reverseScored"):
                    answers[q["id"]] = 6 - answers[q["id"]]
            else:
                answers[q["id"]] = 3
        return frequency_result(qs, answers)["vector"]

    deep = make_freq("deep")
    social = make_freq("social")
    neutral = make_freq("neutral")

    pairs = [
        ("same MM archetype, identical scores, no vector", "MM", "MM", 50, 50, 50, 50, None, None),
        ("same MM + similar Frequency vectors (deep×deep)", "MM", "MM", 50, 50, 50, 50, deep, deep),
        ("same MM + dissimilar Frequency (deep×social)", "MM", "MM", 50, 50, 50, 50, deep, social),
        ("same MM + both neutral vectors (~midpoint)", "MM", "MM", 50, 50, 50, 50, neutral, neutral),
        ("51 vs 59 IQ (same M band) + deep vectors", "MM", "MM", 51, 50, 59, 50, deep, deep),
        ("HH vs LL (opposite) + deep vectors", "HH", "LL", 80, 80, 20, 20, deep, deep),
    ]

    print(
        f"\nWeights: vec={W_VEC} type/tag={W_TYPE_TAG} arch={W_ARCH} "
        f"iq={W_IQ} eq={W_EQ} int={W_INT} rec={W_REC}"
    )
    print(f"{'scenario':<52} {'arch':>5} {'vec':>5} {'combo':>6}")
    for label, ca, cb, iq_a, eq_a, iq_b, eq_b, va, vb in pairs:
        arch = archetype_affinity(ca, cb)
        vec = vector_similarity(va or {}, vb or {}) if va is not None else MISSING
        iq = band_closeness(iq_a, iq_b)
        eq = band_closeness(eq_a, eq_b)
        combo = combined_compat(arch=arch, iq=iq, eq=eq, vec=vec)
        print(f"{label:<52} {arch:5.2f} {vec:5.2f} {combo:6.3f}")

    print(
        "\nNote: archetype-only affinity no longer dominates ranking when "
        "Frequency vectors differ; missing vectors stay at "
        f"{MISSING} (not rewarded as a match)."
    )


if __name__ == "__main__":
    raise SystemExit(main())
