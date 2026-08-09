# QMatch Persona Prototype Gap Register v1

**Phase:** P2C-3A-2
**Companion:** `qmatch_persona_canonical_audit_v1.md`

```text
PERSONA_RUNTIME_READY = false
canonical Persona distance scorer = IMPLEMENTED_OFFLINE_SHADOW
```

| Gap | Status | Notes |
|-----|--------|-------|
| Stable 18 Persona IDs | **CLOSED** | |
| Structural 20D target vectors | **CLOSED (provisional)** | v2 |
| Structural 20D dimension weights | **CLOSED (provisional)** | v2 |
| Anti-trait / min-evidence / tie ranks | **CLOSED (provisional)** | v2 |
| Shadow reliability policy | **RESOLVED_FOR_SHADOW_ONLY** | `q=E`; no fake R |
| Shadow evidence sufficiency | **RESOLVED_FOR_SHADOW_ONLY** | IQ 7/6/6/6; EQ 3; F 5 |
| Distance γ_A / γ_Ω conflict | **RESOLVED** | 0.10 / 0.05 |
| Offline shadow distance scorer | **IMPLEMENTED** | `CanonicalPersonaShadowScorer` |
| Prototype reachability (shadow) | **CLOSED** | all 18 reachable |
| Temperature T | **UNRESOLVED / unused** | not required for distance shadow |
| Top-2 thresholds | **UNRESOLVED / unused** | raw Δ_D only |
| Confidence | **NOT_COMPUTED** | |
| Production prototype blessing | **OPEN** | synthetic_validation_only |
| Live Firestore persona writer | **OPEN** | |
| Shadow → production reveal | **OPEN / NOT_STARTED** | |
| Matching/QRCF via Persona | **FORBIDDEN for now** | |

## Exact next work

Decide production reveal readiness only after affinity/T/Top-2/confidence policies
are resolved (or explicitly waived). Do not auto-reveal.
