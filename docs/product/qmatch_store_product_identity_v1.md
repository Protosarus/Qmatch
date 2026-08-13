# QMatch Store Product Identity v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_store_product_identity_v1` |
| Status | `store_product_identity_v1` · `product_ratified_not_live` |
| Parents | [Store Creation Readiness v1](./qmatch_store_creation_readiness_v1.md) · [Catalog Draft](./qmatch_resonance_store_product_catalog_draft_v1.md) · [Entitlement Engineering](./qmatch_resonance_entitlement_engineering_contract_v1.md) |
| Scope | Canonical identity + iOS/Android mapping for the **4 frozen launch products** |
| Non-goals | App code, store-console creation, prices, Quarterly, ×5 packs, ranking/scoring |
| ID status | **Final** (ratified) — still no store-console creation until readiness allows |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

This document is the **ratified** canonical product identity for launch SKUs so backend verification, client billing, and store consoles share one vocabulary.

**Status meaning:** product-ratified identity — store ID strings and Play model are final for planning. **Not live** in stores. Still **does not authorize** console SKU creation until readiness blockers clear.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Canonical keys | `resonance_monthly` · `resonance_annual` · `super_resonance_x1` · `boost_x1` |
| iOS subscription IDs | `qmatch.resonance.monthly` · `qmatch.resonance.annual` |
| iOS/Android consumables | `qmatch.super_resonance.x1` · `qmatch.boost.x1` |
| Play subscription | Product `qmatch.resonance` + base plans `monthly` · `annual` |
| Play anti-pattern | Do **not** use separate Play subscription products unless a future store constraint forces migration |
| Entitlement | Monthly + Annual → same Resonance access; Super Resonance / Boost → own ledgers only |
| Scores | No product changes compatibility scores |
| Deferred | Quarterly · ×5 packs |
| Prices | `TBD` |
| Console | No store-console creation yet |

### Hard rules

| Rule | Spec |
| --- | --- |
| Launch set only | Monthly, Annual, Super Resonance ×1, Boost ×1 |
| No Quarterly / ×5 | Out of identity scope |
| No prices | `TBD` |
| No score effects | Subscription/consumables never change compatibility score |
| No store creation yet | Identity ratification ≠ authorization to create SKUs |
| Entitlement mapping | Per [Entitlement Engineering Contract](./qmatch_resonance_entitlement_engineering_contract_v1.md) |

---

## 1. Canonical ID table (final)

| Launch product | Canonical internal key | Store ID string |
| --- | --- | --- |
| Resonance Monthly | `resonance_monthly` | `qmatch.resonance.monthly` |
| Resonance Annual | `resonance_annual` | `qmatch.resonance.annual` |
| Super Resonance ×1 | `super_resonance_x1` | `qmatch.super_resonance.x1` |
| Boost ×1 | `boost_x1` | `qmatch.boost.x1` |

Internal keys are stable enums for code/backend. Store ID strings are what App Store Connect / Play Console use (with Play subscriptions using parent `qmatch.resonance` + base plans per §3).

---

## 2. Per-product identity

### 2.1 Resonance Monthly

| Field | Spec |
| --- | --- |
| Canonical internal key | `resonance_monthly` |
| iOS product ID | `qmatch.resonance.monthly` |
| Android mapping | See §3 — **base plan** `monthly` under subscription product `qmatch.resonance` (**recommended**) **or** standalone product `qmatch.resonance.monthly` if separate-products model chosen |
| Type | Auto-renewable **subscription** |
| Entitlement / ledger | Sets `tier=resonance`, drives `subscription_state` / `resonance_access`; **no** consumable credit; **no** compatibility-score change |
| Restore | Restores as subscription after backend verify; does not credit Super Resonance / Boost |
| Backend verification | Verify iOS transaction / Play subscription purchase → upsert EntitlementSnapshot; map product/base-plan → `resonance_monthly`; idempotent on store subscription/original transaction id + `uid` |

### 2.2 Resonance Annual

| Field | Spec |
| --- | --- |
| Canonical internal key | `resonance_annual` |
| iOS product ID | `qmatch.resonance.annual` |
| Android mapping | Base plan `annual` under `qmatch.resonance` (**recommended**) **or** standalone `qmatch.resonance.annual` |
| Type | Auto-renewable **subscription** |
| Entitlement / ledger | Same Resonance access as monthly; longer period only; no consumable credit; no score change |
| Restore | Same as monthly (subscription) |
| Backend verification | Same path; map → `resonance_annual`; idempotent on subscription identity + `uid` |

### 2.3 Super Resonance ×1

| Field | Spec |
| --- | --- |
| Canonical internal key | `super_resonance_x1` |
| iOS product ID | `qmatch.super_resonance.x1` |
| Android product ID | `qmatch.super_resonance.x1` (in-app **consumable** product) |
| Type | **Consumable** |
| Entitlement / ledger | Credit `super_resonance_balance` +1; never sets `resonance_access`; never changes compatibility score |
| Restore | Does **not** restore as subscription; may credit ledger only for verified **unconsumed** purchase |
| Backend verification | Verify consumable → idempotent ledger credit keyed by store transaction / purchase token |

### 2.4 Boost ×1

| Field | Spec |
| --- | --- |
| Canonical internal key | `boost_x1` |
| iOS product ID | `qmatch.boost.x1` |
| Android product ID | `qmatch.boost.x1` (in-app **consumable** product) |
| User-facing name | **Boost** |
| Type | **Consumable** |
| Entitlement / ledger | Credit boost balance +1; never sets `resonance_access`; never changes compatibility score |
| Restore | Same as Super Resonance (ledger only if unconsumed) |
| Backend verification | Verify consumable → idempotent boost credit on transaction id |

---

## 3. Google Play subscription model — tradeoff & recommendation

### 3.1 Option A — One Resonance subscription + base plans (**recommended**)

| Piece | Value |
| --- | --- |
| Subscription product ID | `qmatch.resonance` |
| Base plan (monthly) | `monthly` → maps to canonical `resonance_monthly` |
| Base plan (annual) | `annual` → maps to canonical `resonance_annual` |

**Pros**

- Matches current Play Billing subscription design (one product, multiple base plans)
- Cleaner upgrade/downgrade / replacement within one subscription
- Parallels iOS “one subscription group, multiple products”
- Backend maps `(productId, basePlanId)` → canonical key

**Cons**

- Android store ID for the **subscription parent** (`qmatch.resonance`) differs from iOS per-duration product IDs
- Client/backend must always carry base-plan id, not product id alone

### 3.2 Option B — Separate subscription products

| Piece | Value |
| --- | --- |
| Monthly product | `qmatch.resonance.monthly` |
| Annual product | `qmatch.resonance.annual` |

**Pros**

- Same string IDs as iOS and as canonical table (simpler mental model)
- Slightly simpler client SKU list if ignoring base plans

**Cons**

- Fights modern Play subscription model; plan changes / proration are clumsier
- Higher risk of two independent subscriptions if misconfigured
- Less aligned with Play Console best practice for duration variants

### 3.3 Ratified Play model

**Option A is ratified:** one Play subscription product `qmatch.resonance` with base plans `monthly` and `annual`.

Do **not** use separate Play subscription products (`qmatch.resonance.monthly` / `qmatch.resonance.annual` as distinct subscriptions) unless a future store constraint requires migration.

Canonical keys stay `resonance_monthly` / `resonance_annual`.  
iOS keeps distinct product IDs `qmatch.resonance.monthly` / `qmatch.resonance.annual` in one App Store subscription group **Resonance**.

| Platform | How duration is identified |
| --- | --- |
| iOS | Product ID `qmatch.resonance.{monthly\|annual}` |
| Android | Product `qmatch.resonance` + base plan `{monthly\|annual}` |

Backend normalizes both to the same canonical internal key.

---

## 4. iOS mapping summary

| Canonical key | iOS product ID | App Store type | Subscription group |
| --- | --- | --- | --- |
| `resonance_monthly` | `qmatch.resonance.monthly` | Auto-renewable subscription | **Resonance** |
| `resonance_annual` | `qmatch.resonance.annual` | Auto-renewable subscription | **Resonance** |
| `super_resonance_x1` | `qmatch.super_resonance.x1` | Consumable | — |
| `boost_x1` | `qmatch.boost.x1` | Consumable | — |

---

## 5. Android / Play mapping summary (recommended model)

| Canonical key | Play product ID | Base plan ID | Play type |
| --- | --- | --- | --- |
| `resonance_monthly` | `qmatch.resonance` | `monthly` | Subscription base plan |
| `resonance_annual` | `qmatch.resonance` | `annual` | Subscription base plan |
| `super_resonance_x1` | `qmatch.super_resonance.x1` | — | Managed consumable |
| `boost_x1` | `qmatch.boost.x1` | — | Managed consumable |

If Option B were chosen instead, subscription rows would use product IDs `qmatch.resonance.monthly` / `qmatch.resonance.annual` with no base-plan dimension — **not recommended**.

---

## 6. Entitlement mapping (all platforms)

| Canonical key | Writes subscription fields | Ledger | `resonance_access` |
| --- | --- | --- | --- |
| `resonance_monthly` | Yes | No | Yes while active/grace/billing_retry |
| `resonance_annual` | Yes | No | Yes while active/grace/billing_retry |
| `super_resonance_x1` | No | `super_resonance_balance` +1 | No |
| `boost_x1` | No | boost balance +1 | No |

Restore: subscriptions → membership snapshot; consumables → unconsumed ledger credit only ([Entitlement Contract](./qmatch_resonance_entitlement_engineering_contract_v1.md)).

---

## 7. Backend verification mapping

| Event | Normalize to | Action |
| --- | --- | --- |
| iOS buy/restore `qmatch.resonance.monthly` | `resonance_monthly` | Upsert subscription snapshot |
| iOS buy/restore `qmatch.resonance.annual` | `resonance_annual` | Upsert subscription snapshot |
| Play buy/restore `qmatch.resonance` + `monthly` | `resonance_monthly` | Upsert subscription snapshot |
| Play buy/restore `qmatch.resonance` + `annual` | `resonance_annual` | Upsert subscription snapshot |
| iOS/Play `qmatch.super_resonance.x1` | `super_resonance_x1` | Idempotent ledger credit |
| iOS/Play `qmatch.boost.x1` | `boost_x1` | Idempotent ledger credit |
| Refund/revoke (either platform) | — | `subscription_state=revoked` or reverse unconsumed credit per ledger rules |

Idempotency: subscription on store subscription/original transaction + `uid`; consumable on store transaction/purchase token.

---

## 8. Remaining decisions

| Decision | Status |
| --- | --- |
| Ratify this identity contract (finalize IDs) | **Done** (2026-08-13) |
| Adopt Play Option A | **Done** — ratified |
| Prices / intro offers | `TBD` |
| Store-console creation | Not authorized yet (readiness blockers) |
| Exact grace/billing-retry mapping | Unresolved (entitlement contract) |
| Cross-platform purchase linking | Unresolved |
| Named readiness owners | Unresolved |

---

## 9. Exact next step

Open a **pricing decision** track (`TBD` → chosen), assign named readiness owners, and start backend verification credentials + ASSN/RTDN setup. Create **sandbox** SKUs only when explicitly ordered and credentials path is underway.

Do **not** create Quarterly or ×5 packs. Do **not** implement app billing code unless separately ordered.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Four launch products only | Yes |
| Canonical + iOS + Android mapping | Yes (§1–5) |
| Play model tradeoff + recommendation | Yes (§3) — Option A |
| Entitlement / restore / verify mapped | Yes (§6–7) |
| No prices / Quarterly / ×5 / score effects / console create | Yes |
| IDs final only after ratification | Yes |
| Status | `store_product_identity_v1` · `product_ratified_not_live` |
