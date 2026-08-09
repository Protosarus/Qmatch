import 'iq_canonical_dimensions.dart';
import 'iq_item_model.dart';

/// Decode error for recovered offline IQ bank JSON (P2C-2A-1).
class IqRecoveredBankDecodeException implements Exception {
  IqRecoveredBankDecodeException(this.message, {this.itemId, this.fieldPath});

  final String message;
  final String? itemId;
  final String? fieldPath;

  @override
  String toString() {
    final buf = StringBuffer('IqRecoveredBankDecodeException: $message');
    if (itemId != null) buf.write(' itemId=$itemId');
    if (fieldPath != null) buf.write(' field=$fieldPath');
    return buf.toString();
  }
}

/// Runtime-neutral recovered bank root (not wired to production loaders).
class IqRecoveredBankDocument {
  const IqRecoveredBankDocument({
    required this.schemaVersion,
    required this.bankVersion,
    required this.locale,
    required this.source,
    required this.items,
    this.parserVersion,
  });

  final String schemaVersion;
  final String bankVersion;
  final String locale;
  final String source;
  final String? parserVersion;
  final List<IqRecoveredBankItem> items;

  static const expectedSchemaVersion = 'qmatch_iq_bank_v1';
  static const expectedBankVersion = 'tr_v2_340';
  static const expectedLocale = 'tr-TR';
  static const expectedItemCount = 340;

  factory IqRecoveredBankDocument.fromJson(Map<String, dynamic> json) {
    final schemaVersion = _reqString(json, 'schema_version');
    if (schemaVersion != expectedSchemaVersion) {
      throw IqRecoveredBankDecodeException(
        'Unsupported schema_version=$schemaVersion',
        fieldPath: 'schema_version',
      );
    }
    final bankVersion = _reqString(json, 'bank_version');
    final locale = _reqString(json, 'locale');
    if (locale != expectedLocale) {
      throw IqRecoveredBankDecodeException(
        'Unsupported locale=$locale',
        fieldPath: 'locale',
      );
    }
    final source = _reqString(json, 'source');
    final parserVersion = json['parser_version'] is String
        ? json['parser_version'] as String
        : null;
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw IqRecoveredBankDecodeException(
        'items must be a List',
        fieldPath: 'items',
      );
    }
    final items = <IqRecoveredBankItem>[];
    for (var i = 0; i < rawItems.length; i++) {
      final row = rawItems[i];
      if (row is! Map) {
        throw IqRecoveredBankDecodeException(
          'items[$i] must be an object',
          fieldPath: 'items[$i]',
        );
      }
      items.add(
        IqRecoveredBankItem.fromJson(Map<String, dynamic>.from(row)),
      );
    }
    return IqRecoveredBankDocument(
      schemaVersion: schemaVersion,
      bankVersion: bankVersion,
      locale: locale,
      source: source,
      parserVersion: parserVersion,
      items: items,
    );
  }
}

/// One recovered bank item — no fabricated difficulty/rationale/subskill.
class IqRecoveredBankItem {
  const IqRecoveredBankItem({
    required this.id,
    required this.dimension,
    required this.templateFamilyId,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    required this.sourceOrder,
    required this.revisionStatus,
    required this.reviewStatus,
  });

  final String id;
  final String dimension;
  final String templateFamilyId;
  final String prompt;
  final List<IqOption> options;
  final String correctOptionId;
  final int sourceOrder;
  final String revisionStatus;
  final String reviewStatus;

  static const allowedOptionIds = {'a', 'b', 'c', 'd'};
  static const allowedRevisionStatuses = {'rewritten_v2', 'retained_v2'};
  static const expectedReviewStatus = 'desk_reviewed_candidate';

  factory IqRecoveredBankItem.fromJson(Map<String, dynamic> json) {
    final id = _reqString(json, 'id');
    final dimension = _reqString(json, 'dimension');
    if (dimension == 'numerical') {
      throw IqRecoveredBankDecodeException(
        'Retired numerical dimension is not allowed',
        itemId: id,
        fieldPath: 'dimension',
      );
    }
    if (!IqCanonicalDimensions.isCanonical(dimension)) {
      throw IqRecoveredBankDecodeException(
        'Unsupported dimension=$dimension',
        itemId: id,
        fieldPath: 'dimension',
      );
    }
    final family = _reqString(json, 'template_family_id');
    final prompt = _reqString(json, 'prompt');
    if (prompt.trim().isEmpty) {
      throw IqRecoveredBankDecodeException(
        'Empty prompt',
        itemId: id,
        fieldPath: 'prompt',
      );
    }
    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.length != 4) {
      throw IqRecoveredBankDecodeException(
        'options must be a list of length 4',
        itemId: id,
        fieldPath: 'options',
      );
    }
    final options = <IqOption>[];
    final seenIds = <String>{};
    final seenTexts = <String>{};
    for (var i = 0; i < rawOptions.length; i++) {
      final row = rawOptions[i];
      if (row is! Map) {
        throw IqRecoveredBankDecodeException(
          'option[$i] must be an object',
          itemId: id,
          fieldPath: 'options[$i]',
        );
      }
      final opt = IqOption.fromJson(Map<String, dynamic>.from(row));
      if (!allowedOptionIds.contains(opt.id)) {
        throw IqRecoveredBankDecodeException(
          'Invalid option id=${opt.id}',
          itemId: id,
          fieldPath: 'options[$i].id',
        );
      }
      if (!seenIds.add(opt.id)) {
        throw IqRecoveredBankDecodeException(
          'Duplicate option id=${opt.id}',
          itemId: id,
          fieldPath: 'options[$i].id',
        );
      }
      final norm =
          opt.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (norm.isEmpty) {
        throw IqRecoveredBankDecodeException(
          'Empty option text',
          itemId: id,
          fieldPath: 'options[$i].text',
        );
      }
      if (!seenTexts.add(norm)) {
        throw IqRecoveredBankDecodeException(
          'Repeated option text',
          itemId: id,
          fieldPath: 'options[$i].text',
        );
      }
      options.add(opt);
    }
    if (options.map((o) => o.id).toList().join() != 'abcd') {
      throw IqRecoveredBankDecodeException(
        'Option IDs must be exactly a,b,c,d in order',
        itemId: id,
        fieldPath: 'options',
      );
    }
    final correct = _reqString(json, 'correct_option_id');
    if (!allowedOptionIds.contains(correct)) {
      throw IqRecoveredBankDecodeException(
        'Invalid correct_option_id=$correct',
        itemId: id,
        fieldPath: 'correct_option_id',
      );
    }
    if (!options.any((o) => o.id == correct)) {
      throw IqRecoveredBankDecodeException(
        'correct_option_id not present in options',
        itemId: id,
        fieldPath: 'correct_option_id',
      );
    }
    final sourceOrder = json['source_order'];
    if (sourceOrder is! int) {
      throw IqRecoveredBankDecodeException(
        'source_order must be int',
        itemId: id,
        fieldPath: 'source_order',
      );
    }
    final revision = _reqString(json, 'revision_status');
    if (!allowedRevisionStatuses.contains(revision)) {
      throw IqRecoveredBankDecodeException(
        'Invalid revision_status=$revision',
        itemId: id,
        fieldPath: 'revision_status',
      );
    }
    final review = _reqString(json, 'review_status');
    if (review != expectedReviewStatus) {
      throw IqRecoveredBankDecodeException(
        'Unexpected review_status=$review',
        itemId: id,
        fieldPath: 'review_status',
      );
    }
    return IqRecoveredBankItem(
      id: id,
      dimension: dimension,
      templateFamilyId: family,
      prompt: prompt,
      options: options,
      correctOptionId: correct,
      sourceOrder: sourceOrder,
      revisionStatus: revision,
      reviewStatus: review,
    );
  }
}

String _reqString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! String || v.isEmpty) {
    throw IqRecoveredBankDecodeException(
      'Missing or invalid string field',
      fieldPath: key,
    );
  }
  return v;
}
