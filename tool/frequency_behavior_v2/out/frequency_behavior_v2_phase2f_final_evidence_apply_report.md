# Frequency V2 Phase 2F — Finalize evidence priors into dormant pool

Status: **applied to dormant selectable pool only**. V2 remains `runtime_selectable=false`.
All values are **uncalibrated reviewer priors**, not validated coefficients,
truth/lie probabilities, personality probabilities, or empirical discrimination.

Human authority: `docs/qmatch_frequency_v2_phase2e_final_human_evidence_review.txt`

Content fingerprint SHA-256 (text/weights; unchanged): `6acb86e18f1567890ea1c112fa54c0ffcdde2d9cda11f1c61e2ca0164d170518`

## Counts

- Archive questions: **426**
- Archive options: **1704**
- DROP questions: **21**
- DROP options: **84**
- Dormant selectable questions: **405**
- Dormant selectable options: **1620**
- Reviewed evidence questions: **405**
- Reviewed evidence options: **1620**
- Pending/null DROP options: **84**
- rewrite_pending: **0**
- selectable dual-primary: **0**

## Combined evidence dataset

- From Phase 2E revised proposal: **396** questions (unspecified scores unchanged)
- From Phase 2E rewritten-10 proposal, retained: **9** questions
- Excluded: `frequency_v2_q0409`
- Human override field-change count: **33**
- Unchanged retained rewritten evidence: `q0213`, `q0377`, `q0410`

Final file: `tool/frequency_behavior_v2/out/frequency_behavior_v2_phase2f_final_evidence_prior.json`

## Human overrides applied

All six listed questions received only the explicit `0.50 -> 0.75` lifts on
`social_desirability`, `obviousness`, and `self_presentation_risk`:

- `frequency_v2_q0020_b` (3)
- `frequency_v2_q0026_a`, `frequency_v2_q0026_b` (6)
- `frequency_v2_q0030_a`, `frequency_v2_q0030_b` (6)
- `frequency_v2_q0035_b`, `frequency_v2_q0035_c` (6)
- `frequency_v2_q0317_a`, `frequency_v2_q0317_b` (6)
- `frequency_v2_q0393_a`, `frequency_v2_q0393_b` (6)

Total: **33** field changes. No unspecified score was modified.

## q0409 archive DROP

- Question and option IDs preserved
- Text, weights, and provenance preserved
- `selector_eligible=false`, `drop_from_selectable=true`
- evidence_meta remains pending/null (no numeric values)
- Not deleted

## Pool evidence_meta

Selectable (1620 options):

- `version`: `frequency_evidence_prior_v1`
- `calibration_status`: `uncalibrated`
- `review_status`: `reviewed`
- all six numeric fields present and on the 0.00/0.25/0.50/0.75/1.00 grid

DROP (84 options, including q0409): pending/null

## Evidence-field value distributions (1620 selectable options)

### social_desirability

- 0.00: 13
- 0.25: 18
- 0.50: 1469
- 0.75: 117
- 1.00: 3

### obviousness

- 0.00: 0
- 0.25: 330
- 0.50: 1227
- 0.75: 60
- 1.00: 3

### behavioral_plausibility

- 0.00: 0
- 0.25: 225
- 0.50: 99
- 0.75: 1153
- 1.00: 143

### self_presentation_risk

- 0.00: 2
- 0.25: 327
- 0.50: 1226
- 0.75: 63
- 1.00: 2

### diagnostic_value

- 0.00: 105
- 0.25: 584
- 0.50: 533
- 0.75: 304
- 1.00: 94

### ambiguity

- 0.00: 0
- 0.25: 1055
- 0.50: 434
- 0.75: 131
- 1.00: 0

## Same-value siblings (all four options identical on a field)

- `social_desirability`: 281 questions
- `obviousness`: 229 questions
- `behavioral_plausibility`: 258 questions
- `self_presentation_risk`: 229 questions
- `diagnostic_value`: 24 questions
- `ambiguity`: 108 questions

## Mean evidence fields by primary dimension

- `contact_need` (n=80 options): social_desirability=0.487, obviousness=0.478, behavioral_plausibility=0.719, self_presentation_risk=0.475, diagnostic_value=0.447, ambiguity=0.316
- `closeness_pace` (n=156 options): social_desirability=0.519, obviousness=0.431, behavioral_plausibility=0.665, self_presentation_risk=0.442, diagnostic_value=0.462, ambiguity=0.381
- `initiative` (n=116 options): social_desirability=0.511, obviousness=0.399, behavioral_plausibility=0.629, self_presentation_risk=0.399, diagnostic_value=0.470, ambiguity=0.414
- `autonomy` (n=228 options): social_desirability=0.502, obviousness=0.482, behavioral_plausibility=0.725, self_presentation_risk=0.477, diagnostic_value=0.439, ambiguity=0.342
- `reassurance_need` (n=104 options): social_desirability=0.476, obviousness=0.476, behavioral_plausibility=0.724, self_presentation_risk=0.483, diagnostic_value=0.399, ambiguity=0.315
- `uncertainty_tolerance` (n=108 options): social_desirability=0.514, obviousness=0.481, behavioral_plausibility=0.704, self_presentation_risk=0.481, diagnostic_value=0.493, ambiguity=0.343
- `disclosure_pace` (n=140 options): social_desirability=0.539, obviousness=0.479, behavioral_plausibility=0.695, self_presentation_risk=0.484, diagnostic_value=0.489, ambiguity=0.373
- `boundary_firmness` (n=208 options): social_desirability=0.517, obviousness=0.434, behavioral_plausibility=0.647, self_presentation_risk=0.435, diagnostic_value=0.439, ambiguity=0.383
- `repair_style` (n=100 options): social_desirability=0.520, obviousness=0.450, behavioral_plausibility=0.667, self_presentation_risk=0.450, diagnostic_value=0.440, ambiguity=0.333
- `social_energy` (n=92 options): social_desirability=0.511, obviousness=0.435, behavioral_plausibility=0.660, self_presentation_risk=0.427, diagnostic_value=0.432, ambiguity=0.361
- `structure_preference` (n=144 options): social_desirability=0.521, obviousness=0.491, behavioral_plausibility=0.729, self_presentation_risk=0.484, diagnostic_value=0.512, ambiguity=0.345
- `adaptability` (n=144 options): social_desirability=0.514, obviousness=0.470, behavioral_plausibility=0.684, self_presentation_risk=0.469, diagnostic_value=0.418, ambiguity=0.349

## Mean social_desirability by primary weight sign

- positive primary weight: 0.520 (n=560)
- negative primary weight: 0.512 (n=358)

## Mean diagnostic_value for |primary weight| = 1 vs 2

- abs(primary weight)=1: 0.549 (n=417)
- abs(primary weight)=2: 0.636 (n=501)

## Suspicious systematic bias (reported only; not auto-corrected)

- social_desirability is piled at 0.50 (1469/1620). This is a residual uniformity from earlier priors plus limited human sibling-relative lifts; not auto-corrected.
- obviousness is piled at 0.50 (1227/1620). Report only.
- self_presentation_risk is piled at 0.50 (1226/1620). Report only.
- Mean diagnostic_value is higher for |primary weight|=2 (0.636) than |primary weight|=1 (0.549). Magnitude was not a scoring rule; residual association is reported, not fixed.

High social desirability does not mean false. Weight sign is not health or maturity.
`discrimination_power` was not authored.

## Safety

- `runtime_selectable` remains false
- V1 hashes unchanged
- locale/live routing unchanged
- no Firebase / C2 / Discover / Persona / matching changes
- no 12D→6D adapter
- no activation

FREQUENCY V2 PHASE 2F FINAL EVIDENCE PRIORS APPLIED TO 405 DORMANT SELECTABLE QUESTIONS — V2 STILL DORMANT
