# Scoring Version Contract v1

**Status:** Contract freeze (P1A)

Every persisted assessment, persona, and matching output must declare the versions that produced it.  
**Existing stored results must not change silently** when configs or formulas change.

## 1. Independent version identifiers

| Field name | Owns | Changes when |
|---|---|---|
| `question_schema_version` | Item metadata shape (ids, constructs, option value schema) | Breaking metadata/schema changes |
| `content_version` | Concrete question text/options/set membership | Any content edit affecting answers |
| `trait_scoring_version` | Mapping answers → dimension scores | Contribution weights, reverse rules, aggregation |
| `rvi_version` | Response Validity Index formula | Flags/thresholds/quality bands |
| `normalization_version` | 0–1 scaling, missing policy, norm tables | Scaling or missing rules; norm pack updates |
| `persona_profile_version` | 18 prototype vectors/weights/anti-traits | Prototype pack edits |
| `persona_scoring_version` | Distance/similarity, tie-break, confidence assembly | Algorithm changes |
| `matching_scoring_version` | Soft similarity formula & weights | Matching math changes |
| `feature_version` | Matching feature set membership (which signals exist) | Adding/removing features |
| `explanation_prompt_version` | AI copy prompts only | Prompt edits (must not alter scores) |
| `ranking_model_version` | Optional learned ranker | Model retrain/deploy |

Recommended companion constants in config packs:

- `assessment_version` — assessment result document schema  
- `persona_version` — persona result document schema  

## 2. Suggested initial freeze labels (documentation only)

These are **contract names**, not deployed runtime constants yet:

| Field | Proposed initial |
|---|---|
| `question_schema_version` | `qschema_v1` |
| `content_version` | `content_legacy_2026_01` for current banks; new banks get new ids |
| `trait_scoring_version` | `trait_unscored_legacy` until EQ trait engine exists |
| `rvi_version` | `rvi_v0_unscored` |
| `normalization_version` | `norm_v0_missing_explicit` |
| `persona_profile_version` | `profiles_invalid_until_20d_remap` for current JSON; next valid `profiles_v2_20d` |
| `persona_scoring_version` | `persona_engine_unscored` until implemented |
| `matching_scoring_version` | `compat_coldstart_v1` (current CompatibilityScoring) |
| `feature_version` | `features_coldstart_v1` |
| `explanation_prompt_version` | `explain_v0` |
| `ranking_model_version` | `none` |

## 3. When a version must change

- Any change that can alter outputs for the same raw answers.  
- Content text changes that can change interpretation or option identity.  
- Prototype vector/weight edits.  
- Missing-data policy changes.  
- Hard-gate threshold pack changes (`matching_scoring_version` and/or `feature_version`).

## 4. When a version must not change

- Pure UI chrome, asset swaps, copy that is not in scoring path.  
- AI wording under same `reason_codes` (bump `explanation_prompt_version` only).  
- Bugfixes that do not alter numeric outputs (document carefully; prefer bump if unsure).  
- Adding dead-code docs.

## 5. Backward compatibility

- Readers must accept older version strings and route to frozen interpreters.  
- New writers must never claim an old version id for new math.  
- Alias maps (legacy dimension keys) live in migration code keyed by `content_version` / `normalization_version`.

## 6. Result immutability

- Completed assessment/persona docs are append-only logically.  
- Corrections create a new doc/version with `supersedes` / `status=superseded` on old.  
- User mirrors may update to point at new result only via explicit recompute.

## 7. Recalculation policy

| Trigger | User-facing change? | Requirement |
|---|---|---|
| Shadow mode | No | Store side-by-side under new versions |
| Admin recompute | Opt-in / flagged | Complete source refs + version bump |
| Automatic silent | **Forbidden** | — |

## 8. Shadow-mode policy

1. Compute candidate outputs with new versions.  
2. Persist to shadow collection or `shadow_*` fields, not as canonical mirrors.  
3. Compare distribution, top2 stability, empty-feed, locale DIF proxies.  
4. Promote only after go/no-go; promotion bumps active config pointer, not old rows.

## 9. Rollback policy

- Keep previous config packs loadable by version id.  
- Rollback = point runtime at prior version ids; do not mutate historical rows.  
- Kill switch for matching gates separate from persona reveal.

## 10. Audit logging requirements

Log (server-side when available):

- uid (or pseudonymous research id)  
- all version fields used  
- set_id / question_order hash  
- output ids (persona, matching decision summary without leaking peer sensitive vectors)  
- timestamp  
- `source` (`client_v1` / `server_v1`)  

## 11. Separation invariants

- Changing `explanation_prompt_version` must not change persona or matching numbers.  
- Changing `persona_scoring_version` must not rewrite `matching_scoring_version` outputs.  
- Compatibility score and matching confidence are distinct fields.  
- Persona confidence ≠ matching confidence.

## 12. Current live gap

Today most version fields are **absent** on Firestore writes.  
P1 implementation must add them before claiming QRCF compliance.  
`persona_profiles_v1.json` declares `scoringVersion: persona_v1.0.0` but is **not** wired; treat as design-only until remapped to canonical 20D.

## Validation

- [x] Versions have single purposes  
- [x] Silent rewrite forbidden  
- [x] Shadow / rollback / audit defined  
- [x] AI prompt version isolated from scoring  
