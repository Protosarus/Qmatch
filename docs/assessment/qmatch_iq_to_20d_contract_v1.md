# QMatch IQ → 20D Contract v1

**Phase:** P2C-2A-6
**Adapter status:** **IMPLEMENTED** — see `docs/profile/qmatch_iq_to_20d_runtime_adapter_v1.md`

---

## Mapping

Canonical IQ scoring contributes **exactly** these four dimensions to the
20-dimensional QMatch profile:

| Canonical IQ dimension | Score range | Calibration |
|------------------------|-------------|-------------|
| logical_reasoning | [0, 1] provisionalScore | uncalibrated |
| pattern_reasoning | [0, 1] provisionalScore | uncalibrated |
| verbal_reasoning | [0, 1] provisionalScore | uncalibrated |
| spatial_reasoning | [0, 1] provisionalScore | uncalibrated |

No other IQ-derived dimensions. No collapsed overall IQ injected into the 20D
vector.

Runtime adapter: `IqTo20dRuntimeAdapter` → `users/{uid}/profiles/canonical_v1`
with `canonical_profile_ready=false` until EQ + Frequency are also measured.

---

## Quality / reliability metadata

Currently **unavailable**:

- reliabilityEstimate = null / `reliability_status=not_calibrated`
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
- Do not fabricate EQ/Frequency placeholders as 0 / 0.5 / 50.

---

## Later requirements before production 20D use

1. Empirical calibration plan satisfied (see calibration plan doc).
2. EQ + Frequency canonical migrations into the same profile schema.
3. Persona / matching consumers gated on `canonical_profile_ready=true`.
