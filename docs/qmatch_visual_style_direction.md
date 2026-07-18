# Qmatch Visual Style Direction (Phase 4A)

Date: 2026-07-18 (patched 4A-Patch: Profile Hero)  
Mode: **Style definition only** — no UI code changes in this phase  
Founder decision: **A — Premium Cosmic Minimal** as primary; lightly borrow **C — Neo Lab** only for IQ/EQ/Frequency visualization components.  
Profile identity: **Cosmic Profile Hero** — large circular portrait with orbital halo (not a flat dating profile).

Product language anchors:

- Not “scores only” — *frequency / connection* (“Skor değil, frekans.”)
- IQ = how you think · EQ = how you feel · Frequency = how you connect

---

## 1. Current visual / design state (audit)

### Theme tokens (today)

| Token | Value | File |
|-------|--------|------|
| Background | `#0C0C0C` near-black | `lib/core/theme/app_colors.dart` |
| Surface | `#1A1A1A` | same |
| Primary / accent | `#E3C565` gold | same |
| Secondary | `#D946EF` purple-pink (named for gradients; lightly used) | same |
| Text | white / `#B0B0B0` | same |
| Error / success | `#FF6B6B` / `#4ECDC4` | same |
| Typography | Playfair Display (display) + Inter (body) via `google_fonts` | `app_theme.dart` |
| Buttons | Transparent fill + gold outline, radius **12** | theme |
| Nav | Pill / floating tab cues with gold selection | `main_navigation_screen.dart` |
| Motion | Welcome fade/slide (~900ms); few shared motion tokens elsewhere | `welcome_screen.dart` |

### Screen inventory (structure)

| Area | Screens (examples) |
|------|-------------------|
| Auth | Welcome, phone signup/verification, login, email paths, social stubs |
| Profile | Setup wizard steps, profile view/edit, photo edit |
| Assessment | IQ/EQ/Frequency intro + test + result |
| Core loop | Main tabs, Discover, Messages/chat |
| Settings / safety | Settings, privacy, notifications (UI-only), help, about, legal docs, blocked, account deletion |

### Assets

- Brand logos under `assets/images/` (`logo.png`, `logo_white.png`, `qmatch_logo.png`)
- Chat wallpaper dark asset
- No dedicated illustration/icon system beyond Material / Font Awesome

### Strengths already present

- Dark-first premium instinct (aligned with Cosmic Minimal)
- Gold + serif display already suggests “elegant / intelligent”
- Some soft gold borders and dialog glow (`success_dialog.dart`)

### Gaps / inconsistencies

- Secondary violet/pink underused; no coherent “cosmic depth” gradients or glass system
- Radius / spacing / cards reinvented per screen (12 / 16 / 18 / 24 / 999 mix)
- Forms often default dark fields; low hierarchy between primary CTA vs outline
- Assessment results lack distinctive visual language (rings/radar reserved for later Cosmic+Lab hybrid)
- Profile view likely reads as a standard flat dating header (photo + text stack) — missing the founder **Cosmic Profile Hero**
- Discover / chat feel utilitarian vs welcome’s intentional motion
- `google_fonts` network fetch noted in store privacy docs (implementation later may need bundling)

**Net:** The app is *pointing* at Premium Cosmic Minimal but lacks a full tokenized system, atmospheric backgrounds, differentiated IQ/EQ/Frequency viz, and a premium profile portrait hero.

---

## 2. Three possible directions

### A. Premium Cosmic Minimal *(primary — selected)*

| Aspect | Direction |
|--------|-----------|
| Brand feeling | Elegant, mysterious, intelligent, emotional, trustworthy |
| User perception | “Premium connection app that sees how I think, feel, and resonate” |
| Color | Deep void blacks/indigos; soft violet–indigo haze; gold as rare accent |
| Typography | Refined display (serif or high-end geometric) + clean sans body |
| Cards / buttons | Soft glass / subtle border glow; gold outline primary; limited solid gold fills |
| Icons / illustration | Minimal line icons; rare star/spark motifs; no cartoon clutter |
| Motion | Slow fades, soft parallax haze, restrained pulse on match/frequency |
| Strengths | Unique vs mass dating apps; fits IQ/EQ/Frequency mythos; App Store “premium” first look |
| Risks | Too dark/cold if overdone; glow spam; fake “AI futurism” look |
| Best screens | Splash, welcome, assessments, discover, results, **profile hero** |

### B. Warm Human Connection

| Aspect | Direction |
|--------|-----------|
| Brand feeling | Soft, trusting, emotional, approachable |
| Color | Warm cream/rose nights or blush accents on dark |
| Strengths | Onboarding comfort, dating trust |
| Risks | Dilutes IQ/Frequency uniqueness; can look generic dating |
| Best screens | Onboarding, chat, safety |

*Not primary.* May borrow **one** warm accent for trust moments (safety success), not whole system.

### C. Neo Lab / Compatibility Engine *(borrow selectively)*

| Aspect | Direction |
|--------|-----------|
| Brand feeling | Analytical, instrumented, “engine” |
| Strengths | Clarity for IQ/EQ/Frequency viz |
| Risks | Dashboard coldness; clinical dating feel |
| Use in Qmatch | **Only** compatibility rings, radar/connection maps, progress arcs, score-explanation cards |

---

## 3. Recommended primary direction

**Primary: A — Premium Cosmic Minimal**  
**Secondary loan: C — Neo Lab viz modules only**

### Why this mix

| Criterion | Fit |
|-----------|-----|
| Global audience | Dark premium social reads internationally; gold/violet feels adult, not juvenile |
| Compatibility positioning | Cosmic “frequency” metaphor; Lab tools explain IQ/EQ/Frequency without owning the whole UI |
| Store first impression | Dramatic but calm splash/welcome; not a spreadsheet |
| Premium without fake | Soft haze + one gold accent > purple neon overload |
| Flutter difficulty | Tokens + ThemeExtension + shared widgets are manageable; full custom charts are phased |

**Emotional hierarchy:** premium → emotional → mysterious → trustworthy **first**; analytical **second**.

Avoid: pure dashboard chrome, dense tables, clinical blues, loud cyberpunk neon.

### Profile identity: Cosmic Profile Hero *(founder requirement)*

The Qmatch **profile page must not look like a standard flat dating profile**. The person’s photo is the premium emotional anchor of the screen.

| Requirement | Spec |
|-------------|------|
| Portrait | **Large circular** portrait near the top of the profile |
| Atmosphere | Subtle **cosmic / orbital glow** around the portrait |
| Halo / frame | Elegant multi-accent frame: **violet · indigo · electric blue · soft gold** |
| Identity cluster | Name, age, profession, city **close to** the portrait |
| Voice | Short quote / bio **close to** the portrait |
| Compatibility | Compatibility context **integrated around** the profile (Cosmic shell; Lab viz only if showing IQ/EQ/Frequency numbers) |
| Feeling | Cinematic, premium, intelligent, **emotionally warm** — mysterious without cold |

**Do not:** small square avatar, flat photo strip, dense stats dashboard above the fold, clinical rings as the whole profile.

**Future component name (docs only — not implemented yet):** `CosmicProfileHero`

---

## 4. Design system foundation (recommended)

### 4.1 Color roles (Cosmic Minimal)

| Role | Intent | Suggested direction (tokens later) |
|------|--------|-------------------------------------|
| `bg.void` | App canvas | Near-black with cool indigo tint (evolve `#0C0C0C`) |
| `bg.deep` | Elevated night | Slightly lifted void |
| `surface.glass` | Cards / sheets | Translucent dark + 1px soft border |
| `border.soft` | Separators | Low-contrast indigo/gold mix |
| `accent.gold` | Primary brand actions / focus | Keep family of `#E3C565` (refine) |
| `accent.violet` / `accent.indigo` | Atmospheric gradients, Frequency | Soft, not neon; replace ad-hoc `#D946EF` overload |
| `text.primary` / `text.muted` | Hierarchy | White / cool gray |
| `state.error` / `success` / `warning` | Feedback | Keep error red; success teal or soft mint (not loud green) |
| `viz.iq` / `viz.eq` / `viz.freq` | Lab-borrowed viz only | Distinct but muted channel colors |

**Light mode:** **Not recommended for v1.** Dark is the brand. Optional future “dawn” mode later; don’t split effort pre-launch.

### 4.2 Typography

| Level | Role | Direction |
|-------|------|-----------|
| Display | Brand / screen titles | Keep Playfair *or* refine to one elegant display; brand > noise |
| Title | Section heads | Semibold sans or lighter display |
| Body | Forms, chat, help | Inter (or bundled equivalent) |
| Caption / meta | Scores, times | Smaller muted sans |
| Viz labels | Ring/radar captions | Caption; never shout |

Avoid stacking too many font weights on one screen.

### 4.3 Spacing scale

`4 · 8 · 12 · 16 · 24 · 32 · 48`  
Screen horizontal padding default **24**. Card internal padding **16–20**.

### 4.4 Radius

| Element | Radius |
|---------|--------|
| Buttons / inputs | **16** |
| Cards / dialogs | **20–24** |
| Pills / nav | **999** |
| Avatars | Circle |
| Profile hero portrait | Large circle (hero scale — not list avatar size) |
| Viz rings | Geometry-led (not generic cards) |

### 4.5 Shadow / glow

- Prefer **1px luminous borders** over heavy drop shadows  
- Gold glow only on: primary CTA focus, match moment, Frequency result peak, **and Cosmic Profile Hero orbital halo** (restrained)  
- Max one glow focus per viewport (on profile, the portrait halo is that focus)  
- Profile halo: soft violet/indigo/electric-blue/gold — orbital, not neon cyberpunk  

### 4.5b Cosmic Profile Hero *(foundation note)*

- Portrait is the hero composition of the profile viewport  
- Meta (name / age / profession / city) and short quote/bio sit in the same vertical cluster as the portrait  
- Compatibility cues wrap or sit adjacent as quiet Cosmic context — not a control panel  
- Edit / settings affordances stay secondary and do not compete with the hero  

Suggested future widget: **`CosmicProfileHero`** (implement in a later design-system phase; not in 4A docs-only).

### 4.6 Buttons

| Type | Style |
|------|--------|
| Primary | Gold outline *or* soft gold fill on dark (pick one system; don’t mix random) |
| Secondary | Ghost / quiet border |
| Destructive | Error outline (Delete account) |
| Disabled | 40% opacity |

### 4.7 Cards

- Glass surface + soft border  
- No stacked “dashboard widgets” on social screens  
- Discover: one hero card composition, not a control panel  

### 4.8 Forms

- Tall touch targets (≥48)  
- Gold focus ring  
- Label above; helper muted  
- Errors in error color, not gold  

### 4.9 Assessment / progress (Cosmic + Lab loan)

- Progress: thin arc or soft bar in accent  
- Result: **ring / radar / connection map** (Lab) sitting on Cosmic glass card  
- Copy: emotional frequency language first; numbers secondary  

### 4.10 Empty / loading / error

- Loading: quiet cosmic pulse (not spinners-as-brand)  
- Empty Discover: short poetic line + single CTA  
- Error: clear, calm, support link `support@qmatch.site`  

### 4.11 Safety / legal / support in-app

- Quiet, readable typography; no glow  
- Links look like links (underline or gold text), not party buttons  
- Deletion flow: serious red outline + clear hierarchy (already partly there)  

---

## 5. Screen-level style guidance

| Screen | Guidance |
|--------|----------|
| **Splash / first impression** | Brand mark large; void + soft indigo haze; minimal text; gold whisper |
| **Login / phone auth** | Calm single-column; logo; one primary CTA; stub Google/Apple de-emphasized or hidden later |
| **Onboarding** | Story beats for IQ / EQ / Frequency — poetic, not lecture; warm trust without abandoning Cosmic |
| **Profile (view)** | **Cosmic Profile Hero:** large circular portrait + orbital halo (violet/indigo/electric blue/soft gold); name/age/profession/city and short quote/bio close to portrait; compatibility context integrated around — cinematic, premium, warm; **not** a flat dating header |
| **Profile create / edit** | Glass step cards; clear progress; photo gallery remains gallery; after save, view should land back into Cosmic Profile Hero language |
| **IQ / EQ / Frequency assessment** | Focus mode: one question; soft progress; minimal chrome |
| **Results / compatibility** | Lab viz (ring/radar) on Cosmic glass; “frequency” headline; scores secondary |
| **Discover** | One composition card; photo + archetype/frequency cue; Pass/Like as elegant twin actions |
| **Chat / messages** | Dark wallpaper OK if subtle; bubbles quiet; safety menu accessible |
| **Settings** | List clarity > decoration; legal/support plain |
| **Delete account / safety** | High clarity, low decoration; destructive confirmed |
| **Legal / support (in-app)** | Document readability; match `qmatch.site` calm tone |

---

## 6. P0 / P1 / P2 design roadmap

### P0 — before public launch (visual)

1. Tokenize Cosmic palette + fix random secondary/glow misuse  
2. Unify button / card / radius / spacing  
3. Welcome + auth first impression pass (premium, not template)  
4. Discover card hierarchy (one composition)  
5. Assessment result / Frequency visual (at least one coherent ring/result treatment)  
6. Delete account / safety readability check (trust)  

### P1 — should fix before launch

1. Profile wizard visual consistency  
2. **`CosmicProfileHero` on profile view** (large circular portrait, orbital halo, identity + quote cluster, integrated compatibility context)  
3. Chat bubble / wallpaper refinement  
4. Empty / loading / error patterns shared  
5. Settings / help / legal typography pass  
6. Bundle or offline strategy for fonts (privacy note)  

### P2 — polish later

1. Micro-interactions (match pulse, soft parallax, gentle hero halo breathe)  
2. Illustration system  
3. Advanced radar / connection map  
4. Optional “dawn” light theme  
5. Discover card may *echo* hero language lightly (circular cue) without copying the full profile composition

---

## 7. Future features *(separate from visual work)*

| Idea | Type | Notes |
|------|------|--------|
| **`CosmicProfileHero` component** | Design system / UI | Docs-locked; implement later — premium circular portrait + orbital halo |
| Richer compatibility explanation | Feature + light UI | Fits Cosmic copy; may sit near Profile Hero |
| Profile badges / frequency tags | Feature | Design after tokens; keep subordinate to Profile Hero |
| Frequency insights history | Feature | Lab viz loan |
| Onboarding story frames | Feature/content | Cosmic |
| Safer report/block UX | Feature | Clarity > glow |
| Premium subscription | Feature | **Store/privacy impact** |
| AI matching / chat assist | Feature | **Privacy/store impact** |
| Push notifications | Feature | **Privacy/store — FCM not configured** |
| Analytics / Crashlytics | Infra | **Privacy/store — currently No** |
| Ads / ATT | Feature | Reject for brand + privacy |

---

## 8. Privacy / store flags for future work

Any future feature that adds the following must update App Privacy / Data Safety + docs:

| Topic | Current launch stance | Design implication |
|-------|----------------------|--------------------|
| Push / FCM | Not configured | Don’t design notification centers that imply push until SDK decision |
| Analytics / Crashlytics | No | Don’t add tracking screens |
| Payments / IAP | Absent | No paywalls in P0 UI unless product decides |
| Precise location | Declared collectable | Don’t upsell background location |
| Camera capture | Gallery path; camera permission messy | Design for gallery-first |
| AI profiling | None | Cosmic metaphor ≠ claiming AI; avoid copy that implies AI analysis |
| Ads / tracking | No | No ad placements in Cosmic layout |
| Sensitive fields | Gender / looking-for / religion | Quiet forms; no voyeuristic spotlight |
| Contacts | Not collected | No “find friends” contact scrapers |

---

## Explicit non-actions (this phase)

No UI code edits · no Firebase · no deploy · no commit/push  

Next: `docs/qmatch_design_system_implementation_plan.md`
