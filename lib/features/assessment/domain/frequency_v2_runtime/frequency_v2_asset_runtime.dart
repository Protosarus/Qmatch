import 'dart:math';

import 'package:flutter/services.dart';

import '../frequency_behavior_v2/frequency_behavior_v2.dart';
import 'frequency_v2_bank_loader.dart';
import 'frequency_v2_session_controller.dart';
import 'frequency_v2_session_manager.dart';
import 'frequency_v2_session_repository.dart';

/// Asset-backed Frequency V2 session factory for debug/device testing.
///
/// Does not use [Directory.current] or `tool/` paths. Live routing is V2.
class FrequencyV2AssetRuntime {
  FrequencyV2AssetRuntime({
    AssetBundle? bundle,
    FrequencyV2SessionPersistenceRepository? repository,
    FrequencyV2SessionIdFactory? idFactory,
    Random? random,
  })  : _loader = FrequencyV2BankLoader(bundle: bundle ?? rootBundle),
        _repository = repository,
        _idFactory = idFactory,
        _random = random ?? Random.secure();

  final FrequencyV2BankLoader _loader;
  final FrequencyV2SessionPersistenceRepository? _repository;
  final FrequencyV2SessionIdFactory? _idFactory;
  final Random _random;

  FrequencyV2BankLoader get loader => _loader;

  String resolvePoolVersion(String? languageCode) {
    final code = (languageCode ?? 'en').toLowerCase();
    if (code.startsWith('tr')) {
      return FrequencyBehaviorV2Contract.poolVersionTrDraft1;
    }
    return FrequencyBehaviorV2Contract.poolVersionEnDraft1;
  }

  String resolveLocale(String? languageCode) {
    final code = (languageCode ?? 'en').toLowerCase();
    if (code.startsWith('tr')) return FrequencyBehaviorV2Contract.localeTr;
    return FrequencyBehaviorV2Contract.localeEn;
  }

  Future<FrequencyV2LoadedBank> loadBankForLanguageCode(
    String? languageCode,
  ) {
    return _loader.load(
      poolVersion: resolvePoolVersion(languageCode),
      locale: resolveLocale(languageCode),
    );
  }

  Future<FrequencyV2SessionController> createSession({
    required FrequencyV2LoadedBank bank,
    required String ownerUid,
    String? sessionSeed,
  }) async {
    final repo = _repository ?? FrequencyV2SessionPrefsRepository();
    final manager = FrequencyV2SessionManager(
      bank: bank,
      repository: repo,
      idFactory: _idFactory ?? FrequencyV2SessionIdFactory(random: _random),
    );
    final controller = FrequencyV2SessionController(
      bank: bank,
      manager: manager,
    );
    final seed = (sessionSeed == null || sessionSeed.trim().isEmpty)
        ? 'frequency_v2_${ownerUid}_${_random.nextInt(1 << 32)}'
        : sessionSeed;
    final started = await controller.start(
      ownerUid: ownerUid,
      sessionSeed: seed,
    );
    if (!started.ok || started.state == null) {
      throw FrequencyV2BankLoadException(
        started.code.isEmpty ? 'session_start_failed' : started.code,
        started.message,
      );
    }
    return controller;
  }
}
