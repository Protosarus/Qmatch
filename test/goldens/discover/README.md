# Discover golden baselines (P2C-1C-2A)

Test-only visual fixtures for the Discover presentation layer.

## Rules

- Synthetic local fixtures only (`test/support/discover_golden_fixtures.dart`)
- No Firebase reads/writes
- No production routes / debug routes in the runtime app
- Goldens live under `test/goldens/discover/`

## Viewports

| name | size |
|------|------|
| compact iPhone | 375 × 667 |
| large iPhone | 430 × 932 |

Text scales: `1.0` (all states) and `1.3` (candidate + empty).

## Fonts

Goldens load Inter/Playfair via `test/fonts/google_fonts/` stand-ins (Roboto copies)
so tests stay offline-deterministic. Device UI still uses real google_fonts families.

## Legacy presentation (goldens / rollback only)

Candidate goldens may intentionally include **rollback** CompatibilityScoring fields:

- compatibility label
- compatibility score (% chip)
- compatibility reasons
- archetype / category chips (when present on the runtime model)

These are **not** live `structural_l2_v1` ranking outputs and must not be read as a product compatibility percentage. Live L2 does not attach a % and does not show archetype as a matching key. Tracked as **G-041**.

## P2C-1C-2B loading refinement

`loading_compact_1_0.png` uses a card-shaped skeleton (photo, identity, bio,
chips, restrained actions) with opacity pulse + small caption spinner.
