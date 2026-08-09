# QMatch IQ Session Persistence Contract v1

**Phase:** P2C-2A-3
**Status:** IMPLEMENTED_OFFLINE

---

## Purpose

Durable local resume of a canonical deterministic 25-question IQ session so that
process death / relaunch never re-rolls selection for a valid in-progress draft.

---

## Schema (`qmatch_iq_persisted_session_v1`)

| Field | Type | Notes |
|-------|------|-------|
| `schema_version` | string | `qmatch_iq_persisted_session_v1` |
| `session_id` | string | Opaque `iq_sess_` + 32 hex; generated once |
| `owner_uid` | string | Auth UID namespace (never shown as UI copy) |
| `bank_version` | string | Must match active bank |
| `bank_locale` | string | e.g. `tr` |
| `selection_policy_version` | string | `iq_session_selection_v1` |
| `session_seed` | string | Original compose seed |
| `item_plans` | array | 25 slim plans (see below) |
| `current_question_index` | int | Clamped / validated `0..24` |
| `answers` | array | `IqSessionAnswer` in plan order |
| `started_at` / `updated_at` / `completed_at` | ISO-8601 UTC | |
| `status` | string | `in_progress` \| `completed` \| `abandoned` |

### Item plan (persisted)

| Field | Required |
|-------|----------|
| `item_id` | yes |
| `dimension` | yes |
| `template_family_id` | yes |
| `displayed_option_ids` | yes (exact display permutation) |

**Not persisted:** question prompt text, `correct_option_id`, `displayed_correct_position`
(Position is rehydrated from the bank at validate time.)

### Answer (`IqSessionAnswer`)

| Field | Notes |
|-------|-------|
| `item_id` | Must be in session plan |
| `selected_option_id` | Stable source option ID (never A/B/C/D index) |
| `answered_at` | ISO-8601 UTC |

One answer max per item; replace on re-answer. Unanswered items absent. No correctness flag.

---

## Session ID strategy

- Generated once via `IqSessionIdFactory` when a **new** session is created.
- Format: `iq_sess_` + 16 cryptographically random bytes as hex.
- Persisted immediately with the session; reused on every resume.
- Not derived from timestamp alone; contains no email/phone/name.

---

## Storage mechanism

- **Adapter:** `IqSessionPrefsRepository` → `shared_preferences`
- **Test/CLI:** `IqSessionMemoryRepository`
- **Keys:**
  - `qmatch.iq_session.v1.active.{uid}` → session id pointer
  - `qmatch.iq_session.v1.session.{uid}.{sessionId}` → JSON blob
- Atomic full-state writes (state is small).

---

## Repository API (`IqSessionPersistenceRepository`)

- `saveSession`
- `loadActiveSession(ownerUid)`
- `loadSession(ownerUid, sessionId)`
- `deleteSession` (explicit only)
- `clearOwnerSessions` (explicit only)

Validation: `IqPersistedSessionValidator.validateStoredSession` path via
`IqPersistedSessionValidator.validate`.

---

## Write-through / get-or-create

**New session:** compose → validate → persist → return.
**Answer / index:** validate → mutate → persist → return.
**Resume:** if valid `in_progress` for UID → return stored plan; **do not** compose.
**Incompatible bank/policy/schema or corrupt:** typed failure; **no** silent regenerate; **no** auto-delete.

---

## Completion

`markCompleted` / `IqSessionManager.complete` requires exactly 25 valid answers, sets
`status=completed` + `completedAt`, persists. No IQ score written in this phase.
Completed sessions are not returned as active.

---

## Logout policy (documented)

`AuthService.signOut` does **not** clear SharedPreferences today. Isolation is by
UID key. Account B never loads A’s active pointer. Returning to A resumes A’s draft
unless a later phase explicitly calls `clearOwnerSessions`.

---

## Non-goals (still)

- No live `IQTestScreen` wiring
- No canonical 4D scoring
- No Firestore session collection
- No Firebase imports in `domain/iq_session`
