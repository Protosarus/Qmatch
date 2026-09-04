import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../frequency_behavior_v2/frequency_behavior_v2.dart';
import 'frequency_v2_runtime_contract.dart';

class FrequencyV2BankLoadException implements Exception {
  const FrequencyV2BankLoadException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'FrequencyV2BankLoadException($code, $message)';
}

/// Version+locale keyed V2 bank. Never live-selectable by itself.
class FrequencyV2LoadedBank {
  const FrequencyV2LoadedBank({
    required this.pool,
    required this.raw,
    required this.reviewByItemId,
    required this.nearDuplicateClusters,
    required this.sourcePath,
    this.translationVersion,
  });

  final FrequencyBehaviorV2PoolDocument pool;
  final Map<String, dynamic> raw;
  final Map<String, Map<String, dynamic>> reviewByItemId;
  final List<List<String>> nearDuplicateClusters;
  final String sourcePath;
  final String? translationVersion;

  String get poolVersion => pool.poolVersion;
  String get locale => pool.locale;
}

/// Loads reviewed Frequency V2 pools by `pool_version` AND locale.
///
/// Does not make the bank live-selectable. Tests may load from the repo
/// filesystem; a Flutter [AssetBundle] is optional.
class FrequencyV2BankLoader {
  FrequencyV2BankLoader({
    this.repoRoot,
    this.bundle,
  });

  final String? repoRoot;
  final AssetBundle? bundle;

  String get _root => repoRoot ?? Directory.current.path;

  Future<FrequencyV2LoadedBank> load({
    required String poolVersion,
    required String locale,
    String? expectedTranslationVersion,
  }) async {
    final path = FrequencyBehaviorV2BankRegistry.draftPath(
      poolVersion: poolVersion,
      locale: locale,
    );
    if (path == null) {
      throw FrequencyV2BankLoadException(
        'unknown_bank',
        'No reviewed V2 bank for $poolVersion|$locale',
      );
    }
    final reviewPath = FrequencyBehaviorV2BankRegistry.draftReviewPath(
      poolVersion: poolVersion,
      locale: locale,
    );
    if (reviewPath == null) {
      throw FrequencyV2BankLoadException(
        'unknown_review',
        'No reviewed V2 review metadata for $poolVersion|$locale',
      );
    }

    final raw = await _loadJsonObject(path);
    final reviewRaw = await _loadJsonObject(reviewPath);
    final pool = FrequencyBehaviorV2PoolDocument.fromJson(raw);

    if (pool.schemaVersion != FrequencyBehaviorV2Contract.schemaVersion) {
      throw FrequencyV2BankLoadException(
        'schema_mismatch',
        pool.schemaVersion,
      );
    }
    if (pool.poolVersion != poolVersion) {
      throw FrequencyV2BankLoadException(
        'pool_version_mismatch',
        'requested $poolVersion, file ${pool.poolVersion}',
      );
    }
    if (pool.locale != locale) {
      throw FrequencyV2BankLoadException(
        'locale_mismatch',
        'requested $locale, file ${pool.locale}',
      );
    }
    if (pool.runtimeSelectable) {
      throw const FrequencyV2BankLoadException(
        'runtime_selectable',
        'V2 bank must not be runtime-selectable',
      );
    }

    final translationVersion = raw['translation_version'] as String?;
    if (locale == FrequencyBehaviorV2Contract.localeEn) {
      final expected = expectedTranslationVersion ??
          FrequencyBehaviorV2Contract.translationVersionEnSemanticV1;
      if (translationVersion != expected) {
        throw FrequencyV2BankLoadException(
          'translation_version_mismatch',
          'expected $expected, file ${translationVersion ?? 'missing'}',
        );
      }
    } else if (expectedTranslationVersion != null &&
        expectedTranslationVersion.isNotEmpty &&
        translationVersion != expectedTranslationVersion) {
      throw FrequencyV2BankLoadException(
        'translation_version_mismatch',
        'expected $expectedTranslationVersion, file ${translationVersion ?? 'missing'}',
      );
    }

    if (pool.items.length != FrequencyBehaviorV2Contract.poolItemCount) {
      throw FrequencyV2BankLoadException(
        'item_count',
        '${pool.items.length}',
      );
    }
    for (final item in pool.items) {
      if (item.options.length != FrequencyV2RuntimeContract.optionsPerItem) {
        throw FrequencyV2BankLoadException('option_count', item.itemId);
      }
    }

    final reviewByItemId = <String, Map<String, dynamic>>{};
    final items = reviewRaw['items'];
    if (items is List) {
      for (final rawItem in items) {
        if (rawItem is! Map) continue;
        final m = Map<String, dynamic>.from(rawItem);
        final id = m['item_id'] as String?;
        if (id == null) continue;
        reviewByItemId[id] = m;
      }
    }

    var dropCount = 0;
    var selectableCount = 0;
    for (final item in pool.items) {
      final review = reviewByItemId[item.itemId];
      final dropped = review?['drop_from_selectable'] == true ||
          review?['review_status']?.toString() == 'dropped_from_selectable';
      if (dropped) {
        dropCount++;
      } else {
        selectableCount++;
      }
    }
    if (dropCount != FrequencyV2RuntimeContract.dropItemCount) {
      throw FrequencyV2BankLoadException('drop_count', '$dropCount');
    }
    if (selectableCount != FrequencyV2RuntimeContract.selectableItemCount) {
      throw FrequencyV2BankLoadException(
        'selectable_count',
        '$selectableCount',
      );
    }

    final clusters = <List<String>>[];
    final rawClusters =
        reviewRaw['semantic_near_duplicate_clusters'] as List? ?? const [];
    for (final c in rawClusters) {
      if (c is! Map) continue;
      final ids = Map<String, dynamic>.from(c)['item_ids'];
      if (ids is! List) continue;
      clusters.add([for (final id in ids) id.toString()]);
    }

    return FrequencyV2LoadedBank(
      pool: pool,
      raw: raw,
      reviewByItemId: reviewByItemId,
      nearDuplicateClusters: clusters,
      sourcePath: path,
      translationVersion: translationVersion,
    );
  }

  Future<Map<String, dynamic>> _loadJsonObject(String relativePath) async {
    final file = File('$_root/$relativePath');
    if (await file.exists()) {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw FrequencyV2BankLoadException('invalid_json', relativePath);
    }
    final asset = bundle;
    if (asset != null) {
      final text = await asset.loadString(relativePath);
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw FrequencyV2BankLoadException('missing_source', relativePath);
  }
}
