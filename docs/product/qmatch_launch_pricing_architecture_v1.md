# QMatch Launch Pricing Architecture v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_launch_pricing_architecture_v1` |
| Status | `pricing_draft_not_live` |
| Parents | [Store Product Identity](./qmatch_store_product_identity_v1.md) · [Store Creation Readiness](./qmatch_store_creation_readiness_v1.md) · [Membership Contract](./qmatch_monetization_membership_contract_v1.md) · [Launch Packaging](./qmatch_resonance_launch_packaging_v1.md) |
| Scope | Candidate customer-facing price architecture for the **4 frozen launch products** |
| Non-goals | App code, store-console changes, net/P&L modeling, ranking/scoring, Quarterly / ×5 packs |
| Price status | All figures are **`candidate_not_frozen`** |
| Draft date | 2026-08-13 |

---

## 0. Purpose

Define **candidate** launch pricing so product can choose a positioning band before store SKUs go live.

Frozen products (identity ratified):

| Product | Canonical key |
| --- | --- |
| Resonance Monthly | `resonance_monthly` |
| Resonance Annual | `resonance_annual` |
| Super Resonance ×1 | `super_resonance_x1` |
| Boost ×1 | `boost_x1` |

**Status meaning:** pricing draft — not store truth, not ratified prices, not net revenue.

### Hard rules

| Rule | Spec |
| --- | --- |
| No competitor copy | Turkey anchors are **reference only** — do not mirror Hinge/Bumble/Tinder prices |
| No fake discounts | No artificial crossed-out “was” prices; annual savings must be real vs monthly |
| Customer price ≠ net | Do **not** assume one universal store commission; net modeling is separate |
| Free loop intact | Pricing must not imply paywall of match/chat/safety |
| No score monetization | Prices never buy better compatibility scores |
| No Quarterly / ×5 | Out of launch pricing scope |

---

## 1. Market anchors (reference only)

Current Turkey App Store **rough** observations (not targets to copy):

| Anchor | Rough TRY band | Use for QMatch |
| --- | --- | --- |
| Hinge-style subscriptions | ~600–1,200 | Upper bound of “full dating premium” |
| Bumble premium IAPs | ~100–600 (product/duration dependent) | Breadth of mid premium / packs |
| Tinder Boost | ~130 | Floor for short visibility bursts |

**Implication:** QMatch Resonance should feel **premium Cosmic**, but Free already delivers the full connection loop — so launch price should buy **control + insight depth**, not access to humans. Sitting *below* top Hinge subscription bands while staying *above* casual one-tap impulse floors is coherent.

---

## 2. Pricing principles

| Principle | Spec |
| --- | --- |
| Annual vs monthly | Annual is the same Resonance entitlement; discount is for prepay commitment only |
| Annual discount target | **~25–35%** vs `12 × monthly` (candidate band) |
| Consumables | À la carte; **not** included in subscription at launch |
| Super Resonance vs Boost | Super Resonance ≥ Boost (intentional signal > short exposure) |
| Regional principle | Localize list prices to store territories; do not hard-FX-lock TRY↔USD |
| Price-change policy | Change via store-scheduled price increase / new SKU; communicate honestly; never fake “sale” strikethrough without a real prior list price |
| Commission | Customer-facing tables are **gross**; Apple/Google fees and tax vary — model net separately |

---

## 3. Positioning scenarios (subscriptions)

All prices **gross customer-facing**, `candidate_not_frozen`.  
`effective_monthly_annual` = annual ÷ 12.  
`annual_discount` ≈ `1 − (annual / (12 × monthly))`.

### 3.1 Turkey TRY

#### Scenario A — Accessible launch

| SKU | Gross price | Effective / mo (annual) | Annual discount |
| --- | --- | --- | --- |
| Resonance Monthly | **TRY 449** | — | — |
| Resonance Annual | **TRY 3,499** | **~TRY 292** | **~35%** vs 12×449 |

| | |
| --- | --- |
| **Positioning** | Easy first yes; under typical top Hinge bands; still clearly paid |
| **Conversion vs ARPU** | Higher conversion / trial-of-paid mindset; lower ARPU; good for density phase |
| **Risk** | May undervalue Cosmic premium; harder to raise later without trust friction |

#### Scenario B — Balanced premium (**recommended candidate**)

| SKU | Gross price | Effective / mo (annual) | Annual discount |
| --- | --- | --- | --- |
| Resonance Monthly | **TRY 599** | — | — |
| Resonance Annual | **TRY 4,799** | **~TRY 400** | **~33%** vs 12×599 |

| | |
| --- | --- |
| **Positioning** | Premium but not “status caste”; aligns with insight + Who Liked You value |
| **Conversion vs ARPU** | Balanced: enough friction for intent, enough room for annual attach |
| **Risk** | Needs strong paywall honesty (already contracted) so Free users don’t feel baited |

#### Scenario C — High premium

| SKU | Gross price | Effective / mo (annual) | Annual discount |
| --- | --- | --- | --- |
| Resonance Monthly | **TRY 849** | — | — |
| Resonance Annual | **TRY 6,999** | **~TRY 583** | **~31%** vs 12×849 |

| | |
| --- | --- |
| **Positioning** | Near upper Turkish dating-premium band; signals exclusivity |
| **Conversion vs ARPU** | Lower conversion; higher ARPU if Free density is already healthy |
| **Risk** | Conflicts with “Free is complete product” story if paywalls feel aggressive |

---

### 3.2 Reference global USD

USD is a **planning reference**, not a FX conversion of TRY. Localize per store country later.

#### Scenario A — Accessible launch

| SKU | Gross | Effective / mo | Annual discount |
| --- | --- | --- | --- |
| Monthly | **$9.99** | — | — |
| Annual | **$69.99** | **~$5.83** | **~42%** vs 12×9.99 |

#### Scenario B — Balanced premium (**recommended candidate**)

| SKU | Gross | Effective / mo | Annual discount |
| --- | --- | --- | --- |
| Monthly | **$14.99** | — | — |
| Annual | **$99.99** | **~$8.33** | **~44%** vs 12×14.99 |

#### Scenario C — High premium

| SKU | Gross | Effective / mo | Annual discount |
| --- | --- | --- | --- |
| Monthly | **$19.99** | — | — |
| Annual | **$149.99** | **~$12.50** | **~37%** vs 12×19.99 |

Note: USD annual discounts in these candidates run a bit richer than the TRY 25–35% target; if parity of *discount story* is required, tighten USD annual toward ~$119.99 on the balanced monthly (≈33% off). **Preferred balanced USD annual alternate:** **$119.99** (~33% off $14.99×12) for discount-message consistency with TRY.

---

## 4. Annual discount model

| Field | Candidate rule |
| --- | --- |
| Target discount | **25–35%** vs twelve monthly payments (TRY primary) |
| Same entitlement | Annual = Monthly Resonance features (no extra allotments) |
| Messaging | “Save ~X% with annual” only when X is computed from **current** list prices |
| Forbidden | Fake “was TRY 9999” strikethrough; fake limited-time unless real |
| Upgrade path | Monthly → Annual via store subscription group / Play base-plan change (ops detail deferred) |

---

## 5. Consumable pricing (`candidate_not_frozen`)

Aligned to scenario bands. Super Resonance priced **above** Boost.

### 5.1 Turkey TRY

| Scenario | Super Resonance ×1 | Boost ×1 | Rationale |
| --- | --- | --- | --- |
| Accessible | **TRY 149** | **TRY 99** | Impulse-capable; Boost near low visibility floor without copying Tinder |
| Balanced (**recommended**) | **TRY 199** | **TRY 149** | Clear step above Boost; below heavy sub sticker shock |
| High premium | **TRY 299** | **TRY 199** | Premium impulse; may suppress consumable attach |

### 5.2 Reference USD

| Scenario | Super Resonance ×1 | Boost ×1 |
| --- | --- | --- |
| Accessible | **$3.99** | **$2.99** |
| Balanced (**recommended**) | **$4.99** | **$3.99** |
| High premium | **$6.99** | **$4.99** |

**Effects unchanged:** Super Resonance = interest visibility; Boost = exposure; neither changes compatibility score; neither grants Resonance subscription.

---

## 6. Recommended launch scenario

**Recommend Scenario B — Balanced premium** for Turkey primary launch.

| Why | |
| --- | --- |
| Brand | Matches Premium Cosmic Minimal without Hinge-top pricing |
| Product truth | Free already completes match/chat — price buys Who Liked You / Rewind / deeper explanations |
| Economics | Room for annual attach at ~33% without race-to-bottom |
| Consumables | TRY 199 / 149 leaves à la carte path without cannibalizing sub |

**Candidate Turkey launch sticker (still not frozen):**

| Product | Candidate gross |
| --- | --- |
| Resonance Monthly | TRY **599** |
| Resonance Annual | TRY **4,799** (~33% vs 12× monthly) |
| Super Resonance ×1 | TRY **199** |
| Boost ×1 | TRY **149** |

**Candidate USD reference (prefer discount-consistent annual):**

| Product | Candidate gross |
| --- | --- |
| Resonance Monthly | **$14.99** |
| Resonance Annual | **$119.99** (~33% off) *or* $99.99 if optimizing annual conversion over discount parity |
| Super Resonance ×1 | **$4.99** |
| Boost ×1 | **$3.99** |

---

## 7. Introductory pricing & free trial

| Lever | Launch recommendation | Rationale |
| --- | --- | --- |
| Free trial | **No trial at launch** | Free tier already includes assessments, Discover, match, chat, safety — trial mainly teaches “cancel after peek” and complicates Who Liked You honesty |
| Introductory subscription price | **Optional, annual-only, deferred past day-one** | If used later: real lower first-year annual, then standard list — never fake strikethrough |
| Consumable intro packs | **No** at launch | Avoid ×5 and confusing “starter packs” before ledger UX is proven |
| Promo codes | Deferred | Ops complexity |

If a trial is forced by store/experiment later: prefer **3–7 days Resonance**, hard stop, no extension spam; still no fake likes during trial teaser.

---

## 8. Regional / localized pricing principle

1. Set a **home-market** candidate (Turkey TRY) for narrative and founder review.  
2. Use store **territory pricing** / Apple & Google localization tools for other countries — not a single global FX multiply.  
3. Keep **relative structure** stable: Annual cheaper per month than Monthly; Super Resonance > Boost; sub ≫ single Boost.  
4. Revisit after 4–8 weeks of sandbox + early production data — price-change policy: honest schedule, no fake sales.

---

## 9. Net revenue (explicitly out of band)

Customer tables above are **gross**.  
Do **not** bake in 15%/30% or VAT assumptions here. Separate finance sheet should apply:

- platform commission by program (Small Business / standard)
- VAT/GST treatment by territory
- refund rate
- annual vs monthly mix

---

## 10. Unresolved decisions

| Decision | Status |
| --- | --- |
| Ratify Scenario A / B / C | Open — **B recommended** |
| Exact TRY stickers within scenario | `candidate_not_frozen` |
| USD annual $99.99 vs $119.99 | Open (discount parity vs conversion) |
| Intro annual offer | Deferred past launch (recommended) |
| Free trial | Recommended **no**; final call open |
| Per-country localization table | Deferred |
| Price-rise schedule | Deferred |
| Finance net model | Separate workstream |

---

## 11. Exact next step

**Write / run `docs/product/qmatch_launch_pricing_decision_v1.md` (decision record, still not live):**

1. Choose Scenario **A / B / C** (recommend B).  
2. Lock candidate TRY four-SKU sticker set (still may stay `candidate_not_frozen` until store create).  
3. Choose USD reference annual ($99.99 vs $119.99).  
4. Confirm **no trial** + **no fake discounts** for launch.  
5. Hand off stickers to readiness for sandbox SKU creation **when authorized** — no app code / no production console in that step unless ordered.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Three TRY + USD scenarios with discount / tradeoff | Yes (§3) |
| Annual discount model 25–35% (TRY) | Yes (§4) |
| Consumable Super ≥ Boost | Yes (§5) |
| Recommended balanced premium | Yes (§6) |
| Trial/intro stance | Yes (§7) — no trial; intro deferred |
| No fake discount / no universal commission | Yes |
| Prices `candidate_not_frozen` | Yes |
| Status | `pricing_draft_not_live` |
