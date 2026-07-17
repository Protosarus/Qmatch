# Assessment scripts

Architecture standard (Phase 3A):

- [`docs/assessment_data_architecture.md`](../docs/assessment_data_architecture.md)

| Script | Purpose |
|--------|---------|
| `generate_iq_sets_50.py` | Generate IQ assessment sets JSON |
| `generate_eq_sets_50.py` | Generate EQ assessment sets JSON |
| `generate_frequency_sets_50.py` | Generate Frequency assessment sets JSON |
| `validate_assessment_sets.py` | Validate set counts, IDs (legacy + versioned), scoring, localization (Phase 2E / 3B) |
| `audit_assessment_firestore_sync.py` | Dry-run audit of what would sync to Firestore (Phase 2P) |
| `export_assessment_sets_v2.py` | Export localized legacy assets → local versioned v2 JSON (Phase 3D) |

## Validate assessment sets

```bash
python3 scripts/validate_assessment_sets.py
```

Exits `0` on PASS, non-zero on FAIL. Does not modify JSON.

Supports:

- **Legacy IDs** (current assets): `iq_set_001`, `eq_set_001`, `frequency_set_001`
- **Versioned IDs** (future publish): `iq_set_001_v2`, … with `base_id`, integer
  `version`, `status`, `active`, `language_mode`

Current bundled assets remain **legacy** schema. Versioned v2 conversion/upload
is a **separate approved phase**.

Validate a local v2 export folder (after export):

```bash
python3 scripts/validate_assessment_sets.py --from-dir build/assessment_sets_v2
```

## Export versioned v2 assessment docs (Phase 3D)

```bash
python3 scripts/export_assessment_sets_v2.py
```

Converts localized legacy assets into immutable versioned docs locally:

- `iq_set_001` → `iq_set_001_v2` (+ `base_id`, integer `version`, `status`, …)
- Output under `build/assessment_sets_v2/` (generated; covered by `/build/` gitignore)
- Does **not** modify original `assets/data/assessment_sets/*.json`
- Does **not** write to Firestore
- Does **not** add files to app assets

Actual Firestore sync/upload of v2 docs is a **separate approved phase**.

## Dry-run Firestore sync audit

```bash
python3 scripts/audit_assessment_firestore_sync.py
```

Prints what would be uploaded to `assessment_sets/{setId}` based on the
localized asset JSON files.

Important:

- This audit script does **not** connect to Firestore.
- It does **not** write to Firestore.
- It does **not** require Firebase credentials.
- Actual sync/upload must be a **separate approved phase**.

## Read-only Firestore preflight compare (Phase 2R / 2S)

Flutter helper:
`lib/features/debug/helpers/assessment_sets_preflight_helper.dart`

```dart
await AssessmentSetsPreflightHelper.compareBundledAssetsWithFirestore();
```

Debug-only UI (Phase 2S):

- Screen: `lib/features/debug/screens/assessment_admin_screen.dart`
- Hub: `lib/features/debug/debug_home_screen.dart`
- Debug routes (registered only when `kDebugMode`): `/debug`, `/debug/assessment-admin`
- Settings → **Debug** tile appears only in debug builds

From Assessment Admin (debug only):

- **Run Firestore Preflight Compare** — reads Firestore only
- **Run v2 Sync Dry Run** — local in-memory v2 conversion report; no writes

Important:

- Preflight **reads** Firestore only.
- v2 Sync Dry Run does **not** write, upload, seed, delete, or batch-write.
- Assessment Admin has **no** sync/write/upload/delete/seed button.
- Debug-only (`kDebugMode`); not visible in release/profile navigation.
- Actual sync/upload remains a **separate approved phase**.

## Flutter sync helper (versioned v2 — Phase 2Q / 3E)

Helper: `lib/features/debug/helpers/upload_assessment_sets_helper.dart`

**Preferred path:** convert bundled legacy assets → immutable `*_v2` docs **in memory**
(same rules as `export_assessment_sets_v2.py`). Does **not** read `build/`.

- Collection: `assessment_sets`
- Document IDs: `iq_set_001_v2`, `eq_set_001_v2`, …
- Mode: `set(..., merge: true)` when write gates pass
- **Default:** dry-run (no Firestore writes)
- Does **not** delete/archive v1 docs
- Legacy in-place sync of `iq_set_001` is **not** recommended and **cannot write**

### Versioned v2 dry-run (default)

```dart
await UploadAssessmentSetsHelper.dryRunVersionedV2AssessmentSync();
// or:
await UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2(dryRun: true);
```

Logs: 150 docs, 50/50/50, 1600 questions, version 2, status published,
language_mode localized, target `*_v2` IDs, and:

`DRY RUN ONLY — no Firestore writes performed`

Local Python export (optional parallel artifact):

```bash
python3 scripts/export_assessment_sets_v2.py
```

### Future real v2 sync (separate approved phase only)

Requires **all** of:

1. Debug build (`kDebugMode`) — release/profile never write
2. Dart-define enabled:

```bash
flutter run --dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true
```

3. Explicit write intent + confirmation phrase:

```dart
await UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2(
  dryRun: false,
  confirmationPhrase: 'SYNC_LOCALIZED_ASSESSMENT_SETS',
);
```

Do not call write mode until a later explicitly approved sync phase.
Legacy `syncBundledAssessmentSets` remains dry-run-only and will not overwrite v1 IDs.
