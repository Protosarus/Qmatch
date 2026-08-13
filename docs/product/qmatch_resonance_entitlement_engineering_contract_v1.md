# QMatch Resonance Entitlement Engineering Contract v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_resonance_entitlement_engineering_contract_v1` |
| Status | `resonance_entitlement_engineering_contract_v1` · `engineering_ratified_not_live` |
| Parents | [Membership Contract](./qmatch_monetization_membership_contract_v1.md) · [Launch Packaging](./qmatch_resonance_launch_packaging_v1.md) · [Paywall & Tease UX](./qmatch_resonance_paywall_tease_ux_v1.md) |
| Scope | Entitlement architecture for Free / Resonance + Super Resonance / Boost balances |
| Non-goals | App code, store console setup, final product IDs, prices, ranking/scoring, Persona/RVI/temporal/QI |
| Platforms | iOS + Android **architecture** only — no platform implementation in this step |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

This document is the **ratified** entitlement architecture for how QMatch **grants, caches, restores, expires, and revokes** Resonance subscription entitlements and consumable balances so:

1. Store-verified purchase state is the **source of truth**
2. The **client cannot self-grant** Resonance or consumables
3. Subscription entitlements stay **separate** from consumable ledgers
4. Consumables **never** alter compatibility scores
5. Offline / verification-outage behavior is **safe** (Free loop intact; no forged premium)

**Status meaning:** engineering-ratified contract — binding for entitlement implementation design. **Not live** in app, stores, or backend until an engineering ship.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Source of truth | Backend + store verification — not the client |
| Client | **Never** self-grants Resonance or consumable credits/spends |
| Separation | Subscription state and consumable balances remain separate |
| Access grant | `active` / `grace` / `billing_retry` → Resonance access |
| Access deny | `expired` / `revoked` → deny Resonance immediately |
| `verification_unavailable` | May use **only** a previously trusted cached snapshot within a **future bounded TTL**; **never** extend period locally |
| No trusted cache | Free-safe fallback (deny Resonance; Free loop intact) |
| Restore | Always re-verifies with trusted backend |
| Logout | Clears user-scoped entitlement cache |
| Sensitive features | Server re-checks entitlement / balance |
| Consumable spends | Server-authoritative and idempotent on store/transaction refs |
| Unresolved | Exact cache TTL · product IDs/prices · exact grace mapping · cross-platform/account linking · persistence layout · webhook implementation |

---

## 1. Canonical entitlement state

### 1.1 Subscription tier

| Field | Values |
| --- | --- |
| `tier` | `free` \| `resonance` |

Only two tiers in v1. No Plus / Orbit.

### 1.2 Subscription lifecycle state

Canonical enum `subscription_state`:

| State | Meaning | Feature access (`resonance`) |
| --- | --- | --- |
| `none` | Never subscribed / fully lapsed with no grace | Free only |
| `active` | Verified paid period in good standing | Granted |
| `billing_retry` | Store reports billing retry / account hold (platform-specific) | **Granted** for a bounded retry window (store policy) |
| `grace` | Store grace period after payment failure | **Granted** during grace |
| `expired` | Paid period ended; no grace/retry remaining | Free only |
| `revoked` | Refund, chargeback, revoke, or trust invalidate | Free only **immediately** |
| `verification_unavailable` | Trusted authority unreachable; see §7 | Soft fallback (§7) — **not** a client grant |

Notes:

- `billing_retry` and `grace` are **store-signaled**. Exact platform mapping is deferred (§9) but both are **access-preserving** while the store says so.
- `revoked` always beats cache and always beats optimistic UI.
- Client must never invent `active` / `grace` / `billing_retry` from local flags alone.

### 1.3 Derived access boolean

```
resonance_access =
  subscription_state ∈ { active, grace, billing_retry }
  AND tier == resonance
  AND NOT revoked
```

`verification_unavailable` does **not** set `resonance_access` by itself; see §7 cache rules.

### 1.4 Consumable balances (separate)

| Balance | Type | Mutates compatibility score? |
| --- | --- | --- |
| `super_resonance_balance` | non-negative int | **Never** |
| `boost_spotlight_balance` | non-negative int | **Never** |

Balances are **not** subscription states. Spending decrements ledger only (interest visibility / exposure tools per membership contract).

### 1.5 Conceptual record (trusted store)

Logical shape (field names illustrative — not a mandated Firestore schema yet):

```
EntitlementSnapshot {
  uid
  tier                     // free | resonance
  subscription_state       // none | active | billing_retry | grace | expired | revoked | verification_unavailable
  resonance_access         // derived bool
  period_ends_at           // nullable timestamp
  grace_ends_at            // nullable
  billing_retry_ends_at    // nullable
  last_verified_at
  verification_source      // app_store | play | restore | webhook | admin
  platform                 // ios | android | unknown
  // NO final product_id required in this contract — placeholder slot only
  product_ref              // opaque / deferred
  super_resonance_balance
  boost_spotlight_balance
  schema_version
}
```

---

## 2. Trusted verification authority

### 2.1 Source of truth

| Layer | Role |
| --- | --- |
| **Apple / Google purchase + server verification** | Ultimate purchase truth |
| **QMatch trusted backend** (Cloud Functions or equivalent) | Sole writer of entitlement grants / revokes / balance credits after verify |
| **Client** | Reader + cache + UX gates; **never** writer of `resonance_access = true` |

### 2.2 Hard rule — no client self-grant

Forbidden:

- Writing `tier: resonance` or `isPremium: true` from the app without a trusted backend response
- Trusting StoreKit / Play Billing client callbacks alone as permanent grant
- Unlocking Resonance features from a local “purchase succeeded” UI event without backend confirmation
- Incrementing consumable balances from the client without a verified credit receipt

Allowed on client:

- Optimistic **UI pending** spinner after purchase CTA
- Reading last trusted snapshot from cache
- Presenting Free teasers / unlock sheets per paywall UX contract

### 2.3 Verification paths (architecture)

| Path | When |
| --- | --- |
| Purchase → client sends store payload → backend verifies with App Store Server API / Play Developer API → writes snapshot | New buy |
| Restore → client sends restore payloads / tokens → backend verifies → writes snapshot | Restore |
| Store server notification / RTDN webhook → backend verifies → updates snapshot | Renewal, expire, revoke, refund |
| Admin / support tool (audited) | Rare ops correction — still server-side |

Exact APIs, secrets, and product IDs: **deferred** (§9).

### 2.4 Authority priority

When signals conflict:

1. `revoked` / refund / chargeback from store or trusted webhook  
2. Fresh successful server verification  
3. Cached snapshot within TTL (§3)  
4. Default Free / deny premium

---

## 3. Client cache contract

### 3.1 Cache contents

Client may persist a **read-only copy** of the last trusted `EntitlementSnapshot` (or a reduced view):

- `tier`, `subscription_state`, `resonance_access`
- `period_ends_at` (if known)
- `super_resonance_balance`, `boost_spotlight_balance`
- `last_verified_at`, `cache_saved_at`, `schema_version`

### 3.2 Cache rules

| Rule | Spec |
| --- | --- |
| Write source | Only after successful trusted-backend response (or signed snapshot if that pattern is chosen later) |
| TTL soft | Prefer revalidate on app foreground / account switch / purchase / restore |
| TTL hard | After hard TTL, treat as stale — revalidate before granting **new** Resonance session if online |
| Tamper | Treat local edits as untrusted; next online verify overwrites |
| Cleared on logout | Wipe entitlement cache on sign-out |
| Account bind | Cache is per authenticated `uid`; never reuse across accounts |

### 3.3 What cache must not do

- Extend `period_ends_at` locally
- Credit consumables locally
- Convert Free → Resonance without server verify
- Survive account switch

---

## 4. Restore / expiry / revocation behavior

### 4.1 Restore purchases

| Step | Behavior |
| --- | --- |
| Trigger | Settings “Restore purchases” (and first-login optional restore) |
| Client | Collect platform restore payloads; call trusted backend |
| Backend | Verify with store; upsert subscription state + **do not** invent consumable credits unless store/ledger proves unconsumed purchases |
| Success | Refresh snapshot; client replaces cache; emit audit |
| Failure | Keep prior trusted snapshot; show calm error; Free loop remains usable |

Restore **associates verified purchases to the current signed-in uid** under multi-device rules (§4.4).

### 4.2 Expiry

| Transition | Access |
| --- | --- |
| `active` → `grace` / `billing_retry` (store) | Keep Resonance features for the store window |
| `grace` / `billing_retry` → `expired` | Lose Resonance features; Free intact |
| Period end with no renewal | `expired` |

Client should revalidate near `period_ends_at` when online.

### 4.3 Revocation

| Cause | Behavior |
| --- | --- |
| Refund / revoke / chargeback / fraud | `subscription_state = revoked`, `resonance_access = false` immediately |
| Webhook or verify detects revoke | Overwrite cache on next fetch; force Free gates |
| Consumables already spent | Not clawed back from peers’ UX history; **unspent** balances may be adjusted only by trusted ledger rules (ops policy deferred) |

### 4.4 Multi-device / multi-account

| Scenario | Rule |
| --- | --- |
| Same uid, multiple devices | Shared backend snapshot; each device caches independently; verify on launch |
| Same store account, different QMatch uids | **Deferred policy** (§9) — default engineering stance: entitlement binds to **QMatch uid** that completed verified purchase / restore; do not auto-share across arbitrary uids |
| Account switch on device | Clear previous uid cache; load new uid snapshot |
| Cross-platform (iOS buy → Android use) | **Deferred** (§9) — architecture must allow a uid-level snapshot that *can* represent either platform’s verified purchase; linking both platforms is not required for v1 draft |

---

## 5. Consumable ledger rules

### 5.1 Separation

| Domain | Storage / semantics |
| --- | --- |
| Subscription | `tier` + `subscription_state` + `resonance_access` |
| Super Resonance | `super_resonance_balance` + append-only credit/debit ledger (trusted) |
| Boost / Spotlight | `boost_spotlight_balance` + separate ledger |

Spending a consumable **must not**:

- change `subscription_state`
- grant Resonance features
- mutate compatibility / ranking / Persona scores

### 5.2 Credit

- Only after trusted verification of a consumable purchase (or audited admin credit)
- Idempotent on store transaction id (no double credit)

### 5.3 Debit

- Only via trusted backend (or trusted callable) when user spends Super Resonance / Boost
- Reject debit if balance < cost
- Record reason: `spend_super_resonance` | `spend_boost_spotlight` + target ids as needed
- Client may optimistically show pending spend UI; final balance is server

### 5.4 Day-one packaging alignment

Per ratified packaging: **no** subscription allotments of consumables on day one. Allotments, if added later, are still ledger credits — not a third tier.

---

## 6. Feature-gate API contract

### 6.1 Logical gate API (client / shared)

Illustrative interface — not requiring a Dart file yet:

```
bool hasResonanceAccess(EntitlementSnapshot s)

bool canUseFeature(EntitlementSnapshot s, FeatureId feature)
  // Resonance features require hasResonanceAccess
  // Free features always true
  // Consumable features require balance > 0 AND spend path

int balanceOf(EntitlementSnapshot s, ConsumableId id)
```

### 6.2 Feature id mapping (align paywall UX enum)

| Feature id | Gate |
| --- | --- |
| `who_liked_you` | `hasResonanceAccess` |
| `rewind` | `hasResonanceAccess` |
| `deeper_compatibility` | `hasResonanceAccess` |
| `advanced_filters` | `hasResonanceAccess` (if packaged) |
| `like_limit` / higher allowance | `hasResonanceAccess` (if packaged) — Free baseline always usable within Free quota |
| `super_resonance` | consumable balance + spend |
| `boost_spotlight` | consumable balance + spend |
| Discover / Like / Pass / match / chat / safety / assessments / Persona | **Always Free** — no Resonance gate |

### 6.3 Gate placement

Gates implement [Paywall & Tease UX](./qmatch_resonance_paywall_tease_ux_v1.md): soft unlock when `canUseFeature == false`; never hard-block Free loop.

### 6.4 Server enforcement

Where abuse matters (Who Liked You list payload, Rewind apply, deeper explanation payload, consumable spend):

- **Server must re-check** entitlement / balance
- Client gate is UX only

---

## 7. Failure / offline behavior

### 7.1 Principles

1. Free core loop always works offline/online.
2. Prefer **fail closed** for *new* Resonance unlocks when verification is unavailable.
3. Prefer **fail soft** for already-verified access inside cache TTL.

### 7.2 Matrix

| Situation | Resonance features | Consumable spend | Free loop |
| --- | --- | --- | --- |
| Online, verify OK | Per snapshot | Per ledger | OK |
| Online, verify fails (auth/network to backend) | Use cache if fresh + was granted; else deny premium | Deny new spend | OK |
| Offline, cache fresh, was `active`/`grace`/`billing_retry` | Allow gated UX from cache until **future bounded hard TTL** (never extend `period_ends_at` locally) | Deny spend (requires server) **or** queue spend only if product later adds durable queue — **default deny spend offline** | OK |
| Offline, cache missing/stale | Deny Resonance (show teaser) — Free-safe fallback | Deny spend | OK |
| `verification_unavailable` prolonged | Use only previously trusted cache within bounded TTL; never invent/extend; then Free for Resonance surfaces | Deny spend | OK |
| Snapshot says `revoked` / `expired` | Deny immediately | Per ledger | OK |

### 7.3 Safe fallback summary

If entitlement verification is unavailable:

- **Never** invent Resonance
- Keep Discover / match / chat / safety
- Show calm “Can’t verify membership right now” on unlock CTA if needed
- Do not burn consumable balances client-side

---

## 8. Analytics / audit fields

### 8.1 Product analytics (align UX contract)

Reuse:

- `resonance_teaser_viewed`
- `resonance_paywall_opened`
- `resonance_paywall_dismissed`
- `resonance_purchase_intent`
- `resonance_feature_unlocked`

Add engineering-oriented events (names only):

| Event | When |
| --- | --- |
| `entitlement_verify_started` | Client/backend verify begins |
| `entitlement_verify_succeeded` | Trusted snapshot applied |
| `entitlement_verify_failed` | Verify error (include `reason_code`) |
| `entitlement_restore_started` | Restore tapped |
| `entitlement_restore_succeeded` | Restore applied |
| `entitlement_restore_failed` | Restore error |
| `entitlement_state_changed` | `subscription_state` transition |
| `consumable_credit_applied` | Balance increased (server) |
| `consumable_spend_applied` | Balance decreased (server) |
| `consumable_spend_rejected` | Insufficient / offline / verify fail |

### 8.2 Audit fields (trusted log / purchase doc)

| Field | Purpose |
| --- | --- |
| `uid` | Account binding |
| `platform` | ios / android |
| `verification_source` | purchase / restore / webhook / admin |
| `subscription_state_from` / `_to` | Transition audit |
| `store_transaction_ref` | Opaque store id (no raw secrets in analytics) |
| `product_ref` | Opaque / deferred product reference |
| `last_verified_at` | Freshness |
| `request_id` | Idempotency |
| `schema_version` | Contract evolution |

Do **not** put IQ/EQ/Persona scores or compatibility scores into entitlement audit streams.

---

## 9. Unresolved platform decisions

| Decision | Status |
| --- | --- |
| Final App Store / Play **product IDs** | Deferred — do not invent |
| Prices / introductory offers | Deferred |
| Exact grace / billing-retry duration mapping per store | Deferred (follow store defaults) |
| Cross-platform purchase sharing on one uid | Deferred |
| Same Apple/Google account → multiple QMatch uids | Deferred (default: bind to purchasing uid) |
| Hard cache TTL hours | Deferred (intent: short enough to honor revoke) |
| Offline consumable spend queue | Deferred — **default deny offline spend** |
| Firestore vs other persistence layout | Deferred |
| App Store Server Notifications v2 / Play RTDN wiring | Deferred implementation |
| Tax / account hold edge copy | Deferred UX |

---

## 10. Exact next step

**Write `docs/product/qmatch_resonance_store_product_catalog_draft_v1.md` (still no code / no prices locked):**

1. Propose **placeholder** product id patterns for Resonance monthly/yearly + Super Resonance + Boost (explicitly `draft_ids_not_final`).
2. Map each product → entitlement effect (subscription state vs ledger credit).
3. List required store console checklist (iOS + Android) without implementing.
4. Note webhook events that must drive `expired` / `revoked` / renewal.
5. Keep prices blank or `TBD`.

Do **not** implement billing SDKs, Cloud Functions, or UI gates in that step.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Free + Resonance states defined | Yes (§1) |
| active / expired / grace / billing_retry / revoked | Yes (§1.2) |
| Store+backend SoT; no client self-grant | Yes (§2) |
| Client cache contract | Yes (§3) |
| Restore / expiry / revocation / multi-device | Yes (§4) |
| Consumable ledger separate; no score mutation | Yes (§5) |
| Feature-gate API + Free loop ungated | Yes (§6) |
| Offline / verify-unavailable safe fallback | Yes (§7) |
| Analytics / audit fields | Yes (§8) |
| No final product IDs / prices | Yes (§9) |
| Status | `resonance_entitlement_engineering_contract_v1` · `engineering_ratified_not_live` |
