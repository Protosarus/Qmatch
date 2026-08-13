# QMatch Resonance Entitlement Firestore Schema v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_resonance_entitlement_firestore_schema_v1` |
| Status | `resonance_entitlement_firestore_schema_v1` · `engineering_ratified_not_live` |
| Parents | [Entitlement Engineering Contract](../product/qmatch_resonance_entitlement_engineering_contract_v1.md) · [Store Product Identity](../product/qmatch_store_product_identity_v1.md) |
| Scope | Trusted Firestore paths for Resonance subscription snapshot, consumable balances, purchase ledger |
| Non-goals | App/backend code, store-console, prices, Plus/Orbit, `discover_eligible` changes |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

Map the ratified entitlement contract onto concrete Firestore documents so Admin/Cloud Functions are the **sole writers**, clients can **read only safe owner-scoped state**, and purchase processing is **idempotent**.

**Status meaning:** engineering-ratified Firestore schema — binding for entitlement persistence design. **Not live** in rules, Functions, or app until an engineering ship. No backend/client implementation in this ratification.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Snapshot path | `entitlements/{uid}` = trusted current entitlement snapshot |
| Ledger path | `entitlements/{uid}/purchase_ledger/{ledgerId}` = immutable Admin-only ledger |
| Owner read | Owner may **GET** own snapshot only |
| Client writes | Client **cannot** create/update/delete entitlement or balances |
| Ledger access | Ledger is **never** client-readable or client-writable |
| Writers | Admin SDK / Cloud Functions are **sole writers** |
| Balances | Frozen: `super_resonance_balance`, `boost_balance` |
| Separation | Subscription state and consumable balances remain separate |
| `resonance_access` | Derived on trusted write; **never** client-authored |
| Discover | `discover_eligible` remains completely separate (`users/{uid}` only) |
| Forbidden | No Plus / Orbit / `premiumTier` fields |
| Purchase idempotency | Ledger idempotency based on store transaction / event identity |
| Spend idempotency | Unique `request_id` + atomic ledger create + debit |

**Hard rules**

| Rule | Spec |
| --- | --- |
| No client grant/edit | Client never creates/updates entitlement, balances, or ledger |
| Backend sole writer | Admin SDK / trusted Functions only |
| Separation | Subscription fields ≠ consumable balances (same uid doc OK; separate field groups + ledger) |
| No legacy premium | **Forbidden:** `premiumTier`, Plus, Orbit |
| Discover isolation | `discover_eligible` stays on `users/{uid}` only — never mirrored into entitlement docs as a grant |
| Store IDs | Only frozen identity IDs / canonical keys |
| Account isolation | Paths keyed by `uid`; logout clears client cache of that uid only |

---

## 1. Firestore paths

### 1.1 Frozen layout

```
entitlements/{uid}                          # trusted current snapshot + balances (owner GET only)
entitlements/{uid}/purchase_ledger/{ledgerId}  # immutable processed events (Admin-only; never client R/W)
```

Optional (deferred, not required for v1): `purchase_ledger_index/{platform}_{store_transaction_id}` → `{ uid, ledger_path }` for webhook lookup without knowing uid — Admin-only.

### 1.2 Why not embed on `users/{uid}`

| Reason |
| --- |
| `users` already has broad Discover `get` paths (`discover_eligible`, matched peers) — entitlement must **not** ride those reads |
| Cleaner protected-key surface than expanding `userProtectedKeysUnchanged` |
| Matches “discover_eligible completely separate” |

### 1.3 Path summary

| Path | Purpose |
| --- | --- |
| `entitlements/{uid}` | **Frozen.** Trusted current entitlement snapshot + consumable balances |
| `entitlements/{uid}/purchase_ledger/{ledgerId}` | **Frozen.** Immutable, Admin-only purchase/restore/webhook/spend records |

---

## 2. Entitlement snapshot fields (`entitlements/{uid}`)

Single document per QMatch account. **Subscription block** and **balance block** are separate field groups.

### 2.1 Subscription / access block

| Field | Type | Values / notes |
| --- | --- | --- |
| `uid` | string | Must equal document id |
| `tier` | string | `free` \| `resonance` only |
| `subscription_state` | string | `none` \| `active` \| `billing_retry` \| `grace` \| `expired` \| `revoked` |
| `resonance_access` | bool | Derived on Admin write only; never client-authored. true iff `tier==resonance` AND state ∈ {active, grace, billing_retry} |
| `platform` | string | `ios` \| `android` \| `unknown` — last verified purchase platform |
| `canonical_product_key` | string \| null | `resonance_monthly` \| `resonance_annual` \| null if free/none |
| `product_id` | string \| null | Frozen store id: iOS `qmatch.resonance.monthly` / `.annual`; Play parent `qmatch.resonance` when platform=android |
| `base_plan_id` | string \| null | Play only: `monthly` \| `annual`; null on iOS |
| `period_ends_at` | timestamp \| null | Paid period end (store) |
| `grace_ends_at` | timestamp \| null | Optional |
| `billing_retry_ends_at` | timestamp \| null | Optional |
| `last_verified_at` | timestamp | Last successful trusted verify |
| `verification_source` | string | `app_store` \| `play` \| `restore` \| `webhook` \| `admin` |
| `original_transaction_id` | string \| null | Durable store subscription identity (iOS original / Play linked) |
| `latest_transaction_ref` | string \| null | Most recent store transaction / order id verified |
| `schema_version` | string | e.g. `resonance_entitlement_firestore_schema_v1` |

**Do not store** `verification_unavailable` as a durable Firestore state for grants — that is a client/runtime condition. Persist last trusted snapshot; on deny paths set `expired` / `revoked` / `none`.

**Forbidden fields:** `premiumTier`, `plus`, `orbit`, `discover_eligible`, compatibility scores.

### 2.2 Derived invariant (backend must enforce on write)

```
resonance_access == (
  tier == "resonance"
  && subscription_state in ["active", "grace", "billing_retry"]
)
```

Client must treat server `resonance_access` as authoritative for UX gates; still re-check on sensitive server APIs.

### 2.3 Default free document

On first entitlement touch (or lazy create on first verify):

```
tier: free
subscription_state: none
resonance_access: false
platform: unknown
canonical_product_key: null
product_id: null
base_plan_id: null
period_ends_at: null
...
super_resonance_balance: 0
boost_balance: 0
schema_version: resonance_entitlement_firestore_schema_v1
```

---

## 3. Consumable balances (frozen; same doc, separate group)

| Field | Type | Notes |
| --- | --- | --- |
| `super_resonance_balance` | int ≥ 0 | **Frozen** field name. Credits from `super_resonance_x1` |
| `boost_balance` | int ≥ 0 | **Frozen** field name. Credits from `boost_x1` (display name Boost) |

| Rule | Spec |
| --- | --- |
| Never grant Resonance | Balance changes must not set `tier` / `resonance_access` |
| Never change scores | No writes to compatibility / Persona fields |
| Spend | Requires unique `request_id`; atomic ledger create + debit in one trusted transaction |
| No day-one allotments | Subscription activate does not increment these |

Legacy name `boost_spotlight_balance` is **not** used.

---

## 4. Purchase ledger (`entitlements/{uid}/purchase_ledger/{ledgerId}`)

### 4.1 Document id (idempotency key)

```
ledgerId = "{platform}:{store_transaction_id}"
```

Examples:

- `ios:1000000123456789`
- `android:GPA.1234-5678-9012-34567`

Alternate for subscription lifecycle events without a new retail txn:  
`{platform}:sub:{original_transaction_id}:{event_type}:{event_id}`  
where `event_id` is store notification UUID / Pub/Sub message id.

**Constraint:** `create` only (or `set` with exists-check). Duplicate processing of the same `ledgerId` is a no-op.

### 4.2 Ledger fields (immutable after create)

| Field | Type | Notes |
| --- | --- | --- |
| `uid` | string | Owner |
| `ledger_id` | string | Same as doc id |
| `store_transaction_id` | string | Raw store txn / order / notification id component |
| `platform` | string | `ios` \| `android` |
| `canonical_product_key` | string | `resonance_monthly` \| `resonance_annual` \| `super_resonance_x1` \| `boost_x1` \| `none` for revoke-only |
| `product_id` | string \| null | Frozen store product id when applicable |
| `base_plan_id` | string \| null | Play base plan when applicable |
| `event_type` | string | See §4.3 |
| `effect` | string | See §4.4 |
| `subscription_state_after` | string \| null | Snapshot state after applying (if sub-related) |
| `balance_delta_super_resonance` | int | Usually 0, +1, or −1 |
| `balance_delta_boost` | int | Usually 0, +1, or −1 |
| `verification_source` | string | `purchase` \| `restore` \| `webhook` \| `spend` \| `admin` |
| `processed_at` | timestamp | Server time |
| `schema_version` | string | `resonance_entitlement_firestore_schema_v1` |

No client-writable fields. Prefer **no updates** after create (true append-only). If a correction is required, write a **new** compensating ledger row; do not mutate history.

### 4.3 `event_type` values

| event_type | Meaning |
| --- | --- |
| `subscription_purchase` | New or renewal purchase verified |
| `subscription_restore` | Restore path verified |
| `subscription_renew` | Webhook renewal |
| `subscription_expire` | Period ended |
| `subscription_grace` | Enter grace |
| `subscription_billing_retry` | Enter billing retry |
| `subscription_revoke` | Refund / revoke / chargeback |
| `consumable_purchase` | Super Resonance / Boost credit |
| `consumable_restore_credit` | Unconsumed consumable credited on restore |
| `consumable_spend` | Trusted spend debit |

### 4.4 `effect` values

| effect | Typical result |
| --- | --- |
| `grant_resonance` | Set tier resonance + active (or grace/retry as signaled) |
| `refresh_resonance` | Extend/refresh period; keep access |
| `deny_resonance_expired` | expired + resonance_access false |
| `deny_resonance_revoked` | revoked + resonance_access false |
| `credit_super_resonance` | +1 super balance |
| `credit_boost` | +1 boost balance |
| `debit_super_resonance` | −1 super balance |
| `debit_boost` | −1 boost balance |
| `noop` | Duplicate / already applied |

---

## 5. Refund / revoke / restore compatibility

### 5.1 Refund / revoke

1. Verify store revoke/refund signal (webhook or verify).  
2. Write ledger row `subscription_revoke` (idempotent on notification id).  
3. Update snapshot: `subscription_state=revoked`, `tier=free` **or** keep `tier=resonance` with `resonance_access=false` — **mandated:** `resonance_access=false`, state=`revoked`. Prefer `tier=free` after revoke for clarity.  
4. **Do not** claw back already-spent consumable effects on peers.  
5. Unspent balances: leave unchanged unless finance policy later adds clawback (default: **no clawback** of unused credits on sub revoke).

### 5.2 Restore

1. Client sends restore payloads → Function verifies with store.  
2. For each new store transaction not yet in ledger: create ledger + apply effect.  
3. Refresh snapshot from latest verified subscription.  
4. Consumables: credit **only** unconsumed purchases (ledger `consumable_restore_credit`).  
5. Never invent Resonance without verify.

### 5.3 Account / logout

| Concern | Spec |
| --- | --- |
| Path isolation | All data under `entitlements/{uid}` |
| Logout | Client drops local cache for previous uid; must not read another uid’s entitlement |
| Rules | `get` only if `request.auth.uid == uid` |

---

## 6. Read / write authority

| Actor | `entitlements/{uid}` | `purchase_ledger/*` |
| --- | --- | --- |
| Owner client | **get** (read snapshot + balances) | **deny** (no list/get) |
| Other clients | **deny** | **deny** |
| Admin SDK / Functions | read/write | create (append) + read |
| Unauthenticated | deny | deny |

**Spend / purchase / restore:** HTTPS callable (or equivalent) authenticated as uid → Function verifies → Admin writes. Client never patches balances.

---

## 7. Idempotency model

| Operation | Idempotency key | Behavior |
| --- | --- | --- |
| Purchase / restore credit | `ledgerId = platform:store_transaction_id` | If doc exists → noop |
| Webhook lifecycle | `platform:sub:originalTxn:eventType:notificationId` | If exists → noop |
| Spend | `platform:spend:{uid}:{request_id}` — **requires** unique client `request_id` (or equivalent unique spend id) | Reject reuse; atomic ledger create + balance debit |

Backend transaction pattern (ratified):

1. Read ledger doc; if exists, return success with prior result (noop).  
2. Else in **one** Firestore transaction: create ledger row + apply subscription/balance effect (for spend: debit).  
3. Never debit without a new ledger row; never create spend ledger without debit when balance allows.

---

## 8. Rules requirements (to implement later)

Add to `firestore.rules` (not in this step):

```
match /entitlements/{uid} {
  allow get: if isOwner(uid);
  allow list: if false;
  allow create, update, delete: if false;  // Admin only
  match /purchase_ledger/{ledgerId} {
    allow read, write: if false;  // Admin only
  }
}
```

Also ensure `users/{uid}` protected keys **never** include entitlement grant fields; do not add `tier`/`resonance_access` onto `users` in v1.

---

## 9. Frozen product mapping (only these)

| canonical_product_key | product_id (examples) | base_plan_id |
| --- | --- | --- |
| `resonance_monthly` | iOS `qmatch.resonance.monthly`; Play `qmatch.resonance` | Play `monthly` |
| `resonance_annual` | iOS `qmatch.resonance.annual`; Play `qmatch.resonance` | Play `annual` |
| `super_resonance_x1` | `qmatch.super_resonance.x1` | null |
| `boost_x1` | `qmatch.boost.x1` | null |

---

## 10. Exact next implementation step

**Scaffold Cloud Functions stubs (no store verify yet):**

1. `getEntitlement` (optional; or client reads `entitlements/{uid}` once rules land).  
2. `verifyAndApplyPurchase` / `restorePurchases` callables — validate auth + shape; return “not configured” until credentials exist.  
3. Add Firestore rules block for `entitlements` as in §8.  
4. Unit-test pure mappers: store product → canonical key; ledgerId builders; `resonance_access` invariant.

Do **not** wire StoreKit/Play Billing or ASSN/RTDN until store credentials + sandbox SKUs are authorized.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Snapshot + balances + ledger paths | Yes (§1–4) |
| Client never writes grants | Yes (§6–8) |
| Sub ≠ consumable; no Plus/Orbit/premiumTier | Yes |
| discover_eligible separate | Yes |
| Refund/restore/idempotency | Yes (§5, §7) |
| Only frozen store IDs | Yes (§9) |
| Status | `resonance_entitlement_firestore_schema_v1` · `engineering_ratified_not_live` |
