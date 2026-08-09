# QMatch Frequency Legacy Runtime Retirement v1

**Phase:** P2C-2A-8R2

```text
legacy Frequency new-session path = RETIRED_FROM_ACTIVE_NEW_SESSION_PATH
```

Active new sessions use `FrequencyCanonicalRuntimeService` + TR/EN banks.

Historical assets retained (not deleted):

* `frequency_sets.json`
* `FrequencyService` Likert helpers
* `FrequencyResultScreen` (no longer navigated from canonical complete path)

Legacy aggregate totals are not the canonical 6D / 20D profile source.
