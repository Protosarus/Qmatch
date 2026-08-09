# QMatch Persona Prototype Gap Register v1

**Phase:** P2C-3A-1  
**Companion:** `qmatch_persona_canonical_audit_v1.md`

```text
PERSONA_RUNTIME_READY = false
```

| Gap | Status | Notes |
|-----|--------|-------|
| Stable 18 Persona IDs | **CLOSED** | Catalog / v1 / v2 agree |
| Structural 20D target vectors | **CLOSED (provisional)** | `persona_profiles_v2_20d.json` |
| Structural 20D dimension weights | **CLOSED (provisional)** | same |
| Anti-trait rules present | **CLOSED (provisional)** | same; do not invent new θ/h |
| Persona-specific min-evidence fields | **CLOSED (provisional)** | same |
| Tie-break ranks 1–18 | **CLOSED** | unique in v2 |
| Production prototype blessing | **OPEN** | `synthetic_validation_only` |
| Retire v1 as live input | **OPEN** | v1 still in pubspec; classify LEGACY |
| Register v2 in pubspec when live | **OPEN** | offline filesystem only today |
| Approved R_j uncalibrated policy | **OPEN / BLOCKED** | `BLOCKED_PERSONA_RELIABILITY_POLICY` |
| Approved E_j / n_j^min Persona handoff | **OPEN / BLOCKED** | `BLOCKED_PERSONA_MINIMUM_EVIDENCE_POLICY` |
| Canonical temperature T | **OPEN / BLOCKED** | `BLOCKED_PERSONA_TEMPERATURE_CONFIG` |
| Canonical Top-2 thresholds | **OPEN / BLOCKED** | `BLOCKED_PERSONA_TOP2_THRESHOLD_POLICY` |
| Total-distance γ_A / γ_Ω reconciliation | **OPEN / CONFLICTED** | Core Engine vs repo 0.12/0.18 |
| Confidence policy | **OPEN** | `NOT_READY_FOR_PRODUCTION` |
| Live Firestore `assessments/persona` writer | **OPEN** | contract exists; no writer |
| Shadow-mode integration | **OPEN** | status enum only |
| Post-Frequency Persona wiring | **OPEN** | intentionally not started |
| ARB TR/EN Persona strings | **OPEN** | inline catalog / JSON only |
| Matching/QRCF using Persona | **FORBIDDEN for now** | Persona ≠ matching key |

## Exact next work (not auto-started)

1. Resolve reliability + evidence Persona input policies without inventing R_j.  
2. Resolve T + Top-2 via simulation/pilot.  
3. Reconcile total-distance coefficients.  
4. Shadow-mode only after policies resolve.  
5. Production reveal is a later phase.
