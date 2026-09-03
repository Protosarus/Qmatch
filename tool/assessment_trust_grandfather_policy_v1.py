#!/usr/bin/env python3
"""Pure assessment-trust grandfather policy (`assessment_trust_grandfather_v1`).

Python twin of `functions/src/assessment_trust_grandfather_v1.js`.
No Firebase initialization or writes. Used by the dry-run and execute tools.

Parity with the JS planner is enforced by fixtures + mocha spawn.
"""

from __future__ import annotations

import json
import sys
from typing import Any

POLICY = "assessment_trust_grandfather_v1"
VERIFICATION_SCHEMA = "assessment_verification_v1"
DEFAULT_CATALOG_VERSION = "assessment_finalize_catalog_v1"
PRESERVED_FLOW = "pre_c2_preserved"
MIGRATION_GRANT_REASON = "pre_trust_migration_preserved"
APPLY_CONFIRM = "PRE_TRUST_MIGRATION_V1"
TRUSTED_MODULE_STATUSES = frozenset({"verified", "grandfathered"})

CLASSIFICATIONS = {
    "grandfather_candidate": "grandfather_candidate",
    "already_trusted_complete": "already_trusted_complete",
    "already_pre_c2_preserved": "already_pre_c2_preserved",
    "stored_eligible_but_formula_false": "stored_eligible_but_formula_false",
    "formula_true_but_stored_false": "formula_true_but_stored_false",
    "not_eligible": "not_eligible",
    "malformed_verification": "malformed_verification",
}

COUNT_KEYS = {
    CLASSIFICATIONS["grandfather_candidate"]: "grandfather_candidates",
    CLASSIFICATIONS["already_trusted_complete"]: "already_trusted_complete",
    CLASSIFICATIONS["already_pre_c2_preserved"]: "already_pre_c2_preserved",
    CLASSIFICATIONS["stored_eligible_but_formula_false"]: (
        "stored_eligible_but_formula_false"
    ),
    CLASSIFICATIONS["formula_true_but_stored_false"]: "formula_true_but_stored_false",
    CLASSIFICATIONS["not_eligible"]: "not_eligible",
    CLASSIFICATIONS["malformed_verification"]: "malformed_verification",
}

FROZEN_USER_KEYS = (
    "discover_eligible",
    "test_completed",
    "assessment_flow_completed",
    "assessment_flow_version",
    "iq_completed",
    "eq_completed",
    "frequency_completed",
    "profile_completed",
    "active",
    "account_deletion_requested",
    "photos",
    "profile_photo_url",
)

REPORT_COUNT_KEYS = (
    "total_users_scanned",
    "grandfather_candidates",
    "already_trusted_complete",
    "already_pre_c2_preserved",
    "stored_eligible_but_formula_false",
    "formula_true_but_stored_false",
    "not_eligible",
    "malformed_verification",
    "planned_writes",
)


def is_plain_object(value: Any) -> bool:
    return isinstance(value, dict)


def has_valid_photo(data: dict[str, Any]) -> bool:
    url = data.get("profile_photo_url")
    if isinstance(url, str) and url.strip():
        return True
    photos = data.get("photos")
    if isinstance(photos, list):
        for p in photos:
            if isinstance(p, str) and p.strip():
                return True
    return False


def derive_discover_eligible(data: dict[str, Any] | None) -> bool:
    """Must match functions/src/discover_eligibility.js."""
    if not isinstance(data, dict):
        return False
    if data.get("account_deletion_requested") is True:
        return False
    if data.get("active") is not True:
        return False
    if data.get("profile_completed") is not True:
        return False
    if not (
        data.get("test_completed") is True
        or data.get("assessment_flow_completed") is True
    ):
        return False
    if not has_valid_photo(data):
        return False
    return True


def module_is_trusted(mod: Any) -> bool:
    return is_plain_object(mod) and mod.get("status") in TRUSTED_MODULE_STATUSES


def copy_module(mod: Any) -> dict[str, Any] | None:
    if not is_plain_object(mod):
        return None
    return dict(mod)


def module_slot_malformed(verification: Any) -> bool:
    if not is_plain_object(verification):
        return False
    for key in ("iq", "eq", "frequency"):
        if key in verification and verification[key] is not None:
            if not is_plain_object(verification[key]):
                return True
    return False


def is_genuinely_trusted_complete(verification: Any) -> bool:
    return (
        is_plain_object(verification)
        and module_is_trusted(verification.get("iq"))
        and module_is_trusted(verification.get("eq"))
        and module_is_trusted(verification.get("frequency"))
    )


def existing_catalog_version(verification: Any) -> str:
    if not is_plain_object(verification):
        return DEFAULT_CATALOG_VERSION
    raw = verification.get("catalog_version")
    if isinstance(raw, str) and raw.strip() != "":
        return raw
    return DEFAULT_CATALOG_VERSION


def empty_counts() -> dict[str, int]:
    return {
        "total_users_scanned": 0,
        "grandfather_candidates": 0,
        "already_trusted_complete": 0,
        "already_pre_c2_preserved": 0,
        "stored_eligible_but_formula_false": 0,
        "formula_true_but_stored_false": 0,
        "not_eligible": 0,
        "malformed_verification": 0,
        "planned_writes": 0,
        "writes_performed": 0,
    }


def classify_grandfather_candidate(user_data: Any) -> str:
    data = user_data if is_plain_object(user_data) else {}
    verification = data.get("assessment_verification_v1")
    if verification is not None and not is_plain_object(verification):
        return CLASSIFICATIONS["malformed_verification"]
    if (
        is_plain_object(verification)
        and verification.get("flow") is not None
        and not isinstance(verification.get("flow"), str)
    ):
        return CLASSIFICATIONS["malformed_verification"]
    if module_slot_malformed(verification):
        return CLASSIFICATIONS["malformed_verification"]

    stored_eligible = data.get("discover_eligible") is True
    formula_eligible = derive_discover_eligible(data)

    if stored_eligible and not formula_eligible:
        return CLASSIFICATIONS["stored_eligible_but_formula_false"]
    if (not stored_eligible) and formula_eligible:
        return CLASSIFICATIONS["formula_true_but_stored_false"]
    if (not stored_eligible) and (not formula_eligible):
        return CLASSIFICATIONS["not_eligible"]

    if is_genuinely_trusted_complete(verification):
        return CLASSIFICATIONS["already_trusted_complete"]

    flow = (
        verification.get("flow")
        if is_plain_object(verification) and isinstance(verification.get("flow"), str)
        else ""
    )
    if flow == PRESERVED_FLOW:
        return CLASSIFICATIONS["already_pre_c2_preserved"]
    return CLASSIFICATIONS["grandfather_candidate"]


def plan_grandfather_write(user_data: Any) -> dict[str, Any]:
    classification = classify_grandfather_candidate(user_data)
    if classification != CLASSIFICATIONS["grandfather_candidate"]:
        return {"classification": classification, "write": None}

    existing = (
        user_data.get("assessment_verification_v1")
        if is_plain_object(user_data)
        else None
    )
    next_map: dict[str, Any] = dict(existing) if is_plain_object(existing) else {}
    next_map.pop("frequency_v2", None)
    next_map["schema_version"] = VERIFICATION_SCHEMA
    next_map["flow"] = PRESERVED_FLOW
    next_map["grant_reason"] = MIGRATION_GRANT_REASON
    next_map["catalog_version"] = existing_catalog_version(existing)

    iq = copy_module(existing.get("iq") if is_plain_object(existing) else None)
    eq = copy_module(existing.get("eq") if is_plain_object(existing) else None)
    frequency = copy_module(
        existing.get("frequency") if is_plain_object(existing) else None
    )
    if iq is not None:
        next_map["iq"] = iq
    else:
        next_map.pop("iq", None)
    if eq is not None:
        next_map["eq"] = eq
    else:
        next_map.pop("eq", None)
    if frequency is not None:
        next_map["frequency"] = frequency
    else:
        next_map.pop("frequency", None)

    return {
        "classification": classification,
        "write": {"assessment_verification_v1": next_map},
    }


def increment_count(counts: dict[str, int], classification: str) -> None:
    key = COUNT_KEYS.get(classification)
    if key and key in counts:
        counts[key] += 1


def assert_verification_only_write(write: Any) -> None:
    if not is_plain_object(write):
        raise ValueError("grandfather write must be an object")
    keys = list(write.keys())
    if keys != ["assessment_verification_v1"]:
        raise ValueError("grandfather write must only set assessment_verification_v1")
    for frozen in FROZEN_USER_KEYS:
        if frozen in write:
            raise ValueError(f"grandfather write must not include {frozen}")


def public_counts(counts: dict[str, int]) -> dict[str, int]:
    return {key: counts[key] for key in REPORT_COUNT_KEYS}


def dump_parity_results(payload: Any) -> dict[str, Any]:
    cases = payload.get("cases") if is_plain_object(payload) else None
    if not isinstance(cases, list):
        raise ValueError("parity payload must contain a cases array")
    out = []
    for row in cases:
        if not is_plain_object(row):
            raise ValueError("parity case must be an object")
        planned = plan_grandfather_write(row.get("user"))
        out.append(
            {
                "id": row.get("id"),
                "classification": planned["classification"],
                "write": planned["write"],
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
        "No Firebase I/O. Used by dry-run/execute tools.\n"
        "Parity: python3 tool/assessment_trust_grandfather_policy_v1.py --parity-stdin\n",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
