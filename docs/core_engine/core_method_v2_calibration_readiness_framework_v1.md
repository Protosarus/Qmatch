# Core Method v2 Calibration Readiness Framework v1

Phase: **P2B-6**. Framework only — **no data collection implemented**.

**Synthetic data cannot establish predictive validity, fairness, calibration,
or production readiness.** Real calibration requires ethically collected,
consented, purpose-limited data.

## Layers

### 1. Engineering readiness

| field | content |
|-------|---------|
| Required inputs | Frozen pure-Dart services; schemas; deterministic harness; invariant suite; smoke/full synthetic runs |
| Current status | In progress via P2B-6 offline evaluation |
| Completed evidence | P2B-1…P2B-5 contracts, services, validators, focused tests; experiment config |
| Missing evidence | Populated robustness JSON under `tool/core_method_v2_out/robustness_v1/`; contiguous scenario report (≥100); coverage matrix updates to `covered` |
| Blocker | Incomplete offline run/report population (not science) |
| Next validation | Deterministic smoke → scenario suite → full population; byte-identical re-runs |

### 2. Measurement readiness

| field | content |
|-------|---------|
| Required inputs | Item quality evidence; construct validity plans; reliability; evidence-strength calibration; expert content review of value matrices |
| Current status | **Not ready** |
| Completed evidence | Pilot bank reviews (IQ/EQ/Frequency) and engineering freeze manifests — provisional only |
| Missing evidence | Consented measurement studies; cultural adaptation evidence; psychometric calibration of scales/thresholds |
| Blocker | No ethically scoped measurement dataset; parameters remain uncalibrated |
| Next validation | Purpose-limited measurement design (separate phase); expert review of registries/matrices |

### 3. Product-research readiness

| field | content |
|-------|---------|
| Required inputs | User comprehension of explanations; preference UX studies; value of hard gates vs soft diagnostics; ranking presentation research |
| Current status | **Not ready** |
| Completed evidence | Explanation localization contract; provisional signal codes |
| Missing evidence | Consented UX/research studies; explanation usefulness metrics not based on addiction/engagement alone |
| Blocker | No product-research protocol or consented cohort |
| Next validation | Offline research design for explanation clarity and expectation alignment |

### 4. Outcome-calibration readiness

| field | content |
|-------|---------|
| Required inputs | Ethically collected, consented, purpose-limited **pair outcome labels** (see below); train/eval splits; documented anti-gaming policy |
| Current status | **Not ready** / conditional at best conceptually |
| Completed evidence | This framework; uncalibrated parameter inventory |
| Missing evidence | Any consented outcome dataset; calibration vs holdout; fairness analyses |
| Blocker | Real-user data forbidden in this phase; no collection implemented |
| Next validation | Controlled offline calibration-data **design** phase only after engineering freeze discussion |

### 5. Production-ranking readiness

| field | content |
|-------|---------|
| Required inputs | Engineering + measurement + product-research + outcome-calibration PASS; production approval; safety/fairness review; no forbidden optimizations |
| Current status | **`not_evaluated` / not ready** |
| Completed evidence | Explicit production prohibitions in configs and contracts |
| Missing evidence | All calibration layers; Discover/CompatibilityScoring integration review; ops monitoring |
| Blocker | Synthetic-only evidence; uncalibrated parameters; no outcome labels |
| Next validation | Do **not** wire production ranking until prior layers clear |

## Allowed future outcome labels (examples)

Purpose-limited labels that may be considered later (with consent):

- mutual conversation continuation
- mutually accepted contact
- repeated voluntary interaction
- user-reported conversational fit
- user-reported expectation satisfaction
- longer-term mutual satisfaction where consented

## Labels that must not stand alone as “compatibility truth”

Do **not** define success as:

- message frequency alone
- swipe acceptance alone
- retention alone
- engagement optimization as the sole target

## Optimization risks

Calibrating or ranking against naive engagement can amplify:

- addiction / compulsive use
- superficial engagement
- popular-profile exposure bias
- demographic imbalance
- self-fulfilling ranking feedback loops

Mitigation direction (future phases): purpose limitation, consented labels
aligned with mutual satisfaction, fairness audits, human review gates, and
explicit refusal to optimize addiction proxies.

## Phase boundary

P2B-6 documents readiness and synthetic engineering behavior only.
**Do not implement data collection, telemetry hooks, or production ranking
in this phase.**
