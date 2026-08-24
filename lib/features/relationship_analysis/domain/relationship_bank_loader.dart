import 'dart:convert';

import 'package:flutter/services.dart';

import 'relationship_bank_models.dart';
import 'relationship_dimensions.dart';

class RelationshipBankLoader {
  RelationshipBankLoader({
    AssetBundle? bundle,
    String assetPath = RelationshipAnalysisContract.assetPath,
  })  : _bundle = bundle,
        _assetPath = assetPath;

  final AssetBundle? _bundle;
  final String _assetPath;
  RelationshipAnalysisBank? _cached;

  Future<RelationshipAnalysisBank> load({bool validate = true}) async {
    if (_cached != null) return _cached!;
    final raw = await (_bundle ?? rootBundle).loadString(_assetPath);
    final bank = parseJsonString(raw, validate: validate);
    _cached = bank;
    return bank;
  }

  static RelationshipAnalysisBank parseJsonString(
    String raw, {
    bool validate = true,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Relationship bank root must be an object');
    }
    final bank =
        RelationshipAnalysisBank.fromJson(Map<String, dynamic>.from(decoded));
    if (validate) RelationshipBankValidator.validate(bank);
    return bank;
  }
}
