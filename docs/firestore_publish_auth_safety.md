# Firestore Publish Auth Safety (Phase 3O-A3B-Safety Correction)

**Date:** 2026-07-18  
**Mode:** Safety correction only — **no Firestore writes**, no publish run, no commit/push

---

## What happened

1. Gated client publish (`UploadAssessmentSetsHelper.syncAssessmentSetsVersionedV2`, `dryRun: false`, phrase `SYNC_LOCALIZED_ASSESSMENT_SETS`, dart-define enabled) entered **write mode**.
2. Firestore returned **`permission-denied`** for unauthenticated client writes.
3. Result: **`docsWritten: 0`**, **`writesPerformed: false`** — failure was safe; no RC1 docs published.
4. An **anonymous auth** retry was briefly added to `tool/publish_assessment_rc1_v2.dart`. That path is **not approved** and has been **removed/disabled**.

---

## Why unauthenticated write failed safely

Project security rules rejected writes without a suitable auth context. The helper still only targets `assessment_sets/{id}_v2`, but the client SDK never completed a successful `set`. Zero documents written is the correct outcome when rules deny the caller.

---

## Why anonymous auth is not approved

- Firestore rules are **unknown** in-repo (no `firestore.rules` checked in; rules not audited for this phase).
- Anonymous sign-in may grant **any** anonymous user the same write rights if rules are merely `request.auth != null`.
- That would **not** be an admin-only publish path and could leave assessment content writable by ephemeral clients.
- Anonymous auth must not be used for RC1 publish unless rules are **proven** to restrict assessment set writes to admin UID / custom claim (not currently proven).

---

## Safer publish options (next step — choose one, do not run yet)

### A. Firebase Admin SDK / service account one-shot

- One-shot Node/Python script using a **service account** (bypasses client rules).
- Payload = same 150 `*_v2` docs as `build/assessment_sets_v2/` / helper conversion.
- **Service account key stored outside the repo** (never commit).
- Still write **only** `assessment_sets/{id}_v2`.

### B. Restrict rules + known admin client session

1. Update Firestore rules so `assessment_sets` writes require a **known admin UID** or **custom claim** (e.g. `admin == true`).
2. Sign in as that admin user in a **debug** build (not anonymous).
3. Run existing gated helper:
   - `kDebugMode`
   - `--dart-define=QMATCH_ENABLE_ASSESSMENT_FIRESTORE_SYNC=true`
   - `dryRun: false`
   - `confirmationPhrase: SYNC_LOCALIZED_ASSESSMENT_SETS`
   - collection `assessment_sets`, IDs `*_v2` only

### Tool state after this correction

`tool/publish_assessment_rc1_v2.dart`:

- **No** `signInAnonymously()`
- **Refuses** if `currentUser == null` or `user.isAnonymous`
- Keeps helper gates documented above
- **Does not** auto-publish; must be run only after an approved auth strategy

---

## Recommendation

Prefer **A (Admin SDK)** for a one-time RC1 content publish if ops can supply an out-of-repo service account, **or** **B** if you want the Flutter helper to remain the only writer after rules are locked to admin.

Do **not** retry client publish with anonymous auth.

---

## Confirmation (this correction step)

| Action | Status |
|--------|--------|
| Firestore write | **No** |
| Publish command run | **No** |
| Anonymous auth used | **No** (removed/disabled) |
| Assessment JSON edited | **No** |
| Scoring / compatibility changed | **No** |
| Commit / push | **No** |
