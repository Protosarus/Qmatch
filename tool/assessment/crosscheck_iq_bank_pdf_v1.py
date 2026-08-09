#!/usr/bin/env python3
"""Secondary PDF cross-check for iq_bank_tr_v1.json (DOCX remains primary)."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError as exc:  # pragma: no cover
    raise SystemExit("pypdf required in .venv_iq_convert") from exc

SECTION_MARKERS = {
    "logical_reasoning": "Mantıksal Muhakeme",
    "pattern_reasoning": "Örüntü Muhakemesi",
    "verbal_reasoning": "Sözel Muhakeme",
    "spatial_reasoning": "Uzamsal Muhakeme",
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--bank",
        default="assets/data/assessment_v3/iq/iq_bank_tr_v1.json",
    )
    ap.add_argument(
        "--pdf",
        default="docs/source/assessment/iq/QMatch_Bilissel_Muhakeme_Soru_Bankasi_v2_340.pdf",
    )
    ap.add_argument(
        "--report",
        default="assets/data/assessment_v3/iq/reports/iq_bank_tr_v1_pdf_crosscheck.json",
    )
    args = ap.parse_args()

    bank_path = Path(args.bank)
    pdf_path = Path(args.pdf)
    if not bank_path.exists() or not pdf_path.exists():
        print("MISSING bank or pdf", file=sys.stderr)
        return 2

    bank = json.loads(bank_path.read_text(encoding="utf-8"))
    items = bank["items"]
    by_dim: dict[str, list] = defaultdict(list)
    for item in items:
        by_dim[item["dimension"]].append(item)

    reader = PdfReader(str(pdf_path))
    full = "\n".join((p.extract_text() or "") for p in reader.pages)
    lines = re.split(r"\n+", full)

    checks: list[dict] = []
    discrepancies: list[dict] = []

    for dim, marker in SECTION_MARKERS.items():
        ok = marker in full
        checks.append({"check": f"section_marker_{dim}", "ok": ok, "marker": marker})
        if not ok:
            discrepancies.append(
                {"type": "missing_section_marker", "dimension": dim, "marker": marker}
            )

    for dim, lst in by_dim.items():
        for label, it in (("first", lst[0]), ("last", lst[-1])):
            ok_id = it["id"] in full
            ok_fam = it["template_family_id"] in full
            checks.append(
                {
                    "check": f"{dim}_{label}",
                    "item_id": it["id"],
                    "family": it["template_family_id"],
                    "id_in_pdf": ok_id,
                    "family_in_pdf": ok_fam,
                }
            )
            if not ok_id:
                discrepancies.append(
                    {
                        "type": "missing_item_id_in_pdf",
                        "item_id": it["id"],
                        "role": label,
                        "dimension": dim,
                    }
                )
            if not ok_fam:
                discrepancies.append(
                    {
                        "type": "missing_family_in_pdf",
                        "item_id": it["id"],
                        "family": it["template_family_id"],
                        "role": label,
                        "dimension": dim,
                    }
                )

    missing_ids = [i["id"] for i in items if i["id"] not in full]
    checks.append(
        {
            "check": "all_item_ids_in_pdf",
            "missing_count": len(missing_ids),
            "missing_sample": missing_ids[:10],
        }
    )
    if missing_ids:
        discrepancies.append(
            {
                "type": "item_ids_missing_from_pdf",
                "count": len(missing_ids),
                "sample": missing_ids[:20],
            }
        )

    rewritten = [i["id"] for i in items if i["revision_status"] == "rewritten_v2"]
    missing_rw = [rid for rid in rewritten if rid not in full]
    checks.append({"check": "rewritten_ids_in_pdf", "missing_count": len(missing_rw)})
    if missing_rw:
        discrepancies.append(
            {"type": "rewritten_id_missing_from_pdf", "ids": missing_rw}
        )

    for phrase in ("340", "170", "40"):
        checks.append({"check": f"phrase_{phrase}", "present": phrase in full})

    checks.append(
        {
            "check": "cevap_anahtari_present",
            "present": "Cevap Anahtar" in full,
        }
    )

    id_set = {i["id"]: i for i in items}
    in_key = False
    pdf_answers: dict[str, str] = {}
    for line in lines:
        if "Cevap Anahtar" in line:
            in_key = True
            continue
        if not in_key:
            continue
        if "Yeniden Yazılan" in line:
            break
        for iid in id_set:
            if iid not in line:
                continue
            m = re.search(re.escape(iid) + r".*?([ABCD])\s*$", line)
            if not m:
                m = re.search(r"\b([ABCD])\b", line)
            if m:
                pdf_answers[iid] = m.group(1).lower()

    mismatches = []
    for iid, letter in pdf_answers.items():
        expected = id_set[iid]["correct_option_id"]
        if letter != expected:
            mismatches.append({"id": iid, "pdf": letter, "docx_bank": expected})
    checks.append(
        {
            "check": "pdf_answer_extractions",
            "extracted": len(pdf_answers),
            "mismatches": len(mismatches),
            "sample": mismatches[:10],
        }
    )
    if mismatches:
        discrepancies.append(
            {
                "type": "answer_key_mismatch_docx_vs_pdf",
                "count": len(mismatches),
                "sample": mismatches[:20],
            }
        )
    if len(pdf_answers) != 340:
        discrepancies.append(
            {
                "type": "pdf_answer_extraction_incomplete",
                "extracted": len(pdf_answers),
                "expected": 340,
                "note": "Report only; DOCX tables remain authoritative for answers.",
            }
        )

    report = {
        "primary_source": "docx",
        "secondary_source": "pdf",
        "bank_path": bank_path.as_posix(),
        "bank_sha256": sha256_file(bank_path),
        "pdf_path": pdf_path.as_posix(),
        "pdf_sha256": sha256_file(pdf_path),
        "pdf_pages": len(reader.pages),
        "checks": checks,
        "discrepancies": discrepancies,
        "discrepancy_count": len(discrepancies),
        "silent_resolution": False,
    }
    out = Path(args.report)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        json.dumps(
            {
                "ok": len(discrepancies) == 0,
                "discrepancy_count": len(discrepancies),
                "pdf_answers_extracted": len(pdf_answers),
            },
            ensure_ascii=False,
        )
    )
    # Non-zero only for hard integrity failures (id/family/answer mismatches),
    # not for incomplete PDF text extraction alone when DOCX is primary.
    hard = [
        d
        for d in discrepancies
        if d["type"]
        in {
            "missing_section_marker",
            "missing_item_id_in_pdf",
            "missing_family_in_pdf",
            "item_ids_missing_from_pdf",
            "rewritten_id_missing_from_pdf",
            "answer_key_mismatch_docx_vs_pdf",
        }
    ]
    return 1 if hard else 0


if __name__ == "__main__":
    raise SystemExit(main())
