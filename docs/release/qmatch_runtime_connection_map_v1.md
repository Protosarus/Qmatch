# QMatch Runtime Connection Map v1

Phase: **P2C-0** · Evidence from repository static analysis only.

Legend: solid = runtime call observed in `lib/` feature path · dashed = offline/domain only · × = missing.

---

## 1. App boot

```
main.dart
  → Firebase.initializeApp(DefaultFirebaseOptions)
  → ProviderScope (no app providers)
  → MaterialApp(home: AuthWrapper)
       → authStateChanges
            → WelcomeScreen | AssessmentProgressService.resolveForUid
                 → IQ / EQ / Frequency / ProfileSetup / MainNavigation
```

---

## 2. Assessment → persistence (current)

```
IQTestScreen → QuestionService.loadIQAssessment
            → AssessmentSetService.getOrAssignSet('iq')
                 → Firestore assessment_sets | assets assessment_sets | legacy
            → on complete: mark assignment + CanonicalAssessmentPersistence
                         + AssessmentProgressService.markIqCompleted

EQTestScreen  (same pattern for 'eq')
FrequencyTestScreen → FrequencyService.loadAssignedFrequencyAssessment
                    → FrequencyService save + flow complete

× TraitScoringService (not called)
× CanonicalUserAssessmentProfile adapter (planned_not_wired)
× PersonaScoringService (not called from screens)
```

---

## 3. Matching (current vs intended)

### Current (`structural_l2_v1`)

```
DiscoverScreen
  → DiscoverService.getCandidates
       → users where discover_eligible==true
       → L1: filter swipes/blocks/active/photo/assessments
       → trusted backend compareStageB2Structural
            (canonical 20D IQ/EQ/Frequency structural distance)
       → DiscoverStructuralL2Ranking (smaller distance first; no %)

Rollback only (`legacy_v1`):
       → CompatibilityScoring.calculateCompatibility / compareDiscoverCandidates
            (Frequency vector, type/tag, archetype, IQ/EQ bands, interests, recency)

× Core Method v2 services
× PartnerPreferenceProfile
× RelationshipValueProfile
× HardConstraintEvaluation
× Persona / archetype as Matching keys
× L3 / L4 / L5 ranking
  (Discover L3 v1 = post-L2 diagnostics only; not a ranker)
  (L4 v1 = post-match cadence diagnostics only; not a ranker)
  (L5 v1 = mixed-state QI validated research shadow; not a ranker)
```

### Intended CM v2 (IMPLEMENTED_OFFLINE only)

```
CanonicalUserAssessmentProfile
  + PartnerPreferenceProfile
  + RelationshipValueProfile
  + HardConstraints
       → StructuralSimilarityService
       → DirectionalPreferenceFitService
       → RelationshipValueComparisonService
       → HardConstraintEvaluationService
       → SoftConflictEvaluationService
       → CoreMethodV2AggregationService
       → StructuredCompatibilityExplanationService
            → Discover ranking / explanations

(Current production path does not invoke this chain.)
```

---

## 4. Social graph

```
DiscoverScreen like/pass
  → SwipeService → users/{uid}/swipes/{target}
  → MatchService.createMatchIfMutualLike (transaction)
       → matches/{a_b}, threads/{a_b}, system message

MessagesScreen → ChatService.getMyThreadsStream
ChatDetailScreen → getMessagesStream / sendTextMessage
                 → SafetyService report/block
                 → MatchService.unmatch

× FCM notification fanout
```

---

## 5. Profile / eligibility

```
ProfileSetupScreen → ProfileService (profile_completed)
PhotoUploadService → Storage profile_photos/{uid}/…
AuthService / ProfileService.refreshDiscoverEligibility
  → discover_eligible = active ∧ assessments ∧ profile_completed ∧ hasPhoto

Gap: Main/Discover tab reachable before hasPhoto; eligibility is separate.
```

---

## 6. Production CM v2 import matrix

| Service | Imported by Discover? | Imported by screens? | Called with user data? |
|---------|----------------------|----------------------|------------------------|
| StructuralSimilarityService | no | no | no |
| DirectionalPreferenceFitService | no | no | no |
| RelationshipValueComparisonService | no | no | no |
| HardConstraintEvaluationService | no | no | no |
| SoftConflictEvaluationService | no | no | no |
| CoreMethodV2AggregationService | no | no | no |
| StructuredCompatibilityExplanationService | no | no | no |

**Production CM v2 service calls: 0**  
**Missing CM v2 connections: 7 services + Discover + persistence + UI + pubspec assets**
