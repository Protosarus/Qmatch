# QMatch IQ Calibration Plan v1

**Phase:** P2C-2A-4 (roadmap only)
**Current scoring:** `iq_4d_uncalibrated_accuracy_v1`
**Calibration status:** NOT_STARTED

---

## Why calibration is blocked today

The 340-item bank is desk-reviewed candidate content without empirical item
response data. Inventing difficulty, discrimination, reliability, or norms
would fabricate psychometrics.

---

## Evidence needed before changing scoring policy

1. **Sufficient pilot sample** — adequate completed 25-item sessions across
   intended locales/populations (sample size justified by analysis plan, not
   slogan).
2. **Item response distributions** — option selection frequencies per item.
3. **Item difficulty estimates** — empirical p-values / IRT difficulty when
   model assumptions hold.
4. **Item discrimination** — correlation / IRT a-parameter where supported.
5. **DIF / fairness checks** — where subgroup Ns permit.
6. **Internal consistency / reliability** — dimension-level where justified.
7. **Retest analysis** — when feasible.
8. **Dimension validation** — confirm 4D structure vs collapsed alternatives.
9. **Language / cultural review** — especially for Turkish verbal items.
10. **Norming** — only if product explicitly requires population-relative
    interpretation (not assumed).

---

## What must not happen before evidence

- Publishing standardized IQ or percentiles
- Fabricated confidence/reliability numbers from structural flags alone
- Difficulty-weighted scoring without item stats
- Silent policy version changes without migration notes

---

## Future policy versions (examples, not implemented)

- `iq_4d_empirical_difficulty_v1` — only after difficulty estimates exist
- `iq_4d_irt_v1` — only after IRT fit is demonstrated
- Norm-referenced variants — only after intentional norming study

Each new policy requires a new `scoring_policy_version` string and validators.
