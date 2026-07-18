# Firestore Assessment Runtime QA (Phase 3O-A3E)

**Date:** 2026-07-18  
**Mode:** Flutter **client** runtime QA after RC1 publish + integer `version` parse fix  
**Constraints:** No re-publish · no `assessment_sets` writes · no Admin SDK publish · no assessment JSON edits · no commit/push

Related: `docs/firestore_publish_rc1_report.md`, `docs/firestore_admin_publish_plan_rc1.md`

---

## 1. Parse fix summary

**Issue:** RC1 Firestore docs store `version` as **integer `2`**.  
`AssessmentSetModel.fromFirestore` previously used `(data['version'] as String?)`, which throws on `int` and blocked client load of `*_v2` sets.

**Fix (kept):** `lib/features/assessment/models/assessment_set_model.dart`  
`_coerceVersionString` accepts `String` or `num` → model field `"2"`.

**Prior read-only confirmation (not re-run this phase):**  
`assessment_sets/iq_set_001_v2` → `version_raw_type=int`, `version_raw=2`, `version_coerced="2"`.

---

## 2. Environment

| Item | Value |
|------|--------|
| Simulator | **iPhone 16e** (`7D75D798-8F24-42D0-A7E0-E7D8D0DE97B2`) |
| Entry | `tool/runtime_qa_firestore_source.dart` (debug Flutter client; not Admin SDK) |
| Auth | Existing non-anonymous Firebase session on simulator |
| Reset helper | `AssessmentAssignmentResetHelper.resetAllAssignments()` |

---

## 3. Current-user assessment reset

| Field | Observed |
|-------|----------|
| Performed | **Yes** |
| `refused` | `false` |
| `writes` | `true` |
| `docsDeleted` | **3** (`iq`, `eq`, `frequency`) |
| Scope | Current user only |
| `assessment_sets` touched | **No** |

---

## 4. Runtime source logs

All fresh assigns logged:

```text
source=firestore_assessment_sets
```

Examples:

```text
[AssessmentLocalization] type=iq set_id=iq_set_028_v2 source=firestore_assessment_sets languageCode=tr resolvedFrom=tr …
[AssessmentLocalization] type=eq set_id=eq_set_022_v2 source=firestore_assessment_sets languageCode=tr resolvedFrom=tr …
[AssessmentLocalization] type=frequency set_id=frequency_set_042_v2 source=firestore_assessment_sets languageCode=tr resolvedFrom=tr …
[AssessmentLocalization] type=iq set_id=iq_set_020_v2 source=firestore_assessment_sets languageCode=en resolvedFrom=en …
[AssessmentLocalization] type=eq set_id=eq_set_042_v2 source=firestore_assessment_sets languageCode=en resolvedFrom=en …
[AssessmentLocalization] type=frequency set_id=frequency_set_004_v2 source=firestore_assessment_sets languageCode=en resolvedFrom=en …
```

No `bundled_assets` source observed for these assigns.

---

## 5. Assigned set IDs observed

| Locale | IQ | EQ | Frequency |
|--------|----|----|-----------|
| **tr** | `iq_set_028_v2` | `eq_set_022_v2` | `frequency_set_042_v2` |
| **en** | `iq_set_020_v2` | `eq_set_042_v2` | `frequency_set_004_v2` |

All IDs end with **`_v2`**. Parsed `version=2` on assigned models.

(Earlier pass also saw `iq_set_019_v2`, `eq_set_024_v2`, `frequency_set_002_v2` / `iq_set_002_v2`, `eq_set_006_v2`, `frequency_set_013_v2` — random active pick.)

---

## 6. Turkish locale QA

| Check | Result |
|-------|--------|
| `languageCode=tr` / `resolvedFrom=tr` | **PASS** |
| Question text Turkish | **PASS** (e.g. EQ: “Tartışmadan sonra özür…”, Frequency Turkish stem) |
| Options Turkish (IQ/EQ) | **PASS** (e.g. IQ opt `Her R28 bir V28'dir.`, EQ Turkish option string) |
| Frequency options | N/A (Likert chrome via app l10n) |

---

## 7. English locale QA

| Check | Result |
|-------|--------|
| `languageCode=en` / `resolvedFrom=en` | **PASS** |
| Question text English | **PASS** |
| Options English (IQ/EQ) | **PASS** (e.g. IQ `Q`, EQ English option) |

---

## 8. Fallback (code inspection only — Firestore not deleted)

`AssessmentSetService` priority unchanged:

1. Firestore `assessment_sets` (by id / active query) → `firestore_assessment_sets`  
2. Bundled assets → `bundled_assets`  
3. Legacy `questions` → last resort  

Bundled assets remain available if Firestore read fails; **not** exercised by deleting live docs this phase.

---

## 9. Confirmations

| Action | Status |
|--------|--------|
| Re-publish / Admin publish script | **No** |
| Write to `assessment_sets` | **No** |
| Assessment JSON edited | **No** |
| Scoring / compatibility weights changed | **No** |
| Commit / push | **No** |
| User assignment reset writes | **Yes** (current user only) |

---

## 10. Issues found

| Issue | Status |
|-------|--------|
| Integer `version` cast crash on client | **Fixed** before successful QA |
| Manual UI locale switch / full screen walkthrough | Not required; client assign + resolver previews covered TR/EN |
| `_matchesLocalizedSetIdPattern` still legacy-only (`^\d{3}$`) | Non-blocking for v2 load/assign; may affect legacy-recovery heuristics later |

---

## 11. Recommendation — next phase

1. Manual smoke in **main app UI** on simulator: Debug Admin reset → start IQ test → confirm on-screen TR/EN with device locale.  
2. Optionally tighten `_matchesLocalizedSetIdPattern` to accept `*_v2` IDs.  
3. Commit parse fix + runtime QA docs when ready.  
4. Proceed to product beta / Discover cold-start validation with Firestore-sourced assessments.
