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

  static const bankAssetPath =
      'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';

  final FirebaseAuth? _auth;
  final IqSessionPersistenceRepository? _repository;
  final IqSessionIdFactory? _idFactory;
  final Random _seedRandom;
  final AssetBundle _bundle;

  IqRecoveredBankDocument? _bank;
  IqSessionManager? _manager;

  FirebaseAuth get _authOrThrow => _auth ?? FirebaseAuth.instance;

  /// Current Auth UID or null if signed out.
  String? get currentUid => _authOrThrow.currentUser?.uid;

  Future<IqRecoveredBankDocument> loadBank() async {
    if (_bank != null) return _bank!;
    final raw = await _bundle.loadString(bankAssetPath);
    _bank = IqRecoveredBankDocument.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    return _bank!;
  }

  Future<IqSessionManager> _ensureManager() async {
    if (_manager != null) return _manager!;
    final bank = await loadBank();
    _manager = IqSessionManager(
      bank: bank,
      repository: _repository ?? IqSessionPrefsRepository(),
      idFactory: _idFactory ?? IqSessionIdFactory(),
    );
    return _manager!;
  }

  String _newSessionSeed(String uid) {
    final bytes = List<int>.generate(8, (_) => _seedRandom.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'live_${uid}_$hex';
  }

  /// Resume valid in-progress draft or create a new canonical session.
  Future<IqSessionWriteResult> getOrCreateActiveSession() async {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) {
      return const IqSessionWriteResult(
        ok: false,
        code: 'owner_unavailable',
        message: 'Owner UID unavailable',
      );
    }
    final manager = await _ensureManager();
    return manager.getOrCreateActiveSession(
      ownerUid: uid,
      sessionSeed: _newSessionSeed(uid),
    );
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
    final manager = await _ensureManager();
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
    final manager = await _ensureManager();
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
    final manager = await _ensureManager();
    return manager.complete(ownerUid: uid, sessionId: sessionId);
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
    final bank = await loadBank();
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
