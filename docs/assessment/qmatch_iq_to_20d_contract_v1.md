# QMatch IQ → 20D Contract v1

**Phase:** P2C-2A-4 (boundary document only)
**Adapter status:** NOT_STARTED — do not wire yet

---

## Mapping

Canonical IQ scoring contributes **exactly** these four dimensions to the
future 20-dimensional QMatch profile:

| Canonical IQ dimension | Score range | Calibration |
|------------------------|-------------|-------------|
| logical_reasoning | [0, 1] provisionalScore | uncalibrated |
| pattern_reasoning | [0, 1] provisionalScore | uncalibrated |
| verbal_reasoning | [0, 1] provisionalScore | uncalibrated |
| spatial_reasoning | [0, 1] provisionalScore | uncalibrated |

No other IQ-derived dimensions. No collapsed overall IQ injected into the 20D
vector.

---

## Quality / reliability metadata

Currently **unavailable**:

- reliabilityEstimate = null
- empiricalUncertainty = null

Structural flags (complete session, quota, bank validity) are **not**
psychometric confidence.

A future calibration phase may add reliability / SE / norms only after adequate
pilot evidence.

---

## Prohibitions

- Do not interpret provisionalScore as population IQ.
- Do not invent percentiles for Discover ranking from this phase’s outputs.
- Do not silently rescale into TraitScoring without an explicit adapter version.

---

## Later requirements before production 20D use

1. Empirical calibration plan satisfied (see calibration plan doc).
2. Explicit adapter version + schema.
3. Live session wiring with option-ID answers.
4. Firestore persistence rules for 4D (or 20D) fields reviewed.
