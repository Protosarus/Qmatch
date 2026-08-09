# QMatch Firebase Security Gap Audit v1

Phase: **P2C-0** · Read-only · No deploy · No Firestore writes

---

## Inventory

| surface | in app? | in repo as deployable artifact? | status |
|---------|---------|----------------------------------|--------|
| Firebase Auth | yes (`main.dart`, `AuthService`) | config via `firebase_options.dart` | RUNTIME_WIRED_UNVERIFIED |
| Firestore | yes (many services) | **no** `firestore.rules` | BLOCKED |
| Storage | yes (`PhotoUploadService`) | **no** `storage.rules` | BLOCKED |
| Cloud Functions | no tree found | n/a | NOT_STARTED |
| FCM | no SDK | n/a | NOT_STARTED |
| App Check | no SDK | n/a | NOT_STARTED |
| Analytics | no SDK | Console product may exist empty | NOT_STARTED |
| Crashlytics | no SDK | Console “Add SDK” per docs | NOT_STARTED |
| Indexes | queries avoid composites | **no** `firestore.indexes.json` | NOT_STARTED |
| Environment separation | single `DefaultFirebaseOptions` | unknown multi-env | UNKNOWN |

Rules drafts only (explicitly NOT_DEPLOYED):

- `docs/firestore_rules_current_snapshot_NOT_DEPLOYED.rules`
- `docs/firestore_rules_candidate_account_deletion_NOT_DEPLOYED.rules`

---

## Collections referenced in code (`firestore_paths.dart` + services)

| collection / path | writers (client) | risk notes |
|-------------------|------------------|------------|
| `users/{uid}` | Auth/Profile/Assessment | Must prevent spoofing of `discover_eligible`, scores |
| `users/{uid}/swipes/{target}` | SwipeService | Client-writable social graph |
| `users/{uid}/blocks/{id}` | SafetyService | OK if owner-only |
| `users/{uid}/assessments/*` | CanonicalAssessmentPersistence | Derived scores must not be freely editable by peers |
| `users/{uid}/assessment_assignments/*` | AssessmentSetService | Assignment integrity |
| `matches/{id}` | MatchService | Transactional create; rules must enforce participants |
| `threads/{id}` / `messages` | ChatService / MatchService | Participant-only |
| `reports/{id}` | SafetyService | Append-oriented |
| `account_deletion_requests/{uid}` | AccountDeletionRequestService | Soft request only |
| `assessment_sets/*`, `questions/*` | debug/upload helpers | Admin publish path — must not be world-writable |

---

## Security blockers

| ID | issue | severity |
|----|-------|----------|
| FS-1 | No versioned Firestore rules in repo → cannot audit/deploy from source of truth | blocker |
| FS-2 | No Storage rules in repo for `profile_photos/{uid}` | blocker |
| FS-3 | Client may be able to write derived fields (`discover_eligible`, assessment scores) depending on live Console rules (unknown here) | critical / UNKNOWN live |
| FS-4 | No App Check → automated abuse of Auth/Firestore/Storage | high |
| FS-5 | Account deletion does not purge Auth/Storage/messages | blocker for compliance |
| FS-6 | Reverse-block not enforced server-side (Discover TODO) | high |
| FS-7 | Debug upload helpers exist for assessment sets — must remain non-production | high |

**Firebase security blockers (blocker severity): 3** (FS-1, FS-2, FS-5)  
plus critical/unknown live rules posture (FS-3).

---

## What this audit did **not** do

- Did not read production Console rules live  
- Did not deploy or write data  
- Did not penetration-test  

Treat live project rules as **UNKNOWN** until exported into the repo and reviewed.
