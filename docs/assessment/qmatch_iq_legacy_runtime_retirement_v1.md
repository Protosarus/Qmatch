# QMatch IQ Legacy Runtime Retirement v1

**Phase:** P2C-2A-5

---

## Status

| Path | Status |
|------|--------|
| Live `IQTestScreen` new sessions | **Canonical 25-session path** |
| `QuestionService.loadIQAssessment` | **Retained** (not called by IQTestScreen) |
| `AssessmentSetService` IQ assignment | **Retained** for legacy data / tooling |
| Legacy 10-item assets | **Retained** on disk |

**Precise status:** `RETIRED_FROM_ACTIVE_NEW_SESSION_PATH`

---

## Cleanup debt (later)

1. Remove dead IQ assignment writes once analytics confirm no legacy resume need.
2. Narrow or delete unused 10-set assets after migration window.
3. Optionally migrate historical `iq_score` mirrors to a documented archival field.
4. Update any external docs still describing “10 questions”.

Do **not** delete legacy code in this phase.
