import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../domain/eq_bank/eq_bank.dart';
import '../domain/eq_scoring/eq_scoring.dart';
import '../domain/eq_session/eq_session.dart';
import '../domain/eq_session/eq_session_prefs_repository.dart';

/// Live orchestration for canonical EQ sessions (P2C-2A-7R2).
class EqCanonicalRuntimeService {
  EqCanonicalRuntimeService({
    FirebaseAuth? auth,
    EqSessionPersistenceRepository? repository,
    EqSessionIdFactory? idFactory,
    Random? seedRandom,
    AssetBundle? bundle,
  })  : _auth = auth,
        _repository = repository,
        _idFactory = idFactory,
        _seedRandom = seedRandom ?? Random.secure(),
        _bundle = bundle ?? rootBundle;

  static const bankAssetPathTr = EqBankContract.trAssetPath;
  static const bankAssetPathEn = EqBankContract.enAssetPath;

  final FirebaseAuth? _auth;
  final EqSessionPersistenceRepository? _repository;
  final EqSessionIdFactory? _idFactory;
  final Random _seedRandom;
  final AssetBundle _bundle;

  final Map<String, EqCanonicalBankDocument> _banksByLocale = {};
  EqSessionManager? _manager;
  EqCanonicalBankDocument? _activeBank;

  FirebaseAuth get _authOrThrow => _auth ?? FirebaseAuth.instance;

  EqSessionPersistenceRepository get _repo =>
      _repository ?? EqSessionPrefsRepository();

  String? get currentUid => _authOrThrow.currentUser?.uid;

  EqCanonicalBankDocument? get activeBank => _activeBank;

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

  Future<EqCanonicalBankDocument> loadBankForLocale(String bankLocale) async {
    final cached = _banksByLocale[bankLocale];
    if (cached != null) return cached;
    final raw = await _bundle.loadString(assetPathForLocale(bankLocale));
    final bank = EqCanonicalBankDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    if (bank.locale != bankLocale) {
      throw StateError(
        'Loaded bank locale ${bank.locale} != requested $bankLocale',
      );
    }
    final check = const EqCanonicalBankValidator().validate(bank);
    if (!check.ok) {
      throw StateError('Invalid EQ bank: ${check.issues.join('; ')}');
    }
    _banksByLocale[bankLocale] = bank;
    return bank;
  }

  Future<EqSessionManager> _bindManager(EqCanonicalBankDocument bank) async {
    if (_manager != null &&
        _activeBank != null &&
        identical(_activeBank, bank)) {
      return _manager!;
    }
    _activeBank = bank;
    _manager = EqSessionManager(
      bank: bank,
      repository: _repo,
      idFactory: _idFactory ?? EqSessionIdFactory(),
    );
    return _manager!;
  }

  String _newSessionSeed(String uid) {
    final bytes = List<int>.generate(8, (_) => _seedRandom.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'live_eq_${uid}_$hex';
  }

  /// Resume valid in-progress / pending-finalization draft, or create new.
  ///
  /// [preferredLanguageCode] only applies when composing a **new** session.
  /// An existing active/pending session always resumes against its persisted
  /// `bank_locale` / `bank_version` (no mid-session language swap).
  Future<EqSessionWriteResult> getOrCreateActiveSession({
    String? preferredLanguageCode,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const EqSessionWriteResult(
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
    if (peek.code == EqSessionLoadCode.corrupt ||
        peek.code == EqSessionLoadCode.ownerMismatch) {
      return EqSessionWriteResult(
        ok: false,
        code: peek.code.name,
        message: peek.message,
      );
    }

    // Stuck pre-hotfix / cleared-pointer recovery: bind the candidate's bank.
    final listed = await _repo.listOwnerSessions(uid);
    final stuck = <EqPersistedSessionState>[
      for (final s in listed)
        if (!s.remoteFinalized &&
            s.answers.length == EqSessionContract.sessionItemCount &&
            (s.status == EqPersistedSessionStatus.completed ||
                s.status ==
                    EqPersistedSessionStatus.completedPendingPersistence))
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

  Future<EqSessionManager> _managerForSession(
    EqPersistedSessionState session,
  ) async {
    final bank = await loadBankForLocale(session.bankLocale);
    return _bindManager(bank);
  }

  Future<EqSessionWriteResult> answer({
    required String sessionId,
    required String itemId,
    required String selectedOptionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return EqSessionWriteResult(
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

  Future<EqSessionWriteResult> moveToIndex({
    required String sessionId,
    required int index,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return EqSessionWriteResult(
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

  Future<EqSessionWriteResult> completeSession({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return EqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.complete(ownerUid: uid, sessionId: sessionId);
  }

  /// After remote assessments/eq + progress + canonical_v1 succeed.
  Future<EqSessionWriteResult> markRemoteFinalized({
    required String sessionId,
  }) async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const EqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final loaded = await _repo.loadSession(uid, sessionId);
    if (!loaded.isLoaded) {
      return EqSessionWriteResult(
        ok: false,
        code: loaded.code.name,
        message: loaded.message,
      );
    }
    final manager = await _managerForSession(loaded.state!);
    return manager.markRemoteFinalized(ownerUid: uid, sessionId: sessionId);
  }

  Future<EqScoringOutcome> scoreCompleted(
    EqPersistedSessionState session,
  ) async {
    final bank = await loadBankForLocale(session.bankLocale);
    await _bindManager(bank);
    if (!session.status.isScoreable) {
      return const EqScoringOutcome.fail(
        code: EqScoringFailureCode.incompleteSession,
        message: 'Session not completed',
      );
    }
    final responses = [
      for (final p in session.itemPlans)
        EqCanonicalResponse(
          itemId: p.itemId,
          optionId: session.answersByItemId[p.itemId]!.selectedOptionId,
        ),
    ];
    return const CanonicalEqScorer().score(
      bank: bank,
      responses: responses,
    );
  }

  List<({String optionId, String text})> displayedOptions({
    required EqCanonicalBankDocument bank,
    required EqSessionItemPlan plan,
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
    required EqCanonicalBankDocument bank,
    required String itemId,
  }) =>
      bank.itemsById[itemId]?.prompt;
}
