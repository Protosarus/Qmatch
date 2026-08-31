#!/usr/bin/env python3
"""Build Frequency V2 EN semantic parity bank from TR master + translations.

Does not activate EN/V2 runtime. Does not modify TR pool or weights.
"""
from __future__ import annotations

import copy
import json
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "out"
TR_POOL = OUT / "frequency_behavior_pool_tr_v2_draft1.json"
TR_REVIEW = OUT / "frequency_behavior_pool_tr_v2_draft1_review_metadata.json"
EN_TRANSLATIONS = OUT / "frequency_v2_en_semantic_text_v1.json"
EN_POOL = OUT / "frequency_behavior_pool_en_v2_draft1.json"
EN_REVIEW = OUT / "frequency_behavior_pool_en_v2_draft1_review_metadata.json"
AUDIT = OUT / "frequency_v2_phase6a_en_parity_audit.md"
REVIEW_DIR = OUT / "en_human_review"

SCHEMA_VERSION = "qmatch_frequency_behavior_pool_v2"
POOL_VERSION_EN = "frequency_behavior_pool_en_v2_draft1"
POOL_VERSION_TR = "frequency_behavior_pool_tr_v2_draft1"
SCORING_POLICY = "frequency_behavior_12d_signed_evidence_v2"
LOCALE_EN = "en-US"
LOCALE_TR = "tr-TR"
TRANSLATION_VERSION = "frequency_v2_en_semantic_v1"
STATUS = "draft_not_runtime"
BATCH_SIZE = 50

EVIDENCE_KEYS = [
    "version",
    "calibration_status",
    "review_status",
    "diagnostic_value",
    "behavioral_plausibility",
    "ambiguity",
    "social_desirability",
    "obviousness",
    "self_presentation_risk",
]

REVIEW_STRUCTURAL_KEYS = [
    "selector_eligible",
    "selector_exclusion_reason",
    "drop_from_selectable",
    "rewrite_pending",
    "primary_review_pending",
    "processing_style_present",
    "semantic_cluster",
    "primary_dimensions",
    "secondary_dimensions",
    "review_status",
]

POSITIVE_CUE_WORDS = {
    "always",
    "immediately",
    "directly",
    "openly",
    "honest",
    "healthy",
    "mature",
    "communicate",
    "respect",
    "supportive",
    "understanding",
    "patient",
    "kind",
}

NEGATIVE_SOFTENING = {
    "maybe",
    "sometimes",
    "a bit",
    "slightly",
    "might",
    "could",
    "perhaps",
}

CULTURAL_MARKERS_TR = [
    "bayram",
    "sünnet",
    "kına",
    "aile baskısı",
    "mahalle",
    "komşu",
    "teyz",
    "amca",
    "dayı",
    "hoca",
    "namaz",
    "oruç",
]

TRANSLATION_STATUSES = {
    "PENDING_HUMAN_REVIEW",
    "REVIEWED",
    "CROSS_CULTURAL_REVIEW_REQUIRED",
    "EVIDENCE_PARITY_REVIEW_REQUIRED",
}


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def primary_weight(option: dict, primary: str) -> float | None:
    w = option.get("behavioral_weights", {})
    return w.get(primary)


def detect_review_flags(
    tr_item: dict,
    en_item: dict,
    tr_prompt: str,
    en_prompt: str,
) -> list[str]:
    flags: list[str] = []
    primary = (
        tr_item.get("primary_dimensions") or [None]
    )[0]

    if any(m in tr_prompt.lower() for m in CULTURAL_MARKERS_TR):
        flags.append("possible_cultural_mismatch")

    en_lower = en_prompt.lower()
    tr_lower = tr_prompt.lower()

    # Heuristic unnatural English
    if len(en_prompt.split()) > len(tr_prompt.split()) * 2.2:
        flags.append("possible_unnatural_english")
    if re.search(r"\b(that|which|who)\s+\w+\s+\w+\s+\w+\s+\w+\s+\w+", en_prompt):
        flags.append("possible_unnatural_english")

    pos_en = sum(1 for w in POSITIVE_CUE_WORDS if w in en_lower)
    pos_tr = sum(1 for w in POSITIVE_CUE_WORDS if w in tr_lower)
    if pos_en > pos_tr + 1:
        flags.append("possible_social_desirability_shift")

    soft_en = sum(1 for w in NEGATIVE_SOFTENING if w in en_lower)
    soft_tr = sum(1 for w in NEGATIVE_SOFTENING if w in tr_lower)
    if soft_en > soft_tr + 1:
        flags.append("possible_ambiguity_change")

    if primary:
        tr_opts = {o["option_id"]: o for o in tr_item["options"]}
        en_opts = {o["option_id"]: o for o in en_item["options"]}
        weights_tr: list[tuple[str, float]] = []
        weights_en: list[tuple[str, float]] = []
        for oid, to in tr_opts.items():
            pw = primary_weight(to, primary)
            if pw is not None:
                weights_tr.append((oid, pw))
        for oid, eo in en_opts.items():
            pw = primary_weight(eo, primary)
            if pw is not None:
                weights_en.append((oid, pw))
        if weights_tr and weights_en:
            tr_by_w = sorted(weights_tr, key=lambda x: -x[1])
            en_by_w = sorted(weights_en, key=lambda x: -x[1])
            if [w for _, w in tr_by_w] != [w for _, w in en_by_w]:
                flags.append("possible_polarity_drift")
            # intensity: compare text length ratios at extremes
            max_tr = tr_by_w[0][0]
            min_tr = tr_by_w[-1][0]
            max_en = en_by_w[0][0]
            min_en = en_by_w[-1][0]
            if max_tr != max_en or min_tr != min_en:
                flags.append("possible_intensity_drift")
            else:
                tr_max_len = len(tr_opts[max_tr]["text"])
                tr_min_len = len(tr_opts[min_tr]["text"])
                en_max_len = len(en_opts[max_en]["text"])
                en_min_len = len(en_opts[min_en]["text"])
                if tr_max_len > tr_min_len and en_max_len < en_min_len:
                    flags.append("possible_intensity_drift")
                if tr_max_len < tr_min_len and en_max_len > en_min_len:
                    flags.append("possible_intensity_drift")

    # dedupe preserve order
    seen: set[str] = set()
    out: list[str] = []
    for f in flags:
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


def resolve_translation_status(flags: list[str], explicit: str | None) -> str:
    if explicit and explicit in TRANSLATION_STATUSES:
        if explicit != "PENDING_HUMAN_REVIEW":
            return explicit
    if "possible_cultural_mismatch" in flags:
        return "CROSS_CULTURAL_REVIEW_REQUIRED"
    if "possible_social_desirability_shift" in flags or "possible_ambiguity_change" in flags:
        return "EVIDENCE_PARITY_REVIEW_REQUIRED"
    return explicit or "PENDING_HUMAN_REVIEW"


def build_en_pool(tr_pool: dict, translations: dict) -> dict:
    tr_items = {it["item_id"]: it for it in tr_pool["items"]}
    trans_items = translations.get("items", {})
    missing = sorted(set(tr_items) - set(trans_items))
    if missing:
        raise SystemExit(f"Missing EN translations for {len(missing)} items: {missing[:5]}...")

    en_items = []
    for item_id in sorted(tr_items):
        tr_it = tr_items[item_id]
        tr_t = trans_items[item_id]
        en_it = copy.deepcopy(tr_it)
        en_it["locale"] = LOCALE_EN
        en_it["prompt"] = tr_t["prompt"]
        opt_text = tr_t.get("options", {})
        for opt in en_it["options"]:
            oid = opt["option_id"]
            if oid not in opt_text:
                raise SystemExit(f"Missing option translation {oid}")
            opt["text"] = opt_text[oid]
        en_items.append(en_it)

    en_pool = copy.deepcopy(tr_pool)
    en_pool.update(
        {
            "pool_version": POOL_VERSION_EN,
            "locale": LOCALE_EN,
            "translation_version": TRANSLATION_VERSION,
            "source_locale": LOCALE_TR,
            "source_pool_version": POOL_VERSION_TR,
            "behavioral_bank_version": tr_pool.get("pool_version", POOL_VERSION_TR),
            "runtime_selectable": False,
            "status": STATUS,
            "items": en_items,
        }
    )
    return en_pool


def build_en_review(tr_review: dict, tr_pool: dict, en_pool: dict, translations: dict) -> dict:
    tr_items = {it["item_id"]: it for it in tr_pool["items"]}
    en_items = {it["item_id"]: it for it in en_pool["items"]}
    trans_items = translations.get("items", {})
    en_review = copy.deepcopy(tr_review)
    en_review["pool_version"] = POOL_VERSION_EN
    en_review["locale"] = LOCALE_EN
    en_review["source_locale"] = LOCALE_TR
    en_review["source_pool_version"] = POOL_VERSION_TR
    en_review["translation_version"] = TRANSLATION_VERSION

    status_counts: Counter = Counter()
    flag_counts: Counter = Counter()
    new_items = []
    for tr_row in tr_review["items"]:
        item_id = tr_row["item_id"]
        row = copy.deepcopy(tr_row)
        tr_it = tr_items[item_id]
        en_it = en_items[item_id]
        tr_t = trans_items[item_id]
        flags = detect_review_flags(
            tr_it,
            en_it,
            tr_it["prompt"],
            tr_t["prompt"],
        )
        explicit = tr_t.get("translation_review_status")
        if tr_t.get("translation_review_flags"):
            for f in tr_t["translation_review_flags"]:
                if f not in flags:
                    flags.append(f)
        status = resolve_translation_status(flags, explicit)
        row["translation_review_status"] = status
        row["translation_review_flags"] = flags
        row["translation_source_prompt_tr"] = tr_it["prompt"]
        row["translation_target_prompt_en"] = tr_t["prompt"]
        status_counts[status] += 1
        for f in flags:
            flag_counts[f] += 1
        new_items.append(row)

    en_review["items"] = new_items
    en_review.setdefault("stats", {})
    en_review["stats"]["translation_review_status_counts"] = dict(status_counts)
    en_review["stats"]["translation_review_flag_counts"] = dict(flag_counts)
    en_review["stats"]["translation_version"] = TRANSLATION_VERSION
    return en_review


def validate_parity(tr_pool: dict, en_pool: dict, tr_review: dict, en_review: dict) -> list[str]:
    issues: list[str] = []
    tr_items = {it["item_id"]: it for it in tr_pool["items"]}
    en_items = {it["item_id"]: it for it in en_pool["items"]}
    tr_rev = {r["item_id"]: r for r in tr_review["items"]}
    en_rev = {r["item_id"]: r for r in en_review["items"]}

    if len(tr_items) != 426:
        issues.append(f"tr_item_count:{len(tr_items)}")
    if len(en_items) != 426:
        issues.append(f"en_item_count:{len(en_items)}")
    if en_pool.get("runtime_selectable") is not False:
        issues.append("en_runtime_selectable_not_false")

    tr_opt = en_opt = 0
    tr_drop = en_drop = 0
    tr_sel = en_sel = 0

    for iid in sorted(tr_items):
        if iid not in en_items:
            issues.append(f"en_only_or_missing:{iid}")
            continue
        ti, ei = tr_items[iid], en_items[iid]
        if ti["primary_dimensions"] != ei["primary_dimensions"]:
            issues.append(f"primary_mismatch:{iid}")
        if ti["semantic_cluster"] != ei["semantic_cluster"]:
            issues.append(f"cluster_mismatch:{iid}")
        if ti["secondary_dimensions"] != ei["secondary_dimensions"]:
            issues.append(f"secondary_mismatch:{iid}")
        tr_o = {o["option_id"]: o for o in ti["options"]}
        en_o = {o["option_id"]: o for o in ei["options"]}
        if set(tr_o) != set(en_o):
            issues.append(f"option_id_mismatch:{iid}")
        for oid, to in tr_o.items():
            tr_opt += 1
            en_opt += 1
            eo = en_o[oid]
            if to["behavioral_weights"] != eo["behavioral_weights"]:
                issues.append(f"weights:{iid}:{oid}")
            for k in EVIDENCE_KEYS:
                if (to.get("evidence_meta") or {}).get(k) != (eo.get("evidence_meta") or {}).get(k):
                    issues.append(f"evidence:{iid}:{oid}:{k}")
        tr_r, en_r = tr_rev[iid], en_rev[iid]
        for k in REVIEW_STRUCTURAL_KEYS:
            if tr_r.get(k) != en_r.get(k):
                issues.append(f"review:{iid}:{k}")

        if tr_r.get("drop_from_selectable"):
            tr_drop += 1
        if en_r.get("drop_from_selectable"):
            en_drop += 1
        if not tr_r.get("drop_from_selectable") and tr_r.get("selector_eligible"):
            tr_sel += 1
        if not en_r.get("drop_from_selectable") and en_r.get("selector_eligible"):
            en_sel += 1

    if tr_opt != 1704:
        issues.append(f"tr_option_count:{tr_opt}")
    if en_opt != 1704:
        issues.append(f"en_option_count:{en_opt}")
    if tr_drop != 21:
        issues.append(f"tr_drop_count:{tr_drop}")
    if en_drop != 21:
        issues.append(f"en_drop_count:{en_drop}")
    if tr_sel != 405:
        issues.append(f"tr_selectable_count:{tr_sel}")
    if en_sel != 405:
        issues.append(f"en_selectable_count:{en_sel}")

    tr_clusters = tr_review.get("semantic_near_duplicate_clusters") or []
    en_clusters = en_review.get("semantic_near_duplicate_clusters") or []
    def norm_clusters(clusters):
        return {tuple(sorted(c["item_ids"])) for c in clusters}
    if norm_clusters(tr_clusters) != norm_clusters(en_clusters):
        issues.append("near_duplicate_cluster_mismatch")

    return issues


def write_review_batches(
    tr_pool: dict,
    en_pool: dict,
    en_review: dict,
) -> list[Path]:
    REVIEW_DIR.mkdir(parents=True, exist_ok=True)
    tr_items = {it["item_id"]: it for it in tr_pool["items"]}
    en_items = {it["item_id"]: it for it in en_pool["items"]}
    rev = {r["item_id"]: r for r in en_review["items"]}
    ids = sorted(tr_items)
    paths: list[Path] = []
    batch_no = 0
    for start in range(0, len(ids), BATCH_SIZE):
        batch_no += 1
        chunk = ids[start : start + BATCH_SIZE]
        lo, hi = chunk[0], chunk[-1]
        q_lo = int(lo.split("_q")[1])
        q_hi = int(hi.split("_q")[1])
        fname = REVIEW_DIR / f"frequency_v2_en_review_{q_lo:03d}_{q_hi:03d}.md"
        lines = [
            f"# Frequency V2 EN Human Review — {q_lo:03d}–{q_hi:03d}",
            "",
            f"**Status:** machine-generated triage — NOT human-reviewed",
            f"**Translation version:** `{TRANSLATION_VERSION}`",
            f"**Items:** {len(chunk)}",
            "",
            "---",
            "",
        ]
        for iid in chunk:
            ti, ei = tr_items[iid], en_items[iid]
            r = rev[iid]
            lines.extend(
                [
                    f"## {iid}",
                    "",
                    f"- **primary_dimension:** `{', '.join(ti['primary_dimensions'])}`",
                    f"- **semantic_cluster:** `{ti['semantic_cluster']}`",
                    f"- **translation_review_status:** `{r.get('translation_review_status')}`",
                    "",
                    "### Stems",
                    "",
                    f"**TR:** {ti['prompt']}",
                    "",
                    f"**EN:** {ei['prompt']}",
                    "",
                    "### Options",
                    "",
                ]
            )
            tr_o = {o["option_id"]: o for o in ti["options"]}
            en_o = {o["option_id"]: o for o in ei["options"]}
            for oid in sorted(tr_o):
                to, eo = tr_o[oid], en_o[oid]
                w = json.dumps(to["behavioral_weights"], ensure_ascii=False)
                lines.extend(
                    [
                        f"#### `{oid}`",
                        f"- **TR:** {to['text']}",
                        f"- **EN:** {eo['text']}",
                        f"- **behavioral_weights:** `{w}`",
                        "",
                    ]
                )
            flags = r.get("translation_review_flags") or []
            lines.append("### Machine triage flags")
            lines.append("")
            if flags:
                for f in flags:
                    lines.append(f"- `{f}`")
            else:
                lines.append("- _(none)_")
            lines.extend(["", "---", ""])
        fname.write_text("\n".join(lines), encoding="utf-8")
        paths.append(fname)
    return paths


def write_audit(
    tr_pool: dict,
    en_pool: dict,
    en_review: dict,
    issues: list[str],
    review_paths: list[Path],
) -> None:
    stats = en_review.get("stats", {})
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [
        "# Frequency V2 Phase 6A — EN Semantic Parity Audit",
        "",
        f"**Generated:** {now}",
        f"**Translation version:** `{TRANSLATION_VERSION}`",
        f"**EN pool version:** `{POOL_VERSION_EN}`",
        f"**TR source pool:** `{POOL_VERSION_TR}`",
        "",
        "## Parity validation",
        "",
        f"- **Result:** {'PASS' if not issues else 'FAIL'}",
        f"- **Issue count:** {len(issues)}",
        "",
    ]
    if issues:
        lines.append("### Issues")
        lines.append("")
        for i in issues[:50]:
            lines.append(f"- `{i}`")
        if len(issues) > 50:
            lines.append(f"- ... and {len(issues) - 50} more")
        lines.append("")

    lines.extend(
        [
            "## Counts",
            "",
            "| Metric | TR | EN |",
            "|---|---:|---:|",
            f"| Questions | 426 | {len(en_pool['items'])} |",
            f"| Options | 1704 | {sum(len(i['options']) for i in en_pool['items'])} |",
            f"| DROP | 21 | {sum(1 for r in en_review['items'] if r.get('drop_from_selectable'))} |",
            f"| Selectable | 405 | {sum(1 for r in en_review['items'] if not r.get('drop_from_selectable') and r.get('selector_eligible'))} |",
            f"| runtime_selectable | false | {en_pool.get('runtime_selectable')} |",
            "",
            "## Translation review status",
            "",
        ]
    )
    for k, v in sorted((stats.get("translation_review_status_counts") or {}).items()):
        lines.append(f"- `{k}`: {v}")
    lines.extend(["", "## Translation triage flags", ""])
    for k, v in sorted(
        (stats.get("translation_review_flag_counts") or {}).items(),
        key=lambda x: -x[1],
    ):
        lines.append(f"- `{k}`: {v}")
    lines.extend(
        [
            "",
            "## Human review batches",
            "",
        ]
    )
    for p in review_paths:
        lines.append(f"- `{p.relative_to(ROOT)}`")
    lines.extend(
        [
            "",
            "## Notes",
            "",
            "- EN bank is a semantic presentation of the same behavioral assessment version.",
            "- All question/option IDs, weights, evidence priors, and selector metadata match TR.",
            "- Translation quality is **not** human-approved; review batches are triage only.",
            "- V2 and EN routing remain dormant (`runtime_selectable=false`).",
            "",
        ]
    )
    AUDIT.write_text("\n".join(lines), encoding="utf-8")


def merge_translation_batches(batch_dir: Path) -> dict:
    merged: dict = {"items": {}}
    for path in sorted(batch_dir.glob("frequency_v2_en_semantic_text_batch_*.json")):
        chunk = load_json(path)
        for iid, data in chunk.get("items", {}).items():
            if iid in merged["items"]:
                raise SystemExit(f"Duplicate translation item {iid} in {path.name}")
            merged["items"][iid] = data
    merged["translation_version"] = TRANSLATION_VERSION
    return merged


def main() -> None:
    tr_pool = load_json(TR_POOL)
    tr_review = load_json(TR_REVIEW)

    batch_dir = OUT / "en_translation_batches"
    if EN_TRANSLATIONS.exists():
        translations = load_json(EN_TRANSLATIONS)
    elif batch_dir.exists() and list(batch_dir.glob("*.json")):
        translations = merge_translation_batches(batch_dir)
        EN_TRANSLATIONS.write_text(
            json.dumps(translations, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
    else:
        raise SystemExit(
            f"Missing translations: {EN_TRANSLATIONS} or batches in {batch_dir}"
        )

    en_pool = build_en_pool(tr_pool, translations)
    en_review = build_en_review(tr_review, tr_pool, en_pool, translations)
    issues = validate_parity(tr_pool, en_pool, tr_review, en_review)

    EN_POOL.write_text(json.dumps(en_pool, ensure_ascii=False, indent=2), encoding="utf-8")
    EN_REVIEW.write_text(json.dumps(en_review, ensure_ascii=False, indent=2), encoding="utf-8")
    review_paths = write_review_batches(tr_pool, en_pool, en_review)
    write_audit(tr_pool, en_pool, en_review, issues, review_paths)

    print(f"EN pool: {EN_POOL}")
    print(f"EN review: {EN_REVIEW}")
    print(f"Audit: {AUDIT}")
    print(f"Review batches: {len(review_paths)}")
    print(f"Parity: {'PASS' if not issues else 'FAIL'} ({len(issues)} issues)")
    if issues:
        for i in issues[:10]:
            print(f"  - {i}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
