# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed phase | **HOTFIX — Canonical assessment completion persistence + safe retry** |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

---

## HOTFIX (IQ completion)

```text
ROOT CAUSE (proven):
  IQ/EQ/Frequency write users/{uid}/profiles/canonical_v1
  but Firestore rules lacked owner allow → permission-denied
  → misleading iqCanonicalSessionError snack

REPO FIXES (this commit):
  - firestore.rules: owner read/create/update on profiles/canonical_v1
    (delete still denied)
  - IQ local lifecycle: in_progress
      → completed_pending_persistence (active pointer retained)
      → completed + remote_finalized (pointer cleared only after remote OK)
  - Same-screen + app-restart resume of pending finalization (no re-answer)
  - Conservative unique stuck-session recovery for pre-hotfix completed blobs
  - Distinct l10n for session vs answer vs persist errors

PRODUCTION FIRESTORE RULES DEPLOYMENT = STILL REQUIRED
  Do not claim live Firebase rules are fixed until deploy runs.
  Manual IQ completion retest against production Firebase = BLOCKED until deploy.

Persona = UNCHANGED (no scoring/prototype/simulation edits)
```

---

## Status

```text
P2C-3A-1 = COMPLETE
P2C-3A-2 = COMPLETE
P2C-3A-3 = COMPLETE (offline)

canonical measured profile = 20 / 20
canonical_profile_ready = true

canonical 18 Persona prototypes = PROVISIONAL / STRUCTURALLY_READY / synthetic_validation_only
canonical Persona distance scorer = IMPLEMENTED_OFFLINE_SHADOW
large-scale shadow stress = COMPLETE (offline)
  seed = 20260809
  overall_n = 100000
  aggregate = docs/persona/reports/persona_shadow_stress_v1_aggregate.json

scoring_version = persona_20d_shadow_distance_v1
quality_policy = persona_shadow_evidence_only_v1
group_weights = 0.15 / 0.30 / 0.55
alpha = 0.65 (provisional)
gamma_A = 0.10
gamma_Omega = 0.05

Persona input reliability policy = RESOLVED_FOR_SHADOW_ONLY (q_j = E_j)
Persona evidence sufficiency policy = RESOLVED_FOR_SHADOW_ONLY
distance coefficient conflict = RESOLVED

temperature = UNRESOLVED / TEMPERATURE_NOT_REQUIRED_FOR_DISTANCE_ONLY_REVEAL_V1
Top-2 thresholds = UNRESOLVED / NOT_REQUIRED_FOR_RAW_MARGIN
confidence = NOT_COMPUTED / CONFIDENCE_NOT_REQUIRED_FOR_DISTANCE_ONLY_REVEAL_V1
explainability reason_code = BLOCKED_PERSONA_REASON_CODE_POLICY
DISTANCE_ONLY_REVEAL_READY_FOR_PRODUCT_REVIEW = false

production Persona reveal = NOT_STARTED / BLOCKED
live Persona persistence = NOT_STARTED
PERSONA_RUNTIME_READY = false

Matching/QRCF = NOT_STARTED
Quantum = NOT_STARTED
RVI runtime = NOT_ACTIVE
Psychometric calibration = NOT_STARTED
```

---

## Canonical Assessment Architecture

| Module | Live | Notes |
|--------|------|-------|
| **IQ** | Canonical live | completion hotfix pending **rules deploy** |
| **EQ** | Canonical live | shares `profiles/canonical_v1` |
| **Frequency** | Canonical live | shares `profiles/canonical_v1`; no Persona |
| **Persona** | Offline shadow distance + stress validated | no reveal / no Firestore |

---

## GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-2A-8R2 live Frequency + Frequency→20D | `025e573c8ad3b84fb91070c4568e3b3994dc1fbd` |
| P2C-3A-1 Persona prototype contract audit | `7c7ccc4bffd816ac783b92f4f164f1225b7b3e40` |
| Continuity tip before Persona shadow | `d212d8414bfef55164cdc136b60e851206636377` |
| P2C-3A-2 Persona shadow distance engine | `dd3ebdcd99c7cc2a2d6f7781060f35a426bfcf7e` |
| P2C-3A-3 Persona large-scale shadow stress | `014825b8b342a0dfdcb28c2ef2ab1f6e8c4d2738` |
| HOTFIX completion persistence (this) | _(fill after commit)_ |

---

## Next Exact Phase

1. **Deploy** updated `firestore.rules` to Firebase project `qmatch-53d62`
   (explicit approval required; not auto-deployed).
2. Manual retest: IQ 25/25 → Reasoning Profile → EQ.
3. Then product/explainability Persona review or Matching — Persona unchanged.

---

## Continuity Rule

Update this file at the end of every implementation phase.
