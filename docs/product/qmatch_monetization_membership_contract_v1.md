# QMatch Monetization & Membership Contract v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_monetization_membership_contract_v1` |
| Status | `monetization_membership_contract_v1` · `product_ratified_not_live` |
| Scope | Launch membership architecture — product contract only |
| Non-goals | App code, billing SDKs, paywalls, prices, exact Like quotas, ranking/scoring changes |
| Supersedes for v1 architecture | Directional MVP slice of [Monetization Strategy Report](../qmatch_monetization_strategy_report.md) (Plus / Orbit are **not** v1 tiers) |
| Related | Live match lifecycle, Discover, Messages, closed-account chat history, Persona / RVI / temporal / QI shadow docs |
| Draft freeze date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

This document is the **ratified** launch membership architecture so product, design, and engineering share one entitlement vocabulary before any IAP / entitlement implementation.

This contract answers:

1. What Free **must** always include
2. What Resonance **may** sell
3. Which consumables exist in v1
4. What monetization patterns are **prohibited**
5. Which decisions remain **deferred**

**Status meaning:** product-ratified contract — binding for planning and packaging. **Not live** in app, stores, or backend entitlements until a separate engineering + packaging ship.

### Ratification lock (2026-08-13)

The following are **frozen** under `product_ratified_not_live`:

| Lock | Rule |
| --- | --- |
| Tiers | **Free + Resonance only** for v1 (no third subscription tier) |
| Consumables | **Super Resonance** + **Boost / Spotlight** only |
| Matching quality | Core structural matching quality stays available to **Free** |
| Social loop | Mutual match, post-match chat, and safety stay **Free** |
| Access gating | No IQ / EQ / Persona premium access gating |
| Shadow honesty | No temporal / QI marketing claims while those signals remain shadow-only |
| Consumable purity | Consumables **never** modify compatibility scores |

Deferred items in §9 stay deferred (prices, quotas, allotments, Boost vs Spotlight naming, paywall tease UX, IAP engineering).

---

## 1. Launch tier architecture (frozen)

### 1.1 Subscription tiers in v1

| Tier | Role |
| --- | --- |
| **Free** | Complete connection loop; default for every account |
| **Resonance** | Sole paid subscription; discovery control, insight depth, visibility tools |

**Hard rule:** no third subscription tier in v1 (no Plus, Orbit, Platinum, or mid-tier SKU).

### 1.2 Consumables in v1

| Consumable | Role |
| --- | --- |
| **Super Resonance** | Stronger / clearer intentional interest signal to a peer |
| **Boost / Spotlight** | Temporary Discover exposure increase |

Consumables may be sold à la carte to Free or Resonance users. Optional monthly allotments for Resonance subscribers are allowed later as packaging — they do **not** create a new tier.

### 1.3 What “membership” is not

Membership is **not**:

- access to “better” or “higher IQ/EQ” people
- a Persona-gated matching key
- a paywall on core structural compatibility quality
- a claim that temporal / QI shadow signals are proven premium compatibility

---

## 2. Product principles (frozen)

### P1 — Free must be a complete product

Free users can onboard, assess, Discover, mutual-match, message after match, and use all safety/block tools without paying.

### P2 — Pay for control, depth, and attention — not humans

Resonance and consumables sell **tools** (filters, rewind, who liked you, insight depth, visibility). They never sell access to a caste of users.

### P3 — Core matching quality stays free

Core structural matching / compatibility used for Discover ranking and mutual match eligibility must remain available on Free. Monetization may deepen **explanations** and **controls**, not replace free matching with a paid “better algorithm.”

### P4 — Persona is free brand identity, not a premium key

Persona completion, reveal, and use as product identity remain Free. Persona must not become a paid matching gate or Resonance-only ranking feature.

### P5 — Shadow / research signals stay honest

Temporal, quantum-inspired (QI), modal/wave, and other **shadow / non-live** signals must not be marketed as proven premium compatibility. If surfaced later, they require separate product + scientific honesty review — default class: **deferred**.

### P6 — Consumables change visibility / interest, not scores

- **Super Resonance** changes **interest visibility / signaling**, not compatibility score.
- **Boost / Spotlight** changes **exposure**, not compatibility score.

### P7 — Safety is never monetized

Block, report, unmatch, account controls, and related safety remain Free forever.

### P8 — No v1 pricing or quota lock yet

This contract freezes **architecture and entitlement classes**, not prices and not final daily Like counts.

---

## 3. Entitlement classes

Every feature in this contract is classified as exactly one of:

| Class | Meaning |
| --- | --- |
| **Free** | Available without subscription or consumable purchase |
| **Resonance** | Requires active Resonance subscription |
| **consumable** | Requires Super Resonance or Boost/Spotlight spend (or a subscriber allotment of that consumable) |
| **deferred** | Not in launch entitlement surface; may return in a later contract |

Tease / locked UI for Resonance features on Free is allowed if it does not break Free’s complete loop.

---

## 4. Free entitlement set (must include)

| Feature | Class | Notes |
| --- | --- | --- |
| Account create / login / session restore | Free | |
| Full onboarding | Free | |
| IQ assessment | Free | |
| EQ assessment | Free | |
| Frequency assessment | Free | |
| Persona (complete / reveal / profile identity) | Free | Not a premium matching key |
| Profile setup / photos / Cosmic profile hero | Free | Never paywall identity hero |
| Basic compatibility score / label on Discover cards | Free | Core structural quality not paywalled |
| Core Discover feed | Free | Volume limits TBD (deferred numbers) |
| Like / Pass on Discover | Free | Allowance TBD (deferred numbers) |
| Mutual match creation | Free | |
| Match-success UX → Open chat / Continue | Free | |
| Messaging after mutual match | Free | History + send on active threads |
| Closed / unavailable chat history safeguards | Free | Read-only / safety UX as product already defines |
| Basic peer profile viewing in matched context | Free | Subject to match/safety rules |
| Block | Free | |
| Report | Free | |
| Unmatch | Free | |
| Settings / privacy policy / account deletion request | Free | |
| Localization of core loop | Free | |

**Free feeling:** usable, intentional, slightly scarce on volume — never broken or “demo-only.”

---

## 5. Resonance entitlement set (may add)

Resonance **may** include any of the following. Packaging can ship a subset at first Resonance launch; items listed here are **in-scope for Resonance**, not a mandatory day-one checklist.

| Feature | Class | Notes |
| --- | --- | --- |
| Who Liked You (who aligned with you) | Resonance | Headline paid discovery control |
| Advanced preference / filter controls | Resonance | Style / range / preference language — **not** IQ caste filters |
| Rewind (undo last Pass / Like) | Resonance | |
| Higher Like allowance | Resonance | Exact count deferred |
| Higher Discover volume / refresh | Resonance | Exact count deferred |
| Deeper compatibility explanations | Resonance | Insight depth on top of free basic score |
| Shared-values / resonance narrative depth | Resonance | Presentation second to Cosmic trust |
| Advanced visibility / privacy controls | Resonance | Presence controls beyond basic settings |
| Saved filter sets / preference presets | Resonance | Optional packaging |
| Top daily high-compatibility picks (curated) | Resonance | Curated by free-quality matching — not paid human caste |
| Subscriber packaging of consumable credits | Resonance | Allotments of Super Resonance / Boost — still **consumable** semantics |

**Explicitly not Resonance-exclusive:**

- Assessments, Persona, mutual match, chat after match, safety
- Core structural matching quality / score used for ranking
- Access to “higher IQ/EQ” users

---

## 6. Consumables

### 6.1 Super Resonance

| Field | Contract |
| --- | --- |
| Class | consumable |
| Effect | Strengthens / clarifies intentional interest **visibility** to a peer (signal salience) |
| Does **not** | Change compatibility score, Discover ranking formula, or Persona |
| Available to | Free and Resonance (à la carte); Resonance may include allotments later |
| Abuse guard (product) | Rate / spam limits deferred; must not coerce |

### 6.2 Boost / Spotlight

| Field | Contract |
| --- | --- |
| Class | consumable |
| Effect | Temporary increase in Discover **exposure** (attention burst) |
| Does **not** | Change compatibility score or imply higher human quality |
| Available to | Free and Resonance (à la carte); Resonance may include allotments later |
| Naming | “Boost” and “Spotlight” are one v1 consumable family (final UX name deferred) |

### 6.3 Out of v1 consumable catalog

| Item | Class |
| --- | --- |
| Deep Insight Report (standalone) | deferred |
| Extra Discover pack | deferred |
| Passport / city mode packs | deferred |
| Profile frame / Orbit cosmetics | deferred |

---

## 7. Full feature classification matrix

| Feature | Class |
| --- | --- |
| Onboarding | Free |
| IQ / EQ / Frequency assessments | Free |
| Persona | Free |
| Profile + photos + CosmicProfileHero | Free |
| Basic compatibility score / Discover card label | Free |
| Core Discover | Free |
| Like / Pass | Free |
| Mutual match + match-success chat entry | Free |
| Messaging after match | Free |
| Block / report / unmatch / safety | Free |
| Settings / account deletion request | Free |
| Who Liked You | Resonance |
| Advanced preference / filter controls | Resonance |
| Rewind | Resonance |
| Higher Like allowance | Resonance |
| Higher Discover volume | Resonance |
| Deeper compatibility explanations | Resonance |
| Advanced visibility / privacy controls | Resonance |
| Top daily curated high-compatibility picks | Resonance |
| Super Resonance | consumable |
| Boost / Spotlight | consumable |
| Exact prices / store SKUs | deferred |
| Exact daily Like / Discover quotas | deferred |
| Resonance monthly allotment sizes | deferred |
| Plus / Orbit / third subscription tier | deferred *(forbidden in v1)* |
| Passport / location exploration | deferred |
| Temporal / QI / wave-state as marketed premium compatibility | deferred *(and prohibited as “proven” claims)* |
| Selling access to higher IQ/EQ users | deferred *(prohibited forever — see §8)* |
| Ads / ATT-funded monetization | deferred |
| Server entitlement schema / IAP wiring | deferred |

---

## 8. Prohibited monetization patterns

These are **out of bounds** for v1 and should remain out of bounds unless a future ethics + legal review explicitly overrides this contract.

1. **Sell access to “higher IQ / EQ” users** or any cognitive/emotional caste in Discover.
2. **Persona as a premium matching key** — paid-only Persona scoring, ranking, or match eligibility.
3. **Paywall core structural matching quality** — Free must receive the same core match quality class; paid may add explanation depth and controls only.
4. **Market temporal / QI / modal / wave shadow signals as proven premium compatibility.**
5. **Let Super Resonance mutate compatibility score** — interest visibility only.
6. **Let Boost / Spotlight mutate compatibility score** — exposure only.
7. **Ship a third subscription tier in v1.**
8. **Paywall mutual match, post-match messaging, or safety/block/report.**
9. **Paywall CosmicProfileHero / basic human identity presentation.**
10. **Humiliating scoreboards** (low/high IQ status ranking, emotional-maturity shaming castes).
11. **Imply clinical IQ/EQ diagnosis** or medical assessment in monetization copy.
12. **Hard-paywall assessments** required to complete the brand loop.

---

## 9. Deferred decisions

Frozen as **not decided in this contract**:

| Decision | Why deferred |
| --- | --- |
| Prices (monthly / yearly / consumable packs) | Store readiness + market test |
| Exact Free daily Like count | Needs retention + density data |
| Exact Free Discover stack size / refresh | Same |
| Exact Resonance Like / Discover multipliers | Packaging after Free baseline |
| Whether Resonance includes monthly Super Resonance / Boost credits | Packaging choice |
| Final Boost vs Spotlight display name | Brand copy |
| Who Liked You tease UX for Free | Design |
| Deep Insight Report packaging | Post-Resonance validation |
| Plus / Orbit as future tiers | Only after Resonance proves value |
| Server entitlement field names / receipt verify | Engineering contract later |
| Platform launch order (Android vs iOS IAP) | Ops / Apple membership |
| Any live use of temporal / QI in paid UI | Research honesty gate |

---

## 10. Relationship to matching / Persona / shadow systems

| System | Membership rule |
| --- | --- |
| Discover L1 eligibility / live match validity | Free; not monetized |
| Core structural compatibility | Free quality; Resonance may deepen **explanations** |
| Persona | Free identity; not premium matching key |
| RVI / relationship-value layers | Insight presentation may deepen under Resonance; must not invent paid human castes |
| Temporal / QI / wave / modal **shadow** | Not live premium claims; deferred |
| Ranking / scoring mathematics | **Out of scope** for this contract — no score changes implied |

---

## 11. Implementation non-goals (this document)

Do **not** treat ratification as authorization to:

- add billing packages / IAP
- write entitlement flags in Firestore from the client alone
- ship paywall UI
- change ranking / scoring / Persona / RVI / temporal / QI code
- commit prices or quotas as product truth

A separate **entitlement engineering contract** should follow once Free/Resonance packaging for the first paid ship is chosen.

---

## 12. Exact next product step

**Write `docs/product/qmatch_resonance_launch_packaging_v1.md` (still product-only):**

1. Choose the **minimum Resonance day-one feature set** from §5 (recommended headline: Who Liked You + Rewind + deeper explanations; filters/allowance as capacity allows).
2. Keep Super Resonance + Boost/Spotlight as the only consumables.
3. Propose **candidate** (non-final) Like/Discover quota ranges for Free vs Resonance — labeled `candidate_not_frozen`.
4. Define Free tease rules for Who Liked You without breaking the Free loop.
5. Explicitly restate §8 prohibitions in launch copy guidelines.

Do **not** implement app code, billing, or ranking changes in that step.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Free includes assessments + Persona + Discover + match + chat + safety | Yes (§4) |
| Resonance is sole paid subscription in v1 | Yes (§1.1) |
| Consumables = Super Resonance + Boost/Spotlight | Yes (§1.2, §6) |
| No third subscription tier in v1 | Yes |
| No final prices / Like counts | Deferred (§9) |
| No selling higher IQ/EQ access | Prohibited (§8) |
| Persona not premium matching key | Prohibited / Free (§2 P4, §8) |
| Core structural match quality not paywalled | Prohibited / Free (§2 P3, §8) |
| Temporal/QI not proven premium compatibility | Prohibited / deferred (§2 P5, §8) |
| Super Resonance / Boost do not change compatibility score | Frozen (§2 P6, §6) |
| Status | `monetization_membership_contract_v1` · `product_ratified_not_live` |
