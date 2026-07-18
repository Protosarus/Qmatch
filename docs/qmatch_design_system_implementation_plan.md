# Qmatch Design System Implementation Plan

Date: 2026-07-18 (patched 4A-Patch: Profile Hero)  
Depends on: `docs/qmatch_visual_style_direction.md`  
Mode for this plan: **implementation order only** — execute later in separate phases.  
Identity: **Premium Cosmic Minimal** primary; **Neo Lab** borrow for IQ/EQ/Frequency viz only.  
Profile: **`CosmicProfileHero`** required on profile view (docs-locked; not implemented yet).

---

## Goal

Turn the style direction into a shippable Flutter design system without making the app feel cold, dashboard-like, or overly scientific.

Order of work:

1. Tokens  
2. Shared components  
3. Screen application (P0 → P1)  
4. Viz modules (Lab loan, restrained)  
5. QA / visual regression  

---

## Phase DS-0 — Foundations (tokens)

**Likely files**

- `lib/core/theme/app_colors.dart` — expand Cosmic roles (`bg.void`, `surface.glass`, accents, viz channels)
- `lib/core/theme/app_theme.dart` — ThemeData + ThemeExtension for spacing/radius/glow
- New (optional): `lib/core/theme/app_spacing.dart`, `app_radii.dart`, `app_shadows.dart`, `app_motion.dart`
- `pubspec.yaml` — only if bundling fonts offline (coordinate with privacy note)

**Deliverables**

- Named Cosmic color roles (void, glass, gold, violet/indigo haze, muted text, states)
- Spacing / radius / elevation-glow scales
- Typography roles wired once through Theme
- Light mode: **skip** for v1

**Risks**

- Over-tokenizing before screens use them → define only what screens need
- `google_fonts` network: plan bundling in P1 if store privacy stays strict

**Done when**

- Theme compiles; no screen restyle yet required
- Founder can review token swatches / a small kitchen-sink preview (optional debug route)

---

## Phase DS-1 — Shared components

Build Cosmic primitives first; add Lab-flavored viz widgets second.

### Cosmic primitives (primary)

| Component | Purpose | Likely location |
|-----------|---------|-----------------|
| `QGlassCard` | Premium glass surface | `lib/core/widgets/` |
| `QPrimaryButton` / `QSecondaryButton` | Unified CTAs | same |
| `QTextField` | Gold focus forms | same |
| `QSectionHeader` | Title + muted support | same |
| `QEmptyState` / `QLoadingPulse` / `QErrorBlock` | Shared feedback | same |
| Soft ambient backdrop helper | Void + indigo haze | widget or decoration |
| **`CosmicProfileHero`** | Profile emotional anchor: large circular portrait, orbital halo (violet / indigo / electric blue / soft gold), name·age·profession·city + short quote/bio close to portrait, compatibility context integrated around | `lib/core/widgets/` or `lib/features/profile/widgets/` |

### `CosmicProfileHero` — component roadmap note *(docs only; do not implement in 4A)*

| Spec | Detail |
|------|--------|
| Goal | Profile must **not** read as a standard flat dating profile |
| Portrait | Large circular photo near top |
| Glow / frame | Subtle cosmic/orbital halo; elegant multi-accent frame |
| Cluster | Identity meta + short bio/quote adjacent to portrait |
| Compatibility | Integrated around hero (Cosmic); Lab rings only if showing IQ/EQ/Frequency scores |
| Feeling | Cinematic, premium, intelligent, emotionally warm |
| Out of scope now | No widget file, no screen wiring, no behavior change until a DS implementation phase |

### Lab-borrowed viz (assessment only)

| Component | Purpose | Constraint |
|-----------|---------|------------|
| `CompatibilityRing` | Score / frequency ring | Soft glow; not dashboard chrome |
| `ProgressArc` or soft progress | Assessment progress | Thin, quiet |
| `ScoreExplainCard` | Number + emotional caption | Cosmic glass shell |
| Later: `RadarChart` / connection map | IQ/EQ/Frequency dimensions | P2 unless P0 needs one |

**Do not** create a general “analytics panel” kit for Discover/Settings.

**Risks**

- Chart packages that look clinical → prefer custom painters for Cosmic feel
- Glow duplication fighting Material ink → disable splash where it breaks glass look

**Done when**

- Primitives used by at least one kitchen-sink or one pilot screen
- Viz widgets unused by Discover/Settings by design
- `CosmicProfileHero` exists as a reusable widget **before** profile screen restyle (DS-3), or is built in the same phase as profile view

---

## Phase DS-2 — Screen application (P0)

Apply Cosmic system where first impression and trust matter most.

| Priority | Screen(s) | Files (examples) | Focus |
|----------|-----------|------------------|-------|
| 1 | Welcome / splash path | `welcome_screen.dart`, `main.dart` entry | Brand-first Cosmic void |
| 2 | Auth (phone) | `phone_signup_screen.dart`, `verification_screen.dart`, related | Calm form + primary CTA |
| 3 | Discover | `discover_screen.dart` | One hero card composition |
| 4 | Assessment intro + result | IQ/EQ/Frequency intro/result screens | Emotion first; Lab ring on result |
| 5 | Safety / delete account | settings + `account_deletion` flows | Clarity; low decoration |

**Rules while applying**

- Replace ad-hoc colors with tokens
- Prefer shared buttons/cards over local `BoxDecoration` copies
- Keep feature logic untouched (scoring, Firebase, swipe rules)

**Done when**

- P0 screens share radius/spacing/CTA language
- App no longer feels “partially themed”

---

## Phase DS-3 — Screen application (P1)

| Area | Screens | Focus |
|------|---------|-------|
| Profile **view** | `profile_screen.dart` (and related) | Wire **`CosmicProfileHero`**: large circular portrait + orbital halo; identity + quote close; compatibility context integrated; not flat dating layout |
| Profile setup / edit | setup steps, photo edit | Wizard glass consistency; feed hero after save |
| Messages | list + chat detail | Quiet bubbles; wallpaper subtle |
| Settings / help / about / legal | settings cluster | Readable; no glow |
| Empty/loading/error | shared call sites | One pattern everywhere |

**Done when**

- Remaining primary navigation surfaces match Cosmic
- Profile view passes founder check: cinematic hero portrait, not flat dating header
- Legal/support still feel trustworthy (not ornamental)

---

## Phase DS-4 — Viz polish + motion (P2)

- Soft match / Frequency pulse
- Optional radar / connection map
- Micro-transitions between assessment steps
- Gentle **CosmicProfileHero** halo breathe (restrained; one focus)
- Illustration assets if needed

Do **not** block store launch on P2.

---

## Phase DS-5 — QA / acceptance

### Visual QA checklist

- [ ] First viewport of welcome passes brand test (brand not overpowered)
- [ ] Dark void + soft haze feel premium, not muddy
- [ ] Gold used sparingly (accent, not wallpaper)
- [ ] Glass cards readable (contrast AA for body text)
- [ ] Discover is one composition, not a dashboard
- [ ] Assessment results: emotional headline + Lab viz secondary
- [ ] **Profile: CosmicProfileHero** — large circular portrait, orbital halo, meta + quote close, compatibility integrated; not flat dating
- [ ] Safety / delete: clear and serious
- [ ] No cold clinical chrome on social screens
- [ ] Light mode not accidentally shipped
- [ ] Reduced-motion / accessibility: text scale doesn’t break glass layouts; hero still readable at large text

### Flutter / build checks (per implementation phase)

- `flutter analyze`
- Device smoke on iOS (primary path): auth → discover → chat → settings → delete request UI
- No Firebase schema / scoring changes in design-only phases

### Regression watch

| Risk | Mitigation |
|------|------------|
| Contrast failure on glass | Cap blur; solid fallback surfaces |
| Glow performance on low devices | Limit blur layers; prefer borders |
| Theme drift (local Color hardcoded) | Grep for hex after each screen pass |
| Over-scientific viz | Founder check on Frequency result before launch |

---

## Suggested implementation sequence (summary)

```
DS-0 Tokens
  → DS-1 Cosmic components (include CosmicProfileHero in roadmap)
    → DS-1b Lab viz (ring + progress + explain card)
      → DS-2 P0 screens (welcome → auth → discover → assessment results → safety)
        → DS-3 P1 remaining (profile view → CosmicProfileHero)
          → DS-4 motion/viz polish (optional; hero halo breathe)
            → DS-5 QA
```

---

## Explicit out of scope for design-system work

- Changing IQ/EQ/Frequency scoring, weights, or assessment JSON
- Android SDK / identity migration
- Firebase rules, deploy, store listing copy (unless a privacy-impacting feature is added)
- Commit / push unless requested
- Push notifications, Analytics, Crashlytics, IAP, ads (each needs separate privacy phase)
- **Implementing `CosmicProfileHero` in Phase 4A / 4A-Patch** — docs requirement only until a DS implementation phase

---

## Future implementation notes — `CosmicProfileHero`

| Note | Detail |
|------|--------|
| When | After DS-0 tokens; build in DS-1 (component) and apply in DS-3 (profile view) |
| Likely files | New widget under `lib/core/widgets/` or `lib/features/profile/widgets/`; wire in `profile_screen.dart` |
| Tokens needed | Halo accents (violet, indigo, electric blue, soft gold), portrait size scale, glow restraint |
| Avoid | Flat square header, photo carousel-as-hero, stats grid above fold, neon overload |
| Compatibility | Soft Cosmic context around hero; Neo Lab rings only for score viz, not the whole profile chrome |
| Performance | Prefer layered borders / soft gradients over heavy multi-blur on low devices |
| Accessibility | Semantically labeled portrait; text scale must not clip name/bio cluster |

---

## Risks & decisions to confirm before coding

| Decision | Recommendation |
|----------|----------------|
| Keep Playfair + Inter | Yes for now; refine later |
| Solid gold fill vs outline primary | Pick **one** primary button language in DS-0 and stick to it |
| Secondary accent `#D946EF` | Soften into indigo/violet atmospheric tokens; don’t flood CTAs |
| Chart package vs CustomPainter | Prefer CustomPainter for Cosmic rings in P0 |
| Debug kitchen-sink route | Useful in debug builds; hide in release |
| Profile hero size | Large circular; dominate first profile viewport without crushing bio |
| Halo intensity | Subtle orbital glow; emotionally warm, not club neon |

---

## Next execution phase (when founder unlocks)

**Start with DS-0 tokens** in `app_colors.dart` / `app_theme.dart`, then one pilot screen (Welcome) + kitchen-sink optionally — still no store submit, Android, or scoring changes.  
**`CosmicProfileHero`:** implement only when a design-system coding phase is unlocked (DS-1 / DS-3), not in this docs patch.
