# QMatch Resonance Store Product Catalog Draft v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_resonance_store_product_catalog_draft_v1` |
| Status | `store_catalog_draft_not_live` · launch set **ratified** via [Store Creation Readiness v1](./qmatch_store_creation_readiness_v1.md) |
| Parents | [Entitlement Engineering Contract](./qmatch_resonance_entitlement_engineering_contract_v1.md) (`engineering_ratified_not_live`) · [Membership](./qmatch_monetization_membership_contract_v1.md) · [Launch Packaging](./qmatch_resonance_launch_packaging_v1.md) |
| Scope | Draft iOS + Android product catalog patterns, entitlement mapping, pre-creation checklist |
| Non-goals | App code, real App Store / Play Console product creation, prices, billing SDK, ranking/scoring |
| ID policy | All product IDs are **`draft_ids_not_final`** — **not frozen yet** |
| Launch freeze | Ratified in [Store Creation Readiness v1](./qmatch_store_creation_readiness_v1.md) (`product_ratified_not_live`) |
| Draft date | 2026-08-13 |
| Launch set ratified | 2026-08-13 |

---

## 0. Purpose

Define the **draft store catalog** for Resonance subscriptions and Super Resonance / Boost consumables so engineering and ops share one product vocabulary **before** any console SKU is created.

This catalog:

- Maps every product → [Entitlement Engineering Contract](./qmatch_resonance_entitlement_engineering_contract_v1.md)
- Keeps subscription and consumable effects separate
- States restore / verification / idempotency expectations
- Lists the checklist required **before** real store creation

**Hard rules**

| Rule | Spec |
| --- | --- |
| No real SKUs yet | Do not create App Store / Play products until readiness blockers clear |
| No score advantage | Resonance subscription **never** grants compatibility-score advantage |
| Consumables separate | Super Resonance + **Boost** stay consumable ledgers — not subscription |
| No day-one allotments | Subscription does **not** auto-credit consumable balances |
| Restore | Consumables do **not** restore as subscription entitlements |
| Launch durations | **Monthly + Annual** launch; Quarterly **deferred** (**ratified**) |
| Launch consumables | Super Resonance ×1 + Boost ×1 launch; ×5 packs **deferred** (**ratified**) |
| Display name | User-facing Boost name = **Boost** (not Spotlight) (**ratified**) |
| Prices | Remain `TBD` (**ratified** unresolved) |
| Product IDs | Remain `draft_ids_not_final` — final IDs **not frozen yet** |

---

## 1. Placeholder ID scheme (`draft_ids_not_final`)

### 1.1 Pattern

```
qmatch.<family>.<sku>.<platform_suffix?>
```

| Segment | Meaning |
| --- | --- |
| `qmatch` | App namespace |
| `family` | `resonance` \| `super_resonance` \| `boost` |
| `sku` | Duration or pack size token |
| platform | Prefer **same base id** on iOS + Android where stores allow; if forced split, append `.ios` / `.android` only as last resort |

### 1.2 Draft catalog IDs (launch freeze)

| Logical product | Draft product ID | Launch class |
| --- | --- | --- |
| Resonance monthly | `qmatch.resonance.monthly` | **launch** · `draft_ids_not_final` |
| Resonance annual | `qmatch.resonance.annual` | **launch** · `draft_ids_not_final` |
| Resonance 3-month | `qmatch.resonance.quarterly` | **deferred** · `draft_ids_not_final` |
| Super Resonance ×1 | `qmatch.super_resonance.x1` | **launch** · `draft_ids_not_final` |
| Super Resonance ×5 | `qmatch.super_resonance.x5` | **deferred** · `draft_ids_not_final` |
| Boost ×1 | `qmatch.boost.x1` | **launch** · `draft_ids_not_final` · display **Boost** |
| Boost ×5 | `qmatch.boost.x5` | **deferred** · `draft_ids_not_final` |

**Day-one store creation set (when authorized):** Monthly, Annual, Super Resonance ×1, Boost ×1 only.

Prices: **`TBD`** for all rows.

---

## 2. Subscription catalog (Resonance family)

All subscription products grant the **same** Resonance entitlement class. Duration only changes billing period — not feature set or match quality.

### 2.1 Resonance monthly

| Field | Spec |
| --- | --- |
| Draft ID | `qmatch.resonance.monthly` (`draft_ids_not_final`) |
| Store product type | Auto-renewable subscription (iOS) / Subscription (Play) |
| Recurring / consumable | **Recurring** |
| Entitlement granted | `tier = resonance`; `subscription_state → active` (then grace/billing_retry per store); `resonance_access = true` while granted |
| Compatibility score | **Unchanged** — no score advantage |
| Consumable credit | **None** (no day-one allotments) |
| Restore behavior | Restores as **subscription** entitlement after backend verify; does not credit Super Resonance / Boost |
| Backend verification mapping | Verify subscription transaction → upsert EntitlementSnapshot subscription fields; set `product_ref` / period end from store |
| Idempotency key | Store original transaction / subscription id (platform-specific) + `uid` — never double-activate from retries |
| Platform parity | Same logical product on iOS + Android; same entitlement effect |

### 2.2 Resonance annual

| Field | Spec |
| --- | --- |
| Draft ID | `qmatch.resonance.annual` (`draft_ids_not_final`) |
| Store product type | Auto-renewable subscription / Subscription |
| Recurring / consumable | **Recurring** |
| Entitlement granted | Same as monthly (`resonance_access`) — longer `period_ends_at` only |
| Compatibility score | **Unchanged** |
| Consumable credit | **None** |
| Restore behavior | Same as monthly (subscription restore) |
| Backend verification mapping | Same path as monthly; duration from store period |
| Idempotency key | Same class as monthly (subscription identity + uid) |
| Platform parity | Required |

### 2.3 Resonance 3-month (deferred)

| Field | Spec |
| --- | --- |
| Draft ID | `qmatch.resonance.quarterly` (`draft_ids_not_final`) |
| Catalog class | **deferred** — not in first store creation set |
| Store product type | Auto-renewable subscription / Subscription |
| Recurring / consumable | **Recurring** |
| Entitlement granted | Same Resonance access as monthly/annual (if ever shipped) |
| Compatibility score | **Unchanged** |
| Consumable credit | **None** |
| Restore / verify / idempotency / parity | Same rules as other Resonance durations |

### 2.4 Subscription group (pre-creation expectation)

| Platform | Expectation |
| --- | --- |
| iOS | Single **Resonance** subscription group containing **monthly + annual only** at launch |
| Android | One Resonance family with **monthly + annual** base plans (exact Play modeling still needs decision) |

Upgrades/downgrades between durations stay inside the Resonance family — never create a second paid tier.

---

## 3. Consumable catalog

### 3.1 Super Resonance

| Field | Spec |
| --- | --- |
| Draft ID (day one) | `qmatch.super_resonance.x1` (`draft_ids_not_final`) |
| Store product type | Consumable (iOS) / Managed product **consumable** (Play) |
| Recurring / consumable | **Consumable** |
| Entitlement granted | Credit `super_resonance_balance` (+1 for x1) via trusted ledger — **not** `resonance_access` |
| Effect | Interest / signal visibility only — **never** alters compatibility score |
| Restore behavior | **Does not** restore as subscription. Unconsumed store purchases may credit ledger **only** after backend verify of unconsumed transaction; already-consumed units are not re-granted as Resonance |
| Backend verification mapping | Verify consumable purchase → idempotent ledger credit keyed by store transaction id |
| Idempotency key | `store_transaction_id` (or Play order/purchase token hash) — one credit per transaction |
| Platform parity | Same credit amount for same pack size on iOS + Android |

### 3.2 Boost (launch display name)

| Field | Spec |
| --- | --- |
| Draft ID (day one) | `qmatch.boost.x1` (`draft_ids_not_final`) |
| User-facing name | **Boost** (do **not** use Spotlight as launch display name) |
| Store product type | Consumable / managed consumable |
| Recurring / consumable | **Consumable** |
| Entitlement granted | Credit boost balance (+1 for x1) — **not** subscription |
| Effect | Temporary Discover exposure only — **never** alters compatibility score |
| Restore behavior | Same as Super Resonance — ledger credit if unconsumed + verified; never grants Resonance subscription |
| Backend verification mapping | Verify → idempotent boost ledger credit |
| Idempotency key | Store transaction id / purchase token — one credit per transaction |
| Platform parity | Same credit semantics both platforms |
| ×5 pack | `qmatch.boost.x5` — **deferred** |

### 3.3 Explicit non-mapping

| Must not happen | Why |
| --- | --- |
| Consumable restore → `tier = resonance` | Separates ledgers from subscription |
| Subscription buy → auto Super Resonance / Boost credits | No day-one allotments |
| Consumable spend without server | Entitlement contract: server-authoritative spends |

---

## 4. Entitlement mapping summary

| Product | Writes subscription fields | Writes consumable ledger | Sets `resonance_access` |
| --- | --- | --- | --- |
| `qmatch.resonance.monthly` | Yes | No | Yes (while active/grace/billing_retry) |
| `qmatch.resonance.annual` | Yes | No | Yes |
| `qmatch.resonance.quarterly` | Yes (if ever shipped) | No | Yes |
| `qmatch.super_resonance.x1` | No | `super_resonance_balance` | No |
| `qmatch.boost.x1` | No | boost balance | No |

Feature gates (`who_liked_you`, `rewind`, `deeper_compatibility`, …) follow subscription access per entitlement + paywall UX contracts. Consumable gates use balances only.

---

## 5. Restore semantics

| Action | Subscription products | Consumable products |
| --- | --- | --- |
| User taps Restore | Client → backend **re-verify** with store | Same entry may also scan for **unconsumed** consumable transactions |
| Backend | Upsert subscription snapshot | Credit only unverified-unconsumed purchases; idempotent |
| Already active Resonance | No-op / refresh period | N/A |
| Expired / revoked | Reflect deny states | Do not resurrect subscription via consumable |
| Free loop | Always remains usable | Always remains usable |

**Rule:** Restore never invents entitlement without store+backend verification ([Entitlement Contract §4](./qmatch_resonance_entitlement_engineering_contract_v1.md)).

---

## 6. Backend verification & idempotency

| Concern | Spec |
| --- | --- |
| Authority | Trusted backend verifies with App Store Server API / Play Developer API |
| Client | Sends purchase/restore payload; never self-grants |
| Subscription idempotency | Key on store subscription / original transaction identity + `uid` |
| Consumable idempotency | Key on store transaction / order id — at-most-once credit |
| Spend idempotency | Key on server spend `request_id` (separate from purchase credit) |
| Webhooks (future) | Renewal → keep/refresh `active`; expire → `expired`; refund/revoke → `revoked`; billing issues → `grace` / `billing_retry` per store mapping (exact mapping unresolved) |

---

## 7. Platform parity rules

| Rule | Spec |
| --- | --- |
| Feature parity | Same Resonance features and consumable effects on iOS and Android |
| ID parity | Prefer identical draft base IDs; document any forced divergence |
| Price parity | Not required in this draft (prices TBD); commercial parity is a later ops decision |
| Entitlement parity | Same `EntitlementSnapshot` semantics regardless of `platform` |
| Cross-platform unlock | **Unresolved** — catalog assumes per-platform purchase until linking policy is decided |
| Naming parity | User-facing: “Resonance”, “Super Resonance”, “**Boost**” (not Spotlight at launch) |

---

## 8. Checklist before real store creation

Do **not** create live SKUs until each applicable item is owned.

### 8.1 Identity & packaging

| Item | Notes |
| --- | --- |
| Bundle / package identity | iOS bundle id + Android application id match shipping apps |
| Signing / Play app integrity | Release signing ready |
| Store listing draft | Not blocked on catalog, but needed before public IAP |

### 8.2 Subscription setup

| Item | Notes |
| --- | --- |
| Subscription group (iOS) / subscription family (Play) | One Resonance family |
| Product naming | Internal + store display names (no IQ caste language) |
| Duration set | Decide monthly+annual; include quarterly only if `catalog_optional` accepted |
| Localization | EN + TR minimum (align app l10n); other locales TBD |
| Tax / category metadata | Store tax category / business model declarations |
| Grace / billing retry | Accept store defaults until exact mapping resolved |

### 8.3 Consumable setup

| Item | Notes |
| --- | --- |
| Consumable type confirmed | Not non-consumable / not subscription |
| Pack sizes | Day one: x1 only unless revised |
| Clear copy | Visibility/exposure — not score upgrades |

### 8.4 Commerce ops

| Item | Notes |
| --- | --- |
| Sandbox / license testers | Apple Sandbox + Play license testers |
| Paid Apps Agreement / merchant | Store agreements active |
| Prices | Still `TBD` — set only when pricing decision freezes |

### 8.5 Backend readiness (before enabling buys)

| Item | Notes |
| --- | --- |
| Backend verification credentials | App Store Connect API key / Play service account — secrets not in client |
| Idempotent purchase handlers | Subscription + consumable credit paths |
| Webhook / server notification setup | ASSN v2 + Play RTDN (or phased equivalent) for renew/expire/revoke |
| Entitlement snapshot writer | Only trusted backend writes grants |
| Restore endpoint | Always re-verifies |

### 8.6 Explicit non-checklist (out of scope here)

- Shipping paywall UI
- Ranking / scoring changes
- Creating final (non-draft) product IDs without a freeze review

---

## 9. Unresolved decisions

| Decision | Status |
| --- | --- |
| Final product IDs (replace `draft_ids_not_final`) | Unresolved |
| Prices / intro offers / trials | Unresolved (`TBD`) |
| Whether quarterly ships in first store launch | **Deferred** — not launch |
| Boost vs Spotlight **display** name | **Frozen: Boost** (Spotlight not launch display) |
| Exact Play subscription modeling (base plans) | Unresolved — see readiness checklist |
| Consumable pack SKUs (x5) | **Deferred** |

---

## 10. Exact next step

Follow [Store Creation Readiness v1](./qmatch_store_creation_readiness_v1.md): freeze final product ID strings for the **four launch SKUs**, assign checklist owners, decide Play base-plan structure, keep prices `TBD`, then sandbox-only creation when authorized.

Do **not** create Quarterly or ×5 packs. Do **not** implement billing code unless explicitly ordered.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Resonance monthly / annual launch; quarterly deferred | Yes (§1–2) |
| Super Resonance ×1 + Boost ×1 launch; ×5 deferred | Yes (§1, §3) |
| IDs marked `draft_ids_not_final` | Yes (§1) |
| No prices / no real store creation | Yes |
| Subscription ≠ consumable; no allotments; no score advantage | Yes |
| Restore / verify / idempotency / parity | Yes (§5–7) |
| Pre-creation checklist | Yes (§8) |
| Mapped to entitlement contract | Yes (§4) |
| Status | `store_catalog_draft_not_live` |
