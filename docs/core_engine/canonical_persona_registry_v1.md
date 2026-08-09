# Canonical Persona Registry v1

**Status:** Contract freeze (P1A)  
**Sources inspected:**  
- `lib/features/assessment/utils/assessment_persona_reference_catalog.dart`  
- `assets/data/persona_profiles_v1.json` (untracked design asset; not runtime-wired)  
- `lib/features/assessment/models/archetype_model.dart`  
- `lib/features/assessment/screens/eq_test_screen.dart` (live HH…LL asset map)  
- `lib/features/assessment/utils/assessment_result_display_resolver.dart`  
- `lib/features/assessment/services/frequency_service.dart`  
- Firestore user fields via `auth_service.dart` / `user_profile_model.dart`  

## Explicit non-equivalences

1. Legacy `HH/HM/HL/MH/MM/ML/LH/LM/LL` are **not** canonical 18-persona IDs.  
2. Frequency types/tags are **not** personas.  
3. Persona labels are **not** matching features (`persona_label_bonus = 0`).  
4. Persona is generated **only after** IQ + EQ + Frequency are complete (target). Live code violates this (EQ-after reveal).  
5. Persona prototypes must use the **exact canonical 20 dimensions** from `canonical_dimension_registry_v1.md`.  
6. `persona_profiles_v1.json` currently embeds **5 IQ slots including `numerical`** and a **different EQ facet set** → prototypes are **not yet valid QRCF v1 prototypes**.

---

## A. Canonical 18 primary personas

**Canonical count from real sources: 18.**  
Catalog IDs and `persona_profiles_v1.json` `personaId` values **agree exactly**. No rename is required for IDs.

| persona_id | TR | EN | Display asset (catalog) | In profiles JSON | Valid 20D prototype today | Uses invalid 5th IQ | Live runtime reachable as primary | Legacy aliases | Migration status |
|---|---|---|---|---|---|---|---|---|---|
| `uygulayici` | Uygulayıcı | Executor | `assessment_persona_executor_reward_sparse.png` | Yes | No (5 IQ + wrong EQ set) | Yes (`numerical`) | No (only LL legacy uses executor art) | LL English “The Executor” is **not** this ID | Retain ID; rebuild prototype |
| `koruyucu` | Koruyucu | Guardian | `assessment_persona_guardian_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `bilge` | Bilge | Sage | `assessment_persona_sage_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `lider` | Lider | Leader | `assessment_persona_leader_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `muhafiz` | Muhafız | Sentinel | `assessment_persona_guard_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `sifaci` | Şifacı | Healer | `assessment_persona_healer_reward_sparse.png` | Yes | No | Yes | Partial asset reuse by legacy `LH` | LH “The Healer” ≠ `sifaci` ID | Retain ID; do not equate LH→sifaci |
| `yargic` | Yargıç | Judge | `assessment_persona_judge_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `empat` | Empat | Empath | `assessment_persona_empath_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `cesur` | Cesur | Brave | `assessment_persona_brave_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `kararli` | Kararlı | Determined | `assessment_persona_determined_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `vizyoner` | Vizyoner | Visionary | `assessment_persona_visionary_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `yaratici` | Yaratıcı | Creator | `assessment_persona_creator_reward_sparse.png` | Yes | No | Yes | No | — | Retain ID |
| `iletisimci` | İletişimci | Communicator | `assessment_persona_communicator_medallion.png` | Yes | No | Yes | No | — | Retain ID; normalize asset style later |
| `analist` | Analist | Analyst | `assessment_persona_analyst_medallion.png` | Yes | No | Yes | No | — | Retain ID |
| `donusturucu` | Dönüştürücü | Transformer | `assessment_persona_transformer_medallion.png` | Yes | No | Yes | No | — | Retain ID |
| `bagimsiz` | Bağımsız | Independent | `assessment_persona_independent_medallion.png` | Yes | No | Yes | No | — | Retain ID |
| `sezgisel` | Sezgisel | Intuitive | `assessment_persona_intuitive_medallion.png` | Yes | No | Yes | No | — | Retain ID |
| `stratejist` | Stratejist | Strategist | `assessment_persona_strategist_knight_medallion.png` | Yes | No | Yes | **Conflict:** legacy `HM` also uses this asset & EN “The Strategist” | HM ≠ `stratejist` | Retain ID; separate display keys |

### Localization

- Catalog titles/descriptions are **inline TR/EN** in Dart / JSON, not dedicated ARB persona keys today.  
- Recommended future keys: `persona_<id>_title`, `persona_<id>_description`, `persona_<id>_trait_<n>`.  
- Do not invent ARB keys in this phase.

### Source files per persona

- IDs + assets + titles: `assessment_persona_reference_catalog.dart`  
- Prototypes (invalid vs 20D): `persona_profiles_v1.json`  
- Debug preview: `persona_result_preview_screen.dart`  
- Live reveal path currently ignores these IDs and uses HH…LL.

---

## B. Legacy 9-grid archetypes (not canonical personas)

Live writer: `ArchetypeCalculator.calculateArchetype` → `AuthService.updateTestCompletion`  
Live reveal: `EQTestScreen` + `AssessmentResultDisplayResolver.resolveIqEqLevel`

| Legacy ID | EN (calculator / resolver) | TR (resolver) | Live asset (`eq_test_screen`) | Firestore | Status |
|---|---|---|---|---|---|
| `HH` | The Mastermind | Usta Zihin | `assessment_persona_mastermind_brain.png` | `category`, `archetype` name | Legacy only |
| `HM` | The Strategist | Stratejist | `assessment_persona_strategist_knight_medallion.png` | same | Legacy; label collision with `stratejist` |
| `HL` | The Architect | Mimar | `assessment_persona_architect_compass.png` | same | Legacy |
| `MH` | The Diplomat | Diplomat | `assessment_persona_diplomat_handshake.png` | same | Legacy |
| `MM` | The Realist | Gerçekçi | `assessment_persona_realist_scales.png` | same | Legacy |
| `ML` | The Technician | Teknik Odaklı Profil | `assessment_persona_technician_wrench.png` | same | Legacy |
| `LH` | The Healer | Şifacı | `assessment_persona_healer_reward_sparse.png` | same | Legacy; label/asset collision with `sifaci` |
| `LM` | The Observer | Gözlemci | `assessment_persona_observer_eye.png` | same | Legacy |
| `LL` | The Executor | Uygulayıcı | `assessment_persona_executor_reward_sparse.png` | same | Legacy; label/asset collision with `uygulayici` |

**Rule:** Never auto-convert HH…LL → one of the 18 IDs.

---

## C. Frequency descriptive types (not personas)

From `FrequencyService.calculateResult` + resolver:

| Type key | TR | EN | Role |
|---|---|---|---|
| `Deep Connector` | Derin Bağ Kurucu | Deep Connector | Descriptive Frequency type |
| `Social Spark` | Sosyal Kıvılcım | Social Spark | Descriptive |
| `Slow Burner` | Yavaş Yanan Bağ | Slow Burner | Descriptive |
| `Emotional Explorer` | Duygusal Kaşif | Emotional Explorer | Descriptive |
| `Open Current` | Açık Akış | Open Current | Descriptive |
| `Balanced Frequency` | Dengeli Frekans | Balanced Frequency | Default/fallback type |

Firestore: `frequency_type` on user doc + `assessments/frequency.type`.

---

## D. Secondary traits / tags

Frequency tags (not personas):

| Tag | TR (resolver) | EN |
|---|---|---|
| `deep_talker` | Derin Konuşmacı | Deep Talker |
| `social_energy` | Sosyal Enerji | Social Energy |
| `spontaneous` | Spontan | Spontaneous |
| `stability_first` | Önce İstikrar | Stability First |
| `emotionally_open` | Duygusal Açıklık | Emotionally Open |
| `slow_bond` | Yavaş ve Güvenli Bağ | Steady Connection |
| `fast_connection` | Hızlı Bağlantı | Fast Connection |

Also: catalog `traitLabels` (3 per persona) are **display chips**, not scoring IDs.

---

## E. Dead / unreachable / conflict definitions

| Item | Why |
|---|---|
| 18 catalog personas in production reveal | Unreachable as scored primary IDs |
| `persona_profiles_v1.json` prototypes | Not imported by runtime scoring service |
| PDF-era names Dengeleyici / Kaşif | Not in catalog or JSON → dead for this codebase |
| Dual use of Strategist/Healer/Executor labels | Legacy grid vs 18-ID collision |
| Medallion vs reward_sparse asset split | Style inconsistency; not dead, needs visual pass |

---

## Required persona result concepts

| Concept | Definition |
|---|---|
| Primary persona | Highest prototype similarity among 18 after all three assessments |
| Secondary persona | Second-highest; narrative support only |
| Persona confidence | Separate from matching confidence; combines top2 margin, evidence coverage, response quality, classification stability |
| Persona evidence | Dimensions/reason codes supporting primary |
| Anti-trait | Prototype-defined opposing evidence that penalizes assignment |
| Minimum evidence | Per-persona and per-dimension floors before assignment allowed |
| Adaptive separator target | Optional later questions that maximize discrimination between current top-2 only after core form; not in P1 runtime |

Confidence bands (display): `low` | `medium` | `high` (numeric internal allowed; never “% clinically certain”).

---

## Taxonomy conflicts (must not be silently resolved)

| Conflict | Evidence | Recommendation | Migration consequence |
|---|---|---|---|
| 5 IQ dims in profiles JSON vs 4 canonical | `dimensionOrder.iqStyle` length 5 + `numerical` | Keep 18 `persona_id`s; **invalidate** current vectors until remapped to 4 IQ + new EQ set | Requires new `persona_profile_version` |
| EQ facet set mismatch | JSON has autonomy/adaptability/intuitiveSensitivity; canonical has conflict_approach/social_awareness/emotional_openness | Do not auto-map; rebuild EQ slots | Content + prototype rewrite |
| Frequency `emotionalOpenness` vs EQ `emotional_openness` | Same English root, different modules | Canonical Frequency ID = `disclosure_pace` | Alias map required |
| HM “Strategist” vs `stratejist` | Shared EN label + asset | Keep both namespaces; different fields | UI must key by ID not English title |
| LH/LL vs sifaci/uygulayici | Shared TR/EN/assets | No automatic equivalence | Historical legacy frozen |

---

## Recommended stable IDs

**Use the 18 Turkish-slug IDs already shared by catalog + JSON** (listed in section A).  
Do **not** switch to English slugs (`executor`, `guardian`, …) without an explicit product rename RFC — that would break assets, profiles JSON, and debug tools simultaneously.

---

## Validation

- [x] Canonical persona count from sources = **18**  
- [x] Catalog IDs == JSON `personaId`s  
- [x] Legacy 9-grid separated  
- [x] Frequency types separated  
- [x] Prototypes marked invalid until 20D remap  
