import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:qmatch/features/assessment/domain/iq_bank/iq_bank.dart';
import 'package:qmatch/features/assessment/domain/iq_scoring/iq_scoring.dart';
import 'package:qmatch/features/assessment/domain/iq_session/iq_session.dart';
import 'package:qmatch/features/assessment/services/iq_canonical_runtime_service.dart';

const _trPath = 'assets/data/assessment_v3/iq/iq_bank_tr_v1.json';
const _enPath = 'assets/data/assessment_v3/iq/iq_bank_en_v1.json';

final _trChars = RegExp(r'[ğüşıöçĞÜŞİÖÇ]');
final _commonTrWords = RegExp(
  r'\b(Aşağıdaki|hangisidir|gelmelidir|bulunmaktadır|şekildedir|ilişkisine)\b',
  caseSensitive: false,
);

IqRecoveredBankDocument _load(String path) {
  return IqRecoveredBankDocument.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
  );
}

void main() {
  late IqRecoveredBankDocument tr;
  late IqRecoveredBankDocument en;

  setUpAll(() {
    tr = _load(_trPath);
    en = _load(_enPath);
  });

  group('TR↔EN structural parity', () {
    test('both banks 340 with identical ID sets and dimensions', () {
      expect(tr.items.length, 340);
      expect(en.items.length, 340);
      expect(tr.locale, 'tr-TR');
      expect(en.locale, 'en-US');
      expect(tr.bankVersion, 'tr_v2_340');
      expect(en.bankVersion, 'en_v2_340');
      expect(
        tr.items.map((e) => e.id).toSet(),
        en.items.map((e) => e.id).toSet(),
      );
      expect(IqRecoveredBankValidator.validate(tr).ok, isTrue);
      expect(IqRecoveredBankValidator.validate(en).ok, isTrue);
      expect(
        IqRecoveredBankValidator.validate(tr).dimensionCounts,
        IqBankContract.recoveredDimensionDistribution,
      );
      expect(
        IqRecoveredBankValidator.validate(en).dimensionCounts,
        IqBankContract.recoveredDimensionDistribution,
      );
    });

    test('per-item family/option/correct parity', () {
      final enBy = {for (final i in en.items) i.id: i};
      for (final t in tr.items) {
        final e = enBy[t.id]!;
        expect(e.dimension, t.dimension, reason: t.id);
        expect(e.templateFamilyId, t.templateFamilyId, reason: t.id);
        expect(e.correctOptionId, t.correctOptionId, reason: t.id);
        expect(e.sourceOrder, t.sourceOrder, reason: t.id);
        expect(e.revisionStatus, t.revisionStatus, reason: t.id);
        expect(e.reviewStatus, t.reviewStatus, reason: t.id);
        expect(
          e.options.map((o) => o.id).toList(),
          t.options.map((o) => o.id).toList(),
          reason: t.id,
        );
        expect(e.options.length, 4, reason: t.id);
        expect(e.prompt.trim().isNotEmpty, isTrue, reason: t.id);
        for (final o in e.options) {
          expect(o.text.trim().isNotEmpty, isTrue, reason: '${t.id}:${o.id}');
        }
      }
    });

    test('EN has no accidental Turkish stems; TR content remains Turkish', () {
      for (final i in en.items) {
        expect(_commonTrWords.hasMatch(i.prompt), isFalse, reason: i.id);
      }
      final trBy = {for (final i in tr.items) i.id: i};
      var identicalPromptCount = 0;
      for (final i in en.items) {
        if (i.prompt == trBy[i.id]!.prompt) identicalPromptCount++;
      }
      expect(identicalPromptCount, 0);
      expect(en.items.first.prompt.contains('Aşağıdaki'), isFalse);
      expect(
        tr.items.any((i) => i.prompt.contains('Aşağıdaki')),
        isTrue,
      );
      expect(
        en.items.any((i) => i.prompt.contains('Aşağıdaki')),
        isFalse,
      );
    });

    test('UTF-8 deterministic parse round-trip', () {
      final raw = File(_enPath).readAsBytesSync();
      expect(raw.isNotEmpty, isTrue);
      final again = IqRecoveredBankDocument.fromJson(
        jsonDecode(utf8.decode(raw)) as Map<String, dynamic>,
      );
      expect(again.items.length, 340);
      expect(again.bankVersion, en.bankVersion);
    });
  });

  group('composer + scorer both locales', () {
    test('composer works for TR and EN with 7/6/6/6', () {
      for (final bank in [tr, en]) {
        final composed = const IqSessionComposer().compose(
          bank: bank,
          config: const IqSessionConfig(sessionSeed: 'parity-seed'),
        );
        expect(composed, isA<IqSessionCompositionSuccess>());
        final plan = (composed as IqSessionCompositionSuccess).plan;
        expect(plan.itemPlans.length, 25);
        expect(plan.bankLocale, bank.locale);
        expect(plan.bankVersion, bank.bankVersion);
        expect(
          plan.itemPlans
              .where((p) => p.dimension == 'logical_reasoning')
              .length,
          7,
        );
        expect(
          plan.itemPlans
              .where((p) => p.dimension == 'pattern_reasoning')
              .length,
          6,
        );
        expect(
          plan.itemPlans.where((p) => p.dimension == 'verbal_reasoning').length,
          6,
        );
        expect(
          plan.itemPlans
              .where((p) => p.dimension == 'spatial_reasoning')
              .length,
          6,
        );
      }
    });

    test('scorer TR/EN same seed + all-correct → equal provisional scores',
        () async {
      Future<IqCanonicalScoringResult> score(
        IqRecoveredBankDocument bank,
      ) async {
        final repo = IqSessionMemoryRepository();
        final manager = IqSessionManager(
          bank: bank,
          repository: repo,
          idFactory: IqSessionIdFactory(random: Random(9)),
          clock: () => DateTime.utc(2026, 8, 9, 12),
        );
        final uid = 'parity_uid_${bank.locale}';
        final created = await manager.getOrCreateActiveSession(
          ownerUid: uid,
          sessionSeed: 'same-abstract-seed',
        );
        expect(created.ok, isTrue);
        var state = created.state!;
        for (final plan in state.itemPlans) {
          final item = bank.items.firstWhere((e) => e.id == plan.itemId);
          final answered = await manager.answer(
            ownerUid: uid,
            sessionId: state.sessionId,
            itemId: plan.itemId,
            selectedOptionId: item.correctOptionId,
          );
          expect(answered.ok, isTrue);
          state = answered.state!;
        }
        final completed = await manager.complete(
          ownerUid: uid,
          sessionId: state.sessionId,
        );
        expect(completed.ok, isTrue);
        final outcome = const IqCanonicalScorer().scoreCompletedSession(
          session: completed.state!,
          bank: bank,
          ownerUid: uid,
        );
        expect(outcome.ok, isTrue);
        return outcome.result!;
      }

      final trScore = await score(tr);
      final enScore = await score(en);
      expect(
        trScore.dimensionScores.map((d) => d.provisionalScore).toList(),
        enScore.dimensionScores.map((d) => d.provisionalScore).toList(),
      );
      expect(trScore.calibrationStatus.wireValue, 'uncalibrated');
      expect(enScore.calibrationStatus.wireValue, 'uncalibrated');
      final trJson = jsonEncode(trScore.toJson());
      expect(trJson.contains('percentile'), isFalse);
      expect(trScore.toJson()['reliability_estimate'], isNull);
      expect(trScore.toJson().containsKey('overall_iq'), isFalse);
    });
  });

  group('runtime locale selection + session stability', () {
    test('TR preferred language loads TR stems; EN loads EN stems', () async {
      final trManager = IqSessionManager(
        bank: tr,
        repository: IqSessionMemoryRepository(),
        idFactory: IqSessionIdFactory(random: Random(1)),
      );
      final enManager = IqSessionManager(
        bank: en,
        repository: IqSessionMemoryRepository(),
        idFactory: IqSessionIdFactory(random: Random(1)),
      );

      final trSession = await trManager.getOrCreateActiveSession(
        ownerUid: 'u_tr',
        sessionSeed: 's1',
      );
      final enSession = await enManager.getOrCreateActiveSession(
        ownerUid: 'u_en',
        sessionSeed: 's1',
      );
      expect(trSession.state!.bankLocale, 'tr-TR');
      expect(enSession.state!.bankLocale, 'en-US');

      final trItemId = trSession.state!.itemPlans.first.itemId;
      final enItemId = enSession.state!.itemPlans.first.itemId;
      final trPrompt = tr.items.firstWhere((e) => e.id == trItemId).prompt;
      final enPrompt = en.items.firstWhere((e) => e.id == enItemId).prompt;
      expect(
        _commonTrWords.hasMatch(trPrompt) || _trChars.hasMatch(trPrompt),
        isTrue,
      );
      expect(_commonTrWords.hasMatch(enPrompt), isFalse);
      expect(enPrompt, isNot(trPrompt));
    });

    test('resolveBankLocale mapping', () {
      expect(IqCanonicalRuntimeService.resolveBankLocale('tr'), 'tr-TR');
      expect(IqCanonicalRuntimeService.resolveBankLocale('tr-TR'), 'tr-TR');
      expect(IqCanonicalRuntimeService.resolveBankLocale('en'), 'en-US');
      expect(IqCanonicalRuntimeService.resolveBankLocale('en-US'), 'en-US');
      expect(IqCanonicalRuntimeService.resolveBankLocale(null), 'en-US');
    });

    test('active TR session does not mutate when preferred language is EN',
        () async {
      final repo = IqSessionMemoryRepository();
      final manager = IqSessionManager(
        bank: tr,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(3)),
      );
      final created = await manager.getOrCreateActiveSession(
        ownerUid: 'stable_uid',
        sessionSeed: 'seed-a',
      );
      expect(created.state!.bankLocale, 'tr-TR');
      final itemOrder = created.state!.itemPlans.map((e) => e.itemId).toList();

      final resumed = await manager.getOrCreateActiveSession(
        ownerUid: 'stable_uid',
        sessionSeed: 'ignored-en-preference',
      );
      expect(resumed.state!.bankLocale, 'tr-TR');
      expect(
        resumed.state!.itemPlans.map((e) => e.itemId).toList(),
        itemOrder,
      );
      expect(manager.lastOperationComposed, isFalse);

      final enManager = IqSessionManager(
        bank: en,
        repository: repo,
        idFactory: IqSessionIdFactory(random: Random(3)),
      );
      final wrong = await enManager.getOrCreateActiveSession(
        ownerUid: 'stable_uid',
        sessionSeed: 'x',
      );
      expect(wrong.ok, isFalse);
      expect(wrong.code, 'incompatibleBank');
    });

    test('pubspec registers both banks; pilots excluded', () {
      final pub = File('pubspec.yaml').readAsStringSync();
      expect(pub.contains('iq_bank_tr_v1.json'), isTrue);
      expect(pub.contains('iq_bank_en_v1.json'), isTrue);
      expect(pub.contains('iq_pilot_tr_v1'), isFalse);
    });

    test('no PII fields in bank file roots', () {
      for (final path in [_trPath, _enPath]) {
        final text = File(path).readAsStringSync();
        expect(text.contains('"email"'), isFalse);
        expect(text.contains('"phone"'), isFalse);
        expect(text.toLowerCase().contains('password_hash'), isFalse);
      }
    });
  });
}
