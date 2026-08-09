# QMatch IQ Session Privacy v1

**Phase:** P2C-2A-3
**Storage:** local SharedPreferences (UID-namespaced), offline draft only.

---

## Allowed in IQ session draft

- Auth UID (storage key / `owner_uid` field only — not rendered publicly)
- Opaque `session_id`
- `bank_version`, `bank_locale`, `selection_policy_version`
- Item IDs, dimension IDs, template family IDs
- Displayed option IDs (permutation)
- Selected option IDs + answer timestamps
- Current index, status, session timestamps / schema version

## Forbidden in IQ session draft

- Email, phone, display name, profile photo
- Precise location or other profile attributes
- Full question prompt / option text (bank remains the source)
- `correct_option_id` or correctness flags
- `displayed_correct_position` (rehydrated from bank at validate time)
- Computed IQ scores / dimension scores
- Core Method / EQ / Frequency payloads

---

## Account isolation

- Keys include UID; load rejects `owner_mismatch` / empty owner.
- Missing UID → `owner_unavailable` (no global fallback key).
- Logout does not currently wipe drafts; drafts remain UID-scoped on device.

## User-facing errors

Typed failure codes only. Do not surface raw JSON, UID, or storage keys in UI copy
(runtime UI wiring is a later phase).
