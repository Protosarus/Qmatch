#!/usr/bin/env python3
"""Trusted Discover cutover policy (`trusted_discover_cutover_v1`).

Python twin of `functions/src/discover_eligibility.js` deriveDiscoverEligible.
Pure: no Firebase I/O. Used by the read-only cutover dry-run.

Parity with JS is enforced by fixtures + mocha spawn.
"""

from __future__ import annotations

import json
import sys
from typing import Any

POLICY = "trusted_discover_cutover_v1"
PRESERVED_FLOW = "pre_c2_preserved"
MIGRATION_GRANT_REASON = "pre_trust_migration_preserved"
TRUSTED_MODULE_STATUSES = frozenset({"verified", "grandfathered"})

REPORT_COUNT_KEYS = (
    "total_users_scanned",
    "stored_true_derived_true",
    "stored_false_derived_false",
    "stored_true_derived_false",
    "stored_false_derived_true",
    "trusted_v1_eligible",
    "grandfather_eligible",
    "derived_eligible_total",
    "mismatches_total",
)


def is_plain_object(value: Any) -> bool:
    return isinstance(value, dict)


def has_valid_photo(data: dict[str, Any] | None) -> bool:
    if not is_plain_object(data):
        return False
    url = data.get("profile_photo_url")
    if isinstance(url, str) and url.strip():
        return True
    photos = data.get("photos")
    if isinstance(photos, list):
        for p in photos:
            if isinstance(p, str) and p.strip():
                return True
    return False


def module_is_trusted(mod: Any) -> bool:
    return is_plain_object(mod) and mod.get("status") in TRUSTED_MODULE_STATUSES


def has_trusted_v1_battery(verification: Any) -> bool:
    if not is_plain_object(verification):
        return False
    return (
        module_is_trusted(verification.get("iq"))
        and module_is_trusted(verification.get("eq"))
        and module_is_trusted(verification.get("frequency"))
    )


def has_pre_trust_migration_grant(verification: Any) -> bool:
    return (
        is_plain_object(verification)
        and verification.get("flow") == PRESERVED_FLOW
        and verification.get("grant_reason") == MIGRATION_GRANT_REASON
    )


def has_trusted_assessment_discover_grant(data: Any) -> bool:
    if not is_plain_object(data):
        return False
    verification = data.get("assessment_verification_v1")
    if has_trusted_v1_battery(verification):
        return True
    if has_pre_trust_migration_grant(verification):
        return True
    return False


def derive_trusted_discover_eligible(data: Any) -> bool:
    """Must match functions/src/discover_eligibility.js deriveDiscoverEligible."""
    if not is_plain_object(data):
        return False
    if data.get("account_deletion_requested") is True:
        return False
    if data.get("active") is not True:
        return False
    if data.get("profile_completed") is not True:
        return False
    if not has_valid_photo(data):
        return False
    if not has_trusted_assessment_discover_grant(data):
        return False
    return True


def empty_counts() -> dict[str, int]:
    return {key: 0 for key in REPORT_COUNT_KEYS}


def public_counts(counts: dict[str, int]) -> dict[str, int]:
    return {key: counts[key] for key in REPORT_COUNT_KEYS}


def classify_cutover(user_data: Any) -> dict[str, Any]:
    data = user_data if is_plain_object(user_data) else {}
    stored = data.get("discover_eligible") is True
    derived = derive_trusted_discover_eligible(data)
    verification = data.get("assessment_verification_v1")
    trusted_v1 = derived and has_trusted_v1_battery(verification)
    grandfather = derived and has_pre_trust_migration_grant(verification)
    if stored and derived:
        bucket = "stored_true_derived_true"
    elif (not stored) and (not derived):
        bucket = "stored_false_derived_false"
    elif stored and (not derived):
        bucket = "stored_true_derived_false"
    else:
        bucket = "stored_false_derived_true"
    return {
        "stored": stored,
        "derived": derived,
        "trusted_v1": trusted_v1,
        "grandfather": grandfather,
        "bucket": bucket,
        "mismatch": stored != derived,
    }


def increment_cutover_counts(counts: dict[str, int], classified: dict[str, Any]) -> None:
    counts["total_users_scanned"] += 1
    counts[classified["bucket"]] += 1
    if classified["trusted_v1"]:
        counts["trusted_v1_eligible"] += 1
    if classified["grandfather"]:
        counts["grandfather_eligible"] += 1
    if classified["derived"]:
        counts["derived_eligible_total"] += 1
    if classified["mismatch"]:
        counts["mismatches_total"] += 1


def dump_parity_results(payload: Any) -> dict[str, Any]:
    cases = payload.get("cases") if is_plain_object(payload) else None
    if not isinstance(cases, list):
        raise ValueError("parity payload must contain a cases array")
    out = []
    for row in cases:
        if not is_plain_object(row):
            raise ValueError("parity case must be an object")
        derived = derive_trusted_discover_eligible(row.get("user"))
        classified = classify_cutover(row.get("user"))
        out.append(
            {
                "id": row.get("id"),
                "derived": derived,
                "trusted_v1": classified["trusted_v1"],
                "grandfather": classified["grandfather"],
            }
        )
    return {"cases": out}


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    if args == ["--parity-stdin"]:
        payload = json.load(sys.stdin)
        json.dump(dump_parity_results(payload), sys.stdout, sort_keys=True)
        sys.stdout.write("\n")
        return 0
    print(
        f"{POLICY} — pure policy helper\n"
        "No Firebase I/O. Used by the trusted Discover cutover dry-run.\n"
        "Parity: python3 tool/trusted_discover_cutover_policy_v1.py --parity-stdin\n",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
