# QMatch Resonance Paywall & Tease UX v1

| Field | Value |
| --- | --- |
| Document id | `qmatch_resonance_paywall_tease_ux_v1` |
| Status | `resonance_paywall_tease_ux_v1` · `product_ratified_not_live` |
| Parent | [Resonance Launch Packaging v1](./qmatch_resonance_launch_packaging_v1.md) (`product_ratified_not_live`) |
| Grandparent | [Monetization & Membership Contract v1](./qmatch_monetization_membership_contract_v1.md) |
| Scope | Free → Resonance teaser states, unlock sheets, honesty rules, analytics event names |
| Non-goals | App code, IAP, prices, ranking/scoring, quota enforcement constants, temporal/QI claims |
| Draft date | 2026-08-13 |
| Ratified | 2026-08-13 |

---

## 0. Purpose

This document is the **ratified** Free → Resonance teaser / paywall UX so product, design, and engineering share one honesty and placement vocabulary before entitlement or IAP work.

**Status meaning:** product-ratified UX contract — binding for teaser/paywall behavior. **Not live** in app until engineering ships. Prices and exact quotas remain unresolved.

### Ratification lock (2026-08-13)

| Lock | Rule |
| --- | --- |
| Who Liked You | Honest teaser only — real counts when known; no fake people / silhouettes |
| Rewind | Paywall **only** when a valid rewind target exists |
| Compatibility | Free **basic** score/label stays visible; **deeper** explanation is Resonance-gated |
| Optional surfaces | Advanced filters + Like wall remain packaging-optional |
| Honesty | No fake likes, counts, people, or compatibility insight bodies |
| Hard paywalls | None on onboarding, mutual match, chat, or safety |
| Aggression | Max **one auto-show per feature per session** + cooldown; tap-retry OK; **no stacked** paywalls |
| Post-purchase | Return to the **original feature context** that opened the sheet |
| Analytics | Event contract in §8 is frozen (names + `feature` enum) |
| Unresolved | Prices · exact Like/Discover quotas · final cool-down constants |

Covers:

| Surface | Packaging class |
| --- | --- |
| Who Liked You | `launch_required` |
| Rewind | `launch_required` |
| Deeper compatibility explanations | `launch_required` |
| Advanced preference / filter controls | `launch_optional` |
| Like-limit wall | `launch_optional` (pairs with higher Like allowance) |

---

## 1. Shared UX system

### 1.1 Components

| Component | Role |
| --- | --- |
| **Teaser entry** | Visible Free control / row that indicates a Resonance feature exists |
| **Locked preview** | Honest empty / locked state — never fabricated people or insight prose |
| **Unlock sheet** | Soft modal / bottom sheet: value + primary CTA + dismiss |
| **Settings Resonance** | Always-available explicit upgrade entry (not a forced interrupt) |

### 1.2 Unlock sheet anatomy (all features)

| Element | Spec |
| --- | --- |
| Title | Feature-specific (“See who aligned with you”, “Rewind”, “Deeper alignment”, etc.) |
| Body | 1–2 calm sentences — Cosmic, no shame, no IQ/EQ caste, no temporal/QI |
| Primary CTA | `Unlock with Resonance` (label may localize; **no price on sheet in this UX contract**) |
| Secondary CTA | `Not now` / dismiss |
| Footer link (optional) | `What is Resonance?` → Settings Resonance explainer (still no prices required here) |
| Consumable mention | Optional one-line that Super Resonance / Boost exist as **separate** tools — never required to unlock these sheets |

### 1.3 Post-purchase destination (shared)

After successful Resonance activation (future IAP):

1. Dismiss unlock sheet.
2. Land on the **feature that triggered** the sheet (see per-feature tables).
3. Do **not** force a second marketing tour.
4. If purchase completes from Settings with no feature context → land on Settings Resonance “active” state, not a random Discover interrupt.

### 1.4 Aggression / frequency rules

| Rule | Spec |
| --- | --- |
| No onboarding hard paywall | Assessments, Persona, profile setup never blocked by Resonance |
| Soft only | Unlock sheets overlay; underlying Free actions remain reachable after dismiss |
| No repeat spam | Same feature unlock sheet: max **1 auto-show per session**; thereafter **tap-only** |
| No stack | Never open two unlock sheets at once |
| No after-match interrupt | Mutual-match dialog / Open chat path never replaced by Resonance sheet |
| No chat interrupt | Opening Messages / sending never triggers Resonance |
| Session cool-down | After dismiss, do not re-present the **same** feature sheet until next app session (unless user taps the locked control again) |
| Daily soft cap (product intent) | Across all auto-triggered sheets: prefer ≤ **2 auto-shows / day**; tap-triggered always allowed |

Exact numeric cool-downs are UX intent; final constants deferred to implementation.

---

## 2. Who Liked You UX

| Field | Spec |
| --- | --- |
| **Free entry point** | Dedicated entry in main chrome and/or Discover header / Profile–adjacent nav (exact tab deferred). Also reachable from Settings → Resonance teaser row |
| **What Free can see** | Entry label + Resonance badge. If **real** inbound Like count `N ≥ 1` is known: “N people aligned with you” **or** “Someone aligned with you” (for N=1). If count unknown / zero / unavailable: generic “See who aligned with you” — **no number** |
| **What stays locked** | The list of people, avatars, names, ages, photos, and any profile preview of likers |
| **Unlock trigger** | Tap entry **or** tap locked list body / “Reveal” CTA |
| **Honest teaser behavior** | **Never** show blurred silhouette grids implying people. **Never** invent counts. **Never** show placeholder faces. Empty Free state with zero real likes: calm empty copy + Resonance value — not faux occupancy |
| **Post-purchase destination** | Who Liked You list (real data only). If still empty after unlock: honest empty state (“No one has liked you yet”) — not a fake fill |

**Unlock sheet copy intent (EN draft, not final):**

- Title: See who aligned with you
- Body: When someone Likes you, Resonance lets you see them — without changing who you match with.
- Primary: Unlock with Resonance

---

## 3. Rewind UX

| Field | Spec |
| --- | --- |
| **Free entry point** | Discover action affordance (icon/text) shown when a Rewind target exists (last Pass or last Like that product allows to undo) |
| **What Free can see** | The Rewind control itself (visible, not hidden). Disabled-looking / locked glyph OK if still tappable |
| **What stays locked** | Actually restoring the previous card / undoing the swipe |
| **Unlock trigger** | Tap Rewind while Free |
| **Honest teaser behavior** | If no Rewind target exists, hide or no-op the control — do **not** open a paywall for an impossible Rewind. Never claim a card was restored without doing it |
| **Post-purchase destination** | Immediately perform Rewind for the pending target if still valid; else return to current Discover card with a calm “Nothing to rewind” |

**Unlock sheet copy intent:**

- Title: Rewind
- Body: Undo your last Pass or Like and take another look — Discover stays yours either way.
- Primary: Unlock with Resonance

**Free Discover remains usable:** Pass / Like / browse continue after dismiss.

---

## 4. Deeper compatibility explanations UX

| Field | Spec |
| --- | --- |
| **Free entry point** | On Discover card and/or matched peer surfaces: row/button “Why you align” / “Deeper explanation” adjacent to the **basic** Free score/label |
| **What Free can see** | Full basic compatibility score/label (unchanged quality class). Locked row with Resonance badge. Optional static headline chips that are **category labels only** (e.g. “Thinking style”, “Emotional depth”, “Frequency”) **without** fabricated explanations |
| **What stays locked** | Narrative paragraphs, detailed factor breakdowns, shared-values prose, any generated “insight body” |
| **Unlock trigger** | Tap deepen row / locked insight card |
| **Honest teaser behavior** | No AI-flavored fake paragraphs. No invented “strengths” lists. No implying Free score is incomplete/wrong — Free score remains valid; Resonance adds **depth of explanation** |
| **Post-purchase destination** | Open deeper explanation for the **same peer context** that triggered the sheet (same Discover card or match). If peer context gone: Discover or match list — not a blank marketing page |

**Unlock sheet copy intent:**

- Title: Deeper alignment
- Body: Keep your free compatibility signal — Resonance adds a clearer explanation of how you align.
- Primary: Unlock with Resonance

**Prohibited:** “Unlock higher IQ matches”, Persona-gated insight, temporal/QI language.

---

## 5. Optional advanced filters UX

*(Only if `launch_optional` advanced preference/filter controls ship.)*

| Field | Spec |
| --- | --- |
| **Free entry point** | Discover filters / preferences entry (icon or “Preferences”) |
| **What Free can see** | Sheet shell + any **already Free** basic preference controls the product already exposes (if none, shell + locked advanced section). Resonance badge on advanced section |
| **What stays locked** | Advanced filter controls (expanded ranges, multi-dimension preference tools as packaging defines) |
| **Unlock trigger** | Tap locked advanced section / “Advanced filters” |
| **Honest teaser behavior** | Do not preview filter results that require paid filters. Do not imply Free Discover is “wrong” without filters. No IQ/EQ caste filter labels |
| **Post-purchase destination** | Same preferences sheet with advanced section unlocked and focus moved to first advanced control |

**Free Discover:** remains browsable with Free filters / default ranking after dismiss.

---

## 6. Optional Like-limit wall UX

*(Only if `launch_optional` higher Like allowance ships with a Free daily Like quota — quotas still `candidate_not_frozen`.)*

| Field | Spec |
| --- | --- |
| **Free entry point** | Discover Like action when Free daily Like allowance is exhausted |
| **What Free can see** | Calm limit message; remaining time-to-reset if known; Pass and browse **still available**; mutual match / chat unaffected |
| **What stays locked** | Additional Likes beyond Free daily allowance |
| **Unlock trigger** | Tap Like while at limit **or** tap “Get more Likes with Resonance” on the limit sheet |
| **Honest teaser behavior** | Never invent remaining likes. Never soft-fail Like without explanation. Never block Pass to coerce upgrade |
| **Post-purchase destination** | Return to the **same Discover card**; if Like still intended, allow Like without re-opening the wall (if allowance now higher) |

**Unlock / limit sheet copy intent:**

- Title: Daily Likes used
- Body: You’ve used today’s free Likes. Pass anytime — or unlock Resonance for a higher daily allowance.
- Primary: Unlock with Resonance
- Secondary: Keep browsing

**Aggression:** Like-limit sheet may show on Like tap at wall; do not auto-show on Discover open or after Pass.

---

## 7. Global paywall rules (summary)

### 7.1 Allowed

- Soft unlock sheets from Who Liked You, Rewind, deepen, optional filters, optional Like wall, Settings Resonance
- Honest empty / locked previews
- Tap-to-retry unlock after dismiss

### 7.2 Disallowed

| Pattern | Why |
| --- | --- |
| Fake likes, fake counts, blurred non-existent people | Honesty / trust |
| Fabricated compatibility insight bodies | Honesty |
| Hard paywall during onboarding / assessments / Persona | Free brand loop |
| Paywall on mutual match Open chat / Messages send | Connection loop Free |
| Paywall on block / report / unmatch | Safety Free |
| Discover hard-stop with no Pass/browse | Discover Free |
| Repeated auto paywalls same session/feature | Aggression |
| IQ / EQ / Persona premium gating copy | Prohibited |
| Temporal / QI claims | Shadow-only honesty |
| Prices on sheets in this UX contract | Prices deferred |
| Requiring Super Resonance / Boost to unlock Resonance features | Consumables stay separate |

---

## 8. Analytics event names

Names only — no SDK wiring in this doc. Use stable snake_case; `feature` param distinguishes surface.

### 8.1 Core funnel events

| Event name | When | Suggested params |
| --- | --- | --- |
| `resonance_teaser_viewed` | Locked teaser / entry becomes visible in viewport | `feature`, `surface`, `has_real_count` (bool, Who Liked You only) |
| `resonance_paywall_opened` | Unlock sheet presented | `feature`, `trigger` (`tap` \| `auto` \| `limit`), `surface` |
| `resonance_paywall_dismissed` | User dismisses / Not now | `feature`, `trigger`, `surface` |
| `resonance_purchase_intent` | Primary CTA tapped (`Unlock with Resonance`) | `feature`, `surface` |
| `resonance_feature_unlocked` | After entitlement active, feature becomes usable | `feature`, `destination` |

### 8.2 `feature` enum (product)

| Value | Surface |
| --- | --- |
| `who_liked_you` | Who Liked You |
| `rewind` | Rewind |
| `deeper_compatibility` | Deeper explanations |
| `advanced_filters` | Optional filters |
| `like_limit` | Optional Like wall |
| `settings_resonance` | Explicit Settings entry |

### 8.3 Non-events (do not invent)

- Do not fire `resonance_feature_unlocked` on Free teaser view
- Do not fire purchase success analytics here (belongs to future IAP contract)
- Do not log Persona / IQ / EQ scores into monetization events

---

## 9. Exact next product step

**Write `docs/product/qmatch_resonance_entitlement_engineering_contract_v1.md` (engineering contract, still not live code):**

1. Map `feature` enum → server entitlement flags / client gates.
2. Define source-of-truth rules (receipt verify; no client-only premium).
3. Specify restore / expiry behavior for Resonance.
4. Keep consumables (Super Resonance, Boost) on separate credit balances.
5. Reference this UX doc for gate placement; **no UI implementation in that step**.

Alternatively, if design wants visuals first: produce Cosmic unlock-sheet mock frames from §1.2 — still no code / no prices.

---

## Trace checklist

| Check | Verdict |
| --- | --- |
| Who Liked You / Rewind / deepen UX defined | Yes (§2–4) |
| Optional filters + Like wall defined | Yes (§5–6) |
| No fake people / counts / insights | Yes (§1, §7) |
| Core Discover / match / chat / safety usable | Yes |
| No onboarding hard paywall / no aggressive repeats | Yes (§1.4) |
| Analytics event names defined | Yes (§8) |
| No prices / no IQ-Persona gating / no QI claims | Yes |
| Status | `resonance_paywall_tease_ux_v1` · `product_ratified_not_live` |
