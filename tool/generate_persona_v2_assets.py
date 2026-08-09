#!/usr/bin/env python3
"""Offline authoring helper for provisional persona_profiles_v2_20d + config.

PROVISIONAL hypotheses only. Not psychological norms. Not runtime-loaded.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIMS = [
    "logical_reasoning",
    "pattern_reasoning",
    "verbal_reasoning",
    "spatial_reasoning",
    "empathy",
    "perspective_taking",
    "self_awareness",
    "emotion_regulation",
    "emotional_openness",
    "boundary_setting",
    "assertiveness",
    "conflict_approach",
    "repair_orientation",
    "social_awareness",
    "depth_preference",
    "social_energy",
    "spontaneity",
    "stability",
    "disclosure_pace",
    "communication_pace",
]
IQ, EQ, FREQ = DIMS[:4], DIMS[4:14], DIMS[14:]

LABELS = {
    "uygulayici": ("Uygulayıcı", "Executor"),
    "koruyucu": ("Koruyucu", "Guardian"),
    "bilge": ("Bilge", "Sage"),
    "lider": ("Lider", "Leader"),
    "muhafiz": ("Muhafız", "Sentinel"),
    "sifaci": ("Şifacı", "Healer"),
    "yargic": ("Yargıç", "Judge"),
    "empat": ("Empat", "Empath"),
    "cesur": ("Cesur", "Brave"),
    "kararli": ("Kararlı", "Determined"),
    "vizyoner": ("Vizyoner", "Visionary"),
    "yaratici": ("Yaratıcı", "Creator"),
    "iletisimci": ("İletişimci", "Communicator"),
    "analist": ("Analist", "Analyst"),
    "donusturucu": ("Dönüştürücü", "Transformer"),
    "bagimsiz": ("Bağımsız", "Independent"),
    "sezgisel": ("Sezgisel", "Intuitive"),
    "stratejist": ("Stratejist", "Strategist"),
}

# target vectors: list of 20 floats in DIMS order — provisional
# PROVISIONAL targets. Frequency signatures are intentionally peaked away from
# 0.5 so central synthetic profiles do not collapse onto a single "mid" persona.
TARGETS: dict[str, list[float]] = {
    "uygulayici": [
        0.72, 0.54, 0.46, 0.50,
        0.40, 0.48, 0.60, 0.78, 0.32, 0.70, 0.76, 0.60, 0.52, 0.50,
        0.42, 0.58, 0.22, 0.90, 0.36, 0.70,
    ],
    "koruyucu": [
        0.46, 0.44, 0.54, 0.42,
        0.88, 0.72, 0.66, 0.74, 0.74, 0.82, 0.52, 0.48, 0.84, 0.70,
        0.80, 0.48, 0.24, 0.88, 0.74, 0.50,
    ],
    "bilge": [
        0.64, 0.62, 0.82, 0.48,
        0.60, 0.88, 0.90, 0.76, 0.56, 0.56, 0.34, 0.44, 0.62, 0.64,
        0.88, 0.26, 0.28, 0.72, 0.52, 0.28,
    ],
    "lider": [
        0.66, 0.56, 0.72, 0.50,
        0.48, 0.66, 0.62, 0.68, 0.40, 0.68, 0.92, 0.82, 0.56, 0.86,
        0.38, 0.90, 0.34, 0.74, 0.28, 0.82,
    ],
    "muhafiz": [
        0.60, 0.52, 0.48, 0.46,
        0.42, 0.54, 0.62, 0.82, 0.28, 0.92, 0.80, 0.86, 0.46, 0.56,
        0.52, 0.38, 0.18, 0.92, 0.24, 0.46,
    ],
    "sifaci": [
        0.44, 0.46, 0.56, 0.42,
        0.90, 0.76, 0.70, 0.76, 0.78, 0.48, 0.30, 0.28, 0.94, 0.74,
        0.80, 0.46, 0.30, 0.74, 0.84, 0.44,
    ],
    "yargic": [
        0.78, 0.68, 0.70, 0.48,
        0.42, 0.86, 0.74, 0.88, 0.24, 0.82, 0.68, 0.80, 0.50, 0.74,
        0.70, 0.34, 0.20, 0.80, 0.26, 0.38,
    ],
    "empat": [
        0.40, 0.46, 0.58, 0.42,
        0.94, 0.82, 0.72, 0.36, 0.90, 0.32, 0.28, 0.30, 0.66, 0.82,
        0.76, 0.52, 0.46, 0.46, 0.88, 0.50,
    ],
    "cesur": [
        0.52, 0.54, 0.50, 0.64,
        0.42, 0.48, 0.52, 0.34, 0.56, 0.38, 0.88, 0.82, 0.44, 0.58,
        0.46, 0.78, 0.90, 0.26, 0.54, 0.74,
    ],
    "kararli": [
        0.70, 0.58, 0.50, 0.48,
        0.44, 0.52, 0.64, 0.84, 0.34, 0.72, 0.82, 0.64, 0.50, 0.54,
        0.50, 0.46, 0.16, 0.94, 0.34, 0.60,
    ],
    "vizyoner": [
        0.58, 0.88, 0.82, 0.60,
        0.50, 0.84, 0.74, 0.44, 0.62, 0.38, 0.66, 0.52, 0.54, 0.68,
        0.84, 0.62, 0.80, 0.24, 0.48, 0.56,
    ],
    "yaratici": [
        0.46, 0.84, 0.54, 0.82,
        0.52, 0.58, 0.68, 0.38, 0.82, 0.30, 0.48, 0.42, 0.50, 0.56,
        0.72, 0.54, 0.92, 0.22, 0.78, 0.50,
    ],
    "iletisimci": [
        0.48, 0.50, 0.88, 0.44,
        0.68, 0.70, 0.58, 0.52, 0.78, 0.42, 0.74, 0.52, 0.60, 0.86,
        0.34, 0.92, 0.68, 0.40, 0.76, 0.92,
    ],
    "analist": [
        0.92, 0.90, 0.66, 0.58,
        0.34, 0.76, 0.70, 0.82, 0.24, 0.64, 0.44, 0.48, 0.40, 0.52,
        0.62, 0.28, 0.20, 0.68, 0.26, 0.34,
    ],
    "donusturucu": [
        0.56, 0.66, 0.64, 0.52,
        0.56, 0.66, 0.60, 0.46, 0.68, 0.40, 0.86, 0.90, 0.76, 0.82,
        0.70, 0.76, 0.88, 0.18, 0.68, 0.74,
    ],
    "bagimsiz": [
        0.64, 0.56, 0.54, 0.50,
        0.36, 0.56, 0.84, 0.74, 0.30, 0.92, 0.78, 0.62, 0.32, 0.42,
        0.60, 0.16, 0.42, 0.70, 0.24, 0.38,
    ],
    "sezgisel": [
        0.38, 0.76, 0.62, 0.48,
        0.82, 0.78, 0.76, 0.44, 0.82, 0.42, 0.32, 0.36, 0.56, 0.92,
        0.74, 0.40, 0.54, 0.42, 0.80, 0.36,
    ],
    "stratejist": [
        0.90, 0.86, 0.70, 0.54,
        0.40, 0.82, 0.74, 0.80, 0.28, 0.74, 0.76, 0.70, 0.46, 0.66,
        0.72, 0.36, 0.14, 0.84, 0.28, 0.60,
    ],
}

# dimension weights (non-negative); primary dims get higher values
WEIGHTS: dict[str, list[float]] = {
    "uygulayici": [
        1.15, 0.80, 0.70, 0.75,
        0.65, 0.70, 0.90, 1.30, 0.60, 1.10, 1.35, 0.85, 0.80, 0.75,
        0.70, 0.85, 0.95, 1.55, 0.65, 1.10,
    ],
    "koruyucu": [
        0.70, 0.65, 0.85, 0.60,
        1.50, 1.05, 0.95, 1.05, 1.15, 1.35, 0.80, 0.75, 1.40, 1.05,
        1.20, 0.80, 0.85, 1.40, 1.15, 0.80,
    ],
    "bilge": [
        0.95, 0.90, 1.35, 0.70,
        0.90, 1.45, 1.50, 1.15, 0.85, 0.85, 0.65, 0.70, 0.95, 0.95,
        1.40, 0.85, 0.80, 1.00, 0.85, 0.90,
    ],
    "lider": [
        0.95, 0.85, 1.15, 0.70,
        0.85, 1.05, 0.95, 1.00, 0.75, 0.90, 1.55, 1.25, 0.90, 1.40,
        0.85, 1.35, 0.85, 0.95, 0.70, 1.15,
    ],
    "muhafiz": [
        0.85, 0.75, 0.75, 0.70,
        0.70, 0.80, 0.90, 1.25, 0.55, 1.55, 1.30, 1.45, 0.75, 0.85,
        0.85, 0.75, 0.95, 1.55, 0.70, 0.80,
    ],
    "sifaci": [
        0.65, 0.70, 0.85, 0.60,
        1.50, 1.15, 1.00, 1.20, 1.20, 0.85, 0.60, 0.55, 1.60, 1.10,
        1.25, 0.80, 0.75, 1.10, 1.30, 0.75,
    ],
    "yargic": [
        1.25, 1.05, 1.10, 0.70,
        0.75, 1.40, 1.10, 1.40, 0.55, 1.25, 1.00, 1.30, 0.85, 1.15,
        0.90, 0.75, 0.80, 1.15, 0.60, 0.75,
    ],
    "empat": [
        0.60, 0.70, 0.90, 0.60,
        1.60, 1.25, 1.05, 0.75, 1.45, 0.70, 0.55, 0.55, 1.05, 1.25,
        1.15, 0.85, 0.80, 0.80, 1.40, 0.80,
    ],
    "cesur": [
        0.80, 0.85, 0.75, 1.00,
        0.70, 0.75, 0.80, 0.70, 0.90, 0.70, 1.45, 1.35, 0.70, 0.90,
        0.75, 1.20, 1.55, 0.85, 0.85, 1.10,
    ],
    "kararli": [
        1.05, 0.85, 0.75, 0.70,
        0.70, 0.80, 0.95, 1.35, 0.65, 1.15, 1.30, 0.95, 0.80, 0.85,
        0.80, 0.80, 1.00, 1.60, 0.65, 0.95,
    ],
    "vizyoner": [
        0.95, 1.45, 1.30, 0.85,
        0.80, 1.30, 1.10, 0.80, 0.90, 0.70, 1.00, 0.85, 0.85, 1.00,
        1.15, 0.95, 1.15, 0.80, 0.85, 0.90,
    ],
    "yaratici": [
        0.80, 1.35, 0.90, 1.30,
        0.85, 0.95, 0.95, 0.75, 1.20, 0.65, 0.85, 0.80, 0.85, 0.90,
        0.95, 0.90, 1.45, 0.75, 1.15, 0.85,
    ],
    "iletisimci": [
        0.75, 0.75, 1.50, 0.65,
        1.00, 1.05, 0.90, 0.85, 1.20, 0.70, 1.15, 0.80, 0.95, 1.40,
        0.70, 1.50, 1.05, 0.75, 1.15, 1.55,
    ],
    "analist": [
        1.55, 1.50, 1.05, 0.85,
        0.60, 1.20, 1.05, 1.30, 0.50, 0.95, 0.70, 0.80, 0.70, 0.80,
        0.90, 0.75, 0.80, 1.00, 0.55, 0.70,
    ],
    "donusturucu": [
        0.85, 0.95, 0.95, 0.80,
        0.95, 1.00, 0.95, 0.85, 1.00, 0.75, 1.40, 1.50, 1.20, 1.25,
        0.90, 1.10, 1.25, 0.80, 0.95, 1.05,
    ],
    "bagimsiz": [
        0.95, 0.85, 0.85, 0.75,
        0.65, 0.90, 1.30, 1.10, 0.65, 1.55, 1.25, 0.95, 0.65, 0.70,
        0.85, 1.00, 0.85, 1.00, 0.70, 0.75,
    ],
    "sezgisel": [
        0.65, 1.20, 0.95, 0.75,
        1.25, 1.20, 1.15, 0.80, 1.25, 0.75, 0.60, 0.65, 0.90, 1.55,
        1.10, 0.80, 0.85, 0.80, 1.20, 0.75,
    ],
    "stratejist": [
        1.45, 1.40, 1.05, 0.80,
        0.70, 1.25, 1.10, 1.20, 0.60, 1.05, 1.15, 1.05, 0.80, 0.95,
        0.90, 0.80, 0.95, 1.15, 0.65, 0.85,
    ],
}

PRIMARY = {
    "uygulayici": ["stability", "assertiveness", "emotion_regulation"],
    "koruyucu": ["empathy", "boundary_setting", "repair_orientation", "stability"],
    "bilge": ["self_awareness", "perspective_taking", "depth_preference", "verbal_reasoning"],
    "lider": ["assertiveness", "social_awareness", "social_energy", "conflict_approach"],
    "muhafiz": ["boundary_setting", "stability", "conflict_approach", "assertiveness"],
    "sifaci": ["repair_orientation", "empathy", "disclosure_pace", "emotion_regulation"],
    "yargic": ["perspective_taking", "emotion_regulation", "conflict_approach", "logical_reasoning"],
    "empat": ["empathy", "emotional_openness", "disclosure_pace", "social_awareness"],
    "cesur": ["spontaneity", "assertiveness", "conflict_approach", "social_energy"],
    "kararli": ["stability", "emotion_regulation", "assertiveness"],
    "vizyoner": ["pattern_reasoning", "verbal_reasoning", "perspective_taking", "spontaneity"],
    "yaratici": ["spontaneity", "pattern_reasoning", "spatial_reasoning", "emotional_openness"],
    "iletisimci": ["communication_pace", "social_energy", "verbal_reasoning", "social_awareness"],
    "analist": ["logical_reasoning", "pattern_reasoning", "emotion_regulation"],
    "donusturucu": ["conflict_approach", "assertiveness", "spontaneity", "social_awareness"],
    "bagimsiz": ["boundary_setting", "self_awareness", "assertiveness", "social_energy"],
    "sezgisel": ["social_awareness", "empathy", "emotional_openness", "pattern_reasoning"],
    "stratejist": ["logical_reasoning", "pattern_reasoning", "perspective_taking", "stability"],
}

SUPPORTING = {
    "uygulayici": ["boundary_setting", "communication_pace", "logical_reasoning"],
    "koruyucu": ["disclosure_pace", "depth_preference", "perspective_taking"],
    "bilge": ["emotion_regulation", "verbal_reasoning", "social_awareness"],
    "lider": ["verbal_reasoning", "communication_pace", "perspective_taking"],
    "muhafiz": ["emotion_regulation", "logical_reasoning"],
    "sifaci": ["depth_preference", "emotional_openness", "perspective_taking"],
    "yargic": ["boundary_setting", "social_awareness", "stability"],
    "empat": ["depth_preference", "perspective_taking", "repair_orientation"],
    "cesur": ["spatial_reasoning", "communication_pace", "emotional_openness"],
    "kararli": ["logical_reasoning", "boundary_setting", "communication_pace"],
    "vizyoner": ["depth_preference", "social_awareness", "assertiveness"],
    "yaratici": ["disclosure_pace", "depth_preference", "social_awareness"],
    "iletisimci": ["emotional_openness", "assertiveness", "disclosure_pace"],
    "analist": ["perspective_taking", "self_awareness", "stability"],
    "donusturucu": ["repair_orientation", "social_energy", "emotional_openness"],
    "bagimsiz": ["emotion_regulation", "stability", "logical_reasoning"],
    "sezgisel": ["perspective_taking", "disclosure_pace", "depth_preference"],
    "stratejist": ["assertiveness", "emotion_regulation", "boundary_setting"],
}

NEUTRAL = {
    pid: [d for d in DIMS if d not in PRIMARY[pid] and d not in SUPPORTING[pid]][:6]
    for pid in LABELS
}

COMPETITORS = {
    "uygulayici": ["kararli", "stratejist", "muhafiz"],
    "koruyucu": ["muhafiz", "sifaci", "empat"],
    "bilge": ["analist", "sezgisel", "yargic"],
    "lider": ["vizyoner", "uygulayici", "donusturucu"],
    "muhafiz": ["koruyucu", "kararli", "yargic"],
    "sifaci": ["empat", "koruyucu", "iletisimci"],
    "yargic": ["analist", "muhafiz", "bilge"],
    "empat": ["sifaci", "iletisimci", "sezgisel"],
    "cesur": ["kararli", "donusturucu", "lider"],
    "kararli": ["cesur", "uygulayici", "muhafiz"],
    "vizyoner": ["lider", "yaratici", "stratejist"],
    "yaratici": ["donusturucu", "sezgisel", "vizyoner"],
    "iletisimci": ["empat", "lider", "donusturucu"],
    "analist": ["bilge", "yargic", "stratejist"],
    "donusturucu": ["yaratici", "lider", "cesur"],
    "bagimsiz": ["sezgisel", "muhafiz", "kararli"],
    "sezgisel": ["bagimsiz", "yaratici", "empat"],
    "stratejist": ["analist", "uygulayici", "vizyoner"],
}

SEPARATORS = {
    "uygulayici": {
        "kararli": ["spontaneity", "communication_pace", "logical_reasoning"],
        "stratejist": ["pattern_reasoning", "perspective_taking", "spontaneity"],
        "muhafiz": ["empathy", "conflict_approach", "disclosure_pace"],
    },
    "koruyucu": {
        "muhafiz": ["empathy", "repair_orientation", "disclosure_pace", "conflict_approach"],
        "sifaci": ["boundary_setting", "assertiveness", "conflict_approach"],
        "empat": ["boundary_setting", "emotion_regulation", "stability"],
    },
    "bilge": {
        "analist": ["depth_preference", "emotional_openness", "self_awareness", "logical_reasoning"],
        "sezgisel": ["verbal_reasoning", "social_energy", "emotion_regulation"],
        "yargic": ["conflict_approach", "boundary_setting", "emotional_openness"],
    },
    "lider": {
        "vizyoner": ["assertiveness", "social_energy", "pattern_reasoning", "spontaneity"],
        "uygulayici": ["social_awareness", "social_energy", "stability"],
        "donusturucu": ["stability", "repair_orientation", "conflict_approach"],
    },
    "muhafiz": {
        "koruyucu": ["empathy", "repair_orientation", "disclosure_pace", "conflict_approach"],
        "kararli": ["conflict_approach", "boundary_setting", "spontaneity"],
        "yargic": ["perspective_taking", "empathy", "disclosure_pace"],
    },
    "sifaci": {
        "empat": ["repair_orientation", "emotion_regulation", "boundary_setting", "stability"],
        "koruyucu": ["assertiveness", "boundary_setting", "conflict_approach"],
        "iletisimci": ["depth_preference", "social_energy", "communication_pace"],
    },
    "yargic": {
        "analist": ["conflict_approach", "social_awareness", "boundary_setting"],
        "muhafiz": ["perspective_taking", "empathy", "logical_reasoning"],
        "bilge": ["conflict_approach", "depth_preference", "emotional_openness"],
    },
    "empat": {
        "sifaci": ["repair_orientation", "emotion_regulation", "boundary_setting", "emotional_openness"],
        "iletisimci": ["empathy", "depth_preference", "social_energy", "communication_pace"],
        "sezgisel": ["disclosure_pace", "assertiveness", "pattern_reasoning"],
    },
    "cesur": {
        "kararli": ["spontaneity", "stability", "emotion_regulation"],
        "donusturucu": ["repair_orientation", "social_awareness", "stability"],
        "lider": ["social_awareness", "stability", "spontaneity"],
    },
    "kararli": {
        "cesur": ["spontaneity", "stability", "emotion_regulation"],
        "uygulayici": ["communication_pace", "logical_reasoning", "spontaneity"],
        "muhafiz": ["conflict_approach", "disclosure_pace", "empathy"],
    },
    "vizyoner": {
        "lider": ["assertiveness", "social_energy", "pattern_reasoning", "spontaneity"],
        "yaratici": ["spatial_reasoning", "emotional_openness", "perspective_taking"],
        "stratejist": ["spontaneity", "stability", "assertiveness"],
    },
    "yaratici": {
        "donusturucu": ["spatial_reasoning", "conflict_approach", "assertiveness", "spontaneity"],
        "sezgisel": ["spatial_reasoning", "social_awareness", "assertiveness"],
        "vizyoner": ["spatial_reasoning", "verbal_reasoning", "stability"],
    },
    "iletisimci": {
        "empat": ["empathy", "depth_preference", "social_energy", "communication_pace"],
        "lider": ["depth_preference", "stability", "conflict_approach"],
        "donusturucu": ["stability", "conflict_approach", "depth_preference"],
    },
    "analist": {
        "bilge": ["depth_preference", "emotional_openness", "logical_reasoning", "self_awareness"],
        "yargic": ["conflict_approach", "social_awareness", "pattern_reasoning"],
        "stratejist": ["assertiveness", "stability", "spontaneity"],
    },
    "donusturucu": {
        "yaratici": ["conflict_approach", "assertiveness", "spatial_reasoning", "repair_orientation"],
        "lider": ["stability", "spontaneity", "repair_orientation"],
        "cesur": ["repair_orientation", "social_awareness", "stability"],
    },
    "bagimsiz": {
        "sezgisel": ["boundary_setting", "empathy", "social_awareness", "assertiveness"],
        "muhafiz": ["empathy", "conflict_approach", "social_energy"],
        "kararli": ["social_energy", "repair_orientation", "spontaneity"],
    },
    "sezgisel": {
        "bagimsiz": ["boundary_setting", "empathy", "social_awareness", "assertiveness"],
        "yaratici": ["spatial_reasoning", "social_awareness", "spontaneity"],
        "empat": ["pattern_reasoning", "assertiveness", "emotion_regulation"],
    },
    "stratejist": {
        "analist": ["assertiveness", "stability", "social_awareness"],
        "uygulayici": ["pattern_reasoning", "perspective_taking", "communication_pace"],
        "vizyoner": ["spontaneity", "stability", "emotional_openness"],
    },
}

TIE_RANK = {pid: i + 1 for i, pid in enumerate(LABELS)}


def vec_map(values: list[float]) -> dict[str, float]:
    return {d: round(float(v), 4) for d, v in zip(DIMS, values)}


def anti_traits(pid: str, target: list[float]) -> list[dict]:
    """Provisional anti-traits from strong valleys / inverted peaks."""
    out: list[dict] = []
    t = {d: target[i] for i, d in enumerate(DIMS)}
    # For each primary high peak, treat very low as anti; for primary low valley, treat very high as anti
    for d in PRIMARY[pid]:
        i = DIMS.index(d)
        if t[d] >= 0.70:
            out.append(
                {
                    "dimension_id": d,
                    "direction": "below",
                    "threshold": round(max(0.15, t[d] - 0.45), 2),
                    "severity": 0.35,
                    "rationale": f"PROVISIONAL: strongly conflicts with {pid} peak on {d}.",
                    "minimum_evidence_required": 2,
                }
            )
        elif t[d] <= 0.40:
            out.append(
                {
                    "dimension_id": d,
                    "direction": "above",
                    "threshold": round(min(0.85, t[d] + 0.40), 2),
                    "severity": 0.30,
                    "rationale": f"PROVISIONAL: strongly conflicts with {pid} valley on {d}.",
                    "minimum_evidence_required": 2,
                }
            )
    # Cap to 4
    return out[:4]


def min_evidence(pid: str) -> dict:
    crit = PRIMARY[pid][:3]
    return {
        "required_groups": ["eq", "frequency"],
        "minimum_group_coverage": {"iq": 0.0, "eq": 0.40, "frequency": 0.50},
        "critical_dimensions": crit,
        "minimum_evidence_per_critical_dimension": 2,
        "minimum_total_coverage": 0.45,
        "notes": "PROVISIONAL: insufficient evidence must block persona assignment.",
    }


def build_persona(pid: str) -> dict:
    tr, en = LABELS[pid]
    target = TARGETS[pid]
    weights = WEIGHTS[pid]
    assert len(target) == 20 and len(weights) == 20
    assert all(0 <= v <= 1 for v in target)
    assert all(w >= 0 for w in weights)
    return {
        "persona_id": pid,
        "labels": {"tr": tr, "en": en},
        "target_vector": vec_map(target),
        "dimension_weights": vec_map(weights),
        "primary_dimensions": PRIMARY[pid],
        "supporting_dimensions": SUPPORTING[pid],
        "neutral_dimensions": NEUTRAL[pid],
        "anti_traits": anti_traits(pid, target),
        "minimum_evidence": min_evidence(pid),
        "closest_competitors": COMPETITORS[pid],
        "separator_targets": {
            other: {"dimensions": dims, "notes": "PROVISIONAL separator set"}
            for other, dims in SEPARATORS[pid].items()
        },
        "tie_break_rank": TIE_RANK[pid],
        "rationale": {
            "tr": f"PROVİZYONEL: {tr} profili ayırt edici tepeler/vadiler ile tanımlanır; ahlaki sıralama değildir.",
            "en": f"PROVISIONAL: {en} is defined by distinctive peaks/valleys; not a moral ranking.",
        },
        "status": "provisional",
    }


def main() -> None:
    for pid, vec in TARGETS.items():
        assert len(vec) == 20, pid
    # uniqueness
    serialized = [tuple(TARGETS[p]) for p in LABELS]
    assert len(set(serialized)) == 18, "duplicate targets"

    profiles = {
        "schema_version": "persona_profiles_v2_20d",
        "persona_profile_version": "persona_profiles_v2_20d.0",
        "dimension_registry_version": "canonical_dimension_registry_v1",
        "status": "provisional",
        "created_at": "2026-07-24",
        "group_weights": {"iq": 0.15, "eq": 0.30, "frequency": 0.55},
        "dimension_order": DIMS,
        "scoring_notes": {
            "provisional": True,
            "similarity_is_not_probability": True,
            "confidence_is_separate_from_similarity": True,
            "no_persona_quota": True,
            "no_forced_distribution": True,
            "missing_evidence_never_filled_with_neutral": True,
            "group_weights_apply_after_within_group_normalization": True,
            "calibration_status": "synthetic_validation_only",
        },
        "calibration_status": "synthetic_validation_only",
        "personas": [build_persona(pid) for pid in LABELS],
    }

    config = {
        "config_version": "persona_scoring_config_v2.0",
        "status": "provisional",
        "persona_profile_version": "persona_profiles_v2_20d.0",
        "dimension_registry_version": "canonical_dimension_registry_v1",
        "group_weights": {"iq": 0.15, "eq": 0.30, "frequency": 0.55},
        "level_distance_weight": 0.65,
        "shape_distance_weight": 0.35,
        "anti_trait_penalty_weight": 0.12,
        "missing_evidence_penalty_weight": 0.18,
        # Lower T stretches similarity margins (PROVISIONAL). Similarity ≠ probability.
        "similarity_temperature": 0.22,
        "top2_margin_threshold": 0.035,
        "low_confidence_threshold": 0.50,
        "minimum_group_coverage": {"iq": 0.0, "eq": 0.40, "frequency": 0.50},
        "minimum_total_coverage": 0.45,
        "adaptive_separator_enabled": True,
        "adaptive_separator_max_questions": 3,
        "deterministic_tie_break_policy": "lowest_tie_break_rank_then_lexicographic_persona_id",
        "numerical_epsilon": 1e-12,
        "calibration_notes": {
            "provisional": True,
            "similarity_scores_are_not_probabilities": True,
            "confidence_is_separate_from_similarity": True,
            "no_persona_quota": True,
            "no_forced_distribution": True,
            "production_calibration_required": True,
            "all_thresholds_are_hypotheses": True,
        },
    }

    out_profiles = ROOT / "assets/data/persona_profiles_v2_20d.json"
    out_config = ROOT / "assets/data/persona_scoring_config_v2.json"
    out_profiles.write_text(json.dumps(profiles, ensure_ascii=False, indent=2) + "\n")
    out_config.write_text(json.dumps(config, ensure_ascii=False, indent=2) + "\n")
    print(f"Wrote {out_profiles}")
    print(f"Wrote {out_config}")


if __name__ == "__main__":
    main()
