# QMatch Phase 7G.2 — Trusted finalize deployment record

Date: 2026-09-03
Mode: production backend deployment only
Firebase project: `qmatch-53d62`

This record documents the operational state after deploying `finalizeEq` and
`finalizeFrequency`. It is not a Flutter release, rules change, Discover
change, Frequency V2 activation, or user-data migration.

---

## Recovery source

| Item | Value |
|------|--------|
| Repository | Protosarus/Qmatch |
| Commit deployed from | `1b97c651f929f4495f3b2c0571c58b7586b775d7` |
| Branch | `main` |
| `HEAD` / `origin/main` at deploy | identical to the commit above |
| Working tree at deploy | clean |

---

## Source registration (committed, not edited)

| Export | Region | Source | Deployed this phase |
|--------|--------|--------|---------------------|
| `finalizeIq` | `europe-west1` | `admin_finalize_iq_v1` | No — already in production |
| `finalizeEq` | `europe-west1` | `admin_finalize_eq_v1` | Yes |
| `finalizeFrequency` | `europe-west1` | `admin_finalize_frequency_v1` | Yes |
| `finalizeFrequencyV2` | `europe-west1` (local export only) | `admin_finalize_frequency_v2_v1` | **No** |

`finalizeFrequencyV2` remains a local export only. `runtime_selectable` remains `false`.

---

## Pre-deploy production inventory

Observed with `firebase functions:list --project qmatch-53d62` before any deploy.

| Function | Pre-deploy production status |
|----------|------------------------------|
| `finalizeIq` | Present — v2 callable, `europe-west1`, nodejs22 |
| `finalizeEq` | Absent |
| `finalizeFrequency` | Absent |
| `finalizeFrequencyV2` | Absent |

---

## Backend test gate

Run in `functions/` against commit `1b97c651f929f4495f3b2c0571c58b7586b775d7`.

| Suite | Result |
|-------|--------|
| `finalize_eq_v1.test.js` | 24 passing |
| `finalize_frequency_v1.test.js` | 33 passing |
| `assessment_finalize_validation_v1.test.js` | 64 passing |
| `assessment_verification_flow_v1.test.js` | 5 passing |
| `finalize_iq_v1.test.js` | 19 passing |
| `finalize_frequency_v2_v1.test.js` | 25 passing |
| Full Functions suite | **625 passing**, 0 failing |

---

## Deploy — `finalizeEq`

| Item | Value |
|------|--------|
| Command scope | `firebase deploy --only functions:finalizeEq --project qmatch-53d62` |
| Result | Successful create — `functions[finalizeEq(europe-west1)]` |
| Region | `europe-west1` |
| Production status | Present — v2 callable, nodejs22 |
| Source | `admin_finalize_eq_v1` |
| Unauthenticated smoke test | `POST https://europe-west1-qmatch-53d62.cloudfunctions.net/finalizeEq` body `{"data":{}}` |
| Smoke result | HTTP **401** — `UNAUTHENTICATED` / "Authentication required to finalize EQ." |

No authenticated session. No successful verified response. No user-document write from this smoke test.

---

## Deploy — `finalizeFrequency`

Performed only after `finalizeEq` deploy + smoke test succeeded.

| Item | Value |
|------|--------|
| Command scope | `firebase deploy --only functions:finalizeFrequency --project qmatch-53d62` |
| Result | Successful create — `functions[finalizeFrequency(europe-west1)]` |
| Region | `europe-west1` |
| Production status | Present — v2 callable, nodejs22 |
| Source | `admin_finalize_frequency_v1` |
| Unauthenticated smoke test | `POST https://europe-west1-qmatch-53d62.cloudfunctions.net/finalizeFrequency` body `{"data":{}}` |
| Smoke result | HTTP **401** — `UNAUTHENTICATED` / "Authentication required to finalize Frequency." |

No authenticated session. No Firestore completion write. No scoring. No migration.

---

## Post-deploy inventory delta

Compared to the pre-deploy list, this phase added only:

- `finalizeEq` (`europe-west1`)
- `finalizeFrequency` (`europe-west1`)

Confirmed unchanged / not deployed:

| Item | Status |
|------|--------|
| `finalizeIq` | Still present, `europe-west1` |
| `finalizeFrequencyV2` | Still absent |
| Discover functions | Unchanged |
| Firestore rules | Unchanged / not deployed |
| Storage rules | Unchanged / not deployed |
| Hosting | Not deployed |
| Other Cloud Functions | Unchanged |

---

## Explicit non-actions

| Action | Executed |
|--------|----------|
| Production user documents mutated manually | **NO** |
| Grandfather dry-run (`assessment_trust_grandfather_dry_run_v1.py --execute-dry-run`) | **NO** |
| Grandfather apply (`assessment_trust_grandfather_execute_v1.py`) | **NO** |
| Authenticated invoke of `finalizeEq` | **NO** |
| Authenticated invoke of `finalizeFrequency` | **NO** |
| Discover eligibility change | **NO** |
| `firestore.rules` change or deploy | **NO** |
| Flutter change / release | **NO** |
| Scoring change | **NO** |
| Frequency V2 deploy / activation | **NO** |
| `runtime_selectable` flipped | **NO** — remains `false` |

Production data migration executed: **NO**
