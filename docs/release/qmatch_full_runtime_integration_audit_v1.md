# QMatch Full Runtime Integration Audit v1

Phase: **P2C-0**  
Date: 2026-07-26  
Branch: `main`  
HEAD: `4bbd6cbfe93c7f10fbbcaf868c81c07f2f67a4b0`  
Mode: **Read-only evidence audit** (no feature implementation)

**Prior Cursor/phase reports are not accepted as proof.** Statuses below are from
direct repository inspection only. Nothing is marked `END_TO_END_VERIFIED` or
`RELEASE_READY` without live E2E proof in this audit (no device/Firebase E2E
run was performed).

---

## Repository WIP snapshot (preserved)

Tracked modifications (unrelated / in-progress): auth, assessment screens,
Discover, profile, `compatibility_scoring`, `pubspec.yaml`, etc.  
Large untracked WIP: `assets/data/assessment_v3/`, `assets/data/core_method_v2/`,
`lib/features/assessment/domain/`, many tests/tools/docs.  
**Not modified, deleted, staged, committed, or pushed by this phase.**

---

## Status legend

| Status | Meaning |
|--------|---------|
| NOT_STARTED | No meaningful implementation |
| DESIGNED_ONLY | Docs/plans/contracts only |
| IMPLEMENTED_OFFLINE | Code/tests/CLI; not production-wired |
| RUNTIME_WIRED_UNVERIFIED | Imported/called in app path; no E2E proof here |
| END_TO_END_VERIFIED | Proven in real app flow (not claimed in this audit) |
| RELEASE_READY | All complete conditions met (not claimed) |
| BLOCKED | Cannot proceed without resolving a hard gap |
| LEGACY_ACTIVE | Old path still serves users |
| DUPLICATED | Parallel old/new implementations |
| UNKNOWN | Insufficient evidence |

---

## 1. App entry and routing

| Item | Evidence | Status |
|------|----------|--------|
| Entry | `lib/main.dart` — `Firebase.initializeApp` + `ProviderScope` + `AuthWrapper` | RUNTIME_WIRED_UNVERIFIED |
| Riverpod providers | `ProviderScope` only; no app `Provider`/`ConsumerWidget` usage under `lib/` | NOT_STARTED |
| go_router | Absent | NOT_STARTED |
| Named routes | Debug-only `/debug`, `/debug/assessment-admin` when `kDebugMode` | RUNTIME_WIRED_UNVERIFIED (debug) |
| Session gate | `lib/core/navigation/auth_wrapper.dart` — `authStateChanges` → assessment progress destination | RUNTIME_WIRED_UNVERIFIED |

### Production route graph (imperative)

```
WelcomeScreen
  ├─ PhoneSignupScreen → AuthWrapper
  └─ LoginScreen (email/password) → AuthWrapper
AuthWrapper (authenticated)
  ├─ IQTestIntroScreen → IQTestScreen → …
  ├─ EQTestIntroScreen → EQTestScreen → …
  ├─ FrequencyIntroScreen → FrequencyTestScreen → AssessmentFlowCompleteScreen
  ├─ ProfileSetupScreen
  └─ MainNavigationScreen
        ├─ DiscoverScreen
        ├─ MessagesScreen → ChatDetailScreen
        └─ ProfileScreen → Photos / Settings → …
```

### Orphaned / unreachable from Welcome

`SocialLoginScreen`, `SignupScreen`, `EmailSignupScreen`, `EmailVerificationScreen`,
`VerificationScreen`, `NameSelectionScreen`, `MainAppScreen` (“coming soon”),
empty `eq_test_screen_temp.dart`, Reveal feature (no screen wiring).

---

## 2. Authentication

| Capability | Evidence | Status |
|------------|----------|--------|
| Phone SMS | `AuthService.startPhoneVerification` / `verifySmsCode`; `PhoneSignupScreen` | RUNTIME_WIRED_UNVERIFIED |
| Email login | `LoginScreen` → `signInWithEmailAndPassword` | RUNTIME_WIRED_UNVERIFIED |
| Email signup (prod Welcome) | Signup screens orphaned; Welcome has no signup CTA | BLOCKED / LEGACY_ACTIVE |
| Google Sign-In | `google_sign_in` in pubspec; **zero** `lib/` imports; empty `onPressed` stubs | NOT_STARTED |
| Apple Sign-In | `sign_in_with_apple` in pubspec; **zero** `lib/` imports | NOT_STARTED |
| Password reset | No `sendPasswordResetEmail` / UI | NOT_STARTED |
| Sign-out | `AuthService.signOut`; Settings | RUNTIME_WIRED_UNVERIFIED |
| Session restore | Firebase Auth persistence + `authStateChanges` | RUNTIME_WIRED_UNVERIFIED |
| Account deletion | Request doc only (`account_deletion_request_service.dart`); does **not** wipe Auth/Storage/messages | RUNTIME_WIRED_UNVERIFIED |
| Email verification gate | Screen exists but unreachable; AuthWrapper does not enforce | LEGACY_ACTIVE |

---

## 3–5. Question banks, dynamic selection, assessment screens

See `qmatch_question_bank_inventory_v1.md`.

**Users currently see:** legacy `assessment_sets` (or Firestore override) —
typically **10 IQ / 10 EQ / 12 Frequency** per assigned set via
`AssessmentSetService` → `QuestionService` / `FrequencyService`.

| Topic | Status |
|-------|--------|
| Final 340-question IQ runtime JSON | **NOT_STARTED** (artifact absent; plan docs cite 150–240) |
| IQ 25-pilot runtime | IMPLEMENTED_OFFLINE (`assessment_v3/…`; not in pubspec; freeze `runtime_loaded: false`) |
| EQ review candidate 1 runtime | IMPLEMENTED_OFFLINE |
| Frequency review candidate 1 runtime | IMPLEMENTED_OFFLINE |
| Dynamic 7/6/6/6 IQ session composer | DESIGNED_ONLY |
| Mid-session answer resume | NOT_STARTED |
| Module progress / assignment resume | RUNTIME_WIRED_UNVERIFIED |
| Assessment screens reachable | RUNTIME_WIRED_UNVERIFIED |

---

## 6. Trait scoring and 20D profile

| Layer | Evidence | Status |
|-------|----------|--------|
| `TraitScoringService` | Domain pure service; not imported by screens | IMPLEMENTED_OFFLINE |
| Adapter → `CanonicalUserAssessmentProfile` | `trait_scoring_adapter_plan.dart`: `planned_not_wired`, `productionWired=false` | DESIGNED_ONLY |
| Live persistence | `CanonicalAssessmentPersistence` writes assessment docs on completion | RUNTIME_WIRED_UNVERIFIED |
| Live scoring shown to users | Live Discover does **not** show a compatibility %. Assessment totals / Frequency vectors may still appear on own-profile surfaces | LEGACY_ACTIVE (profile/assessment display, not Discover rank) |

---

## 7. Persona

| Topic | Status |
|-------|--------|
| Canonical persona scoring engine | IMPLEMENTED_OFFLINE (`PersonaScoringService`) |
| Runtime invoke from assessments/Discover | NOT_STARTED (guards assert non-import) |
| Discover uses coarse `archetype` affinity | **Not live ranking.** Rollback-only inside `CompatibilityScoring` (`legacy_v1`). Persona is not a Matching key |

---

## 8–9. Partner preferences / relationship values / hard constraints

| Topic | Status |
|-------|--------|
| CM v2 models + services | IMPLEMENTED_OFFLINE |
| Production preference/value/hard-constraint screens | NOT_STARTED |
| Profile “preferences” step | LEGACY_ACTIVE (`looking_for`, `age_range`, distance only) |
| Used in Discover ranking | NOT_STARTED |

---

## 10. Core Method v2 production connection

| Service | Prod import outside domain? | Discover? | Status |
|---------|----------------------------|-----------|--------|
| StructuralSimilarityService | No | No | IMPLEMENTED_OFFLINE |
| DirectionalPreferenceFitService | No | No | IMPLEMENTED_OFFLINE |
| RelationshipValueComparisonService | No | No | IMPLEMENTED_OFFLINE |
| HardConstraintEvaluationService | No | No | IMPLEMENTED_OFFLINE |
| SoftConflictEvaluationService | No | No | IMPLEMENTED_OFFLINE |
| CoreMethodV2AggregationService | No | No | IMPLEMENTED_OFFLINE |
| StructuredCompatibilityExplanationService | No | No | IMPLEMENTED_OFFLINE |

CM v2 assets under `assets/data/core_method_v2/` are **not** listed in
`pubspec.yaml` → not Flutter-bundled for production.

**Production Core Method v2 service calls: 0.**  
**Missing connections: all 7 services + Discover + persistence + UI.**

---

## 11–13. Discover / like-pass-match / messaging

| Area | Evidence | Status |
|------|----------|--------|
| Discover load | `discover_eligible == true` query; local filters | RUNTIME_WIRED_UNVERIFIED |
| Discover ranking | Trusted structural L2 (`structural_l2_v1`, canonical 20D). `CompatibilityScoring` is **rollback only** (`legacy_v1`). No live %. Persona/archetype are not Matching keys. L3/L4/L5 not live | RUNTIME_WIRED |
| Age/gender/orientation/distance filters | Profile fields unused in Discover query | NOT_STARTED |
| Pagination cursor | Over-fetch batch only | RUNTIME_WIRED_UNVERIFIED |
| Like/pass | `SwipeService` → `users/{uid}/swipes` | RUNTIME_WIRED_UNVERIFIED |
| Mutual match | `MatchService.createMatchIfMutualLike` transaction | RUNTIME_WIRED_UNVERIFIED |
| Messaging | `ChatService` Firestore snapshots | RUNTIME_WIRED_UNVERIFIED |
| Push on message/match | No FCM SDK | NOT_STARTED |

---

## 14–17. Profile/photos, notifications, safety, subscriptions

| Area | Status |
|------|--------|
| Profile setup + photo upload (Storage) | RUNTIME_WIRED_UNVERIFIED |
| Photo not required to enter Main/Discover tab | Gap vs `discover_eligible` photo requirement |
| FCM / token / push navigation | NOT_STARTED |
| Block / report / blocked list | RUNTIME_WIRED_UNVERIFIED |
| Reverse-block server enforcement | Incomplete (TODO in Discover) |
| Subscriptions / IAP | NOT_STARTED (strategy docs only) |

---

## 18. Firebase / backend

| Item | Status |
|------|--------|
| Auth / Firestore / Storage used in app | RUNTIME_WIRED_UNVERIFIED |
| Deployable `firestore.rules` / `storage.rules` / indexes in repo | **Absent** → BLOCKED for versioned security |
| Rules drafts in `docs/*NOT_DEPLOYED*` | DESIGNED_ONLY |
| App Check / Crashlytics / Analytics / Performance / FCM SDKs | NOT_STARTED (confirmed vs Console notes in docs) |
| Cloud Functions | NOT_STARTED (no functions/ tree found in audit) |

See `qmatch_firebase_security_gap_audit_v1.md`.

---

## 19. Release / store packaging

| Item | Evidence | Status |
|------|----------|--------|
| Android `applicationId` | `com.example.qmatch` (`android/app/build.gradle`) | BLOCKED for store identity |
| Android `namespace` | `com.example.qmatch` | BLOCKED |
| iOS bundle ID | `com.qmatch.app` | RUNTIME_WIRED_UNVERIFIED (ID mismatch vs Android) |
| Version | `pubspec.yaml` `1.0.0+1` | RUNTIME_WIRED_UNVERIFIED |
| Icons / splash | Present (default/launcher assets) | RUNTIME_WIRED_UNVERIFIED |
| In-app Privacy/Terms | Localized draft bodies + `LegalDocumentScreen` | RUNTIME_WIRED_UNVERIFIED |
| Static legal site drafts | `docs/legal_static_site/` | DESIGNED_ONLY (hosting not proven) |
| Support contact | `support@qmatch.site` in copy | DESIGNED_ONLY / unverified ops |
| Store listings / screenshots / Data Safety forms | Docs packs exist | DESIGNED_ONLY |

See `qmatch_release_readiness_scorecard_v1.md`.

---

## 20. Legacy / duplicated paths

| Path | Notes |
|------|-------|
| `assessment_sets` + flat IQ/EQ JSON | Live question path |
| `CompatibilityScoring` vs CM v2 | Parallel matching stacks |
| Archetype strings vs PersonaScoring | Parallel persona concepts |
| Frequency Dart constants vs sets | Fallback duplication |
| Orphaned auth/onboarding screens | Dead UI |
| Reveal feature | Unwired |
| Firestore legacy `questions` collection | Last-resort path |

Do **not** delete in this phase — see gap register for migration requirements.

---

## Absolute release blockers (summary)

1. No production Core Method v2 wiring (if v1 product claim requires it).  
2. Users on legacy 10/10/12 banks; no 340 IQ bank; no dynamic 25-session composer.  
3. Trait→Canonical adapter not wired; 20D CM profile not production.  
4. Partner prefs / values / hard constraints not collectable in UI.  
5. Preference filters unused; L3/L4/L5 not live. Discover ranking is structural L2 (not CompatibilityScoring).  
6. Android package still `com.example.qmatch` (vs iOS `com.qmatch.app`).  
7. No versioned Firestore/Storage rules/indexes in repo.  
8. Account deletion is request-only (not full wipe).  
9. Google/Apple/password-reset/email-signup Welcome path incomplete.  
10. No FCM; no Crashlytics; no subscriptions if required for launch.

Exact gap IDs and severities: `qmatch_release_master_gap_register_v1.md`.
