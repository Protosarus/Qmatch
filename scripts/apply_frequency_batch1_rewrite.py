#!/usr/bin/env python3
"""Apply Phase 3M-A1 Frequency content rewrite to frequency_set_001..010.

Changes only question.en / question.tr.
Preserves IDs, dimension, reverseScored, question order/count, and all
other non-text fields.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FREQ_PATH = ROOT / "assets" / "data" / "assessment_sets" / "frequency_sets.json"
SCENARIOS_PATH = ROOT / "scripts" / "frequency_batch1_scenarios.json"
SET_RE = re.compile(r"^frequency_set_00[1-9]$|^frequency_set_010$")


def main() -> None:
    scenarios = {
        row["id"]: row for row in json.loads(SCENARIOS_PATH.read_text(encoding="utf-8"))
    }
    data = json.loads(FREQ_PATH.read_text(encoding="utf-8"))
    n = 0

    for s in data["sets"]:
        if not SET_RE.match(s["id"]):
            continue
        for q in s["questions"]:
            qid = q["id"]
            if qid not in scenarios:
                raise KeyError(f"Missing scenario for {qid}")
            sc = scenarios[qid]
            # Preserve non-text fields explicitly by only touching question text.
            before_dim = q.get("dimension")
            before_rev = q.get("reverseScored")
            q["question"]["en"] = sc["en"]
            q["question"]["tr"] = sc["tr"]
            if q.get("dimension") != before_dim or q.get("reverseScored") != before_rev:
                raise AssertionError(f"{qid}: non-text field changed unexpectedly")
            n += 1

    if n != 120:
        raise AssertionError(f"Expected 120 rewrites, got {n}")

    FREQ_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Rewrote Frequency batch 1: {n} questions in frequency_sets.json")


if __name__ == "__main__":
    main()
