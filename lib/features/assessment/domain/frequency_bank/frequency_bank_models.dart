import 'frequency_canonical_dimensions.dart';

/// One selectable behavioral option with signed Frequency dimension evidence.
class FrequencyCanonicalOption {
  const FrequencyCanonicalOption({
    required this.optionId,
    required this.text,
    required this.dimensionDeltas,
  });

  final String optionId;
  final String text;

  /// Explicit evidence only. Missing key ⇒ no evidence for that dimension.
  final Map<String, double> dimensionDeltas;

  factory FrequencyCanonicalOption.fromJson(Map<String, dynamic> json) {
    final raw = json['dimension_deltas'];
    if (raw is! Map) {
      throw FormatException('option.dimension_deltas must be a map');
    }
    final deltas = <String, double>{};
    for (final e in raw.entries) {
      final key = e.key.toString();
      final val = e.value;
      if (val is! num) {
        throw FormatException('delta for $key must be numeric');
      }
      deltas[key] = val.toDouble();
    }
    return FrequencyCanonicalOption(
      optionId: json['option_id'] as String,
      text: json['text'] as String,
      dimensionDeltas: deltas,
    );
  }

  Map<String, dynamic> toJson() => {
        'option_id': optionId,
        'text': text,
        'dimension_deltas': dimensionDeltas,
      };
}

/// One canonical Frequency item.
class FrequencyCanonicalItem {
  const FrequencyCanonicalItem({
    required this.itemId,
    required this.itemRole,
    required this.primaryDimension,
    required this.secondaryDimensions,
    required this.prompt,
    required this.options,
    this.semanticPairId,
    this.reversePairId,
    this.behavioralIsomorphGroupId,
    this.relationshipType,
    this.reverseScored,
    this.sourcePilotQuestionId,
    this.responseFormat = 'scenario_mcq_behavioral_tendency',
    this.separatorType,
    this.separatorDimensions = const [],
    this.separatorPersonaTargets = const [],
    this.traitScoring = true,
    this.qualityType,
    this.expectedProtocolOptionId,
    this.rviRuntimeGate = false,
  });

  final String itemId;

  /// One of: core | behavioral_equivalence | separator | response_quality
  final String itemRole;
  final String? primaryDimension;
  final List<String> secondaryDimensions;
  final String prompt;
  final List<FrequencyCanonicalOption> options;
  final String? semanticPairId;
  final String? reversePairId;
  final String? behavioralIsomorphGroupId;
  final String? relationshipType;
  final bool? reverseScored;
  final String? sourcePilotQuestionId;
  final String responseFormat;

  /// Separator contract (R1A): dimension_boundary; persona targets may be empty.
  final String? separatorType;
  final List<String> separatorDimensions;
  final List<String> separatorPersonaTargets;

  /// Quality-only items must set [traitScoring] false with empty deltas.
  final bool traitScoring;
  final String? qualityType;
  final String? expectedProtocolOptionId;
  final bool rviRuntimeGate;

  FrequencyCanonicalOption? optionById(String optionId) {
    for (final o in options) {
      if (o.optionId == optionId) return o;
    }
    return null;
  }

  factory FrequencyCanonicalItem.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List)
        .map((e) => FrequencyCanonicalOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    final secs = (json['secondary_dimensions'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final sepDims = (json['separator_dimensions'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final sepPersona = (json['separator_persona_targets'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    return FrequencyCanonicalItem(
      itemId: json['item_id'] as String,
      itemRole: json['item_role'] as String,
      primaryDimension: json['primary_dimension'] as String?,
      secondaryDimensions: secs,
      prompt: json['prompt'] as String,
      options: opts,
      semanticPairId: json['semantic_pair_id'] as String?,
      reversePairId: json['reverse_pair_id'] as String?,
      behavioralIsomorphGroupId:
          json['behavioral_isomorph_group_id'] as String?,
      relationshipType: json['relationship_type'] as String?,
      reverseScored: json['reverse_scored'] as bool?,
      sourcePilotQuestionId: json['source_pilot_question_id'] as String?,
      responseFormat: (json['response_format'] as String?) ??
          'scenario_mcq_behavioral_tendency',
      separatorType: json['separator_type'] as String?,
      separatorDimensions: sepDims,
      separatorPersonaTargets: sepPersona,
      traitScoring: (json['trait_scoring'] as bool?) ?? true,
      qualityType: json['quality_type'] as String?,
      expectedProtocolOptionId: json['expected_protocol_option_id'] as String?,
      rviRuntimeGate: (json['rvi_runtime_gate'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_role': itemRole,
        'primary_dimension': primaryDimension,
        'secondary_dimensions': secondaryDimensions,
        'prompt': prompt,
        'options': [for (final o in options) o.toJson()],
        'semantic_pair_id': semanticPairId,
        'reverse_pair_id': reversePairId,
        'behavioral_isomorph_group_id': behavioralIsomorphGroupId,
        'relationship_type': relationshipType,
        'reverse_scored': reverseScored,
        if (sourcePilotQuestionId != null)
          'source_pilot_question_id': sourcePilotQuestionId,
        'response_format': responseFormat,
        'separator_type': separatorType,
        'separator_dimensions': separatorDimensions,
        'separator_persona_targets': separatorPersonaTargets,
        'trait_scoring': traitScoring,
        'quality_type': qualityType,
        'expected_protocol_option_id': expectedProtocolOptionId,
        'rvi_runtime_gate': rviRuntimeGate,
      };
}

/// Parsed Frequency bank document (runtime candidate or math fixture).
class FrequencyCanonicalBankDocument {
  const FrequencyCanonicalBankDocument({
    required this.schemaVersion,
    required this.bankVersion,
    required this.contentVersion,
    required this.locale,
    required this.status,
    required this.calibrationStatus,
    required this.reliabilityStatus,
    required this.scoringPolicyVersion,
    required this.items,
    required this.pairRegistry,
    this.rviRuntimeGate,
  });

  final String schemaVersion;
  final String bankVersion;
  final String contentVersion;
  final String locale;
  final String status;
  final String calibrationStatus;
  final String reliabilityStatus;
  final String scoringPolicyVersion;
  final List<FrequencyCanonicalItem> items;
  final Map<String, dynamic> pairRegistry;
  final String? rviRuntimeGate;

  Map<String, FrequencyCanonicalItem> get itemsById => {
        for (final i in items) i.itemId: i,
      };

  factory FrequencyCanonicalBankDocument.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((e) => FrequencyCanonicalItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    return FrequencyCanonicalBankDocument(
      schemaVersion: json['schema_version'] as String,
      bankVersion: json['bank_version'] as String,
      contentVersion: json['content_version'] as String,
      locale: json['locale'] as String,
      status: json['status'] as String,
      calibrationStatus: json['calibration_status'] as String,
      reliabilityStatus: json['reliability_status'] as String,
      scoringPolicyVersion: json['scoring_policy_version'] as String,
      items: items,
      pairRegistry: Map<String, dynamic>.from(
        (json['pair_registry'] as Map?) ?? const {},
      ),
      rviRuntimeGate: json['rvi_runtime_gate'] as String?,
    );
  }
}

/// One selected response for offline scoring.
class FrequencyCanonicalResponse {
  const FrequencyCanonicalResponse({
    required this.itemId,
    required this.optionId,
  });

  final String itemId;
  final String optionId;
}

/// Per-dimension primary vs total evidence inventory (bank structure).
class FrequencyDimensionCoverage {
  const FrequencyDimensionCoverage({
    required this.dimensionId,
    required this.corePrimaryItemCount,
    required this.relatedItemCount,
    required this.totalPossibleEvidenceCount,
  });

  final String dimensionId;
  final int corePrimaryItemCount;
  final int relatedItemCount;
  final int totalPossibleEvidenceCount;
}

List<FrequencyDimensionCoverage> frequencyBankDimensionCoverage(
  FrequencyCanonicalBankDocument bank,
) {
  final core = <String, int>{
    for (final d in FrequencyCanonicalDimensions.all) d: 0,
  };
  final related = <String, int>{
    for (final d in FrequencyCanonicalDimensions.all) d: 0,
  };
  final total = <String, int>{
    for (final d in FrequencyCanonicalDimensions.all) d: 0,
  };

  for (final item in bank.items) {
    final primary = item.primaryDimension;
    if (primary != null && FrequencyCanonicalDimensions.isCanonical(primary)) {
      if (item.itemRole == 'core') {
        core[primary] = core[primary]! + 1;
      } else if (item.itemRole == 'behavioral_equivalence') {
        related[primary] = related[primary]! + 1;
      }
    }
    if (!item.traitScoring) continue;
    for (final o in item.options) {
      for (final d in o.dimensionDeltas.keys) {
        if (FrequencyCanonicalDimensions.isCanonical(d)) {
          total[d] = total[d]! + 1;
        }
      }
    }
  }

  return [
    for (final d in FrequencyCanonicalDimensions.all)
      FrequencyDimensionCoverage(
        dimensionId: d,
        corePrimaryItemCount: core[d]!,
        relatedItemCount: related[d]!,
        totalPossibleEvidenceCount: total[d]!,
      ),
  ];
}
