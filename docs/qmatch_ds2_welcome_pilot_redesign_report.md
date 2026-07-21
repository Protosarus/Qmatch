# Qmatch DS-2 — Responsive Hybrid Welcome Rebuild

Date: 2026-07-19  
Phase: **DS-2 Responsive Hybrid Welcome Rebuild**  
Mode: Visual + layout only — auth / navigation / Firebase unchanged.

---

## A. Files changed

| File | Change |
|------|--------|
| `lib/features/auth/screens/welcome_screen.dart` | Full hybrid responsive rebuild |
| `assets/images/welcome_cosmic_background.png` | New text-free cosmic backdrop |
| `assets/images/welcome_couple_hero.png` | New transparent couple + energy hero |
| `docs/qmatch_ds2_welcome_pilot_redesign_report.md` | Updated (this report) |
| `assets/images/welcome_screen_full.png` | **Removed** (full UI mockup) |
| `assets/images/welcome_portal_hero.png` | Removed obsolete portal file |

`pubspec.yaml` unchanged — `assets/images/` already registered.

---

## B. Full-screen mockup removed?

**Yes.** `welcome_screen_full.png` is deleted and is no longer used as a background. The approved concept remains a visual reference only.

---

## C. Decorative assets used

1. `assets/images/welcome_cosmic_background.png` — stars, nebula, horizon; **no text/UI**
2. `assets/images/welcome_couple_hero.png` — facing profiles + central energy; soft circular alpha; **no text/UI**

All branding, cues, headline, CTA, login, trust cards, and legal text are Flutter widgets.

---

## D. Responsive layout strategy

- `SafeArea` + `LayoutBuilder` + `MediaQuery`-derived density
- Content capped at **430px** max width, centered
- Horizontal padding: `4.5%` of width (clamped 14–22)
- Hero size: fraction of content width, clamped by available height and max caps
- Typography scales within dense/short/normal bands
- `BoxFit.cover` only for cosmic background
- `BoxFit.contain` for couple hero
- `Flexible`/`Expanded` only around the hero
- Controlled `SingleChildScrollView` **only** when height &lt; 640
- Exactly one CTA, one login link, one trust-card row, one legal block

---

## E. Sizes tested

| Size | Strategy |
|------|----------|
| 320 × 568 | tiny density + scroll safety |
| 375 × 812 | short/dense scaling |
| 390 × 844 | standard |
| 430 × 932 | max-width constrained |

(Simulator matrix not exhaustively automated in this pass; layout math targets these breakpoints.)

---

## F. Behavior preserved

- Continue with Phone → `PhoneSignupScreen` (`l10n.welcomeContinueWithPhone`)
- Login link → `LoginScreen`
- Terms copy → `l10n.welcomeTermsPrivacy`
- Light status bar icons on dark background (`SystemUiOverlayStyle.light`)

---

## G. Auth / Firebase changes

**None.**

---

## H. Animation status

**Static** for this step. Orbits / particles deferred.

---

## I. flutter analyze

See latest run in session — target: no issues on `welcome_screen.dart`.

---

## J. Git status

Uncommitted local changes only. **Not committed. Not pushed.**

---

## K. Remaining visual limitations

- Couple hero is a soft-masked square PNG; eventual dedicated transparent export will read cleaner on extreme aspect ratios
- Feature cue labels currently English (brand row); CTA/terms/login localize
- Motion system (portal rings, star drift) not yet implemented
- Trust card body copy still English marketing strings

---

## Composition order (top → bottom)

1. Brand (Q / Qmatch / tagline)  
2. Feature cues  
3. Couple hero (asset)  
4. Find your / frequency + subtitle  
5. Continue with Phone  
6. Log in with email  
7. Trust cards  
8. Legal text  
