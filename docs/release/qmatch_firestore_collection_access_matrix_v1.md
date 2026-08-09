# QMatch Firestore Collection Access Matrix v1

Phase: **P2C-1A** · Evidence from `lib/**` callers only.  
No inferred Cloud Functions / Admin SDK behavior (none proven in repo).

Canonical path helpers: `lib/core/utils/firestore_paths.dart`.

---

## Collection / path inventory

### `users/{uid}`

| field | value |
|-------|-------|
| path pattern | `users/{uid}` |
| read caller | `AuthService`, `ProfileService`, `DiscoverService`, `AssessmentProgressService`, chat/match UIs via profile loads, `AccountDeletionRequestService` |
| create caller | `AuthService` (signup / ensure user doc) |
| update caller | `AuthService`, `ProfileService`, `AssessmentProgressService`, `FrequencyService`, `AccountDeletionRequestService` (soft markers) |
| delete caller | none in client |
| ownership | doc id == Auth uid |
| counterpart access | Discover reads other users where `discover_eligible == true`; matched peers need profile fields for chat |
| admin-only expectation | moderation / wipe not client |
| sensitive fields | phone/email mirrors, assessment score mirrors, photos URLs, preferences |
| derived fields | `discover_eligible`, `iq_score`, `eq_score`, frequency mirrors, persona/archetype mirrors |
| current rule requirement | authenticated; get limited to owner / discover-eligible / matched peer; owner create/update with protected derived keys immutable after create |
| unknown behavior | live Console rules unknown; no Admin wipe pipeline in repo |

### `users/{uid}/assessment_assignments/{type}`

| field | value |
|-------|-------|
| path pattern | `users/{uid}/assessment_assignments/{iq\|eq\|frequency}` |
| read/create/update | `AssessmentSetService`, progress helpers |
| delete | none proven |
| ownership | owner only |
| counterpart access | none |
| sensitive | assigned set ids |
| rule requirement | owner read/write |
| unknown | remote set content quality |

### `users/{uid}/assessments/{docId}`

| field | value |
|-------|-------|
| path pattern | `users/{uid}/assessments/{iq\|eq\|frequency\|persona…}` |
| read/write | `FrequencyService`, `CanonicalAssessmentPersistence`, `AssessmentProgressService`, Discover (own frequency hydrate only) |
| ownership | owner only |
| counterpart access | **must be denied** (private answers / evidence / confidence) |
| sensitive | answers, vectors, confidence, evidence internals |
| rule requirement | owner only; no public/peer read |
| unknown | future CM v2 snapshot docs — **not created in rules this phase** |

### `users/{uid}/swipes/{targetUid}`

| field | value |
|-------|-------|
| callers | `SwipeService` write; `MatchService` reads reverse swipe; Discover uses swipe id set |
| ownership | writer = path uid |
| counterpart access | target may read reverse swipe for mutual-like |
| rule requirement | owner write; owner or target read |
| unknown | pass/like retention policy |

### `users/{uid}/blocks/{blockedUid}`

| field | value |
|-------|-------|
| callers | `SafetyService`, `BlockedUsersScreen` (`orderBy created_at`) |
| ownership | owner only |
| counterpart access | none (reverse-block not server-enforced — product gap G-028) |
| rule requirement | owner read/write/delete |
| unknown | whether blocked user can detect block |

### `matches/{matchId}`

| field | value |
|-------|-------|
| path pattern | deterministic `{minUid}_{maxUid}` |
| create | `MatchService.createMatchIfMutualLike` (client transaction) |
| read | `MatchService`, `RevealService`, `SafetyService` |
| update | block/reveal flows |
| delete | none |
| ownership | `users` array membership |
| counterpart access | both members |
| sensitive / derived | `compat` map (client currently writes empty); reveal consent |
| rule requirement | create only if mutual likes + deterministic id + member; members read/update; protect `compat` mutation; no arbitrary create |
| unknown | server-side match creation (preferred) — **not present** |

### `threads/{threadId}` + `threads/{threadId}/messages/{messageId}`

| field | value |
|-------|-------|
| create thread/message | `MatchService` (system message); `ChatService.sendTextMessage` |
| read | `ChatService` (`participants` arrayContains; messages `orderBy client_created_at`) |
| update | chat unread / last message; safety close |
| ownership | `participants` |
| rule requirement | members only; message create sender==auth or system bootstrap; participants immutable |
| unknown | moderation pipeline |

### `reports/{reportId}`

| field | value |
|-------|-------|
| create | `SafetyService.reportUser` |
| read/update/delete | **no client readers** |
| ownership | `reporter_uid == auth.uid` on create |
| rule requirement | create only; deny client read/update/delete |
| unknown | admin triage tooling |

### `account_deletion_requests/{uid}`

| field | value |
|-------|-------|
| create/update/read | `AccountDeletionRequestService` |
| delete | none |
| ownership | doc id == auth uid |
| rule requirement | owner read/create/update while `status == requested`; no client status escalation to completed |
| unknown | ops wipe SLA (G-023) |

### `assessment_sets/{setId}`

| field | value |
|-------|-------|
| read | `AssessmentSetService` (`where type ==`) |
| write | debug helpers exist in repo — **must not be allowed for normal clients** |
| rule requirement | authenticated read; deny write |
| unknown | production bank contents vs legacy (G-037) |

### `questions/{docId}` (legacy)

| field | value |
|-------|-------|
| read | legacy fallback in `AssessmentSetService` |
| write | deny |
| rule requirement | authenticated read; deny write |

---

## Queries with index evidence

| query | evidence | composite index needed? |
|-------|----------|-------------------------|
| `users.where('discover_eligible' == true).limit(n)` | `discover_service.dart` | No (single-field) |
| `threads.where('participants' arrayContains uid)` | `chat_service.dart` | No (single-field) |
| `matches.where('users' arrayContains uid)` | `match_service.dart` | No (single-field) |
| `messages.orderBy('client_created_at')` | `chat_service.dart` | No (single-field on subcollection) |
| `assessment_sets.where('type' == …)` | `assessment_set_service.dart` | No (single-field) |
| `questions.where('type' == …)` | legacy path | No (single-field) |
| `blocks.orderBy('created_at')` | `blocked_users_screen.dart` | No (single-field) |

`firestore.indexes.json` ships with empty `indexes` array because **no composite query evidence** was found. Add composites only when a proven query requires them.

---

## Core Method v2 (deferred — P2C-4 / P2C-6)

CM v2 is **not** runtime-wired. Do **not** invent production collections for it in this phase.

Later security requirements:

- Private trait/persona/evidence docs must remain owner-only (or server-only).
- Compatibility aggregation outputs must not be client-writable as authoritative ranking truth.
- Preference / values / hard-constraint profiles need ownership + field allowlists.
- Discover eligibility should move to trusted backend evaluation.

---

## Rule vs runtime conflicts (summary)

See final P2C-1A report section **S**. Highest impact: client writes to `discover_eligible` / score mirrors conflict with protected-field rules until a backend owns eligibility.
