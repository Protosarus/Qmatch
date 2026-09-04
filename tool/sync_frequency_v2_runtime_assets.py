#!/usr/bin/env python3
"""Copy reviewed Frequency V2 banks into Flutter runtime assets.

Source of truth remains tool/frequency_behavior_v2/out/. Runtime copies live
under assets/assessment/frequency_v2/. This tool never rewrites question text.

Usage:
  python3 tool/sync_frequency_v2_runtime_assets.py --check
  python3 tool/sync_frequency_v2_runtime_assets.py --sync
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tool" / "frequency_behavior_v2" / "out"
DEST_DIR = ROOT / "assets" / "assessment" / "frequency_v2"

RUNTIME_FILES = (
    "frequency_behavior_pool_tr_v2_draft1.json",
    "frequency_behavior_pool_tr_v2_draft1_review_metadata.json",
    "frequency_behavior_pool_en_v2_draft1.json",
    "frequency_behavior_pool_en_v2_draft1_review_metadata.json",
)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_json_sha256(data: bytes) -> str:
    parsed = json.loads(data.decode("utf-8"))
    canonical = json.dumps(parsed, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return sha256_bytes(canonical.encode("utf-8"))


def sync() -> int:
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    for name in RUNTIME_FILES:
        src = SOURCE_DIR / name
        if not src.is_file():
            print(f"missing source: {src}", file=sys.stderr)
            return 1
        shutil.copyfile(src, DEST_DIR / name)
        print(f"copied {name}")
    return 0


def check() -> int:
    failed = False
    for name in RUNTIME_FILES:
        src = SOURCE_DIR / name
        dest = DEST_DIR / name
        if not src.is_file():
            print(f"FAIL missing source {src}")
            failed = True
            continue
        if not dest.is_file():
            print(f"FAIL missing runtime asset {dest}")
            failed = True
            continue
        src_bytes = src.read_bytes()
        dest_bytes = dest.read_bytes()
        if src_bytes != dest_bytes:
            print(f"FAIL byte mismatch {name}")
            failed = True
            continue
        src_hash = sha256_bytes(src_bytes)
        dest_hash = sha256_bytes(dest_bytes)
        src_canon = canonical_json_sha256(src_bytes)
        dest_canon = canonical_json_sha256(dest_bytes)
        if src_hash != dest_hash or src_canon != dest_canon:
            print(f"FAIL hash mismatch {name}")
            failed = True
            continue
        print(f"OK {name} sha256={src_hash} canonical={src_canon}")
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--sync", action="store_true")
    args = parser.parse_args()
    if args.sync:
        return sync()
    return check()


if __name__ == "__main__":
    raise SystemExit(main())
