import 'iq_canonical_dimensions.dart';

/// Maintainable primary subskill registry for canonical IQ items.
///
/// Every future item must declare exactly one [primary] subskill belonging to
/// its top-level dimension. Secondary tags must not alter scoring unless a
/// later contract explicitly allows it.
class IqSubskillRegistry {
  IqSubskillRegistry._();

  static const Map<String, Set<String>> byDimension = {
    IqCanonicalDimensions.logicalReasoning: {
      'conditional_inference',
      'set_relations',
      'constraint_satisfaction',
      'syllogistic_validity',
      'causal_necessity',
    },
    IqCanonicalDimensions.patternReasoning: {
      'numeric_sequence',
      'figurative_series',
      'matrix_completion',
      'rule_induction',
      'analogy_structure',
    },
    IqCanonicalDimensions.verbalReasoning: {
      'semantic_analogy',
      'definition_precision',
      'verbal_classification',
      'passage_inference',
      'antonym_synonym_logic',
    },
    IqCanonicalDimensions.spatialReasoning: {
      'mental_rotation',
      'folding_assembly',
      'viewpoint_projection',
      'path_navigation',
      'shape_composition',
    },
  };

  static Set<String> get all {
    final out = <String>{};
    for (final values in byDimension.values) {
      out.addAll(values);
    }
    return out;
  }

  static bool isRegistered({
    required String dimension,
    required String subskill,
  }) {
    final allowed = byDimension[dimension];
    if (allowed == null) return false;
    return allowed.contains(subskill);
  }
}
