# Qmatch DS-0 — Cosmic Theme Foundation Report

Date: 2026-07-18  
Phase: **4D-DS0B** (complete partial DS-0 after interrupted prior run)  
Mode: **Tokens only** — no screen redesign, no animations, no Firebase writes, no deploy, no commit.

---

## Summary

Premium Cosmic Minimal token foundation is complete and compiles.  
`flutter analyze` passes. Runtime app theme in `main.dart` is **unchanged** (still seed `ThemeData`) so no visible behavior shift.

---

## Files changed

| File | Status | Notes |
|------|--------|-------|
| `lib/core/theme/app_colors.dart` | Modified | Cosmic roles + backward-compatible aliases |
| `lib/core/theme/app_gradients.dart` | New | Cosmic + Neo Lab viz gradients |
| `lib/core/theme/app_radii.dart` | New | Radius scale + semantic helpers |
| `lib/core/theme/app_spacing.dart` | New | Spacing scale from style direction |
| `lib/core/theme/app_shadows.dart` | New | Soft glass / gold / cosmic glow lists |
| `lib/core/theme/app_theme.dart` | Modified | Token-wired `darkTheme` (not applied in `main.dart`) |
| `docs/qmatch_ds0_cosmic_theme_foundation_report.md` | New | This report |

---

## Token structure

```
lib/core/theme/
  app_colors.dart      → AppColors
  app_gradients.dart   → AppGradients
  app_radii.dart       → AppRadii
  app_spacing.dart     → AppSpacing
  app_shadows.dart     → AppShadows
  app_theme.dart       → AppTheme.darkTheme (ready, unused by main)
```

No `AppTextStyles` file — typography stays in `AppTheme` via existing `google_fonts` (Playfair + Inter).  
No `AppMotion` — motion deferred (no animations this phase).  
No new packages. No network fonts added.

---

## Colors added (`AppColors`)

### Cosmic canvas
| Token | Hex | Role |
|-------|-----|------|
| `cosmicBlack` | `#0C0C0C` | bg.void / app canvas |
| `midnightNavy` | `#0A0F1C` | bg.deep / atmospheric top |
| `deepIndigo` | `#161B3A` | indigo depth |
| `cosmicPurple` | `#5B4B8A` | soft purple haze |
| `electricBlue` | `#4F7CFF` | electric accent |
| `resonanceViolet` | `#7C6CFF` | violet accent |

### Gold
| Token | Hex |
|-------|-----|
| `softGold` | `#E3C565` |
| `warmGold` | `#C9A227` |

### Glass / surfaces
| Token | Value |
|-------|--------|
| `glassSurface` | `#99141A2E` (translucent) |
| `glassSurfaceStrong` | `#CC1A2240` |
| `surfaceElevated` | `#1A1A1A` |

### Borders / text / semantic
| Token | Notes |
|-------|--------|
| `borderSubtle` | Low-contrast luminous border |
| `borderGlow` | Soft gold border glow |
| `textPrimary` / `textSecondary` / `textMuted` / `textGold` | Hierarchy |
| `danger` / `success` / `warning` | States |
| `disabledOpacity` | `0.4` |

### Neo Lab viz (IQ / EQ / Frequency only)
| Token | Hex |
|-------|-----|
| `vizIq` | `#6B8CFF` |
| `vizEq` | `#9B7CFF` |
| `vizFrequency` | `#5EC8D8` |

### Backward-compatible aliases (unchanged API for screens)
`primary`, `secondary`, `background`, `surface`, `accent`, `error`, `buttonOutline`, `buttonText` — preserved so existing screens keep compiling without migration.

---

## Gradients added (`AppGradients`)

| Token | Purpose |
|-------|---------|
| `cosmicBackgroundGradient` | Void depth wash (navy → black) |
| `primaryActionGradient` | Violet → indigo → electric blue |
| `goldActionGradient` | Soft → warm gold |
| `glassCardGradient` | Soft glass wash |
| `profileHeroGlowGradient` | Sweep halo token (static; no motion) |
| `compatibilityRingGradient` | Lab viz ring |
| `iqGradient` / `eqGradient` / `frequencyGradient` | Channel-only viz |

---

## Radii / spacing / shadow / text decisions

### Radii (`AppRadii`)
- Scale: `xs8 · sm12 · md16 · lg20 · xl24 · pill999`
- Semantic: `button=16`, `card=20`, `sheet=24`
- Helpers: `buttonBorder`, `cardBorder`, `sheetBorder`, `pillBorder`
- `profileHeroShape = BoxShape.circle` (geometry note only)

### Spacing (`AppSpacing`)
- Scale: `4 · 8 · 12 · 16 · 24 · 32 · 48` (matches style direction)
- `screenHorizontal = 24`, `cardPadding = 16`, `cardPaddingComfortable = 20`
- Button padding helpers aligned with theme CTA padding

### Shadows (`AppShadows`)
- Prefer luminous borders over heavy Material elevation
- Tokens: `glassCard`, `goldGlow`, `cosmicGlow`, `dialog`
- Intended for later components (CTA focus, hero halo) — unused by screens yet

### Text styles
- **No separate `AppTextStyles` file** (avoid duplication / new font surface)
- `AppTheme.darkTheme` keeps Playfair Display (display) + Inter (body) via existing `google_fonts`
- Added `bodySmall` → `textMuted` for caption/meta readiness

---

## Theme integration

| Question | Answer |
|----------|--------|
| Was `AppTheme` updated to use tokens? | **Yes** — radii, spacing, colors, card/dialog theme, fuller `ColorScheme` |
| Was `main.dart` switched to `AppTheme.darkTheme`? | **No** — intentionally left on seed `ThemeData` |
| Why? | Wiring `AppTheme` into `MaterialApp` would restyle the whole app; out of DS-0 “tokens only” scope |

Screens continue using ad-hoc `AppColors.*` as before. New tokens are available for DS-1 components.

---

## Intentionally not changed

- No screen / widget redesign
- No user-flow changes
- No animations / motion tokens implementation
- No monetization / billing packages
- No Firebase SDK additions, writes, or deploys
- No Firestore rules edits
- No `main.dart` theme switch
- No GoogleFonts / network font additions beyond what already existed
- No commit / push
- No kitchen-sink debug route (optional; deferred)

---

## Next phase — DS-1 (shared components)

Build Cosmic primitives first (still no full screen redesign):

1. `QGlassCard` — glass surface + `AppRadii.card` + `AppColors.borderSubtle`
2. `QPrimaryButton` / `QSecondaryButton` — gold outline system
3. `QTextField` — gold focus forms
4. `QSectionHeader`, empty/loading/error blocks
5. Soft ambient backdrop helper (`AppGradients.cosmicBackgroundGradient`)
6. **`CosmicProfileHero`** widget shell (portrait + static orbital halo tokens; no motion yet)
7. Lab-only viz: `CompatibilityRing` / progress arc (IQ/EQ/Frequency screens only)

Then DS-2 applies tokens/components to P0 screens (Welcome → Auth → Discover → Assessment → Safety).

---

## Verification

```
flutter analyze
→ No issues found!

git status --short  (theme + this report subset)
 M lib/core/theme/app_colors.dart
 M lib/core/theme/app_theme.dart
?? lib/core/theme/app_gradients.dart
?? lib/core/theme/app_radii.dart
?? lib/core/theme/app_spacing.dart
?? lib/core/theme/app_shadows.dart
?? docs/qmatch_ds0_cosmic_theme_foundation_report.md
```
