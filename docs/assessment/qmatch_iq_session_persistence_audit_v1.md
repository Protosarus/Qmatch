# QMatch IQ Session Persistence Audit v1

**Phase:** P2C-2A-3
**Date:** 2026-08-09
**Scope:** Existing assessment persistence technologies before adding durable IQ session resume.

---

## Existing persistence technologies

| Technology | Present in repo? | Assessment use |
|------------|------------------|----------------|
| SharedPreferences | **Not used** before this phase (`pubspec` had none; settings screens intentionally avoid it) | None |
| Hive / Isar / sqflite / drift | **No** | — |
| flutter_secure_storage | **No** | — |
| hydrated_bloc / similar | **No** | — |
| Firestore | **Yes** (primary app persistence) | Assessment progress, assignments, completed results |
| In-memory widget state | **Yes** | Live IQ/EQ mid-test answers + index |
| Asset JSON | **Yes** | Question banks / sets |

**Conclusion:** No reusable local durable assessment-draft abstraction existed. Firestore stores **completion / assignment** documents, not mid-test question plans with option order.

---

## Existing reusable abstractions

| Abstraction | Role | Reusable for P2C-2A-3? |
|-------------|------|------------------------|
| `AssessmentProgressService` | Firestore module status (iq/eq/frequency) | **No** — completion routing only |
| `CanonicalAssessmentPersistence` | Result write path | **No** — scores/results |
| `AssessmentSetService` | Assigns fixed 10-item sets | **No** — legacy selection |
| `QuestionService` | Loads live IQ questions | **No** — must remain unchanged |
| `IqSessionComposer` / plan models | Offline compose (P2C-2A-2) | **Yes** — plan blob source |
| Auth UID (`FirebaseAuth.currentUser.uid`) | Account identity | **Yes** — storage namespace only |

---

## Current IQ progress persistence

- **Firestore:** `users/{uid}` mirrors + `users/{uid}/assessments/iq` + assignment docs.
- **What is stored:** completion flags / status / assignment set id — **not** per-question mid-test answers.
- **Live UI:** `IQTestScreen` keeps `_currentQuestionIndex` and answers in **widget memory** only.

## Current answer persistence

- Mid-test IQ answers: **memory only** (lost on kill / leave).
- On IQ complete: legacy score / result written via assessment persistence services.
- No durable “draft session with 25 item IDs + option order” document today.

## Legacy IQ resume

| Question | Answer |
|----------|--------|
| Does legacy IQ resume mid-test after kill? | **No** |
| Does Firestore restore exact question order? | **No** (set assignment may persist, but UI does not restore answers/index) |
| Canonical 25-session resume | **Did not exist** before P2C-2A-3 |

## Local storage UID namespacing

- Prior local assessment draft storage: **none**.
- P2C-2A-3 keys: `qmatch.iq_session.v1.active.{uid}` and `qmatch.iq_session.v1.session.{uid}.{sessionId}`.
- Keys use **Firebase Auth UID**, never email/phone/display name.

## Account switching / logout

| Behavior | Finding |
|----------|---------|
| Could account switch expose another user’s draft? | **Mitigated** by UID-scoped keys; load requires matching `owner_uid`. |
| Does `AuthService.signOut` clear local prefs? | **No** — logout only calls Firebase `signOut`. Owner-scoped drafts **remain on device** under the prior UID key. |
| Isolation policy | Drafts are **isolated by UID**, not wiped on logout. Explicit `clearOwnerSessions(uid)` exists for a later caller. |

## Firestore schema suitability for this phase

| Need | Existing schema? |
|------|------------------|
| 25 item IDs + displayed option order | **No** |
| Mid-test answers by option id | **No** |
| Bank / selection-policy version binding | **No** |
| Suitable without new collection? | **No** for exact resume |

**Decision:** Do **not** introduce a production Firestore collection in P2C-2A-3. Use **local SharedPreferences** (new lightweight dependency) for durable on-device resume. Cloud sync deferred.

---

## Storage decision (summary)

1. Prefer reuse → none suitable for local drafts.
2. Prefer existing package → SharedPreferences was not in pubspec.
3. Add lightweight `shared_preferences` → **selected**.
4. No large DB package. No new Firestore schema.
