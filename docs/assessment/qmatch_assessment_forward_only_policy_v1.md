# QMatch Assessment Forward-Only Policy v1

## Scope

Active question screens:

- `IQTestScreen`
- `EQTestScreen`
- `FrequencyTestScreen`

## Policy

Once a response is submitted via Continue and the cursor advances:

1. Previous items are **not** revisitable in the UI.
2. Previous responses are **immutable** in the session domain layer.
3. The assessment cursor is **forward-only** (`moveToIndex` rejects `index < currentQuestionIndex`).
4. Route pop (system back, gesture back, chrome back) is blocked while the session is `in_progress` or `completed_pending_persistence`.

## Allowed

- Changing the **current** question’s local selection before Continue.
- Backgrounding / killing the app and resuming from persisted state.
- Pending-finalization retry (HOTFIX lifecycle) without editing answers.

## Domain codes

- `answer_already_committed` — overwrite of a committed item response rejected
- `cursor_not_forward` — backward cursor movement rejected
- `session_not_editable` — answers rejected after complete/pending/finalized

## Non-goals

Does not change scoring mathematics, banks, adapters, Persona, or Matching.
