import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/iq_bank/iq_bank.dart';
import '../domain/iq_scoring/iq_scoring.dart';
import '../domain/iq_session/iq_session.dart';
import '../domain/iq_session/iq_session_prefs_repository.dart';

/// Live orchestration for canonical IQ sessions (P2C-2A-5).
///
/// Wraps offline bank + [IqSessionManager] + [IqCanonicalScorer].
/// Selects TR/EN bank from preferred language for **new** sessions; an
/// existing active session's persisted `bank_locale` remains authoritative.
/// Does not invent standardized IQ / percentiles / 20D mapping.
class IqCanonicalRuntimeService {
  IqCanonicalRuntimeService({
    FirebaseAuth? auth,
    IqSessionPersistenceRepository? repository,
    IqSessionIdFactory? idFactory,
    Random? seedRandom,
    AssetBundle? bundle,
  })  : _auth = auth,
        _repository = repository,
        _idFactory = idFactory,
        _seedRandom = seedRandom ?? Random.secure(),
        _bundle = bundle ?? rootBundle;

  static const bankAssetPathTr =
      'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
  static const bankAssetPathEn =
      'assets/data/assessment_v3/iq/iq_bank_en_v1.json';

  /// Backward-compatible alias (TR bank). Prefer [assetPathForLocale].
  static const bankAssetPath = bankAssetPathTr;

  final FirebaseAuth? _auth;
  final IqSessionPersistenceRepository? _repository;
  final IqSessionIdFactory? _idFactory;
  final Random _seedRandom;
  final AssetBundle _bundle;

  final Map<String, IqRecoveredBankDocument> _banksByLocale = {};
  IqSessionManager? _manager;
  IqRecoveredBankDocument? _activeBank;

  FirebaseAuth get _authOrThrow => _auth ?? FirebaseAuth.instance;

  IqSessionPersistenceRepository get _repo =>
      _repository ?? IqSessionPrefsRepository();

  /// Current Auth UID or null if signed out.
  String? get currentUid => _authOrThrow.currentUser?.uid;

  /// Bank bound to the current manager / last successful session bind.
  IqRecoveredBankDocument? get activeBank => _activeBank;

  /// Maps app language codes to canonical bank locales.
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

  Future<IqRecoveredBankDocument> loadBankForLocale(String bankLocale) async {
    final cached = _banksByLocale[bankLocale];
    if (cached != null) return cached;
    final raw = await _bundle.loadString(assetPathForLocale(bankLocale));
    final bank = IqRecoveredBankDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (bank.locale != bankLocale) {
      throw StateError(
        'Loaded bank locale ${bank.locale} != requested $bankLocale',
      );
    }
    _banksByLocale[bankLocale] = bank;
    return bank;
  }

  /// Loads the TR bank (tests / tools). Prefer [loadBankForLocale].
  Future<IqRecoveredBankDocument> loadBank() => loadBankForLocale('tr-TR');

  Future<IqSessionManager> _bindManager(IqRecoveredBankDocument bank) async {
    if (_manager != null &&
        _activeBank != null &&
        identical(_activeBank, bank)) {
      return _manager!;
    }
    _activeBank = bank;
    _manager = IqSessionManager(
      bank: bank,
      repository: _repo,
      idFactory: _idFactory ?? IqSessionIdFactory(),
    );
    return _manager!;
  }

  String _newSessionSeed(String uid) {
    final bytes = List<int>.generate(8, (_) => _seedRandom.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'live_${uid}_$hex';
  }

  /// Resume valid in-progress / pending-finalization draft, or create new.
  ///
  /// [preferredLanguageCode] only applies when composing a **new** session.
  /// An existing active/pending session always resumes against its persisted
  /// `bank_locale` / `bank_version` (no mid-session language swap).
  Future<IqSessionWriteResult> getOrCreateActiveSession({
    String? preferredLanguageCode,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }

    final peek = await _repo.loadActiveSession(uid);
    if (peek.isLoaded && peek.state!.status.keepsActivePointer) {
      final sessionLocale = peek.state!.bankLocale;
      final bank = await loadBankForLocale(sessionLocale);
      final manager = await _bindManager(bank);
      return manager.getOrCreateActiveSession(
        ownerUid: uid,
        sessionSeed: _newSessionSeed(uid),
      );
    }
    if (peek.code == IqSessionLoadCode.corrupt ||
        peek.code == IqSessionLoadCode.ownerMismatch) {
      return IqSessionWriteResult(
        ok: false,
        code: peek.code.name,
        message: peek.message,
      );
    }

    // Stuck pre-hotfix / cleared-pointer recovery: bind the candidate's bank.
    final listed = await _repo.listOwnerSessions(uid);
    final stuck = <IqPersistedSessionState>[
      for (final s in listed)
        if (!s.remoteFinalized &&
            s.answers.length == IqSessionContract.sessionItemCount &&
            (s.status == IqPersistedSessionStatus.completed ||
                s.status ==
                    IqPersistedSessionStatus.completedPendingPersistence))
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

  Future<IqSessionManager> _managerForSession(
    IqPersistedSessionState session,
  ) async {
    final bank = await loadBankForLocale(session.bankLocale);
    return _bindManager(bank);
  }

  Future<IqSessionWriteResult> answer({
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
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

  Future<IqSessionWriteResult> moveToIndex({
    required String sessionId,
    required int index,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
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

  Future<IqSessionWriteResult> completeSession({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.complete(ownerUid: uid, sessionId: sessionId);
  }

  /// After remote assessments/iq + progress + canonical_v1 succeed.
  Future<IqSessionWriteResult> markRemoteFinalized({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return IqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.markRemoteFinalized(ownerUid: uid, sessionId: sessionId);
  }

  Future<IqScoringOutcome> scoreCompleted(
    IqPersistedSessionState session,
  ) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqScoringOutcome.fail(
        code: IqScoringFailureCode.ownerUnavailable,
        message: 'Owner UID unavailable',
      );
    }
    final bank = await loadBankForLocale(session.bankLocale);
    _activeBank = bank;
    return const IqCanonicalScorer().scoreCompletedSession(
      session: session,
      bank: bank,
      ownerUid: uid,
    );
  }

  /// Resolve option label text for a plan's displayed option IDs.
  List<({String optionId, String text})> displayedOptions({
    required IqRecoveredBankDocument bank,
    required IqSessionItemPlan plan,
  }) {
    IqRecoveredBankItem? item;
    for (final i in bank.items) {
      if (i.id == plan.itemId) {
        item = i;
        break;
      }
    }
    if (item == null) return const [];
    final byId = {for (final o in item.options) o.id: o.text};
    return [
      for (final id in plan.displayedOptionIds)
        (optionId: id, text: byId[id] ?? id),
    ];
  }

  String? promptFor({
    required IqRecoveredBankDocument bank,
    required String itemId,
  }) {
    for (final i in bank.items) {
      if (i.id == itemId) return i.prompt;
    }
    return null;
  }

  @visibleForTesting
  bool get lastOperationComposed => _manager?.lastOperationComposed ?? false;
}
