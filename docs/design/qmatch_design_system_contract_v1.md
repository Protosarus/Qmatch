# QMatch Design System Contract v1

Phase: **P2C-1C-0** · Provisional canonical tokens  
Source preference: Phone auth + IQ question chrome + existing `AppColors` / `AppGradients` / spacing / radii.  
**Tokens marked ⏳ still need visual approval.**

Do not create a second competing purple/gold palette. Prefer one cosmic purple family + one gold family.

---

## 1. Color tokens

| token | provisional value | evidence | approval |
|-------|-------------------|----------|----------|
| `bg.primary` (void) | `#0C0C0C` (`AppColors.cosmicBlack`) | tokens + main scaffolds | approved_as_token |
| `bg.secondary` (deep) | `#0A0F1C` (`midnightNavy`) | phone / IQ intro | approved_as_token |
| `bg.elevated` | `#1A1A1A` (`surfaceElevated`) | cards / dialogs | approved_as_token |
| `bg.glass` | `#99141A2E` (`glassSurface`) | token | ⏳ glass opacity on device |
| `accent.purple` | `#7C6CFF` (`resonanceViolet`) | phone orbs, IQ label | approved_as_token |
| `accent.purpleDeep` | `#5B4B8A` / `#161B3A` | tokens | ⏳ which deep stop for CTAs |
| `accent.blue` | `#4F7CFF` (`electricBlue`) | phone orbs | approved_as_token |
| `accent.gold` | `#E3C565` (`softGold`) | primary alias | approved_as_token |
| `accent.goldWarm` | `#C9A227` (`warmGold`) | gold gradient | approved_as_token |
| `text.primary` | `#FFFFFF` | tokens | approved_as_token |
| `text.secondary` | `#B0B0B0` | tokens | approved_as_token |
| `text.muted` | `#7A7A8A` | tokens | approved_as_token |
| `text.onGold` | `#0C0C0C` | Discover/Login pattern | approved_as_token |
| `border.subtle` | `#33A8B0D0` | tokens | ⏳ contrast on OLED |
| `border.glow` | `#66E3C565` | tokens | ⏳ |
| `disabled` | opacity `0.4` | `AppColors.disabledOpacity` | approved_as_token |
| `success` | `#4ECDC4` | tokens | ⏳ semantic review |
| `warning` | `#F5B942` | tokens | ⏳ |
| `error` | `#FF6B6B` (`danger`) | tokens | approved_as_token |

**Deprecated for new UI:** seed `ColorScheme.fromSeed`; Welcome-only `#05040C` (map to `bg.primary` or `bg.secondary`); ad-hoc `Colors.grey`.

**Magenta alias:** `AppColors.secondary` (`#D946EF`) — do **not** expand; prefer `resonanceViolet` for purple accent unity. ⏳ retire vs keep for rare gradients.

---

## 2. Gradients

| token | definition | use |
|-------|------------|-----|
| `grad.background` | `cosmicBackgroundGradient` (midnightNavy → cosmicBlack → `#08060F`) | scaffolds |
| `grad.cta.primary` | **Pick one** cosmic CTA for main app | ⏳ **approval required** between `cosmicCtaGradient` and `iqQuestionCtaGradient` |
| `grad.cta.gold` | `goldActionGradient` | secondary gold fills |
| `grad.glass` | `glassCardGradient` | cards |
| `grad.viz.*` | iq / eq / frequency / compatibilityRing | assessment / future match viz only |

Provisional recommendation for main-app CTAs: **`cosmicCtaGradient`** (Welcome/Phone proven). Keep `iqQuestionCtaGradient` for assessment Continue until unified.

---

## 3. Typography

| role | family | size / weight | color |
|------|--------|---------------|-------|
| Brand / hero title | Playfair Display | 32–48 / w600–w700 | gold or white (context) |
| Screen title | Playfair Display | 28–32 / w600 | `accent.gold` |
| Section title | Playfair Display | 18–22 / w600 | `accent.gold` |
| Body | Inter | 14–16 / w400–w500 | `text.primary` / secondary |
| Caption / meta | Inter | 12–13 / w500–w600 | muted or violet/gold shader |
| Button | Inter | 16 / w600 | on-CTA white or `text.onGold` |

Source: `AppTheme` textTheme + modern screens. **Wire via ThemeData** in P2C-1C-1+.

---

## 4. Spacing scale

Use `AppSpacing`: **4 · 8 · 12 · 16 · 24 · 32 · 48**.

| semantic | token |
|----------|-------|
| screen horizontal | `lg` (24) — Welcome may clamp 16–24 by width |
| card padding | `md` (16) or `cardPaddingComfortable` (20) |
| section gap | `lg`–`xl` |
| nav content height | 56 (+ safe area) — from `MainNavigationScreen` |

---

## 5. Radius scale

`AppRadii`: xs8 · sm12 · md16 · lg20 · xl24 · pill999.

| control | radius |
|---------|--------|
| buttons | md (16) or pill for primary launch CTAs |
| cards | lg (20) |
| sheets / dialogs | xl (24) |
| nav selected chip | pill |
| avatars | circle |

---

## 6. Icon sizes

| context | size |
|---------|------|
| bottom nav | 22 |
| settings leading | 22–24 |
| empty state | 56–72 |
| profile camera badge | 20 |

Material Icons (current). ⏳ custom icon set not required for P2C-1C.

---

## 7. Shadows / glows

Prefer 1px luminous borders; max **one** glow focus per viewport.

| token | use |
|-------|-----|
| `shadow.glassCard` | quiet lift |
| `shadow.goldGlow` | CTA / match |
| `shadow.cosmicGlow` | hero only |

---

## 8. Component metrics

| metric | value |
|--------|-------|
| primary button height | 48–56 (Welcome scales 46–56) |
| card padding | 16–20 |
| bottom nav content | 56 |
| bottom nav max width | 360 |
| profile avatar | 150 (Profile today) → ⏳ align with CosmicProfileHero later |

---

## 9. Safe-area behavior

- All full-screen scaffolds: respect `MediaQuery.padding` / `SafeArea`.
- Floating bottom nav: position `safeBottom + 10`; body padding ≥ nav total + 24.
- Status bar: light icons on dark cosmic backgrounds (`SystemUiOverlayStyle.light`).

---

## 10. Dark contrast checklist

- Gold text on void: OK for titles; body should stay white/secondary.
- Gold filled buttons: use `text.onGold`, not white-on-gold (low contrast risk).
- Violet accents on void: verify WCAG for small meta text (ShaderMask labels are decorative).

---

## 11. Explicit non-goals (this contract)

- No final CM v2 explanation palette.
- No second “neon yellow” brand.
- No light theme in v1 contract.
