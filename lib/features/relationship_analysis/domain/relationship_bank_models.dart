import 'relationship_dimensions.dart';

class RelationshipLocalizedText {
  const RelationshipLocalizedText({required this.en, required this.tr});
  final String en;
  final String tr;
  String resolve(String languageCode) =>
      languageCode.toLowerCase().startsWith('tr') ? tr : en;

  factory RelationshipLocalizedText.fromJson(Map<String, dynamic> json) =>
      RelationshipLocalizedText(
        en: (json['en'] ?? '').toString().trim(),
        tr: (json['tr'] ?? '').toString().trim(),
      );
}

class RelationshipAnswerOption {
  const RelationshipAnswerOption({
    required this.id,
    required this.text,
    required this.dimensionDeltas,
  });
  final String id;
  final RelationshipLocalizedText text;
  final Map<String, double> dimensionDeltas;

  factory RelationshipAnswerOption.fromJson(Map<String, dynamic> json) {
    final raw = json['dimension_deltas'];
    final deltas = <String, double>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is num) {
          deltas[e.key.toString()] = (e.value as num).toDouble();
        }
      }
    }
    return RelationshipAnswerOption(
      id: (json['id'] ?? '').toString().trim(),
      text: RelationshipLocalizedText.fromJson(
        Map<String, dynamic>.from(json['text'] as Map? ?? const {}),
      ),
      dimensionDeltas: Map.unmodifiable(deltas),
    );
  }
}

class RelationshipQuestion {
  const RelationshipQuestion({
    required this.id,
    required this.version,
    required this.context,
    required this.prompt,
    required this.options,
  });
  final String id;
  final String version;
  final String context;
  final RelationshipLocalizedText prompt;
  final List<RelationshipAnswerOption> options;

  factory RelationshipQuestion.fromJson(Map<String, dynamic> json) {
    final opts = <RelationshipAnswerOption>[];
    final raw = json['options'];
    if (raw is List) {
      for (final o in raw) {
        if (o is Map) {
          opts.add(
            RelationshipAnswerOption.fromJson(Map<String, dynamic>.from(o)),
          );
        }
      }
    }
    return RelationshipQuestion(
      id: (json['id'] ?? '').toString().trim(),
      version: (json['version'] ?? '').toString().trim(),
      context: (json['context'] ?? '').toString().trim(),
      prompt: RelationshipLocalizedText.fromJson(
        Map<String, dynamic>.from(json['prompt'] as Map? ?? const {}),
      ),
      options: List.unmodifiable(opts),
    );
  }
}

class RelationshipAnalysisBank {
  const RelationshipAnalysisBank({
    required this.schemaVersion,
    required this.bankVersion,
    required this.contentVersion,
    required this.scoringPolicyVersion,
    required this.dimensionRegistryVersion,
    required this.microScanSize,
    required this.canonicalDimensions,
    required this.items,
    required this.responseInstruction,
  });

  final String schemaVersion;
  final String bankVersion;
  final String contentVersion;
  final String scoringPolicyVersion;
  final String dimensionRegistryVersion;
  final int microScanSize;
  final List<String> canonicalDimensions;
  final List<RelationshipQuestion> items;
  final RelationshipLocalizedText responseInstruction;

  Map<String, RelationshipQuestion> get byId => {
        for (final q in items) q.id: q,
      };

  factory RelationshipAnalysisBank.fromJson(Map<String, dynamic> json) {
    final dims = <String>[];
    final dimsRaw = json['canonical_dimensions'];
    if (dimsRaw is List) {
      for (final d in dimsRaw) {
        dims.add(d.toString());
      }
    }
    final items = <RelationshipQuestion>[];
    final itemsRaw = json['items'];
    if (itemsRaw is List) {
      for (final i in itemsRaw) {
        if (i is Map) {
          items.add(
            RelationshipQuestion.fromJson(Map<String, dynamic>.from(i)),
          );
        }
      }
    }
    final instr = json['response_instruction'];
    return RelationshipAnalysisBank(
      schemaVersion: (json['schema_version'] ?? '').toString(),
      bankVersion: (json['bank_version'] ?? '').toString(),
      contentVersion: (json['content_version'] ?? '').toString(),
      scoringPolicyVersion: (json['scoring_policy_version'] ?? '').toString(),
      dimensionRegistryVersion:
          (json['dimension_registry_version'] ?? '').toString(),
      microScanSize: (json['micro_scan_size'] as num?)?.toInt() ??
          RelationshipAnalysisContract.microScanSize,
      canonicalDimensions: List.unmodifiable(dims),
      items: List.unmodifiable(items),
      responseInstruction: RelationshipLocalizedText.fromJson(
        Map<String, dynamic>.from(instr is Map ? instr : const {}),
      ),
    );
  }
}

class RelationshipBankValidationException implements Exception {
  RelationshipBankValidationException(this.message);
  final String message;
  @override
  String toString() => 'RelationshipBankValidationException: $message';
}

class RelationshipBankValidator {
  RelationshipBankValidator._();

  static void validate(RelationshipAnalysisBank bank) {
    final errors = <String>[];
    if (bank.schemaVersion != RelationshipAnalysisContract.schemaVersion) {
      errors.add('schema_version mismatch');
    }
    if (bank.items.length != RelationshipAnalysisContract.questionCount) {
      errors
          .add('expected ${RelationshipAnalysisContract.questionCount} items');
    }
    if (bank.microScanSize != RelationshipAnalysisContract.microScanSize) {
      errors.add('micro_scan_size must be 4');
    }
    final gotDims = bank.canonicalDimensions.map((e) => e.trim()).toSet();
    if (gotDims.length != RelationshipDimensionIds.all.length ||
        !gotDims.containsAll(RelationshipDimensionIds.allSet)) {
      errors.add(
        'canonical_dimensions mismatch: got=$gotDims '
        'expected=${RelationshipDimensionIds.allSet}',
      );
    }

    final ids = <String>{};
    final absWeight = {for (final d in RelationshipDimensionIds.all) d: 0.0};
    final touched = {
      for (final d in RelationshipDimensionIds.all) d: <String>{},
    };

    for (final q in bank.items) {
      if (q.id.isEmpty || !ids.add(q.id)) {
        errors.add('invalid/duplicate question id: ${q.id}');
      }
      if (q.prompt.en.isEmpty || q.prompt.tr.isEmpty) {
        errors.add('missing EN/TR prompt: ${q.id}');
      }
      if (q.options.length < 2 || q.options.length > 4) {
        errors.add('invalid option count: ${q.id}');
      }
      final optIds = <String>{};
      for (final o in q.options) {
        if (o.id.isEmpty || !optIds.add(o.id)) {
          errors.add('invalid option id on ${q.id}');
        }
        if (o.text.en.isEmpty || o.text.tr.isEmpty) {
          errors.add('missing EN/TR option: ${q.id}/${o.id}');
        }
        if (o.dimensionDeltas.isEmpty) {
          errors.add('empty vector: ${q.id}/${o.id}');
        }
        for (final e in o.dimensionDeltas.entries) {
          if (!RelationshipDimensionIds.allSet.contains(e.key)) {
            errors.add('unknown dim ${e.key} on ${q.id}/${o.id}');
          }
          if (!e.value.isFinite || e.value.abs() > 0.55) {
            errors.add('bad delta ${e.key} on ${q.id}/${o.id}');
          }
          absWeight[e.key] = absWeight[e.key]! + e.value.abs();
          touched[e.key]!.add(q.id);
        }
      }
    }

    for (final d in RelationshipDimensionIds.all) {
      if (touched[d]!.length <
          RelationshipAnalysisContract.minQuestionsPerDimension) {
        errors.add('low question coverage for $d');
      }
      if (absWeight[d]! <
          RelationshipAnalysisContract.minAbsWeightPerDimension) {
        errors.add('low abs weight for $d');
      }
    }

    if (errors.isNotEmpty) {
      throw RelationshipBankValidationException(errors.join('; '));
    }
  }
}
