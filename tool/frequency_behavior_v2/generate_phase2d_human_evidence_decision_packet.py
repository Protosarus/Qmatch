#!/usr/bin/env python3
"""Phase 2D: human evidence decision packet. Proposal-only. Does not apply scores.

Covers the 29 REAL_REVIEW_REQUIRED questions and the 10 Phase 2C
±1 diagnostic_value leakage-suspect options. Does not rescore the bank.
"""
from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parent / "out"
POOL_PATH = OUT_DIR / "frequency_behavior_pool_tr_v2_draft1.json"
PROPOSAL_PATH = OUT_DIR / "frequency_behavior_v2_phase2b_evidence_prior_proposal.json"
TRIAGE_PATH = OUT_DIR / "frequency_behavior_v2_phase2c_evidence_triage.json"
PACKET_PATH = OUT_DIR / "frequency_behavior_v2_phase2d_human_evidence_decision_packet.md"

FIELDS = (
    "social_desirability",
    "obviousness",
    "behavioral_plausibility",
    "self_presentation_risk",
    "diagnostic_value",
    "ambiguity",
)
ACTIONS = (
    "KEEP_SCORES",
    "ADJUST_EVIDENCE_ONLY",
    "REWRITE_REQUIRED",
    "DROP_FROM_SELECTABLE",
)
GRID = {0.00, 0.25, 0.50, 0.75, 1.00}

# Compact human recommendations. Scores/text are copied from the proposal at runtime.
QUESTION_RECS: dict[str, dict] = {
    "frequency_v2_q0002": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Option D ('eşlik etmekten keyif alırım') is an ideal-self / people-pleasing "
            "script with a large social-desirability gap versus A–C. It is also off the "
            "named structure_preference axis. A–C still form a readable structure contrast "
            "(flow / need a draft / do own work then join)."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0002_d",
                "field": "obviousness",
                "new": 0.75,
                "why": "The wording is easy to read as the approved 'good partner' answer.",
            }
        ],
    },
    "frequency_v2_q0015": {
        "action": "KEEP_SCORES",
        "issue": (
            "Option A is socially attractive (immediate hug + apology). That is a wording "
            "advantage, not proof that repair engagement is 'correct'. Proposed scores "
            "already mark A high on social_desirability and self_presentation_risk. "
            "The four repair-pacing readings remain usable."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0020": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Named primary is uncertainty_tolerance, but no option carries that weight. "
            "The four reactions (insist / wait / ignore / hug) are interpretable as "
            "contact, boundary, and closeness behaviors. Evidence scoring cannot attach "
            "an uncertainty-tolerance signal that the options do not instantiate."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0026": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Value-disagreement scene is readable, but options map to initiative, "
            "boundary/autonomy, disclosure, and adaptability — none to the named "
            "uncertainty_tolerance primary. Scoring cannot relabel the axis."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0030": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Hidden-past-detail stem could be uncertainty or disclosure, but current "
            "options are authored on disclosure, adaptability, and reassurance. None "
            "carry uncertainty_tolerance. Evidence priors cannot create that primary."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0035": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Stress-spillover stem is multidimensional. Options are contact/reassurance, "
            "autonomy, structure/uncertainty, and self-sacrifice — none carry "
            "disclosure_pace. Scoring cannot recover a disclosure contrast."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0049": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "A and B already span reassurance_need. D is a textbook 'healthy communication' "
            "script (iletişim fırsatı / suçlamadan / net) and is off-primary. B also "
            "contains an identity claim ('kıskançlık yapan biri değilimdir') whose "
            "social-desirability prior is too low."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0049_b",
                "field": "social_desirability",
                "new": 0.75,
                "why": "The wording presents a composed, non-jealous identity relative to A/C.",
            },
            {
                "option_id": "frequency_v2_q0049_b",
                "field": "self_presentation_risk",
                "new": 0.75,
                "why": "Easy to select mainly to look unjealous; not a lie score.",
            },
            {
                "option_id": "frequency_v2_q0049_d",
                "field": "diagnostic_value",
                "new": 0.25,
                "why": "If chosen sincerely it signals communication style, not reassurance_need.",
            },
        ],
    },
    "frequency_v2_q0081": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Meeting family/close circle is culturally loaded, but the four answers "
            "(early / when the time comes / when I am ready / let it flow) still form a "
            "closeness_pace contrast. Short wording made Phase 2B mark A–C as implausible; "
            "they are ordinary brief reactions, not caricatures."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0081_a",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Brief but ordinary 'I want it early' reaction.",
            },
            {
                "option_id": "frequency_v2_q0081_b",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Brief but ordinary wait-for-timing reaction.",
            },
            {
                "option_id": "frequency_v2_q0081_c",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Brief but ordinary self-readiness boundary.",
            },
        ],
    },
    "frequency_v2_q0097": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "A/B are socially attractive apology scripts; that is already partly scored. "
            "A is a stub, so Phase 2B set low plausibility and high ambiguity. The text "
            "'Hemen ve net özür dilerim' is a clear, ordinary immediate-repair pole."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0097_a",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Short, but a realistic immediate apology.",
            },
            {
                "option_id": "frequency_v2_q0097_a",
                "field": "ambiguity",
                "new": 0.25,
                "why": "One clear repair-pacing reading, not mixed motives.",
            },
        ],
    },
    "frequency_v2_q0107": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Option B mixes space with a small contact request ('ama … küçük bir temas'). "
            "That is one mixed-motive reading, not two incompatible interpretations. "
            "ambiguity=1.00 is a Phase 2B conjunction overflag."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0107_b",
                "field": "ambiguity",
                "new": 0.50,
                "why": "Readable mixed space-plus-contact request, not uninterpretable.",
            }
        ],
    },
    "frequency_v2_q0123": {
        "action": "KEEP_SCORES",
        "issue": (
            "Near-duplicate of q0015. Option A is the obvious immediate-apology script; "
            "proposed scores already raise social_desirability, obviousness, and "
            "self_presentation_risk. Do not treat high repair engagement as the correct answer."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0152": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Option D (discomfort without asking; wait for them to unfollow) was scored "
            "ambiguity=1.00. It is a single delayed/indirect reading, not two opposite "
            "meanings. C is more test-transparent ('açıkça … netleştiririm') and already "
            "marked high on social_desirability/obviousness."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0152_d",
                "field": "ambiguity",
                "new": 0.50,
                "why": "Discomfort-plus-silence is one interpretation.",
            }
        ],
    },
    "frequency_v2_q0156": {
        "action": "KEEP_SCORES",
        "issue": (
            "Family-dinner timing is culturally loaded. A still carries closeness_pace; "
            "B–D drift into disclosure/social_energy/initiative and already have lower "
            "diagnostic_value. Keep the priors; do not treat family-meeting enthusiasm as "
            "healthier closeness."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0159": {
        "action": "KEEP_SCORES",
        "issue": (
            "Bill-splitting ('Alman usulü', 'en adilidir', provider-script D) is culturally "
            "dependent. The four options still contrast structure vs rotation vs not tracking "
            "vs being paid for. Proposed SD on A and low DV on D already reflect that. "
            "Keep scores; interpret later with locale caution."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0176": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Option B (respect the diet, keep my own food, two menus) is the clearest "
            "autonomy/boundary pole in the set. ambiguity=1.00 is an 'ama' overflag, not "
            "two rival meanings."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0176_b",
                "field": "ambiguity",
                "new": 0.25,
                "why": "One clear two-menu / non-merging reading.",
            }
        ],
    },
    "frequency_v2_q0186": {
        "action": "KEEP_SCORES",
        "issue": (
            "The stem states the respondent was completely wrong, which moralizes the "
            "scene. B ('gurur yapmadan … özür') is the obvious approved repair. Proposed "
            "scores already mark it high on social_desirability, obviousness, and "
            "self_presentation_risk. Immediate apology is not scored as more 'healthy'."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0197": {
        "action": "KEEP_SCORES",
        "issue": (
            "Money-pooling norms vary by culture. A vs B still instantiate a usable "
            "autonomy contrast (fully merged money vs pooled bills plus separate savings). "
            "C/D are off-primary and already low diagnostic. Keep priors."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0203": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "B ('Giderim ama kısa tutarım') is a clear milder boundary, not ambiguity=1.00. "
            "Short wording also under-scored plausibility. C is the obvious firm no and "
            "already has high obviousness — leave that."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0203_b",
                "field": "ambiguity",
                "new": 0.50,
                "why": "Attend-but-limit-time is one mixed but readable boundary.",
            },
            {
                "option_id": "frequency_v2_q0203_b",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Ordinary real-world compromise, not a stub caricature.",
            },
            {
                "option_id": "frequency_v2_q0203_b",
                "field": "diagnostic_value",
                "new": 0.50,
                "why": "Sincere selection gives a milder on-axis boundary signal versus C.",
            },
            {
                "option_id": "frequency_v2_q0203_d",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Brief but realistic self-push to attend.",
            },
        ],
    },
    "frequency_v2_q0208": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Who-pays is culturally loaded, but the four answers (split / accept / rotate / "
            "always separate) are interpretable. A/B plausibility 0.25 is stub leakage. "
            "Primary is autonomy; D is the strongest on-axis option."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0208_a",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Ordinary split suggestion.",
            },
            {
                "option_id": "frequency_v2_q0208_b",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Ordinary acceptance of being paid for.",
            },
            {
                "option_id": "frequency_v2_q0208_a",
                "field": "diagnostic_value",
                "new": 0.50,
                "why": "Proposing to share is a usable milder autonomy/structure signal.",
            },
        ],
    },
    "frequency_v2_q0213": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Family introduction is culturally loaded, and A ('Biraz erken') vs D "
            "('Ertelemeyi öneririm') are functionally near-duplicates of slowing the pace. "
            "Evidence scoring cannot create contrast between those two options."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0227": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Family/bayram invitation vs an existing plan is culturally loaded, but A–D "
            "still contrast adaptability (drop plan / decline / short visit / reschedule). "
            "Stub plausibility 0.25 on A–C is not deserved."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0227_a",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Canceling one's plan to attend is ordinary, not artificial.",
            },
            {
                "option_id": "frequency_v2_q0227_b",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Declining this time is an ordinary boundary.",
            },
            {
                "option_id": "frequency_v2_q0227_c",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "A short appearance is a realistic compromise.",
            },
            {
                "option_id": "frequency_v2_q0227_b",
                "field": "diagnostic_value",
                "new": 0.50,
                "why": "Clear non-adapting pole versus A; 0.00 was cue leakage.",
            },
        ],
    },
    "frequency_v2_q0278": {
        "action": "KEEP_SCORES",
        "issue": (
            "A (grateful for 'objective' advice) and B (textbook 'just listen' boundary) "
            "are both socially coded. Proposed scores already put A at SD/SPR 1.00 and B "
            "at obviousness 1.00. Keep those priors; do not treat B as the mature answer."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0317": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "After a fight, partner asks for space. Options (give space / ask how long / "
            "text / withdraw too) are interpretable, but none carry repair_style. Evidence "
            "scoring cannot measure repair engagement from autonomy/contact weights."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0332": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Near-duplicate scenario of q0227 (family event vs existing commitment). Same "
            "adaptability contrast; same stub-plausibility overflag. Cultural loading is "
            "real but does not make the four choices unreadable."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0332_a",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Ordinary plan-drop to attend.",
            },
            {
                "option_id": "frequency_v2_q0332_b",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Ordinary decline.",
            },
            {
                "option_id": "frequency_v2_q0332_c",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Ordinary short visit.",
            },
            {
                "option_id": "frequency_v2_q0332_b",
                "field": "diagnostic_value",
                "new": 0.50,
                "why": "Clear non-adapting pole versus A.",
            },
        ],
    },
    "frequency_v2_q0375": {
        "action": "ADJUST_EVIDENCE_ONLY",
        "issue": (
            "Option B uses hyperbolic 'her zaman felaketle sonuçlanır', so Phase 2C marked "
            "low plausibility. It is a strong but realistic refuse-to-mix-work-and-relationship "
            "stance, not a cartoon. C is off-primary (structure) with DV 0.00 — leave that."
        ),
        "adjustments": [
            {
                "option_id": "frequency_v2_q0375_b",
                "field": "behavioral_plausibility",
                "new": 0.75,
                "why": "Forceful wording, but a believable hard no on mixing business and the relationship.",
            }
        ],
    },
    "frequency_v2_q0377": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Forgotten wallet at a luxury restaurant is culturally loaded (who pays, "
            "fairness, being 'used'). Named primary is adaptability, but only B carries "
            "a small adaptability weight; others are boundary, reassurance, and structure. "
            "Scoring cannot turn a money-fairness scene into an adaptability item."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0393": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Rain-on-the-way-to-an-event is a strong adaptability scene in the text, but "
            "weights sit on uncertainty, closeness, initiative, and structure — none on "
            "adaptability. All four diagnostic_value=0.25 because they are off-primary. "
            "Evidence scoring cannot re-author the axis."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0409": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Partner withdraws after a fight. Options are space / ask duration / 'I'm here' "
            "/ withdraw too. Readable behaviors, but none carry repair_style. Same class "
            "as q0317. Scoring cannot supply the missing primary."
        ),
        "adjustments": [],
    },
    "frequency_v2_q0410": {
        "action": "REWRITE_REQUIRED",
        "issue": (
            "Early family introduction is culturally loaded. A ('Kabul ederim') is a stub; "
            "B/D both slow the pace ('biraz erken' / 'Ertelemeyi öneririm') with little "
            "semantic contrast. Scoring cannot separate those slowing options."
        ),
        "adjustments": [],
    },
}

DV_RECS: dict[str, dict] = {
    "frequency_v2_q0001_c": {
        "judgment": "DV_TOO_LOW",
        "new_diagnostic_value": 0.75,
        "why": (
            "A short, specific first-contact message is a clear milder initiative pole "
            "versus waiting (B) or steering with a joke (A). Low DV is cue/magnitude leakage, "
            "not weak text."
        ),
    },
    "frequency_v2_q0006_c": {
        "judgment": "DV_TOO_LOW",
        "new_diagnostic_value": 0.50,
        "why": (
            "Tolerating an unlabeled relationship if actions already match is a distinct "
            "+1 uncertainty reading versus needing a talk (A) or waiting for them to open (D)."
        ),
    },
    "frequency_v2_q0018_b": {
        "judgment": "DV_TOO_LOW",
        "new_diagnostic_value": 0.75,
        "why": (
            "Lock only the first step and leave the rest is the textbook milder uncertainty "
            "pole between leaving the topic open (+2) and needing same-day numbers (−2)."
        ),
    },
    "frequency_v2_q0062_d": {
        "judgment": "DV_JUSTIFIED",
        "new_diagnostic_value": None,
        "why": (
            "Text is mostly switching to a solo plan (autonomy +2). It does not adapt the "
            "shared plan, so diagnostic_value 0.25 for adaptability is fair."
        ),
    },
    "frequency_v2_q0082_b": {
        "judgment": "DV_TOO_LOW",
        "new_diagnostic_value": 0.50,
        "why": (
            "Keeping a backup if the maybe-cancel happens is a real +1 uncertainty reading "
            "versus pinning it down now (A). Residual autonomy mix keeps it at 0.50, not 0.75."
        ),
    },
    "frequency_v2_q0101_c": {
        "judgment": "DV_TOO_LOW",
        "new_diagnostic_value": 0.75,
        "why": (
            "Same pattern as q0001 C: a short 'dün güzeldi' ping is a clear milder initiative "
            "act, not a weak signal."
        ),
    },
    "frequency_v2_q0105_c": {
        "judgment": "DV_TOO_LOW",
        "new_diagnostic_value": 0.50,
        "why": (
            "Making my own plan and inviting them is a readable initiative move versus "
            "offering couple-options (A) or following them (D). Autonomy is co-present, "
            "so 0.50 not 0.75."
        ),
    },
    "frequency_v2_q0129_c": {
        "judgment": "DV_JUSTIFIED",
        "new_diagnostic_value": None,
        "why": (
            "A shared reminder system is structure_preference, not delayed repair. "
            "Low diagnostic_value on repair_style matches the text."
        ),
    },
    "frequency_v2_q0133_d": {
        "judgment": "DV_JUSTIFIED",
        "new_diagnostic_value": None,
        "why": (
            "Leaving initiation to them is mostly initiative −1. It does not increase "
            "contact toward the partner's request, so low adaptability diagnostic_value is fair."
        ),
    },
    "frequency_v2_q0145_b": {
        "judgment": "DV_JUSTIFIED",
        "new_diagnostic_value": None,
        "why": (
            "Same as q0129 C: a reminder system is a structural fix, not a repair-pacing "
            "signal. Keep 0.25."
        ),
    },
}


def fingerprint(pool: dict) -> str:
    rows = []
    for it in pool["items"]:
        opts = [
            (o["option_id"], o["text"], json.dumps(o["behavioral_weights"], sort_keys=True))
            for o in it["options"]
        ]
        rows.append((it["item_id"], it["prompt"], opts))
    blob = json.dumps(rows, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(blob.encode("utf-8")).hexdigest()


def file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fmt_score(v: float) -> str:
    return f"{v:.2f}"


def main() -> None:
    proposal_hash = file_sha256(PROPOSAL_PATH)
    triage_hash = file_sha256(TRIAGE_PATH)
    proposal = json.loads(PROPOSAL_PATH.read_text(encoding="utf-8"))
    triage = json.loads(TRIAGE_PATH.read_text(encoding="utf-8"))
    pool = json.loads(POOL_PATH.read_text(encoding="utf-8"))
    fp = fingerprint(pool)

    if proposal.get("applied_to_pool") is not False:
        raise SystemExit("proposal applied")
    if pool.get("runtime_selectable") is not False:
        raise SystemExit("runtime_selectable")
    for it in pool["items"]:
        for o in it["options"]:
            em = o.get("evidence_meta") or {}
            if em.get("review_status") != "pending":
                raise SystemExit("pool evidence not pending")
            for f in FIELDS:
                if em.get(f) is not None:
                    raise SystemExit("pool evidence assigned")

    real_ids = list(triage["real_review_required_ids"])
    if real_ids != sorted(QUESTION_RECS):
        missing = set(real_ids) - set(QUESTION_RECS)
        extra = set(QUESTION_RECS) - set(real_ids)
        raise SystemExit(f"rec id mismatch missing={missing} extra={extra}")

    leak_opts = [
        r
        for r in triage["diagnostic_value_bias"]["sample_pm1_dv_le_025"]
        if r.get("judgment") == "WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE"
    ]
    if len(leak_opts) != 10:
        raise SystemExit(f"expected 10 leakage-suspect options, got {len(leak_opts)}")
    leak_ids = [r["option_id"] for r in leak_opts]
    if leak_ids != list(DV_RECS):
        raise SystemExit(f"DV rec ids must match leakage sample order: {leak_ids}")

    pool_by = {it["item_id"]: it for it in pool["items"]}
    prop_by = {q["question_id"]: q for q in proposal["items"]}
    tri_by = {q["question_id"]: q for q in triage["questions"]}

    lines: list[str] = []
    lines.append("# Frequency V2 Phase 2D — Human evidence decision packet")
    lines.append("")
    lines.append("Status: **packet only**. No scores applied. Proposal JSON unchanged.")
    lines.append("Dormant pool `evidence_meta` remains `pending` / null.")
    lines.append("V2 remains `runtime_selectable=false`. Bank-wide rescoring was not done.")
    lines.append("")
    lines.append(f"Source pool fingerprint SHA-256: `{fp}`")
    lines.append(f"Phase 2B proposal SHA-256 (unchanged): `{proposal_hash}`")
    lines.append(f"Phase 2C triage SHA-256 (unchanged): `{triage_hash}`")
    lines.append("")
    lines.append("Scope:")
    lines.append("")
    lines.append("- 29 `REAL_REVIEW_REQUIRED` questions from Phase 2C")
    lines.append("- 10 sampled ±1 options with `diagnostic_value` ≤ 0.25 judged as possible cue/magnitude leakage")
    lines.append("")
    lines.append("Priors remain uncalibrated. High social desirability is not falsehood.")
    lines.append("Do not treat reassurance as weak, boundary as healthy, autonomy as mature,")
    lines.append("or repair engagement as the correct answer.")
    lines.append("")
    lines.append("## 1. Twenty-nine REAL_REVIEW_REQUIRED questions")
    lines.append("")

    action_c: Counter[str] = Counter()
    for qid in real_ids:
        rec = QUESTION_RECS[qid]
        action = rec["action"]
        if action not in ACTIONS:
            raise SystemExit(action)
        action_c[action] += 1
        pq = prop_by[qid]
        src = pool_by[qid]
        tq = tri_by[qid]
        letters = "ABCD"
        lines.append(f"### `{qid}`")
        lines.append("")
        lines.append(f"- **Primary dimension:** `{pq['primary_dimension']}`")
        lines.append(f"- **Triage reason codes:** {', '.join(f'`{c}`' for c in tq['reason_codes'])}")
        lines.append(f"- **Phase 2B quality:** {pq['question_evidence_quality']}")
        lines.append(f"- **Question text:** {src['prompt']}")
        lines.append("")
        for i, (o, so) in enumerate(zip(pq["options"], src["options"])):
            if o["option_text"] != so["text"] or o["behavioral_weights"] != so["behavioral_weights"]:
                raise SystemExit(f"proposal/pool drift {o['option_id']}")
            em = o["evidence_meta"]
            letter = letters[i]
            w = json.dumps(o["behavioral_weights"], ensure_ascii=False)
            scores = ", ".join(f"{k}={fmt_score(em[k])}" for k in FIELDS)
            lines.append(f"**{letter}.** `{o['option_id']}`")
            lines.append(f"- text: {o['option_text']}")
            lines.append(f"- behavioral_weights: `{w}`")
            lines.append(f"- proposed evidence: {scores}")
            lines.append("")
        lines.append("**ISSUE ANALYSIS**")
        lines.append("")
        lines.append(rec["issue"])
        lines.append("")
        lines.append(f"**RECOMMENDATION:** `{action}`")
        lines.append("")
        if action == "REWRITE_REQUIRED":
            lines.append(
                "Evidence scoring alone cannot fix this. Do not rewrite in Phase 2D."
            )
            lines.append("")
        if action == "DROP_FROM_SELECTABLE":
            lines.append("Recommend removing from the selectable dormant set. Not applied.")
            lines.append("")
        if rec["adjustments"]:
            if action != "ADJUST_EVIDENCE_ONLY":
                raise SystemExit(f"adjustments without ADJUST {qid}")
            lines.append("Proposed evidence adjustments (fields that should change only):")
            lines.append("")
            for adj in rec["adjustments"]:
                oid, field, new = adj["option_id"], adj["field"], adj["new"]
                if field not in FIELDS or new not in GRID:
                    raise SystemExit(f"bad adjustment {adj}")
                opt = next(o for o in pq["options"] if o["option_id"] == oid)
                old = float(opt["evidence_meta"][field])
                if old == new:
                    raise SystemExit(f"no-op adjustment {oid} {field}")
                lines.append(
                    f"- `{oid}` `{field}`: {fmt_score(old)} → {fmt_score(new)} — {adj['why']}"
                )
            lines.append("")
        elif action == "ADJUST_EVIDENCE_ONLY":
            raise SystemExit(f"ADJUST without rows {qid}")
        lines.append("---")
        lines.append("")

    lines.append("## 2. Ten suspect ±1 low-diagnostic_value options")
    lines.append("")
    lines.append(
        "These are the Phase 2C sample rows with `diagnostic_value` ≤ 0.25 and "
        "judgment `WEIGHT_MAGNITUDE_OR_CUE_LEAKAGE`. ±2 is not assumed to be more "
        "diagnostic than ±1. Judge the option text."
    )
    lines.append("")

    dv_c: Counter[str] = Counter()
    for row in leak_opts:
        rec = DV_RECS[row["option_id"]]
        j = rec["judgment"]
        if j not in ("DV_JUSTIFIED", "DV_TOO_LOW"):
            raise SystemExit(j)
        dv_c[j] += 1
        lines.append(f"### `{row['option_id']}`")
        lines.append("")
        lines.append(f"- question_id: `{row['question_id']}`")
        lines.append(f"- option_text: {row['option_text']}")
        lines.append(f"- primary_dimension: `{row['primary_dimension']}`")
        lines.append(f"- primary_weight: {row['primary_weight']:+.0f}")
        lines.append(f"- current diagnostic_value: {fmt_score(row['diagnostic_value'])}")
        lines.append(f"- ambiguity: {fmt_score(row['ambiguity'])}")
        lines.append(f"- behavioral_plausibility: {fmt_score(row['behavioral_plausibility'])}")
        lines.append(f"- behavioral_weights: `{json.dumps(row['behavioral_weights'], ensure_ascii=False)}`")
        lines.append("")
        lines.append(f"**Classification:** `{j}`")
        lines.append("")
        if j == "DV_TOO_LOW":
            new = rec["new_diagnostic_value"]
            if new not in GRID:
                raise SystemExit(f"bad dv grid {row['option_id']}")
            if new == float(row["diagnostic_value"]):
                raise SystemExit(f"DV_TOO_LOW no change {row['option_id']}")
            lines.append(
                f"**Revised diagnostic_value:** {fmt_score(row['diagnostic_value'])} → {fmt_score(new)}"
            )
            lines.append("")
        lines.append(rec["why"])
        lines.append("")
        lines.append("---")
        lines.append("")

    if sum(action_c.values()) != 29:
        raise SystemExit("need 29 question recs")
    if sum(dv_c.values()) != 10:
        raise SystemExit("need 10 dv recs")

    lines.append("## Counts")
    lines.append("")
    lines.append("Question recommendations:")
    lines.append("")
    for a in ACTIONS:
        lines.append(f"- `{a}`: **{action_c[a]}**")
    lines.append("")
    lines.append("±1 diagnostic_value sample:")
    lines.append("")
    lines.append(f"- `DV_JUSTIFIED`: **{dv_c['DV_JUSTIFIED']}**")
    lines.append(f"- `DV_TOO_LOW`: **{dv_c['DV_TOO_LOW']}**")
    lines.append("")
    lines.append("## Safety")
    lines.append("")
    lines.append("- Phase 2B proposal JSON not modified")
    lines.append("- Phase 2C triage not modified")
    lines.append("- Dormant pool not modified")
    lines.append("- Question/option text not modified")
    lines.append("- Behavioral weights not modified")
    lines.append("- DROP options not scored")
    lines.append("- V2 remains dormant")
    lines.append("- No V1 / Firebase / matching / Persona / Discover / C2 change")
    lines.append("")
    lines.append("FREQUENCY V2 PHASE 2D HUMAN EVIDENCE DECISION PACKET READY — NO VALUES APPLIED")
    lines.append("")

    PACKET_PATH.write_text("\n".join(lines), encoding="utf-8")

    if file_sha256(PROPOSAL_PATH) != proposal_hash:
        raise SystemExit("proposal changed")
    if file_sha256(TRIAGE_PATH) != triage_hash:
        raise SystemExit("triage changed")
    if fingerprint(json.loads(POOL_PATH.read_text(encoding="utf-8"))) != fp:
        raise SystemExit("pool changed")

    print("KEEP_SCORES", action_c["KEEP_SCORES"])
    print("ADJUST_EVIDENCE_ONLY", action_c["ADJUST_EVIDENCE_ONLY"])
    print("REWRITE_REQUIRED", action_c["REWRITE_REQUIRED"])
    print("DROP_FROM_SELECTABLE", action_c["DROP_FROM_SELECTABLE"])
    print("DV_JUSTIFIED", dv_c["DV_JUSTIFIED"])
    print("DV_TOO_LOW", dv_c["DV_TOO_LOW"])
    print("FREQUENCY V2 PHASE 2D HUMAN EVIDENCE DECISION PACKET READY — NO VALUES APPLIED")


if __name__ == "__main__":
    main()
