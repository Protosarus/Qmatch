import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../domain/frequency_bank/frequency_bank.dart';
import '../domain/frequency_scoring/frequency_scoring.dart';
import '../domain/frequency_session/frequency_session.dart';

/// Live orchestration for canonical Frequency sessions (P2C-2A-8R2).
class FrequencyCanonicalRuntimeService {
  FrequencyCanonicalRuntimeService({
    FirebaseAuth? auth,
    FrequencySessionPersistenceRepository? repository,
    FrequencySessionIdFactory? idFactory,
    Random? seedRandom,
    AssetBundle? bundle,
  })  : _auth = auth,
        _repository = repository,
        _idFactory = idFactory,
        _seedRandom = seedRandom ?? Random.secure(),
        _bundle = bundle ?? rootBundle;

  static const bankAssetPathTr = FrequencyBankContract.trAssetPath;
  static const bankAssetPathEn = FrequencyBankContract.enAssetPath;

  final FirebaseAuth? _auth;
  final FrequencySessionPersistenceRepository? _repository;
  final FrequencySessionIdFactory? _idFactory;
  final Random _seedRandom;
  final AssetBundle _bundle;

  final Map<String, FrequencyCanonicalBankDocument> _banksByLocale = {};
  FrequencySessionManager? _manager;
  FrequencyCanonicalBankDocument? _activeBank;

  FirebaseAuth get _authOrThrow => _auth ?? FirebaseAuth.instance;

  FrequencySessionPersistenceRepository get _repo =>
      _repository ?? FrequencySessionPrefsRepository();

  String? get currentUid => _authOrThrow.currentUser?.uid;

  FrequencyCanonicalBankDocument? get activeBank => _activeBank;

  static String resolveBankLocale(String? languageCode) {
    final code = (languageCode ?? 'en').toLowerCase();
    if (code.startsWith('tr')) return 'tr-TR';
    return 'en-US';
  }

  static String assetPathForLocale(String bankLocale) {
    switch (bankLocale) {
      case 'tr-TR':
        return bankAssetPathTr;
      case 'en-US':
        return bankAssetPathEn;
      default:
        throw ArgumentError('Unsupported bank locale: $bankLocale');
    }
  }

  Future<FrequencyCanonicalBankDocument> loadBankForLocale(
      String bankLocale) async {
    final cached = _banksByLocale[bankLocale];
    if (cached != null) return cached;
    final raw = await _bundle.loadString(assetPathForLocale(bankLocale));
    final bank = FrequencyCanonicalBankDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (bank.locale != bankLocale) {
      throw StateError(
        'Loaded bank locale ${bank.locale} != requested $bankLocale',
      );
    }
    final check = const FrequencyCanonicalBankValidator().validate(bank);
    if (!check.ok) {
      throw StateError('Invalid Frequency bank: ${check.issues.join('; ')}');
    }
    _banksByLocale[bankLocale] = bank;
    return bank;
  }

  Future<FrequencySessionManager> _bindManager(
      FrequencyCanonicalBankDocument bank) async {
    if (_manager != null &&
        _activeBank != null &&
        identical(_activeBank, bank)) {
      return _manager!;
    }
    _activeBank = bank;
    _manager = FrequencySessionManager(
      bank: bank,
      repository: _repo,
      idFactory: _idFactory ?? FrequencySessionIdFactory(),
    );
    return _manager!;
  }

  String _newSessionSeed(String uid) {
    final bytes = List<int>.generate(8, (_) => _seedRandom.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'live_frequency_${uid}_$hex';
  }

  /// Resume valid in-progress / pending-finalization draft, or create new.
  ///
  /// [preferredLanguageCode] only applies when composing a **new** session.
  /// An existing active/pending session always resumes against its persisted
  /// `bank_locale` / `bank_version` (no mid-session language swap).
  Future<FrequencySessionWriteResult> getOrCreateActiveSession({
    String? preferredLanguageCode,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }

    final peek = await _repo.loadActiveSession(uid);
    if (peek.isLoaded && peek.state!.status.keepsActivePointer) {
      final bank = await loadBankForLocale(peek.state!.bankLocale);
      final manager = await _bindManager(bank);
      return manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: _newSessionSeed(uid),
      );
    }
    if (peek.code == FrequencySessionLoadCode.corrupt ||
        peek.code == FrequencySessionLoadCode.ownerMismatch) {
      return FrequencySessionWriteResult(
        ok: false,
        code: peek.code.name,
        message: peek.message,
      );
    }

    // Stuck pre-hotfix / cleared-pointer recovery: bind the candidate's bank.
    final listed = await _repo.listOwnerSessions(uid);
    final stuck = <FrequencyPersistedSessionState>[
      for (final s in listed)
        if (!s.remoteFinalized &&
            s.answers.length == FrequencySessionContract.sessionItemCount &&
            (s.status == FrequencyPersistedSessionStatus.completed ||
                s.status ==
                    FrequencyPersistedSessionStatus
                        .completedPendingPersistence))
          s,
    ];
    if (stuck.length == 1) {
      final bank = await loadBankForLocale(stuck.single.bankLocale);
      final manager = await _bindManager(bank);
      return manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: _newSessionSeed(uid),
      );
    }

    final bankLocale = resolveBankLocale(preferredLanguageCode);
    final bank = await loadBankForLocale(bankLocale);
    final manager = await _bindManager(bank);
    return manager.getOrCreateActiveSession(
      ownerUid: uid,
      sessionSeed: _newSessionSeed(uid),
    );
  }

  Future<FrequencySessionManager> _managerForSession(
    FrequencyPersistedSessionState session,
  ) async {
    final bank = await loadBankForLocale(session.bankLocale);
    return _bindManager(bank);
  }

  Future<FrequencySessionWriteResult> answer({
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.answer(
      ownerUid: uid,
      sessionId: sessionId,
      itemId: itemId,
      selectedOptionId: selectedOptionId,
    );
  }

  Future<FrequencySessionWriteResult> moveToIndex({
    required String sessionId,
    required int index,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.moveToIndex(
      ownerUid: uid,
      sessionId: sessionId,
      index: index,
    );
  }

  Future<FrequencySessionWriteResult> reconcileCursor({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.reconcileCursorToFirstUnanswered(
      ownerUid: uid,
      sessionId: sessionId,
    );
  }

  Future<FrequencySessionWriteResult> completeSession({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.complete(ownerUid: uid, sessionId: sessionId);
  }

  /// After remote assessments/frequency + progress + canonical_v1 succeed.
  Future<FrequencySessionWriteResult> markRemoteFinalized({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const FrequencySessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return FrequencySessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.markRemoteFinalized(ownerUid: uid, sessionId: sessionId);
  }

  Future<FrequencyScoringOutcome> scoreCompleted(
    FrequencyPersistedSessionState session,
  ) async {
    final bank = await loadBankForLocale(session.bankLocale);
    await _bindManager(bank);
    if (!session.status.isScoreable) {
      return const FrequencyScoringOutcome.fail(
        code: FrequencyScoringFailureCode.incompleteSession,
        message: 'Session not completed',
      );
    }
    final responses = [
      for (final p in session.itemPlans)
        FrequencyCanonicalResponse(
          itemId: p.itemId,
          optionId: session.answersByItemId[p.itemId]!.selectedOptionId,
        ),
    ];
    return const CanonicalFrequencyScorer().score(
      bank: bank,
      responses: responses,
    );
  }

  List<({String optionId, String text})> displayedOptions({
    required FrequencyCanonicalBankDocument bank,
    required FrequencySessionItemPlan plan,
  }) {
    final item = bank.itemsById[plan.itemId];
    if (item == null) return const [];
    return [
      for (final id in plan.displayedOptionIds)
        (
          optionId: id,
          text: item.optionById(id)?.text ?? '',
        ),
    ];
  }

  String? promptFor({
    required FrequencyCanonicalBankDocument bank,
    required String itemId,
  }) =>
      bank.itemsById[itemId]?.prompt;

  /// Protocol attention signals only — never trait scores / RVI gates.
  static Map<String, dynamic> deriveQualitySignals({
    required FrequencyCanonicalBankDocument bank,
    required FrequencyPersistedSessionState session,
  }) {
    final byId = session.answersByItemId;
    bool? instructionPassed;
    bool? protocolPassed;
    for (final item in bank.items) {
      if (item.itemRole != FrequencyBankContract.itemRoleQuality) continue;
      final ans = byId[item.itemId];
      final passed = ans != null &&
          item.expectedProtocolOptionId != null &&
          ans.selectedOptionId == item.expectedProtocolOptionId;
      if (item.itemId == 'freq_quality_instruction_v1') {
        instructionPassed = passed;
      } else if (item.itemId == 'freq_quality_protocol_v1') {
        protocolPassed = passed;
      }
    }
    return {
      'attention_check_1_passed': instructionPassed,
      'attention_check_2_passed': protocolPassed,
      'protocol_signal_only': true,
      'rvi_runtime_gate': FrequencyScoringContract.rviRuntimeGate,
    };
  }
}
