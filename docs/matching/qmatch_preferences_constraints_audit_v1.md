# QMatch Preferences & Hard Constraints Audit v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_preferences_constraints_audit_v1` |
| Status | `audit_only_not_live` |
| Scope | **Repo / data-model audit only.** No scoring weights, Discover changes, Persona/RVI/temporal/QI, or implementation. |
| Architecture peer | [qmatch_final_matching_architecture_v1.md](./qmatch_final_matching_architecture_v1.md) (L1 hard eligibility, L3 preferences/values) |
| Explicit non-goals | Inventing fusion weights; inventing missing preference vocabularies; wiring Core Method offline models into Discover |

---

## 0. Verdict

Discover **today** hard-filters only **eligibility / photo / swipe / block**. Profile setup already collects several preference-like fields (`looking_for`, `age_range`, `distance_preference`) and attributes (`gender`, `age`, `location`, `religion`, lifestyle), but **most are not applied as reciprocal Matching constraints**.

Soft ranking remains legacy `CompatibilityScoring` (Frequency / archetype / IQ·EQ bands / interests / recency). Core Method v2 preference-fit and hard-constraint models exist **offline only** and are **not** persisted on live Discover user docs.

---

## 1. Attribute vs preference (definitions used here)

| Kind | Meaning | Example in repo |
| --- | --- | --- |
| **User attribute** | Who I am / what I have | `gender`, `age`, `religion`, `location`, `children` (self status) |
| **User preference** | Who / what I want | `age_range`, `distance_preference`; CM `children_preference` (offline) |
| **Ambiguous / dual-use** | Collected as “preferences” but stores self intent, not partner filter | `looking_for` (relationship intent strings) |
| **Eligibility / safety state** | Account or interaction gate | `discover_eligible`, blocks, swipes |
| **Assessment soft signal** | Measured trait / rhythm used in soft score | `frequency_vector`, `iq_normalized` |

Classification below is **as the code behaves today**, not a product decision.

---

## 2. Existing fields (inventory)

### 2.1 Profile / Firestore `users/{uid}` (setup + mirrors)

Primary models:

- `lib/features/profile/models/user_profile_model.dart`
- `lib/features/discover/models/discover_user_model.dart`
- Setup: `basic_info_step.dart`, `lifestyle_step.dart`, `preferences_step.dart`

| Firestore key | Dart | Attr / Pref | Matching class today | Notes |
| --- | --- | --- | --- | --- |
| `gender` | `gender` | Attribute | **Display-capable / unused in Discover filter & score** | Setup: `Erkek` / `Kadın` only. On Discover model but **not** card-rendered; **not** filtered |
| `looking_for` | `lookingFor` | **Ambiguous** (self relationship intent) | **Soft-preference candidate / unused** | Prefs step TR intents (“Ciddi İlişki”, “Evlilik”, …). Own-profile display; Discover unused |
| `age` | `age` | Attribute | **Display-only** on Discover (name+age) | Not filtered by viewer `age_range` |
| `age_range` | `ageRange` `[min,max]` | Preference | **Unsuitable until wired** (collected, unused) | On `UserProfileModel` only; **not** on `DiscoverUserModel`; Discover never reads |
| `distance_preference` | `distancePreference` (km) | Preference | **Unsuitable until wired** | Unused; needs geo |
| `location` | `location` (`GeoPoint?`) | Attribute | **Unsuitable until wired** | Optional GPS; unused for distance |
| `location_text` | `locationText` | Attribute / display | **Display / unused in Discover** | — |
| `religion` | `religion` | Attribute | **Unsuitable for Matching as-is** (no partner-religion pref) | Lifestyle setup; not Discover |
| `interests` | `interests` | Attribute (tags) | **Soft preference/value signal** | Jaccard in CompatibilityScoring + Discover chips |
| `education` | `education` | Attribute | **Display / unused for Matching** | Own profile |
| `bio` / `name` | same | Attribute / identity | **Display-only** | Not scoring inputs |
| `occupation` | `occupation` | Attribute | **Unsuitable / unused** | — |
| `drinking` / `smoking` / `pets` / `animal_love` | same | Attribute | **Unsuitable / unused** for Discover Matching | Lifestyle self-status |
| `children` | `children` | Attribute (self status) | **Ambiguous / unsuitable as preference** | Not CM `children_preference` |
| `photos` / `profile_photo_url` | same | Attribute + gate | **Hard eligibility** (must have photo) | — |
| `archetype` / `category` | same | Assessment attribute | **Soft signal** (+ display chips) | CompatibilityScoring |
| `iq_normalized` / `eq_normalized` | same | Assessment attribute | **Soft signal** (band closeness) | Not shown as raw % |
| `frequency_type` / `frequency_tags` / `frequency_vector` | same | Assessment attribute | **Soft signal** (primary cold-start) | May hydrate from `assessments/frequency` |
| `last_active_at` | `lastActiveAt` | Activity attribute | **Soft signal** + sort tiebreak | Candidate-only |
| `profile_completed` / `test_completed` / `active` | same | Eligibility | **Hard eligibility** | See §3 |
| `discover_eligible` | (bool) | Derived eligibility | **Hard eligibility** | Firestore query gate |
| `assessment_flow_completed` | (user doc) | Eligibility input | **Hard (via derivation)** | Not on Discover model |
| `verified` | `verified` | Meta | **Unsuitable / unused** | — |
| `email` / `phone_number` / auth ids | — | Identity | **Unsuitable for Matching** | Auth |

### 2.2 Interaction / safety (not preferences)

| Store | Use today | Class |
| --- | --- | --- |
| `users/{uid}/swipes/{target}` | Exclude already-swiped | **Hard eligibility** |
| `users/{uid}/blocks/{blocked_uid}` | Exclude users **I** blocked | **Hard eligibility** (asymmetric; reverse-block TODO) |

### 2.3 Offline Core Method v2 (not live Discover)

Assets / services under `lib/features/assessment/domain/core_method_v2/` and `assets/data/core_method_v2/`:

| Family | Examples | Class if ever promoted | Live today? |
| --- | --- | --- | --- |
| Partner preference profile | dimensional `preferred_min` / `preferred_max`, importance | Soft L3 | **No** |
| Directional preference fit | A←B / B←A fit scores | Soft L3 | **No** |
| Relationship value registry | `relationship_intent`, `marriage_intent`, `children_preference`, `monogamy_expectation`, `religion_importance`, smoking/alcohol prefs, etc. | Soft and/or hard per `supports_hard_constraint` | **No** |
| Hard constraint evaluation | mutual categorical pass/fail | Hard L1 (designed) | **No** |

These must **not** be treated as existing live Matching inputs.

### 2.4 Not found in live user / Discover models

| Expected product concept | Status in repo |
| --- | --- |
| `interested_in` / preferred gender / sexual orientation | **Missing** |
| Separate `min_age` / `max_age` keys | Only `age_range` list |
| Partner religion preference | **Missing** (only self `religion`) |
| Mutual intent matcher on `looking_for` | **Missing** |
| Discover filter_* prefs collection | **Missing** |

---

## 3. Hard eligibility constraints (as used today)

Source: `DiscoverService.getCandidates` + eligibility refresh in `ProfileService` / `AuthService`.

| Constraint | Mechanism | Reciprocal? |
| --- | --- | --- |
| `discover_eligible == true` | Firestore `where` | N/A (account gate) |
| Not self | Local skip | N/A |
| Not already swiped by me | SwipeService | One-sided |
| Not blocked by me | SafetyService | One-sided; reverse incomplete |
| `active != false` | Local | Account |
| `test_completed && profile_completed` | Local re-check | Account |
| Has photo | `profile_photo_url` or non-empty `photos` | Account |

**Eligibility derivation (writers):** roughly  
`discover_eligible = active && (test_completed || assessment_flow_completed) && profile_completed && hasPhoto`.

**Ambiguity:** derivation allows `assessment_flow_completed` **OR** `test_completed`; local Discover re-check still requires `testCompleted`. Treat as eligibility inconsistency, not a preference.

**Explicitly NOT hard constraints today:** gender, looking_for, age vs age_range, distance, location, religion, lifestyle, CM hard constraints.

---

## 4. Soft preferences / value signals (as used today)

Live soft ranking — `CompatibilityScoring` (`lib/core/utils/compatibility_scoring.dart`):

| Signal | Inputs | Role |
| --- | --- | --- |
| Frequency vector similarity | `frequency_vector` / `vector` | Soft (required ≥3 shared dims or score unavailable) |
| Frequency type / tags | `frequency_type`, `frequency_tags` | Soft |
| Archetype / category affinity | `archetype`, `category` | Soft |
| IQ / EQ band closeness | `iq_normalized`, `eq_normalized` | Soft |
| Interests Jaccard | `interests` | Soft + display |
| Recency | candidate `last_active_at` | Soft + sort tiebreak |

**Collected but unused soft-preference candidates (not scored):** `looking_for`, `age_range`, `distance_preference`.

**Architecture note:** Final Matching Architecture places future L3 (preferences/values) **separate** from L2 structural 20D. This audit does **not** assign weights.

Shadow diagnostics (equal-20D / Stage B2 group-normalized 20D) are **not** preference fields and do not reorder Discover.

---

## 5. Display-only (matching-adjacent)

| Field | Where |
| --- | --- |
| `name` + `age` | Discover card identity |
| `bio` | Discover details |
| `interests` | Discover chips (also soft-scored) |
| Compatibility score / label / reasons | Discover UI (legacy soft score) |
| Archetype / category chips | Discover presentation |
| Own `gender`, `looking_for`, education, drinking, smoking | Own profile presentation |
| `religion`, `children`, `pets`, `age_range`, `distance_preference` | Collected in setup; generally **not** Discover-card content |

`DiscoverUserModel.gender` / `lookingFor` are mapped from Firestore but **not** used by `qmatch_candidate_card.dart` for filtering or (currently) display of matching logic.

---

## 6. Unsuitable for Matching (as inputs)

| Field / system | Why |
| --- | --- |
| Auth identity (`email`, phone, `uid`) | Not compatibility |
| Ops timestamps | Not preference |
| Swipe / block docs | Interaction / safety state (gates, not prefs) |
| Raw assessment answers | Must not become Discover scoring mirrors |
| Self lifestyle without partner preference counterpart | e.g. self `religion` without partner-religion pref |
| Offline CM snapshots without persistence + Discover contract | Not live inputs |
| `verified` (unused) | Meta only today |
| Persona / RVI / temporal / QI | Out of scope for this audit; architecture prohibits as Matching keys where frozen |

---

## 7. Missing / ambiguous reciprocal constraints

| Gap | Detail |
| --- | --- |
| **No interested-in / gender preference** | Only self `gender`; cannot express mutual gender eligibility |
| **`looking_for` ≠ gender preference** | Stores relationship intent; Discover does not compare A↔B intents |
| **`age_range` unused** | Preference collected; no “B.age ∈ A.age_range” and no mutual reciprocity |
| **`distance_preference` + `location` unused** | No geo radius filter |
| **No partner-religion preference** | Self `religion` only; CM `religion_importance` offline only |
| **`children` vs `children_preference`** | Profile self-status vs CM preference vocabulary; unmapped |
| **Legacy `looking_for` vs CM `relationship_intent`** | Different vocabularies (TR UI strings vs registry enums); no Discover mapping |
| **Block reverse incomplete** | Users who blocked me not fully excluded (TODO in DiscoverService) |
| **Eligibility OR vs local AND** | `assessment_flow_completed` vs required `test_completed` mismatch |

---

## 8. Mapping to Final Matching Architecture layers

| Architecture layer | What exists today |
| --- | --- |
| **L1 Hard eligibility** | `discover_eligible`, active, profile/test completion, photo, swipe exclude, block-by-me |
| **L2 Structural** | Group-normalized 20D production candidate (not live ranking) |
| **L3 Preferences / values** | Partial collection (`age_range`, `distance_preference`, `looking_for`); CM offline preference-fit / values; **not Discover-wired** |
| **L4 / L5** | Out of scope (temporal / QI) |

---

## 9. Recommended next step

**Write `qmatch_matching_constraints_contract_v1` (docs/spec only)** that:

1. For each Firestore key in §2, freezes a product decision: **hard L1** / **soft L3** / **display** / **out of Matching**.
2. Explicitly decides reciprocity for age, distance, intent, and (if required) gender interested-in — including the fact that interested-in is **currently missing**.
3. Maps or deprecates legacy `looking_for` / lifestyle fields vs Core Method relationship-value registry **before** any Discover wiring.
4. Keeps CM hard-constraint / preference-fit **offline** until persistence + Discover integration is specified.
5. Does **not** invent scoring weights or change Discover.

Until that contract exists, treat unused profile prefs as **collected but not Matching-authoritative**.

---

## 10. Primary code anchors

- `lib/features/profile/models/user_profile_model.dart`
- `lib/features/profile/screens/steps/preferences_step.dart`
- `lib/features/discover/models/discover_user_model.dart`
- `lib/features/discover/services/discover_service.dart`
- `lib/core/utils/compatibility_scoring.dart`
- `assets/data/core_method_v2/relationship_value_registry_v1.json`
- `docs/matching/qmatch_final_matching_architecture_v1.md`

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Initial preferences / hard-constraints audit from repo data model |
