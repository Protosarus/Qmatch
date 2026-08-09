# QMatch IQ Session Persistence Contract v1

**Phase:** P2C-2A-2 (document only)
**Status:** NOT_STARTED (implementation deferred to P2C-2A-3)

---

## Purpose

Define the minimum durable fields required to **resume an identical IQ session**
after process death, without re-rolling selection.

The composer itself does **not** persist anything in P2C-2A-2.

---

## Required persistence fields

| Field | Why |
|-------|-----|
| `session_id` | Stable identity for resume / audit |
| `bank_version` | Bind to exact bank revision (`tr_v2_340`) |
| `selection_policy_version` | Bind to `iq_session_selection_v1` algorithm |
| `session_seed` | Reproduce option order / interleave if needed |
| `selected item IDs` **or** full `IqSessionPlan` JSON | Exact 25 items + order + displayed option IDs |
| `displayed option order` (or reproducible seed contract) | Prefer storing plan’s `displayed_option_ids` explicitly |
| `current_question_index` | Resume cursor |
| `answers` | Map of item_id → selected_option_id (never index-only) |
| `completion_state` | in_progress / completed / abandoned |

Recommended: store the full `IqSessionPlan.toJson()` blob plus progress fields.

---

## Non-goals of P2C-2A-3 (called out early)

- Do not re-compose on resume when a plan blob exists
- Do not use list index as answer identity
- Do not mutate the canonical bank file
- Do not auto-activate seen-family relaxation

---

## Storage targets (future)

- Local durable store for offline resume candidate
- Optional Firestore document keyed by `uid` + `session_id`

Neither is implemented in this phase.
