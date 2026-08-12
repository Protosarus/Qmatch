# QMatch Live Match Lifecycle Audit v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_live_match_lifecycle_audit_v1` |
| Status | `audit_only_not_live_change` |
| Scope | **Production path only.** Discover → like/pass → mutual match → thread → Messages. No code changes in this doc. |
| Out of scope | Matching scores/ranking, Persona, RVI, temporal, QI, L3 soft prefs, Stage B shadow collectors |
| Primary code | `DiscoverScreen`, `DiscoverService`, `SwipeService`, `MatchService`, `ChatService`, `SafetyService`, `firestore.rules`, `FirestorePaths` |
| Audit date | 2026-08-12 |

---

## A. Current flow (end-to-end)

```
DiscoverScreen._loadCandidates
  → DiscoverService.getCandidates
       → users where discover_eligible == true
       → exclude self / already-swiped / L1 blocks / L1 account gates
       → CompatibilityScoring (live rank) + optional shadow diagnostics
  → local deck (_candidates / _currentIndex)

DiscoverScreen._onPass / _onLike  (UI serializes via _isActionLoading)
  → SwipeService.passUser(target)  OR  SwipeService.likeUser(target)
       → set users/{me}/swipes/{target}
            { from_uid, target_uid, direction: pass|like, source: discover, created_at }
            SetOptions(merge: true)   // NOT inside the match transaction
  → (like only) MatchService.createMatchIfMutualLike(target)
       → matchId = threadId = sorted(uidA, uidB) joined by '_'
       → runTransaction:
            1. if matches/{matchId} exists → return true   // no state check
            2. if reverse swipe users/{target}/swipes/{me}.direction != 'like' → return false
            3. tx.set matches/{matchId}  (state=active, thread_id, users, empty compat, reveal defaults)
            4. tx.set threads/{threadId} (merge:true, status=active, preview "You matched!")
            5. tx.set threads/{threadId}/messages/{autoId}  (system "You matched!")
            → return true

Discover UI on like:
  → if matched==true → showQMatchDiscoverMatchDialog (Continue → pop only)
  → _advance() to next card
  → does NOT navigate to ChatDetailScreen / Messages tab

Messages entry (separate surface):
  → MessagesScreen ← ChatService.getMyThreadsStream
       (participants arrayContains me, status == active)
  → ChatDetailScreen(threadId)
       → getMessagesStream / sendTextMessage
       → optional unmatch / block / report
```

### ID consistency (as implemented)

| Entity | ID formula | Notes |
| --- | --- | --- |
| Match | `FirestorePaths.deterministicMatchId` = `minUid_maxUid` | Doc id must equal `user_a_user_b` (rules enforce) |
| Thread | `deterministicThreadId` = **same string** as match id | MVP mirror; `match.thread_id` / `thread.match_id` both set |
| System message | auto-id from `.doc()` **before** `runTransaction` | Stable across retries of the **same** client call |

### Navigation after mutual match

- **Production today:** dialog → Continue → stay on Discover, advance deck.
- **Not production today:** deep-link into the new thread, FCM “It’s a match”, or tab switch to Messages.

---

## B. Invariants that are already safe

1. **Deterministic pair IDs** — one match/thread doc per unordered pair; no random match IDs on the happy path.
2. **Duplicate match create (same pair, first-time)** — transaction reads `matches/{id}`; if exists, returns `true` without a second create. Concurrent creators conflict on the same read → Firestore retries → loser sees existence.
3. **Mutual-like gate in client transaction** — reverse swipe must be `direction == 'like'` before create.
4. **Rules gate on match create** — `mutualLikeForMatchCreate()` + `matchUsersValid(matchId)` + creator must be in `users` (size 2).
5. **Swipe doc identity** — one doc per `(from, target)`; Discover excludes by swipe **doc id**, so re-showing the same person after any swipe is prevented on the next load.
6. **UI double-tap on one device** — `_isActionLoading` blocks concurrent like/pass from Discover for the current card.
7. **Self-swipe / self-match** — client throws; match rules also require two distinct users in practice via sorted pair + membership.
8. **Unmatch / block close path (when IDs passed)** — `MatchService.unmatch` sets match `unmatched` + thread `closed`; `SafetyService.blockUser` can set match `blocked` + thread `closed`.
9. **Messages list filters closed threads** — `ChatService.getMyThreadsStream` keeps `status == active` only; closed chat send paths reject.
10. **Match `compat` mutation** — rules forbid clients from changing `compat` / `compatibility` after create (empty map written at create only).

---

## C. Bugs / risks

| ID | Severity | Issue | Evidence |
| --- | --- | --- | --- |
| L-01 | **High** | **Rematch after unmatch/block is broken / misleading.** `createMatchIfMutualLike` returns `true` whenever the match **doc exists**, regardless of `state`. It does not reactivate `active`, does not reopen a closed thread, and does not refuse cleanly. UI can show “It’s a match” while Messages still hides a closed thread. | `match_service.dart` early `if (matchSnap.exists) return true;` |
| L-02 | **High** | **No block check on like or match create.** Discover L1 excludes blocks at fetch time only. `SwipeService.likeUser` / `MatchService.createMatchIfMutualLike` never read `users/*/blocks/*`. Mutual likes can still create an active match/thread after a block (or with a pre-existing reverse like). | `swipe_service.dart`, `match_service.dart`, `discover_service.dart` |
| L-03 | **Med** | **Like write is outside the match transaction (TOCTOU).** Order is: write own swipe → then transaction. First liker’s mutual check correctly returns false; concurrent second liker usually creates the match. Rare races are mostly OK for **data**, but the **first** client never learns a later match was created (no listener). | `SwipeService.likeUser` then `createMatchIfMutualLike` |
| L-04 | **Med** | **Like → pass after match does not unwind the match.** Swipe merge overwrites `direction` to `pass`; match/thread stay active. Social graph says “passed” while chat remains open. | `passUser` merge; no match teardown |
| L-05 | **Med** | **Stale / deleted / ineligible targets not validated at like time.** No check that target user exists, `active`, `discover_eligible`, or still has photo. Match can be created against a ghost profile if reverse like exists. | `likeUser` / transaction |
| L-06 | **Low–Med** | **Match dialog false negative for the first liker** (by design of return value). Second liker gets the dialog. Simultaneous likes usually both get `true` after retries. No Messages deep-link either way. | `DiscoverScreen._onLike` |
| L-07 | **Low** | **Swipe `created_at` rewritten on every merge** — retries/re-likes lose original timestamp; analytics/idempotency of “first swipe time” unreliable. | `SetOptions(merge: true)` + always `created_at: serverTimestamp` |
| L-08 | **Low** | **System “You matched!” message id is client auto-id**; content is fine under one winner transaction, but rules also allow **any participant** to create further `sender_id: 'system'` messages (spoof). | `firestore.rules` messages create |

---

## D. Data consistency risks

1. **Match state vs thread status drift**
   - Unmatch / block update match and thread in separate writes (unmatch: two sequential sets; block: one batch — better).
   - Partial failure on unmatch can leave match `unmatched` with thread still `active` (or the reverse if ordering changes later).

2. **Rematch / existence semantics (L-01)**
   - Matches are **never deleted** (`allow delete: if false`).
   - Existence ≠ “active match”. Client and `isMatchedWith()` in rules both treat existence as matched for some reads.

3. **Thread `SetOptions(merge: true)` on create**
   - Rematch path (if create ran again) would merge into an old closed thread rather than minting a new id (ids are deterministic anyway). Combined with L-01, reactivation is inconsistent.

4. **Swipe direction vs match lifecycle**
   - Swipes are append-only in rules (`delete: false`) but **direction is mutable**.
   - Pass-after-like and rematch scenarios can leave likes/passes out of sync with match `state`.

5. **Unread / counters**
   - System match message does not increment `unread_counts` (both stay 0). Harmless for MVP; Messages preview shows “You matched!” from thread fields.

6. **Discover deck vs server**
   - After like/pass, UI advances locally; exclusion is only guaranteed on **next** `getCandidates` via swipe collection. Mid-session deck can still hold already-acted cards if index doesn’t advance correctly (advance is local-only — OK for current card).

7. **`isMatchedWith(otherUid)` (rules)**
   - `exists(matches/{sortedPair})` only — **ignores** `state`. Unmatched/blocked pairs may still grant peer `users/{uid}` get via “matched peers” path.

---

## E. Security-rule risks / assumptions

| Assumption in rules | Production reality | Risk |
| --- | --- | --- |
| Match create requires mutual likes + deterministic id | Client transaction does the same | **OK** for first-time create; does not encode `state==active` |
| Thread create = participant + sorted id | **Does not require** match existence or mutual likes | **Gap:** colluding clients can create a chat thread without a match if they agree on sorted participant ids |
| Message create: `sender_id == auth.uid` OR system type | Any **participant** may write `sender_id: 'system'` | **Spoof** system messages |
| Swipe write: owner only; target may read | No schema validation on `direction` / immutability | Mutable like↔pass; no server block gate |
| Blocks: owner-only read/write | Reverse-block is **client-enforced** in Discover only | Match create bypasses blocks (L-02) |
| Match update: members; freeze users; block compat edits | Broad other field updates allowed | Client can set arbitrary `state` / reveal fields within membership |
| `isMatchedWith` for user get | Existence only | Peer profile readable after unmatch/block until docs are purged (never purged) |
| Match/thread delete denied | Soft-close only | Correct for audit trail; forces rematch logic to handle existing docs (currently doesn’t) |

**Not assumed / not present:** Cloud Functions for match creation, App Check enforcement in this audit, FCM match fanout, server-side eligibility at swipe time.

---

## F. Exact next implementation step

**Status (2026-08-12):** Implemented as `match_create_lifecycle_v1` in
`MatchCreateLifecycleGate` + `MatchService.createMatchIfMutualLike`
(active idempotent; unmatched no-reactivate; blocked/unknown refuse;
either-direction block refuse; mutual likes required for new create).

**Follow-ups (not this harden):** Messages deep-link after match; fold swipe
write into the same transaction; Cloud Function ownership for match bootstrap
(optional); ops deploy of updated `firestore.rules`.

---

## Trace checklist (requested)

| Check | Verdict |
| --- | --- |
| Duplicate likes | Same swipe doc merge; direction overwritten; match create idempotent if match already **exists** |
| Duplicate match creation | Safe for first-time via deterministic id + transaction |
| Retry / idempotency | Swipe rewrite + match exists→true works for **active** first match; broken for rematch (L-01) |
| Near-simultaneous mutual likes | Transaction resolves single match; both clients typically get `true` |
| Match/thread ID consistency | Same sorted-pair string; linked fields set |
| Firestore transaction/batch safety | Match+thread+system message atomic on create; swipe write **not** in tx; unmatch not batched |
| Blocked users after a like | Discover filters at fetch; like/match **do not** re-check (L-02) |
| Stale/deleted users | Not validated at like/match (L-05) |
| Navigation after mutual match | Dialog only; no chat route |
| Security-rule assumptions | Mutual-like match create OK; thread-without-match + system spoof + existence-as-matched gaps |

---

## Security-rule follow-up (harden v1 — 2026-08-12)

Implemented in `firestore.rules`:

- Match **read** requires `state == active` (existence alone insufficient).
- Match **create** requires mutual likes, `state == active`, `thread_id == matchId`, and **no blocks** either direction.
- Match **update** may leave `active` → `unmatched`/`blocked` but **cannot** rematch to `active`.
- Thread **create** requires corresponding **active** match with mirrored id + sorted participants + no blocks.
- Thread **update** cannot reopen (`status=active`) unless match is active.
- Messages: normal creates require `sender_id == auth.uid` + `type == text` + active thread + active match; system bootstrap only at fixed id `system_match_v1`.

### Remaining match.state vs thread.status drift (accepted)

**Close path (2026-08-12 `match_close_lifecycle_v1`):** `MatchService.unmatch` and
`SafetyService.blockUser` now close match + thread in **one Firestore transaction**
(block doc included on block). Idempotent when already closed; never reactivates.
Missing thread → match still closes. Rules allow `unmatched → blocked` (not rematch).

**Like path (2026-08-12 `like_match_atomicity_v1`):** `SwipeService.likeUser` →
`MatchService.likeAndMaybeCreateMatch` writes the viewer Like **inside** the same
transaction that reads reverse Like, both blocks, and match state, then optionally
creates match/thread/`system_match_v1`. Pass remains swipe-only (never closes match).

**Still accepted residual:** If a legacy client writes only one of the two docs, or a
write is rejected mid-flight by rules/membership edge cases, drift can still appear
until the next successful close retry. Message create still requires both active
match and active thread. Pass-after-Like can leave swipe=`pass` while match stays
active (by design — Pass must not mutate match).

---

## Changelog

| Version | Date | Notes |
| --- | --- | --- |
| v1 | 2026-08-12 | Production-path audit only; no code changes |
| v1.1 | 2026-08-12 | Noted `match_create_lifecycle_v1` harden (unmatched refuse, blocks, mutual likes) |
| v1.2 | 2026-08-12 | Firestore rules harden v1 + remaining state/status drift documented |
| v1.3 | 2026-08-12 | Atomic match/thread close lifecycle (`match_close_lifecycle_v1`) |
| v1.4 | 2026-08-12 | Atomic Like→match evaluation (`like_match_atomicity_v1`) |
