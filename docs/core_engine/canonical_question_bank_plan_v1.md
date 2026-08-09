# Canonical Question Bank Plan v1

**Status:** authoring plan (P2A-1)  
**Priority:** quality over retaining weak legacy volume  

## Session vs bank

| Module | Session size | Target reviewed bank | Notes |
|---|---:|---:|---|
| IQ | 25 | 150–240 | Domain-balanced; secure exposure classes |
| EQ | 30 | 180–300 | Families + reverse/isomorph coverage |
| Frequency | 50 | 240–420 | ≥6 primary/dim in session; deep bank per dim |
| Adaptive separators | 0–8 | ≥8–12 per difficult pair | Information-value pool |

## Per-module plan

### IQ

- Anchor pool: ≥40 reviewed anchors (≈10/domain)  
- Exposure: `secure_iq` rotation; overlap policy per blueprint  
- Locale equivalence mandatory before `active`  
- Promotion: requires solution review + two-locale language review + pilot stats  
- Deprecation: disputed key, leakage, or bias flags  

### EQ

- Anchor pool: ≥60  
- Every canonical EQ dim: ≥18 primary-capable items in bank before claiming session coverage stability  
- No correct-answer fields ever  
- Retirement: moralized / socially obvious items (majority of current bank)  

### Frequency

- Anchor pool: ≥48 (≈8/dim)  
- Map legacy camelCase → canonical snake_case on rewrite  
- Separate `disclosure_pace` from EQ `emotional_openness`  
- Retire mystical / type-assignment wording if found  

## Review stages

`draft → internal_review → construct_review → language_review → security_review → pilot → calibrated → active`  
(`suspended` / `retired` as needed)

## Calibration-data requirements

- Pilot N provisional; no clinical claims  
- Item stats: difficulty/discrimination hypotheses for IQ; option selection distributions for EQ/Frequency  
- Separator items need near-tie simulation utility checks offline  

## Do not

- Keep hundreds of weak items only because they exist  
- Promote items lacking canonical dimension metadata  
- Ship EQ items with `correctAnswer`  
