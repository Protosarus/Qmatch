# Firestore Publish Preflight — Assessment Content RC1 (Phase 3O-A3A)

**Date:** 2026-07-18  
**Mode:** Preflight only — **no Firestore writes**, no publish, no assessment JSON edits, no scoring/compatibility weight changes, no commit/push  
**RC name:** Assessment Content RC1

---

## Executive recommendation

**READY for Phase 3O-A3B (controlled real publish)** — with the gates and publish path below.

Local assets + v2 export validate clean. Write helper targets only immutable `assessment_sets/{id}_v2`. Admin UI exposes dry-run only (no production publish button). Known content notes (54 Turkish heuristic flags) are documented and non-blocking for RC1.

---

## 1. Intended Firestore target

| Item | Value |
|------|--------|
| Collection | `assessment_sets` |
| Document IDs | `{legacy_id}_v2` only — e.g. `iq_set_001_v2`, `eq_set_042_v2`, `frequency_set_050_v2` |
| Path pattern | `assessment_sets/{set_id}_v2` |
| Write API | `set(..., SetOptions(merge: true))` on **versioned IDs only** |
| Helper | `UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2` |

### Confirmed non-targets

| Surface | Touched by publish helper? |
|---------|----------------------------|
| `users/*` | **No** |
| Messages / matches / profiles | **No** |
| Legacy `assessment_sets/iq_set_001` (no `_v2`) | **No** — legacy write path is dry-run-only and **cannot write** |
| Legacy `questions` collection | **No** — helper never writes there |
| Soft-delete / archive of v1 | **No** — v1 not deleted on v2 publish |

---

## 2. Doc / question counts

| Type | Docs (sets) | Questions |
|------|------------:|----------:|
| IQ | 50 | 500 |
| EQ | 50 | 500 |
| Frequency | 50 | 600 |
| **Total** | **150** | **1600** |

v2 metadata (every exported doc): `version: 2`, `active: true`, `status: published`, `language_mode: localized`, `base_id` = legacy id.

---

## 3. v2 export result

Command: `python3 scripts/export_assessment_sets_v2.py`

| Output | Present |
|--------|---------|
| `build/assessment_sets_v2/iq_sets_v2.json` | yes |
| `build/assessment_sets_v2/eq_sets_v2.json` | yes |
| `build/assessment_sets_v2/frequency_sets_v2.json` | yes |
| `build/assessment_sets_v2/all_assessment_sets_v2.json` | yes |

- Legacy docs read: 150 → versioned docs generated: 150  
- Source assets **unchanged**  
- Firestore writes during export: **no**

---

## 4. Validation results

| Check | Result |
|-------|--------|
| `python3 scripts/validate_assessment_sets.py` (assets) | **PASS** (legacy schema, 150 sets) |
| `python3 scripts/validate_assessment_sets.py --from-dir build/assessment_sets_v2` | **PASS** (versioned, 150 `*_v2`) |
| `python3 scripts/audit_assessment_content_quality.py` | **PASS WITH NOTES** (54 Turkish heuristic flags; IQ `generic_biri` ×50 + EQ idioms ×4) |
| `python3 scripts/audit_assessment_firestore_sync.py` | **PASS** / dry-run only / **no network / no writes** |
| `flutter analyze` | **No issues found** |

Note: The Python Firestore sync audit still lists **legacy** asset IDs as the on-disk source shape. The **approved publish path** converts those to `*_v2` in memory (same as export). Do **not** interpret the audit’s `assessment_sets/iq_set_001` paths as the write target for 3O-A3B.

---

## 5. Dry-run publish (no writes)

### 5.1 In-app / helper path (authoritative for future write)

```dart
await UploadAssessmentSetsHelper.dryRunVersionedV2AssessmentSync();
// or
await UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2(dryRun: true);
```

**Admin UI:** Debug → Assessment Admin → **“Run v2 Sync Dry Run”**  
(`assessment_admin_screen.dart` — never passes `dryRun: false` or the confirmation phrase.)

### 5.2 Expected dry-run report (v2)

Mirrored from local v2 export + helper contract (this preflight did **not** connect to Firebase):

| Field | Expected |
|-------|----------|
| `mode` | `dryRun` |
| `docsConsidered` | **150** |
| `docsWritten` | **0** |
| `writesPerformed` / `firestoreWritesPerformed` | **false** |
| `versionedIdCount` | **150** |
| `legacyIdCount` | **0** |
| `version` | **2** |
| `active` | **true** |
| `status` | `published` |
| `language_mode` | `localized` |
| `targetCollection` | `assessment_sets` |
| ID range | `iq_set_001_v2` … `frequency_set_050_v2` |

### 5.3 Python sync audit (local assets, no Firebase)

- Total documents considered from assets: **150**  
- **DRY RUN ONLY — no Firestore writes performed**  
- Explicitly states no credentials / no network

### 5.4 Confirmation: no Firestore writes in 3O-A3A

**No Firestore write occurred** in this phase (export local-only; audits offline; helper write gates not invoked with `dryRun: false`).

---

## 6. Write gate confirmation

Real writes require **all** of:

| Gate | Detail |
|------|--------|
| Debug mode | `kDebugMode == true` (release/profile never write) |
| Dart-define | `--dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true` (default **false**) |
| Explicit write | `dryRun: false` |
| Confirmation phrase | Exactly `SYNC_LOCALIZED_ASSESSMENT_SETS` |
| Default | `dryRun: true` — accidental write prevented |
| Production UI | **No** production publish button; admin screen is dry-run only |
| Legacy API | `syncBundledAssessmentSets` / `uploadAllBundledSets` **cannot** overwrite v1 IDs |

If gates fail while write requested → continues as **dry-run**, `docsWritten=0`, `writesPerformed=false`.

---

## 7. Exact command / UI path for Phase 3O-A3B (real publish)

**Do not run in A3A.** For the approved publish phase only:

1. Debug build with dart-define:
   ```bash
   flutter run --dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true
   ```
2. Call (debug/console or temporary debug-only invocation — **not** a production button):
   ```dart
   await UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2(
     dryRun: false,
     confirmationPhrase: 'SYNC_LOCALIZED_ASSESSMENT_SETS',
   );
   ```
3. Confirm report: `mode: write`, `docsWritten: 150`, `firestoreWritesPerformed: true`, IDs all `*_v2`.

**Confirmation phrase (exact):** `SYNC_LOCALIZED_ASSESSMENT_SETS`

---

## 8. Rollback / disable strategy

| Action | Effect |
|--------|--------|
| Set `active: false` on published `*_v2` docs | Assignment skips inactive Firestore sets |
| App fallback | `AssessmentSetService`: Firestore → bundled `assets/data/assessment_sets/*_sets.json` → last-resort legacy |
| Do not delete v1 blindly | v2 publish does not remove v1; keep backup before any later archive |
| Revert dart-define | Disable further writes; does not undo already-written docs |

---

## 9. Risk checklist

| Risk | Status / mitigation |
|------|---------------------|
| Overwrite legacy set IDs | Mitigated — v2 IDs only; legacy write disabled |
| Touch users / chats / matches | Mitigated — collection scoped to `assessment_sets` |
| Accidental production write | Mitigated — multi-gate + no prod button |
| Partial publish | Merge per doc; re-run can complete missing `*_v2` |
| Assignment still on legacy IDs | Verify assignment prefers versioned/active docs after publish (ops check in A3B) |
| Content TR heuristic notes | Accepted for RC1 (documented false positives / idioms) |
| Cold-start compat / scoring | Orthogonal — already on main; publish does not change scoring code |
| Fake percentiles | Not part of publish |

---

## 10. Related docs

- `docs/assessment_content_release_candidate.md`
- `docs/assessment_final_content_audit.md`
- `docs/assessment_rc1_runtime_qa.md`
- `docs/scoring_calibration_distribution_guard.md`
- `docs/compatibility_guard_runtime_qa.md`

---

## 11. Confirmations (this phase)

| Action | Done? |
|--------|------|
| Firestore write | **No** |
| Publish | **No** |
| Assessment JSON edited | **No** |
| Scoring / compatibility weights changed | **No** |
| Runtime behavior changed | **No** |
| Production publish button added | **No** |
| Commit / push | **No** |
| Preflight report | **Yes** — this file |

---

## 12. Recommendation for 3O-A3B

**READY** to proceed to controlled real publish of **150** immutable `assessment_sets/*_v2` docs, using the gated helper call above, after a final in-app **v2 Sync Dry Run** screenshot/log confirmation on a debug device if desired.
