# QMatch Store Purchase Verification Contract v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_store_purchase_verification_contract_v1` |
| Status | `store_purchase_verification_contract_v1` · `engineering_ratified_not_live` |
| Parents | [Entitlement Firestore Schema](./qmatch_resonance_entitlement_firestore_schema_v1.md) · [Store Product Identity](../product/qmatch_store_product_identity_v1.md) · [Entitlement Engineering Contract](../product/qmatch_resonance_entitlement_engineering_contract_v1.md) |
| Scope | Trusted App Store + Play verification → `entitlements/{uid}` + purchase ledger |
| Non-goals | Credentials, store-console SKU creation, client Billing SDK, ASSN/RTDN deployment, fake verification |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

Define how QMatch **verifies** purchases for the four frozen launch products on Apple App Store and Google Play, then maps trusted store state into the ratified entitlement schema — without trusting the client as source of truth.

**Status meaning:** engineering-ratified verification contract — binding for Apple/Play verify design. **Not live.** Does **not** authorize console creation, credential provisioning, client IAP SDK work, or deployment. No implementation in this ratification.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Apple verify | Server verifies signed transaction / App Store Server API state |
| Apple uid bind | `appAccountToken` binds purchase to QMatch uid |
| Apple lifecycle | ASSN v2 is authoritative for later renewal / expiry / refund / revoke updates |
| Play verify | Server verifies `purchaseToken` with Play Developer API |
| Play subscription | Subscription = `qmatch.resonance` + `monthly` / `annual` base plans |
| Play ack/consume | **Server** owns acknowledgement / consumption |
| Play lifecycle | RTDN causes authoritative state **re-fetch** (never grant from notification body alone) |
| Client claims | Client purchase claims **never** grant entitlement |
| Products | Only frozen product IDs / base plans accepted |
| Binding | Verified store identity **must** bind to caller uid |
| Idempotency | Duplicate transaction / event IDs are idempotent (noop) |
| Tamper | Replay / tamper attempts **fail closed** |
| Refund/revoke | Removes subscription access (`revoked` / deny `resonance_access`) |
| Consumables | Credit ledger / balances only — never grant Resonance |
| Side effects | No compatibility-score or `discover_eligible` effects |
| Credentials | External credentials / setup remain **unresolved** |

### Hard rules

| Rule | Spec |
| --- | --- |
| No client grant | Client payloads are **hints/transport only**; never grant from client claims alone |
| No fake verification | If store APIs/credentials are unavailable → `verification_not_configured` / fail closed (no Resonance / no credits) |
| Frozen products only | Reject unknown product IDs / base plans |
| Schema lock | Writes only via Admin to `entitlements/{uid}` + `purchase_ledger` |
| Separation | Subscription verify ≠ consumable credit; never mix effects |
| Scores | Verification never writes compatibility / Persona / `discover_eligible` |
| Forbidden | Plus / Orbit / `premiumTier` |
| Unresolved | Apple/Play API keys, ASSN/RTDN endpoints, console SKUs — **not** provisioned by this ratification |

### Frozen products in scope

| Canonical key | Apple | Google Play |
| --- | --- | --- |
| `resonance_monthly` | auto-renewable `qmatch.resonance.monthly` | subscription `qmatch.resonance` + base plan `monthly` |
| `resonance_annual` | auto-renewable `qmatch.resonance.annual` | subscription `qmatch.resonance` + base plan `annual` |
| `super_resonance_x1` | consumable `qmatch.super_resonance.x1` | consumable `qmatch.super_resonance.x1` |
| `boost_x1` | consumable `qmatch.boost.x1` | consumable `qmatch.boost.x1` |

---

## 1. Shared architecture

```
Client (authenticated uid)
  → callable: verifyAndApplyPurchase | restorePurchases
      → Server fetches/verifies with Apple / Google APIs
          → Map to canonical product + subscription_state / balance delta
              → Idempotent ledger row + entitlements/{uid} update (Admin)
```

Webhooks (ASSN v2 / RTDN) are **first-class** trusted inputs for renew/expire/revoke; they must not depend on the client being online.

### 1.1 What the client may send

| Field | Allowed | Notes |
| --- | --- | --- |
| Firebase Auth uid | Implicit via callable auth | Required |
| `platform` | `ios` \| `android` | Required |
| `kind` | `subscription` \| `consumable` \| `restore` | Required |
| Apple: signed transaction / JWS or transaction id + appAccountToken | Transport | Server re-fetches / verifies signature |
| Play: `purchaseToken`, `productId`, optional `packageName` | Transport | Server calls Play Developer API |
| Client-claimed `tier`, `resonance_access`, balances, expiry | **Forbidden to trust** | Ignored for grants |
| Client-claimed “already verified” | **Forbidden** | |

### 1.2 What must be fetched / verified server-side

| Platform | Must verify |
| --- | --- |
| Apple | JWS signature (App Store root / intermediate), bundle id, product id ∈ frozen set, transaction ownership, subscription status / expiry / revocation via App Store Server API |
| Google | purchaseToken with Play Developer API; package name; productId / basePlanId ∈ frozen set; purchase state; acknowledgement; subscription expiry / cancel / revoke |

### 1.3 Account / uid binding

| Rule | Spec |
| --- | --- |
| Auth | Callable requires `request.auth.uid`; all writes go to `entitlements/{thatUid}` |
| Apple appAccountToken | Prefer set at purchase to Firebase uid (or stable hash of uid); on verify, if present, **must equal** caller uid or reject |
| Play obfuscatedExternalAccountId | Prefer set to Firebase uid (or stable hash); if present, must match caller uid or reject |
| Cross-uid reuse | If store identity already bound to another uid in `purchase_ledger_index` / prior ledger → **reject** (no silent transfer in v1) |
| Restore | Same binding rules; restore does not allow hijacking another account’s subscription |
| Logout | Client clears local cache only; server state remains uid-scoped |

**v1 policy:** one store subscription identity → one QMatch uid. Cross-platform / family sharing edge cases deferred.

---

## 2. Apple App Store verification

### 2.1 Preferred APIs

| API | Role |
| --- | --- |
| App Store Server API | Get Transaction History / Transaction Info / All Subscription Statuses |
| JWS verification | Verify signed transactions & renewal info locally with Apple certs |
| App Store Server Notifications V2 (ASSN) | Server-to-server renew / expire / refund / revoke |

**Do not** use legacy `verifyReceipt` as the primary path for new work.

### 2.2 Purchase transaction input (client → server)

| Input | Required | Purpose |
| --- | --- | --- |
| `platform: "ios"` | yes | Router |
| `signedTransaction` (JWS) **or** `transactionId` | yes | Locate transaction |
| `productHint` | optional | Client SKU hint only |
| `appAccountToken` echo | optional | Binding check aid |

Server **must** re-verify the signed payload or fetch Transaction Info from Apple using the transaction id — never trust unsigned client fields for product/expiry/state.

### 2.3 Server-side verification steps (purchase)

1. Authenticate uid.  
2. If credentials missing → return `verification_not_configured` (no grant).  
3. Verify JWS (or fetch Transaction Info with server API key).  
4. Assert `bundleId` matches QMatch iOS app.  
5. Assert `productId` ∈ {`qmatch.resonance.monthly`, `qmatch.resonance.annual`, `qmatch.super_resonance.x1`, `qmatch.boost.x1`}.  
6. Enforce uid binding (`appAccountToken` / prior ledger).  
7. Branch subscription vs consumable (§2.4–2.5).  
8. Write ledger + snapshot atomically.

### 2.4 Subscription status / expiry (Apple)

| Apple signal | Map to `subscription_state` | `resonance_access` |
| --- | --- | --- |
| Active auto-renew, paid period | `active` | true (with `tier=resonance`) |
| Billing Grace Period | `grace` | true |
| Billing Retry / Account Hold (access-preserving per Apple) | `billing_retry` | true while store says entitled |
| Expired / lapsed | `expired` | false |
| Refund / Revoke / Offer redemption revoke | `revoked` | false **immediately** |

Store into snapshot:

| Snapshot field | Source |
| --- | --- |
| `tier` | `resonance` if access-granting; `free` on expire/revoke/none |
| `canonical_product_key` | map productId → monthly/annual |
| `product_id` | Apple productId |
| `base_plan_id` | `null` |
| `platform` | `ios` |
| `period_ends_at` | expiresDate |
| `grace_ends_at` / `billing_retry_ends_at` | when Apple provides |
| `original_transaction_id` | **originalTransactionId** (durable sub identity) |
| `latest_transaction_ref` | transactionId |
| `last_verified_at` | server now |
| `verification_source` | `app_store` \| `restore` \| `webhook` |

### 2.5 Consumables (Apple)

1. Verify transaction productId ∈ consumable set.  
2. Confirm not revoked.  
3. Idempotent credit: `super_resonance_balance` or `boost_balance` +1.  
4. **Never** set `tier` / `resonance_access` from consumable.  
5. Finish / consume on Apple side only after successful ledger credit (server-owned completion policy).

### 2.6 Restore (Apple)

1. Client triggers StoreKit restore → sends transaction ids / signed txns for current entitlement set.  
2. Server verifies **each** with Apple.  
3. Subscription: refresh snapshot from latest All Subscription Statuses for `originalTransactionId`.  
4. Consumable: credit **only** if Apple still shows an unconsumed / restorable purchase that has not been ledger-credited (prefer: only credit when server never saw the transaction id).  
5. No grant without verify.

### 2.7 Refund / revoke (Apple)

| Trigger | Action |
| --- | --- |
| ASSN `REFUND`, `REVOKE`, consumption request outcomes that invalidate | Ledger `subscription_revoke` / consumable revoke note; snapshot `subscription_state=revoked`, `resonance_access=false`, prefer `tier=free` |
| Consumable refund after credit | Do **not** silently leave balance if refund notification is definitive — v1 default: **decrement unspent credit if balance ≥ 1 and ledger shows unused credit**; never claw peer-facing Super Resonance effects already applied |
| Spent consumable refund | No peer undo; record ledger compensation event |

### 2.8 App Store Server Notifications v2

| Requirement | Spec |
| --- | --- |
| Endpoint | HTTPS Cloud Function; verify signed payload with Apple root |
| Auth | Apple JWS — not client Firebase auth |
| Idempotency | `ledgerId = ios:sub:{originalTransactionId}:{notificationType}:{notificationUUID}` |
| Resolve uid | Lookup `original_transaction_id` / `purchase_ledger_index` → uid; if unknown, acknowledge & quarantine (no grant to random uid) |
| Types to handle (min) | `DID_RENEW`, `EXPIRED`, `GRACE_PERIOD_EXPIRED`, `DID_FAIL_TO_RENEW`, `REFUND`, `REVOKE`, `DID_CHANGE_RENEWAL_STATUS` (log; may not change access alone) |
| Response | 200 after durable ledger attempt (incl. noop); retry-safe |

---

## 3. Google Play verification

### 3.1 Preferred APIs

| API | Role |
| --- | --- |
| Google Play Developer API — subscriptions v2 | `purchases.subscriptionsv2.get` with purchaseToken |
| Google Play Developer API — products | `purchases.products.get` for consumables |
| Real-time developer notifications (RTDN) | Pub/Sub → renew / cancel / revoke / voided |

### 3.2 Purchase token input (client → server)

| Input | Required | Purpose |
| --- | --- | --- |
| `platform: "android"` | yes | Router |
| `purchaseToken` | yes | Server verification key |
| `productId` | yes | Hint; must match API result |
| `packageName` | optional | Default to configured QMatch package |
| obfuscated account id echo | optional | Binding check |

Server **must** call Play API with the token — never trust client `purchaseState` / expiry.

### 3.3 Server-side verification steps (purchase)

1. Authenticate uid.  
2. If Play credentials missing → `verification_not_configured`.  
3. Call subscriptions v2 **or** products API based on product class.  
4. Assert package name.  
5. Assert product ∈ frozen set; for Resonance assert base plan ∈ {`monthly`,`annual`}.  
6. Enforce uid binding.  
7. Apply subscription or consumable effect.  
8. Acknowledge / consume **after** successful ledger write (server ownership).

### 3.4 Subscription product + base plans

| Play product | Base plan | Canonical key |
| --- | --- | --- |
| `qmatch.resonance` | `monthly` | `resonance_monthly` |
| `qmatch.resonance` | `annual` | `resonance_annual` |

Reject unknown base plans. Do **not** treat separate Play subscription products as launch path.

| Play subscription state (conceptual) | `subscription_state` | Access |
| --- | --- | --- |
| Active / in grace (entitled) | `active` or `grace` | granted |
| On hold / account hold with entitlement | `billing_retry` | granted while entitled |
| Expired / canceled past expiry | `expired` | deny |
| Revoked / refunded / voided | `revoked` | deny immediately |

Snapshot fields:

| Field | Source |
| --- | --- |
| `product_id` | `qmatch.resonance` |
| `base_plan_id` | `monthly` \| `annual` |
| `canonical_product_key` | mapped |
| `original_transaction_id` | linked purchase / order id stable identity (store subscription id / latestOrderId policy — pick one durable id and stick to it in implementation) |
| `latest_transaction_ref` | purchaseToken hash or orderId (token itself may be long; store orderId + token fingerprint) |
| `platform` | `android` |
| `verification_source` | `play` \| `restore` \| `webhook` |

**Token storage:** prefer store **orderId** + **token fingerprint** in ledger; full purchaseToken in Secret-grade Admin-only field or Secret Manager reference if needed for RTDN correlation — never client-readable.

### 3.5 Consumable verification (Play)

1. `purchases.products.get(packageName, productId, token)`.  
2. Assert productId ∈ {`qmatch.super_resonance.x1`,`qmatch.boost.x1`}.  
3. Assert purchaseState purchased; not cancelled.  
4. Idempotent +1 balance.  
5. Never grant Resonance.

### 3.6 Acknowledgement / consumption ownership

| Product class | Owner | Rule |
| --- | --- | --- |
| Subscription | **Server** | Acknowledge via Play API **after** successful entitlement ledger apply |
| Consumable | **Server** | Consume / acknowledge **after** successful balance credit ledger apply |
| Client ack | Forbidden as sole path | Client may retry callable if network fails; server idempotent |

If ledger apply fails → do **not** acknowledge/consume (allow retry). If ledger apply succeeds and ack fails → retry ack only (ledger already exists → noop grant).

### 3.7 Expiry / cancel / revoke (Play)

| Signal | Action |
| --- | --- |
| Expiry reached | `expired`, deny access |
| User cancel but still in paid period | Keep `active` until expiry |
| Refund / voided purchase | `revoked`, deny immediately |
| Account hold / grace | Map to `billing_retry` / `grace` per Play entitlement |

### 3.8 RTDN

| Requirement | Spec |
| --- | --- |
| Transport | Play Console → Cloud Pub/Sub → push subscription → Function |
| Verify | Authenticate Pub/Sub OIDC / push authenticity; fetch fresh subscription state with purchaseToken from notification |
| Idempotency | `ledgerId = android:sub:{subscriptionIdOrOrder}:{notificationType}:{messageId}` |
| Resolve uid | Index by purchase token fingerprint / orderId → uid |
| Min types | recovered, renewed, canceled, expired, on hold, in grace, revoked, voided purchases |
| Never grant from notification body alone | Always re-GET subscription/product from API when possible |

---

## 4. Canonical entitlement mapping

### 4.1 Product → snapshot / balances

| Canonical key | Entitlement effect | Balance effect |
| --- | --- | --- |
| `resonance_monthly` | `tier=resonance` + state from store | none |
| `resonance_annual` | same Resonance access | none |
| `super_resonance_x1` | none | `super_resonance_balance += 1` |
| `boost_x1` | none | `boost_balance += 1` |

`resonance_access` **always derived** on write:

```
tier == resonance && subscription_state ∈ {active, grace, billing_retry}
```

### 4.2 `verification_source` values

| Value | When |
| --- | --- |
| `app_store` | Apple purchase verify callable |
| `play` | Play purchase verify callable |
| `restore` | Restore callable path |
| `webhook` | ASSN / RTDN |
| `admin` | Manual trusted ops only |

### 4.3 Event → ledger `event_type` / `effect`

Align with schema §4.3–4.4:

| Flow | event_type (examples) | effect (examples) |
| --- | --- | --- |
| Sub purchase/renew | `subscription_purchase` / `subscription_renew` | `grant_resonance` / `refresh_resonance` |
| Restore sub | `subscription_restore` | `grant_resonance` / `refresh_resonance` |
| Expire | `subscription_expire` | `deny_resonance_expired` |
| Grace / retry | `subscription_grace` / `subscription_billing_retry` | `grant_resonance` |
| Refund/revoke | `subscription_revoke` | `deny_resonance_revoked` |
| Consumable buy/restore | `consumable_purchase` / `consumable_restore_credit` | `credit_super_resonance` / `credit_boost` |

---

## 5. Idempotency & replay / tamper protection

### 5.1 Ledger identities (frozen pattern)

| Case | `ledgerId` |
| --- | --- |
| Apple purchase / consumable | `ios:{transactionId}` |
| Play purchase / consumable | `android:{orderId}` (fallback `android:token:{sha256(purchaseToken)}` if orderId absent) |
| Apple ASSN | `ios:sub:{originalTransactionId}:{notificationType}:{notificationUUID}` |
| Play RTDN | `android:sub:{durableSubId}:{notificationType}:{pubsubMessageId}` |
| Spend (separate) | `platform:spend:{uid}:{request_id}` |

Duplicate `ledgerId` → **noop** (return prior success).

### 5.2 Replay / tamper protection

| Threat | Mitigation |
| --- | --- |
| Client forges “paid” flag | Ignored; server store verify required |
| Replay same receipt/token | Ledger idempotency |
| Swap product id in client payload | Server uses store API product/base plan |
| Use another user’s token | uid binding + prior index reject |
| Truncate / edit JWS | Signature verification fails |
| Call verify while logged out | Unauthenticated rejected |
| Grant during `verification_not_configured` | Forbidden |
| Webhook spoof | Verify Apple JWS / Pub/Sub authenticity; re-fetch store state |

### 5.3 Failure states (callable / webhook)

| Code / state | Meaning | Entitlement effect |
| --- | --- | --- |
| `verification_not_configured` | Credentials/API not wired | **No** grant/credit |
| `unauthenticated` | No Firebase auth | No write |
| `invalid_argument` | Missing token/txn | No write |
| `product_not_allowed` | Not in frozen set | No write |
| `uid_binding_mismatch` | Store account ≠ caller | No write |
| `store_ownership_conflict` | Txn already bound other uid | No write |
| `store_verification_failed` | Apple/Play rejected / invalid | No write |
| `store_temporarily_unavailable` | 5xx / timeout | No write; client may retry; no local extend |
| `already_processed` | Idempotent noop | Prior state unchanged |
| `revoked` (result after verify) | Store revoked | Deny access |

---

## 6. Refund / revoke handling (both stores)

| Step | Spec |
| --- | --- |
| 1 | Receive ASSN/RTDN or verify-time revoke signal |
| 2 | Re-fetch store status when possible |
| 3 | Idempotent ledger `subscription_revoke` (or consumable compensation) |
| 4 | Snapshot: `subscription_state=revoked`, `resonance_access=false`, prefer `tier=free` |
| 5 | Consumable: no undo of already-applied peer effects; unspent credit clawback only when policy + balance allow |
| 6 | `revoked` beats any client cache |

---

## 7. Required external credentials / setup (**unresolved**)

**Ratification note:** Items below remain **unresolved**. This contract does not provision secrets, link consoles, or authorize SKU creation.

### 7.1 Apple

| Item | Purpose | Status |
| --- | --- | --- |
| App Store Connect API key (Issuer ID, Key ID, `.p8`) | App Store Server API | **Unresolved** |
| App bundle id | Verify transactions belong to QMatch | **Unresolved** (known app, key not wired) |
| ASSN v2 production + sandbox HTTPS endpoints | Notifications | **Unresolved** |
| Apple Root CA / intermediate for JWS | Local signature verify | **Unresolved** |
| Sandbox testers | QA only — after console SKUs exist | **Unresolved** |

### 7.2 Google Play

| Item | Purpose | Status |
| --- | --- | --- |
| GCP service account with Android Publisher permission | Play Developer API | **Unresolved** |
| Link Play Console ↔ Cloud project | API access | **Unresolved** |
| Application package name | Verify package | **Unresolved** (known app, key not wired) |
| RTDN topic + push subscription | Lifecycle notifications | **Unresolved** |
| Play Billing Library later on client | Out of scope here | Deferred |

### 7.3 Explicitly out of scope now

| Item | Status |
| --- | --- |
| Creating store SKUs / base plans | **Not authorized** by this contract |
| Checking credentials into git | Forbidden |
| Fake / stub “always valid” verifier | Forbidden |
| Client StoreKit 2 / Play Billing implementation | Not this ratification |
| Implementation or deployment of verifiers / webhooks | **Not this ratification** |

---

## 8. Callable contract alignment

Existing scaffolds `verifyAndApplyPurchase` / `restorePurchases` remain correct until credentials exist:

| Condition | Behavior |
| --- | --- |
| No Apple/Play credentials | Return `verification_not_configured`; `granted=false` |
| Credentials present (future) | Execute this contract end-to-end |

No intermediate “trust client” mode.

---

## 9. Exact next implementation step

**Implement Apple + Play verifier modules behind a feature flag / credential gate — still no client Billing SDK and no console SKU creation:**

1. Add `functions/src/store_verify_apple.js` + `store_verify_play.js` that:
   - fail closed with `verification_not_configured` when secrets absent  
   - when secrets present (local/dev only), verify signature/API and return a **normalized StoreVerificationResult** (no Firestore writes yet in unit tests with fixtures)  
2. Add pure mappers: store product/base plan → canonical key; Apple/Play status → `subscription_state`.  
3. Unit-test fixtures (signed payload mocks / recorded API JSON) for mapping + binding rejection.  
4. Only after mappers are green: wire repository apply into callables behind credential check.

Do **not** deploy ASSN/RTDN receivers until SKUs exist and sandbox credentials are approved.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Apple purchase/restore/ASSN/refund | Yes (§2) |
| Play token/base plans/consumable/ack/RTDN | Yes (§3) |
| Client vs server responsibilities | Yes (§1) |
| Canonical mapping + ledger ids | Yes (§4–5) |
| No fake verify / no console / no client SDK | Yes (§0, §7) |
| Credentials unresolved | Yes (§7) |
| Status | `store_purchase_verification_contract_v1` · `engineering_ratified_not_live` |
