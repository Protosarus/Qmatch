import 'dart:convert';
import 'dart:io';

import 'package:qmatch/features/assessment/domain/persona_scoring/persona_scoring.dart';

/// Filesystem loader for offline tests/tools only.
/// Does NOT register v2 JSON as Flutter runtime assets.
class PersonaScoringFileLoader {
  PersonaScoringFileLoader._();

  static ({PersonaProfileCatalog catalog, PersonaScoringConfig config})
      loadFromRepoRoot(String root) {
    final profilesPath = '$root/assets/data/persona_profiles_v2_20d.json';
    final configPath = '$root/assets/data/persona_scoring_config_v2.json';
    final catalog = PersonaScoringParsers.parseProfilesJson(
      File(profilesPath).readAsStringSync(),
    );
    final config = PersonaScoringParsers.parseConfigJson(
      File(configPath).readAsStringSync(),
    );
    PersonaScoringParsers.assertCompatible(catalog, config);
    return (catalog: catalog, config: config);
  }

  static PersonaScoringService serviceFromRepoRoot(String root) {
    final loaded = loadFromRepoRoot(root);
    return PersonaScoringService(
      catalog: loaded.catalog,
      config: loaded.config,
    );
  }

  /// Offline shadow scorer (P2C-3A-2). Does not register assets in pubspec.
  static ({PersonaProfileCatalog catalog, PersonaShadowScoringConfig config})
      loadShadowFromRepoRoot(String root) {
    final profilesPath = '$root/assets/data/persona_profiles_v2_20d.json';
    final configPath =
        '$root/assets/data/persona_shadow_scoring_config_v1.json';
    final catalog = PersonaScoringParsers.parseProfilesJson(
      File(profilesPath).readAsStringSync(),
    );
    final config = PersonaShadowConfigParser.parseJson(
      File(configPath).readAsStringSync(),
    );
    return (catalog: catalog, config: config);
  }

  static CanonicalPersonaShadowScorer shadowScorerFromRepoRoot(String root) {
    final loaded = loadShadowFromRepoRoot(root);
    return CanonicalPersonaShadowScorer(
      catalog: loaded.catalog,
      config: loaded.config,
    );
  }

  /// Deep-copy JSON maps with shuffled key insertion order for determinism tests.
  static Map<String, dynamic> shuffleMapOrder(
    Map<String, dynamic> source,
    int seed,
  ) {
    final encoded = jsonEncode(source);
    final decoded = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    // Re-insert keys in reverse order to change LinkedHashMap iteration.
    final keys = decoded.keys.toList().reversed.toList();
    final out = <String, dynamic>{};
    for (final k in keys) {
      out[k] = decoded[k];
    }
    // Touch seed so callers can vary per case without unused warnings.
    if (seed < 0) {
      throw ArgumentError('seed');
    }
    return out;
  }
}
