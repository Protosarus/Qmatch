import '../frequency_behavior_v2/frequency_behavior_v2_contract.dart';
import 'persona_dimension_profile.dart';

/// Native Persona V2 contract: IQ 4D + EQ 10D + Frequency V2 12D.
///
/// Does not map Frequency V2 12D onto legacy Frequency 6D or write
/// `canonical_v1` Frequency slots.
class PersonaV2Contract {
  PersonaV2Contract._();

  static const String scoringVersion =
      'persona_26d_iq_eq_frequency_v2_distance_v1';
  static const String policyVersion = 'persona_v2_authoritative_v1';
  static const String configVersion = 'persona_v2_scoring_config_v1';
  static const String prototypeVersion = 'persona_profiles_v2_26d.0';
  static const String dimensionRegistryVersion = 'persona_v2_26d_registry_v1';
  static const String source = 'persona_v2_assign_v1';

  static const double iqGroupWeight = 0.15;
  static const double eqGroupWeight = 0.30;
  static const double frequencyV2GroupWeight = 0.55;
  static const double levelDistanceWeight = 0.65;
  static const double shapeDistanceWeight = 0.35;
  static const double numericalEpsilon = 1e-12;

  static const List<String> iq = PersonaDimensionIds.iq;
  static const List<String> eq = PersonaDimensionIds.eq;
  static const List<String> frequencyV2 =
      FrequencyBehaviorV2Contract.canonicalDimensions;

  static const List<String> all = [...iq, ...eq, ...frequencyV2];

  static const Set<String> allSet = {...iq, ...eq, ...frequencyV2};

  static const String iqGroup = 'iq';
  static const String eqGroup = 'eq';
  static const String frequencyV2Group = 'frequency_v2';

  static const List<String> groups = [iqGroup, eqGroup, frequencyV2Group];

  static List<String> dimsOf(String group) {
    switch (group) {
      case iqGroup:
        return iq;
      case eqGroup:
        return eq;
      case frequencyV2Group:
        return frequencyV2;
      default:
        throw ArgumentError('Unknown Persona V2 group: $group');
    }
  }

  static String groupOf(String dimensionId) {
    if (iq.contains(dimensionId)) return iqGroup;
    if (eq.contains(dimensionId)) return eqGroup;
    if (frequencyV2.contains(dimensionId)) return frequencyV2Group;
    throw ArgumentError('Unknown Persona V2 dimension: $dimensionId');
  }

  static double groupWeight(String group) {
    switch (group) {
      case iqGroup:
        return iqGroupWeight;
      case eqGroup:
        return eqGroupWeight;
      case frequencyV2Group:
        return frequencyV2GroupWeight;
      default:
        throw ArgumentError('Unknown Persona V2 group: $group');
    }
  }

  /// Affine unit map for signed Frequency V2 behavior.
  /// Does not translate twelve Frequency V2 dimensions into legacy six.
  static double unitIntervalFromSignedBehavior(double signed) {
    return ((signed + 1.0) / 2.0).clamp(0.0, 1.0);
  }
}
