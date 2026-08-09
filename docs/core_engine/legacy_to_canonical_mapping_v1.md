# Legacy → Canonical Mapping v1

**Status:** Contract freeze (P1A)  
**Policy:** Preserve history. Do not silently upgrade. Do not invent personas from incomplete vectors.

## Mapping legend

| Action | Meaning |
|---|---|
| `retain` | Keep as historical field forever (or long retention) |
| `mirror` | Temporary dual-read during migration |
| `deprecate` | Stop new writes; readers until cutover |
| `retire` | Remove from new runtime reads after cutover |

---

## 1. Persona / archetype legacy

| Legacy field / value | Writer | Reader | Current meaning | Canonical replacement | Rule | Migrate users? | Recalc? | Freeze history? |
|---|---|---|---|---|---|---|---|---|
| `category` = HH…LL | `AuthService.updateTestCompletion` | Discover, messages, profile display, compatibility | IQ×EQ band grid | None as persona_id. Optional `legacy_iq_eq_category` | retain → deprecate | No auto map to 18 | Only if full new assessments exist | Yes |
| `archetype` English name | same | UI resolvers | Display name for grid | `primary_persona_id` only after new engine | retain as `legacy_archetype_name` | No | No from name alone | Yes |
| HH…LL as identity | `ArchetypeCalculator` | EQ reveal | 9 personas | 18 `persona_id` | retire from scoring | Never convert | Requires IQ+EQ+F canonical vectors | Yes |

**Hard rule:** Do **not** convert a legacy 9-grid archetype into a canonical 18 persona.

---

## 2. IQ / EQ score legacy

| Legacy | Writer | Reader | Meaning | Canonical | Action | Notes |
|---|---|---|---|---|---|---|
| `iq_score` | `updateTestCompletion` | limited | Raw correct count | `assessments/iq.performance_summary.correct_count` | mirror then deprecate on user doc | Denominator must be IQ `question_count` |
| `eq_score` | same | limited | Raw “correct” count | **Retire as character score**; EQ has no correct | deprecate | Keep frozen historical |
| `iq_normalized` | same | compatibility bands | 0–100 from shared denominator bug risk | IQ domain scores + optional performance | deprecate for matching | Band closeness ≠ QRCF |
| `eq_normalized` | same | compatibility | 0–100 | EQ 10D vector | deprecate | |
| Assignment `score` IQ/EQ | `markAssignmentCompleted` | admin/debug | Progress score | Keep as assignment metadata only | retain | Not profile vector |

---

## 3. Frequency legacy

| Legacy | Writer | Reader | Meaning | Canonical | Action |
|---|---|---|---|---|---|
| `frequency_type` | `FrequencyService.saveFrequencyResult` | Discover, UI | if/else type label | Descriptive only; not persona | retain as descriptive mirror; not matching identity |
| `frequency_tags` | same | compatibility | tag list | Optional soft tags | deprecate for primary matching |
| `frequency_score` / `score_total` / `scoreTotal` | same | UI | mean of dims ×100 | **Not** persona/match driver → `legacy_score_total` | deprecate |
| `frequency_vector` / `vector` with keys `depth`, `socialEnergy`, `spontaneity`, `stability`, `emotionalOpenness`, `conversationPace` | same | compatibility | 6D 0–1 | Map to canonical Frequency IDs | mirror with alias map |
| Empty dim → `0.5` | `calculateResult.dimAvg` | scoring | fabricated neutral | **Forbidden** | retire behavior |
| Dual camelCase/snake_case | model toFirestore/fromFirestore | readers | transport inconsistency | snake_case canonical writes | mirror readers temporarily |

### Frequency key alias map

| Legacy key | Canonical `dimension_id` |
|---|---|
| `depth` | `depth_preference` |
| `socialEnergy` | `social_energy` |
| `spontaneity` | `spontaneity` |
| `stability` | `stability` |
| `emotionalOpenness` | `disclosure_pace` |
| `conversationPace` | `communication_pace` |

---

## 4. Compatibility / Discover legacy

| Legacy | Writer | Reader | Meaning | Canonical | Action |
|---|---|---|---|---|---|
| `CompatibilityScoring.calculateCompatibility` weighted sum | DiscoverService | Discover UI | Soft rank 0–1 | New matching engine + hard gates | deprecate formula |
| `archetype` weight 0.15 | same | rank | Persona-like signal | **Must go to 0** | retire |
| `missingSignalNeutral = 0.42` | same | rank | Missing filler | Missing = absent; lower confidence | retire |
| `compatibilityScore ?? 0.5` sort fallback | DiscoverService | sort | Fake mid | Treat as missing / exclude | retire |
| `closenessScore` raw | helper | optional | Raw IQ/EQ closeness | Prefer reliability-weighted dims; hard gates | deprecate |
| Interests / recency | same | rank | Soft signals | Allowed as soft rerank after gates | retain conceptually |
| `looking_for` | profile | **not in scoring today** | Intent | Values/intent layer | activate in matching later |

---

## 5. Naming duplicates

| Pair | Canonical choice | Rule |
|---|---|---|
| `scoreTotal` vs `score_total` | `legacy_score_total` or omit | New docs snake_case only |
| `completedAt` vs `completed_at` | `completed_at` | |
| `frequency_vector` vs `vector` | `dimension_scores` in assessments/frequency | Keep read adapter |
| `test_completed` | Keep during migration | Means “legacy IQ+EQ finished”; add explicit `iq_assessment_completed` / `eq_assessment_completed` / `persona_ready` |

---

## 6. Profile null overwrite

| Legacy behavior | Canonical |
|---|---|
| `UserProfileModel.toFirestore()` writes `archetype: null`, `category: null` | Omit nulls; never clear assessment mirrors from profile setup |
| `ProfileService.saveProfile` merge of those nulls | Merge allowlist excluding assessment/persona fields |

---

## 7. Documents that do not exist yet

| Missing path | Canonical action |
|---|---|
| `users/{uid}/assessments/iq` | Create on new completions only |
| `users/{uid}/assessments/eq` | Create on new completions only |
| `users/{uid}/assessments/persona` | Create only after all three + engine |

Legacy users without these docs: **no invented persona**.

---

## 8. Recalculation policy (summary)

| Case | Allowed? |
|---|---|
| Silent rewrite of stored legacy category/archetype | **No** |
| Shadow compute new persona without user-facing replace | Yes |
| User-facing replace | Only with new `persona_scoring_version` + complete source refs + explicit recompute flow |
| Partial vector (missing Frequency) | Insufficient → no primary persona |

---

## Validation

- [x] HH…LL separated from 18 IDs  
- [x] Frequency types not personas  
- [x] Missing filler called out for retirement  
- [x] Historical freeze required  
