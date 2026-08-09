# QMatch Persona Collision Matrix v1

**Phase:** P2C-3A-3
**Source:** `docs/persona/reports/persona_shadow_stress_v1_aggregate.json`
**Seed:** 20260809 · overall n = 100000
**Scorer:** `persona_20d_shadow_distance_v1`

Collision = ordered Top-2 pair `(primary, secondary)` under shadow distance.
Telemetry only — no invented collision pass/fail band.

```text
shadow_only = true
simulation_diagnostic_only = true
PERSONA_RUNTIME_READY = false
```

---

## Top collision pairs (overall)

| Rank | primary | secondary | count | share |
|------|---------|-----------|------:|------:|
| 1 | `uygulayici` | `kararli` | 3990 | 0.0399 |
| 2 | `bagimsiz` | `analist` | 3711 | 0.03711 |
| 3 | `sezgisel` | `empat` | 3556 | 0.03556 |
| 4 | `cesur` | `donusturucu` | 3307 | 0.03307 |
| 5 | `analist` | `bagimsiz` | 2984 | 0.02984 |
| 6 | `sezgisel` | `vizyoner` | 2927 | 0.02927 |
| 7 | `koruyucu` | `sifaci` | 2912 | 0.02912 |
| 8 | `yaratici` | `vizyoner` | 2644 | 0.02644 |
| 9 | `bagimsiz` | `uygulayici` | 2425 | 0.02425 |
| 10 | `empat` | `sezgisel` | 2331 | 0.02331 |
| 11 | `bagimsiz` | `sezgisel` | 2267 | 0.02267 |
| 12 | `sezgisel` | `bagimsiz` | 2050 | 0.0205 |
| 13 | `vizyoner` | `sezgisel` | 2036 | 0.02036 |
| 14 | `lider` | `uygulayici` | 1874 | 0.01874 |
| 15 | `vizyoner` | `cesur` | 1675 | 0.01675 |

`self_secondary_count` overall = **0** (primary never equals secondary).

Full 18×18 matrices per family live in the aggregate JSON
(`families.*.collision_matrix`, `overall.collision_matrix`).

---

## Closest / farthest prototype pairs

Pairwise separation is a **simulation diagnostic** between prototype vectors
(not a user-sample Δ_D).

### Closest (top 5)

| persona_a | persona_b | separation | top dims |
|-----------|-----------|------------|----------|
| `uygulayici` | `kararli` | 0.0036374844919254204 | social_energy, communication_pace, depth_preference, spontaneity, emotion_regulation |
| `muhafiz` | `kararli` | 0.006136689313568438 | conflict_approach, boundary_setting, communication_pace, disclosure_pace, logical_reasoning |
| `yargic` | `stratejist` | 0.0064893510122286625 | communication_pace, pattern_reasoning, logical_reasoning, conflict_approach, emotion_regulation |
| `empat` | `sezgisel` | 0.008451274601999886 | pattern_reasoning, communication_pace, empathy, social_energy, social_awareness |
| `koruyucu` | `sifaci` | 0.00850040567789088 | boundary_setting, assertiveness, conflict_approach, stability, repair_orientation |

### Farthest (top 5)

| persona_a | persona_b | separation | top dims |
|-----------|-----------|------------|----------|
| `muhafiz` | `yaratici` | 0.16730488970694318 | spontaneity, stability, boundary_setting, disclosure_pace, emotional_openness |
| `kararli` | `yaratici` | 0.1560972214450621 | spontaneity, stability, emotional_openness, emotion_regulation, disclosure_pace |
| `muhafiz` | `donusturucu` | 0.1485766191342803 | stability, spontaneity, boundary_setting, disclosure_pace, emotional_openness |
| `yaratici` | `stratejist` | 0.14505475370388027 | spontaneity, stability, emotional_openness, disclosure_pace, logical_reasoning |
| `iletisimci` | `bagimsiz` | 0.14265935867633006 | social_energy, communication_pace, disclosure_pace, boundary_setting, emotional_openness |

---

## Notes

* Closest pair `uygulayici`/`kararli` also leads overall Top-2 collision count —
  consistent with tight prototype separation, not a scoring bug report.
* Midpoint Top-2 is `sezgisel`/`bagimsiz` (see center-magnet doc); that pair
  also appears high in the collision table (rows 11–12).
* No prototype numeric repair was applied in P2C-3A-3.
