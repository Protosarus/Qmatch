#!/usr/bin/env python3
"""Read-only scan for likely hardcoded Flutter UI strings.

Usage:
  python3 scripts/audit_flutter_localization.py
  python3 scripts/audit_flutter_localization.py --json

Does not modify any files. Heuristic only — review findings manually.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

# Skip pure non-UI / generated / debug internals for production counts
SKIP_DIR_PARTS = {
    "l10n",
    ".dart_tool",
}

# Paths treated as debug-only (P2)
DEBUG_MARKERS = ("/features/debug/", "/assessment_localization_debug.dart")

# Heuristic: Turkish characters / common TR UI words
TR_RE = re.compile(
    r"[çğıöşüÇĞİÖŞÜ]|"
    r"\b(Keşfet|Mesajlar|Profil|Ayarlar|DEVAM|Hakkımda|İptal|Çıkış|"
    r"Bildirim|Gizlilik|Engellen|Yardım|Hakkında|Fotoğraf)\b",
    re.I,
)

# Common English UI words (avoid matching code identifiers alone)
EN_UI_RE = re.compile(
    r"\b(Continue|Cancel|Retry|Error|Loading|Welcome|Sign up|Log in|"
    r"Password|Email|Phone|Submit|Report|Block|Unmatch|Like|Pass|"
    r"No compatible|Settings|Notifications|Privacy|Delete|Next|"
    r"Back|Finish|Start|Verify|Resend)\b",
    re.I,
)

# Capture string literals in common UI constructors / named args
PATTERNS = [
    re.compile(r"""Text\s*\(\s*(['"])(.*?)\1""", re.S),
    re.compile(r"""(?:title|label|hintText|labelText|helperText|semanticLabel|tooltip|message|content)\s*:\s*(['"])(.*?)\1"""),
    re.compile(r"""SnackBar\s*\([^)]*?content:\s*Text\s*\(\s*(['"])(.*?)\1""", re.S),
]


def is_skipped(path: Path) -> bool:
    parts = set(path.parts)
    if "l10n" in parts:
        return True
    name = path.name
    if name.endswith(".g.dart") or name.endswith(".freezed.dart"):
        return True
    return False


def detect_lang(s: str) -> str:
    has_tr = bool(TR_RE.search(s))
    has_en = bool(EN_UI_RE.search(s))
    if has_tr and has_en:
        return "mixed"
    if has_tr:
        return "tr"
    if has_en:
        return "en"
    # brand / short / ambiguous
    if s.lower() in {"qmatch", "qmatch!", "ok", "ios", "android"}:
        return "brand"
    if re.search(r"[A-Za-z]{3,}", s) and not has_tr:
        return "en_likely"
    return "other"


def feature_of(path: Path) -> str:
    rel = path.as_posix()
    for feat in (
        "auth",
        "profile",
        "discover",
        "messages",
        "settings",
        "assessment",
        "debug",
        "main",
        "matching",
        "reveal",
        "safety",
    ):
        if f"/features/{feat}/" in rel:
            return feat
    if "/core/" in rel:
        return "core"
    return "other"


def priority(path: Path, lang: str, feature: str) -> str:
    rel = path.as_posix()
    if any(m in rel for m in DEBUG_MARKERS) or feature == "debug":
        return "P2"
    if feature == "assessment" and "AppLocalizations" in path.read_text(encoding="utf-8", errors="ignore")[:5000]:
        # assessment screens often still have few leftovers; keep non-debug as P1 unless clearly hardcoded UI lang
        if lang in ("tr", "en", "en_likely"):
            return "P1"
    # Hardcoded TR chrome → English-locale risk (P0)
    # Hardcoded EN chrome → Turkish-locale risk (P0) for production user screens
    if feature in {
        "auth",
        "profile",
        "discover",
        "messages",
        "settings",
        "main",
        "core",
    }:
        if lang in ("tr", "en", "en_likely", "mixed"):
            return "P0"
    return "P1"


def scan() -> dict:
    findings: list[dict] = []
    for path in sorted(LIB.rglob("*.dart")):
        if is_skipped(path):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        # Skip import-only / pure model files with no UI widgets lightly
        if not any(k in text for k in ("Text(", "SnackBar", "AppBar", "hintText", "label:", "title:")):
            continue
        feat = feature_of(path)
        seen_in_file: set[str] = set()
        for pat in PATTERNS:
            for m in pat.finditer(text):
                s = m.group(2)
                s = s.replace("\\n", " ").replace("\\'", "'").replace('\\"', '"').strip()
                if len(s) < 2:
                    continue
                if s.startswith("$") or s.startswith("${"):
                    continue
                # skip pure interpolation templates with no letters
                if not re.search(r"[A-Za-zÇçĞğİıÖöŞşÜü]", s):
                    continue
                key = s[:160]
                if key in seen_in_file:
                    continue
                seen_in_file.add(key)
                lang = detect_lang(s)
                if lang == "other" and len(s) < 4:
                    continue
                findings.append(
                    {
                        "file": str(path.relative_to(ROOT)),
                        "feature": feat,
                        "text": key,
                        "language": lang,
                        "priority": priority(path, lang, feat),
                        "production_user_facing": feat != "debug"
                        and "/features/debug/" not in path.as_posix(),
                    }
                )

    by_pri = Counter(f["priority"] for f in findings)
    by_feat = Counter(f["feature"] for f in findings)
    by_lang = Counter(f["language"] for f in findings)
    return {
        "total": len(findings),
        "by_priority": dict(by_pri),
        "by_feature": dict(by_feat),
        "by_language": dict(by_lang),
        "findings": findings,
    }


def print_report(data: dict) -> None:
    print("=" * 72)
    print("Flutter Localization Hardcoded-String Audit (READ ONLY)")
    print("=" * 72)
    print(f"Total findings: {data['total']}")
    print("By priority:", data["by_priority"])
    print("By feature:", data["by_feature"])
    print("By language:", data["by_language"])
    print()
    grouped: dict[str, list] = defaultdict(list)
    for f in data["findings"]:
        if f["priority"] == "P0":
            grouped[f["feature"]].append(f)
    print("Sample P0 by feature (max 8 each):")
    for feat, items in sorted(grouped.items()):
        print(f"\n[{feat}] {len(items)} P0")
        for it in items[:8]:
            print(f"  - {it['file']}: {it['language']}: {it['text'][:90]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    data = scan()
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print_report(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
