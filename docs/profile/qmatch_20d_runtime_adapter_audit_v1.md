# QMatch 20D Runtime Adapter Audit v1

**Phase:** P2C-2A-6 (pre-implementation audit)
**Date:** 2026-08-09
**Tip at audit:** `70f6ac7cbccb3d387bce0dfc14e4b1e711a991a4`

---

## 1. Canonical IQ result (live)

- Model: `IqCanonicalScoringResult` (`lib/features/assessment/domain/iq_scoring/`)
- Policy: `iq_4d_uncalibrated_accuracy_v1`
- Dimensions: `logical_reasoning`, `pattern_reasoning`, `verbal_reasoning`,
  `spatial_reasoning` with `provisionalScore ∈ [0,1]`, `calibrationStatus=uncalibrated`
- Firestore: `users/{uid}/assessments/iq` via `buildCanonicalIq4dPayload`
  (`qmatch_iq_live_result_v1`), `canonical_profile_ready: false`
- UI: IQ completion navigates to `EQTestIntroScreen` (Reasoning Profile /
  IQ→EQ transition screens removed)
- **Does not** write a multidimensional profile document today

## 2. Canonical 20D taxonomy (exists — do not invent)

Authoritative sources:

| Source | Role |
|--------|------|
| `docs/core_engine/canonical_dimension_registry_v1.md` | Human contract |
| `assets/data/core_method_v2/canonical_dimension_registry_v1.json` | Machine registry |
| `assets/data/persona_profiles_v2_20d.json` `dimension_order` | 20 IDs + group weights |
| `PersonaDimensionIds` / `CanonicalDimensions` | Dart constants |

Exact 20 IDs:

```
IQ (4): logical_reasoning, pattern_reasoning, verbal_reasoning, spatial_reasoning
EQ (10): empathy, perspective_taking, self_awareness, emotion_regulation,
         emotional_openness, boundary_setting, assertiveness, conflict_approach,
         repair_orientation, social_awareness
Frequency (6): depth_preference, social_energy, spontaneity, stability,
               disclosure_pace, communication_pace
```

Hard rule already documented: missing evidence must never be filled with `0.5`
or other neutrals.

## 3. Existing profile / TraitScoring / CM v2 models

| Artifact | Status |
|----------|--------|
| `CanonicalUserAssessmentProfile` + `ModuleAssessmentProfile` + `DimensionMeasurement` | Offline CM v2; **not** live-wired after IQ |
| `CanonicalProfileAssembler` / `TraitScoringService` | Offline; screens do not call on IQ completion |
| `DimensionMeasurement.confidence` / `uncertainty` | Required finite `[0,1]` when present — **unsuitable** for inventing psychometric reliability from uncalibrated IQ |
| Prior boundary doc `docs/assessment/qmatch_iq_to_20d_contract_v1.md` | Adapter **NOT_STARTED** |

## 4. Persistence state

| Path | Content |
|------|---------|
| `users/{uid}/assessments/iq` | Live canonical 4D result |
| `users/{uid}.iq_score` | Legacy scalar; **not** written for new canonical completions |
| `users/{uid}/profiles/*` | **No** canonical multidimensional profile doc observed |

Discover still gates on Frequency `canonical_profile_ready` (legacy frequency path),
not a 20D profile document.

## 5. Exact migration points (this phase)

1. After valid `IqCanonicalScorer` result + IQ assessment persist
2. Run `IqTo20dRuntimeAdapter` → partial canonical profile fragment
3. Persist versioned profile (new path) without fabricating EQ/Frequency values
4. Continue onboarding IQ → EQ Intro → EQ unchanged (no Reasoning Profile)
5. Do **not** call Persona / matching / quantum / TraitScoring live paths

## 6. Adapter design decision

Prefer a dedicated versioned profile fragment
(`qmatch_canonical_profile_v1`) over forcing uncalibrated IQ into CM v2
`DimensionMeasurement` confidence fields.

Reuse registry dimension IDs from `CanonicalDimensions` / `PersonaDimensionIds`.
