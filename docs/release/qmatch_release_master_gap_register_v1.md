# QMatch Release Master Gap Register v1

Phase: **P2C-1A** (updates) · base HEAD `4bbd6cb`  
Companion: `qmatch_full_runtime_integration_audit_v1.md` · identity/rules docs in `docs/release/`

Severity: `blocker` | `critical` | `high` | `medium` | `low`  
Release-blocking: yes/no

---

## Gap table

| gap ID | subsystem | description | evidence | status | severity | dependency | files | recommended phase | acceptance criteria | release blocking |
|--------|-----------|-------------|----------|--------|----------|------------|-------|-------------------|---------------------|------------------|
| G-001 | packaging | Android applicationId still `com.example.qmatch` | Prior: example id. **P2C-1A:** `applicationId`/`namespace`/`MainActivity` → `com.qmatch.app`. Remaining: Play listing + signing + Android Firebase JSON still example package | PARTIAL — source aligned; store/Firebase external | blocker | Play Console + Firebase Android app for `com.qmatch.app` | `android/app/build.gradle.kts`, MainActivity path | P2C-1A done source; P2C-1B/ops for store | applicationId `com.qmatch.app` in source ✅; signed Play upload + matching `google-services.json` open | yes (external) |
| G-002 | packaging | iOS/Android bundle ID mismatch | **P2C-1A:** both Runner + Android source use `com.qmatch.app`. Android Firebase JSON still `com.example.qmatch` | RESOLVED_IN_SOURCE — Firebase Android config still mismatched | blocker | G-001 Firebase Android registration | gradle + pbxproj | P2C-1A | Source IDs aligned ✅; Android Firebase package match open | yes (Firebase Android config) |
| G-003 | firebase | No deployable `firestore.rules` in repo | **P2C-1A:** `firestore.rules` created + referenced by `firebase.json`. Not deployed. Runtime conflicts with client `discover_eligible`/score writes | IMPLEMENTED_IN_REPO_NOT_DEPLOYED | blocker | deploy + conflict resolution (trusted backend) | `firestore.rules` | P2C-1A source; deploy later | Rules reviewed/tested locally; production deploy + CF for eligibility open | yes |
| G-004 | firebase | No deployable `storage.rules` in repo | **P2C-1A:** `storage.rules` created (owner write, image types, 5MiB). Conflicts if `putFile` omits contentType | IMPLEMENTED_IN_REPO_NOT_DEPLOYED | blocker | deploy + PhotoUploadService contentType | `storage.rules` | P2C-1A | Ownership/size/type enforced in source; deploy open | yes |
| G-005 | firebase | No `firestore.indexes.json` | **P2C-1A:** `firestore.indexes.json` present (empty composites — only single-field queries evidenced) | IMPLEMENTED_IN_REPO | high | add composites when proven | `firestore.indexes.json` | P2C-1A | Source of truth exists; no speculative composites | no* (single-field OK) |
| G-006 | cm_v2 | Zero production imports of CM v2 services | ripgrep outside `domain/core_method_v2` | IMPLEMENTED_OFFLINE | blocker | matching product claim | `lib/features/assessment/domain/core_method_v2/*` | P2C-3 | Discover/match calls aggregation with real snapshots | yes |
| G-007 | cm_v2 | CM v2 assets not in pubspec | `pubspec.yaml` assets omit `core_method_v2/` | IMPLEMENTED_OFFLINE | critical | G-006 | `pubspec.yaml` | P2C-3 | Required configs loadable at runtime | yes |
| G-008 | discover | Ranking uses legacy CompatibilityScoring | `discover_service.dart` + `compatibility_scoring.dart` | LEGACY_ACTIVE | blocker | G-006 | those files | P2C-3 | Ranking uses approved engine; legacy path gated | yes |
| G-009 | discover | looking_for / age_range / distance unused | profile fields present; Discover ignores | NOT_STARTED | critical | product filters | `discover_service.dart`, `user_profile_model.dart` | P2C-2 | Filters applied server and/or client with tests | yes |
| G-010 | banks | No 340-question IQ **runtime** bank | **P2C-2A-1:** content **FOUND_RECOVERABLE**; `iq_bank_tr_v1.json` **IMPLEMENTED_OFFLINE** (not pubspec / not loader-wired). Runtime still legacy 10-item | IMPLEMENTED_OFFLINE (runtime NOT_STARTED) | blocker | assessment quality claim | `iq_bank_tr_v1.json`, `docs/source/assessment/iq/` | P2C-2A-2+ | Approved IQ bank runtime JSON + pubspec + session composer | yes |
| G-011 | banks | Users see legacy 10/10/12 sets | `AssessmentSetService` + screens | LEGACY_ACTIVE | blocker | G-010/G-012 | `assessment_set_service.dart`, `*_sets.json` | P2C-2 | Production loads approved banks only | yes |
| G-012 | banks | Dynamic IQ 25-session composer absent | blueprint only; live = fixed set | DESIGNED_ONLY / NOT_STARTED | blocker | G-010 offline bank now available | docs blueprint; no SessionComposer | P2C-2A-2 | 7/6/6/6 + ≤1 family/session production-called | yes |
| G-013 | banks | IQ/EQ/Freq v3 pilots not runtime | not in pubspec; freeze `runtime_loaded:false` | IMPLEMENTED_OFFLINE | critical | G-011 | `assets/data/assessment_v3/*` | P2C-2 | Pilots either promoted with wiring or explicitly non-prod | yes |
| G-014 | scoring | TraitScoring→Canonical adapter planned_not_wired | `trait_scoring_adapter_plan.dart` | DESIGNED_ONLY | blocker | 20D profile | that file + screens | P2C-2 | Live answers → TraitScoring → CanonicalUserAssessmentProfile persisted | yes |
| G-015 | scoring | TraitScoringService unused by screens | no screen imports | IMPLEMENTED_OFFLINE | blocker | G-014 | `trait_scoring_service.dart` | P2C-2 | Called on assessment completion | yes |
| G-016 | prefs | PartnerPreferenceProfile not user-editable | no screens; offline contracts | NOT_STARTED | blocker | CM v2 preference fit | `partner_preference_*` | P2C-3 | User can set range/similarity/open; persisted | yes |
| G-017 | values | Relationship values UI absent | offline registry/services only | NOT_STARTED | blocker | CM v2 values | `relationship_value_*` | P2C-3 | Values collected + persisted + permissioned | yes |
| G-018 | hard | Hard constraints UI absent | offline only | NOT_STARTED | blocker | CM v2 hard gate | `hard_constraint*` | P2C-3 | User can enable constraints; failed blocks ranking | yes |
| G-019 | auth | Google Sign-In not implemented | empty stubs; no package use in lib | NOT_STARTED | critical | store UX | `social_login_screen.dart`, pubspec | P2C-1 auth | Working Google auth or remove store claim | yes |
| G-020 | auth | Apple Sign-In not implemented | same | NOT_STARTED | critical | iOS guideline | same | P2C-1 auth | Working Apple auth if social offered | yes |
| G-021 | auth | Password reset absent | no API/UI | NOT_STARTED | high | email accounts | — | P2C-1 auth | Reset email flow works | yes |
| G-022 | auth | Email signup unreachable from Welcome | orphaned signup screens | BLOCKED | high | account creation | `welcome_screen.dart`, signup screens | P2C-1 auth | Clear path to create email account | yes |
| G-023 | auth | Account deletion is request-only | service comments; no wipe | RUNTIME_WIRED_UNVERIFIED | blocker | store compliance | `account_deletion_request_service.dart` | P2C-1 deletion | Full deletion of Auth+data within policy SLA | yes |
| G-024 | notifications | No FCM SDK | pubspec/lib absent; Console notes | NOT_STARTED | high | engagement | — | P2C-4 | Tokens + match/message push | no* |
| G-025 | observability | No Crashlytics SDK | pubspec/docs | NOT_STARTED | high | release ops | — | P2C-1 | Crashes reported in production | yes |
| G-026 | assessment | Mid-session answer resume absent | UI resets on reopen | NOT_STARTED | high | UX | test screens | P2C-2 | Resume restores answers | no |
| G-027 | discover | Photo not required to enter Discover tab | AuthWrapper→Main without photo; eligibility separate | RUNTIME_WIRED_UNVERIFIED | medium | G-009 | `auth_wrapper.dart`, eligibility | P2C-2 | Consistent gate or empty-state CTA | no |
| G-028 | discover | Reverse-block not server-enforced | TODO in discover_service | RUNTIME_WIRED_UNVERIFIED | high | safety | `discover_service.dart` | P2C-2 | Blocked-by cannot appear | yes |
| G-029 | match | `getMyMatchesStream` orphaned | defined; no UI caller | IMPLEMENTED_OFFLINE | medium | UX | `match_service.dart` | P2C-2 | Matches surface in UI or remove | no |
| G-030 | persona | PersonaScoring not runtime; archetype still matching | EQ skips persona; Discover uses archetype | DUPLICATED / LEGACY_ACTIVE | high | product semantics | persona domain; compatibility_scoring | P2C-3 | Persona explanation-only; not ranking input unless decided | yes |
| G-031 | cm_v2 | Registry namespace mismatch aggregation/values | P2B-6 harness shim required | IMPLEMENTED_OFFLINE | critical | G-006 | aggregation + value registry versions | P2C-3 | Production resolves namespace without silent invalidation | yes |
| G-032 | firebase | App Check absent | **P2C-1A:** plan only `docs/release/qmatch_app_check_integration_plan_v1.md`; SDK still absent | NOT_STARTED (plan written) | high | Console + SDK | plan doc | P2C-1 later | Providers + enforce on device | yes |
| G-033 | subscriptions | No IAP | no billing packages | NOT_STARTED | medium | monetization | docs strategy only | P2C-5 or defer | Explicit v1 decision: ship free or implement | yes if paid v1 |
| G-034 | legacy | Orphaned auth/onboarding screens | no importers | LEGACY_ACTIVE | medium | cleanup | auth screens list in audit | P2C-6 | Removed or reconnected | no |
| G-035 | messaging | No push for new messages | no FCM | NOT_STARTED | medium | G-024 | chat_service | P2C-4 | Optional for soft launch | no* |
| G-036 | legal | Privacy/Terms are launch drafts | l10n + legal_static_site | DESIGNED_ONLY / RUNTIME_WIRED_UNVERIFIED | high | counsel | l10n, `docs/legal_*` | P2C-1 | Counsel-approved + hosted URLs | yes |
| G-037 | assessment | Firestore assessment_sets content unverified | remote primary path | UNKNOWN | high | G-011 | `assessment_set_service.dart` | P2C-2 | Documented remote content = intended banks | yes |
| G-038 | riverpod | No real DI providers | ProviderScope empty | NOT_STARTED | low | architecture | `main.dart` | later | Optional | no |
| G-039 | reveal | Reveal feature unwired | `lib/features/reveal` | IMPLEMENTED_OFFLINE | low | product | reveal/* | defer | Ship or remove | no |
| G-040 | test_targets | iOS RunnerTests bundle still `com.example.qmatch.RunnerTests` | **P2C-1A:** renamed to `com.qmatch.app.RunnerTests` | RESOLVED | low | none | pbxproj | P2C-1A | Renamed ✅ | no |
| G-041 | discover_ui | Discover candidate card still presents **legacy** CompatibilityScoring label/score/reasons and archetype/category chips as if they were final product signals | P2C-1C-2 visual migration + P2C-1C-2A goldens intentionally show these fields when runtime model supplies them; CM v2 has zero production calls (G-006/G-008) | LEGACY_ACTIVE | blocker | G-006, G-008, G-030 | `qmatch_candidate_card.dart`, `discover_service.dart`, CompatibilityScoring | P2C-3 | Replace or remove legacy compat/archetype presentation when CM v2 is production-wired; do not treat current chips as calibrated CM output | yes |
| G-042 | messaging | Messages inbox + chat-detail **visually** migrated but messaging is **not** end-to-end release verified; push absent; message-list pagination absent; spam/rate limits absent; reverse-block enforcement incomplete; counterpart profile is a client user-doc read; deleted-user/account-deletion cleanup gaps remain | P2C-1C-3A/3B presentation audit; G-024/G-035; `ChatService` streams/writes unchanged | RUNTIME_WIRED_UNVERIFIED | high | G-024, G-003 | `messages_screen.dart`, `chat_detail_screen.dart`, `chat_service.dart` | P2C-4 / security | E2E messaging QA + push decision + pagination decision + hardened public profile reads | yes |
| G-043 | build | Golden-test Inter/Playfair stand-in TTFs remain registered under `test/fonts/google_fonts/` in production `pubspec.yaml` asset bundle (offline google_fonts for goldens) | Font audit P2C-1C-3B; moved off `assets/google_fonts/` | DESIGNED_ONLY / TRACKED | low | bundle size | `pubspec.yaml`, `test/fonts/google_fonts/` | later | Prefer test-only asset loading that does not ship in release IPA | no |
| G-044 | identity | Display-name moderation/profanity filter absent | P2C-1C-4A validator rejects contact-like values only | NOT_STARTED | medium | safety | `display_name_validator.dart` | later | Optional moderation service | no |
| G-045 | identity | Legacy Auth `displayName` / empty Firestore `name` values remain; no bulk migration script | P2C-1C-4A gate + prefill; canonical writes to `users.name` | RUNTIME_WIRED_UNVERIFIED | medium | G-044 | AuthService phone bootstrap; DisplayNameService | later | Confirm existing users in simulator; remove Auth-as-identity assumptions | yes for soft launch QA |
| G-046 | profile | Profile Edit (display-name change after onboarding) not shipped | P2C-1C-4A contract supports later edit; only photo edit wired | NOT_STARTED | medium | G-045 | profile screens | P2C-1C-4B+ | Wire edit using DisplayNameService | no |
| G-047 | identity | Android + production/manual existing-user display-name verification deferred | P2C-1C-4A code-complete; SDK absent | NOT_STARTED | medium | Android SDK | — | device QA | Manual pass on iOS with empty-name account | yes |
| G-048 | identity | Firestore rules mocha suite not executed on this host (Java runtime missing; Temurin install requires sudo) | Rules cases exist in `tool/firebase_rules_tests` | BLOCKED_LOCAL | medium | Java 17+ | `tool/firebase_rules_tests` | host tooling | Run `npm test` once Java available | yes for soft launch |
| G-049 | profile | Canonical CM v2 persona not shown on Profile; legacy `archetype`/`category` intentionally omitted in P2C-1C-4B | Audit v1; CM v2 not production-wired | NOT_STARTED | medium | G-006, G-008 | profile presentation | P2C-3 | Show documented CM v2 persona only when runtime field exists | no |
| G-050 | profile | Profile visual migration + shared cosmic background code-complete; live iOS Profile visual/scroll/background sign-off not performed, including 8-second breathing observation | P2C-1C-4B/5/5B goldens + contact sheets + phase tests | RUNTIME_WIRED_UNVERIFIED | medium | device QA | `test/goldens/profile/`, `cosmic_background/` | device QA | Human pass vs goldens on simulator; confirm subtle live breathing | yes |
| G-051 | settings | Settings presentation migrated; Notifications/Privacy destinations remain local-MVP (no FCM / no Firestore preference writes); destination screens visually migrated in P2C-1C-5B but live iOS Settings/destination sign-off open | P2C-1C-5/5B audits + goldens | RUNTIME_WIRED_UNVERIFIED | medium | FCM product decision; device QA | `settings_screen.dart`, notifications/privacy screens | later / device QA | Persist prefs or remove claim; human visual pass on root + pushed routes | yes for soft launch QA |
| G-052 | profile_photos | Profile Photo Management presentation migrated; shared header/primary action added in P2C-1C-5B; live permission/upload/delete/reorder and breathing QA open; no photo moderation | P2C-1C-5/5B audit + goldens | RUNTIME_WIRED_UNVERIFIED | medium | device QA; G-004 storage deploy | `profile_photo_edit_screen.dart`, PhotoUploadService | device QA | Human pass on simulator with real camera/gallery; confirm no duplicate upload taps | yes |
| G-053 | banks | IQ canonical 340 recovered offline; not runtime | **P2C-2A-1:** DOCX→JSON conversion complete; validators pass; distribution **100/80/80/80** (not 85×4). Runtime/pubspec still absent | IMPLEMENTED_OFFLINE | blocker | G-010 | `assets/data/assessment_v3/iq/iq_bank_tr_v1.json` | P2C-2A-2 | Runtime loader + 7/6/6/6 composer + review gates | yes |
| G-054 | banks | Turkish IQ content review incomplete | recovered bank `review_status=desk_reviewed_candidate` only; expert/language sign-off absent | NOT_STARTED | critical | G-053 | recovered bank + pilots | P2C-2A | Language review signed | yes |
| G-055 | banks | Expert IQ content review incomplete | red-team ≠ expert sign-off; recovered bank not expert-reviewed | NOT_STARTED | critical | G-054 | review docs | P2C-2A | Expert review state recorded | yes |
| G-056 | banks | IQ empirical difficulty calibration absent | recovered bank intentionally omits fabricated difficulty/IRT; pilot bands editorial only | NOT_STARTED | high | pilot/empirical data | quality standard | P2C-2B | Empirical estimates replace editorial | no* |
| G-057 | banks | IQ item exposure control absent | no runtime exposure ledger | NOT_STARTED | high | G-012 | session composer | P2C-2 | Overexposure monitored | yes |
| G-058 | banks | Legacy→canonical IQ migration path absent | compatibility doc forbids silent import; recovered bank is separate offline source | NOT_STARTED | blocker | G-010/G-011 | legacy compatibility doc | P2C-2 | Migration without silent `numerical` remap | yes |
| G-059 | banks | Android verification of future IQ v3 session | Android deferred | NOT_STARTED | medium | G-012 wiring | devices | P2C-2 / Android | Android session parity verified | yes |

\*May be non-blocking for a tightly scoped soft launch if product explicitly accepts no push.

---

## Derived counts

| severity | count |
|----------|------:|
| blocker | 17 |
| critical | 6 |
| high | 13 |
| medium | 7 |
| low | 4 |
| **total gaps listed** | **50** |

| release_blocking = yes | count |
|-------------------------|------:|
| yes | 37 |
| no / conditional | 9 |

**Total release blockers (severity=blocker): 17**  
**Total critical gaps: 6**

Note: Some blockers are conditional on product claims (e.g. G-006 if CM v2 is required for v1 marketing). Treat as blocking unless product explicitly ships legacy-only matching with disclosed limitations.

---

## P2C-1C-2A Discover visual verification note

- Deterministic goldens under `test/goldens/discover/` verify presentation states without Firebase.
- **G-041** records that legacy compatibility/archetype UI on Discover is release-blocking relative to any CM v2 product claim.
- Live device visual pass remains separate from golden baselines.

---

## P2C-1C-3A Messages inbox note

- Inbox presentation migrated; chat-detail deferred to P2C-1C-3B.
- Deterministic goldens under `test/goldens/messages/`.
- **G-042** records messaging not release-ready despite visual migration.

---

## P2C-1C-5 Settings / Photos / cosmic note

- Settings + Profile Photo Management presentation migrated; shared `QMatchCosmicBackground` on Profile / Settings / Photos only (not Chat Detail).
- Deterministic goldens under `test/goldens/settings/`, `profile_photos/`, `cosmic_background/`.
- **G-051** / **G-052** / extended **G-050**: live iOS visual + permission sign-off open; Notifications/Privacy not server-backed; Android deferred.
- Do **not** mark Settings/Photos/Profile release-ready from goldens alone.

---

## P2C-1A gap change log

| gap | prior status | new status | evidence | remaining external dependency | release-blocking | acceptance still open |
|-----|--------------|------------|----------|-------------------------------|------------------|----------------------|
| G-001 | BLOCKED | PARTIAL — source aligned | gradle + MainActivity `com.qmatch.app` | Play listing, signing, Android `google-services.json` for `com.qmatch.app` | yes | matching Firebase Android config + signed store binary |
| G-002 | BLOCKED | RESOLVED_IN_SOURCE | Android+iOS source ids both `com.qmatch.app` | Android Firebase package registration | yes (config) | Firebase Android package == `com.qmatch.app` |
| G-003 | BLOCKED | IMPLEMENTED_IN_REPO_NOT_DEPLOYED | `firestore.rules` + `firebase.json` | deploy; backend for eligibility/scores | yes | production deploy + conflict fixes |
| G-004 | BLOCKED | IMPLEMENTED_IN_REPO_NOT_DEPLOYED | `storage.rules` | deploy; upload contentType | yes | production deploy + upload metadata fix |
| G-005 | NOT_STARTED | IMPLEMENTED_IN_REPO | empty composite index file (evidence-based) | future composite queries | conditional | add when query evidence requires |
| G-032 | NOT_STARTED | NOT_STARTED (plan written) | App Check plan doc | Console + SDK + devices | yes | enforcement verified |
| G-040 | LEGACY_ACTIVE | RESOLVED | RunnerTests → `com.qmatch.app.RunnerTests` | none | no | none |
