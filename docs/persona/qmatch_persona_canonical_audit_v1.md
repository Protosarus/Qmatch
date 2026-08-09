# QMatch Persona Canonical Audit v1

**Phase:** P2C-3A-1  
**Date:** 2026-08-09  
**Mode:** READ-ONLY / CONTRACT-FOUNDATION  
**Starting tip:** `8e7317d2266d4c6ca7865b8012fc88e246556897`

```text
PERSONA_RUNTIME_READY = false
Canonical measurement profile = 20 / 20 (uncalibrated)
Canonical Persona runtime = NOT_STARTED
```

This audit does **not** invent prototype vectors, reliability values, temperature,
Top-2 thresholds, or confidence. It does **not** wire live Persona reveal.

---

## Decision summary

| Area | Verdict |
|------|---------|
| Exact 18 Persona IDs | **READY** (stable across catalog / v1 / v2) |
| Structural 20D prototypes | **READY** in `persona_profiles_v2_20d.json` only |
| Scientific / production prototype blessing | **UNRESOLVED** (`provisional` / `synthetic_validation_only`) |
| Legacy `persona_profiles_v1.json` | **LEGACY_PERSONA_PROTOTYPE_ASSET** — do not feed 20D profile |
| Group weights 0.15 / 0.30 / 0.55 | **READY** in v2 config (matches Core Engine v2) |
| Reliability input R_j | **BLOCKED_PERSONA_RELIABILITY_POLICY** |
| Evidence sufficiency E_j / n_j^min Persona handoff | **BLOCKED_PERSONA_MINIMUM_EVIDENCE_POLICY** |
| Temperature T | **BLOCKED_PERSONA_TEMPERATURE_CONFIG** |
| Top-2 thresholds | **BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY** |
| Confidence | **NOT_READY_FOR_PRODUCTION** |
| Live post-Frequency Persona scoring | **NOT wired** (by design after P2C-2A-8R2) |

---

## Exact readiness matrix (section 26)

| # | Item | Status |
|---|------|--------|
| 1 | Exact 18 stable Persona IDs | **READY** |
| 2 | Exact 20D target vector for every Persona | **READY** (v2 structural; provisional calibration) |
| 3 | Exact 20D dimension weights for every Persona | **READY** (v2; provisional) |
| 4 | Canonical anti-trait rules | **READY** (v2 provisional rules present) |
| 5 | Persona-specific minimum evidence rules | **READY** (v2 fields present; provisional) |
| 6 | Tie-break ranks | **READY** (unique 1–18 in v2) |
| 7 | Scoring version | **READY** (`persona_scoring_config_v2.0`, status provisional) |
| 8 | Prototype version | **READY** (`persona_profiles_v2_20d.0`) |
| 9 | Status per Persona | **READY** (`provisional` on all 18) |
| 10 | TR/EN names | **READY** (catalog + v1 + v2 labels) |
| 11 | TR/EN descriptions | **LEGACY_ONLY / CONFLICTED** (catalog + v1 have prose; v2 labels-only; no ARB keys) |
| 12 | Canonical asset mapping | **READY** via `assessment_persona_reference_catalog.dart` (not inside v2 JSON) |
| 13 | Canonical `n_j_min` | **CONFLICTED** — trait config has provisional `minimum_primary_evidence`; Core Engine E_j formula / live Persona handoff not resolved |
| 14 | Uncalibrated reliability fallback policy | **MISSING** → **BLOCKED_PERSONA_RELIABILITY_POLICY** |
| 15 | Temperature T | **UNRESOLVED** → **BLOCKED_PERSONA_TEMPERATURE_CONFIG** |
| 16 | Top-2 thresholds | **UNRESOLVED** → **BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY** |
| 17 | Confidence policy | **UNRESOLVED** / **NOT_READY_FOR_PRODUCTION** |
| 18 | Firestore Persona result schema | **READY** as contract doc; **MISSING** as live writer |
| 19 | Legacy migration policy | **READY** (docs forbid silent remap HH…LL / v1 aliases → 20D) |
| 20 | Shadow-mode path | **MISSING** (status enum only; no live shadow writer/UI) |

---

## Exact 18 Persona inventory

Sources:

* IDs / TR·EN titles / assets: `lib/features/assessment/utils/assessment_persona_reference_catalog.dart`
* Structural 20D prototypes: `assets/data/persona_profiles_v2_20d.json`
* Legacy prototypes: `assets/data/persona_profiles_v1.json` → **LEGACY_PERSONA_PROTOTYPE_ASSET**
* Offline scoring config: `assets/data/persona_scoring_config_v2.json`

| persona_id | TR | EN | status | source (canonical structure) | target_vector[20] | dimension_weights[20] | anti_traits | minimum_evidence | tie_break_rank | asset mapping | legacy vs canonical |
|------------|----|----|--------|------------------------------|-------------------|-----------------------|-------------|------------------|----------------|---------------|---------------------|
| `uygulayici` | Uygulayıcı | Executor | provisional | v2 + catalog | yes | yes | yes (3) | yes | 1 | catalog PNG | ID stable; v1 legacy taxonomy |
| `koruyucu` | Koruyucu | Guardian | provisional | v2 + catalog | yes | yes | yes (4) | yes | 2 | catalog PNG | same |
| `bilge` | Bilge | Sage | provisional | v2 + catalog | yes | yes | yes (4) | yes | 3 | catalog PNG | same |
| `lider` | Lider | Leader | provisional | v2 + catalog | yes | yes | yes (4) | yes | 4 | catalog PNG | same |
| `muhafiz` | Muhafız | Sentinel | provisional | v2 + catalog | yes | yes | yes (4) | yes | 5 | catalog PNG | same |
| `sifaci` | Şifacı | Healer | provisional | v2 + catalog | yes | yes | yes (4) | yes | 6 | catalog PNG | ID ≠ legacy LH |
| `yargic` | Yargıç | Judge | provisional | v2 + catalog | yes | yes | yes (4) | yes | 7 | catalog PNG | same |
| `empat` | Empat | Empath | provisional | v2 + catalog | yes | yes | yes (4) | yes | 8 | catalog PNG | same |
| `cesur` | Cesur | Brave | provisional | v2 + catalog | yes | yes | yes (4) | yes | 9 | catalog PNG | same |
| `kararli` | Kararlı | Determined | provisional | v2 + catalog | yes | yes | yes (3) | yes | 10 | catalog PNG | same |
| `vizyoner` | Vizyoner | Visionary | provisional | v2 + catalog | yes | yes | yes (4) | yes | 11 | catalog PNG | same |
| `yaratici` | Yaratıcı | Creator | provisional | v2 + catalog | yes | yes | yes (4) | yes | 12 | catalog PNG | same |
| `iletisimci` | İletişimci | Communicator | provisional | v2 + catalog | yes | yes | yes (4) | yes | 13 | catalog PNG | same |
| `analist` | Analist | Analyst | provisional | v2 + catalog | yes | yes | yes (3) | yes | 14 | catalog PNG | same |
| `donusturucu` | Dönüştürücü | Transformer | provisional | v2 + catalog | yes | yes | yes (4) | yes | 15 | catalog PNG | same |
| `bagimsiz` | Bağımsız | Independent | provisional | v2 + catalog | yes | yes | yes (4) | yes | 16 | catalog PNG | same |
| `sezgisel` | Sezgisel | Intuitive | provisional | v2 + catalog | yes | yes | yes (4) | yes | 17 | catalog PNG | same |
| `stratejist` | Stratejist | Strategist | provisional | v2 + catalog | yes | yes | yes (4) | yes | 18 | catalog PNG | ID ≠ legacy HM |

Count = **18**. No 19th invented. IDs not renamed in this phase.

---

## Legacy vs canonical taxonomy

### LEGACY — `assets/data/persona_profiles_v1.json`

Classified: **LEGACY_PERSONA_PROTOTYPE_ASSET**

* IQ aliases include `logic`, `pattern`, `verbal`, `spatial`, **`numerical`** (5 slots)
* EQ camelCase / obsolete set (`selfAwareness`, `autonomy`, `adaptability`, …)
* Frequency aliases (`depth`, `socialEnergy`, `emotionalOpenness`, `conversationPace`)
* Group weights inside v1: `0.10 / 0.55 / 0.35` (obsolete relative to Core Engine v2)
* Registered in `pubspec.yaml`; **must not** receive the canonical 20D profile
* No silent remap (`numerical→pattern_reasoning`, etc.) approved for live scoring

### CANONICAL structure — `assets/data/persona_profiles_v2_20d.json`

* Exact registry IDs matching `PersonaDimensionIds` / current 20D profile
* Group weights `iq=0.15`, `eq=0.3`, `frequency=0.55`
* **Not** registered in `pubspec.yaml` (filesystem offline loader only)
* `calibration_status = synthetic_validation_only`
* All personas `status = provisional`

### Forbidden alias guard (code)

`PersonaDimensionIds.forbiddenAliases` rejects legacy keys such as `logic`, `numerical`, `emotionalOpenness`, `conversationPace`, etc.

---

## Offline Persona scoring library (not live)

Present under `lib/features/assessment/domain/persona_scoring/`:

* `PersonaScoringService` — pure offline math
* `PersonaScoringFileLoader` — loads v2 from repo filesystem
* Tests + `tool/persona_prototype_simulator.dart` for synthetic reachability

Production screens are guarded **not** to import `PersonaScoringService`
(`test/assessment_blueprint_contract_test.dart`).

Post-Frequency path (`FrequencyTestScreen`) → `AssessmentFlowCompleteScreen` with **no** Persona invoke.

---

## Reliability / evidence blockers (detail)

### Reliability

* Live IQ / EQ / Frequency → 20D adapters persist `reliability_status = not_calibrated`
* No approved uncalibrated Persona fallback for `R_j`
* Offline service currently defaults omitted reliability to **`1.0`** — this is **not** an approved production policy under Core Engine v2

→ **BLOCKED_PERSONA_RELIABILITY_POLICY**

### Evidence sufficiency

* Trait config defines per-dimension `minimum_primary_evidence` (and a **provisional** sufficiency curve)
* Core Engine v2 specifies `E_j = min(1, n_j / n_j^{min})`
* These are **not** reconciled into an approved Persona handoff from the live 20D profile
* 20/20 completeness must **not** imply `E_j = 1`

→ **BLOCKED_PERSONA_MINIMUM_EVIDENCE_POLICY**

---

## Temperature / Top-2 / affinity / confidence

| Parameter | Repo provisional value | Core Engine v2 (this phase) | Status |
|-----------|------------------------|-----------------------------|--------|
| T | `0.22` in config | **UNDETERMINED** (simulation required) | **BLOCKED_PERSONA_TEMPERATURE_CONFIG** |
| Top-2 margin | `0.035` | **UNDETERMINED** | **BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY** |
| Affinity `π_p` | computed offline via `exp(-D/T)` | Must not expose as probability; blocked until T resolved | **UNRESOLVED** for production |
| Confidence | blended offline heuristic | **NOT_READY_FOR_PRODUCTION** | blocked |

Do **not** reuse older example values (e.g. `T=0.18`, margins `0.05/0.08/0.15`) as canonical.

---

## Formula alignment note

Latest Core Engine v2 (this phase) uses Frequency-first group weights after within-group distances, α=0.65, and total distance with provisional `γ_A=0.10`, `γ_Ω=0.05` in the clipped convex form.

Repo `persona_scoring_config_v2.json` currently uses additive penalties `γ=0.12`, `δ=0.18` instead of those coefficients.

→ Total-distance coefficients: **CONFLICTED** (document only; no numbers invented/changed in this phase).

Group weights `0.15/0.30/0.55` and α=`0.65` **agree**.

See `docs/persona/qmatch_persona_scoring_math_contract_v1.md`.

---

## Legacy runtime audit

| Topic | Finding |
|-------|---------|
| When invoked | Historical EQ/9-grid path; **not** after canonical Frequency completion |
| Inputs | Legacy IQ/EQ aggregates / levels (HH…LL), not canonical 20D |
| Taxonomy | 9-grid `HH…LL` via `ArchetypeCalculator` — **not** the 18 IDs |
| Firestore | User mirrors `archetype`, `category`, score fields; `updateTestCompletion` appears unwired from current callers |
| UI | Legacy result / Discover chips still present; Frequency routes to neutral flow-complete |
| Action this phase | **Do not reconnect** |

---

## Firestore Persona schema audit (read-only)

Intended contract (`docs/core_engine/assessment_result_contract_v1.md`):

```text
users/{uid}/assessments/persona
```

Fields include `primary_persona_id`, `secondary_persona_id`, similarities, `top2_margin`, versions, status.

**Collision risks:**

* Legacy user fields `archetype` / `category` still exist in Discover UX
* No live writer found in `CanonicalAssessmentPersistence` for `assessments/persona`
* Client-written persona IDs must not be trusted without versioned server doc

No Persona writes performed in this phase.

---

## Synthetic simulation readiness

| Artifact | Present? |
|----------|----------|
| `tool/persona_prototype_simulator.dart` | yes |
| Offline sim reports / fingerprints | yes (`docs/core_engine/persona_prototype_simulation_report_v2.md`, `tool/persona_sim_out/`) |
| Contract / determinism / missing-data tests | yes |
| Production Frequency→Persona E2E | **no** (intentionally unwired) |

Reachability claims are **offline / synthetic only**.

---

## Matching / quantum

Not integrated. Persona is not a matching key. No QRCF / fidelity / density-matrix work in this phase.

---

## Exact blocker list

```text
BLOCKED_PERSONA_RELIABILITY_POLICY
BLOCKED_PERSONA_MINIMUM_EVIDENCE_POLICY
BLOCKED_PERSONA_TEMPERATURE_CONFIG
BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY
```

Structural 20D prototypes are **not** missing (v2). They remain **provisional / synthetic_validation_only** and are **not** production-blessed.

```text
PERSONA_RUNTIME_READY = false
```

---

## Exact next phase

Resolve Persona input policies **before** live ranking/reveal:

1. Approved uncalibrated reliability policy (or keep Persona offline until calibrated R_j exists)
2. Approved E_j / `n_j_min` handoff from live 20D evidence
3. Canonical temperature + Top-2 threshold resolution (simulation + pilot)
4. Reconcile total-distance coefficient form with Core Engine v2
5. Only then: shadow-mode → production Persona runtime (separate phase)

Do **not** auto-start Persona reveal, Matching, QRCF, or quantum.
