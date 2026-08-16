# QMatch Release Readiness Scorecard v1

Phase: **P2C-1A update** · base HEAD `4bbd6cb`  
**Percentage is derived only from this weighted table — not invented.**

Nothing scored `END_TO_END_VERIFIED` or `RELEASE_READY` (no device E2E in this audit).

---

## Scoring rules

| status | credit (% of category weight) |
|--------|-------------------------------:|
| RELEASE_READY | 100 |
| END_TO_END_VERIFIED | 85 |
| RUNTIME_WIRED_UNVERIFIED | 50 |
| LEGACY_ACTIVE | 40 |
| IMPLEMENTED_OFFLINE | 25 |
| DESIGNED_ONLY | 10 |
| UNKNOWN | 15 |
| NOT_STARTED | 0 |
| BLOCKED | 0 |
| DUPLICATED | min of competing paths |

Category score = weight × credit.  
**Total readiness % = sum(category scores).**

---

## Weighted categories

| # | category | weight | assigned status | credit | score |
|---|----------|-------:|-----------------|-------:|------:|
| 1 | Auth & account lifecycle | 10 | mixed → treat as BLOCKED/incomplete (Google/Apple/reset/deletion) effective **NOT_STARTED+partial** → use **25** blended* | 25 | **2.5** |
| 2 | Assessments & question banks | 15 | LEGACY_ACTIVE | 40 | **6.0** |
| 3 | Trait scoring / 20D canonical profile | 10 | DESIGNED_ONLY (adapter) | 10 | **1.0** |
| 4 | Partner prefs / values / hard constraints | 8 | NOT_STARTED | 0 | **0.0** |
| 5 | Core Method v2 matching engine | 12 | IMPLEMENTED_OFFLINE | 25 | **3.0** |
| 6 | Discover & ranking | 10 | `structural_l2_v1` live (canonical 20D); CompatibilityScoring rollback-only | 70 | **7.0** |
| 7 | Like / pass / match | 8 | RUNTIME_WIRED_UNVERIFIED | 50 | **4.0** |
| 8 | Messaging | 8 | RUNTIME_WIRED_UNVERIFIED | 50 | **4.0** |
| 9 | Profile & photos | 6 | RUNTIME_WIRED_UNVERIFIED | 50 | **3.0** |
| 10 | Notifications (FCM) | 4 | NOT_STARTED | 0 | **0.0** |
| 11 | Safety / moderation | 4 | RUNTIME_WIRED_UNVERIFIED | 50 | **2.0** |
| 12 | Firebase security & backend ops | 10 | IMPLEMENTED_OFFLINE (rules/storage/indexes in repo, not deployed; runtime conflicts) | 25 | **2.5** |
| 13 | Store packaging & legal | 5 | RUNTIME_WIRED_UNVERIFIED (canonical ids aligned; Android Firebase JSON + signing/legal still open) | 50 | **2.5** |
| | **Total** | **100** | | | **37.5** |

\*Auth blend: phone + email login RUNTIME_WIRED_UNVERIFIED (~50 of half the weight) and Google/Apple/reset/deletion gaps at 0 → documented as **2.5/10**.

---

## Derived release-readiness percentage

\[
\mathbf{37.5\%}
\]

Interpretation: **not release-ready**. Discover ranking is trusted structural L2 (`structural_l2_v1`); remaining gaps are banks, CM v2, prefs/values, packaging, and security. Do not treat CompatibilityScoring as the live ranker.

---

## Feature tallies (audit-wide)

| tally | count | notes |
|-------|------:|-------|
| Runtime-wired features (unverified) | **11** | phone/email login, assessment flow screens, Discover load, swipe/match, chat, photos, block/report, sign-out, deletion *request*, progress routing, eligibility field writes |
| Offline-only features | **12+** | CM v2 ×7 services, TraitScoring, PersonaScoring, v3 pilots/candidates, offline harnesses |
| Legacy-active features | **5** | assessment_sets banks, flat JSON fallbacks, Frequency constants, grandfather routing, CompatibilityScoring **rollback-only** (`legacy_v1`; not live Discover ranking) |
| Placeholders / designed-only UI | **8+** | Google/Apple stubs, MainAppScreen, notification toggles (local), privacy toggles (local), legal drafts, monetization docs |
| Unknown/unverified | **4+** | remote Firestore bank contents, live Console rules, multi-env, signing secrets |
| Question banks found (major artifacts) | **18+** | see inventory |
| Runtime question banks | **5** | sets + flats |
| Non-runtime question banks | **12+** | v3 + fixtures |
| Production CM v2 service calls | **0** | |
| Missing CM v2 connections | **7+** | services + Discover + assets + UI |
| Firebase security blockers | **3** | rules, storage rules, deletion wipe |
| Release blockers (gap severity=blocker) | **16** | gap register |
| Critical gaps | **6** | |
| High gaps | **12** | |
| Medium gaps | **5** | |
| Low gaps | **3** | |

---

## Recommended implementation order

1. **P2C-1 Packaging + Auth + Security foundation** — application IDs, rules/storage in repo, deletion wipe design, Crashlytics, auth gaps.  
2. **P2C-2 Assessment modernization** — bank decision, runtime wiring, TraitScoring adapter, progress/resume.  
3. **P2C-3 Matching** — prefs/values/hard UI + CM v2 Discover integration + registry namespace fix.  
4. **P2C-4 Messaging notifications / polish** — FCM, reverse-block, Discover filters.  
5. **P2C-5 Monetization** — only if v1 requires IAP.  
6. **P2C-6 Legacy cleanup** — remove orphans after cutover.

## First implementation phase after audit

**P2C-1 — Release identity, Auth completion, and Firebase security source-of-truth**  
(No CM v2 feature work until packaging/security/auth blockers are addressed, unless product explicitly chooses a disclosed legacy soft-launch — still requires G-001/G-003/G-004/G-023.)


---

## P2C-1A recalculation note

Prior total **29.5**. Category 12: 0 → 2.5 (`IMPLEMENTED_OFFLINE` 25% × 10). Category 13: 0 → 2.5 (`RUNTIME_WIRED_UNVERIFIED` 50% × 5). **New total 34.5**. Not inflated to “release ready”; Android Firebase config mismatch and undeployed rules remain blockers.
