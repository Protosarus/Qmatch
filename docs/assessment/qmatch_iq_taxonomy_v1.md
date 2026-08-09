# QMatch IQ Taxonomy v1 (Frozen)

**Phase:** P2C-2A-0  
**Top-level dimensions:** exactly four.  
**Retired:** `numerical` (never silently remapped).

---

## Top-level dimensions

### 1. `logical_reasoning`

| | |
|--|--|
| **Measures** | Rule-based inference, constraint satisfaction, validity of conclusions from stated premises |
| **Does not measure** | Vocabulary size, memorized formulas, spatial visualization skill, creativity |
| **Allowed families** | Conditional inference, set relations, constraint puzzles, syllogistic validity, necessity/sufficiency |
| **Prohibited families** | Trivia, historical facts, “trick” wording unrelated to logic, school calculus as gate |
| **Language dependence** | Medium (Turkish clarity required) |
| **Accessibility** | Avoid dense nested clauses; offer short premises |
| **Bias risks** | Legal/medical jargon; culture-specific institutions |
| **20D profile** | Direct IQ module contributor |

### 2. `pattern_reasoning`

| | |
|--|--|
| **Measures** | Induction of generative rules from sequences/matrices/analogies |
| **Does not measure** | Pure arithmetic fluency as end goal, verbal semantics, 3D rotation |
| **Allowed families** | Numeric sequences, figurative series, matrix completion, rule induction, structural analogy |
| **Prohibited families** | Factorial/combinatorics requiring specialized schooling without scaffolding; opaque “find the next” with multiple equally valid rules |
| **Language dependence** | Low–medium |
| **Accessibility** | Prefer explicit option values; avoid unreadable ASCII art when SVG/asset unavailable |
| **Bias risks** | Advanced math notation familiarity |
| **20D profile** | Direct IQ module contributor |

### 3. `verbal_reasoning`

| | |
|--|--|
| **Measures** | Semantic relations, precise definitions, classification, short-passage inference in Turkish |
| **Does not measure** | Foreign-language proficiency, literary taste, IQ-as-vocabulary-only |
| **Allowed families** | Semantic analogy, definition precision, verbal classification, passage inference, antonym/synonym logic |
| **Prohibited families** | Obscure archaic words as traps; region-only slang; political/religious judgment stems |
| **Language dependence** | High |
| **Accessibility** | Common contemporary Turkish; define rare terms if unavoidable |
| **Bias risks** | Education register, regional idioms |
| **20D profile** | Direct IQ module contributor |

### 4. `spatial_reasoning`

| | |
|--|--|
| **Measures** | Mental rotation, folding/assembly, viewpoint, path, shape composition |
| **Does not measure** | Artistic skill, memory of landmarks, arithmetic |
| **Allowed families** | Mental rotation, folding/assembly, viewpoint projection, path navigation, shape composition |
| **Prohibited families** | Items requiring unsupported external images; ambiguous 2D sketches with multiple viewpoints |
| **Language dependence** | Low |
| **Accessibility** | Text-only spatial items must be unambiguous; image items need bundled assets + alt text policy (future) |
| **Bias risks** | Assumptions about left/right writing systems; color-only coding |
| **20D profile** | Direct IQ module contributor |

---

## Subskill registry (primary)

Every item chooses **exactly one** primary subskill from its dimension:

| Dimension | Subskills |
|-----------|-----------|
| `logical_reasoning` | `conditional_inference`, `set_relations`, `constraint_satisfaction`, `syllogistic_validity`, `causal_necessity` |
| `pattern_reasoning` | `numeric_sequence`, `figurative_series`, `matrix_completion`, `rule_induction`, `analogy_structure` |
| `verbal_reasoning` | `semantic_analogy`, `definition_precision`, `verbal_classification`, `passage_inference`, `antonym_synonym_logic` |
| `spatial_reasoning` | `mental_rotation`, `folding_assembly`, `viewpoint_projection`, `path_navigation`, `shape_composition` |

Secondary tags may exist later but **must not** affect canonical scoring unless a future contract says so.

IDs are stable ASCII `snake_case`.
