import 'iq_bank_contract.dart';
import 'iq_canonical_dimensions.dart';
import 'iq_item_model.dart';
import 'iq_subskill_registry.dart';

enum IqValidationSeverity { error, warning }

class IqValidationFinding {
  const IqValidationFinding({
    required this.code,
    required this.message,
    required this.severity,
    this.itemId,
    this.fieldPath,
  });

  final String code;
  final String message;
  final IqValidationSeverity severity;
  final String? itemId;
  final String? fieldPath;

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'severity': severity.name,
        if (itemId != null) 'item_id': itemId,
        if (fieldPath != null) 'field_path': fieldPath,
      };
}

class IqValidationReport {
  IqValidationReport({
    required this.findings,
    required this.dimensionCounts,
    required this.subskillCounts,
    required this.difficultyCounts,
    required this.answerPositionCounts,
    required this.itemCount,
  });

  final List<IqValidationFinding> findings;
  final Map<String, int> dimensionCounts;
  final Map<String, int> subskillCounts;
  final Map<String, int> difficultyCounts;
  final Map<String, int> answerPositionCounts;
  final int itemCount;

  bool get hasErrors =>
      findings.any((f) => f.severity == IqValidationSeverity.error);

  List<IqValidationFinding> get errors =>
      findings.where((f) => f.severity == IqValidationSeverity.error).toList();

  List<IqValidationFinding> get warnings => findings
      .where((f) => f.severity == IqValidationSeverity.warning)
      .toList();

  Map<String, dynamic> toJson() => {
        'item_count': itemCount,
        'error_count': errors.length,
        'warning_count': warnings.length,
        'has_errors': hasErrors,
        'dimension_counts': dimensionCounts,
        'subskill_counts': subskillCounts,
        'difficulty_counts': difficultyCounts,
        'answer_position_counts': answerPositionCounts,
        'difficulty_is_calibrated': IqBankContract.treatsDifficultyAsCalibrated,
        'findings': findings.map((f) => f.toJson()).toList(),
      };

  String toHumanReadable() {
    final buf = StringBuffer()
      ..writeln('IQ item validation report')
      ..writeln(
          'items=$itemCount errors=${errors.length} warnings=${warnings.length}')
      ..writeln('dimensions=$dimensionCounts')
      ..writeln('difficulty=$difficultyCounts (editorial, not calibrated)')
      ..writeln('answer_positions=$answerPositionCounts');
    for (final f in findings) {
      buf.writeln(
        '[${f.severity.name}] ${f.code}'
        '${f.itemId != null ? ' item=${f.itemId}' : ''}'
        '${f.fieldPath != null ? ' path=${f.fieldPath}' : ''}: ${f.message}',
      );
    }
    return buf.toString();
  }
}

/// Offline deterministic validator for canonical IQ items / banks.
class IqItemValidator {
  IqItemValidator._();

  static final RegExp _idPattern = RegExp(r'^iq_[a-z0-9_]+$');
  static final RegExp _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');
  static final RegExp _html = RegExp(r'<[^>]+>');
  static final List<RegExp> _bannedOptionPatterns = [
    RegExp(r'all of the above', caseSensitive: false),
    RegExp(r'none of the above', caseSensitive: false),
    RegExp(r'\bhepsi\b', caseSensitive: false),
    RegExp(r'hiçbiri|hicbiri', caseSensitive: false),
  ];

  static const Set<String> _forbiddenQuantumOrFakeKeys = {
    'quantum_score',
    'quantum_amplitude',
    'irt_a',
    'irt_b',
    'discrimination',
    'estimated_discrimination',
    'user_answers',
    'correct_index',
  };

  static String normalizePrompt(String prompt) {
    var s = prompt.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll('"', '');
    s = s.replaceAll("'", '');
    return s;
  }

  static IqValidationReport validateItems(
    List<Map<String, dynamic>> rawItems, {
    bool enforceBankTargets = false,
    bool treatCandidateAsRuntime = false,
  }) {
    final findings = <IqValidationFinding>[];
    final dimensionCounts = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final subskillCounts = <String, int>{};
    final difficultyCounts = <String, int>{
      for (final d in IqBankContract.difficultyBands) d: 0,
    };
    final answerPositionCounts = <String, int>{'A': 0, 'B': 0, 'C': 0, 'D': 0};
    final seenIds = <String>{};
    final seenPrompts = <String>{};
    final nearDupBuckets = <String, List<String>>{};

    void error(
      String code,
      String message, {
      String? itemId,
      String? fieldPath,
    }) {
      findings.add(
        IqValidationFinding(
          code: code,
          message: message,
          severity: IqValidationSeverity.error,
          itemId: itemId,
          fieldPath: fieldPath,
        ),
      );
    }

    void warn(
      String code,
      String message, {
      String? itemId,
      String? fieldPath,
    }) {
      findings.add(
        IqValidationFinding(
          code: code,
          message: message,
          severity: IqValidationSeverity.warning,
          itemId: itemId,
          fieldPath: fieldPath,
        ),
      );
    }

    for (var i = 0; i < rawItems.length; i++) {
      final raw = rawItems[i];
      final itemId = raw['id']?.toString() ?? 'index_$i';

      for (final key in _forbiddenQuantumOrFakeKeys) {
        if (raw.containsKey(key)) {
          error(
            'forbidden_field',
            'Forbidden field "$key" is not allowed in canonical IQ schema',
            itemId: itemId,
            fieldPath: key,
          );
        }
      }

      const required = [
        'id',
        'schema_version',
        'bank_version',
        'locale',
        'dimension',
        'subskill',
        'prompt',
        'options',
        'correct_option_id',
        'rationale',
        'difficulty_band',
        'estimated_time_seconds',
        'language_dependency',
        'cognitive_load',
        'answer_order_policy',
        'status',
        'source',
        'review_state',
        'tags',
      ];
      for (final field in required) {
        if (!raw.containsKey(field) || raw[field] == null) {
          error(
            'missing_required_field',
            'Missing required field "$field"',
            itemId: itemId,
            fieldPath: field,
          );
        }
      }

      IqCanonicalItem? item;
      try {
        item = IqCanonicalItem.fromJson(raw);
      } catch (e) {
        error(
          'parse_failure',
          'Failed to parse item: $e',
          itemId: itemId,
        );
        continue;
      }

      if (item.schemaVersion != IqBankContract.schemaVersion) {
        error(
          'invalid_schema_version',
          'Expected ${IqBankContract.schemaVersion}',
          itemId: item.id,
          fieldPath: 'schema_version',
        );
      }
      if (!_idPattern.hasMatch(item.id)) {
        error(
          'invalid_id',
          'Item id must match ^iq_[a-z0-9_]+\$',
          itemId: item.id,
          fieldPath: 'id',
        );
      }
      if (!seenIds.add(item.id)) {
        error(
          'duplicate_item_id',
          'Duplicate item id',
          itemId: item.id,
          fieldPath: 'id',
        );
      }
      if (!IqBankContract.locales.contains(item.locale)) {
        error(
          'invalid_locale',
          'Unsupported locale "${item.locale}"',
          itemId: item.id,
          fieldPath: 'locale',
        );
      }
      if (IqCanonicalDimensions.isRetired(item.dimension)) {
        error(
          'retired_dimension',
          'Retired dimension "${item.dimension}" is forbidden',
          itemId: item.id,
          fieldPath: 'dimension',
        );
      } else if (!IqCanonicalDimensions.isCanonical(item.dimension)) {
        error(
          'unsupported_dimension',
          'Unsupported dimension "${item.dimension}"',
          itemId: item.id,
          fieldPath: 'dimension',
        );
      } else {
        dimensionCounts[item.dimension] =
            (dimensionCounts[item.dimension] ?? 0) + 1;
      }

      if (!IqSubskillRegistry.isRegistered(
        dimension: item.dimension,
        subskill: item.subskill,
      )) {
        error(
          'unregistered_subskill',
          'Subskill "${item.subskill}" is not registered for ${item.dimension}',
          itemId: item.id,
          fieldPath: 'subskill',
        );
      } else {
        subskillCounts[item.subskill] =
            (subskillCounts[item.subskill] ?? 0) + 1;
      }

      if (!IqBankContract.difficultyBands.contains(item.difficultyBand)) {
        error(
          'invalid_difficulty',
          'Invalid difficulty_band "${item.difficultyBand}"',
          itemId: item.id,
          fieldPath: 'difficulty_band',
        );
      } else {
        difficultyCounts[item.difficultyBand] =
            (difficultyCounts[item.difficultyBand] ?? 0) + 1;
      }

      if (item.estimatedTimeSeconds < IqBankContract.minEstimatedTimeSeconds ||
          item.estimatedTimeSeconds > IqBankContract.maxEstimatedTimeSeconds) {
        error(
          'estimated_time_out_of_bounds',
          'estimated_time_seconds out of bounds',
          itemId: item.id,
          fieldPath: 'estimated_time_seconds',
        );
      }

      if (item.rationale.trim().isEmpty || item.rationale.trim().length < 12) {
        error(
          'empty_rationale',
          'Rationale is required and must be substantive',
          itemId: item.id,
          fieldPath: 'rationale',
        );
      }

      if (_controlChars.hasMatch(item.prompt) ||
          _controlChars.hasMatch(item.rationale)) {
        error(
          'control_characters',
          'Control characters are not allowed',
          itemId: item.id,
        );
      }
      if (_html.hasMatch(item.prompt) || _html.hasMatch(item.rationale)) {
        error(
          'raw_html',
          'Raw HTML is not allowed',
          itemId: item.id,
        );
      }

      if (item.options.length != 4) {
        error(
          'invalid_option_count',
          'Exactly 4 options required',
          itemId: item.id,
          fieldPath: 'options',
        );
      }

      final optionIds = <String>{};
      final optionTexts = <String>{};
      for (final opt in item.options) {
        if (!const {'A', 'B', 'C', 'D'}.contains(opt.id)) {
          error(
            'invalid_option_id',
            'Option id must be A/B/C/D',
            itemId: item.id,
            fieldPath: 'options',
          );
        }
        if (!optionIds.add(opt.id)) {
          error(
            'duplicate_option_id',
            'Duplicate option id ${opt.id}',
            itemId: item.id,
            fieldPath: 'options',
          );
        }
        final normOpt = normalizePrompt(opt.text);
        if (normOpt.isEmpty) {
          error(
            'empty_option_text',
            'Option text empty',
            itemId: item.id,
            fieldPath: 'options.${opt.id}',
          );
        }
        if (!optionTexts.add(normOpt)) {
          error(
            'repeated_option_text',
            'Option texts collide after normalization',
            itemId: item.id,
            fieldPath: 'options',
          );
        }
        for (final ban in _bannedOptionPatterns) {
          if (ban.hasMatch(opt.text)) {
            error(
              'banned_answer_pattern',
              'Banned option pattern: ${ban.pattern}',
              itemId: item.id,
              fieldPath: 'options.${opt.id}',
            );
          }
        }
        if (opt.text.length > 280) {
          warn(
            'option_length_anomaly',
            'Option text unusually long (${opt.text.length})',
            itemId: item.id,
            fieldPath: 'options.${opt.id}',
          );
        }
      }

      final matching =
          item.options.where((o) => o.id == item!.correctOptionId).toList();
      if (matching.isEmpty) {
        error(
          'missing_correct_option',
          'correct_option_id does not match any option',
          itemId: item.id,
          fieldPath: 'correct_option_id',
        );
      } else if (matching.length != 1) {
        error(
          'multiple_correct_options',
          'Multiple options match correct_option_id',
          itemId: item.id,
          fieldPath: 'correct_option_id',
        );
      } else {
        answerPositionCounts[item.correctOptionId] =
            (answerPositionCounts[item.correctOptionId] ?? 0) + 1;
      }

      // Multiple-correct representation via list/index is impossible by model;
      // still reject legacy keys if present.
      if (raw.containsKey('correct_option_ids') ||
          raw['correct_option_id'] is List) {
        error(
          'multiple_correct_representation',
          'Multiple-correct representations are forbidden',
          itemId: item.id,
          fieldPath: 'correct_option_id',
        );
      }

      final normPrompt = normalizePrompt(item.prompt);
      if (normPrompt.isEmpty) {
        error(
          'empty_prompt',
          'Prompt empty after normalization',
          itemId: item.id,
          fieldPath: 'prompt',
        );
      } else if (!seenPrompts.add(normPrompt)) {
        error(
          'duplicate_normalized_prompt',
          'Duplicate prompt after normalization',
          itemId: item.id,
          fieldPath: 'prompt',
        );
      }

      final prefix =
          normPrompt.length <= 48 ? normPrompt : normPrompt.substring(0, 48);
      nearDupBuckets.putIfAbsent(prefix, () => <String>[]).add(item.id);

      if (item.prompt.contains(item.correctOptionId) &&
          RegExp('doğru cevap|correct answer|cevap\\s*:\\s*${item.correctOptionId}',
                  caseSensitive: false)
              .hasMatch(item.prompt)) {
        error(
          'answer_leakage',
          'Prompt appears to reveal the correct option',
          itemId: item.id,
          fieldPath: 'prompt',
        );
      }

      if (treatCandidateAsRuntime &&
          !IqBankContract.isRuntimeEligibleStatus(item.status)) {
        error(
          'candidate_not_runtime_eligible',
          'Status "${item.status}" is not runtime_eligible',
          itemId: item.id,
          fieldPath: 'status',
        );
      } else if (!IqBankContract.isRuntimeEligibleStatus(item.status) &&
          item.status == 'draft') {
        // informational only for bank drafts
      }
    }

    for (final entry in nearDupBuckets.entries) {
      if (entry.value.length > 1) {
        warn(
          'near_duplicate_prompt_family',
          'Possible near-duplicate family (${entry.value.join(', ')})',
          fieldPath: 'prompt',
        );
      }
    }

    if (enforceBankTargets) {
      if (rawItems.length != IqBankContract.targetUniqueItems) {
        error(
          'bank_count_mismatch',
          'Expected ${IqBankContract.targetUniqueItems} items, found ${rawItems.length}',
        );
      }
      for (final d in IqCanonicalDimensions.all) {
        final c = dimensionCounts[d] ?? 0;
        if (c != IqBankContract.targetPerDimension) {
          error(
            'bank_dimension_target_mismatch',
            'Expected ${IqBankContract.targetPerDimension} for $d, found $c',
            fieldPath: d,
          );
        }
      }
    }

    return IqValidationReport(
      findings: findings,
      dimensionCounts: dimensionCounts,
      subskillCounts: subskillCounts,
      difficultyCounts: difficultyCounts,
      answerPositionCounts: answerPositionCounts,
      itemCount: rawItems.length,
    );
  }

  /// Pilot form uses qmatch_question_schema_v3 — validate session distribution only.
  static IqValidationReport validatePilotForm(Map<String, dynamic> form) {
    final findings = <IqValidationFinding>[];
    final items = (form['items'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    void error(String code, String message) {
      findings.add(
        IqValidationFinding(
          code: code,
          message: message,
          severity: IqValidationSeverity.error,
        ),
      );
    }

    if (items.length != IqBankContract.pilotItems) {
      error(
        'pilot_count_mismatch',
        'Expected ${IqBankContract.pilotItems}, found ${items.length}',
      );
    }

    final dims = <String, int>{
      for (final d in IqCanonicalDimensions.all) d: 0,
    };
    final ids = <String>{};
    for (final item in items) {
      final id = item['question_id']?.toString() ?? '';
      if (!ids.add(id)) {
        error('pilot_duplicate_id', 'Duplicate question_id $id');
      }
      final dim = item['primary_dimension']?.toString() ?? '';
      if (IqCanonicalDimensions.isRetired(dim)) {
        error('retired_dimension', 'Pilot uses retired dimension $dim');
      } else if (!IqCanonicalDimensions.isCanonical(dim)) {
        error('unsupported_dimension', 'Pilot unsupported dimension $dim');
      } else {
        dims[dim] = (dims[dim] ?? 0) + 1;
      }
      final correct = item['correct_option_id']?.toString();
      final options = (item['options'] as List<dynamic>? ?? const []);
      final match = options
          .where((o) => (o as Map)['option_id']?.toString() == correct)
          .length;
      if (match != 1) {
        error(
          'pilot_correct_option',
          'Item $id must have exactly one matching correct_option_id',
        );
      }
      if (options.length != 4) {
        error('pilot_option_count', 'Item $id must have 4 options');
      }
    }

    for (final entry in IqBankContract.liveSessionDistribution.entries) {
      if ((dims[entry.key] ?? 0) != entry.value) {
        error(
          'pilot_distribution_mismatch',
          'Expected ${entry.value} for ${entry.key}, found ${dims[entry.key] ?? 0}',
        );
      }
    }

    return IqValidationReport(
      findings: findings,
      dimensionCounts: dims,
      subskillCounts: const {},
      difficultyCounts: const {},
      answerPositionCounts: const {},
      itemCount: items.length,
    );
  }
}
