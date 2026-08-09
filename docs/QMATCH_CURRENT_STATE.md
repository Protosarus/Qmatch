# QMatch Current State

**Authority:** This file + the repository code are the source of truth for
project continuity across ChatGPT/Cursor sessions.

---

## Repository Checkpoint

| Field | Value |
|-------|-------|
| Branch | `main` |
| Last completed phase | **HOTFIX 2 — Canonical profile reconciliation + safe EQ/Frequency finalization** |
| Continuity document | `docs/QMATCH_CURRENT_STATE.md` |
| Checkpoint date | 2026-08-09 |

---

## HOTFIX 2

```text
ROOT CAUSE:
  Historical/pre-rules users can have assessments/iq + iq_completed
  without canonical_v1 IQ4. Progress routed to EQ. EqTo20d correctly
  refused incomplete IQ preservation. EQ local complete cleared active
  → retry "Session is not in progress".

REPO FIXES:
  - CanonicalAssessmentProfileReconciler: reconstruct IQ4/EQ10 from
    versioned assessments/{iq|eq} only (never legacy scalars)
  - AssessmentProgressService.resolveForUid: reconcile IQ4 / 14D before
    EQ / Frequency destinations
  - IQ finalization order: assessments/iq → profile IQ4 → markIqCompleted
  - EQ + Frequency: completed_pending_persistence + remote_finalized
    (mirror IQ hotfix); retry without re-answer; stuck recovery
  - Adapter IQ4/EQ10 preconditions UNCHANGED (still correct)

CANONICAL PIPELINE INVARIANT:
  IQ ready ⇔ canonical_v1 exact IQ4
  EQ ready ⇔ exact IQ4+EQ10 (14/20)
  Frequency ready ⇔ exact 20/20 + canonical_profile_ready

Firestore rules for canonical_v1: already deployed (HOTFIX 1)
No new rules deploy required for HOTFIX 2.

Persona = UNCHANGED
```

---

## Status

```text
P2C-3A-1 = COMPLETE
P2C-3A-2 = COMPLETE
P2C-3A-3 = COMPLETE (offline)

HOTFIX 1 (IQ completion persistence + rules) = COMPLETE (repo + rules deployed)
HOTFIX 2 (profile reconcile + EQ/Freq finalize) = COMPLETE (repo)

canonical measured profile = 20 / 20 (when Frequency finalized)
PERSONA_RUNTIME_READY = false
Matching/QRCF = NOT_STARTED
```

---

## Canonical Assessment Architecture

| Module | Live | Notes |
|--------|------|-------|
| **IQ** | Canonical live | pending-finalization + profile-before-progress |
| **EQ** | Canonical live | pending-finalization + IQ4 reconcile gate |
| **Frequency** | Canonical live | pending-finalization + 14D reconcile gate |
| **Persona** | Offline shadow | untouched |

---

## GitHub Checkpoints

| Phase | Commit |
|-------|--------|
| P2C-3A-3 Persona large-scale shadow stress | `014825b8b342a0dfdcb28c2ef2ab1f6e8c4d2738` |
| HOTFIX 1 completion persistence | `5ff7e9d36a86ba39db5f891bc270f225a0cb9a7a` |
| HOTFIX 2 (this) | _(fill after commit)_ |

---

## Next Exact Phase

1. Manual retest: stuck EQ user — open app → EQ should recover pending / repair IQ4 → 14/20 → Frequency.
2. Fresh path: IQ → Reasoning Profile → EQ → Frequency → 20/20.
3. Persona / Matching only when product prioritizes — do not auto-start.

---

## Continuity Rule

Update this file at the end of every implementation phase.
