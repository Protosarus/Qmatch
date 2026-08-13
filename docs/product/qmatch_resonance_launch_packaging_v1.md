# QMatch Resonance Launch Packaging v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_resonance_launch_packaging_v1` |
| Status | `resonance_launch_packaging_v1` · `product_ratified_not_live` |
| Parent | [Monetization & Membership Contract v1](./qmatch_monetization_membership_contract_v1.md) (`product_ratified_not_live`) |
| Scope | Minimum **day-one** Resonance subscription package + Free teaser / paywall placement rules |
| Non-goals | App code, IAP, final prices, ranking/scoring changes, third tier, temporal/QI claims |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

This document is the **ratified** day-one Resonance package so product, design, and engineering share one packaging vocabulary before paywall UX and IAP work.

It classifies Resonance candidates as `launch_required` | `launch_optional` | `deferred`. Numbers labeled `candidate_not_frozen` remain planning ranges only.

**Status meaning:** product-ratified packaging — binding for day-one Resonance scope. **Not live** in app, stores, or entitlements until engineering ships.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| `launch_required` | **Who Liked You** · **Rewind** · **deeper compatibility explanations** |
| `launch_optional` | Advanced preference/filter controls · higher Like allowance |
| `deferred` | Advanced visibility/privacy · Discover multipliers · consumable allotments · curated picks/presets · third tier |
| Consumables | **Super Resonance** + **Boost/Spotlight** remain **separate** à la carte (no day-one allotments) |
| Teasers | **No fake teaser data** (no invented likes / fabricated insight bodies) |
| Free loop | Core Discover · mutual match · chat · safety remain **fully Free** |
| Quotas | Like/Discover ranges stay `candidate_not_frozen` (§5) |

---

## 1. Non-negotiable inheritance (from ratified contract)

| Rule | Implication for packaging |
| --- | --- |
| Free + Resonance only | No Plus / Orbit SKU |
| Core structural matching quality Free | Resonance does not get a “better algorithm” |
| Mutual match + chat + safety Free | Never paywall the connection loop |
| No IQ / EQ / Persona premium gating | Filters/copy must not sell cognitive castes |
| No temporal / QI marketing while shadow-only | Packaging copy stays silent on those signals |
| Consumables never change compatibility scores | Super Resonance / Boost stay visibility tools |
| No final prices | This doc has no price table |

---

## 2. Day-one Resonance package

### 2.1 Feature classification

| Feature | Class | Rationale |
| --- | --- | --- |
| **Who Liked You** | `launch_required` | Headline paid discovery control; clearest Free→Resonance reason |
| **Rewind** | `launch_required` | Immediate, tangible Discover QoL; low conceptual ambiguity |
| **Deeper compatibility explanations** | `launch_required` | Monetizes **insight depth** on top of free basic score — not match quality |
| **Advanced preference / filter controls** | `launch_optional` | High value; heavier UX + preference schema; ship if capacity allows after required three |
| **Higher Like allowance** | `launch_optional` | Needs quota system; valuable but not required for “insight + who liked you” story |
| **Advanced visibility / privacy controls** | `deferred` | Important trust surface; not a day-one conversion headline; avoid blocking Resonance MVP |

### 2.2 Minimum day-one ship set (`launch_required`)

Resonance day one **must** include all three:

1. Who Liked You (who aligned with you)
2. Rewind (undo last Pass / Like)
3. Deeper compatibility explanations (beyond Free basic score/label)

**Day-one story:** “See who aligned with you, undo a miss, understand the connection more deeply.”

### 2.3 Launch-optional (same release if capacity)

| Feature | Ship rule |
| --- | --- |
| Advanced preference / filter controls | Include if filter UX can ship without IQ/EQ caste language and without changing Free core ranking quality |
| Higher Like allowance | Include only with an explicit Free baseline quota (`candidate_not_frozen` §5); otherwise defer with the feature |

Optional features must not delay the required three.

### 2.4 Deferred (not day-one Resonance)

| Feature | Class | Notes |
| --- | --- | --- |
| Advanced visibility / privacy controls | `deferred` | Later packaging / settings polish |
| Higher Discover volume / refresh (beyond Like allowance) | `deferred` | Separate from Like quota; decide after Free baseline density |
| Saved filter presets | `deferred` | After advanced filters exist |
| Top daily curated picks | `deferred` | After Who Liked You proves conversion |
| Shared-values narrative archive / timeline | `deferred` | Insight packaging v2 |
| Resonance monthly Super Resonance / Boost allotments | `deferred` | See §6 — day one keeps consumables separate |
| Plus / Orbit / third tier | `deferred` *(forbidden in v1)* | |

---

## 3. What must remain fully Free

These surfaces stay fully usable without Resonance or consumables:

| Surface | Free rule |
| --- | --- |
| Onboarding + IQ / EQ / Frequency | Full access |
| Persona | Full access; not a paid matching key |
| Profile / photos / CosmicProfileHero | Full access |
| Basic compatibility score / card label | Full access — **same core matching quality class** |
| Core Discover | Full access (volume may be limited; quality not downgraded) |
| Like / Pass | Full access within Free allowance |
| Mutual match + match-success Open chat | Full access |
| Messaging after match | Full access on active / product-allowed threads |
| Block / report / unmatch / safety | Full access |
| Settings / account deletion request | Full access |

**Hard rule:** Free users must never lose mutual match, chat, safety, assessments, Persona, or core structural match quality to “force” Resonance.

---

## 4. Free teaser rules & paywall placement

### 4.1 Teaser principles

| Principle | Rule |
| --- | --- |
| Complete Free loop | Teasers must not block Discover Like/Pass, match, or chat |
| Honest lock | Locked Resonance features show clear “Resonance” affordance — no fake data |
| No shame | Cosmic, calm copy; no “you’re missing high-IQ people” |
| No shadow claims | No temporal / QI / wave language in teaser or paywall |
| Count honesty | If teaser shows a count (e.g. likes waiting), only show when product can compute it without inventing users |

### 4.2 What Free users see as a teaser

| Feature | Free teaser (day-one intent) |
| --- | --- |
| Who Liked You | Entry point visible (nav/settings/Discover chrome). Body locked. Optional: “Someone aligned with you” / count **only if real**; else generic “See who aligned with you” without false specifics |
| Rewind | Control visible on Discover after Pass/Like when Rewind would apply; tapping shows Resonance unlock — Free never silently fails |
| Deeper compatibility explanations | Free keeps basic score/label. “Deeper explanation” / “Why you align” row shows locked preview (headlines only, no fabricated insight body) |
| Advanced filters (`launch_optional`) | If shipped: filter entry visible; advanced controls locked |
| Higher Like allowance (`launch_optional`) | If shipped: when Free hits daily Like wall, calm upgrade path — Free can still Pass and browse remaining Discover cards per Free rules |

### 4.3 Where paywalls may appear

Allowed **soft paywall / unlock sheets** (not full-app blocks):

| Placement | Trigger |
| --- | --- |
| Who Liked You surface | Open list / card while Free |
| Discover Rewind control | Tap Rewind while Free |
| Compatibility insight deepen | Tap “deeper explanation” while Free |
| Advanced filters sheet | Open advanced filter while Free (`launch_optional`) |
| Like-limit sheet | Free daily Like allowance exhausted (`launch_optional`) |
| Settings → Resonance | Explicit upgrade entry (always OK) |

**Disallowed paywall placements:**

| Placement | Why |
| --- | --- |
| Blocking assessments / Persona | Breaks Free brand loop |
| Blocking mutual match dialog or Open chat | Connection loop must stay Free |
| Blocking Messages / send on active match | Chat stays Free |
| Blocking block/report/unmatch | Safety stays Free |
| Discover feed hard-stop with no Pass / browse | Free Discover must remain usable |
| Anywhere implying paid access to higher IQ/EQ people | Prohibited |

---

## 5. Candidate Like / Discover quota ranges (`candidate_not_frozen`)

These are **planning ranges only** — not ratified quotas, not store truth, not app constants.

### 5.1 Like allowance

| Tier | Candidate daily Likes | Notes |
| --- | --- | --- |
| Free | **8–15 / day** | Enough for intentional outreach; scarce enough that Resonance allowance feels real |
| Resonance | **30–50 / day** or **~3× Free** | Prefer a simple multiplier once Free baseline is chosen |

**Default planning midpoint (still not frozen):** Free **12**, Resonance **40**.

### 5.2 Discover volume

| Tier | Candidate daily stack | Notes |
| --- | --- | --- |
| Free | **15–25 cards / day** (or soft refresh cap) | Must not feel empty after two minutes |
| Resonance | **unlimited soft refresh** or **~2× Free** | Exact model deferred; do not invent “priority humans” |

Discover volume is **deferred** relative to day-one Resonance features unless Higher Like allowance ships and needs a paired Free wall.

### 5.3 Explicitly not frozen here

- Final numeric quotas
- Timezone / reset rules
- Carry-over
- Whether Pass counts against anything (product default: Pass does **not** consume Like allowance)

---

## 6. Consumable relationship (day one)

| Decision | Day-one packaging |
| --- | --- |
| Super Resonance | **Always separate consumable** (à la carte) |
| Boost / Spotlight | **Always separate consumable** (à la carte) |
| Included in Resonance subscription | **No** for day one |
| Monthly allotments | `deferred` (may return in a later packaging revision) |

**Why separate on day one**

- Keeps Resonance value story = Who Liked You + Rewind + deeper explanations
- Avoids bundling unfinished credit UX into first subscription ship
- Preserves ratified rule: consumables change visibility / interest signaling, **not** compatibility scores
- Free and Resonance can both buy consumables without inventing a third tier

Resonance paywalls may **mention** consumables as related tools but must not require them to complete Who Liked You / Rewind / deeper explanations.

---

## 7. Copy / ethics guardrails for packaging

Allowed frames:

- who aligned with you
- undo a pass
- deeper compatibility explanation
- more intentional Likes
- preference / connection-style filters

Forbidden frames:

- access to higher IQ / EQ users
- Persona unlock as matching key
- “better matches algorithm” for paying users
- proven temporal / QI compatibility
- Super Resonance / Boost as score upgrades

---

## 8. Exact next product step

**Write `docs/product/qmatch_resonance_paywall_tease_ux_v1.md` (product / UX only):**

1. Wireframe Free teaser states for Who Liked You, Rewind, and deeper explanations.
2. Define unlock-sheet content + CTAs (Resonance subscribe vs dismiss) — still **no prices**.
3. Specify count-honesty rules for Who Liked You teaser.
4. List analytics events (names only) for teaser impressions / unlock taps — no SDK work.
5. Restate disallowed paywall placements from §4.3.

Do **not** implement app code, IAP, ranking, or quota enforcement in that step.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| launch_required = Who Liked You + Rewind + deeper explanations | Yes (§2.2) |
| Filters + higher Likes = launch_optional | Yes (§2.3) |
| Advanced visibility/privacy = deferred | Yes (§2.4) |
| Free core matching / match / chat / safety intact | Yes (§3) |
| Teaser + paywall placement defined | Yes (§4) |
| Quota ranges candidate_not_frozen | Yes (§5) |
| Consumables separate on day one (no allotments) | Yes (§6) |
| No prices / third tier / IQ-Persona gating / QI claims | Yes |
| Status | `resonance_launch_packaging_v1` · `product_ratified_not_live` |
