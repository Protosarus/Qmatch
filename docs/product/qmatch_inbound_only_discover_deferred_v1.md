# Discover inbound-only filter — implementation plan (deferred)

**Status:** Deferred — production behavior unchanged.  
**Date:** 2026-08-23  
**Roadmap:** PHASE 6

## Intent

Optional Discover mode where the swipe deck is seeded only from users who already liked / Super-Resonated the viewer (“inbound-only”), without changing compatibility scoring.

## Why this is blocked for a safe production ship

1. **Monetization / trust boundary**  
   Ordinary inbound identities are Resonance-gated via Alignment Signals (`listWhoLikedYou`). Putting the same identities into Free Discover would either give away paid value or leave Free users with an empty deck.

2. **Duplicate product surface**  
   Alignment Signals (`Uyum Sinyalleri`) already is inbound discovery with Like/Pass. Merging into Discover needs an explicit product RFC (which surface owns the action?).

3. **No trusted Discover seed API**  
   Live Discover loads `discover_eligible` (+ Passport) on the client, then ranks via `compareStageB2Structural`. Clients cannot efficiently collectionGroup-query inbound likes. Inbound-only needs a trusted callable returning a UID list with the same safety filters as `shouldIncludeLiker`.

4. **Matching constraints freeze**  
   Prefs must not mutate `discover_eligible`. Inbound-only is a new L1 *pool seed strategy* and requires an additive RFC to `qmatch_matching_constraints_contract_v1.md`.

5. **Empty-deck / cold-start**  
   New users with zero inbound likes would see a permanent empty Discover unless fallback rules are defined (and those rules must not silently change eligibility for existing users).

6. **Backward-compatible default**  
   Existing users must default to current outbound / worldwide Discover. Any new preference must be opt-in with a safe default.

## Safe default (current production)

- Discover remains outbound `discover_eligible` (+ optional Passport geo).
- Inbound remains Alignment Signals + Super Resonance inbox only.
- No new preference field written.

## Implementation plan (when product RFC is approved)

1. **Product RFC** covering Free vs Resonance, Discover vs Alignment Signals ownership, empty-deck UX, Passport ∩ inbound interaction.
2. **Preference schema** e.g. `users/{uid}/preferences/discover_feed_mode_v1` with `mode: outbound | inbound_only`, default `outbound`, Admin/callable writes only.
3. **Trusted callable** `listDiscoverInboundCandidates` (or extend existing inbox) returning UIDs + public cards, reusing `shouldIncludeLiker` + reverse-block rules.
4. **Client** alternate seed path in `DiscoverService` when mode is inbound-only; still run L2 ranking unchanged.
5. **Tests** CF parity with `list_who_liked_you_callable.test.js`; Flutter mode toggle + empty state; rules tests for the pref doc.
6. **Rollout** feature-flag / Resonance-only first; never flip existing users without opt-in.

## Explicit non-goals for this phase

- No scoring formula changes.
- No silent eligibility changes for existing users.
- No client-side weakening of Firestore rules to enumerate inbound swipes.
