import 'eq_canonical_dimensions.dart';

/// One selectable behavioral option with signed dimension evidence.
class EqCanonicalOption {
  const EqCanonicalOption({
    required this.optionId,
    required this.text,
    required this.dimensionDeltas,
  });

  final String optionId;
  final String text;

  /// Explicit evidence only. Missing key ⇒ no evidence for that dimension.
  final Map<String, double> dimensionDeltas;

  factory EqCanonicalOption.fromJson(Map<String, dynamic> json) {
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
    return EqCanonicalOption(
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

/// One canonical EQ scenario item.
class EqCanonicalItem {
  const EqCanonicalItem({
    required this.itemId,
    required this.primaryDimension,
    required this.secondaryDimensions,
    required this.prompt,
    required this.options,
    this.semanticPairId,
    this.reversePairId,
    this.sourcePilotQuestionId,
    this.responseFormat = 'scenario_mcq_behavioral_tendency',
  });

  final String itemId;
  final String primaryDimension;
  final List<String> secondaryDimensions;
  final String prompt;
  final List<EqCanonicalOption> options;
  final String? semanticPairId;
  final String? reversePairId;
  final String? sourcePilotQuestionId;
  final String responseFormat;

  EqCanonicalOption? optionById(String optionId) {
    for (final o in options) {
      if (o.optionId == optionId) return o;
    }
    return null;
  }

  factory EqCanonicalItem.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List)
        .map((e) =>
            EqCanonicalOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final secs = (json['secondary_dimensions'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    return EqCanonicalItem(
      itemId: json['item_id'] as String,
      primaryDimension: json['primary_dimension'] as String,
      secondaryDimensions: secs,
      prompt: json['prompt'] as String,
      options: opts,
      semanticPairId: json['semantic_pair_id'] as String?,
      reversePairId: json['reverse_pair_id'] as String?,
      sourcePilotQuestionId: json['source_pilot_question_id'] as String?,
      responseFormat: (json['response_format'] as String?) ??
          'scenario_mcq_behavioral_tendency',
    );
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'primary_dimension': primaryDimension,
        'secondary_dimensions': secondaryDimensions,
        'prompt': prompt,
        'options': [for (final o in options) o.toJson()],
        'semantic_pair_id': semanticPairId,
        'reverse_pair_id': reversePairId,
        if (sourcePilotQuestionId != null)
          'source_pilot_question_id': sourcePilotQuestionId,
        'response_format': responseFormat,
      };
}

/// Parsed runtime-candidate EQ bank document.
class EqCanonicalBankDocument {
  const EqCanonicalBankDocument({
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
  final List<EqCanonicalItem> items;
  final Map<String, dynamic> pairRegistry;
  final String? rviRuntimeGate;

  Map<String, EqCanonicalItem> get itemsById => {
        for (final i in items) i.itemId: i,
      };

  factory EqCanonicalBankDocument.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((e) =>
            EqCanonicalItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return EqCanonicalBankDocument(
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
class EqCanonicalResponse {
  const EqCanonicalResponse({
    required this.itemId,
    required this.optionId,
  });

  final String itemId;
  final String optionId;
}

/// Per-dimension primary vs total evidence inventory (bank structure).
class EqDimensionCoverage {
  const EqDimensionCoverage({
    required this.dimensionId,
    required this.primaryItemCount,
    required this.totalPossibleEvidenceCount,
  });

  final String dimensionId;
  final int primaryItemCount;

  /// Number of (item, option) pairs that carry an explicit delta for this dim.
  final int totalPossibleEvidenceCount;
}

/// Convenience: stable coverage over [EqCanonicalDimensions.all].
List<EqDimensionCoverage> eqBankDimensionCoverage(
  EqCanonicalBankDocument bank,
) {
  final primary = <String, int>{
    for (final d in EqCanonicalDimensions.all) d: 0,
  };
  final total = <String, int>{
    for (final d in EqCanonicalDimensions.all) d: 0,
  };
  for (final item in bank.items) {
    if (EqCanonicalDimensions.isCanonical(item.primaryDimension)) {
      primary[item.primaryDimension] =
          (primary[item.primaryDimension] ?? 0) + 1;
    }
    for (final o in item.options) {
      for (final d in o.dimensionDeltas.keys) {
        if (EqCanonicalDimensions.isCanonical(d)) {
          total[d] = (total[d] ?? 0) + 1;
        }
      }
    }
  }
  return [
    for (final d in EqCanonicalDimensions.all)
      EqDimensionCoverage(
        dimensionId: d,
        primaryItemCount: primary[d] ?? 0,
        totalPossibleEvidenceCount: total[d] ?? 0,
      ),
  ];
}
