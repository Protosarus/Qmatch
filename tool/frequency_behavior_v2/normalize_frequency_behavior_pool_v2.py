#!/usr/bin/env python3
"""Normalize the Frequency V2 426-item TR source pool into a dormant draft.

Does not write live Frequency V1 banks, pubspec, or runtime routing.
"""
from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/qmatch_frequency_v2_426_unique_source_pool_tr.txt"
OUT_DIR = Path(__file__).resolve().parent / "out"

SCHEMA_VERSION = "qmatch_frequency_behavior_pool_v2"
POOL_VERSION = "frequency_behavior_pool_tr_v2_draft1"
SCORING_POLICY = "frequency_behavior_12d_signed_evidence_v2"
LOCALE = "tr-TR"
STATUS = "draft_not_runtime"

CANONICAL_12D = [
    "contact_need",
    "closeness_pace",
    "initiative",
    "autonomy",
    "reassurance_need",
    "uncertainty_tolerance",
    "disclosure_pace",
    "boundary_firmness",
    "repair_style",
    "social_energy",
    "structure_preference",
    "adaptability",
]
CANONICAL_SET = set(CANONICAL_12D)

SAFE_ALIASES = {
    "initiative_tendency": "initiative",
    "autonomy_need": "autonomy",
    "boundary_style": "boundary_firmness",
    "rhythm_adaptation": "adaptability",
}

FORBIDDEN_AUTO_MAP = {"processing_style"}

EVIDENCE_META_KEYS = [
    "social_desirability",
    "behavioral_plausibility",
    "self_presentation_risk",
    "ambiguity",
    "directness",
]

OPTION_LETTERS = ("a", "b", "c", "d")

CONTEXT_BUCKETS = {
    "early_dating": (
        "early",
        "first",
        "new match",
        "new_match",
        "dating",
        "first_meet",
        "first contact",
        "undefined_relationship",
        "growing_trust",
        "growing trust",
    ),
    "established": ("established", "routine", "private_established", "recovery"),
    "conflict": ("conflict", "disagreement", "feedback", "everyday_conflict"),
    "support": ("support", "stress", "repair", "emotional_tension"),
    "social": ("social", "friend", "party", "family", "celebration"),
    "boundaries": ("boundar", "privacy", "space", "autonomy"),
    "planning": ("plan", "vacation", "future", "schedule", "weekend"),
    "uncertainty": (
        "uncert",
        "ambigu",
        "silence",
        "reconnect",
        "undefined",
        "trust_ambiguity",
        "communication",
        "trust",
    ),
    "cross_check": ("cross_check", "crosscheck", "cross-check"),
}

SD_OPTION_HINTS = (
    "hemen özür",
    "yanında durduğumu",
    "duygusal olarak yanında",
    "saygı",
    "empati",
    "anlayışla karşılarım",
    "desteklerim",
    "olgun",
    "suçlamadan ama net",
    "haklısın",
    "onun için her şeyi",
    "ne isterse onu yaparım",
    "her zaman yanında",
)

SD_VIRTUE_VS_SELFISH = (
    "anlayışla",
    "desteklerim",
    "sakinleştir",
    "özür diler",
    "açıkça konuşurum",
)

REWRITE_WEAK_TRADEOFF_HINTS = (
    "fark etmez",
    "ne olursa olsun",
)

ITEM_SPLIT = re.compile(
    r"^=+\s*\nFQ(\d+)\s*\nsource:\s*(\S+)\s*\nsource_header:\s*(.*)\s*\n-+\s*\n",
    re.MULTILINE,
)
WEIGHT_PAIR = re.compile(
    r"([a-z_]+)\s*:\s*([+-]?\d+(?:\.\d+)?)",
    re.IGNORECASE,
)
WEIGHT_PAIR_BARE = re.compile(
    r"([a-z_]+)\s+([+-]?\d+(?:\.\d+)?)",
    re.IGNORECASE,
)
HEADER_FIELD = re.compile(
    r"(?:Pri|Sec|Ctx|ID|id|primary|secondary|context)\s*[:=]\s*`?([^`|\n]+)`?",
    re.IGNORECASE,
)


def nfkc(s: str) -> str:
    return unicodedata.normalize("NFKC", s or "")


def collapse_ws(s: str) -> str:
    return re.sub(r"\s+", " ", nfkc(s)).strip()


def normalize_question_text(s: str) -> str:
    t = collapse_ws(s).casefold()
    t = t.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
    t = re.sub(r"[^\w\sğüşöçıİĞÜŞÖÇ]", " ", t, flags=re.UNICODE)
    return collapse_ws(t)


def tokenize(s: str) -> set[str]:
    return {w for w in normalize_question_text(s).split(" ") if len(w) > 2}


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    inter = len(a & b)
    union = len(a | b)
    return inter / union if union else 0.0


def char_ngrams(s: str, n: int = 4) -> set[str]:
    t = normalize_question_text(s).replace(" ", "")
    if len(t) < n:
        return {t} if t else set()
    return {t[i : i + n] for i in range(len(t) - n + 1)}


def similarity(a: str, b: str) -> float:
    return max(jaccard(tokenize(a), tokenize(b)), jaccard(char_ngrams(a), char_ngrams(b)))


def parse_weight_blob(blob: str) -> list[tuple[str, float]]:
    text = blob.strip().strip("[]`")
    out: list[tuple[str, float]] = []
    seen = set()
    for rx in (WEIGHT_PAIR, WEIGHT_PAIR_BARE):
        for m in rx.finditer(text):
            dim = m.group(1).strip().lower()
            val = float(m.group(2))
            key = (dim, val)
            if dim in seen:
                continue
            seen.add(dim)
            out.append((dim, val))
    return out


def split_dims(raw: str | None) -> list[str]:
    if not raw:
        return []
    parts = re.split(r"[,/|]| and ", raw)
    out = []
    for p in parts:
        p = p.strip().strip("`").lower().replace(" ", "_")
        p = re.sub(r"[^a-z_]", "", p)
        if p:
            out.append(p)
    return out


def bucket_context(raw_contexts: list[str]) -> list[str]:
    joined = " ".join(raw_contexts).lower().replace("_", " ")
    hits = []
    for bucket, keys in CONTEXT_BUCKETS.items():
        if any(k in joined for k in keys):
            hits.append(bucket)
    return hits or ["unclassified"]


def truncate_item_body(body: str) -> str:
    cut = re.search(
        r"\n### SECTION|\nDUPLICATE OCCURRENCES REMOVED|\nEND OF SOURCE POOL",
        body,
    )
    if cut:
        return body[: cut.start()]
    return body


def parse_header_meta(source_header: str, body: str) -> dict:
    meta = {
        "source_item_id": None,
        "primary_raw": [],
        "secondary_raw": [],
        "context_raw": [],
    }
    id_m = re.search(r"(?:ID|id)\s*[:=]\s*`?([a-z0-9_]+)`?", source_header, re.I)
    if not id_m:
        id_m = re.search(r"(?:ID|id)\s*[:=]\s*`?([a-z0-9_]+)`?", body, re.I)
    if id_m:
        meta["source_item_id"] = id_m.group(1)

    pri = re.search(
        r"(?:\*\*)?Pri(?:mary)?(?:_dimension)?(?:\*\*)?\s*[:=]\s*`?([^`\n|]+)`?",
        source_header + "\n" + body,
        re.I,
    )
    sec = re.search(
        r"(?:\*\*)?Sec(?:ondary)?(?:\*\*)?\s*[:=]\s*`?([^`\n|]+)`?",
        source_header + "\n" + body,
        re.I,
    )
    ctx = re.search(
        r"(?:\*\*)?Ctx|context(?:\*\*)?\s*[:=]\s*`?([^`\n]+)`?",
        source_header + "\n" + body,
        re.I,
    )
    # More reliable line-based parse for Metadata blocks.
    for line in (source_header + "\n" + body).splitlines():
        s = line.strip()
        low = s.lower()
        if low.startswith("primary:") or low.startswith("primary_dimension:"):
            meta["primary_raw"] = split_dims(s.split(":", 1)[1])
        elif low.startswith("secondary:"):
            meta["secondary_raw"] = split_dims(s.split(":", 1)[1])
        elif low.startswith("context:"):
            meta["context_raw"] = [
                c.strip().lower().replace(" ", "_")
                for c in re.split(r"[,/]", s.split(":", 1)[1])
                if c.strip()
            ]
        elif "| pri:" in low or "| pri :" in low:
            m = re.search(r"Pri:\s*`([^`]+)`", s, re.I)
            if m:
                meta["primary_raw"] = split_dims(m.group(1))
            m = re.search(r"Sec:\s*`([^`]+)`", s, re.I)
            if m:
                meta["secondary_raw"] = split_dims(m.group(1))
            m = re.search(r"Ctx:\s*`([^`]+)`", s, re.I)
            if m:
                ctx_val = m.group(1)
                meta["context_raw"] = [
                    c.strip().lower().replace(" ", "_")
                    for c in re.split(r"[,/]", ctx_val)
                    if c.strip()
                ]
    if pri and not meta["primary_raw"]:
        meta["primary_raw"] = split_dims(pri.group(1) if pri.lastindex else "")
    if sec and not meta["secondary_raw"]:
        meta["secondary_raw"] = split_dims(sec.group(1))
    if ctx and not meta["context_raw"]:
        raw = ctx.group(1) if ctx.lastindex else ctx.group(0)
        meta["context_raw"] = [
            c.strip().lower().replace(" ", "_")
            for c in re.split(r"[,/]", raw)
            if c.strip() and c.strip().lower() not in {"ctx", "context"}
        ]
    return meta


def parse_format_markdown(body: str) -> tuple[str, list[dict]]:
    prompt_m = re.search(r"\*\*Soru:\*\*\s*(.+)", body)
    prompt = collapse_ws(prompt_m.group(1)) if prompt_m else ""
    options = []
    for letter in "ABCD":
        m = re.search(
            rf"\*\*{letter}:\*\*\s*(.+?)\s*`\[(.+?)\]`",
            body,
            re.DOTALL,
        )
        if not m:
            m = re.search(
                rf"\*\*{letter}:\*\*\s*(.+)",
                body,
            )
            if not m:
                continue
            text = collapse_ws(m.group(1))
            # Strip trailing weight blob if attached without backticks.
            wm = re.search(r"\[(.+?)\]\s*$", text)
            weights = parse_weight_blob(wm.group(1)) if wm else []
            if wm:
                text = collapse_ws(text[: wm.start()])
            options.append({"letter": letter.lower(), "text": text, "raw_weights": weights})
            continue
        text = collapse_ws(m.group(1))
        weights = parse_weight_blob(m.group(2))
        options.append({"letter": letter.lower(), "text": text, "raw_weights": weights})
    return prompt, options


def parse_format_master(body: str) -> tuple[str, list[dict]]:
    prompt_m = re.search(r"^Soru:\s*(.+)$", body, re.M)
    prompt = collapse_ws(prompt_m.group(1)) if prompt_m else ""
    options = []
    for letter in "ABCD":
        m = re.search(
            rf"^{letter}\s+\[[^\]]+\]\s*(.+)$\n\s*weights:\s*(.+)$",
            body,
            re.M,
        )
        if not m:
            continue
        options.append(
            {
                "letter": letter.lower(),
                "text": collapse_ws(m.group(1)),
                "raw_weights": parse_weight_blob(m.group(2)),
            }
        )
    return prompt, options


def parse_format_metadata(body: str) -> tuple[str, list[dict]]:
    # Drop markdown Q-line and Metadata block from prompt.
    lines = [ln.rstrip() for ln in body.splitlines()]
    prompt_lines = []
    option_map: dict[str, str] = {}
    in_meta = False
    meta_by_letter: dict[str, str] = {}
    for ln in lines:
        s = ln.strip()
        if s.lower().startswith("metadata:"):
            in_meta = True
            continue
        if in_meta:
            mm = re.match(r"^([ABCD])\s*:\s*(.+)$", s)
            if mm:
                meta_by_letter[mm.group(1).lower()] = mm.group(2)
            continue
        om = re.match(r"^([ABCD])\)\s*(.+)$", s)
        if om:
            option_map[om.group(1).lower()] = collapse_ws(om.group(2))
            continue
        if s.startswith("**Q") or s.startswith("Q") and re.match(r"^Q\d+", s):
            continue
        if s.startswith("primary") or s.startswith("secondary") or s.startswith("context"):
            continue
        if s.startswith("source:") or s.startswith("source_header"):
            continue
        if s and not s.startswith("==") and not s.startswith("--"):
            prompt_lines.append(s)
    prompt = collapse_ws(" ".join(prompt_lines))
    options = []
    for letter in OPTION_LETTERS:
        text = option_map.get(letter, "")
        blob = meta_by_letter.get(letter, "")
        options.append(
            {
                "letter": letter,
                "text": text,
                "raw_weights": parse_weight_blob(blob) if blob else [],
            }
        )
    return prompt, options


def detect_format(body: str) -> str:
    if re.search(r"\*\*Soru:\*\*", body) and re.search(r"\*\*A:\*\*", body):
        return "markdown"
    if re.search(r"^Soru:", body, re.M) and re.search(r"^A\s+\[", body, re.M):
        return "master"
    if re.search(r"^A\)\s+", body, re.M) and re.search(r"Metadata:", body, re.I):
        return "metadata"
    if re.search(r"^A\)\s+", body, re.M):
        return "metadata"
    return "unknown"


def apply_alias(dim: str) -> tuple[str | None, str]:
    """Return (canonical_or_none, action). action: canonical|alias|processing_style|unknown"""
    d = dim.strip().lower()
    if d in CANONICAL_SET:
        return d, "canonical"
    if d in SAFE_ALIASES:
        return SAFE_ALIASES[d], "alias"
    if d in FORBIDDEN_AUTO_MAP:
        return None, "processing_style"
    return None, "unknown"


def empty_evidence_meta() -> dict:
    return {
        **{k: None for k in EVIDENCE_META_KEYS},
        "review_status": "pending",
    }


def heuristic_flags(prompt: str, options: list[dict]) -> list[str]:
    flags = []
    texts = [o.get("text", "") for o in options]
    blob = (prompt + " " + " ".join(texts)).casefold()
    if any(h in blob for h in SD_OPTION_HINTS):
        flags.append("high_social_desirability_risk")
    virtue = sum(1 for t in texts if any(h in t.casefold() for h in SD_VIRTUE_VS_SELFISH))
    if virtue == 1 and len([t for t in texts if t]) == 4:
        flags.append("one_option_socially_preferred")
    if any(h in blob for h in REWRITE_WEAK_TRADEOFF_HINTS):
        flags.append("weak_tradeoff_language")
    # Near-identical option pair.
    for i in range(len(texts)):
        for j in range(i + 1, len(texts)):
            if texts[i] and texts[j] and similarity(texts[i], texts[j]) >= 0.82:
                flags.append("non_distinct_options")
                break
    # Feeling / identity rather than behavior.
    if re.search(r"hangi(si)?\s+(sana )?(daha )?(doğal|yakın) gelir", prompt.casefold()):
        flags.append("internal_state_prompt")
    if "en güvende hissettiğin" in prompt.casefold() or "nasıl bir içsel tepki" in prompt.casefold():
        flags.append("too_context_or_feeling_dependent")
    if len(prompt) > 280:
        flags.append("very_long_prompt")
    return sorted(set(flags))


def perspective_direction(prompt: str) -> str | None:
    p = prompt.casefold()
    partner_need = any(
        x in p
        for x in (
            "partnerin",
            "partneriniz",
            "karşı taraf",
            "o daha sık",
            "o daha seyrek",
            "alan ihtiyacım var",
        )
    )
    user_need = any(
        x in p
        for x in (
            "sen istiyorsun",
            "senin için",
            "sana daha",
            "senin ihtiyac",
        )
    )
    if partner_need and user_need:
        return "both"
    if partner_need:
        return "partner_initiated"
    if user_need:
        return "self_initiated"
    return None


class UnionFind:
    def __init__(self, n: int):
        self.p = list(range(n))

    def find(self, x: int) -> int:
        while self.p[x] != x:
            self.p[x] = self.p[self.p[x]]
            x = self.p[x]
        return x

    def union(self, a: int, b: int) -> None:
        pa, pb = self.find(a), self.find(b)
        if pa != pb:
            self.p[pb] = pa


def parse_source() -> list[dict]:
    raw = SOURCE.read_text(encoding="utf-8")
    matches = list(ITEM_SPLIT.finditer(raw))
    items = []
    for i, m in enumerate(matches):
        fq = int(m.group(1))
        source = m.group(2).strip()
        source_header = m.group(3).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else raw.find("\nDUPLICATE OCCURRENCES REMOVED")
        if end < 0:
            end = len(raw)
        body = truncate_item_body(raw[start:end])
        fmt = detect_format(body)
        if fmt == "markdown":
            prompt, options = parse_format_markdown(body)
        elif fmt == "master":
            prompt, options = parse_format_master(body)
        elif fmt == "metadata":
            prompt, options = parse_format_metadata(body)
        else:
            prompt, options = "", []
        header = parse_header_meta(source_header, body)
        items.append(
            {
                "fq": fq,
                "source": source,
                "source_header": source_header,
                "source_item_id": header["source_item_id"],
                "format": fmt,
                "prompt": prompt,
                "options": options,
                "primary_raw": header["primary_raw"],
                "secondary_raw": header["secondary_raw"],
                "context_raw": header["context_raw"],
                "body": body,
            }
        )
    return items


def canonicalize(items: list[dict]) -> tuple[list[dict], list[dict], dict]:
    alias_events = 0
    processing_items = 0
    unknown_counter: Counter[str] = Counter()
    processing_item_ids = []
    pool = []
    review = []

    for raw in items:
        item_id = f"frequency_v2_q{raw['fq']:04d}"
        unresolved_labels = []
        alias_applied = []
        processing_hits = []
        canonical_primary = []
        canonical_secondary = []

        def ingest(label: str, bucket: list[str]) -> None:
            nonlocal alias_events
            canon, action = apply_alias(label)
            if action == "alias":
                alias_events += 1
                alias_applied.append({"from": label, "to": canon})
                if canon and canon not in bucket:
                    bucket.append(canon)
            elif action == "canonical":
                if canon not in bucket:
                    bucket.append(canon)
            elif action == "processing_style":
                processing_hits.append(label)
                unresolved_labels.append(label)
            else:
                unknown_counter[label] += 1
                unresolved_labels.append(label)

        for lab in raw["primary_raw"]:
            ingest(lab, canonical_primary)
        for lab in raw["secondary_raw"]:
            ingest(lab, canonical_secondary)

        option_docs = []
        option_reviews = []
        for opt in raw["options"]:
            letter = opt["letter"]
            option_id = f"{item_id}_{letter}"
            behavioral = {}
            unresolved_weights = []
            for dim, val in opt["raw_weights"]:
                canon, action = apply_alias(dim)
                if action == "alias":
                    alias_events += 1
                    alias_applied.append({"from": dim, "to": canon, "option_id": option_id})
                if action == "processing_style":
                    processing_hits.append(dim)
                    unresolved_weights.append({"dimension": dim, "weight": val})
                    unresolved_labels.append(dim)
                    continue
                if action == "unknown":
                    unknown_counter[dim] += 1
                    unresolved_weights.append({"dimension": dim, "weight": val})
                    unresolved_labels.append(dim)
                    continue
                if canon:
                    # Later explicit values overwrite; keep first unless conflict.
                    if canon in behavioral and behavioral[canon] != val:
                        unresolved_weights.append(
                            {
                                "dimension": dim,
                                "canonical": canon,
                                "weight": val,
                                "conflict_with": behavioral[canon],
                            }
                        )
                    else:
                        behavioral[canon] = val
                    if canon not in canonical_primary and canon not in canonical_secondary:
                        canonical_secondary.append(canon)
            # Distinguish missing vs explicit 0: store only explicit keys.
            option_docs.append(
                {
                    "option_id": option_id,
                    "text": opt["text"],
                    "behavioral_weights": {
                        k: v for k, v in behavioral.items()
                    },
                    "evidence_meta": empty_evidence_meta(),
                }
            )
            option_reviews.append(
                {
                    "option_id": option_id,
                    "unresolved_weights": unresolved_weights,
                    "explicit_zero_keys": [k for k, v in behavioral.items() if v == 0],
                }
            )

        flags = heuristic_flags(raw["prompt"], raw["options"])
        issues = []
        if raw["format"] == "unknown":
            issues.append("malformed_unrecognized_format")
        if not raw["prompt"]:
            issues.append("missing_prompt")
        if len(raw["options"]) != 4:
            issues.append(f"option_count_{len(raw['options'])}")
        if any(not o["text"] for o in option_docs):
            issues.append("empty_option_text")
        if any(not o["behavioral_weights"] for o in option_docs):
            issues.append("option_missing_canonical_weights")
        if not canonical_primary:
            issues.append("no_canonical_primary")
        if processing_hits:
            issues.append("processing_style_manual_review")
            processing_items += 1
            processing_item_ids.append(item_id)
        if unresolved_labels:
            issues.append("unknown_or_blocked_dimension_labels")

        for o in option_docs:
            for dim, val in o["behavioral_weights"].items():
                if dim not in CANONICAL_SET:
                    issues.append("noncanonical_weight_leaked")
                if val < -2 or val > 2:
                    issues.append("weight_out_of_range")

        review_status = "pending"
        if issues:
            review_status = "manual_review"

        contexts = bucket_context(raw["context_raw"])
        cluster_key = (
            (canonical_primary[0] if canonical_primary else "unassigned")
            + ":"
            + (contexts[0] if contexts else "unclassified")
        )

        pool.append(
            {
                "item_id": item_id,
                "locale": LOCALE,
                "prompt": raw["prompt"],
                "context": contexts,
                "primary_dimensions": canonical_primary,
                "secondary_dimensions": [
                    d for d in canonical_secondary if d not in canonical_primary
                ],
                "semantic_cluster": cluster_key,
                "crosscheck_group_ids": [],
                "options": option_docs,
            }
        )
        review.append(
            {
                "item_id": item_id,
                "source_fq": f"FQ{raw['fq']:03d}",
                "source_set": raw["source"],
                "source_item_id": raw["source_item_id"],
                "source_format": raw["format"],
                "source_header": raw["source_header"],
                "source_context_raw": raw["context_raw"],
                "source_primary_raw": raw["primary_raw"],
                "source_secondary_raw": raw["secondary_raw"],
                "alias_applied": alias_applied,
                "unresolved_dimension_labels": sorted(set(unresolved_labels)),
                "processing_style_present": bool(processing_hits),
                "review_status": review_status,
                "issues": sorted(set(issues)),
                "heuristic_flags": flags,
                "perspective_direction": perspective_direction(raw["prompt"]),
                "options": option_reviews,
            }
        )

    stats = {
        "alias_events": alias_events,
        "processing_style_item_count": processing_items,
        "processing_style_item_ids": processing_item_ids,
        "unknown_labels": dict(unknown_counter),
    }
    return pool, review, stats


def exact_duplicate_questions(pool: list[dict]) -> list[dict]:
    by_norm = defaultdict(list)
    for it in pool:
        by_norm[normalize_question_text(it["prompt"])].append(it["item_id"])
    return [
        {"normalized_prompt": k, "item_ids": v}
        for k, v in by_norm.items()
        if k and len(v) > 1
    ]


def exact_duplicate_option_texts(pool: list[dict]) -> dict:
    within = []
    across = defaultdict(list)
    for it in pool:
        seen = defaultdict(list)
        for o in it["options"]:
            key = normalize_question_text(o["text"])
            if not key:
                continue
            seen[key].append(o["option_id"])
            across[key].append(
                {"item_id": it["item_id"], "option_id": o["option_id"], "text": o["text"]}
            )
        for key, ids in seen.items():
            if len(ids) > 1:
                within.append({"item_id": it["item_id"], "option_ids": ids, "normalized": key})
    across_dups = []
    for key, occ in across.items():
        items = {x["item_id"] for x in occ}
        if len(items) > 1:
            across_dups.append(
                {
                    "normalized": key,
                    "text": occ[0]["text"],
                    "occurrences": occ,
                    "item_count": len(items),
                }
            )
    across_dups.sort(key=lambda x: (-x["item_count"], x["text"]))
    return {"within_item": within, "across_items": across_dups}


def semantic_clusters(pool: list[dict], threshold: float = 0.62) -> list[dict]:
    n = len(pool)
    uf = UnionFind(n)
    prompts = [it["prompt"] for it in pool]
    # Block by first 24 normalized chars to keep O(n^2) cheaper.
    blocks = defaultdict(list)
    for i, p in enumerate(prompts):
        blocks[normalize_question_text(p)[:24]].append(i)
    # Also compare within same semantic_cluster.
    by_sc = defaultdict(list)
    for i, it in enumerate(pool):
        by_sc[it["semantic_cluster"]].append(i)

    def maybe_union(i: int, j: int) -> None:
        if i >= j:
            return
        if similarity(prompts[i], prompts[j]) >= threshold:
            uf.union(i, j)

    for idxs in blocks.values():
        for a in range(len(idxs)):
            for b in range(a + 1, len(idxs)):
                maybe_union(idxs[a], idxs[b])
    for idxs in by_sc.values():
        if len(idxs) > 80:
            continue
        for a in range(len(idxs)):
            for b in range(a + 1, min(a + 12, len(idxs))):
                maybe_union(idxs[a], idxs[b])

    groups = defaultdict(list)
    for i in range(n):
        groups[uf.find(i)].append(i)
    clusters = []
    for members in groups.values():
        if len(members) < 2:
            continue
        pairs = []
        for a in range(len(members)):
            for b in range(a + 1, len(members)):
                i, j = members[a], members[b]
                sim = similarity(prompts[i], prompts[j])
                if sim >= threshold:
                    pairs.append((sim, i, j))
        if not pairs:
            continue
        clusters.append(
            {
                "size": len(members),
                "item_ids": [pool[i]["item_id"] for i in members],
                "prompts": [pool[i]["prompt"] for i in members],
                "max_similarity": round(max(p[0] for p in pairs), 3),
            }
        )
    clusters.sort(key=lambda c: (-c["size"], -c["max_similarity"]))
    return clusters


def assign_crosscheck_groups(pool: list[dict], review: list[dict]) -> None:
    """Assign hidden cross-check groups from context + construct, not as lie detectors."""
    by_dim = defaultdict(list)
    for it in pool:
        for d in it["primary_dimensions"]:
            by_dim[d].append(it["item_id"])
    group_ids_by_item = defaultdict(list)
    for dim, ids in by_dim.items():
        if len(ids) < 4:
            continue
        gid = f"cc_{dim}_v2"
        for iid in ids:
            group_ids_by_item[iid].append(gid)
    # Asymmetry pairs from perspective + shared primary.
    review_by_id = {r["item_id"]: r for r in review}
    partner = [
        it
        for it in pool
        if review_by_id[it["item_id"]].get("perspective_direction") == "partner_initiated"
    ]
    selfs = [
        it
        for it in pool
        if review_by_id[it["item_id"]].get("perspective_direction") == "self_initiated"
    ]
    # Tag items; do not auto-pair all of them.
    for it in pool:
        it["crosscheck_group_ids"] = sorted(set(group_ids_by_item.get(it["item_id"], [])))
        flags = []
        pdir = review_by_id[it["item_id"]].get("perspective_direction")
        if pdir:
            flags.append(f"perspective:{pdir}")
        ctx = it["context"]
        if "conflict" in ctx:
            flags.append("construct_probe:repair_or_boundary")
        review_by_id[it["item_id"]]["construct_probe"] = (
            it["primary_dimensions"][0] if it["primary_dimensions"] else None
        )
        review_by_id[it["item_id"]]["crosscheck_group_ids"] = it["crosscheck_group_ids"]
        review_by_id[it["item_id"]]["selector_flags"] = flags


def selector_plan(pool: list[dict]) -> dict:
    primary_counts = Counter()
    context_counts = Counter()
    cluster_counts = Counter()
    for it in pool:
        for d in it["primary_dimensions"] or ["unassigned"]:
            primary_counts[d] += 1
        for c in it["context"]:
            context_counts[c] += 1
        cluster_counts[it["semantic_cluster"]] += 1

    # 50-item session: 4 items per 12 dimensions = 48, plus 2 flex for
    # under-covered contexts / cross-checks.
    per_dim = 4
    proposed_quota = {d: per_dim for d in CANONICAL_12D}
    context_targets = {
        "early_dating": 7,
        "established": 8,
        "conflict": 7,
        "support": 5,
        "social": 5,
        "boundaries": 6,
        "planning": 6,
        "uncertainty": 6,
    }
    return {
        "session_item_count": 50,
        "selection_policy_version": "frequency_behavior_50_of_426_seeded_quota_v2_draft1",
        "method": "seeded_quota_then_redundancy_penalty",
        "not": "pure_random",
        "dimension_quota": proposed_quota,
        "flex_slots": 2,
        "context_targets": context_targets,
        "constraints": [
            "cover all 12 canonical dimensions",
            "max 1 item per semantic_cluster unless pool shortage",
            "no adjacent items from the same semantic_cluster",
            "include at least 8 items that participate in a crosscheck_group",
            "mix partner_initiated and self_initiated when available",
            "deterministic from session_seed",
            "persist displayed_option_ids; score by option_id",
        ],
        "pool_primary_distribution": dict(primary_counts),
        "pool_context_distribution": dict(context_counts),
        "semantic_cluster_count": len(cluster_counts),
        "notes": [
            "processing_style items stay in the draft pool but must not be selected for a production-ready session until re-scored",
            "V1 sessions remain bound to frequency_bank_*_v1 via existing locale+bank_version persistence",
        ],
    }


def write_json(path: Path, obj) -> None:
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def build_report(
    items: list[dict],
    pool: list[dict],
    review: list[dict],
    stats: dict,
    q_dups: list,
    opt_dups: dict,
    clusters: list,
    plan: dict,
) -> str:
    malformed = [r for r in review if "malformed_unrecognized_format" in r["issues"] or "missing_prompt" in r["issues"]]
    rewrite = [
        r
        for r in review
        if set(r["heuristic_flags"]) & {
            "non_distinct_options",
            "weak_tradeoff_language",
            "too_context_or_feeling_dependent",
        }
        or "option_missing_canonical_weights" in r["issues"]
        or "no_canonical_primary" in r["issues"]
    ]
    sd_risk = [
        r
        for r in review
        if "high_social_desirability_risk" in r["heuristic_flags"]
        or "one_option_socially_preferred" in r["heuristic_flags"]
    ]
    lines = [
        "# Frequency V2 426-pool normalization report",
        "",
        f"Source: `{SOURCE.relative_to(ROOT)}`",
        f"schema_version: `{SCHEMA_VERSION}`",
        f"pool_version: `{POOL_VERSION}`",
        f"scoring_policy_version: `{SCORING_POLICY}`",
        "Status: **draft_not_runtime** — not selected by live Frequency routing.",
        "",
        "## Counts",
        "",
        f"- Parsed FQ blocks: {len(items)}",
        f"- Parsed questions in pool: {len(pool)}",
        f"- Parsed options: {sum(len(p['options']) for p in pool)}",
        f"- Exact duplicate normalized prompts: {len(q_dups)}",
        f"- Exact duplicate option texts within an item: {len(opt_dups['within_item'])}",
        f"- Exact duplicate option texts across items: {len(opt_dups['across_items'])}",
        f"- Likely semantic near-duplicate clusters (sim≥0.62): {len(clusters)}",
        f"- Items in those clusters: {sum(c['size'] for c in clusters)}",
        f"- Safe alias applications (label occurrences): {stats['alias_events']}",
        f"- Items with processing_style (NOT mapped): {stats['processing_style_item_count']}",
        f"- Unknown dimension labels: {stats['unknown_labels'] or '{}'}",
        f"- High social-desirability heuristic flags: {len(sd_risk)}",
        f"- Rewrite / manual-cleanup candidates: {len(rewrite)}",
        f"- Malformed/incomplete parse: {len(malformed)}",
        "",
        "## Alias policy",
        "",
        "Normalized only after label match:",
        "",
        "- `initiative_tendency` → `initiative`",
        "- `autonomy_need` → `autonomy`",
        "- `boundary_style` → `boundary_firmness`",
        "- `rhythm_adaptation` → `adaptability`",
        "",
        "`processing_style` is **never** mapped to `repair_style`.",
        "",
        "## processing_style items",
        "",
    ]
    for iid in stats["processing_style_item_ids"]:
        r = next(x for x in review if x["item_id"] == iid)
        lines.append(f"- `{iid}` ({r['source_fq']} / {r['source_set']}) primary_raw={r['source_primary_raw']}")
    lines += [
        "",
        "## Unknown labels",
        "",
    ]
    if stats["unknown_labels"]:
        for k, v in sorted(stats["unknown_labels"].items(), key=lambda kv: (-kv[1], kv[0])):
            lines.append(f"- `{k}`: {v} occurrence(s)")
    else:
        lines.append("- none")
    lines += [
        "",
        "## Exact duplicate prompts",
        "",
    ]
    if q_dups:
        for d in q_dups:
            lines.append(f"- {d['item_ids']}")
    else:
        lines.append("- none (source unique-prompt policy held)")
    lines += [
        "",
        "## Duplicate option texts across items (top 25)",
        "",
    ]
    for d in opt_dups["across_items"][:25]:
        ids = ", ".join(sorted({x['item_id'] for x in d['occurrences']}))
        lines.append(f"- `{d['text']}` — {d['item_count']} items: {ids}")
    lines += [
        "",
        "## Semantic near-duplicate clusters (top 20)",
        "",
    ]
    for c in clusters[:20]:
        lines.append(
            f"- size={c['size']} max_sim={c['max_similarity']} ids={', '.join(c['item_ids'])}"
        )
        lines.append(f"  - {c['prompts'][0][:160]}")
    lines += [
        "",
        "## High social-desirability risk (heuristic, not a lie score)",
        "",
        "These flags are review hints. They are not `truth_score` / `lie_score`.",
        "",
    ]
    for r in sd_risk[:40]:
        it = next(p for p in pool if p["item_id"] == r["item_id"])
        lines.append(
            f"- `{r['item_id']}` flags={r['heuristic_flags']}: {it['prompt'][:140]}"
        )
    lines += [
        "",
        "## Rewrite / incomplete / weak-tradeoff candidates",
        "",
    ]
    for r in rewrite[:50]:
        lines.append(
            f"- `{r['item_id']}` issues={r['issues']} flags={r['heuristic_flags']}"
        )
    lines += [
        "",
        "## Second-layer evidence",
        "",
        "All 1,704 `evidence_meta` values are `null` with `review_status=pending`.",
        "No numeric social_desirability / plausibility / etc. was invented.",
        "",
        "## Live production",
        "",
        "This generator does not write:",
        "",
        "- `assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json`",
        "- `assets/data/assessment_v3/frequency/frequency_bank_en_v1.json`",
        "- `pubspec.yaml`",
        "- Frequency locale routing",
        "",
        "## Recommended next phase",
        "",
        "Human metadata review: re-score every `processing_style` item onto the 12D vocabulary or drop it from production selection; fill evidence_meta only where a reviewer can defend a [0,1] value; resolve near-duplicate clusters before activating a 50-of-426 selector.",
        "",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    if not SOURCE.exists():
        raise SystemExit(f"missing source {SOURCE}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    items = parse_source()
    if len(items) != 426:
        # Still write artifacts so tests can show the actual count.
        print(f"WARNING: parsed {len(items)} FQ blocks, expected 426")
    pool, review, stats = canonicalize(items)
    assign_crosscheck_groups(pool, review)
    q_dups = exact_duplicate_questions(pool)
    opt_dups = exact_duplicate_option_texts(pool)
    clusters = semantic_clusters(pool)
    plan = selector_plan(pool)

    document = {
        "schema_version": SCHEMA_VERSION,
        "pool_version": POOL_VERSION,
        "content_version": POOL_VERSION,
        "scoring_policy_version": SCORING_POLICY,
        "locale": LOCALE,
        "module": "frequency_behavior_v2",
        "status": STATUS,
        "calibration_status": "uncalibrated",
        "runtime_selectable": False,
        "canonical_dimensions": CANONICAL_12D,
        "dimension_weight_range": {"min": -2, "max": 2},
        "question_count": len(pool),
        "option_count": sum(len(p["options"]) for p in pool),
        "not_claims": [
            "clinical_diagnosis",
            "lie_detection",
            "moral_character",
            "quantum_mechanical_personhood",
            "canonical_frequency_6d",
            "canonical_v1_20d_frequency_slots",
        ],
        "items": pool,
    }
    review_doc = {
        "schema_version": "qmatch_frequency_behavior_pool_v2_review_metadata",
        "pool_version": POOL_VERSION,
        "developer_only": True,
        "evidence_meta_policy": "null_pending_until_human_review",
        "forbidden_inferences": [
            "truth_score",
            "lie_score",
            "deception_score",
            "honesty_score",
        ],
        "safe_aliases": SAFE_ALIASES,
        "never_auto_map": {"processing_style": "repair_style"},
        "stats": stats,
        "exact_duplicate_prompts": q_dups,
        "exact_duplicate_options": {
            "within_item": opt_dups["within_item"],
            "across_item_count": len(opt_dups["across_items"]),
            "across_items": opt_dups["across_items"][:80],
        },
        "semantic_near_duplicate_clusters": clusters,
        "items": review,
    }

    write_json(OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json", document)
    write_json(
        OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json",
        review_doc,
    )
    write_json(
        OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_selector_plan.json",
        plan,
    )
    report = build_report(items, pool, review, stats, q_dups, opt_dups, clusters, plan)
    (OUT_DIR / "frequency_behavior_pool_tr_v2_draft1_normalization_report.md").write_text(
        report, encoding="utf-8"
    )

    src_hash = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
    v1_tr = ROOT / "assets/data/assessment_v3/frequency/frequency_bank_tr_v1.json"
    v1_en = ROOT / "assets/data/assessment_v3/frequency/frequency_bank_en_v1.json"
    print(json.dumps(
        {
            "parsed_items": len(items),
            "pool_items": len(pool),
            "options": sum(len(p["options"]) for p in pool),
            "alias_events": stats["alias_events"],
            "processing_style_items": stats["processing_style_item_count"],
            "unknown_labels": stats["unknown_labels"],
            "exact_dup_prompts": len(q_dups),
            "semantic_clusters": len(clusters),
            "source_sha256": src_hash,
            "v1_tr_sha256": hashlib.sha256(v1_tr.read_bytes()).hexdigest(),
            "v1_en_sha256": hashlib.sha256(v1_en.read_bytes()).hexdigest(),
        },
        indent=2,
    ))
    return 0 if len(items) == 426 else 1


if __name__ == "__main__":
    raise SystemExit(main())
