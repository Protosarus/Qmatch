# QMatch Store Creation Readiness v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_store_creation_readiness_v1` |
| Status | `store_creation_readiness_v1` · `product_ratified_not_live` |
| Parents | [Store Product Catalog Draft](./qmatch_resonance_store_product_catalog_draft_v1.md) · [Entitlement Engineering Contract](./qmatch_resonance_entitlement_engineering_contract_v1.md) |
| Scope | Freeze launch SKU set + ownership/status checklist before any store-console creation |
| Non-goals | App code, App Store / Play Console changes, prices, billing implementation |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

This document is the **ratified** launch catalog + readiness score for what must be true before creating real store products.

Status classes (preserved):

| Class | Meaning |
| --- | --- |
| `ready` | Decision/source known enough to proceed without further product debate |
| `needs_decision` | Product/ops must choose before console creation |
| `needs_external_setup` | Requires Apple/Google/Firebase/ops account work |
| `blocked` | Depends on missing prerequisite (decision, credential, or prior setup) |

**Status meaning:** product-ratified readiness — launch SKU set is frozen. **Not live** in stores. **Does not authorize console SKU creation** until blockers clear and owners mark items ready.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Launch subscriptions | Resonance Monthly · Resonance Annual |
| Launch consumables | Super Resonance ×1 · Boost ×1 |
| Deferred | Resonance Quarterly · ×5 consumable packs |
| Display name | **Boost** (not Spotlight) |
| Prices | Remain `TBD` |
| Product IDs | **Final** per [Store Product Identity v1](./qmatch_store_product_identity_v1.md) — console creation still not authorized |
| Console | **No** store-console creation yet |
| External setup | Tracked by readiness matrix classifications |
| Play model | `qmatch.resonance` + base plans `monthly`/`annual` (**decided**) |

---

## 1. Frozen launch catalog

### 1.1 Subscriptions

| Product | Launch class | Draft ID (`draft_ids_not_final`) |
| --- | --- | --- |
| Resonance Monthly | **launch** | `qmatch.resonance.monthly` |
| Resonance Annual | **launch** | `qmatch.resonance.annual` |
| Resonance Quarterly | **deferred** | `qmatch.resonance.quarterly` (kept in catalog as deferred only) |

### 1.2 Consumables

| Product | Launch class | Draft ID (`draft_ids_not_final`) | User-facing name |
| --- | --- | --- | --- |
| Super Resonance ×1 | **launch** | `qmatch.super_resonance.x1` | Super Resonance |
| Boost ×1 | **launch** | `qmatch.boost.x1` | **Boost** |
| Super Resonance ×5 | **deferred** | `qmatch.super_resonance.x5` | — |
| Boost ×5 | **deferred** | `qmatch.boost.x5` | — |

### 1.3 Naming freeze

| Surface | Decision |
| --- | --- |
| User-facing consumable name | **Boost** |
| “Spotlight” | **Not** used as launch display name |
| Internal/family token | Prefer `boost` in new IDs; legacy `boost_spotlight` wording in older drafts is superseded for launch |

### 1.4 Still not frozen

| Item | Status |
| --- | --- |
| Final store product IDs | **Frozen** — see [Store Product Identity v1](./qmatch_store_product_identity_v1.md) |
| Subscription consumable allotments | **None** (no day-one allotments) |
| Play subscription model | **Frozen** — one `qmatch.resonance` + `monthly`/`annual` base plans |

---

## 2. Readiness matrix

Owner column uses role placeholders until named assignees exist.

| # | Checklist item | Class | Owner | Notes / evidence |
| --- | --- | --- | --- | --- |
| 1 | Final iOS bundle identity | `ready` | Eng / Release | Source: `com.qmatch.app` (Runner). Confirm App Store Connect app record matches before SKU create |
| 2 | Final Android package identity | `ready` | Eng / Release | Source: `com.qmatch.app`. Confirm Play app record + `google-services.json` match before SKU create |
| 3 | App Store subscription group | `needs_external_setup` | iOS ops | Create one **Resonance** group; attach Monthly + Annual only |
| 4 | Play subscription / base-plan structure | `needs_external_setup` | Android ops | **Decided:** product `qmatch.resonance` + base plans `monthly`/`annual` ([Identity](./qmatch_store_product_identity_v1.md)). Remaining: create in Play Console when authorized |
| 5 | Final product IDs | `ready` | Product + Eng | **Frozen** in [Store Product Identity v1](./qmatch_store_product_identity_v1.md). Console create still blocked on other items |
| 6 | Product display names / descriptions | `needs_decision` | Product / Copy | EN/TR copy; no IQ caste / score-upgrade claims; Boost not Spotlight |
| 7 | TR/EN localization | `needs_decision` | Product / L10n | Store listing + IAP display strings for launch SKUs |
| 8 | Tax / category metadata | `needs_external_setup` | Store ops | Apple/Google tax category + business declarations |
| 9 | Sandbox / test accounts | `needs_external_setup` | QA / Ops | Apple Sandbox + Play license testers |
| 10 | App Store server notification setup | `needs_external_setup` | Backend | ASSN v2 endpoint for renew / expire / revoke |
| 11 | Google Play Developer API / RTDN setup | `needs_external_setup` | Backend | Purchase verify + Real-time developer notifications |
| 12 | Backend verification credentials | `needs_external_setup` | Backend / SecOps | App Store Connect API key + Play service account — never in client |
| 13 | Refund / revoke handling | `needs_decision` + `blocked` | Backend + Product | Behavior contracted (`revoked` deny); **implementation + webhook wiring** not live → blocked on #10–12 |
| 14 | Restore-purchase test plan | `needs_decision` | QA + Eng | Plan can be written now; execution blocked until sandbox SKUs + verify path exist |
| 15 | Consumable idempotency test plan | `needs_decision` | QA + Eng | Plan: double-credit attempt, retry, restore unconsumed; execution blocked on #9–12 |
| 16 | Ownership / status for each item | `needs_decision` | Product lead | Assign named humans to Owner column; roles above are placeholders |

### 2.1 Class rollup

| Class | Items |
| --- | --- |
| `ready` | #1 iOS bundle identity (source), #2 Android package identity (source), **#5 final product IDs** |
| `needs_decision` | #6 names/descriptions, #7 localization, #13 (ops policy details), #14–16 plans/ownership |
| `needs_external_setup` | #3, **#4** (model decided; console create pending), #8, #9, #10, #11, #12 |
| `blocked` | #13 implementation until verification credentials + notifications exist; #14–15 **execution** until sandbox + backend verify |

---

## 3. External setup required

Must be completed outside this repo before production-capable IAP:

1. App Store Connect — app record, Resonance subscription group, Monthly + Annual products (IDs frozen)
2. Google Play Console — app record, subscription `qmatch.resonance` + base plans `monthly`/`annual` (model frozen)
3. Tax / merchant / paid-apps agreements
4. Sandbox / license test accounts
5. ASSN v2 URL + auth
6. Play RTDN + Developer API credentials
7. Backend secrets for receipt/purchase verification
8. Matching Firebase / signing configs for `com.qmatch.app` on both stores

---

## 4. Blockers (cannot create production SKUs yet)

| Blocker | Why |
| --- | --- |
| Prices `TBD` | Cannot publish paid SKUs without pricing decision (sandbox may use placeholder prices later) |
| Play / App Store products not created | #3/#4 still `needs_external_setup` (identity decided) |
| No backend verification credentials | Entitlement contract forbids client self-grant |
| No store server notifications | Renew/expire/revoke path incomplete |
| Refund/revoke handling not implemented | Contract exists; code/ops path missing |
| Named owners incomplete | Checklist #16 |
| Display copy / localization | #6/#7 still `needs_decision` |

**Allowed later without clearing all blockers:** writing test plans (#14–15 as documents), drafting EN/TR copy offline, sandbox-only experiments **after** explicit order — still **no** production console creation from this draft.

---

## 5. Launch SKU entitlement reminder

| Launch SKU | Entitlement effect |
| --- | --- |
| Resonance Monthly / Annual | `resonance_access` while active/grace/billing_retry — **no** score advantage, **no** consumable allotments |
| Super Resonance ×1 | Credit `super_resonance_balance` only |
| Boost ×1 | Credit boost balance only (display **Boost**) |

Deferred SKUs must not appear in first console creation set.

---

## 6. Exact next step

**Pricing + credentials path (still no console create unless ordered):**

1. Open a **pricing** decision — keep `TBD` here until decided.
2. Assign named owners for readiness matrix §2 (#16).
3. Start App Store Connect API / Play service account + ASSN/RTDN setup (#10–12).
4. Draft EN/TR display names (#6–7).
5. Only when credentials path started and (for production) prices decided: create **sandbox** products using [Store Product Identity v1](./qmatch_store_product_identity_v1.md).

Do **not** create Quarterly or x5 packs. Do **not** implement app billing code unless explicitly ordered.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Monthly + Annual launch; Quarterly deferred | Yes (§1.1) |
| Super Resonance x1 + Boost x1 launch; x5 deferred | Yes (§1.2) |
| Display name Boost; no Spotlight launch name | Yes (§1.3) |
| Prices TBD; IDs draft until creation | Yes (§1.4) |
| 16-item readiness matrix with classes | Yes (§2) |
| No store-console / app code in this step | Yes |
| Status | `store_creation_readiness_v1` · `product_ratified_not_live` |
