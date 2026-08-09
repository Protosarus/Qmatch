# Structured Explanation Localization Contract v1

Phase: **P2B-5**. Keys + parameters only. **No** production localization files.

## Mode

`structured_code_and_parameters`

Domain models store `localizationKey` + typed `localizationParameters`.
They must **not** store complete user-facing sentences.

## Allowed parameter types

- `dimension_id`, `field_id`, `module_id`, `direction`
- `normalized_score`, `confidence`, `confidence_band`, `severity_band`
- `percentage_like_ratio`, `count`, `status_code`
- `component_id`, `constraint_id`, `shrink_direction`

## Forbidden in parameters

Names, emails, raw private values, messages, photos, medical data, inferred
sensitive attributes, free-form prose.

## Example keys

- `qmatch.explanation.overall.complete`
- `qmatch.explanation.overall.partial`
- `qmatch.explanation.overall.insufficient`
- `qmatch.explanation.overall.blocked`
- `qmatch.explanation.overall.invalid`
- `qmatch.explanation.structural.close`
- `qmatch.explanation.structural.different`
- `qmatch.explanation.preference.strong_fit`
- `qmatch.explanation.preference.weak_fit`
- `qmatch.explanation.value.aligned`
- `qmatch.explanation.value.difference`
- `qmatch.explanation.soft_conflict.moderate`
- `qmatch.explanation.hard_constraint.failed`
- `qmatch.explanation.evidence.low_confidence`
- `qmatch.explanation.confidence.shrunk_to_neutral`
- `qmatch.explanation.production.not_approved`

UI layers may later map keys → strings. This phase does not ship those strings.
