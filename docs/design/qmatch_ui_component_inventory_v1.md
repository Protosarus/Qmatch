# QMatch UI Component Inventory v1

Phase: **P2C-1C-0** · Planned reusable components — **not implemented in this phase**.

Naming below is contractual; existing `Q*` cosmic widgets may be adapted or aliased.

---

## Component table

| component | current duplicates | proposed responsibility | screens | priority | must remain unchanged |
|-----------|-------------------|-------------------------|---------|----------|------------------------|
| **QMatchScaffold** | Each screen’s own `Scaffold` + bg color | Dark cosmic scaffold, status bar, optional background slot | all main + auth | P0 | routing / Firebase lifecycle |
| **QMatchBackground** | Welcome `_Backdrop`, phone gradient stack, IQ intro backdrop, flat `AppColors.background` | Shared void/deep gradient (+ optional asset layer) | shell, Discover, Messages, Profile, Settings | P0 | no forced heavy assets if perf issue |
| **QMatchPrimaryButton** | `QCosmicButton`, Discover Like, Login Filled, phone CTA | Primary CTA (cosmic gradient) + loading | all | P0 | onPressed contracts; disabled opacity 0.4 |
| **QMatchSecondaryButton** | Discover Pass outline, ghost CTAs | Outline / ghost gold-violet | Discover, Settings dialogs | P1 | |
| **QMatchGlassCard** | `QGlassCard`, Discover surface cards, IQ option cards | Glass/elevated card with border | Discover, Messages rows, Settings groups | P0 | list tap targets |
| **QMatchSectionTitle** | `QSectionHeader`, Playfair titles copy-pasted | Screen/section titles | all | P1 | l10n strings passed in |
| **QMatchEmptyState** | Discover / Messages empty columns | Icon + title + subtitle + optional CTA | Discover, Messages, Profile sections | P1 | existing l10n keys |
| **QMatchErrorState** | Discover / Messages error columns | Error icon + copy + retry | Discover, Messages, Profile load | P1 | retry callbacks |
| **QMatchLoadingState** | Gold `CircularProgressIndicator` centers | Consistent loader | all | P1 | |
| **QMatchProfileAvatar** | Profile circle + camera badge; Discover person placeholder | Avatar + fallback + edit affordance | Profile, Discover, Messages | P1 | photo URL / navigation to edit |
| **QMatchBottomNavigation** | Inline in `MainNavigationScreen` | Shared 3-tab nav (Discover / Messages / Profile) | shell only | P0 | index state; Settings stays pushed route |
| **QMatchSettingsTile** | Settings `ListTile`s | Leading icon + title + trailing | Settings + subpages | P1 | navigation targets |
| **QMatchProfileSection** | Profile `_buildSection` / interests | Labeled content block | Profile | P2 | field data |

### Existing primitives to reuse (prefer adapt over rewrite)

| existing | maps toward |
|----------|-------------|
| `QCosmicButton` | QMatchPrimaryButton / secondary variants |
| `QGlassCard` | QMatchGlassCard |
| `QPremiumTextField` | form fields on auth/settings |
| `CosmicProfileHero` | future Profile hero (not v1 tab requirement) |
| Assessment chrome widgets | stay assessment-scoped; borrow metrics only |

---

## Migration priority legend

- **P0** — required for shared shell / first visual unification
- **P1** — required to finish Discover/Messages/Profile/Settings polish
- **P2** — nice-to-have consistency

---

## Behavior freeze (non-visual)

Do not change while restyling:

- Tab indices and destinations
- Discover like/pass → swipe/match services
- Messages stream + chat navigation
- Profile photo edit route
- Settings logout / deletion request / blocked users
- Assessment FLAG_SECURE and scoring flows
