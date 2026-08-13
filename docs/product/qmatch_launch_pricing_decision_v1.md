# QMatch Launch Pricing Decision v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_launch_pricing_decision_v1` |
| Status | `launch_pricing_decision_v1` · `product_ratified_not_live` |
| Parents | [Launch Pricing Architecture v1](./qmatch_launch_pricing_architecture_v1.md) · [Store Product Identity v1](./qmatch_store_product_identity_v1.md) · [Store Creation Readiness v1](./qmatch_store_creation_readiness_v1.md) |
| Scope | Ratified **Balanced Premium** launch pricing for the four frozen launch SKUs |
| Non-goals | App code, store-console changes, country price tables, net/P&L, ranking/scoring |
| Decision date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Decision

**Adopt Balanced Premium** as the ratified launch pricing (from [Pricing Architecture](./qmatch_launch_pricing_architecture_v1.md) Scenario B).

| Field | Value |
| --- | --- |
| Scenario | Balanced premium |
| Price status | **Product-ratified gross stickers** — not store-live until console create is authorized |
| Entitlement | Monthly and Annual grant the **same** Resonance access |
| Trial | **No** free trial at launch |
| Intro pricing | **No** introductory pricing at launch |
| Display | **No** fake crossed-out / artificial “was” prices |
| Regional | Localized territorial pricing — **not** direct FX conversion |

**Status meaning:** product-ratified pricing decision. **Not live** in App Store / Play. Does **not** authorize store-console creation — follow [Store Creation Readiness](./qmatch_store_creation_readiness_v1.md).

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Turkey | Monthly TRY 599 · Annual TRY 4,799 · Super Resonance TRY 199 · Boost TRY 149 |
| USD reference | Monthly 14.99 · Annual 119.99 · Super Resonance 4.99 · Boost 3.99 |
| Annual discount | **~33%** vs 12× monthly |
| Trial / intro | None at launch |
| Fake discounts | Forbidden |
| Entitlement | Monthly ≡ Annual Resonance access |
| Unresolved | Country store tables · net/commission/tax · final console territory pricing |

---

## 1. Selected customer-facing pricing

### 1.1 Turkey (primary narrative market)

| Product | Canonical key | Gross price |
| --- | --- | --- |
| Resonance Monthly | `resonance_monthly` | **TRY 599** |
| Resonance Annual | `resonance_annual` | **TRY 4,799** |
| Super Resonance ×1 | `super_resonance_x1` | **TRY 199** |
| Boost ×1 | `boost_x1` | **TRY 149** |

### 1.2 Global USD reference

USD is a **reference band** for planning — not a hard FX conversion of TRY. Other territories use localized store pricing.

| Product | Canonical key | Gross price |
| --- | --- | --- |
| Resonance Monthly | `resonance_monthly` | **USD 14.99** |
| Resonance Annual | `resonance_annual` | **USD 119.99** |
| Super Resonance ×1 | `super_resonance_x1` | **USD 4.99** |
| Boost ×1 | `boost_x1` | **USD 3.99** |

---

## 2. Annual economics

| Market | Monthly | 12 × monthly | Annual list | Effective / mo | Discount vs 12× monthly |
| --- | --- | --- | --- | --- | --- |
| Turkey | TRY 599 | TRY 7,188 | TRY 4,799 | **~TRY 400** | **~33.2%** |
| USD reference | USD 14.99 | USD 179.88 | USD 119.99 | **~USD 10.00** | **~33.3%** |

| Freeze | Spec |
| --- | --- |
| Discount target | **~33%** annual vs twelve monthly payments |
| Entitlement parity | Annual = Monthly Resonance features (no extra consumable allotments) |
| Messaging | May say “save ~33% with annual” only while list prices match this table |

---

## 3. Consumable pricing

| Product | Turkey | USD reference | Ledger effect |
| --- | --- | --- | --- |
| Super Resonance ×1 | TRY **199** | USD **4.99** | `super_resonance_balance` +1 only |
| Boost ×1 | TRY **149** | USD **3.99** | boost balance +1 only |

| Rule | Spec |
| --- | --- |
| Ordering | Super Resonance ≥ Boost |
| Subscription | Consumables **not** included at launch |
| Compatibility score | **Never** modified by either consumable |
| Display name | Boost (not Spotlight) |

---

## 4. Regional pricing rule

| Rule | Spec |
| --- | --- |
| Principle | **Localized** territorial pricing via App Store / Play tools |
| Not allowed as primary method | Direct FX multiply from TRY or USD into every country |
| Structure to preserve | Annual cheaper per month than Monthly; Super Resonance > Boost; sub ≫ single Boost |
| Home narrative | Turkey TRY stickers are the founder/product review baseline |
| Price changes | Honest store-scheduled changes only; no fake sale strikethrough |

---

## 5. Launch policy freezes

| Policy | Decision |
| --- | --- |
| Free trial | **No** at launch |
| Introductory annual discount | **No** at launch |
| Fake crossed-out pricing | **Forbidden** |
| Monthly vs annual entitlement | **Identical** Resonance access |
| Quarterly / ×5 packs | Still **deferred** (not priced here) |

---

## 6. Unresolved finance / store display items

| Item | Status |
| --- | --- |
| Formal `product_ratified` of these stickers | **Done** — `launch_pricing_decision_v1` · `product_ratified_not_live` |
| Country-by-country store price tables | Unresolved — localize later |
| Net revenue / commission model | Unresolved — separate from gross stickers; no universal fee assumed |
| Tax-inclusive display behavior per store | Unresolved — follow Apple/Google territory rules at create time |
| Final store-console territory pricing | Unresolved — enter at sandbox/production create time |
| Sandbox / production console entry | Blocked on readiness (credentials, notifications, owners, etc.) |

---

## 7. Exact next step

1. Keep readiness **pricing decision = ready**; console creation **still not authorized**.  
2. Assign named readiness owners (#16).  
3. Start verification credentials + ASSN/RTDN (#10–12).  
4. Draft EN/TR display names (#6–7).  
5. When authorized: create **sandbox** SKUs using [Identity](./qmatch_store_product_identity_v1.md) + these gross stickers.  

Do **not** implement app billing code or production store products unless explicitly ordered.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Balanced Premium adopted | Yes |
| TRY + USD four-SKU tables | Yes (§1) |
| ~33% annual discount | Yes (§2) |
| No trial / no intro / no fake strikethrough | Yes (§5) |
| Localized regional principle | Yes (§4) |
| Finance items unresolved listed | Yes (§6) |
| Status | `launch_pricing_decision_v1` · `product_ratified_not_live` |
