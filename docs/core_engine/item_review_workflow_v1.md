# Item Review Workflow v1

**Status:** process contract (P2A-1)  
**Claim level:** operational review — **not** clinical validation  

## Statuses

| Status | Meaning |
|---|---|
| `draft` | Authoring in progress |
| `internal_review` | Product/construct first pass |
| `construct_review` | Dimension mapping & deltas reviewed |
| `language_review` | TR + EN equivalence reviewed |
| `security_review` | Exposure/leakage/PII/IQ key security |
| `pilot` | Eligible for limited pilot forms |
| `calibrated` | Pilot metrics recorded; still provisional norms |
| `active` | Eligible for production banks (future) |
| `suspended` | Temporarily removed |
| `retired` | Permanently removed from active pools |

## Required reviewers

1. Product/construct reviewer  
2. Turkish-language reviewer  
3. English-language reviewer  
4. IQ answer/solution reviewer (IQ only)  
5. Psychological-measurement reviewer (non-clinical)  
6. Privacy/security reviewer  

## Evidence required before `active`

- Stable `question_id` + schema_version  
- Canonical `primary_dimension`  
- TR/EN prompts (and options)  
- IQ: keyed answer + solution_method + distractor logic  
- EQ/Frequency: bounded deltas; no correct-answer fields; SDR risk rated  
- Separator items: valid `separator_targets` only  
- Dual review sign-off recorded in authoring notes/metadata  
- No unresolved MANUAL_REVIEW audit blockers  

## Explicit non-claims

This workflow does **not** certify clinical, diagnostic, or legally definitive psychological instruments.
