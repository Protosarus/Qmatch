import 'package:flutter/services.dart';

import 'persona_scoring_parsers.dart';
import 'persona_shadow_config_parser.dart';
import 'persona_shadow_contract.dart';
import 'persona_shadow_scoring_config.dart';
import 'persona_prototype.dart';
import 'canonical_persona_shadow_scorer.dart';

/// Loads shadow Persona assets for runtime (not the legacy affinity scorer).
class PersonaRuntimeAssetLoader {
  PersonaRuntimeAssetLoader({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  Future<({PersonaProfileCatalog catalog, PersonaShadowScoringConfig config})>
      loadShadow() async {
    final profilesJson = await _bundle.loadString(
      PersonaShadowContract.prototypeAssetPath,
    );
    final configJson = await _bundle.loadString(
      PersonaShadowContract.configAssetPath,
    );
    final catalog = PersonaScoringParsers.parseProfilesJson(profilesJson);
    final config = PersonaShadowConfigParser.parseJson(configJson);
    return (catalog: catalog, config: config);
  }

  Future<CanonicalPersonaShadowScorer> loadScorer() async {
    final loaded = await loadShadow();
    return CanonicalPersonaShadowScorer(
      catalog: loaded.catalog,
      config: loaded.config,
    );
  }
}
