# QMatch Current UI Audit v1

Phase: **P2C-1C-0** · Branch `main` · HEAD `4bbd6cb`  
Scope: evidence-based visual + implementation audit only. **No UI code changed.**

---

## 1. Theme architecture

| file | role | wired at runtime? | modern / legacy | notes |
|------|------|-------------------|-----------------|-------|
| `lib/core/theme/app_colors.dart` | Cosmic color tokens (DS-0) | imported by many screens | **shared modern tokens** | Aliases `primary`=`softGold`, `background`=`cosmicBlack` |
| `lib/core/theme/app_gradients.dart` | Cosmic / CTA / viz gradients | used by auth + assessment chrome | modern | Competing CTA grads (`cosmicCta` vs `iqQuestionCta`) |
| `lib/core/theme/app_spacing.dart` | 4–48 scale | partial | modern | Often ignored; screens hard-code 24 |
| `lib/core/theme/app_radii.dart` | 8–999 scale | partial | modern | |
| `lib/core/theme/app_shadows.dart` | glass / gold / cosmic glows | sparse | modern | Prefer borders over heavy shadows |
| `lib/core/theme/app_theme.dart` | Full `ThemeData.darkTheme` | **NOT applied** | designed_only | `main.dart` uses `ColorScheme.fromSeed(0xFFE3C565)` instead |
| `lib/main.dart` | MaterialApp theme | **active** | **legacy seed theme** | Blocks token ThemeData |

**Migration requirement:** Wire `AppTheme.darkTheme` (or equivalent) in `main.dart` only after main-shell migration; until then treat `AppColors`/`AppGradients` as the practical SoT.

---

## 2. Shared cosmic components (exist, lightly used)

| component | file | usage | status |
|-----------|------|-------|--------|
| `QCosmicButton` | `q_cosmic_button.dart` | assessment / some cosmic flows | modern; **not** used by Discover/Messages/Profile/Settings |
| `QGlassCard` | `q_glass_card.dart` | sparse | modern |
| `QPremiumTextField` | `q_premium_text_field.dart` | sparse | modern |
| `QSectionHeader` | `q_section_header.dart` | sparse | modern |
| `QMetricCircle` | `q_metric_circle.dart` | assessment viz | modern |
| `CosmicProfileHero` | `cosmic_profile_hero.dart` | token-ready | **not** on Profile tab |
| Assessment chrome | `iq_question_chrome.dart`, `q_assessment_*` | IQ/EQ/Freq | modern reference |

Barrel: `lib/core/widgets/cosmic/cosmic_widgets.dart`.

---

## 3. Modern reference screens (audit)

### 3.1 Welcome — `lib/features/auth/screens/welcome_screen.dart`

| aspect | evidence |
|--------|----------|
| Background | Layered assets (`welcome_cosmic_background.png`, couple heroes, Q glow); scaffold `0xFF05040C` |
| Palette | Mostly `Colors.white` overlays; gold/violet via assets more than `AppColors` |
| Typography | Playfair wordmark + Inter body (`GoogleFonts`) |
| Buttons | Custom CTA (not always `QCosmicButton`); glass secondary cards |
| Spacing | Responsive scale from height (`h/780`); max content width 430 |
| Safe area | `SafeArea` + `SystemUiOverlayStyle.light` |
| Localization | `l10n.welcome*` |
| Inconsistencies | Hard-coded near-black vs `AppColors.cosmicBlack` / `midnightNavy`; little use of token spacing |

**Verdict:** Strong visual reference; **not fully tokenized**.

### 3.2 Phone auth — `lib/features/auth/screens/phone_signup_screen.dart`

| aspect | evidence |
|--------|----------|
| Background | `AppGradients.cosmicBackgroundGradient` + orb blurs + `phone_signup_world_map.png` |
| Palette | `AppColors.midnightNavy`, `softGold`, `resonanceViolet`, `electricBlue` |
| CTA | `AppGradients.cosmicCtaGradient` + gold/violet glow shadows |
| Fields | Custom decoration (gold focus); Inter |
| Safe area | Yes |
| Loading | White spinner on CTA |

**Verdict:** Best **token-aligned** modern reference among auth screens.

### 3.3 IQ intro — `lib/features/assessment/screens/iq_test_intro_screen.dart`

| aspect | evidence |
|--------|----------|
| Background | Custom `_IqIntroBackdrop` on `AppColors.midnightNavy` |
| Brand | `welcome_q_glow.png` |
| Typography | Playfair/Inter; violet→gold ShaderMask on label |
| Hero | Breathing neural asset |
| Localization | `l10n.iqIntro*` |

**Verdict:** Strong modern reference; shares Q mark language with Welcome/IQ question.

### 3.4 IQ question — `iq_test_screen.dart` + `iq_question_chrome.dart`

| aspect | evidence |
|--------|----------|
| Chrome | Cosmic bg asset, glass option cards, violet/gold progress, `iqQuestionCtaGradient` |
| Top bar | Circular back + Q glow |
| Behavior | FLAG_SECURE via windowmanager (security, not visual) |

**Verdict:** Strongest **in-app product** visual reference for cards/CTA/progress.

### Reference inconsistencies (do not copy blindly)

1. Welcome scaffold `0xFF05040C` vs phone/IQ `midnightNavy` / `cosmicBlack`.
2. Multiple CTA gradients (`cosmicCta` vs `iqQuestionCta` vs solid gold ElevatedButtons on legacy).
3. `AppTheme.darkTheme` unused while screens reinvent TextStyles.
4. Some auth screens still flat black + solid gold (`login_screen`, `verification_screen`) — **semi-legacy** beside modern Welcome/Phone.

---

## 4. Legacy main screens

### 4.1 Shell — `MainNavigationScreen`

- Flat `AppColors.background` scaffold; **no cosmic backdrop**.
- Custom floating icon row (not Material `BottomNavigationBar`); content height 56 + safe bottom.
- Labels in Semantics only — **icons without visible text labels**.
- Settings not a tab (pushed from Profile).
- Uses l10n for nav labels.

### 4.2 Discover — `discover_screen.dart`

- Gold-primary Material buttons on flat black/surface cards.
- Has empty / loading / error / deletion banner (l10n) — good state coverage relative to Profile.
- Compatibility % / archetype chips are **not** live L2 ranking UI (product). Live order is trusted structural L2 without a percentage.
- Visual language: **black + gold**, weak violet/purple atmosphere.

### 4.3 Messages — `messages_screen.dart`

- Playfair title gold; list on flat background.
- Loading / error / empty present with l10n.
- Peer name/archetype resolution via Firestore + display resolver.
- Chat detail uses `chat_wallpaper_dark.png` (separate visual).

### 4.4 Profile — `profile_screen.dart`

- SliverAppBar + gold wash gradient; circular photo; Playfair `name, age`.
- **Name binding bug:** `'${_profile!.name}, ${_profile!.age}'` → empty name shows as `, 26`.
- `UserProfileModel.name` from Firestore `name ?? ''`.
- Phone user bootstrap writes `'name': user.displayName` (often null).
- `NameSelectionScreen` updates Auth `displayName` only; does **not** write Firestore `name` until `ProfileSetupScreen.save` copies Auth displayName.
- `AuthWrapper` routes to `ProfileSetupScreen` / `MainNavigationScreen` — **NameSelection not in wrapper path** (risk of empty name).
- No cosmic hero; Settings via AppBar icon.
- Limited empty-field UX beyond bio placeholder.

### 4.5 Settings — `settings_screen.dart`

- List tiles on `AppColors.background` / surface dialogs.
- l10n for most strings; logout + deletion request wired.
- Visual: gold titles, black canvas — same legacy main-app family.
- Sub-screens (privacy, notifications, blocked, legal) same family.

---

## 5. Hard-coded style inventory (representative)

| pattern | examples | modern/legacy | migration |
|---------|----------|---------------|-----------|
| `Color(0xFF…)` outside tokens | Welcome `05040C`; IQ chrome `0x66101828`, `0x779B8CFF` | mixed | fold into tokens |
| `Colors.white` / `Colors.black` | Welcome, CTAs, Discover like button | legacy/mixed | map to `textPrimary` / `onGold` |
| Solid gold `ElevatedButton` | Discover Like, Login | legacy vs cosmic CTA | replace with `QCosmicButton` / shared CTA |
| `GoogleFonts.playfairDisplay` / `inter` repeated | almost every screen | duplicated | text theme / style helpers |
| Padding `24` | Profile, Messages, Settings | duplicated vs `AppSpacing.lg` | standardize |
| `BorderRadius.circular(30)` | Profile archetype chip | ad-hoc | use `AppRadii` |
| Seed ThemeData | `main.dart` | legacy | replace when shell migrates |

---

## 6. Localization

- Main tabs + Discover/Messages/Settings: generally **l10n-ready**.
- Gaps: raw `e.toString()` SnackBars (Discover); some debug/admin strings; emoji in archetype chip.
- Profile name is data, not l10n.

---

## 7. Background assets (modern)

Welcome/Phone/IQ rely on `assets/images/welcome_*`, `phone_signup_world_map.png`, `iq_question_*`, `iq_neural_*`. Main tabs largely **asset-free flat fills**.

---

## 8. Future data-dependent screens (placeholders only)

Do **not** finalize UI for: partner preferences, relationship values, hard constraints, CM v2 compatibility cards, structured explanations. Document only that Discover cards and Profile metrics will need contract-driven redesign later (P2C-2/3).

---

## 9. Summary verdict

| area | status |
|------|--------|
| Token files | Exist (DS-0) |
| ThemeData application | **Not wired** |
| Cosmic components | Exist; **main tabs unused** |
| Welcome / Phone / IQ | Modern reference (with internal inconsistencies) |
| Discover / Messages / Profile / Settings / Nav | **Legacy black–gold** |
| Highest functional UI bug | Profile `, age` empty-name (**data_binding**) |
