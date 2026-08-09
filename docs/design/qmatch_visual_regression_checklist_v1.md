# QMatch Visual Regression Checklist v1

Phase: **P2C-1C-0** · Use after each P2C-1C implementation slice.

---

## A. Visual language

- [ ] Main tabs use same dark cosmic language as Welcome / Phone / IQ (not flat black–yellow only)
- [ ] Single purple accent family (`resonanceViolet` ± deep/blue supports)
- [ ] Single gold accent family (`softGold` / `warmGold`)
- [ ] Playfair titles + Inter body consistently
- [ ] Primary CTAs use agreed gradient (or documented exception)
- [ ] Cards share radius/border language

## B. Navigation and layout

- [ ] Bottom nav Discover / Messages / Profile unchanged in behavior
- [ ] Settings still reachable from Profile
- [ ] No broken back stacks
- [ ] Body content not hidden under floating nav
- [ ] Safe area: no clipped status bar / home indicator content
- [ ] No RenderFlex overflow on iPhone SE-class and large Android

## C. States

- [ ] Loading: consistent indicator
- [ ] Empty: Discover + Messages (and Profile sections as applicable)
- [ ] Error: retry where previously available
- [ ] Profile missing name: no leading comma (fallback or data fix verified)

## D. Data / Firebase behavior (non-regression)

- [ ] Discover like/pass/match still write expected paths
- [ ] Messages threads stream unchanged
- [ ] Profile photo URL load/edit
- [ ] Settings logout + deletion request
- [ ] No hard-coded user names/ages in UI code

## E. Localization and a11y

- [ ] User-visible strings via l10n (en/tr smoke)
- [ ] Semantics on nav items
- [ ] Contrast: gold-on-void titles OK; body readable; on-gold text dark
- [ ] Dynamic type: no critical clipping at large text (spot-check)

## F. Platforms

- [ ] iOS simulator visual pass (no codesign claim)
- [ ] Android emulator/device visual pass
- [ ] Dark theme contrast checked on both

## F1. P2C-1C-1 shell and navigation checks

- [ ] Shared shell background visible behind Discover / Messages / Profile without reducing readability
- [ ] Bottom navigation keeps tab order: Discover → Messages → Profile
- [ ] Tab switching preserves screen state (no unnecessary page reconstruction)
- [ ] Settings remains accessible from Profile and is not promoted to a tab
- [ ] Compact iPhone safe area checked
- [ ] Large iPhone safe area checked
- [ ] Compact Android / gesture-nav bottom inset checked
- [ ] Text scale 130% checked for nav labels and tap targets
- [ ] Keyboard interaction on pushed screens checked where relevant
- [ ] App resume returns to the previously selected tab where runtime currently preserves it
- [ ] Orientation policy verified unchanged
- [ ] Profile `, 26` defect still tracked as unresolved **Profile/data** issue (not hidden by shell styling)

## F2. P2C-1C-2 Discover visual migration checks

Device checks below remain **unchecked** until fresh iOS (and later Android) visual verification.

- [ ] Discover loading state: skeleton / indicator, not blank frozen screen
- [ ] Populated candidate card: photo + identity + bio/interests when present
- [ ] Missing-photo candidate: deterministic placeholder + semantic label
- [ ] Empty state: modern copy (no Core Method claim); retry available
- [ ] Error state: distinct from empty; localized title/body; retry; no raw Firebase text
- [ ] Retry from empty and error reloads candidates
- [ ] Like control triggers existing handler; loading/disabled during action
- [ ] Pass control triggers existing handler; loading/disabled during action
- [ ] Mutual match dialog (when like returns match): modern tokens; continue dismisses
- [ ] Compact iPhone: card + actions clear of bottom nav; no overflow
- [ ] Large iPhone: card proportions remain readable
- [ ] Text scale ~130%: identity / bio / actions remain usable
- [ ] Shell / cosmic background continuity behind Discover content
- [ ] Bottom-navigation clearance preserved (shell inset + Discover SafeArea)
- [ ] Long display name ellipsizes; empty name does not render leading comma
- [ ] No fabricated Core Method / persona / distance fields on card

## F2A. P2C-1C-2A Discover golden baseline (deterministic)

Synthetic fixtures only — no Firebase. Goldens: `test/goldens/discover/`.

- [x] Loading state golden (compact, text scale 1.0)
- [x] Empty state golden (compact 1.0 + 1.3)
- [x] Error state golden (compact 1.0) — visually distinct from empty
- [x] Candidate with synthetic photo (compact 1.0, large 1.0, compact 1.3)
- [x] Candidate missing photo placeholder (compact 1.0)
- [x] Long name/bio candidate (compact 1.0) — no overflow exception
- [x] Action-loading state (compact 1.0)
- [x] Mutual-match dialog chrome (compact 1.0)
- [x] Shell + action bar clears bottom navigation (compact 1.0)
- [x] Missing name does not render `, {age}` malformed identity
- [x] Presentation widgets audited: no Firebase/query/scoring ownership
- [x] Legacy compat label/score/reasons/archetype documented as temporary (G-041) — **not** final CM v2
- [ ] Live iOS simulator visual pass against goldens (human)
- [ ] Live Android visual pass (deferred — SDK absent)

## F2B. P2C-1C-2B Discover loading refinement

- [x] Loading skeleton mirrors candidate card (photo / identity / bio / chips / restrained actions)
- [x] No large isolated spinner in empty photo panel
- [x] Lightweight opacity pulse via Flutter `AnimationController` (no shimmer package)
- [x] Small spinner adjacent to localized loading text
- [x] Action placeholders reduced (height 40 vs prior 52 full bars)
- [x] Refined loading golden regenerated (`loading_compact_1_0.png`)
- [x] Re-proof goldens: photo / missing-photo / long-content / error / match dialog
- [ ] Live iOS confirmation of refined loading (human)

## F3. P2C-1C-3A Messages inbox visual migration

Device checks remain **unchecked** until live iOS verification.

- [ ] Messages loading skeleton (avatar / name / preview / timestamp)
- [ ] Messages empty state (modern; after-match copy; no fake CTA)
- [ ] Messages error state (distinct from empty; localized; retry re-subscribes)
- [ ] Populated conversation list with glass tiles
- [ ] Unread row: weight + unread marker (not color-only); real unread_counts only
- [ ] Read row: restrained weight; no fabricated unread
- [ ] Missing avatar placeholder
- [ ] Missing/deleted counterpart uses localized fallback (no raw uid/email)
- [ ] Long name / long preview truncate without overflow
- [ ] Bottom-navigation clearance for last row
- [ ] Compact + large iPhone viewports
- [ ] Text scale ~130%
- [ ] Conversation tap opens existing ChatDetailScreen
- [ ] No fabricated online/typing/compatibility on inbox rows
- [x] Chat-detail screen deferred from 3A → completed in P2C-1C-3B (code)

### F3A. Deterministic goldens (`test/goldens/messages/`)

- [x] loading
- [x] empty
- [x] error
- [x] read conversation
- [x] unread conversation
- [x] multiple conversations
- [x] missing avatar
- [x] deleted/missing counterpart
- [x] long name + long preview
- [x] text scale ~1.3 (list)
- [ ] Live iOS visual pass against goldens (human)

## F3B. P2C-1C-3B Conversation detail visual migration

Device checks remain **unchecked** until live iOS verification.

- [ ] Patterned science/love/space wallpaper visible (repo-owned WebP)
- [ ] Wallpaper contrast / dark-purple overlay keeps bubbles readable
- [ ] Modern conversation app bar (avatar + name + existing menu)
- [ ] Incoming bubble (distinct; readable on wallpaper)
- [ ] Outgoing bubble (restrained violet; not bright gold fill)
- [ ] Long message wraps without horizontal overflow
- [ ] Timestamps only when backed by createdAt / clientCreatedAt
- [ ] Date separators on day boundaries (presentation-only)
- [ ] Empty / loading / error states (wallpaper remains for empty/loading)
- [ ] Modern multi-line composer + send; no attachment/camera/mic chrome
- [ ] Keyboard open: composer above keyboard; no bottom overflow
- [ ] Compact + large iPhone viewports
- [ ] Text scale ~130%
- [ ] Missing / deleted counterpart: localized fallback; avatar placeholder; no uid/email
- [ ] Scrolling / auto-scroll on new message count (existing stream preserved)
- [ ] Send behavior unchanged (ChatService.sendTextMessage; duplicate guard)
- [ ] No fabricated online / typing / read receipts / calls / compatibility
- [ ] Live iOS simulator visual pass against goldens (human)

### F3B-G. Deterministic goldens (`test/goldens/chat_detail/`)

- [x] empty *(wallpaper verified after asset precache in golden harness)*
- [x] loading
- [x] error
- [x] incoming
- [x] outgoing
- [x] mixed conversation (+ date separators)
- [x] long message
- [x] emoji / multiline *(emoji glyphs may be limited under test fonts)*
- [x] missing counterpart
- [x] composer + keyboard insets
- [x] large viewport
- [x] text scale ~1.3
- [x] Human-review contact sheet: `chat_detail_visual_review_contact_sheet.png` (P2C-1C-3B-1)
- [ ] Live iOS simulator visual pass against goldens (human) — still recommended when a real conversation exists; synthetic proof is complete

## F4A. P2C-1C-4A Display-name identity

- [x] Shared validator / resolver (no `, 26`)
- [x] Completion screen goldens under `test/goldens/display_name/`
- [x] Profile identity uses shared formatter
- [ ] Live iOS pass: new user must enter display name before assessments
- [ ] Live iOS pass: existing empty-name user gated to completion
- [ ] Android verification (deferred)

## G. Explicit non-checks (later phases)

- [ ] CM v2 explanation UI
- [ ] Preference / values / hard-constraint final screens
- [ ] Production Firebase rules deploy
- [ ] Full Profile visual migration (P2C-1C-4B) — **code complete**; live iOS human sign-off open
- [ ] Profile Edit display-name change UI (G-046)

## F4B. P2C-1C-4B Profile visual migration

- [x] Audit: `docs/design/qmatch_profile_screen_audit_v1.md`
- [x] Modern header + Settings (44×44)
- [x] Shared identity resolver (no `, 26`)
- [x] Photo + missing placeholder; photo edit preserved
- [x] About / interests / details sections
- [x] Legacy archetype / category / raw scores omitted
- [x] Loading / error states
- [x] Goldens under `test/goldens/profile/`
- [x] Contact sheet: `profile_visual_review_contact_sheet.png`
- [ ] Live iOS simulator visual pass (human)
- [ ] Android verification (deferred)
- [ ] Profile Edit (G-046)

## F5. P2C-1C-5 Settings / Photos / cosmic background

- [x] Audits: `qmatch_settings_screen_audit_v1.md`, `qmatch_profile_photo_screen_audit_v1.md`
- [x] Shared `QMatchCosmicBackground` (deterministic, reduced-motion safe)
- [x] Cosmic applied to Profile, Settings, Profile Photo Management only
- [x] Settings grouped glass tiles; Debug `kDebugMode` / test override
- [x] Honest Notifications/Privacy subtitles (no fake FCM)
- [x] Logout vs delete visually separated
- [x] Photo zero / partial / nine layouts (no nine empty placeholders)
- [x] Upload/delete/reorder paths preserved; max count 9 unchanged
- [x] Sanitized upload/delete failure copy (no raw Firebase)
- [x] Goldens: `test/goldens/settings/`, `profile_photos/`, `cosmic_background/`
- [x] Contact sheets for settings / photos / cosmic
- [ ] Live iOS Settings visual sign-off
- [ ] Live iOS Profile Photo Management sign-off (incl. permissions)
- [ ] Live iOS Profile + cosmic scroll/background sign-off (G-050)
- [ ] Android verification (deferred)
- [ ] Notifications persistence / FCM (product gap)
- [ ] Privacy preference persistence (product gap)

## F5B. Settings destinations / shared controls / breathing verification

- [x] Destination audit: `qmatch_settings_destination_audit_v1.md`
- [x] Shared `QMatchPushedScreenHeader` on Settings destinations + Profile Photos
- [x] Shared `QMatchPrimaryAction` on Profile Photos and destination CTAs
- [x] Privacy visual migration on cosmic background
- [x] Debug visual migration remains debug-only
- [x] Reachable legal/help/about/delete destinations visually migrated
- [x] Deterministic phase-A / phase-B / reduced-motion cosmic verification added
- [ ] Manual iOS simulator observation: watch Profile / Settings / Profile Photos for **8 seconds** and confirm at least one accent star subtly brightens/dims
- [ ] Manual iOS simulator observation: reduced motion ON shows static stars only
- [ ] Manual iOS simulator observation: no synchronized blinking / no rapid flashes
- [ ] Manual iOS simulator observation: pushed Settings destinations match root visual language
- [ ] Android verification (deferred)
