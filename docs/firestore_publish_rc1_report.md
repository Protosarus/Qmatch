# Firestore Publish RC1 Report (Phase 3O-A3D Verification)

**Publish completed:** 2026-07-18T07:21:39.638071+00:00 (UTC)  
**Verification completed:** 2026-07-18 (Phase 3O-A3D, read-only)  
**Project:** `qmatch-53d62`  
**Mode this phase:** Read-only verification — **no Firestore writes**, no re-publish, no commit/push

---

## 1. Publish summary (from Admin SDK result file)

Source: `build/firestore_admin_publish_rc1_result.json`

| Field | Value |
|-------|--------|
| SDK | Python `firebase-admin` (`python_firebase_admin`) |
| `mode` | `write` |
| `targetCollection` | `assessment_sets` |
| `dryRun` | `false` |
| `confirmationAccepted` | `true` |
| `credentialsConfigured` | `true` |
| `docsConsidered` | **150** |
| `docsWritten` | **150** |
| `writesPerformed` | **true** |
| `versionedIdCount` | **150** |
| `errors` | `[]` |
| First doc | `iq_set_001_v2` |
| Last doc | `frequency_set_050_v2` |
| Source payload | `build/assessment_sets_v2/all_assessment_sets_v2.json` |

User approval context: Admin SDK publish after client `permission-denied`; confirmation phrase `SYNC_LOCALIZED_ASSESSMENT_SETS`.

---

## 2. Post-publish Firestore read verification

**Method:** Admin SDK credentials via env (path outside repo). **Reads only** `assessment_sets` (+ existence probe on `questions`). Artifact: `build/firestore_publish_rc1_verify_readonly.json`.

| Check | Result |
|-------|--------|
| Overall `ok` | **true** |
| Total `assessment_sets` docs | **150** |
| `*_v2` docs | **150** |
| IQ `*_v2` | **50** |
| EQ `*_v2` | **50** |
| Frequency `*_v2` | **50** |
| Every ID ends with `_v2` | **Yes** |
| `version == 2` | **Yes** (all 150) |
| `active == true` | **Yes** (all 150) |
| `status == published` | **Yes** (all 150) |
| `language_mode == localized` | **Yes** (all 150) |
| Missing expected IDs | **None** |
| Extra unexpected `*_v2` IDs | **None** |
| Non-`*_v2` docs in `assessment_sets` | **0** |
| `writesPerformedThisStep` | **false** |

First / last verified: `iq_set_001_v2` … `frequency_set_050_v2`.

### Unexpected docs from this publish?

- **No non-v2 `assessment_sets` docs** present (collection currently contains only the 150 RC1 `*_v2` docs).  
- Publish did not create unexpected extra `*_v2` IDs.

### User data / other collections

| Collection | Touched by RC1 Admin publish? |
|------------|-------------------------------|
| `users` | **No** (script targets only `assessment_sets`) |
| `messages` / `matches` / `profiles` | **No** |
| `questions` | **No write** from publish script. Read probe shows the collection **has at least one pre-existing doc** — not evidence of RC1 authorship; RC1 publisher never writes `questions`. |

---

## 3. Result-file field checklist (Task 2)

| Field | Expected | Observed |
|-------|----------|----------|
| `mode` | `write` | `write` |
| `targetCollection` | `assessment_sets` | `assessment_sets` |
| `dryRun` | `false` | `false` |
| `confirmationAccepted` | `true` | `true` |
| `credentialsConfigured` | `true` | `true` |
| `docsConsidered` | `150` | `150` |
| `docsWritten` | `150` | `150` |
| `writesPerformed` | `true` | `true` |
| `versionedIdCount` | `150` | `150` |
| `errors` | `[]` | `[]` |

---

## 4. Rollback / disable strategy

| Action | Effect |
|--------|--------|
| Set `active: false` on published `*_v2` docs | Assignment skips inactive Firestore sets |
| App fallback | `AssessmentSetService`: Firestore → bundled `assets/data/assessment_sets/*_sets.json` |
| Prefer deactivate over delete | Keeps audit trail; v1 path was not used by this publish |
| Revoke service account key | Stops further Admin publishes |

---

## 5. Next runtime QA steps

1. **Reset** current debug user assessment state (assignment reset helper — current user only).  
2. Start a **new** assessment (IQ → EQ → Frequency as applicable).  
3. Confirm logs: `source=firestore_assessment_sets` (not only `bundled_assets`).  
4. Confirm localization: `languageCode=tr/en`, `resolvedFrom=tr/en`.  
5. Test on **Turkish** device locale.  
6. Test on **English** device locale.  
7. Optional: Discover / Frequency vector mirror still works after assessment complete.

---

## 6. Confirmations (Phase 3O-A3D)

| Action | Status |
|--------|--------|
| Firestore write this phase | **No** |
| Re-publish | **No** |
| Assessment JSON edited | **No** |
| Scoring / compatibility changed | **No** |
| Commit / push | **No** |
| Report | **Yes** — this file |
